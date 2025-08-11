import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recognition_result.dart';
import '../models/app_settings.dart';
import '../models/plant_encounter.dart';

class RecognitionService {
  RecognitionService();

  void initialize(AppSettings settings) {
    // 简化初始化逻辑
  }

  void updateSettings(AppSettings settings) {
    // 简化更新逻辑
  }

  Future<RecognitionResponse> identifyPlant(
    File imageFile, 
    AppSettings settings,
  ) async {
    if (!settings.isConfigured) {
      return RecognitionResponse.error(
        error: '未配置识别服务',
        method: RecognitionMethod.local,
      );
    }

    try {
      return await _identifyWithAPI(imageFile, settings);
    } catch (e) {
      return RecognitionResponse.error(
        error: '识别失败: $e',
        method: RecognitionMethod.local,
      );
    }
  }

  Future<RecognitionResponse> _identifyWithAPI(
    File imageFile, 
    AppSettings settings,
  ) async {
    try {
      final uri = Uri.parse(settings.baseUrl!);
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer ${settings.apiKey}',
        'Content-Type': 'multipart/form-data',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      if (settings.baseUrl!.contains('mnnchat')) {
        // MNN Chat 特定参数
        request.fields['model'] = 'plant-recognition';
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        return RecognitionResponse.error(
          error: 'API请求失败: ${response.statusCode} - $responseBody',
          method: RecognitionMethod.local,
        );
      }

      final jsonResponse = jsonDecode(responseBody);
      
      // 尝试解析不同的响应格式
      if (settings.baseUrl!.contains('mnnchat')) {
        return _parseMNNChatResponse(jsonResponse);
      } else {
        return _parseGenericResponse(jsonResponse);
      }
    } catch (e) {
      return RecognitionResponse.error(
        error: 'API调用失败: $e',
        method: RecognitionMethod.local,
      );
    }
  }

  RecognitionResponse _parseMNNChatResponse(Map<String, dynamic> json) {
    try {
      final results = <RecognitionResult>[];
      
      if (json['results'] != null) {
        for (var result in json['results']) {
          results.add(RecognitionResult(
            speciesId: result['species_id'] ?? result['id'] ?? 'unknown',
            scientificName: result['scientific_name'] ?? 'Unknown',
            commonName: result['common_name'] ?? result['name'] ?? 'Unknown',
            confidence: (result['confidence'] ?? 0.0).toDouble(),
            description: result['description'],
            isToxic: result['is_toxic'] ?? false,
            toxicityInfo: result['toxicity_info'],
          ));
        }
      }

      return RecognitionResponse(
        success: true,
        results: results,
        method: RecognitionMethod.local,
      );
    } catch (e) {
      return RecognitionResponse.error(
        error: '解析MNN Chat响应失败: $e',
        method: RecognitionMethod.local,
      );
    }
  }

  RecognitionResponse _parseGenericResponse(Map<String, dynamic> json) {
    try {
      final results = <RecognitionResult>[];
      
      // 尝试不同的响应格式
      List<dynamic> candidates = [];
      
      if (json['predictions'] != null) {
        candidates = json['predictions'];
      } else if (json['results'] != null) {
        candidates = json['results'];
      } else if (json['candidates'] != null) {
        candidates = json['candidates'];
      }

      for (var candidate in candidates) {
        results.add(RecognitionResult(
          speciesId: candidate['species_id'] ?? candidate['id'] ?? 'unknown',
          scientificName: candidate['scientific_name'] ?? candidate['species'] ?? 'Unknown',
          commonName: candidate['common_name'] ?? candidate['name'] ?? 'Unknown',
          confidence: (candidate['confidence'] ?? candidate['score'] ?? 0.0).toDouble(),
          description: candidate['description'],
          isToxic: candidate['is_toxic'] ?? false,
          toxicityInfo: candidate['toxicity_info'],
        ));
      }

      return RecognitionResponse(
        success: true,
        results: results,
        method: RecognitionMethod.local,
      );
    } catch (e) {
      return RecognitionResponse.error(
        error: '解析通用响应失败: $e',
        method: RecognitionMethod.local,
      );
    }
  }

  Future<bool> testConnection(AppSettings settings) async {
    if (!settings.isConfigured) {
      return false;
    }

    try {
      final uri = Uri.parse(settings.baseUrl!);
      
      // 尝试一个简单的GET请求来测试连接
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${settings.apiKey}',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 401; // 401说明连接正常但认证失败
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    // 清理资源
  }
}