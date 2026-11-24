#ifndef APICLIENT_H
#define APICLIENT_H

#include <QJSValue>
#include <QNetworkAccessManager>
#include <QObject>
#include <QUrl>

class QQmlEngine;

// HTTP 接口调用封装（GET/POST/PUT/DELETE）
// 供 QML 以回调方式使用：ApiClient.get("/api/projects", function(ok, status, body, error) {...})
class ApiClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)

public:
    explicit ApiClient(QObject *parent = nullptr);

    QString baseUrl() const { return m_baseUrl; }
    void setBaseUrl(const QString &url);

    // callback(bool ok, int statusCode, string body, string error)
    Q_INVOKABLE void get(const QString &pathOrUrl, const QJSValue &callback);
    Q_INVOKABLE void post(const QString &pathOrUrl, const QJSValue &body, const QJSValue &callback);
    Q_INVOKABLE void put(const QString &pathOrUrl, const QJSValue &body, const QJSValue &callback);
    Q_INVOKABLE void del(const QString &pathOrUrl, const QJSValue &callback);

signals:
    void baseUrlChanged();

private:
    void send(const QString &method, const QString &pathOrUrl,
              const QByteArray &body, const QJSValue &callback);
    QUrl resolveUrl(const QString &pathOrUrl) const;
    static QByteArray toJsonBytes(const QJSValue &body);
    void invoke(QJSValue callback, bool ok, int status,
                const QString &body, const QString &error);

    QNetworkAccessManager m_nam;
    QString m_baseUrl = QStringLiteral("http://localhost:7788");
};

#endif // APICLIENT_H
