pragma Singleton
import QtQuick

// 配置层 · 设计令牌：全局配色 / 字体 / 圆角，深浅色双主题
// 页面里不要写死颜色，统一引用 Theme.xxx
QtObject {
    id: theme

    readonly property bool lightMode: Application.styleHints.colorScheme === Qt.Light

    // —— 深色主题 ——
    readonly property color reallyDark: "#1f1f1f"   // 侧栏 / 最深面板
    readonly property color dark: "#262626"         // 页面底
    readonly property color panel: "#1a1a1a"        // 卡片 / 输入框
    readonly property color groupDark: "#333333"    // 分组条
    readonly property color borderDark: "#444444"
    readonly property color dimDark: "#aaaaaa"
    readonly property color mutedDark: "#999999"

    // —— 浅色主题 ——
    readonly property color reallyLight: "#e7e7e7"
    readonly property color light: "#e0e0e0"
    readonly property color cardLight: "#ffffff"
    readonly property color groupLight: "#d0d0d0"
    readonly property color borderLight: "#cccccc"
    readonly property color dimLight: "#555555"
    readonly property color mutedLight: "#666666"

    // —— 强调与状态 ——
    readonly property color accent: "#4a90d9"
    readonly property color accentWarm: "#f2a33c"   // 运维控制台主强调（琥珀）
    readonly property color ok: "#2ecc71"
    readonly property color err: "#e06c75"
    readonly property color okBg: Qt.rgba(0.18, 0.76, 0.44, 0.16)
    readonly property color errBg: Qt.rgba(0.88, 0.42, 0.45, 0.16)
    readonly property color warnBg: Qt.rgba(0.95, 0.64, 0.24, 0.16)

    // —— 字体（macOS 原生组合；其他平台自动回退）——
    readonly property string monoFont: "Menlo"        // 数字 / 代码 / 状态
    readonly property string uiFont: "PingFang SC"    // 界面文字

    // —— 圆角 ——
    readonly property int radiusCard: 10
    readonly property int radiusSm: 6
}
