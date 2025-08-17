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
  String? _lastPath;
  String? _analysisSummary;

  @override
  void initState() {
    super.initState();
    _uploader = PhotoUploadController();
  }

  Future<void> _analyzeLast() async {
    final path = _lastPath;
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

  Future<void> _deleteLast() async {
    final path = _lastPath;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (path == null || userId == null) return;
    try {
      final repo = PhotoRepository.of();
      await repo.deleteByPath(path);
      if (!mounted) return;
      setState(() {
        _lastPath = null;
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
      setState(() => _lastPath = result.path);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        actions: [
          IconButton(
            tooltip: 'New entry',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New entry coming soon')),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your diary entries will show here.'),
              const SizedBox(height: 24),
              const Text('Quick Photo Upload (demo):'),
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
              const SizedBox(height: 12),
              ValueListenableBuilder<PhotoUploadState>(
                valueListenable: _uploader.state,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UploadProgress(state: value),
                    const SizedBox(height: 8),
                    if ({UploadStage.picking, UploadStage.processing, UploadStage.uploading}
                        .contains(value.stage))
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
              if (_lastPath != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last: $_lastPath',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _analyzeLast,
                      icon: const Icon(Icons.science),
                      label: const Text('Analyze'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _deleteLast,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
                if (_analysisSummary != null) ...[
                  const SizedBox(height: 8),
                  Text('Summary: $_analysisSummary'),
                ]
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New entry',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New entry coming soon')),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
