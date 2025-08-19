import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/embedded_model.dart';
import '../services/app_state.dart';
import '../services/embedded_model_service.dart';
import '../services/recognition_service.dart';
import '../models/privacy_policy.dart';
import '../services/privacy_service.dart';
import '../models/recognition_result.dart';
import 'mnn_chat_config_screen.dart';
import 'cloud_service_config_screen.dart';
import 'policy_detail_screen.dart';
import 'privacy_consent_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  final _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _settings = appState.settings ?? AppSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _autoSaveSettings() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.updateSettings(_settings);
  }

  void _onSettingChanged() {
    // 延迟保存，避免频繁保存
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _autoSaveSettings();
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('设置')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            // AI识别服务选择
            _buildAIServiceSelectionSection(),
            const SizedBox(height: 16),
            // 应用内AI模型管理
            _buildEmbeddedModelSection(),
            const SizedBox(height: 16),
            // 下载策略已迁移到"离线AI模型"页面
            // MNN Chat服务
            _buildMNNChatServiceSection(),
            const SizedBox(height: 16),
            // 云端服务
            _buildCloudServiceSection(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('其他设置', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('启用位置服务'),
                      subtitle: const Text('自动记录遇见地点'),
                      value: _settings.enableLocation,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(enableLocation: value);
                        });
                        _onSettingChanged();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('自动保存位置'),
                      subtitle: const Text('在遇见记录中保存位置信息'),
                      value: _settings.autoSaveLocation,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(
                            autoSaveLocation: value,
                          );
                        });
                        _onSettingChanged();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('保存原始照片'),
                      subtitle: const Text('保存高质量原始照片'),
                      value: _settings.saveOriginalPhotos,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(
                            saveOriginalPhotos: value,
                          );
                        });
                        _onSettingChanged();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 存储管理区域
            _buildStorageManagementSection(),
            const SizedBox(height: 16),
            // 隐私协议区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '隐私与协议',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // 隐私政策
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.privacy_tip,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('隐私政策'),
                      subtitle: Text(
                        '了解我们如何收集、使用和保护您的个人信息',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PolicyDetailScreen(
                              title: '隐私政策',
                              content: PrivacyPolicy.privacyPolicyContent,
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // 用户协议
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.description,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('用户协议'),
                      subtitle: Text(
                        '查看使用PlantMeet应用的条款和条件',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PolicyDetailScreen(
                              title: '用户协议',
                              content: PrivacyPolicy.userAgreementContent,
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // 协议状态
                    FutureBuilder<Map<String, dynamic>>(
                      future: PrivacyService.getConsentSummary(),
                      builder: (context, snapshot) {
                        final summary = snapshot.data;
                        final isConsented = summary?['is_consented'] ?? false;
                        final consentDate = summary?['consent_date'];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isConsented ? Icons.verified_user : Icons.warning,
                            color: isConsented
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          title: Text(isConsented ? '已同意协议' : '未同意协议'),
                          subtitle: Text(
                            isConsented && consentDate != null
                                ? '同意时间：${DateTime.parse(consentDate).toLocal().toString().substring(0, 19)}'
                                : '请阅读并同意用户协议和隐私政策',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: isConsented
                              ? TextButton(
                                  onPressed: () => _showRevokeDialog(),
                                  child: const Text('撤回同意'),
                                )
                              : TextButton(
                                  onPressed: () => _showConsentDialog(),
                                  child: const Text('重新同意'),
                                ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // 版本信息
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '协议版本信息',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '当前版本：${PrivacyPolicy.currentVersion}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '更新时间：${PrivacyPolicy.lastUpdated}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 下载策略 UI 已移除

  /// 显示撤回同意对话框
  void _showRevokeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('撤回同意'),
          content: const Text(
            '撤回同意将会：\n\n'
            '• 删除您的个人数据\n'
            '• 停止数据收集和处理\n'
            '• 可能影响应用正常使用\n\n'
            '确定要撤回对用户协议和隐私政策的同意吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await PrivacyService.revokeConsent();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已撤回同意，应用将重启以应用更改')),
                    );
                  }
                  // 这里可以重启应用或返回到同意页面
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('撤回同意失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                '确认撤回',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 显示重新同意对话框
  void _showConsentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重新同意协议'),
          content: const Text(
            '请重新阅读并同意最新版本的用户协议和隐私政策。\n\n'
            '这将允许应用正常收集和处理必要的数据以提供服务。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 导航到协议同意页面
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PrivacyConsentScreen(
                      onConsented: () {
                        Navigator.of(context).pop();
                        // 刷新页面状态
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
              child: const Text('重新同意'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMNNChatServiceSection() {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MNNChatConfigScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.computer, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MNN Chat服务',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _buildServiceStatusChip(_settings.enableLocalRecognition),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '使用本地MNN Chat API进行隐私安全的植物识别',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _settings.enableLocalRecognition
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                    size: 16,
                    color: _settings.enableLocalRecognition
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _settings.enableLocalRecognition
                        ? '已启用，可进行本地识别'
                        : '未启用，点击下方按钮进行配置',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '点击卡片配置 MNN Chat 服务',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudServiceSection() {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CloudServiceConfigScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '云端服务',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _buildServiceStatusChip(false), // 临时设为false，后续可以添加专门的云端开关
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '连接云端API进行高精度植物识别，支持多种服务商',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '未配置，点击下方按钮进行配置',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '点击卡片配置云端服务',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceStatusChip(bool enabled) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (enabled) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      text = '已启用';
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      text = '未配置';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmbeddedModelSection() {
    return Consumer<EmbeddedModelService>(
      builder: (context, modelService, child) {
        final status = modelService.state.status;
        final isReady = modelService.isModelReady;
        final isDownloaded = modelService.isModelDownloaded;

        return Card(
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed('/embedded-model-manager'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '应用内AI模型',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildModelStatusChip(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '下载Gemma 3n E4B LiteRT模型到应用内，实现完全离线的植物识别',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isReady
                            ? Icons.check_circle
                            : (isDownloaded
                                  ? Icons.pending
                                  : Icons.cloud_download),
                        size: 16,
                        color: isReady
                            ? Colors.green
                            : (isDownloaded ? Colors.orange : Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '点击卡片管理 AI 模型 · ${_getModelStatusText(status)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelStatusChip(ModelStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case ModelStatus.ready:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = '就绪';
        break;
      case ModelStatus.downloaded:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        text = '已下载';
        break;
      case ModelStatus.downloading:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = '下载中';
        break;
      case ModelStatus.loading:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = '加载中';
        break;
      case ModelStatus.error:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        text = '错误';
        break;
      case ModelStatus.notDownloaded:
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = '未下载';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getModelStatusText(ModelStatus status) {
    switch (status) {
      case ModelStatus.ready:
        return '模型已就绪，可进行离线识别';
      case ModelStatus.downloaded:
        return '模型已下载，正在加载中...';
      case ModelStatus.downloading:
        return '正在下载模型，请稍候...';
      case ModelStatus.loading:
        return '正在加载模型，请稍候...';
      case ModelStatus.error:
        return '模型加载失败，请检查设备存储';
      case ModelStatus.updating:
        return '正在更新模型，请稍候...';
      default:
        return '点击"管理AI模型"下载离线识别模型';
    }
  }

  /// 构建存储管理区域
  Widget _buildStorageManagementSection() {
    return Consumer<EmbeddedModelService>(
      builder: (context, modelService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '存储管理',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 显示模型存储状态
                FutureBuilder<Map<String, dynamic>>(
                  future: modelService.getModelStats(),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? {};
                    final modelSizeMB = (stats['model_size_mb'] ?? 0.0) as double;
                    // final modelSizeFormatted = stats['model_size_mb_formatted'] ?? '0.0';
                    final isModelDownloaded = modelService.isModelDownloaded;
                    
                    return Column(
                      children: [
                        // 模型存储信息
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isModelDownloaded 
                                ? Colors.green.shade50 
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isModelDownloaded 
                                  ? Colors.green.shade200 
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isModelDownloaded ? Icons.check_circle : Icons.cloud_download,
                                    size: 16,
                                    color: isModelDownloaded ? Colors.green.shade600 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isModelDownloaded ? 'AI模型已下载' : 'AI模型未下载',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isModelDownloaded ? Colors.green.shade700 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (isModelDownloaded) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '占用空间：${_formatFileSize(modelSizeMB * 1024 * 1024)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                Text(
                                  '下载后约占用 2.5 GB 存储空间',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 操作按钮
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pushNamed('/embedded-model-manager'),
                                icon: const Icon(Icons.settings),
                                label: const Text('详细管理'),
                              ),
                            ),
                            if (isModelDownloaded) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showQuickDeleteDialog(context, modelService, modelSizeMB),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.delete_sweep),
                                  label: const Text('清理模型'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示快速删除对话框
  Future<void> _showQuickDeleteDialog(
    BuildContext context, 
    EmbeddedModelService modelService,
    double modelSizeMB,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('清理存储空间'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('释放 ${_formatFileSize(modelSizeMB * 1024 * 1024)} 存储空间？'),
            const SizedBox(height: 8),
            Text(
              '删除后若需要离线识别，需要重新下载约2.5GB的模型文件。',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            child: const Text('确认清理'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await modelService.deleteModel();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已释放 ${_formatFileSize(modelSizeMB * 1024 * 1024)} 存储空间'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清理失败：$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  /// 构建AI服务选择区域
  Widget _buildAIServiceSelectionSection() {
    return Consumer<RecognitionService>(
      builder: (context, recognitionService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'AI识别服务',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '选择您首选的植物识别服务',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // 当前首选服务显示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '当前首选：${_settings.preferredRecognitionMethod.displayName}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AI服务选项列表
                _buildAIServiceOption(
                  RecognitionMethod.embedded,
                  Icons.smartphone,
                  Colors.green,
                  recognitionService,
                ),
                const SizedBox(height: 12),
                _buildAIServiceOption(
                  RecognitionMethod.local,
                  Icons.computer,
                  Colors.blue,
                  recognitionService,
                ),
                const SizedBox(height: 12),
                _buildAIServiceOption(
                  RecognitionMethod.cloud,
                  Icons.cloud,
                  Colors.purple,
                  recognitionService,
                ),
                const SizedBox(height: 12),
                _buildAIServiceOption(
                  RecognitionMethod.hybrid,
                  Icons.auto_awesome,
                  Colors.orange,
                  recognitionService,
                ),

                const SizedBox(height: 16),

                // 智能推荐
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '推荐使用"智能识别"，会自动选择最佳服务',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建单个AI服务选项
  Widget _buildAIServiceOption(
    RecognitionMethod method,
    IconData icon,
    Color color,
    RecognitionService recognitionService,
  ) {
    final isSelected = _settings.preferredRecognitionMethod == method;
    final isAvailable = recognitionService.isMethodAvailable(method);
    
    return InkWell(
      onTap: isAvailable ? () => _selectAIService(method) : () => _showServiceConfigDialog(method),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.1) 
              : (isAvailable ? Colors.transparent : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? color 
                : (isAvailable ? Colors.grey.shade300 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isAvailable ? color : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isAvailable ? color : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isAvailable ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildServiceStatusBadge(method, isAvailable),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isAvailable ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20)
            else if (!isAvailable)
              Icon(Icons.settings, color: Colors.grey.shade600, size: 16),
          ],
        ),
      ),
    );
  }

  /// 构建服务状态徽章
  Widget _buildServiceStatusBadge(RecognitionMethod method, bool isAvailable) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (isAvailable) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      text = '可用';
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade600;
      text = method == RecognitionMethod.hybrid ? '自动' : '需配置';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 选择AI服务
  void _selectAIService(RecognitionMethod method) {
    setState(() {
      _settings = _settings.copyWith(preferredRecognitionMethod: method);
    });
    _onSettingChanged();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已设置首选服务：${method.displayName}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示服务配置对话框
  void _showServiceConfigDialog(RecognitionMethod method) {
    String title = '';
    String content = '';
    String actionText = '';
    VoidCallback? action;

    switch (method) {
      case RecognitionMethod.embedded:
        title = '应用内AI识别';
        content = '需要下载AI模型才能使用此服务。模型大小约4GB，建议在Wi-Fi环境下下载。';
        actionText = '前往下载';
        action = () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/embedded-model-manager');
        };
        break;
      case RecognitionMethod.local:
        title = '本地AI识别';
        content = '需要配置本地MNN Chat服务才能使用此功能。';
        actionText = '前往配置';
        action = () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MNNChatConfigScreen()),
          );
        };
        break;
      case RecognitionMethod.cloud:
        title = '云端AI识别';
        content = '需要配置云端服务API才能使用此功能。';
        actionText = '前往配置';
        action = () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CloudServiceConfigScreen()),
          );
        };
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: action,
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}
