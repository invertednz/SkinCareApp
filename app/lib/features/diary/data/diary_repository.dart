import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare_app/features/diary/widgets/shared_photo_picker.dart';
import '../../../services/analytics.dart';
import '../../../services/analytics_events.dart';
import 'package:flutter/foundation.dart';

class DiaryEntry {
  final String id;
  final String userId;
  final String type;
  final Map<String, dynamic> data;
  final List<PhotoEntry> photos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool canEdit;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.data,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
    required this.canEdit,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json, String type) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    final now = DateTime.now();
    final canEdit = now.difference(createdAt).inHours < 72;

    return DiaryEntry(
      id: json['entry_id'] as String,
      userId: json['user_id'] as String,
      type: type,
      data: json,
      photos: [], // Will be populated separately
      createdAt: createdAt,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      canEdit: canEdit,
    );
  }

  String get displayTitle {
    switch (type) {
      case 'skin_health':
        return 'Skin Health';
      case 'symptoms':
        return 'Symptoms';
      case 'diet':
        return 'Diet';
      case 'supplements':
        return 'Supplements';
      case 'routine':
        return 'Routine';
      default:
        return 'Entry';
    }
  }

  String get displaySubtitle {
    switch (type) {
      case 'skin_health':
        final overall = data['overall_skin_health'] as num? ?? 0;
        return 'Overall: ${overall.round()}/10';
      case 'symptoms':
        final locations = data['locations'] as List? ?? [];
        final subtypes = data['subtypes'] as List? ?? [];
        return '${locations.length} areas, ${subtypes.length} symptoms';
      case 'diet':
        final flags = data['diet_flags'] as Map? ?? {};
        final selectedCount = flags.values.where((v) => v == true).length;
        return '$selectedCount dietary factors';
      case 'supplements':
        final supplements = data['supplements'] as List? ?? [];
        return '${supplements.length} supplements';
      case 'routine':
        final items = data['routine_items'] as List? ?? [];
        final completed = items.where((item) => item['completed'] == true).length;
        return '$completed/${items.length} completed';
      default:
        return '';
    }
  }
}

class DiaryRepository {
  final SupabaseClient _supabase;

  DiaryRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // Task 4.1: List views grouped by date with filters by type
  Future<List<DiaryEntry>> getEntries({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? types,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final entries = <DiaryEntry>[];
      final entryTypes = types ?? ['skin_health', 'symptoms', 'diet', 'supplements', 'routine'];

      for (final type in entryTypes) {
        final tableName = '${type}_entries';

        // Build base filter query first so that filter methods are available
        var baseQuery = _supabase
            .from(tableName)
            .select('*')
            .eq('user_id', user.id);

        if (startDate != null) {
          baseQuery = baseQuery.gte('created_at', startDate.toIso8601String());
        }
        if (endDate != null) {
          baseQuery = baseQuery.lte('created_at', endDate.toIso8601String());
        }

        // Apply transform methods (order, limit, range) after filtering
        final response = await baseQuery
            .order('created_at', ascending: false)
            .limit(limit)
            .range(offset, offset + limit - 1);

        for (final item in response) {
          entries.add(DiaryEntry.fromJson(item, type));
        }
      }

      // Sort all entries by creation date
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Load photos for each entry
      for (final entry in entries) {
        entry.photos.addAll(await _getPhotosForEntry(entry.id));
      }

      return entries;
    } catch (e) {
      throw Exception('Failed to load diary entries: $e');
    }
  }

  // Task 4.2: Detail view to read entries and view photos
  Future<DiaryEntry?> getEntry(String entryId, String type) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final tableName = '${type}_entries';
      final response = await _supabase
          .from(tableName)
          .select('*')
          .eq('user_id', user.id)
          .eq('entry_id', entryId)
          .maybeSingle();

      if (response == null) return null;

      final entry = DiaryEntry.fromJson(response, type);
      entry.photos.addAll(await _getPhotosForEntry(entryId));

