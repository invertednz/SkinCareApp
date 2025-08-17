import 'package:flutter/material.dart';
import 'responsive_wrapper.dart';

/// Test widget to verify responsive behavior at different breakpoints
class ResponsiveTestWidget extends StatelessWidget {
  const ResponsiveTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive Test'),
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: Breakpoints.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreakpointInfo(context),
              const SizedBox(height: 24),
              _buildResponsiveGrid(context),
              const SizedBox(height: 24),
              _buildResponsiveText(context),
              const SizedBox(height: 24),
              _buildResponsiveButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakpointInfo(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(context);
    final isTablet = Breakpoints.isTablet(context);
    final isDesktop = Breakpoints.isDesktop(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Width: ${screenWidth.toInt()}px'),
            Text('Breakpoint: ${isMobile ? 'Mobile' : isTablet ? 'Tablet' : 'Desktop'}'),
            Text('Is Mobile: $isMobile'),
            Text('Is Tablet: $isTablet'),
            Text('Is Desktop: $isDesktop'),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildGrid(context, 1),
      tablet: _buildGrid(context, 2),
      desktop: _buildGrid(context, 3),
    );
  }

  Widget _buildGrid(BuildContext context, int columns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responsive Grid ($columns columns)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Card(
              child: Center(
                child: Text('Item ${index + 1}'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveText(BuildContext context) {
    final fontScale = Breakpoints.getResponsiveFontScale(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responsive Typography',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Font Scale: ${fontScale.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'This is a headline that scales with screen size.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * fontScale,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is body text that also scales appropriately for different screen sizes. '
          'On mobile devices, it maintains readability while on desktop it can be slightly larger.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveButtons(BuildContext context) {
    return ResponsiveLayout(
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mobile Layout (Stacked)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {},
            child: const Text('Primary Action'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Secondary Action'),
          ),
        ],
      ),
      tablet: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tablet Layout (Mixed)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Primary Action'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Secondary Action'),
                ),
              ),
            ],
          ),
        ],
      ),
      desktop: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desktop Layout (Inline)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () {},
                child: const Text('Primary Action'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Secondary Action'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
