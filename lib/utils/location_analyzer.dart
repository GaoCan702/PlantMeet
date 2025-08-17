import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;

/// 位置信息分析工具
class LocationAnalyzer {
  
  /// 分析定位来源和质量
  static LocationAnalysis analyze({
    required double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
  }) {
    if (accuracy == null) {
      return LocationAnalysis(
        source: LocationSource.unknown,
        quality: LocationQuality.none,
        confidence: 0,
        description: '无位置信息',
      );
    }
    
    // 根据精度判断定位来源
    LocationSource source;
    LocationQuality quality;
    double confidence;
    String description;
    
    if (accuracy <= 5) {
      source = LocationSource.gpsHigh;
      quality = LocationQuality.excellent;
      confidence = 0.99;
      description = 'GPS定位(军用级)';
    } else if (accuracy <= 10) {
      source = LocationSource.gpsHigh;
      quality = LocationQuality.excellent;
      confidence = 0.95;
      description = 'GPS定位(高精度)';
    } else if (accuracy <= 20) {
      source = LocationSource.gps;
      quality = LocationQuality.good;
      confidence = 0.90;
      description = 'GPS定位(良好)';
    } else if (accuracy <= 50) {
      source = LocationSource.gps;
      quality = LocationQuality.moderate;
      confidence = 0.80;
      description = 'GPS定位(一般)';
    } else if (accuracy <= 100) {
      source = LocationSource.gpsWeak;
      quality = LocationQuality.fair;
      confidence = 0.60;
      description = 'GPS定位(信号弱)';
    } else if (accuracy <= 200) {
      source = LocationSource.hybrid;
      quality = LocationQuality.fair;
      confidence = 0.50;
      description = 'GPS+网络混合';
    } else if (accuracy <= 500) {
      source = LocationSource.wifi;
      quality = LocationQuality.poor;
      confidence = 0.40;
      description = 'WiFi定位';
    } else if (accuracy <= 1000) {
      source = LocationSource.wifi;
      quality = LocationQuality.poor;
      confidence = 0.30;
      description = 'WiFi定位(粗略)';
    } else if (accuracy <= 5000) {
      source = LocationSource.cell;
      quality = LocationQuality.veryPoor;
      confidence = 0.20;
      description = '基站定位';
    } else {
      source = LocationSource.cell;
      quality = LocationQuality.veryPoor;
      confidence = 0.10;
      description = '基站定位(极粗略)';
    }
    
    // 高度信息是GPS的强指标
    if (altitude != null && altitude != 0) {
      // 有高度信息，很可能是GPS
      if (source == LocationSource.hybrid || source == LocationSource.wifi) {
        source = LocationSource.gpsWeak;
        description += ' [有高度]';
        confidence = (confidence + 0.2).clamp(0, 1);
      }
    }
    
    // 速度信息也是GPS的指标
    if (speed != null && speed > 0) {
      if (source == LocationSource.wifi || source == LocationSource.cell) {
        source = LocationSource.hybrid;
        description += ' [有速度]';
        confidence = (confidence + 0.1).clamp(0, 1);
      }
    }
    
    // 航向信息
    if (heading != null && heading >= 0) {
      description += ' [有方向]';
      confidence = (confidence + 0.05).clamp(0, 1);
    }
    
    return LocationAnalysis(
      source: source,
      quality: quality,
      confidence: confidence,
      description: description,
      accuracy: accuracy,
      hasAltitude: altitude != null && altitude != 0,
      hasSpeed: speed != null && speed > 0,
      hasHeading: heading != null && heading >= 0,
    );
  }
  
  /// 从 Geolocator Position 分析
  static LocationAnalysis fromGeoPosition(Position position) {
    return analyze(
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
    );
  }
  
  /// 从 Location LocationData 分析
  static LocationAnalysis fromLocationData(loc.LocationData data) {
    return analyze(
      accuracy: data.accuracy,
      altitude: data.altitude,
      speed: data.speed,
      heading: data.heading,
      timestamp: data.time != null 
          ? DateTime.fromMillisecondsSinceEpoch(data.time!.toInt())
          : null,
    );
  }
  
