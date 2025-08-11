# PlantMeet Logo 图标生成指南

## 📋 所需图标规格

### Android 图标 (android/app/src/main/res/)
```
mipmap-mdpi/ic_launcher.png       - 48x48
mipmap-hdpi/ic_launcher.png       - 72x72  
mipmap-xhdpi/ic_launcher.png      - 96x96
mipmap-xxhdpi/ic_launcher.png     - 144x144
mipmap-xxxhdpi/ic_launcher.png    - 192x192
```

### iOS 图标 (ios/Runner/Assets.xcassets/AppIcon.appiconset/)
```
Icon-App-20x20@1x.png    - 20x20
Icon-App-20x20@2x.png    - 40x40
Icon-App-20x20@3x.png    - 60x60
Icon-App-29x29@1x.png    - 29x29
Icon-App-29x29@2x.png    - 58x58
Icon-App-29x29@3x.png    - 87x87
Icon-App-40x40@1x.png    - 40x40
Icon-App-40x40@2x.png    - 80x80
Icon-App-40x40@3x.png    - 120x120
Icon-App-60x60@2x.png    - 120x120
Icon-App-60x60@3x.png    - 180x180
Icon-App-76x76@1x.png    - 76x76
Icon-App-76x76@2x.png    - 152x152
Icon-App-83.5x83.5@2x.png - 167x167
Icon-App-1024x1024@1x.png - 1024x1024
```

### Web 图标 (web/icons/)
```
Icon-192.png             - 192x192
Icon-512.png             - 512x512
Icon-maskable-192.png    - 192x192
Icon-maskable-512.png    - 512x512
```

### macOS 图标 (macos/Runner/Assets.xcassets/AppIcon.appiconset/)
```
app_icon_16.png    - 16x16
app_icon_32.png    - 32x32  
app_icon_64.png    - 64x64
app_icon_128.png   - 128x128
app_icon_256.png   - 256x256
app_icon_512.png   - 512x512
app_icon_1024.png  - 1024x1024
```

## 🛠️ 生成方法

### 方法1: 使用在线工具
1. **App Icon Generator**: https://appicon.co/
   - 上传1024x1024的PNG版本
   - 自动生成所有尺寸

2. **Icon Kitchen**: https://icon.kitchen/
   - Google官方工具，特别适合Android

### 方法2: 使用Flutter工具
1. 安装flutter_launcher_icons包
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

2. 在pubspec.yaml中配置:
```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/logo/logo_1024.png"
```

3. 运行生成命令:
```bash
dart run flutter_launcher_icons:main
```

### 方法3: 使用SVG转PNG工具
1. **Inkscape命令行** (免费):
```bash
# 安装Inkscape后
inkscape logo_base.svg -w 1024 -h 1024 -o logo_1024.png
inkscape logo_base.svg -w 512 -h 512 -o logo_512.png
# ... 其他尺寸
```

2. **ImageMagick**:
```bash
convert logo_base.svg -resize 1024x1024 logo_1024.png
```

3. **在线SVG转PNG**:
   - https://convertio.co/svg-png/
   - https://cloudconvert.com/svg-to-png

## 🎯 推荐流程

1. **使用logo_simple.svg** (小尺寸时更清晰)
2. **先生成1024x1024的高质量PNG**
3. **使用flutter_launcher_icons自动生成所有尺寸**
4. **手动检查小尺寸图标的清晰度**

## 📝 注意事项

- **小尺寸优化**: 16x16和20x20等超小尺寸建议使用logo_simple.svg
- **背景色**: iOS需要透明背景，Android可以有背景色
- **圆角**: iOS会自动添加圆角，Android需要手动处理
- **安全区域**: 确保重要元素不会被系统圆角裁切

## 🔄 替换步骤

1. 生成所有尺寸的PNG文件
2. 替换对应目录下的图标文件
3. 重新构建应用
4. 检查各平台显示效果