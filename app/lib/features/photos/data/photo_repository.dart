import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PhotoRepository {
  PhotoRepository(this._client);
  final SupabaseClient _client;

  static PhotoRepository of() => PhotoRepository(Supabase.instance.client);

  String _buildPath(String userId) {
    final now = DateTime.now().toUtc();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final fileId = const Uuid().v4();
    return '$userId/$yyyy/$mm/$dd/$fileId.jpg';
  }

  Future<String> uploadJpegBytes({
    required Uint8List bytes,
    required String userId,
    String? entryId,
    int? width,
    int? height,
  }) async {
    final path = _buildPath(userId);
    await _client.storage.from('user-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
    await _client.from('photos').insert({
      'user_id': userId,
      'entry_id': entryId,
      'path': path,
      'width': width,
      'height': height,
      'bytes': bytes.length,
    });
    return path;
  }

  Future<String> createSignedUrl(String path, {Duration expiresIn = const Duration(hours: 1)}) async {
    final res = await _client.storage.from('user-photos').createSignedUrl(path, expiresIn.inSeconds);
    return res;
  }

  Future<void> deleteByPath(String path) async {
    // Delete storage object
    await _client.storage.from('user-photos').remove([path]);
    // Delete DB row
    await _client.from('photos').delete().eq('path', path);
  }

  Future<int> countForEntry(String userId, String entryId) async {
    final List<dynamic> rows = await _client
        .from('photos')
        .select('id')
        .eq('user_id', userId)
        .eq('entry_id', entryId);
    return rows.length;
  }
}
