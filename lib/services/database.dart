import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/index.dart';

part 'database.g.dart';

class PlantSpeciesTable extends Table {
  TextColumn get id => text()();
  TextColumn get scientificName => text()();
  TextColumn get commonName => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isToxic => boolean().nullable()();
  TextColumn get toxicityInfo => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlantEncounterTable extends Table {
  TextColumn get id => text()();
  TextColumn get speciesId => text().nullable()(); // 改为可空，支持未识别植物
  DateTimeColumn get encounterDate => dateTime()();
  TextColumn get location => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get photoPaths => text()(); // JSON array
  TextColumn get notes => text().nullable()();
  IntColumn get source => intEnum<RecognitionSource>()();
  IntColumn get method => intEnum<RecognitionMethod>()();
  TextColumn get userDefinedName => text().nullable()(); // 用户自定义名称
  BoolColumn get isIdentified => boolean().withDefault(const Constant(false))(); // 是否已识别
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get baseUrl => text().nullable()();
  TextColumn get apiKey => text().nullable()();
  BoolColumn get enableLocation =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoSaveLocation =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get saveOriginalPhotos =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get enableLocalRecognition =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(
  tables: [PlantSpeciesTable, PlantEncounterTable, AppSettingsTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        // 添加 enableLocalRecognition 字段
        await m.addColumn(
          appSettingsTable,
          appSettingsTable.enableLocalRecognition,
        );
      }
      if (from < 4) {
        // 添加支持未识别植物的新字段
        await m.addColumn(
          plantEncounterTable,
          plantEncounterTable.userDefinedName,
        );
        await m.addColumn(
          plantEncounterTable,
          plantEncounterTable.isIdentified,
        );
        // 将speciesId改为可空在某些数据库中需要重建表
        // 这里假设新安装或可以接受数据迁移
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'plantmeet.sqlite'));
    return NativeDatabase(file);
  });
}
