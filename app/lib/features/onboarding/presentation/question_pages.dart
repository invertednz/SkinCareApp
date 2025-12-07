import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/brand.dart';
import '../../../widgets/staggered_animation.dart';

class SkinConcernsPage extends StatefulWidget {
  final Function(Map<String, double>) onConcernsSelected;

  const SkinConcernsPage({super.key, required this.onConcernsSelected});

  @override
  State<SkinConcernsPage> createState() => _SkinConcernsPageState();
}

class _SkinConcernsPageState extends State<SkinConcernsPage> {
  // Map of concern key to severity (1.0 = mild, 2.0 = moderate, 3.0 = severe)
  final Map<String, double> _selectedConcerns = {};

  final List<Map<String, dynamic>> _concerns = [
    {
      'title': 'Acne & Blemishes',
      'icon': '🌋',
      'key': 'acne',
    },
    {
      'title': 'Dryness & Dehydration',
      'icon': '💧',
      'key': 'dryness',
    },
    {
      'title': 'Fine Lines & Wrinkles',
      'icon': '👵',
      'key': 'aging',
    },
    {
      'title': 'Redness & Sensitivity',
      'icon': '🔴',
      'key': 'sensitivity',
    },
    {
      'title': 'Dark Spots & Pigmentation',
      'icon': '🌑',
      'key': 'pigmentation',
    },
    {
      'title': 'Oiliness & Pores',
      'icon': '✨',
      'key': 'oiliness',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Brand.primaryStart,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'What are your skin concerns?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Brand.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select all that apply and set severity.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Brand.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                itemCount: _concerns.length,
                itemBuilder: (context, index) {
                  final concern = _concerns[index];
                  final isSelected = _selectedConcerns.containsKey(concern['key']);
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Brand.primaryStart : Brand.borderLight,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? Brand.primaryStart.withOpacity(0.15)
                              : Brand.primaryStart.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedConcerns.remove(concern['key']);
                              } else {
                                _selectedConcerns[concern['key']] = 2.0; // Default to moderate
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Brand.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    concern['icon'],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    concern['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Brand.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Brand.primaryStart,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Brand.borderMedium, width: 2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Mild', style: TextStyle(fontSize: 12, color: Brand.textTertiary)),
                                    Text('Moderate', style: TextStyle(fontSize: 12, color: Brand.textTertiary)),
                                    Text('Severe', style: TextStyle(fontSize: 12, color: Brand.textTertiary)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: Brand.primaryStart,
                                    inactiveTrackColor: Brand.borderMedium,
                                    thumbColor: Brand.primaryStart,
                                    overlayColor: Brand.primaryStart.withOpacity(0.1),
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                                  ),
                                  child: Slider(
                                    value: _selectedConcerns[concern['key']]!,
                                    min: 1.0,
                                    max: 3.0,
                                    divisions: 2,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedConcerns[concern['key']] = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedConcerns.isEmpty
                ? null
                : () => widget.onConcernsSelected(_selectedConcerns),
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
      ),
    );
  }
}

class SkinTypePage extends StatefulWidget {
  final Function(String) onSkinTypeSelected;

  const SkinTypePage({super.key, required this.onSkinTypeSelected});

  @override
  State<SkinTypePage> createState() => _SkinTypePageState();
}

class _SkinTypePageState extends State<SkinTypePage> {
  String? _selectedType;

  final List<Map<String, dynamic>> _types = [
    {
      'title': 'Normal',
      'subtitle': 'Balanced, not too oily or dry',
      'icon': Icons.sentiment_satisfied_alt,
      'key': 'normal',
    },
    {
      'title': 'Dry',
      'subtitle': 'Tight, flaky, or rough texture',
      'icon': Icons.water_drop_outlined,
      'key': 'dry',
    },
    {
      'title': 'Oily',
      'subtitle': 'Shiny, enlarged pores, prone to breakouts',
      'icon': Icons.opacity,
      'key': 'oily',
    },
    {
      'title': 'Combination',
      'subtitle': 'Oily T-zone, dry cheeks',
      'icon': Icons.dashboard_customize_outlined,
      'key': 'combination',
    },
    {
      'title': 'Sensitive',
      'subtitle': 'Reacts easily to products or environment',
      'icon': Icons.spa_outlined,
      'key': 'sensitive',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Brand.primaryStart,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'What is your skin type?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Brand.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This helps us recommend the right products.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Brand.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final isSelected = _selectedType == type['key'];
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => setState(() => _selectedType = type['key']),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
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
                              : [
                                  BoxShadow(
                                    color: Brand.primaryStart.withOpacity(0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  )
                                ],
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
                                type['icon'],
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
                                    type['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Brand.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    type['subtitle'],
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
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedType == null
                ? null
                : () => widget.onSkinTypeSelected(_selectedType!),
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
      ),
    );
  }
}
