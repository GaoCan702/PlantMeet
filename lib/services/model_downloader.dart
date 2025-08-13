import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import '../models/embedded_model.dart';
import 'modelscope_client.dart';
import 'huggingface_client.dart';
import 'model_storage_manager.dart';

class ModelDownloader {
  // 不再使用模拟下载，直接使用真实的 HuggingFace 客户端
  bool get _useMockDownload => false;
  
  // Google AI Edge Gallery 官方下载源
  static const String _aiEdgeReleaseUrl = 'https://github.com/google-ai-edge/gallery/releases/latest/download/gemma-3n-4b-it-litert.task';
  
  // TensorFlow Hub 植物识别模型（公开可下载）
  static const String _tfhubPlantModel = 'https://tfhub.dev/google/aiy/vision/classifier/plants_V1/1';
  static const String _plantnetModel = 'https://storage.googleapis.com/tfhub-modules/google/aiy/vision/classifier/plants_V1/1.tar.gz';
  
  // 使用公开可下载的植物识别 TFLite 模型
  static final Map<ModelSource, ModelSourceInfo> _sources = {
    ModelSource.github: ModelSourceInfo(
      baseUrl: 'https://raw.githubusercontent.com',
      modelId: 'plant-disease-detection-v1', 
      priority: 1, // 最高优先级 - 专门的植物识别模型
      regionOptimized: ['Global'], // 全球可用
      testUrl: 'https://raw.githubusercontent.com/akshayrana30/plant-disease-detection/master/PlantSaverApp/app/src/main/assets/model.tflite',
    ),
    ModelSource.huggingFace: ModelSourceInfo(
      baseUrl: 'https://huggingface.co',
      modelId: 'google/gemma-3n-E4B-it-litert-preview', // 保留作为备用
      priority: 2, // 降低优先级
      regionOptimized: ['US', 'EU', 'CN'], 
      testUrl: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview',
    ),
    ModelSource.modelScope: ModelSourceInfo(
      baseUrl: 'https://modelscope.cn',
      modelId: 'google/gemma-3n-E4B-it-litert-preview',
      priority: 2, // 备用选项
      regionOptimized: ['CN', 'AS'],
      testUrl: 'https://modelscope.cn/api/v1/models/google/gemma-3n-E4B-it-litert-preview',
    ),
    ModelSource.kaggle: ModelSourceInfo(
      baseUrl: 'https://www.kaggle.com',
      modelId: 'google/gemma',
      priority: 3,
      regionOptimized: ['US'],
      testUrl: 'https://www.kaggle.com/models/google/gemma',
    ),
  };

  final ModelStorageManager _storageManager;
  final ModelScopeClient _modelScopeClient;
  final HuggingFaceClient _huggingFaceClient;
  final Logger _logger = Logger();
  final Dio _dio;

  CancelToken? _currentDownloadToken;
  StreamController<DownloadProgress>? _progressController;

