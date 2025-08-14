/// 大模型Prompt模板系统 - 为Qwen2.5-VL等视觉语言模型设计
class LLMPromptTemplates {
  /// 系统级提示词 - 定义AI助手的角色和行为
  static const String systemPrompt = '''
你是PlantMeet应用的植物识别专家，专门为学生和植物爱好者提供生活化的植物识别服务。

# 你的特点
- 使用亲切、易懂的中文表达
- 专注实用信息而非学术分类
- 优先考虑安全性和实用性
- 提供有趣的植物知识

# 输出要求
- 必须使用指定的JSON格式
- 信息要准确、实用、有趣
- 避免过于专业的术语
- 重点关注安全性警告

# 处理原则
- 如果不确定，诚实说明
- 多个可能时提供前3个最可能的结果
- 优先保障用户安全
''';

  /// 主要识别提示词模板
  static String getIdentificationPrompt({
    String? userContext,
    String? season,
    String? location,
  }) {
    final contextInfo = _buildContextInfo(userContext, season, location);

    return '''
请识别图片中的植物，并提供生活化的详细信息。

$contextInfo

请按以下JSON格式输出，确保信息准确且对普通用户友好：

```json
{
  "success": true,
  "confidence": "很确定|比较确定|可能是|不太确定",
  "primary_result": {
    "name": "通俗易懂的中文名称",
    "nickname": "别名或俗名（如果有）",
    "description": "简洁生动的描述，让人容易理解和记住",
    "key_features": ["关键特征1", "关键特征2", "关键特征3"],
    "safety": {
      "level": "safe|caution|toxic|dangerous",
      "description": "安全性简短说明",
      "warnings": ["具体警告信息（如果有）"]
    },
    "life_info": {
      "season": "常见季节",
      "locations": ["常见地点"],
      "tags": ["实用标签"]
    },
    "care_tips": {
      "difficulty": "简单|适中|困难",
      "water": "浇水建议",
      "light": "光照需求",
      "tips": ["实用养护建议"]
    },
    "fun_fact": "有趣的植物小知识",
    "scientific_info": {
      "scientific_name": "学名（可选）",
      "family": "科属（可选）"
    }
  },
  "alternatives": [
    // 如果有其他可能，提供1-2个备选
    {
      "name": "备选植物名称",
      "confidence_note": "为什么可能是这个",
      "key_difference": "与主要结果的区别"
    }
  ],
  "user_guidance": "给用户的友好建议和下一步行动指导"
}
```

重要提醒：
1. 如果图片不清楚或无法识别植物，请在success字段返回false并说明原因
2. 安全信息至关重要，宁可保守也不要遗漏风险
3. 描述要生动有趣，避免枯燥的学术语言
4. 养护建议要实用，适合普通家庭环境
''';
  }

  /// 快速识别提示词（性能优先）
  static String getQuickIdentificationPrompt() {
    return '''
请快速识别图片中的植物，只需要基本信息。

按以下简化JSON格式输出：

```json
{
  "success": true,
  "name": "植物名称",
  "confidence": "很确定|比较确定|可能是|不太确定", 
  "safety_alert": "如果有安全风险请在这里说明，没有则为null",
  "brief_description": "一句话描述这个植物",
  "quick_tip": "一个实用小建议"
}
```

要求：
- 响应速度优先
- 重点关注安全性
- 信息简洁准确
''';
  }

  /// 安全检查专用提示词
  static String getSafetyCheckPrompt() {
    return '''
专门检查图片中植物的安全性，特别关注是否对人类（尤其是儿童）和宠物有害。

请按以下格式输出：

```json
{
  "safety_level": "safe|caution|toxic|dangerous|unknown",
  "risk_assessment": "详细的安全性评估",
  "specific_warnings": ["具体的警告信息"],
  "emergency_info": "如果误食或接触后的应急处理建议",
  "child_pet_safety": "对儿童和宠物的特别提醒"
}
```

重点关注：
- 是否有毒（误食、接触）
- 是否有刺或其他物理伤害风险
- 是否会引起过敏反应
- 对儿童和宠物的特殊风险
''';
  }

