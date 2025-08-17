import 'recognition_result.dart';

class PlantEncounter {
  final String id;
  final String? speciesId;  // 改为可选，支持未识别的植物
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
  
  // 新增字段支持未识别植物
  final String? userDefinedName;  // 用户自定义名称，如"路边的小黄花"
  final bool isIdentified;  // 是否已识别

  PlantEncounter({
    required this.id,
    this.speciesId,  // 改为可选
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
    this.userDefinedName,
    bool? isIdentified,
  }) : isIdentified = isIdentified ?? (speciesId != null);

  factory PlantEncounter.fromJson(Map<String, dynamic> json) {
    return PlantEncounter(
      id: json['id'] as String,
      speciesId: json['species_id'] as String?,  // 改为可选
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
      userDefinedName: json['user_defined_name'] as String?,
      isIdentified: json['is_identified'] as bool? ?? (json['species_id'] != null),
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
      'user_defined_name': userDefinedName,
      'is_identified': isIdentified,
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
    String? userDefinedName,
    bool? isIdentified,
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
      userDefinedName: userDefinedName ?? this.userDefinedName,
      isIdentified: isIdentified ?? this.isIdentified,
    );
  }
}

enum RecognitionSource { camera, gallery }
