import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';

class UnidentifiedPlantDetailScreen extends StatefulWidget {
  final PlantEncounter encounter;
  
  const UnidentifiedPlantDetailScreen({
    super.key,
    required this.encounter,
  });

  @override
  State<UnidentifiedPlantDetailScreen> createState() => _UnidentifiedPlantDetailScreenState();
}

class _UnidentifiedPlantDetailScreenState extends State<UnidentifiedPlantDetailScreen> {
  final RecognitionService _recognitionService = RecognitionService();
  bool _isIdentifying = false;
  
  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _recognitionService.initialize(appState.settings ?? AppSettings());
  }
  
  Future<void> _tryIdentify() async {
    if (widget.encounter.photoPaths.isEmpty) {
      _showError('没有照片可用于识别');
      return;
    }
    
    setState(() {
      _isIdentifying = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final settings = appState.settings ?? AppSettings();
      
      // 检查是否有可用的识别服务
      final availableMethods = _recognitionService.getAvailableMethods();
      if (availableMethods.isEmpty) {
        _showError('没有可用的识别服务，请先在设置中配置');
        return;
      }
      
      final imageFile = File(widget.encounter.photoPaths.first);
      final response = await _recognitionService.identifyPlant(
        imageFile,
        settings,
      );
      
      if (!response.success) {
        _showError('识别失败: ${response.error}');
        return;
      }
      
      if (response.results.isEmpty) {
        _showError('未能识别出植物种类');
        return;
      }
      
      // 显示识别结果对话框
      _showIdentificationResult(response.results.first);
      
    } catch (e) {
      _showError('识别出错: $e');
    } finally {
      setState(() {
        _isIdentifying = false;
      });
    }
  }
  
  void _showIdentificationResult(RecognitionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('识别结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (result.scientificName != null) ...[
              const SizedBox(height: 4),
              Text(
                result.scientificName!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('置信度: ${result.confidenceText}'),
            const SizedBox(height: 12),
            Text(result.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _acceptIdentification(result);
            },
            child: const Text('接受识别结果'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _acceptIdentification(RecognitionResult result) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final now = DateTime.now();
      
      // 创建植物物种
      final species = PlantSpecies(
        id: result.id,
        scientificName: result.scientificName ?? 'Unknown',
        commonName: result.name,
        description: result.description,
        isToxic: result.safety.level == SafetyLevel.toxic,
        toxicityInfo: result.safety.warnings.isNotEmpty
            ? result.safety.warnings.first
            : null,
        createdAt: now,
        updatedAt: now,
      );
      
      // 使用新的更新方法，避免创建重复记录
      await appState.updateUnidentifiedToIdentified(species, widget.encounter);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('植物已成功识别'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 返回主页
      Navigator.pop(context);
      
    } catch (e) {
      _showError('保存识别结果失败: $e');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('植物详情'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 照片展示
            if (widget.encounter.photoPaths.isNotEmpty)
              Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.encounter.photoPaths.first),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 植物名称（用户定义的）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.encounter.userDefinedName ?? '未命名的植物',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '未识别',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.encounter.notes != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.encounter.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 时间和位置信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dateFormat.format(widget.encounter.encounterDate),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    if (widget.encounter.location != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.encounter.location!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 识别按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isIdentifying ? null : _tryIdentify,
                icon: _isIdentifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isIdentifying ? '识别中...' : '尝试AI识别'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI识别可以帮助您了解这是什么植物',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}