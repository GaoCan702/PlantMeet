import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../services/app_state.dart';
import '../services/recognition_service.dart';
import '../services/embedded_model_service.dart';
import '../services/share_service.dart';

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
  late RecognitionService _recognitionService;
  bool _isIdentifying = false;
  
  @override
  void initState() {
    super.initState();
    // 使用 Provider 提供的单例服务
    _recognitionService = Provider.of<RecognitionService>(context, listen: false);
    
    // 刷新识别服务状态，确保模型已加载
    _initializeRecognitionService();
  }
  
  Future<void> _initializeRecognitionService() async {
    await _recognitionService.refreshStatus();
  }
  
  Future<void> _tryIdentify() async {
    print('🌱[植物识别] === 开始植物识别流程 ===');
    
    if (widget.encounter.photoPaths.isEmpty) {
      print('❌[植物识别] 没有照片可用于识别');
      _showError('没有照片可用于识别');
      return;
    }
    
    print('📷[植物识别] 找到照片: ${widget.encounter.photoPaths.first}');
    
    setState(() {
      _isIdentifying = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final settings = appState.settings ?? AppSettings();
      final imageFile = File(widget.encounter.photoPaths.first);
      
      print('📁[植物识别] 图片文件路径: ${imageFile.path}');
      print('📏[植物识别] 图片文件是否存在: ${await imageFile.exists()}');
      
      if (await imageFile.exists()) {
        final fileSize = await imageFile.length();
        print('📐[植物识别] 图片文件大小: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      }
      
      print('⚙️[植物识别] 识别设置:');
      print('   - 首选方法: ${settings.preferredRecognitionMethod}');
      print('   - 回退顺序: ${settings.recognitionMethodFallbackOrder}');
      print('   - 云端配置: ${settings.isConfigured}');
      
      final stopwatch = Stopwatch()..start();
      print('🚀[植物识别] 调用 RecognitionService.identifyPlant()...');
      
      // 直接使用 RecognitionService，让它处理所有的回退逻辑
      final response = await _recognitionService.identifyPlant(
        imageFile,
        settings,
      );
      
      stopwatch.stop();
      print('⏱️[植物识别] 识别耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('📋[植物识别] 识别响应:');
      print('   - 成功: ${response.success}');
      print('   - 使用方法: ${response.method}');
      print('   - 结果数量: ${response.results.length}');
      
      if (!response.success) {
        print('❌[植物识别] 识别失败: ${response.error}');
        _showError('识别失败: ${response.error}');
        return;
      }
      
      if (response.results.isEmpty) {
        print('⚠️[植物识别] 未能识别出植物种类');
        _showError('未能识别出植物种类');
        return;
      }
      
      // 打印识别结果详情
      for (int i = 0; i < response.results.length; i++) {
        final result = response.results[i];
        print('🌿[植物识别] 结果 ${i + 1}:');
        print('   - 名称: ${result.name}');
        print('   - 置信度: ${result.confidence}');
        print('   - 描述: ${result.description}');
        print('   - 学名: ${result.scientificName ?? "无"}');
        print('   - 标签: ${result.tags}');
      }
      
      // 直接显示最佳结果
      if (mounted) {
        print('✅[植物识别] 显示识别结果给用户');
        _showIdentificationResult(response.results.first);
      }
      
    } catch (e, stackTrace) {
      print('💥[植物识别] 识别异常: $e');
      print('📍[植物识别] 堆栈跟踪: $stackTrace');
      _showError('识别出错: $e');
    } finally {
      setState(() {
        _isIdentifying = false;
      });
      print('🏁[植物识别] === 植物识别流程结束 ===');
    }
  }
  
  void _showIdentificationResult(RecognitionResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
          children: [
            // 简单的标题
            Text(
              '这可能是',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // 植物名称
            Text(
              result.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 简短描述
            Text(
              result.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // 两个简单按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSimpleCorrectionOptions();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('不对'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _acceptIdentification(result);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('对的'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _acceptIdentification(RecognitionResult result) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final now = DateTime.now();
      
      // 创建植物物种 - 适配极简结构化输出
      final species = PlantSpecies(
        id: result.id,
        scientificName: result.scientificName ?? result.name, // 如果没有学名，用植物名称
        commonName: result.name,
        description: result.description,
        isToxic: false, // 极简输出不提供具体毒性分析，默认为否
        toxicityInfo: null, // 极简输出不提供毒性信息
        createdAt: now,
        updatedAt: now,
      );
      
      // 使用新的更新方法，避免创建重复记录
      await appState.updateUnidentifiedToIdentified(species, widget.encounter);
      
      // 刷新数据以确保UI更新
      await appState.refreshData();
      
      if (!context.mounted) return;
      
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
  
  Future<void> _showMergeDialog(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final species = appState.species;
    
    if (species.isEmpty) {
      _showError('还没有已识别的植物，请先识别一些植物');
      return;
    }
    
    String? selectedSpeciesId;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择要归类到的植物',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: species.length,
                  itemBuilder: (context, index) {
                    final plant = species[index];
                    final encounterCount = appState.getEncountersForSpecies(plant.id).length;
                    
                    return RadioListTile<String>(
                      value: plant.id,
                      groupValue: selectedSpeciesId,
                      onChanged: (value) {
                        setState(() {
                          selectedSpeciesId = value;
                        });
                      },
                      title: Text(plant.commonName),
                      subtitle: Text(
                        plant.scientificName.isNotEmpty 
                            ? plant.scientificName 
                            : '已记录 $encounterCount 次',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      secondary: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            plant.commonName.isNotEmpty ? plant.commonName.substring(0, 1) : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: selectedSpeciesId == null
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _mergeToSpecies(selectedSpeciesId!);
                          },
                    child: const Text('确认归类'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _mergeToSpecies(String targetSpeciesId) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.mergeEncounterToSpecies(widget.encounter.id, targetSpeciesId);
      
      // 刷新数据以确保UI更新
      await appState.refreshData();
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('植物已成功归类'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 返回主页
      Navigator.pop(context);
    } catch (e) {
      _showError('归类失败: $e');
    }
  }
  
  void _showSimpleCorrectionOptions() {
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
          children: [
            const Text(
              '选择正确的植物',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 从已有植物选择
            ListTile(
              leading: const Icon(Icons.local_florist),
              title: const Text('从我的植物中选择'),
              subtitle: const Text('选择一个已识别的植物'),
              onTap: () {
                Navigator.pop(context);
                _showMergeDialog(context);
              },
            ),
            
            const Divider(),
            
            // 手动输入
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('手动输入'),
              subtitle: const Text('输入植物名称'),
              onTap: () {
                Navigator.pop(context);
                _showManualInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showManualInputDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动输入植物信息'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '植物名称',
                  hintText: '例如：向日葵',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  hintText: '描述这个植物的特征',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入植物名称')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.trim().isNotEmpty) {
      // 创建手动输入的植物
      final appState = Provider.of<AppState>(context, listen: false);
      final now = DateTime.now();
      final species = PlantSpecies(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        scientificName: nameController.text.trim(),
        commonName: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty 
            ? '用户手动输入的植物' 
            : descriptionController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      
      await appState.updateUnidentifiedToIdentified(species, widget.encounter);
      
      // 刷新数据以确保UI更新
      await appState.refreshData();
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('植物信息已保存'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('植物详情'),
        actions: [
          // 分享按钮
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ShareService.shareEncounter(
                encounter: widget.encounter,
                species: null, // 未识别的植物没有species
                context: context,
              );
            },
          ),
        ],
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
            
            // 归类按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showMergeDialog(context),
                icon: const Icon(Icons.merge),
                label: const Text('归类到已有植物'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 识别按钮
            Consumer<EmbeddedModelService>(
              builder: (context, embeddedService, child) {
                final isModelLoading = embeddedService.isModelLoading;
                final isRecognitionInProgress = embeddedService.isRecognitionInProgress;
                final isAnyProcessing = _isIdentifying || isModelLoading || isRecognitionInProgress;
                
                String buttonText;
                if (isModelLoading) {
                  buttonText = '模型加载中...';
                } else if (isRecognitionInProgress) {
                  buttonText = '识别中...';
                } else if (_isIdentifying) {
                  buttonText = '初始化中...';
                } else {
                  buttonText = '使用AI识别植物';
                }
                
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isAnyProcessing ? null : _tryIdentify,
                    icon: isAnyProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.orange.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⏰ 初次使用模型加载较慢，请耐心等待1-3分钟',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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