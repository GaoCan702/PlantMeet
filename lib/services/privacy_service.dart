import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/privacy_policy.dart';

/// 隐私协议管理服务
class PrivacyService {
  static final Logger _logger = Logger();
  static const String _consentKey = 'privacy_consent';
  static const String _consentHistoryKey = 'privacy_consent_history';

  /// 初始化隐私服务
  static Future<void> initialize() async {
    // 这里可以添加任何初始化逻辑
    // 目前主要用于统一初始化接口
  }

  /// 获取用户协议同意状态
  static Future<PolicyConsent> getUserConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentJson = prefs.getString(_consentKey);

      if (consentJson != null) {
        final consentMap = json.decode(consentJson) as Map<String, dynamic>;
        return PolicyConsent.fromJson(consentMap);
      }

      return const PolicyConsent();
    } catch (e) {
      _logger.e('获取用户协议状态失败: $e');
      return const PolicyConsent();
    }
  }

  /// 设置用户协议同意状态
  static Future<void> setUserConsent(PolicyConsent consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentJson = json.encode(consent.toJson());
      await prefs.setString(_consentKey, consentJson);

      // 记录历史
      await _recordConsentHistory(consent);

      _logger.i('✅ 用户协议状态已保存');
    } catch (e) {
      _logger.e('❌ 保存用户协议状态失败: $e');
      throw Exception('保存协议状态失败: $e');
    }
  }

  /// 检查是否需要显示协议同意页面
  static Future<bool> needsConsent() async {
    final consent = await getUserConsent();

    // 如果从未同意过，需要显示
    if (!consent.isFullyConsented) {
      return true;
    }

    // 如果协议版本更新了，需要重新同意
    if (consent.needsUpdate) {
      return true;
    }

    return false;
  }

  /// 撤回用户协议同意（用于设置页面）
  static Future<void> revokeConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentKey);

      // 记录撤回操作
      final revokeConsent = PolicyConsent(
        hasAcceptedUserAgreement: false,
        hasAcceptedPrivacyPolicy: false,
        consentDate: DateTime.now(),
      );
      await _recordConsentHistory(revokeConsent);

      _logger.i('✅ 用户协议同意已撤回');
    } catch (e) {
      _logger.e('❌ 撤回用户协议失败: $e');
      throw Exception('撤回协议失败: $e');
    }
  }

  /// 获取协议同意历史记录
  static Future<List<PolicyConsent>> getConsentHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_consentHistoryKey) ?? [];

      return historyJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return PolicyConsent.fromJson(map);
      }).toList();
    } catch (e) {
      _logger.e('获取协议历史失败: $e');
      return [];
    }
  }

  /// 记录协议同意历史
  static Future<void> _recordConsentHistory(PolicyConsent consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_consentHistoryKey) ?? [];

      // 添加新记录
      final consentWithTimestamp = consent.copyWith(
        consentDate: DateTime.now(),
      );
      history.add(json.encode(consentWithTimestamp.toJson()));

      // 保留最近30条记录
      if (history.length > 30) {
        history.removeAt(0);
      }

      await prefs.setStringList(_consentHistoryKey, history);
    } catch (e) {
      _logger.e('记录协议历史失败: $e');
    }
  }

  /// 清理协议数据（用于测试或重置）
  static Future<void> clearAllConsentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentKey);
      await prefs.remove(_consentHistoryKey);
      _logger.i('✅ 协议数据已清理');
    } catch (e) {
      _logger.e('❌ 清理协议数据失败: $e');
      throw Exception('清理数据失败: $e');
    }
  }

  /// 检查特定权限的同意状态
  static Future<bool> hasPermissionConsent(String permission) async {
    final consent = await getUserConsent();

    switch (permission.toLowerCase()) {
      case 'location':
        // 位置权限需要隐私政策同意
        return consent.hasAcceptedPrivacyPolicy;
      case 'camera':
        // 相机权限需要用户协议同意
        return consent.hasAcceptedUserAgreement;
      case 'storage':
        // 存储权限需要用户协议同意
        return consent.hasAcceptedUserAgreement;
      default:
        return consent.isFullyConsented;
    }
  }

  /// 获取协议状态摘要（用于设置页面显示）
  static Future<Map<String, dynamic>> getConsentSummary() async {
    final consent = await getUserConsent();
    final history = await getConsentHistory();

    return {
      'current_consent': consent.toJson(),
      'is_consented': consent.isFullyConsented,
      'needs_update': consent.needsUpdate,
      'current_version': PrivacyPolicy.currentVersion,
      'user_agreement_version': consent.userAgreementVersion,
      'privacy_policy_version': consent.privacyPolicyVersion,
      'consent_date': consent.consentDate?.toIso8601String(),
      'history_count': history.length,
      'last_update_date': PrivacyPolicy.lastUpdated,
    };
  }

  /// 验证协议完整性（开发调试用）
  static Future<Map<String, dynamic>> validateConsent() async {
    final consent = await getUserConsent();
    final issues = <String>[];

    // 检查基本同意状态
    if (!consent.hasAcceptedUserAgreement) {
      issues.add('用户协议未同意');
    }

    if (!consent.hasAcceptedPrivacyPolicy) {
      issues.add('隐私政策未同意');
    }

    // 检查版本一致性
    if (consent.userAgreementVersion != PrivacyPolicy.currentVersion) {
      issues.add('用户协议版本不匹配');
    }

    if (consent.privacyPolicyVersion != PrivacyPolicy.currentVersion) {
      issues.add('隐私政策版本不匹配');
    }

    // 检查同意时间
    if (consent.consentDate == null) {
      issues.add('缺少同意时间记录');
    }

    return {
      'is_valid': issues.isEmpty,
      'issues': issues,
      'consent_status': consent.toJson(),
    };
  }

  /// 导出协议数据（用于数据可携带性）
  static Future<Map<String, dynamic>> exportConsentData() async {
    final consent = await getUserConsent();
    final history = await getConsentHistory();
    final summary = await getConsentSummary();

    return {
      'export_date': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // 可以从包信息获取
      'policy_version': PrivacyPolicy.currentVersion,
      'current_consent': consent.toJson(),
      'consent_history': history.map((c) => c.toJson()).toList(),
      'summary': summary,
    };
  }
}
