import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/embedded_model_service.dart';

/// 多模态模型聊天测试页面 - 参考官方示例设计
class ModelChatTestScreen extends StatefulWidget {
  const ModelChatTestScreen({super.key});

  @override
  State<ModelChatTestScreen> createState() => _ModelChatTestScreenState();
}

class _ModelChatTestScreenState extends State<ModelChatTestScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isProcessing = false;
  String _currentResponse = '';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(Message.text(
      text: '''欢迎使用离线AI模型聊天测试！

我是基于 Gemma 3 Nano E4B 的多模态AI助手，可以：
- 📝 回答各种问题
- 🌿 识别和分析植物图片
- 💬 进行自然对话

请输入文字或选择图片开始对话吧！''',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(Message message) async {
    if (_isProcessing) return;

    setState(() {
      _messages.add(message);
      _isProcessing = true;
      _currentResponse = '';
    });

    _scrollToBottom();

    try {
      final modelService = Provider.of<EmbeddedModelService>(context, listen: false);
      
      // 添加AI回复的占位消息
      final aiMessage = Message.text(text: '', isUser: false);
      setState(() {
        _messages.add(aiMessage);
      });

      // 使用流式响应 - 让服务自己处理模型加载
      await for (final token in modelService.chatStream(
        prompt: message.text,
        imageFile: message.hasImage ? await _saveImageToTempFile(message.imageBytes!) : null,
      )) {
        if (token.isNotEmpty) {
          setState(() {
            _currentResponse += token;
            _messages.last = Message.text(text: _currentResponse, isUser: false);
          });
          _scrollToBottom();
        }
      }
      
      // 如果没有收到任何回复，显示默认消息
      if (_currentResponse.isEmpty) {
        setState(() {
          _messages.last = Message.text(
            text: 'ℹ️ 模型没有返回任何内容。请尝试改变提问方式或重新初始化模型。',
            isUser: false,
          );
        });
      }
    } catch (e) {
      // 更新占位消息为错误消息，而不是添加新消息
      setState(() {
        _messages.last = Message.text(
          text: '❌ 处理失败: $e\n\n请检查模型状态或重试。',
          isUser: false,
        );
      });
    } finally {
      setState(() {
        _isProcessing = false;
        _currentResponse = '';
      });
      _scrollToBottom();
    }
  }

  Future<File> _saveImageToTempFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/chat_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);
    return tempFile;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('离线AI聊天测试'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.length > 1 ? _clearChat : null,
            tooltip: '清空聊天',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessage(_messages[index]);
                },
              ),
            ),
          ),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '🌱 AI正在思考...',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: _buildChatInput(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(false),
          if (!message.isUser) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display image if available
                  if (message.hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        message.imageBytes!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  
                  // Display text
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser 
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.green.withOpacity(0.1),
      child: Icon(
        isUser ? Icons.person : Icons.eco,
        color: isUser ? Theme.of(context).primaryColor : Colors.green,
        size: 16,
      ),
    );
  }

  Widget _buildChatInput() {
    return Column(
      children: [
        // Selected image preview
        if (_selectedImageBytes != null) _buildImagePreview(),
        
        // Input field
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // Image button
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: _selectedImageBytes != null 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade600,
                ),
                onPressed: _isProcessing ? null : _pickImage,
                tooltip: '选择图片',
              ),
              
              // Text field
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !_isProcessing,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: _selectedImageBytes != null
                        ? '为图片添加描述...'
                        : '输入消息...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  onSubmitted: _isProcessing ? null : _handleTextSubmitted,
                ),
              ),
              
              // Send button
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: _isProcessing ? null : () => _handleTextSubmitted(_textController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _selectedImageBytes!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedImageName ?? 'Image',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_selectedImageBytes!.length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.green.shade600),
            onPressed: _clearImage,
            tooltip: '移除图片',
          ),
        ],
      ),
    );
  }

  // Image handling
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片选择失败: $e')),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  void _handleTextSubmitted(String text) {
    if (_isProcessing) return; // 防止重复提交
    if (text.trim().isEmpty && _selectedImageBytes == null) return;

    final message = _selectedImageBytes != null
        ? Message.withImage(
            text: text.trim(),
            imageBytes: _selectedImageBytes!,
            isUser: true,
          )
        : Message.text(text: text.trim(), isUser: true);

    _textController.clear();
    _clearImage();
    _handleSubmitted(message);
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空聊天记录'),
        content: const Text('确定要清空所有聊天记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}