#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "interface/apiclient.h"
#include "interface/dbbridge.h"
#include "interface/redisclient.h"
#include "interface/serialbridge.h"
#include "model/taskworker.h"

#include <QtQml/qqml.h>

int main(int argc, char *argv[])
{
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QGuiApplication app(argc, argv);

    // 后端单例：在 QML 里 import App.Backend 1.0 后直接使用
    ApiClient apiClient;
    SerialBridge serialBridge;
    TaskRunner taskRunner;
    DbBridge dbBridge;
    RedisClient redisClient;

    qmlRegisterSingletonInstance("App.Backend", 1, 0, "ApiClient", &apiClient);
    qmlRegisterSingletonInstance("App.Backend", 1, 0, "Serial", &serialBridge);
    qmlRegisterSingletonInstance("App.Backend", 1, 0, "Tasks", &taskRunner);
    qmlRegisterSingletonInstance("App.Backend", 1, 0, "Db", &dbBridge);
    qmlRegisterSingletonInstance("App.Backend", 1, 0, "Redis", &redisClient);

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("test1", "Main");

    return QGuiApplication::exec();
}
