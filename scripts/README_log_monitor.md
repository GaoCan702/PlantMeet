# PlantMeet 日志监控工具

## 概述

日志监控工具用于实时捕获应用运行时的错误和异常，自动保存到文件供后续分析。特别适合调试阶段发现和记录问题。

## 快速开始

### 方法1：使用启动脚本（推荐）

```bash
cd /Users/limit/AndroidStudioProjects/PlantMeet
./scripts/start_monitor.sh
```

### 方法2：直接运行Python脚本

```bash
cd /Users/limit/AndroidStudioProjects/PlantMeet
python3 scripts/monitor_logs.py
```

## 功能特性

### 🔍 实时错误检测
- 自动识别错误关键词和异常模式
- 实时在终端显示错误信息
- 支持中文和英文错误消息

### 📝 日志记录
- 所有日志保存到文件 `logs/app_monitor.log`
- 带时间戳和错误标记
- 支持长期运行和大文件处理

### 📊 统计信息
- 实时显示处理的日志行数
- 错误计数和最后错误时间
- 运行时间统计

### 🎯 灵活配置
- 可指定监控的应用包名
- 支持不同日志级别过滤
- 自定义输出文件路径

## 使用方法

### 基本用法

```bash
# 监控PlantMeet应用（默认）
python3 scripts/monitor_logs.py

# 监控所有应用
python3 scripts/monitor_logs.py --package "*"

# 仅监控错误级别日志
python3 scripts/monitor_logs.py --level E

# 自定义输出文件
python3 scripts/monitor_logs.py --output logs/debug_session.log
```

### 命令行参数

```bash
python3 scripts/monitor_logs.py [选项]

选项:
  --package, -p PACKAGE   要监控的应用包名 (默认: com.arousedata.plantmeet)
                         使用 "*" 监控所有应用
  --output, -o OUTPUT     输出日志文件路径 (默认: logs/app_monitor.log)
  --level, -l LEVEL       日志级别: V|D|I|W|E|F (默认: V)
                         V=详细, D=调试, I=信息, W=警告, E=错误, F=致命
  --check-only           仅检查ADB连接状态，不开始监控
  -h, --help             显示帮助信息
```

### 日志级别说明

- **V (Verbose)**: 所有日志 - 用于完整调试
- **D (Debug)**: 调试信息及以上 - 开发调试
- **I (Info)**: 信息级别及以上 - 一般监控
- **W (Warn)**: 警告级别及以上 - 关注问题
- **E (Error)**: 错误级别及以上 - 仅关注错误
- **F (Fatal)**: 致命错误 - 仅关注崩溃

## 错误检测模式

### 自动识别的错误类型

**系统级错误**:
- FATAL, ERROR, Exception
- ANR (应用无响应)
- OutOfMemory, StackOverflow
- Crash, NullPointerException

**网络错误**:
- NetworkError, TimeoutException
- ConnectionError, HttpException
- ClientException, SocketException

**Flutter/Dart错误**:
- StateError, ArgumentError
- FormatException, FileSystemException
- PlatformException, UnimplementedError
- AssertionError, RangeError

**应用特定错误**:
- 下载失败, 连接失败
- 网络错误, 解析错误
- 初始化失败, 加载失败

### 输出格式

**终端输出** (仅错误):
```
🔴 ERROR: E/flutter (12345): ClientException: Invalid response line
```

**文件输出** (所有日志):
```
2024-01-15 15:30:25.123 [ERROR] E/flutter (12345): ClientException: Invalid response line
2024-01-15 15:30:25.124 [INFO] I/flutter (12345): 开始下载模型...
```

## 实际使用场景

### 场景1：调试模型下载问题

```bash
# 1. 启动监控
./scripts/start_monitor.sh

# 2. 在应用中操作模型下载功能
# 3. 观察终端中的错误输出
# 4. 分析保存的日志文件
```

### 场景2：长期稳定性测试

```bash
# 后台运行监控
nohup python3 scripts/monitor_logs.py > monitor_output.txt 2>&1 &

# 查看进程ID
echo $! > monitor.pid

# 停止监控
kill $(cat monitor.pid)
```

### 场景3：特定问题调试

```bash
# 仅监控错误日志，减少噪音
python3 scripts/monitor_logs.py --level E --output logs/errors_only.log

# 监控网络相关问题
python3 scripts/monitor_logs.py | grep -i "network\|connection\|http"
```

## 故障排除

### 常见问题

#### 1. ADB连接失败

```
❌ 未检测到连接的Android设备
```

**解决方案**:
```bash
# 检查ADB状态
adb devices

# 重启ADB服务
adb kill-server
adb start-server

# 检查USB调试是否开启
```

#### 2. 应用未运行

```
⚠️  应用 com.arousedata.plantmeet 未运行
```

**解决方案**:
- 先启动PlantMeet应用
- 或选择继续监控等待应用启动

#### 3. 权限问题

```
❌ 写入日志文件失败: Permission denied
```

**解决方案**:
```bash
# 确保logs目录有写权限
chmod 755 logs/
touch logs/app_monitor.log
chmod 644 logs/app_monitor.log
```

#### 4. 日志文件过大

**解决方案**:
```bash
# 按日期轮转日志
python3 scripts/monitor_logs.py --output logs/app_$(date +%Y%m%d).log

# 或定期清理
find logs/ -name "*.log" -mtime +7 -delete
```

### 调试技巧

#### 检查监控状态

```bash
# 检查ADB连接
python3 scripts/monitor_logs.py --check-only

# 查看应用进程
adb shell pidof com.arousedata.plantmeet

# 手动测试logcat
adb logcat | grep plantmeet
```

#### 分析日志文件

```bash
# 统计错误数量
grep -c "\[ERROR\]" logs/app_monitor.log

# 查看最近的错误
grep "\[ERROR\]" logs/app_monitor.log | tail -10

# 按时间过滤
grep "2024-01-15 15:" logs/app_monitor.log

# 搜索特定错误
grep -i "download\|network" logs/app_monitor.log
```

## 性能考虑

- **CPU使用**: 监控脚本CPU占用很低 (<1%)
- **内存使用**: 常驻内存约10-20MB
- **磁盘空间**: 日志文件大小取决于应用活跃度
- **网络影响**: 无网络开销，仅本地ADB通信

## 最佳实践

1. **开发阶段**: 使用详细级别(V)监控所有日志
2. **测试阶段**: 使用错误级别(E)关注问题
3. **问题调试**: 使用自定义输出文件分类保存
4. **长期运行**: 考虑日志轮转和清理策略
5. **团队协作**: 将重要错误日志提交到版本控制

## 文件结构

```
scripts/
├── monitor_logs.py         # 主监控脚本
├── start_monitor.sh        # 快速启动脚本
└── README_log_monitor.md   # 本说明文件

logs/                       # 日志输出目录
├── app_monitor.log         # 默认日志文件
├── debug_session.log       # 自定义会话日志
└── errors_only.log         # 仅错误日志
```

## 集成与扩展

### 与CI/CD集成

```yaml
# GitHub Actions 示例
- name: Monitor App Logs
  run: |
    python3 scripts/monitor_logs.py --level E --output artifacts/test_errors.log &
    MONITOR_PID=$!
    
    # 运行测试...
    
    kill $MONITOR_PID
    
- name: Upload Error Logs
  uses: actions/upload-artifact@v3
  with:
    name: error-logs
    path: artifacts/test_errors.log
```

### 自定义错误模式

可以修改 `monitor_logs.py` 中的 `error_patterns` 列表来添加项目特定的错误关键词。

## 许可证

本工具遵循项目主许可证。