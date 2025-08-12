import 'package:flutter/material.dart';
import '../models/privacy_policy.dart';
import '../services/privacy_service.dart';

/// 隐私保护守卫 - 确保在用户同意协议前不访问个人信息
class PrivacyGuard {
  static bool _isConsentChecked = false;
  static bool _hasValidConsent = false;
  static PolicyConsent? _cachedConsent;
  
  /// 初始化隐私守卫 - 应用启动时调用
  static Future<void> initialize() async {
    if (!_isConsentChecked) {
      _cachedConsent = await PrivacyService.getUserConsent();
      _hasValidConsent = _cachedConsent?.isFullyConsented == true && 
                        !(_cachedConsent?.needsUpdate ?? true);
      _isConsentChecked = true;
      
      debugPrint('🔒 PrivacyGuard initialized: consent=${_hasValidConsent}');
    }
  }
  
  /// 检查是否有有效的用户同意
  static bool hasValidConsent() {
    if (!_isConsentChecked) {
      debugPrint('⚠️ PrivacyGuard not initialized, blocking access');
      return false;
    }
    return _hasValidConsent;
  }
  
  /// 更新同意状态（用户同意后调用）
  static void updateConsent(PolicyConsent consent) {
    _cachedConsent = consent;
    _hasValidConsent = consent.isFullyConsented && !consent.needsUpdate;
    debugPrint('🔓 PrivacyGuard consent updated: ${_hasValidConsent}');
  }
  
  /// 清除同意状态（用户撤回同意时调用）
  static void revokeConsent() {
    _hasValidConsent = false;
    _cachedConsent = null;
    debugPrint('🔒 PrivacyGuard consent revoked');
  }
  
  /// 检查特定功能的访问权限
  static bool canAccess(PrivacyFeature feature) {
    if (!hasValidConsent()) {
      debugPrint('🚫 Access denied for ${feature.name}: no consent');
      return false;
    }
    
    // 根据功能类型检查具体权限
    switch (feature) {
      case PrivacyFeature.camera:
        return _cachedConsent?.hasAcceptedUserAgreement == true;
      case PrivacyFeature.location:
        return _cachedConsent?.hasAcceptedPrivacyPolicy == true;
      case PrivacyFeature.storage:
        return _cachedConsent?.hasAcceptedUserAgreement == true;
      case PrivacyFeature.deviceInfo:
        return _cachedConsent?.hasAcceptedPrivacyPolicy == true;
      case PrivacyFeature.analytics:
        return _cachedConsent?.hasAcceptedPrivacyPolicy == true;
      case PrivacyFeature.crashReporting:
        return _cachedConsent?.hasAcceptedPrivacyPolicy == true;
      default:
        return _hasValidConsent;
    }
  }
  
  /// 受保护的功能执行器
  static Future<T?> guardedExecution<T>({
    required PrivacyFeature feature,
    required Future<T> Function() action,
    String? errorMessage,
  }) async {
    if (!canAccess(feature)) {
      debugPrint('🚫 Blocked execution of ${feature.name}: ${errorMessage ?? 'No consent'}');
      return null;
    }
    
    try {
      return await action();
    } catch (e) {
      debugPrint('❌ Error in guarded execution for ${feature.name}: $e');
      return null;
    }
  }
  
  /// 同步版本的受保护执行器
  static T? guardedSync<T>({
    required PrivacyFeature feature,
    required T Function() action,
    String? errorMessage,
  }) {
    if (!canAccess(feature)) {
      debugPrint('🚫 Blocked sync execution of ${feature.name}: ${errorMessage ?? 'No consent'}');
      return null;
    }
    
    try {
      return action();
    } catch (e) {
      debugPrint('❌ Error in guarded sync execution for ${feature.name}: $e');
      return null;
    }
  }
  
  /// 记录隐私访问日志
  static void logAccess(PrivacyFeature feature, {bool granted = false, String? details}) {
    final status = granted ? '✅ GRANTED' : '❌ DENIED';
    debugPrint('📝 Privacy Access Log: ${feature.name} - $status${details != null ? ' ($details)' : ''}');
  }
  
  /// 获取当前隐私状态摘要
  static Map<String, dynamic> getPrivacyStatus() {
    return {
      'initialized': _isConsentChecked,
      'has_valid_consent': _hasValidConsent,
      'consent_date': _cachedConsent?.consentDate?.toIso8601String(),
      'user_agreement_accepted': _cachedConsent?.hasAcceptedUserAgreement,
      'privacy_policy_accepted': _cachedConsent?.hasAcceptedPrivacyPolicy,
      'needs_update': _cachedConsent?.needsUpdate,
      'current_version': PrivacyPolicy.currentVersion,
      'user_version': _cachedConsent?.userAgreementVersion,
      'policy_version': _cachedConsent?.privacyPolicyVersion,
    };
  }
  
  /// 重置守卫状态（测试用）
  static void reset() {
    _isConsentChecked = false;
    _hasValidConsent = false;
    _cachedConsent = null;
    debugPrint('🔄 PrivacyGuard reset');
  }
}

/// 需要隐私保护的功能枚举
enum PrivacyFeature {
  camera('相机访问'),
  location('位置信息'),
  storage('存储访问'),
  deviceInfo('设备信息'),
  analytics('使用统计'),
  crashReporting('崩溃报告'),
  photoLibrary('照片库访问'),
  networkAccess('网络访问'),
  biometrics('生物识别'),
  notifications('通知推送');
  
  const PrivacyFeature(this.name);
  final String name;
}

/// 隐私保护的Widget装饰器
class PrivacyProtectedWidget extends StatelessWidget {
  final PrivacyFeature feature;
  final Widget child;
  final Widget? fallback;
  final String? deniedMessage;
  
  const PrivacyProtectedWidget({
    Key? key,
    required this.feature,
    required this.child,
    this.fallback,
    this.deniedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PrivacyGuard.canAccess(feature)) {
      PrivacyGuard.logAccess(feature, granted: true);
      return child;
    } else {
      PrivacyGuard.logAccess(feature, granted: false, details: deniedMessage);
      return fallback ?? _buildDefaultFallback(context);
    }
  }
  
  Widget _buildDefaultFallback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.privacy_tip,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '需要隐私授权',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deniedMessage ?? '此功能需要您同意相关隐私协议后才能使用。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 隐私保护的Future构建器
class PrivacyFutureBuilder<T> extends StatelessWidget {
  final PrivacyFeature feature;
  final Future<T> Function() future;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final Widget? noConsentWidget;
  
  const PrivacyFutureBuilder({
    Key? key,
    required this.feature,
    required this.future,
    required this.builder,
    this.noConsentWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!PrivacyGuard.canAccess(feature)) {
      return noConsentWidget ?? Container(
        child: const Text('隐私权限不足'),
      );
    }
    
    return FutureBuilder<T>(
      future: future(),
      builder: builder,
    );
  }
}