import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/embedded_model.dart';
import '../services/embedded_model_service.dart';
import '../widgets/model_download_progress_card.dart';
import '../widgets/model_status_card.dart';
import '../widgets/device_compatibility_card.dart';

class EmbeddedModelManagerScreen extends StatelessWidget {
  const EmbeddedModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('离线AI模型'), elevation: 0),
      body: Consumer<EmbeddedModelService>(
        builder: (context, modelService, child) {
          return RefreshIndicator(
            onRefresh: () => modelService.initialize(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(context, modelService),
                  const SizedBox(height: 24),
                  _buildDownloadPolicySection(context),
                  const SizedBox(height: 24),
                  // 只在非下载状态时显示状态卡片，避免重复
                  if (modelService.state.status != ModelStatus.downloading)
                    _buildStatusSection(context, modelService),
                  if (modelService.state.status != ModelStatus.downloading)
                    const SizedBox(height: 24),
                  if (modelService.state.status == ModelStatus.downloading) ...[
                    _buildDownloadSection(context, modelService),
                    const SizedBox(height: 24),
                  ],
                  if (modelService.state.status == ModelStatus.notDownloaded)
                    _buildDownloadPromptSection(context, modelService),
                  if (modelService.isModelReady)
                    _buildModelReadySection(context, modelService),
                  if (modelService.isModelDownloaded && !modelService.hasError)
                    _buildChatTestSection(context, modelService),
                  if (modelService.hasError)
                    _buildErrorSection(context, modelService),
                  const SizedBox(height: 24),
                  _buildCompatibilitySection(context, modelService),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(context, modelService),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemma 3 Nano E4B',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '多模态植物识别模型',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFeatureChip('🚀 完全离线', Colors.green),
        _buildFeatureChip('🔒 隐私保护', Colors.blue),
        _buildFeatureChip('📱 端侧推理', Colors.orange)
      ],
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildDownloadPolicySection(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        bool allowBackground = prefs?.getBool('allow_background_download') ?? false;
        bool wifiOnly = prefs?.getBool('wifi_only_download') ?? true;
        bool autoPauseLowBattery = prefs?.getBool('auto_pause_low_battery') ?? true;

        void save() {
          if (prefs != null) {
            prefs.setBool('allow_background_download', allowBackground);
            prefs.setBool('wifi_only_download', wifiOnly);
            prefs.setBool('auto_pause_low_battery', autoPauseLowBattery);
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '下载策略',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('允许后台继续下载模型'),
                  subtitle: const Text('切到其他应用时继续下载'),
                  value: allowBackground,
                  onChanged: (v) {
                    allowBackground = v;
                    save();
                    (context as Element).markNeedsBuild();
                  },
                ),
                SwitchListTile(
                  title: const Text('仅在 Wi‑Fi 下下载模型'),
                  subtitle: const Text('移动网络时等待 Wi‑Fi'),
                  value: wifiOnly,
                  onChanged: (v) {
                    wifiOnly = v;
                    save();
                    (context as Element).markNeedsBuild();
                  },
                ),
                SwitchListTile(
                  title: const Text('低电量时自动暂停下载'),
                  subtitle: const Text('电量 ≤ 15% 且未充电时暂停'),
                  value: autoPauseLowBattery,
                  onChanged: (v) {
                    autoPauseLowBattery = v;
                    save();
                    (context as Element).markNeedsBuild();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return ModelStatusCard(
      status: modelService.state.status,
      modelInfo: modelService.modelInfo,
      downloadProgress: modelService.downloadProgress,
      currentSource: modelService.state.currentSource,
    );
  }

  Widget _buildDownloadSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Column(
      children: [
        ModelDownloadProgressCard(
          progress: modelService.downloadProgress,
          currentSource: modelService.state.currentSource,
          downloadedBytes:
              (modelService.downloadProgress *
                      (modelService.modelInfo?.sizeBytes ?? 0))
                  .round(),
          totalBytes: modelService.modelInfo?.sizeBytes ?? 0,
          statusMessage: modelService.downloadStatus.isNotEmpty
              ? modelService.downloadStatus
              : null,
          onCancel: () => modelService.cancelDownload(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // 继续下载（忽略一次 Wi‑Fi/电量限制）
                  modelService.didChangeAppLifecycleState(AppLifecycleState.resumed);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('继续'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => modelService.pauseDownload(),
                icon: const Icon(Icons.pause),
                label: const Text('暂停'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => modelService.cancelDownload(),
                icon: const Icon(Icons.stop),
                label: const Text('取消'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadPromptSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '获取离线AI模型',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '下载后可完全离线识别植物，无需网络和API密钥。模型大小约2.5GB，建议在WiFi环境下载。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.cloud_download,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '来源: HuggingFace (flutter_gemma 官方推荐)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showModelDetails(context, modelService),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('了解详情'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: modelService.deviceCapability != null
                        ? () => _startDownload(context, modelService)
                        : null,
                    icon: const Icon(Icons.download),
                    label: const Text('立即下载'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelReadySection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  '模型就绪',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '离线AI模型已就绪，可以开始识别植物了！',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // 主要功能按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _testModel(context, modelService),
                    icon: const Icon(Icons.speed),
                    label: const Text('性能测试'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/camera'),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('开始识别'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Chat测试卡片
            _buildChatTestCard(context, modelService),
          ],
        ),
      ),
    );
  }

  /// Chat测试区域 - 独立显示，不依赖模型ready状态
  Widget _buildChatTestSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildChatTestCard(context, modelService),
      ],
    );
  }

  /// Chat测试功能卡片 - 跳转到专门的Chat页面
  Widget _buildChatTestCard(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Card(
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/model-chat-test'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '多模态聊天测试',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '与AI模型进行文本和图片的实时对话测试',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 在离线模型就绪时提供一个简易多模态聊天测试区块（文本+可选图片）
  Widget _buildLocalChatTester(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    final promptController = TextEditingController(
      text: '请用简洁的中文描述这张图片中的植物特征，并判断可能的物种。',
    );
    File? pickedImage;

    Future<void> pickImage() async {
      try {
        final picker = ImagePicker();
        final XFile? img = await picker.pickImage(source: ImageSource.gallery);
        if (img != null) {
          pickedImage = File(img.path);
          (context as Element).markNeedsBuild();
        }
      } catch (_) {}
    }

    Future<void> runChat() async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('离线多模态聊天处理中...'),
                ],
              ),
            ),
          ),
        ),
      );
      try {
        final resp = await modelService.chat(
          prompt: promptController.text.trim().isEmpty
              ? '请分析图片内容并用中文解释。'
              : promptController.text.trim(),
          imageFile: pickedImage,
        );
        if (!context.mounted) return;
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('聊天结果'),
            content: SingleChildScrollView(child: Text(resp)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('离线聊天失败：$e')),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('多模态聊天测试', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: promptController,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '输入提示词（可留空使用默认）',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: const Text('选择图片'),
            ),
            const SizedBox(width: 12),
            if (pickedImage != null)
              Expanded(
                child: Text(
                  pickedImage!.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: runChat,
            icon: const Icon(Icons.chat),
            label: const Text('开始聊天'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  '模型错误',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.red.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              modelService.errorMessage ?? '未知错误',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => modelService.initialize(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showErrorHelp(context, modelService),
                    icon: const Icon(Icons.help),
                    label: const Text('获取帮助'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilitySection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return DeviceCompatibilityCard(
      capability: modelService.deviceCapability,
      modelInfo: modelService.modelInfo,
    );
  }

  Widget _buildAdvancedSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('高级选项', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('存储管理'),
              subtitle: const Text('查看模型文件占用空间'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showStorageInfo(context, modelService),
            ),
            if (modelService.isModelDownloaded) ...[
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade600),
                title: Text(
                  '删除模型',
                  style: TextStyle(color: Colors.red.shade600),
                ),
                subtitle: const Text('释放存储空间，可重新下载'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmDeleteModel(context, modelService),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showModelDetails(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    final compatibilityReport = await modelService.getCompatibilityReport();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('模型详细信息'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('模型：Gemma 3 Nano 4B'),
              const SizedBox(height: 8),
              Text('大小：约2.5GB'),
              const SizedBox(height: 8),
              Text('功能：多模态植物识别'),
              const SizedBox(height: 16),
              Text('设备兼容性', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(compatibilityReport),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          if (modelService.deviceCapability != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startDownload(context, modelService);
              },
              child: const Text('开始下载'),
            ),
        ],
      ),
    );
  }

  Future<void> _startDownload(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    await modelService.downloadModel();
  }

  Future<void> _testModel(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在测试模型性能...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final testDuration = await modelService.testInferenceSpeed();

      if (!context.mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('性能测试结果'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('预计推理时间：${testDuration.inSeconds}秒'),
              const SizedBox(height: 8),
              Text(
                '后端：${modelService.deviceCapability?.recommendedBackend.name ?? 'Unknown'}',
              ),
              const SizedBox(height: 8),
              Text(
                '设备等级：${modelService.deviceCapability?.isHighEnd == true ? '高端' : '中低端'}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('性能测试失败：$e')));
    }
  }

  Future<void> _showStorageInfo(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    final stats = await modelService.getModelStats();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('存储信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模型大小：${_formatFileSize((stats['model_size_bytes'] ?? 0).toDouble())}'),
            const SizedBox(height: 8),
            Text('存储路径：应用私有目录'),
            const SizedBox(height: 8),
            Text('状态：${_getStatusDisplayName(modelService.state.status)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteModel(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    // 获取模型统计信息
    final stats = await modelService.getModelStats();
    final modelSizeMB = (stats['model_size_mb'] ?? 0.0) as double;
    final modelSizeBytes = (stats['model_size_bytes'] ?? 0) as int;
    
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('确认删除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('确定要删除离线AI模型吗？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, size: 16, color: Colors.red.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '将释放存储空间：${_formatFileSize(modelSizeBytes.toDouble())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• 删除后需要重新下载才能使用离线识别',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                  Text(
                    '• 重新下载需要约2.5GB流量',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await modelService.deleteModel();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('模型已删除')));
      }
    }
  }

  Future<void> _showErrorHelp(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('常见问题解决方案：'),
              SizedBox(height: 16),
              Text('1. 网络连接问题'),
              Text('   • 检查网络连接是否正常'),
              Text('   • 尝试切换到WiFi网络'),
              SizedBox(height: 8),
              Text('2. 存储空间不足'),
              Text('   • 清理设备存储空间'),
              Text('   • 确保至少有4GB可用空间'),
              SizedBox(height: 8),
              Text('3. 设备性能限制'),
              Text('   • 关闭其他占用内存的应用'),
              Text('   • 重启设备后重试'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(ModelStatus status) {
    switch (status) {
      case ModelStatus.notDownloaded:
        return '未下载';
      case ModelStatus.downloading:
        return '下载中';
      case ModelStatus.downloaded:
        return '已下载';
      case ModelStatus.loading:
        return '加载中';
      case ModelStatus.ready:
        return '就绪';
      case ModelStatus.error:
        return '错误';
      case ModelStatus.updating:
        return '更新中';
    }
  }

  /// 格式化文件大小显示
  String _formatFileSize(double sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '${sizeInBytes.toStringAsFixed(0)} B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
