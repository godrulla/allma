import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/companions/models/companion.dart';
import '../../../core/companions/providers/companions_provider.dart';
import '../../../shared/utils/constants.dart';
import '../widgets/companion_card.dart';
import 'companion_profile_page.dart';
import 'create_companion_page.dart';

class CompanionSelectionPage extends ConsumerStatefulWidget {
  const CompanionSelectionPage({super.key});

  @override
  ConsumerState<CompanionSelectionPage> createState() => _CompanionSelectionPageState();
}

class _CompanionSelectionPageState extends ConsumerState<CompanionSelectionPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabController;
  String _searchQuery = '';
  CompanionFilter _currentFilter = CompanionFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Animate FAB in after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companionsAsync = ref.watch(companionsProvider);
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Choose Your Companion',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated background pattern
                      ...List.generate(12, (index) {
                        return Positioned(
                          left: (index * 60.0) % 400,
                          top: 20 + (index * 20.0) % 160,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(duration: 2000.ms)
                          .then(delay: (index * 200).ms)
                          .fadeOut(duration: 2000.ms),
                        );
                      }),
                      
                      // Welcome message
                      Positioned(
                        bottom: 80,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Allma',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideX(begin: -0.3),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'Select a companion to start your AI relationship journey',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideX(begin: -0.3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            SliverPersistentHeader(
              delegate: _SearchAndFilterDelegate(_onSearch, _onFilterChanged),
              pinned: true,
            ),
            
            SliverPersistentHeader(
              delegate: _TabBarDelegate(_tabController),
              pinned: true,
            ),
          ];
        },
        body: companionsAsync.when(
          data: (companions) {
            final filteredCompanions = _filterCompanions(companions);
            
            return TabBarView(
              controller: _tabController,
              children: [
                _AllCompanionsTab(companions: filteredCompanions),
                _FavoritesTab(companions: filteredCompanions.where((c) => c.isFavorite).toList()),
                _RecentTab(companions: filteredCompanions),
                _PopularTab(companions: filteredCompanions),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading companions',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(error.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(companionsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: _createNewCompanion,
          icon: const Icon(Icons.add),
          label: const Text('Create New'),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
        ),
      ),
    );
  }

  List<Companion> _filterCompanions(List<Companion> companions) {
    var filtered = companions;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((companion) =>
        companion.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        companion.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    switch (_currentFilter) {
      case CompanionFilter.energetic:
        filtered = filtered.where((c) => c.personality.extraversion > 0.6).toList();
        break;
      case CompanionFilter.caring:
        filtered = filtered.where((c) => c.personality.agreeableness > 0.6).toList();
        break;
      case CompanionFilter.creative:
        filtered = filtered.where((c) => c.personality.openness > 0.6).toList();
        break;
      case CompanionFilter.calm:
        filtered = filtered.where((c) => c.personality.neuroticism < 0.4).toList();
        break;
      case CompanionFilter.all:
      default:
        break;
    }
    
    return filtered;
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(CompanionFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  void _createNewCompanion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateCompanionPage(),
      ),
    );
  }

  void _onCompanionSelected(Companion companion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanionProfilePage(companionId: companion.id),
      ),
    );
  }

  void _onCompanionFavorited(Companion companion) {
    ref.read(companionsProvider.notifier).toggleFavorite(companion.id);
  }
}

enum CompanionFilter { all, energetic, caring, creative, calm }

class _SearchAndFilterDelegate extends SliverPersistentHeaderDelegate {
  final Function(String) onSearch;
  final Function(CompanionFilter) onFilterChanged;

