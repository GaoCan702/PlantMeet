import 'package:flutter/material.dart';
import '../models/embedded_model.dart';

class ModelStatusCard extends StatelessWidget {
  final ModelStatus status;
  final ModelInfo? modelInfo;
  final double downloadProgress;
  final ModelSource? currentSource;

  const ModelStatusCard({
    super.key,
    required this.status,
    this.modelInfo,
    this.downloadProgress = 0.0,
    this.currentSource,
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
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _getStatusDescription(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            if (status == ModelStatus.downloading) ...[
              const SizedBox(height: 16),
              _buildProgressSection(context),
            ],
            if (modelInfo != null) ...[
              const SizedBox(height: 16),
              _buildModelInfoSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color? iconColor;

    switch (status) {
      case ModelStatus.notDownloaded:
        iconData = Icons.cloud_download_outlined;
        iconColor = Colors.grey;
        break;
      case ModelStatus.downloading:
        iconData = Icons.downloading;
        iconColor = Colors.blue;
        break;
      case ModelStatus.downloaded:
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case ModelStatus.loading:
        iconData = Icons.hourglass_empty;
        iconColor = Colors.orange;
        break;
      case ModelStatus.ready:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case ModelStatus.error:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case ModelStatus.updating:
        iconData = Icons.update;
        iconColor = Colors.blue;
        break;
    }

    return Icon(iconData, color: iconColor, size: 32);
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case ModelStatus.notDownloaded:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = '未下载';
        break;
      case ModelStatus.downloading:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        text = '下载中';
        break;
      case ModelStatus.downloaded:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = '已下载';
        break;
      case ModelStatus.loading:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = '加载中';
        break;
      case ModelStatus.ready:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = '就绪';
        break;
      case ModelStatus.error:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        text = '错误';
        break;
      case ModelStatus.updating:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        text = '更新中';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(downloadProgress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (currentSource != null)
              Text(
                _getSourceDisplayName(currentSource!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: downloadProgress,
          backgroundColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  Widget _buildModelInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '模型信息',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('名称', modelInfo!.name),
          _buildInfoRow('版本', modelInfo!.version),
          _buildInfoRow('大小', _formatBytes(modelInfo!.sizeBytes)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle() {
    switch (status) {
      case ModelStatus.notDownloaded:
        return '离线AI模型未下载';
      case ModelStatus.downloading:
        return '正在下载模型...';
      case ModelStatus.downloaded:
        return '模型下载完成';
      case ModelStatus.loading:
        return '正在加载模型...';
      case ModelStatus.ready:
        return '模型就绪';
      case ModelStatus.error:
        return '模型错误';
      case ModelStatus.updating:
        return '正在更新模型...';
    }
  }

  String _getStatusDescription() {
    switch (status) {
      case ModelStatus.notDownloaded:
        return '下载后可完全离线识别植物';
      case ModelStatus.downloading:
        return '正在从${currentSource != null ? _getSourceDisplayName(currentSource!) : '服务器'}下载';
      case ModelStatus.downloaded:
        return '可以开始离线植物识别';
      case ModelStatus.loading:
        return '正在初始化AI模型';
      case ModelStatus.ready:
        return '可以进行离线植物识别';
      case ModelStatus.error:
        return '模型加载或下载失败';
      case ModelStatus.updating:
        return '正在更新到最新版本';
    }
  }

  String _getSourceDisplayName(ModelSource source) {
    switch (source) {
      case ModelSource.github:
        return 'GitHub';
      case ModelSource.modelScope:
        return 'ModelScope';
      case ModelSource.huggingFace:
        return 'HuggingFace';
      case ModelSource.kaggle:
        return 'Kaggle';
      case ModelSource.google:
        return 'Google';
      case ModelSource.direct:
        return '直链';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}