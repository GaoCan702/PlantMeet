import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recognition_result.dart';
import '../models/app_settings.dart';
import '../widgets/plant_recognition_card.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';

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
  State<PlantRecognitionResultScreen> createState() =>
      _PlantRecognitionResultScreenState();
}

class _PlantRecognitionResultScreenState
    extends State<PlantRecognitionResultScreen> {
  bool _isReRecognizing = false;
  RecognitionResponse? _currentResponse;

  @override
  void initState() {
    super.initState();
    _currentResponse = widget.response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('识别结果'),
        actions: [
          // 重新识别按钮
          if (widget.photoPath != null)
            IconButton(
              onPressed: _isReRecognizing ? null : _reRecognize,
              icon: _isReRecognizing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: '重新识别',
            ),
          // 分享按钮
          if ((_currentResponse?.success ?? false) && (_currentResponse?.results.isNotEmpty ?? false))
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

            // 简化的识别结果显示
            _buildSimpleResult(),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar:
          _currentResponse!.success && _currentResponse!.bestMatch != null
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
            color: Colors.black.withValues(alpha: 0.1),
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


  /// 简化的识别结果显示
  Widget _buildSimpleResult() {
    if (!_currentResponse!.success) {
      return _buildErrorCard();
    }

    if (_currentResponse!.results.isEmpty) {
      return _buildEmptyCard();
    }

    final result = _currentResponse!.bestMatch!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 植物名称
          Row(
            children: [
              Icon(Icons.eco, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 描述
          Text(
            result.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          // 简单的置信度和提醒
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(result.confidence).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getConfidenceColor(result.confidence).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '置信度: ${result.confidenceText}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getConfidenceColor(result.confidence),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '谨慎处理',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final theme = Theme.of(context);
    final error = _currentResponse!.error ?? '未知错误';
    
    // 检查是否是非植物检测
    final isNonPlant = error.contains('未检测到植物') || error.contains('图片中没有植物');
    
    // 检查是否是超时错误
    final isTimeout = error.contains('超时') || error.contains('timeout');
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNonPlant 
            ? theme.colorScheme.surfaceVariant 
            : isTimeout
                ? Colors.orange.withValues(alpha: 0.1)
                : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isNonPlant 
                ? Icons.search_off 
                : isTimeout 
                    ? Icons.timer
                    : Icons.error_outline,
            color: isNonPlant 
                ? theme.colorScheme.onSurfaceVariant 
                : isTimeout
                    ? Colors.orange
                    : theme.colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isNonPlant 
                ? '未检测到植物' 
                : isTimeout
                    ? '识别超时'
                    : '识别失败',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isNonPlant 
                ? '请确保照片中包含植物，然后重新拍摄' 
                : isTimeout
                    ? '模型初次加载需要较长时间，请重新尝试或稍等片刻'
                    : error,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (isNonPlant) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '提示：AI可以识别花朵、叶子、树木等各种植物',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isTimeout) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '提示：第一次使用时模型需要初始化，通常需要1-3分钟',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, color: theme.colorScheme.onSurfaceVariant, size: 48),
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
    );
  }


  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              onPressed: () => _saveToMyGarden(_currentResponse!.bestMatch!),
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
    // 此功能已在其他页面实现，直接返回
    Navigator.pop(context);
  }

  void _saveToMyGarden(RecognitionResult result) {
    // 植物已通过识别流程自动保存
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('植物已自动保存到记录中'),
      ),
    );
    Navigator.pop(context);
  }

  /// 重新识别功能 - 不走缓存
  Future<void> _reRecognize() async {
    if (widget.photoPath == null || _isReRecognizing) return;

    setState(() {
      _isReRecognizing = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final recognitionService = Provider.of<RecognitionService>(context, listen: false);
      final settings = appState.settings ?? AppSettings();

      final imageFile = File(widget.photoPath!);
      
      // 强制重新识别，不使用缓存
      final response = await recognitionService.identifyPlant(
        imageFile,
        settings,
        // 如果有preferredMethod参数，可以强制使用本地模型
        preferredMethod: RecognitionMethod.embedded,
      );

      if (mounted) {
        setState(() {
          _currentResponse = response;
          _isReRecognizing = false;
        });

        // 显示重新识别的结果提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.success 
                ? '重新识别完成' 
                : '重新识别失败: ${response.error}'),
            backgroundColor: response.success 
                ? Colors.green 
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReRecognizing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重新识别出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareResult() {
    // 分享功能已在植物详情页实现，此处关闭页面
    Navigator.pop(context);
  }

  void _retakePhoto() {
    Navigator.of(context).pop();
  }
}
