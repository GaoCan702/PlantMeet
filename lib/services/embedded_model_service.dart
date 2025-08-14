import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/embedded_model.dart';
import '../models/recognition_result.dart';
import 'model_storage_manager.dart';
import 'device_capability_detector.dart';
import 'simple_model_downloader.dart';
import 'gemma_inference_service.dart';

class EmbeddedModelService extends ChangeNotifier with WidgetsBindingObserver {
  static const String _modelId =
      'google/gemma-3n-E4B-it-litert-preview'; // 使用支持视觉的 E4B 版本

  final ModelStorageManager _storageManager;
  final DeviceCapabilityDetector _capabilityDetector;
  final SimpleModelDownloader _downloader;
  final GemmaInferenceService _inferenceService;
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  // 指数退避
  int _retryAttempt = 0;
  Timer? _retryTimer;

  EmbeddedModelState _state = EmbeddedModelState(
    status: ModelStatus.notDownloaded,
  );
  String _downloadStatus = '';

  EmbeddedModelService({
    required ModelStorageManager storageManager,
    required DeviceCapabilityDetector capabilityDetector,
    required SimpleModelDownloader downloader,
    required GemmaInferenceService inferenceService,
  }) : _storageManager = storageManager,
       _capabilityDetector = capabilityDetector,
       _downloader = downloader,
       _inferenceService = inferenceService;

  EmbeddedModelState get state => _state;
  String get downloadStatus => _downloadStatus;

  Future<void> initialize() async {
    try {
      _logger.i('Initializing embedded model service...');
      // 监听应用生命周期
      WidgetsBinding.instance.addObserver(this);
      // 监听网络变化
      _connectivity.onConnectivityChanged.listen((results) {
        _handleConnectivityChange(results);
      });
      // 初始化电量与省电模式提示
      unawaited(_battery.batteryLevel.then((_) {}));

      // Check device capability
      final capability = await _capabilityDetector.detect();
      _updateState(_state.copyWith(capability: capability));

      // 启动阶段仅做本地模型校验，不进行模型加载
      final isDownloaded = await _downloader.isModelDownloaded(_modelId);

      if (isDownloaded) {
        _updateState(_state.copyWith(status: ModelStatus.downloaded));
        _logger.i(
          'Local model validation passed, ready for loading when needed',
        );
      } else {
        _updateState(_state.copyWith(status: ModelStatus.notDownloaded));
        _logger.i('No local model found, download required');
      }

      // Load model info
      await _loadModelInfo();

      _logger.i('Embedded model service initialized');
    } catch (e) {
      _logger.e('Failed to initialize embedded model service: $e');
      _updateState(
        _state.copyWith(
          status: ModelStatus.error,
          errorMessage: 'Initialization failed: $e',
        ),
      );
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

      _updateState(
        _state.copyWith(
          status: ModelStatus.downloading,
          downloadProgress: 0.0,
          errorMessage: null,
        ),
      );

      // 使用简化的下载器
      await _downloader.downloadModel(
        modelId: _modelId,
        onProgress: (progress) {
          _updateState(_state.copyWith(downloadProgress: progress));
        },
        onStatusUpdate: (status) {
          _downloadStatus = status;
          notifyListeners();
        },
      );

      _logger.i('Download completed successfully');
      await _onDownloadCompleted();
    } catch (e) {
      // 暂停不视为错误
      if (e is DownloadPausedException) {
        _logger.i('Download paused by lifecycle');
        _downloadStatus = '下载已暂停';
        notifyListeners();
      } else {
        _logger.e('Failed to download model: $e');
        _updateState(
          _state.copyWith(
            status: ModelStatus.error,
            errorMessage: 'Download failed: $e',
          ),
        );
      }
    }
  }

