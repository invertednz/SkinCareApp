import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';
import '../onboarding/state/onboarding_state.dart';

class Supplement {
  String id;
  String name;
  String dosage;
  String frequency;
  String? notes;
  bool enabled;
  bool am;
  bool pm;

  Supplement({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.notes,
    this.enabled = true,
    this.am = true,
    this.pm = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'notes': notes,
    'enabled': enabled,
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
    dosage: (json['dosage'] ?? '') as String,
    frequency: (json['frequency'] ?? 'Once daily') as String,
    notes: json['notes'] as String?,
    enabled: _asBool(json['enabled'], defaultValue: true),
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
  final _formKey = GlobalKey<FormState>();
  
  List<Supplement> _supplements = [];
  // UI state for mockup-aligned inline form and toggles
  final TextEditingController _formNameController = TextEditingController();
  final TextEditingController _quickAddController = TextEditingController();
  final TextEditingController _formDosageController = TextEditingController();
  String _formFrequency = 'Once daily';
  bool _formMorning = false;
  bool _formAfternoon = false;
  bool _formEvening = false;

  final Map<String, bool> _intakeToggle = {};
  final DateTime _today = DateTime.now();
  
  // Common supplements for quick selection
  final List<String> _commonSupplements = [
    'Vitamin A',
    'Vitamin C',
    'Vitamin D',
    'Vitamin E',
    'Zinc',
    'Omega-3',
    'Biotin',
    'Collagen',
    'Probiotics',
    'Evening Primrose Oil',
    'Hyaluronic Acid',
    'Niacinamide',
    'Selenium',
    'Iron',
    'B-Complex',
    'Magnesium',
    'Turmeric',
    'Green Tea Extract',
  ];

  final List<String> _frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every other day',
    'Weekly',
    'As needed',
  ];
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // Track screen view
    AnalyticsService.capture('screen_view', {
      'screen_name': 'supplements_form',
      'entry_id': widget.entryId,
    });
  }

