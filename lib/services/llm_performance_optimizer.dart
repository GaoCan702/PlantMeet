import 'dart:io';
import 'package:image/image.dart' as img;

/// 大模型性能优化器 - 针对Qwen2.5-VL等视觉语言模型的性能优化
class LLMPerformanceOptimizer {
  // 性能配置
  static const int _maxImageSize = 768; // 最大图片边长
  static const int _jpegQuality = 85; // JPEG压缩质量
  static const int _maxFileSize = 2 * 1024 * 1024; // 最大文件大小 2MB
  
  // 推理配置
  static const Map<String, dynamic> _quickModeConfig = {
    'max_tokens': 512,
    'temperature': 0.1,
    'top_p': 0.9,
  };
  
  static const Map<String, dynamic> _detailedModeConfig = {
    'max_tokens': 1024,
    'temperature': 0.15,
    'top_p': 0.95,
  };
  
  /// 优化图片以适合大模型推理
  static Future<File> optimizeImageForLLM(File originalFile) async {
    try {
      // 读取原始图片
      final bytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('无法解码图片文件');
      }
      
      // 记录原始信息
      final originalSize = bytes.length;
      final originalDimensions = '${image.width}x${image.height}';
      
      // 调整图片尺寸
      image = _resizeImageForLLM(image);
      
      // 图片预处理增强
      image = _enhanceImageForRecognition(image);
      
      // 压缩并保存
      final optimizedBytes = img.encodeJpg(image, quality: _jpegQuality);
      
      // 创建优化后的临时文件
      final tempDir = Directory.systemTemp;
      final optimizedFile = File('${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await optimizedFile.writeAsBytes(optimizedBytes);
      
      // 输出优化信息
      print('🖼️ 图片优化完成:');
      print('  原始: $originalDimensions (${_formatFileSize(originalSize)})');
      print('  优化: ${image.width}x${image.height} (${_formatFileSize(optimizedBytes.length)})');
      print('  压缩率: ${((1 - optimizedBytes.length / originalSize) * 100).toStringAsFixed(1)}%');
      
      return optimizedFile;
    } catch (e) {
      print('⚠️ 图片优化失败，使用原始文件: $e');
      return originalFile;
    }
  }
  
