import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/analytics.dart';
import '../../../theme/brand.dart';
import '../../../widgets/brand_scaffold.dart';
import '../data/referral_service.dart';
import '../widgets/referral_rewards_card.dart';

/// Screen shown after user accepts the gift offer
/// This is the peak gratitude moment - perfect for viral sharing!
class ShareSuccessScreen extends StatefulWidget {
  const ShareSuccessScreen({
    super.key,
    this.donorName,
  });

  final String? donorName;

  @override
  State<ShareSuccessScreen> createState() => _ShareSuccessScreenState();
}

class _ShareSuccessScreenState extends State<ShareSuccessScreen> {
  final ReferralService _referralService = ReferralService.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeReferral();
    AnalyticsService.capture('share_success_screen_view', {
      'donor_name': widget.donorName,
    });
  }

  Future<void> _initializeReferral() async {
    // In production, get actual user ID from auth
    // For now using a placeholder
    await _referralService.initializeReferral('current_user_id');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleShare() async {
    final message = _referralService.getShareMessage(userName: widget.donorName);
    
    AnalyticsService.capture('share_button_clicked', {
      'source': 'success_screen',
      'referral_code': _referralService.referralCode,
      'donor_name': widget.donorName,
    });

    try {
      final result = await Share.share(
        message,
        subject: 'Join me on this skincare journey!',
      );

      if (result.status == ShareResultStatus.success) {
        AnalyticsService.capture('share_completed', {
          'source': 'success_screen',
          'referral_code': _referralService.referralCode,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for sharing! 🎉'),
              backgroundColor: Color(0xFF2ECC71),
            ),
          );
        }
      } else if (result.status == ShareResultStatus.dismissed) {
        AnalyticsService.capture('share_dismissed', {
          'source': 'success_screen',
        });
      }
    } catch (e) {
      AnalyticsService.capture('share_error', {
        'error': e.toString(),
      });
    }
  }

  void _handleContinue() {
    AnalyticsService.capture('share_screen_continue', {
      'shared': false,
      'donor_name': widget.donorName,
    });
    context.go('/tabs');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GradientHeader(title: 'Welcome!'),
            Expanded(
              child: OverlapCard(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Success message
                            const Icon(
                              Icons.check_circle,
                              size: 80,
                              color: Color(0xFF2ECC71),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'You\'re all set!',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.donorName != null
                                  ? 'Thanks to ${widget.donorName}\'s generosity and our matching program, you\'re now a premium member for just \$27/year!'
                                  : 'You\'re now a premium member! Welcome to the community.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.black54,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Why share section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFFFF9E6),
                                    const Color(0xFFFFF3CD),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFF39C12),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.volunteer_activism,
                                        color: Color(0xFFF39C12),
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Pay It Forward',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFE67E22),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Someone helped you get access to premium skincare support. Now it\'s your turn to share the gift!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFF856404),
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Help friends access better skincare',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Earn \$${ReferralService.rewardPerReferral.toInt()} off per referral (up to \$${ReferralService.maxRewardCap.toInt()})',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Build a supportive skincare community',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Referral rewards card
                            ListenableBuilder(
                              listenable: _referralService,
                              builder: (context, _) {
                                return ReferralRewardsCard(
                                  service: _referralService,
                                  onSharePressed: _handleShare,
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Primary share button
                            FilledButton.icon(
                              onPressed: _handleShare,
                              icon: const Icon(Icons.share),
                              label: const Text('Share Your Gift'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF2ECC71),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Secondary continue button
                            TextButton(
                              onPressed: _handleContinue,
                              child: const Text('Continue to App'),
                            ),

                            const SizedBox(height: 16),

                            // Fine print
                            Text(
                              'You can share anytime from your profile. Each successful referral earns you \$${ReferralService.rewardPerReferral.toInt()} off your next renewal (max ${ReferralService.maxReferrals} referrals).',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
