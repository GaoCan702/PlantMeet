import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// 测试图片管理器 - 为MNN Chat测试提供预设植物图片
class TestImageManager {
  static const String _testImagesDir = 'test_plant_images';
  
  // 预设测试图片信息
  static const List<TestImageInfo> _presetImages = [
    TestImageInfo(
      id: 'sunflower_leaf',
      name: '向日葵叶子',
      description: '典型的向日葵叶片，心形，边缘有锯齿',
      expectedResult: '向日葵',
      difficulty: TestDifficulty.easy,
    ),
    TestImageInfo(
      id: 'rose_flower',
      name: '玫瑰花',
      description: '红色玫瑰花朵，层叠花瓣清晰可见',
      expectedResult: '玫瑰',
      difficulty: TestDifficulty.medium,
    ),
    TestImageInfo(
      id: 'bamboo_leaves',
      name: '竹叶',
      description: '细长的竹叶，平行脉络明显',
      expectedResult: '竹子',
      difficulty: TestDifficulty.easy,
    ),
    TestImageInfo(
      id: 'cactus_plant',
      name: '仙人掌',
      description: '多肉植物，表面有明显的刺座',
      expectedResult: '仙人掌',
      difficulty: TestDifficulty.medium,
    ),
    TestImageInfo(
      id: 'complex_scene',
      name: '复杂场景',
      description: '包含多种植物的复杂背景，测试识别精度',
      expectedResult: '需要用户判断',
      difficulty: TestDifficulty.hard,
    ),
  ];
  
