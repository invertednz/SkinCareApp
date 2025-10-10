import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';

class RoutineItem {
  String id;
  String name;
  String category;
  String freq;
  String? notes;

  RoutineItem({
    required this.id,
    required this.name,
    required this.category,
    this.freq = 'daily',
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
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  List<RoutineItem> _routineItems = [];
  // New: AM/PM lists to mirror onboarding routine UI
  static const List<String> _freqOptions = ['daily', 'weekly', 'as-needed'];
  late List<Map<String, dynamic>> _am; // {key,label,checked,freq}
  late List<Map<String, dynamic>> _pm; // {key,label,checked,freq}
  final _amCtrl = TextEditingController();
  final _pmCtrl = TextEditingController();
  
  // Default routine items organized by category
  final Map<String, List<String>> _defaultRoutineItems = {
    'Morning Cleansing': [
      'Face wash',
      'Toner',
      'Vitamin C serum',
      'Moisturizer',
      'Sunscreen',
    ],
    'Evening Cleansing': [
      'Makeup remover',
      'Face wash',
      'Exfoliant',
      'Treatment serum',
      'Night moisturizer',
      'Face oil',
    ],
    'Weekly Treatments': [
      'Face mask',
      'Deep cleansing',
      'Exfoliation',
      'Professional treatment',
    ],
    'Body Care': [
      'Body wash',
      'Body moisturizer',
      'Body sunscreen',
    ],
  };
  
  bool _isLoading = false;
  bool _hasChanges = false;
  // UI state for mockup tabs and reminders
  int _currentTabIndex = 0; // kept for potential future use
  bool _remindersEnabled = false; // retained but not shown in UI now
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _am = [];
    _pm = [];
    _loadInitialData();
    
    // Track screen view
    AnalyticsService.capture('screen_view', {
      'screen_name': 'routine_form',
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

  Widget _gradientCircle({required Widget child, double size = 36}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        child: child,
      ),
    );
  }

  bool _isMorningCategory(String category) => category.toLowerCase().contains('morning');
  bool _isEveningCategory(String category) => category.toLowerCase().contains('evening');

  List<RoutineItem> _itemsForCurrentTab() {
    final isMorning = _currentTabIndex == 0;
    final items = _routineItems.where((item) {
      if (isMorning) return _isMorningCategory(item.category);
      return _isEveningCategory(item.category);
    }).toList();
    return items;
  }

  String _freqLabel(String value) {
    switch (value) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'as-needed':
        return 'As needed';
    }
    return value;
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) {
      setState(() => _reminderTime = picked);
      _markChanged();
    }
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      setState(() {
        final routineData = data['routine_items'] as List? ?? [];
        _routineItems = routineData
            .map((item) => RoutineItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _notesController.text = data['notes'] as String? ?? '';
        _populateAmPmFromRoutineItems();
      });
    } else {
      // Initialize with default routine items
      _initializeDefaultRoutine();
    }
  }

  void _initializeDefaultRoutine() {
    final items = <RoutineItem>[];
    
    _defaultRoutineItems.forEach((category, itemNames) {
      for (final name in itemNames) {
        items.add(RoutineItem(
          id: '${category}_$name'.replaceAll(' ', '_').toLowerCase(),
          name: name,
          category: category,
        ));
      }
    });
    
    setState(() {
      _routineItems = items;
      _populateAmPmFromRoutineItems();
    });
  }

  void _populateAmPmFromRoutineItems() {
    // Convert existing RoutineItem list into AM/PM sections used by onboarding UI
    List<Map<String, dynamic>> am = [];
    List<Map<String, dynamic>> pm = [];
    for (final item in _routineItems) {
      final map = {
        'key': item.id,
        'label': item.name,
        'checked': true,
        'freq': item.freq,
      };
      if (_isMorningCategory(item.category)) {
        am.add(Map<String, dynamic>.from(map));
      } else if (_isEveningCategory(item.category)) {
        pm.add(Map<String, dynamic>.from(map));
      } else {
        // Default to AM if category is unrecognized
        am.add(Map<String, dynamic>.from(map));
      }
    }
    _am = am;
    _pm = pm;
  }

  Map<String, dynamic> _makeItem(String key, String label, {bool checked = true, String freq = 'daily'}) =>
      {'key': key, 'label': label, 'checked': checked, 'freq': freq};

  void _emitAmPmChanged() {
    _markChanged();
  }

