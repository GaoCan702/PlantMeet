#!/usr/bin/env python3
"""
简化的文件服务器 - 专为Flutter HTTP客户端优化

使用方法:
python3 scripts/simple_file_server.py [--port PORT]
"""

import os
import sys
import argparse
import socket
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import unquote
import time

class SimpleFileHandler(BaseHTTPRequestHandler):
    """简化的文件处理器，专门处理模型文件下载"""
    
    def __init__(self, *args, model_file_path=None, **kwargs):
        self.model_file_path = model_file_path
        super().__init__(*args, **kwargs)
    
    def log_message(self, format, *args):
        """自定义日志格式"""
        client_ip = self.address_string()
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {client_ip} - {format % args}")
    
    def end_headers(self):
        # 添加CORS头
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Range, Authorization, User-Agent')
        super().end_headers()
    
    def do_OPTIONS(self):
        """处理CORS预检请求"""
        self.send_response(200)
        self.end_headers()
    
    def do_HEAD(self):
        """处理HEAD请求"""
        if self.path == '/gemma-3n-E4B-it-int4.task' and self.model_file_path.exists():
            file_size = self.model_file_path.stat().st_size
            self.send_response(200)
            self.send_header('Content-Length', str(file_size))
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Accept-Ranges', 'bytes')
            self.end_headers()
        else:
            self.send_error(404, "File not found")
    
    def do_GET(self):
        """处理GET请求"""
        if self.path != '/gemma-3n-E4B-it-int4.task':
            self.send_error(404, "File not found")
            return
        
        if not self.model_file_path.exists():
            self.send_error(404, "Model file not found")
            return
        
        try:
            file_size = self.model_file_path.stat().st_size
            range_header = self.headers.get('Range')
            
            if range_header:
                # 处理范围请求
                range_spec = range_header.replace('bytes=', '').strip()
                if '-' in range_spec:
                    start_str, end_str = range_spec.split('-', 1)
                    start = int(start_str) if start_str else 0
                    end = int(end_str) if end_str else file_size - 1
                else:
                    start = int(range_spec)
                    end = file_size - 1
                
                # 确保范围有效
                start = max(0, min(start, file_size - 1))
                end = max(start, min(end, file_size - 1))
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
            self.end_headers()
            
            # 发送文件内容
            with open(self.model_file_path, 'rb') as f:
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
                    except (ConnectionResetError, BrokenPipeError):
                        # 客户端断开连接，正常情况
                        print(f"客户端断开连接，已发送 {content_length - remaining} 字节")
                        break
                        
        except Exception as e:
            print(f"发送文件时出错: {e}")
            if not self.wfile.closed:
                try:
                    self.send_error(500, f"Internal server error")
                except:
                    pass

def get_local_ip():
    """获取本机IP地址"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except:
        return "127.0.0.1"

def main():
    parser = argparse.ArgumentParser(description='简化文件服务器')
    parser.add_argument('--port', type=int, default=8001, help='服务器端口 (默认: 8001)')
    parser.add_argument('--host', default='0.0.0.0', help='绑定主机 (默认: 0.0.0.0)')
    args = parser.parse_args()
    
    # 获取模型文件路径
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    model_file = project_root / 'assets' / 'models' / 'gemma-3n-E4B-it-int4.task'
    
    print("=== PlantMeet 简化文件服务器 ===")
    print(f"模型文件: {model_file}")
    
    # 检查模型文件
    if not model_file.exists():
        print(f"❌ 模型文件不存在: {model_file}")
        print("请先运行: python3 scripts/download_model_auto.py")
        sys.exit(1)
    
    file_size = model_file.stat().st_size
    expected_size = 4405655031
    
    if file_size != expected_size:
        print(f"⚠️  文件大小异常: {file_size} != {expected_size}")
    else:
        print(f"✅ 模型文件检查通过: {file_size/1024/1024/1024:.2f} GB")
    
    # 创建处理器工厂
    def handler_factory(*args, **kwargs):
        return SimpleFileHandler(*args, model_file_path=model_file, **kwargs)
    
    try:
        server = HTTPServer((args.host, args.port), handler_factory)
        local_ip = get_local_ip()
        
        print(f"\n🚀 服务器已启动:")
        print(f"  本地: http://localhost:{args.port}")
        print(f"  网络: http://{local_ip}:{args.port}")
        print(f"\n📱 编译命令:")
        print(f"flutter build apk --debug \\")
        print(f"  --dart-define=LOCAL_MODEL_SERVER=http://{local_ip}:{args.port} \\")
        print(f"  --dart-define=HF_ACCESS_TOKEN=your_hf_token_here")
        print(f"\n按 Ctrl+C 停止服务器")
        print("-" * 50)
        
        server.serve_forever()
        
    except KeyboardInterrupt:
        print("\n\n🛑 服务器已停止")
    except OSError as e:
        if e.errno == 48:
            print(f"❌ 端口 {args.port} 已被占用")
            print(f"尝试其他端口: python3 scripts/simple_file_server.py --port {args.port + 1}")
        else:
            print(f"❌ 启动失败: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 未知错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()