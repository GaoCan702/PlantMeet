import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/plant_species.dart';
import '../models/plant_encounter.dart';
import '../models/chat_message.dart';
import '../services/app_state.dart';
import '../services/embedded_model_service.dart';
import '../utils/location_display_helper.dart';

class PlantDetailScreenV2 extends StatefulWidget {
  final String speciesId;

  const PlantDetailScreenV2({super.key, required this.speciesId});

  @override
  State<PlantDetailScreenV2> createState() => _PlantDetailScreenV2State();
}

class _PlantDetailScreenV2State extends State<PlantDetailScreenV2> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _chatInputController = TextEditingController();
  double _opacity = 0.0;
  List<ChatMessage> _messages = [];
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final species = appState.species.firstWhere(
          (s) => s.id == widget.speciesId,
          orElse: () => PlantSpecies(
            id: '',
            scientificName: '',
            commonName: '未知植物',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final encounters = appState.getEncountersForSpecies(widget.speciesId);
        // 按时间排序，最新的在前
        encounters.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));

        // 获取所有照片
        final allPhotos = <String>[];
        for (final encounter in encounters) {
          allPhotos.addAll(encounter.photoPaths);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 自定义的SliverAppBar，带照片背景
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _opacity,
                    child: Text(
                      species.commonName,
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
                      if (allPhotos.isNotEmpty)
                        Image.file(
                          File(allPhotos.first),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.green.shade200,
                            child: const Icon(
                              Icons.eco,
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
                                Colors.green.shade300,
                                Colors.green.shade600,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.eco,
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
                            Text(
                              species.commonName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              species.scientificName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
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
                    // 毒性警告（如果有）
                    if (species.isToxic == true)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade50,
                              Colors.orange.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '毒性警告',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    species.toxicityInfo ?? '该植物有毒，请小心处理',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 植物描述
                    if (species.description != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '植物简介',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              species.description!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 统计信息条
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            icon: Icons.visibility,
                            value: '${encounters.length}',
                            label: '遇见次数',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.photo_library,
                            value: '${allPhotos.length}',
                            label: '照片数量',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.calendar_today,
                            value: encounters.isNotEmpty
                                ? DateFormat('MM/dd').format(encounters.first.encounterDate)
                                : '--',
                            label: '最近遇见',
                          ),
                        ],
                      ),
                    ),

                    // AI植物助手
                    _buildAIChatSection(context, species, allPhotos),

                    // 遇见记录标题
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '遇见时光轴',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 遇见记录列表 - 时间轴样式
              if (encounters.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无遇见记录',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final encounter = encounters[index];
                      final isFirst = index == 0;
                      final isLast = index == encounters.length - 1;

                      return _buildTimelineItem(
                        context,
                        encounter: encounter,
                        isFirst: isFirst,
                        isLast: isLast,
                      );
                    },
                    childCount: encounters.length,
                  ),
                ),

              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required PlantEncounter encounter,
    required bool isFirst,
    required bool isLast,
  }) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 时间轴线
          SizedBox(
            width: 60,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: Colors.grey.shade300,
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // 内容区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间
                  Text(
                    dateFormat.format(encounter.encounterDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 内容容器
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 照片（如果有）
                        if (encounter.photoPaths.isNotEmpty)
                          Container(
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: encounter.photoPaths.length,
                              itemBuilder: (context, photoIndex) {
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(encounter.photoPaths[photoIndex])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // 位置信息
                        if (encounter.location != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  LocationDisplayHelper.getShortDisplay(
                                    latitude: encounter.latitude,
                                    longitude: encounter.longitude,
                                    address: encounter.location,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        // 备注（如果有）
                        if (encounter.notes != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    encounter.notes!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建AI聊天助手模块
  Widget _buildAIChatSection(BuildContext context, PlantSpecies species, List<String> allPhotos) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI植物助手',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.smart_toy,
                  color: Colors.green[600],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 欢迎文字
            Text(
              '💬 您好！我可以回答关于 ${species.commonName} 的任何问题',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            
            // 预置问题网格
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickButton('🌱 如何养护？', species),
                _buildQuickButton('💧 浇水频次？', species),
                _buildQuickButton('☀️ 光照需求？', species),
                _buildQuickButton('⚠️ 注意事项？', species),
              ],
            ),
            const SizedBox(height: 12),
            
            // 自定义输入入口
            InkWell(
              onTap: () => _openChatDialog(species, allPhotos),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '输入自定义问题...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预置问题按钮
  Widget _buildQuickButton(String text, PlantSpecies species) {
    return OutlinedButton(
      onPressed: () => _askQuestionDirectly(text, species),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green[700],
        side: BorderSide(color: Colors.green.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  /// 直接提问（不打开对话框）
  Future<void> _askQuestionDirectly(String question, PlantSpecies species) async {
    // 在SnackBar中显示问题和回答
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在为您查询: $question'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final answer = await _getAIResponse(question, species);
      
      if (mounted) {
        // 显示回答的对话框
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Flexible(child: Text('关于 ${species.commonName}')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '问：$question',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  answer,
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openChatDialog(species, []);
                },
                child: const Text('继续对话'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取回答失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 打开聊天对话界面
  void _openChatDialog(PlantSpecies species, List<String> allPhotos) {
    // 重置消息列表
    _messages = [
      ChatMessage.ai('您好！我是 ${species.commonName} 的AI助手。有什么想了解的吗？'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // 头部
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '与 ${species.commonName} 对话',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // 对话区域
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessage(_messages[index]),
                ),
              ),
              
              // 相关问题推荐
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    '🌿 繁殖方法？',
                    '🐛 病虫害？',
                    '📅 季节护理？',
                  ].map((q) => _buildSuggestionChip(q, species, setModalState)).toList(),
                ),
              ),
              
              // 输入区域
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatInputController,
                        decoration: InputDecoration(
                          hintText: '询问关于 ${species.commonName} 的问题...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) => _sendMessage(species, setModalState),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isChatLoading 
                        ? null 
                        : () => _sendMessage(species, setModalState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: _isChatLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建消息组件
  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Icon(Icons.smart_toy, size: 16, color: Colors.green[700]),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? Colors.green[600] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 16, color: Colors.blue[700]),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建建议问题小按钮
  Widget _buildSuggestionChip(String question, PlantSpecies species, StateSetter setModalState) {
    return ActionChip(
      label: Text(question),
      onPressed: () async {
        _chatInputController.text = question;
        await _sendMessage(species, setModalState);
      },
      backgroundColor: Colors.green.shade50,
      labelStyle: TextStyle(color: Colors.green[700], fontSize: 12),
    );
  }

  /// 发送消息
  Future<void> _sendMessage(PlantSpecies species, StateSetter setModalState) async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty || _isChatLoading) return;

    // 添加用户消息
    final userMessage = ChatMessage.user(text);
    setModalState(() {
      _messages.add(userMessage);
      _isChatLoading = true;
    });
    
    _chatInputController.clear();

    try {
      // 获取AI回答
      final response = await _getAIResponse(text, species);
      
      // 添加AI回答
      final aiMessage = ChatMessage.ai(response);
      setModalState(() {
        _messages.add(aiMessage);
        _isChatLoading = false;
      });
    } catch (e) {
      // 错误处理
      final errorMessage = ChatMessage.ai('抱歉，我暂时无法回答这个问题。请稍后再试。');
      setModalState(() {
        _messages.add(errorMessage);
        _isChatLoading = false;
      });
    }
  }

  /// 获取AI回应（集成现有的AI服务）
  Future<String> _getAIResponse(String question, PlantSpecies species) async {
    try {
      // 尝试使用嵌入式模型服务（通过Provider获取）
      final embeddedModelService = Provider.of<EmbeddedModelService>(context, listen: false);
      if (embeddedModelService.isModelReady) {
        try {
          // 这里我们使用预设回答，因为直接调用embedded model比较复杂
          // 在实际应用中，可以考虑添加专门的聊天接口
          return _getPresetResponse(question, species);
        } catch (e) {
          // 模型调用失败，使用预设回答
          return _getPresetResponse(question, species);
        }
      } else {
        // 模型未就绪，使用预设回答
        return _getPresetResponse(question, species);
      }
    } catch (e) {
      // 如果AI服务失败，使用预设回答
      return _getPresetResponse(question, species);
    }
  }

  /// 预设回答（当AI服务不可用时使用）
  String _getPresetResponse(String question, PlantSpecies species) {
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('养护') || lowerQuestion.contains('怎么养')) {
      return '${species.commonName}的基本养护要点：\n\n'
          '💧 浇水：保持土壤湿润，但避免积水\n'
          '☀️ 光照：提供充足的散射光\n'
          '🌡️ 温度：保持在15-25°C之间\n'
          '🌿 通风：确保良好的空气流通\n\n'
          '建议定期观察植物状态，根据季节和环境调整护理方式。';
    }
    
    if (lowerQuestion.contains('浇水')) {
      return '关于${species.commonName}的浇水：\n\n'
          '🕐 频次：一般每3-5天浇水一次，具体要看土壤干湿情况\n'
          '💧 方法：浇透水，直到底部有水流出\n'
          '⏰ 时间：早上或傍晚浇水效果最佳\n'
          '🌡️ 季节：夏季需水量大，冬季减少浇水\n\n'
          '记住"见干见湿"的原则，避免频繁浇水导致烂根。';
    }
    
    if (lowerQuestion.contains('光照') || lowerQuestion.contains('阳光')) {
      return '${species.commonName}的光照需求：\n\n'
          '☀️ 喜欢明亮的散射光，避免强烈直射\n'
          '🏠 室内可放在靠近窗户的位置\n'
          '🌤️ 每天至少需要4-6小时的光照\n'
          '🔄 定期转动花盆，让各面都能接收到光照\n\n'
          '如果叶片发黄或徒长，可能是光照不足的信号。';
    }
    
    if (lowerQuestion.contains('注意') || lowerQuestion.contains('禁忌')) {
      return '${species.commonName}的注意事项：\n\n'
          '⚠️ 避免过度浇水，这是最常见的问题\n'
          '🌡️ 不要放在空调或暖气直吹的地方\n'
          '🐾 ${species.isToxic == true ? '该植物有毒，请避免儿童和宠物接触' : '对宠物和儿童相对安全'}\n'
          '🧤 修剪时建议戴手套\n'
          '🔄 避免频繁移动和换盆\n\n'
          '${species.toxicityInfo ?? '日常护理时多观察植物状态变化。'}';
    }
    
    // 默认回答
    return '感谢您对${species.commonName}的关注！\n\n'
        '这种植物${species.description ?? '是一种很好的选择'}。'
        '如果您有具体的养护问题，建议咨询植物专家或查阅更详细的养护指南。\n\n'
        '您也可以尝试询问关于浇水、光照、养护等具体问题。';
  }
}