  /// 获取测试图片目录
  static Future<Directory> _getTestImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final testDir = Directory('${appDir.path}/$_testImagesDir');
    if (!await testDir.exists()) {
      await testDir.create(recursive: true);
    }
    return testDir;
  }
  
  /// 初始化预设测试图片
  static Future<void> initializePresetImages() async {
    print('🖼️ 初始化测试图片...');
    
    for (final imageInfo in _presetImages) {
      final file = await getPresetImageFile(imageInfo.id);
      if (!await file.exists()) {
        await _generateTestImage(imageInfo, file);
        print('✅ 生成测试图片: ${imageInfo.name}');
      }
    }
    
    print('🎉 测试图片初始化完成');
  }
  
  /// 获取预设图片文件
  static Future<File> getPresetImageFile(String imageId) async {
    final testDir = await _getTestImagesDirectory();
    return File('${testDir.path}/$imageId.jpg');
  }
  
  /// 获取所有预设图片信息
  static List<TestImageInfo> getPresetImageInfos() {
    return List.from(_presetImages);
  }
  
  /// 根据ID获取图片信息
  static TestImageInfo? getImageInfo(String imageId) {
    try {
      return _presetImages.firstWhere((img) => img.id == imageId);
    } catch (e) {
      return null;
    }
  }
  
  /// 生成测试图片
  static Future<void> _generateTestImage(TestImageInfo info, File file) async {
    late img.Image image;
    
    switch (info.id) {
      case 'sunflower_leaf':
        image = _createSunflowerLeaf();
        break;
      case 'rose_flower':
        image = _createRoseFlower();
        break;
      case 'bamboo_leaves':
        image = _createBambooLeaves();
        break;
      case 'cactus_plant':
        image = _createCactusPlant();
        break;
      case 'complex_scene':
        image = _createComplexScene();
        break;
      default:
        image = _createDefaultTestImage();
    }
    
    final bytes = img.encodeJpg(image, quality: 85);
    await file.writeAsBytes(bytes);
  }
  
  /// 创建向日葵叶子测试图片
  static img.Image _createSunflowerLeaf() {
    final image = img.Image(width: 512, height: 512);
    
    // 绿色背景渐变
    img.fill(image, color: img.ColorRgb8(120, 150, 100));
    
    // 绘制心形叶片轮廓
    _drawHeartShapeLeaf(image, 256, 256, 180, img.ColorRgb8(80, 120, 60));
    
    // 添加叶脉
    _drawLeafVeins(image, 256, 256, img.ColorRgb8(60, 100, 40));
    
    // 添加锯齿边缘
    _drawSerratEdge(image, 256, 256, 180);
    
    // 添加一些自然变化
    _addNaturalTexture(image, img.ColorRgb8(90, 130, 70));
    
    return image;
  }
  
  /// 创建玫瑰花测试图片
  static img.Image _createRoseFlower() {
    final image = img.Image(width: 512, height: 512);
    
    // 浅绿色背景
    img.fill(image, color: img.ColorRgb8(140, 160, 120));
    
    // 绘制玫瑰花层叠花瓣
    for (int layer = 3; layer >= 0; layer--) {
      final radius = 60 + layer * 30;
      final petalCount = 5 + layer * 2;
      final red = 180 + layer * 15;
      
      for (int i = 0; i < petalCount; i++) {
        final angle = (2 * pi / petalCount * i) + (layer * 0.3);
        final x = 256 + cos(angle) * radius * 0.8;
        final y = 256 + sin(angle) * radius * 0.8;
        
        img.drawCircle(image, 
          x: x.round(), 
          y: y.round(), 
          radius: 25 + layer * 5,
          color: img.ColorRgb8(red.clamp(0, 255), 100 - layer * 10, 120 - layer * 15));
      }
    }
    
    // 花心
    img.drawCircle(image, x: 256, y: 256, radius: 15, color: img.ColorRgb8(220, 200, 80));
    
    return image;
  }
  
  /// 创建竹叶测试图片
  static img.Image _createBambooLeaves() {
    final image = img.Image(width: 512, height: 512);
    
    // 淡绿色背景
    img.fill(image, color: img.ColorRgb8(150, 180, 140));
    
    // 绘制多片细长竹叶
    for (int i = 0; i < 8; i++) {
      final startX = 50 + i * 50;
      final startY = 100 + Random().nextInt(100);
      final length = 200 + Random().nextInt(100);
      
      // 叶片主体
      for (int j = 0; j < length; j++) {
        final x = startX + j * 0.3;
        final y = startY + j;
        final width = (20 - j * 0.05).clamp(2, 20);
        
        img.drawRect(image,
          x1: (x - width/2).round(),
          y1: y.round(),
          x2: (x + width/2).round(),
          y2: (y + 2).round(),
          color: img.ColorRgb8(100 + Random().nextInt(40), 140 + Random().nextInt(20), 80 + Random().nextInt(30)));
      }
      
      // 平行叶脉
      for (int vein = 0; vein < 3; vein++) {
        for (int j = 0; j < length - 10; j++) {
          final x = startX + j * 0.3 + (vein - 1) * 3;
          final y = startY + j + 5;
          img.drawPixel(image, x.round(), y.round(), img.ColorRgb8(80, 120, 60));
        }
      }
    }
    
    return image;
  }
  
  /// 创建仙人掌测试图片
  static img.Image _createCactusPlant() {
    final image = img.Image(width: 512, height: 512);
    
    // 沙漠背景色
    img.fill(image, color: img.ColorRgb8(200, 180, 140));
    
    // 主体仙人掌茎
    img.drawRect(image,
      x1: 200, y1: 150,
      x2: 312, y2: 450,
      color: img.ColorRgb8(120, 150, 100));
    
    // 仙人掌分支
    img.drawRect(image,
      x1: 280, y1: 200,
      x2: 380, y2: 280,
      color: img.ColorRgb8(110, 140, 90));
    
    // 添加刺座和刺
    for (int i = 0; i < 50; i++) {
      final x = 200 + Random().nextInt(112);
      final y = 150 + Random().nextInt(300);
      
      // 刺座
      img.drawCircle(image, x: x, y: y, radius: 3, color: img.ColorRgb8(140, 120, 80));
      
      // 刺
      for (int j = 0; j < 6; j++) {
        final angle = Random().nextDouble() * 2 * pi;
        final length = 8 + Random().nextInt(12);
        final endX = x + cos(angle) * length;
        final endY = y + sin(angle) * length;
        
        _drawLine(image, x, y, endX.round(), endY.round(), img.ColorRgb8(80, 70, 50));
      }
    }
    
    // 小花
    img.drawCircle(image, x: 320, y: 180, radius: 8, color: img.ColorRgb8(220, 100, 140));
    
    return image;
  }
  
  /// 创建复杂场景测试图片
  static img.Image _createComplexScene() {
    final image = img.Image(width: 512, height: 512);
    
    // 复杂背景
    img.fill(image, color: img.ColorRgb8(130, 150, 110));
    
    // 添加多个植物元素
    // 背景树叶
    for (int i = 0; i < 20; i++) {
      final x = Random().nextInt(512);
      final y = Random().nextInt(512);
      final size = 10 + Random().nextInt(30);
      final green = 100 + Random().nextInt(50);
      
      img.drawCircle(image, x: x, y: y, radius: size, 
        color: img.ColorRgb8(green, green + 20, green - 20));
    }
    
    // 前景主要植物（混合特征）
    _drawHeartShapeLeaf(image, 200, 300, 80, img.ColorRgb8(90, 130, 70));
    img.drawCircle(image, x: 350, y: 200, radius: 25, color: img.ColorRgb8(200, 150, 100));
    
    // 添加噪点模拟复杂环境
    for (int i = 0; i < 1000; i++) {
      final x = Random().nextInt(512);
      final y = Random().nextInt(512);
      final brightness = Random().nextInt(50);
      img.drawPixel(image, x, y, img.ColorRgb8(brightness, brightness, brightness));
    }
    
    return image;
  }
  
  /// 创建默认测试图片
  static img.Image _createDefaultTestImage() {
    final image = img.Image(width: 512, height: 512);
    img.fill(image, color: img.ColorRgb8(100, 150, 100));
    
    // 简单的叶子形状
    img.drawCircle(image, x: 256, y: 256, radius: 100, color: img.ColorRgb8(80, 120, 80));
    
    return image;
  }
  
  /// 保存用户上传的测试图片
  static Future<File> saveUserTestImage(File sourceFile) async {
    final testDir = await _getTestImagesDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetFile = File('${testDir.path}/user_test_$timestamp.jpg');
    
    // 优化图片尺寸
    final bytes = await sourceFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image != null) {
      // 调整大小到合适的测试尺寸
      final resized = img.copyResize(image, width: 512, height: 512);
      final optimizedBytes = img.encodeJpg(resized, quality: 85);
      await targetFile.writeAsBytes(optimizedBytes);
    } else {
      // 如果无法解码，直接复制原文件
      await sourceFile.copy(targetFile.path);
    }
    
    return targetFile;
  }
  
  /// 清理测试图片
  static Future<void> cleanupTestImages() async {
    try {
      final testDir = await _getTestImagesDirectory();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
      print('🧹 测试图片已清理');
    } catch (e) {
      print('⚠️ 清理测试图片失败: $e');
    }
  }
  
  /// 获取测试图片文件大小
  static Future<int> getImageFileSize(String imageId) async {
    try {
      final file = await getPresetImageFile(imageId);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('获取图片大小失败: $e');
    }
    return 0;
  }
  
  // 辅助绘图方法
  static void _drawHeartShapeLeaf(img.Image image, int centerX, int centerY, int size, img.Color color) {
    for (int i = -size; i < size; i++) {
      for (int j = -size; j < size; j++) {
        final x = i / size.toDouble();
        final y = j / size.toDouble();
        
        // 心形方程的简化版本
        if ((x * x + y * y - 1).abs() < 0.3 || (x * x + (y - 0.5) * (y - 0.5) - 0.5).abs() < 0.2) {
          final pixelX = centerX + i;
          final pixelY = centerY + j;
          if (pixelX >= 0 && pixelX < image.width && pixelY >= 0 && pixelY < image.height) {
            img.drawPixel(image, pixelX, pixelY, color);
          }
        }
      }
    }
  }
  
  static void _drawLeafVeins(img.Image image, int centerX, int centerY, img.Color color) {
    // 主脉
    _drawLine(image, centerX, centerY - 100, centerX, centerY + 100, color);
    
    // 侧脉
    for (int i = -3; i <= 3; i++) {
      if (i == 0) continue;
      final startX = centerX;
      final startY = centerY + i * 25;
      final endX = centerX + i * 30;
      final endY = startY + 40;
      _drawLine(image, startX, startY, endX, endY, color);
    }
  }
  
  static void _drawSerratEdge(img.Image image, int centerX, int centerY, int size) {
    // 简化的锯齿边缘
    for (int angle = 0; angle < 360; angle += 10) {
      final radian = angle * pi / 180;
      final radius = size + sin(angle * 8 * pi / 180) * 10;
      final x = centerX + cos(radian) * radius;
      final y = centerY + sin(radian) * radius;
      img.drawPixel(image, x.round(), y.round(), img.ColorRgb8(60, 100, 40));
    }
  }
  
  static void _addNaturalTexture(img.Image image, img.Color baseColor) {
    final random = Random();
    for (int i = 0; i < 2000; i++) {
      final x = random.nextInt(image.width);
      final y = random.nextInt(image.height);
      final variation = random.nextInt(40) - 20;
      
      final r = (baseColor.r + variation).clamp(0, 255).toInt();
      final g = (baseColor.g + variation).clamp(0, 255).toInt();
      final b = (baseColor.b + variation).clamp(0, 255).toInt();
      
      img.drawPixel(image, x, y, img.ColorRgb8(r, g, b));
    }
  }
  
  static void _drawLine(img.Image image, int x1, int y1, int x2, int y2, img.Color color) {
    final dx = (x2 - x1).abs();
    final dy = (y2 - y1).abs();
    final sx = x1 < x2 ? 1 : -1;
    final sy = y1 < y2 ? 1 : -1;
    var err = dx - dy;
    
    var x = x1;
    var y = y1;
    
    while (true) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        img.drawPixel(image, x, y, color);
      }
      
      if (x == x2 && y == y2) break;
      
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
  }
}

/// 测试图片信息
class TestImageInfo {
  final String id;
  final String name;
  final String description;
  final String expectedResult;
  final TestDifficulty difficulty;
  
  const TestImageInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.expectedResult,
    required this.difficulty,
  });
}

/// 测试难度
enum TestDifficulty {
  easy,    // 简单 - 单一植物，特征明显
  medium,  // 中等 - 需要仔细观察特征
  hard,    // 困难 - 复杂场景或模糊特征
}