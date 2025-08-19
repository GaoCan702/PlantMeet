import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/permission_service.dart';
import 'quick_record_screen_v3.dart';

/// 简化版相机页面 - 专注于快速记录
class CameraScreenV2 extends StatefulWidget {
  const CameraScreenV2({super.key});

  @override
  State<CameraScreenV2> createState() => _CameraScreenV2State();
}

class _CameraScreenV2State extends State<CameraScreenV2> {
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissionService = PermissionService();
  bool _hasPermissions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndProceed();
  }

  Future<void> _checkPermissionsAndProceed() async {
    setState(() {
      _isLoading = true;
    });

    // 检查权限
    final cameraGranted = await _permissionService.checkCameraPermission();
    final storageGranted = await _permissionService.checkStoragePermission();
    
    setState(() {
      _hasPermissions = cameraGranted && storageGranted;
      _isLoading = false;
    });

    // 权限检查完成，显示选择界面
  }

  Future<void> _takePicture() async {
    if (!_hasPermissions) {
      await _requestPermissions();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // 直接进入快速记录页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuickRecordScreenV3(imagePath: image.path),
          ),
        );
      } else if (mounted) {
        // 用户取消拍照，返回主页
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('拍照失败: $e');
        // 出错后返回主页
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_hasPermissions) {
      await _requestPermissions();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // 直接进入快速记录页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuickRecordScreenV3(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      _showError('选择图片失败: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _permissionService.requestAllPermissions();
      if (granted) {
        setState(() {
          _hasPermissions = true;
        });
        // 权限获取成功后，自动打开相机
        _takePicture();
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      _showError('权限请求失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要权限'),
        content: const Text('应用需要相机和存储权限才能记录植物。请前往设置开启权限。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 返回主页
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('记录遇见'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _hasPermissions ? '正在打开相机...' : '检查权限中...',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : !_hasPermissions
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '需要相机权限',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请授权相机和存储权限以记录植物',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _requestPermissions,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('授权并拍照'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('稍后再说'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 相机选项
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 64,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '选择图片来源',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _takePicture,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('拍照'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickFromGallery,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('相册'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}