import 'package:flutter/material.dart';
import 'package:skincare_app/features/diary/data/diary_repository.dart';
import 'package:skincare_app/features/diary/diary_entry_detail_screen.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DiaryRepository _repository = DiaryRepository();
  
  Map<DateTime, List<DiaryEntry>> _groupedEntries = {};
  Map<String, int> _entryStats = {};
  final List<String> _selectedTypes = ['skin_health', 'symptoms', 'diet', 'supplements', 'routine'];
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool _isLoading = true;
  String? _error;

  final Map<String, String> _typeLabels = {
    'skin_health': 'Skin Health',
    'symptoms': 'Symptoms',
    'diet': 'Diet',
    'supplements': 'Supplements',
    'routine': 'Routine',
  };

  final Map<String, IconData> _typeIcons = {
    'skin_health': Icons.face,
    'symptoms': Icons.healing,
    'diet': Icons.restaurant,
    'supplements': Icons.medication,
    'routine': Icons.checklist,
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
    
    // Track screen view
    AnalyticsService.capture('screen_view', {
      'screen_name': 'diary_history',
    });
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final [groupedEntries, stats] = await Future.wait([
        _repository.getEntriesGroupedByDate(
          startDate: _startDate,
          endDate: _endDate,
          types: _selectedTypes,
        ),
        _repository.getEntryStats(
          startDate: _startDate,
          endDate: _endDate,
        ),
      ]);

      setState(() {
        _groupedEntries = groupedEntries as Map<DateTime, List<DiaryEntry>>;
        _entryStats = stats as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Entries'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Entry Types:'),
                const SizedBox(height: 8),
                ..._typeLabels.entries.map((entry) {
                  final type = entry.key;
                  final label = entry.value;
                  final isSelected = _selectedTypes.contains(type);
                  
                  return CheckboxListTile(
                    title: Text(label),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 16),
                const Text('Date Range:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _startDate = date;
                            });
                          }
                        },
                        child: Text(_startDate != null 
                            ? DateFormat('MMM d, y').format(_startDate!)
                            : 'Start Date'),
                      ),
                    ),
                    const Text(' - '),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _endDate = date;
                            });
                          }
                        },
                        child: Text(_endDate != null 
                            ? DateFormat('MMM d, y').format(_endDate!)
                            : 'End Date'),
                      ),
                    ),
                  ],
                ),
                if (_startDate != null || _endDate != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    child: const Text('Clear Date Range'),
                  ),
                ],
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
                Navigator.of(context).pop();
                _loadEntries();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalEntries = _entryStats.values.fold(0, (sum, count) => sum + count);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entry Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Total Entries: $totalEntries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _entryStats.entries.map((entry) {
                final type = entry.key;
                final count = entry.value;
                final label = _typeLabels[type] ?? type;
                final icon = _typeIcons[type] ?? Icons.circle;
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 4),
                    Text('$label: $count'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    final icon = _typeIcons[entry.type] ?? Icons.circle;
    final canEdit = entry.canEdit;
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: canEdit 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            icon,
            color: canEdit 
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ),
        title: Text(entry.displayTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.displaySubtitle),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  DateFormat('h:mm a').format(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (entry.photos.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.photo_camera,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.photos.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (!canEdit) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DiaryEntryDetailScreen(
                entryId: entry.id,
                entryType: entry.type,
              ),
            ),
          ).then((_) {
            // Refresh entries when returning from detail screen
            _loadEntries();
          });
        },
      ),
    );
  }

  Widget _buildDateSection(DateTime date, List<DiaryEntry> entries) {
    final isToday = DateTime.now().difference(date).inDays == 0;
    final isYesterday = DateTime.now().difference(date).inDays == 1;
    
    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d, y').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ...entries.map(_buildEntryCard),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter entries',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: _isLoading
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
                          'Failed to load entries',
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
                          onPressed: _loadEntries,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _groupedEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No diary entries found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start logging your skincare journey to see entries here.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildStatsCard(),
                          const SizedBox(height: 16),
                          ..._groupedEntries.entries
                            .map((entry) => _buildDateSection(entry.key, entry.value)),
                        ],
                      ),
      ),
    );
  }
}
