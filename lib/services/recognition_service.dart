import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/recognition_result.dart';
import '../models/app_settings.dart';
import 'mnn_chat_service.dart';
import 'embedded_model_service.dart';

/// 植物识别服务 - 支持应用内模型、MNN Chat和云端识别的生活化植物识别
/// 单例模式，确保全局只有一个识别服务实例
class RecognitionService extends ChangeNotifier {
  static const bool _preferLocalLLM = true; // 优先使用本地大模型

  // 单例实例
  static RecognitionService? _instance;
  
  final Logger _logger = Logger();
  MNNChatService? _mnnChatService;
  bool _isMNNChatReady = false;

  EmbeddedModelService? _embeddedModelService;
  bool _isEmbeddedModelReady = false;
  bool _isInitialized = false;

  // 私有构造函数
  RecognitionService._internal({EmbeddedModelService? embeddedModelService}) {
    _embeddedModelService = embeddedModelService;
  }
  
  // 工厂构造函数，返回单例
  factory RecognitionService({EmbeddedModelService? embeddedModelService}) {
    _instance ??= RecognitionService._internal(embeddedModelService: embeddedModelService);
    
    // 如果传入了新的 embeddedModelService，更新它
    if (embeddedModelService != null && _instance!._embeddedModelService == null) {
      _instance!._embeddedModelService = embeddedModelService;
    }
    
    // 不在构造函数中初始化异步操作，改为在 initialize 方法中处理
    
    return _instance!;
  }

  Future<void> initialize(AppSettings settings) async {
    // 确保只初始化一次
    if (_isInitialized) {
      _logger.i('RecognitionService already initialized');
      return;
    }
    
    // 初始化所有识别服务
    await _initializeServices();
    _isInitialized = true;
  }

  /// 初始化所有识别服务
  Future<void> _initializeServices() async {
    await Future.wait([_initializeEmbeddedModel(), _initializeMNNChat()]);
  }

  /// 初始化应用内模型服务
  Future<void> _initializeEmbeddedModel() async {
    if (_embeddedModelService == null) return;

    try {
      // 安全地添加状态监听器（避免重复添加）
      _embeddedModelService!.removeListener(_onEmbeddedModelStatusChanged);
      _embeddedModelService!.addListener(_onEmbeddedModelStatusChanged);
      
      // 检查模型状态（初始化时不自动加载，让它按需加载）
      _isEmbeddedModelReady = _embeddedModelService!.isModelReady;

      if (_isEmbeddedModelReady) {
        _logger.i('✅ 应用内 Gemma 3 Nano 4B 模型就绪');
      } else if (_embeddedModelService!.isModelDownloaded) {
        _logger.i('📦 应用内模型已下载，将在使用时自动加载');
      } else {
        _logger.w('⚠️ 应用内模型未下载，状态: ${_embeddedModelService!.state.status}');
      }
    } catch (e) {
      _logger.e('❌ 应用内模型初始化异常: $e');
      _isEmbeddedModelReady = false;
    }
  }
  
  /// 监听应用内模型状态变化
  void _onEmbeddedModelStatusChanged() {
    if (_embeddedModelService == null) return;
    
    final wasReady = _isEmbeddedModelReady;
    _isEmbeddedModelReady = _embeddedModelService!.isModelReady;
    
    if (wasReady != _isEmbeddedModelReady) {
      _logger.i('📱 应用内模型状态更新: ${_isEmbeddedModelReady ? '就绪' : '未就绪'}');
    }
  }

  /// 初始化MNN Chat服务
  Future<void> _initializeMNNChat() async {
    if (!_preferLocalLLM) return;

    try {
      _mnnChatService = MNNChatService();
      _isMNNChatReady = await _mnnChatService!.initialize();

      if (_isMNNChatReady) {
        final status = _mnnChatService!.getStatus();
        _logger.i('✅ MNN Chat + Qwen2.5-VL-3B 初始化成功');
        _logger.i('  状态: ${status['status']}');
        _logger.i('  视觉理解: ${status['features']['vision_support']}');
      } else {
        _logger.w('⚠️ MNN Chat 初始化失败，将使用云端服务');
      }
    } catch (e) {
      _logger.e('❌ MNN Chat 初始化异常: $e');
      _isMNNChatReady = false;
    }
  }

