import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../onboarding/state/onboarding_state.dart';
import '../../theme/brand.dart';
import '../../services/gemini_service.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key, this.entryId, this.initialData});

  final String? entryId;
  final Map<String, dynamic>? initialData;

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _FoodItem {
  _FoodItem({required this.text, this.meal, this.portion});
  String text;
  String? meal; // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  String? portion;
}

class _DietScreenState extends State<DietScreen> {
  static const Color _mint = Color(0xFFA8EDEA);
  final TextEditingController _foodCtrl = TextEditingController();
  final TextEditingController _triggerCtrl = TextEditingController();
  final List<_FoodItem> _foods = [];
  final Set<String> _triggers = <String>{};
  final List<String> _customTriggers = <String>[]; // user-added triggers
  int _water = 0; // glasses 0..10
  DateTime _current = DateTime.now();
  
  // Meal photo state
  bool _isAnalyzing = false;
  String? _analysisError;

  String _formatDate(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    const weekdays = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
  String _dateLabel(DateTime d) => DateUtils.isSameDay(d, DateTime.now())
      ? 'Today'
      : ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d.weekday - 1];

  void _addFood() {
    final t = _foodCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _foods.add(_FoodItem(text: t));
      _foodCtrl.clear();
    });
  }

  /// Take or select a meal photo and analyze with Gemini AI
  Future<void> _captureAndAnalyzeMeal(ImageSource source) async {
    final picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return; // User cancelled
      
      setState(() {
        _isAnalyzing = true;
        _analysisError = null;
      });

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Analyze with Gemini
      final result = await GeminiService.instance.analyzeMealPhoto(imageBytes);
      
      if (!mounted) return;
      
      if (result.hasError) {
        setState(() {
          _isAnalyzing = false;
          _analysisError = result.error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: ${result.error}')),
        );
        return;
      }
      
      if (result.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _analysisError = 'No food items detected in the image';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No food items detected. Try a clearer photo.')),
        );
        return;
      }
      
      // Add detected foods to the list
      setState(() {
        for (final food in result.foods) {
          _foods.add(_FoodItem(
            text: food.name,
            meal: food.category ?? result.mealType,
            portion: food.portion,
          ));
        }
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${result.foods.length} food items from photo'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showMealPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📸 Scan Your Meal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo of your meal and AI will identify the foods',
                style: TextStyle(
                  fontSize: 14,
                  color: Brand.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPhotoOptionButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _captureAndAnalyzeMeal(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPhotoOptionButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _captureAndAnalyzeMeal(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: Brand.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Brand.primaryStart.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _foodCtrl.dispose();
    _triggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Date card
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _circleGradientButton(
                    icon: Icons.chevron_left,
                    onTap: () => setState(() => _current = _current.subtract(const Duration(days: 1))),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dateLabel(_current), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(_current),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  _circleGradientButton(
                    icon: Icons.chevron_right,
                    onTap: () => setState(() => _current = _current.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scan Meal Photo Card
            _card(
              child: InkWell(
                onTap: _isAnalyzing ? null : _showMealPhotoOptions,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: Brand.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isAnalyzing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Analyzing your meal...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              '📸 Scan Your Meal',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Add What You Ate
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add What You Ate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _foodCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Oatmeal with berries, Chicken salad, Latte',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addFood(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _mint,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ).copyWith(
                          side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFE5E7EB))),
                        ),
                        onPressed: _addFood,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_foods.isEmpty)
                    Text('No items yet. Add something above.', style: TextStyle(color: Colors.grey[600]))
                  else
                    ...[
                      for (int i = 0; i < _foods.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_foods[i].text, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        if (_foods[i].portion != null && _foods[i].portion!.isNotEmpty)
                                          Text(
                                            _foods[i].portion!,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Remove',
                                    onPressed: () => setState(() => _foods.removeAt(i)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final entry in const [
                                    ['breakfast', 'Breakfast'],
                                    ['lunch', 'Lunch'],
                                    ['dinner', 'Dinner'],
                                    ['snack', 'Snack'],
                                  ])
                                    ChoiceChip(
                                      label: Text(entry[1] as String),
                                      selected: _foods[i].meal == entry[0],
                                      selectedColor: _mint,
                                      onSelected: (sel) => setState(() {
                                        _foods[i].meal = sel ? entry[0] as String : null;
                                      }),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Water intake (no bubble icon)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Water Intake', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('How many glasses of water did you drink today?'),
                  Slider(
                    value: _water.toDouble(),
                    onChanged: (v) => setState(() => _water = v.round()),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: _mint,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('0'),
                      Text('2'),
                      Text('4'),
                      Text('6'),
                      Text('8'),
                      Text('10'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Food triggers (match onboarding allowedDietFlags)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Common Trigger Foods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  // Custom trigger input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _triggerCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Add a trigger food (e.g., cheese, wine, sugar)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) {
                            final t = _triggerCtrl.text.trim();
                            if (t.isEmpty) return;
                            setState(() {
                              if (!_customTriggers.any((e) => e.toLowerCase() == t.toLowerCase())) {
                                _customTriggers.add(t);
                              }
                              _triggers.add(t);
                              _triggerCtrl.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _mint,
                          foregroundColor: Colors.black87,
                        ).copyWith(side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFE5E7EB)))),
                        onPressed: () {
                          final t = _triggerCtrl.text.trim();
                          if (t.isEmpty) return;
                          setState(() {
                            if (!_customTriggers.any((e) => e.toLowerCase() == t.toLowerCase())) {
                              _customTriggers.add(t);
                            }
                            _triggers.add(t);
                            _triggerCtrl.clear();
                          });
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opt in OnboardingValidators.allowedDietFlags)
                        FilterChip(
                          label: Text(opt),
                          selected: _triggers.contains(opt),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _triggers.add(opt);
                            } else {
                              _triggers.remove(opt);
                            }
                          }),
                        ),
                      // Custom triggers as chips as well
                      for (final opt in _customTriggers)
                        FilterChip(
                          label: Text(opt),
                          selected: _triggers.contains(opt),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _triggers.add(opt);
                            } else {
                              _triggers.remove(opt);
                            }
                          }),
                          onDeleted: () {
                            setState(() {
                              _customTriggers.remove(opt);
                              _triggers.remove(opt);
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// Helpers
Widget _card({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: child,
  );
}

Widget _circleGradientButton({required IconData icon, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Brand.primaryGradient,
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );
}
