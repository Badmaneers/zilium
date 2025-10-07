#include "ziliumcontroller.h"
#include <QFileDialog>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QCoreApplication>
#include <QTextStream>
#include <QDateTime>
#include <QFileInfo>

ZiliumController::ZiliumController(QObject *parent)
    : QObject(parent)
    , m_progress(0)
    , m_isRunning(false)
    , m_isValid(false)
    , m_hasUnsavedChanges(false)
    , m_process(nullptr)
    , m_progressTimer(new QTimer(this))
{
    m_status = "Ready";
    m_estimatedTime = "Unknown";
    
    // Setup progress timer
    m_progressTimer->setInterval(100);
    connect(m_progressTimer, &QTimer::timeout, [this]() {
        if (m_isRunning && m_progress < 90) {
            setProgress(m_progress + 1);
        }
    });
}

void ZiliumController::setConfigPath(const QString &path)
{
    if (m_configPath != path) {
        m_configPath = path;
        emit configPathChanged();
        
        // Auto-load config when path is set
        if (!path.isEmpty()) {
            loadConfig(path);
        }
    }
}

void ZiliumController::setOutputPath(const QString &path)
{
    if (m_outputPath != path) {
        m_outputPath = path;
        emit outputPathChanged();
    }
}

QString ZiliumController::browseForConfig()
{
    QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QString filter = "JSON Files (*.json);;All Files (*)";
    
    QString path = QFileDialog::getOpenFileName(
        nullptr,
        "Select Configuration File",
        documentsPath,
        filter
    );
    
    if (!path.isEmpty()) {
        setConfigPath(path);
    }
    
    return path;
}

QString ZiliumController::browseForOutput()
{
    QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    
    QString path = QFileDialog::getExistingDirectory(
        nullptr,
        "Select Output Directory",
        documentsPath
    );
    
    if (!path.isEmpty()) {
        setOutputPath(path);
    }
    
    return path;
}

bool ZiliumController::loadConfig(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        appendConsoleOutput(QString("ERROR: Cannot open config file: %1").arg(path));
        setStatus("Error loading config");
        return false;
    }
    
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
    
    if (error.error != QJsonParseError::NoError) {
        appendConsoleOutput(QString("ERROR: JSON parse error: %1").arg(error.errorString()));
        setStatus("Invalid JSON config");
        return false;
    }
    
    m_loadedConfig = doc.object();
    
    appendConsoleOutput(QString("✓ Configuration loaded: %1").arg(QFileInfo(path).fileName()));
    setStatus("Config loaded");
    
    // Reset unsaved changes when loading new config
    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
    
    // Validate after loading
    validateConfiguration();
    calculateEstimatedTime();
    
    emit configLoaded(m_loadedConfig);
    return true;
}

