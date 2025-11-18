import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/brand.dart';
import '../data/referral_service.dart';

class ReferralRewardsCard extends StatelessWidget {
  const ReferralRewardsCard({
    super.key,
    required this.service,
    this.onSharePressed,
  });

  final ReferralService service;
  final VoidCallback? onSharePressed;

  @override
  Widget build(BuildContext context) {
    final earnedReward = service.earnedReward;
    final successfulReferrals = service.successfulReferrals;
    final referralCode = service.referralCode;
    final remainingReferrals = service.remainingReferrals;
    final potentialEarnings = service.potentialEarnings;
    final hasReachedCap = service.hasReachedCap;

    final progressPercent = (earnedReward / ReferralService.maxRewardCap).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2ECC71),
            const Color(0xFF27AE60),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ECC71).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral Rewards',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        hasReachedCap
                            ? 'Maximum rewards earned! 🎉'
                            : 'Share & earn up to \$${ReferralService.maxRewardCap.toInt()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main reward display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      icon: Icons.attach_money,
                      value: '\$${earnedReward.toInt()}',
                      label: 'Earned',
                      color: const Color(0xFF2ECC71),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                    _StatColumn(
                      icon: Icons.people,
                      value: '$successfulReferrals',
                      label: 'Referrals',
                      color: const Color(0xFF3498DB),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                    _StatColumn(
                      icon: Icons.trending_up,
                      value: '$remainingReferrals',
                      label: 'Remaining',
                      color: const Color(0xFFF39C12),
                    ),
                  ],
                ),
                
                if (!hasReachedCap) ...[
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress to max',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          Text(
                            '\$${earnedReward.toInt()} / \$${ReferralService.maxRewardCap.toInt()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                        ),
                      ),
                      if (potentialEarnings > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF39C12), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars, color: Color(0xFFF39C12), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$remainingReferrals more referral${remainingReferrals == 1 ? '' : 's'} to earn \$${potentialEarnings.toInt()}!',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFFE67E22),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Referral code section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your Referral Code',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        referralCode,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral code copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, color: Colors.white),
                        tooltip: 'Copy code',
                      ),
                    ],
                  ),
                ),
                
                if (onSharePressed != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: hasReachedCap ? null : onSharePressed,
                    icon: const Icon(Icons.share),
                    label: Text(hasReachedCap ? 'Max Rewards Reached' : 'Share Your Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
