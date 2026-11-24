#ifndef DBBRIDGE_H
#define DBBRIDGE_H

#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>

// MySQL 连接封装（QtSql + QMYSQL 驱动）
// 说明：演示用同步调用；生产环境应把查询放后台线程（参考 TaskRunner）
class DbBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit DbBridge(QObject *parent = nullptr);

    bool isConnected() const;
    QString lastError() const { return m_lastError; }

    Q_INVOKABLE bool connectMysql(const QString &host, int port, const QString &user,
                                  const QString &password, const QString &database);
    Q_INVOKABLE void disconnectDb();
    // 返回 { ok, columns: [..], rows: [[..]], affected, error }
    Q_INVOKABLE QVariantMap query(const QString &sql);
    Q_INVOKABLE QStringList availableDrivers() const;

signals:
    void connectedChanged();
    void lastErrorChanged();

private:
    void setError(const QString &err);

    QSqlDatabase m_db;
    QString m_lastError;
};

#endif // DBBRIDGE_H
