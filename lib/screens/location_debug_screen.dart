import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationDebugScreen extends StatefulWidget {
  const LocationDebugScreen({super.key});

  @override
  State<LocationDebugScreen> createState() => _LocationDebugScreenState();
}

class _LocationDebugScreenState extends State<LocationDebugScreen> {
  final List<String> _logs = [];
  bool _isTesting = false;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  
  @override
  void initState() {
    super.initState();
    _runFullDiagnostic();
  }
  
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
  
  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print('LocationDebug: $message');
  }
  
  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isTesting = true;
      _logs.clear();
    });
    
    _addLog('========== 开始位置服务诊断 ==========');
    _addLog('设备平台: ${Platform.operatingSystem}');
    _addLog('设备版本: ${Platform.operatingSystemVersion}');
    
    // 1. 检查位置服务状态
    try {
      _addLog('步骤1: 检查位置服务是否启用...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _addLog('位置服务状态: ${serviceEnabled ? "✅ 已启用" : "❌ 未启用"}');
      
      if (!serviceEnabled) {
        _addLog('⚠️ 请在设备设置中开启位置服务');
        return;
      }
    } catch (e) {
      _addLog('❌ 检查位置服务失败: $e');
    }
    
    // 2. 检查权限状态
    try {
      _addLog('步骤2: 检查位置权限...');
      LocationPermission permission = await Geolocator.checkPermission();
      _addLog('当前权限: $permission');
      
      if (permission == LocationPermission.denied) {
        _addLog('步骤2.1: 请求位置权限...');
        permission = await Geolocator.requestPermission();
        _addLog('权限请求结果: $permission');
      }
      
      if (permission == LocationPermission.deniedForever) {
        _addLog('❌ 位置权限被永久拒绝，请在设置中手动开启');
        return;
      }
      
      if (permission == LocationPermission.denied) {
        _addLog('❌ 位置权限被拒绝');
        return;
      }
      
      _addLog('✅ 位置权限已授予');
    } catch (e) {
      _addLog('❌ 权限检查失败: $e');
    }
    
    // 3. 尝试获取最后已知位置
    try {
      _addLog('步骤3: 获取最后已知位置...');
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _addLog('✅ 最后已知位置:');
        _addLog('  纬度: ${lastKnown.latitude}');
        _addLog('  经度: ${lastKnown.longitude}');
        _addLog('  精度: ${lastKnown.accuracy}米');
        _addLog('  时间: ${lastKnown.timestamp}');
      } else {
        _addLog('⚠️ 没有最后已知位置');
      }
    } catch (e) {
      _addLog('❌ 获取最后位置失败: $e');
    }
    
    // 4. 尝试不同精度级别获取位置
    final accuracyLevels = [
      (LocationAccuracy.lowest, '最低'),
      (LocationAccuracy.low, '低'),
      (LocationAccuracy.medium, '中'),
      (LocationAccuracy.high, '高'),
      (LocationAccuracy.best, '最佳'),
    ];
    
    for (var (accuracy, name) in accuracyLevels) {
      try {
        _addLog('步骤4: 尝试以【$name】精度获取位置...');
        final stopwatch = Stopwatch()..start();
        
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 10),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('获取超时'),
        );
        
        stopwatch.stop();
        _addLog('✅ 成功获取位置 (耗时: ${stopwatch.elapsed.inSeconds}秒):');
        _addLog('  纬度: ${position.latitude}');
        _addLog('  经度: ${position.longitude}');
        _addLog('  精度: ${position.accuracy}米');
        _addLog('  海拔: ${position.altitude}米');
        _addLog('  速度: ${position.speed}米/秒');
        
        setState(() {
          _lastPosition = position;
        });
        
        break; // 成功就跳出循环
      } catch (e) {
        _addLog('❌ $name精度失败: ${e.toString().substring(0, 50)}...');
      }
    }
    
    // 5. 测试位置流
    try {
      _addLog('步骤5: 测试位置流监听...');
      int updateCount = 0;
      
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10, // 10米触发更新
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: (sink) {
          sink.addError('位置流超时');
          sink.close();
        },
      ).listen(
        (Position position) {
          updateCount++;
          _addLog('📍 位置更新 #$updateCount: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})');
          if (updateCount >= 3) {
            _positionStream?.cancel();
            _addLog('✅ 位置流测试成功');
          }
        },
        onError: (error) {
          _addLog('❌ 位置流错误: $error');
        },
      );
      
      // 10秒后自动停止
      Future.delayed(const Duration(seconds: 10), () {
        if (_positionStream != null) {
          _positionStream?.cancel();
          _addLog('⚠️ 位置流测试超时停止');
        }
      });
    } catch (e) {
      _addLog('❌ 位置流测试失败: $e');
    }
    
    _addLog('========== 诊断完成 ==========');
    
    setState(() {
      _isTesting = false;
    });
  }
  
  Future<void> _manualGetLocation() async {
    _addLog('手动获取位置...');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _addLog('✅ 获取成功: (${position.latitude}, ${position.longitude})');
      setState(() {
        _lastPosition = position;
      });
    } catch (e) {
      _addLog('❌ 获取失败: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置服务诊断'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isTesting ? null : _runFullDiagnostic,
          ),
        ],
      ),
      body: Column(
        children: [
          // 当前位置信息
          if (_lastPosition != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最新位置信息',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('纬度: ${_lastPosition!.latitude}'),
                  Text('经度: ${_lastPosition!.longitude}'),
                  Text('精度: ${_lastPosition!.accuracy}米'),
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
                    onPressed: _isTesting ? null : _manualGetLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text('手动获取位置'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Geolocator.openLocationSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('位置设置'),
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
                  if (log.contains('✅')) {
                    textColor = Colors.green.shade700;
                  } else if (log.contains('❌')) {
                    textColor = Colors.red.shade700;
                  } else if (log.contains('⚠️')) {
                    textColor = Colors.orange.shade700;
                  } else if (log.contains('📍')) {
                    textColor = Colors.blue.shade700;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: textColor,
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