# 开发工具脚本

## 模型下载脚本

### 使用方法

**自动下载（推荐）**:
```bash
cd /Users/limit/AndroidStudioProjects/PlantMeet
python3 scripts/download_model_auto.py
```

**交互式下载**:
```bash
cd /Users/limit/AndroidStudioProjects/PlantMeet
python3 scripts/download_model.py
```

### 功能特性

- ✅ 自动检测已存在文件，避免重复下载
- ✅ 支持断点续传，网络中断后可恢复
- ✅ 显示下载进度和速度
- ✅ 验证文件完整性
- ✅ 自动创建目标目录

### 下载的模型

- **文件名**: `gemma-3n-E4B-it-int4.task`
- **大小**: 约 4.1 GB
- **用途**: Gemma 3 Nano 多模态模型，支持文本和图像理解
- **保存位置**: `assets/models/`

### 工作流程

1. **检查现有文件** - 如果已存在且完整，跳过下载
2. **连接 HuggingFace** - 使用提供的 access token
3. **断点续传** - 支持网络中断后继续下载
4. **保存到 assets** - 下载到 `assets/models/` 目录
5. **验证完整性** - 检查文件大小是否正确

### Debug 阶段使用

下载完成后：

1. **重新编译应用**:
   ```bash
   flutter clean
   flutter build apk --debug
   ```

2. **安装到设备**:
   ```bash
   flutter install
   ```

3. **自动加载** - 应用启动时会自动检测并使用 assets 中的模型

### 发布阶段注意事项

发布生产版本时，请在 `pubspec.yaml` 中注释掉 assets 配置：

```yaml
assets:
  - assets/logo/
  # - assets/models/  # 发布时注释掉，避免安装包过大
```

### 环境要求

- Python 3.6+
- requests 库: `pip install requests`

### 故障排除

**网络连接问题**:
- 脚本支持断点续传，重新运行即可继续下载
- 检查网络连接和防火墙设置

**权限问题**:
```bash
chmod +x scripts/download_model_auto.py
```

**磁盘空间不足**:
- 确保至少有 5GB 可用空间
- 检查 `assets/models/` 目录权限

**Token 问题**:
- 确认 HuggingFace token 仍然有效
- 检查 token 是否有访问 Google Gemma 模型的权限