#!/bin/zsh
# test1 Qt 客户端启动脚本（供 ServiceMonitor 进程组件调用）
# 优先使用 Qt Creator 构建产物（每次 Qt Creator 里构建后自动为最新），
# 不存在时退回 build-check（命令行构建产物）。
set -e

QT_CREATOR_BIN="/Users/gowork/Desktop/all/learn/qt/test1/build/Qt_6_12_0_for_macOS_Debug/apptest1.app/Contents/MacOS/apptest1"
BUILD_CHECK_BIN="/Users/gowork/Desktop/all/learn/qt/test1/build-check/apptest1.app/Contents/MacOS/apptest1"

if [ -x "$QT_CREATOR_BIN" ]; then
    echo "[run-app] 使用 Qt Creator 构建: $QT_CREATOR_BIN"
    exec "$QT_CREATOR_BIN" "$@"
elif [ -x "$BUILD_CHECK_BIN" ]; then
    echo "[run-app] 使用 build-check 构建: $BUILD_CHECK_BIN"
    exec "$BUILD_CHECK_BIN" "$@"
else
    echo "[run-app] 找不到可执行文件，请先在 Qt Creator 或 cmake 里构建" >&2
    exit 1
fi
