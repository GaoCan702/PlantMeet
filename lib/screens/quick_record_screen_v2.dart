import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';
import '../services/fast_location_service.dart';
import '../utils/location_formatter.dart';
import '../utils/location_display_helper.dart';
import '../models/index.dart';

class QuickRecordScreenV2 extends StatefulWidget {
  final String? imagePath;
  
  const QuickRecordScreenV2({super.key, this.imagePath});

  @override
  State<QuickRecordScreenV2> createState() => _QuickRecordScreenV2State();
}

class _QuickRecordScreenV2State extends State<QuickRecordScreenV2> {
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('位置获取成功 ${result.accuracyText}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _locationAddress = '位置获取失败（可手动输入）';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法获取位置，但您仍可保存记录'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('获取位置错误: $e');
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
      print('获取地址失败: $e');
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
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('快速记录'),
        actions: [
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
            _buildPhotoSection(),
            
            const SizedBox(height: 16),
            
            // 时间和位置信息
            _buildInfoCard(),
            
            const SizedBox(height: 16),
            
            // 备注输入
            _buildNotesCard(),
            
            const SizedBox(height: 16),
            
            // 保存按钮
            _buildSaveButton(),
            
            const SizedBox(height: 8),
            
            // 提示信息
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
  
  Widget _buildPhotoSection() {
    if (_imagePath == null) {
      return Card(
        child: InkWell(
          onTap: _showPhotoOptions,
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
      );
    }
    
    return Card(
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
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    return Card(
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
              onTap: _isGettingLocation ? null : _getQuickLocation,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: _locationResult != null 
                        ? Colors.green.shade600 
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            fontSize: 15,
                            color: _locationResult != null 
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (_locationResult != null && _locationResult!.accuracy != null)
                          Text(
                            LocationDisplayHelper.getAccuracyDescription(_locationResult!.accuracy),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
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
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesCard() {
    return Card(
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
    );
  }
  
  Widget _buildSaveButton() {
    return SizedBox(
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
    _locationUpdateSubscription?.cancel();
    super.dispose();
  }
}