bool ZiliumController::validateConfiguration()
{
    m_validationErrors.clear();
    m_validationWarnings.clear();
    
    if (m_loadedConfig.isEmpty()) {
        m_validationErrors << "No configuration loaded";
        updateValidationState();
        return false;
    }
    
    QString romDir = getRomDirectory();
    if (romDir.isEmpty()) {
        m_validationErrors << "Cannot determine ROM directory";
        updateValidationState();
        return false;
    }
    
    // Validate partitions exist and check sizes
    if (!m_loadedConfig.contains("partitions")) {
        m_validationErrors << "No partitions defined in configuration";
        updateValidationState();
        return false;
    }
    
    QJsonArray partitions = m_loadedConfig["partitions"].toArray();
    if (partitions.isEmpty()) {
        m_validationErrors << "Partition list is empty";
        updateValidationState();
        return false;
    }
    
    qint64 totalSize = 0;
    int missingCount = 0;
    QStringList missingSlotAPartitions;
    QStringList missingSlotBPartitions;
    
    for (int i = 0; i < partitions.size(); i++) {
        QJsonObject partition = partitions[i].toObject();
        QString name = partition["name"].toString();
        QString path = partition["path"].toString();
        qint64 declaredSize = partition["size"].toString().toLongLong();
        
        QString fullPath = QDir(romDir).filePath(path);
        QFileInfo fileInfo(fullPath);
        
        if (!fileInfo.exists()) {
            // Track A/B slot partitions separately
            if (name.endsWith("_a")) {
                missingSlotAPartitions << name;
            } else if (name.endsWith("_b")) {
                missingSlotBPartitions << name;
            } else {
                // Non-slotted partition is critical
                m_validationErrors << QString("Missing partition: %1 (%2)").arg(name, path);
                missingCount++;
            }
        } else {
            qint64 actualSize = fileInfo.size();
            totalSize += actualSize;
            
            if (actualSize > declaredSize) {
                m_validationWarnings << QString("%1: File size (%2) exceeds declared size (%3)")
                    .arg(name, formatFileSize(actualSize), formatFileSize(declaredSize));
            } else if (actualSize < declaredSize * 0.5) {
                m_validationWarnings << QString("%1: File size (%2) is much smaller than declared (%3)")
                    .arg(name, formatFileSize(actualSize), formatFileSize(declaredSize));
            }
        }
    }
    
    // For A/B devices: Only report missing slots if BOTH slots are missing
    // If only one slot is missing, treat it as a warning (single-slot build)
    if (!missingSlotAPartitions.isEmpty() && !missingSlotBPartitions.isEmpty()) {
        // Both slots missing - this is an error
        for (const QString &name : missingSlotAPartitions) {
            m_validationErrors << QString("Missing partition: %1").arg(name);
            missingCount++;
        }
        for (const QString &name : missingSlotBPartitions) {
            m_validationErrors << QString("Missing partition: %1").arg(name);
            missingCount++;
        }
    } else if (!missingSlotAPartitions.isEmpty()) {
        // Only slot A missing - warning (using slot B)
        m_validationWarnings << QString("Slot A partitions missing (building for slot B only): %1")
            .arg(missingSlotAPartitions.join(", "));
    } else if (!missingSlotBPartitions.isEmpty()) {
        // Only slot B missing - warning (using slot A)
        m_validationWarnings << QString("Slot B partitions missing (building for slot A only): %1")
            .arg(missingSlotBPartitions.join(", "));
    }
    
    // Check if total size exceeds device size
    if (m_loadedConfig.contains("block_devices")) {
        QJsonArray blockDevices = m_loadedConfig["block_devices"].toArray();
        if (!blockDevices.isEmpty()) {
            QJsonObject blockDevice = blockDevices[0].toObject();
            qint64 deviceSize = blockDevice["size"].toString().toLongLong();
            
            if (totalSize > deviceSize) {
                m_validationErrors << QString("Total partition size (%1) exceeds device size (%2)")
                    .arg(formatFileSize(totalSize), formatFileSize(deviceSize));
            }
        }
    }
    
    // Don't log validation results to console - they're shown in the validation panel
    
    updateValidationState();
    return m_validationErrors.isEmpty();
}

QVariantMap ZiliumController::getBuildPlan()
{
    QVariantMap plan;
    
    if (m_loadedConfig.isEmpty()) {
        plan["error"] = "No configuration loaded";
        return plan;
    }
    
    QString romDir = getRomDirectory();
    QString outputFile = QDir(m_outputPath).filePath("super.img");
    
    // Collect required files
    QStringList requiredFiles;
    qint64 totalSize = 0;
    
    if (m_loadedConfig.contains("partitions")) {
        QJsonArray partitions = m_loadedConfig["partitions"].toArray();
        for (const QJsonValue &val : partitions) {
            QJsonObject partition = val.toObject();
            QString path = partition["path"].toString();
            QString fullPath = QDir(romDir).filePath(path);
            requiredFiles << fullPath;
            
            QFileInfo fileInfo(fullPath);
            if (fileInfo.exists()) {
                totalSize += fileInfo.size();
            }
        }
    }
    
    plan["requiredFiles"] = requiredFiles;
    plan["totalInputSize"] = formatFileSize(totalSize);
    plan["outputPath"] = outputFile;
    plan["estimatedOutputSize"] = formatFileSize(
        m_loadedConfig.contains("block_devices") && 
        !m_loadedConfig["block_devices"].toArray().isEmpty() ?
        m_loadedConfig["block_devices"].toArray()[0].toObject()["size"].toString().toLongLong() : 0
    );
    plan["romDirectory"] = romDir;
    plan["configFile"] = m_configPath;
    
    return plan;
}

