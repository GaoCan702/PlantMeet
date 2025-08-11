import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';
import '../widgets/copyable_error_message.dart';

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