  /// 养护建议专用提示词
  static String getCareAdvicePrompt() {
    return '''
为图片中的植物提供实用的家庭养护建议，面向普通植物爱好者。

请按以下格式输出：

```json
{
  "difficulty_level": "新手友好|需要经验|专家级别",
  "care_guide": {
    "watering": {
      "frequency": "浇水频率建议",
      "amount": "浇水量建议", 
      "tips": ["浇水小技巧"]
    },
    "lighting": {
      "requirement": "光照需求",
      "best_position": "最佳摆放位置",
      "tips": ["光照小技巧"]
    },
    "environment": {
      "temperature": "适宜温度范围",
      "humidity": "湿度要求",
      "ventilation": "通风建议"
    },
    "maintenance": {
      "pruning": "修剪建议",
      "fertilizing": "施肥建议",
      "repotting": "换盆建议"
    }
  },
  "seasonal_care": {
    "spring": "春季养护重点",
    "summer": "夏季养护重点", 
    "autumn": "秋季养护重点",
    "winter": "冬季养护重点"
  },
  "common_problems": [
    {
      "problem": "常见问题",
      "cause": "可能原因",
      "solution": "解决方法"
    }
  ],
  "beginner_tips": ["给新手的实用建议"]
}
```
''';
  }

  /// 趣味知识提示词
  static String getFunFactPrompt() {
    return '''
为图片中的植物提供有趣的知识和文化背景，让用户更好地了解和记住这个植物。

请按以下格式输出：

```json
{
  "interesting_facts": [
    "有趣的生物学事实",
    "特殊的生存技能", 
    "令人惊讶的用途"
  ],
  "cultural_significance": {
    "symbolism": "文化象征意义",
    "history": "历史文化背景",
    "traditions": "相关传统或习俗"
  },
  "ecological_role": "在生态系统中的作用",
  "human_relationship": "与人类的关系和用途",
  "memorable_story": "一个容易记住的小故事或比喻",
  "did_you_know": "\"你知道吗？\"类型的趣味事实"
}
```

要求：
- 信息准确有趣
- 适合各年龄段理解
- 避免过于专业的术语
- 帮助用户记忆和理解
''';
  }

  /// 构建上下文信息
  static String _buildContextInfo(
    String? userContext,
    String? season,
    String? location,
  ) {
    final contextParts = <String>[];

    if (userContext != null && userContext.isNotEmpty) {
      contextParts.add('用户补充信息：$userContext');
    }

    if (season != null && season.isNotEmpty) {
      contextParts.add('当前季节：$season');
    }

    if (location != null && location.isNotEmpty) {
      contextParts.add('地理位置：$location');
    }

    if (contextParts.isEmpty) {
      return '';
    }

    return '''
# 上下文信息
${contextParts.join('\n')}

请结合这些信息提供更准确的识别结果。
''';
  }

  /// 获取错误恢复提示词
  static String getErrorRecoveryPrompt(
    String originalPrompt,
    String errorMessage,
  ) {
    return '''
之前的识别请求遇到了问题：$errorMessage

请重新尝试识别图片中的植物，这次请：
1. 更仔细地观察图片细节
2. 如果图片质量不够好，请说明具体问题
3. 即使不完全确定，也要提供最可能的结果
4. 重点关注安全性信息

$originalPrompt
''';
  }

  /// 验证JSON输出的模式
  static const Map<String, dynamic> outputSchema = {
    'type': 'object',
    'required': ['success'],
    'properties': {
      'success': {'type': 'boolean'},
      'confidence': {
        'type': 'string',
        'enum': ['很确定', '比较确定', '可能是', '不太确定'],
      },
      'primary_result': {
        'type': 'object',
        'required': ['name', 'description', 'safety'],
        'properties': {
          'name': {'type': 'string'},
          'nickname': {'type': 'string'},
          'description': {'type': 'string'},
          'key_features': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'safety': {
            'type': 'object',
            'required': ['level', 'description'],
            'properties': {
              'level': {
                'type': 'string',
                'enum': ['safe', 'caution', 'toxic', 'dangerous'],
              },
              'description': {'type': 'string'},
              'warnings': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          },
        },
      },
    },
  };
}