  /// 调整图片尺寸
  static img.Image _resizeImageForLLM(img.Image image) {
    // 如果图片已经足够小，直接返回
    if (image.width <= _maxImageSize && image.height <= _maxImageSize) {
      return image;
    }
    
    // 计算缩放比例，保持宽高比
    final scale = _maxImageSize / (image.width > image.height ? image.width : image.height);
    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();
    
    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.cubic, // 使用高质量插值
    );
  }
  
  /// 增强图片以提高识别效果
  static img.Image _enhanceImageForRecognition(img.Image image) {
    // 使用高斯模糊的反向操作来增强细节
    // 避免使用不兼容的convolution方法
    
    // 调整对比度和亮度
    image = img.adjustColor(
      image,
      contrast: 1.1, // 轻微增加对比度
      brightness: 1.05, // 轻微增加亮度
      saturation: 1.1, // 轻微增加饱和度以突出植物颜色
    );
    
    return image;
  }
  
  /// 获取推理配置
  static Map<String, dynamic> getInferenceConfig({
    bool quickMode = false,
    double? customTemperature,
    int? customMaxTokens,
  }) {
    final config = Map<String, dynamic>.from(
      quickMode ? _quickModeConfig : _detailedModeConfig
    );
    
    // 允许自定义参数覆盖
    if (customTemperature != null) {
      config['temperature'] = customTemperature;
    }
    
    if (customMaxTokens != null) {
      config['max_tokens'] = customMaxTokens;
    }
    
    return config;
  }
  
  /// 根据设备性能调整配置
  static Map<String, dynamic> getDeviceOptimizedConfig() {
    // 简单的设备性能检测
    final processorCount = Platform.numberOfProcessors;
    final isLowEndDevice = processorCount <= 4;
    
    return {
      'batch_size': isLowEndDevice ? 1 : 2,
      'max_concurrent_requests': isLowEndDevice ? 1 : 2,
      'enable_kv_cache': !isLowEndDevice,
      'quantization': isLowEndDevice ? 'int8' : 'fp16',
      'max_sequence_length': isLowEndDevice ? 1024 : 2048,
    };
  }
  
  /// 预处理Prompt以提高效率
  static String optimizePrompt(String originalPrompt, {bool quickMode = false}) {
    if (quickMode) {
      // 快速模式：简化提示词
      return '''
请快速识别图片中的植物。只需要：
1. 植物名称（中文）
2. 是否安全（重要！）
3. 一句话描述

JSON格式输出，简洁准确。
''';
    }
    
    // 优化原始提示词：移除冗余，重点突出
    return originalPrompt
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // 移除多余空行
        .replaceAll(RegExp(r'[ ]{2,}'), ' ') // 移除多余空格
        .trim();
  }
  
  /// 缓存管理 - 避免重复推理
  static final Map<String, dynamic> _inferenceCache = {};
  static const int _maxCacheSize = 50;
  
  static String _generateImageHash(File imageFile) {
    // 简单的文件哈希（实际项目中应使用更强的哈希算法）
    final stat = imageFile.statSync();
    return '${stat.size}_${stat.modified.millisecondsSinceEpoch}';
  }
  
  static dynamic getCachedResult(File imageFile) {
    final hash = _generateImageHash(imageFile);
    return _inferenceCache[hash];
  }
  
  static void cacheResult(File imageFile, dynamic result) {
    if (_inferenceCache.length >= _maxCacheSize) {
      // LRU淘汰策略：移除最老的缓存
      final oldestKey = _inferenceCache.keys.first;
      _inferenceCache.remove(oldestKey);
    }
    
    final hash = _generateImageHash(imageFile);
    _inferenceCache[hash] = result;
  }
  
  static void clearCache() {
    _inferenceCache.clear();
  }
  
  /// 预热模型性能测试
  static Future<Map<String, dynamic>> performanceTest() async {
    final stopwatch = Stopwatch();
    final results = <String, dynamic>{};
    
    try {
      // 创建测试图片
      final testImage = _createTestImage();
      final testFile = await _saveTestImage(testImage);
      
      // 测试图片优化性能
      stopwatch.start();
      await optimizeImageForLLM(testFile);
      stopwatch.stop();
      
      results['image_optimization_ms'] = stopwatch.elapsedMilliseconds;
      
      // 清理测试文件
      await testFile.delete();
      
      // 设备信息
      results['device_info'] = {
        'platform': Platform.operatingSystem,
        'processors': Platform.numberOfProcessors,
        'recommended_config': getDeviceOptimizedConfig(),
      };
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }
  
  /// 创建测试图片
  static img.Image _createTestImage() {
    final image = img.Image(width: 512, height: 512);
    img.fill(image, color: img.ColorRgb8(100, 150, 100)); // 绿色背景模拟植物
    
    // 添加一些模拟的植物特征
    img.drawCircle(image, x: 256, y: 200, radius: 50, color: img.ColorRgb8(200, 100, 100));
    img.drawRect(image, x1: 200, y1: 300, x2: 312, y2: 400, color: img.ColorRgb8(80, 120, 80));
    
    return image;
  }
  
  /// 保存测试图片
  static Future<File> _saveTestImage(img.Image image) async {
    final bytes = img.encodeJpg(image, quality: 90);
    final tempDir = Directory.systemTemp;
    final testFile = File('${tempDir.path}/test_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await testFile.writeAsBytes(bytes);
    return testFile;
  }
  
  /// 格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  /// 内存管理 - 清理临时文件
  static Future<void> cleanup() async {
    try {
      final tempDir = Directory.systemTemp;
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && 
            (file.path.contains('optimized_') || file.path.contains('test_image_'))) {
          try {
            await file.delete();
          } catch (e) {
            // 忽略删除失败的文件
          }
        }
      }
      
      clearCache();
      print('🧹 性能优化器清理完成');
    } catch (e) {
      print('⚠️ 清理临时文件失败: $e');
    }
  }
  
  /// 获取性能建议
  static List<String> getPerformanceTips() {
    final tips = <String>[];
    
    final deviceConfig = getDeviceOptimizedConfig();
    final isLowEnd = deviceConfig['quantization'] == 'int8';
    
    if (isLowEnd) {
      tips.addAll([
        '设备性能较低，建议使用快速识别模式',
        '避免同时处理多张图片',
        '定期清理应用缓存以释放内存',
      ]);
    } else {
      tips.addAll([
        '设备性能良好，可使用详细识别模式',
        '支持批量处理和高质量输出',
        '建议开启本地缓存以提高响应速度',
      ]);
    }
    
    tips.addAll([
      '拍摄植物时保持清晰聚焦',
      '避免强烈逆光和阴影',
      '包含植物的关键特征（叶片、花朵等）',
    ]);
    
    return tips;
  }
}