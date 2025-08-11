
class PlantEncounter {
  final String id;
  final String speciesId;
  final DateTime encounterDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<String> photoPaths;
  final String? notes;
  final RecognitionSource source;
  final RecognitionMethod method;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantEncounter({
    required this.id,
    required this.speciesId,
    required this.encounterDate,
    this.location,
    this.latitude,
    this.longitude,
    required this.photoPaths,
    this.notes,
    required this.source,
    required this.method,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlantEncounter.fromJson(Map<String, dynamic> json) {
    return PlantEncounter(
      id: json['id'] as String,
      speciesId: json['species_id'] as String,
      encounterDate: DateTime.parse(json['encounter_date'] as String),
      location: json['location'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      photoPaths: List<String>.from(json['photo_paths'] as List),
      notes: json['notes'] as String?,
      source: RecognitionSource.values[json['source'] as int],
      method: RecognitionMethod.values[json['method'] as int],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'species_id': speciesId,
      'encounter_date': encounterDate.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'photo_paths': photoPaths,
      'notes': notes,
      'source': source.index,
      'method': method.index,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlantEncounter copyWith({
    String? id,
    String? speciesId,
    DateTime? encounterDate,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? photoPaths,
    String? notes,
    RecognitionSource? source,
    RecognitionMethod? method,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantEncounter(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      encounterDate: encounterDate ?? this.encounterDate,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoPaths: photoPaths ?? this.photoPaths,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum RecognitionSource {
  camera,
  gallery,
}

enum RecognitionMethod {
  local,
  cloud,
  manual,
}