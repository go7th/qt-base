import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import test1 1.0

// 组件层 · 项目卡片：状态色条 + 状态徽章 + 交错入场 + hover 提亮
Rectangle {
    id: card

    property var rowData: ({})
    property int index: 0
    signal openDetail()

    readonly property bool anyRunning: String(rowData.status).indexOf("0/") !== 0
    readonly property color statusColor: anyRunning ? Theme.ok : Theme.err

    implicitHeight: 82
    radius: Theme.radiusCard
    color: Theme.lightMode ? Theme.cardLight : Theme.panel
    border.width: hover.hovered ? 2 : 1
    border.color: hover.hovered ? Theme.accentWarm
                : (Theme.lightMode ? Theme.borderLight : Theme.borderDark)
    Behavior on border.color { ColorAnimation { duration: 140 } }

    // 入场：交错渐显 + 上移
    opacity: 0
    transform: Translate { id: lift; y: 14 }
    Component.onCompleted: enterAnim.start()
    SequentialAnimation {
        id: enterAnim
        PauseAnimation { duration: Math.min(card.index * 45, 600) }
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 1
                              duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: lift; property: "y"; to: 0
                              duration: 240; easing.type: Easing.OutCubic }
        }
    }

    HoverHandler { id: hover }

    // 左侧状态色条
    Rectangle {
        width: 4
        radius: 2
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        color: card.statusColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 16
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Label {
                text: card.rowData.title
                font.family: Theme.uiFont
                font.bold: true
                font.pixelSize: 15
                color: Theme.lightMode ? Theme.reallyDark : Theme.reallyLight
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                text: card.rowData.desc
                font.family: Theme.uiFont
                font.pixelSize: 12
                color: Theme.lightMode ? Theme.mutedLight : Theme.mutedDark
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // 状态徽章
        Rectangle {
            radius: 999
            color: card.anyRunning ? Theme.okBg : Theme.errBg
            implicitWidth: statusRow.implicitWidth + 18
            implicitHeight: 26

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    width: 7
                    height: 7
                    radius: 4
                    color: card.statusColor
                }
                Label {
                    text: card.rowData.status
                    font.family: Theme.monoFont
                    font.pixelSize: 11
                    color: card.statusColor
                }
            }
        }

        Label {
            text: card.rowData.disk
            font.family: Theme.monoFont
            font.pixelSize: 12
            color: Theme.lightMode ? Theme.dimLight : Theme.dimDark
            Layout.preferredWidth: 64
            horizontalAlignment: Text.AlignRight
        }

        Button {
            text: "详情"
            hoverEnabled: true
            onClicked: card.openDetail()
            background: Rectangle {
                radius: Theme.radiusSm
                color: parent.hovered ? Theme.accentWarm
                     : (Theme.lightMode ? Theme.light : Theme.groupDark)
                border.width: 1
                border.color: parent.hovered ? Theme.accentWarm
                            : (Theme.lightMode ? Theme.borderLight : Theme.borderDark)
            }
            contentItem: Label {
                text: parent.text
                font.family: Theme.uiFont
                font.bold: true
                font.pixelSize: 13
                color: parent.hovered ? Theme.reallyDark
                     : (Theme.lightMode ? Theme.reallyDark : Theme.reallyLight)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
