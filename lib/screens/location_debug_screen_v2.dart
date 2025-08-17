import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import '../services/location_service.dart';
import '../utils/location_analyzer.dart';

class LocationDebugScreenV2 extends StatefulWidget {
  const LocationDebugScreenV2({super.key});

  @override
  State<LocationDebugScreenV2> createState() => _LocationDebugScreenV2State();
}

class _LocationDebugScreenV2State extends State<LocationDebugScreenV2> {
  final List<String> _logs = [];
  final LocationService _locationService = LocationService();
  final loc.Location _location = loc.Location();
  
  bool _isTesting = false;
  LocationResult? _lastLocationResult;
  String? _lastAddress;
  
  @override
  void initState() {
    super.initState();
    _runFullDiagnostic();
  }
  
  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }
  
  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isTesting = true;
      _logs.clear();
      _lastLocationResult = null;
      _lastAddress = null;
    });
    
    _addLog('========== 开始位置服务诊断 ==========');
    _addLog('设备平台: ${Platform.operatingSystem}');
    _addLog('设备版本: ${Platform.operatingSystemVersion}');
    
    // 1. 测试新的 LocationService
    _addLog('');
    _addLog('【测试新位置服务 LocationService】');
    try {
      _addLog('使用智能策略获取位置...');
      final startTime = DateTime.now();
      
      final result = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 20),
        useCache: false, // 不使用缓存，测试真实获取
      );
      
      final elapsed = DateTime.now().difference(startTime);
      
      if (result != null) {
        _addLog('✅ 成功获取位置 (耗时: ${elapsed.inSeconds}秒)');
        _addLog('  纬度: ${result.latitude}');
        _addLog('  经度: ${result.longitude}');
        _addLog('  精度: ${result.accuracy?.toStringAsFixed(1)}米 (${result.accuracyText})');
        _addLog('  海拔: ${result.altitude?.toStringAsFixed(1)}米');
        
        setState(() {
          _lastLocationResult = result;
        });
        
        // 尝试获取地址
        _addLog('尝试解析地址...');
        try {
          final address = await _locationService.getAddressFromCoordinates(
            result.latitude,
            result.longitude,
          );
          if (address != null) {
            _addLog('✅ 地址: $address');
            setState(() {
              _lastAddress = address;
            });
          } else {
            _addLog('⚠️ 无法解析地址');
          }
        } catch (e) {
          _addLog('❌ 地址解析失败: ${e.toString().substring(0, 50)}');
        }
      } else {
        _addLog('❌ LocationService 无法获取位置');
      }
    } catch (e) {
      _addLog('❌ LocationService 错误: ${e.toString()}');
    }
    
    // 2. 分别测试 location 库
    _addLog('');
    _addLog('【测试 location 库（优先）】');
    await _testLocationPackage();
    
    // 3. 分别测试 geolocator 库
    _addLog('');
    _addLog('【测试 geolocator 库（备用）】');
    await _testGeolocatorPackage();
    
    // 4. 测试权限状态
    _addLog('');
    _addLog('【权限状态检查】');
    await _checkPermissions();
    
    _addLog('');
    _addLog('========== 诊断完成 ==========');
    
    setState(() {
      _isTesting = false;
    });
  }
  
  Future<void> _testLocationPackage() async {
    try {
      // 检查服务状态
      bool serviceEnabled = await _location.serviceEnabled();
      _addLog('位置服务: ${serviceEnabled ? "✅ 已启用" : "❌ 未启用"}');
      
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        _addLog('请求开启服务: ${serviceEnabled ? "✅ 成功" : "❌ 失败"}');
      }
      
      // 检查权限
      loc.PermissionStatus permission = await _location.hasPermission();
      _addLog('当前权限: $permission');
      
      if (permission == loc.PermissionStatus.denied) {
        permission = await _location.requestPermission();
        _addLog('请求权限结果: $permission');
      }
      
      if (permission == loc.PermissionStatus.granted ||
          permission == loc.PermissionStatus.grantedLimited) {
        // 测试不同精度 - 不要break，测试所有精度级别
        final accuracies = [
          (loc.LocationAccuracy.low, '低精度'),
          (loc.LocationAccuracy.balanced, '平衡'),
          (loc.LocationAccuracy.high, '高精度'),
          (loc.LocationAccuracy.navigation, '导航级'),
        ];
        
        for (var (accuracy, name) in accuracies) {
          try {
            await _location.changeSettings(
              accuracy: accuracy,
              interval: 1000,
              distanceFilter: 0, // 无距离过滤
            );
            
            _addLog('尝试 $name...');
            final stopwatch = Stopwatch()..start();
            final locationData = await _location.getLocation().timeout(
              const Duration(seconds: 15), // 给高精度更多时间
              onTimeout: () => throw TimeoutException('超时'),
            );
            stopwatch.stop();
            
            _addLog('✅ $name成功 (${stopwatch.elapsed.inSeconds}秒)');
            _addLog('  坐标: (${locationData.latitude?.toStringAsFixed(4)}, ${locationData.longitude?.toStringAsFixed(4)})');
            _addLog('  精度: ${locationData.accuracy?.toStringAsFixed(1)}米');
            
            // 如果精度小于50米，说明GPS已激活
            if (locationData.accuracy != null && locationData.accuracy! < 50) {
              _addLog('  🎯 GPS已激活！');
            }
          } catch (e) {
            _addLog('❌ $name失败: ${e.toString().substring(0, 50)}');
          }
        }
      }
    } catch (e) {
      _addLog('❌ location库测试失败: $e');
    }
  }
  
  Future<void> _testGeolocatorPackage() async {
    try {
      // 检查服务
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      _addLog('位置服务: ${serviceEnabled ? "✅ 已启用" : "❌ 未启用"}');
      
      // 检查权限
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      _addLog('当前权限: $permission');
      
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        _addLog('请求权限结果: $permission');
      }
      
      // 获取最后已知位置
      final lastKnown = await geo.Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _addLog('✅ 最后已知位置:');
        _addLog('  坐标: (${lastKnown.latitude.toStringAsFixed(4)}, ${lastKnown.longitude.toStringAsFixed(4)})');
        _addLog('  时间: ${lastKnown.timestamp}');
      } else {
        _addLog('⚠️ 无最后已知位置');
      }
      
      // 测试不同精度级别
      if (permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always) {
        
        final accuracies = [
          (geo.LocationAccuracy.lowest, '最低'),
          (geo.LocationAccuracy.low, '低'),
          (geo.LocationAccuracy.medium, '中'),
          (geo.LocationAccuracy.high, '高'),
          (geo.LocationAccuracy.best, '最佳'),
          (geo.LocationAccuracy.bestForNavigation, '导航'),
        ];
        
        for (var (accuracy, name) in accuracies) {
          try {
            _addLog('尝试 $name精度...');
            final stopwatch = Stopwatch()..start();
            final position = await geo.Geolocator.getCurrentPosition(
              desiredAccuracy: accuracy,
              forceAndroidLocationManager: accuracy == geo.LocationAccuracy.bestForNavigation,
              timeLimit: const Duration(seconds: 10),
            ).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('超时'),
            );
            stopwatch.stop();
            
            _addLog('✅ $name成功 (${stopwatch.elapsed.inSeconds}秒)');
            _addLog('  坐标: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})');
            _addLog('  精度: ${position.accuracy.toStringAsFixed(1)}米');
            _addLog('  海拔: ${position.altitude}米');
            _addLog('  速度: ${position.speed}米/秒');
            
            // 使用分析器详细判断
            final analysis = LocationAnalyzer.fromGeoPosition(position);
            _addLog('  ${analysis.icon} ${analysis.description}');
            _addLog('  置信度: ${(analysis.confidence * 100).toStringAsFixed(0)}%');
            
            if (analysis.isDefinitelyGPS) {
              _addLog('  ✅ 确认是GPS定位！');
            } else if (analysis.isPossiblyGPS) {
              _addLog('  ⚠️ 可能是GPS混合定位');
            } else {
              _addLog('  ❌ 非GPS定位');
            }
            _addLog('  ${LocationAnalyzer.getCostExplanation(analysis)}');
          } catch (e) {
            _addLog('❌ $name失败: ${e.toString().substring(0, 50)}');
          }
        }
      }
    } catch (e) {
      _addLog('❌ geolocator库测试失败: $e');
    }
  }
  
  Future<void> _checkPermissions() async {
    // Location 库权限
    try {
      final locPermission = await _location.hasPermission();
      _addLog('location库权限: $locPermission');
    } catch (e) {
      _addLog('location权限检查失败: $e');
    }
    
    // Geolocator 库权限
    try {
      final geoPermission = await geo.Geolocator.checkPermission();
      _addLog('geolocator库权限: $geoPermission');
      
      // 检查位置精度授权（iOS 14+）
      if (Platform.isIOS) {
        final accuracy = await geo.Geolocator.getLocationAccuracy();
        _addLog('iOS位置精度授权: $accuracy');
      }
    } catch (e) {
      _addLog('geolocator权限检查失败: $e');
    }
  }
  
  Future<void> _quickTest() async {
    _addLog('');
    _addLog('【快速测试】');
    
    setState(() {
      _lastLocationResult = null;
      _lastAddress = null;
    });
    
    try {
      final startTime = DateTime.now();
      final result = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 30),
        useCache: true,
      );
      final elapsed = DateTime.now().difference(startTime);
      
      if (result != null) {
        _addLog('✅ 成功 (${elapsed.inSeconds}秒): ${result.toDisplayString()}');
        setState(() {
          _lastLocationResult = result;
        });
        
        // 获取地址
        final address = await _locationService.getAddressFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (address != null) {
          _addLog('📍 地址: $address');
          setState(() {
            _lastAddress = address;
          });
        }
      } else {
        _addLog('❌ 无法获取位置');
      }
    } catch (e) {
      _addLog('❌ 错误: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置服务诊断 V2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isTesting ? null : _runFullDiagnostic,
          ),
        ],
      ),
      body: Column(
        children: [
          // 当前位置信息卡片
          if (_lastLocationResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '最新位置',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _lastLocationResult!.accuracyText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('纬度: ${_lastLocationResult!.latitude.toStringAsFixed(6)}'),
                  Text('经度: ${_lastLocationResult!.longitude.toStringAsFixed(6)}'),
                  if (_lastLocationResult!.accuracy != null)
                    Text('精度: ${_lastLocationResult!.accuracy!.toStringAsFixed(1)}米'),
                  if (_lastAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _lastAddress!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _quickTest,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('快速测试'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => geo.Geolocator.openLocationSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('位置设置'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('清除'),
                  ),
                ),
              ],
            ),
          ),
          
          // 进度指示器
          if (_isTesting)
            const LinearProgressIndicator(),
          
          // 日志列表
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: ListView.builder(
                reverse: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[_logs.length - 1 - index];
                  Color? textColor;
                  FontWeight fontWeight = FontWeight.normal;
                  
                  if (log.contains('✅')) {
                    textColor = Colors.green.shade700;
                  } else if (log.contains('❌')) {
                    textColor = Colors.red.shade700;
                  } else if (log.contains('⚠️')) {
                    textColor = Colors.orange.shade700;
                  } else if (log.contains('📍')) {
                    textColor = Colors.blue.shade700;
                  } else if (log.contains('【') && log.contains('】')) {
                    textColor = Colors.purple.shade700;
                    fontWeight = FontWeight.bold;
                  } else if (log.contains('=====')) {
                    textColor = Colors.black87;
                    fontWeight = FontWeight.bold;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: textColor,
                        fontWeight: fontWeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}