import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import test1 1.0

import App.Backend 1.0

// 多线程 / 协程：
//  1) QThread 常驻工作线程（进度 + 取消）
//  2) QtConcurrent 线程池并行计算
//  Qt/QML 本身没有协程；异步靠信号槽 + 回调，C++20 协程需配合 QCoro 库
Rectangle {
    id: root
    property bool lightMode: Theme.lightMode
    color: lightMode ? Theme.light : Theme.dark

    property int progressValue: 0
    property bool running: false

    function appendLog(line) {
        logArea.append("[" + Qt.formatTime(new Date(), "hh:mm:ss.zzz") + "] " + line)
    }

    Connections {
        target: Tasks
        function onTaskProgress(name, percent) {
            root.progressValue = percent
        }
        function onTaskLog(name, msg) {
            root.appendLog(msg)
        }
        function onTaskFinished(name, result) {
            root.appendLog("任务结束：" + result)
            root.running = false
        }
        function onParallelLog(msg) {
            root.appendLog(msg)
        }
        function onParallelFinished(count, elapsedMs, threads) {
            root.appendLog("并行计算完成：素数 " + count + " 个，耗时 " + elapsedMs
                           + " ms（" + threads + " 线程）")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "多线程 / 协程"
            font.pixelSize: 20
            font.bold: true
            color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
        }

        // 证明 UI 不卡：旋转动画 + 计时器
        RowLayout {
            spacing: 12
            Rectangle {
                width: 28; height: 28; radius: 14
                color: root.accentColor
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: 1200
                }
            }
            Label {
                id: tickLabel
                property int ticks: 0
                text: "UI 心跳：" + ticks + "（任务运行时数字持续走动 = 界面未卡死）"
                font.pixelSize: 12
                color: root.lightMode ? Theme.dimLight : Theme.dimDark
            }
            Timer {
                interval: 100; running: true; repeat: true
                onTriggered: tickLabel.ticks++
            }
        }

        // QThread 任务区
        GroupBox {
            Layout.fillWidth: true
            title: "① QThread 常驻工作线程（进度 / 取消）"
            background: Rectangle {
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
                radius: 6
                color: root.lightMode ? Theme.cardLight : Theme.reallyDark
                border.color: root.lightMode ? Theme.borderLight : Theme.borderDark
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                RowLayout {
                    spacing: 8
                    Button {
                        text: "开始后台任务（100 步 × 80ms）"
                        highlighted: true
                        enabled: !root.running
                        onClicked: {
                            root.running = true
                            root.progressValue = 0
                            Tasks.startTask("task", 100, 80)
                        }
                    }
                    Button {
                        text: "取消"
                        enabled: root.running
                        onClicked: Tasks.cancelTask()
                    }
                    ProgressBar {
                        Layout.preferredWidth: 220
                        from: 0; to: 100
                        value: root.progressValue
                    }
                    Label {
                        text: root.progressValue + "%"
                        font.pixelSize: 12
                        color: root.lightMode ? Theme.reallyDark : Theme.reallyLight
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }

        // QtConcurrent 并行区
        GroupBox {
            Layout.fillWidth: true
            title: "② QtConcurrent 线程池并行计算（素数统计）"
            background: Rectangle {
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
                radius: 6
                color: root.lightMode ? Theme.cardLight : Theme.reallyDark
                border.color: root.lightMode ? Theme.borderLight : Theme.borderDark
            }
            RowLayout {
                spacing: 8
                Button {
                    text: "并行计算 [2, 2000000) 素数个数"
                    highlighted: true
                    onClicked: Tasks.runParallel(2000000)
                }
                Label {
                    text: "按 CPU 核数自动分片，QFutureWatcher 回传结果"
                    font.pixelSize: 12
                    color: root.lightMode ? Theme.dimLight : Theme.dimDark
                }
            }
        }

        // 说明
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            color: root.lightMode ? Theme.dimLight : Theme.dimDark
            text: "③ 关于协程：Qt/QML 没有内置协程。QML 的信号槽 + 回调相当于 async/await 的替代；"
                  + "C++20 协程在 Qt 中需配合第三方 QCoro 库使用。选型建议：常驻后台任务用 QThread，"
                  + "CPU 密集并行计算用 QtConcurrent/线程池，IO 密集网络请求用 QNetworkAccessManager 异步回调。"
        }

        Label {
            text: "日志"
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

    property color accentColor: Theme.accent
}
