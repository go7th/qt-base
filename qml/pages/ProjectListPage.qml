import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import App.Backend 1.0
import test1 1.0

// 项目列表页：GET /api/projects（ServiceMonitor，端口 7788）
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: Theme.lightMode ? Theme.light : Theme.dark

    // 嵌套作用域里 StackView.view 为 null，必须在页面根捕获
    property var stackView: StackView.view

    property var rows: []
    property string statusText: ""

    function load(refresh) {
        root.statusText = "加载中..."
        ApiClient.get("/api/projects" + (refresh ? "?refresh=1" : ""),
                      function (ok, status, body, error) {
            if (status === 0 && !ok) {
                root.statusText = "请求失败：" + error + "（ServiceMonitor 是否已启动？默认端口 7788）"
                return
            }
            try {
                var data = JSON.parse(body)
                var list = []
                var groups = data.groups || []
                for (var g = 0; g < groups.length; ++g) {
                    var group = groups[g]
                    list.push({ kind: "group", title: group.name + "（" + group.projects.length + "）" })
                    var projects = group.projects || []
                    for (var p = 0; p < projects.length; ++p) {
                        var proj = projects[p]
                        var running = 0
                        var comps = proj.components || []
                        for (var c = 0; c < comps.length; ++c)
                            if (comps[c].status === "running")
                                running++
                        list.push({
                            kind: "project",
                            project: proj,
                            title: proj.name,
                            desc: proj.description || "",
                            status: running + "/" + comps.length + " 运行中",
                            disk: proj.diskSizeText || ""
                        })
                    }
                }
                root.rows = list
                root.statusText = "共 " + groups.length + " 个分组 · HTTP " + status
            } catch (e) {
                root.statusText = "解析失败：" + e
            }
        })
    }

    Component.onCompleted: load(false)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // —— 页头 ——
        RowLayout {
            spacing: 12
            ColumnLayout {
                spacing: 2
                Label {
                    text: "项目列表"
                    font.family: Theme.uiFont
                    font.pixelSize: 26
                    font.bold: true
                    color: Theme.lightMode ? Theme.reallyDark : Theme.reallyLight
                }
                Label {
                    text: "SERVICEMONITOR · LOCAL DEV OPS"
                    font.family: Theme.monoFont
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    color: Theme.lightMode ? Theme.dimLight : Theme.dimDark
                }
            }
            Item { Layout.fillWidth: true }
            TextField {
                id: baseUrlField
                Layout.preferredWidth: 240
                font.family: Theme.monoFont
                font.pixelSize: 12
                text: ApiClient.baseUrl
                placeholderText: "http://localhost:7788"
                onEditingFinished: ApiClient.baseUrl = text
            }
            Button {
                text: "刷新状态"
                font.family: Theme.uiFont
                font.bold: true
                hoverEnabled: true
                onClicked: root.load(true)
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: parent.down ? Theme.reallyDark
                         : (parent.hovered ? Theme.accentWarm : Theme.accent)
                }
                contentItem: Label {
                    text: parent.text
                    font: parent.font
                    color: parent.down ? Theme.reallyLight : (parent.hovered ? Theme.reallyDark : "#ffffff")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 14
                    rightPadding: 14
                }
            }
        }

        // —— 状态条 ——
        RowLayout {
            spacing: 8
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: Theme.ok
            }
            Label {
                text: root.statusText
                font.family: Theme.monoFont
                font.pixelSize: 11
                color: Theme.lightMode ? Theme.dimLight : Theme.dimDark
            }
        }

        // —— 列表 ——
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            clip: true
            model: root.rows

            // 注意：Component {} 内解析不到 delegate 的 id（rowLoader），只能在
            // delegate 作用域里用 onLoaded 命令式赋值 / 闭包连接信号
            delegate: Loader {
                id: rowLoader
                property var rowData: modelData
                property int rowIndex: index
                width: ListView.view.width
                height: item ? item.implicitHeight : 0
                sourceComponent: rowData.kind === "group" ? groupComponent : cardComponent
                onLoaded: {
                    item.rowData = rowData
                    if (item.openDetail)
                        item.openDetail.connect(function () {
                            root.stackView.push("ProjectDetailPage.qml",
                                                { project: rowLoader.rowData.project })
                        })
                }
            }
        }

        Component {
            id: cardComponent
            ProjectCard {}
        }

        Component {
            id: groupComponent
            Rectangle {
                id: groupRoot
                property var rowData: ({})
                implicitHeight: 38
                color: "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 12
                    Label {
                        text: groupRoot.rowData.title
                        font.family: Theme.monoFont
                        font.bold: true
                        font.pixelSize: 12
                        font.letterSpacing: 1
                        color: Theme.lightMode ? Theme.dimLight : Theme.dimDark
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.lightMode ? Theme.borderLight : Theme.borderDark
                    }
                }
            }
        }
    }
}
