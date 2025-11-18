import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics.dart';
import '../../services/analytics_events.dart';
import '../../theme/brand.dart';
import '../../widgets/brand_scaffold.dart';
import '../profile/profile_service.dart';
import 'data/iap_service.dart';

const List<String> _donorNames = [
  'Ava', 'Olivia', 'Emma', 'Sophia', 'Isabella', 'Mia', 'Amelia', 'Harper', 'Evelyn', 'Abigail',
  'Emily', 'Ella', 'Elizabeth', 'Camila', 'Luna', 'Sofia', 'Avery', 'Mila', 'Aria', 'Scarlett',
  'Penelope', 'Layla', 'Chloe', 'Victoria', 'Madison', 'Eleanor', 'Grace', 'Nora', 'Riley', 'Zoey',
  'Hannah', 'Hazel', 'Lily', 'Ellie', 'Violet', 'Lillian', 'Zoe', 'Stella', 'Aurora', 'Natalie',
  'Emilia', 'Everly', 'Leah', 'Aubrey', 'Willow', 'Addison', 'Lucy', 'Audrey', 'Bella', 'Nova',
  'Brooklyn', 'Paisley', 'Savannah', 'Claire', 'Skylar', 'Isla', 'Genesis', 'Naomi', 'Elena', 'Caroline',
  'Eliana', 'Anna', 'Maya', 'Valentina', 'Ruby', 'Kennedy', 'Ivy', 'Ariana', 'Aaliyah', 'Cora',
  'Madelyn', 'Alice', 'Kinsley', 'Hailey', 'Gabriella', 'Allison', 'Serenity', 'Autumn', 'Ayla', 'Rylee',
  'Liam', 'Noah', 'Oliver', 'Elijah', 'James', 'William', 'Benjamin', 'Lucas', 'Henry', 'Alexander',
  'Mason', 'Michael', 'Ethan', 'Daniel', 'Jacob', 'Logan', 'Jackson', 'Levi', 'Sebastian', 'Mateo',
];

class PaywallScreenV2 extends StatefulWidget {
  const PaywallScreenV2({super.key});

  @override
  State<PaywallScreenV2> createState() => _PaywallScreenV2State();
}

class _PaywallScreenV2State extends State<PaywallScreenV2> {
  static const String _paywallVariant = 'annual_first_v1';

  final Random _random = Random();

  bool _showAllPlans = false;
  bool _showGiftOffer = false;
  bool _isLoading = false;
  bool _iapInitialized = false;
  String? _giftDonorName;

