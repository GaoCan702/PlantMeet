import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/recognition_result.dart';
import 'llm_performance_optimizer.dart';

/// MNN Chat API服务 - 专门适配MNN Chat本地部署的Qwen2.5-VL-3B模型
class MNNChatService {
  final Logger _logger = Logger();
  final String baseUrl;
  final Duration timeout;
  final bool enableImageOptimization;

  // MNN Chat专用配置
  static const String _targetModel = 'qwen2.5-vl-3b';
  static const int _maxImageSize = 768; // MNN优化的图片尺寸
  static const int _contextLength = 8192; // Qwen2.5-VL上下文长度

  // 连接状态
  bool _isConnected = false;
  String _connectionStatus = 'disconnected';
  Map<String, dynamic> _modelInfo = {};

  MNNChatService({
    this.baseUrl = 'http://127.0.0.1:8080', // MNN Chat常用端口
    this.timeout = const Duration(seconds: 45),
    this.enableImageOptimization = true,
  });

  /// 初始化MNN Chat连接，专门适配Qwen2.5-VL-3B模型
  Future<bool> initialize() async {
    try {
      _logger.i('🔍 正在连接MNN Chat...');

      // 1. 检查MNN Chat服务状态
      final isHealthy = await _checkMNNChatHealth();
      if (!isHealthy) {
        _connectionStatus = 'mnn_chat_not_available';
        return false;
      }

      // 2. 检查Qwen2.5-VL-3B模型是否就绪
      final isModelReady = await _checkQwenVLModel();
      if (!isModelReady) {
        _connectionStatus = 'qwen_vl_model_not_ready';
        return false;
      }

      // 3. 获取模型信息
      _modelInfo = await _getQwenVLModelInfo();

      _isConnected = true;
      _connectionStatus = 'qwen_vl_ready';

      _logger.i('✅ MNN Chat + Qwen2.5-VL-3B 初始化成功');
      _logger.i('  服务地址: $baseUrl');
      _logger.i('  模型: $_targetModel');
      _logger.i('  视觉理解: 支持');
      _logger.i('  上下文长度: $_contextLength');

      return true;
    } catch (e) {
      _connectionStatus = 'initialization_failed: $e';
      _logger.e('❌ MNN Chat初始化失败: $e');
      return false;
    }
  }

  /// 检查MNN Chat服务状态
  Future<bool> _checkMNNChatHealth() async {
    try {
      // 尝试多个常用的健康检查端点
      final endpoints = ['/health', '/status', '/ping', '/api/health'];

      for (final endpoint in endpoints) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl$endpoint'),
                headers: {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            _logger.i('✅ MNN Chat服务响应正常: $endpoint');
            return true;
          }
        } catch (e) {
          // 继续尝试下一个端点
          continue;
        }
      }

