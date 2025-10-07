#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QDir>

#include "ziliumcontroller.h"
#include "partitionmodel.h"
#include "superconfigmodel.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    // Set application properties
    app.setApplicationName("Zilium Super Compactor");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("Zilium");
    app.setOrganizationDomain("zilium.com");
    
    // Set the Quick Controls style to Material for better KDE-like appearance
    QQuickStyle::setStyle("Material");
    
    // Create the QML engine
    QQmlApplicationEngine engine;
    
    // Create controller and models
    ZiliumController controller;
    PartitionModel partitionModel;
    SuperConfigModel configModel;
    
    // Register types with QML
    qmlRegisterType<ZiliumController>("ZiliumGUI", 1, 0, "ZiliumController");
    qmlRegisterType<PartitionModel>("ZiliumGUI", 1, 0, "PartitionModel");
    qmlRegisterType<SuperConfigModel>("ZiliumGUI", 1, 0, "SuperConfigModel");
    
    // Set context properties
    engine.rootContext()->setContextProperty("ziliumController", &controller);
    engine.rootContext()->setContextProperty("partitionModel", &partitionModel);
    engine.rootContext()->setContextProperty("configModel", &configModel);
    
    // Connect controller to models
    QObject::connect(&controller, &ZiliumController::configLoaded,
                     &partitionModel, &PartitionModel::updateFromConfig);
    QObject::connect(&controller, &ZiliumController::configLoaded,
                     &configModel, &SuperConfigModel::updateFromConfig);
    
    // Connect partition model changes back to controller
    QObject::connect(&partitionModel, &PartitionModel::dataChanged,
                     [&controller, &partitionModel](const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &roles) {
        // If path was changed, update the controller's config
        if (roles.contains(PartitionModel::PathRole)) {
            int row = topLeft.row();
            QString newPath = partitionModel.getPartitionPath(row);
            controller.updatePartitionInConfig(row, newPath);
        }
    });
    
    // Load QML - use platform-specific version on Windows
#ifdef Q_OS_WIN
    const QUrl url(u"qrc:/ZiliumGUI/qml/main_windows.qml"_qs);
#else
    const QUrl url(u"qrc:/ZiliumGUI/qml/main.qml"_qs);
#endif
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    if (engine.rootObjects().isEmpty())
        return -1;
    
    return app.exec();
}
