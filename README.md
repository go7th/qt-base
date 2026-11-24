# Qt 应用底座（Qt 6 + QML）

一个可直接二次开发的 Qt 6 / QML 桌面应用底座：**分层架构 + 常用能力开箱即用**。
包含登录/登出、串口助手、REST 接口调试、多线程、MySQL / Redis / Qdrant 连接等页面，
后续项目可直接基于本底座扩展。

## 功能

- **登录 / 登出**：含 Qt 虚拟键盘（InputPanel）用法
- **串口助手**：QSerialPort 枚举 / 打开关闭 / 文本与 HEX 收发
- **项目列表 / 详情**：对接 ServiceMonitor REST API（`/api/projects`），组件状态、启停控制
- **HTTP 接口调试**：ApiClient 封装 GET / POST / PUT / DELETE，QML 回调式调用
- **多线程**：QThread 任务（进度/取消）+ QtConcurrent 并行计算；附协程（QCoro）说明
- **数据库**：MySQL（QtSql / QMYSQL）、Redis（原生 RESP 协议，无第三方库）、Qdrant 向量库（REST API）
- **深 / 浅色双主题**：全部颜色走设计令牌（`qml/config/Theme.qml`）

## 技术栈

- Qt 6.12（Quick、Qml、Network、Sql、SerialPort、Concurrent、VirtualKeyboard）
- CMake ≥ 3.16、C++17
- macOS 验证；Linux / Windows 可移植（字体会自动回退）

## 目录结构（分层）

```
test1/
├── CMakeLists.txt
├── src/                        # C++ 源码
│   ├── main.cpp                # 入口：注册后端单例、加载 QML 模块
│   ├── interface/              # 接口层 —— 与外部系统通信
│   │   ├── apiclient.h/.cpp        # HTTP REST（QNetworkAccessManager）
│   │   ├── dbbridge.h/.cpp         # MySQL（QtSql / QMYSQL）
│   │   ├── redisclient.h/.cpp      # Redis（RESP over QTcpSocket）
│   │   └── serialbridge.h/.cpp     # 串口（QSerialPort）
│   └── model/                  # 模型层 —— 任务与数据处理
│       └── taskworker.h/.cpp       # QThread 任务 + QtConcurrent 并行
└── qml/                        # QML 界面（模块 URI：test1）
    ├── Main.qml                # 主窗口 + 侧边导航框架 + 虚拟键盘
    ├── config/                 # 配置层 —— 单例
    │   ├── Theme.qml               # 设计令牌：配色 / 字体 / 圆角
    │   └── AppConfig.qml           # 本地服务默认地址与端口
    ├── components/             # 组件层 —— 可复用控件
    │   └── ProjectCard.qml         # 项目卡片（状态徽章 / 交错入场动画）
    └── pages/                  # 页面层
        ├── LoginPage.qml           # 登录
        ├── SerialPage.qml          # 串口助手
        ├── ProjectListPage.qml     # 项目列表
        ├── ProjectDetailPage.qml   # 项目详情
        ├── ApiPage.qml             # HTTP 接口调试
        ├── ThreadPage.qml          # 多线程 / 协程
        ├── DatabasePage.qml        # MySQL
        ├── RedisPage.qml           # Redis
        └── VectorPage.qml          # Qdrant 向量库
```

| 分层 | 位置 | 职责 |
| --- | --- | --- |
| 接口层 | `src/interface/` | 封装 HTTP / MySQL / Redis / 串口等外部通信，暴露 Q_INVOKABLE 给 QML |
| 模型层 | `src/model/` | 任务调度、多线程、数据加工 |
| 配置层 | `qml/config/` | 设计令牌（Theme）、服务默认配置（AppConfig），全局单例 |
| 组件层 | `qml/components/` | 可复用 UI 控件 |
| 页面层 | `qml/pages/` | 各功能页面，通过 `Main.qml` 导航框架加载 |