QVariantMap ZiliumController::getPartitionSizeRecommendations()
{
    QVariantMap recommendations;
    
    if (m_loadedConfig.isEmpty()) {
        return recommendations;
    }
    
    QString romDir = getRomDirectory();
    if (romDir.isEmpty()) {
        return recommendations;
    }
    
    qint32 alignment = 4096; // Default
    if (m_loadedConfig.contains("block_devices")) {
        QJsonArray blockDevices = m_loadedConfig["block_devices"].toArray();
        if (!blockDevices.isEmpty()) {
            alignment = blockDevices[0].toObject()["alignment"].toString().toInt();
        }
    }
    
    if (m_loadedConfig.contains("partitions")) {
        QJsonArray partitions = m_loadedConfig["partitions"].toArray();
        for (int i = 0; i < partitions.size(); i++) {
            QJsonObject partition = partitions[i].toObject();
            QString name = partition["name"].toString();
            QString path = partition["path"].toString();
            qint64 declaredSize = partition["size"].toString().toLongLong();
            
            QString fullPath = QDir(romDir).filePath(path);
            QFileInfo fileInfo(fullPath);
            
            QVariantMap rec;
            rec["currentSize"] = formatFileSize(declaredSize);
            rec["actualFileSize"] = fileInfo.exists() ? formatFileSize(fileInfo.size()) : "N/A";
            
            if (fileInfo.exists()) {
                qint64 actualSize = fileInfo.size();
                qint64 recommendedSize = ((actualSize + alignment - 1) / alignment) * alignment;
                rec["recommendedSize"] = formatFileSize(recommendedSize);
                rec["needsResize"] = (recommendedSize != declaredSize);
            } else {
                rec["recommendedSize"] = "File not found";
                rec["needsResize"] = false;
            }
            
            recommendations[name] = rec;
        }
    }
    
    return recommendations;
}

bool ZiliumController::exportConfig(const QString &outputPath)
{
    if (m_loadedConfig.isEmpty()) {
        appendConsoleOutput("ERROR: No configuration loaded to export");
        return false;
    }
    
    QFile file(outputPath);
    if (!file.open(QIODevice::WriteOnly)) {
        appendConsoleOutput(QString("ERROR: Cannot write to: %1").arg(outputPath));
        return false;
    }
    
    QJsonDocument doc(m_loadedConfig);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    
    appendConsoleOutput(QString("✓ Configuration exported to: %1").arg(outputPath));
    return true;
}

bool ZiliumController::verifyOutputImage()
{
    if (m_outputPath.isEmpty()) {
        appendConsoleOutput("ERROR: No output path specified");
        return false;
    }
    
    QString outputFile = QDir(m_outputPath).filePath("super.img");
    QFileInfo fileInfo(outputFile);
    
    if (!fileInfo.exists()) {
        appendConsoleOutput("ERROR: Output file does not exist");
        return false;
    }
    
    appendConsoleOutput(QString("✓ Output file exists: %1").arg(outputFile));
    appendConsoleOutput(QString("  Size: %1").arg(formatFileSize(fileInfo.size())));
    appendConsoleOutput("");
    appendConsoleOutput("Running lpdump verification...");
    
    // Try to run lpdump to verify the image
    QString appDir = QCoreApplication::applicationDirPath();
    
    // Platform-specific binary names
#ifdef _WIN32
    QString lpdumpName = "lpdump.exe";
#else
    QString lpdumpName = "lpdump";
#endif
    
    QStringList possiblePaths = {
        // Windows packaged location (lptools directory next to executable)
        QDir(appDir).filePath("lptools/" + lpdumpName),
        // Same directory as executable
        QDir(appDir).filePath(lpdumpName),
        // Legacy paths for development builds
        QDir(appDir).filePath("../lptools-prebuilt/win/" + lpdumpName),
        QDir(appDir).filePath("../../lptools-prebuilt/win/" + lpdumpName),
#ifndef _WIN32
        // Linux packaged location
        QDir(appDir).filePath("lptools/" + lpdumpName),
        // Linux prebuilt location
        QDir(appDir).filePath("../lptools-prebuilt/linux/" + lpdumpName),
        QDir(appDir).filePath("../../lptools-prebuilt/linux/" + lpdumpName),
#endif
        // System PATH as fallback
        lpdumpName
    };
    
    QString lpdump;
    for (const QString &path : possiblePaths) {
        QFileInfo checkFile(path);
        if (checkFile.exists() && checkFile.isExecutable()) {
            lpdump = checkFile.absoluteFilePath();
            appendConsoleOutput(QString("Using lpdump: %1").arg(lpdump));
            break;
        }
    }
    
    if (lpdump.isEmpty()) {
        lpdump = "lpdump";
        appendConsoleOutput("Using system lpdump");
    }
    
    QProcess process;
    process.start(lpdump, QStringList() << outputFile);
    
    if (!process.waitForStarted(3000)) {
        appendConsoleOutput("✗ Failed to start lpdump");
        appendConsoleOutput("⚠ Verification skipped - lpdump not available");
        return false;
    }
    
    process.waitForFinished(10000);
    
    QString stdoutText = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
    QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
    
    // lpdump outputs to stdout on success
    if (!stdoutText.isEmpty()) {
        appendConsoleOutput("✓ Image verification: PASSED");
        appendConsoleOutput("");
        appendConsoleOutput("Super Image Details:");
        appendConsoleOutput(stdoutText);
        return true;
    } else if (!stderrText.isEmpty()) {
        appendConsoleOutput("✗ Image verification: FAILED");
        appendConsoleOutput("");
        appendConsoleOutput("Error details:");
        appendConsoleOutput(stderrText);
        return false;
    } else {
        appendConsoleOutput("⚠ Image verification: UNKNOWN");
        appendConsoleOutput(QString("lpdump exited with code: %1").arg(process.exitCode()));
        return false;
    }
}

