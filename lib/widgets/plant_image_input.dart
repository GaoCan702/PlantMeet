import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 植物图片输入组件 - 借鉴 flutter_gemma 示例的优秀设计
class PlantImageInput extends StatefulWidget {
  final Function(File?) onImageSelected;
  final File? selectedImage;
  final bool enabled;
  final String? hint;

  const PlantImageInput({
    super.key,
    required this.onImageSelected,
    this.selectedImage,
    this.enabled = true,
    this.hint,
  });

  @override
  State<PlantImageInput> createState() => _PlantImageInputState();
}

class _PlantImageInputState extends State<PlantImageInput> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    _loadImageIfExists();
  }

  @override
  void didUpdateWidget(PlantImageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedImage != oldWidget.selectedImage) {
      _loadImageIfExists();
    }
  }

  Future<void> _loadImageIfExists() async {
    if (widget.selectedImage != null) {
      try {
        final bytes = await widget.selectedImage!.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = widget.selectedImage!.path.split('/').last;
        });
      } catch (e) {
        debugPrint('Failed to load image: $e');
      }
    } else {
      setState(() {
        _imageBytes = null;
        _imageName = null;
      });
    }
  }

  Future<void> _pickImage() async {
    if (!widget.enabled) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
        
        widget.onImageSelected(file);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (!widget.enabled) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
        
        widget.onImageSelected(file);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('拍照失败: $e')),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
    });
    widget.onImageSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图片预览区域
        if (_imageBytes != null) _buildImagePreview(),
        
        // 图片选择按钮区域
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _imageBytes != null 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              // 相机按钮
              IconButton(
                onPressed: widget.enabled ? _takePhoto : null,
                icon: Icon(
                  Icons.camera_alt,
                  color: widget.enabled 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
                ),
                tooltip: '拍照',
              ),
              
              // 相册按钮
              IconButton(
                onPressed: widget.enabled ? _pickImage : null,
                icon: Icon(
                  Icons.photo_library,
                  color: widget.enabled 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
                ),
                tooltip: '从相册选择',
              ),
              
              // 提示文本
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _imageName ?? widget.hint ?? '选择植物图片进行识别',
                    style: TextStyle(
                      color: _imageName != null 
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Theme.of(context).hintColor,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // 清除按钮
              if (_imageBytes != null)
                IconButton(
                  onPressed: widget.enabled ? _clearImage : null,
                  icon: Icon(
                    Icons.clear,
                    color: widget.enabled 
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).disabledColor,
                  ),
                  tooltip: '清除图片',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 图片显示
            Container(
              width: double.infinity,
              height: 200,
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
              ),
            ),
            
            // 图片信息叠加层
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _imageName ?? '植物图片',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(_imageBytes!.length / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 清除按钮
            if (widget.enabled)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _clearImage,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}