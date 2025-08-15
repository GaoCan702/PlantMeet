#!/bin/bash
# PlantMeet 日志监控启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== PlantMeet 日志监控 ==="
echo "项目目录: $PROJECT_ROOT"

# 切换到项目目录
cd "$PROJECT_ROOT"

# 创建日志目录
mkdir -p logs

# 检查ADB连接
echo "检查ADB连接..."
if ! python3 scripts/monitor_logs.py --check-only; then
    echo "❌ ADB连接检查失败"
    exit 1
fi

echo ""
echo "🎯 即将开始监控 PlantMeet 应用日志"
echo "  - 包名: com.arousedata.plantmeet"
echo "  - 日志文件: logs/app_monitor.log"
echo "  - 级别: 所有日志 (V)"
echo "  - 模式: 实时错误检测"
echo ""
echo "💡 使用提示:"
echo "  - 错误日志会实时显示在终端"
echo "  - 所有日志会保存到文件"
echo "  - 按 Ctrl+C 停止监控"
echo ""

# 等待用户确认
read -p "按 Enter 开始监控，或 Ctrl+C 取消: "

echo ""
echo "🚀 开始监控..."
echo ""

# 启动监控
python3 scripts/monitor_logs.py \
    --package com.arousedata.plantmeet \
    --output logs/app_monitor.log \
    --level V