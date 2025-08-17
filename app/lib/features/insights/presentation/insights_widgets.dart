import 'package:flutter/material.dart';
import '../data/insights_repository.dart';
import '../../../widgets/responsive_wrapper.dart';

/// Widget to display insights summary section
class InsightsSummaryCard extends StatelessWidget {
  const InsightsSummaryCard({
    super.key,
    required this.summary,
  });

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: Breakpoints.getResponsivePadding(context),
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
                  'Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summary.overallAssessment,
              style: theme.textTheme.bodyLarge,
            ),
            if (summary.keyTrends.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Key Trends',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...summary.keyTrends.map((trend) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, right: 8),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        trend,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (summary.dataQualityNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary.dataQualityNote!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget to display recommendations by category
class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.recommendations,
    this.onAddToRoutine,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<InsightsRecommendation> recommendations;
  final void Function(InsightsRecommendation)? onAddToRoutine;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: Breakpoints.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => 
              RecommendationTile(
                recommendation: recommendation,
                onAddToRoutine: onAddToRoutine,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual recommendation tile
class RecommendationTile extends StatelessWidget {
  const RecommendationTile({
    super.key,
    required this.recommendation,
    this.onAddToRoutine,
  });

  final InsightsRecommendation recommendation;
  final void Function(InsightsRecommendation)? onAddToRoutine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recommendation.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _ConfidenceBadge(level: recommendation.confidenceLevel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.rationale,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onAddToRoutine != null && 
              (recommendation.category == 'start' || recommendation.category == 'continue')) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onAddToRoutine!(recommendation),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add to Routine'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confidence level badge
class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    
    switch (level.toLowerCase()) {
      case 'high':
        backgroundColor = const Color(0xFFE0C3FC).withOpacity(0.3);
        textColor = const Color(0xFF6A11CB);
        break;
      case 'medium':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'low':
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Action plan section
class ActionPlanCard extends StatelessWidget {
  const ActionPlanCard({
    super.key,
    required this.actionPlan,
  });

  final InsightsActionPlan actionPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: Breakpoints.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Action Plan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (actionPlan.immediateActions.isNotEmpty)
              _ActionSection(
                title: 'Immediate Actions',
                icon: Icons.flash_on,
                items: actionPlan.immediateActions,
                color: Colors.red.shade600,
              ),
            if (actionPlan.weeklyGoals.isNotEmpty)
              _ActionSection(
                title: 'Weekly Goals',
                icon: Icons.calendar_view_week,
                items: actionPlan.weeklyGoals,
                color: Colors.blue.shade600,
              ),
            if (actionPlan.monitoringFocus.isNotEmpty)
              _ActionSection(
                title: 'Monitoring Focus',
                icon: Icons.visibility,
                items: actionPlan.monitoringFocus,
                color: const Color(0xFF6A11CB),
              ),
          ],
        ),
      ),
    );
  }
}

/// Action section within action plan
class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Insights metadata footer
class InsightsMetadata extends StatelessWidget {
  const InsightsMetadata({
    super.key,
    required this.insights,
  });

  final InsightsData insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: Breakpoints.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analysis Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Period: ${insights.dataPeriod.startDate} to ${insights.dataPeriod.endDate} (${insights.dataPeriod.daysAnalyzed} days)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Generated: ${_formatDateTime(insights.generatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                insights.disclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
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
