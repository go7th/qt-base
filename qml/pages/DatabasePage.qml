import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

import App.Backend 1.0

// MySQL 连接：QtSql + QMYSQL 驱动（本地 docker 容器 qt-demo-mysql）
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    function showResult(info) {
        var text = ""
        if (info.ok) {
            text = "✓ 成功 · 影响行数 " + info.affected
            if (info.columns.length > 0) {
                text += "\n列: " + info.columns.join(" | ")
                for (var i = 0; i < info.rows.length; ++i)
                    text += "\n" + info.rows[i].join(" | ")
            }
        } else {
            text = "✗ 失败: " + info.error
        }
        resultArea.text = text
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "MySQL 连接（QtSql / QMYSQL）"
            font.pixelSize: 20
            font.bold: true
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        Label {
            text: "依赖 docker 容器 qt-demo-mysql（root/123456，库 demo）。驱动插件 libqsqlmysql.dylib 需自行编译。"
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
        }

        // 连接参数
        GridLayout {
            columns: 8
            columnSpacing: 8
            rowSpacing: 8

            Label { text: "主机:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: hostField; text: "localhost"; Layout.preferredWidth: 110 }
            Label { text: "端口:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: portField; text: "3306"; Layout.preferredWidth: 60 }
            Label { text: "用户:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: userField; text: "root"; Layout.preferredWidth: 90 }
            Label { text: "密码:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: passField; text: "123456"; echoMode: TextInput.Password; Layout.preferredWidth: 90 }

            Label { text: "库名:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField { id: dbField; text: "demo"; Layout.preferredWidth: 110 }
            Button {
                text: Db.connected ? "断开" : "连接"
                highlighted: !Db.connected
                onClicked: {
                    if (Db.connected)
                        Db.disconnectDb()
                    else
                        Db.connectMysql(hostField.text, parseInt(portField.text),
                                        userField.text, passField.text, dbField.text)
                }
            }
            Button {
                text: "检测驱动"
                onClicked: {
                    var ds = Db.availableDrivers()
                    resultArea.text = "已注册 SQL 驱动: " + ds.join(", ")
                            + "\nQMYSQL 可用: " + (ds.indexOf("QMYSQL") >= 0)
                            + (ds.indexOf("QMYSQL") >= 0 ? ""
                               : "\n若缺少 QMYSQL：检查 Qt plugins/sqldrivers/libqsqlmysql.dylib")
                }
            }
            Item { Layout.columnSpan: 4 }
        }

        RowLayout {
            spacing: 8
            Label {
                text: Db.connected ? "● 已连接" : "○ 未连接"
                color: Db.connected ? Theme.ok : Theme.err
                font.pixelSize: 13
            }
            Label {
                text: Db.lastError
                color: Theme.err
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // 快捷测试按钮
        RowLayout {
            spacing: 8
            Button {
                text: "① 建表"
                onClicked: root.showResult(Db.query(
                    "CREATE TABLE IF NOT EXISTS qt_demo ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY, "
                    + "name VARCHAR(64), "
                    + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"))
            }
            Button {
                text: "② 插入"
                onClicked: root.showResult(Db.query(
                    "INSERT INTO qt_demo (name) VALUES ('hello-"
                    + Qt.formatTime(new Date(), "hhmmss") + "')"))
            }
            Button {
                text: "③ 查询"
                onClicked: root.showResult(Db.query(
                    "SELECT id, name, created_at FROM qt_demo ORDER BY id DESC LIMIT 20"))
            }
            Button {
                text: "④ 清空表"
                onClicked: root.showResult(Db.query("DELETE FROM qt_demo"))
            }
        }

        Label {
            text: "SQL（可编辑后点执行）"
            font.bold: true
            font.pixelSize: 13
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        RowLayout {
            spacing: 8
            TextArea {
                id: sqlArea
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                text: "SELECT id, name, created_at FROM qt_demo ORDER BY id DESC LIMIT 20"
                font.family: "Menlo"
                font.pixelSize: 12
                wrapMode: TextEdit.Wrap
                background: Rectangle {
                    color: root.lightMode ? Theme.cardLight : Theme.panel
                    border.color: root.lightMode ? Theme.borderLight : Theme.borderDark
                }
            }
            Button {
                text: "执行 SQL"
                highlighted: true
                onClicked: root.showResult(Db.query(sqlArea.text))
            }
        }

        Label {
            text: "结果"
            font.bold: true
            font.pixelSize: 13
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        TextArea {
            id: resultArea
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
