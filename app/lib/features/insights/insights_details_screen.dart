import 'package:flutter/material.dart';
import '../../utils/breakpoints.dart';

class InsightsDetailsScreen extends StatelessWidget {
  const InsightsDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Recommendations'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Breakpoints.getResponsivePadding(context, const EdgeInsets.all(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro
            Text(
              'Your Personalized Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Based on your tracking data, here are recommendations to improve your skin health.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Progress Overview
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.show_chart, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Skin Health Trend', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text('Last 30 days', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ]),
                      Text('+12%', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProgressBar(percent: 0.68),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('68% improvement', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text('Recommendations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Continue Doing
            _LabeledCard(
              label: 'Continue Doing',
              labelIcon: Icons.check_circle,
              labelColor: theme.colorScheme.primary,
              items: const [
                ('Morning Hydration', 'Your skin shows better hydration on days you use your morning moisturizer.'),
                ('Vitamin C Serum', 'Continued use has shown positive effects on your skin tone.'),
              ],
            ),

            // Start Doing
            _LabeledCard(
              label: 'Start Doing',
              labelIcon: Icons.play_circle_fill,
              labelColor: Colors.blue,
              items: const [
                ('Increase Water Intake', 'Your skin appears dehydrated. Try drinking at least 8 glasses of water daily.'),
                ('Nighttime Retinol', 'Based on your age and skin concerns, adding retinol could help with texture.'),
              ],
            ),

            // Consider Stopping
            _LabeledCard(
              label: 'Consider Stopping',
              labelIcon: Icons.stop_circle,
              labelColor: Colors.red,
              items: const [
                ('Harsh Exfoliation', 'Your skin shows signs of irritation after physical exfoliation. Consider switching to chemical exfoliants.'),
                ('Dairy Consumption', "There's a correlation between your dairy intake and breakouts. Try reducing for 2 weeks."),
              ],
            ),

            // Pattern Analysis
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pattern Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _PatternItem(
                    title: 'Sleep Quality & Skin Health',
                    badge: 'Strong Correlation',
                    badgeColor: theme.colorScheme.secondary,
                    explanation: 'Your skin health scores are 42% higher on days following 7+ hours of sleep.',
                    percent: 0.85,
                  ),
                  const SizedBox(height: 12),
                  _PatternItem(
                    title: 'Stress Levels & Breakouts',
                    badge: 'Moderate Correlation',
                    badgeColor: theme.colorScheme.primary,
                    explanation: 'Breakouts increase by 28% during periods of reported high stress.',
                    percent: 0.65,
                  ),
                ],
              ),
            ),

            // Action Plan
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Action Plan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("Based on your data, here's a personalized plan for the next 2 weeks:", style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  _BulletList(items: const [
                    'Increase water intake to 8 glasses daily',
                    'Reduce dairy consumption by 50%',
                    'Aim for 7-8 hours of sleep consistently',
                    'Switch to gentle chemical exfoliation 2x weekly',
                    'Continue with your current morning hydration routine',
                  ]),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Add to My Routine'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Breakpoints.getResponsiveSpacing(context, 32)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: Breakpoints.getResponsivePadding(context, const EdgeInsets.all(16)),
        child: child,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent});
  final double percent; // 0..1
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Container(color: theme.colorScheme.surfaceContainerHighest),
            FractionallySizedBox(
              widthFactor: percent.clamp(0, 1),
              child: Container(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledCard extends StatelessWidget {
  const _LabeledCard({
    required this.label,
    required this.labelIcon,
    required this.labelColor,
    required this.items,
  });
  final String label;
  final IconData labelIcon;
  final Color labelColor;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(labelIcon, color: labelColor),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.titleMedium?.copyWith(color: labelColor, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.chevron_right, size: 18, color: labelColor),
                  const SizedBox(width: 4),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.$1, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(e.$2, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ])),
                ]),
              )),
        ],
      ),
    );
  }
}

class _PatternItem extends StatelessWidget {
  const _PatternItem({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.explanation,
    required this.percent,
  });
  final String title;
  final String badge;
  final Color badgeColor;
  final String explanation;
  final double percent;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
              child: Text(badge, style: theme.textTheme.labelSmall?.copyWith(color: badgeColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(explanation, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        _ProgressBar(percent: percent),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6, right: 8), decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)),
                  Expanded(child: Text(e, style: theme.textTheme.bodyMedium)),
                ]),
              ))
          .toList(),
    );
  }
}