void ZiliumController::startCompiling()
{
    if (m_isRunning) {
        return;
    }
    
    if (m_configPath.isEmpty()) {
        appendConsoleOutput("ERROR: No configuration file selected");
        setStatus("Config required");
        return;
    }
    
    if (m_outputPath.isEmpty()) {
        appendConsoleOutput("ERROR: No output directory selected");
        setStatus("Output path required");
        return;
    }
    
    // Validate configuration before starting
    if (!validateConfiguration()) {
        appendConsoleOutput("ERROR: Configuration validation failed");
        appendConsoleOutput("Please fix the following errors:");
        for (const QString &error : m_validationErrors) {
            appendConsoleOutput("  ✗ " + error);
        }
        setStatus("Validation failed");
        return;
    }
    
    if (!m_validationWarnings.isEmpty()) {
        appendConsoleOutput("⚠ Warnings detected (continuing anyway):");
        for (const QString &warning : m_validationWarnings) {
            appendConsoleOutput("  ⚠ " + warning);
        }
    }
    
    // Check if there are unsaved changes
    if (m_hasUnsavedChanges) {
        appendConsoleOutput("ERROR: You have unsaved configuration changes");
        appendConsoleOutput("Please save your changes before building");
        setStatus("Unsaved changes");
        return;
    }
    
    // Use temp config if it exists (from manual save), otherwise use original
    QString configToUse = m_configPath;
    QString configFileName = QFileInfo(m_configPath).fileName();
    
    if (!m_tempConfigPath.isEmpty() && QFile::exists(m_tempConfigPath)) {
        // Copy temp config to META directory so CLI can find it
        QString romDir = getRomDirectory();
        QString metaDir = QDir(romDir).filePath("META");
        QFileInfo tempConfigInfo(m_tempConfigPath);
        QString destPath = QDir(metaDir).filePath(tempConfigInfo.fileName());
        
        // Remove old temp file if exists
        if (QFile::exists(destPath)) {
            QFile::remove(destPath);
        }
        
        // Copy temp config to META directory
        if (QFile::copy(m_tempConfigPath, destPath)) {
            configToUse = destPath;
            configFileName = tempConfigInfo.fileName();
            appendConsoleOutput(QString("✓ Using modified config: %1").arg(configFileName));
        } else {
            appendConsoleOutput("⚠ Warning: Could not copy temp config, using original");
        }
    }
    
    QString ziliumBinary = findZiliumBinary();
    if (ziliumBinary.isEmpty()) {
        appendConsoleOutput("ERROR: Zilium binary not found");
        setStatus("Binary not found");
        return;
    }
    
    // Clean up any existing process
    if (m_process) {
        m_process->deleteLater();
    }
    
    m_process = new QProcess(this);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ZiliumController::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &ZiliumController::onProcessError);
    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &ZiliumController::onProcessOutput);
    connect(m_process, &QProcess::readyReadStandardError,
            this, &ZiliumController::onProcessOutput);
    
    // Prepare arguments
    QStringList arguments;
    
    QString romDir = getRomDirectory();
    
    // Determine output file path
    QString outputFilePath = QDir(m_outputPath).filePath("super.img");
    
    // Pass ROM directory, specific JSON filename, and output directory
    arguments << romDir << configFileName << m_outputPath;
    
    appendConsoleOutput("╔═══════════════════════════════════════════╗");
    appendConsoleOutput("║         Starting Compilation              ║");
    appendConsoleOutput("╚═══════════════════════════════════════════╝");
    appendConsoleOutput(QString("ROM Directory: %1").arg(romDir));
    appendConsoleOutput(QString("Config File: %1").arg(configFileName));
    appendConsoleOutput(QString("Output Directory: %1").arg(m_outputPath));
    appendConsoleOutput(QString("Output: %1").arg(outputFilePath));
    appendConsoleOutput(QString("Estimated Time: %1").arg(m_estimatedTime));
    appendConsoleOutput(QString("Command: %1 %2").arg(ziliumBinary, arguments.join(" ")));
    appendConsoleOutput("");
    
    m_buildStartTime = QDateTime::currentDateTime();
    setStatus("Compiling...");
    setProgress(0);
    setIsRunning(true);
    m_progressTimer->start();
    
    m_process->start(ziliumBinary, arguments);
}

