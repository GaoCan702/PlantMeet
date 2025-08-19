import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';
import '../widgets/copyable_error_message.dart';

class CloudServiceConfigScreen extends StatefulWidget {
  const CloudServiceConfigScreen({super.key});

  @override
  State<CloudServiceConfigScreen> createState() =>
      _CloudServiceConfigScreenState();
}

class _CloudServiceConfigScreenState extends State<CloudServiceConfigScreen> {
  late AppSettings _settings;
  final _formKey = GlobalKey<FormState>();
  final _cloudApiUrlController = TextEditingController();
  final _cloudApiKeyController = TextEditingController();
  late RecognitionService _recognitionService;
  bool _isApiKeyVisible = false;
  bool _isTesting = false;
  String _selectedService = 'gemini';
  
  // Gemini API预设配置
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';
  static const String _geminiApiKey = 'AIzaSyDNhhTj-7BW-5UinIjrrpspL9yrlyDGAlU';

  @override
  void initState() {
    super.initState();
    // 使用 Provider 提供的单例服务
    _recognitionService = Provider.of<RecognitionService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    _settings = appState.settings ?? AppSettings();
    
    // 设置默认的Gemini API配置
    _cloudApiUrlController.text = _settings.baseUrl ?? _geminiApiUrl;
    _cloudApiKeyController.text = _settings.apiKey ?? _geminiApiKey;
    
    // 如果是首次使用，自动设置为Gemini服务
    if (_settings.baseUrl == null || _settings.baseUrl!.isEmpty) {
      _cloudApiUrlController.text = _geminiApiUrl;
      _cloudApiKeyController.text = _geminiApiKey;
      _selectedService = 'gemini';
    } else if (_settings.baseUrl!.contains('generativelanguage.googleapis.com')) {
      _selectedService = 'gemini';
    } else {
      _selectedService = 'custom';
    }
  }

  @override
  void dispose() {
    _cloudApiUrlController.dispose();
    _cloudApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _autoSaveSettings() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final updatedSettings = _settings.copyWith(
      baseUrl: _cloudApiUrlController.text.isEmpty
          ? null
          : _cloudApiUrlController.text,
      apiKey: _cloudApiKeyController.text.isEmpty
          ? null
          : _cloudApiKeyController.text,
    );

    await appState.updateSettings(updatedSettings);
  }

