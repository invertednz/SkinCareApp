import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';

class DietScreen extends StatefulWidget {
  final String? entryId;
  final Map<String, dynamic>? initialData;

  const DietScreen({
    super.key,
    this.entryId,
    this.initialData,
  });

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  // Diet flags - common dietary factors that can affect skin
  final Map<String, bool> _dietFlags = {
    'dairy': false,
    'sugar': false,
    'processed_foods': false,
    'gluten': false,
    'chocolate': false,
    'spicy_foods': false,
    'alcohol': false,
    'caffeine': false,
    'nuts': false,
    'seafood': false,
    'citrus': false,
    'high_glycemic': false,
    'fried_foods': false,
    'artificial_sweeteners': false,
  };

  // User-friendly labels for diet flags
  final Map<String, String> _dietLabels = {
    'dairy': 'Dairy Products',
    'sugar': 'High Sugar Foods',
    'processed_foods': 'Processed Foods',
    'gluten': 'Gluten-containing Foods',
    'chocolate': 'Chocolate',
    'spicy_foods': 'Spicy Foods',
    'alcohol': 'Alcohol',
    'caffeine': 'Caffeine',
    'nuts': 'Nuts',
    'seafood': 'Seafood',
    'citrus': 'Citrus Fruits',
    'high_glycemic': 'High Glycemic Foods',
    'fried_foods': 'Fried Foods',
    'artificial_sweeteners': 'Artificial Sweeteners',
  };

  // Diet flag descriptions
  final Map<String, String> _dietDescriptions = {
    'dairy': 'Milk, cheese, yogurt, ice cream',
    'sugar': 'Candy, desserts, sugary drinks',
    'processed_foods': 'Packaged meals, fast food',
    'gluten': 'Bread, pasta, cereals',
    'chocolate': 'Dark, milk, or white chocolate',
    'spicy_foods': 'Hot peppers, spicy sauces',
    'alcohol': 'Beer, wine, spirits',
    'caffeine': 'Coffee, tea, energy drinks',
    'nuts': 'Peanuts, tree nuts, nut butters',
    'seafood': 'Fish, shellfish, sushi',
    'citrus': 'Oranges, lemons, grapefruits',
    'high_glycemic': 'White rice, potatoes, white bread',
    'fried_foods': 'French fries, fried chicken',
    'artificial_sweeteners': 'Diet sodas, sugar-free products',
  };
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // Track screen view
    AnalyticsService.capture('screen_view', {
      'screen_name': 'diet_form',
      'entry_id': widget.entryId,
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      setState(() {
        // Load diet flags from saved data
        final savedFlags = data['diet_flags'] as Map<String, dynamic>? ?? {};
        for (final key in _dietFlags.keys) {
          _dietFlags[key] = savedFlags[key] as bool? ?? false;
        }
        _notesController.text = data['notes'] as String? ?? '';
      });
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveDiet() async {
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
        'diet_flags': _dietFlags,
        'notes': _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('diet_entries')
          .upsert(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet entry saved')),
        );

        // Track successful save
        AnalyticsService.capture(AnalyticsEvents.logCreateDiet, {
          'entry_id': widget.entryId,
          AnalyticsProperties.hasPhoto: false, // Diet entries don't have photos
          'ts': DateTime.now().toIso8601String(),
          'has_notes': _notesController.text.trim().isNotEmpty,
          'diet_flags_count': _dietFlags.values.where((v) => v).length,
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
          'entry_type': 'diet',
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

  Widget _buildDietFlagTile(String key) {
    final label = _dietLabels[key] ?? key;
    final description = _dietDescriptions[key] ?? '';
    final isSelected = _dietFlags[key] ?? false;

    return Card(
      child: SwitchListTile(
        title: Text(label),
        subtitle: Text(description),
        value: isSelected,
        onChanged: (value) {
          setState(() {
            _dietFlags[key] = value;
          });
          _markChanged();
        },
        secondary: Icon(
          _getDietIcon(key),
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
    );
  }

  IconData _getDietIcon(String key) {
    switch (key) {
      case 'dairy':
        return Icons.local_drink;
      case 'sugar':
        return Icons.cake;
      case 'processed_foods':
        return Icons.fastfood;
      case 'gluten':
        return Icons.grain;
      case 'chocolate':
        return Icons.cookie;
      case 'spicy_foods':
        return Icons.local_fire_department;
      case 'alcohol':
        return Icons.wine_bar;
      case 'caffeine':
        return Icons.coffee;
      case 'nuts':
        return Icons.eco;
      case 'seafood':
        return Icons.set_meal;
      case 'citrus':
        return Icons.emoji_food_beverage;
      case 'high_glycemic':
        return Icons.rice_bowl;
      case 'fried_foods':
        return Icons.restaurant;
      case 'artificial_sweeteners':
        return Icons.science;
      default:
        return Icons.restaurant_menu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _dietFlags.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveDiet,
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
              'Track your diet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select the foods and drinks you consumed today that might affect your skin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            if (selectedCount > 0)
              Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$selectedCount dietary factor${selectedCount == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Group diet flags into categories
            Text(
              'Common Trigger Foods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            _buildDietFlagTile('dairy'),
            _buildDietFlagTile('sugar'),
            _buildDietFlagTile('processed_foods'),
            _buildDietFlagTile('gluten'),
            _buildDietFlagTile('chocolate'),
            
            const SizedBox(height: 16),
            Text(
              'Beverages & Stimulants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            _buildDietFlagTile('alcohol'),
            _buildDietFlagTile('caffeine'),
            
            const SizedBox(height: 16),
            Text(
              'Other Foods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            _buildDietFlagTile('spicy_foods'),
            _buildDietFlagTile('nuts'),
            _buildDietFlagTile('seafood'),
            _buildDietFlagTile('citrus'),
            _buildDietFlagTile('high_glycemic'),
            _buildDietFlagTile('fried_foods'),
            _buildDietFlagTile('artificial_sweeteners'),
            
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
                    Text(
                      'Record any other foods, meals, or dietary patterns you think might be relevant.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'e.g., "Had pizza for lunch, tried a new protein powder..."',
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
              onPressed: _isLoading ? null : _saveDiet,
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
                  : const Text('Save Diet Entry'),
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
