# PlantMeet 架构文档

## 概述

PlantMeet（遇见植物）是一个"小而美"的植物识别应用，采用 Flutter 框架开发，支持多平台部署。本文档描述了当前架构实现和未来演进规划。

## 当前架构

### 技术栈

- **框架**: Flutter 3.8+ (Dart)
- **状态管理**: Provider
- **数据库**: Drift (SQLite)
- **AI识别**: flutter_gemma + MNN Chat + 云端API
- **UI设计**: Material 3

### 核心服务层

```
lib/services/
├── app_state.dart              # 全局应用状态管理
├── database_service.dart       # 数据库操作封装
├── recognition_service.dart    # 植物识别核心服务
├── embedded_model_service.dart # 应用内AI模型管理
├── mnn_chat_service.dart      # MNN Chat外部服务接口
├── privacy_service.dart       # 隐私保护和数据合规
└── pdf_export_service.dart    # PDF导出功能
```

### 数据模型

```
lib/models/
├── plant_species.dart         # 植物种类实体
├── plant_encounter.dart       # 遇见记录实体
├── recognition_result.dart    # 识别结果模型
├── app_settings.dart         # 应用配置
└── embedded_model.dart       # AI模型元数据
```

### 用户界面

```
lib/screens/
├── home_screen.dart                    # 首页：植物图鉴展示
├── camera_screen.dart                  # 拍照识别页面
├── plant_detail_screen.dart           # 植物详情页
├── settings_screen.dart               # 设置页面
├── embedded_model_manager_screen.dart  # AI模型管理
└── onboarding_screen.dart             # 新手引导
```

## AI识别架构

### 三重识别方案

PlantMeet 采用多层次识别策略，确保在不同环境下都能提供可靠的植物识别服务：

#### 1. 应用内模型 (EmbeddedModelService)
- **模型**: Gemma 3 Nano 4B via flutter_gemma
- **特点**: 完全离线，隐私安全，零API成本
- **适用**: 网络受限环境，隐私敏感用户

#### 2. 本地外部服务 (MNNChatService)  
- **模型**: Qwen2.5-VL-3B via MNN Chat
- **特点**: 本地推理，更强性能，支持多模态对话
- **适用**: 有MNN Chat环境的高级用户

#### 3. 云端API (CloudProvider)
- **模式**: BYOK (Bring Your Own Key)
- **特点**: 最新模型，云端算力，用户承担成本
- **适用**: 对准确率要求极高的场景

### 智能回退机制

```dart
// 识别流程示例
Future<RecognitionResponse> identifyPlant(File image) async {
  // 1. 检查可用服务
  final hasEmbedded = embeddedModelService.isReady;
  final hasMNN = mnnChatService.isReady;
  final hasCloud = settings.cloudAPI.isConfigured;
  
  // 2. 按用户偏好和可用性选择方法
  for (final method in settings.fallbackOrder) {
    final result = await _tryMethod(method, image);
    if (result.success) return result;
  }
  
  // 3. 所有方法失败，返回错误
  return RecognitionResponse.error("无可用识别服务");
}
```

## 数据架构

### 核心实体关系

```
PlantSpecies (植物种类)
├── id: String (taxonID)
├── commonName: String
├── scientificName: String
├── family: String
├── description: String
└── encounters: List<PlantEncounter>

PlantEncounter (遇见记录)  
├── id: String
├── speciesId: String (FK)
├── timestamp: DateTime
├── location: GeoLocation?
├── photos: List<String>
├── notes: String?
└── recognitionResult: RecognitionResult
```

### 智能去重策略

- **种类去重**: 基于 taxonID 自动合并同种植物
- **多次遇见**: 每次识别创建新的 Encounter 记录
- **数据完整性**: 删除 Species 时保留 Encounter 历史

## 隐私与安全

### 数据保护原则

1. **本地优先**: 默认使用本地识别，数据不出设备
2. **明确同意**: 使用云端服务前明确告知用户
3. **最小化收集**: 只收集识别必需的数据
4. **用户控制**: 用户可随时删除数据和撤回同意

### 合规实现

- **未成年人保护**: 默认禁用云端识别
- **GDPR兼容**: 支持数据导出和删除请求  
- **透明性**: 在设置中清晰展示数据处理方式

---

## 未来演进规划

### 当前架构局限

**紧耦合问题**:
- 识别服务直接依赖具体实现类
- 硬编码的初始化和回退逻辑
- 新增识别源需要修改核心代码

**扩展性限制**:
- 无法支持多个同类型模型实例
- 设置界面与服务实现强绑定
- 缺乏动态负载均衡能力

### 目标架构：ModelProvider 抽象层

#### 1. 统一Provider接口

```dart
abstract class ModelProvider {
  // 基础生命周期
  Future<bool> init();
  bool get isReady;
  Future<void> dispose();
  
  // 核心功能
  Future<RecognitionResult> identify(File image, RecognitionContext context);
  Future<ChatResponse> chat(List<ChatMessage> messages); // 可选
  
  // 元数据
  ProviderCapabilities get capabilities;
  ProviderStatus get status;
  ProviderMetrics get metrics;
}
```

