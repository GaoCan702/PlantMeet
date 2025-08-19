// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlantSpeciesTableTable extends PlantSpeciesTable
    with TableInfo<$PlantSpeciesTableTable, PlantSpeciesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantSpeciesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scientificNameMeta = const VerificationMeta(
    'scientificName',
  );
  @override
  late final GeneratedColumn<String> scientificName = GeneratedColumn<String>(
    'scientific_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commonNameMeta = const VerificationMeta(
    'commonName',
  );
  @override
  late final GeneratedColumn<String> commonName = GeneratedColumn<String>(
    'common_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isToxicMeta = const VerificationMeta(
    'isToxic',
  );
  @override
  late final GeneratedColumn<bool> isToxic = GeneratedColumn<bool>(
    'is_toxic',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_toxic" IN (0, 1))',
    ),
  );
  static const VerificationMeta _toxicityInfoMeta = const VerificationMeta(
    'toxicityInfo',
  );
  @override
  late final GeneratedColumn<String> toxicityInfo = GeneratedColumn<String>(
    'toxicity_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scientificName,
    commonName,
    description,
    isToxic,
    toxicityInfo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plant_species_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlantSpeciesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scientific_name')) {
      context.handle(
        _scientificNameMeta,
        scientificName.isAcceptableOrUnknown(
          data['scientific_name']!,
          _scientificNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scientificNameMeta);
    }
    if (data.containsKey('common_name')) {
      context.handle(
        _commonNameMeta,
        commonName.isAcceptableOrUnknown(data['common_name']!, _commonNameMeta),
      );
    } else if (isInserting) {
      context.missing(_commonNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_toxic')) {
      context.handle(
        _isToxicMeta,
        isToxic.isAcceptableOrUnknown(data['is_toxic']!, _isToxicMeta),
      );
    }
    if (data.containsKey('toxicity_info')) {
      context.handle(
        _toxicityInfoMeta,
        toxicityInfo.isAcceptableOrUnknown(
          data['toxicity_info']!,
          _toxicityInfoMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlantSpeciesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlantSpeciesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scientificName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scientific_name'],
      )!,
      commonName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}common_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isToxic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_toxic'],
      ),
      toxicityInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}toxicity_info'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlantSpeciesTableTable createAlias(String alias) {
    return $PlantSpeciesTableTable(attachedDatabase, alias);
  }
}

