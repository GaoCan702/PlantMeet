import 'dart:async';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'location_service.dart';

/// 快速位置服务 - 优先速度而非精度
class FastLocationService {
  static final FastLocationService _instance = FastLocationService._internal();
  factory FastLocationService() => _instance;
  FastLocationService._internal();

  final Location _location = Location();
  
  // 缓存
  static LocationResult? _cachedResult;
  static DateTime? _cacheTime;
  static const Duration _cacheValidity = Duration(minutes: 10);
  
  // 后台改进位置的结果
  LocationResult? _improvedResult;
  StreamController<LocationResult>? _locationUpdateController;
  
  /// 获取快速位置（优先返回，后台改进）
  Future<LocationResult?> getQuickLocation({
    bool allowCache = true,
    bool improveInBackground = true,
  }) async {
    // 1. 立即返回缓存（如果有效）
    if (allowCache && _cachedResult != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheValidity) {
        print('FastLocation: 使用缓存 (${age.inSeconds}秒前)');
        
        // 后台尝试改进位置
        if (improveInBackground) {
          _improveLocationInBackground();
        }
        
        return _cachedResult;
      }
    }
    
    // 2. 并行尝试多种方法，返回最快的
    final results = await Future.any([
      _getLastKnownPosition(),
      _getQuickNetworkLocation(),
      _getGeolocatorPosition(),
    ].map((future) => future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    )));
    
    if (results != null) {
      _updateCache(results);
      
      // 后台继续改进精度
      if (improveInBackground && (results.accuracy == null || results.accuracy! > 100)) {
        _improveLocationInBackground();
      }
      
      return results;
    }
    
    // 3. 如果都失败，返回任何可用的缓存
    return _cachedResult;
  }
  
  /// 获取最后已知位置（最快）
  Future<LocationResult?> _getLastKnownPosition() async {
    try {
      // Geolocator 的最后位置
      final geoLast = await geo.Geolocator.getLastKnownPosition();
      if (geoLast != null) {
        final age = DateTime.now().difference(geoLast.timestamp ?? DateTime.now());
        if (age.inMinutes < 30) {
          print('FastLocation: 使用最后已知位置');
          return LocationResult.fromGeoPosition(geoLast);
        }
      }
    } catch (e) {
      print('FastLocation: 获取最后位置失败: $e');
    }
    return null;
  }
  
  /// 快速网络定位
  Future<LocationResult?> _getQuickNetworkLocation() async {
    try {
      // 检查权限（快速）
      final hasPermission = await _location.hasPermission();
      if (hasPermission == PermissionStatus.denied || 
          hasPermission == PermissionStatus.deniedForever) {
        return null;
      }
      
      // 设置最低精度（最快）
      await _location.changeSettings(
        accuracy: LocationAccuracy.low,
        interval: 100,
        distanceFilter: 0,
      );
      
      // 快速获取
      final locationData = await _location.getLocation().timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('网络定位超时'),
      );
      
      print('FastLocation: 网络定位成功');
      return LocationResult.fromLocationData(locationData);
    } catch (e) {
      print('FastLocation: 网络定位失败: $e');
      return null;
    }
  }
  
  /// 使用 Geolocator 获取
  Future<LocationResult?> _getGeolocatorPosition() async {
    try {
      // 检查服务
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      
      // 检查权限
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        return null;
      }
      
      // 使用最低精度快速获取
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.lowest,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 2),
      );
      
      print('FastLocation: Geolocator定位成功');
      return LocationResult.fromGeoPosition(position);
    } catch (e) {
      print('FastLocation: Geolocator失败: $e');
      return null;
    }
  }
  
  /// 后台改进位置精度
  Future<void> _improveLocationInBackground() async {
    print('FastLocation: 后台改进位置精度...');
    
    try {
      // 尝试获取高精度位置
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 5,
      );
      
      final improvedData = await _location.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('高精度超时'),
      );
      
      final improvedResult = LocationResult.fromLocationData(improvedData);
      
      // 只有精度更好时才更新
      if (_cachedResult == null || 
          improvedResult.accuracy == null ||
          (_cachedResult!.accuracy != null && 
           improvedResult.accuracy! < _cachedResult!.accuracy!)) {
        print('FastLocation: 位置精度改进成功');
        _updateCache(improvedResult);
        _improvedResult = improvedResult;
        
        // 通知监听者
        _locationUpdateController?.add(improvedResult);
      }
    } catch (e) {
      print('FastLocation: 后台改进失败: $e');
    }
  }
  
  /// 更新缓存
  void _updateCache(LocationResult result) {
    _cachedResult = result;
    _cacheTime = DateTime.now();
  }
  
  /// 获取位置更新流（用于监听后台改进）
  Stream<LocationResult> get locationUpdates {
    _locationUpdateController ??= StreamController<LocationResult>.broadcast();
    return _locationUpdateController!.stream;
  }
  
  /// 清理资源
  void dispose() {
    _locationUpdateController?.close();
  }
  
  /// 清除缓存
  void clearCache() {
    _cachedResult = null;
    _cacheTime = null;
    _improvedResult = null;
  }
  
  /// 预热服务（应用启动时调用）
  Future<void> warmup() async {
    try {
      // 预先检查权限
      await _location.hasPermission();
      await geo.Geolocator.checkPermission();
      
      // 预先获取最后位置
      await _getLastKnownPosition();
      
      print('FastLocation: 服务预热完成');
    } catch (e) {
      print('FastLocation: 预热失败: $e');
    }
  }
}