      return false;
    } catch (e) {
      _logger.w('⚠️ MNN Chat健康检查失败: $e');
      return false;
    }
  }

  /// 检查Qwen2.5-VL-3B模型是否就绪
  Future<bool> _checkQwenVLModel() async {
    try {
      // 尝试多个可能的模型查询端点
      final endpoints = [
        '/v1/models',
        '/api/models',
        '/models',
        '/api/v1/models',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl$endpoint'),
                headers: {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            // 检查响应中是否包含Qwen2.5-VL模型
            if (_containsQwenVLModel(data)) {
              _logger.i('✅ 找到Qwen2.5-VL-3B模型');
              return true;
            }
          }
        } catch (e) {
          continue;
        }
      }

      _logger.w('⚠️ 未找到Qwen2.5-VL-3B模型，尝试直接连接...');
      return true; // 先假设可用，在实际调用时再验证
    } catch (e) {
      _logger.w('⚠️ 模型检查失败: $e');
      return false;
    }
  }

  /// 检查响应中是否包含Qwen VL模型
  bool _containsQwenVLModel(Map<String, dynamic> data) {
    // 尝试不同的响应格式
    if (data['data'] is List) {
      final models = data['data'] as List;
      return models.any((model) {
        final id = model['id']?.toString().toLowerCase() ?? '';
        return id.contains('qwen') &&
            (id.contains('vl') || id.contains('vision'));
      });
    }

    if (data['models'] is List) {
      final models = data['models'] as List;
      return models.any((model) {
        final name = model.toString().toLowerCase();
        return name.contains('qwen') &&
            (name.contains('vl') || name.contains('vision'));
      });
    }

    // 检查字符串形式
    final responseStr = data.toString().toLowerCase();
    return responseStr.contains('qwen') &&
        (responseStr.contains('vl') || responseStr.contains('vision'));
  }

  /// 获取Qwen2.5-VL-3B模型信息
  Future<Map<String, dynamic>> _getQwenVLModelInfo() async {
    final defaultInfo = {
      'model_name': 'qwen2.5-vl-3b',
      'max_tokens': 2048,
      'context_length': _contextLength,
      'supports_vision': true,
      'supports_chinese': true,
      'optimized_for': 'mobile_inference',
      'recommended_image_size': _maxImageSize,
    };

    try {
      // 尝试获取模型具体信息
      final endpoints = [
        '/v1/models/$_targetModel',
        '/api/models/$_targetModel',
        '/model/info',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl$endpoint'),
                headers: {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return {...defaultInfo, ...data}; // 合并默认和获取的信息
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      _logger.w('⚠️ 获取模型信息失败，使用默认配置: $e');
    }

    return defaultInfo;
  }

  /// 植物识别主接口
  Future<RecognitionResponse> identifyPlant(
    File imageFile, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) async {
    if (!_isConnected) {
      return RecognitionResponse.error(
        error: 'MNN Chat未连接: $_connectionStatus',
        method: RecognitionMethod.local,
      );
    }

    try {
      // 1. 图片预处理（如果启用）
      File processedImage = imageFile;
      if (enableImageOptimization) {
        processedImage = await LLMPerformanceOptimizer.optimizeImageForLLM(
          imageFile,
        );
      }

      // 2. 准备适配Qwen2.5-VL的提示词
      final prompt = _prepareQwenVLPrompt(
        userContext: userContext,
        season: season,
        location: location,
        quickMode: quickMode,
      );

      // 3. 调用Qwen2.5-VL-3B模型
      final response = await _callQwenVLModel(
        processedImage,
        prompt,
        quickMode,
      );

      // 4. 解析响应
      final result = await _parseResponse(response, quickMode);

      // 5. 清理临时文件
      if (enableImageOptimization && processedImage.path != imageFile.path) {
        try {
          await processedImage.delete();
        } catch (e) {
          // 忽略删除失败
        }
      }

      return result;
    } catch (e) {
      return RecognitionResponse.error(
        error: 'MNN Chat识别失败: $e',
        method: RecognitionMethod.local,
      );
    }
  }

  /// 准备适合Qwen2.5-VL的提示词
  String _prepareQwenVLPrompt({
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) {
    final systemPrompt = '''
你是专业的植物识别助手，请分析图片中的植物并提供准确的识别结果。

重要要求：
1. 必须使用中文回答
2. 输出格式必须是有效的JSON
3. 优先考虑用户安全
4. 描述要生动易懂
''';

    if (quickMode) {
      return '''$systemPrompt

请快速识别图片中的植物，按以下JSON格式输出：

{
  "name": "植物中文名称",
  "confidence": "很确定|比较确定|可能是|不太确定",
  "safety_level": "safe|caution|toxic|dangerous",
  "brief_description": "一句话描述",
  "key_tip": "重要提醒或养护建议"
}
''';
    }

    final contextInfo = _buildContextInfo(userContext, season, location);

    return '''$systemPrompt

$contextInfo

请详细识别图片中的植物，按以下JSON格式输出：

{
  "name": "通俗的中文植物名称",
  "nickname": "别名（如果有）",
  "confidence": "很确定|比较确定|可能是|不太确定",
  "description": "生动有趣的植物描述",
  "key_features": ["特征1", "特征2", "特征3"],
  "safety": {
    "level": "safe|caution|toxic|dangerous",
    "description": "安全性说明",
    "warnings": ["具体警告"]
  },
  "care": {
    "difficulty": "简单|适中|困难",
    "water": "浇水建议",
    "light": "光照需求",
    "tips": ["实用建议"]
  },
  "fun_fact": "有趣的植物知识",
  "season": "常见季节",
  "locations": ["常见地点"],
  "tags": ["标签"]
}

如果不确定或无法识别，请在name字段返回"无法确定"并说明原因。
''';
  }

  /// 构建上下文信息
  String _buildContextInfo(
    String? userContext,
    String? season,
    String? location,
  ) {
    final parts = <String>[];

    if (season != null && season.isNotEmpty) {
      parts.add('当前季节：$season');
    }

    if (location != null && location.isNotEmpty) {
      parts.add('地理位置：$location');
    }

    if (userContext != null && userContext.isNotEmpty) {
      parts.add('用户说明：$userContext');
    }

    if (parts.isEmpty) {
      return '';
    }

    return '额外信息：\n${parts.join('\n')}\n';
  }

  /// 调用Qwen2.5-VL-3B模型
  Future<String> _callQwenVLModel(
    File imageFile,
    String prompt,
    bool quickMode,
  ) async {
    // 将图片转换为base64
    final imageBytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    final imageMimeType = _getImageMimeType(imageFile.path);

    // 构建符合OpenAI格式的请求
    final requestBody = {
      'model': _targetModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$imageMimeType;base64,$imageBase64'},
            },
          ],
        },
      ],
      'max_tokens': quickMode ? 512 : 1024,
      'temperature': quickMode ? 0.1 : 0.2,
      'top_p': 0.9,
      'stream': false,
      // MNN Chat特有参数
      'response_format': {'type': 'json_object'},
    };

    final response = await http
        .post(
          Uri.parse('$baseUrl/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(requestBody),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('API请求失败: ${response.statusCode} - ${response.body}');
    }

    final responseData = json.decode(response.body);

    if (responseData['error'] != null) {
      throw Exception('API错误: ${responseData['error']['message']}');
    }

    final choices = responseData['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('API返回空结果');
    }

    final content = choices[0]['message']['content'];
    if (content == null || content.isEmpty) {
      throw Exception('API返回内容为空');
    }

    return content;
  }

  /// 解析MNN Chat的响应
  Future<RecognitionResponse> _parseResponse(
    String response,
    bool quickMode,
  ) async {
    try {
      final data = json.decode(response);

      if (quickMode) {
        return _parseQuickResponse(data);
      } else {
        return _parseDetailedResponse(data);
      }
    } catch (e) {
      // JSON解析失败，尝试从文本中提取信息
      return _parseFallbackResponse(response);
    }
  }

  /// 解析快速模式响应
  RecognitionResponse _parseQuickResponse(Map<String, dynamic> data) {
    final result = RecognitionResult(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '未知植物',
      confidence: _parseConfidence(data['confidence']),
      description: data['brief_description'] ?? data['key_tip'] ?? '暂无描述',
      features: [],
      safety: SafetyInfo(
        level: _parseSafetyLevel(data['safety_level']),
        description: data['key_tip'] ?? '请注意安全',
        warnings: [],
      ),
      locations: [],
      tags: ['MNN Chat', '快速识别'],
    );

    return RecognitionResponse.success(
      results: [result],
      method: RecognitionMethod.local,
    );
  }

  /// 解析详细模式响应
  RecognitionResponse _parseDetailedResponse(Map<String, dynamic> data) {
    if (data['name'] == '无法确定') {
      return RecognitionResponse.error(
        error: data['description'] ?? '无法识别图片中的植物',
        method: RecognitionMethod.local,
      );
    }

    final result = RecognitionResult(
      id: 'detailed_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '未知植物',
      nickname: data['nickname'],
      confidence: _parseConfidence(data['confidence']),
      description: data['description'] ?? '',
      features: List<String>.from(data['key_features'] ?? []),
      safety: _parseSafetyInfo(data['safety']),
      care: _parseCareInfo(data['care']),
      season: data['season'],
      locations: List<String>.from(data['locations'] ?? []),
      funFact: data['fun_fact'],
      tags: ['MNN Chat', '详细识别', ...List<String>.from(data['tags'] ?? [])],
    );

    return RecognitionResponse.success(
      results: [result],
      method: RecognitionMethod.local,
    );
  }

  /// 降级解析（当JSON解析失败时）
  RecognitionResponse _parseFallbackResponse(String response) {
    // 尝试从自然语言中提取基本信息
    final lines = response.split('\n');
    String name = '识别结果异常';
    String description = '模型输出格式异常，请重试';

    for (final line in lines) {
      if (line.contains('植物') || line.contains('名称')) {
        // 简单的名称提取逻辑
        final match = RegExp(r'[:：](.+)').firstMatch(line);
        if (match != null) {
          name = match.group(1)?.trim() ?? name;
          break;
        }
      }
    }

    final result = RecognitionResult(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      confidence: 0.3,
      description: description,
      features: [],
      safety: const SafetyInfo(
        level: SafetyLevel.unknown,
        description: '无法确定安全性',
        warnings: ['输出格式异常，请谨慎参考'],
      ),
      locations: [],
      tags: ['MNN Chat', '格式异常'],
    );

    return RecognitionResponse.success(
      results: [result],
      method: RecognitionMethod.local,
    );
  }

  // 辅助解析方法
  double _parseConfidence(String? confidence) {
    switch (confidence) {
      case '很确定':
        return 0.9;
      case '比较确定':
        return 0.75;
      case '可能是':
        return 0.6;
      case '不太确定':
        return 0.4;
      default:
        return 0.5;
    }
  }

  SafetyLevel _parseSafetyLevel(String? level) {
    switch (level) {
      case 'safe':
        return SafetyLevel.safe;
      case 'caution':
        return SafetyLevel.caution;
      case 'toxic':
        return SafetyLevel.toxic;
      case 'dangerous':
        return SafetyLevel.dangerous;
      default:
        return SafetyLevel.unknown;
    }
  }

  SafetyInfo _parseSafetyInfo(Map<String, dynamic>? safetyData) {
    if (safetyData == null) {
      return const SafetyInfo(
        level: SafetyLevel.unknown,
        description: '安全信息不明',
        warnings: [],
      );
    }

    return SafetyInfo(
      level: _parseSafetyLevel(safetyData['level']),
      description: safetyData['description'] ?? '请注意安全',
      warnings: List<String>.from(safetyData['warnings'] ?? []),
    );
  }

  CareInfo? _parseCareInfo(Map<String, dynamic>? careData) {
    if (careData == null) return null;

    return CareInfo(
      difficulty: careData['difficulty'] ?? '未知',
      water: careData['water'] ?? '适量',
      light: careData['light'] ?? '适宜',
      temperature: careData['temperature'] ?? '常温',
      tips: List<String>.from(careData['tips'] ?? []),
    );
  }

  /// 获取图片MIME类型
  String _getImageMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// 从响应中提取内容
  String _extractContentFromResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);

      // 尝试不同的响应格式
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        final content = data['choices'][0]['message']['content'];
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }

      // 尝试直接内容格式
      if (data['content'] != null) {
        return data['content'];
      }

      // 尝试response格式
      if (data['response'] != null) {
        return data['response'];
      }

      // 尝试text格式
      if (data['text'] != null) {
        return data['text'];
      }

      throw Exception('无法从响帄中提取内容');
    } catch (e) {
      throw Exception('解析响应失败: $e');
    }
  }

  /// 获取MNN Chat + Qwen2.5-VL服务状态
  Map<String, dynamic> getStatus() {
    return {
      'connected': _isConnected,
      'status': _connectionStatus,
      'service_url': baseUrl,
      'target_model': _targetModel,
      'model_info': _modelInfo,
      'features': {
        'vision_support': true,
        'chinese_optimized': true,
        'mobile_optimized': true,
        'context_length': _contextLength,
        'max_image_size': _maxImageSize,
      },
      'performance': {
        'image_optimization': enableImageOptimization,
        'timeout_seconds': timeout.inSeconds,
      },
    };
  }

  /// 测试MNN Chat连接和Qwen2.5-VL模型
  Future<Map<String, dynamic>> testConnection() async {
    final testResult = {
      'mnn_chat_available': false,
      'qwen_vl_ready': false,
      'overall_status': 'failed',
      'error_message': null,
      'response_time_ms': 0,
    };

    final stopwatch = Stopwatch()..start();

    try {
      // 测试MNN Chat服务
      testResult['mnn_chat_available'] = await _checkMNNChatHealth();

      if (testResult['mnn_chat_available'] == true) {
        // 测试Qwen2.5-VL模型
        testResult['qwen_vl_ready'] = await _checkQwenVLModel();

        if (testResult['qwen_vl_ready'] == true) {
          testResult['overall_status'] = 'ready';
        } else {
          testResult['overall_status'] = 'model_not_ready';
          testResult['error_message'] = 'Qwen2.5-VL-3B 模型不可用';
        }
      } else {
        testResult['overall_status'] = 'service_unavailable';
        testResult['error_message'] = 'MNN Chat 服务不可用';
      }
    } catch (e) {
      testResult['overall_status'] = 'error';
      testResult['error_message'] = e.toString();
    } finally {
      stopwatch.stop();
      testResult['response_time_ms'] = stopwatch.elapsedMilliseconds;
    }

    return testResult;
  }

  /// 清理资源
  void dispose() {
    _isConnected = false;
    _connectionStatus = 'disposed';
    _modelInfo.clear();
    _logger.i('🗑️ MNN Chat服务已释放');
  }
}
