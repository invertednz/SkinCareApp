import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/analytics_service.dart';

class NotificationsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get notification settings for the current user
  Future<List<NotificationSetting>> getNotificationSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', user.id)
          .order('category');

      return response
          .map<NotificationSetting>((json) => NotificationSetting.fromJson(json))
          .toList();
    } catch (e) {
      AnalyticsService.capture('notification_settings_fetch_error', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Update notification setting
  Future<void> updateNotificationSetting(NotificationSetting setting) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('notification_settings').upsert({
        'user_id': user.id,
        'category': setting.category,
        'enabled': setting.enabled,
        'time': setting.time.format24Hour,
        'quiet_from': setting.quietFrom.format24Hour,
        'quiet_to': setting.quietTo.format24Hour,
        'updated_at': DateTime.now().toIso8601String(),
      });

      AnalyticsService.capture('notification_settings_update', {
        'category': setting.category,
        'enabled': setting.enabled,
      });
    } catch (e) {
      AnalyticsService.capture('notification_settings_update_error', {
        'error': e.toString(),
        'category': setting.category,
      });
      rethrow;
    }
  }

  /// Create default notification settings for a user
  Future<void> createDefaultSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.rpc('create_default_notification_settings', params: {
        'user_id': user.id,
      });
    } catch (e) {
      AnalyticsService.capture('notification_default_settings_error', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Check if user has any notification settings
  Future<bool> hasNotificationSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('notification_settings')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Notification setting model
class NotificationSetting {
  final String id;
  final String userId;
  final String category;
  final bool enabled;
  final AppTimeOfDay time;
  final AppTimeOfDay quietFrom;
  final AppTimeOfDay quietTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSetting({
    required this.id,
    required this.userId,
    required this.category,
    required this.enabled,
    required this.time,
    required this.quietFrom,
    required this.quietTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    return NotificationSetting(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      enabled: json['enabled'],
      time: AppTimeOfDay.fromString(json['time']),
      quietFrom: AppTimeOfDay.fromString(json['quiet_from']),
      quietTo: AppTimeOfDay.fromString(json['quiet_to']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'enabled': enabled,
      'time': time.format24Hour,
      'quiet_from': quietFrom.format24Hour,
      'quiet_to': quietTo.format24Hour,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationSetting copyWith({
    String? id,
    String? userId,
    String? category,
    bool? enabled,
    AppTimeOfDay? time,
    AppTimeOfDay? quietFrom,
    AppTimeOfDay? quietTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      quietFrom: quietFrom ?? this.quietFrom,
      quietTo: quietTo ?? this.quietTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name for category
  String get displayName {
    switch (category) {
      case 'routine_am':
        return 'Morning Routine';
      case 'routine_pm':
        return 'Evening Routine';
      case 'daily_log':
        return 'Daily Log Reminder';
      case 'weekly_insights':
        return 'Weekly Insights';
      default:
        return category;
    }
  }

  /// Get description for category
  String get description {
    switch (category) {
      case 'routine_am':
        return 'Reminder to complete your morning skincare routine';
      case 'routine_pm':
        return 'Reminder to complete your evening skincare routine';
      case 'daily_log':
        return 'Reminder to log your daily skin health and symptoms';
      case 'weekly_insights':
        return 'Weekly insights about your skin health progress';
      default:
        return '';
    }
  }
}

/// Time of day helper class
class AppTimeOfDay {
  final int hour;
  final int minute;

  const AppTimeOfDay({required this.hour, required this.minute});

  factory AppTimeOfDay.fromString(String timeString) {
    final parts = timeString.split(':');
    return AppTimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String get format24Hour => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

  String get format12Hour {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  String toString() => format12Hour;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTimeOfDay && runtimeType == other.runtimeType && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