void ZiliumController::stopCompiling()
{
    if (m_process && m_process->state() == QProcess::Running) {
        m_process->kill();
        appendConsoleOutput("Compilation stopped by user");
        setStatus("Stopped");
        setIsRunning(false);
        m_progressTimer->stop();
    }
}

void ZiliumController::clearConsole()
{
    m_consoleOutput.clear();
    emit consoleOutputChanged();
}

QString ZiliumController::formatFileSize(qint64 bytes)
{
    const char* units[] = {"B", "KB", "MB", "GB", "TB"};
    int unitIndex = 0;
    double size = bytes;
    
    while (size >= 1024.0 && unitIndex < 4) {
        size /= 1024.0;
        unitIndex++;
    }
    
    return QString("%1 %2").arg(size, 0, 'f', unitIndex == 0 ? 0 : 1).arg(units[unitIndex]);
}

QString ZiliumController::loadLicenseFile()
{
    QFile file(":/ZiliumGUI/LICENSE");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        QString content = in.readAll();
        file.close();
        return content;
    }
    return "Failed to load LICENSE file.";
}

void ZiliumController::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    m_progressTimer->stop();
    setProgress(100);
    setIsRunning(false);
    
    qint64 buildTimeMs = m_buildStartTime.msecsTo(QDateTime::currentDateTime());
    int buildTimeSec = buildTimeMs / 1000;
    int minutes = buildTimeSec / 60;
    int seconds = buildTimeSec % 60;
    
    QString buildTimeStr = (minutes > 0) 
        ? QString("%1m %2s").arg(minutes).arg(seconds)
        : QString("%1s").arg(seconds);
    
    appendConsoleOutput("");
    appendConsoleOutput("╔═══════════════════════════════════════════╗");
    
    if (exitStatus == QProcess::NormalExit && exitCode == 0) {
        appendConsoleOutput("║         Compilation Complete!             ║");
        appendConsoleOutput("╚═══════════════════════════════════════════╝");
        appendConsoleOutput(QString("✓ Build time: %1").arg(buildTimeStr));
        appendConsoleOutput("");
        
        // Verify output
        QString outputFile = QDir(m_outputPath).filePath("super.img");
        QFileInfo fileInfo(outputFile);
        if (fileInfo.exists()) {
            appendConsoleOutput(QString("✓ Output file: %1").arg(outputFile));
            appendConsoleOutput(QString("✓ File size: %1").arg(formatFileSize(fileInfo.size())));
        }
        
        setStatus("Success");
    } else {
        appendConsoleOutput("║         Compilation Failed!               ║");
        appendConsoleOutput("╚═══════════════════════════════════════════╝");
        appendConsoleOutput(QString("✗ Exit code: %1").arg(exitCode));
        appendConsoleOutput(QString("✗ Build time: %1").arg(buildTimeStr));
        setStatus("Failed");
    }
    
    // Clean up temp config files
    if (!m_tempConfigPath.isEmpty()) {
        // Remove temp file from system temp
        if (QFile::exists(m_tempConfigPath)) {
            QFile::remove(m_tempConfigPath);
        }
        
        // Remove temp file from META directory
        QString romDir = getRomDirectory();
        QFileInfo tempInfo(m_tempConfigPath);
        QString metaTempPath = QDir(romDir).filePath("META/" + tempInfo.fileName());
        if (QFile::exists(metaTempPath)) {
            QFile::remove(metaTempPath);
        }
        
        m_tempConfigPath.clear();
    }
    
    emit compilationFinished(exitCode == 0);
}

