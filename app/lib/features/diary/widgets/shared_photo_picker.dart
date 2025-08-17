import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skincare_app/features/photos/photo_uploader.dart';
import 'package:skincare_app/widgets/upload_progress.dart';
import 'package:skincare_app/services/analytics.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/features/photos/data/photo_repository.dart';

class PhotoEntry {
  final String id;
  final String path;
  final String? url; // Uploaded URL
  final int? width;
  final int? height;
  final int? bytes;

  PhotoEntry({
    required this.id,
    required this.path,
    this.url,
    this.width,
    this.height,
    this.bytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'url': url,
    'width': width,
    'height': height,
    'bytes': bytes,
  };

  factory PhotoEntry.fromJson(Map<String, dynamic> json) => PhotoEntry(
    id: json['id'] as String,
    path: json['path'] as String,
    url: json['url'] as String?,
    width: json['width'] as int?,
    height: json['height'] as int?,
    bytes: json['bytes'] as int?,
  );
}

class SharedPhotoPicker extends StatefulWidget {
  final String entryId;
  final List<PhotoEntry> initialPhotos;
  final ValueChanged<List<PhotoEntry>> onPhotosChanged;
  final int maxPhotos;

  const SharedPhotoPicker({
    super.key,
    required this.entryId,
    required this.onPhotosChanged,
    this.initialPhotos = const [],
    this.maxPhotos = 3,
  });

  @override
  State<SharedPhotoPicker> createState() => _SharedPhotoPickerState();
}

class _SharedPhotoPickerState extends State<SharedPhotoPicker> {
  late List<PhotoEntry> _photos;
  late PhotoUploadController _uploader;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
    _uploader = PhotoUploadController();
    
    // Listen to upload state changes
    _uploader.state.addListener(_onUploadStateChanged);
  }

  @override
  void dispose() {
    _uploader.state.removeListener(_onUploadStateChanged);
    _uploader.dispose();
    super.dispose();
  }

  void _onUploadStateChanged() async {
    final state = _uploader.state.value;
    
    if (state.stage == UploadStage.complete && state.path != null) {
      // Upload completed successfully
      final newPhoto = PhotoEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: state.path!,
        url: null, // will be resolved via signed URL if needed
        width: state.width,
        height: state.height,
        bytes: state.bytes,
      );
      
      setState(() {
        _photos.add(newPhoto);
        _isUploading = false;
      });
      
      widget.onPhotosChanged(_photos);
      
      // Track successful photo addition
      AnalyticsService.capture('diary_photo_added', {
        'entry_id': widget.entryId,
        'photo_count': _photos.length,
        'max_photos': widget.maxPhotos,
      });
      
      // Resolve a signed URL for preview
      try {
        final repo = PhotoRepository.of();
        final url = await repo.createSignedUrl(state.path!);
        if (!mounted) return;
        setState(() {
          final idx = _photos.indexWhere((p) => p.id == newPhoto.id);
          if (idx != -1) {
            _photos[idx] = PhotoEntry(
              id: newPhoto.id,
              path: newPhoto.path,
              url: url,
              width: newPhoto.width,
              height: newPhoto.height,
              bytes: newPhoto.bytes,
            );
          }
        });
        widget.onPhotosChanged(_photos);
      } catch (_) {
        // ignore URL errors for preview
      }
      
    } else if (state.stage == UploadStage.error || state.stage == UploadStage.cancelled) {
      setState(() {
        _isUploading = false;
      });
    } else if (state.stage == UploadStage.uploading) {
      setState(() {
        _isUploading = true;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxPhotos} photos allowed per entry')),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to add photos')),
        );
        return;
      }

      // Recreate controller with selected source so picking uses correct input
      _uploader.state.removeListener(_onUploadStateChanged);
      _uploader.dispose();
      setState(() {
        _uploader = PhotoUploadController(source: source);
      });
      _uploader.state.addListener(_onUploadStateChanged);

      await _uploader.pickAndUpload(userId: user.id, entryId: widget.entryId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  void _removePhoto(String photoId) {
    setState(() {
      _photos.removeWhere((photo) => photo.id == photoId);
    });
    
    widget.onPhotosChanged(_photos);
    
    // Track photo removal
    AnalyticsService.capture('diary_photo_removed', {
      'entry_id': widget.entryId,
      'photo_count': _photos.length,
    });
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(PhotoEntry photo) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: photo.url != null
                ? Image.network(
                    photo.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  )
                : File(photo.path).existsSync()
                    ? Image.file(
                        File(photo.path),
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
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _removePhoto(photo.id),
              ),
            ),
          ),
          if (photo.bytes != null)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatFileSize(photo.bytes!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${_photos.length}/${widget.maxPhotos}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _photos.length >= widget.maxPhotos 
                        ? Colors.orange 
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to ${widget.maxPhotos} photos to document your skin condition.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            
            // Photo grid
            if (_photos.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, index) => _buildPhotoPreview(_photos[index]),
              ),
              const SizedBox(height: 16),
            ],
            
            // Upload progress
            if (_isUploading) ...[
              ValueListenableBuilder<PhotoUploadState>(
                valueListenable: _uploader.state,
                builder: (context, state, _) => Column(
                  children: [
                    UploadProgress(state: state),
                    const SizedBox(height: 8),
                    if ({UploadStage.picking, UploadStage.processing, UploadStage.uploading}
                        .contains(state.stage))
                      TextButton.icon(
                        onPressed: () {
                          AnalyticsService.capture('diary_photo_upload_cancel', {
                            'entry_id': widget.entryId,
                          });
                          _uploader.cancel();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel upload'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Add photo button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _photos.length >= widget.maxPhotos || _isUploading 
                    ? null 
                    : _showPhotoOptions,
                icon: const Icon(Icons.add_a_photo),
                label: Text(
                  _photos.length >= widget.maxPhotos 
                      ? 'Maximum photos reached'
                      : _isUploading
                          ? 'Uploading...'
                          : 'Add Photo',
                ),
              ),
            ),
            
            if (_photos.length >= widget.maxPhotos)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You can remove existing photos to add new ones.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
