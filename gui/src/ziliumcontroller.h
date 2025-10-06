#ifndef ZILIUMCONTROLLER_H
#define ZILIUMCONTROLLER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QProcess>
#include <QTimer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QVariantMap>

class ZiliumController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString configPath READ configPath WRITE setConfigPath NOTIFY configPathChanged)
    Q_PROPERTY(QString outputPath READ outputPath WRITE setOutputPath NOTIFY outputPathChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString consoleOutput READ consoleOutput NOTIFY consoleOutputChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)
    Q_PROPERTY(QStringList validationErrors READ validationErrors NOTIFY validationErrorsChanged)
    Q_PROPERTY(QStringList validationWarnings READ validationWarnings NOTIFY validationWarningsChanged)
    Q_PROPERTY(bool isValid READ isValid NOTIFY isValidChanged)
    Q_PROPERTY(QString estimatedTime READ estimatedTime NOTIFY estimatedTimeChanged)
    Q_PROPERTY(bool hasUnsavedChanges READ hasUnsavedChanges NOTIFY hasUnsavedChangesChanged)

public:
    explicit ZiliumController(QObject *parent = nullptr);
    
    // Property getters
    QString configPath() const { return m_configPath; }
    QString outputPath() const { return m_outputPath; }
    QString status() const { return m_status; }
    int progress() const { return m_progress; }
    QString consoleOutput() const { return m_consoleOutput; }
    bool isRunning() const { return m_isRunning; }
    QStringList validationErrors() const { return m_validationErrors; }
    QStringList validationWarnings() const { return m_validationWarnings; }
    bool isValid() const { return m_isValid; }
    QString estimatedTime() const { return m_estimatedTime; }
    bool hasUnsavedChanges() const { return m_hasUnsavedChanges; }
    
    // Property setters
    void setConfigPath(const QString &path);
    void setOutputPath(const QString &path);

public slots:
    // File operations
    Q_INVOKABLE QString browseForConfig();
    Q_INVOKABLE QString browseForOutput();
    Q_INVOKABLE bool loadConfig(const QString &path);
    
    // Validation
    Q_INVOKABLE bool validateConfiguration();
    Q_INVOKABLE QVariantMap getBuildPlan();
    Q_INVOKABLE QVariantMap getPartitionSizeRecommendations();
    
    // Config operations
    Q_INVOKABLE void updatePartitionInConfig(int index, const QString &path);
    Q_INVOKABLE bool saveModifiedConfig();
    Q_INVOKABLE QString saveConfigAs();
    Q_INVOKABLE bool exportConfig(const QString &outputPath);
    
    // Main operation
    Q_INVOKABLE void startCompiling();
    Q_INVOKABLE void stopCompiling();
    Q_INVOKABLE bool verifyOutputImage();
    
    // Console operations
    Q_INVOKABLE void clearConsole();
    
    // Utility functions
    Q_INVOKABLE QString formatFileSize(qint64 bytes);
    Q_INVOKABLE QString loadLicenseFile();

signals:
    void configPathChanged();
    void outputPathChanged();
    void statusChanged();
    void progressChanged();
    void consoleOutputChanged();
    void isRunningChanged();
    void configLoaded(const QJsonObject &config);
    void compilationFinished(bool success);
    void validationErrorsChanged();
    void validationWarningsChanged();
    void isValidChanged();
    void estimatedTimeChanged();
    void hasUnsavedChangesChanged();

private slots:
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessError(QProcess::ProcessError error);
    void onProcessOutput();

private:
    void setStatus(const QString &status);
    void setProgress(int progress);
    void appendConsoleOutput(const QString &text);
    void setIsRunning(bool running);
    QString findZiliumBinary();
    void updateValidationState();
    void calculateEstimatedTime();
    QString getRomDirectory();
    
    QString m_configPath;
    QString m_tempConfigPath;  // Temp config path when modifications are made
    QString m_outputPath;
    QString m_status;
    int m_progress;
    QString m_consoleOutput;
    bool m_isRunning;
    QStringList m_validationErrors;
    QStringList m_validationWarnings;
    bool m_isValid;
    QString m_estimatedTime;
    bool m_hasUnsavedChanges;
    
    QProcess *m_process;
    QTimer *m_progressTimer;
    
    // Loaded config data
    QJsonObject m_loadedConfig;
    QDateTime m_buildStartTime;
};

#endif // ZILIUMCONTROLLER_H