  /// 获取定位建议
  static String getRecommendation(LocationAnalysis analysis) {
    switch (analysis.source) {
      case LocationSource.gpsHigh:
      case LocationSource.gps:
        return '✅ GPS定位正常，定位精确';
      
      case LocationSource.gpsWeak:
        return '⚠️ GPS信号弱，建议到开阔地带';
      
      case LocationSource.hybrid:
        return '⚠️ 混合定位，GPS可能被遮挡';
      
      case LocationSource.wifi:
        return '📶 WiFi定位，建议开启GPS获得更精确位置';
      
      case LocationSource.cell:
        return '📡 基站定位，请检查GPS是否开启，或到室外重试';
      
      case LocationSource.unknown:
        return '❌ 无法确定定位来源';
    }
  }
  
  /// 获取费用说明
  static String getCostExplanation(LocationAnalysis analysis) {
    switch (analysis.source) {
      case LocationSource.gpsHigh:
      case LocationSource.gps:
      case LocationSource.gpsWeak:
        return '🆓 GPS定位完全免费，不消耗流量';
      
      case LocationSource.hybrid:
        return '🆓 GPS为主，辅助定位可能消耗极少量流量(<1KB)';
      
      case LocationSource.wifi:
        return '📱 WiFi定位需要少量流量查询WiFi位置数据库';
      
      case LocationSource.cell:
        return '📱 基站定位需要少量流量查询基站位置';
      
      case LocationSource.unknown:
        return '❓ 未知定位方式';
    }
  }
}

/// 定位来源
enum LocationSource {
  gpsHigh,  // GPS高精度（<20米）
  gps,      // GPS标准（20-50米）
  gpsWeak,  // GPS弱信号（50-100米）
  hybrid,   // 混合定位（100-200米）
  wifi,     // WiFi定位（200-1000米）
  cell,     // 基站定位（>1000米）
  unknown,  // 未知
}

/// 定位质量
enum LocationQuality {
  excellent,  // 优秀（<10米）
  good,       // 良好（10-20米）
  moderate,   // 中等（20-50米）
  fair,       // 一般（50-200米）
  poor,       // 较差（200-1000米）
  veryPoor,   // 很差（>1000米）
  none,       // 无
}

/// 位置分析结果
class LocationAnalysis {
  final LocationSource source;
  final LocationQuality quality;
  final double confidence;  // 0-1，判断可信度
  final String description;
  final double? accuracy;
  final bool hasAltitude;
  final bool hasSpeed;
  final bool hasHeading;
  
  LocationAnalysis({
    required this.source,
    required this.quality,
    required this.confidence,
    required this.description,
    this.accuracy,
    this.hasAltitude = false,
    this.hasSpeed = false,
    this.hasHeading = false,
  });
  
  /// 是否确定是GPS定位
  bool get isDefinitelyGPS => 
      source == LocationSource.gpsHigh || 
      source == LocationSource.gps ||
      (source == LocationSource.gpsWeak && hasAltitude);
  
  /// 是否可能是GPS定位
  bool get isPossiblyGPS => 
      isDefinitelyGPS || 
      source == LocationSource.gpsWeak ||
      source == LocationSource.hybrid;
  
  /// 获取图标
  String get icon {
    switch (source) {
      case LocationSource.gpsHigh:
      case LocationSource.gps:
        return '🛰️';
      case LocationSource.gpsWeak:
        return '📡';
      case LocationSource.hybrid:
        return '📶';
      case LocationSource.wifi:
        return '📶';
      case LocationSource.cell:
        return '📱';
      case LocationSource.unknown:
        return '❓';
    }
  }
  
  /// 获取质量颜色（用于UI）
  int get colorValue {
    switch (quality) {
      case LocationQuality.excellent:
        return 0xFF4CAF50; // 绿色
      case LocationQuality.good:
        return 0xFF8BC34A; // 浅绿
      case LocationQuality.moderate:
        return 0xFFCDDC39; // 黄绿
      case LocationQuality.fair:
        return 0xFFFFEB3B; // 黄色
      case LocationQuality.poor:
        return 0xFFFF9800; // 橙色
      case LocationQuality.veryPoor:
        return 0xFFFF5722; // 深橙
      case LocationQuality.none:
        return 0xFF9E9E9E; // 灰色
    }
  }
}