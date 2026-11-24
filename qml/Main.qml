import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import QtQuick.VirtualKeyboard

import test1 1.0

ApplicationWindow {
    id: window
    width: 1160
    height: 740
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    title: qsTr("Qt 应用底座")

    property bool lightMode: Theme.lightMode
    property bool loggedIn: false
    property string username: ""

    color: Theme.lightMode ? Theme.light : Theme.dark

    readonly property var navItems: [
        { title: "项目列表", page: "pages/ProjectListPage.qml" },
        { title: "串口助手", page: "pages/SerialPage.qml" },
        { title: "接口调试", page: "pages/ApiPage.qml" },
        { title: "多线程 · 协程", page: "pages/ThreadPage.qml" },
        { title: "MySQL 连接", page: "pages/DatabasePage.qml" },
        { title: "Redis 连接", page: "pages/RedisPage.qml" },
        { title: "Qdrant 向量库", page: "pages/VectorPage.qml" }
    ]

    function showLogin() {
        window.loggedIn = false
        window.username = ""
        var item = stack.replace("pages/LoginPage.qml")
        item.loginSucceeded.connect(function (user) {
            window.username = user
            window.loggedIn = true
            stack.replace(navItems[0].page)
        })
    }

    function navTo(index) {
        stack.replace(navItems[index].page)
    }

    Component.onCompleted: showLogin()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 侧边导航栏
        Rectangle {
            visible: window.loggedIn
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: Theme.lightMode ? Theme.reallyLight : Theme.reallyDark

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                Label {
                    text: "Qt 应用底座"
                    font.family: Theme.uiFont
                    font.bold: true
                    font.pixelSize: 18
                    color: Theme.lightMode ? Theme.reallyDark : Theme.reallyLight
                }
                Label {
                    text: "当前用户：" + window.username
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    color: Theme.lightMode ? Theme.dark : Theme.light
                }
                Item { Layout.preferredHeight: 8 }

                Repeater {
                    model: window.navItems
                    delegate: Button {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        text: modelData.title
                        flat: true
                        font.family: Theme.uiFont
                        font.pixelSize: 14
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: Theme.lightMode ? Theme.reallyDark : Theme.reallyLight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                        background: Rectangle {
                            radius: 6
                            color: parent.down ? Theme.accent
                               : (parent.hovered ? (Theme.lightMode ? Theme.light : Theme.dark) : "transparent")
                        }
                        onClicked: window.navTo(index)
                    }
                }

                Item { Layout.fillHeight: true }

                Button {
                    Layout.fillWidth: true
                    text: "退出登录"
                    font.family: Theme.uiFont
                    onClicked: window.showLogin()
                }
            }
        }

        // 内容区
        StackView {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: Item {}
        }
    }

    // 虚拟键盘面板（InputPanel 用法示例）
    InputPanel {
        id: inputPanel
        z: 99
        y: window.height
        width: window.width

        states: State {
            name: "visible"
            when: inputPanel.active
            PropertyChanges {
                inputPanel.y: window.height - inputPanel.height
            }
        }
        transitions: Transition {
            from: ""
            to: "visible"
            reversible: true
            NumberAnimation {
                properties: "y"
                easing.type: Easing.InOutQuad
            }
        }
    }
}
