import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/embedded_model.dart';
import '../services/embedded_model_service.dart';

class EmbeddedModelManagerScreen extends StatelessWidget {
  const EmbeddedModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('离线AI模型'), elevation: 0),
      body: Consumer<EmbeddedModelService>(
        builder: (context, modelService, child) {
          return RefreshIndicator(
            onRefresh: () => modelService.initialize(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainSection(context, modelService),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(context, modelService),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 主要内容区域 - 根据状态显示不同内容
  Widget _buildMainSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header 始终显示
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemma 3 Nano E4B',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _getStatusDescription(modelService),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getStatusColor(context, modelService),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 根据状态显示不同内容
            _buildStatusContent(context, modelService),
          ],
        ),
      ),
    );
  }

  /// 获取状态描述
  String _getStatusDescription(EmbeddedModelService modelService) {
    switch (modelService.state.status) {
      case ModelStatus.notDownloaded:
        return '4.1GB 离线AI模型，点击下载';
      case ModelStatus.downloading:
        return '下载中 ${(modelService.downloadProgress * 100).toStringAsFixed(1)}%';
      case ModelStatus.downloaded:
        return '已下载，点击开始聊天';
      case ModelStatus.loading:
        return '模型加载中...';
      case ModelStatus.ready:
        return '模型就绪，可以使用了！';
      case ModelStatus.error:
        return '发生错误，点击重试';
      case ModelStatus.updating:
        return '更新中...';
    }
  }
  
  /// 获取状态颜色
  Color _getStatusColor(BuildContext context, EmbeddedModelService modelService) {
    switch (modelService.state.status) {
      case ModelStatus.notDownloaded:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case ModelStatus.downloading:
        return Colors.blue.shade600;
      case ModelStatus.downloaded:
        return Colors.green.shade600;
      case ModelStatus.loading:
        return Colors.orange.shade600;
      case ModelStatus.ready:
        return Colors.green.shade700;
      case ModelStatus.error:
        return Colors.red.shade600;
      case ModelStatus.updating:
        return Colors.blue.shade600;
    }
  }
  
  /// 根据状态显示相应内容
  Widget _buildStatusContent(BuildContext context, EmbeddedModelService modelService) {
    switch (modelService.state.status) {
      case ModelStatus.notDownloaded:
        return _buildDownloadContent(context, modelService);
      case ModelStatus.downloading:
        return _buildDownloadingContent(context, modelService);
      case ModelStatus.downloaded:
      case ModelStatus.loading:
      case ModelStatus.ready:
        return _buildReadyContent(context, modelService);
      case ModelStatus.error:
        return _buildErrorContent(context, modelService);
      case ModelStatus.updating:
        return _buildUpdatingContent(context, modelService);
    }
  }

  /// 未下载状态 - 简洁下载按钮
  Widget _buildDownloadContent(BuildContext context, EmbeddedModelService modelService) {
    return Column(
      children: [
        // 特性标签
        Wrap(
          spacing: 8,
          children: [
            _buildFeatureChip('🚀 完全离线', Colors.green),
            _buildFeatureChip('🔒 隐私保护', Colors.blue),
            _buildFeatureChip('📱 端侧推理', Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        // 主下载按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: modelService.deviceCapability != null
                ? () => _startDownload(context, modelService)
                : null,
            icon: const Icon(Icons.download),
            label: const Text('下载模型 (4.1GB)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 设置入口
        TextButton.icon(
          onPressed: () => _showDownloadSettings(context),
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('下载设置'),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
  
  /// 下载中状态 - 简化控制
  Widget _buildDownloadingContent(BuildContext context, EmbeddedModelService modelService) {
    return Column(
      children: [
        // 进度条
        LinearProgressIndicator(
          value: modelService.downloadProgress,
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 12),
        // 状态信息
        if (modelService.downloadStatus.isNotEmpty)
          Text(
            modelService.downloadStatus,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        // 控制按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: modelService.isDownloadPaused 
                  ? () => modelService.resumeDownload()
                  : () => modelService.pauseDownload(),
                icon: Icon(modelService.isDownloadPaused 
                  ? Icons.play_arrow 
                  : Icons.pause),
                label: Text(modelService.isDownloadPaused ? '继续' : '暂停'),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _confirmCancelDownload(context, modelService),
              child: const Text('取消'),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 已下载/就绪状态 - 主要操作
  Widget _buildReadyContent(BuildContext context, EmbeddedModelService modelService) {
    return Column(
      children: [
        // 主要操作按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/model-chat-test'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('开始AI聊天'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 错误状态 - 重试操作
  Widget _buildErrorContent(BuildContext context, EmbeddedModelService modelService) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(
            modelService.errorMessage ?? '未知错误',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => modelService.initialize(),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showErrorHelp(context, modelService),
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text('帮助'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 更新状态 - 简单提示
  Widget _buildUpdatingContent(BuildContext context, EmbeddedModelService modelService) {
    return const Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('正在更新模型...'),
      ],
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }







  Widget _buildAdvancedSection(
    BuildContext context,
    EmbeddedModelService modelService,
  ) {
    return ExpansionTile(
      title: const Text('高级选项'),
      leading: const Icon(Icons.settings),
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('存储管理'),
                subtitle: const Text('查看模型文件占用空间'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStorageInfo(context, modelService),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('设备兼容性'),
                subtitle: const Text('查看设备性能和支持情况'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCompatibilityInfo(context, modelService),
              ),
              if (modelService.isModelDownloaded) ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red.shade600),
                  title: Text(
                    '删除模型',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  subtitle: const Text('释放存储空间，可重新下载'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmDeleteModel(context, modelService),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  /// 显示下载设置对话框
  Future<void> _showDownloadSettings(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool allowBackground = prefs.getBool('allow_background_download') ?? false;
    bool wifiOnly = prefs.getBool('wifi_only_download') ?? true;
    bool autoPauseLowBattery = prefs.getBool('auto_pause_low_battery') ?? true;

    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('下载设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('后台下载'),
                subtitle: const Text('允许切换应用时继续下载'),
                value: allowBackground,
                onChanged: (v) {
                  setState(() => allowBackground = v);
                  prefs.setBool('allow_background_download', v);
                },
              ),
              SwitchListTile(
                title: const Text('仅WiFi下载'),
                subtitle: const Text('使用移动网络时暂停'),
                value: wifiOnly,
                onChanged: (v) {
                  setState(() => wifiOnly = v);
                  prefs.setBool('wifi_only_download', v);
                },
              ),
              SwitchListTile(
                title: const Text('低电量暂停'),
                subtitle: const Text('电量≤15%时自动暂停'),
                value: autoPauseLowBattery,
                onChanged: (v) {
                  setState(() => autoPauseLowBattery = v);
                  prefs.setBool('auto_pause_low_battery', v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  /// 确认取消下载
  Future<void> _confirmCancelDownload(BuildContext context, EmbeddedModelService modelService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消下载'),
        content: const Text('确定要取消下载吗？已下载的部分将保留，可以稍后继续。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续下载'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      modelService.cancelDownload();
    }
  }

  /// 显示设备兼容性信息
  Future<void> _showCompatibilityInfo(BuildContext context, EmbeddedModelService modelService) async {
    final compatibilityReport = await modelService.getCompatibilityReport();
    
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备兼容性'),
        content: SingleChildScrollView(
          child: Text(compatibilityReport),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    await modelService.downloadModel();
  }


  Future<void> _showStorageInfo(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    final stats = await modelService.getModelStats();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('存储信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模型大小：${_formatFileSize((stats['model_size_bytes'] ?? 0).toDouble())}'),
            const SizedBox(height: 8),
            Text('存储路径：应用私有目录'),
            const SizedBox(height: 8),
            Text('状态：${_getStatusDisplayName(modelService.state.status)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteModel(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    // 获取模型统计信息
    final stats = await modelService.getModelStats();
    final modelSizeBytes = (stats['model_size_bytes'] ?? 0) as int;
    
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('确认删除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('确定要删除离线AI模型吗？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, size: 16, color: Colors.red.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '将释放存储空间：${_formatFileSize(modelSizeBytes.toDouble())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• 删除后需要重新下载才能使用离线识别',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                  Text(
                    '• 重新下载需要约2.5GB流量',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await modelService.deleteModel();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('模型已删除')));
      }
    }
  }

  Future<void> _showErrorHelp(
    BuildContext context,
    EmbeddedModelService modelService,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('常见问题解决方案：'),
              SizedBox(height: 16),
              Text('1. 网络连接问题'),
              Text('   • 检查网络连接是否正常'),
              Text('   • 尝试切换到WiFi网络'),
              SizedBox(height: 8),
              Text('2. 存储空间不足'),
              Text('   • 清理设备存储空间'),
              Text('   • 确保至少有4GB可用空间'),
              SizedBox(height: 8),
              Text('3. 设备性能限制'),
              Text('   • 关闭其他占用内存的应用'),
              Text('   • 重启设备后重试'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(ModelStatus status) {
    switch (status) {
      case ModelStatus.notDownloaded:
        return '未下载';
      case ModelStatus.downloading:
        return '下载中';
      case ModelStatus.downloaded:
        return '已下载';
      case ModelStatus.loading:
        return '加载中';
      case ModelStatus.ready:
        return '就绪';
      case ModelStatus.error:
        return '错误';
      case ModelStatus.updating:
        return '更新中';
    }
  }

  /// 格式化文件大小显示
  String _formatFileSize(double sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '${sizeInBytes.toStringAsFixed(0)} B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
