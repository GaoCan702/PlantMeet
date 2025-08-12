import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/recognition_result.dart';
import 'llm_prompt_templates.dart';

/// 本地大模型推理服务 - 支持Qwen2.5-VL等视觉语言模型
class LocalLLMService {
  // 本地推理服务配置
  static const String _defaultHost = '127.0.0.1';
  static const int _defaultPort = 8000;
  static const String _defaultModel = 'qwen2.5-vl-3b';
  
  final String host;
  final int port;
  final String modelName;
  final Duration timeout;
  
  late final String _baseUrl;
  bool _isInitialized = false;
  
  LocalLLMService({
    this.host = _defaultHost,
    this.port = _defaultPort,
    this.modelName = _defaultModel,
    this.timeout = const Duration(seconds: 30),
  }) {
    _baseUrl = 'http://$host:$port';
  }
  
  /// 初始化服务并检查模型可用性
  Future<bool> initialize() async {
    try {
      final isHealthy = await _checkHealth();
      final isModelLoaded = await _checkModelStatus();
      
      _isInitialized = isHealthy && isModelLoaded;
      return _isInitialized;
    } catch (e) {
      print('LocalLLMService initialization failed: $e');
      return false;
    }
  }
  
  /// 检查服务健康状态
  Future<bool> _checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// 检查模型加载状态
  Future<bool> _checkModelStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models/$modelName/status'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'loaded';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// 主要的植物识别接口
  Future<RecognitionResponse> identifyPlant(
    File imageFile, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) async {
    if (!_isInitialized) {
      return RecognitionResponse.error(
        error: '本地AI模型未就绪，请检查服务状态',
        method: RecognitionMethod.local,
      );
    }
    
    try {
      // 根据模式选择不同的提示词
      final prompt = quickMode 
          ? LLMPromptTemplates.getQuickIdentificationPrompt()
          : LLMPromptTemplates.getIdentificationPrompt(
              userContext: userContext,
              season: season,
              location: location,
            );
      
      // 调用大模型推理
      final response = await _callVisionModel(
        imageFile: imageFile,
        prompt: prompt,
        maxTokens: quickMode ? 512 : 1024,
      );
      
      // 解析结构化输出
      return await _parseModelResponse(response, quickMode);
      
    } catch (e) {
      return RecognitionResponse.error(
        error: '本地AI识别失败: $e',
        method: RecognitionMethod.local,
      );
    }
  }
  
  /// 专门的安全性检查
  Future<SafetyInfo> checkPlantSafety(File imageFile) async {
    try {
      final response = await _callVisionModel(
        imageFile: imageFile,
        prompt: LLMPromptTemplates.getSafetyCheckPrompt(),
        maxTokens: 512,
      );
      
      final data = json.decode(response);
      return SafetyInfo.fromJson(data);
    } catch (e) {
      return const SafetyInfo(
        level: SafetyLevel.unknown,
        description: '安全性检查失败',
        warnings: ['无法确定安全性，请谨慎处理'],
      );
    }
  }
  
  /// 获取养护建议
  Future<CareInfo?> getPlantCareAdvice(File imageFile) async {
    try {
      final response = await _callVisionModel(
        imageFile: imageFile,
        prompt: LLMPromptTemplates.getCareAdvicePrompt(),
        maxTokens: 800,
      );
      
      final data = json.decode(response);
      return CareInfo.fromJson(data['care_guide']);
    } catch (e) {
      return null;
    }
  }
  
