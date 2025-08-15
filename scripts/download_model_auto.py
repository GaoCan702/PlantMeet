#!/usr/bin/env python3
"""
自动模型下载脚本 - 用于 debug 阶段预下载模型到 assets

使用方法:
python3 scripts/download_model_auto.py
"""

import os
import sys
import requests
from pathlib import Path

# 模型配置
MODEL_URL = "https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task"
MODEL_FILENAME = "gemma-3n-E4B-it-int4.task"
EXPECTED_SIZE = 4405655031  # 约 4.1GB

# HuggingFace Token
HF_TOKEN = 'your_hf_token_here'

def get_project_root() -> Path:
    """获取项目根目录"""
    script_dir = Path(__file__).parent
    return script_dir.parent

def get_assets_model_dir() -> Path:
    """获取 assets/models 目录"""
    return get_project_root() / "assets" / "models"

def format_size(size_bytes: int) -> str:
    """格式化文件大小"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} TB"

def check_existing_file(file_path: Path) -> bool:
    """检查已存在的文件是否完整"""
    if not file_path.exists():
        return False
    
    file_size = file_path.stat().st_size
    print(f"发现已存在文件: {file_path}")
    print(f"文件大小: {format_size(file_size)}")
    
    if file_size == EXPECTED_SIZE:
        print("✅ 文件大小匹配，跳过下载")
        return True
    else:
        print(f"⚠️  文件大小不匹配 (期望: {format_size(EXPECTED_SIZE)})")
        return False

def download_model(url: str, output_path: Path, token: str) -> bool:
    """下载模型文件"""
    headers = {
        'User-Agent': 'PlantMeet/1.0 Model Downloader',
        'Authorization': f'Bearer {token}'
    }
    
    print(f"开始下载模型:")
    print(f"URL: {url}")
    print(f"目标: {output_path}")
    
    try:
        # 检查远程文件信息
        print("\n检查远程文件信息...")
        head_response = requests.head(url, headers=headers, timeout=30)
        head_response.raise_for_status()
        
        remote_size = int(head_response.headers.get('content-length', 0))
        print(f"远程文件大小: {format_size(remote_size)}")
        
        # 检查断点续传
        downloaded_size = 0
        mode = 'wb'
        
        if output_path.exists():
            downloaded_size = output_path.stat().st_size
            if downloaded_size > 0 and downloaded_size < remote_size:
                print(f"检测到部分下载文件 ({format_size(downloaded_size)})，将续传")
                headers['Range'] = f'bytes={downloaded_size}-'
                mode = 'ab'
            elif downloaded_size >= remote_size:
                print("✅ 文件已完整下载")
                return True
        
        # 开始下载
        print(f"\n开始下载... (从 {format_size(downloaded_size)} 处继续)")
        response = requests.get(url, headers=headers, stream=True, timeout=30)
        response.raise_for_status()
        
        # 创建目录
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        total_size = downloaded_size + int(response.headers.get('content-length', 0))
        
        with open(output_path, mode) as f:
            received = downloaded_size
            chunk_size = 1024 * 1024  # 1MB chunks for faster download
            progress_counter = 0
            
            for chunk in response.iter_content(chunk_size=chunk_size):
                if chunk:
                    f.write(chunk)
                    received += len(chunk)
                    progress_counter += 1
                    
                    # 每 10MB 显示一次进度
                    if progress_counter % 10 == 0:
                        if total_size > 0:
                            progress = (received / total_size) * 100
                            print(f"下载进度: {progress:.1f}% ({format_size(received)}/{format_size(total_size)})")
        
        print(f"\n✅ 下载完成! 文件大小: {format_size(received)}")
        return True
        
    except requests.RequestException as e:
        print(f"❌ 下载失败: {e}")
        return False
    except Exception as e:
        print(f"❌ 未知错误: {e}")
        return False

def main():
    """主函数"""
    print("=== PlantMeet 自动模型下载器 ===")
    print("用于 debug 阶段预下载模型到 assets 目录\n")
    
    # 检查项目结构
    project_root = get_project_root()
    assets_dir = get_assets_model_dir()
    
    print(f"项目根目录: {project_root}")
    print(f"目标目录: {assets_dir}")
    
    # 确保 assets/models 目录存在
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    # 目标文件路径
    model_path = assets_dir / MODEL_FILENAME
    
    # 检查已存在文件
    if check_existing_file(model_path):
        print("\n✅ 模型文件已存在且完整，无需下载")
        return
    
    # 显示下载信息
    print(f"\n开始自动下载模型文件:")
    print(f"- 文件: {MODEL_FILENAME}")
    print(f"- 大小: {format_size(EXPECTED_SIZE)}")
    print(f"- 保存: {model_path}")
    
    # 下载模型
    success = download_model(MODEL_URL, model_path, HF_TOKEN)
    
    if success:
        print(f"\n🎉 模型下载成功!")
        print(f"文件位置: {model_path}")
        print(f"\n下次编译应用时，模型将自动从 assets 加载，无需重新下载。")
        print(f"\n⚠️  发布生产版本时，请在 pubspec.yaml 中注释掉 assets/models/ 行以减小安装包大小。")
    else:
        print("\n❌ 模型下载失败")
        sys.exit(1)

if __name__ == "__main__":
    main()