  Future<void> _onDownloadCompleted() async {
    try {
      // Verify download
      final isValid = await _storageManager.validateModelIntegrity(_modelId);

      if (isValid) {
        _updateState(
          _state.copyWith(
            status: ModelStatus.downloaded,
            downloadProgress: 1.0,
          ),
        );

        // Try to load the model immediately
        await _tryLoadModel();
      } else {
        throw Exception('Downloaded model failed integrity check');
      }
    } catch (e) {
      _logger.e('Download completion failed: $e');
      _updateState(
        _state.copyWith(
          status: ModelStatus.error,
          errorMessage: 'Download verification failed: $e',
        ),
      );
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
      _updateState(
        _state.copyWith(
          status: ModelStatus.error,
          errorMessage: 'Failed to load model: $e',
        ),
      );
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
          description:
              'Google Gemma 3 Nano multimodal model optimized for mobile devices',
          sizeBytes: downloadInfo['remote_size_bytes'] ?? 4405655031,
          requiredFiles: ['gemma-3n-E4B-it-int4.task'],
          metadata: {
            'author': 'Google',
            'model_type': 'gemma-3n-e4b-litert',
            'capabilities': [
              'text-generation',
              'vision-understanding',
              'multimodal-chat',
            ],
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
      throw Exception(
        'Model is not available for loading. Current status: ${_state.status}',
      );
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

  /// 对外暴露的多模态聊天接口（文本+可选图片），便于在离线模型页做测试
  Future<String> chat({
    required String prompt,
    File? imageFile,
  }) async {
    // 如果模型未加载，先尝试加载
    if (_state.status == ModelStatus.downloaded) {
      await ensureModelLoaded();
    }
    if (_state.status != ModelStatus.ready) {
      throw Exception('Model is not ready. Current status: ${_state.status}');
    }

    return _inferenceService.chat(prompt: prompt, imageFile: imageFile);
  }

  Future<void> deleteModel() async {
    try {
      _logger.i('Deleting model...');

      // Unload model from memory first
      await _inferenceService.unloadModel();

      // Delete model files
      await _downloader.deleteModel(_modelId);

      _updateState(
        _state.copyWith(
          status: ModelStatus.notDownloaded,
          downloadProgress: 0.0,
          errorMessage: null,
        ),
      );

      _logger.i('Model deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete model: $e');
      _updateState(
        _state.copyWith(
          status: ModelStatus.error,
          errorMessage: 'Failed to delete model: $e',
        ),
      );
    }
  }

  // 生命周期回调：前后台切换时暂停/恢复下载
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state.status == ModelStatus.downloading) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _maybePauseForBackground();
      } else if (state == AppLifecycleState.resumed) {
        // 回到前台自动续传
        scheduleMicrotask(() async {
          try {
            // 若仅 Wi‑Fi 下载，但当前非 Wi‑Fi，直接暂停并提示
            if (await _isWifiRequiredAndNotOnWifi()) {
              _downloadStatus = '等待 Wi‑Fi 连接以继续下载';
              notifyListeners();
              _scheduleRetry();
              return;
            }
            // 低电量自动暂停
            if (await _shouldAutoPauseForBattery()) {
              _downloadStatus = '电量较低，已暂停下载';
              notifyListeners();
              _scheduleRetry();
              return;
            }
            await _downloader.downloadModel(
              modelId: _modelId,
              onProgress: (p) => _updateState(_state.copyWith(downloadProgress: p)),
              onStatusUpdate: (s) {
                _downloadStatus = s;
                notifyListeners();
              },
            );
            await _onDownloadCompleted();
            _resetRetry();
          } catch (e) {
            if (e is! DownloadPausedException) {
              _logger.e('Resume download failed: $e');
              _updateState(
                _state.copyWith(status: ModelStatus.error, errorMessage: '$e'),
              );
            } else {
              _scheduleRetry();
            }
          }
        });
      }
    }
  }

  Future<void> _maybePauseForBackground() async {
    // 读取后台下载策略
    final prefs = await SharedPreferences.getInstance();
    final allowBackground = prefs.getBool(_prefsAllowBackgroundKey) ?? false;
    if (!allowBackground) {
      try {
        _downloader.pause();
        _downloadStatus = '已暂停（前台受限）';
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<bool> _isWifiRequiredAndNotOnWifi() async {
    final prefs = await SharedPreferences.getInstance();
    final wifiOnly = prefs.getBool(_prefsWifiOnlyKey) ?? true;
    if (!wifiOnly) return false;
    final results = await _connectivity.checkConnectivity();
    return !(results.contains(ConnectivityResult.wifi));
  }

  Future<bool> _shouldAutoPauseForBattery() async {
    final prefs = await SharedPreferences.getInstance();
    final autoPause = prefs.getBool(_prefsAutoPauseLowBatteryKey) ?? true;
    if (!autoPause) return false;
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState; // charging/full/discharging
    return level <= 15 && state != BatteryState.charging;
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (_state.status == ModelStatus.downloading) {
      if (!(results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile))) {
        // 无网络，暂停
        try {
          _downloader.pause();
          _downloadStatus = '网络中断，已暂停';
          notifyListeners();
        } catch (_) {}
        _scheduleRetry();
      } else if (results.contains(ConnectivityResult.wifi)) {
        // 网络恢复，尝试重试
        _scheduleRetry(immediate: true);
      }
    }
  }

  void _scheduleRetry({bool immediate = false}) {
    _retryTimer?.cancel();
    final nextDelay = immediate ? Duration.zero : Duration(seconds: math.min(60, (1 << _retryAttempt)));
    _retryAttempt = math.min(_retryAttempt + 1, 6); // 最大 64s 上限，最终 clamp 为 60s
    _retryTimer = Timer(nextDelay, () {
      if (_state.status == ModelStatus.downloading) {
        didChangeAppLifecycleState(AppLifecycleState.resumed);
      }
    });
  }

  void _resetRetry() {
    _retryAttempt = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
  }
  void cancelDownload() {
    if (_state.status == ModelStatus.downloading) {
      // 主动暂停底层下载
      try {
        _downloader.pause();
      } catch (_) {}
      // 重置状态
      _updateState(
        _state.copyWith(
          status: ModelStatus.notDownloaded,
          downloadProgress: 0.0,
          errorMessage: null,
        ),
      );

      _logger.i('Download cancelled by user');
    }
  }

  /// 暂停下载（保持当前进度与状态为 downloading，仅停止网络流）
  void pauseDownload() {
    if (_state.status == ModelStatus.downloading) {
      try {
        _downloader.pause();
        _downloadStatus = '下载已暂停';
        notifyListeners();
        _logger.i('Download paused by user');
      } catch (e) {
        _logger.w('Pause download failed: $e');
      }
    }
  }

  Future<String> getCompatibilityReport() async {
    if (_state.modelInfo == null) {
      await _loadModelInfo();
    }

    if (_state.modelInfo != null) {
      return await _capabilityDetector.getCompatibilityReport(
        _state.modelInfo!,
      );
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
      'model_size_mb': modelSize / (1024 * 1024), // 返回数字而不是字符串
      'model_size_mb_formatted': (modelSize / (1024 * 1024)).toStringAsFixed(1), // 格式化的字符串
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
    return _state.capability?.estimatedInferenceTime ??
        const Duration(seconds: 15);
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
    WidgetsBinding.instance.removeObserver(this);
    _inferenceService.dispose();
    super.dispose();
  }

  // Convenience getters
  bool get isModelDownloaded =>
      _state.status == ModelStatus.downloaded ||
      _state.status == ModelStatus.ready;
  bool get isModelReady => _state.status == ModelStatus.ready;
  bool get isDownloading => _state.status == ModelStatus.downloading;
  bool get hasError => _state.status == ModelStatus.error;
  String? get errorMessage => _state.errorMessage;
  double get downloadProgress => _state.downloadProgress;
  ModelInfo? get modelInfo => _state.modelInfo;
  DeviceCapability? get deviceCapability => _state.capability;

  // 下载策略读取（与设置页使用相同的 key）
  static const _prefsAllowBackgroundKey = 'allow_background_download';
  static const _prefsWifiOnlyKey = 'wifi_only_download';
  static const _prefsAutoPauseLowBatteryKey = 'auto_pause_low_battery';
}