  void updateSettings(AppSettings settings) {
    // 简化更新逻辑
  }

  /// 植物识别主入口 - 支持应用内模型、MNN Chat和云端识别
  Future<RecognitionResponse> identifyPlant(
    File imageFile,
    AppSettings settings, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
    RecognitionMethod? preferredMethod,
  }) async {
    print('🔧[RecognitionService] === 进入植物识别服务 ===');
    print('📂[RecognitionService] 图片文件: ${imageFile.path}');
    print('⚙️[RecognitionService] 参数: userContext=$userContext, season=$season, location=$location, quickMode=$quickMode');
    print('🎯[RecognitionService] 首选方法: ${preferredMethod ?? settings.preferredRecognitionMethod}');
    
    // 若无任何真实服务可用，直接中断，不使用模拟数据
    final hasEmbedded = (_embeddedModelService?.isModelReady ?? false) || 
                       (_embeddedModelService?.isModelDownloaded ?? false);
    final hasMNN = _preferLocalLLM && _isMNNChatReady;
    final hasCloud = settings.isConfigured;
    final anyAvailable = hasEmbedded || hasMNN || hasCloud;

    // 添加调试信息
    print('🔍[RecognitionService] 识别服务状态检查:');
    print('   - EmbeddedModel 就绪: ${_embeddedModelService?.isModelReady ?? false}');
    print('   - EmbeddedModel 已下载: ${_embeddedModelService?.isModelDownloaded ?? false}');
    print('   - EmbeddedModel 状态: ${_embeddedModelService?.state.status}');
    print('   - EmbeddedModel 加载中: ${_embeddedModelService?.isModelLoading ?? false}');
    print('   - EmbeddedModel 识别中: ${_embeddedModelService?.isRecognitionInProgress ?? false}');
    print('   - MNN Chat 就绪: $_isMNNChatReady');
    print('   - MNN Chat 偏好: $_preferLocalLLM');
    print('   - Cloud 配置: ${settings.isConfigured}');
    print('   - 任何服务可用: $anyAvailable');
    
    _logger.d('识别服务状态检查:');
    _logger.d('  EmbeddedModel: ready=${_embeddedModelService?.isModelReady}, downloaded=${_embeddedModelService?.isModelDownloaded}, status=${_embeddedModelService?.state.status}');
    _logger.d('  MNN Chat: ready=$_isMNNChatReady');
    _logger.d('  Cloud: configured=${settings.isConfigured}');
    _logger.d('  任何可用: $anyAvailable');

    if (!anyAvailable) {
      final errorMsg = '没有可用的识别服务：请先下载并加载本地模型(状态: ${_embeddedModelService?.state.status})，或确保MNN Chat服务可用，或在云端配置API。';
      print('❌[RecognitionService] $errorMsg');
      return RecognitionResponse.error(
        error: errorMsg,
        method: preferredMethod ?? settings.preferredRecognitionMethod,
      );
    }

    // 根据用户偏好或自动选择识别方法，支持回退机制
    final method = preferredMethod ?? settings.preferredRecognitionMethod;
    print('📋[RecognitionService] 选定识别方法: $method');
    print('🔄[RecognitionService] 回退顺序: ${settings.recognitionMethodFallbackOrder}');

    // 如果用户设置了智能识别，使用最佳可用方法
    if (method == RecognitionMethod.hybrid) {
      print('🧠[RecognitionService] 使用混合智能识别模式');
      final result = await _hybridRecognition(
        imageFile,
        settings,
        userContext: userContext,
        season: season,
        location: location,
        quickMode: quickMode,
      );
      print('🏁[RecognitionService] 混合识别完成: success=${result.success}, method=${result.method}');
      return result;
    }

    // 尝试用户首选的方法，如果失败则按照设置的回退顺序尝试
    print('🎯[RecognitionService] 使用指定方法识别: $method');
    final result = await _tryRecognitionWithFallback(
      imageFile,
      settings,
      method,
      userContext: userContext,
      season: season,
      location: location,
      quickMode: quickMode,
    );

    print('🏁[RecognitionService] 识别流程完成: success=${result.success}, method=${result.method}');
    if (!result.success) {
      print('❌[RecognitionService] 识别失败原因: ${result.error}');
    } else {
      print('✅[RecognitionService] 识别成功，结果数量: ${result.results.length}');
    }
    return result;
  }

  /// 混合识别模式 - 按优先级尝试各种方法
  Future<RecognitionResponse> _hybridRecognition(
    File imageFile,
    AppSettings settings, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) async {
    // 按照设置中的回退顺序尝试各种方法
    for (final method in settings.recognitionMethodFallbackOrder) {
      if (method == RecognitionMethod.hybrid ||
          method == RecognitionMethod.manual) {
        continue; // 跳过混合模式和手动模式
      }

      final result = await _trySingleRecognitionMethod(
        imageFile,
        settings,
        method,
        userContext: userContext,
        season: season,
        location: location,
        quickMode: quickMode,
      );

      if (result.success && result.results.isNotEmpty) {
        return result;
      }
    }

    // 如果所有方法都失败了，返回错误
    return RecognitionResponse.error(
      error: '所有配置的识别方法都无法使用，请检查设置或网络连接',
      method: RecognitionMethod.hybrid,
    );
  }

  /// 使用回退机制尝试识别
  Future<RecognitionResponse> _tryRecognitionWithFallback(
    File imageFile,
    AppSettings settings,
    RecognitionMethod primaryMethod, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
    int maxRetries = 2,
  }) async {
    // 首先尝试主要方法
    var result = await _trySingleRecognitionMethod(
      imageFile,
      settings,
      primaryMethod,
      userContext: userContext,
      season: season,
      location: location,
      quickMode: quickMode,
    );

    // 如果成功，直接返回
    if (result.success && result.results.isNotEmpty) {
      return result;
    }

    // 如果主要方法失败，尝试重试（最多2次）
    for (int retry = 0; retry < maxRetries; retry++) {
      await Future.delayed(Duration(seconds: retry + 1));
      result = await _trySingleRecognitionMethod(
        imageFile,
        settings,
        primaryMethod,
        userContext: userContext,
        season: season,
        location: location,
        quickMode: quickMode,
      );

      if (result.success && result.results.isNotEmpty) {
        return result;
      }
    }

    // 如果重试后仍然失败，按照回退顺序尝试其他方法
    final fallbackOrder = List<RecognitionMethod>.from(
      settings.recognitionMethodFallbackOrder,
    );
    fallbackOrder.remove(primaryMethod); // 移除已经尝试过的主要方法
    fallbackOrder.removeWhere(
      (method) =>
          method == RecognitionMethod.hybrid ||
          method == RecognitionMethod.manual,
    );

    for (final method in fallbackOrder) {
      final fallbackResult = await _trySingleRecognitionMethod(
        imageFile,
        settings,
        method,
        userContext: userContext,
        season: season,
        location: location,
        quickMode: quickMode,
      );

      if (fallbackResult.success && fallbackResult.results.isNotEmpty) {
        return fallbackResult;
      }
    }

    // 所有方法都失败了
    return RecognitionResponse.error(
      error: '主要识别方法失败，备用方法也无法使用。错误：${result.error}',
      method: primaryMethod,
    );
  }

  /// 尝试单一识别方法
  Future<RecognitionResponse> _trySingleRecognitionMethod(
    File imageFile,
    AppSettings settings,
    RecognitionMethod method, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) async {
    print('🔄[RecognitionService] 尝试识别方法: $method');
    final stopwatch = Stopwatch()..start();
    
    switch (method) {
      case RecognitionMethod.embedded:
        print('🔧[RecognitionService] 尝试使用应用内模型 (Embedded)');
        print('   - 模型就绪: ${_embeddedModelService?.isModelReady ?? false}');
        print('   - 模型已下载: ${_embeddedModelService?.isModelDownloaded ?? false}');
        print('   - 模型状态: ${_embeddedModelService?.state.status}');
        print('   - 模型加载中: ${_embeddedModelService?.isModelLoading ?? false}');
        
        // 实时检查模型状态，不依赖缓存
        if (_embeddedModelService?.isModelReady ?? false) {
          print('✅[RecognitionService] 模型已就绪，直接开始识别');
          final result = await _tryEmbeddedModelRecognition(imageFile);
          stopwatch.stop();
          print('⏱️[RecognitionService] 应用内模型识别耗时: ${stopwatch.elapsedMilliseconds}ms');
          return result;
        }
        
        // 如果模型已下载但未加载，尝试自动加载
        if (_embeddedModelService != null && 
            _embeddedModelService!.isModelDownloaded && 
            !_embeddedModelService!.isModelReady) {
          try {
            print('🔄[RecognitionService] 模型已下载但未加载，正在按需加载...');
            _logger.i('🔄 模型已下载但未加载，正在按需加载...');
            await _embeddedModelService!.loadModel();
            
            if (_embeddedModelService!.isModelReady) {
              print('✅[RecognitionService] 模型按需加载成功，开始识别...');
              _logger.i('✅ 模型按需加载成功，开始识别...');
              final result = await _tryEmbeddedModelRecognition(imageFile);
              stopwatch.stop();
              print('⏱️[RecognitionService] 应用内模型识别(含加载)耗时: ${stopwatch.elapsedMilliseconds}ms');
              return result;
            } else {
              print('❌[RecognitionService] 模型加载后仍未就绪');
            }
          } catch (e) {
            print('💥[RecognitionService] 模型按需加载失败: $e');
            _logger.e('❌ 模型按需加载失败: $e');
          }
        }
        
        final errorMsg = '应用内模型未就绪，状态: ${_embeddedModelService?.state.status ?? '未知'}';
        print('❌[RecognitionService] $errorMsg');
        stopwatch.stop();
        return RecognitionResponse.error(
          error: errorMsg,
          method: RecognitionMethod.embedded,
        );

      case RecognitionMethod.local:
        if (_isMNNChatReady && _mnnChatService != null) {
          return await _tryMNNChatRecognition(
            imageFile,
            userContext: userContext,
            season: season,
            location: location,
            quickMode: quickMode,
          );
        }
        return RecognitionResponse.error(
          error: 'MNN Chat服务未就绪',
          method: RecognitionMethod.local,
        );

      case RecognitionMethod.cloud:
        if (settings.isConfigured) {
          return await _tryCloudRecognition(imageFile, settings);
        }
        return RecognitionResponse.error(
          error: '云端识别未配置',
          method: RecognitionMethod.cloud,
        );

      case RecognitionMethod.manual:
        return RecognitionResponse.error(
          error: '手动模式不支持自动识别',
          method: RecognitionMethod.manual,
        );
      
      case RecognitionMethod.none:
        return RecognitionResponse.error(
          error: '未识别模式不支持识别操作',
          method: RecognitionMethod.none,
        );

      case RecognitionMethod.hybrid:
        // 这种情况不应该发生，因为hybrid会被特殊处理
        return RecognitionResponse.error(
          error: '不支持在单一方法中调用混合模式',
          method: RecognitionMethod.hybrid,
        );
    }
  }

  /// 选择最佳识别方法（根据设置和可用性）
  RecognitionMethod _selectBestMethod(AppSettings settings) {
    // 按照设置的回退顺序找到第一个可用的方法
    for (final method in settings.recognitionMethodFallbackOrder) {
      if (isMethodAvailable(method)) {
        return method;
      }
    }

    // 如果没有可用的方法，返回云端（总是可用，但需要配置）
    return RecognitionMethod.cloud;
  }

  /// 应用内模型识别（Gemma 3 Nano 4B）
  Future<RecognitionResponse> _tryEmbeddedModelRecognition(
    File imageFile,
  ) async {
    if (_embeddedModelService == null) {
      return RecognitionResponse.error(
        error: '应用内模型服务未初始化',
        method: RecognitionMethod.embedded,
      );
    }

    // 实时检查模型状态，不依赖缓存的 _isEmbeddedModelReady
    if (!_embeddedModelService!.isModelReady) {
      return RecognitionResponse.error(
        error: '应用内模型未就绪，当前状态: ${_embeddedModelService!.state.status}',
        method: RecognitionMethod.embedded,
      );
    }

    try {
      _logger.i('🔄 开始植物识别，初次加载可能需要较长时间...');
      
      // 增加超时时间，因为Gemma模型初次加载很慢
      final results = await _embeddedModelService!.recognizePlant(imageFile)
          .timeout(
            const Duration(minutes: 3), // 3分钟超时
            onTimeout: () {
              _logger.w('⏰ 植物识别超时，可能是模型初次加载时间过长');
              throw TimeoutException('植物识别超时，模型初次加载需要较长时间，请稍后重试', const Duration(minutes: 3));
            },
          );

      // 如果结果为空，表示图片中没有植物
      if (results.isEmpty) {
        return RecognitionResponse.error(
          error: '图片中未检测到植物，请确保照片中包含植物并重试',
          method: RecognitionMethod.embedded,
        );
      }

      // 转换为生活化的RecognitionResult格式
      final convertedResults = results
          .map((result) => _convertToLifestyleResult(result))
          .toList();

      // 添加应用内模型的特殊标识
      for (final plant in convertedResults) {
        plant.tags.add('应用内AI');
        plant.tags.add('Gemma 3 Nano');
        plant.tags.add('完全离线');
      }

      return RecognitionResponse.success(
        results: convertedResults,
        method: RecognitionMethod.embedded,
      );
    } catch (e) {
      if (e is TimeoutException) {
        _logger.w('⏰ 植物识别超时: ${e.message}');
        return RecognitionResponse.error(
          error: '识别超时：模型初次加载需要较长时间（约1-3分钟），请耐心等待或稍后重试',
          method: RecognitionMethod.embedded,
        );
      }
      
      return RecognitionResponse.error(
        error: '应用内模型识别异常: $e',
        method: RecognitionMethod.embedded,
      );
    }
  }

  /// 将Gemma识别结果转换为生活化格式
  RecognitionResult _convertToLifestyleResult(dynamic gemmaResult) {
    // 这里假设gemmaResult是从Gemma推理服务返回的RecognitionResult
    // 需要转换为生活化的RecognitionResult格式

    if (gemmaResult is RecognitionResult) {
      // 如果已经是正确格式，直接返回
      return gemmaResult;
    }

    // 如果是其他格式，需要转换
    // 这里提供一个基本的转换示例
    return RecognitionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: gemmaResult.commonName ?? '未知植物',
      nickname: null,
      confidence: gemmaResult.confidence ?? 0.5,
      description: gemmaResult.description ?? '这是一种植物',
      features: ['通过AI识别的特征'],
      safety: SafetyInfo(
        level: gemmaResult.isToxic == true
            ? SafetyLevel.toxic
            : SafetyLevel.safe,
        description: gemmaResult.isToxic == true ? '该植物可能有毒，请小心接触' : '该植物相对安全',
        warnings: gemmaResult.toxicityInfo != null
            ? [gemmaResult.toxicityInfo!]
            : [],
      ),
      care: null,
      season: null,
      locations: ['室内', '户外'],
      funFact: null,
      tags: ['AI识别'],
      scientificName: gemmaResult.scientificName,
      family: null,
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
        for (final plant in result.results) {
          plant.tags.add('MNN Chat');
          plant.tags.add('Qwen2.5-VL-3B');
          if (quickMode) plant.tags.add('快速模式');
        }
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
        await http.MultipartFile.fromPath('image', imageFile.path),
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
        _logger.e('安全性检查失败: $e');
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
        _logger.e('获取养护建议失败: $e');
      }
    }

    // 极简输出模型不提供养护信息，返回null
    // UI层应该适当处理null情况
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
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer ${settings.apiKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 获取识别方法状态
  Map<String, dynamic> getRecognitionMethodsStatus([AppSettings? settings]) {
    final result = {
      'embedded_model': {
        'available': _embeddedModelService?.isModelReady ?? false,
        'status': _embeddedModelService?.state.status.toString(),
        'model_info': _embeddedModelService?.modelInfo?.toJson(),
        'device_capability':
            _embeddedModelService?.deviceCapability?.additionalInfo,
      },
      'mnn_chat': {
        'available': _isMNNChatReady,
        'status': _mnnChatService?.getStatus(),
      },
      'cloud': {
        'available': true, // 云端总是可用的，只要有配置
        'configured': settings?.isConfigured ?? false,
      },
    };

    if (settings != null) {
      result['settings'] = {
        'preferred_method': settings.preferredRecognitionMethod.name,
        'preferred_method_display':
            settings.preferredRecognitionMethod.displayName,
        'fallback_order': settings.recognitionMethodFallbackOrder
            .map((e) => e.name)
            .toList(),
        'fallback_order_display': settings.recognitionMethodFallbackOrder
            .map((e) => e.displayName)
            .toList(),
        'recommended_method': _selectBestMethod(settings).toString(),
      };
    }

    return result;
  }

  /// 刷新服务状态
  Future<void> refreshStatus() async {
    // 如果服务还未初始化，先初始化
    if (!_isInitialized) {
      await _initializeServices();
      _isInitialized = true;
    } else {
      // 如果已初始化，只刷新状态
      await _initializeServices();
    }
  }

  /// 获取可用的识别方法列表
  List<RecognitionMethod> getAvailableMethods() {
    final methods = <RecognitionMethod>[];

    // 应用内模型：如果已就绪或已下载（可按需加载），则认为可用
    if ((_embeddedModelService?.isModelReady ?? false) || 
        (_embeddedModelService?.isModelDownloaded ?? false)) {
      methods.add(RecognitionMethod.embedded);
    }

    if (_isMNNChatReady) {
      methods.add(RecognitionMethod.local);
    }

    // 云端方法总是可用（如果配置了）
    methods.add(RecognitionMethod.cloud);

    return methods;
  }

  /// 检查特定方法是否可用
  bool isMethodAvailable(RecognitionMethod method) {
    switch (method) {
      case RecognitionMethod.embedded:
        return (_embeddedModelService?.isModelReady ?? false) || 
               (_embeddedModelService?.isModelDownloaded ?? false);
      case RecognitionMethod.local:
        return _isMNNChatReady;
      case RecognitionMethod.cloud:
        return true; // 云端总是可用（如果配置了）
      case RecognitionMethod.hybrid:
        final hasEmbedded = (_embeddedModelService?.isModelReady ?? false) || 
                           (_embeddedModelService?.isModelDownloaded ?? false);
        return hasEmbedded || _isMNNChatReady;
      case RecognitionMethod.manual:
        return true; // 手动输入总是可用
      case RecognitionMethod.none:
        return false; // 未识别模式不可用于识别
    }
  }

  /// 获取方法显示名称
  String getMethodDisplayName(RecognitionMethod method) {
    switch (method) {
      case RecognitionMethod.embedded:
        return '应用内AI模型';
      case RecognitionMethod.local:
        return 'MNN Chat (外部)';
      case RecognitionMethod.cloud:
        return '云端API';
      case RecognitionMethod.hybrid:
        return '智能识别';
      case RecognitionMethod.manual:
        return '手动输入';
      case RecognitionMethod.none:
        return '未识别';
    }
  }

  /// 获取方法描述
  String getMethodDescription(RecognitionMethod method) {
    switch (method) {
      case RecognitionMethod.embedded:
        return '使用设备内置的Gemma 3 Nano 4B模型，完全离线，隐私安全';
      case RecognitionMethod.local:
        return '通过MNN Chat应用使用本地Qwen2.5-VL-3B模型';
      case RecognitionMethod.cloud:
        return '使用云端API服务，需要网络连接和API密钥';
      case RecognitionMethod.hybrid:
        return '结合本地和云端模型，取长补短';
      case RecognitionMethod.manual:
        return '用户手动输入植物信息';
      case RecognitionMethod.none:
        return '未进行识别，等待后续识别';
    }
  }

  @override
  void dispose() {
    // 清理资源
    _mnnChatService?.dispose();
    _mnnChatService = null;
    _isMNNChatReady = false;

    // 移除应用内模型状态监听器
    _embeddedModelService?.removeListener(_onEmbeddedModelStatusChanged);
    // 不要dispose外部传入的embeddedModelService，只清除引用
    _embeddedModelService = null;
    _isEmbeddedModelReady = false;
    
    super.dispose();
  }
}
