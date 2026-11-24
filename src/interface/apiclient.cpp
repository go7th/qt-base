#include "apiclient.h"

#include <QJsonDocument>
#include <QNetworkReply>
#include <QQmlEngine>
#include <QtDebug>

ApiClient::ApiClient(QObject *parent)
    : QObject(parent)
{
}

void ApiClient::setBaseUrl(const QString &url)
{
    if (m_baseUrl == url)
        return;
    m_baseUrl = url;
    emit baseUrlChanged();
}

QUrl ApiClient::resolveUrl(const QString &pathOrUrl) const
{
    if (pathOrUrl.startsWith(QLatin1String("http://"))
        || pathOrUrl.startsWith(QLatin1String("https://")))
        return QUrl(pathOrUrl);
    QString base = m_baseUrl;
    if (base.endsWith(QLatin1Char('/')))
        base.chop(1);
    const QString path = pathOrUrl.startsWith(QLatin1Char('/')) ? pathOrUrl
                                                                : QLatin1Char('/') + pathOrUrl;
    return QUrl(base + path);
}

QByteArray ApiClient::toJsonBytes(const QJSValue &body)
{
    if (body.isString())
        return body.toString().toUtf8();
    if (body.isObject() && !body.isNull())
        return QJsonDocument::fromVariant(body.toVariant()).toJson(QJsonDocument::Compact);
    return QByteArrayLiteral("{}");
}

void ApiClient::invoke(QJSValue callback, bool ok, int status,
                       const QString &body, const QString &error)
{
    if (!callback.isCallable())
        return;
    QJSValueList args;
    args << QJSValue(ok) << QJSValue(status) << QJSValue(body) << QJSValue(error);
    const QJSValue result = callback.call(args);
    if (result.isError())
        qWarning() << "ApiClient callback error:" << result.toString();
}

void ApiClient::send(const QString &method, const QString &pathOrUrl,
                     const QByteArray &body, const QJSValue &callback)
{
    QNetworkRequest req(resolveUrl(pathOrUrl));
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    QNetworkReply *reply = m_nam.sendCustomRequest(req, method.toUtf8(), body);
    connect(reply, &QNetworkReply::finished, this, [this, reply, callback]() {
        reply->deleteLater();
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QString bodyText = QString::fromUtf8(reply->readAll());
        const bool ok = (reply->error() == QNetworkReply::NoError);
        invoke(callback, ok, status, bodyText,
               ok ? QString() : reply->errorString());
    });
}

void ApiClient::get(const QString &pathOrUrl, const QJSValue &callback)
{
    send(QStringLiteral("GET"), pathOrUrl, QByteArray(), callback);
}

void ApiClient::post(const QString &pathOrUrl, const QJSValue &body, const QJSValue &callback)
{
    send(QStringLiteral("POST"), pathOrUrl, toJsonBytes(body), callback);
}

void ApiClient::put(const QString &pathOrUrl, const QJSValue &body, const QJSValue &callback)
{
    send(QStringLiteral("PUT"), pathOrUrl, toJsonBytes(body), callback);
}

void ApiClient::del(const QString &pathOrUrl, const QJSValue &callback)
{
    send(QStringLiteral("DELETE"), pathOrUrl, QByteArray(), callback);
}
