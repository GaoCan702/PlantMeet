import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/embedded_model.dart';

/// HuggingFace 客户端 - 直接从 HuggingFace 下载 Gemma 3 Nano 模型
class HuggingFaceClient {
  static const String _baseUrl = 'https://huggingface.co';
  static const String _apiBaseUrl = 'https://huggingface.co/api';
  // 使用 Gemma 3n E4B LiteRT 模型，专为移动设备优化
  static const String _modelId = 'google/gemma-3n-E4B-it-litert-preview';
  // 通过 --dart-define=HF_ACCESS_TOKEN=... 注入；为空时匿名请求
  static const String _envAccessToken = String.fromEnvironment(
    'HF_ACCESS_TOKEN',
    defaultValue: '',
  );

  final Dio _dio;
  final Logger _logger = Logger();

  HuggingFaceClient() : _dio = Dio() {
    _dio.options.baseUrl = _apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 5);
    final headers = <String, String>{
      'User-Agent': 'PlantMeet/1.0 Flutter App',
      'Accept': 'application/json',
    };
    if (_envAccessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_envAccessToken';
    }
    _dio.options.headers = headers;

    _logger.i('HuggingFace client initialized with embedded access token');
  }

  bool get hasValidToken => _envAccessToken.isNotEmpty;

  /// 获取模型基本信息
  Future<ModelInfo> getModelInfo() async {
    try {
      _logger.i('获取 Gemma 3 Nano 模型信息...');

      // HuggingFace API 获取模型信息
      final response = await _dio.get('/models/$_modelId');
      final data = response.data;

      return ModelInfo(
        id: _modelId,
        name: 'Gemma 3n E4B LiteRT Preview',
        version: data['sha'] ?? 'latest',
        description:
            'Google Gemma 3 Nano multimodal model optimized for mobile devices with vision support (LiteRT)',
        sizeBytes: 4405655031, // 4.1GB 准确大小 (E4B)
        requiredFiles: ['gemma-3n-E4B-it-int4.task'], // LiteRT 任务文件
        metadata: {
          'author': 'Google',
          'license': data['cardData']?['license'] ?? 'Gemma License',
          'tags':
              (data['tags'] as List?)?.cast<String>() ??
              ['multimodal', 'vision', 'text-generation'],
          'downloadCount': data['downloads'] ?? 0,
          'lastModified':
              DateTime.tryParse(data['lastModified'] ?? '') ??
              DateTime.now().toIso8601String(),
          'modelType': 'gemma-3n-e4b',
          'capabilities': [
            'text-generation',
            'vision-understanding',
            'multimodal-chat',
            'plant-identification',
          ],
          'requirements': {
            'min_android_api': 24,
            'min_ios_version': '12.0',
            'min_ram_mb': 2048,
            'storage_mb': 2500,
          },
        },
      );
    } catch (e) {
      _logger.e('获取模型信息失败: $e');
      // 返回默认信息作为降级处理
      return _getDefaultModelInfo();
    }
  }

  /// 获取模型文件列表
  Future<List<ModelFile>> getModelFiles() async {
    try {
      _logger.i('获取 Gemma 3n E4B LiteRT 模型文件列表...');

      // Gemma 3n E4B LiteRT Preview 使用单个 .task 文件
      final requiredFiles = [
        'gemma-3n-E4B-it-int4.task', // 4.1GB LiteRT 任务文件
      ];

      final modelFiles = <ModelFile>[];

      // 直接获取每个必需文件的信息
      for (final fileName in requiredFiles) {
        try {
          final modelFile = await _getFileInfo(fileName);
          modelFiles.add(modelFile);
          _logger.i(
            '✅ 找到文件: $fileName (${(modelFile.size / 1024 / 1024).toStringAsFixed(1)} MB)',
          );
        } catch (e) {
          _logger.w('⚠️ 获取文件信息失败 $fileName: $e，使用估算大小');

          // 为必需文件创建默认条目
          final downloadUrl = '$_baseUrl/$_modelId/resolve/main/$fileName';
          final estimatedSize = _estimateFileSize(fileName);

          modelFiles.add(
            ModelFile(
              name: fileName,
              size: estimatedSize,
              downloadUrl: downloadUrl,
              checksum: null,
            ),
          );
        }
      }

      if (modelFiles.isEmpty) {
        throw Exception('未找到有效的模型文件');
      }

      final totalSizeGB = modelFiles.fold<double>(
        0,
        (sum, file) => sum + (file.size / 1024 / 1024 / 1024),
      );
      _logger.i(
        '📦 LiteRT 模型文件列表准备完成，共 ${modelFiles.length} 个文件，总大小: ${totalSizeGB.toStringAsFixed(2)} GB',
      );
      return modelFiles;
    } catch (e) {
      _logger.e('获取模型文件列表失败: $e');
      // 返回默认文件列表作为降级处理
      return _getDefaultModelFiles();
    }
  }

  /// 获取单个文件信息
  Future<ModelFile> _getFileInfo(String fileName) async {
    final downloadUrl = '$_baseUrl/$_modelId/resolve/main/$fileName';

    try {
      // 获取文件大小
      final headResponse = await _dio.head(downloadUrl);
      final contentLength = headResponse.headers['content-length']?.first;
      final fileSize = contentLength != null ? int.parse(contentLength) : 0;

      return ModelFile(
        name: fileName,
        size: fileSize,
        downloadUrl: downloadUrl,
        checksum: null, // HuggingFace 通常不提供 checksum
      );
    } catch (e) {
      _logger.w('获取文件信息失败 $fileName: $e');
      // 返回默认信息
      return ModelFile(
        name: fileName,
        size: _estimateFileSize(fileName),
        downloadUrl: downloadUrl,
        checksum: null,
      );
    }
  }

  /// 判断是否为必需的模型文件
  bool _isRequiredModelFile(String fileName) {
    final requiredExtensions = ['.tflite', '.bin', '.json', '.txt'];
    final ignoredFiles = ['README.md', 'config.json', '.gitattributes'];

    if (ignoredFiles.contains(fileName)) return false;

    return requiredExtensions.any(
          (ext) => fileName.toLowerCase().endsWith(ext),
        ) ||
        fileName.contains('model') ||
        fileName.contains('weights') ||
        fileName.contains('tokenizer');
  }

  /// 获取文件类型
  String _getFileType(String fileName) {
    if (fileName.endsWith('.tflite')) return 'model';
    if (fileName.endsWith('.json')) return 'config';
    if (fileName.endsWith('.txt')) return 'tokenizer';
    if (fileName.endsWith('.bin')) return 'weights';
    return 'other';
  }

  /// 获取文件描述
  String _getFileDescription(String fileName) {
    if (fileName.contains('model') && fileName.endsWith('.tflite')) {
      return 'TensorFlow Lite 模型文件';
    }
    if (fileName.contains('tokenizer')) {
      return '分词器配置文件';
    }
    if (fileName.endsWith('.json')) {
      return '模型配置文件';
    }
    if (fileName.endsWith('.bin')) {
      return '模型权重文件';
    }
    return '模型相关文件';
  }

  /// 估算文件大小
  int _estimateFileSize(String fileName) {
    if (fileName == 'gemma-3n-E4B-it-int4.task') {
      return 4405655031; // 4.1GB 准确大小 (E4B)
    }
    if (fileName.endsWith('.json')) {
      return 2048; // ~2KB JSON配置文件
    }
    return 1024 * 1024; // 1MB 默认
  }

  /// 估算模型总大小
  int _estimateModelSize() {
    return 4405655031; // 4.1GB LiteRT 任务文件准确大小 (E4B)
  }

  /// 获取默认模型信息（降级处理）
  ModelInfo _getDefaultModelInfo() {
    return ModelInfo(
      id: _modelId,
      name: 'Gemma 3n E4B LiteRT Preview',
      version: 'latest',
      description:
          'Google Gemma 3 Nano multimodal model optimized for mobile devices with vision support (LiteRT)',
      sizeBytes: _estimateModelSize(),
      requiredFiles: ['gemma-3n-E4B-it-int4.task'],
      metadata: {
        'author': 'Google',
        'license': 'Gemma License',
        'tags': [
          'multimodal',
          'vision',
          'text-generation',
          'litert',
          'mobile-optimized',
        ],
        'downloadCount': 0,
        'lastModified': DateTime.now().toIso8601String(),
        'modelType': 'gemma-3n-e4b-litert',
        'capabilities': [
          'text-generation',
          'vision-understanding',
          'multimodal-chat',
          'plant-identification',
          'litert-optimized',
        ],
        'requirements': {
          'min_android_api': 24,
          'min_ios_version': '12.0',
          'min_ram_mb': 3072,
          'storage_mb': 4500,
        },
      },
    );
  }

  /// 获取默认文件列表（降级处理）
  List<ModelFile> _getDefaultModelFiles() {
    return [
      ModelFile(
        name: 'gemma-3n-E4B-it-int4.task',
        size: 4405655031, // 4.1GB 准确大小
        downloadUrl:
            '$_baseUrl/$_modelId/resolve/main/gemma-3n-E4B-it-int4.task',
        checksum: null,
      ),
    ];
  }

  /// 测试连接
  Future<bool> testConnection() async {
    if (!hasValidToken) {
      _logger.w('HuggingFace 连接测试失败: 无有效 token');
      return false;
    }

    try {
      _logger.i('开始测试 HuggingFace 连接，模型: $_modelId');

      final response = await _dio.get(
        '/models/$_modelId',
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          headers: _envAccessToken.isNotEmpty
              ? {'Authorization': 'Bearer $_envAccessToken'}
              : {},
        ),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ HuggingFace 连接测试成功');
        return true;
      } else {
        _logger.w('❌ HuggingFace 连接测试失败: HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ HuggingFace 连接测试失败: $e');
      return false;
    }
  }

  /// 获取下载统计信息
  Future<Map<String, dynamic>> getDownloadStats() async {
    try {
      final response = await _dio.get('/models/$_modelId');
      final data = response.data;

      return {
        'downloads': data['downloads'] ?? 0,
        'likes': data['likes'] ?? 0,
        'last_modified': data['lastModified'],
        'model_size': _estimateModelSize(),
        'files_count': 1, // 单个 .task 文件
      };
    } catch (e) {
      _logger.w('获取下载统计失败: $e');
      return {
        'downloads': 0,
        'likes': 0,
        'last_modified': DateTime.now().toIso8601String(),
        'model_size': _estimateModelSize(),
        'files_count': 1,
      };
    }
  }

  void dispose() {
    _dio.close();
  }
}
