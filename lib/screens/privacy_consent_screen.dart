import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/privacy_policy.dart';
import '../services/privacy_service.dart';
import 'policy_detail_screen.dart';

/// 隐私协议同意页面 - 首次启动时显示
class PrivacyConsentScreen extends StatefulWidget {
  final VoidCallback onConsented;
  
  const PrivacyConsentScreen({
    Key? key,
    required this.onConsented,
  }) : super(key: key);

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen>
    with SingleTickerProviderStateMixin {
  bool _hasAcceptedUserAgreement = false;
  bool _hasAcceptedPrivacyPolicy = false;
  bool _isAccepting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  bool get _canProceed => _hasAcceptedUserAgreement && _hasAcceptedPrivacyPolicy;
  
  Future<void> _handleAccept() async {
    if (!_canProceed) return;
    
    setState(() {
      _isAccepting = true;
    });
    
    try {
      await PrivacyService.setUserConsent(
        PolicyConsent(
          hasAcceptedUserAgreement: true,
          hasAcceptedPrivacyPolicy: true,
          userAgreementVersion: PrivacyPolicy.currentVersion,
          privacyPolicyVersion: PrivacyPolicy.currentVersion,
          consentDate: DateTime.now(),
        ),
      );
      
      widget.onConsented();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存协议同意状态失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isAccepting = false;
      });
    }
  }
  
  /// 处理用户拒绝协议
  void _handleReject() {
    showDialog(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Text('无法使用应用'),
            ],
          ),
          content: const Text(
            '很抱歉，如果您不同意《用户协议》和《隐私政策》，我们将无法为您提供PlantMeet的服务。\n\n您可以：\n1. 重新阅读协议内容\n2. 同意协议后继续使用\n3. 退出应用',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框，返回协议页面
              },
              child: const Text('重新考虑'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
                _exitApp(); // 退出应用
              },
              child: Text(
                '退出应用',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 退出应用
  void _exitApp() {
    // 根据平台选择不同的退出方式
    // SystemNavigator.pop(); // 需要导入 'package:flutter/services.dart'
    // 或者可以显示一个说明，让用户手动退出
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出应用'),
          content: const Text('请手动关闭应用或切换到其他应用。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }
  
  void _showPolicyDetail(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PolicyDetailScreen(
          title: title,
          content: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo和应用名称
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.eco,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'PlantMeet',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '遇见植物，记录美好',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // 隐私说明
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.privacy_tip,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '隐私保护承诺',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '我们重视您的隐私权利。您的植物识别数据主要存储在本地设备，仅在您明确授权时使用云端服务。我们不会出售您的个人信息。',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 协议同意选项
                _buildConsentCheckbox(
                  value: _hasAcceptedUserAgreement,
                  onChanged: (value) {
                    setState(() {
                      _hasAcceptedUserAgreement = value ?? false;
                    });
                  },
                  text: '我已阅读并同意',
                  linkText: '《用户协议》',
                  onLinkTap: () => _showPolicyDetail(
                    '用户协议',
                    PrivacyPolicy.userAgreementContent,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildConsentCheckbox(
                  value: _hasAcceptedPrivacyPolicy,
                  onChanged: (value) {
                    setState(() {
                      _hasAcceptedPrivacyPolicy = value ?? false;
                    });
                  },
                  text: '我已阅读并同意',
                  linkText: '《隐私政策》',
                  onLinkTap: () => _showPolicyDetail(
                    '隐私政策',
                    PrivacyPolicy.privacyPolicyContent,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 同意/拒绝按钮组
                Row(
                  children: [
                    // 拒绝按钮
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isAccepting ? null : _handleReject,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '不同意',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // 同意按钮
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _canProceed && !_isAccepting ? _handleAccept : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canProceed 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                            foregroundColor: _canProceed 
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: _canProceed ? 2 : 0,
                          ),
                          child: _isAccepting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('保存中'),
                                  ],
                                )
                              : const Text(
                                  '同意',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),
                
                // 版本信息
                Text(
                  '协议版本 ${PrivacyPolicy.currentVersion} • 更新于 ${PrivacyPolicy.lastUpdated}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建协议同意复选框
  Widget _buildConsentCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(text: text),
                TextSpan(
                  text: linkText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// 显示退出应用确认对话框
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认退出'),
          content: const Text('如果不同意用户协议和隐私政策，将无法使用PlantMeet应用。确定要退出吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 这里可以调用系统退出方法
                // SystemNavigator.pop(); // 需要import 'package:flutter/services.dart';
              },
              child: Text(
                '退出应用',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}