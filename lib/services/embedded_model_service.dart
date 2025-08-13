import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/embedded_model.dart';
import '../models/recognition_result.dart';
import 'model_storage_manager.dart';
import 'device_capability_detector.dart';
import 'modelscope_client.dart';
import 'huggingface_client.dart';
import 'model_downloader.dart';
import 'gemma_inference_service.dart';

class EmbeddedModelService extends ChangeNotifier {
  static const String _modelId = 'google/gemma-3n-E4B-it-litert-preview'; // 使用支持视觉的 E4B 版本
  
  final ModelStorageManager _storageManager;
  final DeviceCapabilityDetector _capabilityDetector;
  final ModelScopeClient _modelScopeClient;
  final HuggingFaceClient _huggingFaceClient; // 添加 HuggingFace 客户端
  final ModelDownloader _downloader;
  final GemmaInferenceService _inferenceService;
  final Logger _logger = Logger();

  EmbeddedModelState _state = EmbeddedModelState(status: ModelStatus.notDownloaded);
  StreamSubscription<DownloadProgress>? _downloadSubscription;

  EmbeddedModelService({
    required ModelStorageManager storageManager,
    required DeviceCapabilityDetector capabilityDetector,
    required ModelScopeClient modelScopeClient,
    required HuggingFaceClient huggingFaceClient, // 添加参数
    required ModelDownloader downloader,
    required GemmaInferenceService inferenceService,
  })  : _storageManager = storageManager,
        _capabilityDetector = capabilityDetector,
        _modelScopeClient = modelScopeClient,
        _huggingFaceClient = huggingFaceClient,
        _downloader = downloader,
        _inferenceService = inferenceService;

  EmbeddedModelState get state => _state;

  void updateHuggingFaceToken(String? token) {
    _huggingFaceClient.updateAccessToken(token);
    _downloader.updateHuggingFaceToken(token);
  }

  Future<void> initialize() async {
    try {
      _logger.i('Initializing embedded model service...');
      
      // Check device capability
      final capability = await _capabilityDetector.detect();
      _updateState(_state.copyWith(capability: capability));

      // Check model status
      final isDownloaded = await _storageManager.isModelDownloaded(_modelId);
      
      if (isDownloaded) {
        // Validate model integrity
        final isValid = await _storageManager.validateModelIntegrity(_modelId);
        
        if (isValid) {
          _updateState(_state.copyWith(status: ModelStatus.downloaded));
          
          // Try to load the model
          await _tryLoadModel();
        } else {
          _logger.w('Model integrity check failed, marking as not downloaded');
          await _storageManager.deleteModel(_modelId);
          _updateState(_state.copyWith(status: ModelStatus.notDownloaded));
        }
      } else {
        _updateState(_state.copyWith(status: ModelStatus.notDownloaded));
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
      _logger.i('Starting model download...');
      
      // Check device compatibility first
      if (_state.capability == null) {
        await initialize();
      }

      // 获取模型信息
      final modelInfo = await _huggingFaceClient.getModelInfo();
      final isSupported = await _capabilityDetector.isModelSupported(modelInfo);
      
      if (!isSupported) {
        throw Exception('Device does not meet minimum requirements for this model');
      }

      // Check network connectivity
      final isNetworkAvailable = await _downloader.isNetworkAvailable();
      if (!isNetworkAvailable) {
        throw Exception('No network connection available');
      }

      _updateState(_state.copyWith(
        status: ModelStatus.downloading,
        downloadProgress: 0.0,
        modelInfo: modelInfo,
        errorMessage: null,
      ));

      // 在开发环境中使用模拟下载，生产环境中提示用户使用官方应用
      const useMockDownload = true; // TODO: 生产环境设为 false
      if (useMockDownload) {
        // 开发模式：继续模拟下载
        _downloadSubscription = _downloader.downloadModel(_modelId).listen(
          (progress) {
            _updateState(_state.copyWith(
              downloadProgress: progress.progress,
              currentSource: progress.source,
            ));
          },
          onError: (error) {
            _logger.e('Download failed: $error');
            _updateState(_state.copyWith(
              status: ModelStatus.error,
              errorMessage: 'Download failed: $error',
            ));
          },
          onDone: () async {
            _logger.i('Download completed');
            await _onDownloadCompleted();
          },
        );
      } else {
        // 生产模式：引导用户到官方 Google AI Edge Gallery
        throw Exception(
          'Direct download not available. Please install Google AI Edge Gallery from: '
          'https://github.com/google-ai-edge/gallery/releases\n\n'
          'The official app provides optimized model downloads and better device compatibility.'
        );
      }

    } catch (e) {
      _logger.e('Failed to start download: $e');
      _updateState(_state.copyWith(
        status: ModelStatus.error,
        errorMessage: 'Failed to start download: $e',
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
        // 优先使用 HuggingFace 客户端获取模型信息
        final modelInfo = await _huggingFaceClient.getModelInfo();
        _updateState(_state.copyWith(modelInfo: modelInfo));
      }
    } catch (e) {
      _logger.w('Failed to load model info: $e');
      // 降级到 ModelScope 客户端
      try {
        final modelInfo = await _modelScopeClient.getModelInfo();
        _updateState(_state.copyWith(modelInfo: modelInfo));
      } catch (e2) {
        _logger.e('Failed to load model info from both sources: $e2');
      }
    }
  }

  Future<List<RecognitionResult>> recognizePlant(File imageFile) async {
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
      await _storageManager.deleteModel(_modelId);
      
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
      _downloader.cancelDownload();
      _downloadSubscription?.cancel();
      _downloadSubscription = null;
      
      _updateState(_state.copyWith(
        status: ModelStatus.notDownloaded,
        downloadProgress: 0.0,
        errorMessage: null,
      ));
      
      _logger.i('Download cancelled');
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
    notifyListeners();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
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