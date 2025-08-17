import 'dart:math';

/// 位置信息格式化工具
class LocationFormatter {
  
  /// 根据精度智能格式化位置显示
  static String formatLocationByAccuracy({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? address,
  }) {
    // 如果有地址，优先显示地址
    if (address != null && address.isNotEmpty) {
      return address;
    }
    
    // 根据精度决定显示精度
    if (accuracy == null) {
      return _formatCoordinates(latitude, longitude, 2); // 未知精度，显示2位小数
    }
    
    if (accuracy < 10) {
      // GPS高精度：显示6位小数（精确到0.1米）
      return _formatCoordinates(latitude, longitude, 6);
    } else if (accuracy < 50) {
      // GPS良好：显示5位小数（精确到1米）
      return _formatCoordinates(latitude, longitude, 5);
    } else if (accuracy < 100) {
      // GPS一般：显示4位小数（精确到10米）
      return _formatCoordinates(latitude, longitude, 4);
    } else if (accuracy < 500) {
      // WiFi定位：显示3位小数（精确到100米）
      return _formatCoordinates(latitude, longitude, 3);
    } else if (accuracy < 1000) {
      // 粗略定位：显示2位小数（精确到1公里）
      return _formatCoordinates(latitude, longitude, 2);
    } else if (accuracy < 5000) {
      // 基站定位：只显示大概区域
      return _getApproximateLocation(latitude, longitude);
    } else {
      // 极粗略：只显示城市级别
      return _getCityLevelLocation(latitude, longitude);
    }
  }
  
  /// 格式化坐标
  static String _formatCoordinates(double lat, double lon, int decimals) {
    final latStr = lat.toStringAsFixed(decimals);
    final lonStr = lon.toStringAsFixed(decimals);
    return '$latStr, $lonStr';
  }
  
  /// 获取大概位置描述（区域级）
  static String _getApproximateLocation(double latitude, double longitude) {
    // 中国主要城市的大概范围
    if (_isNearLocation(latitude, longitude, 31.23, 121.47, 0.5)) {
      return '上海市区附近';
    } else if (_isNearLocation(latitude, longitude, 39.90, 116.40, 0.5)) {
      return '北京市区附近';
    } else if (_isNearLocation(latitude, longitude, 23.13, 113.26, 0.5)) {
      return '广州市区附近';
    } else if (_isNearLocation(latitude, longitude, 30.29, 120.16, 0.5)) {
      return '杭州市区附近';
    } else if (_isNearLocation(latitude, longitude, 31.30, 120.62, 0.3)) {
      return '苏州市区附近';
    } else if (_isNearLocation(latitude, longitude, 32.06, 118.78, 0.5)) {
      return '南京市区附近';
    } else if (_isNearLocation(latitude, longitude, 22.54, 114.06, 0.5)) {
      return '深圳市区附近';
    } else if (_isNearLocation(latitude, longitude, 30.57, 104.06, 0.5)) {
      return '成都市区附近';
    } else if (_isNearLocation(latitude, longitude, 29.56, 106.55, 0.5)) {
      return '重庆市区附近';
    } else if (_isNearLocation(latitude, longitude, 34.26, 108.93, 0.5)) {
      return '西安市区附近';
    } else if (_isNearLocation(latitude, longitude, 36.06, 120.38, 0.5)) {
      return '青岛市区附近';
    } else if (_isNearLocation(latitude, longitude, 38.91, 121.61, 0.5)) {
      return '大连市区附近';
    } else if (_isNearLocation(latitude, longitude, 43.82, 125.32, 0.5)) {
      return '长春市区附近';
    } else if (_isNearLocation(latitude, longitude, 45.75, 126.64, 0.5)) {
      return '哈尔滨市区附近';
    } else {
      // 按省份范围判断
      return _getProvinceLevelLocation(latitude, longitude);
    }
  }
  
  /// 获取城市级别位置
  static String _getCityLevelLocation(double latitude, double longitude) {
    // 更粗略的位置，只显示省份
    return _getProvinceLevelLocation(latitude, longitude);
  }
  
