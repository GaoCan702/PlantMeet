import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/embedded_model.dart';

class DeviceCapabilityDetector {
  static const int _minimumRamBytes = 4 * 1024 * 1024 * 1024; // 4GB
  static const int _recommendedRamBytes = 6 * 1024 * 1024 * 1024; // 6GB
  static const int _minimumStorageBytes = 4 * 1024 * 1024 * 1024; // 4GB

  Future<DeviceCapability> detect() async {
    final deviceInfo = DeviceInfoPlugin();
    final ramSize = await _getAvailableRAM(deviceInfo);
    final storageSpace = await _getAvailableStorage();
    final cpuInfo = await _getCPUInfo(deviceInfo);

    final isHighEnd = ramSize >= _recommendedRamBytes;
    final recommendedBackend = _determineRecommendedBackend(ramSize, cpuInfo);
    final estimatedTime = _estimateInferenceTime(
      ramSize,
      cpuInfo,
      recommendedBackend,
    );

    return DeviceCapability(
      ramSizeBytes: ramSize,
      availableStorageBytes: storageSpace,
      isHighEnd: isHighEnd,
      recommendedBackend: recommendedBackend,
      estimatedInferenceTime: estimatedTime,
      additionalInfo: {
        'cpu_info': cpuInfo,
        'meets_minimum_requirements': _meetsMinimumRequirements(
          ramSize,
          storageSpace,
        ),
        'platform': Platform.operatingSystem,
      },
    );
  }

  Future<int> _getAvailableRAM(DeviceInfoPlugin deviceInfo) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Android doesn't directly expose RAM size, estimate based on device characteristics
        final sdkInt = androidInfo.version.sdkInt;
        final brand = androidInfo.brand.toLowerCase();

