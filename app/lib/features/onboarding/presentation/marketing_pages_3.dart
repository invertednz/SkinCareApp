import 'package:flutter/material.dart';
import '../../../theme/brand.dart';
import '../../../widgets/staggered_animation.dart';

class TimelineVisualizationPage extends StatelessWidget {
  final VoidCallback onContinue;

  const TimelineVisualizationPage({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Brand.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Trial Journey',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Here\'s what happens next',
                style: TextStyle(
                  fontSize: 18,
                  color: Brand.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: StaggeredAnimation(
                  children: [
                    _buildTimelineItem(
                      icon: Icons.play_circle_outline,
                      title: 'Today',
                      subtitle: 'Start your 7-day free trial',
                      isFirst: true,
                      isActive: true,
                    ),
                    const SizedBox(height: 24),
                    _buildTimelineItem(
                      icon: Icons.notifications_active_outlined,
                      title: 'Day 5',
                      subtitle: 'Reminder: Trial ending in 2 days',
                    ),
                    const SizedBox(height: 24),
                    _buildTimelineItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Day 7',
                      subtitle: 'Subscription begins at \$9.99/month',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Brand.secondaryStart, Brand.secondaryEnd.withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Brand.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Brand.primaryEnd, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Important Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Brand.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Cancel anytime before Day 7 to avoid charges\n'
                      '• Easy cancellation in settings\n'
                      '• No hidden fees or commitments',
                      style: TextStyle(
                        fontSize: 13,
                        color: Brand.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.primaryStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: isActive ? Brand.primaryGradient : null,
            color: isActive ? null : Brand.secondaryStart,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Brand.primaryEnd : Brand.borderMedium,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Brand.primaryEnd,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Brand.textPrimary : Brand.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Brand.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class PaymentPage extends StatefulWidget {
  final Function(bool) onComplete;

  const PaymentPage({super.key, required this.onComplete});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;
  String _selectedPlan = 'monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Brand.textPrimary),
          onPressed: () => widget.onComplete(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start with 7 days free, cancel anytime',
                style: TextStyle(
                  fontSize: 18,
                  color: Brand.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _buildPlanCard(
                id: 'monthly',
                title: 'Monthly',
                price: '\$7',
                period: '/month',
                savings: null,
                isSelected: _selectedPlan == 'monthly',
              ),
              const SizedBox(height: 16),
              _buildPlanCard(
                id: 'yearly',
                title: 'Yearly',
                price: '\$50',
                period: '/year',
                savings: 'Save 40%',
                isSelected: _selectedPlan == 'yearly',
                isRecommended: true,
              ),
              const SizedBox(height: 16),
              _buildPlanCard(
                id: 'web',
                title: 'Web Only',
                price: '\$40',
                period: '/year',
                savings: 'Web Access',
                isSelected: _selectedPlan == 'web',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Brand.borderLight),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.check_circle_outline, 
                      'Free for 7 days, then ${_getPriceText()}',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.lock_outline, 'Secure payment via Apple Pay / Google Pay'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.sync, 'Cancel anytime in settings'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.primaryStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Brand.borderMedium,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start Free Trial',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 11,
                  color: Brand.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    String? savings,
    required bool isSelected,
    bool isRecommended = false,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPlan = id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? Brand.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Brand.primaryEnd.withOpacity(0.6) : Brand.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Brand.primaryStart.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Brand.borderMedium,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Brand.textPrimary,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white.withOpacity(0.25)
                                : Brand.primaryStart.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'BEST VALUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Brand.primaryEnd,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '7 days free, then $price$period',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white.withOpacity(0.9) : Brand.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (savings != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.25)
                      : Brand.secondaryStart,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  savings,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Brand.primaryEnd,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPriceText() {
    switch (_selectedPlan) {
      case 'monthly':
        return '\$7/month';
      case 'yearly':
        return '\$50/year';
      case 'web':
        return '\$40/year (web only)';
      default:
        return '\$7/month';
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Brand.primaryEnd),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Brand.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isProcessing = false);
      widget.onComplete(true);
    }
  }
}

class SpecialDiscountPage extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const SpecialDiscountPage({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Brand.backgroundLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: Brand.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Brand.backgroundLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '50%\nOFF',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Brand.primaryStart,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Wait!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Brand.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Exclusive one-time offer',
                  style: TextStyle(
                    fontSize: 20,
                    color: Brand.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Brand.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.primaryStart.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Brand.primaryStart,
                            ),
                          ),
                          Text(
                            '4.99',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Brand.primaryStart,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'per month for your first year',
                        style: TextStyle(
                          fontSize: 16,
                          color: Brand.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: Brand.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Save \$60 in your first year',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Brand.primaryStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Claim This Offer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onDecline,
                  child: Text(
                    'No thanks, continue with regular price',
                    style: TextStyle(
                      fontSize: 14,
                      color: Brand.textTertiary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '⏰ This offer expires in 5 minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Brand.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
