import 'package:flutter/material.dart';
import '../../../theme/brand.dart';

class AppFeaturesCarouselPage extends StatefulWidget {
  final VoidCallback onContinue;

  const AppFeaturesCarouselPage({super.key, required this.onContinue});

  @override
  State<AppFeaturesCarouselPage> createState() => _AppFeaturesCarouselPageState();
}

class _AppFeaturesCarouselPageState extends State<AppFeaturesCarouselPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.edit_calendar_outlined,
      'title': 'Daily Diary',
      'description': 'Track your skin journey with detailed daily entries',
    },
    {
      'icon': Icons.photo_library_outlined,
      'title': 'Photo Timeline',
      'description': 'Visual progress tracking to see your transformation',
    },
    {
      'icon': Icons.insights_outlined,
      'title': 'AI Insights',
      'description': 'Smart analysis of your skin patterns and triggers',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'title': 'AI Assistant',
      'description': 'Personalized recommendations and support',
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Smart Reminders',
      'description': 'Never miss your routine with gentle notifications',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: Brand.primaryGradient,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Brand.primaryStart.withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            feature['icon'],
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          feature['title'],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Brand.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feature['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Brand.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _features.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: _currentPage == index ? Brand.primaryGradient : null,
                    color: _currentPage == index ? null : Brand.borderMedium,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onContinue,
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
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTimingPage extends StatefulWidget {
  final Function(String) onTimingSelected;

  const NotificationTimingPage({super.key, required this.onTimingSelected});

  @override
  State<NotificationTimingPage> createState() => _NotificationTimingPageState();
}

class _NotificationTimingPageState extends State<NotificationTimingPage> {
  String? _selectedTime;

  final List<Map<String, String>> _times = [
    {'time': 'Morning', 'subtitle': '7:00 AM - 10:00 AM', 'icon': '🌅'},
    {'time': 'Midday', 'subtitle': '11:00 AM - 2:00 PM', 'icon': '☀️'},
    {'time': 'Afternoon', 'subtitle': '3:00 PM - 6:00 PM', 'icon': '🌤️'},
    {'time': 'Evening', 'subtitle': '7:00 PM - 10:00 PM', 'icon': '🌙'},
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
                'Daily Reminder',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'When would you like your daily skin check-in?',
                style: TextStyle(
                  fontSize: 18,
                  color: Brand.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: _times.length,
                  itemBuilder: (context, index) {
                    final timeSlot = _times[index];
                    final isSelected = _selectedTime == timeSlot['time'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => setState(() => _selectedTime = timeSlot['time']),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: isSelected ? Brand.primaryGradient : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                                      ? Colors.white.withOpacity(0.25)
                                      : Brand.secondaryStart,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    timeSlot['icon']!,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeSlot['time']!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Brand.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeSlot['subtitle']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected 
                                            ? Colors.white.withOpacity(0.9)
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
                  onPressed: _selectedTime == null
                      ? null
                      : () => widget.onTimingSelected(_selectedTime!),
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

class ThankYouPage extends StatelessWidget {
  final VoidCallback onReview;
  final VoidCallback onContinue;

  const ThankYouPage({
    super.key,
    required this.onReview,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: Brand.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Brand.primaryStart.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                'Thank You!',
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
                'Congratulations on choosing to help your skin',
                style: TextStyle(
                  fontSize: 18,
                  color: Brand.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
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
                      'You\'re part of our community',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Brand.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('50K+', 'Users'),
                        _buildDivider(),
                        _buildStat('94%', 'Success'),
                        _buildDivider(),
                        _buildStat('4.8★', 'Rating'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Love SkinCare? Share your experience!',
                style: TextStyle(
                  fontSize: 14,
                  color: Brand.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Brand.primaryStart,
                    side: BorderSide(color: Brand.primaryStart, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline),
                      SizedBox(width: 8),
                      Text(
                        'Review on App Store',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    'Start Free Trial',
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

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Brand.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Brand.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Brand.borderLight,
    );
  }
}

class FreeTrialOfferPage extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  const FreeTrialOfferPage({
    super.key,
    required this.onAccept,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: Brand.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✨ SPECIAL OFFER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Brand.textTertiary),
                    onPressed: onSkip,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '7 Days Free',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Then \$9.99/month',
                style: TextStyle(
                  fontSize: 20,
                  color: Brand.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
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
                    _buildFeature('Unlimited photo tracking'),
                    _buildFeature('AI-powered insights'),
                    _buildFeature('Personalized recommendations'),
                    _buildFeature('Progress analytics'),
                    _buildFeature('Priority support'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Brand.secondaryStart.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: Brand.primaryEnd, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We\'ll notify you 2 days before your trial ends',
                        style: TextStyle(
                          fontSize: 13,
                          color: Brand.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
                    'Start Free Trial',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cancel anytime • No commitment',
                style: TextStyle(
                  fontSize: 13,
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

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: Brand.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Brand.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
