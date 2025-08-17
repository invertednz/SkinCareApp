import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';

class SymptomsScreen extends StatefulWidget {
  final String? entryId;
  final Map<String, dynamic>? initialData;

  const SymptomsScreen({
    super.key,
    this.entryId,
    this.initialData,
  });

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final TextEditingController _customSubtypeController = TextEditingController();
  
  // Symptom locations (from database presets)
  final List<String> _availableLocations = [
    'Forehead',
    'Cheeks',
    'Nose',
    'Chin',
    'Jawline',
    'Around Eyes',
    'Around Mouth',
    'Neck',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
  ];

  // Acne subtypes (from database presets)
  final List<String> _availableSubtypes = [
    'Blackheads',
    'Whiteheads',
    'Papules',
    'Pustules',
    'Nodules',
    'Cysts',
    'Comedones',
    'Milia',
    'Rosacea',
    'Eczema',
    'Dermatitis',
    'Hyperpigmentation',
    'Scarring',
    'Dryness',
    'Flaking',
    'Irritation',
    'Redness',
    'Swelling',
  ];

  Set<String> _selectedLocations = {};
  Set<String> _selectedSubtypes = {};
  double _severityLevel = 3.0;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // Track screen view
    AnalyticsService.capture('screen_view', {
      'screen_name': 'symptoms_form',
      'entry_id': widget.entryId,
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      setState(() {
        _selectedLocations = Set<String>.from(data['locations'] as List? ?? []);
        _selectedSubtypes = Set<String>.from(data['subtypes'] as List? ?? []);
        _severityLevel = (data['severity_level'] as num?)?.toDouble() ?? 3.0;
        _notesController.text = data['notes'] as String? ?? '';
      });
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _addCustomSubtype() {
    final text = _customSubtypeController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_availableSubtypes.contains(text)) {
        _availableSubtypes.add(text);
      }
      _selectedSubtypes.add(text);
    });
    _customSubtypeController.clear();
    _markChanged();
  }

  Future<void> _saveSymptoms() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocations.isEmpty && _selectedSubtypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one location or symptom type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final entryData = {
        'user_id': user.id,
        'entry_id': widget.entryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'locations': _selectedLocations.toList(),
        'subtypes': _selectedSubtypes.toList(),
        'severity_level': _severityLevel,
        'notes': _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('symptom_entries')
          .upsert(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Symptoms entry saved')),
        );

        // Track successful save
        AnalyticsService.capture(AnalyticsEvents.logCreateSymptoms, {
          'entry_id': widget.entryId,
          AnalyticsProperties.hasPhoto: false, // Symptoms entries don't have photos
          'ts': DateTime.now().toIso8601String(),
          'has_notes': _notesController.text.trim().isNotEmpty,
          'location_count': _selectedLocations.length,
          'subtype_count': _selectedSubtypes.length,
          'severity_level': _severityLevel,
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
          'entry_type': 'symptoms',
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

  Widget _buildLocationChips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Affected Areas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select all areas where you\'re experiencing symptoms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableLocations.map((location) {
                final isSelected = _selectedLocations.contains(location);
                return FilterChip(
                  label: Text(location),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLocations.add(location);
                      } else {
                        _selectedLocations.remove(location);
                      }
                    });
                    _markChanged();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtypeChips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptom Types',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select all types of symptoms you\'re experiencing',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSubtypes.map((subtype) {
                final isSelected = _selectedSubtypes.contains(subtype);
                return FilterChip(
                  label: Text(subtype),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSubtypes.add(subtype);
                      } else {
                        _selectedSubtypes.remove(subtype);
                      }
                    });
                    _markChanged();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Other conditions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customSubtypeController,
              decoration: InputDecoration(
                hintText: 'Type a condition and press Add',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add condition',
                  onPressed: _addCustomSubtype,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addCustomSubtype(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeveritySlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Severity Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'How severe are your symptoms today?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Mild',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Expanded(
                  child: Slider(
                    value: _severityLevel,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: _getSeverityLabel(_severityLevel),
                    onChanged: (value) {
                      setState(() => _severityLevel = value);
                      _markChanged();
                    },
                  ),
                ),
                Text(
                  'Severe',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Center(
              child: Text(
                _getSeverityLabel(_severityLevel),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getSeverityColor(_severityLevel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSeverityLabel(double value) {
    switch (value.round()) {
      case 1:
        return 'Very Mild';
      case 2:
        return 'Mild';
      case 3:
        return 'Moderate';
      case 4:
        return 'Severe';
      case 5:
        return 'Very Severe';
      default:
        return 'Moderate';
    }
  }

  Color _getSeverityColor(double value) {
    switch (value.round()) {
      case 1:
        return const Color(0xFF6A11CB);
      case 2:
        return const Color(0xFF8EC5FC);
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptoms'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveSymptoms,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
            Text(
              'Track your symptoms',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Record the location, type, and severity of any skin symptoms you\'re experiencing.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            _buildLocationChips(),
            const SizedBox(height: 16),
            
            _buildSubtypeChips(),
            const SizedBox(height: 16),
            
            _buildSeveritySlider(),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your symptoms in more detail...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markChanged(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSymptoms,
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Saving...'),
                      ],
                    )
                  : const Text('Save Symptoms Entry'),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customSubtypeController.dispose();
    super.dispose();
  }
}
