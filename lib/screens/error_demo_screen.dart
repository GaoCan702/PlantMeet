import 'package:flutter/material.dart';
import 'package:plantmeet/widgets/copyable_error_message.dart';

class ErrorDemoScreen extends StatelessWidget {
  const ErrorDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('错误消���演示'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '错误消息组件演示',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              '1. 可复制的错误消息组件',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            CopyableErrorMessage(
              title: 'API 请求失败',
              message: 'API请求失败: 401 - {"error": "Unauthorized", "message": "Invalid API key provided"}',
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              '2. 简单错误消息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            CopyableErrorMessage(
              message: '网络连接超时，请检查您的网络设置',
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              '3. 技术错误详情',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            CopyableErrorMessage(
              title: '解析错误',
              message: 'Failed to parse JSON response: Unexpected end of input at line 1 column 15',
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              '使用说明：',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• 点击复制按钮可以复制错误信息到剪贴板'),
                    SizedBox(height: 8),
                    Text('• 技术性错误信息使用等宽字体显示'),
                    SizedBox(height: 8),
                    Text('• ��误信息包含标题和详细信息，便于用户理解和复制'),
                    SizedBox(height: 8),
                    Text('• 在SnackBar中也有复制按钮，方便快速复制'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () {
                // 演示SnackBar错误消息
                ErrorSnackBar.show(
                  context,
                  message: '这是一个可复制的错误消息示例',
                  title: '示例错误',
                );
              },
              child: const Text('显示SnackBar错误消息'),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {
                // 演示错误对话框
                showDialog(
                  context: context,
                  builder: (context) => const ErrorDialog(
                    message: '操作失败，请重试',
                    title: '操作错误',
                    details: 'Detailed error information with stack trace and technical details that users can copy for debugging purposes.',
                  ),
                );
              },
              child: const Text('显示错误对话框'),
            ),
          ],
        ),
      ),
    );
  }
}