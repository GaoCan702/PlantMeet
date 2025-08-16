#!/bin/bash

# PlantMeet 开发阶段自动部署脚本
# 功能：启动文件服务器 -> 获取IP -> 编译 -> 安装到手机

set -e  # 遇到错误立即退出

echo "🚀 PlantMeet 开发部署脚本"
echo "=========================="

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# 1. 停止可能存在的服务器进程
echo "🛑 清理旧的服务器进程..."
lsof -ti:8001 | xargs -r kill -9 2>/dev/null || true

# 2. 启动文件服务器（后台）
echo "🌐 启动本地模型文件服务器..."
cd scripts
python3 local_model_server.py &
SERVER_PID=$!
cd ..

# 等待服务器启动
sleep 3

# 3. 获取本机IP地址
LOCAL_IP=$(python3 -c "
import socket
try:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.connect(('8.8.8.8', 80))
        print(s.getsockname()[0])
except:
    print('127.0.0.1')
")

LOCAL_MODEL_SERVER="http://${LOCAL_IP}:8001"
echo "📡 检测到本机IP: $LOCAL_IP"
echo "🔗 模型服务器地址: $LOCAL_MODEL_SERVER"

# 4. 测试服务器是否正常
echo "🔍 测试服务器连接..."
if curl -sf "$LOCAL_MODEL_SERVER/gemma-3n-E4B-it-int4.task" --range 0-0 > /dev/null; then
    echo "✅ 服务器连接正常"
else
    echo "❌ 服务器连接失败"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# 5. 编译应用
echo "🔨 编译Flutter应用..."
flutter build apk --debug --dart-define=LOCAL_MODEL_SERVER="$LOCAL_MODEL_SERVER"

# 6. 安装到手机
echo "📱 安装到手机..."
if adb install build/app/outputs/flutter-apk/app-debug.apk; then
    echo "✅ 安装成功！"
    echo ""
    echo "📋 部署信息："
    echo "  • 服务器地址: $LOCAL_MODEL_SERVER"
    echo "  • 服务器进程PID: $SERVER_PID"
    echo "  • APK路径: build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "💡 服务器将在后台继续运行"
    echo "   要停止服务器，运行: kill $SERVER_PID"
    echo "   或者运行: scripts/stop_server.sh"
else
    echo "❌ 安装失败"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# 保存服务器PID到文件，方便后续停止
echo $SERVER_PID > scripts/.server.pid
echo "✨ 部署完成！可以开始测试了"