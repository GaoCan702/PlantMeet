class AppSettings {
  final String? baseUrl;
  final String? apiKey;
  final bool enableLocation;
  final bool autoSaveLocation;
  final bool saveOriginalPhotos;
  final bool enableLocalRecognition;

  AppSettings({
    this.baseUrl,
    this.apiKey,
    this.enableLocation = true,
    this.autoSaveLocation = true,
    this.saveOriginalPhotos = true,
    this.enableLocalRecognition = true,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      baseUrl: json['base_url'] as String?,
      apiKey: json['api_key'] as String?,
      enableLocation: json['enable_location'] as bool? ?? true,
      autoSaveLocation: json['auto_save_location'] as bool? ?? true,
      saveOriginalPhotos: json['save_original_photos'] as bool? ?? true,
      enableLocalRecognition: json['enable_local_recognition'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_url': baseUrl,
      'api_key': apiKey,
      'enable_location': enableLocation,
      'auto_save_location': autoSaveLocation,
      'save_original_photos': saveOriginalPhotos,
      'enable_local_recognition': enableLocalRecognition,
    };
  }

  AppSettings copyWith({
    String? baseUrl,
    String? apiKey,
    bool? enableLocation,
    bool? autoSaveLocation,
    bool? saveOriginalPhotos,
    bool? enableLocalRecognition,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      enableLocation: enableLocation ?? this.enableLocation,
      autoSaveLocation: autoSaveLocation ?? this.autoSaveLocation,
      saveOriginalPhotos: saveOriginalPhotos ?? this.saveOriginalPhotos,
      enableLocalRecognition: enableLocalRecognition ?? this.enableLocalRecognition,
    );
  }

  bool get isConfigured {
    return baseUrl?.isNotEmpty == true && apiKey?.isNotEmpty == true;
  }
}