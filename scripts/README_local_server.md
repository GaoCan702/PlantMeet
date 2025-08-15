# 本地模型服务器使用指南

## 概述

本地模型服务器用于开发调试阶段，避免重复从 HuggingFace 下载 4.1GB 模型文件。服务器提供 HTTP 接口，支持断点续传。

## 快速开始

### 1. 下载模型文件（一次性操作）

```bash
cd /Users/limit/AndroidStudioProjects/PlantMeet
python3 scripts/download_model_auto.py
```

### 2. 启动本地服务器

```bash
# 使用默认端口 8000
./scripts/start_local_server.sh

# 或指定其他端口
./scripts/start_local_server.sh 8080
```

### 3. 编译应用（使用本地服务器）

```bash
# 获取本机IP地址（服务器启动后会显示）
# 然后编译应用并指定本地服务器和HF Token（重要：两个参数都需要）
flutter build apk --debug \
  --dart-define=LOCAL_MODEL_SERVER=http://192.168.1.100:8001 \
  --dart-define=HF_ACCESS_TOKEN=your_hf_token_here

# 安装到设备
flutter install
```

## 详细说明

### 服务器特性

- ✅ **支持断点续传** - Range 请求支持
- ✅ **CORS 跨域** - 支持 Web 和移动端访问
- ✅ **自动文件检查** - 启动前验证模型文件完整性
- ✅ **详细日志** - 显示客户端访问信息
- ✅ **错误处理** - 优雅处理各种异常情况

### 目录结构

```
scripts/
├── local_model_server.py      # HTTP 服务器主程序
├── start_local_server.sh      # 启动脚本（推荐）
├── download_model_auto.py     # 模型下载脚本
└── README_local_server.md     # 本说明文件

assets/models/
└── gemma-3n-E4B-it-int4.task # 模型文件（4.1GB）
```

### 命令行选项

#### 服务器脚本

```bash
python3 scripts/local_model_server.py [选项]

选项:
  --port PORT    服务器端口 (默认: 8000)
  --host HOST    绑定主机 (默认: 0.0.0.0)
```

#### 启动脚本

```bash
./scripts/start_local_server.sh [端口]

参数:
  端口    服务器端口 (默认: 8000)
```

### 环境变量说明

应用支持以下编译时环境变量：

- `LOCAL_MODEL_SERVER`: 本地服务器地址，如 `http://192.168.1.100:8000`
- `HF_ACCESS_TOKEN`: HuggingFace 访问令牌（仅在未设置本地服务器时使用）

### 使用模式

#### 开发调试模式（推荐）

```bash
# 1. 启动本地服务器
./scripts/start_local_server.sh 8001

# 2. 编译应用（使用本地服务器，同时保留HF Token作为备用）
flutter build apk --debug \
  --dart-define=LOCAL_MODEL_SERVER=http://192.168.1.100:8001 \
  --dart-define=HF_ACCESS_TOKEN=your_hf_token_here

# 优势：
# - 下载速度快（局域网）
# - 有HuggingFace Token备用
# - 支持断点续传
# - 节省带宽
```

#### 生产环境模式

```bash
# 编译应用（使用 HuggingFace）
flutter build apk --release --dart-define=HF_ACCESS_TOKEN=your_token

# 特点：
# - 直接从 HuggingFace 下载
# - 需要有效的访问令牌
# - 适合正式发布
```

## 网络配置

### 防火墙设置

确保本地防火墙允许相应端口（默认 8000）的入站连接：

```bash
# macOS
sudo pfctl -f /etc/pf.conf

# 或临时开放端口（根据系统而定）
```

### 获取本机IP地址

```bash
# macOS/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# 或使用服务器启动时显示的IP地址
```

## 故障排除

### 常见问题

#### 1. 端口被占用

```
❌ 端口 8000 已被占用，请尝试其他端口:
python3 scripts/local_model_server.py --port 8001
```

**解决方案**: 使用其他端口或停止占用端口的程序

#### 2. 模型文件不存在

```
❌ 模型文件不存在: assets/models/gemma-3n-E4B-it-int4.task
请先运行下载脚本:
python3 scripts/download_model_auto.py
```

**解决方案**: 运行下载脚本获取模型文件

#### 3. 文件大小异常

```
⚠️  模型文件大小异常:
  实际: 1234567 bytes (1.18 GB)
  期望: 4405655031 bytes (4.10 GB)
```

**解决方案**: 重新下载模型文件

#### 4. 设备无法连接服务器

**检查项目**:
- 确认设备和服务器在同一网络
- 检查防火墙设置
- 验证IP地址和端口是否正确
- 尝试使用浏览器访问 `http://IP:PORT/gemma-3n-E4B-it-int4.task`

### 调试方法

#### 1. 验证服务器运行

```bash
# 本地测试
curl -I http://localhost:8000/gemma-3n-E4B-it-int4.task

# 网络测试
curl -I http://192.168.1.100:8000/gemma-3n-E4B-it-int4.task
```

#### 2. 查看服务器日志

服务器会显示详细的访问日志：

```
[2024-01-15 10:30:15] 192.168.1.101 - "HEAD /gemma-3n-E4B-it-int4.task HTTP/1.1" 200 -
[2024-01-15 10:30:16] 192.168.1.101 - "GET /gemma-3n-E4B-it-int4.task HTTP/1.1" 206 -
```

#### 3. 应用日志

在应用中查看下载日志，确认使用的 URL：

```
I/flutter: 开始下载: 总大小 4.10 GB
I/flutter: 连接服务器: http://192.168.1.100:8000/gemma-3n-E4B-it-int4.task
```

## 性能优化

### 网络优化

- 使用有线网络连接提高传输速度
- 确保路由器支持千兆网络
- 关闭不必要的网络应用减少干扰

### 系统优化

- 确保足够的磁盘空间（至少 5GB）
- 关闭不必要的后台应用
- 使用 SSD 硬盘提高 I/O 性能

## 安全注意事项

- 本地服务器仅用于开发调试，不要在生产环境使用
- 确保模型文件来源可信
- 定期检查和更新访问令牌
- 不要在公网暴露本地服务器端口

## 技术实现

### 服务器架构

```python
# 支持特性
- HTTP/1.1 协议
- Range 请求 (RFC 7233)
- CORS 跨域访问
- 优雅错误处理
- 内容类型检测
```

### 应用集成

```dart
// 动态URL选择
static String get _modelUrl {
  if (_localModelServer.isNotEmpty) {
    return '$_localModelServer/$_fileName';  // 本地服务器
  } else {
    return _defaultModelUrl;                 // HuggingFace
  }
}
```

## 许可证

本项目遵循项目主许可证。模型文件版权归 Google 所有。