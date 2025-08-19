# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PlantMeet (遇见植物) is a "small and beautiful" plant identification app designed for students and plant enthusiasts. The app focuses on three core features: identification, recording (with smart deduplication), and export functionality. It uses a hybrid recognition approach combining local MNN chat API (primary) with optional cloud API (BYOK - Bring Your Own Key).

## Development Commands

### Flutter Development
- `flutter run` - Run the app in development mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter test` - Run tests
- `flutter analyze` - Static code analysis
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Android Specific
- `flutter build apk --release` - Build release APK
- `flutter build appbundle --release` - Build Android App Bundle

### Testing and Quality
- `flutter test` - Run unit tests
- `flutter analyze` - Run static analysis with flutter_lints
- `flutter format .` - Format code according to Dart style guide

### Development Automation (Debug Mode)

#### 🚨 重要：编译时必须包含 LOCAL_MODEL_SERVER 参数
```bash
# ❌ 错误 - 缺少 LOCAL_MODEL_SERVER 参数会导致模型下载失败
flutter build apk --debug

# ✅ 正确 - 必须指定 LOCAL_MODEL_SERVER
flutter build apk --debug --dart-define=LOCAL_MODEL_SERVER="http://192.168.1.100:8001"

# ✅✅ 推荐 - 使用自动化脚本（自动处理所有参数）
./scripts/dev_deploy.sh
```

#### 一键部署脚本
- `./scripts/dev_deploy.sh` - **推荐使用**：自动处理服务器启动、IP检测、编译参数、安装
- `./scripts/stop_server.sh` - 停止本地模型文件服务器
- `python3 scripts/local_model_server.py` - 手动启动本地模型文件服务器（默认8001端口）

#### 开发流程说明
在debug阶段，**必须使用 `./scripts/dev_deploy.sh`** 实现一键部署：
1. 自动清理旧的服务器进程
2. 启动本地模型文件服务器（端口8001）
3. 自动检测本机IP地址
4. **自动添加 LOCAL_MODEL_SERVER 编译参数**（重要！）
5. 自动安装到已连接的Android设备

这解决了手动编译时容易忘记添加参数的问题。

## Architecture and Key Components

### Core Application Structure
- **lib/main.dart** - Entry point with basic Flutter app structure (currently default template)
- **Multi-platform support**: Android, iOS, web, Linux, macOS, Windows

### Project Status
This is a new Flutter project currently in the template stage. The actual implementation needs to be built according to the detailed product requirements in `plantmeet_prd.md`.

### Key Design Principles (from plantmeet_prd.md)
1. **Minimalist**: Only identification, recording, and export features
2. **Local-first**: Default to local MNN chat API for zero cost and privacy
3. **Smart deduplication**: Merge same plant species with multiple encounter records
4. **Export-focused**: PDF generation for physical field guides
5. **Privacy-conscious**: Local storage by default, optional cloud with user consent

### Data Models (to be implemented)
- **Species**: Unique plant entries with taxonID
- **Encounter**: Individual sightings with time, location, photos, notes
- **Recognition results**: Top-3 candidates with confidence scores

### Technical Requirements (from PRD)
- Local recognition via MNN chat API
- Optional cloud recognition with BYOK
- PDF export functionality
- Local database for plant and encounter data
- Camera and photo library integration
- Location services (optional)
- Smart deduplication logic

## Development Guidelines

### Code Style
- Follow Dart/Flutter standard style guidelines
- Use flutter_lints for code quality (configured in analysis_options.yaml)
- Prefer single quotes for strings
- Follow the existing project structure

### Platform Considerations
- The project supports multiple platforms (Android, iOS, web, desktop)
- Android package ID: `com.arousedata.plantmeet`
- Minimum SDK versions follow Flutter defaults

### UI Layout Guidelines
- **Bottom Safe Area**: Always handle system navigation bar overlap for pages with bottom buttons or important content
- Use `EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom)` for bottom containers
- Alternative: Use `SafeArea` widget for simpler cases
- Test on devices with virtual navigation bars (Android) and home indicators (iOS)

### Testing
- Place tests in the `test/` directory
- Run tests with `flutter test`
- Currently has basic widget test template

## Important Notes

- This is a greenfield project - most features need to be implemented from scratch
- The detailed product requirements are in `plantmeet_prd.md` (Chinese)
- The app should prioritize privacy and local processing
- Implementation should follow the "small and beautiful" philosophy outlined in the PRD
- Current codebase is Flutter template - actual implementation needed