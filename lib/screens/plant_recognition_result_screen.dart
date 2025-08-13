import 'package:flutter/material.dart';
import '../models/recognition_result.dart';
import '../widgets/plant_recognition_card.dart';

/// 植物识别结果页面 - 生活化展示
class PlantRecognitionResultScreen extends StatefulWidget {
  final RecognitionResponse response;
  final String? photoPath;

  const PlantRecognitionResultScreen({
    super.key,
    required this.response,
    this.photoPath,
  });

  @override
  State<PlantRecognitionResultScreen> createState() => _PlantRecognitionResultScreenState();
}

class _PlantRecognitionResultScreenState extends State<PlantRecognitionResultScreen> {
  bool _showAdvancedInfo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('识别结果'),
        actions: [
          if (widget.response.success && widget.response.results.isNotEmpty)
            IconButton(
              onPressed: _shareResult,
              icon: const Icon(Icons.share),
              tooltip: '分享结果',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 原始照片展示
            if (widget.photoPath != null) _buildPhotoSection(),
            
            // 识别结果摘要
            _buildSummarySection(),
            
            // 主要识别结果
            RecognitionResultsList(
              response: widget.response,
              onResultTap: _showPlantDetails,
              onResultSave: _saveToMyGarden,
            ),
            
            // 高级信息切换
            if (widget.response.success && widget.response.results.isNotEmpty)
              _buildAdvancedInfoToggle(),
            
            // 操作建议
            if (widget.response.success) _buildActionSuggestions(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: widget.response.success && widget.response.bestMatch != null
          ? _buildBottomActions()
          : null,
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.photoPath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 64),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'AI识别结果',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.response.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final theme = Theme.of(context);
    final bestMatch = widget.response.bestMatch;
    
    if (bestMatch == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        _buildStatItem(
          theme,
          Icons.verified,
          '置信度',
          bestMatch.confidenceText,
          _getConfidenceColor(bestMatch.confidence),
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          theme,
          Icons.security,
          '安全性',
          _getSafetyText(bestMatch.safety.level),
          _getSafetyColor(bestMatch.safety.level),
        ),
        const SizedBox(width: 16),
        if (bestMatch.care != null)
          _buildStatItem(
            theme,
            Icons.spa,
            '养护',
            bestMatch.care!.difficulty,
            theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedInfoToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: const Text('显示学术信息'),
        subtitle: Text(_showAdvancedInfo ? '隐藏专业分类信息' : '查看学名、科属等专业信息'),
        leading: const Icon(Icons.science),
        onExpansionChanged: (expanded) {
          setState(() {
            _showAdvancedInfo = expanded;
          });
        },
        children: [
          if (_showAdvancedInfo && widget.response.bestMatch != null)
            _buildAdvancedInfo(widget.response.bestMatch!),
        ],
      ),
    );
  }

  Widget _buildAdvancedInfo(RecognitionResult result) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.scientificName != null)
            _buildAdvancedInfoItem('学名', result.scientificName!),
          if (result.family != null)
            _buildAdvancedInfoItem('科属', result.family!),
          _buildAdvancedInfoItem('置信度', '${(result.confidence * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildAdvancedInfoItem(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label：',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSuggestions() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '接下来可以做什么？',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSuggestionCard(
            theme,
            Icons.bookmark_add,
            '保存到我的图鉴',
            '记录这次相遇，建立个人植物档案',
            () => _saveToMyGarden(widget.response.bestMatch!),
          ),
          _buildSuggestionCard(
            theme,
            Icons.camera_alt,
            '拍摄更多角度',
            '从不同角度拍摄，获得更准确的识别结果',
            _retakePhoto,
          ),
          _buildSuggestionCard(
            theme,
            Icons.share,
            '分享给朋友',
            '和朋友分享你的发现',
            _shareResult,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _retakePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('重新拍摄'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _saveToMyGarden(widget.response.bestMatch!),
              icon: const Icon(Icons.bookmark_add),
              label: const Text('保存到图鉴'),
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.blue;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getSafetyText(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return '安全';
      case SafetyLevel.caution:
        return '小心';
      case SafetyLevel.toxic:
        return '有毒';
      case SafetyLevel.dangerous:
        return '危险';
      case SafetyLevel.unknown:
        return '未知';
    }
  }

  Color _getSafetyColor(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return Colors.green;
      case SafetyLevel.caution:
        return Colors.orange;
      case SafetyLevel.toxic:
      case SafetyLevel.dangerous:
        return Colors.red;
      case SafetyLevel.unknown:
        return Colors.grey;
    }
  }

  // 事件处理
  void _showPlantDetails(RecognitionResult result) {
    // TODO: 导航到植物详情页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看 ${result.name} 的详细信息')),
    );
  }

  void _saveToMyGarden(RecognitionResult result) {
    // TODO: 保存到用户的植物图鉴
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.name} 已保存到我的图鉴'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            // TODO: 导航到我的图鉴
          },
        ),
      ),
    );
  }

  void _shareResult() {
    final bestMatch = widget.response.bestMatch;
    if (bestMatch == null) return;
    
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('分享 ${bestMatch.name} 的识别结果')),
    );
  }

  void _retakePhoto() {
    Navigator.of(context).pop();
  }
}