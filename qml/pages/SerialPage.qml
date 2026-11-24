import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

import App.Backend 1.0

// 串口助手：枚举串口、打开/关闭、文本与 HEX 收发
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    function now() {
        return Qt.formatTime(new Date(), "hh:mm:ss.zzz")
    }

    function appendLog(line) {
        logArea.append("[" + now() + "] " + line)
    }

    Connections {
        target: Serial
        function onDataReceived(text, hex) {
            root.appendLog("← " + (hexCheck.checked ? ("[HEX] " + hex) : text))
        }
        function onLogMessage(msg) {
            root.appendLog(msg)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "串口助手"
            font.pixelSize: 20
            font.bold: true
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }

        // 连接控制区
        RowLayout {
            spacing: 8
            Label { text: "串口:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            ComboBox {
                id: portBox
                Layout.preferredWidth: 160
                model: Serial.ports
            }
            Button {
                text: "刷新"
                onClicked: Serial.refreshPorts()
            }
            Label { text: "波特率:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            ComboBox {
                id: baudBox
                Layout.preferredWidth: 100
                model: ["9600", "19200", "38400", "57600", "115200"]
                currentIndex: 4
            }
            Button {
                text: Serial.open ? "关闭串口" : "打开串口"
                highlighted: !Serial.open
                onClicked: {
                    if (Serial.open)
                        Serial.closePort()
                    else if (portBox.currentText.length > 0)
                        Serial.openPort(portBox.currentText, parseInt(baudBox.currentText))
                }
            }
            Label {
                text: Serial.open ? "● 已打开 " + Serial.currentPort : "○ 未连接"
                color: Serial.open ? Theme.ok : Theme.err
                font.pixelSize: 13
            }
            Item { Layout.fillWidth: true }
        }

        // 接收区
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "接收日志"
                font.bold: true
                color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
            }
            CheckBox {
                id: hexCheck
                text: "HEX 显示"
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "清空"
                onClicked: logArea.clear()
            }
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

        // 发送区
        RowLayout {
            spacing: 8
            TextField {
                id: sendField
                Layout.fillWidth: true
                placeholderText: "输入要发送的内容（文本或 HEX，如 01 03 00 00）"
                onAccepted: {
                    Serial.sendText(text)
                    text = ""
                }
            }
            Button {
                text: "发送文本"
                onClicked: {
                    Serial.sendText(sendField.text)
                    sendField.text = ""
                }
            }
            Button {
                text: "发送 HEX"
                onClicked: {
                    Serial.sendHex(sendField.text)
                    sendField.text = ""
                }
            }
        }
    }
}