  @override
  void initState() {
    super.initState();
    AnalyticsService.capture(AnalyticsEvents.paywallView, {
      'variant': _paywallVariant,
    });
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

  Future<void> _handlePurchase(String planType, {bool fromGift = false}) async {
    final baseAnalytics = {
      AnalyticsProperties.plan: planType,
      'variant': _paywallVariant,
      'offer_type': fromGift ? 'gift_match' : 'standard',
      if (_giftDonorName != null) 'gift_donor': _giftDonorName,
    };

    if (kIsWeb) {
      AnalyticsService.capture(AnalyticsEvents.startTrial, {
        ...baseAnalytics,
        AnalyticsProperties.platform: 'web',
      });
      ProfileService.instance.setSubscriptionForDebug(true);
      if (mounted) {
        if (fromGift) {
          context.go('/share-success', extra: _giftDonorName);
        } else {
          context.go('/tabs');
        }
      }
      return;
    }

    if (kDebugMode) {
      AnalyticsService.capture(AnalyticsEvents.startTrial, baseAnalytics);
      ProfileService.instance.setSubscriptionForDebug(true);
      if (mounted && fromGift) {
        context.go('/share-success', extra: _giftDonorName);
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

    String productId;
    switch (planType) {
      case 'monthly':
        productId = IAPService.monthlyProductId;
        break;
      case 'annual':
        productId = IAPService.annualProductId;
        break;
      case 'pay_it_forward':
        productId = IAPService.payItForwardProductId;
        break;
      default:
        productId = IAPService.annualProductId;
    }

    try {
      AnalyticsService.capture(AnalyticsEvents.purchaseInitiated, {
        ...baseAnalytics,
        AnalyticsProperties.productId: productId,
      });

      final success = await IAPService.instance.purchaseProduct(productId);
      if (!success) {
        _showErrorSnackBar('We couldn\'t start your purchase. Please try again.');
      }
    } catch (error) {
      _showErrorSnackBar('Something went wrong. Please try again.');
      AnalyticsService.capture(AnalyticsEvents.purchaseFailure, {
        ...baseAnalytics,
        AnalyticsProperties.error: error.toString(),
        'stage': 'initiation',
      });
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

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _handleRestorePurchases() async {
    if (kIsWeb || kDebugMode) return;
    if (!_iapInitialized) {
      _showErrorSnackBar('Payment system not available. Please try again.');
      return;
    }

    try {
      await IAPService.instance.restorePurchases();
      _showSuccessSnackBar('Checking for previous purchases...');
    } catch (error) {
      _showErrorSnackBar('Unable to restore purchases. Please try again.');
    }
  }

  void _handleShowAllPlans() {
    setState(() {
      _showAllPlans = true;
    });
    AnalyticsService.capture('paywall_show_all_plans', {
      'variant': _paywallVariant,
    });
  }

  void _handleBackToAnnual() {
    setState(() {
      _showAllPlans = false;
    });
    AnalyticsService.capture('paywall_back_to_annual', {
      'variant': _paywallVariant,
    });
  }

  void _handleBackPress() {
    if (_showGiftOffer) return;
    final donor = _donorNames[_random.nextInt(_donorNames.length)];
    setState(() {
      _giftDonorName = donor;
      _showGiftOffer = true;
    });
    AnalyticsService.capture('paywall_gift_offer_shown', {
      'variant': _paywallVariant,
      'donor_name': donor,
    });
  }

  Future<void> _openTerms() async {
    const url = 'https://your-app.com/terms';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openPrivacy() async {
    const url = 'https://your-app.com/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  String _annualPrice() {
    final product = IAPService.instance.annualProduct;
    return (product?.price ?? '\$47.00 / year').replaceAll('\u0000', '');
  }

  String _annualMonthlyEquivalent() {
    final equivalent = IAPService.instance.getAnnualMonthlyEquivalent();
    if (equivalent == 'Price unavailable') {
      return '\$3.92/month';
    }
    return equivalent;
  }

  String _monthlyPrice() {
    final product = IAPService.instance.monthlyProduct;
    return (product?.price ?? '\$9.00 / month').replaceAll('\u0000', '');
  }

  String _payItForwardPrice() {
    final product = IAPService.instance.payItForwardProduct;
    return (product?.price ?? '\$57.00 / year').replaceAll('\u0000', '');
  }

  String _payItForwardMonthlyEquivalent() {
    final equivalent = IAPService.instance.getPayItForwardMonthlyEquivalent();
    if (equivalent == 'Price unavailable') {
      return '\$4.75/month';
    }
    return equivalent;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _showGiftOffer,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          AnalyticsService.capture('paywall_exit', {
            'variant': _paywallVariant,
            'gift_shown': _showGiftOffer,
          });
          return;
        }
        _handleBackPress();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientHeader(
                title: 'Unlock Premium',
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _handleBackPress,
                ),
              ),
              Expanded(
                child: OverlapCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _showGiftOffer
                        ? _buildGiftOffer()
                        : _showAllPlans
                            ? _buildAllPlansView()
                            : _buildAnnualView(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnualView() {
    return Column(
      key: const ValueKey('annual'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Transform your skin',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Get personalized AI insights, track your progress, and achieve your skincare goals with expert guidance.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: Brand.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Brand.mintColor.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annual Membership',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _annualPrice(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_annualMonthlyEquivalent()} equivalent • Best value',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Brand.mintColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Most Popular',
                          style: TextStyle(color: Brand.mintColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Save 48% compared to monthly. Lock in this rate for a full year of unlimited access to all premium features.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _FeatureItem(text: 'AI-powered personalized insights', icon: Icons.psychology_alt_outlined),
        const _FeatureItem(text: 'Daily reminders & accountability', icon: Icons.notifications_active_outlined),
        const _FeatureItem(text: 'Photo analysis & progress tracking', icon: Icons.camera_alt_outlined),
        const _FeatureItem(text: 'Unlimited diary entries & history', icon: Icons.book_outlined),
        const _FeatureItem(text: '24/7 AI chat concierge support', icon: Icons.chat_bubble_outline),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : () => _handlePurchase('annual'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Brand.mintColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Continue with Annual',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _handleShowAllPlans,
          child: Text(
            'See other plans',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
        const Spacer(),
        if (!kDebugMode)
          TextButton(
            onPressed: _handleRestorePurchases,
            child: const Text('Restore Purchases'),
          ),
        const SizedBox(height: 8),
        _FinePrint(onTermsPressed: _openTerms, onPrivacyPressed: _openPrivacy),
      ],
    );
  }

  Widget _buildAllPlansView() {
    return Column(
      key: const ValueKey('allPlans'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBackToAnnual,
            ),
            Expanded(
              child: Text(
                'Choose Your Membership',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Annual Membership',
          price: _annualPrice(),
          subtitle: '${_annualMonthlyEquivalent()} • Best value',
          badge: 'RECOMMENDED',
          isRecommended: true,
          onTap: () => _handlePurchase('annual'),
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Monthly Membership',
          price: _monthlyPrice(),
          subtitle: 'Billed monthly • cancel anytime',
          isRecommended: false,
          onTap: () => _handlePurchase('monthly'),
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Pay It Forward',
          price: _payItForwardPrice(),
          subtitle: '${_payItForwardMonthlyEquivalent()} • Includes \$10 donation',
          badge: null,
          isRecommended: false,
          onTap: () => _handlePurchase('pay_it_forward'),
          isLoading: _isLoading,
        ),
        const SizedBox(height: 20),
        Text(
          'Every plan includes:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const _FeatureItem(text: 'Personalized AI insights & action plans', compact: true),
        const _FeatureItem(text: 'Guided routines & reminders', compact: true),
        const _FeatureItem(text: 'Photo tracking, analysis & secure storage', compact: true),
        const Spacer(),
        if (!kDebugMode)
          TextButton(
            onPressed: _handleRestorePurchases,
            child: const Text('Restore Purchases'),
          ),
        _FinePrint(onTermsPressed: _openTerms, onPrivacyPressed: _openPrivacy),
      ],
    );
  }

  Widget _buildGiftOffer() {
    final donorName = _giftDonorName ?? _donorNames.first;
    const String discountedPrice = '\$27.00 / year';
    const String discountedMonthly = '\$2.25/month equivalent';

    return Column(
      key: const ValueKey('giftOffer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.card_giftcard, color: Color(0xFFA8EDEA), size: 70),
        const SizedBox(height: 16),
        Text(
          '$donorName just sent you a gift',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Our Pay It Forward members believe no one should be priced out of healthy skin. We\'re matching $donorName\'s contribution to lower your yearly membership.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: Brand.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Brand.mintColor.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gifted Pay It Forward Membership',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _payItForwardPrice(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          decoration: TextDecoration.lineThrough,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    discountedPrice,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$discountedMonthly • $donorName covered the rest and we matched it',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Accepting this gift unlocks the full experience and keeps our community-funded scholarship going.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () {
                  AnalyticsService.capture('gift_offer_accepted', {
                    'variant': _paywallVariant,
                    'donor_name': donorName,
                  });
                  _handlePurchase('pay_it_forward', fromGift: true);
                },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Brand.mintColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Accept Gift & Activate Premium',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'Instant activation • No hidden fees • We\'ll notify the community member you supported',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            AnalyticsService.capture('gift_offer_declined', {
              'variant': _paywallVariant,
              'donor_name': donorName,
            });
            if (mounted) {
              context.go('/auth');
            }
          },
          child: const Text('No thanks, I\'ll pass for now'),
        ),
        const SizedBox(height: 8),
        Text(
          '⏰ This gift is reserved for you while you\'re here.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _FinePrint(onTermsPressed: _openTerms, onPrivacyPressed: _openPrivacy),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    required this.isRecommended,
    required this.onTap,
    required this.isLoading,
  });

  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final bool isRecommended;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isRecommended ? Brand.primaryGradient : null,
          color: isRecommended ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? Colors.transparent : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isRecommended ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRecommended ? Colors.white : Brand.mintColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: isRecommended ? Brand.mintColor : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isRecommended ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isRecommended ? Colors.white.withOpacity(0.9) : Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isRecommended ? Colors.white : Colors.black54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text, this.icon, this.compact = false});

  final String text;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.check_circle_outline,
            color: Brand.mintColor,
            size: compact ? 18 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 14 : 16,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinePrint extends StatelessWidget {
  const _FinePrint({required this.onTermsPressed, required this.onPrivacyPressed});

  final VoidCallback onTermsPressed;
  final VoidCallback onPrivacyPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Free trial available. Cancel anytime.\nNative in-app purchases on mobile.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              'By continuing you agree to our ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            GestureDetector(
              onTap: onTermsPressed,
              child: Text(
                'Terms',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
            Text(
              ' and ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            GestureDetector(
              onTap: onPrivacyPressed,
              child: Text(
                'Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
