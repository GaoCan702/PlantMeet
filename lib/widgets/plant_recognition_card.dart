import 'package:flutter/material.dart';
import '../models/recognition_result.dart';

/// 生活化的植物识别结果展示卡片
class PlantRecognitionCard extends StatelessWidget {
  final RecognitionResult result;
  final bool showDetails;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const PlantRecognitionCard({
    super.key,
    required this.result,
    this.showDetails = false,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主要识别结果
              _buildMainResult(theme),

              if (showDetails) ...[
                const SizedBox(height: 16),
                _buildDetails(theme),
              ],

              const SizedBox(height: 12),
              _buildActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainResult(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 植物图标
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.eco,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // 植物名称和置信度
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildConfidenceBadge(theme),
                ],
              ),

              if (result.nickname != null)
                Text(
                  '别名：${result.nickname}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

              const SizedBox(height: 4),
              Text(
                result.description,
                style: theme.textTheme.bodyMedium,
                maxLines: showDetails ? null : 2,
                overflow: showDetails ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(ThemeData theme) {
    final color = _getConfidenceColor(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        result.confidenceText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getConfidenceColor(ThemeData theme) {
    if (result.confidence >= 0.8) return Colors.green;
    if (result.confidence >= 0.6) return Colors.blue;
    if (result.confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 极简模式：只显示基本的安全提醒（无具体分析）
        _buildSafetyInfo(theme),

        // 只有当有实际特征时才显示
        if (result.features.isNotEmpty && !_isGemmaMinimalFeatures()) ...[
          const SizedBox(height: 12),
          _buildFeatures(theme),
        ],

        // 只有当有具体位置信息时才显示生活信息
        if (result.locations.isNotEmpty || result.season != null) ...[
          const SizedBox(height: 12),
          _buildLifeInfo(theme),
        ],

        // 养护建议（如果有）
        if (result.care != null) ...[
          const SizedBox(height: 12),
          _buildCareInfo(theme),
        ],

        // 有趣知识
        if (result.funFact != null) ...[
          const SizedBox(height: 12),
          _buildFunFact(theme),
        ],

        // 对于Gemma极简输出，显示额外说明
        if (_isGemmaMinimalOutput()) ...[
          const SizedBox(height: 12),
          _buildMinimalOutputNotice(theme),
        ],
      ],
    );
  }

  /// 检查是否是Gemma模型的极简输出
  bool _isGemmaMinimalOutput() {
    return result.tags.any((tag) => tag.contains('Gemma')) &&
           result.features.isEmpty &&
           result.locations.isEmpty &&
           result.care == null &&
           result.funFact == null;
  }

  /// 检查是否是Gemma模型的占位特征
  bool _isGemmaMinimalFeatures() {
    return result.features.length == 1 && 
           result.features.first.contains('Gemma');
  }

  /// 为极简输出显示友好提醒
  Widget _buildMinimalOutputNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '离线AI识别',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '此结果来自本地AI模型的基础识别。如需更详细信息，建议咨询专业人士或查阅植物百科。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyInfo(ThemeData theme) {
    final safety = result.safety;
    final (icon, color) = _getSafetyIconAndColor(safety.level);

    // 对于Gemma极简输出，显示简化的安全提醒
    if (_isGemmaMinimalOutput()) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '请谨慎处理未知植物，避免直接接触或食用',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 原有的详细安全信息显示
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safety.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (safety.warnings.isNotEmpty)
                  ...safety.warnings.map(
                    (warning) => Text(
                      '• $warning',
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getSafetyIconAndColor(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return (Icons.check_circle, Colors.green);
      case SafetyLevel.caution:
        return (Icons.warning, Colors.orange);
      case SafetyLevel.toxic:
      case SafetyLevel.dangerous:
        return (Icons.dangerous, Colors.red);
      case SafetyLevel.unknown:
        return (Icons.help, Colors.grey);
    }
  }

  Widget _buildFeatures(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关键特征',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: result.features
              .map(
                (feature) => Chip(
                  label: Text(feature, style: theme.textTheme.bodySmall),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLifeInfo(ThemeData theme) {
    return Row(
      children: [
        if (result.season != null)
          Expanded(
            child: _buildInfoItem(
              theme,
              Icons.calendar_today,
              '常见季节',
              result.season!,
            ),
          ),
        if (result.locations.isNotEmpty)
          Expanded(
            child: _buildInfoItem(
              theme,
              Icons.place,
              '常见地点',
              result.locations.join('、'),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildCareInfo(ThemeData theme) {
    final care = result.care!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '养护建议',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCareItem(
                theme,
                '难度',
                care.difficulty,
                Icons.fitness_center,
              ),
            ),
            Expanded(
              child: _buildCareItem(theme, '浇水', care.water, Icons.water_drop),
            ),
            Expanded(
              child: _buildCareItem(theme, '光照', care.light, Icons.wb_sunny),
            ),
          ],
        ),
        if (care.tips.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...care.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(tip, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCareItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFunFact(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '有趣小知识',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(result.funFact!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        // 标签展示
        if (result.tags.isNotEmpty)
          Expanded(
            child: Wrap(
              spacing: 4,
              children: result.tags
                  .take(3)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // 操作按钮
        if (onSave != null)
          TextButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_add, size: 18),
            label: const Text('保存'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),

        if (!showDetails && onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('查看详情'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }
}

/// 识别结果列表展示
class RecognitionResultsList extends StatelessWidget {
  final RecognitionResponse response;
  final Function(RecognitionResult)? onResultTap;
  final Function(RecognitionResult)? onResultSave;

  const RecognitionResultsList({
    super.key,
    required this.response,
    this.onResultTap,
    this.onResultSave,
  });

  @override
  Widget build(BuildContext context) {
    if (!response.success) {
      return _buildErrorCard(context);
    }

    if (response.results.isEmpty) {
      return _buildEmptyCard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 识别方法说明
        _buildMethodInfo(context),

        const SizedBox(height: 8),

        // 最佳匹配
        if (response.bestMatch != null)
          PlantRecognitionCard(
            result: response.bestMatch!,
            showDetails: true,
            onTap: () => onResultTap?.call(response.bestMatch!),
            onSave: () => onResultSave?.call(response.bestMatch!),
          ),

        // 备选结果
        if (response.alternatives.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('其他可能', style: Theme.of(context).textTheme.titleMedium),
          ),
          ...response.alternatives.map(
            (result) => PlantRecognitionCard(
              result: result,
              onTap: () => onResultTap?.call(result),
              onSave: () => onResultSave?.call(result),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMethodInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            response.method.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text('识别失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              response.error ?? '未知错误',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              color: theme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('未找到匹配的植物', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '请尝试从不同角度拍摄，或使用更清晰的照片',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
