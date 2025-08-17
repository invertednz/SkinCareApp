import 'package:flutter/material.dart';
import 'package:skincare_app/features/photos/photo_uploader.dart';

class UploadProgress extends StatelessWidget {
  const UploadProgress({super.key, required this.state});
  final PhotoUploadState state;

  @override
  Widget build(BuildContext context) {
    switch (state.stage) {
      case UploadStage.idle:
        return const SizedBox.shrink();
      case UploadStage.picking:
        return const _Row(icon: Icons.image_search, label: 'Selecting photo…');
      case UploadStage.processing:
        return _Progress(label: 'Processing photo…', value: state.progress);
      case UploadStage.uploading:
        return _Progress(label: 'Uploading…', value: state.progress);
      case UploadStage.complete:
        return const _Row(icon: Icons.check_circle, label: 'Uploaded');
      case UploadStage.cancelled:
        return const _Row(icon: Icons.cancel, label: 'Cancelled');
      case UploadStage.error:
        return _Row(icon: Icons.error, label: state.message ?? 'Upload error');
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.label, this.value});
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value == 0 ? null : value),
      ],
    );
  }
}
