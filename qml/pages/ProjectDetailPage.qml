import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

import App.Backend 1.0

// 项目详情页：展示组件状态，POST /api/projects/:pid/start|stop 控制启停
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    property var project: ({})
    property string statusText: ""

    // 嵌套作用域里 StackView.view 为 null，必须在页面根捕获
    property var stackView: StackView.view

    function refresh() {
        ApiClient.get("/api/projects?refresh=1", function (ok, status, body, error) {
            if (status === 0 && !ok) {
                root.statusText ="刷新失败：" + error
                return
            }
            try {
                var data = JSON.parse(body)
                var groups = data.groups || []
                for (var g = 0; g < groups.length; ++g) {
                    var projects = groups[g].projects || []
                    for (var p = 0; p < projects.length; ++p) {
                        if (projects[p].id === root.project.id) {
                            root.project = projects[p]
                            root.statusText ="已刷新 · HTTP " + status
                            return
                        }
                    }
                }
                root.statusText ="未找到项目 " + root.project.id
            } catch (e) {
                root.statusText ="解析失败：" + e
            }
        })
    }

    function control(action) {
        root.statusText =action === "start" ? "启动中..." : "停止中..."
        ApiClient.post("/api/projects/" + root.project.id + "/" + action, {},
                       function (ok, status, body, error) {
            root.statusText =(action === "start" ? "启动" : "停止") + "请求完成 · HTTP "
                         + status + (ok ? "" : " · " + error)
            root.refresh()
        })
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            spacing: 12
            Button {
                text: "← 返回"
                onClicked: root.stackView.pop()
            }
            Label {
                text: root.project.name || ""
                font.pixelSize: 20
                font.bold: true
                color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "启动项目"
                highlighted: true
                onClicked: root.control("start")
            }
            Button {
                text: "停止项目"
                onClicked: root.control("stop")
            }
            Button {
                text: "刷新"
                onClicked: root.refresh()
            }
        }

        Label {
            text: (root.project.description || "") + "\n"
                  + "路径：" + (root.project.path || "") + "    磁盘占用："
                  + (root.project.diskSizeText || "-")
                  + "    标签：" + ((root.project.tags || []).join(", ") || "-")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
        }

        Label {
            text: root.statusText
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
        }

        Label {
            text: "组件"
            font.bold: true
            font.pixelSize: 15
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            clip: true
            model: root.project.components || []

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 84
                radius: 6
                color: root.lightMode ? Theme.cardLight : Theme.reallyDark
                border.color: root.lightMode ? Theme.borderLight : Theme.borderDark

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: modelData.label || modelData.id
                            font.bold: true
                            font.pixelSize: 14
                            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
                        }
                        Label {
                            text: "类型：" + (modelData.type || "-")
                                  + "    端口：" + (modelData.port || "-")
                                  + (modelData.memoryText ? "    内存：" + modelData.memoryText : "")
                                  + (modelData.cpu !== null && modelData.cpu !== undefined
                                     ? "    CPU：" + Number(modelData.cpu).toFixed(1) + "%" : "")
                            font.pixelSize: 12
                            color: root.lightMode ? Theme.mutedLight : Theme.mutedDark
                        }
                        Label {
                            text: modelData.url || ""
                            font.pixelSize: 12
                            color: Theme.accent
                            visible: text.length > 0
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally(parent.text)
                            }
                        }
                    }

                    Rectangle {
                        radius: 10
                        width: statusLabel.implicitWidth + 16
                        height: 22
                        color: modelData.status === "running" ? Theme.ok
                             : (modelData.status === "stopped" ? Theme.mutedDark : Theme.err)
                        Label {
                            id: statusLabel
                            anchors.centerIn: parent
                            text: modelData.status === "running" ? "运行中"
                                : (modelData.status === "stopped" ? "已停止" : modelData.status)
                            font.pixelSize: 11
                            color: "white"
                        }
                    }
                }
            }
        }
    }
}
