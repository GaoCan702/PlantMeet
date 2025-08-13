import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';
import '../widgets/copyable_error_message.dart';
import 'mnn_chat_test_screen.dart';

class MNNChatConfigScreen extends StatefulWidget {
  const MNNChatConfigScreen({super.key});

  @override
  State<MNNChatConfigScreen> createState() => _MNNChatConfigScreenState();
}

class _MNNChatConfigScreenState extends State<MNNChatConfigScreen> {
  late AppSettings _settings;
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final RecognitionService _recognitionService = RecognitionService();
  bool _isApiKeyVisible = false;
  bool _isTesting = false;

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
        title: const Text('MNN Chat服务'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
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
                  Icons.computer,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MNN Chat本地服务',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '连接到本地MNN Chat API进行植物识别',
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
        _buildFeatureChip('🔐 隐私安全', Colors.green),
        _buildFeatureChip('⚡ 低延迟', Colors.blue),
        _buildFeatureChip('💰 零成本', Colors.orange),
        _buildFeatureChip('🔧 自托管', Colors.purple),
      ],
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '服务配置',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用MNN Chat服务'),
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
                hintText: '输入MNN Chat服务的API地址',
                helperText: '例如: http://localhost:8080',
              ),
              onChanged: (value) {
                _onSettingChanged();
              },
              validator: (value) {
                if (_settings.enableLocalRecognition && (value == null || value.isEmpty)) {
                  return '启用MNN Chat服务需要配置API地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API密钥',
                hintText: '输入您的API密钥',
                helperText: '可选，如果服务需要身份验证',
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
            Text(
              '连接测试',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '测试与MNN Chat服务的连接状态',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
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
                        ? () => _openTestScreen()
                        : null,
                    icon: const Icon(Icons.science),
                    label: const Text('功能测试'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            Text(
              '高级选项',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('服务状态'),
              subtitle: Text(
                _settings.enableLocalRecognition 
                    ? 'MNN Chat服务已启用'
                    : 'MNN Chat服务已禁用',
              ),
              trailing: Icon(
                _settings.enableLocalRecognition 
                    ? Icons.check_circle 
                    : Icons.radio_button_unchecked,
                color: _settings.enableLocalRecognition 
                    ? Colors.green 
                    : Colors.grey,
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_suggest),
              title: const Text('推荐配置'),
              subtitle: const Text('查看MNN Chat服务的推荐配置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRecommendedConfig(),
            ),
          ],
        ),
      ),
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
        message: '请先启用MNN Chat服务',
        title: '配置错误',
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _settings = _settings.copyWith(
        baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
        apiKey: _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
      );
    });

    try {
      _recognitionService.updateSettings(_settings);
      final isConnected = await _recognitionService.testConnection(_settings);

      if (mounted) {
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MNN Chat连接测试成功！'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ErrorSnackBar.show(
            context,
            message: '连接测试失败，请检查API地址和网络连接',
            title: '连接错误',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: '连接测试异常：$e',
          title: '测试异常',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  void _openTestScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MNNChatTestScreen(
          appSettings: _settings,
        ),
      ),
    );
  }

  void _showRecommendedConfig() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('推荐配置'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('MNN Chat服务推荐配置：'),
              SizedBox(height: 16),
              Text('1. API地址'),
              Text('   • 本地：http://localhost:8080'),
              Text('   • 局域网：http://192.168.x.x:8080'),
              SizedBox(height: 8),
              Text('2. 端口配置'),
              Text('   • 默认端口：8080'),
              Text('   • 确保端口未被占用'),
              SizedBox(height: 8),
              Text('3. 网络要求'),
              Text('   • 设备需在同一网络'),
              Text('   • 防火墙允许访问'),
              SizedBox(height: 8),
              Text('4. 性能建议'),
              Text('   • 使用有线网络连接'),
              Text('   • 确保服务器性能充足'),
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
}