import 'dart:io';
import 'dart:typed_data';
// import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;
import '../models/embedded_model.dart';
import '../models/recognition_result.dart';
import 'model_storage_manager.dart';
import 'device_capability_detector.dart';

// Mock implementation for FlutterGemmaPlugin until actual API is available
class FlutterGemmaPlugin {
  Future<void> init({
    required String modelPath,
    required int maxTokens,
    required double temperature,
    required int topK,
    required int randomSeed,
  }) async {
    // Mock initialization
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<String> generateResponseWithImage({
    required String prompt,
    required Uint8List image,
  }) async {
    // Mock response for plant identification
    await Future.delayed(const Duration(seconds: 5));
    return '''
植物识别结果：
1. 中文名：玫瑰花
   学名：Rosa rugosa
   置信度：85
   特征：花朵红色，有香味，茎上有刺

2. 中文名：月季花
   学名：Rosa chinensis
   置信度：75
   特征：花朵较大，颜色多样，四季开花

3. 中文名：蔷薇花
   学名：Rosa multiflora
   置信度：60
   特征：花朵较小，簇生，有淡香

毒性提醒：无明显毒性记录，但茎上有刺，注意防护
''';
  }
}

class GemmaInferenceService {
  static const String _modelId = 'google/gemma-3n-E4B-it-litert-preview';
  static const String _modelFileName = 'gemma-3n-E4B-it-int4.task';
  
  final ModelStorageManager _storageManager;
  final DeviceCapabilityDetector _capabilityDetector;
  final Logger _logger = Logger();
  
  FlutterGemmaPlugin? _gemmaPlugin;
  bool _isModelLoaded = false;
  bool _isInitializing = false;
  
  GemmaInferenceService(this._storageManager, this._capabilityDetector);

  Future<bool> isModelReady() async {
    return _isModelLoaded && _gemmaPlugin != null;
  }

  Future<void> initializeModel() async {
    if (_isModelLoaded || _isInitializing) {
      return;
    }

    _isInitializing = true;
    
    try {
      _logger.i('Initializing Gemma model...');
      
      // Check if model files exist directly instead of relying on status
      final modelPath = await _storageManager.getModelPath(_modelId);
      final modelFile = File('$modelPath/$_modelFileName');
      
      if (!await modelFile.exists()) {
        throw Exception('Model file not found at: ${modelFile.path}. Please download the model first.');
      }

      // Get device capability for optimal configuration
      final capability = await _capabilityDetector.detect();
      
      // Initialize Gemma plugin
      _gemmaPlugin = FlutterGemmaPlugin();
      
      // Configure based on device capability
      final config = _createModelConfig(capability, modelFile.path);
      
      await _gemmaPlugin!.init(
        modelPath: modelFile.path,
        maxTokens: config.maxTokens,
        temperature: config.temperature,
        topK: config.topK,
        randomSeed: config.randomSeed,
      );

      // Warm up the model with a simple inference
      await _warmupModel();
      
      _isModelLoaded = true;
      _logger.i('Gemma model initialized successfully');
      
    } catch (e) {
      _logger.e('Failed to initialize Gemma model: $e');
      _isModelLoaded = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<List<RecognitionResult>> recognizePlant(
    File imageFile, {
    int maxResults = 3,
  }) async {
    if (!_isModelLoaded || _gemmaPlugin == null) {
      throw Exception('Model not initialized. Call initializeModel() first.');
    }

    try {
      _logger.i('Starting plant recognition...');
      
      // Preprocess image
      final processedImage = await _preprocessImage(imageFile);
      
      // Create prompt for plant identification
      final prompt = _createPlantIdentificationPrompt();
      
      // Perform inference
      final startTime = DateTime.now();
      final response = await _gemmaPlugin!.generateResponseWithImage(
        prompt: prompt,
        image: processedImage,
      );
      final inferenceTime = DateTime.now().difference(startTime);
      
      _logger.i('Inference completed in ${inferenceTime.inMilliseconds}ms');
      
      // Parse response to recognition results
      final results = _parseRecognitionResponse(response, inferenceTime);
      
      return results;
      
    } catch (e) {
      _logger.e('Plant recognition failed: $e');
      rethrow;
    }
  }

  Future<Uint8List> _preprocessImage(File imageFile) async {
    try {
      // Read image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to optimal size for model (typically 224x224 or 384x384)
      const targetSize = 384;
      final resizedImage = img.copyResize(
        originalImage,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.linear,
      );

      // Convert to format expected by model
      final processedBytes = img.encodeJpg(resizedImage, quality: 90);
      
      return Uint8List.fromList(processedBytes);
      
    } catch (e) {
      _logger.e('Image preprocessing failed: $e');
      rethrow;
    }
  }

  String _createPlantIdentificationPrompt() {
    return '''
请仔细观察这张植物图片，并识别这是什么植物。请按照以下格式回答：

植物识别结果：
1. 中文名：[植物的中文常用名称]
   学名：[植物的学名（拉丁名）]
   置信度：[0-100的数字，表示识别的可信程度]
   特征：[简要描述识别的关键特征]

2. 中文名：[第二个可能的植物名称]
   学名：[对应学名]
   置信度：[置信度数字]
   特征：[关键特征描述]

3. 中文名：[第三个可能的植物名称]
   学名：[对应学名]
   置信度：[置信度数字]
   特征：[关键特征描述]

毒性提醒：[如果植物有毒，请明确说明；如果无毒或不确定，请说明"无明显毒性记录"或"毒性未知"]

请确保：
1. 提供3个最可能的识别结果
2. 学名必须是正确的拉丁双名法
3. 置信度要真实反映识别的确定程度
4. 特征描述要具体且有助于确认识别结果
5. 毒性信息要准确且负责任
''';
  }

  List<RecognitionResult> _parseRecognitionResponse(
    String response,
    Duration inferenceTime,
  ) {
    try {
      final results = <RecognitionResult>[];
      
      // Parse the structured response
      final lines = response.split('\n');
      String? currentChineseName;
      String? currentScientificName;
      int? currentConfidence;
      String? currentDescription;
      String? toxicityInfo;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.startsWith('中文名：')) {
          // Save previous result if complete
          if (currentChineseName != null && currentScientificName != null && currentConfidence != null) {
            results.add(_createRecognitionResult(
              currentChineseName,
              currentScientificName,
              currentConfidence,
              currentDescription ?? '',
              toxicityInfo,
              inferenceTime,
            ));
          }
          
          currentChineseName = trimmedLine.substring(4);
        } else if (trimmedLine.startsWith('学名：')) {
          currentScientificName = trimmedLine.substring(3);
        } else if (trimmedLine.startsWith('置信度：')) {
          final confidenceStr = trimmedLine.substring(4).replaceAll(RegExp(r'[^0-9]'), '');
          currentConfidence = int.tryParse(confidenceStr);
        } else if (trimmedLine.startsWith('特征：')) {
          currentDescription = trimmedLine.substring(3);
        } else if (trimmedLine.startsWith('毒性提醒：')) {
          toxicityInfo = trimmedLine.substring(5);
        }
      }
      
      // Save last result
      if (currentChineseName != null && currentScientificName != null && currentConfidence != null) {
        results.add(_createRecognitionResult(
          currentChineseName,
          currentScientificName,
          currentConfidence,
          currentDescription ?? '',
          toxicityInfo,
          inferenceTime,
        ));
      }
      
      // If parsing failed, create fallback results
      if (results.isEmpty) {
        results.addAll(_createFallbackResults(response, inferenceTime));
      }
      
      // Sort by confidence
      results.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      return results.take(3).toList();
      
    } catch (e) {
      _logger.e('Failed to parse recognition response: $e');
      return _createFallbackResults(response, inferenceTime);
    }
  }

