import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';
import '../../theme/brand.dart';

class RoutineItem {
  String id;
  String name;
  String category;
  String freq;
  String icon;
  bool isSelected;
  String? notes;

  RoutineItem({
    required this.id,
    required this.name,
    required this.category,
    this.freq = 'daily',
    this.icon = '✨',
    this.isSelected = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'freq': freq,
    'notes': notes,
  };

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    freq: (json['freq'] as String?) ?? 'daily',
    isSelected: true,
    notes: json['notes'] as String?,
  );
}

class RoutineScreen extends StatefulWidget {
  final String? entryId;
  final Map<String, dynamic>? initialData;

  const RoutineScreen({
    super.key,
    this.entryId,
    this.initialData,
  });

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  bool _isLoading = false;
  bool _noRoutineYet = false;
  final TextEditingController _morningAddCtrl = TextEditingController();
  final TextEditingController _eveningAddCtrl = TextEditingController();

  // Morning routine items with icons
  final List<RoutineItem> _morningItems = [
    RoutineItem(id: 'cleanser', name: 'Cleanser', category: 'Morning', icon: '🧼'),
    RoutineItem(id: 'toner', name: 'Toner', category: 'Morning', icon: '💧'),
    RoutineItem(id: 'serum', name: 'Serum', category: 'Morning', icon: '✨'),
    RoutineItem(id: 'moisturizer', name: 'Moisturizer', category: 'Morning', icon: '🧴'),
    RoutineItem(id: 'sunscreen', name: 'Sunscreen', category: 'Morning', icon: '☀️'),
    RoutineItem(id: 'eye_cream', name: 'Eye Cream', category: 'Morning', icon: '👁️'),
  ];

  // Evening routine items with icons
  final List<RoutineItem> _eveningItems = [
    RoutineItem(id: 'makeup_remover', name: 'Makeup Remover', category: 'Evening', icon: '🧹'),
    RoutineItem(id: 'cleanser_pm', name: 'Cleanser', category: 'Evening', icon: '🧼'),
    RoutineItem(id: 'exfoliant', name: 'Exfoliant', category: 'Evening', icon: '🌟'),
    RoutineItem(id: 'actives', name: 'Actives (Retinol, etc.)', category: 'Evening', icon: '💊'),
    RoutineItem(id: 'moisturizer_pm', name: 'Moisturizer', category: 'Evening', icon: '💧'),
    RoutineItem(id: 'face_oil', name: 'Face Oil', category: 'Evening', icon: '🫒'),
    RoutineItem(id: 'night_mask', name: 'Night Mask', category: 'Evening', icon: '🌙'),
  ];

