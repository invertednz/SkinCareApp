import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../theme/brand.dart';
import '../../widgets/brand_scaffold.dart';
import '../profile/profile_service.dart';
import '../../services/analytics.dart';
import '../../services/analytics_events.dart';
import 'data/iap_service.dart';
import 'data/subscription_repository.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _annual = true;
  bool _isLoading = false;
  bool _iapInitialized = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.capture(AnalyticsEvents.paywallView);
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    if (!kIsWeb) {
      final success = await IAPService.instance.initialize();
      setState(() {
        _iapInitialized = success;
      });
    }
  }

  Future<void> _handlePurchase() async {
    if (kIsWeb) {
      // On web, simulate success and navigate to main app
      AnalyticsService.capture(AnalyticsEvents.startTrial, {
        AnalyticsProperties.plan: _annual ? 'annual' : 'monthly',
        'platform': 'web',
      });
      ProfileService.instance.setSubscriptionForDebug(true);
      if (mounted) {
        context.go('/tabs');
      }
      return;
    }

    if (kDebugMode) {
      // Debug mode - simulate purchase
      AnalyticsService.capture(AnalyticsEvents.startTrial, {
        AnalyticsProperties.plan: _annual ? 'annual' : 'monthly',
      });
      ProfileService.instance.setSubscriptionForDebug(true);
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
      final productId = _annual 
          ? IAPService.annualProductId 
          : IAPService.monthlyProductId;

      AnalyticsService.capture('purchase_initiated', {
        'product_id': productId,
        'plan': _annual ? 'annual' : 'monthly',
      });

      final success = await IAPService.instance.purchaseProduct(productId);
      
      if (!success) {
        _showErrorSnackBar('Failed to start purchase. Please try again.');
      }
      // Success/failure will be handled by the purchase stream in IAPService
      
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
      AnalyticsService.capture('purchase_failure', {
        'error': e.toString(),
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

  void _showWebMockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('Purchases are not yet available on web. Please use the mobile app to subscribe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
    } catch (e) {
      _showErrorSnackBar('Failed to restore purchases. Please try again.');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _openTerms() async {
    const url = 'https://your-app.com/terms'; // TODO: Replace with actual terms URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openPrivacy() async {
    const url = 'https://your-app.com/privacy'; // TODO: Replace with actual privacy URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GradientHeader(title: 'Upgrade'),
            Expanded(
              child: OverlapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Unlock your personalized skincare',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get AI insights, daily reminders, photo analysis, and chat support. Cancel anytime.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _PlanSwitcher(
                      annual: _annual,
                      onChanged: (v) {
                        setState(() => _annual = v);
                        AnalyticsService.capture(AnalyticsEvents.paywallSelectPlan, {
                          AnalyticsProperties.plan: v ? 'annual' : 'monthly',
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(annual: _annual, iapInitialized: _iapInitialized),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : _handlePurchase,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_annual ? 'Start annual trial' : 'Start monthly trial'),
                    ),
                    const SizedBox(height: 8),
                    if (kIsWeb)
                      Text(
                        'Purchases coming soon on web. Use mobile app to subscribe.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (!kIsWeb && !kDebugMode)
                      TextButton(
                        onPressed: _handleRestorePurchases,
                        child: const Text('Restore Purchases'),
                      ),
                    const Spacer(),
                    _FinePrint(onTermsPressed: _openTerms, onPrivacyPressed: _openPrivacy),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanSwitcher extends StatelessWidget {
  const _PlanSwitcher({required this.annual, required this.onChanged});
  final bool annual;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: annual ? null : () => onChanged(true),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: annual ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
            ),
            child: const Text('Annual'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: annual ? () => onChanged(false) : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: annual ? Colors.grey.shade300 : Theme.of(context).colorScheme.primary),
            ),
            child: const Text('Monthly'),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.annual, required this.iapInitialized});
  final bool annual;
  final bool iapInitialized;

  @override
  Widget build(BuildContext context) {
    String price;
    String monthlyEquivalent = '';
    
    if (kIsWeb || !iapInitialized) {
      // Fallback prices for web or when IAP not initialized
      price = annual ? '\$47.00 / year' : '\$7.99 / month';
      if (annual) {
        monthlyEquivalent = '\$3.92/month';
      }
    } else {
      // Get real prices from IAP service
      if (annual) {
        final annualProduct = IAPService.instance.annualProduct;
        price = annualProduct?.price ?? '\$47.00 / year';
        monthlyEquivalent = IAPService.instance.getAnnualMonthlyEquivalent();
      } else {
        final monthlyProduct = IAPService.instance.monthlyProduct;
        price = monthlyProduct?.price ?? '\$7.99 / month';
      }
    }
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(price.replaceAll('\u0000', ''), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              if (annual && monthlyEquivalent.isNotEmpty)
                Text(
                  monthlyEquivalent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (annual) const SizedBox(height: 4),
              if (annual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: Brand.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Best value',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureItem(text: 'AI insights & summaries'),
            _FeatureItem(text: 'Daily reminders & routines'),
            _FeatureItem(text: 'Photo tracking & analysis'),
            _FeatureItem(text: 'Chat assistant access'),
          ],
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(text),
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
          'Monthly and annual plans. Free trial available. Cancel anytime.\nNative in-app purchases on mobile. Web checkout coming soon.',
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
            Text(
              '.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
