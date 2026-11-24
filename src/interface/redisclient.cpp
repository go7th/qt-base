#include "redisclient.h"

#include <QQmlEngine>
#include <QtDebug>

RedisClient::RedisClient(QObject *parent)
    : QObject(parent)
{
    connect(&m_socket, &QTcpSocket::connected, this, [this]() {
        emit logMessage(tr("已连接 %1:%2")
                            .arg(m_socket.peerName())
                            .arg(m_socket.peerPort()));
        emit connectedChanged();
    });
    connect(&m_socket, &QTcpSocket::disconnected, this, [this]() {
        emit logMessage(tr("连接已断开"));
        emit connectedChanged();
    });
    connect(&m_socket, &QTcpSocket::readyRead, this, &RedisClient::onReadyRead);
    connect(&m_socket, &QTcpSocket::errorOccurred, this,
            [this](QAbstractSocket::SocketError) {
                emit logMessage(tr("socket 错误: %1").arg(m_socket.errorString()));
                emit connectedChanged();
            });
}

bool RedisClient::isConnected() const
{
    return m_socket.state() == QAbstractSocket::ConnectedState;
}

void RedisClient::connectRedis(const QString &host, int port)
{
    if (m_socket.state() != QAbstractSocket::UnconnectedState)
        m_socket.abort();
    m_buffer.clear();
    emit logMessage(tr("正在连接 %1:%2 ...").arg(host).arg(port));
    m_socket.connectToHost(host, static_cast<quint16>(port));
}

void RedisClient::disconnectRedis()
{
    m_socket.disconnectFromHost();
}

void RedisClient::invoke(QJSValue callback, bool ok, const QString &reply,
                         const QString &error)
{
    if (!callback.isCallable())
        return;
    QJSValueList args;
    args << QJSValue(ok) << QJSValue(reply) << QJSValue(error);
    const QJSValue result = callback.call(args);
    if (result.isError())
        qWarning() << "RedisClient callback error:" << result.toString();
}

void RedisClient::command(const QStringList &args, const QJSValue &callback)
{
    if (args.isEmpty())
        return;
    if (!isConnected()) {
        invoke(callback, false, QString(), tr("未连接 redis"));
        return;
    }
    // RESP 数组编码：*N\r\n$len\r\narg\r\n...
    QByteArray cmd = "*" + QByteArray::number(args.size()) + "\r\n";
    for (const QString &a : args) {
        const QByteArray b = a.toUtf8();
        cmd += "$" + QByteArray::number(b.size()) + "\r\n" + b + "\r\n";
    }
    m_pending.append(callback);
    m_socket.write(cmd);
}

void RedisClient::onReadyRead()
{
    m_buffer += m_socket.readAll();
    pump();
}

void RedisClient::pump()
{
    while (!m_pending.isEmpty()) {
        int consumed = 0;
        QString display;
        bool isError = false;
        if (!parseReplyAt(m_buffer, 0, consumed, display, isError))
            return; // 回包不完整，等更多数据
        m_buffer.remove(0, consumed);
        invoke(m_pending.takeFirst(), !isError, display,
               isError ? display : QString());
        emit replyReceived(!isError, display);
    }
}

// 解析一条 RESP 回复；数据不足返回 false
bool RedisClient::parseReplyAt(const QByteArray &buf, int pos, int &consumed,
                               QString &display, bool &isError)
{
    if (pos >= buf.size())
        return false;
    const char type = buf.at(pos);
    const int lineEnd = buf.indexOf("\r\n", pos);
    if (lineEnd < 0)
        return false;
    const QByteArray line = buf.mid(pos + 1, lineEnd - pos - 1);

    switch (type) {
    case '+': // 简单字符串
    case '-': // 错误
    case ':': // 整数
        display = QString::fromUtf8(line);
        isError = (type == '-');
        consumed = lineEnd + 2 - pos;
        return true;
    case '$': { // 批量字符串
        const qlonglong len = line.toLongLong();
        if (len < 0) {
            display = QStringLiteral("(nil)");
            consumed = lineEnd + 2 - pos;
            return true;
        }
        const int dataStart = lineEnd + 2;
        if (buf.size() < dataStart + len + 2)
            return false;
        display = QString::fromUtf8(buf.mid(dataStart, int(len)));
        consumed = dataStart + int(len) + 2 - pos;
        return true;
    }
    case '*': { // 数组
        const qlonglong count = line.toLongLong();
        if (count < 0) {
            display = QStringLiteral("(nil)");
            consumed = lineEnd + 2 - pos;
            return true;
        }
        int offset = lineEnd + 2;
        QStringList items;
        for (qlonglong i = 0; i < count; ++i) {
            int sub = 0;
            QString subDisplay;
            bool subErr = false;
            if (!parseReplyAt(buf, offset, sub, subDisplay, subErr))
                return false;
            items << subDisplay;
            offset += sub;
        }
        display = QLatin1Char('[') + items.join(QStringLiteral(", "))
                  + QLatin1Char(']');
        consumed = offset - pos;
        return true;
    }
    default:
        display = QString::fromUtf8(buf.mid(pos, lineEnd - pos));
        consumed = lineEnd + 2 - pos;
        isError = true;
        return true;
    }
}
