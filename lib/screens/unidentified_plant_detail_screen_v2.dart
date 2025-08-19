import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/plant_encounter.dart';
import '../services/app_state.dart';
import '../utils/location_display_helper.dart';
import '../screens/plant_recognition_result_screen.dart';
import '../services/recognition_service.dart';

class UnidentifiedPlantDetailScreenV2 extends StatefulWidget {
  final PlantEncounter encounter;

  const UnidentifiedPlantDetailScreenV2({
    super.key, 
    required this.encounter,
  });

  @override
  State<UnidentifiedPlantDetailScreenV2> createState() => _UnidentifiedPlantDetailScreenV2State();
}

class _UnidentifiedPlantDetailScreenV2State extends State<UnidentifiedPlantDetailScreenV2> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  double _opacity = 0.0;
  bool _isRecognizing = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _nameController.text = widget.encounter.userDefinedName ?? '';
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _opacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startRecognition() async {
    if (widget.encounter.photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('需要至少一张照片才能识别'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isRecognizing = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final recognitionService = Provider.of<RecognitionService>(context, listen: false);
      
      final imageFile = File(widget.encounter.photoPaths.first);
      final result = await recognitionService.identifyPlant(
        imageFile,
        appState.settings!,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlantRecognitionResultScreen(
              response: result,
              photoPath: widget.encounter.photoPaths.first,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('识别出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }

  Future<void> _saveNameChange() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final updatedEncounter = widget.encounter.copyWith(
      userDefinedName: newName,
      updatedAt: DateTime.now(),
    );
    
    await appState.databaseService.updateEncounter(updatedEncounter);
    await appState.initialize();
    
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('名称已更新'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    final displayName = widget.encounter.userDefinedName ?? '未识别的植物';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 自定义的SliverAppBar，带照片背景
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.orange.shade600,
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _opacity,
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图片
                  if (widget.encounter.photoPaths.isNotEmpty)
                    Image.file(
                      File(widget.encounter.photoPaths.first),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade700,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.question_mark,
                          size: 80,
                          color: Colors.white30,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade700,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.question_mark,
                        size: 80,
                        color: Colors.white30,
                      ),
                    ),
                  // 渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // 底部信息
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _isEditing
                                  ? TextField(
                                      controller: _nameController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '给植物起个名字',
                                        hintStyle: TextStyle(
                                          color: Colors.white54,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      autofocus: true,
                                      onSubmitted: (_) => _saveNameChange(),
                                    )
                                  : Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditing ? Icons.check : Icons.edit,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_isEditing) {
                                  _saveNameChange();
                                } else {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '待识别',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI识别卡片
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade50,
                        Colors.blue.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple.shade200,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isRecognizing ? null : _startRecognition,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: _isRecognizing
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.purple.shade600,
                                      ),
                                    )
                                  : Icon(
                                      Icons.auto_awesome,
                                      color: Colors.purple.shade600,
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isRecognizing ? '正在识别中...' : '使用 AI 识别植物',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isRecognizing 
                                        ? '请稍候，AI 正在分析图片'
                                        : '点击开始智能识别，获取植物信息',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.purple.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 基本信息
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '遇见信息',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 信息网格
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              icon: Icons.calendar_today,
                              label: '遇见时间',
                              value: dateFormat.format(widget.encounter.encounterDate),
                              iconColor: Colors.blue,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.location_on,
                              label: '遇见地点',
                              value: widget.encounter.location != null
                                  ? LocationDisplayHelper.getDisplayText(
                                      latitude: widget.encounter.latitude,
                                      longitude: widget.encounter.longitude,
                                      address: widget.encounter.location,
                                    )
                                  : '未记录位置',
                              iconColor: Colors.green,
                            ),
                            if (widget.encounter.notes != null) ...[
                              const Divider(height: 24),
                              _buildInfoRow(
                                context,
                                icon: Icons.note,
                                label: '备注',
                                value: widget.encounter.notes!,
                                iconColor: Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 照片墙
                if (widget.encounter.photoPaths.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '照片记录',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.encounter.photoPaths.length} 张',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.encounter.photoPaths.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
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
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(widget.encounter.photoPaths[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                // 照片编号标签
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // 操作按钮区
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: null, // 功能暂未开放
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('添加照片'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: null, // 分享功能已在AppBar实现
                          icon: const Icon(Icons.share),
                          label: const Text('分享'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 底部间距
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}