        // Rough estimation based on Android SDK level and brand
        if (sdkInt >= 30) {
          // Android 11+
          if (_isHighEndBrand(brand)) {
            return 8 * 1024 * 1024 * 1024; // 8GB
          } else {
            return 6 * 1024 * 1024 * 1024; // 6GB
          }
        } else if (sdkInt >= 28) {
          // Android 9+
          return 4 * 1024 * 1024 * 1024; // 4GB
        } else {
          return 3 * 1024 * 1024 * 1024; // 3GB
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final model = iosInfo.model.toLowerCase();

        // iOS RAM estimation based on device model
        if (model.contains('iphone')) {
          if (model.contains('15') || model.contains('14')) {
            return 6 * 1024 * 1024 * 1024; // 6GB for iPhone 14/15
          } else if (model.contains('13') || model.contains('12')) {
            return 4 * 1024 * 1024 * 1024; // 4GB for iPhone 12/13
          } else {
            return 3 * 1024 * 1024 * 1024; // 3GB for older iPhones
          }
        } else {
          return 8 * 1024 * 1024 * 1024; // iPad typically has more RAM
        }
      }
    } catch (e) {
      // Fallback estimation
      return 4 * 1024 * 1024 * 1024; // 4GB default
    }

    return 4 * 1024 * 1024 * 1024; // 4GB default
  }

  Future<int> _getAvailableStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();

      // This is a rough estimation - actual implementation would need platform-specific code
      // For now, assume we have at least 10GB available if the directory exists
      return 10 * 1024 * 1024 * 1024; // 10GB
    } catch (e) {
      return 5 * 1024 * 1024 * 1024; // 5GB fallback
    }
  }

  Future<Map<String, dynamic>> _getCPUInfo(DeviceInfoPlugin deviceInfo) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'architecture': androidInfo.supportedAbis.first,
          'supported_abis': androidInfo.supportedAbis,
          'hardware': androidInfo.hardware,
          'model': androidInfo.model,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'architecture': 'arm64',
          'model': iosInfo.model,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      // Fallback
    }

    return {'architecture': 'unknown', 'platform': Platform.operatingSystem};
  }

  InferenceBackend _determineRecommendedBackend(
    int ramSize,
    Map<String, dynamic> cpuInfo,
  ) {
    // For mobile devices, start with CPU backend for stability
    // GPU backend can be enabled later based on performance testing
    if (ramSize >= _recommendedRamBytes) {
      return InferenceBackend.auto; // Let the system decide
    } else if (ramSize >= _minimumRamBytes) {
      return InferenceBackend.cpu;
    } else {
      return InferenceBackend.cpu; // Conservative choice for low-end devices
    }
  }

  Duration _estimateInferenceTime(
    int ramSize,
    Map<String, dynamic> cpuInfo,
    InferenceBackend backend,
  ) {
    // Rough estimation based on device capabilities
    int baseTimeSeconds = 15; // Base time for 4B model inference

    if (ramSize >= 8 * 1024 * 1024 * 1024) {
      // 8GB+
      baseTimeSeconds = 8;
    } else if (ramSize >= 6 * 1024 * 1024 * 1024) {
      // 6GB+
      baseTimeSeconds = 12;
    } else if (ramSize >= 4 * 1024 * 1024 * 1024) {
      // 4GB+
      baseTimeSeconds = 15;
    } else {
      baseTimeSeconds = 25; // Low-end devices
    }

    // Adjust for backend
    if (backend == InferenceBackend.gpu) {
      baseTimeSeconds = (baseTimeSeconds * 0.7)
          .round(); // GPU is typically faster
    }

    return Duration(seconds: baseTimeSeconds);
  }

  bool _meetsMinimumRequirements(int ramSize, int storageSpace) {
    return ramSize >= _minimumRamBytes && storageSpace >= _minimumStorageBytes;
  }

  bool _isHighEndBrand(String brand) {
    const highEndBrands = [
      'samsung',
      'google',
      'oneplus',
      'xiaomi',
      'oppo',
      'vivo',
    ];
    return highEndBrands.any((b) => brand.contains(b));
  }

  Future<bool> isModelSupported(ModelInfo modelInfo) async {
    final capability = await detect();

    // Check minimum requirements
    if (!_meetsMinimumRequirements(
      capability.ramSizeBytes,
      capability.availableStorageBytes,
    )) {
      return false;
    }

    // Check if we have enough storage for the model
    if (capability.availableStorageBytes < modelInfo.sizeBytes * 2) {
      // 2x for safety
      return false;
    }

    return true;
  }

  Future<String> getCompatibilityReport(ModelInfo modelInfo) async {
    final capability = await detect();
    final supported = await isModelSupported(modelInfo);

    final ramGB = (capability.ramSizeBytes / (1024 * 1024 * 1024))
        .toStringAsFixed(1);
    final storageGB = (capability.availableStorageBytes / (1024 * 1024 * 1024))
        .toStringAsFixed(1);
    final modelSizeGB = (modelInfo.sizeBytes / (1024 * 1024 * 1024))
        .toStringAsFixed(1);

    if (supported) {
      return '''设备兼容性: ✅ 支持
内存: ${ramGB}GB (推荐: 4GB+)
存储: ${storageGB}GB 可用 (需要: ${modelSizeGB}GB)
推荐后端: ${_backendDisplayName(capability.recommendedBackend)}
预计推理时间: ${capability.estimatedInferenceTime.inSeconds}秒''';
    } else {
      return '''设备兼容性: ❌ 不支持
内存: ${ramGB}GB (最低需要: 4GB)
存储: ${storageGB}GB 可用 (需要: ${modelSizeGB}GB)
建议: 请释放更多存储空间或使用云端识别''';
    }
  }

  String _backendDisplayName(InferenceBackend backend) {
    switch (backend) {
      case InferenceBackend.cpu:
        return 'CPU';
      case InferenceBackend.gpu:
        return 'GPU';
      case InferenceBackend.auto:
        return '自动';
    }
  }
}
