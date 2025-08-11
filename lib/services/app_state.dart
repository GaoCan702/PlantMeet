import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/database_service.dart';
import '../services/recognition_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService databaseService;
  
  AppSettings? _settings;
  List<PlantSpecies> _species = [];
  List<PlantEncounter> _encounters = [];
  bool _isLoading = false;
  String? _error;

  AppState({required this.databaseService});

  AppSettings? get settings => _settings;
  List<PlantSpecies> get species => _species;
  List<PlantEncounter> get encounters => _encounters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 检查是否已配置识别服务
  bool get isConfigured {
    return _settings?.isConfigured ?? false;
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      _settings = await databaseService.getSettings() ?? AppSettings();
      await _loadData();
    } catch (e) {
      _setError('Failed to initialize app: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadData() async {
    try {
      _species = await databaseService.getAllSpecies();
      _encounters = await databaseService.getAllEncounters();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load data: $e');
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    _setLoading(true);
    try {
      _settings = await databaseService.updateSettings(settings);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  void updateRecognitionService(RecognitionService recognitionService) {
    recognitionService.updateSettings(_settings ?? AppSettings());
  }

  Future<void> addSpecies(PlantSpecies species) async {
    _setLoading(true);
    try {
      await databaseService.createSpecies(species);
      await _loadData();
    } catch (e) {
      _setError('Failed to add species: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addEncounter(PlantEncounter encounter) async {
    _setLoading(true);
    try {
      await databaseService.createEncounter(encounter);
      await _loadData();
    } catch (e) {
      _setError('Failed to add encounter: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 智能添加识别结果，实现去重逻辑
  Future<void> addRecognitionResult(
    PlantSpecies species, 
    PlantEncounter encounter,
  ) async {
    _setLoading(true);
    try {
      // 1. 检查是否已存在相同的物种（基于scientific name + common name）
      final existingSpecies = await databaseService.findSpeciesByNames(
        species.scientificName,
        species.commonName,
      );

      String finalSpeciesId;
      
      if (existingSpecies != null) {
        // 物种已存在，更新现有记录
        finalSpeciesId = existingSpecies.id;
        
        // 更新物种信息（可能有新的描述或毒性信息）
        final updatedSpecies = existingSpecies.copyWith(
          description: species.description ?? existingSpecies.description,
          isToxic: species.isToxic ?? existingSpecies.isToxic,
          toxicityInfo: species.toxicityInfo ?? existingSpecies.toxicityInfo,
          updatedAt: DateTime.now(),
        );
        
        await databaseService.updateSpecies(updatedSpecies);
      } else {
        // 新物种，直接创建
        finalSpeciesId = species.id;
        await databaseService.createSpecies(species);
      }

      // 2. 创建新的遇见记录，使用最终的物种ID
      final finalEncounter = encounter.copyWith(
        speciesId: finalSpeciesId,
      );
      
      await databaseService.createEncounter(finalEncounter);

      // 3. 重新加载数据
      await _loadData();
    } catch (e) {
      _setError('Failed to add recognition result: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 统计方法
  int getSpeciesEncounterCount(String speciesId) {
    return _encounters.where((e) => e.speciesId == speciesId).length;
  }

  List<PlantEncounter> getSpeciesEncounters(String speciesId) {
    return _encounters.where((e) => e.speciesId == speciesId).toList()
      ..sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
  }

  DateTime? getSpeciesFirstEncounter(String speciesId) {
    final encounters = getSpeciesEncounters(speciesId);
    if (encounters.isEmpty) return null;
    
    encounters.sort((a, b) => a.encounterDate.compareTo(b.encounterDate));
    return encounters.first.encounterDate;
  }

  DateTime? getSpeciesLastEncounter(String speciesId) {
    final encounters = getSpeciesEncounters(speciesId);
    if (encounters.isEmpty) return null;
    
    encounters.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
    return encounters.first.encounterDate;
  }

  List<PlantEncounter> getEncountersForSpecies(String speciesId) {
    return _encounters.where((e) => e.speciesId == speciesId).toList();
  }

  List<PlantSpecies> getSpeciesWithEncounters() {
    return _species.where((species) => 
      _encounters.any((encounter) => encounter.speciesId == species.id)
    ).toList();
  }
}