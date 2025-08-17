import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plant_species.dart';
import '../models/plant_encounter.dart';
import '../utils/location_display_helper.dart';

/// 统一的植物卡片组件，确保布局一致
class UnifiedPlantCard extends StatelessWidget {
  // 已识别的植物
  final PlantSpecies? species;
  final int? encounterCount;
  final String? firstImagePath;  // 已识别植物的第一张图片
  
  // 未识别的植物
  final PlantEncounter? unidentifiedEncounter;
  
  final VoidCallback onTap;
  
  // 固定的图片高度比例（相对于卡片宽度）
  static const double imageAspectRatio = 0.75;
  
  const UnifiedPlantCard.identified({
    super.key,
    required PlantSpecies this.species,
    required int this.encounterCount,
    required this.onTap,
    this.firstImagePath,
  }) : unidentifiedEncounter = null;
  
  const UnifiedPlantCard.unidentified({
    super.key,
    required PlantEncounter this.unidentifiedEncounter,
    required this.onTap,
  }) : species = null, encounterCount = null, firstImagePath = null;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图片区域 - 固定高度比例
            AspectRatio(
              aspectRatio: 1 / imageAspectRatio,
              child: _buildImageSection(),
            ),
            
            // 信息区域 - 固定高度
            SizedBox(
              height: 120, // 固定高度，确保对齐
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildInfoSection(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageSection() {
    // 未识别植物的图片
    if (unidentifiedEncounter != null) {
      if (unidentifiedEncounter!.photoPaths.isNotEmpty) {
        return Image.file(
          File(unidentifiedEncounter!.photoPaths.first),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
            icon: Icons.question_mark,
            color: Colors.orange,
          ),
        );
      }
      return _buildPlaceholder(
        icon: Icons.question_mark,
        color: Colors.orange,
      );
    }
    
    // 已识别植物
    if (firstImagePath != null) {
      return Image.file(
        File(firstImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
          icon: Icons.eco,
          color: Colors.green,
        ),
      );
    }
    return _buildPlaceholder(
      icon: Icons.eco,
      color: Colors.green,
    );
  }
  
  Widget _buildPlaceholder({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: color.withOpacity(0.6),
        ),
      ),
    );
  }
  
  Widget _buildInfoSection(BuildContext context) {
    if (unidentifiedEncounter != null) {
      return _buildUnidentifiedInfo(context);
    }
    return _buildIdentifiedInfo(context);
  }
  
  Widget _buildIdentifiedInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 植物名称
        Text(
          species!.commonName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // 学名
        Text(
          species!.scientificName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const Spacer(), // 使用Spacer推送底部内容
        
        // 底部信息行
        Row(
          children: [
            // 遇见次数
            Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '$encounterCount 次遇见',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const Spacer(),
            
            // 毒性标记（如果有）
            if (species!.isToxic == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning,
                      size: 12,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '有毒',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildUnidentifiedInfo(BuildContext context) {
    final dateFormat = DateFormat('MM月dd日');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 名称或默认文字
        Text(
          unidentifiedEncounter!.userDefinedName ?? '未识别的植物',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // 待识别标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '待识别',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const Spacer(), // 使用Spacer推送底部内容
        
        // 底部信息行 - 固定布局
        SizedBox(
          height: 20,  // 固定高度
          child: Row(
            children: [
              // 日期 - 始终显示
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(unidentifiedEncounter!.encounterDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 位置 - 使用智能显示
              Icon(Icons.place, size: 14, 
                color: unidentifiedEncounter!.location != null 
                    ? Colors.grey[600] 
                    : Colors.grey[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getLocationDisplay(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: unidentifiedEncounter!.location != null 
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 获取位置显示文本 - 基于精度智能显示
  String _getLocationDisplay() {
    if (unidentifiedEncounter == null) return '未记录';
    
    // 如果有位置文本，直接使用（已经是处理过的）
    if (unidentifiedEncounter!.location != null && 
        unidentifiedEncounter!.location!.isNotEmpty) {
      // 对于3km精度的位置，通常已经是"城市名"这样的简短显示
      // 提取关键位置信息
      final location = unidentifiedEncounter!.location!;
      
      // 如果是坐标格式，转换为城市显示
      if (location.contains(',') && 
          unidentifiedEncounter!.latitude != null && 
          unidentifiedEncounter!.longitude != null) {
        // 假设3km精度，返回城市名
        return LocationDisplayHelper.getShortDisplay(
          latitude: unidentifiedEncounter!.latitude,
          longitude: unidentifiedEncounter!.longitude,
          accuracy: 3000, // 假设为基站定位精度
        );
      }
      
      // 对于长地址，提取关键部分
      if (location.length > 10) {
        return LocationDisplayHelper.getShortDisplay(
          latitude: unidentifiedEncounter!.latitude,
          longitude: unidentifiedEncounter!.longitude,
          accuracy: null,
          address: location,
        );
      }
      
      return location;
    }
    
    // 如果只有坐标
    if (unidentifiedEncounter!.latitude != null && 
        unidentifiedEncounter!.longitude != null) {
      return LocationDisplayHelper.getShortDisplay(
        latitude: unidentifiedEncounter!.latitude,
        longitude: unidentifiedEncounter!.longitude,
        accuracy: 3000, // 默认假设为基站定位
      );
    }
    
    return '未记录';
  }
}