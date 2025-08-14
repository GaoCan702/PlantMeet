import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/embedded_model.dart';
import '../models/recognition_result.dart';
import 'model_storage_manager.dart';
import 'device_capability_detector.dart';
import 'simple_model_downloader.dart';
import 'gemma_inference_service.dart';

class EmbeddedModelService extends ChangeNotifier {
  static const String _modelId = 'google/gemma-3n-E4B-it-litert-preview'; // 使用支持视觉的 E4B 版本
  
  final ModelStorageManager _storageManager;
  final DeviceCapabilityDetector _capabilityDetector;
  final SimpleModelDownloader _downloader;
  final GemmaInferenceService _inferenceService;
  final Logger _logger = Logger();

  EmbeddedModelState _state = EmbeddedModelState(status: ModelStatus.notDownloaded);
  String _downloadStatus = '';

  EmbeddedModelService({
    required ModelStorageManager storageManager,
    required DeviceCapabilityDetector capabilityDetector,
    required SimpleModelDownloader downloader,
    required GemmaInferenceService inferenceService,
  })  : _storageManager = storageManager,
        _capabilityDetector = capabilityDetector,
        _downloader = downloader,
        _inferenceService = inferenceService;

  EmbeddedModelState get state => _state;
  String get downloadStatus => _downloadStatus;