  /// 调用视觉语言模型
  Future<String> _callVisionModel({
    required File imageFile,
    required String prompt,
    int maxTokens = 1024,
    double temperature = 0.1,
  }) async {
    // 将图片转换为base64
    final imageBytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    
    // 构建请求
    final request = {
      'model': modelName,
      'messages': [
        {
          'role': 'system',
          'content': LLMPromptTemplates.systemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'image': 'data:image/jpeg;base64,$imageBase64',
            },
            {
              'type': 'text', 
              'text': prompt,
            },
          ],
        },
      ],
      'max_tokens': maxTokens,
      'temperature': temperature,
      'response_format': {'type': 'json_object'}, // 强制JSON输出
    };
    
    final response = await http.post(
      Uri.parse('$_baseUrl/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(request),
    ).timeout(timeout);
    
    if (response.statusCode != 200) {
      throw Exception('Model inference failed: ${response.statusCode} - ${response.body}');
    }
    
    final responseData = json.decode(response.body);
    final content = responseData['choices'][0]['message']['content'];
    
    return content;
  }
  
  /// 解析模型响应并转换为应用数据结构
  Future<RecognitionResponse> _parseModelResponse(String response, bool quickMode) async {
    try {
      final data = json.decode(response);
      
      // 检查是否识别成功
      if (data['success'] != true) {
        return RecognitionResponse.error(
          error: data['error_message'] ?? '识别失败',
          method: RecognitionMethod.local,
        );
      }
      
      final results = <RecognitionResult>[];
      
      if (quickMode) {
        // 快速模式的简化解析
        results.add(_parseQuickResult(data));
      } else {
        // 完整模式的详细解析
        if (data['primary_result'] != null) {
          results.add(_parseDetailedResult(data['primary_result']));
        }
        
        // 解析备选结果
        if (data['alternatives'] != null) {
          for (var alt in data['alternatives']) {
            results.add(_parseAlternativeResult(alt));
          }
        }
      }
      
      return RecognitionResponse.success(
        results: results,
        method: RecognitionMethod.local,
      );
      
    } catch (e) {
      // JSON解析失败，尝试从文本中提取信息
      return await _fallbackParsing(response);
    }
  }
  
  /// 解析快速识别结果
  RecognitionResult _parseQuickResult(Map<String, dynamic> data) {
    return RecognitionResult(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '未知植物',
      confidence: _parseConfidence(data['confidence']),
      description: data['brief_description'] ?? '暂无描述',
      features: [],
      safety: _parseSafetyFromAlert(data['safety_alert']),
      season: null,
      locations: [],
      tags: ['快速识别'],
    );
  }
  
  /// 解析详细识别结果
  RecognitionResult _parseDetailedResult(Map<String, dynamic> data) {
    return RecognitionResult(
      id: 'detailed_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '未知植物',
      nickname: data['nickname'],
      confidence: _parseConfidence(data['confidence'] ?? '不太确定'),
      description: data['description'] ?? '',
      features: List<String>.from(data['key_features'] ?? []),
      safety: SafetyInfo.fromJson(data['safety'] ?? {}),
      care: data['care_tips'] != null ? CareInfo.fromJson(data['care_tips']) : null,
      season: data['life_info']?['season'],
      locations: List<String>.from(data['life_info']?['locations'] ?? []),
      funFact: data['fun_fact'],
      tags: List<String>.from(data['life_info']?['tags'] ?? []),
      scientificName: data['scientific_info']?['scientific_name'],
      family: data['scientific_info']?['family'],
    );
  }
  
  /// 解析备选结果
  RecognitionResult _parseAlternativeResult(Map<String, dynamic> data) {
    return RecognitionResult(
      id: 'alt_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '备选植物',
      confidence: 0.5, // 备选结果置信度较低
      description: data['confidence_note'] ?? '',
      features: [],
      safety: const SafetyInfo(
        level: SafetyLevel.unknown,
        description: '备选结果，请谨慎参考',
        warnings: [],
      ),
      locations: [],
      tags: ['备选结果'],
    );
  }
  
  /// 从安全警告解析安全信息
  SafetyInfo _parseSafetyFromAlert(String? alert) {
    if (alert == null || alert.isEmpty) {
      return const SafetyInfo(
        level: SafetyLevel.safe,
        description: '暂无安全风险',
        warnings: [],
      );
    }
    
    return SafetyInfo(
      level: SafetyLevel.caution,
      description: '需要注意安全',
      warnings: [alert],
    );
  }
  
  /// 解析置信度文本为数值
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
  
  /// 降级解析（当JSON解析失败时）
  Future<RecognitionResponse> _fallbackParsing(String response) async {
    // 尝试从自然语言响应中提取信息
    // 这里可以用简单的正则表达式或关键词匹配
    
    return RecognitionResponse.error(
      error: '模型输出格式异常，请重试',
      method: RecognitionMethod.local,
    );
  }
  
  /// 获取模型信息
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models/$modelName/info'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get model info');
    } catch (e) {
      return {
        'error': e.toString(),
        'model': modelName,
        'status': 'unknown',
      };
    }
  }
  
  /// 预热模型（首次推理会比较慢）
  Future<bool> warmupModel() async {
    try {
      // 创建一个小的测试图片
      final testImageData = Uint8List.fromList([
        // 这里应该是一个很小的测试图片的字节数据
        // 为了简化，我们跳过实际的预热
      ]);
      
      // TODO: 实现实际的模型预热逻辑
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 清理资源
  void dispose() {
    _isInitialized = false;
  }
  
  /// 服务状态检查
  bool get isReady => _isInitialized;
  String get status => _isInitialized ? 'ready' : 'not_ready';
}