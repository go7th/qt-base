import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

import App.Backend 1.0

// 接口调试页：ApiClient 的 GET/POST/PUT/DELETE 调用与返回展示
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    // 请求列表：method + path + 说明 + QML 调用代码
    readonly property var samples: [
        {
            title: "GET /api/projects — 获取项目列表",
            method: "GET",
            path: "/api/projects",
            code: 'ApiClient.get("/api/projects", function(ok, status, body, error) {\n'
                  + '    if (!ok) { console.log(error); return }\n'
                  + '    var data = JSON.parse(body)   // { groups: [...], lanIp: "..." }\n'
                  + '})',
            note: "ServiceMonitor 核心接口：返回分组/项目/组件状态"
        },
        {
            title: "GET /api/projects?refresh=1 — 强制刷新状态",
            method: "GET",
            path: "/api/projects?refresh=1",
            code: 'ApiClient.get("/api/projects?refresh=1", function(ok, status, body) {\n'
                  + '    // 忽略缓存，重新探测进程/容器状态\n'
                  + '})',
            note: "带缓存清理的查询参数写法"
        },
        {
            title: "GET /api/models — 获取模型列表",
            method: "GET",
            path: "/api/models",
            code: 'ApiClient.get("/api/models", function(ok, status, body) {\n'
                  + '    console.log(body)\n'
                  + '})',
            note: "另一个 GET 接口（本地模型管理）"
        },
        {
            title: "POST /api/projects/:pid/start — 启动项目",
            method: "POST",
            path: "/api/projects/__PID__/start",
            code: '// 第二个参数是 JS 对象，会自动序列化为 JSON body\n'
                  + 'ApiClient.post("/api/projects/my-project/start", {\n'
                  + '    // 空 body 传 {}\n'
                  + '}, function(ok, status, body) {\n'
                  + '    console.log("HTTP", status)\n'
                  + '})',
            note: "POST + JSON body；路径参数替换 :pid"
        },
        {
            title: "GET /api/projects/:pid/readme — 读取 README",
            method: "GET",
            path: "/api/projects/__PID__/readme",
            code: 'ApiClient.get("/api/projects/my-project/readme", function(ok, status, body) {\n'
                  + '    console.log(body)\n'
                  + '})',
            note: "路径参数写法"
        }
    ]

    property string responseText: ""
    property string pidHint: ""

    function send() {
        var s = samples[sampleBox.currentIndex]
        var path = s.path
        if (path.indexOf("__PID__") >= 0) {
            if (pidField.text.length === 0) {
                responseText = "该请求需要填项目 id（可先跑『GET /api/projects』看 id 字段）"
                return
            }
            path = path.replace("__PID__", pidField.text)
        }
        var t0 = Date.now()
        var cb = function (ok, status, body, error) {
            var ms = Date.now() - t0
            var pretty = body
            try { pretty = JSON.stringify(JSON.parse(body), null, 2) } catch (e) {}
            root.responseText = "请求: " + s.method + " " + path + "\n"
                    + "结果: HTTP " + status + " · " + ms + " ms · ok=" + ok
                    + (ok ? "" : ("\n错误: " + error)) + "\n\n" + pretty
        }
        if (s.method === "GET")
            ApiClient.get(path, cb)
        else
            ApiClient.post(path, {}, cb)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "接口调试"
            font.pixelSize: 20
            font.bold: true
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        Label {
            text: "统一走 C++ ApiClient（QNetworkAccessManager），回调签名：function(ok, status, body, error)"
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
        }

        RowLayout {
            spacing: 8
            ComboBox {
                id: sampleBox
                Layout.preferredWidth: 360
                model: {
                    var titles = []
                    for (var i = 0; i < root.samples.length; ++i)
                        titles.push(root.samples[i].title)
                    return titles
                }
                onCurrentIndexChanged: {
                    codeArea.text = root.samples[currentIndex].code
                    noteLabel.text = root.samples[currentIndex].note
                }
            }
            TextField {
                id: pidField
                Layout.preferredWidth: 180
                placeholderText: "项目 id（含 :pid 的接口用）"
            }
            Button {
                text: "发送请求"
                highlighted: true
                onClicked: root.send()
            }
        }

        Label {
            id: noteLabel
            text: root.samples[sampleBox.currentIndex].note
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
        }

        Label {
            text: "QML 调用代码"
            font.bold: true
            font.pixelSize: 13
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        TextArea {
            id: codeArea
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            readOnly: true
            text: root.samples[sampleBox.currentIndex].code
            font.family: "Menlo"
            font.pixelSize: 12
            wrapMode: TextEdit.Wrap
            background: Rectangle {
                color: root.lightMode ? Theme.cardLight : Theme.panel
                border.color: root.lightMode ? Theme.borderLight : Theme.borderDark
            }
        }

        Label {
            text: "响应"
            font.bold: true
            font.pixelSize: 13
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        TextArea {
            id: responseArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            readOnly: true
            text: root.responseText
            font.family: "Menlo"
            font.pixelSize: 12
            wrapMode: TextEdit.Wrap
            background: Rectangle {
                color: root.lightMode ? Theme.cardLight : Theme.panel
                border.color: root.lightMode ? Theme.borderLight : Theme.borderDark
            }
        }
    }
}