void ZiliumController::onProcessError(QProcess::ProcessError error)
{
    m_progressTimer->stop();
    setIsRunning(false);
    
    QString errorString;
    switch (error) {
        case QProcess::FailedToStart:
            errorString = "Failed to start process";
            break;
        case QProcess::Crashed:
            errorString = "Process crashed";
            break;
        case QProcess::Timedout:
            errorString = "Process timed out";
            break;
        default:
            errorString = "Unknown process error";
            break;
    }
    
    appendConsoleOutput(QString("ERROR: %1").arg(errorString));
    setStatus("Error");
}

void ZiliumController::onProcessOutput()
{
    if (!m_process) return;
    
    QByteArray data = m_process->readAllStandardOutput();
    data += m_process->readAllStandardError();
    
    if (!data.isEmpty()) {
        QString output = QString::fromUtf8(data);
        appendConsoleOutput(output.trimmed());
    }
}

void ZiliumController::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
    }
}

void ZiliumController::setProgress(int progress)
{
    if (m_progress != progress) {
        m_progress = qBound(0, progress, 100);
        emit progressChanged();
    }
}

void ZiliumController::appendConsoleOutput(const QString &text)
{
    if (!text.isEmpty()) {
        if (!m_consoleOutput.isEmpty()) {
            m_consoleOutput += "\n";
        }
        m_consoleOutput += text;
        emit consoleOutputChanged();
    }
}

void ZiliumController::setIsRunning(bool running)
{
    if (m_isRunning != running) {
        m_isRunning = running;
        emit isRunningChanged();
    }
}

QString ZiliumController::findZiliumBinary()
{
    // First, try to find the binary in the same directory as the GUI
    QString appDir = QCoreApplication::applicationDirPath();
    
    // Platform-specific binary names
#ifdef _WIN32
    QString binaryName = "zilium-super-compactor.exe";
#else
    QString binaryName = "zilium-super-compactor";
#endif
    
    // Check common binary names and locations
    QStringList possiblePaths = {
        // Same directory as GUI executable (packaged location)
        QDir(appDir).filePath(binaryName),
        // Development build locations
        QDir(appDir).filePath("../" + binaryName),
        QDir(appDir).filePath("../../" + binaryName),
        QDir(appDir).filePath("../build/Release/" + binaryName),
        QDir(appDir).filePath("../../build/Release/" + binaryName),
#ifndef _WIN32
        // System-wide installation paths (Linux)
        "/usr/local/bin/zilium-super-compactor",
        "/usr/bin/zilium-super-compactor"
#endif
    };
    
    for (const QString &path : possiblePaths) {
        if (QFile::exists(path) && QFileInfo(path).isExecutable()) {
            return path;
        }
    }
    
    // Try to find in PATH as fallback
    return binaryName;
}

void ZiliumController::updatePartitionInConfig(int index, const QString &path)
{
    if (!m_loadedConfig.contains("partitions")) {
        return;
    }
    
    QJsonArray partitions = m_loadedConfig["partitions"].toArray();
    if (index < 0 || index >= partitions.size()) {
        return;
    }
    
    QJsonObject partition = partitions[index].toObject();
    partition["path"] = path;
    partitions[index] = partition;
    
    m_loadedConfig["partitions"] = partitions;
    
    // Mark as having unsaved changes
    m_hasUnsavedChanges = true;
    emit hasUnsavedChangesChanged();
    
    qDebug() << "Updated partition" << index << "path to:" << path;
    appendConsoleOutput(QString("⚠ Configuration modified (unsaved changes)"));
}

bool ZiliumController::saveModifiedConfig()
{
    if (m_configPath.isEmpty() || m_loadedConfig.isEmpty()) {
        appendConsoleOutput("ERROR: No config loaded to save");
        return false;
    }
    
    // Create temp config in system temp directory with unique name
    QString tempDir = QDir::tempPath();
    QFileInfo configInfo(m_configPath);
    QString baseName = configInfo.completeBaseName(); // filename without extension
    QString tempFileName = QString("zilium_%1_%2.json")
        .arg(baseName)
        .arg(QDateTime::currentMSecsSinceEpoch());
    QString tempPath = QDir(tempDir).filePath(tempFileName);
    
    QFile file(tempPath);
    if (!file.open(QIODevice::WriteOnly)) {
        appendConsoleOutput(QString("ERROR: Cannot write to: %1").arg(tempPath));
        return false;
    }
    
    QJsonDocument doc(m_loadedConfig);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    
    appendConsoleOutput(QString("✓ Saved modified config to: %1").arg(tempPath));
    
    // Store temp path separately - DON'T overwrite original path
    m_tempConfigPath = tempPath;
    
    // Reset unsaved changes flag
    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
    
    return true;
}

