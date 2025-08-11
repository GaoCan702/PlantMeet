#!/usr/bin/env python3
"""
PlantMeet Logo Generator
将SVG logo转换为各种平台所需的PNG图标
"""

import os
import subprocess
from pathlib import Path

# 定义所需的图标尺寸
ICON_SIZES = {
    # Android 图标
    'android': {
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    },
    
    # iOS 图标
    'ios': {
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
    },
    
    # Web 图标  
    'web': {
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
        'web/favicon.png': 32,
    },
    
    # macOS 图标
    'macos': {
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
    }
}

def check_dependencies():
    """检查所需依赖"""
    try:
        # 检查是否安装了cairosvg
        import cairosvg
        return True
    except ImportError:
        print("❌ 缺少依赖: cairosvg")
        print("请运行: pip install cairosvg")
        return False

def convert_svg_to_png_cairosvg(svg_path, png_path, size):
    """使用cairosvg将SVG转换为PNG"""
    try:
        import cairosvg
        
        # 确保输出目录存在
        os.makedirs(os.path.dirname(png_path), exist_ok=True)
        
        # 转换SVG为PNG
        cairosvg.svg2png(
            url=svg_path,
            write_to=png_path,
            output_width=size,
            output_height=size,
        )
        return True
    except Exception as e:
        print(f"❌ 转换失败 {png_path}: {e}")
        return False

def convert_svg_to_png_subprocess(svg_path, png_path, size):
    """使用系统命令转换SVG为PNG"""
    # 确保输出目录存在
    os.makedirs(os.path.dirname(png_path), exist_ok=True)
    
    # 尝试使用不同的工具
    tools = [
        # Inkscape
        ['inkscape', svg_path, '-w', str(size), '-h', str(size), '-o', png_path],
        # ImageMagick
        ['convert', svg_path, '-resize', f'{size}x{size}', png_path],
        # rsvg-convert
        ['rsvg-convert', '-w', str(size), '-h', str(size), svg_path, '-o', png_path]
    ]
    
    for tool in tools:
        try:
            result = subprocess.run(tool, capture_output=True, text=True)
            if result.returncode == 0:
                return True
        except FileNotFoundError:
            continue
    
    return False

def generate_icons(svg_path='logo_simple.svg', project_root='../../'):
    """生成所有图标"""
    svg_file = Path(svg_path)
    if not svg_file.exists():
        print(f"❌ SVG文件不存在: {svg_path}")
        return False
    
    project_path = Path(project_root).resolve()
    success_count = 0
    total_count = 0
    
    print(f"🚀 开始生成图标...")
    print(f"📁 项目路径: {project_path}")
    print(f"🎨 SVG源文件: {svg_file}")
    
    # 首先尝试使用cairosvg
    use_cairosvg = check_dependencies()
    
    for platform, icons in ICON_SIZES.items():
        print(f"\n📱 生成 {platform.upper()} 图标...")
        
        for relative_path, size in icons.items():
            output_path = project_path / relative_path
            total_count += 1
            
            # 选择SVG源文件（小尺寸使用简化版本）
            source_svg = svg_file if size >= 64 else 'logo_simple.svg'
            
            success = False
            if use_cairosvg:
                success = convert_svg_to_png_cairosvg(str(source_svg), str(output_path), size)
            
            if not success:
                success = convert_svg_to_png_subprocess(str(source_svg), str(output_path), size)
            
            if success:
                print(f"  ✅ {size}x{size} -> {relative_path}")
                success_count += 1
            else:
                print(f"  ❌ {size}x{size} -> {relative_path}")
    
    print(f"\n📊 生成完成: {success_count}/{total_count} 成功")
    
    if success_count == 0:
        print("\n💡 提示: 请确保安装以下工具之一:")
        print("  - pip install cairosvg")
        print("  - brew install inkscape (macOS)")
        print("  - sudo apt-get install inkscape (Ubuntu)")
        print("  - brew install imagemagick (macOS)")
        
    return success_count > 0

def main():
    """主函数"""
    print("🌱 PlantMeet Logo Generator")
    print("=" * 40)
    
    # 检查SVG文件
    svg_files = ['logo_base.svg', 'logo_simple.svg']
    available_files = [f for f in svg_files if Path(f).exists()]
    
    if not available_files:
        print("❌ 未找到SVG文件，请确保logo_base.svg或logo_simple.svg存在")
        return
    
    # 使用找到的第一个SVG文件
    svg_file = available_files[0]
    print(f"📁 使用SVG文件: {svg_file}")
    
    # 生成图标
    success = generate_icons(svg_file)
    
    if success:
        print("\n🎉 图标生成完成!")
        print("\n📋 下一步:")
        print("1. 重新构建Flutter应用")
        print("2. 检查各平台图标显示效果")
        print("3. 如需调整，编辑SVG文件后重新运行此脚本")
    else:
        print("\n❌ 图标生成失败，请检查依赖和权限")

if __name__ == "__main__":
    main()