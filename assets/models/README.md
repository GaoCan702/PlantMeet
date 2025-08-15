# 模型文件目录

## Debug 阶段使用说明

在 debug 阶段，您可以将模型文件放置在此目录中以避免重复下载：

1. 将 `gemma-3n-E4B-it-int4.task` 文件复制到此目录
2. 应用启动时会自动检测并使用 assets 中的模型
3. 首次运行时会将模型从 assets 复制到本地存储

## 文件结构

```
assets/models/
├── README.md                    # 本说明文件
└── gemma-3n-E4B-it-int4.task  # 模型文件（需要手动放置）
```

## 获取模型文件

如果您已经下载过模型，可以从以下位置复制：
- Android: `/data/data/com.arousedata.plantmeet/app_flutter/models/google_gemma-3n-E4B-it-litert-preview/gemma-3n-E4B-it-int4.task`
- iOS: `~/Library/Developer/CoreSimulator/Devices/.../Documents/models/google_gemma-3n-E4B-it-litert-preview/gemma-3n-E4B-it-int4.task`

## 发布时注意事项

发布生产版本时，请在 `pubspec.yaml` 中注释掉 `assets/models/` 行以减小安装包大小：

```yaml
assets:
  - assets/logo/
  # - assets/models/  # 发布时注释掉
```

## 模型文件大小

- `gemma-3n-E4B-it-int4.task`: 约 4.1 GB

**警告**: 包含模型文件会显著增加安装包大小，仅建议在开发调试阶段使用。