## 快速开始

### Qt Creator

打开 `CMakeLists.txt` → 选择 Qt 6.12 kit → 构建运行。

### 命令行

```bash
cmake -B build -DCMAKE_PREFIX_PATH=~/Qt/6.12.0/macos
cmake --build build
./build/apptest1            # Windows: build\Debug\apptest1.exe
```

## QMYSQL 驱动（必须手动编译一次）

Qt 官方安装包**不带** QMYSQL 插件，MySQL 页面需要它。步骤概要：

1. 安装 MySQL 客户端库（macOS：`brew install mysql-client`）
2. 从 [qtbase 源码](https://github.com/qt/qtbase)（tag 与 Qt 版本一致）取
   `src/plugins/sqldrivers/mysql/` 四个文件，用 CMake 针对已安装的 Qt 编译
3. 产物 `libqsqlmysql.dylib`（Linux 为 `.so`）拷入
   `<Qt>/6.12.0/<platform>/plugins/sqldrivers/`

> 注意：**Qt 升级后需重新编译安装**。另外 libmysqlclient 遇 host `localhost`
> 会走 unix socket，连 Docker 容器时请用 `127.0.0.1`（本底座 `dbbridge.cpp` 已自动处理）。

## 本地依赖服务（可选，Docker）

MySQL / Redis / Qdrant 可用 Docker 一键启动（连接参数见 `qml/config/AppConfig.qml`）：

```bash
docker run -d --name qt-demo-mysql  -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -e MYSQL_DATABASE=demo mysql:8.4
docker run -d --name qt-demo-redis  -p 6379:6379 redis:7-alpine
docker run -d --name qt-demo-qdrant -p 6333:6333 -p 6334:6334 qdrant/qdrant
```

项目列表 / 详情页还依赖 ServiceMonitor（默认 `http://localhost:7788`）。

## 测试

`../smoketest/` 内含两个目标：

```bash
cd ../smoketest && cmake -B build -DCMAKE_PREFIX_PATH=~/Qt/6.12.0/macos && cmake --build build
QT_QPA_PLATFORM=offscreen ./build/smoke   # 离屏逐页加载全部 QML，捕获错误
./build/integration                        # 对真实 MySQL/Redis 做读写验证
```

## 二次开发指南

- **新增接口**：在 `src/interface/` 加类 → `main.cpp` 里
  `qmlRegisterSingletonInstance("App.Backend", 1, 0, "Name", &obj)` → QML 中
  `import App.Backend 1.0` 后直接用（同步改 `smoketest/smoke.cpp` 的注册）
- **新增页面**：`qml/pages/` 加文件 → `CMakeLists.txt` 的 `QML_FILES` 加一行 →
  `Main.qml` 的 `navItems` 加条目（`StackView` 加载）
- **新增组件**：`qml/components/` 加文件 → `QML_FILES` 加一行 → 页面里
  `import test1 1.0` 后按类型名使用
- **改主题**：只改 `qml/config/Theme.qml`，页面不要写死颜色

## 实践要点（踩坑记录）

- `StackView.view` 在**嵌套 delegate/按钮里解析为 null**，需在页面根捕获：
  `property var stackView: StackView.view`，嵌套处用 `root.stackView.push(...)`
- **`Component {}` 内解析不到 delegate 的 id**（如 `delegate: Loader { id: rowLoader }` 里的
  `rowLoader`），运行时 ReferenceError 且被静默吞掉。数据传递用 delegate 作用域的
  `onLoaded: item.xxx = xxx` 命令式赋值，事件用 `item.signal.connect(function(){...})` 闭包
- QML 单例：`set_source_files_properties(... QT_QML_SINGLETON_TYPE TRUE)` 必须放在
  `qt_add_qml_module` **之前**，且模块要声明 `VERSION 1.0`
- 同模块 QML 互相引用类型需要显式 `import test1 1.0`（隐式解析不可用）