  /// 获取省份级别位置
  static String _getProvinceLevelLocation(double latitude, double longitude) {
    // 简单的省份判断
    if (latitude > 35 && latitude < 42 && longitude > 113 && longitude < 120) {
      return '华北地区';
    } else if (latitude > 29 && latitude < 35 && longitude > 117 && longitude < 123) {
      return '华东地区';
    } else if (latitude > 20 && latitude < 27 && longitude > 108 && longitude < 117) {
      return '华南地区';
    } else if (latitude > 28 && latitude < 34 && longitude > 102 && longitude < 110) {
      return '西南地区';
    } else if (latitude > 35 && latitude < 50 && longitude > 120 && longitude < 135) {
      return '东北地区';
    } else if (latitude > 35 && latitude < 42 && longitude > 95 && longitude < 110) {
      return '西北地区';
    } else if (latitude > 25 && latitude < 35 && longitude > 110 && longitude < 117) {
      return '华中地区';
    } else {
      return '中国';
    }
  }
  
  /// 判断是否在某个位置附近
  static bool _isNearLocation(
    double lat,
    double lon,
    double targetLat,
    double targetLon,
    double threshold,
  ) {
    final distance = _calculateDistance(lat, lon, targetLat, targetLon);
    return distance < threshold;
  }
  
  /// 计算两点间的距离（度）
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = (lat2 - lat1).abs();
    final dLon = (lon2 - lon1).abs();
    return sqrt(dLat * dLat + dLon * dLon);
  }
  
  /// 获取友好的精度描述
  static String getAccuracyDescription(double? accuracy) {
    if (accuracy == null) return '未知精度';
    
    if (accuracy < 5) {
      return '极精确 (±${accuracy.toStringAsFixed(0)}米)';
    } else if (accuracy < 10) {
      return '高精度 (±${accuracy.toStringAsFixed(0)}米)';
    } else if (accuracy < 30) {
      return '精确 (±${accuracy.toStringAsFixed(0)}米)';
    } else if (accuracy < 50) {
      return '较准确 (±${accuracy.toStringAsFixed(0)}米)';
    } else if (accuracy < 100) {
      return '一般 (±${accuracy.toStringAsFixed(0)}米)';
    } else if (accuracy < 500) {
      return '粗略 (±${(accuracy / 100).toStringAsFixed(0)}百米)';
    } else if (accuracy < 1000) {
      return '很粗略 (±${(accuracy / 100).toStringAsFixed(0)}百米)';
    } else if (accuracy < 5000) {
      return '仅供参考 (±${(accuracy / 1000).toStringAsFixed(1)}公里)';
    } else {
      return '位置不准确 (±${(accuracy / 1000).toStringAsFixed(0)}公里)';
    }
  }
  
  /// 获取隐私保护的位置显示
  static String getPrivacyProtectedLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? address,
  }) {
    // 如果精度太差，不显示具体坐标
    if (accuracy != null && accuracy > 1000) {
      // 只显示大概区域
      return _getApproximateLocation(latitude, longitude);
    }
    
    // 如果有地址，模糊化处理
    if (address != null && address.isNotEmpty) {
      // 移除详细门牌号等信息
      final parts = address.split(' ');
      if (parts.length > 3) {
        // 只保留前3个部分（通常是省市区）
        return parts.take(3).join(' ');
      }
      return address;
    }
    
    // 根据精度决定坐标显示精度
    return formatLocationByAccuracy(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }
  
  /// 格式化为用户友好的显示
  static String formatForDisplay({
    required double? latitude,
    required double? longitude,
    double? accuracy,
    String? address,
    bool showAccuracy = true,
  }) {
    if (latitude == null || longitude == null) {
      return '位置未知';
    }
    
    String result = '';
    
    // 根据精度选择显示方式
    if (accuracy != null && accuracy > 1000) {
      // 精度太差，显示大概位置
      result = _getApproximateLocation(latitude, longitude);
      
      if (showAccuracy) {
        result += '\n${getAccuracyDescription(accuracy)}';
      }
    } else if (address != null && address.isNotEmpty) {
      // 有地址，优先显示地址
      result = address;
      
      if (showAccuracy && accuracy != null && accuracy < 100) {
        // 只有精度较好时才显示坐标
        result += '\n${formatLocationByAccuracy(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
        )}';
      }
    } else {
      // 显示坐标
      result = formatLocationByAccuracy(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
      
      if (showAccuracy && accuracy != null) {
        result += '\n${getAccuracyDescription(accuracy)}';
      }
    }
    
    return result;
  }
}