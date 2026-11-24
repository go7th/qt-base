import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

import App.Backend 1.0

// Redis 连接测试：QTcpSocket + RESP 协议（docker 容器 qt-demo-redis）
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    function appendLog(line) {
        logArea.append("[" + Qt.formatTime(new Date(), "hh:mm:ss.zzz") + "] " + line)
    }

    // 发送一条 redis 命令并记录收发
    function run(args) {
        appendLog("→ " + args.join(" "))
        Redis.command(args, function (ok, reply, error) {
            root.appendLog("← " + (ok ? reply : ("错误: " + error)))
        })
    }

    Connections {
        target: Redis
        function onLogMessage(msg) {
            root.appendLog(msg)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "Redis 连接测试（RESP 协议）"
            font.pixelSize: 20
            font.bold: true
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        Label {
            text: "无第三方库：C++ 直接用 QTcpSocket 实现 RESP 编解码。依赖 docker 容器 qt-demo-redis。"
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
        }

        RowLayout {
            spacing: 8
            Label { text: "主机:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: hostField; text: "localhost"; Layout.preferredWidth: 120 }
            Label { text: "端口:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: portField; text: "6379"; Layout.preferredWidth: 70 }
            Button {
                text: Redis.connected ? "断开" : "连接"
                highlighted: !Redis.connected
                onClicked: {
                    if (Redis.connected)
                        Redis.disconnectRedis()
                    else
                        Redis.connectRedis(hostField.text, parseInt(portField.text))
                }
            }
            Label {
                text: Redis.connected ? "● 已连接" : "○ 未连接"
                color: Redis.connected ? Theme.ok : Theme.err
                font.pixelSize: 13
            }
            Item { Layout.fillWidth: true }
        }

        // 测试命令按钮组
        RowLayout {
            spacing: 8
            Button {
                text: "PING"
                enabled: Redis.connected
                onClicked: root.run(["PING"])
            }
            Label { text: "键:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: keyField; text: "qt:demo"; Layout.preferredWidth: 110 }
            Label { text: "值:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: valueField; text: "hello"; Layout.preferredWidth: 90 }
        }
        RowLayout {
            spacing: 8
            Button {
                text: "SET"
                enabled: Redis.connected
                onClicked: root.run(["SET", keyField.text, valueField.text])
            }
            Button {
                text: "GET"
                enabled: Redis.connected
                onClicked: root.run(["GET", keyField.text])
            }
            Button {
                text: "DEL"
                enabled: Redis.connected
                onClicked: root.run(["DEL", keyField.text])
            }
            Button {
                text: "INCR 计数器"
                enabled: Redis.connected
                onClicked: root.run(["INCR", "qt:demo:counter"])
            }
            Button {
                text: "INFO"
                enabled: Redis.connected
                onClicked: root.run(["INFO", "server"])
            }
            Item { Layout.fillWidth: true }
        }

        Label {
            text: "收发日志"
            font.bold: true
            font.pixelSize: 13
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        TextArea {
            id: logArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            readOnly: true
            wrapMode: TextEdit.Wrap
            font.family: "Menlo"
            font.pixelSize: 12
            background: Rectangle {
                color: root.lightMode ? Theme.cardLight : Theme.panel
                border.color: root.lightMode ? Theme.borderLight : Theme.borderDark
            }
        }
    }
}
