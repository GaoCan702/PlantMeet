enum ModelStatus {
  notDownloaded,
  downloading,
  downloaded,
  loading,
  ready,
  error,
  updating,
}

enum ModelSource {
  github,      // 新增：GitHub 开源模型
  modelScope,
  huggingFace,
  kaggle,
  google,
  direct,
}

enum InferenceBackend {
  cpu,
  gpu,
  auto,
}

class ModelInfo {
  final String id;
  final String name;
  final String version;
  final int sizeBytes;
  final List<String> requiredFiles;
  final String description;
  final Map<String, dynamic> metadata;

  ModelInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.sizeBytes,
    required this.requiredFiles,
    required this.description,
    this.metadata = const {},
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      sizeBytes: json['size_bytes'] as int,
      requiredFiles: List<String>.from(json['required_files'] as List),
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'size_bytes': sizeBytes,
      'required_files': requiredFiles,
      'description': description,
      'metadata': metadata,
    };
  }
}

class ModelFile {
  final String name;
  final int size;
  final String? checksum;
  final String downloadUrl;

  ModelFile({
    required this.name,
    required this.size,
    this.checksum,
    required this.downloadUrl,
  });

  factory ModelFile.fromJson(Map<String, dynamic> json) {
    return ModelFile(
      name: json['name'] as String,
      size: json['size'] as int,
      checksum: json['checksum'] as String?,
      downloadUrl: json['download_url'] as String,
    );
  }
}

class ModelSourceInfo {
  final String baseUrl;
  final String modelId;
  final String? downloadUrl;
  final int priority;
  final List<String> regionOptimized;
  final String? testUrl;

  ModelSourceInfo({
    required this.baseUrl,
    required this.modelId,
    this.downloadUrl,
    required this.priority,
    required this.regionOptimized,
    this.testUrl,
  });
}

class DeviceCapability {
  final int ramSizeBytes;
  final int availableStorageBytes;
  final bool isHighEnd;
  final InferenceBackend recommendedBackend;
  final Duration estimatedInferenceTime;
  final Map<String, dynamic> additionalInfo;

  DeviceCapability({
    required this.ramSizeBytes,
    required this.availableStorageBytes,
    required this.isHighEnd,
    required this.recommendedBackend,
    required this.estimatedInferenceTime,
    this.additionalInfo = const {},
  });
}

class EmbeddedModelState {
  final ModelStatus status;
  final double downloadProgress;
  final String? errorMessage;
  final ModelInfo? modelInfo;
  final DeviceCapability? capability;
  final ModelSource? currentSource;
  final DateTime? lastUpdated;

  EmbeddedModelState({
    required this.status,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.modelInfo,
    this.capability,
    this.currentSource,
    this.lastUpdated,
  });

  EmbeddedModelState copyWith({
    ModelStatus? status,
    double? downloadProgress,
    String? errorMessage,
    ModelInfo? modelInfo,
    DeviceCapability? capability,
    ModelSource? currentSource,
    DateTime? lastUpdated,
  }) {
    return EmbeddedModelState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      modelInfo: modelInfo ?? this.modelInfo,
      capability: capability ?? this.capability,
      currentSource: currentSource ?? this.currentSource,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double speed;
  final Duration estimatedTimeRemaining;
  final ModelSource source;

  DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
    required this.estimatedTimeRemaining,
    required this.source,
  });

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}

class DownloadException implements Exception {
  final String message;
  final ModelSource source;
  final Exception? originalException;

  DownloadException(this.message, this.source, [this.originalException]);

  @override
  String toString() => 'DownloadException: $message (source: $source)';
}