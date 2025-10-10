import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:skincare_app/features/photos/photo_uploader.dart';
import 'package:skincare_app/widgets/upload_progress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skincare_app/features/photos/data/photo_repository.dart';
import 'package:skincare_app/features/photos/data/photo_analysis_repository.dart';
import 'package:skincare_app/services/analytics.dart';
import 'package:skincare_app/services/analytics_events.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late PhotoUploadController _uploader;
  final _entryId = const Uuid().v4(); // temporary draft entry id
  // Date paging like Diet
  DateTime _current = DateTime.now();
  // Notes by YYYY-MM-DD key
  final Map<String, List<_DiaryNote>> _notesByDay = {};

  // Composer state (always open)
  final TextEditingController _noteCtrl = TextEditingController();
  final Set<String> _selectedFactors = <String>{};
  String? _pendingPhotoPath; // uploaded photo to attach on Add
  String? _analysisSummary; // last analysis summary for displayed note/photo

  @override
  void initState() {
    super.initState();
    _uploader = PhotoUploadController();
  }

  Future<void> _analyzePath(String? photoPath) async {
    final path = photoPath;
    if (path == null) return;
    try {
      AnalyticsService.capture(AnalyticsEvents.photoAnalyzeStart, {
        'entry_id': _entryId,
        'path': path,
      });
      final repo = PhotoAnalysisRepository.of();
      final data = await repo.analyzePaths([path], context: {'entry_id': _entryId});
      final analyses = (data['analyses'] as List?) ?? const [];
      String summary = 'No observations';
      bool moderationBlocked = false;
      List<String> categories = const [];
      if (analyses.isNotEmpty) {
        final first = analyses.first as Map? ?? {};
        final mod = (first['moderation'] as Map?) ?? {};
        final allowed = (mod['allowed'] as bool?) ?? true;
        categories = ((mod['categories'] as List?)?.cast<String>()) ?? const [];
        final obs = (first['observations'] as List?) ?? const [];
        if (!allowed) {
          moderationBlocked = true;
          summary = (obs.isNotEmpty ? (obs.first['summary'] as String?) : null) ??
              'This image appears sensitive. Analysis was not performed.';
        } else if (obs.isNotEmpty) {
          summary = (obs.first['summary'] as String?) ?? summary;
        }
      }
      if (!mounted) return;
      setState(() => _analysisSummary = summary);
      if (moderationBlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis blocked due to content: ${categories.join(', ')}')),
        );
        AnalyticsService.capture(AnalyticsEvents.photoModerationBlock, {
          'entry_id': _entryId,
          'path': path,
          AnalyticsProperties.moderationCategory: categories.join(','),
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis complete')),
        );
        AnalyticsService.capture(AnalyticsEvents.photoAnalyzeSuccess, {
          'entry_id': _entryId,
          'path': path,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analyze failed: $e')),
      );
      AnalyticsService.capture(AnalyticsEvents.photoAnalyzeFailure, {
        'entry_id': _entryId,
        'path': path,
        AnalyticsProperties.error: e.toString(),
      });
    }
  }

  Future<void> _deletePhoto(String? photoPath) async {
    final path = photoPath;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (path == null || userId == null) return;
    try {
      final repo = PhotoRepository.of();
      await repo.deleteByPath(path);
      if (!mounted) return;
      setState(() {
        _analysisSummary = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted')),
      );
      AnalyticsService.capture(AnalyticsEvents.photoDelete, {
        'entry_id': _entryId,
        'path': path,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
      AnalyticsService.capture(AnalyticsEvents.photoDelete, {
        'entry_id': _entryId,
        'path': path,
        AnalyticsProperties.error: e.toString(),
      });
    }
  }

  Future<void> _startUpload(ImageSource source) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upload photos.')),
        );
      }
      return;
    }
    AnalyticsService.capture('photo_upload_start', {
      'source': source.name,
      'entry_id': _entryId,
    });
    setState(() {
      _uploader = PhotoUploadController(source: source);
    });
    final result = await _uploader.pickAndUpload(
      userId: userId,
      entryId: _entryId,
    );
    if (!mounted) return;
    if (result.stage == UploadStage.complete) {
      setState(() => _pendingPhotoPath = result.path);
      setState(() => _analysisSummary = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded')),
      );
      AnalyticsService.capture('photo_upload_success', {
        'entry_id': _entryId,
        'path': result.path,
        'bytes': result.bytes,
        'width': result.width,
        'height': result.height,
      });
      AnalyticsService.capture(AnalyticsEvents.photoUploadCancel, {
        'entry_id': _entryId,
      });
    } else if (result.stage == UploadStage.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Upload failed')),
      );
      AnalyticsService.capture('photo_upload_error', {
        'entry_id': _entryId,
        'message': result.message,
      });
    }
  }

  @override
  void dispose() {
    _uploader.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  List<_DiaryNote> get _currentNotes => _notesByDay[_dateKey(_current)] ?? const [];

  String _formatDate(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    const weekdays = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
  String _dateLabel(DateTime d) => DateUtils.isSameDay(d, DateTime.now())
      ? 'Today'
      : ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d.weekday - 1];

  void _toggleFactor(String f, bool sel) {
    setState(() {
      if (sel) {
        _selectedFactors.add(f);
      } else {
        _selectedFactors.remove(f);
      }
    });
  }

  void _addNote() {
    final text = _noteCtrl.text.trim();
    final hasContent = text.isNotEmpty || _selectedFactors.isNotEmpty || _pendingPhotoPath != null;
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text, select a factor, or attach a photo')),
      );
      return;
    }
    final note = _DiaryNote(
      text: text,
      factors: Set<String>.from(_selectedFactors),
      photoPath: _pendingPhotoPath,
      createdAt: DateTime.now(),
    );
    final key = _dateKey(_current);
    setState(() {
      _notesByDay.putIfAbsent(key, () => []);
      _notesByDay[key]!.add(note);
      // clear composer
      _noteCtrl.clear();
      _selectedFactors.clear();
      _pendingPhotoPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note added')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        actions: const [],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date pager (copied style from Diet)
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _circleGradientButton(
                    icon: Icons.chevron_left,
                    onTap: () => setState(() => _current = _current.subtract(const Duration(days: 1))),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dateLabel(_current), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(_current),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  _circleGradientButton(
                    icon: Icons.chevron_right,
                    onTap: () => setState(() => _current = _current.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Composer: Add Note (always open)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type a note (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Optional Factors', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opt in const [
                        'Lack of sleep','High stress','Exercise','Travel','Weather change','Menstruation','Illness','Medication change','Skincare change','Dehydration'
                      ])
                        FilterChip(
                          label: Text(opt),
                          selected: _selectedFactors.contains(opt),
                          onSelected: (sel) => _toggleFactor(opt, sel),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Add a Photo (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _startUpload(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Camera'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _startUpload(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<PhotoUploadState>(
                    valueListenable: _uploader.state,
                    builder: (context, value, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UploadProgress(state: value),
                        const SizedBox(height: 8),
                        if ({UploadStage.picking, UploadStage.processing, UploadStage.uploading}.contains(value.stage))
                          TextButton.icon(
                            onPressed: () {
                              AnalyticsService.capture('photo_upload_cancel', {
                                'entry_id': _entryId,
                              });
                              _uploader.cancel();
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel upload'),
                          ),
                      ],
                    ),
                  ),
                  if (_pendingPhotoPath != null) ...[
                    const SizedBox(height: 8),
                    Text('Attached photo: $_pendingPhotoPath', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _addNote,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notes for current day
            if (_currentNotes.isNotEmpty) ...[
              const Text('Today\'s Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final n in _currentNotes.reversed)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.text.isNotEmpty) Text(n.text),
                      if (n.factors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final f in n.factors) Chip(label: Text(f)),
                          ],
                        ),
                      ],
                      if (n.photoPath != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _analyzePath(n.photoPath),
                              icon: const Icon(Icons.science),
                              label: const Text('Analyze'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _deletePhoto(n.photoPath),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(_formatTime(n.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              if (_analysisSummary != null) ...[
                const SizedBox(height: 8),
                Text('Summary: $_analysisSummary'),
              ],
            ] else ...[
              const Text('No notes for this day yet.'),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m';
  }
}

// Simple card and gradient circle button reused from Diet screen
Widget _card({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: child,
  );
}

Widget _circleGradientButton({required IconData icon, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );
}

class _DiaryNote {
  _DiaryNote({required this.text, required this.factors, this.photoPath, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  final String text;
  final Set<String> factors;
  final String? photoPath;
  final DateTime createdAt;
}

// Bottom sheet removed; composer is always visible on the page.