  void _onSettingChanged() {
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
      appBar: AppBar(title: const Text('云端服务')),
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
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildConfigurationSection(),
            const SizedBox(height: 24),
            _buildTestSection(),
            const SizedBox(height: 24),
            _buildAdvancedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '云端识别服务',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '连接云端API进行高精度植物识别',
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
        _buildFeatureChip('🎯 高精度', Colors.blue),
        _buildFeatureChip('🚀 快速响应', Colors.green), 
        _buildFeatureChip('🔄 Gemini Vision', Colors.orange),
        _buildFeatureChip('🌍 BYOK模式', Colors.purple),
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

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('服务配置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            // 服务选择器
            _buildServiceSelector(),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用云端服务'),
              subtitle: const Text('使用云端API进行植物识别'),
              value: _settings.enableLocalRecognition, // 临时使用现有字段，后续可以添加专门的云端开关
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enableLocalRecognition: value);
                });
                _onSettingChanged();
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cloudApiUrlController,
              decoration: InputDecoration(
                labelText: '云端API地址',
                hintText: _selectedService == 'gemini' ? 'Gemini API地址（已预设）' : '输入云端植物识别API地址',
                helperText: _selectedService == 'gemini' 
                  ? 'Google Gemini Vision Pro API'
                  : '例如: https://api.plantnet.org/v2',
                suffixIcon: _selectedService == 'gemini' 
                  ? Icon(Icons.lock_outline, color: Colors.grey[600])
                  : null,
              ),
              enabled: _selectedService != 'gemini', // Gemini模式下禁用编辑
              onChanged: (value) {
                _onSettingChanged();
              },
              validator: (value) {
                if (_settings.enableLocalRecognition &&
                    (value == null || value.isEmpty)) {
                  return '启用云端服务需要配置API地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cloudApiKeyController,
              decoration: InputDecoration(
                labelText: 'API密钥',
                hintText: _selectedService == 'gemini' ? '已预设API密钥（可修改）' : '输入您的API密钥',
                helperText: _selectedService == 'gemini' 
                  ? 'Google Cloud Console获取Gemini API密钥 (BYOK)'
                  : '从API提供商获取的身份验证密钥',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedService == 'gemini')
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.blue[600]),
                        onPressed: _showGeminiApiInfo,
                        tooltip: 'Gemini API说明',
                      ),
                    IconButton(
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
                  ],
                ),
              ),
              obscureText: !_isApiKeyVisible,
              onChanged: (value) {
                _onSettingChanged();
              },
              validator: (value) {
                if (_settings.enableLocalRecognition &&
                    (value == null || value.isEmpty)) {
                  return '云端服务通常需要API密钥进行身份验证';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('连接测试', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '测试与云端API服务的连接状态和识别功能',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_isTesting ? '测试中...' : '测试连接'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _settings.enableLocalRecognition
                        ? () => _testRecognition()
                        : null,
                    icon: const Icon(Icons.science),
                    label: const Text('识别测试'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildApiStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
              const SizedBox(width: 8),
              Text(
                'API状态信息',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '状态：${_settings.enableLocalRecognition ? "已配置" : "未配置"}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text('连接：等待测试', style: Theme.of(context).textTheme.bodySmall),
          Text('最后测试：从未测试', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('高级选项', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.speed),
              title: const Text('请求超时'),
              subtitle: const Text('设置API请求的超时时间'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTimeoutSettings(),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security),
              title: const Text('安全设置'),
              subtitle: const Text('配置HTTPS和证书验证'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSecuritySettings(),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: const Text('使用统计'),
              subtitle: const Text('查看API调用次数和费用'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showUsageStats(),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline),
              title: const Text('支持的服务商'),
              subtitle: const Text('查看兼容的云端植物识别API'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSupportedProviders(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      ErrorSnackBar.show(context, message: '请先填写必要配置信息', title: '配置错误');
      return;
    }

    if (!_settings.enableLocalRecognition) {
      ErrorSnackBar.show(context, message: '请先启用云端服务', title: '配置错误');
      return;
    }

    setState(() {
      _isTesting = true;
      _settings = _settings.copyWith(
        baseUrl: _cloudApiUrlController.text.isEmpty
            ? null
            : _cloudApiUrlController.text,
        apiKey: _cloudApiKeyController.text.isEmpty
            ? null
            : _cloudApiKeyController.text,
      );
    });

    try {
      _recognitionService.updateSettings(_settings);
      final isConnected = await _recognitionService.testConnection(_settings);

      if (mounted) {
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('云端API连接测试成功！'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ErrorSnackBar.show(
            context,
            message: '连接测试失败，请检查API地址、密钥和网络连接',
            title: '连接错误',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, message: '连接测试异常：$e', title: '测试异常');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _testRecognition() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('识别功能测试'),
        content: const Text('识别功能测试需要上传图片到云端API。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performRecognitionTest();
            },
            child: const Text('开始测试'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRecognitionTest() async {
    // 这里可以实现实际的识别测试逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('识别功能测试功能待实现'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showTimeoutSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('请求超时设置'),
        content: const Text('当前超时时间：30秒\n\n您可以根据网络条件调整超时时间。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安全设置'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前安全配置：'),
              SizedBox(height: 8),
              Text('• HTTPS验证：启用'),
              Text('• 证书验证：启用'),
              Text('• API密钥加密：启用'),
              SizedBox(height: 16),
              Text('建议保持默认安全设置以保护您的数据。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showUsageStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用统计'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('本月使用统计：'),
              SizedBox(height: 8),
              Text('• API调用次数：0'),
              Text('• 成功识别：0'),
              Text('• 预计费用：\$0.00'),
              SizedBox(height: 16),
              Text('注意：具体费用以API提供商账单为准。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSupportedProviders() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支持的服务商'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('兼容的植物识别API服务：'),
              SizedBox(height: 16),
              Text('🌿 PlantNet API'),
              Text('   • 免费学术用途'),
              Text('   • 高质量植物数据库'),
              SizedBox(height: 8),
              Text('🔬 iNaturalist API'),
              Text('   • 社区驱动的识别'),
              Text('   • 广泛的生物识别'),
              SizedBox(height: 8),
              Text('🏢 商业API服务'),
              Text('   • Google Vision API'),
              Text('   • 自定义植物识别API'),
              SizedBox(height: 16),
              Text('配置时请参考对应服务商的API文档。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建服务选择器
  Widget _buildServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择云端服务',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Google Gemini'),
                subtitle: const Text('高精度视觉模型'),
                value: 'gemini',
                groupValue: _selectedService,
                onChanged: (value) {
                  setState(() {
                    _selectedService = value!;
                    if (value == 'gemini') {
                      _cloudApiUrlController.text = _geminiApiUrl;
                      _cloudApiKeyController.text = _geminiApiKey;
                    }
                  });
                  _onSettingChanged();
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('自定义API'),
                subtitle: const Text('其他服务商'),
                value: 'custom',
                groupValue: _selectedService,
                onChanged: (value) {
                  setState(() {
                    _selectedService = value!;
                    if (value == 'custom') {
                      _cloudApiUrlController.text = '';
                      _cloudApiKeyController.text = '';
                    }
                  });
                  _onSettingChanged();
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 显示Gemini API信息
  void _showGeminiApiInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Gemini API 说明'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '关于 Gemini API',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Google Gemini Vision Pro API'),
              Text('• 支持图像理解和植物识别'),
              Text('• BYOK (Bring Your Own Key) 模式'),
              Text('• 需要在 Google Cloud Console 启用'),
              SizedBox(height: 16),
              
              Text(
                '如何获取API密钥：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. 访问 Google AI Studio'),
              Text('2. 创建新的API密钥'),
              Text('3. 复制密钥并粘贴到此处'),
              SizedBox(height: 16),
              
              Text(
                '预设密钥说明：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('应用已预设测试用API密钥，您可以：'),
              Text('• 直接使用预设密钥测试功能'),
              Text('• 替换为您自己的API密钥'),
              Text('• 确保API密钥有足够的配额'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }
}
