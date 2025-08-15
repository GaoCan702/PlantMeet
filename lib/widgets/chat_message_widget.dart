import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/recognition_result.dart';

/// 聊天消息类型
enum ChatMessageType {
  user,
  assistant,
  system,
  thinking,
}

/// 聊天消息数据
class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String text;
  final File? image;
  final List<RecognitionResult>? recognitionResults;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.type,
    required this.text,
    this.image,
    this.recognitionResults,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    List<RecognitionResult>? recognitionResults,
  }) {
    return ChatMessage(
      id: id,
      type: type,
      text: text ?? this.text,
      image: image,
      recognitionResults: recognitionResults ?? this.recognitionResults,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// 聊天消息显示组件 - 借鉴 flutter_gemma 示例设计
class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onCopy;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onCopy,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.message.type == ChatMessageType.user 
        ? const Offset(0.3, 0) 
        : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // 启动动画
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: _buildMessageContent(),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case ChatMessageType.user:
        return _buildUserMessage();
      case ChatMessageType.assistant:
        return _buildAssistantMessage();
      case ChatMessageType.system:
        return _buildSystemMessage();
      case ChatMessageType.thinking:
        return _buildThinkingMessage();
    }
  }

  Widget _buildUserMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 用户图片预览
                if (widget.message.image != null) ...[
                  _buildImagePreview(widget.message.image!),
                  const SizedBox(height: 8),
                ],
                
                // 用户消息气泡
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    widget.message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                // 时间戳
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Text(
                    _formatTime(widget.message.timestamp),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 用户头像
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI头像
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(
            Icons.eco,
            color: Colors.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        
        // AI消息内容
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI消息气泡
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 消息文本
                      if (widget.message.text.isNotEmpty) ...[
                        Text(
                          widget.message.text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (widget.message.recognitionResults != null) 
                          const SizedBox(height: 12),
                      ],
                      
                      // 流式输入指示器
                      if (widget.message.isStreaming) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI 正在思考...',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // 识别结果
                      if (widget.message.recognitionResults != null)
                        _buildRecognitionResults(widget.message.recognitionResults!),
                    ],
                  ),
                ),
                
                // 操作按钮和时间戳
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(widget.message.timestamp),
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 复制按钮
                      InkWell(
                        onTap: _copyMessage,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy,
                            size: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.message.text,
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.message.text,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File image) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 200,
        maxHeight: 150,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildRecognitionResults(List<RecognitionResult> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.search,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              '识别结果',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        ...results.take(3).map((result) => _buildRecognitionItem(result)),
      ],
    );
  }

  Widget _buildRecognitionItem(RecognitionResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getSafetyColor(result.safety.level).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 植物名称和置信度
          Row(
            children: [
              Expanded(
                child: Text(
                  result.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(result.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          // 安全信息
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _getSafetyIcon(result.safety.level),
                size: 14,
                color: _getSafetyColor(result.safety.level),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  result.safety.description,
                  style: TextStyle(
                    color: _getSafetyColor(result.safety.level),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          // 简短描述
          if (result.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              result.description,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
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

  IconData _getSafetyIcon(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return Icons.check_circle;
      case SafetyLevel.caution:
        return Icons.warning;
      case SafetyLevel.toxic:
      case SafetyLevel.dangerous:
        return Icons.dangerous;
      case SafetyLevel.unknown:
        return Icons.help;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _copyMessage() {
    String textToCopy = widget.message.text;
    
    // 如果有识别结果，也包含在复制内容中
    if (widget.message.recognitionResults != null && 
        widget.message.recognitionResults!.isNotEmpty) {
      textToCopy += '\n\n识别结果:\n';
      for (final result in widget.message.recognitionResults!) {
        textToCopy += '${result.name} (${(result.confidence * 100).toStringAsFixed(0)}%)\n';
        textToCopy += '安全性: ${result.safety.description}\n\n';
      }
    }
    
    Clipboard.setData(ClipboardData(text: textToCopy));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
    
    widget.onCopy?.call();
  }
}