import 'recognition_result.dart';

class AppSettings {
  final String? baseUrl;
  final String? apiKey;
  final bool enableLocation;
  final bool autoSaveLocation;
  final bool saveOriginalPhotos;
  final bool enableLocalRecognition;
  final RecognitionMethod preferredRecognitionMethod;
  final List<RecognitionMethod> recognitionMethodFallbackOrder;
  final String? huggingfaceToken;

  AppSettings({
    this.baseUrl,
    this.apiKey,
    this.enableLocation = true,
    this.autoSaveLocation = true,
    this.saveOriginalPhotos = true,
    this.enableLocalRecognition = true,
    this.preferredRecognitionMethod = RecognitionMethod.hybrid,
    this.recognitionMethodFallbackOrder = const [
      RecognitionMethod.embedded,
      RecognitionMethod.local,
      RecognitionMethod.cloud,
    ],
    this.huggingfaceToken,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      baseUrl: json['base_url'] as String?,
      apiKey: json['api_key'] as String?,
      enableLocation: json['enable_location'] as bool? ?? true,
      autoSaveLocation: json['auto_save_location'] as bool? ?? true,
      saveOriginalPhotos: json['save_original_photos'] as bool? ?? true,
      enableLocalRecognition: json['enable_local_recognition'] as bool? ?? true,
      preferredRecognitionMethod: RecognitionMethod.values.firstWhere(
        (e) => e.name == json['preferred_recognition_method'],
        orElse: () => RecognitionMethod.hybrid,
      ),
      recognitionMethodFallbackOrder: json['recognition_method_fallback_order'] != null
          ? (json['recognition_method_fallback_order'] as List)
              .map((e) => RecognitionMethod.values.firstWhere(
                (method) => method.name == e,
                orElse: () => RecognitionMethod.hybrid,
              ))
              .toList()
          : const [
              RecognitionMethod.embedded,
              RecognitionMethod.local,
              RecognitionMethod.cloud,
            ],
      huggingfaceToken: json['huggingface_token'] as String?,
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
      'preferred_recognition_method': preferredRecognitionMethod.name,
      'recognition_method_fallback_order': recognitionMethodFallbackOrder.map((e) => e.name).toList(),
      'huggingface_token': huggingfaceToken,
    };
  }

  AppSettings copyWith({
    String? baseUrl,
    String? apiKey,
    bool? enableLocation,
    bool? autoSaveLocation,
    bool? saveOriginalPhotos,
    bool? enableLocalRecognition,
    RecognitionMethod? preferredRecognitionMethod,
    List<RecognitionMethod>? recognitionMethodFallbackOrder,
    String? huggingfaceToken,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      enableLocation: enableLocation ?? this.enableLocation,
      autoSaveLocation: autoSaveLocation ?? this.autoSaveLocation,
      saveOriginalPhotos: saveOriginalPhotos ?? this.saveOriginalPhotos,
      enableLocalRecognition: enableLocalRecognition ?? this.enableLocalRecognition,
      preferredRecognitionMethod: preferredRecognitionMethod ?? this.preferredRecognitionMethod,
      recognitionMethodFallbackOrder: recognitionMethodFallbackOrder ?? this.recognitionMethodFallbackOrder,
      huggingfaceToken: huggingfaceToken ?? this.huggingfaceToken,
    );
  }

  bool get isConfigured {
    return baseUrl?.isNotEmpty == true && apiKey?.isNotEmpty == true;
  }

  bool get isHuggingFaceConfigured {
    return huggingfaceToken?.isNotEmpty == true;
  }
}