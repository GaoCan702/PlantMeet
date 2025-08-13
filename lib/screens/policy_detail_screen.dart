import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 协议详情页面 - 显示用户协议或隐私政策的详细内容
class PolicyDetailScreen extends StatefulWidget {
  final String title;
  final String content;
  
  const PolicyDetailScreen({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() {
        _showScrollToTop = true;
      });
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() {
        _showScrollToTop = false;
      });
    }
  }
  
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
  
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('协议内容已复制到剪贴板'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            tooltip: '复制内容',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareContent();
                  break;
                case 'print':
                  _printContent();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('分享'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 20),
                    SizedBox(width: 12),
                    Text('打印'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 内容区域
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Markdown(
              controller: _scrollController,
              data: widget.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                // 自定义样式 - 符合合规要求：文字清晰易读
                h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  height: 1.4,
                  fontSize: 24, // 确保标题足够大
                ),
                h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                  fontSize: 20, // 确保副标题足够大
                ),
                h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                  fontSize: 18,
                ),
                p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8, // 增加行高，提高可读性
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16, // 确保正文足够大
                ),
                listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16, // 确保列表文字足够大
                ),
                code: TextStyle(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                blockquoteDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 4,
                    ),
                  ),
                ),
                tableHead: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                tableBody: Theme.of(context).textTheme.bodySmall,
                tableBorder: TableBorder.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                // 链接样式
                a: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                // 水平分割线
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              onTapLink: (text, href, title) {
                // 处理链接点击
                if (href != null) {
                  _handleLinkTap(href);
                }
              },
            ),
          ),
          
          // 滚动到顶部按钮
          if (_showScrollToTop)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                onPressed: _scrollToTop,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
        ],
      ),
      // 底部信息栏
      bottomSheet: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '本协议具有法律约束力，请仔细阅读',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '可复制',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _shareContent() {
    // 实现分享功能
    // 需要添加 share_plus 依赖
    /*
    Share.share(
      '${widget.title}\n\n${widget.content}',
      subject: widget.title,
    );
    */
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }
  
  void _printContent() {
    // 实现打印功能
    // 可以集成打印插件或生成PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打印功能开发中')),
    );
  }
  
  void _handleLinkTap(String url) {
    // 处理链接点击
    // 可以打开浏览器或显示详情
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('链接: $url')),
    );
  }
}