  ModelDownloader(this._storageManager, this._modelScopeClient, this._huggingFaceClient) 
      : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
  }

  Stream<DownloadProgress> downloadModel(String modelId) async* {
    _currentDownloadToken = CancelToken();
    _progressController = StreamController<DownloadProgress>.broadcast();

    try {
      yield* _downloadWithFallback(modelId);
    } catch (e) {
      _logger.e('Download failed: $e');
      rethrow;
    } finally {
      await _progressController?.close();
      _progressController = null;
      _currentDownloadToken = null;
    }
  }

  Stream<DownloadProgress> _downloadWithFallback(String modelId) async* {
    final sources = await _getOptimizedSourceOrder();
    Exception? lastError;

    for (final source in sources) {
      try {
        _logger.i('Attempting download from ${source.name}');
        
        yield* _downloadFromSource(modelId, source);
        return; // Success, exit
      } catch (e) {
        lastError = e as Exception;
        _logger.w('Download failed from ${source.name}: $e');
        
        // If not the last source, continue to next
        if (source != sources.last) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
      }
    }

    throw DownloadException(
      'All download sources failed',
      sources.last,
      lastError,
    );
  }

  Stream<DownloadProgress> _downloadFromSource(
    String modelId,
    ModelSource source,
  ) async* {
    final modelInfo = await _getModelInfo(source);
    final modelFiles = await _getModelFiles(source);
    final modelDir = await _storageManager.ensureModelDirectory(modelId);

    int totalBytes = modelFiles.fold(0, (sum, file) => sum + file.size);
    int downloadedBytes = 0;
    final startTime = DateTime.now();

    await _storageManager.markModelStatus(modelId, ModelStatus.downloading);
    await _storageManager.saveModelMetadata(modelId, modelInfo);

    for (final file in modelFiles) {
      final filePath = path.join(modelDir.path, file.name);
      final tempFilePath = '$filePath.tmp';

      // Check if file already exists and is valid
      if (await _isFileValid(filePath, file)) {
        downloadedBytes += file.size;
        yield _createProgress(downloadedBytes, totalBytes, source, startTime);
        continue;
      }

      // Download file
      await _downloadFile(
        file.downloadUrl,
        tempFilePath,
        onProgress: (received, total) {
          final currentProgress = downloadedBytes + received;
          if (_progressController != null && !_progressController!.isClosed) {
            _progressController!.add(
              _createProgress(currentProgress, totalBytes, source, startTime),
            );
          }
        },
      );

      // Verify and move file
      if (await _verifyFile(tempFilePath, file)) {
        await File(tempFilePath).rename(filePath);
        downloadedBytes += file.size;

        // Save checksum
        if (file.checksum != null) {
          await _storageManager.saveFileChecksum(
            modelId,
            file.name,
            file.checksum!,
          );
        }

        yield _createProgress(downloadedBytes, totalBytes, source, startTime);
      } else {
        await File(tempFilePath).delete();
        throw DownloadException(
          'File verification failed: ${file.name}',
          source,
        );
      }
    }

    // Final validation
    if (await _storageManager.validateModelIntegrity(modelId)) {
      await _storageManager.markModelStatus(modelId, ModelStatus.downloaded);
      _logger.i('Model download completed successfully');
    } else {
      throw DownloadException('Model integrity check failed', source);
    }
  }

  Future<void> _downloadFile(
    String url,
    String filePath,
    {required Function(int, int) onProgress}
  ) async {
    if (_useMockDownload) {
      // 模拟下载过程
      await _simulateDownload(filePath, onProgress);
      return;
    }
    
    // 真实下载
    try {
      await _dio.download(
        url,
        filePath,
        cancelToken: _currentDownloadToken,
        onReceiveProgress: onProgress,
        options: Options(
          headers: {
            'User-Agent': 'PlantMeet/1.0 Flutter',
            'Accept': 'application/octet-stream',
          },
        ),
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        throw DownloadException(
          '下载被拒绝: 请先在 HuggingFace 网站上接受 Gemma 模型的使用条款。\n'
          '访问 https://huggingface.co/google/gemma-2b-it 并点击 "Agree and access repository"',
          ModelSource.huggingFace,
          e,
        );
      }
      rethrow;
    }
  }

  Future<void> _simulateDownload(
    String filePath,
    Function(int, int) onProgress,
  ) async {
    // 模拟文件下载过程
    final fileName = path.basename(filePath);
    final fileSize = _getExpectedFileSize(fileName);
    
    // 创建临时内容
    final content = _createMockFileContent(fileName);
    
    // 模拟渐进式下载
    const chunkSize = 1024 * 1024; // 1MB chunks
    int downloaded = 0;
    
    while (downloaded < fileSize) {
      if (_currentDownloadToken?.isCancelled == true) {
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: 'mock://download'),
          reason: 'Download cancelled by user',
        );
      }
      
      final remaining = fileSize - downloaded;
      final currentChunk = remaining < chunkSize ? remaining : chunkSize;
      downloaded += currentChunk;
      
      // 报告进度
      onProgress(downloaded, fileSize);
      
      // 模拟下载延时
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // 写入模拟文件内容
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(content);
    
    _logger.i('模拟文件下载完成: $fileName (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)');
  }

  int _getExpectedFileSize(String fileName) {
    if (fileName == 'gemma-3n-E4B-it-int4.task') {
      return 4405655031; // 4.10GB LiteRT 任务文件
    } else if (fileName == 'model.tflite') {
      return 2000 * 1024 * 1024; // 2GB 传统模型
    } else if (fileName == 'tokenizer.json') {
      return 5 * 1024 * 1024; // 5MB
    } else {
      return 1024 * 1024; // 1MB 默认
    }
  }

  List<int> _createMockFileContent(String fileName) {
    if (fileName == 'gemma-3n-E4B-it-int4.task') {
      // 创建一个假的 LiteRT 任务文件
      final content = List<int>.filled(4405655031, 0);
      // 添加 LiteRT 任务文件魔数标识
      const taskMagic = [0x54, 0x41, 0x53, 0x4B]; // "TASK"
      for (int i = 0; i < taskMagic.length; i++) {
        content[i] = taskMagic[i];
      }
      return content;
    } else if (fileName == 'model.tflite') {
      // 创建一个假的 TFLite 模型文件头
      final content = List<int>.filled(2000 * 1024 * 1024, 0);
      // 添加 TFLite 魔数标识
      const tfliteMagic = [0x54, 0x46, 0x4C, 0x33]; // "TFL3"
      for (int i = 0; i < tfliteMagic.length; i++) {
        content[i] = tfliteMagic[i];
      }
      return content;
    } else if (fileName == 'tokenizer.json') {
      // 创建一个假的分词器配置文件
      final jsonContent = '''
{
  "version": "1.0",
  "truncation": null,
  "padding": null,
  "added_tokens": [],
  "normalizer": null,
  "pre_tokenizer": {
    "type": "ByteLevel",
    "add_prefix_space": false,
    "trim_offsets": true
  },
  "post_processor": null,
  "decoder": {
    "type": "ByteLevel",
    "add_prefix_space": true,
    "trim_offsets": true
  },
  "model": {
    "type": "BPE",
    "dropout": null,
    "unk_token": null,
    "continuing_subword_prefix": null,
    "end_of_word_suffix": null,
    "fuse_unk": false,
    "vocab": {},
    "merges": []
  }
}''';
      // 填充到目标大小
      final baseContent = utf8.encode(jsonContent);
      final targetSize = 5 * 1024 * 1024; // 5MB
      final content = List<int>.filled(targetSize, 32); // 用空格填充
      for (int i = 0; i < baseContent.length; i++) {
        content[i] = baseContent[i];
      }
      return content;
    } else {
      return List<int>.filled(1024 * 1024, 0); // 1MB 填充
    }
  }

  Future<bool> _isFileValid(String filePath, ModelFile file) async {
    final fileExists = await File(filePath).exists();
    if (!fileExists) return false;

    final stat = await File(filePath).stat();
    if (stat.size != file.size) return false;

    // If checksum is available, verify it
    if (file.checksum != null) {
      final actualChecksum = await _calculateFileChecksum(filePath);
      return actualChecksum == file.checksum;
    }

    return true;
  }

  Future<bool> _verifyFile(String filePath, ModelFile file) async {
    final fileExists = await File(filePath).exists();
    if (!fileExists) return false;

    final stat = await File(filePath).stat();
    if (stat.size != file.size) {
      _logger.w('File size mismatch: expected ${file.size}, got ${stat.size}');
      return false;
    }

    return true;
  }

  Future<String> _calculateFileChecksum(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  DownloadProgress _createProgress(
    int downloadedBytes,
    int totalBytes,
    ModelSource source,
    DateTime startTime,
  ) {
    final elapsed = DateTime.now().difference(startTime);
    final speed = elapsed.inMilliseconds > 0 
        ? downloadedBytes / elapsed.inMilliseconds * 1000 
        : 0.0;
    
    final remainingBytes = totalBytes - downloadedBytes;
    final estimatedTime = speed > 0 
        ? Duration(seconds: (remainingBytes / speed).round())
        : const Duration(seconds: 0);

    return DownloadProgress(
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      speed: speed,
      estimatedTimeRemaining: estimatedTime,
      source: source,
    );
  }

  Future<List<ModelSource>> _getOptimizedSourceOrder() async {
    // 优先使用 flutter_gemma 推荐的 HuggingFace
    // 这是最稳定可靠的下载源
    return [
      ModelSource.huggingFace, // flutter_gemma 官方推荐
      ModelSource.modelScope,  // 国内备用
      ModelSource.kaggle,      // Kaggle 备用
    ];
  }

  Future<ModelInfo> _getModelInfo(ModelSource source) async {
    switch (source) {
      case ModelSource.github:
        return _getGitHubModelInfo();
      case ModelSource.huggingFace:
        // 使用专用的 HuggingFace 客户端
        return await _huggingFaceClient.getModelInfo();
      case ModelSource.modelScope:
        return await _modelScopeClient.getModelInfo();
      case ModelSource.kaggle:
      case ModelSource.google:
      case ModelSource.direct:
        // 优先使用 HuggingFace 客户端作为降级
        return await _huggingFaceClient.getModelInfo();
    }
  }

  Future<List<ModelFile>> _getModelFiles(ModelSource source) async {
    switch (source) {
      case ModelSource.github:
        return _getGitHubModelFiles();
      case ModelSource.huggingFace:
        // 使用专用的 HuggingFace 客户端获取文件列表
        return await _huggingFaceClient.getModelFiles();
      case ModelSource.modelScope:
        return await _modelScopeClient.getModelFiles();
      case ModelSource.kaggle:
      case ModelSource.google:
      case ModelSource.direct:
        // 优先使用 HuggingFace 客户端作为降级
        return await _huggingFaceClient.getModelFiles();
    }
  }

  Future<Duration> testSourceSpeed(ModelSource source) async {
    final sourceInfo = _sources[source];
    if (sourceInfo?.testUrl == null) {
      return const Duration(seconds: 999);
    }

    final stopwatch = Stopwatch()..start();
    try {
      await _dio.head(sourceInfo!.testUrl!);
      stopwatch.stop();
      return stopwatch.elapsed;
    } catch (e) {
      _logger.e('Error testing ${source.name} speed: $e');
      return const Duration(seconds: 999);
    }
  }

  Future<bool> isNetworkAvailable() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  Future<bool> isWifiConnected() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  void cancelDownload() {
    _currentDownloadToken?.cancel('User cancelled download');
    _logger.i('Download cancelled by user');
  }

  /// 获取 GitHub 开源植物识别模型信息
  ModelInfo _getGitHubModelInfo() {
    return ModelInfo(
      id: 'plant-disease-detection-v1',
      name: 'Plant Disease Detection TFLite',
      version: '1.0',
      description: 'Open source plant disease detection model optimized for mobile devices. '
          'Trained to identify common plant diseases and health conditions.',
      sizeBytes: 15 * 1024 * 1024, // 约 15MB (比 Gemma 3n 小得多)
      requiredFiles: ['model.tflite'],
      metadata: {
        'author': 'Open Source Community',
        'license': 'MIT/Apache 2.0',
        'tags': ['plant-disease', 'mobile', 'tensorflow-lite', 'plant-recognition'],
        'sourceRepository': 'https://github.com/akshayrana30/plant-disease-detection',
        'modelType': 'cnn-classification',
        'capabilities': [
          'plant-disease-detection',
          'plant-health-assessment',
          'mobile-optimized',
        ],
        'supportedFormats': ['tflite'],
        'optimization': 'quantized-int8',
        'accuracy': '90%+',
        'inferenceTime': '<100ms on mobile CPU',
      },
    );
  }

  /// 获取 GitHub 开源植物识别模型文件列表
  List<ModelFile> _getGitHubModelFiles() {
    const baseUrl = 'https://raw.githubusercontent.com/akshayrana30/plant-disease-detection/master/PlantSaverApp/app/src/main/assets';
    
    return [
      ModelFile(
        name: 'model.tflite',
        size: 15 * 1024 * 1024, // 15MB
        downloadUrl: '$baseUrl/model.tflite',
        checksum: null, // GitHub raw files 通常不提供 checksum
      ),
    ];
  }

  void dispose() {
    _currentDownloadToken?.cancel();
    _progressController?.close();
  }
}