  void _addTo(String section) {
    final ctrl = section == 'am' ? _amCtrl : _pmCtrl;
    final list = section == 'am' ? _am : _pm;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    if (!list.any((e) => (e['key'] as String).toLowerCase() == key)) {
      setState(() {
        list.add(_makeItem(key, name, checked: true, freq: 'daily'));
      });
      _emitAmPmChanged();
    }
    ctrl.clear();
  }

  Widget _buildSection(String title, String section, List<Map<String, dynamic>> list, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var index = 0; index < list.length; index++)
              Builder(
                builder: (context) {
                  final item = list[index];
                  return Container(
                    key: ValueKey('$section-${item['key']}-$index'),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(item['label']?.toString() ?? item['key'].toString())),
                        SizedBox(
                          height: 36,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final f in _freqOptions) ...[
                                  ChoiceChip(
                                    label: Text(_freqLabel(f)),
                                    selected: item['freq'] == f,
                                    selectedColor: const Color(0xFFA8EDEA),
                                    onSelected: (_) {
                                      setState(() => item['freq'] = f);
                                      _emitAmPmChanged();
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      list.removeAt(index);
                                    });
                                    _emitAmPmChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: section == 'am' ? 'Add morning step' : 'Add evening step',
                ),
                onSubmitted: (_) => _addTo(section),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => _addTo(section), child: const Text('Add')),
          ],
        ),
      ],
    );
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _setItemFreq(String id, String freq) {
    setState(() {
      final index = _routineItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _routineItems[index].freq = freq;
      }
    });
    _markChanged();
  }

  void _addCustomRoutineItem([String? defaultCategory]) {
    final nameController = TextEditingController();
    String selectedCategory = defaultCategory ?? _defaultRoutineItems.keys.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Routine Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Routine Item Name',
                  hintText: 'e.g., "Retinol serum"',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a routine item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _defaultRoutineItems.keys.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final newItem = RoutineItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    category: selectedCategory,
                  );
                  
                  setState(() {
                    _routineItems.add(newItem);
                  });
                  _markChanged();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeRoutineItem(String id) {
    setState(() {
      _routineItems.removeWhere((item) => item.id == id);
    });
    _markChanged();
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Map AM/PM lists back into flat routine_items for storage
      final List<RoutineItem> combined = [
        ..._am.map((e) => RoutineItem(
              id: (e['key'] as String),
              name: (e['label'] as String),
              category: 'Morning',
              freq: (e['freq'] as String? ?? 'daily'),
            )),
        ..._pm.map((e) => RoutineItem(
              id: (e['key'] as String),
              name: (e['label'] as String),
              category: 'Evening',
              freq: (e['freq'] as String? ?? 'daily'),
            )),
      ];

      final entryData = {
        'user_id': user.id,
        'entry_id': widget.entryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'routine_items': combined.map((item) => item.toJson()).toList(),
        'notes': _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('routine_entries')
          .upsert(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine entry saved')),
        );

        // Track successful save (simplified, no completion metrics)
        AnalyticsService.capture(AnalyticsEvents.logCreateRoutine, {
          'entry_id': widget.entryId,
          AnalyticsProperties.hasPhoto: false, // Routine entries don't have photos
          'ts': DateTime.now().toIso8601String(),
          'has_notes': _notesController.text.trim().isNotEmpty,
          'total_items': _routineItems.length,
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
          'entry_type': 'routine',
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

  Widget _buildCategorySection(String category) {
    final categoryItems = _routineItems.where((item) => item.category == category).toList();
    
    if (categoryItems.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...categoryItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                  SizedBox(
                    height: 36,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in const ['daily','weekly','as-needed']) ...[
                            ChoiceChip(
                              label: Text(_freqLabel(f)),
                              selected: item.freq == f,
                              selectedColor: const Color(0xFFA8EDEA),
                              onSelected: (_) => _setItemFreq(item.id, f),
                            ),
                            const SizedBox(width: 6),
                          ],
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _removeRoutineItem(item.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine', style: TextStyle(color: Colors.white)),
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
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveRoutine,
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
            // Title & helper
            Text('Current routine', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text("Add your morning and evening steps. You can change frequency for each.", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
            const SizedBox(height: 12),

            // Morning section
            _buildSection('Morning', 'am', _am, _amCtrl),
            const SizedBox(height: 16),
            // Evening section
            _buildSection('Evening', 'pm', _pm, _pmCtrl),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text("I don't have a routine yet"),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amCtrl.dispose();
    _pmCtrl.dispose();
    super.dispose();
  }
}
