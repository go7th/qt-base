#ifndef SERIALBRIDGE_H
#define SERIALBRIDGE_H

#include <QObject>
#include <QSerialPort>
#include <QStringList>

// 串口助手后端：枚举串口、打开/关闭、收发文本与 HEX 数据
class SerialBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool open READ isOpen NOTIFY openChanged)
    Q_PROPERTY(QStringList ports READ ports NOTIFY portsChanged)
    Q_PROPERTY(QString currentPort READ currentPort NOTIFY openChanged)

public:
    explicit SerialBridge(QObject *parent = nullptr);

    bool isOpen() const { return m_port.isOpen(); }
    QStringList ports() const { return m_ports; }
    QString currentPort() const { return m_port.portName(); }

    Q_INVOKABLE void refreshPorts();
    Q_INVOKABLE bool openPort(const QString &name, int baudRate);
    Q_INVOKABLE void closePort();
    Q_INVOKABLE void sendText(const QString &text);
    Q_INVOKABLE void sendHex(const QString &hexText);

signals:
    void openChanged();
    void portsChanged();
    void dataReceived(const QString &text, const QString &hex);
    void logMessage(const QString &msg);

private:
    QSerialPort m_port;
    QStringList m_ports;
};

#endif // SERIALBRIDGE_H