      return entry;
    } catch (e) {
      throw Exception('Failed to load diary entry: $e');
    }
  }

  // Task 4.3: Allow edit/delete within 72 hours
  Future<bool> canEditEntry(String entryId, String type) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final tableName = '${type}_entries';
      final response = await _supabase
          .from(tableName)
          .select('created_at')
          .eq('user_id', user.id)
          .eq('entry_id', entryId)
          .maybeSingle();

      if (response == null) return false;

      final createdAt = DateTime.parse(response['created_at'] as String);
      final now = DateTime.now();
      return now.difference(createdAt).inHours < 72;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteEntry(String entryId, String type) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if entry can be edited (within 72 hours)
      final canEdit = await canEditEntry(entryId, type);
      if (!canEdit) {
        throw Exception('Entry can only be deleted within 72 hours of creation');
      }

      final tableName = '${type}_entries';
      
      // Delete associated photos first
      await _deletePhotosForEntry(entryId);
      
      // Delete the entry
      await _supabase
          .from(tableName)
          .delete()
          .eq('user_id', user.id)
          .eq('entry_id', entryId);
    } catch (e) {
      throw Exception('Failed to delete diary entry: $e');
    }
  }

  Future<void> updateEntry(String entryId, String type, Map<String, dynamic> data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if entry can be edited (within 72 hours)
      final canEdit = await canEditEntry(entryId, type);
      if (!canEdit) {
        throw Exception('Entry can only be edited within 72 hours of creation');
      }

      final tableName = '${type}_entries';
      final updateData = {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(tableName)
          .update(updateData)
          .eq('user_id', user.id)
          .eq('entry_id', entryId);
    } catch (e) {
      throw Exception('Failed to update diary entry: $e');
    }
  }

  // Get entries grouped by date for list view
  Future<Map<DateTime, List<DiaryEntry>>> getEntriesGroupedByDate({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? types,
  }) async {
    final entries = await getEntries(
      startDate: startDate,
      endDate: endDate,
      types: types,
    );

    final grouped = <DateTime, List<DiaryEntry>>{};
    
    for (final entry in entries) {
      final date = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(entry);
    }

    return grouped;
  }

  // Helper method to get photos for an entry
  Future<List<PhotoEntry>> _getPhotosForEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('photos')
          .select('*')
          .eq('user_id', user.id)
          .eq('entry_id', entryId)
          .order('created_at', ascending: true);

      return response.map<PhotoEntry>((photo) {
        return PhotoEntry(
          id: photo['id'] as String,
          path: photo['path'] as String,
          url: photo['url'] as String?,
          width: photo['width'] as int?,
          height: photo['height'] as int?,
          bytes: photo['bytes'] as int?,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper method to delete photos for an entry
  Future<void> _deletePhotosForEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get photos to delete from storage
      final photos = await _getPhotosForEntry(entryId);
      
      // Delete from storage
      for (final photo in photos) {
        try {
          await _supabase.storage.from('user-photos').remove([photo.path]);
        } catch (e) {
          // Continue even if storage deletion fails
          debugPrint('Failed to delete photo from storage: $e');
        }
      }

      // Delete from database
      await _supabase
          .from('photos')
          .delete()
          .eq('user_id', user.id)
          .eq('entry_id', entryId);
    } catch (e) {
      debugPrint('Failed to delete photos for entry: $e');
    }
  }

  // Get entry statistics
  Future<Map<String, int>> getEntryStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {};
      }

      final stats = <String, int>{};
      final entryTypes = ['skin_health', 'symptoms', 'diet', 'supplements', 'routine'];

      for (final type in entryTypes) {
        final tableName = '${type}_entries';
        
        var query = _supabase
            .from(tableName)
            .select('id')
            .eq('user_id', user.id);

        if (startDate != null) {
          query = query.gte('created_at', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('created_at', endDate.toIso8601String());
        }

        final List<dynamic> data = await query;
        stats[type] = data.length;
      }

      return stats;
    } catch (e) {
      return {};
    }
  }
}
