import 'package:flutter/material.dart';
import '../../../widgets/error_widget.dart';
import '../../../utils/breakpoints.dart';
import 'data/insights_repository.dart';
import 'presentation/insights_widgets.dart';
import 'services/insights_trigger_service.dart';
import '../../services/analytics.dart';
import '../../services/analytics_events.dart';
import 'package:go_router/go_router.dart';
import '../../theme/brand.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late final InsightsRepository _repository;
  late final InsightsTriggerService _triggerService;

  @override
  void initState() {
    super.initState();
    _repository = InsightsRepository.instance;
    _triggerService = InsightsTriggerService.instance;
    
    // Load cached insights on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repository.loadCachedInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: ListenableBuilder(
          listenable: _repository,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: Breakpoints.getResponsivePadding(context, const EdgeInsets.all(16.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    _buildHeader(context, theme),
                    const SizedBox(height: 16),
                    // Dashboard quick links (from index.html design)
                    _buildDashboard(context),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Skin Insights',
                    style: Breakpoints.getResponsiveTextStyle(
                      context,
                      (theme.textTheme.headlineMedium ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-powered analysis of your skin health journey',
                    style: Breakpoints.getResponsiveTextStyle(
                      context,
                      (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_repository.currentInsights != null && !_repository.loading)
              IconButton(
                onPressed: _repository.canRefresh 
                    ? () => _handleManualRefresh()
                    : null,
                icon: const Icon(Icons.refresh),
                tooltip: _repository.canRefresh 
                    ? 'Generate new insights'
                    : _triggerService.formatCooldownRemaining(),
              ),
          ],
        ),
        if (_repository.lastGenerated != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last updated: ${_formatLastGenerated(_repository.lastGenerated!)}',
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width >= 900) {
      crossAxisCount = 4;
    } else if (width >= 600) {
      crossAxisCount = 3;
    }

    final items = [
      _DashboardItem(
        title: 'Insights',
        icon: Icons.insights,
        color: Colors.blue,
        onTap: () => context.push('/insights/details'),
      ),
      _DashboardItem(
        title: 'Diet',
        icon: Icons.restaurant,
        color: Colors.orange,
        onTap: () => context.push('/diet'),
      ),
      _DashboardItem(
        title: 'Supplements',
        icon: Icons.medication_outlined,
        color: Brand.deepEnd,
        onTap: () => context.push('/supplements'),
      ),
      _DashboardItem(
        title: 'Routine',
        icon: Icons.checklist_rtl,
        color: Colors.indigo,
        onTap: () => context.push('/routine'),
      ),
      _DashboardItem(
        title: 'Diary',
        icon: Icons.book_outlined,
        color: Colors.blueGrey,
        onTap: () => context.go('/tabs/diary'),
      ),
      _DashboardItem(
        title: 'Chat',
        icon: Icons.chat_bubble_outline,
        color: Colors.purple,
        onTap: () => context.go('/tabs/chat'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _DashboardCard(item: items[index]),
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: Breakpoints.getResponsivePadding(context, const EdgeInsets.all(16.0)),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating Insights',
              style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing your skin health data to provide personalized insights...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    return CompactErrorWidget(
      error: _repository.error!,
      onRetry: () => _repository.generateInsights(),
    );
  }

  

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: Breakpoints.getResponsivePadding(context, const EdgeInsets.all(16.0)),
        child: Column(
          children: [
            Icon(
              Icons.insights,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Insights Yet',
              style: (theme.textTheme.headlineSmall ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your skin health data to receive personalized insights and recommendations.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('/diet');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Start Logging'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _handleManualRefresh(bypassCooldown: true),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Sample'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsContent(BuildContext context, InsightsData insights) {
    // Track insights view
    AnalyticsService.capture(AnalyticsEvents.insightsView, {
      'recommendations_count': insights.recommendations.length,
      'data_period_days': insights.dataPeriod.daysAnalyzed,
      'generated_at': insights.generatedAt.toIso8601String(),
    });

    return Column(
      children: [
        // Summary section
        InsightsSummaryCard(summary: insights.summary),
        const SizedBox(height: 16),
        
        // Recommendations sections
        RecommendationsSection(
          title: 'Continue Doing',
          icon: Icons.check_circle,
          color: const Color(0xFF6A11CB),
          recommendations: insights.continueRecommendations,
          onAddToRoutine: _onAddToRoutine,
        ),
        const SizedBox(height: 16),
        
        RecommendationsSection(
          title: 'Start Doing',
          icon: Icons.add_circle,
          color: Colors.blue.shade600,
          recommendations: insights.startRecommendations,
          onAddToRoutine: _onAddToRoutine,
        ),
        const SizedBox(height: 16),
        
        RecommendationsSection(
          title: 'Consider Stopping',
          icon: Icons.remove_circle,
          color: Colors.orange.shade600,
          recommendations: insights.stopRecommendations,
        ),
        const SizedBox(height: 16),
        
        // Action plan section
        ActionPlanCard(actionPlan: insights.actionPlan),
        const SizedBox(height: 16),
        
        // Metadata footer
        InsightsMetadata(insights: insights),
        
        // Additional responsive spacing
        SizedBox(height: Breakpoints.getResponsiveSpacing(context, 32)),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    await _triggerService.triggerManualRefresh();
  }

  Future<void> _handleManualRefresh({bool bypassCooldown = false}) async {
    final success = await _triggerService.triggerManualRefresh(
      bypassCooldown: bypassCooldown,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait before refreshing. ${_triggerService.formatCooldownRemaining()}'),
          action: SnackBarAction(
            label: 'Override',
            onPressed: () => _handleManualRefresh(bypassCooldown: true),
          ),
        ),
      );
    }
  }

  void _onAddToRoutine(InsightsRecommendation recommendation) {
    // Track add to routine event
    AnalyticsService.capture(AnalyticsEvents.insightsAddToRoutine, {
      'recommendation_title': recommendation.title,
      'recommendation_category': recommendation.category,
      'recommendation_priority': recommendation.priority,
      'confidence_level': recommendation.confidenceLevel,
    });

    // Navigate to routine screen
    context.push('/routine');
  }

  String _formatLastGenerated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.item});
  final _DashboardItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const Spacer(),
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
