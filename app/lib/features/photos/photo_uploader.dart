import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'data/photo_repository.dart';

/// Constraints per PRD: max 3 photos per entry, 10MB each, max dimension 4096px; EXIF stripped
class PhotoConstraints {
  static const int maxPhotosPerEntry = 3;
  static const int maxBytes = 10 * 1024 * 1024; // 10MB
  static const int maxDimension = 4096; // px
}

enum UploadStage { idle, picking, processing, uploading, complete, error, cancelled }

class PhotoUploadState {
  PhotoUploadState({
    required this.stage,
    this.progress = 0,
    this.message,
    this.path,
    this.bytes,
    this.width,
    this.height,
  });
  final UploadStage stage;
  final double progress; // 0..1 for coarse stage progress
  final String? message;
  final String? path; // storage path when complete
  final int? bytes; // bytes uploaded
  final int? width; // px
  final int? height; // px

  PhotoUploadState copyWith({
    UploadStage? stage,
    double? progress,
    String? message,
    String? path,
    int? bytes,
    int? width,
    int? height,
  }) =>
      PhotoUploadState(
        stage: stage ?? this.stage,
        progress: progress ?? this.progress,
        message: message ?? this.message,
        path: path ?? this.path,
        bytes: bytes ?? this.bytes,
        width: width ?? this.width,
        height: height ?? this.height,
      );
}

/// Controller to manage a single photo upload lifecycle with cancellation and retries
class PhotoUploadController extends ChangeNotifier {
  PhotoUploadController({ImageSource? source}) : _source = source;

  final ImageSource? _source;
  final ImagePicker _picker = ImagePicker();
  final ValueNotifier<PhotoUploadState> state =
      ValueNotifier<PhotoUploadState>(PhotoUploadState(stage: UploadStage.idle));

  bool _cancelled = false;
  void cancel() {
    _cancelled = true;
    state.value = state.value.copyWith(stage: UploadStage.cancelled, message: 'Cancelled');
  }

  Future<XFile?> _pick() async {
    state.value = PhotoUploadState(stage: UploadStage.picking, progress: 0.0);
    try {
      final src = _source;
      if (src != null) {
        return _picker.pickImage(source: src, imageQuality: 100);
      }
      // Default to gallery if unspecified
      return _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    } catch (e) {
      state.value = PhotoUploadState(stage: UploadStage.error, message: 'Picker error: $e');
      return null;
    }
  }

  /// Process bytes: decode, constrain to maxDimension, re-encode JPEG (strips EXIF)
  Future<Uint8List?> _process(Uint8List original) async {
    state.value = PhotoUploadState(stage: UploadStage.processing, progress: 0.33);
    try {
      // If original already under size and small dimensions, keep it
      if (original.lengthInBytes <= PhotoConstraints.maxBytes) {
        final decoded = img.decodeImage(original);
        if (decoded != null && decoded.width <= PhotoConstraints.maxDimension && decoded.height <= PhotoConstraints.maxDimension) {
          // Re-encode once to strip EXIF
          final jpeg = img.encodeJpg(decoded, quality: 85);
          return Uint8List.fromList(jpeg);
        }
      }
      // Decode and resize
      final decoded = img.decodeImage(original);
      if (decoded == null) return null;
      final int w = decoded.width;
      final int h = decoded.height;
      final double scale = 1.0 * PhotoConstraints.maxDimension / (w > h ? w : h);
      final img.Image resized = (w > PhotoConstraints.maxDimension || h > PhotoConstraints.maxDimension)
          ? img.copyResize(decoded, width: (w * scale).round(), height: (h * scale).round())
          : decoded;
      // Encode with quality targeting size limit
      int quality = 85;
      Uint8List out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      while (out.lengthInBytes > PhotoConstraints.maxBytes && quality > 50) {
        quality -= 5;
        out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      }
      return out.lengthInBytes <= PhotoConstraints.maxBytes ? out : null;
    } catch (e) {
      state.value = PhotoUploadState(stage: UploadStage.error, message: 'Process error: $e');
      return null;
    }
  }

  /// High-level helper to pick/capture and upload for an entry
  Future<PhotoUploadState> pickAndUpload({
    required String userId,
    required String entryId,
    PhotoRepository? repo,
  }) async {
    _cancelled = false;
    final repository = repo ?? PhotoRepository.of();

    // Enforce max photos per entry
    final currentCount = await repository.countForEntry(userId, entryId);
    if (currentCount >= PhotoConstraints.maxPhotosPerEntry) {
      const msg = 'Max ${PhotoConstraints.maxPhotosPerEntry} photos per entry reached';
      final s = PhotoUploadState(stage: UploadStage.error, message: msg);
      state.value = s;
      return s;
    }

    final file = await _pick();
    if (file == null || _cancelled) {
      return state.value;
    }

    final bytes = await file.readAsBytes();
    final processed = await _process(bytes);
    if (processed == null) {
      final s = PhotoUploadState(stage: UploadStage.error, message: 'Could not process image under 10MB/4096px');
      state.value = s;
      return s;
    }
    if (_cancelled) return state.value;

    // Upload with retries
    state.value = PhotoUploadState(stage: UploadStage.uploading, progress: 0.66);
    const attempts = 3;
    // Compute dimensions for metadata
    int? width;
    int? height;
    try {
      final decoded = img.decodeImage(processed);
      if (decoded != null) {
        width = decoded.width;
        height = decoded.height;
      }
    } catch (_) {}
    for (int i = 0; i < attempts; i++) {
      if (_cancelled) return state.value;
      try {
        final path = await repository.uploadJpegBytes(
          bytes: processed,
          userId: userId,
          entryId: entryId,
          width: width,
          height: height,
        );
        final s = PhotoUploadState(
          stage: UploadStage.complete,
          progress: 1.0,
          path: path,
          bytes: processed.lengthInBytes,
          width: width,
          height: height,
        );
        state.value = s;
        return s;
      } catch (e) {
        if (i == attempts - 1) {
          final s = PhotoUploadState(stage: UploadStage.error, message: 'Upload failed: $e');
          state.value = s;
          return s;
        }
        // Exponential backoff
        final delayMs = [300, 800, 1500][i];
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }
    return state.value;
  }
}
