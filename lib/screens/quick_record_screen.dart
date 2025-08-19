// 此文件已被 quick_record_screen_v2.dart 替代，使用新的位置服务
// 保留此文件仅为向后兼容，将在下个版本中删除
@Deprecated('Use QuickRecordScreenV2 instead')

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
// import '../services/permission_service.dart';  // 未使用，已注释
import '../models/index.dart';

class QuickRecordScreen extends StatefulWidget {
  final String? imagePath;
  
  const QuickRecordScreen({super.key, this.imagePath});

  @override
  State<QuickRecordScreen> createState() => _QuickRecordScreenState();
}

class _QuickRecordScreenState extends State<QuickRecordScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();
  
  String? _imagePath;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  int _locationRetryCount = 0;
  static const int _maxRetries = 3;
  
  // 位置信息
  double? _latitude;
  double? _longitude;
  String? _locationName;
  
  // 时间信息
  late DateTime _encounterTime;
  
  @override
  void initState() {
    super.initState();
    _imagePath = widget.imagePath;
    _encounterTime = DateTime.now();
    _tryGetLocation();
  }
  
  Future<void> _tryGetLocation({bool isRetry = false}) async {
    if (_isGettingLocation) return; // 防止重复调用
    
    setState(() {
      _isGettingLocation = true;
      _locationName = '正在获取位置...';
    });
    
    String debugInfo = '';
    
    try {
      debugInfo += '开始获取位置...\n';
      print('DEBUG: ==================== 位置获取开始 ====================');
      print('DEBUG: 当前时间: ${DateTime.now()}');
      
      // 检查位置服务是否启用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugInfo += '位置服务状态: ${serviceEnabled ? "已开启" : "未开启"}\n';
      print('DEBUG: GPS/位置服务状态: $serviceEnabled');
      
      if (!serviceEnabled) {
        // 尝试打开位置服务设置
        setState(() {
          _isGettingLocation = false;
          _locationName = '位置服务未开启（请在手机设置中开启GPS）';
        });
        
        // 显示详细提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('请开启位置服务（GPS）'),
              action: SnackBarAction(
                label: '打开设置',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      // 检查权限
      LocationPermission permission = await Geolocator.checkPermission();
      debugInfo += '当前权限状态: $permission\n';
      print('DEBUG: 当前位置权限状态: $permission');
      print('DEBUG: 权限详情 - denied: ${permission == LocationPermission.denied}');
      print('DEBUG: 权限详情 - deniedForever: ${permission == LocationPermission.deniedForever}');
      print('DEBUG: 权限详情 - whileInUse: ${permission == LocationPermission.whileInUse}');
      print('DEBUG: 权限详情 - always: ${permission == LocationPermission.always}');
      
      if (permission == LocationPermission.denied) {
        debugInfo += '请求权限中...\n';
        permission = await Geolocator.requestPermission();
        debugInfo += '权限请求结果: $permission\n';
        print('DEBUG: 权限请求结果: $permission');
        
        if (permission == LocationPermission.denied) {
          setState(() {
            _isGettingLocation = false;
            _locationName = '位置权限被拒绝';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isGettingLocation = false;
          _locationName = '请在设置中开启位置权限';
        });
        
        // 显示详细提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('需要位置权限才能记录植物位置'),
              action: SnackBarAction(
                label: '打开设置',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      debugInfo += '开始获取GPS坐标...\n';
      print('DEBUG: 开始获取GPS坐标...');
      print('DEBUG: 设备平台: ${Theme.of(context).platform}');
      
      // 先尝试获取最后已知位置（更快）
      print('DEBUG: 尝试获取最后已知位置...');
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        debugInfo += '获取到最后已知位置: ${lastPosition.latitude}, ${lastPosition.longitude}\n';
        print('DEBUG: 最后已知位置: ${lastPosition.latitude}, ${lastPosition.longitude}');
        print('DEBUG: 位置时间戳: ${lastPosition.timestamp}');
        print('DEBUG: 位置精度: ${lastPosition.accuracy}米');
        
        // 如果最后位置是最近的（5分钟内），直接使用它
        final timeDiff = DateTime.now().difference(lastPosition.timestamp ?? DateTime.now());
        if (timeDiff.inMinutes < 5) {
          print('DEBUG: 使用最近的已知位置（${timeDiff.inMinutes}分钟前）');
          setState(() {
            _latitude = lastPosition.latitude;
            _longitude = lastPosition.longitude;
            _locationName = '已获取位置 (${lastPosition.latitude.toStringAsFixed(4)}, ${lastPosition.longitude.toStringAsFixed(4)})';
            _isGettingLocation = false;
          });
          return;
        }
      } else {
        print('DEBUG: 没有最后已知位置');
      }
      
      // 尝试快速获取低精度位置
      print('DEBUG: 尝试快速获取低精度位置...');
      Position? position;
      
      // 对于小米手机，先尝试获取网络位置
      try {
        // 使用最低精度，这通常使用网络定位而非GPS
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.lowest,
          forceAndroidLocationManager: true, // 强制使用Android原生定位
          timeLimit: const Duration(seconds: 3),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('网络定位超时'),
        );
        print('DEBUG: 网络定位成功');
      } catch (e) {
        print('DEBUG: 网络定位失败: $e');
      }
      
      // 如果网络定位失败，尝试低精度GPS
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          ).timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('低精度获取超时'),
          );
        } catch (e) {
          print('DEBUG: 低精度获取失败: $e');
        }
      }
      
      // 如果低精度失败，使用最后已知位置
      if (position == null && lastPosition != null) {
        print('DEBUG: 使用最后已知位置作为备选');
        position = lastPosition;
      }
      
      // 如果还是没有位置，尝试中等精度
      if (position == null) {
        print('DEBUG: 尝试中等精度获取...');
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('DEBUG: 中等精度也超时了');
              // 如果有最后位置，使用它
              if (lastPosition != null) {
                return lastPosition;
              }
              throw TimeoutException('获取位置超时');
            },
          );
        } catch (e) {
          print('DEBUG: 中等精度获取失败: $e');
          if (lastPosition != null) {
            print('DEBUG: 回退到最后已知位置');
            position = lastPosition;
          } else {
            rethrow;
          }
        }
      }
      
      if (position == null) {
        throw Exception('无法获取位置信息');
      }
      
      debugInfo += '成功获取位置: ${position.latitude}, ${position.longitude}\n';
      debugInfo += '精度: ${position.accuracy}米\n';
      print('DEBUG: ==================== 成功获取位置 ====================');
      print('DEBUG: 纬度: ${position.latitude}');
      print('DEBUG: 经度: ${position.longitude}');
      print('DEBUG: 精度: ${position.accuracy}米');
      print('DEBUG: 海拔: ${position.altitude}米');
      print('DEBUG: 速度: ${position.speed}米/秒');
      print('DEBUG: 时间戳: ${position.timestamp}');
      print('DEBUG: ==================================================');
      
      setState(() {
        _latitude = position!.latitude;
        _longitude = position.longitude;
        
        // 根据精度显示不同的提示
        String accuracyText = '';
        if (position.accuracy < 20) {
          accuracyText = '精确';
        } else if (position.accuracy < 50) {
          accuracyText = '较准确';
        } else if (position.accuracy < 100) {
          accuracyText = '大概';
        } else {
          accuracyText = '粗略';
        }
        
        _locationName = '📍 已定位 ($accuracyText)';
        _isGettingLocation = false;
      });
      
    } catch (e, stackTrace) {
      debugInfo += '错误: $e\n';
      print('DEBUG: ==================== 位置获取失败 ====================');
      print('DEBUG: 错误类型: ${e.runtimeType}');
      print('DEBUG: 错误信息: $e');
      print('DEBUG: 调试信息累积: $debugInfo');
      print('DEBUG: 堆栈跟踪开始 >>>>>');
      print('$stackTrace');
      print('DEBUG: <<<<< 堆栈跟踪结束');
      print('DEBUG: ==================================================');
      
      String errorMessage = '位置获取失败';
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = '获取位置超时（请在空旷处重试）';
        print('DEBUG: 错误分类: 超时');
      } else if (e.toString().contains('service')) {
        errorMessage = '位置服务异常';
        print('DEBUG: 错误分类: 服务异常');
      } else if (e.toString().contains('permission')) {
        errorMessage = '位置权限问题';
        print('DEBUG: 错误分类: 权限问题');
      } else if (e.toString().contains('location')) {
        errorMessage = '无法获取位置信息';
        print('DEBUG: 错误分类: 位置相关');
      } else {
        print('DEBUG: 错误分类: 未知');
      }
      
      setState(() {
        _isGettingLocation = false;
        _locationName = errorMessage;
      });
      
      // 自动重试机制
      if (!isRetry && _locationRetryCount < _maxRetries) {
        _locationRetryCount++;
        print('DEBUG: 尝试第 ${_locationRetryCount} 次重试...');
        
        // 显示重试提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('正在重试... (第 $_locationRetryCount/$_maxRetries 次)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // 延迟后重试
        await Future.delayed(const Duration(seconds: 2));
        _tryGetLocation(isRetry: true);
      } else if (_locationRetryCount >= _maxRetries) {
        print('DEBUG: 已达最大重试次数');
        
        // 显示最终失败信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('位置获取失败，请手动点击重试'),
              action: SnackBarAction(
                label: '重试',
                onPressed: () {
                  _locationRetryCount = 0;
                  _tryGetLocation();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      
      // 显示详细错误信息（调试用）
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('调试信息: ${e.toString().substring(0, 100 < e.toString().length ? 100 : e.toString().length)}...'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍照失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _saveEncounter() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加照片'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final now = DateTime.now();
      
      // 创建遇见记录（不需要识别）
      final encounter = PlantEncounter(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speciesId: null,  // 未识别，所以没有speciesId
        encounterDate: _encounterTime,
        location: _locationName,
        latitude: _latitude,
        longitude: _longitude,
        photoPaths: [_imagePath!],
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        userDefinedName: '待识别植物',  // 默认名称，不需要用户输入
        source: RecognitionSource.camera,
        method: RecognitionMethod.none,  // 未识别
        isIdentified: false,
        createdAt: now,
        updatedAt: now,
      );
      
      // 保存到数据库
      await appState.addUnidentifiedEncounter(encounter);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('遇见记录已保存'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('快速记录'),
        actions: [
          // 保存按钮更显眼
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isSaving || _imagePath == null ? null : _saveEncounter,
              icon: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white),
              label: Text(
                _isSaving ? '保存中' : '完成',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 照片区域
            if (_imagePath == null) ...[
              Card(
                child: InkWell(
                  onTap: () => _showPhotoOptions(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 60,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '添加植物照片',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_imagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(153),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => _showPhotoOptions(),
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 时间和位置信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 时间行
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dateFormat.format(_encounterTime),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 位置行
                    InkWell(
                      onTap: _isGettingLocation ? null : () {
                        _locationRetryCount = 0;
                        _tryGetLocation();
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: _locationName != null 
                                ? Colors.green.shade600 
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isGettingLocation
                                  ? '正在获取位置...'
                                  : (_locationName ?? '点击添加位置'),
                              style: TextStyle(
                                fontSize: 15,
                                color: _locationName != null 
                                    ? Theme.of(context).textTheme.bodyLarge?.color
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (_isGettingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 备注输入（简化版）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: '添加备注（可选）',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    icon: Icon(Icons.edit_note, color: Colors.grey.shade600, size: 20),
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 快速操作按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving || _imagePath == null ? null : _saveEncounter,
                icon: const Icon(Icons.save_alt),
                label: Text(_isSaving ? '保存中...' : '保存记录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 提示信息（更小）
            Center(
              child: Text(
                '稍后可在主页尝试AI识别',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.green.shade600),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue.shade600),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}