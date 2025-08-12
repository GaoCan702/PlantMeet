import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recognition_result.dart';
import '../models/app_settings.dart';
import '../models/plant_encounter.dart';
import 'mock_recognition_service.dart';
import 'mnn_chat_service.dart';

/// 植物识别服务 - 支持本地大模型和云端识别的生活化植物识别
class RecognitionService {
  static const bool _useMockData = true; // 开发阶段使用模拟数据
  static const bool _preferLocalLLM = true; // 优先使用本地大模型
  
  MNNChatService? _mnnChatService;
  bool _isMNNChatReady = false;
  
  RecognitionService() {
    _initializeMNNChat();
  }

  void initialize(AppSettings settings) async {
    // 初始化MNN Chat服务
    await _initializeMNNChat();
  }
  
  /// 初始化MNN Chat服务
  Future<void> _initializeMNNChat() async {
    if (!_preferLocalLLM) return;
    
    try {
      _mnnChatService = MNNChatService();
      _isMNNChatReady = await _mnnChatService!.initialize();
      
      if (_isMNNChatReady) {
        final status = _mnnChatService!.getStatus();
        print('✅ MNN Chat + Qwen2.5-VL-3B 初始化成功');
        print('  状态: ${status['status']}');
        print('  视觉理解: ${status['features']['vision_support']}');
      } else {
        print('⚠️ MNN Chat 初始化失败，将使用云端服务');
      }
    } catch (e) {
      print('❌ MNN Chat 初始化异常: $e');
      _isMNNChatReady = false;
    }
  }

  void updateSettings(AppSettings settings) {
    // 简化更新逻辑
  }

  /// 植物识别主入口 - 支持本地大模型和云端识别
  Future<RecognitionResponse> identifyPlant(
    File imageFile, 
    AppSettings settings, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) async {
    // 开发阶段使用模拟数据演示
    if (_useMockData) {
      return await _getMockRecognitionResult(imageFile);
    }
    
    // 优先尝试MNN Chat识别
    if (_isMNNChatReady && _mnnChatService != null) {
      final localResult = await _tryMNNChatRecognition(
        imageFile,
        userContext: userContext,
        season: season,
        location: location,
        quickMode: quickMode,
      );
      
      if (localResult.success && localResult.results.isNotEmpty) {
        return localResult;
      }
    }
    
    // 本地识别不可用或失败，尝试云端识别
    if (settings.isConfigured) {
      return await _tryCloudRecognition(imageFile, settings);
    }
    
    return RecognitionResponse.error(
      error: '无可用的识别服务，请启动MNN Chat或配置云端服务',
      method: RecognitionMethod.local,
    );
  }
  
  /// MNN Chat识别（Qwen2.5-VL-3B）
  Future<RecognitionResponse> _tryMNNChatRecognition(
    File imageFile, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) async {
    if (_mnnChatService == null || !_isMNNChatReady) {
      return RecognitionResponse.error(
        error: 'MNN Chat服务未就绪',
        method: RecognitionMethod.local,
      );
    }
    
    try {
      final result = await _mnnChatService!.identifyPlant(
        imageFile,
        userContext: userContext,
        season: season,
        location: location,
        quickMode: quickMode,
      );
      
      // 添加MNN Chat的特殊标识
      if (result.success && result.results.isNotEmpty) {
        result.results.forEach((plant) {
          plant.tags.add('MNN Chat');
          plant.tags.add('Qwen2.5-VL-3B');
          if (quickMode) plant.tags.add('快速模式');
        });
      }
      
      return result;
    } catch (e) {
      return RecognitionResponse.error(
        error: 'MNN Chat识别异常: $e',
        method: RecognitionMethod.local,
      );
    }
  }
  
  /// 云端AI识别（BYOK模式）
  Future<RecognitionResponse> _tryCloudRecognition(
    File imageFile,
    AppSettings settings,
  ) async {
    try {
      return await _identifyWithAPI(imageFile, settings);
    } catch (e) {
      return RecognitionResponse.error(
        error: '云端识别失败: $e',
        method: RecognitionMethod.cloud,
      );
    }
  }
  
