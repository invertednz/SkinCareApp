import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoAnalysisRepository {
  PhotoAnalysisRepository(this._client);
  final SupabaseClient _client;

  static PhotoAnalysisRepository of() => PhotoAnalysisRepository(Supabase.instance.client);

  Future<Map<String, dynamic>> analyzePaths(List<String> paths, {Map<String, dynamic>? context}) async {
    final payload = {
      'paths': paths,
      if (context != null) 'context': context,
    };
    final response = await _client.functions.invoke('vision-analyze', body: payload);
    // Supabase Dart returns the parsed response in data, throws on non-2xx
    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Empty response from vision-analyze');
    }
    return data;
  }
}
