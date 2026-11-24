#include "dbbridge.h"

#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>

static const char kConnName[] = "qt-demo-mysql";

DbBridge::DbBridge(QObject *parent)
    : QObject(parent)
{
}

bool DbBridge::isConnected() const
{
    return m_db.isValid() && m_db.isOpen();
}

void DbBridge::setError(const QString &err)
{
    if (m_lastError == err)
        return;
    m_lastError = err;
    emit lastErrorChanged();
}

QStringList DbBridge::availableDrivers() const
{
    return QSqlDatabase::drivers();
}

bool DbBridge::connectMysql(const QString &host, int port, const QString &user,
                            const QString &password, const QString &database)
{
    disconnectDb();

    bool ok = false;
    QString err;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QMYSQL"),
                                                   QString::fromLatin1(kConnName));
        // "localhost" 会让 libmysqlclient 走 unix socket，Docker 场景需强制 TCP
        db.setHostName(host == QLatin1String("localhost") ? QStringLiteral("127.0.0.1")
                                                         : host);
        db.setPort(port);
        db.setUserName(user);
        db.setPassword(password);
        db.setDatabaseName(database);
        ok = db.open();
        if (ok) {
            m_db = db;
        } else {
            err = db.lastError().text();
        }
    }
    if (!ok) {
        QSqlDatabase::removeDatabase(QString::fromLatin1(kConnName));
        setError(err.isEmpty() ? tr("连接失败") : err);
    } else {
        setError(QString());
    }
    emit connectedChanged();
    return ok;
}

void DbBridge::disconnectDb()
{
    if (m_db.isValid()) {
        const QString name = m_db.connectionName();
        m_db.close();
        m_db = QSqlDatabase();
        QSqlDatabase::removeDatabase(name);
    }
    emit connectedChanged();
}

QVariantMap DbBridge::query(const QString &sql)
{
    QVariantMap result;
    result.insert(QStringLiteral("ok"), false);
    result.insert(QStringLiteral("columns"), QStringList());
    result.insert(QStringLiteral("rows"), QVariantList());
    result.insert(QStringLiteral("affected"), -1);
    result.insert(QStringLiteral("error"), QString());

    if (!isConnected()) {
        result.insert(QStringLiteral("error"), tr("未连接数据库"));
        return result;
    }

    QSqlQuery q(m_db);
    if (!q.exec(sql)) {
        const QString err = q.lastError().text();
        setError(err);
        result.insert(QStringLiteral("error"), err);
        return result;
    }

    if (q.isSelect()) {
        QStringList columns;
        const QSqlRecord rec = q.record();
        for (int i = 0; i < rec.count(); ++i)
            columns << rec.fieldName(i);
        QVariantList rows;
        while (q.next()) {
            QVariantList row;
            for (int i = 0; i < rec.count(); ++i)
                row << q.value(i);
            rows.append(QVariant(row));
        }
        result.insert(QStringLiteral("columns"), columns);
        result.insert(QStringLiteral("rows"), rows);
        result.insert(QStringLiteral("affected"), rows.size());
    } else {
        result.insert(QStringLiteral("affected"), q.numRowsAffected());
    }
    result.insert(QStringLiteral("ok"), true);
    setError(QString());
    return result;
}