QString ZiliumController::saveConfigAs()
{
    if (m_loadedConfig.isEmpty()) {
        appendConsoleOutput("ERROR: No configuration loaded to save");
        return QString();
    }
    
    QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    
    // Suggest a default filename based on current config
    QString defaultName = "super_config.json";
    if (!m_configPath.isEmpty()) {
        QFileInfo configInfo(m_configPath);
        defaultName = configInfo.baseName() + "_modified.json";
    }
    
    QString defaultPath = QDir(documentsPath).filePath(defaultName);
    
    QString filter = "JSON Files (*.json);;All Files (*)";
    
    QString savePath = QFileDialog::getSaveFileName(
        nullptr,
        "Save Configuration As",
        defaultPath,
        filter
    );
    
    if (savePath.isEmpty()) {
        // User cancelled
        return QString();
    }
    
    // Ensure .json extension
    if (!savePath.endsWith(".json", Qt::CaseInsensitive)) {
        savePath += ".json";
    }
    
    // Save the configuration
    QFile file(savePath);
    if (!file.open(QIODevice::WriteOnly)) {
        appendConsoleOutput(QString("ERROR: Cannot write to: %1").arg(savePath));
        return QString();
    }
    
    QJsonDocument doc(m_loadedConfig);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    
    appendConsoleOutput(QString("✓ Configuration saved to: %1").arg(savePath));
    
    // Reset unsaved changes flag
    if (m_hasUnsavedChanges) {
        m_hasUnsavedChanges = false;
        emit hasUnsavedChangesChanged();
    }
    
    return savePath;
}

void ZiliumController::updateValidationState()
{
    bool wasValid = m_isValid;
    m_isValid = m_validationErrors.isEmpty();
    
    emit validationErrorsChanged();
    emit validationWarningsChanged();
    
    if (wasValid != m_isValid) {
        emit isValidChanged();
    }
}

void ZiliumController::calculateEstimatedTime()
{
    if (m_loadedConfig.isEmpty()) {
        m_estimatedTime = "Unknown";
        emit estimatedTimeChanged();
        return;
    }
    
    QString romDir = getRomDirectory();
    if (romDir.isEmpty()) {
        m_estimatedTime = "Unknown";
        emit estimatedTimeChanged();
        return;
    }
    
    qint64 totalBytes = 0;
    
    if (m_loadedConfig.contains("partitions")) {
        QJsonArray partitions = m_loadedConfig["partitions"].toArray();
        for (const QJsonValue &val : partitions) {
            QJsonObject partition = val.toObject();
            QString path = partition["path"].toString();
            QString fullPath = QDir(romDir).filePath(path);
            
            QFileInfo fileInfo(fullPath);
            if (fileInfo.exists()) {
                totalBytes += fileInfo.size();
            }
        }
    }
    
    // Estimate: ~100 MB/s processing speed
    qint64 estimatedSeconds = totalBytes / (100 * 1024 * 1024);
    if (estimatedSeconds < 1) estimatedSeconds = 1;
    
    int minutes = estimatedSeconds / 60;
    int seconds = estimatedSeconds % 60;
    
    if (minutes > 0) {
        m_estimatedTime = QString("%1m %2s").arg(minutes).arg(seconds);
    } else {
        m_estimatedTime = QString("%1s").arg(seconds);
    }
    
    emit estimatedTimeChanged();
}

QString ZiliumController::getRomDirectory()
{
    if (m_configPath.isEmpty()) {
        return QString();
    }
    
    QFileInfo configFileInfo(m_configPath);
    QString metaDir = configFileInfo.absolutePath();
    QString romDir = metaDir;
    
    // If the config is in META folder, go up one level to get ROM root
    if (QFileInfo(metaDir).fileName() == "META") {
        romDir = QFileInfo(metaDir).absolutePath();
    }
    
    return romDir;
}