  RecognitionResult _createRecognitionResult(
    String chineseName,
    String scientificName,
    int confidence,
    String description,
    String? toxicityInfo,
    Duration inferenceTime,
  ) {
    final toxicityLevel = _parseToxicityInfo(toxicityInfo);
    
    return RecognitionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: chineseName,
      scientificName: scientificName,
      confidence: confidence / 100.0, // Convert to 0-1 range
      description: description,
      features: [description], // Use description as feature
      safety: SafetyInfo(
        level: toxicityLevel ? SafetyLevel.toxic : SafetyLevel.safe,
        description: toxicityLevel 
            ? '该植物可能有毒，请小心接触' 
            : '该植物相对安全',
        warnings: toxicityInfo != null ? [toxicityInfo] : [],
      ),
      locations: ['室内', '户外'], // Default locations
      tags: ['AI识别', 'Gemma 3 Nano', '应用内模型'],
    );
  }

  bool _parseToxicityInfo(String? toxicityInfo) {
    if (toxicityInfo == null) return false;
    
    final lowerInfo = toxicityInfo.toLowerCase();
    if (lowerInfo.contains('有毒') || (lowerInfo.contains('毒性') && !lowerInfo.contains('无'))) {
      return true;
    } else if (lowerInfo.contains('无毒') || lowerInfo.contains('无明显毒性')) {
      return false;
    }
    
    return false; // Default to safe
  }

  List<RecognitionResult> _createFallbackResults(String response, Duration inferenceTime) {
    return [
      RecognitionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '识别中',
        scientificName: 'Unknown species',
        confidence: 0.5,
        description: 'AI模型正在处理中，请稍候...',
        features: ['AI识别'],
        safety: SafetyInfo(
          level: SafetyLevel.unknown,
          description: '安全性未知，请谨慎接触',
          warnings: [],
        ),
        locations: ['未知'],
        tags: ['AI识别', 'Gemma 3 Nano', '处理中'],
      ),
    ];
  }

  _ModelConfig _createModelConfig(DeviceCapability capability, String modelPath) {
    return _ModelConfig(
      maxTokens: capability.isHighEnd ? 2048 : 1024,
      temperature: 0.1, // Low temperature for more deterministic results
      topK: 40,
      randomSeed: 42,
    );
  }

  Future<void> _warmupModel() async {
    try {
      _logger.i('Warming up model...');
      
      // Create a small dummy image for warmup
      final dummyImage = _createDummyImage();
      
      await _gemmaPlugin!.generateResponseWithImage(
        prompt: '这是什么？',
        image: dummyImage,
      );
      
      _logger.i('Model warmup completed');
    } catch (e) {
      _logger.w('Model warmup failed (non-critical): $e');
    }
  }

  Uint8List _createDummyImage() {
    // Create a small 64x64 green image for warmup
    final image = img.Image(width: 64, height: 64);
    img.fill(image, color: img.ColorRgb8(0, 255, 0)); // Green
    return Uint8List.fromList(img.encodeJpg(image));
  }

  Future<void> unloadModel() async {
    if (_gemmaPlugin != null) {
      try {
        // Note: FlutterGemma might not have explicit unload method
        // This would depend on the actual plugin implementation
        _gemmaPlugin = null;
        _isModelLoaded = false;
        _logger.i('Model unloaded');
      } catch (e) {
        _logger.e('Error unloading model: $e');
      }
    }
  }

  void dispose() {
    unloadModel();
  }
}

class _ModelConfig {
  final int maxTokens;
  final double temperature;
  final int topK;
  final int randomSeed;

  _ModelConfig({
    required this.maxTokens,
    required this.temperature,
    required this.topK,
    required this.randomSeed,
  });
}