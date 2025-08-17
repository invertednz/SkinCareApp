import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';

class RoutineItem {
  String id;
  String name;
  String category;
  bool completed;
  String? notes;

  RoutineItem({
    required this.id,
    required this.name,
    required this.category,
    this.completed = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'completed': completed,
    'notes': notes,
  };

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    completed: json['completed'] as bool? ?? false,
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
  int _currentTabIndex = 0; // 0 = Morning, 1 = Evening
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
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
    });
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _toggleRoutineItem(String id, bool completed) {
    setState(() {
      final index = _routineItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _routineItems[index].completed = completed;
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

      final entryData = {
        'user_id': user.id,
        'entry_id': widget.entryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'routine_items': _routineItems.map((item) => item.toJson()).toList(),
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

        // Track successful save
        final completedCount = _routineItems.where((item) => item.completed).length;
        final adherenceRate = _routineItems.isEmpty ? 0.0 : completedCount / _routineItems.length;
        
        AnalyticsService.capture(AnalyticsEvents.logCreateRoutine, {
          'entry_id': widget.entryId,
          AnalyticsProperties.hasPhoto: false, // Routine entries don't have photos
          'ts': DateTime.now().toIso8601String(),
          'has_notes': _notesController.text.trim().isNotEmpty,
          'total_items': _routineItems.length,
          'completed_items': completedCount,
          'adherence_rate': adherenceRate,
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

    final completedCount = categoryItems.where((item) => item.completed).length;
    final totalCount = categoryItems.length;

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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedCount == totalCount 
                        ? const Color(0xFFE0C3FC).withOpacity(0.3)
                        : Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/$totalCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: completedCount == totalCount 
                          ? const Color(0xFF6A11CB)
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...categoryItems.map((item) => CheckboxListTile(
              title: Text(item.name),
              value: item.completed,
              onChanged: (value) => _toggleRoutineItem(item.id, value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              secondary: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeRoutineItem(item.id);
                  }
                },
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
            // Intro
            Text(
              'Skincare Routine',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check off each step in your morning and evening routine.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

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
                    _gradientCircle(child: const Icon(Icons.calendar_today, color: Colors.white, size: 18)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tabs: Morning / Evening
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Morning'),
                  selected: _currentTabIndex == 0,
                  onSelected: (v) => setState(() => _currentTabIndex = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Evening'),
                  selected: _currentTabIndex == 1,
                  onSelected: (v) => setState(() => _currentTabIndex = 1),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Steps list
            Builder(
              builder: (context) {
                final items = _itemsForCurrentTab();
                if (items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentTabIndex == 0
                                  ? 'No morning steps yet. Add your morning routine items.'
                                  : 'No evening steps yet. Add your evening routine items.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                int step = 1;
                return Column(
                  children: items.map((item) {
                    final index = step++;
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                _gradientCircle(child: Text('$index')),
                                const SizedBox(width: 12),
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Checkbox(
                              value: item.completed,
                              onChanged: (v) => _toggleRoutineItem(item.id, v ?? false),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Add step action
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  // Default category based on current tab
                  final defaultCategory = _currentTabIndex == 0
                      ? _defaultRoutineItems.keys.firstWhere(_isMorningCategory, orElse: () => 'Morning Cleansing')
                      : _defaultRoutineItems.keys.firstWhere(_isEveningCategory, orElse: () => 'Evening Cleansing');
                  _addCustomRoutineItem(defaultCategory);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Step'),
              ),
            ),

            const SizedBox(height: 8),

            // Add New Product button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addCustomRoutineItem,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add New Product'),
              ),
            ),

            const SizedBox(height: 16),

            // Routine Reminders
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Routine Reminders', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable reminders'),
                      value: _remindersEnabled,
                      onChanged: (v) {
                        setState(() => _remindersEnabled = v);
                        _markChanged();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InputChip(
                          label: Text('Time: ${_reminderTime.format(context)}'),
                          onPressed: _pickReminderTime,
                          avatar: const Icon(Icons.access_time, size: 18),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reminder management not implemented')),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Manage'),
                        ),
                      ],
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
    _notesController.dispose();
    super.dispose();
  }
}
