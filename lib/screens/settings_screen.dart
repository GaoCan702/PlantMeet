import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/embedded_model.dart';
import '../models/recognition_result.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';
import '../services/embedded_model_service.dart';
import '../services/huggingface_client.dart';
import '../widgets/copyable_error_message.dart';
import '../models/privacy_policy.dart';
import '../services/privacy_service.dart';
import 'mnn_chat_test_screen.dart';
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
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final RecognitionService _recognitionService = RecognitionService();
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _settings = appState.settings ?? AppSettings();
    _baseUrlController.text = _settings.baseUrl ?? '';
    _apiKeyController.text = _settings.apiKey ?? '';
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _autoSaveSettings() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    final updatedSettings = _settings.copyWith(
      baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
      apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
    );

    await appState.updateSettings(updatedSettings);
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
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
          children: [
            // 应用内AI模型管理
            _buildEmbeddedModelSection(),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '识别服务',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        OutlinedButton.icon(
                          onPressed: _testConnection,
                          icon: const Icon(Icons.wifi_find, size: 18),
                          label: const Text('测试连接'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('本地识别'),
                      subtitle: const Text('使用本地MNN Chat API进行植物识别'),
                      value: _settings.enableLocalRecognition,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(enableLocalRecognition: value);
                        });
                        _onSettingChanged();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'API地址',
                        hintText: '输入识别服务的API地址',
                        helperText: ' ', // 预留错误信息空间
                      ),
                      onChanged: (value) {
                        _onSettingChanged();
                      },
                      validator: (value) {
                        if (_settings.enableLocalRecognition && (value == null || value.isEmpty)) {
                          return '本地识别需要配置API地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'API密钥',
                        hintText: '输入您的API密钥',
                        helperText: ' ', // 预留错误信息空间
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _isApiKeyVisible = !_isApiKeyVisible;
                            });
                          },
                          tooltip: _isApiKeyVisible ? '隐藏密钥' : '显示密钥',
                        ),
                      ),
                      obscureText: !_isApiKeyVisible,
                      onChanged: (value) {
                        _onSettingChanged();
                      },
                      validator: (value) {
                        if (_settings.enableLocalRecognition && (value == null || value.isEmpty)) {
                          return '本地识别需要配置API密钥';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40, // 固定高度避免布局变化
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _settings.enableLocalRecognition 
                              ? '本地识别需要配置MNN Chat API地址和密钥'
                              : '支持MNN Chat或其他植物识别API服务',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // HuggingFace Token 配置
            _buildHuggingFaceSection(),
            const SizedBox(height: 16),
            // 识别模型设置
            _buildRecognitionMethodSection(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '其他设置',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
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
                          _settings = _settings.copyWith(autoSaveLocation: value);
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
                          _settings = _settings.copyWith(saveOriginalPhotos: value);
                        });
                        _onSettingChanged();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // MNN Chat 测试区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MNN Chat 测试',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '测试MNN Chat连接状态和植物识别功能，查看详细日志和识别结果',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MNNChatTestScreen(
                                appSettings: _settings,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.science),
                        label: const Text('打开 MNN Chat 测试页面'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '协议版本信息',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
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
            '确定要撤回对用户协议和隐私政策的同意吗？'
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已撤回同意，应用将重启以应用更改'),
                    ),
                  );
                  // 这里可以重启应用或返回到同意页面
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('撤回同意失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
            '这将允许应用正常收集和处理必要的数据以提供服务。'
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

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      ErrorSnackBar.show(
        context,
        message: '请先填写必要配置信息',
        title: '配置错误',
      );
      return;
    }

    if (!_settings.enableLocalRecognition) {
      ErrorSnackBar.show(
        context,
        message: '请先启用本地识别',
        title: '配置错误',
      );
      return;
    }

    setState(() {
      _settings = _settings.copyWith(
        baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
        apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
      );
    });

    // 显示测试中提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在测试连接...'),
        duration: Duration(seconds: 1),
      ),
    );

    // 初始化识别服务进行测试
    _recognitionService.updateSettings(_settings);
    final isConnected = await _recognitionService.testConnection(_settings);

    if (mounted) {
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接测试成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ErrorSnackBar.show(
          context,
          message: '连接测试失败，请检查配置',
          title: '连接错误',
        );
      }
    }
  }

  Widget _buildEmbeddedModelSection() {
    return Consumer<EmbeddedModelService>(
      builder: (context, modelService, child) {
        final status = modelService.state.status;
        final isReady = modelService.isModelReady;
        final isDownloaded = modelService.isModelDownloaded;
        
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
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '应用内AI模型',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _buildModelStatusChip(status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '下载Gemma 3n E4B LiteRT模型到应用内，实现完全离线的植物识别',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      isReady ? Icons.check_circle : (isDownloaded ? Icons.pending : Icons.cloud_download),
                      size: 16,
                      color: isReady 
                          ? Colors.green 
                          : (isDownloaded ? Colors.orange : Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getModelStatusText(status),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/embedded-model-manager'),
                    icon: const Icon(Icons.settings),
                    label: const Text('管理AI模型'),
                  ),
                ),
              ],
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
      case ModelStatus.error:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        text = '错误';
        break;
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

  Widget _buildRecognitionMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '识别方法设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '选择默认的植物识别方法和失败时的备用方法顺序',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // 首选识别方法
            Text(
              '首选识别方法',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecognitionMethodDropdown(),
            const SizedBox(height: 16),
            
            // 识别方法状态
            Text(
              '识别方法状态',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecognitionMethodStatus(),
            const SizedBox(height: 16),
            
            // 回退顺序设置
            Text(
              '回退顺序',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当首选方法失败时，将按以下顺序尝试其他方法',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildFallbackOrderList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecognitionMethodDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RecognitionMethod>(
          value: _settings.preferredRecognitionMethod,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          items: RecognitionMethod.values
              .where((method) => method != RecognitionMethod.manual)
              .map((method) => DropdownMenuItem<RecognitionMethod>(
                    value: method,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getMethodIcon(method),
                              size: 18,
                              color: _isMethodCurrentlyAvailable(method) 
                                  ? Colors.green 
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(method.displayName),
                            const Spacer(),
                            if (!_isMethodCurrentlyAvailable(method))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '不可用',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings.copyWith(preferredRecognitionMethod: value);
              });
              _onSettingChanged();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRecognitionMethodStatus() {
    final status = _recognitionService.getRecognitionMethodsStatus(_settings);
    
    return Column(
      children: [
        _buildMethodStatusTile(
          RecognitionMethod.embedded,
          status['embedded_model']['available'] as bool,
          _getEmbeddedModelStatusText(status['embedded_model']),
        ),
        _buildMethodStatusTile(
          RecognitionMethod.local,
          status['mnn_chat']['available'] as bool,
          status['mnn_chat']['available'] as bool ? 'MNN Chat已就绪' : 'MNN Chat未启动',
        ),
        _buildMethodStatusTile(
          RecognitionMethod.cloud,
          status['cloud']['configured'] as bool,
          status['cloud']['configured'] as bool ? '云端API已配置' : '云端API未配置',
        ),
      ],
    );
  }

  Widget _buildMethodStatusTile(RecognitionMethod method, bool available, String statusText) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        _getMethodIcon(method),
        size: 20,
        color: available ? Colors.green : Colors.grey,
      ),
      title: Text(
        method.displayName,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: available ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        available ? Icons.check_circle : Icons.error_outline,
        size: 18,
        color: available ? Colors.green : Colors.grey,
      ),
    );
  }

  Widget _buildFallbackOrderList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _settings.recognitionMethodFallbackOrder.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                _settings.recognitionMethodFallbackOrder[i].displayName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                _settings.recognitionMethodFallbackOrder[i].description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0)
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up),
                      iconSize: 20,
                      onPressed: () => _moveFallbackMethod(i, i - 1),
                    ),
                  if (i < _settings.recognitionMethodFallbackOrder.length - 1)
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      iconSize: 20,
                      onPressed: () => _moveFallbackMethod(i, i + 1),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getMethodIcon(RecognitionMethod method) {
    switch (method) {
      case RecognitionMethod.embedded:
        return Icons.memory;
      case RecognitionMethod.local:
        return Icons.computer;
      case RecognitionMethod.cloud:
        return Icons.cloud;
      case RecognitionMethod.hybrid:
        return Icons.auto_awesome;
      case RecognitionMethod.manual:
        return Icons.edit;
    }
  }

  bool _isMethodCurrentlyAvailable(RecognitionMethod method) {
    return _recognitionService.isMethodAvailable(method);
  }

  String _getEmbeddedModelStatusText(Map<String, dynamic> status) {
    if (status['available'] as bool) {
      return '应用内模型已就绪';
    } else {
      final statusString = status['status'] as String?;
      if (statusString?.contains('downloading') == true) {
        return '正在下载模型...';
      } else if (statusString?.contains('error') == true) {
        return '模型加载错误';
      } else {
        return '模型未下载';
      }
    }
  }

  void _moveFallbackMethod(int fromIndex, int toIndex) {
    setState(() {
      final newOrder = List<RecognitionMethod>.from(_settings.recognitionMethodFallbackOrder);
      final method = newOrder.removeAt(fromIndex);
      newOrder.insert(toIndex, method);
      _settings = _settings.copyWith(recognitionMethodFallbackOrder: newOrder);
    });
    _onSettingChanged();
  }

  Widget _buildHuggingFaceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '模型下载配置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '配置 HuggingFace Access Token 以下载 Gemma 3n LiteRT 模型',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // HuggingFace Token 输入框
            TextFormField(
              initialValue: _settings.huggingfaceToken,
              decoration: InputDecoration(
                labelText: 'HuggingFace Access Token',
                hintText: 'hf_xxxxxxxxxxxx',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: _settings.isHuggingFaceConfigured 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.grey),
                border: const OutlineInputBorder(),
                helperText: _settings.isHuggingFaceConfigured 
                    ? '✅ Token 已配置' 
                    : '需要 HuggingFace token 才能下载模型',
                helperStyle: TextStyle(
                  color: _settings.isHuggingFaceConfigured ? Colors.green : Colors.orange,
                ),
              ),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(huggingfaceToken: value.trim());
                });
                _onSettingChanged();
              },
            ),
            const SizedBox(height: 12),
            
            // 帮助说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '如何获取 HuggingFace Access Token',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. 访问 huggingface.co 并创建账号\n'
                    '2. 进入 Settings → Access Tokens\n'
                    '3. 点击"New token"，选择"Read"权限\n'
                    '4. 访问 google/gemma-3n-E4B-it-litert-preview 模型页面\n'
                    '5. 点击"Agree and access repository"接受许可证\n'
                    '6. 复制生成的 token (以hf_开头)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '重要: 必须先在 HuggingFace 网站上接受 Gemma 模型的使用条款，否则会出现 403 错误',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _launchUrl('https://huggingface.co/google/gemma-3n-E4B-it-litert-preview'),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('访问模型页面'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _testHuggingFaceConnection,
                        icon: const Icon(Icons.network_check, size: 16),
                        label: const Text('测试连接'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      // 这里应该使用 url_launcher 包，但为了简化，我们先用系统方法
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请在浏览器中访问: $url'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '复制链接',
            onPressed: () {
              // 这里应该实现复制到剪贴板功能
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开链接: $e')),
      );
    }
  }

  Future<void> _testHuggingFaceConnection() async {
    if (!_settings.isHuggingFaceConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 HuggingFace Access Token')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在测试连接...')),
    );

    try {
      final token = _settings.huggingfaceToken!;
      
      // 先检查 token 格式
      if (!token.startsWith('hf_') || token.length < 20) {
        throw Exception('Token 格式不正确，应该以 hf_ 开头且长度足够');
      }

      // 创建 HuggingFace 客户端测试连接
      final testClient = HuggingFaceClient(accessToken: token);
      final isConnected = await testClient.testConnection();
      
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ HuggingFace 连接测试成功！可以开始下载模型'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '前往下载',
              onPressed: () {
                Navigator.pushNamed(context, '/embedded-model');
              },
            ),
          ),
        );
      } else {
        throw Exception('无法连接到 HuggingFace API，请检查网络或 token 权限');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 连接测试失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '确定',
            onPressed: () {},
          ),
        ),
      );
    }
  }
}