import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/permission_service.dart';
import '../services/recognition_service.dart';
import '../models/index.dart';
import '../widgets/copyable_error_message.dart';
import 'quick_record_screen_v3.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissionService = PermissionService();
  late RecognitionService _recognitionService;
  String? _imagePath;
  bool _isProcessing = false;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    // 使用 Provider 提供的单例服务
    _recognitionService = Provider.of<RecognitionService>(context, listen: false);
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraGranted = await _permissionService.checkCameraPermission();
    final storageGranted = await _permissionService.checkStoragePermission();

    setState(() {
      _hasPermissions = cameraGranted && storageGranted;
    });
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

      if (image != null) {
        // 显示选项：识别还是快速记录
        _showRecordOptions(image.path);
      }
    } catch (e) {
      _showError('拍照失败: $e');
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

      if (image != null) {
        // 显示选项：识别还是快速记录
        _showRecordOptions(image.path);
      }
    } catch (e) {
      _showError('选择图片失败: $e');
    }
  }
  
  void _showRecordOptions(String imagePath) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '选择操作',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: Colors.green.shade600),
              ),
              title: const Text('快速记录'),
              subtitle: const Text('无需识别，记录这次遇见'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuickRecordScreenV3(imagePath: imagePath),
                  ),
                ).then((_) {
                  // 返回后关闭相机页面
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.search, color: Colors.blue.shade600),
              ),
              title: const Text('AI识别'),
              subtitle: Text(
                _hasAvailableRecognitionMethod() 
                  ? '使用AI识别植物种类'
                  : '需要先配置识别服务',
              ),
              enabled: _hasAvailableRecognitionMethod(),
              onTap: _hasAvailableRecognitionMethod() ? () {
                Navigator.pop(context);
                setState(() {
                  _imagePath = imagePath;
                });
              } : null,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final granted = await _permissionService.requestAllPermissions();
      if (granted) {
        setState(() {
          _hasPermissions = true;
        });
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      _showError('权限请求失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限被拒绝'),
        content: const Text('应用需要相机和存储权限才能正常工作。请前往设置开启权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  bool _hasAvailableRecognitionMethod() {
    final availableMethods = _recognitionService.getAvailableMethods();
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.settings ?? AppSettings();

    // 检查是否有至少一个可用的识别方法
    return availableMethods.any(
      (method) =>
          method == RecognitionMethod.embedded &&
              _recognitionService.isMethodAvailable(method) ||
          method == RecognitionMethod.local &&
              _recognitionService.isMethodAvailable(method) ||
          method == RecognitionMethod.cloud && settings.isConfigured,
    );
  }


  void _showError(String message) {
    ErrorSnackBar.show(context, message: message, title: '错误');
  }

  void _showDetailedError(String message, String? details) {
    if (details != null && details.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            ErrorDialog(message: message, title: '识别失败', details: details),
      );
    } else {
      _showError(message);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _identifyPlant() async {
    if (_imagePath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final settings = appState.settings ?? AppSettings();

      if (!_hasAvailableRecognitionMethod()) {
        _showError('当前没有可用的识别服务，请在设置中配置或启用识别方法');
        return;
      }

      final imageFile = File(_imagePath!);
      final response = await _recognitionService.identifyPlant(
        imageFile,
        settings,
      );

      if (!response.success) {
        _showDetailedError('识别失败', response.error);
        return;
      }

      if (response.results.isEmpty) {
        _showError('未识别到植物，请尝试重新拍照');
        return;
      }

      final topResult = response.results.first;
      final now = DateTime.now();

      // 创建或获取植物物种
      final species = PlantSpecies(
        id: topResult.id,
        scientificName: topResult.scientificName ?? 'Unknown',
        commonName: topResult.name,
        description: topResult.description,
        isToxic: topResult.safety.level == SafetyLevel.toxic,
        toxicityInfo: topResult.safety.warnings.isNotEmpty
            ? topResult.safety.warnings.first
            : null,
        createdAt: now,
        updatedAt: now,
      );

      // 创建遇见记录
      final encounter = PlantEncounter(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        speciesId: species.id,
        encounterDate: now,
        location: null,
        photoPaths: [_imagePath!],
        notes:
            '通过${response.method == RecognitionMethod.local ? '本地' : '云端'}识别',
        source: RecognitionSource.camera,
        method: response.method,
        createdAt: now,
        updatedAt: now,
      );

      // 智能保存到数据库（自动去重）
      await appState.addRecognitionResult(species, encounter);

      _showSuccess('识别完成！已识别为: ${topResult.name}');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('识别失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildPermissionUI() {
    if (!_hasPermissions) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('需要权限才能使用相机', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('请授权相机和存储权限', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _requestPermissions,
            icon: const Icon(Icons.security),
            label: const Text('请求权限'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('选择拍照或从相册选择', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('识别植物')),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: _imagePath == null
                  ? _buildPermissionUI()
                  : Image.file(File(_imagePath!), fit: BoxFit.cover),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                if (_imagePath == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takePicture,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('拍照'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('相册'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  if (_isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('正在识别中...'),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _identifyPlant,
                      icon: const Icon(Icons.search),
                      label: const Text('开始识别'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _imagePath = null;
                      });
                    },
                    child: const Text('重新选择'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
