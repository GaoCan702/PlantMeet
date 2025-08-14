class PlantSpecies {
  final String id;
  final String scientificName;
  final String commonName;
  final String? description;
  final bool? isToxic;
  final String? toxicityInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantSpecies({
    required this.id,
    required this.scientificName,
    required this.commonName,
    this.description,
    this.isToxic,
    this.toxicityInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      id: json['id'] as String,
      scientificName: json['scientific_name'] as String,
      commonName: json['common_name'] as String,
      description: json['description'] as String?,
      isToxic: json['is_toxic'] as bool?,
      toxicityInfo: json['toxicity_info'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scientific_name': scientificName,
      'common_name': commonName,
      'description': description,
      'is_toxic': isToxic,
      'toxicity_info': toxicityInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlantSpecies copyWith({
    String? id,
    String? scientificName,
    String? commonName,
    String? description,
    bool? isToxic,
    String? toxicityInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantSpecies(
      id: id ?? this.id,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      description: description ?? this.description,
      isToxic: isToxic ?? this.isToxic,
      toxicityInfo: toxicityInfo ?? this.toxicityInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
