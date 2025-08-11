import 'plant_encounter.dart';

class RecognitionResult {
  final String speciesId;
  final String scientificName;
  final String commonName;
  final double confidence;
  final String? description;
  final bool? isToxic;
  final String? toxicityInfo;

  RecognitionResult({
    required this.speciesId,
    required this.scientificName,
    required this.commonName,
    required this.confidence,
    this.description,
    this.isToxic,
    this.toxicityInfo,
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(
      speciesId: json['species_id'] as String,
      scientificName: json['scientific_name'] as String,
      commonName: json['common_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String?,
      isToxic: json['is_toxic'] as bool?,
      toxicityInfo: json['toxicity_info'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species_id': speciesId,
      'scientific_name': scientificName,
      'common_name': commonName,
      'confidence': confidence,
      'description': description,
      'is_toxic': isToxic,
      'toxicity_info': toxicityInfo,
    };
  }
}

class RecognitionResponse {
  final List<RecognitionResult> results;
  final String? error;
  final bool success;
  final RecognitionMethod method;

  RecognitionResponse({
    required this.results,
    this.error,
    required this.success,
    required this.method,
  });

  factory RecognitionResponse.success({
    required List<RecognitionResult> results,
    required RecognitionMethod method,
  }) {
    return RecognitionResponse(
      results: results,
      success: true,
      method: method,
    );
  }

  factory RecognitionResponse.error({
    required String error,
    required RecognitionMethod method,
  }) {
    return RecognitionResponse(
      results: [],
      error: error,
      success: false,
      method: method,
    );
  }

  List<RecognitionResult> get topResults {
    final sorted = List<RecognitionResult>.from(results)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted.take(3).toList();
  }
}