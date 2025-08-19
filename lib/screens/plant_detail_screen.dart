import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_species.dart';
import '../models/plant_encounter.dart';
import '../services/app_state.dart';
import '../services/share_service.dart';

class PlantDetailScreen extends StatelessWidget {
  final String speciesId;

  const PlantDetailScreen({super.key, required this.speciesId});
  
  void _showMoreOptions(BuildContext context, PlantSpecies species, List<PlantEncounter> encounters) {
    if (encounters.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          20, 
          20, 
          20, 
          20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '更多操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 分享按钮
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('分享植物'),
              subtitle: const Text('分享最近的遇见记录'),
              onTap: () {
                Navigator.pop(context);
                // 分享最近的一条记录
                if (encounters.isNotEmpty) {
                  ShareService.shareEncounter(
                    encounter: encounters.first,
                    species: species,
                    context: context,
                  );
                }
              },
            ),
            
            const Divider(),
            
            // 纠错按钮
            ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.orange),
              title: const Text('识别错误？'),
              subtitle: Text('将${encounters.length}条记录移到正确的植物下'),
              onTap: () {
                Navigator.pop(context);
                _mergeToDifferentSpecies(context, encounters);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _mergeToDifferentSpecies(BuildContext context, List<PlantEncounter> encounters) {
    final appState = Provider.of<AppState>(context, listen: false);
    final otherSpecies = appState.species.where((s) => s.id != speciesId).toList();
    
    if (otherSpecies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有其他植物可以归类')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '选择正确的植物',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: otherSpecies.length,
                itemBuilder: (context, index) {
                  final species = otherSpecies[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(species.commonName.substring(0, 1)),
                    ),
                    title: Text(species.commonName),
                    subtitle: Text(species.scientificName),
                    onTap: () async {
                      Navigator.pop(context);
                      
                      // 批量更新所有记录
                      for (final encounter in encounters) {
                        await appState.mergeEncounterToSpecies(
                          encounter.id, 
                          species.id,
                        );
                      }
                      
                      // 刷新数据以确保UI更新
                      await appState.refreshData();
                      
                      if (!context.mounted) return;
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已将${encounters.length}条记录归类到${species.commonName}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // 返回主页
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('植物详情'),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              final species = appState.species.firstWhere(
                (s) => s.id == speciesId,
                orElse: () => PlantSpecies(
                  id: '',
                  scientificName: '',
                  commonName: '未知植物',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              final encounters = appState.getEncountersForSpecies(speciesId);
              if (encounters.isEmpty) return const SizedBox();
              
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMoreOptions(context, species, encounters),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final species = appState.species.firstWhere(
            (s) => s.id == speciesId,
            orElse: () => PlantSpecies(
              id: '',
              scientificName: '',
              commonName: '未知植物',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final encounters = appState.getEncountersForSpecies(speciesId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          species.commonName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          species.scientificName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                        ),
                        if (species.isToxic == true) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    species.toxicityInfo ?? '该植物有毒，请小心处理',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (species.description != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            '简介',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            species.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '遇见记录',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${encounters.length} 次记录',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (encounters.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无遇见记录',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: encounters.length,
                    itemBuilder: (context, index) {
                      final encounter = encounters[index];
                      return ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(
                          '${encounter.encounterDate.year}-${encounter.encounterDate.month.toString().padLeft(2, '0')}-${encounter.encounterDate.day.toString().padLeft(2, '0')}',
                        ),
                        subtitle: encounter.location != null
                            ? Text(encounter.location!)
                            : null,
                        trailing: Text('${encounter.photoPaths.length} 张照片'),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
