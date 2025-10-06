#include "partitionmodel.h"
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QFileDialog>
#include <QStandardPaths>

PartitionModel::PartitionModel(QObject *parent)
    : QAbstractTableModel(parent)
{
    loadSampleData();
}

int PartitionModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_partitions.count();
}

int PartitionModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 4; // Enabled, Name, Size, Path
}

QVariant PartitionModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_partitions.count()) {
        return QVariant();
    }

    const Partition &partition = m_partitions.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
        switch (index.column()) {
        case 0: return partition.enabled;
        case 1: return partition.name;
        case 2: return partition.size;
        case 3: return partition.path;
        }
        break;
    case Qt::CheckStateRole:
        if (index.column() == 0) {
            return partition.enabled ? Qt::Checked : Qt::Unchecked;
        }
        break;
    case EnabledRole:
        return partition.enabled;
    case NameRole:
        return partition.name;
    case SizeRole:
        return partition.size;
    case PathRole:
        return partition.path;
    case SizeBytesRole:
        return partition.sizeBytes;
    }

    return QVariant();
}

bool PartitionModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid() || index.row() >= m_partitions.count()) {
        return false;
    }

    Partition &partition = m_partitions[index.row()];

    switch (role) {
    case Qt::CheckStateRole:
        if (index.column() == 0) {
            partition.enabled = (value.toInt() == Qt::Checked);
            emit dataChanged(index, index, {Qt::CheckStateRole, EnabledRole});
            return true;
        }
        break;
    case EnabledRole:
        partition.enabled = value.toBool();
        emit dataChanged(index, index, {EnabledRole});
        return true;
    }

    return false;
}

Qt::ItemFlags PartitionModel::flags(const QModelIndex &index) const
{
    if (!index.isValid()) {
        return Qt::NoItemFlags;
    }

    Qt::ItemFlags flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;
    
    if (index.column() == 0) {
        flags |= Qt::ItemIsUserCheckable;
    }

    return flags;
}

QVariant PartitionModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
        switch (section) {
        case 0: return "Enabled";
        case 1: return "Partition Name";
        case 2: return "Size";
        case 3: return "Path";
        }
    }
    return QVariant();
}

QHash<int, QByteArray> PartitionModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[EnabledRole] = "enabled";
    roles[NameRole] = "name";
    roles[SizeRole] = "size";  
    roles[PathRole] = "path";
    roles[SizeBytesRole] = "sizeBytes";
    return roles;
}

void PartitionModel::updateFromConfig(const QJsonObject &config)
{
    qDebug() << "PartitionModel::updateFromConfig called";
    qDebug() << "Config keys:" << config.keys();
    
    beginResetModel();
    m_partitions.clear();

    if (config.contains("partitions") && config["partitions"].isArray()) {
        QJsonArray partitionsArray = config["partitions"].toArray();
        qDebug() << "Found" << partitionsArray.size() << "partitions in config";
        
        for (const QJsonValue &value : partitionsArray) {
            QJsonObject partitionObj = value.toObject();
            
            QString name = partitionObj["name"].toString();
            qint64 sizeBytes = partitionObj["size"].toString().toLongLong();
            QString path = partitionObj["path"].toString();
            
            qDebug() << "Adding partition:" << name << "size:" << sizeBytes << "path:" << path;
            
            Partition partition(name, sizeBytes, path);
            m_partitions.append(partition);
        }
        
        qDebug() << "Total partitions loaded:" << m_partitions.count();
    } else {
        qDebug() << "WARNING: No 'partitions' array found in config!";
    }

    endResetModel();
}

void PartitionModel::setPartitionEnabled(int row, bool enabled)
{
    if (row >= 0 && row < m_partitions.count()) {
        QModelIndex idx = index(row, 0);
        setData(idx, enabled, EnabledRole);
    }
}

bool PartitionModel::isPartitionEnabled(int row) const
{
    if (row >= 0 && row < m_partitions.count()) {
        return m_partitions.at(row).enabled;
    }
    return false;
}

QString PartitionModel::getPartitionName(int row) const
{
    if (row >= 0 && row < m_partitions.count()) {
        return m_partitions.at(row).name;
    }
    return QString();
}

QString PartitionModel::getPartitionSize(int row) const
{
    if (row >= 0 && row < m_partitions.count()) {
        return m_partitions.at(row).size;
    }
    return QString();
}

QString PartitionModel::getPartitionPath(int row) const
{
    if (row >= 0 && row < m_partitions.count()) {
        return m_partitions.at(row).path;
    }
    return QString();
}

void PartitionModel::loadSampleData()
{
    beginResetModel();
    m_partitions.clear();
    
    // Add sample partitions
    m_partitions.append(Partition("system", 1258291200, "IMAGES/system.img"));
    m_partitions.append(Partition("vendor", 536870912, "IMAGES/vendor.img"));
    m_partitions.append(Partition("product", 268435456, "IMAGES/product.img"));
    m_partitions.append(Partition("odm", 134217728, "IMAGES/odm.img"));
    
    endResetModel();
}

void PartitionModel::setPartitionPath(int row, const QString &path)
{
    if (row >= 0 && row < m_partitions.count()) {
        m_partitions[row].path = path;
        
        // Emit dataChanged for the path column
        QModelIndex topLeft = index(row, 3);
        QModelIndex bottomRight = index(row, 3);
        emit dataChanged(topLeft, bottomRight, {PathRole});
        
        qDebug() << "Updated partition" << m_partitions[row].name << "path to:" << path;
    }
}

void PartitionModel::browseForPartitionImage(int row)
{
    qDebug() << "browseForPartitionImage called for row:" << row;
    
    if (row < 0 || row >= m_partitions.count()) {
        qDebug() << "Invalid row:" << row << "count:" << m_partitions.count();
        return;
    }
    
    QString currentPath = m_partitions[row].path;
    QString startDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    
    // If current path exists, use its directory as starting point
    if (!currentPath.isEmpty()) {
        QFileInfo fileInfo(currentPath);
        if (fileInfo.exists()) {
            startDir = fileInfo.absolutePath();
        }
    }
    
    qDebug() << "Opening file dialog for partition:" << m_partitions[row].name;
    qDebug() << "Starting directory:" << startDir;
    
    QString filter = "Image Files (*.img *.raw *.bin);;All Files (*)";
    QString newPath = QFileDialog::getOpenFileName(
        nullptr,
        QString("Select Image for %1 Partition").arg(m_partitions[row].name),
        startDir,
        filter
    );
    
    qDebug() << "Selected path:" << newPath;
    
    if (!newPath.isEmpty()) {
        setPartitionPath(row, newPath);
    }
}
