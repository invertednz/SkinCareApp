import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';

class Supplement {
  String id;
  String name;
  String dosage;
  String frequency;
  String? notes;

  Supplement({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'notes': notes,
  };

  factory Supplement.fromJson(Map<String, dynamic> json) => Supplement(
    id: json['id'] as String,
    name: json['name'] as String,
    dosage: json['dosage'] as String,
    frequency: json['frequency'] as String,
    notes: json['notes'] as String?,
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
      setState(() {
        final supplementsData = data['supplements'] as List? ?? [];
        _supplements = supplementsData
            .map((s) => Supplement.fromJson(s as Map<String, dynamic>))
            .toList();
      });
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
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
    if (!_formKey.currentState!.validate()) return;

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

  Widget _buildSupplementCard(Supplement supplement) {
    return Card(
      child: ListTile(
        title: Text(
          supplement.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplement.dosage.isNotEmpty)
              Text('Dosage: ${supplement.dosage}'),
            Text('Frequency: ${supplement.frequency}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditSupplementDialog(supplement),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeSupplement(supplement.id),
            ),
          ],
        ),
        isThreeLine: false,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Intro
            Text(
              'Track Your Supplements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Log your supplement intake to monitor their effects on your skin health.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Today's Date Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_today),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    _gradientCircle(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Supplements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Current Supplements', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _showAddSupplementDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add New'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_supplements.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.medication_outlined, color: Colors.grey[400]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No supplements added yet. Tap "Add New" to get started.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _supplements.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      _gradientCircle(Icons.medication_outlined),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(
                                            '${s.dosage.isNotEmpty ? '${s.dosage}, ' : ''}${s.frequency}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _intakeToggle[s.id] ?? false,
                                    onChanged: (v) => setState(() => _intakeToggle[s.id] = v),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Add New Supplement Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Supplement', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _formNameController,
                      decoration: const InputDecoration(
                        labelText: 'Supplement Name',
                        hintText: 'e.g., Vitamin D, Collagen, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _formDosageController,
                            decoration: const InputDecoration(
                              labelText: 'Dosage',
                              hintText: 'e.g., 500mg',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _formFrequency,
                            items: _frequencyOptions
                                .map((f) => DropdownMenuItem<String>(value: f, child: Text(f)))
                                .toList(),
                            onChanged: (v) => setState(() => _formFrequency = v ?? _formFrequency),
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Time of Day', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Checkbox(
                          value: _formMorning,
                          onChanged: (v) => setState(() => _formMorning = v ?? false),
                        ),
                        const Text('Morning'),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: _formAfternoon,
                          onChanged: (v) => setState(() => _formAfternoon = v ?? false),
                        ),
                        const Text('Afternoon'),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: _formEvening,
                          onChanged: (v) => setState(() => _formEvening = v ?? false),
                        ),
                        const Text('Evening'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleAddSupplementFromForm,
                        child: const Text('Add Supplement'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Supplement History
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Supplement History', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Last Week', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Added Biotin, Removed Fish Oil', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
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
    );
  }

  @override
  void dispose() {
    _formNameController.dispose();
    _formDosageController.dispose();
    super.dispose();
  }
}
