import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/companions/models/companion.dart';
import '../../../core/companions/providers/companions_provider.dart';
import '../../../shared/utils/constants.dart';
import '../widgets/companion_profile_header.dart';
import '../../chat/pages/chat_page.dart';

class CompanionProfilePage extends ConsumerStatefulWidget {
  final String companionId;

  const CompanionProfilePage({
    required this.companionId,
    super.key,
  });

  @override
  ConsumerState<CompanionProfilePage> createState() => _CompanionProfilePageState();
}

class _CompanionProfilePageState extends ConsumerState<CompanionProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companionsAsync = ref.watch(companionsProvider);
    
    return companionsAsync.when(
      data: (companions) {
        final companion = companions.firstWhere(
          (c) => c.id == widget.companionId,
          orElse: () => throw Exception('Companion not found'),
        );
        
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: CompanionProfileHeader(
                    companion: companion,
                    onFavorite: () => _toggleFavorite(companion),
                    onChat: () => _openChat(companion),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _TabBarDelegate(_tabController),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _PersonalityTab(companion: companion),
                _MemoriesTab(companion: companion),
                _SettingsTab(companion: companion),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading companion',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(Companion companion) {
    ref.read(companionsProvider.notifier).toggleFavorite(companion.id);
  }

  void _openChat(Companion companion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(companion: companion),
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
          Tab(
            icon: Icon(Icons.psychology),
            text: 'Personality',
          ),
          Tab(
            icon: Icon(Icons.auto_stories),
            text: 'Memories',
          ),
          Tab(
            icon: Icon(Icons.settings),
            text: 'Settings',
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _PersonalityTab extends StatelessWidget {
  final Companion companion;

  const _PersonalityTab({required this.companion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality Traits',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
          .animate()
          .fadeIn()
          .slideX(begin: -0.3),
          
          const SizedBox(height: 20),
          
          PersonalityTraitBar(
            label: 'Extraversion',
            value: companion.personality.extraversion,
            color: Colors.orange,
            icon: Icons.groups,
          ),
          
          const SizedBox(height: 12),
          
          PersonalityTraitBar(
            label: 'Agreeableness',
            value: companion.personality.agreeableness,
            color: Colors.green,
            icon: Icons.favorite,
          ),
          
          const SizedBox(height: 12),
          
          PersonalityTraitBar(
            label: 'Conscientiousness',
            value: companion.personality.conscientiousness,
            color: Colors.blue,
            icon: Icons.task_alt,
          ),
          
          const SizedBox(height: 12),
          
          PersonalityTraitBar(
            label: 'Emotional Stability',
            value: 1.0 - companion.personality.neuroticism,
            color: Colors.purple,
            icon: Icons.psychology,
          ),
          
          const SizedBox(height: 12),
          
          PersonalityTraitBar(
            label: 'Openness',
            value: companion.personality.openness,
            color: Colors.teal,
            icon: Icons.lightbulb,
          ),
          
          const SizedBox(height: 24),
          
          _PersonalityInsights(companion: companion),
        ],
      ),
    );
  }
}

class _PersonalityInsights extends StatelessWidget {
  final Companion companion;

  const _PersonalityInsights({required this.companion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _generateInsights(companion.personality);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Personality Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_right,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    )
    .animate()
    .fadeIn(delay: 300.ms)
    .slideY(begin: 0.3);
  }

  List<String> _generateInsights(CompanionPersonality personality) {
    final insights = <String>[];
    
    if (personality.extraversion > 0.7) {
      insights.add('Very social and enjoys engaging conversations');
    } else if (personality.extraversion < 0.3) {
      insights.add('Prefers thoughtful, one-on-one interactions');
    }
    
    if (personality.agreeableness > 0.7) {
      insights.add('Highly empathetic and supportive in relationships');
    }
    
    if (personality.conscientiousness > 0.7) {
      insights.add('Well-organized and reliable in commitments');
    }
    
    if (personality.neuroticism < 0.3) {
      insights.add('Emotionally stable and calming presence');
    }
    
    if (personality.openness > 0.7) {
      insights.add('Creative and enjoys exploring new ideas');
    }
    
    if (insights.isEmpty) {
      insights.add('Well-balanced personality with moderate traits');
    }
    
    return insights;
  }
}

class _MemoriesTab extends StatelessWidget {
  final Companion companion;

  const _MemoriesTab({required this.companion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shared Memories',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your conversations and shared experiences with ${companion.name}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          // Placeholder for memories - will be implemented with memory system
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Memories Yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start chatting with ${companion.name} to create shared memories',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
          .animate()
          .fadeIn()
          .scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final Companion companion;

  const _SettingsTab({required this.companion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Companion Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          _SettingsTile(
            icon: Icons.edit,
            title: 'Edit Companion',
            subtitle: 'Modify appearance and personality',
            onTap: () {
              // TODO: Navigate to edit companion page
            },
          ),
          
          _SettingsTile(
            icon: Icons.history,
            title: 'Clear Chat History',
            subtitle: 'Remove all conversation history',
            onTap: () => _showClearHistoryDialog(context),
          ),
          
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage companion notifications',
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          
          _SettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Settings',
            subtitle: 'Control data sharing and storage',
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          
          const SizedBox(height: 24),
          
          _SettingsTile(
            icon: Icons.delete,
            title: 'Delete Companion',
            subtitle: 'Permanently remove this companion',
            isDestructive: true,
            onTap: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: Text('Are you sure you want to clear all conversation history with ${companion.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement clear history
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Companion'),
        content: Text('Are you sure you want to permanently delete ${companion.name}? This will remove all conversations, memories, and data associated with this companion. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
              // TODO: Implement delete companion
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive 
              ? theme.colorScheme.error 
              : theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isDestructive ? theme.colorScheme.error : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .slideX(begin: 0.3);
  }
}