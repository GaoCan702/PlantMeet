import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';
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
          padding: const EdgeInsets.all(16),
          children: [
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
}