import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/embedded_model.dart';
import '../models/recognition_result.dart';
import 'model_storage_manager.dart';
import 'device_capability_detector.dart';

/// Gemma 推理服务 - 基于 flutter_gemma 的最佳实践
class GemmaInferenceService {
  final ModelStorageManager _storageManager;
  final DeviceCapabilityDetector _capabilityDetector;
  final Logger _logger = Logger();

  static const String _modelId = 'google/gemma-3n-E4B-it-litert-preview';
  static const String _modelFileName = 'gemma-3n-E4B-it-int4.task';

  // 使用 flutter_gemma 插件实例
  final _gemmaPlugin = FlutterGemmaPlugin.instance;
  InferenceModel? _gemmaModel;
  InferenceChat? _chat;
  bool _isModelLoaded = false;
  bool _isInitializing = false;
  bool _isRecognitionInProgress = false; // 跟踪识别是否正在进行
  int _messageCount = 0; // 跟踪消息数量
  
  /// 分类和详细化异常信息
  String _categorizeError(dynamic error, String context) {
    final errorString = error.toString().toLowerCase();
    
    // 模型文件相关错误
    if (errorString.contains('file not found') || errorString.contains('no such file')) {
      return '$context: Model file not found. Please ensure the model is downloaded correctly.';
    }
    
    // 内存相关错误
    if (errorString.contains('memory') || errorString.contains('out of memory') || errorString.contains('oom')) {
      return '$context: Insufficient memory to load model. Try closing other apps or use a device with more RAM.';
    }
    
    // 权限相关错误
    if (errorString.contains('permission') || errorString.contains('access denied')) {
      return '$context: File access permission denied. Check app storage permissions.';
    }
    
    // 网络相关错误
    if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('timeout')) {
      return '$context: Network connectivity issue. Check internet connection.';
    }
    
    // 模型格式或兼容性错误
    if (errorString.contains('format') || errorString.contains('corrupted') || errorString.contains('invalid')) {
      return '$context: Invalid or corrupted model file. Try re-downloading the model.';
    }
    
    // 设备兼容性错误
    if (errorString.contains('unsupported') || errorString.contains('incompatible')) {
      return '$context: Device incompatibility. This model may not be supported on your device.';
    }
    
    // 插件相关错误
    if (errorString.contains('plugin') || errorString.contains('flutter_gemma')) {
      return '$context: Flutter Gemma plugin error. Plugin may need to be updated.';
    }
    
