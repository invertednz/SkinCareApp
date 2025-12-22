import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';
import '../../theme/brand.dart';

class Supplement {
  String id;
  String name;
  String description;
  String icon;
  String dosage;
  String frequency;
  String? notes;
  bool isSelected;
  bool am;
  bool pm;

  Supplement({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = '💊',
    required this.dosage,
    required this.frequency,
    this.notes,
    this.isSelected = false,
    this.am = false,
    this.pm = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'dosage': dosage,
    'frequency': frequency,
    'notes': notes,
    'enabled': isSelected,
    'am': am,
    'pm': pm,
  };

  static bool _asBool(dynamic v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == 'yes' || s == '1') return true;
      if (s == 'false' || s == 'no' || s == '0') return false;
    }
    return defaultValue;
  }

  factory Supplement.fromJson(Map<String, dynamic> json) => Supplement(
    id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: (json['name'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    dosage: (json['dosage'] ?? '') as String,
    frequency: (json['frequency'] ?? 'Once daily') as String,
    notes: json['notes'] as String?,
    isSelected: _asBool(json['enabled'], defaultValue: true),
    am: _asBool(json['am'], defaultValue: true),
    pm: _asBool(json['pm'], defaultValue: false),
  );
}

class SupplementsScreen extends StatefulWidget {
  final String? entryId;
  final Map<String, dynamic>? initialData;

  const SupplementsScreen({
    super.key,
    this.entryId,
    this.initialData,
  });

  @override
  State<SupplementsScreen> createState() => _SupplementsScreenState();
}

class _SupplementsScreenState extends State<SupplementsScreen> {
  bool _isLoading = false;
  final TextEditingController _customCtrl = TextEditingController();

  // Default supplements with descriptions and icons
  final List<Supplement> _defaultSupplements = [
    Supplement(id: 'omega3', name: 'Omega-3', description: 'Anti-inflammatory fish oils', icon: '🐟', dosage: '', frequency: 'daily'),
    Supplement(id: 'vitamin_a', name: 'Vitamin A', description: 'Supports skin cell turnover', icon: '🥕', dosage: '', frequency: 'daily'),
    Supplement(id: 'vitamin_c', name: 'Vitamin C', description: 'Antioxidant & collagen support', icon: '🍊', dosage: '', frequency: 'daily'),
    Supplement(id: 'vitamin_d', name: 'Vitamin D', description: 'Immune & skin health', icon: '☀️', dosage: '', frequency: 'daily'),
    Supplement(id: 'vitamin_e', name: 'Vitamin E', description: 'Skin protection & healing', icon: '🌿', dosage: '', frequency: 'daily'),
    Supplement(id: 'zinc', name: 'Zinc', description: 'Wound healing & acne control', icon: '⚡', dosage: '', frequency: 'daily'),
    Supplement(id: 'biotin', name: 'Biotin', description: 'Hair, skin & nail support', icon: '💅', dosage: '', frequency: 'daily'),
    Supplement(id: 'collagen', name: 'Collagen', description: 'Skin elasticity & hydration', icon: '✨', dosage: '', frequency: 'daily'),
    Supplement(id: 'probiotics', name: 'Probiotics', description: 'Gut-skin axis support', icon: '🦠', dosage: '', frequency: 'daily'),
    Supplement(id: 'evening_primrose', name: 'Evening Primrose Oil', description: 'Hormonal skin support', icon: '🌸', dosage: '', frequency: 'daily'),
    Supplement(id: 'hyaluronic', name: 'Hyaluronic Acid', description: 'Deep hydration', icon: '💧', dosage: '', frequency: 'daily'),
    Supplement(id: 'niacinamide', name: 'Niacinamide (B3)', description: 'Barrier repair & brightening', icon: '🧪', dosage: '', frequency: 'daily'),
    Supplement(id: 'b_complex', name: 'B-Complex', description: 'Energy & skin metabolism', icon: '💛', dosage: '', frequency: 'daily'),
    Supplement(id: 'magnesium', name: 'Magnesium', description: 'Stress & inflammation support', icon: '🟢', dosage: '', frequency: 'daily'),
  ];

  // Custom added supplements
  final List<Supplement> _customSupplements = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    AnalyticsService.capture('screen_view', {
      'screen_name': 'supplements_form',
      'entry_id': widget.entryId,
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      final raw = data['supplements'];
      if (raw is List) {
        for (final item in raw) {
          String name = '';
          bool am = true;
          bool pm = false;
          if (item is String) {
            name = item;
          } else if (item is Map) {
            name = item['name']?.toString() ?? '';
            am = Supplement._asBool(item['am'], defaultValue: true);
            pm = Supplement._asBool(item['pm'], defaultValue: false);
          }
          
          final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
          final found = _defaultSupplements.where((s) => s.id == id || s.name.toLowerCase() == name.toLowerCase()).firstOrNull;
          if (found != null) {
            found.isSelected = true;
            found.am = am;
            found.pm = pm;
          } else if (name.isNotEmpty) {
            _customSupplements.add(Supplement(
              id: id,
              name: name,
              description: '',
              icon: '💊',
              dosage: '',
              frequency: 'daily',
              isSelected: true,
              am: am,
              pm: pm,
            ));
          }
        }
        setState(() {});
      }
    }
  }

  void _addCustomSupplement() {
    final name = _customCtrl.text.trim();
    if (name.isEmpty) return;

    final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final allItems = [..._defaultSupplements, ..._customSupplements];
    if (!allItems.any((e) => e.id == id)) {
      setState(() {
        _customSupplements.add(Supplement(
          id: id,
          name: name,
          description: '',
          icon: '💊',
          dosage: '',
          frequency: 'daily',
          isSelected: true,
          am: true,
          pm: false,
        ));
      });
    }
    _customCtrl.clear();
  }

  Future<void> _saveSupplements() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final List<Map<String, dynamic>> supplements = [];
      for (final s in [..._defaultSupplements, ..._customSupplements]) {
        if (s.isSelected) {
          supplements.add(s.toJson());
        }
      }

      final entryData = {
        'user_id': user.id,
        'entry_id': widget.entryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'supplements': supplements,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('supplement_entries').upsert(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplements saved')),
        );
        AnalyticsService.capture(AnalyticsEvents.logCreateSupplements, {
          'entry_id': widget.entryId,
          'supplement_count': supplements.length,
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
                      'Supplements',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Brand.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select supplements you take and when you take them.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Brand.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('💊 Common Supplements'),
                    const SizedBox(height: 12),
                    ..._defaultSupplements.map((s) => _buildSupplementCard(s)),
                    ..._customSupplements.map((s) => _buildSupplementCard(s, isCustom: true)),
                    _buildAddButton(),
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
            'Supplements',
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

  Widget _buildSupplementCard(Supplement item, {bool isCustom = false}) {
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
            // Top row: icon, name+description, checkbox
            InkWell(
              onTap: () => setState(() => item.isSelected = !item.isSelected),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: Brand.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(item.icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Brand.textPrimary,
                          ),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Brand.textSecondary,
                            ),
                          ),
                        ],
                      ],
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
            // AM/PM buttons - only show if selected
            if (isSelected) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'When do you take it?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Brand.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  _buildAmPmButton(item, true, 'AM'),
                  const SizedBox(width: 8),
                  _buildAmPmButton(item, false, 'PM'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmPmButton(Supplement item, bool isAm, String label) {
    final isActive = isAm ? item.am : item.pm;
    return InkWell(
      onTap: () {
        setState(() {
          if (isAm) {
            item.am = !item.am;
          } else {
            item.pm = !item.pm;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Brand.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showAddDialog,
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
            '+ Add custom supplement',
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

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Custom Supplement'),
        content: TextField(
          controller: _customCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g., Turmeric',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) {
            _addCustomSupplement();
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
              _addCustomSupplement();
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
          onPressed: _isLoading ? null : _saveSupplements,
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
                  'Save Supplements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }
}
