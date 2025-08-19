import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../widgets/unified_plant_card.dart';
import 'unidentified_plant_detail_screen_v2.dart';
import 'plant_detail_screen_v2.dart';
import '../services/share_service.dart';
import '../models/plant_species.dart';

class HomeScreenV3 extends StatefulWidget {
  const HomeScreenV3({super.key});

  @override
  State<HomeScreenV3> createState() => _HomeScreenV3State();
}

class _HomeScreenV3State extends State<HomeScreenV3> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
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

  // 分享今日记录
  void _shareTodayEncounters(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 筛选今日的记录
    final todayEncounters = appState.encounters.where((e) {
      final encounterDate = DateTime(
        e.encounterDate.year,
        e.encounterDate.month,
        e.encounterDate.day,
      );
      return encounterDate == today;
    }).toList();
    
    if (todayEncounters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今天还没有记录哦')),
      );
      return;
    }
    
    // 构建 species map
    final speciesMap = <String, PlantSpecies>{};
    for (final species in appState.species) {
      speciesMap[species.id] = species;
    }
    
    // 分享
    ShareService.shareMultipleEncounters(
      encounters: todayEncounters,
      speciesMap: speciesMap,
      title: '今日植物记录 ${DateFormat('yyyy-MM-dd').format(now)}',
      context: context,
    );
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
            return _buildErrorState(context, appState);
          }

          final speciesWithEncounters = appState.getSpeciesWithEncounters();
          final unidentifiedEncounters = appState.getUnidentifiedEncounters();
          final allEncounters = appState.encounters;
          
          // 获取最近的遇见
          final recentEncounter = allEncounters.isNotEmpty 
              ? allEncounters.reduce((a, b) => 
                  a.encounterDate.isAfter(b.encounterDate) ? a : b)
              : null;

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 精简的AppBar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  snap: true,
                  pinned: true,
                  elevation: _isScrolled ? 1 : 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isScrolled ? 1.0 : 0.0,
                    child: const Text(
                      '遇见植物图鉴',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: () => Navigator.pushNamed(context, '/gallery'),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'share_today':
                            _shareTodayEncounters(context);
                            break;
                          case 'settings':
                            Navigator.pushNamed(context, '/settings');
                            break;
                          case 'debug':
                            Navigator.pushNamed(context, '/test-plant-detail');
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share_today',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 12),
                              Text('分享今日记录'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings, size: 20),
                              SizedBox(width: 12),
                              Text('设置'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'debug',
                          child: Row(
                            children: [
                              Icon(Icons.bug_report, size: 20, color: Colors.orange),
                              SizedBox(width: 12),
                              Text('调试'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '遇见植物图鉴',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (recentEncounter != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '最近: ${_formatRecentTime(recentEncounter.encounterDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 搜索栏（可选显示）
                if (_showSearch)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: '搜索植物名称...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),

                // Tab栏 - 带数量显示
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grid_view, size: 18),
                              const SizedBox(width: 6),
                              const Text('全部'),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${speciesWithEncounters.length + unidentifiedEncounters.length}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 18),
                              const SizedBox(width: 6),
                              const Text('已识别'),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${speciesWithEncounters.length}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.help_outline, size: 18),
                              const SizedBox(width: 6),
                              const Text('待识别'),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${unidentifiedEncounters.length}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 全部标签页
                _buildGridView(
                  context,
                  appState,
                  unidentifiedEncounters,
                  speciesWithEncounters,
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
          );
        },
      ),
      // 悬浮按钮
      floatingActionButton: _buildFAB(context),
    );
  }

  String _formatRecentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else {
      return DateFormat('MM月dd日').format(dateTime);
    }
  }

  Widget _buildErrorState(BuildContext context, AppState appState) {
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

  Widget _buildGridView(
    BuildContext context,
    AppState appState,
    List<dynamic> unidentifiedEncounters,
    List<dynamic> speciesWithEncounters,
  ) {
    final totalItems = unidentifiedEncounters.length + speciesWithEncounters.length;
    
    if (totalItems == 0) {
      return _buildEmptyState(context);
    }

    // 过滤搜索结果
    final filteredUnidentified = unidentifiedEncounters.where((e) {
      if (_searchQuery.isEmpty) return true;
      final name = e.userDefinedName ?? '未识别的植物';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredIdentified = speciesWithEncounters.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.commonName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             s.scientificName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredTotal = filteredUnidentified.length + filteredIdentified.length;

    if (filteredTotal == 0 && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('没有找到"$_searchQuery"相关的植物'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredTotal,
      itemBuilder: (context, index) {
        // 先显示未识别的，再显示已识别的
        if (index < filteredUnidentified.length) {
          final encounter = filteredUnidentified[index];
          return UnifiedPlantCard.unidentified(
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
          );
        } else {
          final speciesIndex = index - filteredUnidentified.length;
          final species = filteredIdentified[speciesIndex];
          final encounters = appState.getEncountersForSpecies(species.id);
          String? firstImage;
          if (encounters.isNotEmpty && encounters.first.photoPaths.isNotEmpty) {
            firstImage = encounters.first.photoPaths.first;
          }
          return UnifiedPlantCard.identified(
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
          );
        }
      },
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: speciesWithEncounters.length,
      itemBuilder: (context, index) {
        final species = speciesWithEncounters[index];
        final encounters = appState.getEncountersForSpecies(species.id);
        String? firstImage;
        if (encounters.isNotEmpty && encounters.first.photoPaths.isNotEmpty) {
          firstImage = encounters.first.photoPaths.first;
        }
        return UnifiedPlantCard.identified(
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
        );
      },
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: unidentifiedEncounters.length,
      itemBuilder: (context, index) {
        final encounter = unidentifiedEncounters[index];
        return UnifiedPlantCard.unidentified(
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
        );
      },
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
            const SizedBox(height: 32),
            if (title == '还没有遇见记录')
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/camera'),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('开始记录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/camera'),
      elevation: 4,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add_a_photo),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// TabBar委托
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}