  _SearchAndFilterDelegate(this.onSearch, this.onFilterChanged);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search companions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
          )
          .animate()
          .fadeIn(delay: 600.ms)
          .slideY(begin: -0.3),
          
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  filter: CompanionFilter.all,
                  onSelected: onFilterChanged,
                ),
                _FilterChip(
                  label: 'Energetic',
                  filter: CompanionFilter.energetic,
                  onSelected: onFilterChanged,
                ),
                _FilterChip(
                  label: 'Caring',
                  filter: CompanionFilter.caring,
                  onSelected: onFilterChanged,
                ),
                _FilterChip(
                  label: 'Creative',
                  filter: CompanionFilter.creative,
                  onSelected: onFilterChanged,
                ),
                _FilterChip(
                  label: 'Calm',
                  filter: CompanionFilter.calm,
                  onSelected: onFilterChanged,
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(delay: 700.ms)
          .slideY(begin: -0.3),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _FilterChip extends StatefulWidget {
  final String label;
  final CompanionFilter filter;
  final Function(CompanionFilter) onSelected;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.onSelected,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(widget.label),
        selected: _isSelected,
        onSelected: (selected) {
          setState(() {
            _isSelected = selected;
          });
          widget.onSelected(widget.filter);
        },
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
        checkmarkColor: theme.colorScheme.primary,
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate(this.tabController);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Favorites'),
          Tab(text: 'Recent'),
          Tab(text: 'Popular'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _AllCompanionsTab extends ConsumerWidget {
  final List<Companion> companions;

  const _AllCompanionsTab({required this.companions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (companions.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off,
        title: 'No Companions Found',
        subtitle: 'Try adjusting your search or filters',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CompanionGrid(
        companions: companions,
        onCompanionSelected: (companion) => _openProfile(context, companion),
        onCompanionFavorited: (companion) => ref.read(companionsProvider.notifier).toggleFavorite(companion.id),
      ),
    );
  }

  void _openProfile(BuildContext context, Companion companion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanionProfilePage(companionId: companion.id),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  final List<Companion> companions;

  const _FavoritesTab({required this.companions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (companions.isEmpty) {
      return _EmptyState(
        icon: Icons.favorite_border,
        title: 'No Favorites Yet',
        subtitle: 'Tap the heart icon on companions you like',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CompanionGrid(
        companions: companions,
        onCompanionSelected: (companion) => _openProfile(context, companion),
        onCompanionFavorited: (companion) => ref.read(companionsProvider.notifier).toggleFavorite(companion.id),
      ),
    );
  }

  void _openProfile(BuildContext context, Companion companion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanionProfilePage(companionId: companion.id),
      ),
    );
  }
}

class _RecentTab extends ConsumerWidget {
  final List<Companion> companions;

  const _RecentTab({required this.companions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort by last interaction (for now, just use creation date)
    final recentCompanions = [...companions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (recentCompanions.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: 'No Recent Chats',
        subtitle: 'Start a conversation to see recent companions here',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CompanionGrid(
        companions: recentCompanions,
        onCompanionSelected: (companion) => _openProfile(context, companion),
        onCompanionFavorited: (companion) => ref.read(companionsProvider.notifier).toggleFavorite(companion.id),
      ),
    );
  }

  void _openProfile(BuildContext context, Companion companion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanionProfilePage(companionId: companion.id),
      ),
    );
  }
}

class _PopularTab extends ConsumerWidget {
  final List<Companion> companions;

  const _PopularTab({required this.companions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort by popularity (for now, just randomize)
    final popularCompanions = [...companions]..shuffle();

    if (popularCompanions.isEmpty) {
      return _EmptyState(
        icon: Icons.trending_up,
        title: 'No Popular Companions',
        subtitle: 'Check back later for trending companions',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CompanionGrid(
        companions: popularCompanions,
        onCompanionSelected: (companion) => _openProfile(context, companion),
        onCompanionFavorited: (companion) => ref.read(companionsProvider.notifier).toggleFavorite(companion.id),
      ),
    );
  }

  void _openProfile(BuildContext context, Companion companion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanionProfilePage(companionId: companion.id),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          )
          .animate()
          .scale(duration: 600.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          )
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.3),
          
          const SizedBox(height: 8),
          
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 400.ms)
          .slideY(begin: 0.3),
        ],
      ),
    );
  }
}