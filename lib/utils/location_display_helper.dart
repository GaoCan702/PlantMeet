/// 位置显示辅助类 - 根据精度智能决定显示内容
class LocationDisplayHelper {
  
  /// 根据精度获取合适的位置显示文本
  static String getDisplayText({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
  }) {
    // 无位置信息
    if (latitude == null || longitude == null) {
      return '位置未记录';
    }
    
    // 根据精度决定显示策略
    if (accuracy == null) {
      // 精度未知，显示模糊信息
      return _getRegionFromCoordinates(latitude, longitude);
    }
    
    // 精度分级显示
    if (accuracy < 50) {
      // GPS高精度 - 可以显示详细地址或坐标
      if (address != null && address.isNotEmpty) {
        return _formatDetailedAddress(address);
      }
      return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
      
    } else if (accuracy < 200) {
      // GPS中等精度 - 显示街道/社区级别
      if (address != null && address.isNotEmpty) {
        return _formatStreetLevel(address);
      }
      return _getDistrictFromCoordinates(latitude, longitude);
      
    } else if (accuracy < 1000) {
      // WiFi定位 - 显示区域级别
      if (address != null && address.isNotEmpty) {
        return _formatDistrictLevel(address);
      }
      return _getDistrictFromCoordinates(latitude, longitude);
      
    } else if (accuracy < 5000) {
      // 基站定位(3km精度) - 只显示城市
      return _getCityFromCoordinates(latitude, longitude);
      
    } else {
      // 极差精度 - 只显示省份
      return _getProvinceFromCoordinates(latitude, longitude);
    }
  }
  
  /// 获取简短显示（用于卡片）
  static String getShortDisplay({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
  }) {
    if (latitude == null || longitude == null) {
      return '未记录';
    }
    
    // 3km精度的情况
    if (accuracy != null && accuracy > 2000) {
      // 只显示城市名
      return _getCityFromCoordinates(latitude, longitude);
    }
    
    // 较好精度
    if (accuracy != null && accuracy < 500) {
      if (address != null && address.isNotEmpty) {
        // 提取关键地名
        return _extractKeyLocation(address);
      }
    }
    
    // 默认显示区域
    return _getDistrictFromCoordinates(latitude, longitude);
  }
  
  /// 格式化详细地址（高精度时使用）
  static String _formatDetailedAddress(String address) {
    // 保留详细信息
    return address;
  }
  
  /// 格式化街道级地址（中等精度）
  static String _formatStreetLevel(String address) {
    // 移除门牌号等详细信息
    final parts = address.split(' ');
    if (parts.length > 4) {
      return parts.sublist(0, 4).join(' ');
    }
    return address;
  }
  
  /// 格式化区域级地址（低精度）
  static String _formatDistrictLevel(String address) {
    // 只保留区县信息
    final parts = address.split(' ');
    if (parts.length > 3) {
      return parts.sublist(0, 3).join(' ');
    }
    return address;
  }
  
  /// 从地址中提取关键位置
  static String _extractKeyLocation(String address) {
    // 查找地标性位置
    final landmarks = [
      '公园', '广场', '大学', '学校', '医院', '商场', '市场',
      '地铁站', '车站', '机场', '体育馆', '博物馆', '图书馆',
      '寺', '庙', '教堂', '清真寺', '湖', '山', '河', '桥',
    ];
    
    for (final landmark in landmarks) {
      if (address.contains(landmark)) {
        final index = address.indexOf(landmark);
        if (index > 0) {
          // 提取地标名称
          final start = index - 10 < 0 ? 0 : index - 10;
          final end = index + landmark.length + 5 > address.length 
              ? address.length 
              : index + landmark.length + 5;
          final extracted = address.substring(start, end).trim();
          // 清理多余字符
          return extracted.replaceAll(RegExp(r'[，。、]'), '');
        }
      }
    }
    
    // 没有地标，返回简化地址
    return _formatDistrictLevel(address);
  }
  
