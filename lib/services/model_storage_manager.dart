import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/embedded_model.dart';

class ModelStorageManager {
  static const String _modelBasePath = 'models';
  static const String _gemmaModelPath = 'gemma_3_nano_4b';
  static const String _metadataFile = 'model_metadata.json';
  static const String _checksumFile = 'checksums.json';
  
  final Logger _logger = Logger();
  
  Future<String> getModelBasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _modelBasePath);
  }

  /// 获取模型目录路径
  Future<String> getModelDirectory() async {
    return await getModelBasePath();
  }

  Future<String> getModelPath(String modelId) async {
    final basePath = await getModelBasePath();
    return path.join(basePath, _gemmaModelPath);
  }

  Future<Directory> ensureModelDirectory(String modelId) async {
    final modelPath = await getModelPath(modelId);
    final directory = Directory(modelPath);
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return directory;
  }

  Future<void> saveModelMetadata(String modelId, ModelInfo modelInfo) async {
    final modelDir = await ensureModelDirectory(modelId);
    final metadataFile = File(path.join(modelDir.path, _metadataFile));
    
    final metadata = {
      'model_info': modelInfo.toJson(),
      'saved_at': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    
    await metadataFile.writeAsString(jsonEncode(metadata));
    _logger.i('Saved model metadata for $modelId');
  }

  Future<ModelInfo?> loadModelMetadata(String modelId) async {
    try {
      final modelPath = await getModelPath(modelId);
      final metadataFile = File(path.join(modelPath, _metadataFile));
      
      if (!await metadataFile.exists()) {
        return null;
      }
      
      final content = await metadataFile.readAsString();
      final metadata = jsonDecode(content);
      
      return ModelInfo.fromJson(metadata['model_info']);
    } catch (e) {
      _logger.e('Error loading model metadata: $e');
      return null;
    }
  }

  Future<bool> isModelDownloaded(String modelId) async {
    try {
      // First check the status flag
      final prefs = await SharedPreferences.getInstance();
      final statusString = prefs.getString('model_${modelId}_status');
      
      if (statusString == null) {
        return false;
      }
      
      final status = ModelStatus.values.firstWhere(
        (s) => s.toString() == statusString,
        orElse: () => ModelStatus.notDownloaded,
      );
      
      if (status != ModelStatus.downloaded && status != ModelStatus.ready) {
        return false;
      }
      
      // Then verify files actually exist
      final modelInfo = await loadModelMetadata(modelId);
      if (modelInfo == null) return false;
      
      final modelPath = await getModelPath(modelId);
      
      // Check if all required files exist
      for (final filename in modelInfo.requiredFiles) {
        final file = File(path.join(modelPath, filename));
        if (!await file.exists()) {
          _logger.w('Missing file: ${file.path}');
          // Mark as not downloaded if files are missing
          await markModelStatus(modelId, ModelStatus.notDownloaded);
          return false;
        }
      }
      
      return true;
    } catch (e) {
      _logger.e('Error checking if model is downloaded: $e');
      return false;
    }
  }

  Future<bool> validateModelIntegrity(String modelId) async {
    try {
      final modelPath = await getModelPath(modelId);
      final checksumFile = File(path.join(modelPath, _checksumFile));
      
      if (!await checksumFile.exists()) {
        _logger.w('No checksum file found, skipping integrity check');
        return true; // Assume valid if no checksum available
      }
      
      final checksumContent = await checksumFile.readAsString();
      final checksums = jsonDecode(checksumContent) as Map<String, dynamic>;
      
      for (final entry in checksums.entries) {
        final filename = entry.key;
        final expectedChecksum = entry.value as String;
        
        final file = File(path.join(modelPath, filename));
        if (!await file.exists()) {
          _logger.e('Missing file during integrity check: $filename');
          return false;
        }
        
        final actualChecksum = await _calculateFileChecksum(file);
        if (actualChecksum != expectedChecksum) {
          _logger.e('Checksum mismatch for $filename');
          return false;
        }
      }
      
      _logger.i('Model integrity validated successfully');
      return true;
    } catch (e) {
      _logger.e('Error validating model integrity: $e');
      return false;
    }
  }

  Future<void> saveFileChecksum(String modelId, String filename, String checksum) async {
    try {
      final modelPath = await getModelPath(modelId);
      final checksumFile = File(path.join(modelPath, _checksumFile));
      
      Map<String, dynamic> checksums = {};
      if (await checksumFile.exists()) {
        final content = await checksumFile.readAsString();
        checksums = jsonDecode(content);
      }
      
      checksums[filename] = checksum;
      await checksumFile.writeAsString(jsonEncode(checksums));
    } catch (e) {
      _logger.e('Error saving file checksum: $e');
    }
  }

  Future<String> _calculateFileChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> getModelSize(String modelId) async {
    try {
      final modelPath = await getModelPath(modelId);
      final modelDir = Directory(modelPath);
      
      if (!await modelDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in modelDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      _logger.e('Error calculating model size: $e');
      return 0;
    }
  }

  Future<void> deleteModel(String modelId) async {
    try {
      final modelPath = await getModelPath(modelId);
      final modelDir = Directory(modelPath);
      
      if (await modelDir.exists()) {
        await modelDir.delete(recursive: true);
        _logger.i('Deleted model: $modelId');
      }
      
      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('model_${modelId}_status');
      await prefs.remove('model_${modelId}_downloaded_at');
    } catch (e) {
      _logger.e('Error deleting model: $e');
      rethrow;
    }
  }

  Future<void> cleanupOldModels() async {
    try {
      final basePath = await getModelBasePath();
      final baseDir = Directory(basePath);
      
      if (!await baseDir.exists()) {
        return;
      }
      
      // For now, we only have one model, so no cleanup needed
      // In the future, this could remove old model versions
      _logger.i('Model cleanup completed');
    } catch (e) {
      _logger.e('Error during model cleanup: $e');
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final basePath = await getModelBasePath();
      final appDir = await getApplicationDocumentsDirectory();
      
      // Calculate total used space
      int totalUsedBytes = 0;
      final baseDir = Directory(basePath);
      if (await baseDir.exists()) {
        await for (final entity in baseDir.list(recursive: true)) {
          if (entity is File) {
            final stat = await entity.stat();
            totalUsedBytes += stat.size;
          }
        }
      }
      
      // Estimate available space (simplified)
      final appDirStat = await appDir.stat();
      final estimatedAvailableBytes = 10 * 1024 * 1024 * 1024; // 10GB estimate
      
      return {
        'total_used_bytes': totalUsedBytes,
        'estimated_available_bytes': estimatedAvailableBytes,
        'base_path': basePath,
        'models_count': await _getModelCount(),
      };
    } catch (e) {
      _logger.e('Error getting storage info: $e');
      return {
        'total_used_bytes': 0,
        'estimated_available_bytes': 0,
        'base_path': '',
        'models_count': 0,
      };
    }
  }

  Future<int> _getModelCount() async {
    try {
      final basePath = await getModelBasePath();
      final baseDir = Directory(basePath);
      
      if (!await baseDir.exists()) {
        return 0;
      }
      
      int count = 0;
      await for (final entity in baseDir.list()) {
        if (entity is Directory) {
          final metadataFile = File(path.join(entity.path, _metadataFile));
          if (await metadataFile.exists()) {
            count++;
          }
        }
      }
      
      return count;
    } catch (e) {
      _logger.e('Error counting models: $e');
      return 0;
    }
  }

  Future<void> markModelStatus(String modelId, ModelStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('model_${modelId}_status', status.toString());
      
      if (status == ModelStatus.downloaded) {
        await prefs.setString(
          'model_${modelId}_downloaded_at',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      _logger.e('Error marking model status: $e');
    }
  }

  Future<ModelStatus> getModelStatus(String modelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusString = prefs.getString('model_${modelId}_status');
      
      if (statusString == null) {
        return ModelStatus.notDownloaded;
      }
      
      return ModelStatus.values.firstWhere(
        (status) => status.toString() == statusString,
        orElse: () => ModelStatus.notDownloaded,
      );
    } catch (e) {
      _logger.e('Error getting model status: $e');
      return ModelStatus.notDownloaded;
    }
  }
}