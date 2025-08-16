#!/bin/bash

# 停止本地模型文件服务器

echo "🛑 停止本地模型服务器..."

# 从PID文件停止
if [ -f "scripts/.server.pid" ]; then
    SERVER_PID=$(cat scripts/.server.pid)
    if kill $SERVER_PID 2>/dev/null; then
        echo "✅ 已停止服务器进程 PID: $SERVER_PID"
        rm scripts/.server.pid
    else
        echo "⚠️  进程 $SERVER_PID 可能已经停止"
        rm scripts/.server.pid
    fi
fi

# 强制杀掉8001端口的所有进程
lsof -ti:8001 | xargs -r kill -9 2>/dev/null && echo "🔥 已清理8001端口的所有进程" || echo "ℹ️  8001端口无占用进程"

echo "✨ 服务器已停止"