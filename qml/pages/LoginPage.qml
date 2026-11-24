import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

// 登录页：演示登录/登出流程（本地校验，可对接真实接口）
Rectangle {
    id: root
    signal loginSucceeded(string user)

    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    function doLogin() {
        if (userField.text.length === 0) {
            errorLabel.text = "请输入用户名"
            return
        }
        if (passwordField.text.length < 4) {
            errorLabel.text = "演示密码至少 4 位"
            return
        }
        errorLabel.text = ""
        root.loginSucceeded(userField.text)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(360, parent.width - 60)
        spacing: 14

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "登 录"
            font.pixelSize: 28
            font.bold: true
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "演示登录（本地校验），实际项目可对接后端鉴权接口"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 320
            color: root.lightMode ? Theme.dark : Theme.light
        }

        TextField {
            id: userField
            Layout.fillWidth: true
            placeholderText: "用户名（任意）"
            font.pixelSize: 15
            onAccepted: passwordField.forceActiveFocus()
        }
        TextField {
            id: passwordField
            Layout.fillWidth: true
            placeholderText: "密码（至少 4 位）"
            echoMode: TextInput.Password
            font.pixelSize: 15
            onAccepted: root.doLogin()
        }

        Label {
            id: errorLabel
            Layout.fillWidth: true
            color: Theme.err
            font.pixelSize: 13
            text: ""
        }

        Button {
            Layout.fillWidth: true
            text: "登录"
            font.pixelSize: 15
            highlighted: true
            onClicked: root.doLogin()
        }

        Label {
            Layout.fillWidth: true
            text: "提示：聚焦输入框可弹出虚拟键盘（InputPanel）"
            font.pixelSize: 11
            color: root.lightMode ? Theme.mutedLight : Theme.mutedDark
        }
    }
}
