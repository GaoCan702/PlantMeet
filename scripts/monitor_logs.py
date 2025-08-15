#!/usr/bin/env python3
"""
PlantMeet 日志监控脚本

持续监控应用日志，自动捕获和保存错误信息到文件

使用方法:
python3 scripts/monitor_logs.py [--package PACKAGE] [--output OUTPUT] [--level LEVEL]
"""

import os
import sys
import time
import argparse
import subprocess
import threading
from pathlib import Path
from datetime import datetime
import re
import signal

class LogMonitor:
    def __init__(self, package_name, output_file, log_level='V'):
        self.package_name = package_name
        self.output_file = Path(output_file)
        self.log_level = log_level
        self.running = False
        self.process = None
        
        # 确保输出目录存在
        self.output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # 错误关键词匹配
        self.error_patterns = [
            r'FATAL',
            r'ERROR',
            r'Exception',
            r'Error',
            r'failed',
            r'Failed',
            r'Crash',
            r'crash',
            r'ANR',
            r'OutOfMemory',
            r'StackOverflow',
            r'NetworkError',
            r'TimeoutException',
            r'ConnectionError',
            r'HttpException',
            r'ClientException',
            r'SocketException',
            r'FormatException',
            r'StateError',
            r'ArgumentError',
            r'FileSystemException',
            r'PlatformException',
            r'UnimplementedError',
            r'UnsupportedError',
            r'AssertionError',
            r'NoSuchMethodError',
            r'RangeError',
            r'TypeError',
            r'CastError',
            r'NullPointerException',
            r'IllegalArgumentException',
            r'IllegalStateException',
            r'SecurityException',
            r'RuntimeException',
            r'下载失败',
            r'连接失败',
            r'网络错误',
            r'解析错误',
            r'初始化失败',
            r'加载失败'
        ]
        self.error_regex = re.compile('|'.join(self.error_patterns), re.IGNORECASE)
        
        # 统计信息
        self.stats = {
            'total_lines': 0,
            'error_lines': 0,
            'start_time': None,
            'last_error_time': None
        }
    
    def get_timestamp(self):
        """获取格式化时间戳"""
        return datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
    
    def write_log(self, content, is_error=False):
        """写入日志文件"""
        timestamp = self.get_timestamp()
        prefix = "[ERROR]" if is_error else "[INFO]"
        
        try:
            with open(self.output_file, 'a', encoding='utf-8') as f:
                f.write(f"{timestamp} {prefix} {content}\n")
                f.flush()
        except Exception as e:
            print(f"写入日志文件失败: {e}")
    
    def is_error_line(self, line):
        """判断是否为错误行"""
        return bool(self.error_regex.search(line))
    
    def process_log_line(self, line):
        """处理单行日志"""
        line = line.strip()
        if not line:
            return
        
        self.stats['total_lines'] += 1
        is_error = self.is_error_line(line)
        
        if is_error:
            self.stats['error_lines'] += 1
            self.stats['last_error_time'] = datetime.now()
            self.write_log(line, is_error=True)
            print(f"🔴 ERROR: {line}")
        else:
            # 普通日志也记录，但不在控制台显示
            self.write_log(line, is_error=False)
        
        # 每1000行显示一次统计
        if self.stats['total_lines'] % 1000 == 0:
            self.print_stats()
    
    def print_stats(self):
        """打印统计信息"""
        runtime = datetime.now() - self.stats['start_time'] if self.stats['start_time'] else 0
        print(f"\n📊 统计信息 (运行时间: {runtime}):")
        print(f"  总日志行数: {self.stats['total_lines']}")
        print(f"  错误行数: {self.stats['error_lines']}")
        if self.stats['last_error_time']:
            print(f"  最后错误时间: {self.stats['last_error_time'].strftime('%H:%M:%S')}")
        print(f"  日志文件: {self.output_file}")
        print("-" * 50)
    
    def start_monitoring(self):
        """开始监控"""
        print(f"🚀 开始监控应用日志...")
        print(f"  应用包名: {self.package_name}")
        print(f"  日志级别: {self.log_level}")
        print(f"  输出文件: {self.output_file}")
        print(f"  开始时间: {self.get_timestamp()}")
        print("  按 Ctrl+C 停止监控")
        print("=" * 60)
        
        # 写入监控开始标记
        self.write_log(f"=== 日志监控开始 ===")
        self.write_log(f"应用包名: {self.package_name}")
        self.write_log(f"日志级别: {self.log_level}")
        self.write_log(f"监控模式: 实时错误检测")
        
        self.stats['start_time'] = datetime.now()
        self.running = True
        
        try:
            # 清除旧日志缓冲区
            subprocess.run(['adb', 'logcat', '-c'], check=False, 
                         capture_output=True, timeout=5)
            
            # 开始实时监控
            cmd = ['adb', 'logcat', f'*:{self.log_level}']
            if self.package_name != '*':
                # 过滤特定应用（如果指定了包名）
                cmd.extend(['--pid', f"$(adb shell pidof {self.package_name})"])
            
            # 启动logcat进程
            self.process = subprocess.Popen(
                ['adb', 'logcat', f'*:{self.log_level}'],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            # 读取日志行
            for line in iter(self.process.stdout.readline, ''):
                if not self.running:
                    break
                
                # 过滤应用相关日志（如果指定了包名且不是通配符）
                if self.package_name != '*' and self.package_name not in line:
                    continue
                
                self.process_log_line(line)
        
        except KeyboardInterrupt:
            print("\n\n⏹️  收到停止信号")
        except subprocess.TimeoutExpired:
            print("\n⚠️  ADB命令超时")
        except Exception as e:
            print(f"\n❌ 监控过程中出错: {e}")
            self.write_log(f"监控错误: {e}", is_error=True)
        finally:
            self.stop_monitoring()
    
    def stop_monitoring(self):
        """停止监控"""
        self.running = False
        
        if self.process:
            try:
                self.process.terminate()
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
            except:
                pass
        
        # 写入监控结束标记
        self.write_log(f"=== 日志监控结束 ===")
        
        # 显示最终统计
        print("\n📈 最终统计:")
        self.print_stats()
        print(f"\n💾 日志已保存到: {self.output_file.absolute()}")

def signal_handler(signum, frame, monitor):
    """信号处理器"""
    print(f"\n收到信号 {signum}")
    monitor.stop_monitoring()
    sys.exit(0)

def check_adb_connection():
    """检查ADB连接"""
    try:
        result = subprocess.run(['adb', 'devices'], 
                              capture_output=True, text=True, timeout=10)
        
        lines = result.stdout.strip().split('\n')[1:]  # 跳过标题行
        devices = [line for line in lines if line.strip() and 'device' in line]
        
        if not devices:
            print("❌ 未检测到连接的Android设备")
            print("请确保:")
            print("  1. 设备已连接并启用USB调试")
            print("  2. 已授权ADB调试")
            print("  3. 运行 'adb devices' 确认设备状态")
            return False
        
        print(f"✅ 检测到 {len(devices)} 个设备:")
        for device in devices:
            print(f"    {device}")
        return True
        
    except subprocess.TimeoutExpired:
        print("❌ ADB连接超时")
        return False
    except FileNotFoundError:
        print("❌ 未找到ADB工具")
        print("请确保Android SDK已安装并且ADB在PATH中")
        return False
    except Exception as e:
        print(f"❌ 检查ADB连接时出错: {e}")
        return False

def get_app_pid(package_name):
    """获取应用进程ID"""
    if package_name == '*':
        return None
    
    try:
        result = subprocess.run(['adb', 'shell', 'pidof', package_name],
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
        return None
    except:
        return None

def main():
    parser = argparse.ArgumentParser(description='PlantMeet 日志监控工具')
    parser.add_argument('--package', '-p', 
                       default='com.arousedata.plantmeet',
                       help='要监控的应用包名 (默认: com.arousedata.plantmeet, 使用 * 监控所有)')
    parser.add_argument('--output', '-o',
                       default='logs/app_monitor.log',
                       help='输出日志文件路径 (默认: logs/app_monitor.log)')
    parser.add_argument('--level', '-l',
                       choices=['V', 'D', 'I', 'W', 'E', 'F'],
                       default='V',
                       help='日志级别: V(erbose), D(ebug), I(nfo), W(arn), E(rror), F(atal) (默认: V)')
    parser.add_argument('--check-only', action='store_true',
                       help='仅检查ADB连接状态，不开始监控')
    parser.add_argument('--auto-start', action='store_true',
                       help='自动开始监控，不等待用户确认')
    
    args = parser.parse_args()
    
    print("=== PlantMeet 日志监控工具 ===")
    
    # 检查ADB连接
    if not check_adb_connection():
        sys.exit(1)
    
    if args.check_only:
        print("\n✅ ADB连接正常")
        if args.package != '*':
            pid = get_app_pid(args.package)
            if pid:
                print(f"✅ 应用 {args.package} 正在运行 (PID: {pid})")
            else:
                print(f"⚠️  应用 {args.package} 未运行")
        sys.exit(0)
    
    # 检查应用是否运行
    if args.package != '*':
        pid = get_app_pid(args.package)
        if not pid:
            print(f"⚠️  应用 {args.package} 未运行")
            print("建议先启动应用，然后再运行监控")
            
            if not args.auto_start:
                try:
                    response = input("是否继续监控？(y/N): ").strip().lower()
                    if response != 'y':
                        print("取消监控")
                        sys.exit(0)
                except (EOFError, KeyboardInterrupt):
                    print("\n取消监控")
                    sys.exit(0)
            else:
                print("自动开始模式：继续监控")
    
    # 创建监控器
    monitor = LogMonitor(args.package, args.output, args.level)
    
    # 设置信号处理
    signal.signal(signal.SIGINT, lambda s, f: signal_handler(s, f, monitor))
    signal.signal(signal.SIGTERM, lambda s, f: signal_handler(s, f, monitor))
    
    # 开始监控
    try:
        monitor.start_monitoring()
    except Exception as e:
        print(f"❌ 启动监控失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()