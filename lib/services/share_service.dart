import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/plant_encounter.dart';
import '../models/plant_species.dart';

/// 轻量级分享服务
/// 支持分享植物照片和文字描述
class ShareService {
  /// 分享植物遇见记录
  static Future<void> shareEncounter({
    required PlantEncounter encounter,
    PlantSpecies? species,
    required BuildContext context,
  }) async {
    // 显示简单的分享选项
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分享植物',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 分享照片和文字
            if (encounter.photoPaths.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.image, color: Colors.green),
                title: const Text('分享照片和描述'),
                subtitle: const Text('分享植物照片和详细信息'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePhotoWithText(encounter, species, context);
                },
              ),
            
            // 仅分享文字
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.blue),
              title: const Text('仅分享文字'),
              subtitle: const Text('分享植物的文字描述'),
              onTap: () {
                Navigator.pop(context);
                _shareTextOnly(encounter, species, context);
              },
            ),
            
            const Divider(),
            
            // 取消按钮
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 分享照片和文字
  static Future<void> _sharePhotoWithText(
    PlantEncounter encounter,
    PlantSpecies? species,
    BuildContext context,
  ) async {
    try {
      final text = _generateShareText(encounter, species);
      
      // 分享第一张照片和文字
      final result = await Share.shareXFiles(
        [XFile(encounter.photoPaths.first)],
        text: text,
      );
      
      // 可选：根据分享结果显示提示
      if (result.status == ShareResultStatus.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分享成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 仅分享文字
  static Future<void> _shareTextOnly(
    PlantEncounter encounter,
    PlantSpecies? species,
    BuildContext context,
  ) async {
    try {
      final text = _generateShareText(encounter, species);
      
      final result = await Share.share(text);
      
      // 可选：根据分享结果显示提示
      if (result.status == ShareResultStatus.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分享成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 生成分享文本
  static String _generateShareText(
    PlantEncounter encounter,
    PlantSpecies? species,
  ) {
    final buffer = StringBuffer();
    
    // 植物名称
    final name = species?.commonName ?? 
                 encounter.userDefinedName ?? 
                 '未知植物';
    buffer.writeln('🌿 $name');
    
    // 学名（如果有）
    if (species?.scientificName.isNotEmpty == true) {
      buffer.writeln('学名：${species!.scientificName}');
    }
    
    buffer.writeln();
    
    // 时间
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    buffer.writeln('📅 ${dateFormat.format(encounter.encounterDate)}');
    
    // 位置（如果有）
    if (encounter.location?.isNotEmpty == true) {
      buffer.writeln('📍 ${encounter.location}');
    }
    
    // 备注（如果有）
    if (encounter.notes?.isNotEmpty == true) {
      buffer.writeln();
      buffer.writeln(encounter.notes!);
    }
    
    // 毒性警告（如果有）
    if (species?.isToxic == true) {
      buffer.writeln();
      buffer.writeln('⚠️ 注意：此植物有毒');
      if (species?.toxicityInfo?.isNotEmpty == true) {
        buffer.writeln(species!.toxicityInfo);
      }
    }
    
    buffer.writeln();
    buffer.writeln('—— 分享自 PlantMeet 植物记录 🌱');
    
    return buffer.toString().trim();
  }

  /// 分享多个植物记录的摘要
  static Future<void> shareMultipleEncounters({
    required List<PlantEncounter> encounters,
    required Map<String, PlantSpecies> speciesMap,
    required String title,
    required BuildContext context,
  }) async {
    if (encounters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可分享的记录')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 $title');
    buffer.writeln('=' * 20);
    buffer.writeln();
    
    final dateFormat = DateFormat('MM/dd HH:mm');
    
    for (final encounter in encounters) {
      final species = speciesMap[encounter.speciesId ?? ''];
      final name = species?.commonName ?? 
                   encounter.userDefinedName ?? 
                   '未知植物';
      
      buffer.writeln('🌿 $name');
      buffer.writeln('   ${dateFormat.format(encounter.encounterDate)}');
      if (encounter.location?.isNotEmpty == true) {
        buffer.writeln('   📍 ${encounter.location}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('—— 共 ${encounters.length} 条记录');
    buffer.writeln('—— 分享自 PlantMeet 🌱');
    
    try {
      await Share.share(buffer.toString());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}