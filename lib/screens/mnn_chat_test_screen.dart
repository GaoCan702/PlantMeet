import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/mnn_chat_service.dart';
import '../services/test_image_manager.dart';
import '../models/app_settings.dart';
import '../models/recognition_result.dart';

/// MNN Chat 可观测性测试页面
class MNNChatTestScreen extends StatefulWidget {
  final AppSettings appSettings;

  const MNNChatTestScreen({
    Key? key,
    required this.appSettings,
  }) : super(key: key);

  @override
  State<MNNChatTestScreen> createState() => _MNNChatTestScreenState();
}

class _MNNChatTestScreenState extends State<MNNChatTestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // 服务和状态
  MNNChatService? _mnnChatService;
  bool _isConnecting = false;
  bool _isTesting = false;
  Map<String, dynamic> _connectionStatus = {};
  
  // 测试相关
  File? _selectedImage;
  TestImageInfo? _selectedPresetImage;
  String _customPrompt = '';
  bool _quickMode = false;
  
  // 日志和结果
  final List<TestLogEntry> _testLogs = [];
  final ScrollController _logScrollController = ScrollController();
  RecognitionResponse? _lastResult;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mnnChatService = MNNChatService();
    _customPrompt = _getDefaultPrompt();
    
    // 初始化测试图片管理器
    TestImageManager.initializePresetImages().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // 初始化MNN Chat连接
    _initializeConnection();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logScrollController.dispose();
    _mnnChatService?.dispose();
    super.dispose();
  }
  
  /// 初始化MNN Chat连接
  Future<void> _initializeConnection() async {
    setState(() {
      _isConnecting = true;
      _addLog('正在连接MNN Chat服务...', LogLevel.info);
    });
    
    try {
      final success = await _mnnChatService!.initialize();
      _connectionStatus = _mnnChatService!.getStatus();
      
      _addLog(
        success ? 'MNN Chat连接成功' : 'MNN Chat连接失败', 
        success ? LogLevel.success : LogLevel.error
      );
      
      if (success) {
        _addLog('模型: ${_connectionStatus['target_model']}', LogLevel.info);
        _addLog('视觉支持: ${_connectionStatus['features']['vision_support']}', LogLevel.info);
      }
    } catch (e) {
      _addLog('连接异常: $e', LogLevel.error);
      _connectionStatus = {'error': e.toString()};
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }
  
  /// 添加测试日志
  void _addLog(String message, LogLevel level) {
    final log = TestLogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    );
    
    setState(() {
      _testLogs.add(log);
    });
    
    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  /// 执行识别测试
  Future<void> _runTest() async {
    if (_selectedImage == null) {
      _addLog('请先选择测试图片', LogLevel.warning);
      return;
    }
    
    setState(() {
      _isTesting = true;
      _lastResult = null;
    });
    
    final stopwatch = Stopwatch()..start();
    
    try {
      _addLog('开始植物识别测试...', LogLevel.info);
      _addLog('图片: ${_selectedImage!.path.split('/').last}', LogLevel.info);
      _addLog('模式: ${_quickMode ? '快速识别' : '详细识别'}', LogLevel.info);
      
      // 显示发送的提示词
      if (_customPrompt.isNotEmpty) {
        _addLog('===== 发送的提示词 =====', LogLevel.debug);
        _addLog(_customPrompt, LogLevel.debug);
        _addLog('========================', LogLevel.debug);
      }
      
      // 实时状态监控
      _addLog('正在处理图片...', LogLevel.info);
      _addLog('连接MNN Chat服务...', LogLevel.info);
      
      // 调用识别服务并添加实时状态更新
      final result = await _runTestWithMonitoring();
      
      stopwatch.stop();
      _lastResult = result;
      
      _addLog('识别完成，总耗时: ${stopwatch.elapsedMilliseconds}ms', LogLevel.success);
      
      if (result.success) {
        _addLog('识别成功，找到 ${result.results.length} 个结果', LogLevel.success);
        for (int i = 0; i < result.results.length; i++) {
          final plant = result.results[i];
          _addLog('结果 ${i + 1}: ${plant.name} (置信度: ${(plant.confidence * 100).toStringAsFixed(1)}%)', LogLevel.info);
        }
        
        // 显示详细的识别结果分析
        _logDetailedResults(result);
      } else {
        _addLog('识别失败: ${result.error}', LogLevel.error);
      }
      
      // 如果是预设图片，显示期望结果对比
      if (_selectedPresetImage != null) {
        _addLog('期望结果: ${_selectedPresetImage!.expectedResult}', LogLevel.info);
        if (result.success && result.results.isNotEmpty) {
          final actualResult = result.results.first.name;
          final isMatch = actualResult.contains(_selectedPresetImage!.expectedResult) ||
                         _selectedPresetImage!.expectedResult.contains(actualResult);
          _addLog(
            '结果匹配: ${isMatch ? '✅ 匹配' : '❌ 不匹配'}',
            isMatch ? LogLevel.success : LogLevel.warning
          );
        }
      }
      
    } catch (e) {
      stopwatch.stop();
      _addLog('测试异常: $e', LogLevel.error);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }
  
  /// 带监控的测试执行
  Future<RecognitionResponse> _runTestWithMonitoring() async {
    final requestStopwatch = Stopwatch()..start();
    
    // 监控图片预处理
    _addLog('预处理图片...', LogLevel.debug);
    final imageSize = await _selectedImage!.length();
    _addLog('原始图片大小: ${_formatFileSize(imageSize)}', LogLevel.debug);
    
    try {
      // 调用识别服务
      _addLog('发送识别请求...', LogLevel.debug);
      final result = await _mnnChatService!.identifyPlant(
        _selectedImage!,
        quickMode: _quickMode,
      );
      
      requestStopwatch.stop();
      _addLog('API请求耗时: ${requestStopwatch.elapsedMilliseconds}ms', LogLevel.debug);
      
      return result;
    } catch (e) {
      requestStopwatch.stop();
      _addLog('API请求失败，耗时: ${requestStopwatch.elapsedMilliseconds}ms', LogLevel.error);
      rethrow;
    }
  }
  
  /// 记录详细识别结果
  void _logDetailedResults(RecognitionResponse result) {
    _addLog('===== 详细识别结果 =====', LogLevel.debug);
    
    for (int i = 0; i < result.results.length; i++) {
      final plant = result.results[i];
      _addLog('结果 ${i + 1}:', LogLevel.debug);
      _addLog('  名称: ${plant.name}', LogLevel.debug);
      if (plant.nickname != null) {
        _addLog('  别名: ${plant.nickname}', LogLevel.debug);
      }
      _addLog('  置信度: ${(plant.confidence * 100).toStringAsFixed(1)}%', LogLevel.debug);
      _addLog('  安全等级: ${plant.safety.level.name}', LogLevel.debug);
      
      if (plant.features.isNotEmpty) {
        _addLog('  特征: ${plant.features.join(', ')}', LogLevel.debug);
      }
      
      if (plant.tags.isNotEmpty) {
        _addLog('  标签: ${plant.tags.join(', ')}', LogLevel.debug);
      }
      
      if (i < result.results.length - 1) {
        _addLog('  ----', LogLevel.debug);
      }
    }
    
    _addLog('=======================', LogLevel.debug);
  }
  
  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  /// 选择预设测试图片
  Future<void> _selectPresetImage(TestImageInfo imageInfo) async {
    try {
      final imageFile = await TestImageManager.getPresetImageFile(imageInfo.id);
      if (await imageFile.exists()) {
        setState(() {
          _selectedImage = imageFile;
          _selectedPresetImage = imageInfo;
        });
        _addLog('选择预设图片: ${imageInfo.name}', LogLevel.info);
      } else {
        _addLog('预设图片不存在，正在生成...', LogLevel.warning);
        await TestImageManager.initializePresetImages();
        setState(() {});
      }
    } catch (e) {
      _addLog('选择预设图片失败: $e', LogLevel.error);
    }
  }
  
  /// 选择自定义图片
  Future<void> _selectCustomImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final file = File(image.path);
        final savedFile = await TestImageManager.saveUserTestImage(file);
        
        setState(() {
          _selectedImage = savedFile;
          _selectedPresetImage = null; // 清除预设选择
        });
        
        _addLog('选择自定义图片: ${image.name}', LogLevel.info);
      }
    } catch (e) {
      _addLog('选择自定义图片失败: $e', LogLevel.error);
    }
  }
  
  /// 清空日志
  void _clearLogs() {
    setState(() {
      _testLogs.clear();
      _lastResult = null;
    });
  }
  
  /// 处理提示词操作
  void _handlePromptAction(String action) {
    switch (action) {
      case 'reset':
        _resetPromptToDefault();
        break;
      case 'templates':
        _showPromptTemplates();
        break;
      case 'save':
        _savePromptTemplate();
        break;
    }
  }
  
  /// 重置提示词为默认值
  void _resetPromptToDefault() {
    setState(() {
      _customPrompt = _getDefaultPrompt();
    });
    _addLog('提示词已重置为默认', LogLevel.info);
  }
  
  /// 显示提示词模板选择器
  void _showPromptTemplates() {
    final templates = _getPromptTemplates();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择提示词模板'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  leading: Icon(template['icon'] as IconData),
                  title: Text(template['name'] as String),
                  subtitle: Text(template['description'] as String),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _customPrompt = template['content'] as String;
                    });
                    _addLog('已应用模板: ${template['name']}', LogLevel.info);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
  
  /// 保存自定义提示词模板
  void _savePromptTemplate() {
    if (_customPrompt.isEmpty) {
      _addLog('提示词为空，无法保存', LogLevel.warning);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        String templateName = '';
        String templateDescription = '';
        
        return AlertDialog(
          title: const Text('保存提示词模板'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: '模板名称',
                  hintText: '输入模板名称...',
                ),
                onChanged: (value) => templateName = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: '模板描述',
                  hintText: '输入模板描述...',
                ),
                onChanged: (value) => templateDescription = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (templateName.isNotEmpty) {
                  // 这里可以实现保存到本地存储
                  Navigator.of(context).pop();
                  _addLog('模板已保存: $templateName', LogLevel.success);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
  
  /// 获取预定义提示词模板
  List<Map<String, dynamic>> _getPromptTemplates() {
    return [
      {
        'name': '基础识别',
        'description': '标准的植物识别提示词',
        'icon': Icons.search,
        'content': _getDefaultPrompt(),
      },
      {
        'name': '安全重点',
        'description': '重点关注植物安全性',
        'icon': Icons.security,
        'content': '''请分析图片中的植物并重点关注安全性。

重要要求：
1. 必须使用中文回答
2. 输出格式必须是有效的JSON
3. 特别关注毒性和安全风险
4. 提供详细的安全建议

请按以下JSON格式输出：

{
  "name": "植物中文名称",
  "confidence": "很确定|比较确定|可能是|不太确定",
  "safety": {
    "level": "safe|caution|toxic|dangerous",
    "description": "详细安全性说明",
    "warnings": ["具体安全警告"],
    "handling_tips": ["安全处理建议"]
  },
  "description": "植物描述"
}''',
      },
      {
        'name': '养护重点',
        'description': '重点提供养护建议',
        'icon': Icons.eco,
        'content': '''请分析图片中的植物并重点提供养护建议。

重要要求：
1. 必须使用中文回答
2. 输出格式必须是有效的JSON
3. 重点关注养护要求和技巧
4. 提供实用的养护建议

请按以下JSON格式输出：

{
  "name": "植物中文名称",
  "confidence": "很确定|比较确定|可能是|不太确定",
  "care": {
    "difficulty": "简单|适中|困难",
    "water": "浇水建议",
    "light": "光照需求",
    "temperature": "温度要求",
    "soil": "土壤要求",
    "tips": ["实用养护技巧"]
  },
  "description": "植物描述"
}''',
      },
      {
        'name': '教学模式',
        'description': '适合教学和学习的详细介绍',
        'icon': Icons.school,
        'content': '''请从教育角度分析图片中的植物。

重要要求：
1. 必须使用中文回答
2. 输出格式必须是有效的JSON
3. 提供教育性内容
4. 适合学习和分享

请按以下JSON格式输出：

{
  "name": "植物中文名称",
  "confidence": "很确定|比较确定|可能是|不太确定",
  "educational_info": {
    "classification": "植物分类",
    "characteristics": "形态特征",
    "habitat": "生长环境",
    "uses": "用途和价值",
    "interesting_facts": ["有趣知识"]
  },
  "description": "教育性描述"
}''',
      },
      {
        'name': '快速模式',
        'description': '简化的快速识别',
        'icon': Icons.speed,
        'content': '''请快速识别图片中的植物。

请按以下简化JSON格式输出：

{
  "name": "植物中文名称",
  "confidence": "很确定|比较确定|可能是|不太确定",
  "brief_description": "一句话描述",
  "safety_alert": "安全提醒（如果需要）"
}

保持简洁，专注核心信息。''',
      },
    ];
  }
  
  /// 获取默认提示词
  String _getDefaultPrompt() {
    return '''请分析图片中的植物并提供准确的识别结果。

重要要求：
1. 必须使用中文回答
2. 输出格式必须是有效的JSON
3. 优先考虑用户安全
4. 描述要生动易懂

请按以下JSON格式输出：

{
  "name": "通俗的中文植物名称",
  "confidence": "很确定|比较确定|可能是|不太确定",
  "description": "生动有趣的植物描述",
  "safety": {
    "level": "safe|caution|toxic|dangerous",
    "description": "安全性说明"
  }
}''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MNN Chat 测试'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: '连接状态'),
            Tab(icon: Icon(Icons.image), text: '图片测试'),
            Tab(icon: Icon(Icons.list), text: '测试日志'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isConnecting ? null : _initializeConnection,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionTab(),
          _buildImageTestTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }
  
  /// 连接状态页面
  Widget _buildConnectionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        16.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _connectionStatus['connected'] == true 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: _connectionStatus['connected'] == true 
                            ? Colors.green 
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MNN Chat 连接状态',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isConnecting) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    const Text('正在连接服务...')
                  ] else ...[
                    _buildStatusItem('服务地址', _connectionStatus['service_url']?.toString() ?? '未知'),
                    _buildStatusItem('目标模型', _connectionStatus['target_model']?.toString() ?? '未知'),
                    _buildStatusItem('连接状态', _connectionStatus['status']?.toString() ?? '未知'),
                    if (_connectionStatus['features'] != null) ...[
                      const Divider(),
                      Text('功能支持', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _buildStatusItem('视觉支持', _connectionStatus['features']['vision_support']?.toString() ?? '未知'),
                      _buildStatusItem('中文优化', _connectionStatus['features']['chinese_optimized']?.toString() ?? '未知'),
                      _buildStatusItem('上下文长度', _connectionStatus['features']['context_length']?.toString() ?? '未知'),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : _initializeConnection,
              child: _isConnecting 
                  ? const Text('连接中...') 
                  : const Text('重新连接'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 状态项显示
  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  /// 图片测试页面
  Widget _buildImageTestTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        16.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片选择区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('选择测试图片', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  
                  // 当前选择的图片
                  if (_selectedImage != null) ...[
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedPresetImage != null) ...[
                      Text('预设图片: ${_selectedPresetImage!.name}'),
                      Text('描述: ${_selectedPresetImage!.description}'),
                      Text('期望结果: ${_selectedPresetImage!.expectedResult}'),
                      Text('难度: ${_selectedPresetImage!.difficulty.name}'),
                    ] else ...[
                      Text('自定义图片: ${_selectedImage!.path.split('/').last}'),
                    ],
                    const SizedBox(height: 16),
                  ],
                  
                  // 图片选择按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectCustomImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('选择图片'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPresetImageDialog(),
                          icon: const Icon(Icons.image),
                          label: const Text('预设图片'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 测试配置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('测试配置', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('快速模式'),
                    subtitle: const Text('使用简化的识别流程'),
                    value: _quickMode,
                    onChanged: (value) {
                      setState(() {
                        _quickMode = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('自定义提示词', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          _handlePromptAction(value);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 18),
                                SizedBox(width: 8),
                                Text('重置为默认'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'templates',
                            child: Row(
                              children: [
                                Icon(Icons.library_books, size: 18),
                                SizedBox(width: 8),
                                Text('选择模板'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'save',
                            child: Row(
                              children: [
                                Icon(Icons.save, size: 18),
                                SizedBox(width: 8),
                                Text('保存模板'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // 编辑模式切换
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '提示词编辑器',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '字符数: ${_customPrompt.length}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextField(
                          controller: TextEditingController(text: _customPrompt),
                          maxLines: 8,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                            hintText: '输入自定义提示词...\n\n提示：\n- 使用中文描述需求\n- 包含输出格式要求\n- 明确安全性要求',
                            hintStyle: TextStyle(fontSize: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _customPrompt = value;
                            });
                          },
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 开始测试按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedImage != null && !_isTesting && _connectionStatus['connected'] == true)
                  ? _runTest
                  : null,
              icon: _isTesting 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isTesting ? '测试中...' : '开始测试'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          
          // 测试结果
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            _buildTestResult(),
          ],
        ],
      ),
    );
  }
  
  /// 显示预设图片选择对话框
  void _showPresetImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择预设测试图片'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: TestImageManager.getPresetImageInfos().map((info) {
                return ListTile(
                  leading: Icon(
                    Icons.image,
                    color: _getDifficultyColor(info.difficulty),
                  ),
                  title: Text(info.name),
                  subtitle: Text(info.description),
                  trailing: Text(info.difficulty.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectPresetImage(info);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
  
  /// 获取难度颜色
  Color _getDifficultyColor(TestDifficulty difficulty) {
    switch (difficulty) {
      case TestDifficulty.easy:
        return Colors.green;
      case TestDifficulty.medium:
        return Colors.orange;
      case TestDifficulty.hard:
        return Colors.red;
    }
  }
  
  /// 构建测试结果显示
  Widget _buildTestResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('测试结果', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            if (_lastResult!.success) ...[
              for (int i = 0; i < _lastResult!.results.length; i++) ...[
                _buildPlantResult(_lastResult!.results[i], i + 1),
                if (i < _lastResult!.results.length - 1) const Divider(),
              ],
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('识别失败', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('错误信息: ${_lastResult!.error}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建植物识别结果
  Widget _buildPlantResult(RecognitionResult result, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '结果 $index: ${result.name}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('置信度: ${(result.confidence * 100).toStringAsFixed(1)}%'),
        if (result.nickname != null) ...[
          Text('别名: ${result.nickname}'),
        ],
        if (result.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('描述: ${result.description}'),
        ],
        if (result.features.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('特征: ${result.features.join(', ')}'),
        ],
        const SizedBox(height: 8),
        // 安全信息
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSafetyColor(result.safety.level).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getSafetyColor(result.safety.level).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getSafetyIcon(result.safety.level),
                color: _getSafetyColor(result.safety.level),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '安全性: ${result.safety.description}',
                  style: TextStyle(
                    color: _getSafetyColor(result.safety.level),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (result.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: result.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.withOpacity(0.1),
                labelStyle: const TextStyle(fontSize: 10),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
  
  /// 获取安全等级颜色
  Color _getSafetyColor(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return Colors.green;
      case SafetyLevel.caution:
        return Colors.orange;
      case SafetyLevel.toxic:
      case SafetyLevel.dangerous:
        return Colors.red;
      case SafetyLevel.unknown:
        return Colors.grey;
    }
  }
  
  /// 获取安全等级图标
  IconData _getSafetyIcon(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return Icons.check_circle;
      case SafetyLevel.caution:
        return Icons.warning;
      case SafetyLevel.toxic:
      case SafetyLevel.dangerous:
        return Icons.dangerous;
      case SafetyLevel.unknown:
        return Icons.help;
    }
  }
  
  /// 测试日志页面
  Widget _buildLogsTab() {
    return Column(
      children: [
        // 日志操作栏
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                '测试日志 (${_testLogs.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: _clearLogs,
                icon: const Icon(Icons.clear_all),
                tooltip: '清空日志',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // 日志列表
        Expanded(
          child: _testLogs.isEmpty
              ? const Center(
                  child: Text('暂无测试日志'),
                )
              : ListView.builder(
                  controller: _logScrollController,
                  itemCount: _testLogs.length,
                  itemBuilder: (context, index) {
                    final log = _testLogs[index];
                    return _buildLogItem(log);
                  },
                ),
        ),
      ],
    );
  }
  
  /// 构建日志项
  Widget _buildLogItem(TestLogEntry log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getLogColor(log.level).withOpacity(0.05),
        border: Border(
          left: BorderSide(
            color: _getLogColor(log.level),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getLogIcon(log.level),
                color: _getLogColor(log.level),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(log.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLogColor(log.level).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  log.level.name.toUpperCase(),
                  style: TextStyle(
                    color: _getLogColor(log.level),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.message,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  /// 获取日志等级颜色
  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.purple;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
  
  /// 获取日志等级图标
  IconData _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.success:
        return Icons.check_circle;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }
  
  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}

/// 测试日志条目
class TestLogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  TestLogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });
}

/// 日志等级
enum LogLevel {
  debug,
  info,
  success,
  warning,
  error,
}