  Future<void> initialize() async {
    try {
      _logger.i('Initializing embedded model service...');
      
      // Check device capability
      final capability = await _capabilityDetector.detect();
      _updateState(_state.copyWith(capability: capability));

      // 启动阶段仅做本地模型校验，不进行模型加载
      final isDownloaded = await _downloader.isModelDownloaded(_modelId);
      
      if (isDownloaded) {
        _updateState(_state.copyWith(status: ModelStatus.downloaded));
        _logger.i('Local model validation passed, ready for loading when needed');
      } else {
        _updateState(_state.copyWith(status: ModelStatus.notDownloaded));
        _logger.i('No local model found, download required');
      }

      // Load model info
      await _loadModelInfo();
      
      _logger.i('Embedded model service initialized');
    } catch (e) {
      _logger.e('Failed to initialize embedded model service: $e');
      _updateState(_state.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Initialization failed: $e',
      ));
    }
  }

  Future<void> downloadModel() async {
    if (_state.status == ModelStatus.downloading) {
      _logger.w('Model download already in progress');
      return;
    }

    try {
      _logger.i('Starting simplified model download...');
      
      // Check device compatibility first
      if (_state.capability == null) {
        await initialize();
      }

      _updateState(_state.copyWith(
        status: ModelStatus.downloading,
        downloadProgress: 0.0,
        errorMessage: null,
      ));

      // 使用简化的下载器
      await _downloader.downloadModel(
        modelId: _modelId,
        onProgress: (progress) {
          _updateState(_state.copyWith(
            downloadProgress: progress,
          ));
        },
        onStatusUpdate: (status) {
          _downloadStatus = status;
          notifyListeners();
        },
      );

      _logger.i('Download completed successfully');
      await _onDownloadCompleted();

    } catch (e) {
      _logger.e('Failed to download model: $e');
      _updateState(_state.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Download failed: $e',
      ));
    }
  }

  Future<void> _onDownloadCompleted() async {
    try {
      // Verify download
      final isValid = await _storageManager.validateModelIntegrity(_modelId);
      
      if (isValid) {
        _updateState(_state.copyWith(
          status: ModelStatus.downloaded,
          downloadProgress: 1.0,
        ));
        
        // Try to load the model immediately
        await _tryLoadModel();
      } else {
        throw Exception('Downloaded model failed integrity check');
      }
    } catch (e) {
      _logger.e('Download completion failed: $e');
      _updateState(_state.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Download verification failed: $e',
      ));
    }
  }

  Future<void> _tryLoadModel() async {
    try {
      _updateState(_state.copyWith(status: ModelStatus.loading));
      
      await _inferenceService.initializeModel();
      
      if (await _inferenceService.isModelReady()) {
        _updateState(_state.copyWith(status: ModelStatus.ready));
        _logger.i('Model loaded and ready for inference');
      } else {
        throw Exception('Model failed to initialize');
      }
    } catch (e) {
      _logger.e('Failed to load model: $e');
      _updateState(_state.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Failed to load model: $e',
      ));
    }
  }

  Future<void> _loadModelInfo() async {
    try {
      if (_state.modelInfo == null) {
        // 使用下载器获取模型信息
        final downloadInfo = await _downloader.getDownloadInfo(_modelId);
        
        // 创建基本的模型信息
        final modelInfo = ModelInfo(
          id: _modelId,
          name: 'Gemma 3n E4B LiteRT Preview',
          version: 'latest',
          description: 'Google Gemma 3 Nano multimodal model optimized for mobile devices',
          sizeBytes: downloadInfo['remote_size_bytes'] ?? 4405655031,
          requiredFiles: ['gemma-3n-E4B-it-int4.task'],
          metadata: {
            'author': 'Google',
            'model_type': 'gemma-3n-e4b-litert',
            'capabilities': ['text-generation', 'vision-understanding', 'multimodal-chat'],
            'local_size_gb': downloadInfo['local_size_gb'],
            'remote_size_gb': downloadInfo['remote_size_gb'],
            'is_downloaded': downloadInfo['is_downloaded'],
          },
        );
        
        _updateState(_state.copyWith(modelInfo: modelInfo));
      }
    } catch (e) {
      _logger.w('Failed to load model info: $e');
    }
  }

  /// 按需加载模型（如果尚未加载）
  Future<void> ensureModelLoaded() async {
    if (_state.status == ModelStatus.downloaded) {
      _logger.i('Loading model on demand...');
      await _tryLoadModel();
    } else if (_state.status == ModelStatus.ready) {
      _logger.d('Model already loaded and ready');
    } else {
      throw Exception('Model is not available for loading. Current status: ${_state.status}');
    }
  }

  Future<List<RecognitionResult>> recognizePlant(File imageFile) async {
    // 如果模型未加载，先尝试加载
    if (_state.status == ModelStatus.downloaded) {
      await ensureModelLoaded();
    }
    
    if (_state.status != ModelStatus.ready) {
      throw Exception('Model is not ready. Current status: ${_state.status}');
    }

    try {
      return await _inferenceService.recognizePlant(imageFile);
    } catch (e) {
      _logger.e('Plant recognition failed: $e');
      rethrow;
    }
  }

  Future<void> deleteModel() async {
    try {
      _logger.i('Deleting model...');
      
      // Unload model from memory first
      await _inferenceService.unloadModel();
      
      // Delete model files
      await _downloader.deleteModel(_modelId);
      
      _updateState(_state.copyWith(
        status: ModelStatus.notDownloaded,
        downloadProgress: 0.0,
        errorMessage: null,
      ));
      
      _logger.i('Model deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete model: $e');
      _updateState(_state.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Failed to delete model: $e',
      ));
    }
  }

  void cancelDownload() {
    if (_state.status == ModelStatus.downloading) {
      // 简化的下载器不支持取消，直接重置状态
      _updateState(_state.copyWith(
        status: ModelStatus.notDownloaded,
        downloadProgress: 0.0,
        errorMessage: null,
      ));
      
      _logger.i('Download cancelled (simplified downloader)');
    }
  }

  Future<String> getCompatibilityReport() async {
    if (_state.modelInfo == null) {
      await _loadModelInfo();
    }
    
    if (_state.modelInfo != null) {
      return await _capabilityDetector.getCompatibilityReport(_state.modelInfo!);
    } else {
      return '无法获取模型信息';
    }
  }

  Future<Map<String, dynamic>> getModelStats() async {
    final storageInfo = await _storageManager.getStorageInfo();
    final modelSize = await _storageManager.getModelSize(_modelId);
    
    return {
      'model_id': _modelId,
      'status': _state.status.toString(),
      'model_size_bytes': modelSize,
      'model_size_mb': (modelSize / (1024 * 1024)).toStringAsFixed(1),
      'is_ready': _state.status == ModelStatus.ready,
      'storage_info': storageInfo,
      'capability': _state.capability?.additionalInfo ?? {},
    };
  }

  Future<Duration> testInferenceSpeed() async {
    if (_state.status != ModelStatus.ready) {
      throw Exception('Model is not ready for testing');
    }

    // This would require a test image
    // For now, return estimated time from capability detector
    return _state.capability?.estimatedInferenceTime ?? const Duration(seconds: 15);
  }

  void _updateState(EmbeddedModelState newState) {
    _state = newState.copyWith(lastUpdated: DateTime.now());
    
    // Sync status to ModelStorageManager's SharedPreferences
    _syncStatusToStorage();
    
    notifyListeners();
  }

  Future<void> _syncStatusToStorage() async {
    try {
      await _storageManager.markModelStatus(_modelId, _state.status);
    } catch (e) {
      _logger.w('Failed to sync status to storage: $e');
    }
  }

  @override
  void dispose() {
    _inferenceService.dispose();
    super.dispose();
  }

  // Convenience getters
  bool get isModelDownloaded => _state.status == ModelStatus.downloaded || _state.status == ModelStatus.ready;
  bool get isModelReady => _state.status == ModelStatus.ready;
  bool get isDownloading => _state.status == ModelStatus.downloading;
  bool get hasError => _state.status == ModelStatus.error;
  String? get errorMessage => _state.errorMessage;
  double get downloadProgress => _state.downloadProgress;
  ModelInfo? get modelInfo => _state.modelInfo;
  DeviceCapability? get deviceCapability => _state.capability;
}