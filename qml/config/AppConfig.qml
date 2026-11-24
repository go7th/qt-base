pragma Singleton
import QtQuick

// 配置层 · 本地开发服务默认地址（由 ServiceMonitor docker-infra 启动）
QtObject {
    readonly property string apiBaseUrl: "http://localhost:7788"   // ServiceMonitor
    readonly property string mysqlHost: "localhost"
    readonly property int mysqlPort: 3306
    readonly property string mysqlUser: "root"
    readonly property string mysqlPassword: "123456"
    readonly property string mysqlDatabase: "demo"
    readonly property string redisHost: "localhost"
    readonly property int redisPort: 6379
    readonly property string qdrantUrl: "http://localhost:6333"
    readonly property string qdrantCollection: "qt_demo"
}