#### 2. 多Provider实现

**EmbeddedProvider**: 应用内模型管理
```dart
class EmbeddedProvider implements ModelProvider {
  // 支持多个嵌入模型: Gemma-2B, Gemma-7B, Phi-3等
  // 设备资源感知的模型选择
  // 模型热切换和并行推理
}
```

**LocalRestProvider**: 本地REST服务
```dart  
class LocalRestProvider implements ModelProvider {
  // 统一管理: MNN Chat, Ollama, LM Studio等
  // 多端点负载均衡
  // 自动发现和健康检查
}
```

**CloudProvider**: 云端API服务
```dart
class CloudProvider implements ModelProvider {
  // 多云支持: OpenAI, Claude, Gemini, 自定义API
  // 密钥池管理和额度监控  
  // 智能重试和降级策略
}
```

#### 3. 智能选择器/调度器

```dart
class ModelSelector {
  // 路由策略
  enum Strategy { performance, cost, quality, privacy }
  
  // 动态选择
  Future<ModelProvider> selectProvider(
    RecognitionContext context,
    List<ModelProvider> available,
  );
  
  // 实时监控和自适应
  void updateMetrics(ModelProvider provider, RecognitionResult result);
}
```

#### 4. 增强配置系统

```yaml
# 分层配置示例
recognition:
  embedded_models:
    - name: "Gemma-2B"
      enabled: true
      priority: 1
    - name: "Gemma-7B"  
      enabled: false
      priority: 2
      
  local_services:
    - name: "MNN Chat"
      endpoint: "http://localhost:8080"
      enabled: true
      priority: 2
      
  cloud_apis:
    - name: "OpenAI GPT-4V"
      enabled: false
      api_key: "user_provided"
      priority: 3

routing:
  strategy: "cost" # performance/cost/quality/privacy
  fallback_order: ["embedded", "local", "cloud"]
  constraints:
    max_latency_ms: 5000
    max_cost_per_request: 0.01
    privacy_level: "device_only" # device_only/local_network/cloud_allowed
```

### 演进收益

#### 开发效率提升
- **插件化架构**: 新增识别源从"改代码"变为"加配置"  
- **标准化接口**: 统一的测试、部署和监控流程
- **降低复杂度**: 关注点分离，减少维护成本

#### 用户体验优化  
- **精细控制**: 用户可以自定义每种识别方式的开关和优先级
- **智能适应**: 根据使用习惯和环境自动优化识别策略
- **透明决策**: 清晰展示为什么选择某个识别方法

#### 商业价值创造
- **生态扩展**: 支持更多第三方识别服务接入
- **Premium功能**: 高级模型、优先路由等付费特性
- **数据驱动**: 基于使用数据持续优化服务质量

### 实施路径

#### 阶段1: 接口抽象 (1个月)
- 定义 ModelProvider 接口和相关数据结构
- 将现有服务重构为 Provider 实现
- 保持向后兼容，确保功能不受影响

#### 阶段2: 选择器引入 (2周)  
- 实现基础的 ModelSelector
- 替换 RecognitionService 中的硬编码逻辑
- 添加简单的策略选择功能

#### 阶段3: 配置增强 (2周)
- 扩展设置系统支持多Provider配置
- 实现动态配置加载和热更新
- 优化设置界面的用户体验

#### 阶段4: 高级特性 (按需)
- 并行推理和结果融合
- 智能学习和自适应优化  
- 高级监控和性能分析

### 风险与注意事项

#### 性能考量
- **抽象开销**: 接口调用可能带来微小性能损失
- **内存使用**: 多Provider并存需要优化资源管理
- **冷启动**: 动态加载可能影响首次使用体验

#### 复杂度管理
- **渐进式改进**: 避免一次性大重构，保证稳定性
- **简单默认**: 为普通用户提供开箱即用的配置
- **文档同步**: 确保架构文档与代码实现保持一致

#### 向后兼容
- **接口稳定性**: Provider 接口设计需要考虑未来扩展
- **数据迁移**: 配置格式变更需要平滑的迁移方案
- **功能对等**: 确保重构后功能不缺失或降级

---

## 开发指南

### 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范
- 使用 flutter_lints 进行静态代码检查
- 优先使用单引号，保持代码风格一致

### 测试策略

```
test/
├── unit/           # 单元测试
├── widget/         # Widget测试  
├── integration/    # 集成测试
└── mocks/          # 模拟对象
```

### 构建命令

```bash
# 开发运行
flutter run

# 代码检查  
flutter analyze

# 单元测试
flutter test

# 构建发布版本
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

### 性能优化

- **懒加载**: 非关键服务延迟初始化
- **图片缓存**: 合理管理识别图片的内存占用
- **数据库优化**: 使用索引和分页查询
- **网络缓存**: 云端API结果适当缓存

---

*最后更新: 2025-08-15*
*版本: v1.0.0*