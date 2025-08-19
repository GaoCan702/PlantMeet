import 'dart:convert';
import 'package:drift/drift.dart';
import 'database.dart';
import '../models/index.dart';

class DatabaseService {
  final AppDatabase database;

  DatabaseService(this.database);

  // Plant Species operations
  Future<List<PlantSpecies>> getAllSpecies() async {
    final results = await database.select(database.plantSpeciesTable).get();
    return results
        .map(
          (row) => PlantSpecies(
            id: row.id,
            scientificName: row.scientificName,
            commonName: row.commonName,
            description: row.description,
            isToxic: row.isToxic,
            toxicityInfo: row.toxicityInfo,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  Future<PlantSpecies?> getSpeciesById(String id) async {
    final results = await (database.select(
      database.plantSpeciesTable,
    )..where((t) => t.id.equals(id))).get();

    if (results.isEmpty) return null;

    final row = results.first;
    return PlantSpecies(
      id: row.id,
      scientificName: row.scientificName,
      commonName: row.commonName,
      description: row.description,
      isToxic: row.isToxic,
      toxicityInfo: row.toxicityInfo,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<PlantSpecies?> findSpeciesByNames(
    String scientificName,
    String commonName,
  ) async {
    final results =
        await (database.select(database.plantSpeciesTable)..where(
              (t) =>
                  t.scientificName.equals(scientificName) &
                  t.commonName.equals(commonName),
            ))
            .get();

    if (results.isEmpty) return null;

    final row = results.first;
    return PlantSpecies(
      id: row.id,
      scientificName: row.scientificName,
      commonName: row.commonName,
      description: row.description,
      isToxic: row.isToxic,
      toxicityInfo: row.toxicityInfo,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<PlantSpecies> createSpecies(PlantSpecies species) async {
    await database
        .into(database.plantSpeciesTable)
        .insert(
          PlantSpeciesTableCompanion.insert(
            id: species.id,
            scientificName: species.scientificName,
            commonName: species.commonName,
            description: Value(species.description),
            isToxic: Value(species.isToxic),
            toxicityInfo: Value(species.toxicityInfo),
            createdAt: species.createdAt,
            updatedAt: species.updatedAt,
          ),
        );
    return species;
  }

  Future<PlantSpecies> updateSpecies(PlantSpecies species) async {
    await database
        .update(database.plantSpeciesTable)
        .replace(
          PlantSpeciesTableCompanion.insert(
            id: species.id,
            scientificName: species.scientificName,
            commonName: species.commonName,
            description: Value(species.description),
            isToxic: Value(species.isToxic),
            toxicityInfo: Value(species.toxicityInfo),
            createdAt: species.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
    return species;
  }

  Future<void> deleteSpecies(String id) async {
    await (database.delete(
      database.plantSpeciesTable,
    )..where((t) => t.id.equals(id))).go();
  }

  // Plant Encounter operations
  Future<List<PlantEncounter>> getAllEncounters() async {
    final results = await database.select(database.plantEncounterTable).get();
    return results.map(_encounterFromRow).toList();
  }

  Future<List<PlantEncounter>> getEncountersBySpecies(String speciesId) async {
    final results = await (database.select(
      database.plantEncounterTable,
    )..where((t) => t.speciesId.equals(speciesId))).get();
    return results.map(_encounterFromRow).toList();
  }

  Future<PlantEncounter?> getEncounterById(String id) async {
    final results = await (database.select(
      database.plantEncounterTable,
    )..where((t) => t.id.equals(id))).get();

    if (results.isEmpty) return null;
    return _encounterFromRow(results.first);
  }

  Future<PlantEncounter> createEncounter(PlantEncounter encounter) async {
    await database
        .into(database.plantEncounterTable)
        .insert(
          PlantEncounterTableCompanion.insert(
            id: encounter.id,
            speciesId: Value(encounter.speciesId),  // 使用Value包装可空类型
            encounterDate: encounter.encounterDate,
            location: Value(encounter.location),
            latitude: Value(encounter.latitude),
            longitude: Value(encounter.longitude),
            photoPaths: jsonEncode(encounter.photoPaths),
            notes: Value(encounter.notes),
            source: encounter.source,
            method: encounter.method,
            userDefinedName: Value(encounter.userDefinedName),
            isIdentified: Value(encounter.isIdentified),
            mergedToSpeciesId: Value(encounter.mergedToSpeciesId),
            createdAt: encounter.createdAt,
            updatedAt: encounter.updatedAt,
          ),
        );
    return encounter;
  }

  Future<PlantEncounter> updateEncounter(PlantEncounter encounter) async {
    await database.update(database.plantEncounterTable).replace(
          PlantEncounterTableCompanion(
            id: Value(encounter.id),
            speciesId: Value(encounter.speciesId),
            encounterDate: Value(encounter.encounterDate),
            location: Value(encounter.location),
            latitude: Value(encounter.latitude),
            longitude: Value(encounter.longitude),
            photoPaths: Value(jsonEncode(encounter.photoPaths)),
            notes: Value(encounter.notes),
            source: Value(encounter.source),
            method: Value(encounter.method),
            userDefinedName: Value(encounter.userDefinedName),
            isIdentified: Value(encounter.isIdentified),
            mergedToSpeciesId: Value(encounter.mergedToSpeciesId),
            createdAt: Value(encounter.createdAt),
            updatedAt: Value(encounter.updatedAt),
          ),
        );
    return encounter;
  }

  Future<void> deleteEncounter(String id) async {
    await (database.delete(
      database.plantEncounterTable,
    )..where((t) => t.id.equals(id))).go();
  }

  // App Settings operations
  Future<AppSettings?> getSettings() async {
    final results = await database.select(database.appSettingsTable).get();
    if (results.isEmpty) return null;

    final row = results.first;
    return AppSettings(
      baseUrl: row.baseUrl,
      apiKey: row.apiKey,
      enableLocation: row.enableLocation,
      autoSaveLocation: row.autoSaveLocation,
      saveOriginalPhotos: row.saveOriginalPhotos,
      enableLocalRecognition: row.enableLocalRecognition,
    );
  }

  Future<AppSettings> updateSettings(AppSettings settings) async {
    final existing = await database.select(database.appSettingsTable).get();

    if (existing.isEmpty) {
      await database
          .into(database.appSettingsTable)
          .insert(
            AppSettingsTableCompanion.insert(
              baseUrl: Value(settings.baseUrl),
              apiKey: Value(settings.apiKey),
              enableLocation: Value(settings.enableLocation),
              autoSaveLocation: Value(settings.autoSaveLocation),
              saveOriginalPhotos: Value(settings.saveOriginalPhotos),
              enableLocalRecognition: Value(settings.enableLocalRecognition),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
    } else {
      await database
          .update(database.appSettingsTable)
          .replace(
            AppSettingsTableCompanion.insert(
              id: Value(existing.first.id),
              baseUrl: Value(settings.baseUrl),
              apiKey: Value(settings.apiKey),
              enableLocation: Value(settings.enableLocation),
              autoSaveLocation: Value(settings.autoSaveLocation),
              saveOriginalPhotos: Value(settings.saveOriginalPhotos),
              enableLocalRecognition: Value(settings.enableLocalRecognition),
              createdAt: existing.first.createdAt,
              updatedAt: DateTime.now(),
            ),
          );
    }

    return settings;
  }

  // Helper methods
  PlantEncounter _encounterFromRow(PlantEncounterTableData row) {
    return PlantEncounter(
      id: row.id,
      speciesId: row.speciesId,
      encounterDate: row.encounterDate,
      location: row.location,
      latitude: row.latitude,
      longitude: row.longitude,
      photoPaths: List<String>.from(jsonDecode(row.photoPaths)),
      notes: row.notes,
      source: row.source,
      method: row.method,
      userDefinedName: row.userDefinedName,
      isIdentified: row.isIdentified,
      mergedToSpeciesId: row.mergedToSpeciesId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // Smart deduplication methods
  Future<List<String>> getSpeciesNames() async {
    final results = await database.select(database.plantSpeciesTable).get();
    return results.map((row) => row.commonName).toList();
  }

  Future<PlantSpecies?> findSpeciesByName(String name) async {
    final results = await (database.select(
      database.plantSpeciesTable,
    )..where((t) => t.commonName.lower().equals(name.toLowerCase()))).get();

    if (results.isEmpty) return null;

    final row = results.first;
    return PlantSpecies(
      id: row.id,
      scientificName: row.scientificName,
      commonName: row.commonName,
      description: row.description,
      isToxic: row.isToxic,
      toxicityInfo: row.toxicityInfo,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<int> getEncounterCount(String speciesId) async {
    final count = await (database.select(
      database.plantEncounterTable,
    )..where((t) => t.speciesId.equals(speciesId))).get();
    return count.length;
  }
}