class PlantSpeciesTableData extends DataClass
    implements Insertable<PlantSpeciesTableData> {
  final String id;
  final String scientificName;
  final String commonName;
  final String? description;
  final bool? isToxic;
  final String? toxicityInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlantSpeciesTableData({
    required this.id,
    required this.scientificName,
    required this.commonName,
    this.description,
    this.isToxic,
    this.toxicityInfo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scientific_name'] = Variable<String>(scientificName);
    map['common_name'] = Variable<String>(commonName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || isToxic != null) {
      map['is_toxic'] = Variable<bool>(isToxic);
    }
    if (!nullToAbsent || toxicityInfo != null) {
      map['toxicity_info'] = Variable<String>(toxicityInfo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlantSpeciesTableCompanion toCompanion(bool nullToAbsent) {
    return PlantSpeciesTableCompanion(
      id: Value(id),
      scientificName: Value(scientificName),
      commonName: Value(commonName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isToxic: isToxic == null && nullToAbsent
          ? const Value.absent()
          : Value(isToxic),
      toxicityInfo: toxicityInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(toxicityInfo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlantSpeciesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlantSpeciesTableData(
      id: serializer.fromJson<String>(json['id']),
      scientificName: serializer.fromJson<String>(json['scientificName']),
      commonName: serializer.fromJson<String>(json['commonName']),
      description: serializer.fromJson<String?>(json['description']),
      isToxic: serializer.fromJson<bool?>(json['isToxic']),
      toxicityInfo: serializer.fromJson<String?>(json['toxicityInfo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scientificName': serializer.toJson<String>(scientificName),
      'commonName': serializer.toJson<String>(commonName),
      'description': serializer.toJson<String?>(description),
      'isToxic': serializer.toJson<bool?>(isToxic),
      'toxicityInfo': serializer.toJson<String?>(toxicityInfo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlantSpeciesTableData copyWith({
    String? id,
    String? scientificName,
    String? commonName,
    Value<String?> description = const Value.absent(),
    Value<bool?> isToxic = const Value.absent(),
    Value<String?> toxicityInfo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlantSpeciesTableData(
    id: id ?? this.id,
    scientificName: scientificName ?? this.scientificName,
    commonName: commonName ?? this.commonName,
    description: description.present ? description.value : this.description,
    isToxic: isToxic.present ? isToxic.value : this.isToxic,
    toxicityInfo: toxicityInfo.present ? toxicityInfo.value : this.toxicityInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlantSpeciesTableData copyWithCompanion(PlantSpeciesTableCompanion data) {
    return PlantSpeciesTableData(
      id: data.id.present ? data.id.value : this.id,
      scientificName: data.scientificName.present
          ? data.scientificName.value
          : this.scientificName,
      commonName: data.commonName.present
          ? data.commonName.value
          : this.commonName,
      description: data.description.present
          ? data.description.value
          : this.description,
      isToxic: data.isToxic.present ? data.isToxic.value : this.isToxic,
      toxicityInfo: data.toxicityInfo.present
          ? data.toxicityInfo.value
          : this.toxicityInfo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlantSpeciesTableData(')
          ..write('id: $id, ')
          ..write('scientificName: $scientificName, ')
          ..write('commonName: $commonName, ')
          ..write('description: $description, ')
          ..write('isToxic: $isToxic, ')
          ..write('toxicityInfo: $toxicityInfo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scientificName,
    commonName,
    description,
    isToxic,
    toxicityInfo,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlantSpeciesTableData &&
          other.id == this.id &&
          other.scientificName == this.scientificName &&
          other.commonName == this.commonName &&
          other.description == this.description &&
          other.isToxic == this.isToxic &&
          other.toxicityInfo == this.toxicityInfo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlantSpeciesTableCompanion
    extends UpdateCompanion<PlantSpeciesTableData> {
  final Value<String> id;
  final Value<String> scientificName;
  final Value<String> commonName;
  final Value<String?> description;
  final Value<bool?> isToxic;
  final Value<String?> toxicityInfo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlantSpeciesTableCompanion({
    this.id = const Value.absent(),
    this.scientificName = const Value.absent(),
    this.commonName = const Value.absent(),
    this.description = const Value.absent(),
    this.isToxic = const Value.absent(),
    this.toxicityInfo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlantSpeciesTableCompanion.insert({
    required String id,
    required String scientificName,
    required String commonName,
    this.description = const Value.absent(),
    this.isToxic = const Value.absent(),
    this.toxicityInfo = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scientificName = Value(scientificName),
       commonName = Value(commonName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlantSpeciesTableData> custom({
    Expression<String>? id,
    Expression<String>? scientificName,
    Expression<String>? commonName,
    Expression<String>? description,
    Expression<bool>? isToxic,
    Expression<String>? toxicityInfo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scientificName != null) 'scientific_name': scientificName,
      if (commonName != null) 'common_name': commonName,
      if (description != null) 'description': description,
      if (isToxic != null) 'is_toxic': isToxic,
      if (toxicityInfo != null) 'toxicity_info': toxicityInfo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlantSpeciesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? scientificName,
    Value<String>? commonName,
    Value<String?>? description,
    Value<bool?>? isToxic,
    Value<String?>? toxicityInfo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlantSpeciesTableCompanion(
      id: id ?? this.id,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      description: description ?? this.description,
      isToxic: isToxic ?? this.isToxic,
      toxicityInfo: toxicityInfo ?? this.toxicityInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scientificName.present) {
      map['scientific_name'] = Variable<String>(scientificName.value);
    }
    if (commonName.present) {
      map['common_name'] = Variable<String>(commonName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isToxic.present) {
      map['is_toxic'] = Variable<bool>(isToxic.value);
    }
    if (toxicityInfo.present) {
      map['toxicity_info'] = Variable<String>(toxicityInfo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlantSpeciesTableCompanion(')
          ..write('id: $id, ')
          ..write('scientificName: $scientificName, ')
          ..write('commonName: $commonName, ')
          ..write('description: $description, ')
          ..write('isToxic: $isToxic, ')
          ..write('toxicityInfo: $toxicityInfo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlantEncounterTableTable extends PlantEncounterTable
    with TableInfo<$PlantEncounterTableTable, PlantEncounterTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantEncounterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speciesIdMeta = const VerificationMeta(
    'speciesId',
  );
  @override
  late final GeneratedColumn<String> speciesId = GeneratedColumn<String>(
    'species_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _encounterDateMeta = const VerificationMeta(
    'encounterDate',
  );
  @override
  late final GeneratedColumn<DateTime> encounterDate =
      GeneratedColumn<DateTime>(
        'encounter_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathsMeta = const VerificationMeta(
    'photoPaths',
  );
  @override
  late final GeneratedColumn<String> photoPaths = GeneratedColumn<String>(
    'photo_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecognitionSource, int> source =
      GeneratedColumn<int>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<RecognitionSource>(
        $PlantEncounterTableTable.$convertersource,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RecognitionMethod, int> method =
      GeneratedColumn<int>(
        'method',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<RecognitionMethod>(
        $PlantEncounterTableTable.$convertermethod,
      );
  static const VerificationMeta _userDefinedNameMeta = const VerificationMeta(
    'userDefinedName',
  );
  @override
  late final GeneratedColumn<String> userDefinedName = GeneratedColumn<String>(
    'user_defined_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isIdentifiedMeta = const VerificationMeta(
    'isIdentified',
  );
  @override
  late final GeneratedColumn<bool> isIdentified = GeneratedColumn<bool>(
    'is_identified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_identified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mergedToSpeciesIdMeta = const VerificationMeta(
    'mergedToSpeciesId',
  );
  @override
  late final GeneratedColumn<String> mergedToSpeciesId =
      GeneratedColumn<String>(
        'merged_to_species_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    speciesId,
    encounterDate,
    location,
    latitude,
    longitude,
    photoPaths,
    notes,
    source,
    method,
    userDefinedName,
    isIdentified,
    mergedToSpeciesId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plant_encounter_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlantEncounterTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('species_id')) {
      context.handle(
        _speciesIdMeta,
        speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta),
      );
    }
    if (data.containsKey('encounter_date')) {
      context.handle(
        _encounterDateMeta,
        encounterDate.isAcceptableOrUnknown(
          data['encounter_date']!,
          _encounterDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encounterDateMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('photo_paths')) {
      context.handle(
        _photoPathsMeta,
        photoPaths.isAcceptableOrUnknown(data['photo_paths']!, _photoPathsMeta),
      );
    } else if (isInserting) {
      context.missing(_photoPathsMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('user_defined_name')) {
      context.handle(
        _userDefinedNameMeta,
        userDefinedName.isAcceptableOrUnknown(
          data['user_defined_name']!,
          _userDefinedNameMeta,
        ),
      );
    }
    if (data.containsKey('is_identified')) {
      context.handle(
        _isIdentifiedMeta,
        isIdentified.isAcceptableOrUnknown(
          data['is_identified']!,
          _isIdentifiedMeta,
        ),
      );
    }
    if (data.containsKey('merged_to_species_id')) {
      context.handle(
        _mergedToSpeciesIdMeta,
        mergedToSpeciesId.isAcceptableOrUnknown(
          data['merged_to_species_id']!,
          _mergedToSpeciesIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlantEncounterTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlantEncounterTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      speciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species_id'],
      ),
      encounterDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}encounter_date'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      photoPaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_paths'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      source: $PlantEncounterTableTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}source'],
        )!,
      ),
      method: $PlantEncounterTableTable.$convertermethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}method'],
        )!,
      ),
      userDefinedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_defined_name'],
      ),
      isIdentified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_identified'],
      )!,
      mergedToSpeciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_to_species_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlantEncounterTableTable createAlias(String alias) {
    return $PlantEncounterTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecognitionSource, int, int> $convertersource =
      const EnumIndexConverter<RecognitionSource>(RecognitionSource.values);
  static JsonTypeConverter2<RecognitionMethod, int, int> $convertermethod =
      const EnumIndexConverter<RecognitionMethod>(RecognitionMethod.values);
}

class PlantEncounterTableData extends DataClass
    implements Insertable<PlantEncounterTableData> {
  final String id;
  final String? speciesId;
  final DateTime encounterDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String photoPaths;
  final String? notes;
  final RecognitionSource source;
  final RecognitionMethod method;
  final String? userDefinedName;
  final bool isIdentified;
  final String? mergedToSpeciesId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlantEncounterTableData({
    required this.id,
    this.speciesId,
    required this.encounterDate,
    this.location,
    this.latitude,
    this.longitude,
    required this.photoPaths,
    this.notes,
    required this.source,
    required this.method,
    this.userDefinedName,
    required this.isIdentified,
    this.mergedToSpeciesId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || speciesId != null) {
      map['species_id'] = Variable<String>(speciesId);
    }
    map['encounter_date'] = Variable<DateTime>(encounterDate);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['photo_paths'] = Variable<String>(photoPaths);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['source'] = Variable<int>(
        $PlantEncounterTableTable.$convertersource.toSql(source),
      );
    }
    {
      map['method'] = Variable<int>(
        $PlantEncounterTableTable.$convertermethod.toSql(method),
      );
    }
    if (!nullToAbsent || userDefinedName != null) {
      map['user_defined_name'] = Variable<String>(userDefinedName);
    }
    map['is_identified'] = Variable<bool>(isIdentified);
    if (!nullToAbsent || mergedToSpeciesId != null) {
      map['merged_to_species_id'] = Variable<String>(mergedToSpeciesId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlantEncounterTableCompanion toCompanion(bool nullToAbsent) {
    return PlantEncounterTableCompanion(
      id: Value(id),
      speciesId: speciesId == null && nullToAbsent
          ? const Value.absent()
          : Value(speciesId),
      encounterDate: Value(encounterDate),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      photoPaths: Value(photoPaths),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      source: Value(source),
      method: Value(method),
      userDefinedName: userDefinedName == null && nullToAbsent
          ? const Value.absent()
          : Value(userDefinedName),
      isIdentified: Value(isIdentified),
      mergedToSpeciesId: mergedToSpeciesId == null && nullToAbsent
          ? const Value.absent()
          : Value(mergedToSpeciesId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlantEncounterTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlantEncounterTableData(
      id: serializer.fromJson<String>(json['id']),
      speciesId: serializer.fromJson<String?>(json['speciesId']),
      encounterDate: serializer.fromJson<DateTime>(json['encounterDate']),
      location: serializer.fromJson<String?>(json['location']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      photoPaths: serializer.fromJson<String>(json['photoPaths']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: $PlantEncounterTableTable.$convertersource.fromJson(
        serializer.fromJson<int>(json['source']),
      ),
      method: $PlantEncounterTableTable.$convertermethod.fromJson(
        serializer.fromJson<int>(json['method']),
      ),
      userDefinedName: serializer.fromJson<String?>(json['userDefinedName']),
      isIdentified: serializer.fromJson<bool>(json['isIdentified']),
      mergedToSpeciesId: serializer.fromJson<String?>(
        json['mergedToSpeciesId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'speciesId': serializer.toJson<String?>(speciesId),
      'encounterDate': serializer.toJson<DateTime>(encounterDate),
      'location': serializer.toJson<String?>(location),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'photoPaths': serializer.toJson<String>(photoPaths),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<int>(
        $PlantEncounterTableTable.$convertersource.toJson(source),
      ),
      'method': serializer.toJson<int>(
        $PlantEncounterTableTable.$convertermethod.toJson(method),
      ),
      'userDefinedName': serializer.toJson<String?>(userDefinedName),
      'isIdentified': serializer.toJson<bool>(isIdentified),
      'mergedToSpeciesId': serializer.toJson<String?>(mergedToSpeciesId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlantEncounterTableData copyWith({
    String? id,
    Value<String?> speciesId = const Value.absent(),
    DateTime? encounterDate,
    Value<String?> location = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    String? photoPaths,
    Value<String?> notes = const Value.absent(),
    RecognitionSource? source,
    RecognitionMethod? method,
    Value<String?> userDefinedName = const Value.absent(),
    bool? isIdentified,
    Value<String?> mergedToSpeciesId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlantEncounterTableData(
    id: id ?? this.id,
    speciesId: speciesId.present ? speciesId.value : this.speciesId,
    encounterDate: encounterDate ?? this.encounterDate,
    location: location.present ? location.value : this.location,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    photoPaths: photoPaths ?? this.photoPaths,
    notes: notes.present ? notes.value : this.notes,
    source: source ?? this.source,
    method: method ?? this.method,
    userDefinedName: userDefinedName.present
        ? userDefinedName.value
        : this.userDefinedName,
    isIdentified: isIdentified ?? this.isIdentified,
    mergedToSpeciesId: mergedToSpeciesId.present
        ? mergedToSpeciesId.value
        : this.mergedToSpeciesId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlantEncounterTableData copyWithCompanion(PlantEncounterTableCompanion data) {
    return PlantEncounterTableData(
      id: data.id.present ? data.id.value : this.id,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      encounterDate: data.encounterDate.present
          ? data.encounterDate.value
          : this.encounterDate,
      location: data.location.present ? data.location.value : this.location,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      photoPaths: data.photoPaths.present
          ? data.photoPaths.value
          : this.photoPaths,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      method: data.method.present ? data.method.value : this.method,
      userDefinedName: data.userDefinedName.present
          ? data.userDefinedName.value
          : this.userDefinedName,
      isIdentified: data.isIdentified.present
          ? data.isIdentified.value
          : this.isIdentified,
      mergedToSpeciesId: data.mergedToSpeciesId.present
          ? data.mergedToSpeciesId.value
          : this.mergedToSpeciesId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlantEncounterTableData(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('encounterDate: $encounterDate, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('photoPaths: $photoPaths, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('method: $method, ')
          ..write('userDefinedName: $userDefinedName, ')
          ..write('isIdentified: $isIdentified, ')
          ..write('mergedToSpeciesId: $mergedToSpeciesId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    speciesId,
    encounterDate,
    location,
    latitude,
    longitude,
    photoPaths,
    notes,
    source,
    method,
    userDefinedName,
    isIdentified,
    mergedToSpeciesId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlantEncounterTableData &&
          other.id == this.id &&
          other.speciesId == this.speciesId &&
          other.encounterDate == this.encounterDate &&
          other.location == this.location &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.photoPaths == this.photoPaths &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.method == this.method &&
          other.userDefinedName == this.userDefinedName &&
          other.isIdentified == this.isIdentified &&
          other.mergedToSpeciesId == this.mergedToSpeciesId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlantEncounterTableCompanion
    extends UpdateCompanion<PlantEncounterTableData> {
  final Value<String> id;
  final Value<String?> speciesId;
  final Value<DateTime> encounterDate;
  final Value<String?> location;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String> photoPaths;
  final Value<String?> notes;
  final Value<RecognitionSource> source;
  final Value<RecognitionMethod> method;
  final Value<String?> userDefinedName;
  final Value<bool> isIdentified;
  final Value<String?> mergedToSpeciesId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlantEncounterTableCompanion({
    this.id = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.encounterDate = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.photoPaths = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.method = const Value.absent(),
    this.userDefinedName = const Value.absent(),
    this.isIdentified = const Value.absent(),
    this.mergedToSpeciesId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlantEncounterTableCompanion.insert({
    required String id,
    this.speciesId = const Value.absent(),
    required DateTime encounterDate,
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required String photoPaths,
    this.notes = const Value.absent(),
    required RecognitionSource source,
    required RecognitionMethod method,
    this.userDefinedName = const Value.absent(),
    this.isIdentified = const Value.absent(),
    this.mergedToSpeciesId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       encounterDate = Value(encounterDate),
       photoPaths = Value(photoPaths),
       source = Value(source),
       method = Value(method),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlantEncounterTableData> custom({
    Expression<String>? id,
    Expression<String>? speciesId,
    Expression<DateTime>? encounterDate,
    Expression<String>? location,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? photoPaths,
    Expression<String>? notes,
    Expression<int>? source,
    Expression<int>? method,
    Expression<String>? userDefinedName,
    Expression<bool>? isIdentified,
    Expression<String>? mergedToSpeciesId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (speciesId != null) 'species_id': speciesId,
      if (encounterDate != null) 'encounter_date': encounterDate,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoPaths != null) 'photo_paths': photoPaths,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (method != null) 'method': method,
      if (userDefinedName != null) 'user_defined_name': userDefinedName,
      if (isIdentified != null) 'is_identified': isIdentified,
      if (mergedToSpeciesId != null) 'merged_to_species_id': mergedToSpeciesId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlantEncounterTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? speciesId,
    Value<DateTime>? encounterDate,
    Value<String?>? location,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String>? photoPaths,
    Value<String?>? notes,
    Value<RecognitionSource>? source,
    Value<RecognitionMethod>? method,
    Value<String?>? userDefinedName,
    Value<bool>? isIdentified,
    Value<String?>? mergedToSpeciesId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlantEncounterTableCompanion(
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
      userDefinedName: userDefinedName ?? this.userDefinedName,
      isIdentified: isIdentified ?? this.isIdentified,
      mergedToSpeciesId: mergedToSpeciesId ?? this.mergedToSpeciesId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<String>(speciesId.value);
    }
    if (encounterDate.present) {
      map['encounter_date'] = Variable<DateTime>(encounterDate.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (photoPaths.present) {
      map['photo_paths'] = Variable<String>(photoPaths.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(
        $PlantEncounterTableTable.$convertersource.toSql(source.value),
      );
    }
    if (method.present) {
      map['method'] = Variable<int>(
        $PlantEncounterTableTable.$convertermethod.toSql(method.value),
      );
    }
    if (userDefinedName.present) {
      map['user_defined_name'] = Variable<String>(userDefinedName.value);
    }
    if (isIdentified.present) {
      map['is_identified'] = Variable<bool>(isIdentified.value);
    }
    if (mergedToSpeciesId.present) {
      map['merged_to_species_id'] = Variable<String>(mergedToSpeciesId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlantEncounterTableCompanion(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('encounterDate: $encounterDate, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('photoPaths: $photoPaths, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('method: $method, ')
          ..write('userDefinedName: $userDefinedName, ')
          ..write('isIdentified: $isIdentified, ')
          ..write('mergedToSpeciesId: $mergedToSpeciesId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enableLocationMeta = const VerificationMeta(
    'enableLocation',
  );
  @override
  late final GeneratedColumn<bool> enableLocation = GeneratedColumn<bool>(
    'enable_location',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enable_location" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoSaveLocationMeta = const VerificationMeta(
    'autoSaveLocation',
  );
  @override
  late final GeneratedColumn<bool> autoSaveLocation = GeneratedColumn<bool>(
    'auto_save_location',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_save_location" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _saveOriginalPhotosMeta =
      const VerificationMeta('saveOriginalPhotos');
  @override
  late final GeneratedColumn<bool> saveOriginalPhotos = GeneratedColumn<bool>(
    'save_original_photos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("save_original_photos" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _enableLocalRecognitionMeta =
      const VerificationMeta('enableLocalRecognition');
  @override
  late final GeneratedColumn<bool> enableLocalRecognition =
      GeneratedColumn<bool>(
        'enable_local_recognition',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_local_recognition" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baseUrl,
    apiKey,
    enableLocation,
    autoSaveLocation,
    saveOriginalPhotos,
    enableLocalRecognition,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    }
    if (data.containsKey('enable_location')) {
      context.handle(
        _enableLocationMeta,
        enableLocation.isAcceptableOrUnknown(
          data['enable_location']!,
          _enableLocationMeta,
        ),
      );
    }
    if (data.containsKey('auto_save_location')) {
      context.handle(
        _autoSaveLocationMeta,
        autoSaveLocation.isAcceptableOrUnknown(
          data['auto_save_location']!,
          _autoSaveLocationMeta,
        ),
      );
    }
    if (data.containsKey('save_original_photos')) {
      context.handle(
        _saveOriginalPhotosMeta,
        saveOriginalPhotos.isAcceptableOrUnknown(
          data['save_original_photos']!,
          _saveOriginalPhotosMeta,
        ),
      );
    }
    if (data.containsKey('enable_local_recognition')) {
      context.handle(
        _enableLocalRecognitionMeta,
        enableLocalRecognition.isAcceptableOrUnknown(
          data['enable_local_recognition']!,
          _enableLocalRecognitionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      ),
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      ),
      enableLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enable_location'],
      )!,
      autoSaveLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_save_location'],
      )!,
      saveOriginalPhotos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}save_original_photos'],
      )!,
      enableLocalRecognition: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enable_local_recognition'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingsTableData extends DataClass
    implements Insertable<AppSettingsTableData> {
  final int id;
  final String? baseUrl;
  final String? apiKey;
  final bool enableLocation;
  final bool autoSaveLocation;
  final bool saveOriginalPhotos;
  final bool enableLocalRecognition;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppSettingsTableData({
    required this.id,
    this.baseUrl,
    this.apiKey,
    required this.enableLocation,
    required this.autoSaveLocation,
    required this.saveOriginalPhotos,
    required this.enableLocalRecognition,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || baseUrl != null) {
      map['base_url'] = Variable<String>(baseUrl);
    }
    if (!nullToAbsent || apiKey != null) {
      map['api_key'] = Variable<String>(apiKey);
    }
    map['enable_location'] = Variable<bool>(enableLocation);
    map['auto_save_location'] = Variable<bool>(autoSaveLocation);
    map['save_original_photos'] = Variable<bool>(saveOriginalPhotos);
    map['enable_local_recognition'] = Variable<bool>(enableLocalRecognition);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      id: Value(id),
      baseUrl: baseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUrl),
      apiKey: apiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(apiKey),
      enableLocation: Value(enableLocation),
      autoSaveLocation: Value(autoSaveLocation),
      saveOriginalPhotos: Value(saveOriginalPhotos),
      enableLocalRecognition: Value(enableLocalRecognition),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      baseUrl: serializer.fromJson<String?>(json['baseUrl']),
      apiKey: serializer.fromJson<String?>(json['apiKey']),
      enableLocation: serializer.fromJson<bool>(json['enableLocation']),
      autoSaveLocation: serializer.fromJson<bool>(json['autoSaveLocation']),
      saveOriginalPhotos: serializer.fromJson<bool>(json['saveOriginalPhotos']),
      enableLocalRecognition: serializer.fromJson<bool>(
        json['enableLocalRecognition'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'apiKey': serializer.toJson<String?>(apiKey),
      'enableLocation': serializer.toJson<bool>(enableLocation),
      'autoSaveLocation': serializer.toJson<bool>(autoSaveLocation),
      'saveOriginalPhotos': serializer.toJson<bool>(saveOriginalPhotos),
      'enableLocalRecognition': serializer.toJson<bool>(enableLocalRecognition),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingsTableData copyWith({
    int? id,
    Value<String?> baseUrl = const Value.absent(),
    Value<String?> apiKey = const Value.absent(),
    bool? enableLocation,
    bool? autoSaveLocation,
    bool? saveOriginalPhotos,
    bool? enableLocalRecognition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppSettingsTableData(
    id: id ?? this.id,
    baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
    apiKey: apiKey.present ? apiKey.value : this.apiKey,
    enableLocation: enableLocation ?? this.enableLocation,
    autoSaveLocation: autoSaveLocation ?? this.autoSaveLocation,
    saveOriginalPhotos: saveOriginalPhotos ?? this.saveOriginalPhotos,
    enableLocalRecognition:
        enableLocalRecognition ?? this.enableLocalRecognition,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingsTableData copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      enableLocation: data.enableLocation.present
          ? data.enableLocation.value
          : this.enableLocation,
      autoSaveLocation: data.autoSaveLocation.present
          ? data.autoSaveLocation.value
          : this.autoSaveLocation,
      saveOriginalPhotos: data.saveOriginalPhotos.present
          ? data.saveOriginalPhotos.value
          : this.saveOriginalPhotos,
      enableLocalRecognition: data.enableLocalRecognition.present
          ? data.enableLocalRecognition.value
          : this.enableLocalRecognition,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableData(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('enableLocation: $enableLocation, ')
          ..write('autoSaveLocation: $autoSaveLocation, ')
          ..write('saveOriginalPhotos: $saveOriginalPhotos, ')
          ..write('enableLocalRecognition: $enableLocalRecognition, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseUrl,
    apiKey,
    enableLocation,
    autoSaveLocation,
    saveOriginalPhotos,
    enableLocalRecognition,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsTableData &&
          other.id == this.id &&
          other.baseUrl == this.baseUrl &&
          other.apiKey == this.apiKey &&
          other.enableLocation == this.enableLocation &&
          other.autoSaveLocation == this.autoSaveLocation &&
          other.saveOriginalPhotos == this.saveOriginalPhotos &&
          other.enableLocalRecognition == this.enableLocalRecognition &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingsTableData> {
  final Value<int> id;
  final Value<String?> baseUrl;
  final Value<String?> apiKey;
  final Value<bool> enableLocation;
  final Value<bool> autoSaveLocation;
  final Value<bool> saveOriginalPhotos;
  final Value<bool> enableLocalRecognition;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AppSettingsTableCompanion({
    this.id = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.enableLocation = const Value.absent(),
    this.autoSaveLocation = const Value.absent(),
    this.saveOriginalPhotos = const Value.absent(),
    this.enableLocalRecognition = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.enableLocation = const Value.absent(),
    this.autoSaveLocation = const Value.absent(),
    this.saveOriginalPhotos = const Value.absent(),
    this.enableLocalRecognition = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? baseUrl,
    Expression<String>? apiKey,
    Expression<bool>? enableLocation,
    Expression<bool>? autoSaveLocation,
    Expression<bool>? saveOriginalPhotos,
    Expression<bool>? enableLocalRecognition,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseUrl != null) 'base_url': baseUrl,
      if (apiKey != null) 'api_key': apiKey,
      if (enableLocation != null) 'enable_location': enableLocation,
      if (autoSaveLocation != null) 'auto_save_location': autoSaveLocation,
      if (saveOriginalPhotos != null)
        'save_original_photos': saveOriginalPhotos,
      if (enableLocalRecognition != null)
        'enable_local_recognition': enableLocalRecognition,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? baseUrl,
    Value<String?>? apiKey,
    Value<bool>? enableLocation,
    Value<bool>? autoSaveLocation,
    Value<bool>? saveOriginalPhotos,
    Value<bool>? enableLocalRecognition,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsTableCompanion(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      enableLocation: enableLocation ?? this.enableLocation,
      autoSaveLocation: autoSaveLocation ?? this.autoSaveLocation,
      saveOriginalPhotos: saveOriginalPhotos ?? this.saveOriginalPhotos,
      enableLocalRecognition:
          enableLocalRecognition ?? this.enableLocalRecognition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (enableLocation.present) {
      map['enable_location'] = Variable<bool>(enableLocation.value);
    }
    if (autoSaveLocation.present) {
      map['auto_save_location'] = Variable<bool>(autoSaveLocation.value);
    }
    if (saveOriginalPhotos.present) {
      map['save_original_photos'] = Variable<bool>(saveOriginalPhotos.value);
    }
    if (enableLocalRecognition.present) {
      map['enable_local_recognition'] = Variable<bool>(
        enableLocalRecognition.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('enableLocation: $enableLocation, ')
          ..write('autoSaveLocation: $autoSaveLocation, ')
          ..write('saveOriginalPhotos: $saveOriginalPhotos, ')
          ..write('enableLocalRecognition: $enableLocalRecognition, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlantSpeciesTableTable plantSpeciesTable =
      $PlantSpeciesTableTable(this);
  late final $PlantEncounterTableTable plantEncounterTable =
      $PlantEncounterTableTable(this);
  late final $AppSettingsTableTable appSettingsTable = $AppSettingsTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    plantSpeciesTable,
    plantEncounterTable,
    appSettingsTable,
  ];
}

typedef $$PlantSpeciesTableTableCreateCompanionBuilder =
    PlantSpeciesTableCompanion Function({
      required String id,
      required String scientificName,
      required String commonName,
      Value<String?> description,
      Value<bool?> isToxic,
      Value<String?> toxicityInfo,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlantSpeciesTableTableUpdateCompanionBuilder =
    PlantSpeciesTableCompanion Function({
      Value<String> id,
      Value<String> scientificName,
      Value<String> commonName,
      Value<String?> description,
      Value<bool?> isToxic,
      Value<String?> toxicityInfo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlantSpeciesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlantSpeciesTableTable> {
  $$PlantSpeciesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isToxic => $composableBuilder(
    column: $table.isToxic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toxicityInfo => $composableBuilder(
    column: $table.toxicityInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlantSpeciesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantSpeciesTableTable> {
  $$PlantSpeciesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isToxic => $composableBuilder(
    column: $table.isToxic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toxicityInfo => $composableBuilder(
    column: $table.toxicityInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlantSpeciesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantSpeciesTableTable> {
  $$PlantSpeciesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commonName => $composableBuilder(
    column: $table.commonName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isToxic =>
      $composableBuilder(column: $table.isToxic, builder: (column) => column);

  GeneratedColumn<String> get toxicityInfo => $composableBuilder(
    column: $table.toxicityInfo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlantSpeciesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlantSpeciesTableTable,
          PlantSpeciesTableData,
          $$PlantSpeciesTableTableFilterComposer,
          $$PlantSpeciesTableTableOrderingComposer,
          $$PlantSpeciesTableTableAnnotationComposer,
          $$PlantSpeciesTableTableCreateCompanionBuilder,
          $$PlantSpeciesTableTableUpdateCompanionBuilder,
          (
            PlantSpeciesTableData,
            BaseReferences<
              _$AppDatabase,
              $PlantSpeciesTableTable,
              PlantSpeciesTableData
            >,
          ),
          PlantSpeciesTableData,
          PrefetchHooks Function()
        > {
  $$PlantSpeciesTableTableTableManager(
    _$AppDatabase db,
    $PlantSpeciesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantSpeciesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantSpeciesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlantSpeciesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scientificName = const Value.absent(),
                Value<String> commonName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool?> isToxic = const Value.absent(),
                Value<String?> toxicityInfo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlantSpeciesTableCompanion(
                id: id,
                scientificName: scientificName,
                commonName: commonName,
                description: description,
                isToxic: isToxic,
                toxicityInfo: toxicityInfo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scientificName,
                required String commonName,
                Value<String?> description = const Value.absent(),
                Value<bool?> isToxic = const Value.absent(),
                Value<String?> toxicityInfo = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlantSpeciesTableCompanion.insert(
                id: id,
                scientificName: scientificName,
                commonName: commonName,
                description: description,
                isToxic: isToxic,
                toxicityInfo: toxicityInfo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlantSpeciesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlantSpeciesTableTable,
      PlantSpeciesTableData,
      $$PlantSpeciesTableTableFilterComposer,
      $$PlantSpeciesTableTableOrderingComposer,
      $$PlantSpeciesTableTableAnnotationComposer,
      $$PlantSpeciesTableTableCreateCompanionBuilder,
      $$PlantSpeciesTableTableUpdateCompanionBuilder,
      (
        PlantSpeciesTableData,
        BaseReferences<
          _$AppDatabase,
          $PlantSpeciesTableTable,
          PlantSpeciesTableData
        >,
      ),
      PlantSpeciesTableData,
      PrefetchHooks Function()
    >;
typedef $$PlantEncounterTableTableCreateCompanionBuilder =
    PlantEncounterTableCompanion Function({
      required String id,
      Value<String?> speciesId,
      required DateTime encounterDate,
      Value<String?> location,
      Value<double?> latitude,
      Value<double?> longitude,
      required String photoPaths,
      Value<String?> notes,
      required RecognitionSource source,
      required RecognitionMethod method,
      Value<String?> userDefinedName,
      Value<bool> isIdentified,
      Value<String?> mergedToSpeciesId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlantEncounterTableTableUpdateCompanionBuilder =
    PlantEncounterTableCompanion Function({
      Value<String> id,
      Value<String?> speciesId,
      Value<DateTime> encounterDate,
      Value<String?> location,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String> photoPaths,
      Value<String?> notes,
      Value<RecognitionSource> source,
      Value<RecognitionMethod> method,
      Value<String?> userDefinedName,
      Value<bool> isIdentified,
      Value<String?> mergedToSpeciesId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlantEncounterTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlantEncounterTableTable> {
  $$PlantEncounterTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get encounterDate => $composableBuilder(
    column: $table.encounterDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPaths => $composableBuilder(
    column: $table.photoPaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecognitionSource, RecognitionSource, int>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RecognitionMethod, RecognitionMethod, int>
  get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get userDefinedName => $composableBuilder(
    column: $table.userDefinedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIdentified => $composableBuilder(
    column: $table.isIdentified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mergedToSpeciesId => $composableBuilder(
    column: $table.mergedToSpeciesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlantEncounterTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantEncounterTableTable> {
  $$PlantEncounterTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get encounterDate => $composableBuilder(
    column: $table.encounterDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPaths => $composableBuilder(
    column: $table.photoPaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userDefinedName => $composableBuilder(
    column: $table.userDefinedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIdentified => $composableBuilder(
    column: $table.isIdentified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mergedToSpeciesId => $composableBuilder(
    column: $table.mergedToSpeciesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlantEncounterTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantEncounterTableTable> {
  $$PlantEncounterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<DateTime> get encounterDate => $composableBuilder(
    column: $table.encounterDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get photoPaths => $composableBuilder(
    column: $table.photoPaths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecognitionSource, int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecognitionMethod, int> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get userDefinedName => $composableBuilder(
    column: $table.userDefinedName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isIdentified => $composableBuilder(
    column: $table.isIdentified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mergedToSpeciesId => $composableBuilder(
    column: $table.mergedToSpeciesId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlantEncounterTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlantEncounterTableTable,
          PlantEncounterTableData,
          $$PlantEncounterTableTableFilterComposer,
          $$PlantEncounterTableTableOrderingComposer,
          $$PlantEncounterTableTableAnnotationComposer,
          $$PlantEncounterTableTableCreateCompanionBuilder,
          $$PlantEncounterTableTableUpdateCompanionBuilder,
          (
            PlantEncounterTableData,
            BaseReferences<
              _$AppDatabase,
              $PlantEncounterTableTable,
              PlantEncounterTableData
            >,
          ),
          PlantEncounterTableData,
          PrefetchHooks Function()
        > {
  $$PlantEncounterTableTableTableManager(
    _$AppDatabase db,
    $PlantEncounterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantEncounterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantEncounterTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlantEncounterTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> speciesId = const Value.absent(),
                Value<DateTime> encounterDate = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String> photoPaths = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<RecognitionSource> source = const Value.absent(),
                Value<RecognitionMethod> method = const Value.absent(),
                Value<String?> userDefinedName = const Value.absent(),
                Value<bool> isIdentified = const Value.absent(),
                Value<String?> mergedToSpeciesId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlantEncounterTableCompanion(
                id: id,
                speciesId: speciesId,
                encounterDate: encounterDate,
                location: location,
                latitude: latitude,
                longitude: longitude,
                photoPaths: photoPaths,
                notes: notes,
                source: source,
                method: method,
                userDefinedName: userDefinedName,
                isIdentified: isIdentified,
                mergedToSpeciesId: mergedToSpeciesId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> speciesId = const Value.absent(),
                required DateTime encounterDate,
                Value<String?> location = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required String photoPaths,
                Value<String?> notes = const Value.absent(),
                required RecognitionSource source,
                required RecognitionMethod method,
                Value<String?> userDefinedName = const Value.absent(),
                Value<bool> isIdentified = const Value.absent(),
                Value<String?> mergedToSpeciesId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlantEncounterTableCompanion.insert(
                id: id,
                speciesId: speciesId,
                encounterDate: encounterDate,
                location: location,
                latitude: latitude,
                longitude: longitude,
                photoPaths: photoPaths,
                notes: notes,
                source: source,
                method: method,
                userDefinedName: userDefinedName,
                isIdentified: isIdentified,
                mergedToSpeciesId: mergedToSpeciesId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlantEncounterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlantEncounterTableTable,
      PlantEncounterTableData,
      $$PlantEncounterTableTableFilterComposer,
      $$PlantEncounterTableTableOrderingComposer,
      $$PlantEncounterTableTableAnnotationComposer,
      $$PlantEncounterTableTableCreateCompanionBuilder,
      $$PlantEncounterTableTableUpdateCompanionBuilder,
      (
        PlantEncounterTableData,
        BaseReferences<
          _$AppDatabase,
          $PlantEncounterTableTable,
          PlantEncounterTableData
        >,
      ),
      PlantEncounterTableData,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableTableCreateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> id,
      Value<String?> baseUrl,
      Value<String?> apiKey,
      Value<bool> enableLocation,
      Value<bool> autoSaveLocation,
      Value<bool> saveOriginalPhotos,
      Value<bool> enableLocalRecognition,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$AppSettingsTableTableUpdateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<int> id,
      Value<String?> baseUrl,
      Value<String?> apiKey,
      Value<bool> enableLocation,
      Value<bool> autoSaveLocation,
      Value<bool> saveOriginalPhotos,
      Value<bool> enableLocalRecognition,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enableLocation => $composableBuilder(
    column: $table.enableLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSaveLocation => $composableBuilder(
    column: $table.autoSaveLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saveOriginalPhotos => $composableBuilder(
    column: $table.saveOriginalPhotos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enableLocalRecognition => $composableBuilder(
    column: $table.enableLocalRecognition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enableLocation => $composableBuilder(
    column: $table.enableLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSaveLocation => $composableBuilder(
    column: $table.autoSaveLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saveOriginalPhotos => $composableBuilder(
    column: $table.saveOriginalPhotos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enableLocalRecognition => $composableBuilder(
    column: $table.enableLocalRecognition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<bool> get enableLocation => $composableBuilder(
    column: $table.enableLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoSaveLocation => $composableBuilder(
    column: $table.autoSaveLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get saveOriginalPhotos => $composableBuilder(
    column: $table.saveOriginalPhotos,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enableLocalRecognition => $composableBuilder(
    column: $table.enableLocalRecognition,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTableTable,
          AppSettingsTableData,
          $$AppSettingsTableTableFilterComposer,
          $$AppSettingsTableTableOrderingComposer,
          $$AppSettingsTableTableAnnotationComposer,
          $$AppSettingsTableTableCreateCompanionBuilder,
          $$AppSettingsTableTableUpdateCompanionBuilder,
          (
            AppSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsTableTable,
              AppSettingsTableData
            >,
          ),
          AppSettingsTableData,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableTableManager(
    _$AppDatabase db,
    $AppSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<String?> apiKey = const Value.absent(),
                Value<bool> enableLocation = const Value.absent(),
                Value<bool> autoSaveLocation = const Value.absent(),
                Value<bool> saveOriginalPhotos = const Value.absent(),
                Value<bool> enableLocalRecognition = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsTableCompanion(
                id: id,
                baseUrl: baseUrl,
                apiKey: apiKey,
                enableLocation: enableLocation,
                autoSaveLocation: autoSaveLocation,
                saveOriginalPhotos: saveOriginalPhotos,
                enableLocalRecognition: enableLocalRecognition,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<String?> apiKey = const Value.absent(),
                Value<bool> enableLocation = const Value.absent(),
                Value<bool> autoSaveLocation = const Value.absent(),
                Value<bool> saveOriginalPhotos = const Value.absent(),
                Value<bool> enableLocalRecognition = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => AppSettingsTableCompanion.insert(
                id: id,
                baseUrl: baseUrl,
                apiKey: apiKey,
                enableLocation: enableLocation,
                autoSaveLocation: autoSaveLocation,
                saveOriginalPhotos: saveOriginalPhotos,
                enableLocalRecognition: enableLocalRecognition,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTableTable,
      AppSettingsTableData,
      $$AppSettingsTableTableFilterComposer,
      $$AppSettingsTableTableOrderingComposer,
      $$AppSettingsTableTableAnnotationComposer,
      $$AppSettingsTableTableCreateCompanionBuilder,
      $$AppSettingsTableTableUpdateCompanionBuilder,
      (
        AppSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $AppSettingsTableTable,
          AppSettingsTableData
        >,
      ),
      AppSettingsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlantSpeciesTableTableTableManager get plantSpeciesTable =>
      $$PlantSpeciesTableTableTableManager(_db, _db.plantSpeciesTable);
  $$PlantEncounterTableTableTableManager get plantEncounterTable =>
      $$PlantEncounterTableTableTableManager(_db, _db.plantEncounterTable);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
}
