import 'package:flutter/material.dart';
import '../models/embedded_model.dart';

class ModelDownloadProgressCard extends StatelessWidget {
  final double progress;
  final ModelSource? currentSource;
  final int downloadedBytes;
  final int totalBytes;
  final VoidCallback? onCancel;

  const ModelDownloadProgressCard({
    super.key,
    required this.progress,
    this.currentSource,
    required this.downloadedBytes,
    required this.totalBytes,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.downloading,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '正在下载离线AI模型',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onCancel != null)
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    tooltip: '取消下载',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressIndicator(context),
            const SizedBox(height: 12),
            _buildProgressDetails(context),
            const SizedBox(height: 16),
            _buildDownloadSource(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildProgressDetails(BuildContext context) {
    final remainingBytes = totalBytes - downloadedBytes;
    final estimatedTimeMinutes = _estimateRemainingTime(remainingBytes);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '剩余大小',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              _formatBytes(remainingBytes),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '预计剩余时间',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              estimatedTimeMinutes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadSource(BuildContext context) {
    if (currentSource == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_download,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '下载源: ${_getSourceDisplayName(currentSource!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _buildSourceStatusIcon(context),
        ],
      ),
    );
  }

  Widget _buildSourceStatusIcon(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getSourceDisplayName(ModelSource source) {
    switch (source) {
      case ModelSource.github:
        return 'GitHub (开源模型)';
      case ModelSource.modelScope:
        return 'ModelScope (推荐)';
      case ModelSource.huggingFace:
        return 'HuggingFace';
      case ModelSource.kaggle:
        return 'Kaggle';
      case ModelSource.google:
        return 'Google AI';
      case ModelSource.direct:
        return '直链下载';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _estimateRemainingTime(int remainingBytes) {
    // Estimate based on typical download speeds
    // This is a rough estimation - in practice you'd calculate based on actual speed
    const averageSpeedBytesPerSecond = 5 * 1024 * 1024; // 5 MB/s
    
    if (remainingBytes <= 0) return '完成';
    
    final remainingSeconds = remainingBytes / averageSpeedBytesPerSecond;
    
    if (remainingSeconds < 60) {
      return '${remainingSeconds.round()}秒';
    } else if (remainingSeconds < 3600) {
      return '${(remainingSeconds / 60).round()}分钟';
    } else {
      final hours = (remainingSeconds / 3600).floor();
      final minutes = ((remainingSeconds % 3600) / 60).round();
      return '${hours}小时${minutes}分钟';
    }
  }
}