#include "serialbridge.h"

#include <QRegularExpression>
#include <QSerialPortInfo>

SerialBridge::SerialBridge(QObject *parent)
    : QObject(parent)
{
    connect(&m_port, &QSerialPort::readyRead, this, [this]() {
        const QByteArray data = m_port.readAll();
        emit dataReceived(QString::fromUtf8(data),
                          QString::fromLatin1(data.toHex(' ')));
    });
    connect(&m_port, &QSerialPort::errorOccurred, this,
            [this](QSerialPort::SerialPortError err) {
                if (err == QSerialPort::NoError)
                    return;
                emit logMessage(tr("串口错误: %1").arg(m_port.errorString()));
                if (m_port.isOpen() && err == QSerialPort::ResourceError) {
                    m_port.close();
                    emit openChanged();
                }
            });
    refreshPorts();
}

void SerialBridge::refreshPorts()
{
    QStringList names;
    const auto infos = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &info : infos)
        names << info.portName();
    if (names != m_ports) {
        m_ports = names;
        emit portsChanged();
    }
    emit logMessage(tr("已刷新串口列表，共 %1 个").arg(names.size()));
}

bool SerialBridge::openPort(const QString &name, int baudRate)
{
    if (m_port.isOpen())
        m_port.close();
    m_port.setPortName(name);
    m_port.setBaudRate(baudRate);
    m_port.setDataBits(QSerialPort::Data8);
    m_port.setParity(QSerialPort::NoParity);
    m_port.setStopBits(QSerialPort::OneStop);
    m_port.setFlowControl(QSerialPort::NoFlowControl);
    if (!m_port.open(QIODevice::ReadWrite)) {
        emit logMessage(tr("打开 %1 失败: %2").arg(name, m_port.errorString()));
        emit openChanged();
        return false;
    }
    emit logMessage(tr("已打开 %1 @ %2 bps").arg(name).arg(baudRate));
    emit openChanged();
    return true;
}

void SerialBridge::closePort()
{
    if (!m_port.isOpen())
        return;
    m_port.close();
    emit logMessage(tr("已关闭 %1").arg(m_port.portName()));
    emit openChanged();
}

void SerialBridge::sendText(const QString &text)
{
    if (!m_port.isOpen()) {
        emit logMessage(tr("发送失败：串口未打开"));
        return;
    }
    m_port.write(text.toUtf8());
    emit logMessage(tr("→ %1").arg(text));
}

void SerialBridge::sendHex(const QString &hexText)
{
    if (!m_port.isOpen()) {
        emit logMessage(tr("发送失败：串口未打开"));
        return;
    }
    QString clean = hexText;
    clean.remove(QRegularExpression(QStringLiteral("[\\s:]")));
    static const QRegularExpression hexRe(QStringLiteral("^[0-9A-Fa-f]*$"));
    if (clean.isEmpty() || clean.size() % 2 != 0 || !hexRe.match(clean).hasMatch()) {
        emit logMessage(tr("HEX 格式无效（需偶数个 0-9A-F）：%1").arg(hexText));
        return;
    }
    const QByteArray data = QByteArray::fromHex(clean.toLatin1());
    m_port.write(data);
    emit logMessage(tr("→ [HEX] %1").arg(QString::fromLatin1(data.toHex(' '))));
}
