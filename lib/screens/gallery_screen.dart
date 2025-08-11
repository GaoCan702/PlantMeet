import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_state.dart';
import '../services/pdf_export_service.dart';
import '../models/index.dart';
import '../widgets/copyable_error_message.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final PDFExportService _pdfService = PDFExportService();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出与分享'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final species = appState.species;
          final encounters = appState.encounters;

          // 构建遇见映射
          final encountersMap = <String, List<PlantEncounter>>{};
          for (final encounter in encounters) {
            if (!encountersMap.containsKey(encounter.speciesId)) {
              encountersMap[encounter.speciesId] = [];
            }
            encountersMap[encounter.speciesId]!.add(encounter);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 统计信息卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '我的植物图鉴',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatisticItem(
                                icon: Icons.eco,
                                label: '植物种类',
                                value: '${species.length}',
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _StatisticItem(
                                icon: Icons.visibility,
                                label: '遇见次数',
                                value: '${encounters.length}',
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        if (species.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatisticItem(
                                  icon: Icons.warning,
                                  label: '有毒植物',
                                  value: '${species.where((s) => s.isToxic == true).length}',
                                  color: Colors.orange,
                                ),
                              ),
                              Expanded(
                                child: _StatisticItem(
                                  icon: Icons.trending_up,
                                  label: '平均遇见',
                                  value: '${(encounters.length / species.length).toStringAsFixed(1)}',
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 导出选项
                Text(
                  'PDF导出',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                if (species.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.eco,
                              size: 48,
                              color: Colors.green.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '还没有识别任何植物',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '去识别一些植物后再来导出图鉴吧！',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _ExportOptionCard(
                    icon: Icons.picture_as_pdf,
                    title: '完整图鉴',
                    subtitle: '包含所有植物的详细信息、遇见记录和统计',
                    isLoading: _isExporting,
                    onTap: () => _exportDetailedPDF(species, encountersMap),
                  ),
                  const SizedBox(height: 12),
                  _ExportOptionCard(
                    icon: Icons.list_alt,
                    title: '快速速览',
                    subtitle: '植物清单表格，适合快速查看和打印',
                    isLoading: _isExporting,
                    onTap: () => _exportSummaryPDF(species, encountersMap),
                  ),
                ],

                const SizedBox(height: 24),

                // 提示信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'PDF文件将保存到设备存储中，您可以通过文件管理器查看或分享给朋友。',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportDetailedPDF(
    List<PlantSpecies> species,
    Map<String, List<PlantEncounter>> encountersMap,
  ) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final file = await _pdfService.exportPlantEncyclopedia(species, encountersMap);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF已导出: ${file.path.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '分享',
              textColor: Colors.white,
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: '导出失败: $e',
          title: '导出错误',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportSummaryPDF(
    List<PlantSpecies> species,
    Map<String, List<PlantEncounter>> encountersMap,
  ) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final file = await _pdfService.exportQuickSummary(species, encountersMap);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF已导出: ${file.path.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '分享',
              textColor: Colors.white,
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          message: '导出失败: $e',
          title: '导出错误',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}