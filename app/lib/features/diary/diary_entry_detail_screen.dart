import 'package:flutter/material.dart';
import 'package:skincare_app/features/diary/data/diary_repository.dart';
import 'package:skincare_app/features/diary/skin_health_screen.dart';
import 'package:skincare_app/features/diary/symptoms_screen.dart';
import 'package:skincare_app/features/diary/diet_screen.dart';
import 'package:skincare_app/features/diary/supplements_screen.dart';
import 'package:skincare_app/features/diary/routine_screen.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:intl/intl.dart';

class DiaryEntryDetailScreen extends StatefulWidget {
  final String entryId;
  final String entryType;

  const DiaryEntryDetailScreen({
    super.key,
    required this.entryId,
    required this.entryType,
  });

  @override
  State<DiaryEntryDetailScreen> createState() => _DiaryEntryDetailScreenState();
}

class _DiaryEntryDetailScreenState extends State<DiaryEntryDetailScreen> {
  final DiaryRepository _repository = DiaryRepository();
  
  DiaryEntry? _entry;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntry();
    
    // Track screen view
    AnalyticsService.capture('screen_view', {
      'screen_name': 'diary_entry_detail',
      'entry_type': widget.entryType,
      'entry_id': widget.entryId,
    });
  }

  Future<void> _loadEntry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entry = await _repository.getEntry(widget.entryId, widget.entryType);
      setState(() {
        _entry = entry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _editEntry() async {
    if (_entry == null || !_entry!.canEdit) return;

    Widget? editScreen;
    
    switch (widget.entryType) {
      case 'skin_health':
        editScreen = SkinHealthScreen(
          entryId: widget.entryId,
          initialData: _entry!.data,
        );
        break;
      case 'symptoms':
        editScreen = SymptomsScreen(
          entryId: widget.entryId,
          initialData: _entry!.data,
        );
        break;
      case 'diet':
        editScreen = DietScreen(
          entryId: widget.entryId,
          initialData: _entry!.data,
        );
        break;
      case 'supplements':
        editScreen = SupplementsScreen(
          entryId: widget.entryId,
          initialData: _entry!.data,
        );
        break;
      case 'routine':
        editScreen = RoutineScreen(
          entryId: widget.entryId,
          initialData: _entry!.data,
        );
        break;
    }

    if (editScreen != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => editScreen!),
      );
      
      if (result == true) {
        // Entry was updated, reload
        _loadEntry();
      }
    }
  }

  Future<void> _deleteEntry() async {
    if (_entry == null || !_entry!.canEdit) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteEntry(widget.entryId, widget.entryType);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry deleted')),
          );
          
          // Track deletion
          AnalyticsService.capture('diary_entry_deleted', {
            'entry_type': widget.entryType,
            'entry_id': widget.entryId,
          });
          
          Navigator.of(context).pop(true); // Return to history screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete entry: $e')),
          );
        }
      }
    }
  }

  Widget _buildPhotosSection() {
    if (_entry?.photos.isEmpty ?? true) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photos (${_entry!.photos.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _entry!.photos.length,
              itemBuilder: (context, index) {
                final photo = _entry!.photos[index];
                return GestureDetector(
                  onTap: () => _showPhotoDialog(photo, index),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: photo.url != null
                        ? Image.network(
                            photo.url!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDialog(photo, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Photo ${index + 1} of ${_entry!.photos.length}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: photo.url != null
                  ? Image.network(
                      photo.url!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
            ),
            if (photo.bytes != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Size: ${_formatFileSize(photo.bytes!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Widget _buildSkinHealthDetails() {
    final data = _entry!.data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skin Health Ratings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildRatingRow('Overall Skin Health', data['overall_skin_health']),
            _buildRatingRow('Acne Level', data['acne_level']),
            _buildRatingRow('Redness', data['redness']),
            _buildRatingRow('Dryness', data['dryness']),
            _buildRatingRow('Oiliness', data['oiliness']),
            _buildRatingRow('Sensitivity', data['sensitivity']),
            _buildRatingRow('Texture', data['texture']),
            _buildRatingRow('Pore Size', data['pore_size']),
            if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(data['notes'] as String),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, dynamic value) {
    final rating = (value as num?)?.toDouble() ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: rating / 10.0,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 8),
          Text('${rating.round()}/10'),
        ],
      ),
    );
  }

  Widget _buildSymptomsDetails() {
    final data = _entry!.data;
    final locations = (data['locations'] as List?)?.cast<String>() ?? [];
    final subtypes = (data['subtypes'] as List?)?.cast<String>() ?? [];
    final severity = (data['severity_level'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptoms Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (locations.isNotEmpty) ...[
              Text(
                'Affected Areas',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: locations.map((location) => Chip(
                  label: Text(location),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (subtypes.isNotEmpty) ...[
              Text(
                'Symptom Types',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: subtypes.map((subtype) => Chip(
                  label: Text(subtype),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Severity Level',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: severity / 5.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      severity >= 4 ? Colors.red : severity >= 3 ? Colors.orange : const Color(0xFF6A11CB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${severity.round()}/5'),
              ],
            ),
            if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(data['notes'] as String),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDietDetails() {
    final data = _entry!.data;
    final dietFlags = data['diet_flags'] as Map<String, dynamic>? ?? {};
    final selectedFlags = dietFlags.entries.where((e) => e.value == true).map((e) => e.key).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diet Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (selectedFlags.isNotEmpty) ...[
              Text(
                'Dietary Factors (${selectedFlags.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: selectedFlags.map((flag) => Chip(
                  label: Text(flag.replaceAll('_', ' ').toUpperCase()),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ] else ...[
              Text(
                'No dietary factors selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(data['notes'] as String),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementsDetails() {
    final data = _entry!.data;
    final supplements = (data['supplements'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supplements (${supplements.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (supplements.isNotEmpty) ...[
              ...supplements.map((supplement) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(supplement['name'] as String? ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (supplement['dosage'] != null && (supplement['dosage'] as String).isNotEmpty)
                        Text('Dosage: ${supplement['dosage']}'),
                      Text('Frequency: ${supplement['frequency'] ?? 'Once daily'}'),
                      if (supplement['notes'] != null && (supplement['notes'] as String).isNotEmpty)
                        Text('Notes: ${supplement['notes']}'),
                    ],
                  ),
                ),
              )),
            ] else ...[
              Text(
                'No supplements recorded',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Additional Notes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(data['notes'] as String),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineDetails() {
    final data = _entry!.data;
    final routineItems = (data['routine_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final completedCount = routineItems.where((item) => item['completed'] == true).length;
    final adherenceRate = routineItems.isEmpty ? 0.0 : completedCount / routineItems.length;

    // Group items by category
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (final item in routineItems) {
      final category = item['category'] as String? ?? 'Other';
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine Adherence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircularProgressIndicator(
                  value: adherenceRate,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(adherenceRate * 100).round()}% Complete',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('$completedCount of ${routineItems.length} items'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...groupedItems.entries.map((entry) {
              final category = entry.key;
              final items = entry.value;
              final categoryCompleted = items.where((item) => item['completed'] == true).length;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$category ($categoryCompleted/${items.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...items.map((item) => CheckboxListTile(
                    title: Text(item['name'] as String? ?? ''),
                    value: item['completed'] as bool? ?? false,
                    onChanged: null, // Read-only
                    contentPadding: EdgeInsets.zero,
                  )),
                  const SizedBox(height: 8),
                ],
              );
            }),
            if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(data['notes'] as String),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryDetails() {
    switch (widget.entryType) {
      case 'skin_health':
        return _buildSkinHealthDetails();
      case 'symptoms':
        return _buildSymptomsDetails();
      case 'diet':
        return _buildDietDetails();
      case 'supplements':
        return _buildSupplementsDetails();
      case 'routine':
        return _buildRoutineDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_entry?.displayTitle ?? 'Entry Details'),
        actions: [
          if (_entry?.canEdit == true) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editEntry,
              tooltip: 'Edit entry',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEntry,
              tooltip: 'Delete entry',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load entry',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEntry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _entry == null
                  ? const Center(child: Text('Entry not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _entry!.displayTitle,
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('EEEE, MMM d, y \'at\' h:mm a').format(_entry!.createdAt),
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_entry!.canEdit)
                                      Chip(
                                        label: const Text('Read Only'),
                                        backgroundColor: Colors.grey[200],
                                      ),
                                  ],
                                ),
                                if (!_entry!.canEdit) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'This entry is older than 72 hours and cannot be edited.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEntryDetails(),
                        const SizedBox(height: 16),
                        _buildPhotosSection(),
                      ],
                    ),
    );
  }
}
