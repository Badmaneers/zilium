#ifndef PARTITIONMODEL_H
#define PARTITIONMODEL_H

#include <QAbstractTableModel>
#include <QJsonObject>
#include <QJsonArray>

struct Partition {
    bool enabled = true;
    QString name;
    QString size;
    QString path;
    qint64 sizeBytes = 0;
    
    explicit Partition(const QString &n = "", qint64 s = 0, const QString &p = "")
        : name(n), sizeBytes(s), path(p) {
        formatSize();
    }
    
    void formatSize() {
        const char* units[] = {"B", "KB", "MB", "GB", "TB"};
        int unitIndex = 0;
        double s = sizeBytes;
        
        while (s >= 1024.0 && unitIndex < 4) {
            s /= 1024.0;
            unitIndex++;
        }
        
        size = QString("%1 %2").arg(s, 0, 'f', unitIndex == 0 ? 0 : 1).arg(units[unitIndex]);
    }
};

class PartitionModel : public QAbstractTableModel
{
    Q_OBJECT

public:
    enum Roles {
        EnabledRole = Qt::UserRole + 1,
        NameRole,
        SizeRole,
        PathRole,
        SizeBytesRole
    };

    explicit PartitionModel(QObject *parent = nullptr);

    // QAbstractTableModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

public slots:
    void updateFromConfig(const QJsonObject &config);
    Q_INVOKABLE void setPartitionEnabled(int row, bool enabled);
    Q_INVOKABLE bool isPartitionEnabled(int row) const;
    Q_INVOKABLE QString getPartitionName(int row) const;
    Q_INVOKABLE QString getPartitionSize(int row) const;
    Q_INVOKABLE QString getPartitionPath(int row) const;
    Q_INVOKABLE void setPartitionPath(int row, const QString &path);
    Q_INVOKABLE void browseForPartitionImage(int row);

private:
    QList<Partition> m_partitions;
    void loadSampleData();
};

#endif // PARTITIONMODEL_H
