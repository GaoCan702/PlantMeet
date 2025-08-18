import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/unified_plant_card.dart';
import 'unidentified_plant_detail_screen_v2.dart';
import 'location_debug_screen_v2.dart';
import 'plant_detail_screen_v2.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    // 每次进入页面时重新加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }
  
  Future<void> _refreshData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    // 使用refreshData替代initialize，避免隐私政策检查影响数据加载
    await appState.refreshData();
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 10;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading && appState.species.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '加载出错',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => appState.initialize(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final speciesWithEncounters = appState.getSpeciesWithEncounters();
          final unidentifiedEncounters = appState.getUnidentifiedEncounters();
          final allEncounters = appState.encounters;
          final totalItems = speciesWithEncounters.length + unidentifiedEncounters.length;

          return RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refreshData,
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              // 自定义AppBar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                elevation: _isScrolled ? 2 : 0,
                backgroundColor: Theme.of(context).colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 装饰性叶子图案
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Transform.rotate(
                            angle: 0.3,
                            child: Icon(
                              Icons.eco,
                              size: 150,
                              color: Colors.green.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -20,
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Icon(
                              Icons.local_florist,
                              size: 100,
                              color: Colors.green.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // 标题和统计
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  '遇见植物图鉴',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '记录每一次美好的植物邂逅',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                // 统计卡片组
                                Row(
                                  children: [
                                    _buildStatCard(
                                      context,
                                      value: '${allEncounters.length}',
                                      label: '次遇见',
                                      icon: Icons.visibility,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatCard(
                                      context,
                                      value: '${speciesWithEncounters.length}',
                                      label: '已识别',
                                      icon: Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatCard(
                                      context,
                                      value: '${unidentifiedEncounters.length}',
                                      label: '待识别',
                                      icon: Icons.help_outline,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  // 临时调试按钮
                  IconButton(
                    icon: const Icon(Icons.bug_report, color: Colors.orange),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocationDebugScreenV2(),
                        ),
                      );
                    },
                  ),
                  // 测试新UI按钮
                  IconButton(
                    icon: const Icon(Icons.preview, color: Colors.purple),
                    onPressed: () {
                      Navigator.pushNamed(context, '/test-plant-detail');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: () => Navigator.pushNamed(context, '/gallery'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),

              // Tab栏
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        text: '全部',
                        icon: Icon(Icons.grid_view, size: 20),
                      ),
                      Tab(
                        text: '已识别',
                        icon: Icon(Icons.local_florist, size: 20),
                      ),
                      Tab(
                        text: '待识别',
                        icon: Icon(Icons.help_outline, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // 内容区域
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 全部标签页
                    _buildGridView(
                      context,
                      appState,
                      unidentifiedEncounters,
                      speciesWithEncounters,
                      totalItems,
                    ),
                    // 已识别标签页
                    _buildIdentifiedGrid(
                      context,
                      appState,
                      speciesWithEncounters,
                    ),
                    // 待识别标签页
                    _buildUnidentifiedGrid(
                      context,
                      unidentifiedEncounters,
                    ),
                  ],
                ),
              ),
              ],
            ),
          );
        },
      ),
      // 悬浮按钮
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    AppState appState,
    List<dynamic> unidentifiedEncounters,
    List<dynamic> speciesWithEncounters,
    int totalItems,
  ) {
    if (totalItems == 0) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Theme.of(context).colorScheme.primary,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85, // 调整比例以适应更紧凑的卡片
        ),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          // 先显示未识别的，再显示已识别的
          if (index < unidentifiedEncounters.length) {
            final encounter = unidentifiedEncounters[index];
            return _buildAnimatedCard(
              child: UnifiedPlantCard.unidentified(
                unidentifiedEncounter: encounter,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UnidentifiedPlantDetailScreenV2(
                        encounter: encounter,
                      ),
                    ),
                  );
                },
              ),
              index: index,
            );
          } else {
            final speciesIndex = index - unidentifiedEncounters.length;
            final species = speciesWithEncounters[speciesIndex];
            final encounters = appState.getEncountersForSpecies(species.id);
            String? firstImage;
            if (encounters.isNotEmpty && encounters.first.photoPaths.isNotEmpty) {
              firstImage = encounters.first.photoPaths.first;
            }
            return _buildAnimatedCard(
              child: UnifiedPlantCard.identified(
                species: species,
                encounterCount: encounters.length,
                firstImagePath: firstImage,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailScreenV2(
                        speciesId: species.id,
                      ),
                    ),
                  );
                },
              ),
              index: index,
            );
          }
        },
        ),
      ),
    );
  }

  Widget _buildIdentifiedGrid(
    BuildContext context,
    AppState appState,
    List<dynamic> speciesWithEncounters,
  ) {
    if (speciesWithEncounters.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.local_florist,
        title: '还没有已识别的植物',
        subtitle: '使用AI识别您遇见的植物',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Theme.of(context).colorScheme.primary,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade50,
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85, // 调整比例以适应更紧凑的卡片
        ),
        itemCount: speciesWithEncounters.length,
        itemBuilder: (context, index) {
          final species = speciesWithEncounters[index];
          final encounters = appState.getEncountersForSpecies(species.id);
          String? firstImage;
          if (encounters.isNotEmpty && encounters.first.photoPaths.isNotEmpty) {
            firstImage = encounters.first.photoPaths.first;
          }
          return _buildAnimatedCard(
            child: UnifiedPlantCard.identified(
              species: species,
              encounterCount: encounters.length,
              firstImagePath: firstImage,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantDetailScreenV2(
                      speciesId: species.id,
                    ),
                  ),
                );
              },
            ),
            index: index,
          );
        },
        ),
      ),
    );
  }

  Widget _buildUnidentifiedGrid(
    BuildContext context,
    List<dynamic> unidentifiedEncounters,
  ) {
    if (unidentifiedEncounters.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.help_outline,
        title: '没有待识别的植物',
        subtitle: '所有植物都已经识别完成',
        color: Colors.orange,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Theme.of(context).colorScheme.primary,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85, // 调整比例以适应更紧凑的卡片
        ),
        itemCount: unidentifiedEncounters.length,
        itemBuilder: (context, index) {
          final encounter = unidentifiedEncounters[index];
          return _buildAnimatedCard(
            child: UnifiedPlantCard.unidentified(
              unidentifiedEncounter: encounter,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnidentifiedPlantDetailScreenV2(
                      encounter: encounter,
                    ),
                  ),
                );
              },
            ),
            index: index,
          );
        },
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required Widget child,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    IconData icon = Icons.eco,
    String title = '还没有遇见记录',
    String subtitle = '点击右下角按钮记录植物遇见',
    Color color = Colors.green,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: color.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/camera'),
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isScrolled
              ? const SizedBox.shrink()
              : const Text('记录遇见'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// TabBar委托
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}