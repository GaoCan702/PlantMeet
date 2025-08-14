import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_species.dart';
import '../services/app_state.dart';

class PlantDetailScreen extends StatelessWidget {
  final String speciesId;

  const PlantDetailScreen({super.key, required this.speciesId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('植物详情')),
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
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(
                            '${encounter.encounterDate.year}-${encounter.encounterDate.month.toString().padLeft(2, '0')}-${encounter.encounterDate.day.toString().padLeft(2, '0')}',
                          ),
                          subtitle: encounter.location != null
                              ? Text(encounter.location!)
                              : null,
                          trailing: Text('${encounter.photoPaths.length} 张照片'),
                        ),
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