  String _formatDate(DateTime d) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekday = weekdays[d.weekday - 1];
    final month = months[d.month - 1];
    return '$weekday, $month ${d.day}, ${d.year}';
  }

  Widget _gradientCircle(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  void _handleAddSupplementFromForm() {
    final name = _formNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a supplement name')),
      );
      return;
    }

    final supplement = Supplement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dosage: _formDosageController.text.trim(),
      frequency: _formFrequency,
      enabled: true,
      am: _formMorning,
      pm: _formEvening,
    );

    setState(() {
      _supplements.add(supplement);
      _intakeToggle[supplement.id] = false;
      _formNameController.clear();
      _formDosageController.clear();
      _formFrequency = 'Once daily';
      _formMorning = false;
      _formAfternoon = false;
      _formEvening = false;
    });
    _markChanged();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      final raw = data['supplements'];
      if (raw is List) {
        final parsed = <Supplement>[];
        for (final item in raw) {
          if (item is String) {
            parsed.add(Supplement(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: item,
              dosage: '',
              frequency: 'Once daily',
              enabled: true,
              am: true,
              pm: false,
            ));
          } else if (item is Map<String, dynamic>) {
            parsed.add(Supplement.fromJson(item));
          } else if (item is Map) {
            parsed.add(Supplement.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        setState(() {
          _supplements = parsed;
        });
      }
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  // Quick-add helpers for chips/input
  void _addByName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final exists = _supplements.any((s) => s.name.toLowerCase() == trimmed.toLowerCase());
    if (exists) return;
    setState(() {
      _supplements.add(Supplement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: trimmed,
        dosage: '',
        frequency: 'Once daily',
        enabled: true,
        am: true,
        pm: false,
      ));
      _hasChanges = true;
    });
  }

  void _toggleQuickPick(String label, bool selected) {
    if (selected) {
      _addByName(label);
    } else {
      setState(() {
        _supplements.removeWhere((s) => s.name.toLowerCase() == label.toLowerCase());
        _hasChanges = true;
      });
    }
  }

  void _addSupplement({String? name}) {
    final supplement = Supplement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name ?? '',
      dosage: '',
      frequency: 'Once daily',
    );

    setState(() {
      _supplements.add(supplement);
    });
    _markChanged();

    if (name == null) {
      // Show edit dialog for custom supplement
      _showEditSupplementDialog(supplement);
    }
  }

  void _removeSupplement(String id) {
    setState(() {
      _supplements.removeWhere((s) => s.id == id);
    });
    _markChanged();
  }

  void _showEditSupplementDialog(Supplement supplement) {
    final nameController = TextEditingController(text: supplement.name);
    final dosageController = TextEditingController(text: supplement.dosage);
    String selectedFrequency = supplement.frequency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(supplement.name.isEmpty ? 'Add Supplement' : 'Edit Supplement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Supplement Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a supplement name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g., 1000mg, 2 capsules',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: _frequencyOptions.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedFrequency = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    supplement.name = nameController.text.trim();
                    supplement.dosage = dosageController.text.trim();
                    supplement.frequency = selectedFrequency;
                  });
                  _markChanged();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSupplementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supplement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose from common supplements:'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: _commonSupplements.length,
                itemBuilder: (context, index) {
                  final supplement = _commonSupplements[index];
                  final isAlreadyAdded = _supplements.any((s) => s.name == supplement);
                  
                  return ListTile(
                    title: Text(supplement),
                    trailing: isAlreadyAdded 
                        ? const Icon(Icons.check, color: Color(0xFF6A11CB))
                        : null,
                    onTap: isAlreadyAdded ? null : () {
                      Navigator.of(context).pop();
                      _addSupplement(name: supplement);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addSupplement();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Supplement'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSupplements() async {
    // Optional validation (no form fields required in this UI variant)
    if (!((_formKey.currentState?.validate()) ?? true)) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final entryData = {
        'user_id': user.id,
        'entry_id': widget.entryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'supplements': _supplements.map((s) => s.toJson()).toList(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('supplement_entries')
          .upsert(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplements entry saved')),
        );

        // Track successful save
        AnalyticsService.capture(AnalyticsEvents.logCreateSupplements, {
          'entry_id': widget.entryId,
          AnalyticsProperties.hasPhoto: false, // Supplements entries don't have photos
          'ts': DateTime.now().toIso8601String(),
          'supplement_count': _supplements.length,
          'supplement_names': _supplements.map((s) => s.name).toList(),
        });

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );

        // Track error
        AnalyticsService.capture('log_create_error', {
          'entry_type': 'supplements',
          'entry_id': widget.entryId,
          'error': e.toString(),
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSupplementRow(Supplement s, int index) {
    const mint = Color(0xFFA8EDEA);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: index < _supplements.length - 1
            ? const Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: s.enabled,
                onChanged: (v) {
                  setState(() {
                    s.enabled = v == true;
                    _hasChanges = true;
                  });
                },
              ),
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('AM'),
                selected: s.am,
                selectedColor: mint,
                onSelected: (_) => setState(() { s.am = !s.am; _hasChanges = true; }),
              ),
              ChoiceChip(
                label: const Text('PM'),
                selected: s.pm,
                selectedColor: mint,
                onSelected: (_) => setState(() { s.pm = !s.pm; _hasChanges = true; }),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditSupplementDialog(s),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeSupplement(s.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplements', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.history, color: Colors.grey),
                onPressed: () {},
              ),
            ),
          ),
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveSupplements,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Supplements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              // Quick picks chips (match onboarding)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final opt in OnboardingValidators.allowedSupplements)
                    FilterChip(
                      label: Text(opt),
                      selected: _supplements.any((s) => s.name.toLowerCase() == opt.toLowerCase()),
                      selectedColor: const Color(0xFFA8EDEA),
                      onSelected: (sel) => _toggleQuickPick(opt, sel),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Input to add custom (match onboarding)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quickAddController,
                      decoration: const InputDecoration(hintText: 'Add a supplement'),
                      onSubmitted: (v) { _addByName(v); _quickAddController.clear(); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () { _addByName(_quickAddController.text); _quickAddController.clear(); },
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // List section (match onboarding list item: checkbox + label + AM/PM chips)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _supplements.isEmpty
                      ? Text('No supplements yet. Use the chips above or add your own.', style: TextStyle(color: Colors.grey[600]))
                      : Column(
                          children: [
                            for (int i = 0; i < _supplements.length; i++)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: i < _supplements.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))) : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _supplements[i].enabled,
                                          onChanged: (v) => setState(() { _supplements[i].enabled = v == true; _hasChanges = true; }),
                                        ),
                                        Text(_supplements[i].name),
                                      ],
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        ChoiceChip(
                                          label: const Text('AM'),
                                          selected: _supplements[i].am,
                                          selectedColor: const Color(0xFFA8EDEA),
                                          onSelected: (_) => setState(() { _supplements[i].am = !_supplements[i].am; _hasChanges = true; }),
                                        ),
                                        ChoiceChip(
                                          label: const Text('PM'),
                                          selected: _supplements[i].pm,
                                          selectedColor: const Color(0xFFA8EDEA),
                                          onSelected: (_) => setState(() { _supplements[i].pm = !_supplements[i].pm; _hasChanges = true; }),
                                        ),
                                      ],
                                    ),
                                  ],
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
    );
  }

  @override
  void dispose() {
    _formNameController.dispose();
    _quickAddController.dispose();
    _formDosageController.dispose();
    super.dispose();
  }
}
