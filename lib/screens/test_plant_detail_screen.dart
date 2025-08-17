import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_species.dart';
import '../models/plant_encounter.dart';
import '../models/index.dart';
import '../services/app_state.dart';
import 'plant_detail_screen_v2.dart';

class TestPlantDetailScreen extends StatelessWidget {
  const TestPlantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试植物详情页'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // 创建测试数据
                final appState = Provider.of<AppState>(context, listen: false);
                
                // 创建一个测试物种
                final testSpecies = PlantSpecies(
                  id: 'test_species_001',
                  scientificName: 'Rosa chinensis',
                  commonName: '月季花',
                  description: '月季花是蔷薇科蔷薇属的常绿或半常绿低矮灌木，四季开花，一般为红色、粉色，偶有白色和黄色，可作为观赏植物，也可作为药用植物。月季花自然花期4月-9月，花大型，有香气，广泛用于园艺栽培和切花。',
                  isToxic: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                // 添加物种
                await appState.addSpecies(testSpecies);
                
                // 创建几个遇见记录
                final encounters = [
                  PlantEncounter(
                    id: 'enc_001',
                    speciesId: testSpecies.id,
                    encounterDate: DateTime.now().subtract(const Duration(days: 1)),
                    location: '苏州工业园区金鸡湖畔',
                    latitude: 31.3016,
                    longitude: 120.6985,
                    photoPaths: [],
                    notes: '在湖边散步时发现的，花朵非常漂亮',
                    source: RecognitionSource.camera,
                    method: RecognitionMethod.local,
                    isIdentified: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  PlantEncounter(
                    id: 'enc_002',
                    speciesId: testSpecies.id,
                    encounterDate: DateTime.now().subtract(const Duration(days: 5)),
                    location: '独墅湖图书馆花园',
                    latitude: 31.2743,
                    longitude: 120.7368,
                    photoPaths: [],
                    notes: '图书馆外的花园里有一大片',
                    source: RecognitionSource.camera,
                    method: RecognitionMethod.local,
                    isIdentified: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  PlantEncounter(
                    id: 'enc_003',
                    speciesId: testSpecies.id,
                    encounterDate: DateTime.now().subtract(const Duration(days: 10)),
                    location: '苏州大学',
                    latitude: 31.2989,
                    longitude: 120.6359,
                    photoPaths: [],
                    source: RecognitionSource.camera,
                    method: RecognitionMethod.local,
                    isIdentified: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ];
                
                // 添加遇见记录
                for (final encounter in encounters) {
                  await appState.addEncounter(encounter);
                }
                
                // 导航到详情页
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantDetailScreenV2(
                      speciesId: testSpecies.id,
                    ),
                  ),
                );
              },
              child: const Text('创建测试数据并查看新版详情页'),
            ),
            const SizedBox(height: 20),
            Text(
              '点击按钮将创建一个月季花的测试数据\n并展示新设计的植物详情页',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}