import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../services/permission_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final PermissionService _permissionService = PermissionService();
  int _currentPage = 0;
  bool _isRequestingPermissions = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      image: Icons.eco,
      title: '欢迎使用PlantMeet',
      subtitle: '遇见植物',
      description: '一个简洁美观的植物识别应用\n帮您记录和分享植物遇见的美好时光',
    ),
    OnboardingPage(
      image: Icons.camera_alt,
      title: '智能识别',
      subtitle: '拍照即可识别',
      description: '支持多种植物识别API服务\n精准识别各种植物，了解它们的特征\n\n需要配置API地址和密钥才能使用',
    ),
    OnboardingPage(
      image: Icons.book,
      title: '个人图鉴',
      subtitle: '记录每次遇见',
      description: '自动去重合并相同植物\n记录遇见时间、地点和个人笔记',
    ),
    OnboardingPage(
      image: Icons.share,
      title: '导出分享',
      subtitle: 'PDF图鉴导出',
      description: '将您的植物图鉴导出为精美PDF\n与朋友分享您的植物知识',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // 页面指示器
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                          ? Colors.green 
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('上一页'),
                    )
                  else
                    const Spacer(),
                  
                  const Spacer(),
                  
                  ElevatedButton(
                    onPressed: _isRequestingPermissions ? null : () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isRequestingPermissions
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentPage < _pages.length - 1 ? '下一页' : '开始使用',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              page.image,
              size: 60,
              color: Colors.green.shade600,
            ),
          ),
          
          const SizedBox(height: 40),
          
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isRequestingPermissions = true;
    });

    try {
      // 请求权限
      await _permissionService.requestAllPermissions();
      await OnboardingService.setPermissionsRequested();
      
      // 标记新手引导完成
      await OnboardingService.setOnboardingSeen();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('权限请求失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermissions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final IconData image;
  final String title;
  final String subtitle;
  final String description;

  OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}