    // 默认错误
    return '$context: ${error.toString()}';
  }

  GemmaInferenceService(this._storageManager, this._capabilityDetector);

  Future<bool> isModelReady() async {
    return _isModelLoaded && _gemmaModel != null && _chat != null;
  }
  
  bool get isRecognitionInProgress => _isRecognitionInProgress;
  bool get isModelLoading => _isInitializing;

  Future<bool> initializeModel() async {
    if (_isModelLoaded || _isInitializing) {
      return _isModelLoaded;
    }

    _isInitializing = true;

    try {
      _logger.i('Initializing Gemma model...');

      // Use the same approach as the official flutter_gemma example
      // Check for model file in application documents directory (like the reference)
      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/$_modelFileName');

      if (!await modelFile.exists()) {
        // Also check our storage manager path as fallback
        final modelPath = await _storageManager.getModelPath(_modelId);
        final fallbackFile = File('$modelPath/$_modelFileName');
        
        if (await fallbackFile.exists()) {
          // Copy from our storage location to the expected location
          _logger.i('Copying model from storage to documents directory...');
          await fallbackFile.copy(modelFile.path);
        } else {
          throw Exception(
            'Model file not found. Expected at: ${modelFile.path}. Please download the model first.',
          );
        }
      }

      // Get device capability for optimal configuration
      final capability = await _capabilityDetector.detect();
      
      // Always set model path like in the official example - this is the key difference!
      if (!await _gemmaPlugin.modelManager.isModelInstalled) {
        await _gemmaPlugin.modelManager.setModelPath(modelFile.path);
        _logger.i('Model path set to: ${modelFile.path}');
      } else {
        _logger.i('Model already installed in plugin');
      }

      // Create model instance with exact parameters from official example for Gemma 3n E4B
      _gemmaModel = await _gemmaPlugin.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: _mapPreferredBackend(capability.recommendedBackend),
        maxTokens: 1024, // From official chat_screen.dart example
        supportImage: true, // Gemma 3 Nano E4B supports multimodal
        maxNumImages: 1, // From official example: gemma3nGpu_4B maxNumImages
      );
      
      _logger.i('Model created successfully with backend: ${capability.recommendedBackend}');

      // Create chat instance with exact parameters from official example for Gemma 3n E4B
      _chat = await _gemmaModel!.createChat(
        temperature: 1.0, // From official example: gemma3nGpu_4B temperature
        randomSeed: 1,
        topK: 64, // From official example: gemma3nGpu_4B topK
        topP: 0.95, // From official example: gemma3nGpu_4B topP
        tokenBuffer: 256, // From official chat_screen.dart example
        supportImage: true, // Enable multimodal support
        supportsFunctionCalls: false, // Don't need function calling for plant recognition
        modelType: ModelType.gemmaIt,
      );
      
      _logger.i('Chat created successfully with image support');

      _isModelLoaded = true;
      _logger.i('Gemma model initialized successfully');
      return true;
    } catch (e, stackTrace) {
      String detailedError;
      
      if (e.toString().contains('setModelPath')) {
        detailedError = _categorizeError(e, 'Model path configuration failed');
      } else if (e.toString().contains('createModel')) {
        detailedError = _categorizeError(e, 'Model creation failed');
      } else if (e.toString().contains('createChat')) {
        detailedError = _categorizeError(e, 'Chat session creation failed');
      } else if (e.toString().contains('warmup')) {
        detailedError = _categorizeError(e, 'Model warmup failed');
      } else if (e.toString().contains('Model file not found')) {
        detailedError = _categorizeError(e, 'Model file missing');
      } else {
        detailedError = _categorizeError(e, 'Unknown initialization error');
      }
      
      _logger.e('Failed to initialize Gemma model: $detailedError');
      _logger.e('Stack trace: $stackTrace');
      _isModelLoaded = false;
      
      // Re-throw with detailed error for upper layers
      throw Exception(detailedError);
    } finally {
      _isInitializing = false;
    }
  }


  Future<List<RecognitionResult>> recognizePlant(File imageFile) async {
    if (!await isModelReady()) {
      throw StateError('Model is not ready. Please initialize the model first. Current status: isLoaded=$_isModelLoaded, model=${_gemmaModel != null}, chat=${_chat != null}');
    }

    // 设置识别进行中状态
    _isRecognitionInProgress = true;
    
    // 为植物识别创建独立的临时聊天会话，不影响聊天功能
    InferenceChat? tempChat;

    try {
      _logger.i('Starting plant recognition with Gemma model (独立会话)');

      // 创建临时的聊天实例，专门用于植物识别
      tempChat = await _gemmaModel!.createChat(
        temperature: 0.1, // 较低的temperature，更确定的输出
        randomSeed: 1,
        topK: 40, // 较小的topK，更聚焦的回答
        topP: 0.9, // 较高的topP，保持质量
        tokenBuffer: 256, // 与聊天保持一致的标准buffer
        supportImage: true,
        supportsFunctionCalls: false,
        modelType: ModelType.gemmaIt,
      );

      // Process the image
      _logger.i('Processing image file: ${imageFile.path}');
      final imageBytes = await _processImage(imageFile);
      _logger.i('Image processed successfully, size: ${imageBytes.length} bytes');
      
      // Create simplified prompt for plant recognition with non-plant detection
      const prompt = '''请仔细观察这张图片，如果是植物请识别，如果不是植物请说明。按照以下格式回答：

如果是植物：
植物名称: [中文名称]
描述: [简单描述，一句话]

如果不是植物：
识别结果: 非植物
描述: [简单说明图片内容，比如"这是动物"、"这是风景"、"这是物体"等]

示例1（植物）：
植物名称: 向日葵
描述: 大型黄色花朵的高大植物

示例2（非植物）：
识别结果: 非植物
描述: 这张图片显示的是一只猫''';

      // Create message with image
      _logger.i('Creating message with image, prompt length: ${prompt.length}');
      final message = Message.withImage(
        text: prompt,
        imageBytes: imageBytes,
        isUser: true,
      );
      _logger.i('Message created successfully, has image: ${message.hasImage}');

      // Add message to temporary chat and get response stream
      _logger.i('Adding query to temporary chat...');
      await tempChat.addQuery(message);
      _logger.i('Query added successfully, generating response...');
      final responseBuffer = StringBuffer();

      try {
        // 使用与聊天相同的流式响应机制
        final responseStream = tempChat.generateChatResponseAsync();
        _logger.i('Response stream created, waiting for tokens...');
        
        int tokenCount = 0;
        await for (final response in responseStream) {
          if (response is TextResponse) {
            responseBuffer.write(response.token);
            tokenCount++;
            if (tokenCount % 10 == 0) {
              _logger.i('Received $tokenCount tokens so far...');
            }
          }
        }
        
        final fullResponse = responseBuffer.toString().trim();
        _logger.i('Plant recognition completed! Response length: ${fullResponse.length} characters');
        _logger.i('Full response: $fullResponse');

        if (fullResponse.isEmpty) {
          throw Exception('Empty response from model');
        }

        // Parse the response into RecognitionResult
        return _parseGemmaResponse(fullResponse);
      } catch (e) {
        _logger.e('Error during response generation: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      String detailedError;
      
      if (e.toString().contains('addQuery')) {
        detailedError = _categorizeError(e, 'Failed to add query to chat');
      } else if (e.toString().contains('generateChatResponseAsync')) {
        detailedError = _categorizeError(e, 'Failed to generate response');
      } else if (e.toString().contains('processImage')) {
        detailedError = _categorizeError(e, 'Image processing failed');
      } else if (e.toString().contains('parseGemmaResponse')) {
        detailedError = _categorizeError(e, 'Failed to parse model response');
      } else {
        detailedError = _categorizeError(e, 'Plant recognition failed');
      }
      
      _logger.e('Plant recognition failed: $detailedError');
      _logger.e('Stack trace: $stackTrace');
      throw Exception(detailedError);
    } finally {
      // 重置识别状态并清理临时聊天会话
      _isRecognitionInProgress = false;
      if (tempChat != null) {
        try {
          // InferenceChat 可能没有dispose方法，直接设置为null让GC回收
          tempChat = null;
        } catch (e) {
          _logger.w('Failed to dispose temporary chat session: $e');
        }
      }
    }
  }

  Future<List<RecognitionResult>> identifyPlantWithContext(
    File imageFile, {
    String? userContext,
    String? season,
    String? location,
    bool quickMode = false,
  }) async {
    if (!await isModelReady()) {
      throw StateError('Model is not ready. Please initialize the model first. Current status: isLoaded=$_isModelLoaded, model=${_gemmaModel != null}, chat=${_chat != null}');
    }

    try {
      final imageBytes = await _processImage(imageFile);
      
      // Build simplified contextual prompt
      var prompt = '''请识别这张植物图片，按照以下格式回答：

植物名称: [中文名称]
描述: [简单描述，一句话]''';
      
      // Add context information
      final contextParts = <String>[];
      if (userContext?.isNotEmpty == true) {
        contextParts.add('用户说明：$userContext');
      }
      if (season?.isNotEmpty == true) {
        contextParts.add('当前季节：$season');
      }
      if (location?.isNotEmpty == true) {
        contextParts.add('拍摄地点：$location');
      }
      
      if (contextParts.isNotEmpty) {
        prompt += '\n\n额外信息：\n${contextParts.join('\n')}';
      }

      final message = Message.withImage(
        text: prompt,
        imageBytes: imageBytes,
        isUser: true,
      );

      await _chat!.addQuery(message);
      final responseStream = _chat!.generateChatResponseAsync();
      final responseBuffer = StringBuffer();

      await for (final response in responseStream) {
        if (response is TextResponse) {
          responseBuffer.write(response.token);
        }
      }

      return _parseGemmaResponse(responseBuffer.toString().trim());
    } catch (e) {
      _logger.e('Contextual plant identification failed: $e');
      rethrow;
    }
  }

  /// 聊天功能，支持文本和图片 - 使用流式响应
  Stream<String> chatStream({required String prompt, File? imageFile}) async* {
    if (!await isModelReady()) {
      throw StateError('Model is not ready. Please initialize the model first.');
    }

    try {
      // 检查聊天历史长度，如果太长则清理
      await _manageChatHistory();
      
      Message message;
      
      if (imageFile != null) {
        final imageBytes = await _processImage(imageFile);
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        message = Message.text(text: prompt, isUser: true);
      }

      await _chat!.addQuery(message);
      final responseStream = _chat!.generateChatResponseAsync();

      // Use official ModelResponse handling like in the example
      await for (final response in responseStream) {
        if (response is TextResponse) {
          yield response.token;
        } else if (response is ThinkingResponse) {
          // Log thinking content but don't yield it to chat interface
          _logger.d('Model thinking: ${response.content}');
        }
      }
    } catch (e) {
      _logger.e('Chat stream failed: $e');
      rethrow;
    }
  }

  /// 传统的聊天功能（向后兼容）
  Future<String> chat({required String prompt, File? imageFile}) async {
    final responseBuffer = StringBuffer();
    
    await for (final token in chatStream(prompt: prompt, imageFile: imageFile)) {
      responseBuffer.write(token);
    }
    
    return responseBuffer.toString().trim();
  }

  Future<void> unloadModel() async {
    try {
      _logger.i('Unloading Gemma model...');
      
      if (_chat != null) {
        await _chat!.clearHistory();
        _chat = null;
      }
      
      if (_gemmaModel != null) {
        await _gemmaModel!.close();
        _gemmaModel = null;
      }
      
      // 不要删除模型文件，只是清理内存中的实例
      // await _gemmaPlugin.modelManager.deleteModel();
      
      _isModelLoaded = false;
      _logger.i('Gemma model unloaded successfully');
    } catch (e) {
      _logger.e('Error unloading model: $e');
      rethrow;
    }
  }

  Future<bool> testInference() async {
    if (!await isModelReady()) {
      return false;
    }

    try {
      _logger.i('Testing Gemma inference capability...');
      
      // Create a simple test message
      final testMessage = Message.text(
        text: '你好，请简短回复确认你可以正常工作。',
        isUser: true,
      );

      await _chat!.addQuery(testMessage);
      final responseStream = _chat!.generateChatResponseAsync();
      bool hasResponse = false;

      await for (final response in responseStream) {
        if (response is TextResponse && response.token.isNotEmpty) {
          hasResponse = true;
          break;
        }
      }

      _logger.i('Inference test ${hasResponse ? 'passed' : 'failed'}');
      return hasResponse;
    } catch (e) {
      _logger.e('Inference test failed: $e');
      return false;
    }
  }

  /// 获取模型信息
  Map<String, dynamic>? get modelInfo => _isModelLoaded
      ? {
          'id': _modelId,
          'name': 'Gemma 3 Nano E4B (Vision)',
          'version': 'E4B-it-litert-preview',
          'size': 0, // 实际大小需要从文件获取
          'description': 'Google Gemma 3 Nano 多模态模型，支持文本和图像理解',
          'capabilities': ['植物识别', '多模态聊天', '图像理解'],
          'supportImage': true,
          'supportFunctionCalls': false,
        }
      : null;

  void dispose() {
    if (_isModelLoaded) {
      unloadModel();
    }
    _logger.i('Gemma 推理服务已释放');
  }

  // Helper methods

  Future<Uint8List> _processImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image for model input (typical size: 224x224 or 384x384)
      final resizedImage = img.copyResize(image, width: 384, height: 384);
      
      // Convert back to bytes
      final processedBytes = img.encodePng(resizedImage);
      return Uint8List.fromList(processedBytes);
    } catch (e) {
      _logger.e('Image processing failed: $e');
      rethrow;
    }
  }

  List<RecognitionResult> _parseGemmaResponse(String response) {
    try {
      // Handle empty or very short responses
      if (response.trim().isEmpty || response.trim().length < 5) {
        return _parseFallbackResponse('模型返回了空响应');
      }
      
      // Parse extremely simple separator format
      final Map<String, String> parsed = {};
      
      // Parse line by line
      final lines = response.split('\n');
      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();
            if (key.isNotEmpty && value.isNotEmpty) {
              parsed[key] = value;
            }
          }
        }
      }
      
      // Check if we got any useful data
      if (parsed.isEmpty) {
        return _parseFallbackResponse(response);
      }
      
      // Check if this is a non-plant detection
      final recognitionResult = parsed['识别结果']?.trim();
      if (recognitionResult != null && recognitionResult.contains('非植物')) {
        final description = parsed['描述']?.trim() ?? '图片中没有植物';
        
        // Return empty list to indicate no plants found
        _logger.i('Non-plant detected: $description');
        return [];
      }
      
      // Extract plant name with multiple key variations
      final rawName = parsed['植物名称']?.trim() ?? 
                     parsed['名称']?.trim() ?? 
                     parsed['植物']?.trim();
      final name = (rawName == null || rawName.isEmpty) ? '未知植物' : rawName;
      
      final rawDescription = parsed['描述']?.trim();
      final description = (rawDescription == null || rawDescription.isEmpty) ? '暂无描述' : rawDescription;
      
      return [
        RecognitionResult(
          id: 'gemma_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          confidence: 0.5, // Fixed medium confidence
          description: description,
          features: [],
          safety: const SafetyInfo(
            level: SafetyLevel.unknown, // Don't provide safety info
            description: '安全性未知，请谨慎处理',
            warnings: ['建议咨询专业人士'],
          ),
          locations: [],
          tags: ['Gemma识别'],
        ),
      ];
    } catch (e) {
      _logger.e('Failed to parse Gemma response: $e');
      
      // Fallback parsing - try to extract plant name from natural language
      return _parseFallbackResponse(response);
    }
  }

  /// Fallback parsing when structured format fails
  List<RecognitionResult> _parseFallbackResponse(String response) {
    // Try to extract plant name from natural language
    final nameMatch = RegExp(r'(这是|可能是|应该是|看起来像)(.+?)(?:\n|$|。|，)').firstMatch(response);
    final name = nameMatch?.group(2)?.trim() ?? '识别异常';
    
    return [
      RecognitionResult(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        confidence: 0.3,
        description: '模型输出格式异常，请重试',
        features: [],
        safety: const SafetyInfo(
          level: SafetyLevel.unknown,
          description: '无法确定安全性',
          warnings: ['输出格式异常，请谨慎参考'],
        ),
        locations: [],
        tags: ['格式异常'],
      ),
    ];
  }


  /// 管理聊天历史，防止上下文过长
  Future<void> _manageChatHistory() async {
    if (_chat == null) return;
    
    // 每5轮对话清理一次历史，避免上下文过长
    // 这是一个保守但实用的策略
    _messageCount++;
    
    if (_messageCount >= 5) {
      try {
        _logger.i('已进行${_messageCount}轮对话，清理聊天历史以防止上下文过长');
        await _chat!.clearHistory();
        _messageCount = 0; // 重置计数器
        _logger.d('聊天历史清理成功');
        
      } catch (e) {
        _logger.w('清理聊天历史失败: $e');
        // 如果清理失败，尝试重新创建聊天实例
        try {
          _logger.i('尝试重新创建聊天实例...');
          
          if (_gemmaModel != null) {
            _chat = await _gemmaModel!.createChat(
              temperature: 1.0,
              randomSeed: 1,
              topK: 64,
              topP: 0.95,
              tokenBuffer: 256,
              supportImage: true,
              supportsFunctionCalls: false,
              modelType: ModelType.gemmaIt,
            );
            _messageCount = 0; // 重置计数器
            _logger.i('聊天实例重新创建成功');
          }
        } catch (recreateError) {
          _logger.e('重新创建聊天实例也失败: $recreateError');
          // 重置计数器，下次再尝试
          _messageCount = 0;
          // 继续执行，不阻断流程
        }
      }
    }
  }

  PreferredBackend _mapPreferredBackend(InferenceBackend backend) {
    switch (backend) {
      case InferenceBackend.cpu:
        return PreferredBackend.cpu;
      case InferenceBackend.gpu:
        return PreferredBackend.gpu;
      case InferenceBackend.auto:
        return PreferredBackend.gpu; // Default to GPU for auto mode
    }
  }
}