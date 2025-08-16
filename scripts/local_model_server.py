#!/usr/bin/env python3
"""
本地模型文件服务器 - 用于开发调试阶段

提供本地HTTP服务器托管模型文件，避免重复从HuggingFace下载。

使用方法:
python3 scripts/local_model_server.py [--port PORT] [--host HOST]

然后在编译应用时使用:
flutter build apk --debug --dart-define=LOCAL_MODEL_SERVER=http://localhost:8000
"""

import os
import sys
import argparse
import socket
import subprocess
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler
import threading
import time

class ModelFileHandler(SimpleHTTPRequestHandler):
    """自定义文件处理器，支持断点续传和CORS"""
    
    def __init__(self, *args, model_dir=None, **kwargs):
        self.model_dir = model_dir
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """处理GET请求"""
        # 仅处理模型文件请求
        if self.path.startswith('/gemma-3n-E4B-it-int4.task'):
            model_file = self.model_dir / 'gemma-3n-E4B-it-int4.task'
            if model_file.exists():
                self.serve_model_file(model_file)
            else:
                self.send_error(404, "Model file not found")
        else:
            self.send_error(404, "File not found")
    
    def do_HEAD(self):
        """处理HEAD请求（用于获取文件信息）"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        
        model_file = self.model_dir / 'gemma-3n-E4B-it-int4.task'
        if model_file.exists():
            file_size = model_file.stat().st_size
            self.send_header('Content-Length', str(file_size))
            self.send_header('Accept-Ranges', 'bytes')
        
        self.send_header('Content-Type', 'application/octet-stream')
        self.end_headers()
    
    def do_OPTIONS(self):
        """处理OPTIONS请求（CORS预检）"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Range, Authorization, User-Agent')
        self.end_headers()
    
    def serve_model_file(self, file_path):
        """提供模型文件，支持断点续传"""
        try:
            file_size = file_path.stat().st_size
            range_header = self.headers.get('Range')
            
            if range_header:
                # 处理范围请求（断点续传）
                range_match = range_header.replace('bytes=', '').split('-')
                start = int(range_match[0]) if range_match[0] else 0
                end = int(range_match[1]) if range_match[1] else file_size - 1
                
                content_length = end - start + 1
                
                self.send_response(206)  # Partial Content
                self.send_header('Content-Range', f'bytes {start}-{end}/{file_size}')
                self.send_header('Content-Length', str(content_length))
            else:
                # 完整文件请求
                start = 0
                end = file_size - 1
                content_length = file_size
                
                self.send_response(200)
                self.send_header('Content-Length', str(content_length))
            
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Cache-Control', 'public, max-age=3600')
            # 添加CORS头
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Range, Authorization, User-Agent')
            self.end_headers()
            
            # 发送文件内容
            with open(file_path, 'rb') as f:
                f.seek(start)
                remaining = content_length
                
                while remaining > 0:
                    chunk_size = min(65536, remaining)  # 64KB chunks
                    chunk = f.read(chunk_size)
                    if not chunk:
                        break
                    
                    try:
                        self.wfile.write(chunk)
                        remaining -= len(chunk)
                    except (BrokenPipeError, ConnectionResetError):
                        # 客户端断开连接，正常情况，不需要记录错误
                        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Client disconnected during download")
                        break
                    
        except (BrokenPipeError, ConnectionResetError):
            # 客户端断开连接，正常情况
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Client disconnected")
        except Exception as e:
            print(f"Error serving file: {e}")
            try:
                self.send_error(500, f"Internal server error: {e}")
            except (BrokenPipeError, ConnectionResetError):
                # 发送错误响应时客户端已断开
                pass
    
    def log_message(self, format, *args):
        """自定义日志格式"""
        client_ip = self.address_string()
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {client_ip} - {format % args}")

def kill_port_process(port):
    """杀掉占用指定端口的进程"""
    try:
        # 查找占用端口的进程
        result = subprocess.run(['lsof', '-ti', f':{port}'], 
                              capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                if pid:
                    print(f"🔥 正在终止占用端口 {port} 的进程 PID: {pid}")
                    subprocess.run(['kill', '-9', pid], capture_output=True)
            return True
    except Exception as e:
        print(f"清理端口 {port} 时出错: {e}")
    return False

def get_local_ip():
    """获取本机IP地址"""
    try:
        # 连接到外部地址来获取本机IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except:
        return "127.0.0.1"

def check_model_file(model_dir):
    """检查模型文件是否存在"""
    model_file = model_dir / 'gemma-3n-E4B-it-int4.task'
    if not model_file.exists():
        print(f"❌ 模型文件不存在: {model_file}")
        print("请先运行下载脚本:")
        print("python3 scripts/download_model_auto.py")
        return False
    
    file_size = model_file.stat().st_size
    expected_size = 4405655031  # 约4.1GB
    
    if file_size != expected_size:
        print(f"⚠️  模型文件大小异常:")
        print(f"  实际: {file_size:,} bytes ({file_size/1024/1024/1024:.2f} GB)")
        print(f"  期望: {expected_size:,} bytes ({expected_size/1024/1024/1024:.2f} GB)")
        return False
    
    print(f"✅ 模型文件检查通过: {file_size/1024/1024/1024:.2f} GB")
    return True

def main():
    parser = argparse.ArgumentParser(description='本地模型文件服务器')
    parser.add_argument('--port', type=int, default=8001, help='服务器端口 (默认: 8001)')
    parser.add_argument('--host', default='0.0.0.0', help='绑定主机 (默认: 0.0.0.0)')
    args = parser.parse_args()
    
    # 获取项目目录
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    model_dir = project_root / 'assets' / 'models'
    
    print("=== PlantMeet 本地模型服务器 ===")
    print(f"项目目录: {project_root}")
    print(f"模型目录: {model_dir}")
    
    # 检查模型文件
    if not check_model_file(model_dir):
        sys.exit(1)
    
    # 如果端口被占用，自动清理
    print(f"🔍 检查端口 {args.port} 是否被占用...")
    if kill_port_process(args.port):
        print(f"✅ 端口 {args.port} 已清理")
        time.sleep(1)  # 等待进程完全退出
    
    # 创建服务器
    def handler_factory(*args, **kwargs):
        return ModelFileHandler(*args, model_dir=model_dir, **kwargs)
    
    try:
        server = HTTPServer((args.host, args.port), handler_factory)
        
        local_ip = get_local_ip()
        print(f"\n🚀 服务器已启动:")
        print(f"  本地访问: http://localhost:{args.port}")
        print(f"  网络访问: http://{local_ip}:{args.port}")
        print(f"\n📱 编译应用时使用:")
        print(f"  flutter build apk --debug --dart-define=LOCAL_MODEL_SERVER=http://{local_ip}:{args.port}")
        print(f"\n📄 模型文件URL:")
        print(f"  http://{local_ip}:{args.port}/gemma-3n-E4B-it-int4.task")
        
        print(f"\n按 Ctrl+C 停止服务器")
        print("-" * 50)
        
        server.serve_forever()
        
    except KeyboardInterrupt:
        print("\n\n🛑 服务器已停止")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ 端口 {args.port} 已被占用，请尝试其他端口:")
            print(f"python3 scripts/local_model_server.py --port {args.port + 1}")
        else:
            print(f"❌ 启动服务器失败: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 未知错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()