  /// 根据坐标获取城市（3km精度时的主要方法）
  static String _getCityFromCoordinates(double latitude, double longitude) {
    // 中国主要城市判断
    if (_isNearCity(latitude, longitude, 31.23, 121.47, 0.3)) {
      return '上海';
    } else if (_isNearCity(latitude, longitude, 39.90, 116.40, 0.3)) {
      return '北京';
    } else if (_isNearCity(latitude, longitude, 23.13, 113.26, 0.3)) {
      return '广州';
    } else if (_isNearCity(latitude, longitude, 22.54, 114.06, 0.3)) {
      return '深圳';
    } else if (_isNearCity(latitude, longitude, 30.29, 120.16, 0.2)) {
      return '杭州';
    } else if (_isNearCity(latitude, longitude, 31.30, 120.62, 0.15)) {
      return '苏州';
    } else if (_isNearCity(latitude, longitude, 32.06, 118.78, 0.2)) {
      return '南京';
    } else if (_isNearCity(latitude, longitude, 31.17, 121.43, 0.15)) {
      return '上海浦东';
    } else if (_isNearCity(latitude, longitude, 31.32, 120.62, 0.1)) {
      return '苏州工业园区';
    } else if (_isNearCity(latitude, longitude, 31.37, 120.95, 0.15)) {
      return '昆山';
    } else if (_isNearCity(latitude, longitude, 31.81, 119.97, 0.15)) {
      return '常州';
    } else if (_isNearCity(latitude, longitude, 31.49, 120.31, 0.15)) {
      return '无锡';
    } else if (_isNearCity(latitude, longitude, 30.57, 104.06, 0.3)) {
      return '成都';
    } else if (_isNearCity(latitude, longitude, 29.56, 106.55, 0.3)) {
      return '重庆';
    } else if (_isNearCity(latitude, longitude, 34.26, 108.93, 0.3)) {
      return '西安';
    } else if (_isNearCity(latitude, longitude, 30.59, 114.30, 0.3)) {
      return '武汉';
    } else if (_isNearCity(latitude, longitude, 28.19, 112.98, 0.2)) {
      return '长沙';
    } else if (_isNearCity(latitude, longitude, 36.06, 120.38, 0.2)) {
      return '青岛';
    } else if (_isNearCity(latitude, longitude, 38.91, 121.61, 0.2)) {
      return '大连';
    } else if (_isNearCity(latitude, longitude, 41.80, 123.43, 0.2)) {
      return '沈阳';
    } else if (_isNearCity(latitude, longitude, 43.82, 125.32, 0.2)) {
      return '长春';
    } else if (_isNearCity(latitude, longitude, 45.75, 126.64, 0.2)) {
      return '哈尔滨';
    } else if (_isNearCity(latitude, longitude, 37.86, 112.56, 0.2)) {
      return '太原';
    } else if (_isNearCity(latitude, longitude, 38.04, 114.51, 0.2)) {
      return '石家庄';
    } else if (_isNearCity(latitude, longitude, 36.65, 116.99, 0.2)) {
      return '济南';
    } else if (_isNearCity(latitude, longitude, 34.75, 113.66, 0.2)) {
      return '郑州';
    } else if (_isNearCity(latitude, longitude, 31.86, 117.28, 0.2)) {
      return '合肥';
    } else if (_isNearCity(latitude, longitude, 28.68, 115.89, 0.2)) {
      return '南昌';
    } else if (_isNearCity(latitude, longitude, 26.07, 119.30, 0.2)) {
      return '福州';
    } else if (_isNearCity(latitude, longitude, 24.48, 118.10, 0.2)) {
      return '厦门';
    } else if (_isNearCity(latitude, longitude, 25.04, 102.71, 0.2)) {
      return '昆明';
    } else if (_isNearCity(latitude, longitude, 26.57, 106.71, 0.2)) {
      return '贵阳';
    } else if (_isNearCity(latitude, longitude, 22.82, 108.32, 0.2)) {
      return '南宁';
    } else if (_isNearCity(latitude, longitude, 20.04, 110.34, 0.2)) {
      return '海口';
    } else if (_isNearCity(latitude, longitude, 36.19, 117.12, 0.15)) {
      return '泰安';
    }
    
    // 返回省份
    return _getProvinceFromCoordinates(latitude, longitude);
  }
  
  /// 根据坐标获取区域
  static String _getDistrictFromCoordinates(double latitude, double longitude) {
    // 苏州周边的详细判断
    if (latitude > 31.2 && latitude < 31.4 && longitude > 120.5 && longitude < 120.7) {
      if (longitude > 120.62) {
        return '苏州工业园区';
      } else {
        return '苏州市区';
      }
    }
    
    // 其他城市返回城市名
    return _getCityFromCoordinates(latitude, longitude);
  }
  
  /// 根据坐标获取地区
  static String _getRegionFromCoordinates(double latitude, double longitude) {
    if (latitude > 29 && latitude < 35 && longitude > 118 && longitude < 123) {
      return '长三角地区';
    } else if (latitude > 37 && latitude < 41 && longitude > 114 && longitude < 120) {
      return '京津冀地区';
    } else if (latitude > 21 && latitude < 25 && longitude > 112 && longitude < 117) {
      return '珠三角地区';
    }
    return '中国';
  }
  
  /// 根据坐标获取省份
  static String _getProvinceFromCoordinates(double latitude, double longitude) {
    if (latitude > 30.5 && latitude < 32.5 && longitude > 119 && longitude < 122) {
      return '江苏省';
    } else if (latitude > 29 && latitude < 32 && longitude > 118 && longitude < 123) {
      return '江浙沪';
    } else if (latitude > 39 && latitude < 42 && longitude > 115 && longitude < 118) {
      return '北京市';
    } else if (latitude > 30 && latitude < 32 && longitude > 120 && longitude < 122) {
      return '上海市';
    } else if (latitude > 22 && latitude < 24 && longitude > 112 && longitude < 115) {
      return '广东省';
    }
    
    return _getRegionFromCoordinates(latitude, longitude);
  }
  
  /// 判断是否在城市附近
  static bool _isNearCity(
    double lat,
    double lon,
    double cityLat,
    double cityLon,
    double threshold,
  ) {
    final dLat = (lat - cityLat).abs();
    final dLon = (lon - cityLon).abs();
    return dLat < threshold && dLon < threshold;
  }
  
  /// 获取精度描述（用于调试）
  static String getAccuracyDescription(double? accuracy) {
    if (accuracy == null) return '';
    
    if (accuracy < 50) {
      return 'GPS定位';
    } else if (accuracy < 200) {
      return 'GPS弱信号';
    } else if (accuracy < 1000) {
      return 'WiFi定位';
    } else if (accuracy < 5000) {
      return '基站定位';
    } else {
      return '粗略定位';
    }
  }
}