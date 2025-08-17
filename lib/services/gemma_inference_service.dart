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
        detailedError = 'Model path configuration failed: ${e.toString()}. Please check if the model file exists and has proper permissions.';
      } else if (e.toString().contains('createModel')) {
        detailedError = 'Model creation failed: ${e.toString()}. This could be due to insufficient memory, incompatible model format, or device limitations.';
      } else if (e.toString().contains('createChat')) {
        detailedError = 'Chat session creation failed: ${e.toString()}. The model loaded but chat initialization failed.';
      } else if (e.toString().contains('warmup')) {
        detailedError = 'Model warmup failed: ${e.toString()}. The model loaded but initial inference test failed.';
      } else if (e.toString().contains('Model file not found')) {
        detailedError = 'Model file missing: ${e.toString()}';
      } else {
        detailedError = 'Unknown initialization error: ${e.toString()}';
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

    try {
      _logger.i('Starting plant recognition with Gemma model');

      // Process the image
      final imageBytes = await _processImage(imageFile);
      
      // Create prompt for plant recognition
      const prompt = '''请分析这张植物图片并提供以下信息：
1. 植物名称（中文和学名）
2. 植物科属
3. 主要特征描述
4. 生长环境和分布
5. 是否有毒或需要注意的安全信息

请用简洁的中文回答。''';

      // Create message with image
      final message = Message.withImage(
        text: prompt,
        imageBytes: imageBytes,
        isUser: true,
      );

      // Add message to chat and get response stream
      await _chat!.addQuery(message);
      final responseStream = _chat!.generateChatResponseAsync();
      final responseBuffer = StringBuffer();

      await for (final response in responseStream) {
        if (response is TextResponse) {
          responseBuffer.write(response.token);
        }
      }

      final fullResponse = responseBuffer.toString().trim();
      _logger.i('Received plant recognition response: ${fullResponse.substring(0, 100)}...');

      // Parse the response into RecognitionResult
      return _parseGemmaResponse(fullResponse);
    } catch (e, stackTrace) {
      String detailedError;
      
      if (e.toString().contains('addQuery')) {
        detailedError = 'Failed to add query to chat: ${e.toString()}. Chat session may be corrupted.';
      } else if (e.toString().contains('generateChatResponseAsync')) {
        detailedError = 'Failed to generate response: ${e.toString()}. Model inference failed.';
      } else if (e.toString().contains('processImage')) {
        detailedError = 'Image processing failed: ${e.toString()}. Invalid image format or size.';
      } else if (e.toString().contains('parseGemmaResponse')) {
        detailedError = 'Failed to parse model response: ${e.toString()}. Unexpected response format.';
      } else {
        detailedError = 'Plant recognition failed: ${e.toString()}';
      }
      
      _logger.e('Plant recognition failed: $detailedError');
      _logger.e('Stack trace: $stackTrace');
      throw Exception(detailedError);
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
      
      // Build contextual prompt
      var prompt = '请分析这张植物图片。';
      
      if (userContext?.isNotEmpty == true) {
        prompt += '\n用户说明：$userContext';
      }
      
      if (season?.isNotEmpty == true) {
        prompt += '\n当前季节：$season';
      }
      
      if (location?.isNotEmpty == true) {
        prompt += '\n拍摄地点：$location';
      }

      if (quickMode) {
        prompt += '\n请简要回答植物名称和主要特征。';
      } else {
        prompt += '\n请详细分析植物的名称、科属、特征、生长环境和注意事项。';
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
      // 简单解析Gemma的文本响应
      // 在实际应用中，可能需要更复杂的解析逻辑
      
      var confidence = 0.8; // Gemma通常有较高的准确性
      var name = '未知植物';
      var description = response;
      
      // 尝试从响应中提取植物名称
      final namePattern = RegExp(r'植物名称[：:]\s*([^\n\r]+)', caseSensitive: false);
      final nameMatch = namePattern.firstMatch(response);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim() ?? name;
      }
      
      // 检测安全警告
      final safetyWarnings = <String>[];
      if (response.contains('有毒') || response.contains('毒性')) {
        safetyWarnings.add('可能有毒，请勿食用');
      }
      
      return [
        RecognitionResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          confidence: confidence,
          description: description,
          features: _extractFeatures(response),
          safety: SafetyInfo(
            level: safetyWarnings.isNotEmpty ? SafetyLevel.caution : SafetyLevel.safe,
            description: safetyWarnings.isNotEmpty ? '检测到安全警告' : '无已知安全问题',
            warnings: safetyWarnings,
          ),
          tags: ['Gemma识别', '多模态'],
          locations: ['室内', '户外'], // 默认值
        ),
      ];
    } catch (e) {
      _logger.e('Failed to parse Gemma response: $e');
      
      // 返回基础结果
      return [
        RecognitionResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '解析失败',
          confidence: 0.1,
          description: '无法解析模型响应: $response',
          features: ['解析错误'],
          safety: const SafetyInfo(
            level: SafetyLevel.unknown,
            description: '无法确定安全性',
            warnings: [],
          ),
          tags: ['错误'],
          locations: ['未知'],
        ),
      ];
    }
  }

  List<String> _extractFeatures(String response) {
    final features = <String>[];
    
    // 从响应中提取特征关键词
    final featureKeywords = [
      '叶子', '花朵', '果实', '茎', '根', '树皮',
      '绿色', '红色', '黄色', '白色', '紫色',
      '大型', '小型', '细长', '圆形', '椭圆',
      '多年生', '一年生', '草本', '木本',
    ];
    
    for (final keyword in featureKeywords) {
      if (response.contains(keyword)) {
        features.add(keyword);
      }
    }
    
    return features.isNotEmpty ? features : ['外观特征'];
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