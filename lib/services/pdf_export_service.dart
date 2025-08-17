import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';

class PDFExportService {
  static final PDFExportService _instance = PDFExportService._internal();
  factory PDFExportService() => _instance;
  PDFExportService._internal();

  Future<File> exportPlantEncyclopedia(
    List<PlantSpecies> species,
    Map<String, List<PlantEncounter>> encountersMap,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy年MM月dd日');

    // 添加封面页
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '遇见植物',
                  style: pw.TextStyle(
                    fontSize: 48,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'PlantMeet',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text('我的植物图鉴', style: pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 20),
                pw.Text(
                  '导出时间: ${dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '共收录 ${species.length} 种植物',
                  style: pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 添加目录页
    if (species.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '目录',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                ...species.asMap().entries.map((entry) {
                  final index = entry.key;
                  final plant = entry.value;
                  final encounters = encountersMap[plant.id] ?? [];

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Text('${index + 1}. '),
                        pw.Expanded(
                          child: pw.Text(
                            '${plant.commonName} (${plant.scientificName})',
                          ),
                        ),
                        pw.Text('${encounters.length}次遇见'),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      );
    }

    // 为每个物种添加详情页
    for (int i = 0; i < species.length; i++) {
      final plant = species[i];
      final encounters = encountersMap[plant.id] ?? [];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 标题
                pw.Text(
                  '${i + 1}. ${plant.commonName}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  plant.scientificName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 16),

                // 基本信息
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '基本信息',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('遇见次数: ${encounters.length}次'),
                      if (encounters.isNotEmpty) ...[
                        pw.Text(
                          '首次遇见: ${dateFormat.format(encounters.last.encounterDate)}',
                        ),
                        pw.Text(
                          '最近遇见: ${dateFormat.format(encounters.first.encounterDate)}',
                        ),
                      ],
                      if (plant.isToxic == true) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '⚠️ 有毒植物',
                          style: pw.TextStyle(color: PdfColors.red),
                        ),
                      ],
                    ],
                  ),
                ),

                // 描述
                if (plant.description != null) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    '植物简介',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(plant.description!),
                ],

                // 毒性信息
                if (plant.toxicityInfo != null) ...[
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      border: pw.Border.all(color: PdfColors.red),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '毒性信息',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          plant.toxicityInfo!,
                          style: pw.TextStyle(color: PdfColors.red800),
                        ),
                      ],
                    ),
                  ),
                ],

                // 遇见记录
                if (encounters.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    '遇见记录',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...encounters.take(10).map((encounter) {
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                dateFormat.format(encounter.encounterDate),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                _getRecognitionMethodText(encounter.method),
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          if (encounter.location != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('地点: ${encounter.location}'),
                          ],
                          if (encounter.notes != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('备注: ${encounter.notes}'),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  if (encounters.length > 10) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '... 还有 ${encounters.length - 10} 条记录',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      );
    }

    // 添加统计页
    final totalEncounters = encountersMap.values.fold<int>(
      0,
      (sum, encounters) => sum + encounters.length,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '统计信息',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('总计识别植物种类: ${species.length} 种'),
                    pw.SizedBox(height: 8),
                    pw.Text('总计遇见记录: $totalEncounters 次'),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '平均每种植物遇见: ${(totalEncounters / species.length.clamp(1, double.infinity)).toStringAsFixed(1)} 次',
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      '导出时间: ${DateFormat('yyyy年MM月dd日 HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '由PlantMeet生成',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // 保存PDF文件
    final output = await getApplicationDocumentsDirectory();
    final fileName =
        'PlantMeet_植物图鉴_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  String _getRecognitionMethodText(RecognitionMethod method) {
    switch (method) {
      case RecognitionMethod.local:
        return '本地识别';
      case RecognitionMethod.cloud:
        return '云端识别';
      case RecognitionMethod.embedded:
        return '内置模型';
      case RecognitionMethod.hybrid:
        return '智能识别';
      case RecognitionMethod.manual:
        return '手动添加';
      case RecognitionMethod.none:
        return '未识别';
    }
  }

  Future<File> exportQuickSummary(
    List<PlantSpecies> species,
    Map<String, List<PlantEncounter>> encountersMap,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy年MM月dd日');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '植物图鉴速览',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('导出时间: ${dateFormat.format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '中文名',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '学名',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '遇见次数',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '状态',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...species.map((plant) {
                    final encounters = encountersMap[plant.id] ?? [];
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(plant.commonName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(plant.scientificName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${encounters.length}次'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(plant.isToxic == true ? '有毒' : ''),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final fileName =
        'PlantMeet_速览_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
