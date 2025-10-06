#include "superconfigmodel.h"
#include <QJsonArray>
#include <QDebug>

SuperConfigModel::SuperConfigModel(QObject *parent)
    : QObject(parent)
    , m_partitionCount(0)
{
    // Initialize with default values
    m_deviceSlotType = "Unknown";
    m_blockSize = "4096";
    m_superPartitionName = "super";
    m_totalSize = "0 B";
    m_metadataversion = "2";
    m_metadataSize = "65536";
    m_maxSizeOfSuper = "0 B";
    m_alignment = "0";
    m_alignmentOffset = "0";
}

void SuperConfigModel::updateFromConfig(const QJsonObject &config)
{
    // Detect slot type
    QString slotType = detectSlotType(config);
    if (m_deviceSlotType != slotType) {
        m_deviceSlotType = slotType;
        emit deviceSlotTypeChanged();
    }

    // Block size
    if (config.contains("block_devices") && config["block_devices"].isArray()) {
        QJsonArray blockDevices = config["block_devices"].toArray();
        if (!blockDevices.isEmpty()) {
            QJsonObject blockDevice = blockDevices.first().toObject();
            
            QString blockSize = blockDevice["block_size"].toString("4096");
            if (m_blockSize != blockSize) {
                m_blockSize = blockSize;
                emit blockSizeChanged();
            }
            
            QString deviceName = blockDevice["name"].toString("super");
            if (m_superPartitionName != deviceName) {
                m_superPartitionName = deviceName;
                emit superPartitionNameChanged();
            }
            
            qint64 totalSizeBytes = blockDevice["size"].toString("0").toLongLong();
            QString totalSize = formatSize(totalSizeBytes);
            if (m_totalSize != totalSize) {
                m_totalSize = totalSize;
                emit totalSizeChanged();
            }
        }
    }

    // Metadata configuration
    if (config.contains("lpmake")) {
        QJsonObject lpmake = config["lpmake"].toObject();
        
        QString metadataversion = QString::number(lpmake["metadata_slots"].toInt(2));
        if (m_metadataversion != metadataversion) {
            m_metadataversion = metadataversion;
            emit metadataversionChanged();
        }
        
        QString metadataSize = QString::number(lpmake["metadata_size"].toInt(65536));
        if (m_metadataSize != metadataSize) {
            m_metadataSize = metadataSize;
            emit metadataSizeChanged();
        }
    } else {
        // Auto-detect based on groups
        bool isAB = (slotType == "A/B Device");
        QString metadataversion = isAB ? "3" : "2";
        if (m_metadataversion != metadataversion) {
            m_metadataversion = metadataversion;
            emit metadataversionChanged();
        }
    }

    // Parse maximum size of super from groups
    if (config.contains("groups") && config["groups"].isArray()) {
        QJsonArray groups = config["groups"].toArray();
        // Find the group with maximum_size (typically groups[1])
        for (const QJsonValue &value : groups) {
            QJsonObject group = value.toObject();
            if (group.contains("maximum_size")) {
                qint64 maxSizeBytes = group["maximum_size"].toString("0").toLongLong();
                QString maxSize = formatSize(maxSizeBytes);
                if (m_maxSizeOfSuper != maxSize) {
                    m_maxSizeOfSuper = maxSize;
                    emit maxSizeOfSuperChanged();
                }
                break; // Use first group with maximum_size
            }
        }
    }

    // Parse alignment from block_devices
    if (config.contains("block_devices") && config["block_devices"].isArray()) {
        QJsonArray blockDevices = config["block_devices"].toArray();
        if (!blockDevices.isEmpty()) {
            QJsonObject blockDevice = blockDevices.first().toObject();
            
            qint64 alignmentBytes = blockDevice["alignment"].toString("0").toLongLong();
            QString alignment = formatSize(alignmentBytes);
            if (m_alignment != alignment) {
                m_alignment = alignment;
                emit alignmentChanged();
            }
            
            QString alignmentOffset = blockDevice["alignment_offset"].toString("0");
            if (m_alignmentOffset != alignmentOffset) {
                m_alignmentOffset = alignmentOffset;
                emit alignmentOffsetChanged();
            }
        }
    }

    // Count partitions
    if (config.contains("partitions") && config["partitions"].isArray()) {
        QJsonArray partitions = config["partitions"].toArray();
        int partitionCount = partitions.size();
        if (m_partitionCount != partitionCount) {
            m_partitionCount = partitionCount;
            emit partitionCountChanged();
        }
    }
}

QString SuperConfigModel::formatSize(qint64 bytes)
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

QString SuperConfigModel::detectSlotType(const QJsonObject &config)
{
    if (config.contains("groups") && config["groups"].isArray()) {
        QJsonArray groups = config["groups"].toArray();
        
        bool hasMainA = false;
        bool hasMainB = false;
        bool hasMain = false;
        
        for (const QJsonValue &value : groups) {
            QJsonObject group = value.toObject();
            QString groupName = group["name"].toString();
            
            if (groupName == "main_a") {
                hasMainA = true;
            } else if (groupName == "main_b") {
                hasMainB = true;
            } else if (groupName == "main") {
                hasMain = true;
            }
        }
        
        if (hasMainA && hasMainB) {
            return "A/B Device";
        } else if (hasMain) {
            return "Non-A/B Device";
        }
    }
    
    return "Unknown";
}
