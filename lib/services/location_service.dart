import 'dart:async';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart' as geo;

/// 统一的位置服务，智能切换多个位置库
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  LocationData? _lastLocationData;
  DateTime? _lastLocationTime;
  
  /// 获取位置信息（智能策略）
  Future<LocationResult?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
    bool useCache = true,
  }) async {
    try {
      // 1. 检查缓存的位置（5分钟内有效）
      if (useCache && _lastLocationData != null && _lastLocationTime != null) {
        final age = DateTime.now().difference(_lastLocationTime!);
        if (age.inMinutes < 5) {
          print('LocationService: 使用缓存位置（${age.inSeconds}秒前）');
          return LocationResult.fromLocationData(_lastLocationData!);
        }
      }

      // 2. 检查并请求权限
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('LocationService: 位置服务未启用');
          return _tryGeolocatorFallback();
        }
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          print('LocationService: 权限被拒绝');
          return _tryGeolocatorFallback();
        }
      }

      // 3. 配置位置精度（针对不同场景）
      await _location.changeSettings(
        accuracy: LocationAccuracy.balanced, // 平衡精度和耗电
        interval: 1000,
        distanceFilter: 10,
      );

      // 4. 获取位置（带超时）
      LocationData? locationData;
      
      try {
        // 先尝试快速获取（低精度）
        await _location.changeSettings(accuracy: LocationAccuracy.low);
        locationData = await _location.getLocation().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('快速定位超时'),
        );
        print('LocationService: 快速定位成功');
      } catch (e) {
        print('LocationService: 快速定位失败，尝试高精度');
        
        // 失败后尝试高精度
        await _location.changeSettings(accuracy: LocationAccuracy.high);
        locationData = await _location.getLocation().timeout(
          timeout,
          onTimeout: () => throw TimeoutException('高精度定位超时'),
        );
      }

      // locationData 不会为null，因为getLocation()会抛出异常而不是返回null
      // if (locationData != null) {  // 不需要这个检查
        _lastLocationData = locationData;
        _lastLocationTime = DateTime.now();
        print('LocationService: 定位成功 (${locationData.latitude}, ${locationData.longitude})');
      return LocationResult.fromLocationData(locationData);
      // }
    } catch (e) {
      print('LocationService: location库失败: $e');
    }

    // 5. 降级到 geolocator
    return _tryGeolocatorFallback();
  }

  /// 使用 geolocator 作为备用方案
  Future<LocationResult?> _tryGeolocatorFallback() async {
    try {
      print('LocationService: 尝试 geolocator 备用方案');
      
      // 检查服务和权限
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          return null;
        }
      }

      // 先尝试最后已知位置
      final lastKnown = await geo.Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 10) {
          print('LocationService: 使用geolocator最后已知位置');
          return LocationResult.fromGeoPosition(lastKnown);
        }
      }

      // 获取当前位置（逐步降低精度）
      for (final accuracy in [
        geo.LocationAccuracy.lowest,
        geo.LocationAccuracy.low,
        geo.LocationAccuracy.medium,
      ]) {
        try {
          final position = await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: const Duration(seconds: 5),
          ).timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('超时'),
          );
          
          print('LocationService: geolocator成功 (精度: $accuracy)');
          return LocationResult.fromGeoPosition(position);
        } catch (e) {
          print('LocationService: geolocator $accuracy 失败');
          continue;
        }
      }
    } catch (e) {
      print('LocationService: geolocator完全失败: $e');
    }

    return null;
  }

  /// 获取地址信息
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        
        if (place.country != null) parts.add(place.country!);
        if (place.administrativeArea != null) parts.add(place.administrativeArea!);
        if (place.locality != null) parts.add(place.locality!);
        if (place.subLocality != null) parts.add(place.subLocality!);
        if (place.thoroughfare != null) parts.add(place.thoroughfare!);
        if (place.name != null && place.name != place.thoroughfare) {
          parts.add(place.name!);
        }
        
        return parts.join(' ');
      }
    } catch (e) {
      print('LocationService: 地址解析失败: $e');
    }
    return null;
  }

  /// 清除缓存
  void clearCache() {
    _lastLocationData = null;
    _lastLocationTime = null;
  }
}

/// 统一的位置结果
class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;
  
  LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory LocationResult.fromLocationData(LocationData data) {
    return LocationResult(
      latitude: data.latitude!,
      longitude: data.longitude!,
      accuracy: data.accuracy,
      altitude: data.altitude,
      speed: data.speed,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data.time!.toInt()),
    );
  }
  
  factory LocationResult.fromGeoPosition(geo.Position position) {
    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      timestamp: position.timestamp,
    );
  }
  
  String get accuracyText {
    if (accuracy == null) return '未知';
    if (accuracy! < 20) return '精确';
    if (accuracy! < 50) return '较准确';
    if (accuracy! < 100) return '大概';
    return '粗略';
  }
  
  String toDisplayString() {
    return '📍 已定位 ($accuracyText)';
  }
  
  String toCoordinateString() {
    // 根据精度决定显示几位小数
    if (accuracy == null || accuracy! > 1000) {
      // 精度太差，只显示2位小数
      return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
    } else if (accuracy! > 100) {
      // 中等精度，显示3位小数
      return '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
    } else if (accuracy! > 50) {
      // 较好精度，显示4位小数
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } else {
      // 高精度，显示5位小数
      return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    }
  }
}