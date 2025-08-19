import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/unified_plant_card.dart';
import 'unidentified_plant_detail_screen_v2.dart';
import 'location_debug_screen_v2.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('遇见植物图鉴'),
        actions: [
          // 临时调试按钮
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationDebugScreenV2(),
                ),
              );
            },
          ),
          // 测试新UI按钮
          IconButton(
            icon: const Icon(Icons.preview, color: Colors.purple),
            onPressed: () {
              Navigator.pushNamed(context, '/test-plant-detail');
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => Navigator.pushNamed(context, '/gallery'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading && appState.species.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appState.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => appState.initialize(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final speciesWithEncounters = appState.getSpeciesWithEncounters();
          final unidentifiedEncounters = appState.getUnidentifiedEncounters();
          final totalItems = speciesWithEncounters.length + unidentifiedEncounters.length;
          

          if (totalItems == 0) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 24),
                          Text(
                            '还没有遇见记录',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '点击右下角按钮记录植物遇见',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '植物遇见',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '已识别 ${speciesWithEncounters.length} 种 · 未识别 ${unidentifiedEncounters.length} 个',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '共 ${appState.encounters.length} 次遇见',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,  // 调整为固定比例
                  ),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    // 先显示未识别的，再显示已识别的
                    if (index < unidentifiedEncounters.length) {
                      final encounter = unidentifiedEncounters[index];
                      return UnifiedPlantCard.unidentified(
                        unidentifiedEncounter: encounter,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UnidentifiedPlantDetailScreenV2(
                                encounter: encounter,
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      final speciesIndex = index - unidentifiedEncounters.length;
                      final species = speciesWithEncounters[speciesIndex];
                      final encounters = appState.getEncountersForSpecies(
                        species.id,
                      );
                      // 获取第一张图片
                      String? firstImage;
                      if (encounters.isNotEmpty && encounters.first.photoPaths.isNotEmpty) {
                        firstImage = encounters.first.photoPaths.first;
                      }
                      return UnifiedPlantCard.identified(
                        species: species,
                        encounterCount: encounters.length,
                        firstImagePath: firstImage,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/plant-detail',
                            arguments: species.id,
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/camera'),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('记录遇见'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
