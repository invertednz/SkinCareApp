import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/analytics.dart';
import '../../theme/brand.dart';
import '../profile/profile_service.dart';
import 'data/iap_service.dart';

class TrialOfferScreen extends StatefulWidget {
  const TrialOfferScreen({super.key});

  @override
  State<TrialOfferScreen> createState() => _TrialOfferScreenState();
}

class _TrialOfferScreenState extends State<TrialOfferScreen> {
  bool _isLoading = false;
  bool _iapInitialized = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.capture('trial_offer_view', {});
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    if (kIsWeb) return;
    final success = await IAPService.instance.initialize();
    if (!mounted) return;
    setState(() {
      _iapInitialized = success;
    });
  }

  String _annualPrice() {
    final product = IAPService.instance.annualProduct;
    return (product?.price ?? '\$47.00/year').replaceAll('\u0000', '');
  }

  Future<void> _handleStartTrial() async {
    AnalyticsService.capture('trial_start_tapped', {});

    if (kIsWeb || kDebugMode) {
      ProfileService.instance.setSubscriptionForDebug(true);
      if (mounted) {
        context.go('/tabs');
      }
      return;
    }

    if (!_iapInitialized) {
      _showErrorSnackBar('Payment system not available. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await IAPService.instance.purchaseProduct(IAPService.annualProductId);
      if (!success) {
        _showErrorSnackBar('We couldn\'t start your trial. Please try again.');
      }
    } catch (error) {
      _showErrorSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _handleComparePlans() {
    AnalyticsService.capture('trial_compare_plans_tapped', {});
    context.go('/paywall');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and logo
            _buildHeader(context),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Brand.textPrimary,
                        ),
                        children: [
                          const TextSpan(text: 'Try '),
                          TextSpan(
                            text: 'SkinCare',
                            style: TextStyle(color: Brand.primaryStart),
                          ),
                          const TextSpan(text: ' free'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Gift icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Brand.primaryStart.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: 40,
                        color: Brand.primaryStart,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Subtitle
                    Text(
                      'No payment today, full access to all features, cancel any time',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Brand.primaryStart,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'We\'ll send you a reminder before your trial ends',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Brand.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Unlimited access during your trial',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Brand.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Reminder text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Brand.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Brand.borderLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Brand.primaryStart,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'We\'ll remind you when your trial ends',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Brand.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Timeline
                    _buildTimeline(context),
                    
                    const SizedBox(height: 32),
                    
                    // Plan card
                    _buildPlanCard(context),
                    
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Brand.textPrimary),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: Brand.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.spa,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SkinCare',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Brand.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          icon: Icons.play_circle_filled,
          iconColor: Brand.primaryStart,
          title: 'Today',
          subtitle: 'Unlock full access to SkinCare and transform your skin',
          isFirst: true,
        ),
        _TimelineItem(
          icon: Icons.notifications_active,
          iconColor: Brand.primaryEnd,
          title: 'In 2 days',
          subtitle: 'We\'ll send a reminder before your trial ends',
          isFirst: false,
        ),
        _TimelineItem(
          icon: Icons.remove_circle,
          iconColor: const Color(0xFF5DADE2),
          title: 'In 3 days',
          subtitle: 'Your subscription begins unless you cancel before',
          isFirst: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.primaryStart.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.primaryStart.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Brand.primaryStart.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'FREE TRIAL',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Brand.primaryStart,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Brand.primaryStart, width: 2),
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 14,
                  color: Brand.primaryStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Try it free',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Brand.textPrimary,
                      ),
                    ),
                    Text(
                      'No commitment. Cancel anytime',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Brand.textSecondary,
                      ),
                    ),
                    Text(
                      'Full access to all features',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Brand.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _annualPrice(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Brand.primaryStart,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Try for FREE button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleStartTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: Brand.primaryStart,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Try for FREE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Compare plans button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _handleComparePlans,
              style: OutlinedButton.styleFrom(
                foregroundColor: Brand.textPrimary,
                side: BorderSide(color: Brand.borderMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Compare plans',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 16,
                    color: Brand.borderMedium,
                  ),
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Brand.borderMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 0 : 8,
                bottom: isLast ? 0 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Brand.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Brand.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
