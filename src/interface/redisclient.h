#ifndef REDISCLIENT_H
#define REDISCLIENT_H

#include <QByteArray>
#include <QJSValue>
#include <QList>
#include <QObject>
#include <QTcpSocket>

class QQmlEngine;

// 极简 Redis 客户端：基于 QTcpSocket 直接实现 RESP 协议（无第三方库）
// 支持 PING / SET / GET / DEL / INCR / INFO 等任意命令
// 用法：Redis.command(["SET", "foo", "bar"], function(ok, reply, error) {...})
class RedisClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)

public:
    explicit RedisClient(QObject *parent = nullptr);

    bool isConnected() const;

    Q_INVOKABLE void connectRedis(const QString &host, int port);
    Q_INVOKABLE void disconnectRedis();
    // callback(bool ok, string reply, string error)
    Q_INVOKABLE void command(const QStringList &args, const QJSValue &callback);

signals:
    void connectedChanged();
    void logMessage(const QString &msg);
    void replyReceived(bool ok, const QString &reply);

private slots:
    void onReadyRead();

private:
    void pump();
    bool parseReplyAt(const QByteArray &buf, int pos, int &consumed,
                      QString &display, bool &isError);
    void invoke(QJSValue callback, bool ok, const QString &reply, const QString &error);

    QTcpSocket m_socket;
    QByteArray m_buffer;
    QList<QJSValue> m_pending;
};

#endif // REDISCLIENT_H
