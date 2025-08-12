import 'plant_encounter.dart';

/// 生活化的植物识别结果 - 专注于实用信息
class RecognitionResult {
  // 基础识别信息
  final String id;
  final String name;           // 通俗易懂的中文名
  final String? nickname;      // 别名/俗名
  final double confidence;     // 置信度(0-1)
  
  // 生活化描述
  final String description;    // 生动的植物描述
  final List<String> features; // 关键特征（简单易懂）
  
  // 实用信息
  final SafetyInfo safety;     // 安全信息
  final CareInfo? care;        // 养护建议
  final String? season;        // 常见季节
  final List<String> locations; // 常见地点
  
  // 趣味信息
  final String? funFact;       // 有趣小知识
  final List<String> tags;     // 标签（如：观叶植物、室内植物）
  
  // 可选学术信息（默认隐藏）
  final String? scientificName; // 学名（高级用户可查看）
  final String? family;         // 科属（可选）

  RecognitionResult({
    required this.id,
    required this.name,
    this.nickname,
    required this.confidence,
    required this.description,
    required this.features,
    required this.safety,
    this.care,
    this.season,
    required this.locations,
    this.funFact,
    required this.tags,
    this.scientificName,
    this.family,
  });
  
  /// 用户友好的置信度描述
  String get confidenceText {
    if (confidence >= 0.8) return '很确定';
    if (confidence >= 0.6) return '比较确定';
    if (confidence >= 0.4) return '可能是';
    return '不太确定';
  }
  
  /// 是否是常见植物
  bool get isCommon => confidence >= 0.6;
  
  /// 生成用户友好的总结
  String get summary {
    final sb = StringBuffer();
    sb.write('这${confidenceText}是 $name');
    if (nickname != null) sb.write('（也叫$nickname）');
    return sb.toString();
  }

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String,
      features: List<String>.from(json['features'] as List),
      safety: SafetyInfo.fromJson(json['safety'] as Map<String, dynamic>),
      care: json['care'] != null ? CareInfo.fromJson(json['care']) : null,
      season: json['season'] as String?,
      locations: List<String>.from(json['locations'] as List),
      funFact: json['fun_fact'] as String?,
      tags: List<String>.from(json['tags'] as List),
      scientificName: json['scientific_name'] as String?,
      family: json['family'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'confidence': confidence,
      'description': description,
      'features': features,
      'safety': safety.toJson(),
      'care': care?.toJson(),
      'season': season,
      'locations': locations,
      'fun_fact': funFact,
      'tags': tags,
      'scientific_name': scientificName,
      'family': family,
    };
  }
}

/// 安全信息 - 重点关注
class SafetyInfo {
  final SafetyLevel level;    // 安全等级
  final String description;   // 安全说明
  final List<String> warnings; // 具体警告
  
  const SafetyInfo({
    required this.level,
    required this.description,
    required this.warnings,
  });
  
  factory SafetyInfo.fromJson(Map<String, dynamic> json) {
    return SafetyInfo(
      level: SafetyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['level'],
        orElse: () => SafetyLevel.unknown,
      ),
      description: json['description'] as String,
      warnings: List<String>.from(json['warnings'] as List),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'level': level.toString().split('.').last,
      'description': description,
      'warnings': warnings,
    };
  }
}

enum SafetyLevel {
  safe,        // 安全
  caution,     // 小心（如有刺）
  toxic,       // 有毒
  dangerous,   // 危险
  unknown,     // 未知
}

/// 养护信息 - 生活化建议
class CareInfo {
  final String difficulty;    // 养护难度：简单/适中/困难
  final String water;        // 浇水：多浇水/适量/少浇水
  final String light;        // 光照：喜阳/半阴/耐阴
  final String temperature;  // 温度要求
  final List<String> tips;   // 养护小贴士
  
  const CareInfo({
    required this.difficulty,
    required this.water,
    required this.light,
    required this.temperature,
    required this.tips,
  });
  
  factory CareInfo.fromJson(Map<String, dynamic> json) {
    return CareInfo(
      difficulty: json['difficulty'] as String,
      water: json['water'] as String,
      light: json['light'] as String,
      temperature: json['temperature'] as String,
      tips: List<String>.from(json['tips'] as List),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty,
      'water': water,
      'light': light,
      'temperature': temperature,
      'tips': tips,
    };
  }
}

/// 识别响应结果 - 简化且用户友好
class RecognitionResponse {
  final List<RecognitionResult> results;
  final String? error;
  final bool success;
  final RecognitionMethod method;
  final String? methodDescription; // 用户友好的方法描述

  RecognitionResponse({
    required this.results,
    this.error,
    required this.success,
    required this.method,
    this.methodDescription,
  });

  factory RecognitionResponse.success({
    required List<RecognitionResult> results,
    required RecognitionMethod method,
  }) {
    return RecognitionResponse(
      results: results,
      success: true,
      method: method,
      methodDescription: method.displayName,
    );
  }

  factory RecognitionResponse.error({
    required String error,
    required RecognitionMethod method,
  }) {
    return RecognitionResponse(
      results: [],
      error: error,
      success: false,
      method: method,
      methodDescription: method.displayName,
    );
  }

  /// 获取最佳匹配结果（只返1个）
  RecognitionResult? get bestMatch {
    if (results.isEmpty) return null;
    return results.first;
  }
  
  /// 获取备选结果（最多3个）
  List<RecognitionResult> get alternatives {
    if (results.length <= 1) return [];
    return results.skip(1).take(2).toList();
  }
  
  /// 用户友好的结果总结
  String get summary {
    if (!success) return '识别失败，请重新尝试';
    if (results.isEmpty) return '未找到匹配的植物';
    
    final best = bestMatch!;
    final sb = StringBuffer();
    sb.write('🌱 ${best.summary}');
    if (alternatives.isNotEmpty) {
      sb.write('，另外还可能是：');
      sb.write(alternatives.map((r) => r.name).join('、'));
    }
    return sb.toString();
  }
}

/// 识别方法 - 用户友好的显示
enum RecognitionMethod {
  local,    // 本地识别
  cloud,    // 云端识别
  hybrid,   // 混合识别
  manual,   // 手动输入
}

extension RecognitionMethodExtension on RecognitionMethod {
  String get displayName {
    switch (this) {
      case RecognitionMethod.local:
        return '本地AI识别';
      case RecognitionMethod.cloud:
        return '云端AI识别';
      case RecognitionMethod.hybrid:
        return '智能识别';
      case RecognitionMethod.manual:
        return '手动输入';
    }
  }
  
  String get description {
    switch (this) {
      case RecognitionMethod.local:
        return '使用本地AI模型，隐私安全，无需网络';
      case RecognitionMethod.cloud:
        return '使用云端高精度模型，识别结果更准确';
      case RecognitionMethod.hybrid:
        return '结合本地和云端，取长补短';
      case RecognitionMethod.manual:
        return '用户手动输入植物信息';
    }
  }
}