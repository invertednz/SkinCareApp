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

// Lightweight line chart using CustomPainter (no external deps)
class _LineChart extends StatelessWidget {
  const _LineChart({required this.values});
  final List<num> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox(height: 80);
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _LineChartPainter(values: values.map((e) => e.toDouble()).toList()),
        child: Container(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values});
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    final path = Path();
    final paintLine = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final n = values.length;
    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * size.width;
      final norm = (values[i] - minV) / range;
      final y = size.height - (norm * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.values != values;
}

class _TrendCaption extends StatelessWidget {
  const _TrendCaption();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.trending_up, color: Color(0xFFA8EDEA)),
        SizedBox(width: 6),
        Text('Improving this week', style: TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Current Streak', style: TextStyle(fontSize: 12, color: Colors.black54)),
              SizedBox(height: 2),
              Text('7 days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/tabs/chat'),
      borderRadius: BorderRadius.circular(16),
      child: _CardContainer(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Chat', style: TextStyle(fontSize: 12, color: Colors.black54)),
                SizedBox(height: 2),
                Text('Ask the AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Shared card container matching brand (white surface, soft border, radius)
class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// Simple sparkline using bars to avoid extra deps
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});
  final List<num> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox(height: 64);
    final maxV = values.reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 16 + (48 * (v.toDouble() / (maxV == 0 ? 1 : maxV))),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
                    // Skin Health Trend + Streak
                    _buildTrendAndStreakRow(context),
                    const SizedBox(height: 16),
                    // Recommendations preview
                    _buildRecommendationsPreview(context),
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
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _DashboardCard(item: items[index]),
    );
  }

  // New: Trend + Streak row
  Widget _buildTrendAndStreakRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _TrendProgressCard(),
                ),
                if (isWide) const SizedBox(width: 12),
                if (isWide)
                  Expanded(
                    flex: 1,
                    child: _StreakCard(),
                  ),
                if (isWide) const SizedBox(width: 12),
                if (isWide)
                  Expanded(
                    flex: 1,
                    child: _ChatCard(),
                  ),
              ],
            ),
            if (!isWide) const SizedBox(height: 12),
            if (!isWide)
              Row(
                children: [
                  Expanded(child: _StreakCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _ChatCard()),
                ],
              ),
          ],
        );
      },
    );
  }

  // New: Recommendations preview
  Widget _buildRecommendationsPreview(BuildContext context) {
    final insights = _repository.currentInsights;
    final hasData = insights != null && !_repository.loading && _repository.error == null;
    final items = hasData
        ? insights!.continueRecommendations
            .followedBy(insights.startRecommendations)
            .take(3)
            .map((r) => _Rec(title: r.title, subtitle: r.rationale))
            .toList()
        : const [
            _Rec(title: 'Morning Hydration', subtitle: 'Your skin shows better hydration on days you hydrate early.'),
            _Rec(title: 'Vitamin C Serum', subtitle: 'Continued use is showing positive effects on tone.'),
          ];

    return _RecommendationsCard(items: items);
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Progress Overview-style Trend card (matches Insights look)
class _TrendProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2FA), // light purple surface to match screenshot
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE6F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.show_chart, color: Color(0xFF6A11CB)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skin Health Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Last 30 days', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Text('+12%', style: TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8E1EF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6A11CB)),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('68% improvement', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

class _Rec {
  final String title;
  final String subtitle;
  const _Rec({required this.title, required this.subtitle});
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.items});
  final List<_Rec> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2FA),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFECE6F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF6A11CB), size: 18),
              ),
              const SizedBox(width: 8),
              const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6A11CB))),
            ],
          ),
          const SizedBox(height: 12),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF6A11CB)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(it.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Text(it.subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
