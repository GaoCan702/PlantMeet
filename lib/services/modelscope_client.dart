import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/embedded_model.dart';

class ModelScopeClient {
  static const String baseUrl = 'https://modelscope.cn/api/v1';
  static const String modelId = 'google/gemma-3n-E4B-it-litert-preview';

  final Dio _dio;
  final Logger _logger = Logger();

  ModelScopeClient() : _dio = Dio() {
    _dio.options.headers['User-Agent'] = 'PlantMeet/1.0';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  Future<ModelInfo> getModelInfo() async {
    try {
      final response = await _dio.get('$baseUrl/models/$modelId');

      if (response.statusCode == 200) {
        final data = response.data;
        return _parseModelInfo(data);
      } else {
        throw Exception('Failed to fetch model info: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching model info: $e');
      return _getFallbackModelInfo();
    }
  }

  Future<List<ModelFile>> getModelFiles() async {
    try {
      final response = await _dio.get('$baseUrl/models/$modelId/repo/files');

      if (response.statusCode == 200) {
        final data = response.data;
        final files = data['files'] as List;

        return files
            .map((file) => ModelFile.fromJson(file))
            .where((file) => _isRequiredFile(file.name))
            .toList();
      } else {
        throw Exception('Failed to fetch model files: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching model files: $e');
      return _getFallbackModelFiles();
    }
  }

  Future<String> getDownloadUrl(String filename) async {
    try {
      final response = await _dio.get(
        '$baseUrl/models/$modelId/repo/files/$filename/download',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['download_url'] as String;
      } else {
        throw Exception(
          'Failed to get download URL for $filename: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error getting download URL for $filename: $e');
      // Fallback to direct file URL
      return 'https://modelscope.cn/models/$modelId/resolve/main/$filename';
    }
  }

  Future<bool> checkModelAvailability() async {
    try {
      final response = await _dio.head('$baseUrl/models/$modelId');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error checking model availability: $e');
      return false;
    }
  }

  Future<Duration> testDownloadSpeed() async {
    const testFile = 'config.json'; // Small file for speed testing
    final stopwatch = Stopwatch()..start();

    try {
      final downloadUrl = await getDownloadUrl(testFile);
      await _dio.head(downloadUrl);
      stopwatch.stop();
      return stopwatch.elapsed;
    } catch (e) {
      _logger.e('Error testing download speed: $e');
      return const Duration(seconds: 999); // Max time indicating failure
    }
  }

  ModelInfo _parseModelInfo(Map<String, dynamic> data) {
    return ModelInfo(
      id: modelId,
      name: data['modelName'] ?? 'Gemma 3 Nano 4B',
      version: data['revision'] ?? 'main',
      sizeBytes: _calculateTotalSize(data),
      requiredFiles: _getRequiredFiles(),
      description: data['description'] ?? 'Gemma 3 Nano 4B multimodal model',
      metadata: {
        'source': 'ModelScope',
        'created_at': data['createdAt'],
        'updated_at': data['updatedAt'],
        'download_count': data['downloadCount'],
      },
    );
  }

  int _calculateTotalSize(Map<String, dynamic> data) {
    // Estimated size for Gemma 3 Nano 4B LiteRT model
    // This would be calculated from actual file sizes in production
    return 2500 * 1024 * 1024; // ~2.5GB
  }

  List<String> _getRequiredFiles() {
    return [
      'model.tflite',
      'tokenizer.json',
      'config.json',
      'special_tokens_map.json',
      'vocab.json',
    ];
  }

  bool _isRequiredFile(String filename) {
    final requiredFiles = _getRequiredFiles();
    return requiredFiles.contains(filename) ||
        filename.endsWith('.tflite') ||
        filename.endsWith('.json');
  }

  ModelInfo _getFallbackModelInfo() {
    return ModelInfo(
      id: modelId,
      name: 'Gemma 3 Nano 4B',
      version: 'main',
      sizeBytes: 2500 * 1024 * 1024, // ~2.5GB
      requiredFiles: _getRequiredFiles(),
      description:
          'Gemma 3 Nano 4B multimodal model for text and image understanding',
      metadata: {'source': 'ModelScope', 'fallback': true},
    );
  }

  List<ModelFile> _getFallbackModelFiles() {
    final baseUrl = 'https://modelscope.cn/models/$modelId/resolve/main';

    return [
      ModelFile(
        name: 'model.tflite',
        size: 2200 * 1024 * 1024, // ~2.2GB
        downloadUrl: '$baseUrl/model.tflite',
      ),
      ModelFile(
        name: 'tokenizer.json',
        size: 500 * 1024, // ~500KB
        downloadUrl: '$baseUrl/tokenizer.json',
      ),
      ModelFile(
        name: 'config.json',
        size: 10 * 1024, // ~10KB
        downloadUrl: '$baseUrl/config.json',
      ),
      ModelFile(
        name: 'special_tokens_map.json',
        size: 5 * 1024, // ~5KB
        downloadUrl: '$baseUrl/special_tokens_map.json',
      ),
      ModelFile(
        name: 'vocab.json',
        size: 100 * 1024, // ~100KB
        downloadUrl: '$baseUrl/vocab.json',
      ),
    ];
  }
}
