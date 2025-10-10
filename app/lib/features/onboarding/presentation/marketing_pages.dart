import 'package:flutter/material.dart';
import '../../../theme/brand.dart';

/// Enhanced onboarding marketing pages matching Dusty Rose & Charcoal design
class WelcomePage extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomePage({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: Brand.primaryGradient,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Welcome to SkinCare',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your personalized journey to healthier,\nmore radiant skin starts here',
                style: TextStyle(
                  fontSize: 18,
                  color: Brand.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Social proof cards
              _buildProofCard(
                icon: Icons.psychology_outlined,
                title: '94% Success Rate',
                subtitle: 'Users report improved skin within 30 days',
              ),
              const SizedBox(height: 16),
              _buildProofCard(
                icon: Icons.science_outlined,
                title: 'Evidence-Based',
                subtitle: 'Backed by dermatological research',
              ),
              const SizedBox(height: 16),
              _buildProofCard(
                icon: Icons.people_outline,
                title: '50,000+ Users',
                subtitle: 'Join our thriving skin wellness community',
              ),
              const Spacer(),
              // Continue button
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
                    'Get Started',
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

  Widget _buildProofCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.borderLight),
        boxShadow: [
          BoxShadow(
            color: Brand.primaryStart.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Brand.secondaryStart,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Brand.primaryEnd, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Brand.textPrimary,
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
        ],
      ),
    );
  }
}

class GoalSelectionPage extends StatefulWidget {
  final Function(String) onGoalSelected;

  const GoalSelectionPage({super.key, required this.onGoalSelected});

  @override
  State<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage> {
  String? _selectedGoal;

  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Clear Acne & Breakouts',
      'subtitle': 'Refined treatments for smooth, confident skin',
      'icon': Icons.face_outlined,
    },
    {
      'title': 'Calm Sensitive Skin',
      'subtitle': 'Gentle sophistication for delicate complexions',
      'icon': Icons.spa_outlined,
    },
    {
      'title': 'Even Skin Tone',
      'subtitle': 'Luminous balance for porcelain-perfect skin',
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'title': 'Anti-Aging & Firmness',
      'subtitle': 'Graceful aging with modern, elegant science',
      'icon': Icons.auto_awesome_outlined,
    },
    {
      'title': 'Overall Skin Health',
      'subtitle': 'Sophisticated wellness for enduring beauty',
      'icon': Icons.favorite_border,
    },
  ];

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
                'What\'s Your Main Goal?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Elegant, personalized skincare for your unique journey.',
                style: TextStyle(
                  fontSize: 18,
                  color: Brand.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final isSelected = _selectedGoal == goal['title'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => setState(() => _selectedGoal = goal['title']),
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: isSelected ? Brand.primaryGradient : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected 
                                  ? Brand.primaryEnd.withOpacity(0.6) 
                                  : Brand.borderLight,
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
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Colors.white.withOpacity(0.35)
                                      : Brand.secondaryStart,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  goal['icon'],
                                  color: isSelected ? Colors.white : Brand.primaryEnd,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal['title'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Brand.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      goal['subtitle'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected 
                                            ? Colors.white.withOpacity(0.95)
                                            : Brand.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedGoal == null
                      ? null
                      : () => widget.onGoalSelected(_selectedGoal!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Brand.primaryStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Brand.borderMedium,
                  ),
                  child: const Text(
                    'Continue',
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
}

class ResultsPage extends StatelessWidget {
  final VoidCallback onContinue;

  const ResultsPage({super.key, required this.onContinue});

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: Brand.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Here\'s what you can expect',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '87%',
                      'Reduced breakouts',
                      'Our users report dramatically improved skin clarity after just 2 weeks',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      '92%',
                      'Improved texture',
                      'Smoother, more radiant skin through consistent tracking',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Before/After Comparison
              Text(
                'See the real difference tracking makes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Brand.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Without Tracking Card
              _buildComparisonCard(
                title: 'Without Tracking',
                isPositive: false,
                items: [
                  'Guessing which products work for you',
                  'Repeating the same skincare mistakes',
                  'Missing patterns in flare-ups',
                  'Wasting money on ineffective products',
                  'Slow to see what triggers breakouts',
                ],
              ),
              const SizedBox(height: 16),
              
              // With SkinCare Card
              _buildComparisonCard(
                title: 'With SkinCare',
                isPositive: true,
                items: [
                  'Know exactly what works for your skin',
                  'Learn from your patterns and progress',
                  'Identify triggers before they cause flare-ups',
                  'Save money with data-driven decisions',
                  'Clear skin through personalized insights',
                ],
              ),
              const SizedBox(height: 32),
              
              // Social Proof Badge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Brand.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Brand.primaryStart.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: Brand.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Over 50,000 users ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Brand.textPrimary,
                        ),
                      ),
                      const TextSpan(text: 'report achieving '),
                      TextSpan(
                        text: 'clearer, healthier skin ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Brand.primaryStart,
                        ),
                      ),
                      const TextSpan(text: 'within the first 30 days'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // CTA
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
                    'Continue',
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

  Widget _buildStatCard(String value, String label, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Brand.primaryStart.withOpacity(0.1),
            Brand.primaryEnd.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Brand.primaryStart.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Brand.primaryStart,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Brand.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Brand.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required bool isPositive,
    required List<String> items,
  }) {
    final bgColor = isPositive 
        ? Brand.primaryStart.withOpacity(0.1)
        : Colors.red.shade50;
    final borderColor = isPositive 
        ? Brand.primaryStart.withOpacity(0.3)
        : Colors.red.shade200;
    final iconColor = isPositive ? Brand.primaryStart : Colors.red.shade400;
    final textColor = isPositive ? Brand.textPrimary : Colors.red.shade900;
    final icon = isPositive ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPositive 
                      ? Brand.primaryStart.withOpacity(0.2)
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPositive ? Icons.auto_awesome : Icons.close,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Items
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
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

class ProgressGraphPage extends StatelessWidget {
  final VoidCallback onContinue;

  const ProgressGraphPage({super.key, required this.onContinue});

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
                'Your Skin Journey',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Patience and consistency lead to lasting results',
                style: TextStyle(
                  fontSize: 18,
                  color: Brand.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Brand.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.primaryStart.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Expected Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Brand.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: CustomPaint(
                          painter: _ProgressGraphPainter(),
                          child: Container(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMilestone('Week 1-2', 'Adjustment period'),
                      const SizedBox(height: 12),
                      _buildMilestone('Week 3-4', 'First improvements'),
                      const SizedBox(height: 12),
                      _buildMilestone('Week 8+', 'Significant results'),
                    ],
                  ),
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
                    'Continue',
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

  Widget _buildMilestone(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Brand.primaryStart,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Brand.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Brand.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Brand.primaryStart, Brand.primaryEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Simulate slow start then ramp up
    path.moveTo(0, size.height * 0.9);
    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.85,
      size.width * 0.4, size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.6, size.height * 0.3,
      size.width, size.height * 0.1,
    );

    canvas.drawPath(path, paint);

    // Fill area under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Brand.primaryStart.withOpacity(0.2),
          Brand.primaryEnd.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
