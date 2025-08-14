import 'package:flutter/material.dart';
import '../models/embedded_model.dart';

class DeviceCompatibilityCard extends StatelessWidget {
  final DeviceCapability? capability;
  final ModelInfo? modelInfo;

  const DeviceCompatibilityCard({super.key, this.capability, this.modelInfo});

  @override
  Widget build(BuildContext context) {
    if (capability == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                '正在检测设备兼容性...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final isCompatible = _checkCompatibility();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompatible ? Icons.verified : Icons.warning,
                  color: isCompatible ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text('设备兼容性', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _buildCompatibilityBadge(context, isCompatible),
              ],
            ),
            const SizedBox(height: 16),
            _buildSpecificationsList(context),
            if (!isCompatible) ...[
              const SizedBox(height: 16),
              _buildRecommendations(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityBadge(BuildContext context, bool isCompatible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompatible ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCompatible ? '兼容' : '部分兼容',
        style: TextStyle(
          color: isCompatible ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSpecificationsList(BuildContext context) {
    return Column(
      children: [
        _buildSpecRow(
          context,
          '内存',
          '${(capability!.ramSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
          _checkRamRequirement(),
          '推荐 4GB+',
        ),
        const SizedBox(height: 8),
        _buildSpecRow(
          context,
          '存储空间',
          '${(capability!.availableStorageBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB 可用',
          _checkStorageRequirement(),
          '需要 4GB+',
        ),
        const SizedBox(height: 8),
        _buildSpecRow(
          context,
          '推理后端',
          _getBackendDisplayName(capability!.recommendedBackend),
          true, // Always true since we adapt to device
          '自动选择',
        ),
        const SizedBox(height: 8),
        _buildSpecRow(
          context,
          '预计性能',
          '${capability!.estimatedInferenceTime.inSeconds}秒/次',
          capability!.estimatedInferenceTime.inSeconds <= 20,
          '≤20秒为佳',
        ),
      ],
    );
  }

  Widget _buildSpecRow(
    BuildContext context,
    String label,
    String value,
    bool passes,
    String requirement,
  ) {
    return Row(
      children: [
        Icon(
          passes ? Icons.check_circle : Icons.warning,
          size: 16,
          color: passes ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            requirement,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '优化建议',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._getRecommendationsList().map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $recommendation',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _checkCompatibility() {
    if (capability == null) return false;

    return _checkRamRequirement() &&
        _checkStorageRequirement() &&
        capability!.estimatedInferenceTime.inSeconds <= 30;
  }

  bool _checkRamRequirement() {
    const minRamBytes = 3 * 1024 * 1024 * 1024; // 3GB minimum
    return capability!.ramSizeBytes >= minRamBytes;
  }

  bool _checkStorageRequirement() {
    const minStorageBytes = 4 * 1024 * 1024 * 1024; // 4GB minimum
    return capability!.availableStorageBytes >= minStorageBytes;
  }

  List<String> _getRecommendationsList() {
    final recommendations = <String>[];

    if (!_checkRamRequirement()) {
      recommendations.add('关闭其他应用以释放内存');
      recommendations.add('重启设备后重试');
    }

    if (!_checkStorageRequirement()) {
      recommendations.add('清理设备存储空间');
      recommendations.add('删除不必要的文件和应用');
    }

    if (capability!.estimatedInferenceTime.inSeconds > 20) {
      recommendations.add('首次推理可能较慢，后续会加快');
      recommendations.add('确保设备电量充足');
    }

    if (!capability!.isHighEnd) {
      recommendations.add('考虑在WiFi环境下使用以获得更好体验');
      recommendations.add('可选择使用云端识别作为补充');
    }

    return recommendations;
  }

  String _getBackendDisplayName(InferenceBackend backend) {
    switch (backend) {
      case InferenceBackend.cpu:
        return 'CPU 推理';
      case InferenceBackend.gpu:
        return 'GPU 加速';
      case InferenceBackend.auto:
        return '自动选择';
    }
  }
}
