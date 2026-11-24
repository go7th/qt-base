import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

import App.Backend 1.0

// Qdrant 向量库：REST API（docker 容器 qt-demo-qdrant，端口 6333）
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    readonly property string collection: "qt_demo"

    function base() {
        return baseUrlField.text.replace(/\/+$/, "")
    }

    function show(title, ok, status, body, error) {
        var pretty = body
        try { pretty = JSON.stringify(JSON.parse(body), null, 2) } catch (e) {}
        responseArea.text = "【" + title + "】HTTP " + status + " · ok=" + ok
                + (ok ? "" : ("\n错误: " + error)) + "\n\n" + pretty
    }

    // 请求包装：method GET/PUT/POST/DELETE + 可选 body
    function call(title, method, path, body) {
        var url = root.base() + path
        var cb = function (ok, status, resp, error) {
            root.show(title, ok, status, resp, error)
        }
        if (method === "GET")
            ApiClient.get(url, cb)
        else if (method === "PUT")
            ApiClient.put(url, body || {}, cb)
        else if (method === "POST")
            ApiClient.post(url, body || {}, cb)
        else
            ApiClient.del(url, cb)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "Qdrant 向量库（REST API）"
            font.pixelSize: 20
            font.bold: true
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        Label {
            text: "依赖 docker 容器 qt-demo-qdrant。内置 4 维测试向量；实际使用时由 embedding 模型输出（常见 768/1536 维）。"
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
        }

        RowLayout {
            spacing: 8
            Label { text: "服务地址:"; color: root.lightMode ? Theme.reallyDark : Theme.reallyLight }
            TextField {
                id: baseUrlField
                text: "http://localhost:6333"
                Layout.preferredWidth: 220
            }
            Label {
                text: "集合: " + root.collection
                font.pixelSize: 12
                color: root.lightMode ? Theme.dimLight : Theme.dimDark
            }
            Item { Layout.fillWidth: true }
        }

        // 操作按钮
        RowLayout {
            spacing: 8
            Button {
                text: "① 健康检查"
                onClicked: root.call("健康检查 GET /", "GET", "/")
            }
            Button {
                text: "② 创建集合"
                onClicked: root.call("创建集合 PUT /collections/" + root.collection,
                    "PUT", "/collections/" + root.collection,
                    { vectors: { size: 4, distance: "Cosine" } })
            }
            Button {
                text: "③ 写入向量"
                onClicked: root.call("写入向量 PUT /collections/" + root.collection + "/points",
                    "PUT", "/collections/" + root.collection + "/points",
                    { points: [
                        { id: 1, vector: [0.05, 0.61, 0.76, 0.44], payload: { name: "cat" } },
                        { id: 2, vector: [0.19, 0.33, 0.55, 0.77], payload: { name: "dog" } },
                        { id: 3, vector: [0.90, 0.10, 0.20, 0.30], payload: { name: "car" } }
                    ] })
            }
            Button {
                text: "④ 相似检索"
                highlighted: true
                onClicked: root.call("相似检索 POST /points/query",
                    "POST", "/collections/" + root.collection + "/points/query",
                    { query: [0.10, 0.60, 0.70, 0.40], limit: 3, with_payload: true })
            }
            Button {
                text: "⑤ 删除集合"
                onClicked: root.call("删除集合 DELETE /collections/" + root.collection,
                    "DELETE", "/collections/" + root.collection)
            }
        }

        Label {
            text: "响应（QML 调用方式同 ApiPage：ApiClient.put(url, body, callback)）"
            font.bold: true
            font.pixelSize: 13
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }
        TextArea {
            id: responseArea
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
