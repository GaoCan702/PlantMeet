import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plantmeet/services/model_storage_manager.dart';

/// 简化的模型下载器 - 参考 flutter_gemma 的最佳实践
class SimpleModelDownloader {
  static const String _modelUrl = 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';
  static const String _fileName = 'gemma-3n-E4B-it-int4.task';
  // 通过 --dart-define=HF_ACCESS_TOKEN=... 注入（无 Token 时将匿名访问）
  static const String _envAccessToken = String.fromEnvironment('HF_ACCESS_TOKEN', defaultValue: '');
  // SharedPreferences key
  static const String _prefsModelKey = 'installed_model_file_name';
  
  final ModelStorageManager _storageManager;
  final Logger _logger = Logger();
  
  // 并发控制
  Completer<bool>? _downloadCompleter;

  SimpleModelDownloader(this._storageManager);

  /// 获取模型文件路径
  Future<String> getModelFilePath(String modelId) async {
    final modelPath = await _storageManager.getModelPath(modelId);
    return path.join(modelPath, _fileName);
  }

  /// 检查模型是否已存在且完整
  Future<bool> isModelDownloaded(String modelId) async {
    if (_downloadCompleter != null) {
      return await _downloadCompleter!.future;
    }

    try {
      // 检查 SharedPreferences 中的记录
      final prefs = await SharedPreferences.getInstance();
      final savedFileName = prefs.getString(_prefsModelKey);
      
      if (savedFileName != _fileName) {
        return false;
      }

      final filePath = await getModelFilePath(modelId);
      final file = File(filePath);

      if (!file.existsSync()) {
        return false;
      }

      // 启动阶段仅做本地快速校验，避免网络请求阻塞冷启动
      _logger.i('✅ 本地检测到模型文件: ${file.path}');
      return true;
    } catch (e) {
      _logger.e('检查模型文件时出错: $e');
      return false;
    }
  }

  /// 删除无效文件
  Future<void> _deleteInvalidFile(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
        _logger.i('已删除损坏的模型文件');
      }
      
      // 清除 SharedPreferences 记录
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsModelKey);
    } catch (e) {
      _logger.e('删除无效文件时出错: $e');
    }
  }

  /// 获取远程文件大小
  Future<int?> _getRemoteFileSize() async {
    try {
      final headers = <String, String>{
        'User-Agent': 'PlantMeet/1.0 Flutter App',
      };
      if (_envAccessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_envAccessToken';
      }

      final response = await http.head(Uri.parse(_modelUrl), headers: headers);
      
      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        return contentLength != null ? int.parse(contentLength) : null;
      } else {
        _logger.w('HEAD 请求失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('获取远程文件大小失败: $e');
      return null;
    }
  }

  /// 下载模型文件（支持断点续传）
  Future<void> downloadModel({
    required String modelId,
    required Function(double progress) onProgress,
    required Function(String message) onStatusUpdate,
  }) async {
    // 检查是否已经在下载中
    if (_downloadCompleter != null) {
      await _downloadCompleter!.future;
      return;
    }

    // 创建下载控制器
    _downloadCompleter = Completer<bool>();

    http.StreamedResponse? response;
    IOSink? fileSink;

    try {
      onStatusUpdate('准备下载模型...');
      
      final filePath = await getModelFilePath(modelId);
      final file = File(filePath);
      
      // 确保目录存在
      await file.parent.create(recursive: true);

      // 检查是否有部分下载的文件
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
        if (downloadedBytes > 0) {
          onStatusUpdate('检测到部分下载，从 ${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB 处继续...');
        }
      }

      // 创建 HTTP 请求
      final request = http.Request('GET', Uri.parse(_modelUrl));
      request.headers.addAll({
        'User-Agent': 'PlantMeet/1.0 Flutter App',
      });
      if (_envAccessToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_envAccessToken';
      }

      // 支持断点续传
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      onStatusUpdate('连接服务器...');
      response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        
        _logger.i('开始下载: 总大小 ${(totalBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB');
        onStatusUpdate('开始下载 ${(totalBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB 文件...');

        fileSink = file.openWrite(mode: FileMode.append);
        int received = downloadedBytes;
        int lastProgressUpdate = DateTime.now().millisecondsSinceEpoch;

        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          received += chunk.length;

          // 限制进度更新频率（每100ms一次）
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastProgressUpdate > 100) {
            final progress = totalBytes > 0 ? received / totalBytes : 0.0;
            final downloadedMB = received / 1024 / 1024;
            final totalMB = totalBytes / 1024 / 1024;
            
            onProgress(progress);
            onStatusUpdate('下载中: ${downloadedMB.toStringAsFixed(1)}MB / ${totalMB.toStringAsFixed(1)}MB (${(progress * 100).toStringAsFixed(1)}%)');
            lastProgressUpdate = now;
          }
        }

        await fileSink.close();
        fileSink = null;

        // 最终验证
        final finalSize = await file.length();
        if (finalSize == totalBytes) {
          // 保存到 SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsModelKey, _fileName);
          
          _logger.i('✅ 模型下载完成: ${(finalSize / 1024 / 1024 / 1024).toStringAsFixed(2)} GB');
          onStatusUpdate('下载完成！模型已准备就绪');
          onProgress(1.0);
          
          // 完成下载
          _downloadCompleter?.complete(true);
        } else {
          throw Exception('文件下载不完整: 期望 $totalBytes 字节，实际 $finalSize 字节');
        }

      } else {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }

    } catch (e) {
      _logger.e('下载模型时出错: $e');
      onStatusUpdate('下载失败: $e');
      
      // 错误时完成 completer
      _downloadCompleter?.completeError(e);
      
      rethrow;
    } finally {
      if (fileSink != null) {
        try {
          await fileSink.close();
        } catch (e) {
          _logger.w('关闭文件流时出错: $e');
        }
      }
      
      // 无论成功还是失败，都清理 completer
      _downloadCompleter = null;
    }
  }

  /// 删除模型文件
  Future<void> deleteModel(String modelId) async {
    try {
      // 重置下载控制器
      _downloadCompleter = null;
      
      final filePath = await getModelFilePath(modelId);
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
        _logger.i('✅ 模型文件已删除');
      }
      
      // 清除 SharedPreferences 记录
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsModelKey);
      
    } catch (e) {
      _logger.e('删除模型文件时出错: $e');
      rethrow;
    }
  }

  /// 获取模型文件大小（如果存在）
  Future<int?> getModelFileSize(String modelId) async {
    try {
      final filePath = await getModelFilePath(modelId);
      final file = File(filePath);
      
      if (file.existsSync()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      _logger.e('获取模型文件大小时出错: $e');
      return null;
    }
  }

  /// 获取下载进度信息
  Future<Map<String, dynamic>> getDownloadInfo(String modelId) async {
    final isDownloaded = await isModelDownloaded(modelId);
    final fileSize = await getModelFileSize(modelId);
    final remoteSize = await _getRemoteFileSize();

    return {
      'is_downloaded': isDownloaded,
      'local_size_bytes': fileSize,
      'remote_size_bytes': remoteSize,
      'local_size_gb': fileSize != null ? fileSize / 1024 / 1024 / 1024 : null,
      'remote_size_gb': remoteSize != null ? remoteSize / 1024 / 1024 / 1024 : null,
      'file_path': await getModelFilePath(modelId),
      'model_url': _modelUrl,
    };
  }
}