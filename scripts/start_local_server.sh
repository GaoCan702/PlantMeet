#!/bin/bash
# PlantMeet 本地模型服务器启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== PlantMeet 本地模型服务器 ==="
echo "项目目录: $PROJECT_ROOT"

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到 python3，请先安装 Python 3"
    exit 1
fi

# 检查模型文件
MODEL_FILE="$PROJECT_ROOT/assets/models/gemma-3n-E4B-it-int4.task"
if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ 模型文件不存在: $MODEL_FILE"
    echo ""
    echo "请先下载模型文件:"
    echo "python3 scripts/download_model_auto.py"
    exit 1
fi

# 获取文件大小
FILE_SIZE=$(stat -f%z "$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_FILE" 2>/dev/null)
EXPECTED_SIZE=4405655031

if [ "$FILE_SIZE" -ne "$EXPECTED_SIZE" ]; then
    echo "⚠️  模型文件大小异常:"
    echo "  实际: $FILE_SIZE bytes"
    echo "  期望: $EXPECTED_SIZE bytes"
    echo ""
    echo "请重新下载模型文件:"
    echo "python3 scripts/download_model_auto.py"
    exit 1
fi

echo "✅ 模型文件检查通过"

# 设置默认端口
PORT=${1:-8000}

# 检查端口是否被占用，如果被占用则杀掉进程
if lsof -ti:$PORT > /dev/null 2>&1; then
    echo "⚠️  端口 $PORT 被占用，正在终止占用进程..."
    # 获取占用端口的进程信息
    PROCESS_INFO=$(lsof -ti:$PORT | head -1)
    if [ -n "$PROCESS_INFO" ]; then
        echo "终止进程 PID: $PROCESS_INFO"
        kill -9 $PROCESS_INFO 2>/dev/null || true
        sleep 1
        
        # 再次检查端口是否被释放
        if lsof -ti:$PORT > /dev/null 2>&1; then
            echo "❌ 无法释放端口 $PORT，请手动检查占用进程"
            echo "使用命令: lsof -i:$PORT"
            exit 1
        else
            echo "✅ 端口 $PORT 已释放"
        fi
    fi
fi

# 启动服务器
echo ""
echo "🚀 启动本地模型服务器 (端口: $PORT)..."
echo "按 Ctrl+C 停止服务器"
echo ""

cd "$PROJECT_ROOT"
python3 scripts/local_model_server.py --port "$PORT"