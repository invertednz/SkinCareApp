import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';

class SkinHealthScreen extends StatefulWidget {
  final String? entryId;
  final Map<String, dynamic>? initialData;

  const SkinHealthScreen({
    super.key,
    this.entryId,
    this.initialData,
  });

  @override
  State<SkinHealthScreen> createState() => _SkinHealthScreenState();
}

class _SkinHealthScreenState extends State<SkinHealthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  // Rating sliders (1-10 scale)
  double _overallSkinHealth = 5.0;
  double _acneLevel = 5.0;
  double _redness = 5.0;
  double _dryness = 5.0;
  double _oiliness = 5.0;
  double _sensitivity = 5.0;
  double _texture = 5.0;
  double _poreSize = 5.0;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // Track screen view
    AnalyticsService.capture('screen_view', {
      'screen_name': 'skin_health_form',
      'entry_id': widget.entryId,
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      setState(() {
        _overallSkinHealth = (data['overall_skin_health'] as num?)?.toDouble() ?? 5.0;
        _acneLevel = (data['acne_level'] as num?)?.toDouble() ?? 5.0;
        _redness = (data['redness'] as num?)?.toDouble() ?? 5.0;
        _dryness = (data['dryness'] as num?)?.toDouble() ?? 5.0;
        _oiliness = (data['oiliness'] as num?)?.toDouble() ?? 5.0;
        _sensitivity = (data['sensitivity'] as num?)?.toDouble() ?? 5.0;
        _texture = (data['texture'] as num?)?.toDouble() ?? 5.0;
        _poreSize = (data['pore_size'] as num?)?.toDouble() ?? 5.0;
        _notesController.text = data['notes'] as String? ?? '';
      });
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveSkinHealth() async {
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
        'overall_skin_health': _overallSkinHealth,
        'acne_level': _acneLevel,
        'redness': _redness,
        'dryness': _dryness,
        'oiliness': _oiliness,
        'sensitivity': _sensitivity,
        'texture': _texture,
        'pore_size': _poreSize,
        'notes': _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('skin_health_entries')
          .upsert(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skin health entry saved')),
        );

        // Track successful save
        AnalyticsService.capture(AnalyticsEvents.logCreateSkin, {
          'entry_id': widget.entryId,
          AnalyticsProperties.hasPhoto: false, // Skin health entries don't have photos
          'ts': DateTime.now().toIso8601String(),
          'has_notes': _notesController.text.trim().isNotEmpty,
          'overall_rating': _overallSkinHealth,
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
          'entry_type': 'skin_health',
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

  Widget _buildRatingSlider({
    required String label,
    required String description,
    required double value,
    required ValueChanged<double> onChanged,
    String lowLabel = 'Poor',
    String highLabel = 'Excellent',
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  lowLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Expanded(
                  child: Slider(
                    value: value,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: value.round().toString(),
                    onChanged: (newValue) {
                      onChanged(newValue);
                      _markChanged();
                    },
                  ),
                ),
                Text(
                  highLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Center(
              child: Text(
                '${value.round()}/10',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Health'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveSkinHealth,
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
              'Rate your skin health today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Use the sliders below to rate different aspects of your skin on a scale of 1-10.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            _buildRatingSlider(
              label: 'Overall Skin Health',
              description: 'How would you rate your overall skin health today?',
              value: _overallSkinHealth,
              onChanged: (value) => setState(() => _overallSkinHealth = value),
            ),
            
            const SizedBox(height: 16),
            _buildRatingSlider(
              label: 'Acne Level',
              description: 'How clear is your skin from acne and breakouts?',
              value: _acneLevel,
              onChanged: (value) => setState(() => _acneLevel = value),
              lowLabel: 'Severe',
              highLabel: 'Clear',
            ),
            
            const SizedBox(height: 16),
            _buildRatingSlider(
              label: 'Redness',
              description: 'How much redness or irritation do you see?',
              value: _redness,
              onChanged: (value) => setState(() => _redness = value),
              lowLabel: 'Very Red',
              highLabel: 'No Redness',
            ),
            
            const SizedBox(height: 16),
            _buildRatingSlider(
              label: 'Dryness',
              description: 'How dry or flaky is your skin?',
              value: _dryness,
              onChanged: (value) => setState(() => _dryness = value),
              lowLabel: 'Very Dry',
              highLabel: 'Well Hydrated',
            ),
            
            const SizedBox(height: 16),
            _buildRatingSlider(
              label: 'Oiliness',
              description: 'How oily or shiny is your skin?',
              value: _oiliness,
              onChanged: (value) => setState(() => _oiliness = value),
              lowLabel: 'Very Oily',
              highLabel: 'Balanced',
            ),
            
            const SizedBox(height: 16),
            _buildRatingSlider(
              label: 'Sensitivity',
              description: 'How sensitive or reactive is your skin?',
              value: _sensitivity,
              onChanged: (value) => setState(() => _sensitivity = value),
              lowLabel: 'Very Sensitive',
              highLabel: 'Not Sensitive',
            ),
            
            const SizedBox(height: 16),
            _buildRatingSlider(
              label: 'Texture',
              description: 'How smooth is your skin texture?',
              value: _texture,
              onChanged: (value) => setState(() => _texture = value),
              lowLabel: 'Rough',
              highLabel: 'Very Smooth',
            ),
            
            const SizedBox(height: 16),
            _buildRatingSlider(
              label: 'Pore Size',
              description: 'How noticeable are your pores?',
              value: _poreSize,
              onChanged: (value) => setState(() => _poreSize = value),
              lowLabel: 'Very Large',
              highLabel: 'Barely Visible',
            ),
            
            const SizedBox(height: 24),
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
                        hintText: 'Any additional observations about your skin today...',
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
              onPressed: _isLoading ? null : _saveSkinHealth,
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
                  : const Text('Save Skin Health Entry'),
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
    super.dispose();
  }
}
