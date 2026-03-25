import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/privacy/privacy_manager.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/loading_indicators.dart';
import '../../../shared/utils/animation_utils.dart';
import '../widgets/privacy_setting_tile.dart';
import '../widgets/data_export_card.dart';
import '../widgets/data_usage_chart.dart';

class PrivacyDashboardPage extends ConsumerStatefulWidget {
  const PrivacyDashboardPage({super.key});

  @override
  ConsumerState<PrivacyDashboardPage> createState() => _PrivacyDashboardPageState();
}

class _PrivacyDashboardPageState extends ConsumerState<PrivacyDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Processing privacy settings...',
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Privacy Center',
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
                        // Privacy icons pattern
                        ...List.generate(15, (index) {
                          return Positioned(
                            left: (index * 80.0) % 400,
                            top: 30 + (index * 25.0) % 140,
                            child: Icon(
                              [Icons.security, Icons.shield, Icons.lock, Icons.privacy_tip][index % 4],
                              color: Colors.white.withOpacity(0.1),
                              size: 24,
                            )
                            .animate(onPlay: (controller) => controller.repeat())
                            .fadeIn(duration: 2000.ms)
                            .then(delay: (index * 200).ms)
                            .fadeOut(duration: 2000.ms),
                          );
                        }),
                        
                        // Main content
                        Positioned(
                          bottom: 80,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Privacy Matters',
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
                                'Control how your data is collected, used, and shared',
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
                delegate: _TabBarDelegate(_tabController),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: const [
              _SettingsTab(),
              _DataTab(),
              _SecurityTab(),
              _ComplianceTab(),
            ],
          ),
        ),
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
        isScrollable: true,
        tabs: const [
          Tab(
            icon: Icon(Icons.settings),
            text: 'Settings',
          ),
          Tab(
            icon: Icon(Icons.storage),
            text: 'Data',
          ),
          Tab(
            icon: Icon(Icons.security),
            text: 'Security',
          ),
          Tab(
            icon: Icon(Icons.gavel),
            text: 'Compliance',
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

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
          .slideInFromLeft(delay: 100.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Configure how your data is processed and used',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          )
          .slideInFromLeft(delay: 200.ms),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            'Data Collection',
            [
              PrivacySettingTile(
                title: 'Conversation Analytics',
                subtitle: 'Allow analysis of conversation patterns for improvement',
                value: true,
                onChanged: (value) {},
              ),
              PrivacySettingTile(
                title: 'Memory Formation',
                subtitle: 'Store conversation memories for personalization',
                value: true,
                onChanged: (value) {},
              ),
              PrivacySettingTile(
                title: 'Usage Statistics',
                subtitle: 'Collect anonymous usage data',
                value: false,
                onChanged: (value) {},
              ),
            ],
            Icons.data_usage,
            theme,
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            'Personalization',
            [
              PrivacySettingTile(
                title: 'Behavioral Learning',
                subtitle: 'Adapt companion personality to your preferences',
                value: true,
                onChanged: (value) {},
              ),
              PrivacySettingTile(
                title: 'Context Awareness',
                subtitle: 'Use conversation context for better responses',
                value: true,
                onChanged: (value) {},
              ),
              PrivacySettingTile(
                title: 'Mood Detection',
                subtitle: 'Analyze emotional context in conversations',
                value: false,
                onChanged: (value) {},
              ),
            ],
            Icons.psychology,
            theme,
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsSection(
            'Sharing & Communication',
            [
              PrivacySettingTile(
                title: 'Third-party Integration',
                subtitle: 'Allow integration with external services',
                value: false,
                onChanged: (value) {},
              ),
              PrivacySettingTile(
                title: 'Research Participation',
                subtitle: 'Contribute anonymized data for AI research',
                value: false,
                onChanged: (value) {},
              ),
              PrivacySettingTile(
                title: 'Companion Sharing',
                subtitle: 'Allow sharing companion configurations',
                value: false,
                onChanged: (value) {},
              ),
            ],
            Icons.share,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    String title,
    List<Widget> children,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    )
    .slideInFromBottom(delay: 300.ms);
  }
}

class _DataTab extends ConsumerWidget {
  const _DataTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Management',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
          .slideInFromLeft(delay: 100.ms),
          
          const SizedBox(height: 24),
          
          // Data usage overview
          Container(
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
                      Icons.storage,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Storage Usage',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const DataUsageChart(),
              ],
            ),
          )
          .slideInFromBottom(delay: 200.ms),
          
          const SizedBox(height: 24),
          
          // Data export
          const DataExportCard()
              .slideInFromBottom(delay: 300.ms),
          
          const SizedBox(height: 24),
          
          // Data retention settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_delete,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Data Retention',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _RetentionSetting(
                  title: 'Conversation History',
                  description: 'How long to keep chat messages',
                  currentValue: '1 Year',
                  options: ['1 Month', '3 Months', '6 Months', '1 Year', 'Forever'],
                ),
                const SizedBox(height: 12),
                _RetentionSetting(
                  title: 'Memory Data',
                  description: 'How long to keep formed memories',
                  currentValue: '1 Year',
                  options: ['6 Months', '1 Year', '2 Years', 'Forever'],
                ),
                const SizedBox(height: 12),
                _RetentionSetting(
                  title: 'Analytics Data',
                  description: 'How long to keep usage analytics',
                  currentValue: '3 Months',
                  options: ['1 Month', '3 Months', '6 Months', '1 Year'],
                ),
              ],
            ),
          )
          .slideInFromBottom(delay: 400.ms),
          
          const SizedBox(height: 24),
          
          // Danger zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Danger Zone',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedButton(
                  onPressed: () => _showDeleteAllDataDialog(context),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  child: const Text('Delete All Data'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Permanently delete all your data. This action cannot be undone.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          )
          .slideInFromBottom(delay: 500.ms),
        ],
      ),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to permanently delete all your data? This includes:\n\n'
          '• All conversation history\n'
          '• All memory data\n'
          '• All companion configurations\n'
          '• All settings and preferences\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete all data
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

class _RetentionSetting extends StatelessWidget {
  final String title;
  final String description;
  final String currentValue;
  final List<String> options;

  const _RetentionSetting({
    required this.title,
    required this.description,
    required this.currentValue,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: currentValue,
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) {
              // TODO: Implement retention setting change
            },
          ),
        ],
      ),
    );
  }
}

class _SecurityTab extends ConsumerWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Security settings coming soon...'),
    );
  }
}

class _ComplianceTab extends ConsumerWidget {
  const _ComplianceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Compliance information coming soon...'),
    );
  }
}