  // Custom added items
  final List<RoutineItem> _customMorning = [];
  final List<RoutineItem> _customEvening = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    AnalyticsService.capture('screen_view', {
      'screen_name': 'routine_form',
      'entry_id': widget.entryId,
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      final routineData = data['routine_items'] as List? ?? [];
      for (final item in routineData) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String? ?? '';
          final category = item['category'] as String? ?? '';
          final isMorning = category.toLowerCase().contains('morning');
          final freq = item['freq'] as String? ?? 'daily';
          
          final defaultList = isMorning ? _morningItems : _eveningItems;
          final found = defaultList.where((o) => o.id == id).firstOrNull;
          if (found != null) {
            found.isSelected = true;
            found.freq = freq;
          } else {
            final customList = isMorning ? _customMorning : _customEvening;
            customList.add(RoutineItem(
              id: id,
              name: item['name'] as String? ?? id,
              category: category,
              icon: '✨',
              isSelected: true,
              freq: freq,
            ));
          }
        }
      }
      _noRoutineYet = data['no_routine'] as bool? ?? false;
      setState(() {});
    }
  }

  void _addCustomItem(String section) {
    final ctrl = section == 'morning' ? _morningAddCtrl : _eveningAddCtrl;
    final list = section == 'morning' ? _customMorning : _customEvening;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;

    final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    if (!list.any((e) => e.id == id)) {
      setState(() {
        list.add(RoutineItem(
          id: id,
          name: name,
          category: section == 'morning' ? 'Morning' : 'Evening',
          icon: '✨',
          isSelected: true,
        ));
      });
    }
    ctrl.clear();
  }

  Future<void> _saveRoutine() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final List<Map<String, dynamic>> routineItems = [];

      // Collect selected morning items
      for (final item in [..._morningItems, ..._customMorning]) {
        if (item.isSelected) {
          routineItems.add(item.toJson());
        }
      }

      // Collect selected evening items
      for (final item in [..._eveningItems, ..._customEvening]) {
        if (item.isSelected) {
          routineItems.add(item.toJson());
        }
      }

      final entryData = {
        'user_id': user.id,
        'entry_id': widget.entryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'routine_items': routineItems,
        'no_routine': _noRoutineYet,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('routine_entries').upsert(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine saved')),
        );
        AnalyticsService.capture(AnalyticsEvents.logCreateRoutine, {
          'entry_id': widget.entryId,
          'total_items': routineItems.length,
        });
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current routine',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Brand.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us what products you currently use. Select frequency for each.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Brand.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Morning section
                    _buildSectionHeader('☀️ Morning'),
                    const SizedBox(height: 12),
                    ..._morningItems.map((item) => _buildRoutineCard(item)),
                    ..._customMorning.map((item) => _buildRoutineCard(item, isCustom: true)),
                    _buildAddButton('morning'),
                    const SizedBox(height: 24),

                    // Evening section
                    _buildSectionHeader('🌙 Evening'),
                    const SizedBox(height: 12),
                    ..._eveningItems.map((item) => _buildRoutineCard(item)),
                    ..._customEvening.map((item) => _buildRoutineCard(item, isCustom: true)),
                    _buildAddButton('evening'),
                    const SizedBox(height: 20),

                    // No routine checkbox
                    InkWell(
                      onTap: () => setState(() => _noRoutineYet = !_noRoutineYet),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _noRoutineYet ? Brand.primaryStart : Brand.borderMedium,
                                  width: 2,
                                ),
                                gradient: _noRoutineYet ? Brand.primaryGradient : null,
                              ),
                              child: _noRoutineYet
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "I don't have a routine yet",
                              style: TextStyle(
                                fontSize: 15,
                                color: Brand.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Brand.primaryStart.withOpacity(0.12),
            Brand.primaryEnd.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/tabs');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Brand.textPrimary),
            ),
          ),
          Text(
            'Routine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Brand.textPrimary,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Brand.textPrimary,
      ),
    );
  }

  Widget _buildRoutineCard(RoutineItem item, {bool isCustom = false}) {
    final isSelected = item.isSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Brand.primaryStart.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Brand.primaryStart : Brand.borderLight,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Brand.primaryStart.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon, name, checkbox
            InkWell(
              onTap: () => setState(() => item.isSelected = !item.isSelected),
              child: Row(
                children: [
                  Text(item.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Brand.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Brand.borderLight,
                        width: 2,
                      ),
                      gradient: isSelected ? Brand.primaryGradient : null,
                      color: isSelected ? null : Colors.white,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
            // Frequency buttons - only show if selected
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Frequency:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Brand.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFreqButton(item, 'daily', 'Daily'),
                  const SizedBox(width: 8),
                  _buildFreqButton(item, 'weekly', 'Weekly'),
                  const SizedBox(width: 8),
                  _buildFreqButton(item, 'as-needed', 'As needed'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFreqButton(RoutineItem item, String freq, String label) {
    final isActive = item.freq == freq;
    return InkWell(
      onTap: () => setState(() => item.freq = freq),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? Brand.primaryGradient : null,
          color: isActive ? null : Brand.cardBackgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.transparent : Brand.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Brand.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(String section) {
    return InkWell(
      onTap: () => _showAddDialog(section),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Brand.cardBackgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Brand.borderLight, width: 2),
        ),
        child: Center(
          child: Text(
            '+ Add ${section == 'morning' ? 'morning' : 'evening'} step',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Brand.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(String section) {
    final ctrl = section == 'morning' ? _morningAddCtrl : _eveningAddCtrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add ${section == 'morning' ? 'Morning' : 'Evening'} Step'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g., Vitamin C serum',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) {
            _addCustomItem(section);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addCustomItem(section);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Brand.primaryStart,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Brand.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveRoutine,
          style: ElevatedButton.styleFrom(
            backgroundColor: Brand.primaryStart,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Save Routine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _morningAddCtrl.dispose();
    _eveningAddCtrl.dispose();
    super.dispose();
  }
}
