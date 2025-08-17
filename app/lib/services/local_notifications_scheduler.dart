import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../features/notifications/data/notifications_repository.dart';
import 'analytics_service.dart';

class LocalNotificationsScheduler {
  static final LocalNotificationsScheduler _instance = LocalNotificationsScheduler._internal();
  factory LocalNotificationsScheduler() => _instance;
  LocalNotificationsScheduler._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationsRepository _repository = NotificationsRepository();
  
  bool _isInitialized = false;

  /// Initialize the local notifications scheduler
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize timezone data
      tzdata.initializeTimeZones();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      _isInitialized = true;
    } catch (e) {
      AnalyticsService.capture('local_notifications_init_error', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Schedule all local notifications based on user settings
  Future<void> scheduleAllNotifications() async {
    try {
      // Cancel all existing notifications first
      await _localNotifications.cancelAll();
      
      // Get user notification settings
      final settings = await _repository.getNotificationSettings();
      
      for (final setting in settings) {
        if (setting.enabled) {
          await _scheduleNotificationForSetting(setting);
        }
      }
      
      AnalyticsService.capture('local_notifications_scheduled', {
        'count': settings.where((s) => s.enabled).length,
      });
    } catch (e) {
      AnalyticsService.capture('local_notifications_schedule_error', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Schedule notification for a specific setting
  Future<void> _scheduleNotificationForSetting(NotificationSetting setting) async {
    try {
      final now = DateTime.now();
      final timeZone = tz.local;
      
      // Calculate next notification time
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        setting.time.hour,
        setting.time.minute,
      );
      
      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Check if the scheduled time is in quiet hours
      if (_isInQuietHours(scheduledDate, setting)) {
        // Skip scheduling if in quiet hours
        return;
      }
      
      final scheduledTz = tz.TZDateTime.from(scheduledDate, timeZone);
      
      final notificationDetails = _getNotificationDetails(setting.category);
      
      // Schedule the notification
      await _localNotifications.zonedSchedule(
        _getNotificationId(setting.category),
        notificationDetails.title,
        notificationDetails.body,
        scheduledTz,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'skincare_${setting.category}',
            _getCategoryDisplayName(setting.category),
            channelDescription: setting.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: setting.category,
          ),
        ),
        payload: setting.category,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
      
      // For weekly insights, schedule weekly instead of daily
      if (setting.category == 'weekly_insights') {
        await _scheduleWeeklyNotification(setting, scheduledTz);
      }
    } catch (e) {
      AnalyticsService.capture('local_notification_schedule_error', {
        'category': setting.category,
        'error': e.toString(),
      });
    }
  }

  /// Schedule weekly notification
  Future<void> _scheduleWeeklyNotification(NotificationSetting setting, tz.TZDateTime scheduledDate) async {
    // Find next Sunday at the scheduled time
    var nextSunday = scheduledDate;
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    
    final notificationDetails = _getNotificationDetails(setting.category);
    
    await _localNotifications.zonedSchedule(
      _getNotificationId(setting.category),
      notificationDetails.title,
      notificationDetails.body,
      nextSunday,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'skincare_${setting.category}',
          _getCategoryDisplayName(setting.category),
          channelDescription: setting.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: setting.category,
        ),
      ),
      payload: setting.category,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeat weekly
    );
  }

  /// Check if scheduled time is in quiet hours
  bool _isInQuietHours(DateTime scheduledTime, NotificationSetting setting) {
    final scheduledMinutes = scheduledTime.hour * 60 + scheduledTime.minute;
    final quietFromMinutes = setting.quietFrom.hour * 60 + setting.quietFrom.minute;
    final quietToMinutes = setting.quietTo.hour * 60 + setting.quietTo.minute;

    // Handle quiet hours that span midnight
    if (quietFromMinutes > quietToMinutes) {
      return scheduledMinutes >= quietFromMinutes || scheduledMinutes <= quietToMinutes;
    } else {
      return scheduledMinutes >= quietFromMinutes && scheduledMinutes <= quietToMinutes;
    }
  }

  /// Get notification details for category
  ({String title, String body}) _getNotificationDetails(String category) {
    switch (category) {
      case 'routine_am':
        return (
          title: 'Morning Skincare Routine',
          body: 'Time for your morning skincare routine! Start your day with healthy skin.',
        );
      case 'routine_pm':
        return (
          title: 'Evening Skincare Routine',
          body: 'Don\'t forget your evening skincare routine before bed.',
        );
      case 'daily_log':
        return (
          title: 'Daily Skin Health Log',
          body: 'How is your skin feeling today? Log your daily observations.',
        );
      case 'weekly_insights':
        return (
          title: 'Weekly Skin Insights',
          body: 'Your weekly skin health insights are ready! Check your progress.',
        );
      default:
        return (
          title: 'SkinCare Reminder',
          body: 'You have a skincare reminder.',
        );
    }
  }

  /// Get notification ID for category
  int _getNotificationId(String category) {
    switch (category) {
      case 'routine_am':
        return 1001;
      case 'routine_pm':
        return 1002;
      case 'daily_log':
        return 1003;
      case 'weekly_insights':
        return 1004;
      default:
        return 1000;
    }
  }

  /// Get category display name
  String _getCategoryDisplayName(String category) {
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
        return 'SkinCare Notifications';
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final category = response.payload;
    if (category != null) {
      AnalyticsService.capture('local_notification_open', {
        'category': category,
      });
      
      // Handle deep linking - this would be handled by the router
      // The deep link routes are already implemented according to the task file
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    
    AnalyticsService.capture('local_notifications_cancelled', {});
  }

  /// Cancel notification for specific category
  Future<void> cancelNotification(String category) async {
    final id = _getNotificationId(category);
    await _localNotifications.cancel(id);
    
    AnalyticsService.capture('local_notification_cancelled', {
      'category': category,
    });
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }
}
