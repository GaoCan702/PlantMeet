#!/usr/bin/env python3
"""
检查日志监控状态和统计信息

使用方法:
python3 scripts/check_monitor.py [--log-file LOG_FILE] [--tail LINES]
"""

import argparse
import os
import sys
from pathlib import Path
from datetime import datetime
import subprocess
import re

def format_time_ago(timestamp):
    """格式化时间差"""
    now = datetime.now()
    diff = now - timestamp
    
    if diff.days > 0:
        return f"{diff.days}天前"
    elif diff.seconds > 3600:
        hours = diff.seconds // 3600
        return f"{hours}小时前"
    elif diff.seconds > 60:
        minutes = diff.seconds // 60
        return f"{minutes}分钟前"
    else:
        return f"{diff.seconds}秒前"

def parse_log_timestamp(line):
    """解析日志时间戳"""
    try:
        timestamp_str = line.split(' ')[0] + ' ' + line.split(' ')[1]
        return datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S.%f')
    except:
        return None

def analyze_log_file(log_file_path):
    """分析日志文件"""
    log_file = Path(log_file_path)
    
    if not log_file.exists():
        print(f"❌ 日志文件不存在: {log_file}")
        return None
    
    stats = {
        'total_lines': 0,
        'error_lines': 0,
        'info_lines': 0,
        'start_time': None,
        'last_time': None,
        'last_error_time': None,
        'file_size': log_file.stat().st_size,
        'recent_errors': []
    }
    
    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                stats['total_lines'] += 1
                timestamp = parse_log_timestamp(line)
                
                if timestamp:
                    if not stats['start_time']:
                        stats['start_time'] = timestamp
                    stats['last_time'] = timestamp
                
                if '[ERROR]' in line:
                    stats['error_lines'] += 1
                    if timestamp:
                        stats['last_error_time'] = timestamp
                    # 保存最近的错误
                    if len(stats['recent_errors']) < 5:
                        stats['recent_errors'].append(line)
                    else:
                        stats['recent_errors'] = stats['recent_errors'][1:] + [line]
                elif '[INFO]' in line:
                    stats['info_lines'] += 1
    
    except Exception as e:
        print(f"❌ 读取日志文件失败: {e}")
        return None
    
    return stats

def check_monitor_process():
    """检查监控进程是否运行"""
    try:
        result = subprocess.run(['pgrep', '-f', 'monitor_logs.py'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            pids = result.stdout.strip().split('\n')
            return [pid for pid in pids if pid]
        return []
    except:
        return []

def format_file_size(size_bytes):
    """格式化文件大小"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} TB"

def main():
    parser = argparse.ArgumentParser(description='检查日志监控状态')
    parser.add_argument('--log-file', '-f', 
                       default='logs/app_monitor.log',
                       help='日志文件路径 (默认: logs/app_monitor.log)')
    parser.add_argument('--tail', '-t', type=int, default=10,
                       help='显示最后几行日志 (默认: 10)')
    parser.add_argument('--errors-only', action='store_true',
                       help='仅显示错误日志')
    
    args = parser.parse_args()
    
    print("=== PlantMeet 日志监控状态 ===")
    
    # 检查监控进程
    pids = check_monitor_process()
    if pids:
        print(f"✅ 监控进程运行中 (PID: {', '.join(pids)})")
    else:
        print("❌ 监控进程未运行")
        print("启动监控: python3 scripts/monitor_logs.py --auto-start")
    
    print()
    
    # 分析日志文件
    stats = analyze_log_file(args.log_file)
    if not stats:
        return
    
    print(f"📊 日志文件统计: {args.log_file}")
    print(f"  文件大小: {format_file_size(stats['file_size'])}")
    print(f"  总行数: {stats['total_lines']}")
    print(f"  错误行数: {stats['error_lines']}")
    print(f"  信息行数: {stats['info_lines']}")
    
    if stats['start_time']:
        print(f"  开始时间: {stats['start_time'].strftime('%Y-%m-%d %H:%M:%S')}")
    
    if stats['last_time']:
        print(f"  最后更新: {stats['last_time'].strftime('%Y-%m-%d %H:%M:%S')} ({format_time_ago(stats['last_time'])})")
    
    if stats['last_error_time']:
        print(f"  最后错误: {stats['last_error_time'].strftime('%Y-%m-%d %H:%M:%S')} ({format_time_ago(stats['last_error_time'])})")
    else:
        print("  最后错误: 无")
    
    # 显示运行时间
    if stats['start_time'] and stats['last_time']:
        duration = stats['last_time'] - stats['start_time']
        print(f"  运行时长: {duration}")
    
    print()
    
    # 显示最近的错误
    if stats['recent_errors']:
        print("🔴 最近的错误:")
        for i, error in enumerate(stats['recent_errors'], 1):
            print(f"  {i}. {error}")
        print()
    
    # 显示最后几行日志
    print(f"📝 最后 {args.tail} 行日志:")
    try:
        with open(args.log_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        start_idx = max(0, len(lines) - args.tail)
        recent_lines = lines[start_idx:]
        
        for line in recent_lines:
            line = line.strip()
            if not line:
                continue
            
            if args.errors_only and '[ERROR]' not in line:
                continue
            
            # 彩色输出
            if '[ERROR]' in line:
                print(f"  🔴 {line}")
            elif '[INFO]' in line:
                print(f"  ℹ️  {line}")
            else:
                print(f"     {line}")
    
    except Exception as e:
        print(f"❌ 读取日志失败: {e}")
    
    print()
    print("💡 实时监控: tail -f logs/app_monitor.log")
    print("💡 仅看错误: grep '\\[ERROR\\]' logs/app_monitor.log")

if __name__ == "__main__":
    main()