  /// 模拟识别结果（开发阶段）
  Future<RecognitionResponse> _getMockRecognitionResult(File imageFile) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));
    
    // 模拟不同的识别结果
    final random = Random();
    final scenarios = [
      'sunflower',
      'rose', 
      'cactus',
      'bamboo',
      'common',
      'error',
      'empty'
    ];
    
    final scenario = scenarios[random.nextInt(scenarios.length)];
    
    switch (scenario) {
      case 'error':
        return MockRecognitionService.generateErrorResponse();
      case 'empty':
        return MockRecognitionService.generateEmptyResponse();
      default:
        return MockRecognitionService.generateMockResponse(plantType: scenario);
    }
  }

  /// 使用API进行植物识别（云端服务）
  Future<RecognitionResponse> _identifyWithAPI(
    File imageFile, 
    AppSettings settings,
  ) async {
    try {
      final uri = Uri.parse('${settings.baseUrl}/identify');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer ${settings.apiKey}',
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      // 添加图片文件
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
      
      // 添加额外参数
      request.fields['format'] = 'detailed'; // 要求详细信息
      request.fields['include_safety'] = 'true'; // 包含安全信息
      request.fields['include_care'] = 'true'; // 包含养护信息

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // 解析新的生活化数据结构
        if (jsonResponse['success'] == true) {
          final results = (jsonResponse['plants'] as List)
              .map((item) => RecognitionResult.fromJson(item))
              .toList();
          
          return RecognitionResponse.success(
            results: results,
            method: RecognitionMethod.cloud,
          );
        } else {
          return RecognitionResponse.error(
            error: jsonResponse['message'] ?? '识别失败',
            method: RecognitionMethod.cloud,
          );
        }
      } else {
        return RecognitionResponse.error(
          error: 'API调用失败: ${response.statusCode} - ${response.body}',
          method: RecognitionMethod.cloud,
        );
      }
    } catch (e) {
      return RecognitionResponse.error(
        error: 'API调用异常: $e',
        method: RecognitionMethod.cloud,
      );
    }
  }
  
  /// 专门的安全性检查（使用MNN Chat）
  Future<SafetyInfo> checkPlantSafety(File imageFile) async {
    if (_mnnChatService != null && _isMNNChatReady) {
      try {
        // 使用快速模式仅获取安全信息
        final result = await _mnnChatService!.identifyPlant(
          imageFile,
          quickMode: true,
        );
        
        if (result.success && result.results.isNotEmpty) {
          return result.results.first.safety;
        }
      } catch (e) {
        print('安全性检查失败: $e');
      }
    }
    
    // 默认返回未知安全状态
    return const SafetyInfo(
      level: SafetyLevel.unknown,
      description: '无法检查安全性，请谨慎处理',
      warnings: ['建议咨询专业人士'],
    );
  }
  
  /// 获取养护建议（使用MNN Chat）
  Future<CareInfo?> getPlantCareAdvice(File imageFile) async {
    if (_mnnChatService != null && _isMNNChatReady) {
      try {
        final result = await _mnnChatService!.identifyPlant(imageFile);
        
        if (result.success && result.results.isNotEmpty) {
          return result.results.first.care;
        }
      } catch (e) {
        print('获取养护建议失败: $e');
      }
    }
    
    return null;
  }
  
  /// 获取支持的识别方法
  List<RecognitionMethod> getSupportedMethods(AppSettings settings) {
    final methods = <RecognitionMethod>[];
    
    // MNN Chat识别
    if (_isMNNChatReady) {
      methods.add(RecognitionMethod.local);
    }
    
    // 云端识别（需要配置）
    if (settings.isConfigured) {
      methods.add(RecognitionMethod.cloud);
    }
    
    return methods;
  }
  
  /// 获取MNN Chat服务状态
  Map<String, dynamic> getMNNChatStatus() {
    if (_mnnChatService == null) {
      return {
        'available': false,
        'status': 'not_initialized',
        'error': 'MNN Chat服务未初始化',
      };
    }
    
    return _mnnChatService!.getStatus();
  }
  
  /// 检查服务可用性
  Future<bool> testConnection(AppSettings settings) async {
    if (!settings.isConfigured) {
      return false;
    }
    
    try {
      final uri = Uri.parse('${settings.baseUrl}/health');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${settings.apiKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    // 清理MNN Chat资源
    _mnnChatService?.dispose();
    _mnnChatService = null;
    _isMNNChatReady = false;
  }
}