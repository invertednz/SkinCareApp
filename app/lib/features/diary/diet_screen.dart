import 'package:flutter/material.dart';
import '../onboarding/state/onboarding_state.dart';
import '../../theme/brand.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key, this.entryId, this.initialData});

  final String? entryId;
  final Map<String, dynamic>? initialData;

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _FoodItem {
  _FoodItem({required this.text, this.meal});
  String text;
  String? meal; // 'breakfast' | 'lunch' | 'dinner' | 'snack'
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
                          side: const MaterialStatePropertyAll(BorderSide(color: Color(0xFFE5E7EB))),
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
                                  Expanded(child: Text(_foods[i].text)),
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
                        ).copyWith(side: const MaterialStatePropertyAll(BorderSide(color: Color(0xFFE5E7EB)))),
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
