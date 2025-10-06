#ifndef SUPERCONFIGMODEL_H
#define SUPERCONFIGMODEL_H

#include <QObject>
#include <QJsonObject>

class SuperConfigModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString deviceSlotType READ deviceSlotType NOTIFY deviceSlotTypeChanged)
    Q_PROPERTY(QString blockSize READ blockSize NOTIFY blockSizeChanged)
    Q_PROPERTY(QString superPartitionName READ superPartitionName NOTIFY superPartitionNameChanged)
    Q_PROPERTY(QString totalSize READ totalSize NOTIFY totalSizeChanged)
    Q_PROPERTY(QString metadataversion READ metadataversion NOTIFY metadataversionChanged)
    Q_PROPERTY(QString metadataSize READ metadataSize NOTIFY metadataSizeChanged)
    Q_PROPERTY(QString maxSizeOfSuper READ maxSizeOfSuper NOTIFY maxSizeOfSuperChanged)
    Q_PROPERTY(QString alignment READ alignment NOTIFY alignmentChanged)
    Q_PROPERTY(QString alignmentOffset READ alignmentOffset NOTIFY alignmentOffsetChanged)
    Q_PROPERTY(int partitionCount READ partitionCount NOTIFY partitionCountChanged)

public:
    explicit SuperConfigModel(QObject *parent = nullptr);

    // Property getters
    QString deviceSlotType() const { return m_deviceSlotType; }
    QString blockSize() const { return m_blockSize; }
    QString superPartitionName() const { return m_superPartitionName; }
    QString totalSize() const { return m_totalSize; }
    QString metadataversion() const { return m_metadataversion; }
    QString metadataSize() const { return m_metadataSize; }
    QString maxSizeOfSuper() const { return m_maxSizeOfSuper; }
    QString alignment() const { return m_alignment; }
    QString alignmentOffset() const { return m_alignmentOffset; }
    int partitionCount() const { return m_partitionCount; }

public slots:
    void updateFromConfig(const QJsonObject &config);

signals:
    void deviceSlotTypeChanged();
    void blockSizeChanged();
    void superPartitionNameChanged();
    void totalSizeChanged();
    void metadataversionChanged();
    void metadataSizeChanged();
    void maxSizeOfSuperChanged();
    void alignmentChanged();
    void alignmentOffsetChanged();
    void partitionCountChanged();

private:
    QString formatSize(qint64 bytes);
    QString detectSlotType(const QJsonObject &config);
    
    QString m_deviceSlotType;
    QString m_blockSize;
    QString m_superPartitionName;
    QString m_totalSize;
    QString m_metadataversion;
    QString m_metadataSize;
    QString m_maxSizeOfSuper;
    QString m_alignment;
    QString m_alignmentOffset;
    int m_partitionCount;
};

#endif // SUPERCONFIGMODEL_H
