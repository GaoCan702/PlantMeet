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
  
  // 智能模型释放机制
  Timer? _modelReleaseTimer;
  Timer? _backgroundReleaseTimer;
  Timer? _memoryPressureTimer;
  DateTime? _lastModelUsage;

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
    } catch (e, stackTrace) {
      String detailedError;
      
      if (e.toString().contains('capability')) {
        detailedError = 'Device capability detection failed: ${e.toString()}. Please check device compatibility.';
      } else if (e.toString().contains('isModelDownloaded')) {
        detailedError = 'Model download check failed: ${e.toString()}. Storage access may be restricted.';
      } else if (e.toString().contains('connectivity')) {
        detailedError = 'Network connectivity check failed: ${e.toString()}. Network services unavailable.';
      } else {
        detailedError = 'Service initialization failed: ${e.toString()}';
      }
      
      _logger.e('Failed to initialize embedded model service: $detailedError');
      _logger.e('Stack trace: $stackTrace');
      _updateState(
        _state.copyWith(
          status: ModelStatus.error,
          errorMessage: detailedError,
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
        String detailedError;
        
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          detailedError = 'Network error during download: ${e.toString()}. Please check internet connection.';
        } else if (e.toString().contains('storage') || e.toString().contains('space')) {
          detailedError = 'Storage error during download: ${e.toString()}. Check available storage space.';
        } else if (e.toString().contains('permission')) {
          detailedError = 'Permission error during download: ${e.toString()}. Storage access denied.';
        } else if (e.toString().contains('timeout')) {
          detailedError = 'Download timeout: ${e.toString()}. Server may be overloaded.';
        } else {
          detailedError = 'Download failed: ${e.toString()}';
        }
        
        _logger.e('Failed to download model: $detailedError');
        _updateState(
          _state.copyWith(
            status: ModelStatus.error,
            errorMessage: detailedError,
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

        // Model downloaded but not loaded - will load on demand
        _logger.i('Model downloaded successfully, ready for on-demand loading');
      } else {
        throw Exception('Downloaded model failed integrity check');
      }
    } catch (e, stackTrace) {
      String detailedError;
      
      if (e.toString().contains('integrity')) {
        detailedError = 'Model integrity check failed: ${e.toString()}. Downloaded file may be corrupted.';
      } else {
        detailedError = 'Download verification failed: ${e.toString()}';
      }
      
      _logger.e('Download completion failed: $detailedError');
      _logger.e('Stack trace: $stackTrace');
      _updateState(
        _state.copyWith(
          status: ModelStatus.error,
          errorMessage: detailedError,
        ),
      );
    }
  }

  /// 公开的加载模型方法
  Future<void> loadModel() async {
    if (_state.status == ModelStatus.ready) {
      _logger.i('Model already loaded and ready');
      return;
    }
    
    if (!isModelDownloaded) {
      _logger.w('Cannot load model: Model not downloaded');
      throw Exception('Model not downloaded');
    }
    
    await _tryLoadModel();
  }

  Future<void> _tryLoadModel() async {
    print('🔄[EmbeddedModelService] === 开始加载模型 ===');
    final loadStopwatch = Stopwatch()..start();
    
    try {
      print('📊[EmbeddedModelService] 更新状态为: loading');
      _updateState(_state.copyWith(status: ModelStatus.loading));

      print('🚀[EmbeddedModelService] 调用推理服务初始化模型...');
      await _inferenceService.initializeModel();

      print('🔍[EmbeddedModelService] 检查模型是否就绪...');
      if (await _inferenceService.isModelReady()) {
        loadStopwatch.stop();
        print('✅[EmbeddedModelService] 模型加载成功！耗时: ${loadStopwatch.elapsedMilliseconds}ms');
        print('📊[EmbeddedModelService] 更新状态为: ready');
        _updateState(_state.copyWith(status: ModelStatus.ready));
        _scheduleModelRelease(); // 启动智能释放调度
        _startMemoryPressureMonitoring(); // 启动内存压力监控
        _logger.i('Model loaded and ready for inference');
        print('🎯[EmbeddedModelService] 模型管理功能已启动');
      } else {
        loadStopwatch.stop();
        print('❌[EmbeddedModelService] 模型初始化后未就绪，耗时: ${loadStopwatch.elapsedMilliseconds}ms');
        throw Exception('Model failed to initialize');
      }
    } catch (e, stackTrace) {
      String detailedError;
      
      if (e.toString().contains('initializeModel')) {
        detailedError = 'Model initialization failed: ${e.toString()}. Check device memory and model compatibility.';
      } else if (e.toString().contains('isModelReady')) {
        detailedError = 'Model readiness check failed: ${e.toString()}. Model loaded but not responding.';
      } else if (e.toString().contains('Model failed to initialize')) {
        detailedError = 'Model failed to initialize: This could be due to insufficient memory, corrupted model file, or device incompatibility.';
      } else {
        detailedError = 'Model loading failed: ${e.toString()}';
      }
      
      _logger.e('Failed to load model: $detailedError');
      _logger.e('Stack trace: $stackTrace');
      _updateState(
        _state.copyWith(
          status: ModelStatus.error,
          errorMessage: detailedError,
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
    print('🚀[EmbeddedModelService] === 开始植物识别 ===');
    print('📂[EmbeddedModelService] 图片文件: ${imageFile.path}');
    print('📊[EmbeddedModelService] 当前模型状态: ${_state.status}');
    print('🔧[EmbeddedModelService] 模型就绪: ${_state.status == ModelStatus.ready}');
    print('⚡[EmbeddedModelService] 推理服务状态: 加载中=${_inferenceService.isModelLoading}, 识别中=${_inferenceService.isRecognitionInProgress}');
    
    // 如果模型未加载，先尝试加载
    if (_state.status == ModelStatus.downloaded) {
      print('🔄[EmbeddedModelService] 模型已下载但未加载，正在自动加载...');
      await ensureModelLoaded();
    }

    if (_state.status != ModelStatus.ready) {
      final errorMsg = 'Model is not ready. Current status: ${_state.status}';
      print('❌[EmbeddedModelService] $errorMsg');
      throw Exception(errorMsg);
    }

    print('✅[EmbeddedModelService] 模型已就绪，开始调用推理服务...');
    final stopwatch = Stopwatch()..start();
    
    try {
      _recordModelUsage(); // 记录模型使用
      notifyListeners(); // 通知UI状态变化
      print('🔧[EmbeddedModelService] 调用 GemmaInferenceService.recognizePlant()...');
      final result = await _inferenceService.recognizePlant(imageFile);
      stopwatch.stop();
      print('⏱️[EmbeddedModelService] 推理耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('📋[EmbeddedModelService] 识别结果数量: ${result.length}');
      
      for (int i = 0; i < result.length; i++) {
        print('🌿[EmbeddedModelService] 结果 ${i + 1}: ${result[i].name} (置信度: ${result[i].confidence})');
      }
      
      notifyListeners(); // 识别完成后通知UI
      print('✅[EmbeddedModelService] 植物识别完成');
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      print('💥[EmbeddedModelService] 植物识别失败: $e');
      print('📍[EmbeddedModelService] 堆栈跟踪: $stackTrace');
      _logger.e('Plant recognition failed: $e');
      notifyListeners(); // 出错后也要通知UI
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
      throw Exception('模型未就绪，当前状态: ${_getStatusDescription(_state.status)}。请返回模型管理页面检查模型状态。');
    }

    _recordModelUsage(); // 记录模型使用
    return _inferenceService.chat(prompt: prompt, imageFile: imageFile);
  }

  /// 流式聊天方法 - 支持实时响应
  Stream<String> chatStream({
    required String prompt,
    File? imageFile,
  }) async* {
    try {
      // 如果模型未加载，先尝试加载
      if (_state.status == ModelStatus.downloaded) {
        yield '🔄 正在初始化模型，请稍候...';
        await ensureModelLoaded();
        yield '\n\n';
      }
      
      if (_state.status != ModelStatus.ready) {
        throw Exception('模型未就绪，当前状态: ${_getStatusDescription(_state.status)}。请返回模型管理页面检查模型状态。');
      }

      _recordModelUsage(); // 记录模型使用
      yield* _inferenceService.chatStream(prompt: prompt, imageFile: imageFile);
    } catch (e) {
      // 如果是模型初始化相关错误，提供更友好的提示
      if (e.toString().contains('initializeModel')) {
        throw Exception('模型初始化失败。这可能是由于设备内存不足或模型文件损坏。建议重新下载模型或重启应用。');
      } else if (e.toString().contains('Model file not found')) {
        throw Exception('模型文件丢失。请返回模型管理页面重新下载模型。');
      }
      rethrow;
    }
  }
  
  String _getStatusDescription(ModelStatus status) {
    switch (status) {
      case ModelStatus.notDownloaded:
        return '未下载';
      case ModelStatus.downloading:
        return '下载中';
      case ModelStatus.downloaded:
        return '已下载，使用时自动加载';
      case ModelStatus.loading:
        return '加载中';
      case ModelStatus.ready:
        return '就绪';
      case ModelStatus.error:
        return '错误';
      case ModelStatus.updating:
        return '更新中';
    }
  }

  Future<void> deleteModel() async {
    try {
      _logger.i('Deleting model...');
      
      // Cancel any scheduled model release
      _cancelModelRelease();
      _stopMemoryPressureMonitoring();

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

  /// 清理不完整的下载文件，重新开始下载
  Future<void> clearIncompleteDownloadAndRestart() async {
    try {
      _logger.i('Clearing incomplete download and restarting...');
      
      // 清理不完整的下载
      await _downloader.clearIncompleteDownload(_modelId);
      
      // 重置状态
      _updateState(
        _state.copyWith(
          status: ModelStatus.notDownloaded,
          downloadProgress: 0.0,
          errorMessage: null,
        ),
      );
      
      _downloadStatus = '';
      notifyListeners();
      
      _logger.i('Incomplete download cleared, ready to restart');
    } catch (e) {
      _logger.e('Failed to clear incomplete download: $e');
    }
  }

  // 生命周期回调：前后台切换时暂停/恢复下载，并优化内存使用
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 处理下载相关的生命周期
    if (_state.status == ModelStatus.downloading) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _maybePauseForBackground();
      } else if (state == AppLifecycleState.resumed) {
        // 回到前台尝试续传
        _tryResumeDownload();
      }
    }
    
    // 处理模型内存释放相关的生命周期
    _handleModelMemoryLifecycle(state);
  }
  
  /// 处理模型内存管理的生命周期
  void _handleModelMemoryLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 延迟释放模型（给用户30秒返回前台的机会）
        _scheduleBackgroundModelRelease();
        break;
      case AppLifecycleState.resumed:
        // 取消后台释放调度
        _cancelBackgroundModelRelease();
        break;
      case AppLifecycleState.detached:
        // 应用被终止，立即释放模型
        _releaseModelImmediately();
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏但可能快速恢复，稍作延迟
        _scheduleBackgroundModelRelease();
        break;
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

  /// 尝试恢复下载（从前台/网络变化等触发）
  void _tryResumeDownload() {
    if (_state.status != ModelStatus.downloading) return;
    
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
        
        _logger.i('Attempting to resume download...');
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
        if (e is DownloadPausedException) {
          _logger.i('Download paused during resume attempt');
          _downloadStatus = '下载已暂停';
          notifyListeners();
          _scheduleRetry();
        } else {
          _logger.w('Resume download failed: $e');
          // 不立即设置为错误状态，而是调度重试
          _downloadStatus = '续传失败，将重试: ${e.toString().split('\n').first}';
          notifyListeners();
          _scheduleRetry();
        }
      }
    });
  }

  void _scheduleRetry({bool immediate = false}) {
    _retryTimer?.cancel();
    final nextDelay = immediate ? Duration.zero : Duration(seconds: math.min(60, (1 << _retryAttempt)));
    _retryAttempt = math.min(_retryAttempt + 1, 6); // 最大 64s 上限，最终 clamp 为 60s
    _retryTimer = Timer(nextDelay, () {
      if (_state.status == ModelStatus.downloading) {
        _tryResumeDownload();
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

  /// 恢复下载（用户主动点击继续按钮）
  Future<void> resumeDownload() async {
    if (_state.status == ModelStatus.downloading) {
      _logger.i('User requested to resume download');
      _downloadStatus = '正在恢复下载...';
      notifyListeners();
      
      // 直接调用恢复下载逻辑
      _tryResumeDownload();
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

  /// 获取详细的资源状态信息（用于UI显示）
  Map<String, dynamic> getResourceStatus() {
    final config = _getDeviceConfig();
    final now = DateTime.now();
    
    // 计算距离上次使用的时间
    Duration? timeSinceLastUse;
    if (_lastModelUsage != null) {
      timeSinceLastUse = now.difference(_lastModelUsage!);
    }
    
    // 计算下次自动释放的时间
    Duration? timeUntilAutoRelease;
    if (_state.status == ModelStatus.ready && _lastModelUsage != null) {
      final autoReleaseTime = _lastModelUsage!.add(config.idleReleaseDelay);
      if (autoReleaseTime.isAfter(now)) {
        timeUntilAutoRelease = autoReleaseTime.difference(now);
      }
    }
    
    return {
      'device_tier': config.deviceTier,
      'model_status': _getStatusDescription(_state.status),
      'model_loaded': _state.status == ModelStatus.ready,
      'last_usage': _lastModelUsage?.toIso8601String(),
      'time_since_last_use_minutes': timeSinceLastUse?.inMinutes,
      'time_until_auto_release_minutes': timeUntilAutoRelease?.inMinutes,
      'auto_release_enabled': _modelReleaseTimer != null,
      'memory_monitoring_enabled': _memoryPressureTimer != null,
      'background_release_scheduled': _backgroundReleaseTimer != null,
      'optimization_config': {
        'idle_release_delay_minutes': config.idleReleaseDelay.inMinutes,
        'memory_check_interval_seconds': config.memoryCheckInterval.inSeconds,
        'memory_pressure_release_enabled': config.enableMemoryPressureRelease,
        'memory_pressure_threshold_minutes': config.memoryPressureThreshold.inMinutes,
      },
      'memory_info': {
        'device_ram_gb': (_state.capability?.ramSizeBytes ?? 0) / (1024 * 1024 * 1024),
        'ram_size_bytes': _state.capability?.ramSizeBytes ?? 0,
      },
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
    _modelReleaseTimer?.cancel();
    _backgroundReleaseTimer?.cancel();
    _memoryPressureTimer?.cancel();
    _retryTimer?.cancel();
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
  bool get isRecognitionInProgress => _inferenceService.isRecognitionInProgress;
  bool get isModelLoading => _inferenceService.isModelLoading;
  double get downloadProgress => _state.downloadProgress;
  
  /// 判断下载是否处于暂停状态
  bool get isDownloadPaused => isDownloading && (
    _downloadStatus.contains('已暂停') || 
    _downloadStatus.contains('等待') ||
    _downloadStatus.contains('电量较低')
  );
  
  /// 判断下载是否正在进行中（非暂停状态）
  bool get isActivelyDownloading => isDownloading && !isDownloadPaused;
  ModelInfo? get modelInfo => _state.modelInfo;
  DeviceCapability? get deviceCapability => _state.capability;

  // 智能模型释放机制
  
  /// 记录模型使用并重置释放计时器
  void _recordModelUsage() {
    _lastModelUsage = DateTime.now();
    _scheduleModelRelease();
  }
  
  /// 根据设备性能获取释放延迟时间
  Duration _getModelReleaseDelay() {
    final config = _getDeviceConfig();
    return config.idleReleaseDelay;
  }
  
  /// 获取设备分级配置
  DeviceConfig _getDeviceConfig() {
    final ramSize = _state.capability?.ramSizeBytes ?? (4 * 1024 * 1024 * 1024);
    
    if (ramSize >= 8 * 1024 * 1024 * 1024) {
      // 高端设备 (8GB+)
      return DeviceConfig.highEnd();
    } else if (ramSize >= 6 * 1024 * 1024 * 1024) {
      // 中端设备 (6-8GB)
      return DeviceConfig.midRange();
    } else {
      // 低端设备 (4-6GB)
      return DeviceConfig.lowEnd();
    }
  }
  
  /// 调度模型自动释放
  void _scheduleModelRelease() {
    _modelReleaseTimer?.cancel();
    
    // 只有在模型已加载时才调度释放
    if (_state.status != ModelStatus.ready) return;
    
    final delay = _getModelReleaseDelay();
    _modelReleaseTimer = Timer(delay, () async {
      try {
        _logger.i('Auto-releasing model after ${delay.inMinutes} minutes of inactivity');
        await _inferenceService.unloadModel();
        
        _updateState(_state.copyWith(
          status: ModelStatus.downloaded,
        ));
        
        _logger.i('Model auto-released successfully');
      } catch (e) {
        _logger.w('Failed to auto-release model: $e');
      }
    });
    
    _logger.d('Scheduled model release in ${delay.inMinutes} minutes');
  }
  
  /// 取消模型释放调度
  void _cancelModelRelease() {
    _modelReleaseTimer?.cancel();
    _logger.d('Cancelled model auto-release schedule');
  }

  // 后台模型释放机制
  
  /// 调度后台模型释放（30秒后释放）
  void _scheduleBackgroundModelRelease() {
    // 如果模型没有加载，无需释放
    if (_state.status != ModelStatus.ready) return;
    
    _backgroundReleaseTimer?.cancel();
    _backgroundReleaseTimer = Timer(const Duration(seconds: 30), () async {
      try {
        _logger.i('Releasing model due to background state');
        await _inferenceService.unloadModel();
        
        _updateState(_state.copyWith(
          status: ModelStatus.downloaded,
        ));
        
        _logger.i('Model released successfully for background optimization');
      } catch (e) {
        _logger.w('Failed to release model in background: $e');
      }
    });
    
    _logger.d('Scheduled background model release in 30 seconds');
  }
  
  /// 取消后台模型释放调度
  void _cancelBackgroundModelRelease() {
    _backgroundReleaseTimer?.cancel();
    _logger.d('Cancelled background model release schedule');
  }
  
  /// 立即释放模型（用于应用终止）
  void _releaseModelImmediately() {
    if (_state.status != ModelStatus.ready) return;
    
    // 同步调用，不使用async
    try {
      _logger.w('Immediately releasing model due to app termination');
      _inferenceService.unloadModel().catchError((e) {
        _logger.e('Failed to immediately release model: $e');
      });
      
      // 直接更新状态，不等待unload完成
      _updateState(_state.copyWith(
        status: ModelStatus.downloaded,
      ));
    } catch (e) {
      _logger.e('Error during immediate model release: $e');
    }
  }

  // 内存压力感知释放机制
  
  /// 启动内存压力监控
  void _startMemoryPressureMonitoring() {
    _stopMemoryPressureMonitoring(); // 先停止之前的监控
    
    final config = _getDeviceConfig();
    
    // 根据设备性能调整监控频率
    _memoryPressureTimer = Timer.periodic(config.memoryCheckInterval, (_) async {
      await _checkMemoryPressure();
    });
    
    _logger.d('Started memory pressure monitoring with ${config.memoryCheckInterval.inSeconds}s interval for ${config.deviceTier} device');
  }
  
  /// 停止内存压力监控
  void _stopMemoryPressureMonitoring() {
    _memoryPressureTimer?.cancel();
    _memoryPressureTimer = null;
    _logger.d('Stopped memory pressure monitoring');
  }
  
  /// 检查内存压力并决定是否释放模型
  Future<void> _checkMemoryPressure() async {
    if (_state.status != ModelStatus.ready) return;
    
    try {
      final config = _getDeviceConfig();
      final now = DateTime.now();
      final lastUsage = _lastModelUsage;
      
      // 检查是否应该基于设备配置进行内存压力释放
      if (config.enableMemoryPressureRelease && lastUsage != null) {
        final inactiveTime = now.difference(lastUsage);
        
        if (inactiveTime >= config.memoryPressureThreshold) {
          _logger.i('Memory pressure release triggered for ${config.deviceTier} device after ${inactiveTime.inMinutes} minutes of inactivity');
          await _releaseModelDueToMemoryPressure();
        }
      }
      
    } catch (e) {
      _logger.w('Memory pressure check failed: $e');
    }
  }
  
  /// 由于内存压力释放模型
  Future<void> _releaseModelDueToMemoryPressure() async {
    try {
      _logger.i('Releasing model due to memory pressure');
      
      // 停止所有其他释放计时器，避免重复释放
      _cancelModelRelease();
      _cancelBackgroundModelRelease();
      
      await _inferenceService.unloadModel();
      
      _updateState(_state.copyWith(
        status: ModelStatus.downloaded,
      ));
      
      _logger.i('Model released successfully due to memory pressure');
      
      // 停止内存压力监控，直到模型下次被加载
      _stopMemoryPressureMonitoring();
      
    } catch (e) {
      _logger.w('Failed to release model due to memory pressure: $e');
    }
  }

  // 下载策略读取（与设置页使用相同的 key）
  static const _prefsAllowBackgroundKey = 'allow_background_download';
  static const _prefsWifiOnlyKey = 'wifi_only_download';
  static const _prefsAutoPauseLowBatteryKey = 'auto_pause_low_battery';
}

/// 设备分级配置类
class DeviceConfig {
  final String deviceTier;
  final Duration idleReleaseDelay;
  final Duration memoryCheckInterval;
  final bool enableMemoryPressureRelease;
  final Duration memoryPressureThreshold;
  
  const DeviceConfig({
    required this.deviceTier,
    required this.idleReleaseDelay,
    required this.memoryCheckInterval,
    required this.enableMemoryPressureRelease,
    required this.memoryPressureThreshold,
  });
  
  /// 高端设备配置 (8GB+)
  factory DeviceConfig.highEnd() => const DeviceConfig(
    deviceTier: 'high-end',
    idleReleaseDelay: Duration(minutes: 5),
    memoryCheckInterval: Duration(minutes: 1),
    enableMemoryPressureRelease: false, // 高端设备不需要激进的内存管理
    memoryPressureThreshold: Duration(minutes: 10),
  );
  
  /// 中端设备配置 (6-8GB)
  factory DeviceConfig.midRange() => const DeviceConfig(
    deviceTier: 'mid-range',
    idleReleaseDelay: Duration(minutes: 3),
    memoryCheckInterval: Duration(seconds: 45),
    enableMemoryPressureRelease: true,
    memoryPressureThreshold: Duration(minutes: 3),
  );
  
  /// 低端设备配置 (4-6GB)
  factory DeviceConfig.lowEnd() => const DeviceConfig(
    deviceTier: 'low-end',
    idleReleaseDelay: Duration(minutes: 1),
    memoryCheckInterval: Duration(seconds: 30),
    enableMemoryPressureRelease: true,
    memoryPressureThreshold: Duration(minutes: 1), // 更激进的内存管理
  );
}
