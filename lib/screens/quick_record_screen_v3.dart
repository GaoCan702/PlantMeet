import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/fast_location_service.dart';
import '../services/location_service.dart';
import '../utils/location_display_helper.dart';
import '../models/index.dart';

class QuickRecordScreenV3 extends StatefulWidget {
  final String? imagePath;
  
  const QuickRecordScreenV3({super.key, this.imagePath});

  @override
  State<QuickRecordScreenV3> createState() => _QuickRecordScreenV3State();
}

class _QuickRecordScreenV3State extends State<QuickRecordScreenV3> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();
  final FastLocationService _fastLocationService = FastLocationService();
  StreamSubscription<LocationResult>? _locationUpdateSubscription;
  
  String? _imagePath;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  
  // 位置信息
  LocationResult? _locationResult;
  String? _locationAddress;
  
  // 时间信息
  late DateTime _encounterTime;
  
  @override
  void initState() {
    super.initState();
    _imagePath = widget.imagePath;
    _encounterTime = DateTime.now();
    // 延迟获取位置，避免阻塞页面加载
    Future.delayed(const Duration(milliseconds: 300), _getQuickLocation);
    
    // 监听位置改进
    _locationUpdateSubscription = _fastLocationService.locationUpdates.listen((improvedLocation) {
      if (mounted) {
        setState(() {
          _locationResult = improvedLocation;
        });
        // 后台获取地址
        _getAddress(improvedLocation);
      }
    });
  }
  
  Future<void> _getQuickLocation() async {
    if (_isGettingLocation) return;
    
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      // 使用快速位置服务
      final result = await _fastLocationService.getQuickLocation(
        allowCache: true,
        improveInBackground: true,  // 后台改进精度
      );
      
      if (result != null) {
        setState(() {
          _locationResult = result;
        });
        
        // 异步获取地址（不阻塞UI）
        _getAddress(result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('位置获取成功 ${result.accuracyText}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _locationAddress = '位置获取失败（可手动输入）';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法获取位置，但您仍可保存记录'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // 获取位置错误: $e
      setState(() {
        _locationAddress = '位置服务异常';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }
  
  Future<void> _getAddress(LocationResult location) async {
    try {
      // 使用 LocationService 来获取地址（地址服务不需要快速）
      final locationService = LocationService();
      final address = await locationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (mounted && address != null) {
        setState(() {
          _locationAddress = address;
        });
      }
    } catch (e) {
      // 获取地址失败: $e
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e'), backgroundColor: Colors.red),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _saveEncounter() async {
    if (_imagePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先添加照片'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final now = DateTime.now();
      
      // 构建位置描述 - 使用新的显示策略
      String? locationText;
      if (_locationResult != null) {
        // 根据精度决定保存什么
        locationText = LocationDisplayHelper.getDisplayText(
          latitude: _locationResult!.latitude,
          longitude: _locationResult!.longitude,
          accuracy: _locationResult!.accuracy,
          address: _locationAddress,
        );
      }
      
      // 创建遇见记录
      final encounter = PlantEncounter(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speciesId: null,
        encounterDate: _encounterTime,
        location: locationText,
        latitude: _locationResult?.latitude,
        longitude: _locationResult?.longitude,
        photoPaths: [_imagePath!],
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        userDefinedName: '待识别植物',
        source: RecognitionSource.camera,
        method: RecognitionMethod.none,
        isIdentified: false,
        createdAt: now,
        updatedAt: now,
      );
      
      await appState.addUnidentifiedEncounter(encounter);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('遇见记录已保存'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('快速记录'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
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
                : const Icon(Icons.check, size: 20),
              label: Text(_isSaving ? '保存中' : '完成'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 照片区域 - 不使用Card，直接展示
            Container(
              height: 250,
              width: double.infinity,
              color: colorScheme.surfaceContainerLowest,
              child: _imagePath == null
                ? InkWell(
                    onTap: _showPhotoOptions,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '添加植物照片',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击拍照或从相册选择',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: _showPhotoOptions,
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
            
            // 信息区域 - 简洁的列表样式，不用Card
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间信息 - 简洁的行布局
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '记录时间',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(_encounterTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 位置信息 - 简洁的行布局
                  InkWell(
                    onTap: _isGettingLocation ? null : _getQuickLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: _locationResult != null 
                                ? colorScheme.primary 
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '记录位置',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isGettingLocation
                                      ? '正在获取位置...'
                                      : (_locationResult != null
                                          ? LocationDisplayHelper.getDisplayText(
                                              latitude: _locationResult!.latitude,
                                              longitude: _locationResult!.longitude,
                                              accuracy: _locationResult!.accuracy,
                                              address: _locationAddress,
                                            )
                                          : '点击添加位置'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _locationResult != null 
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                                if (_locationResult != null && _locationResult!.accuracy != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      LocationDisplayHelper.getAccuracyDescription(_locationResult!.accuracy),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_isGettingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_locationResult == null)
                            Icon(
                              Icons.add,
                              size: 20,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 备注输入 - 更简洁的输入框
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note_add,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '备注信息',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(可选)',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            hintText: '记录植物特征、生长环境等信息...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 3,
                          minLines: 2,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 底部操作区域
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  // 保存按钮 - 更简洁的样式
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isSaving || _imagePath == null ? null : _saveEncounter,
                      icon: Icon(
                        _isSaving ? Icons.hourglass_empty : Icons.save,
                        size: 20,
                      ),
                      label: Text(
                        _isSaving ? '保存中...' : '保存记录',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 提示信息
                  Text(
                    '记录将保存为"待识别"，可在主页使用AI识别',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPhotoOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    _locationUpdateSubscription?.cancel();
    super.dispose();
  }
}