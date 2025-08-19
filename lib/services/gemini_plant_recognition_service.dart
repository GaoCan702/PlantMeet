import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/recognition_result.dart';

/// Gemini植物识别服务
/// 使用Google Gemini Vision Pro API进行植物识别，支持BYOK模式
class GeminiPlantRecognitionService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';
  
  final Logger _logger = Logger();
  final String apiKey;
  
  GeminiPlantRecognitionService({required this.apiKey});
  
  /// 植物识别主方法
  Future<RecognitionResponse> identifyPlant(File imageFile) async {
    try {
      _logger.i('🌿[GeminiService] 开始使用Gemini API识别植物');
      
      // 读取图像并转换为base64
      final imageBytes = await imageFile.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);
      
      // 构建请求体
      final requestBody = _buildRequestBody(imageBase64);
      
      // 发送请求
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));
      
      _logger.d('Gemini API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        _logger.e('Gemini API Error: ${response.statusCode} - ${response.body}');
        return RecognitionResponse.error(
          error: 'API调用失败: ${response.statusCode}',
          method: RecognitionMethod.cloud,
        );
      }
    } catch (e) {
      _logger.e('Gemini API Exception: $e');
      return RecognitionResponse.error(
        error: '识别异常: $e',
        method: RecognitionMethod.cloud,
      );
    }
  }
  
  /// 构建Gemini API请求体
  Map<String, dynamic> _buildRequestBody(String imageBase64) {
    return {
      "contents": [
        {
          "parts": [
            {
              "text": _buildPlantIdentificationPrompt()
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": imageBase64
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1, // 低温度确保一致性
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 2048,
        "candidateCount": 1
      },
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH", 
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
    };
  }
  
  /// 构建植物识别的Prompt
  String _buildPlantIdentificationPrompt() {
    return '''
请仔细分析这张图片中的植物，识别植物种类。

要求：
1. 识别图片中的主要植物
2. 提供中文通俗名称
3. 简单描述植物特征
4. 给出识别的置信度评分(0-1)

请按照以下格式返回，保持极简：

植物名称: [中文植物名称]
学名: [拉丁学名]
置信度: [0-1之间的数值]
描述: [简单的植物描述，1-2句话]

示例：
植物名称: 绿萝
学名: Epipremnum aureum
置信度: 0.92
描述: 常见的室内观叶植物，叶片呈心形，颜色翠绿，具有很强的空气净化能力

如果图片中没有植物或无法识别，请返回：
识别结果: 非植物
描述: 图片中没有明显的植物特征

注意：
- 只返回上述格式的内容，不要包含其他文字
- 植物名称使用中文通俗名称
- 描述要简洁明了，不超过50字
- 置信度是0到1之间的小数
''';
  }
  
  /// 解析Gemini API响应
  RecognitionResponse _parseResponse(String responseBody) {
    try {
      final jsonResponse = json.decode(responseBody);
      
      // 检查响应格式
      if (jsonResponse['candidates'] == null || 
          jsonResponse['candidates'].isEmpty) {
        return RecognitionResponse.error(
          error: '无效的API响应格式',
          method: RecognitionMethod.cloud,
        );
      }
      
      final candidate = jsonResponse['candidates'][0];
      if (candidate['content'] == null || 
          candidate['content']['parts'] == null ||
          candidate['content']['parts'].isEmpty) {
        return RecognitionResponse.error(
          error: 'API返回空内容',
          method: RecognitionMethod.cloud,
        );
      }
      
      final textContent = candidate['content']['parts'][0]['text'];
      _logger.d('Gemini原始响应: $textContent');
      
      // 解析极简键值对格式（仿照本地模型）
      final recognitionResult = _parseSimpleResponse(textContent);
      if (recognitionResult == null) {
        return RecognitionResponse.error(
          error: '无法解析识别结果',
          method: RecognitionMethod.cloud,
        );
      }
      
      // 添加Gemini特有标签
      recognitionResult.tags.addAll(['Gemini API', '云端识别', '高精度']);
      
      _logger.i('✅[GeminiService] 识别成功');
      
      return RecognitionResponse.success(
        results: [recognitionResult],
        method: RecognitionMethod.cloud,
      );
      
    } catch (e) {
      _logger.e('解析响应失败: $e');
      return RecognitionResponse.error(
        error: '响应解析异常: $e',
        method: RecognitionMethod.cloud,
      );
    }
  }
  
  /// 解析简单的键值对响应（仿照本地模型格式）
  RecognitionResult? _parseSimpleResponse(String response) {
    try {
      // 检查是否是"非植物"响应
      if (response.contains('识别结果: 非植物') || 
          response.contains('非植物') || 
          response.toLowerCase().contains('not a plant')) {
        return null; // 非植物，返回null
      }
      
      // 解析键值对
      final Map<String, String> parsed = {};
      
      // 逐行解析
      final lines = response.split('\n');
      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();
            if (key.isNotEmpty && value.isNotEmpty) {
              parsed[key] = value;
            }
          }
        }
      }
      
      // 提取植物信息
      final name = parsed['植物名称'] ?? parsed['名称'] ?? '未知植物';
      final scientificName = parsed['学名'] ?? parsed['拉丁名'];
      final description = parsed['描述'] ?? parsed['简介'] ?? '这是一种植物';
      
      // 解析置信度
      double confidence = 0.5;
      final confidenceStr = parsed['置信度'] ?? parsed['信心'] ?? parsed['准确度'];
      if (confidenceStr != null) {
        try {
          confidence = double.parse(confidenceStr);
          confidence = confidence.clamp(0.0, 1.0); // 确保在有效范围内
        } catch (e) {
          _logger.w('无法解析置信度: $confidenceStr');
        }
      }
      
      // 创建RecognitionResult
      return RecognitionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        nickname: null,
        confidence: confidence,
        description: description,
        features: ['Gemini识别的植物特征'],
        safety: const SafetyInfo(
          level: SafetyLevel.unknown,
          description: '安全性信息请咨询专业人士',
          warnings: [],
        ),
        care: null, // 极简模式不提供养护信息
        season: null,
        locations: ['室内', '户外'],
        funFact: null,
        tags: [], // 会在上层添加Gemini标签
        scientificName: scientificName,
        family: null,
      );
      
    } catch (e) {
      _logger.e('解析简单响应失败: $e');
      return null;
    }
  }
  
  /// 测试连接
  Future<bool> testConnection() async {
    try {
      // 使用一个简单的请求测试连接
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": "Hello"}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('连接测试失败: $e');
      return false;
    }
  }
}