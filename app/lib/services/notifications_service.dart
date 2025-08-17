import 'dart:async';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_service.dart';
import 'local_notifications_scheduler.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final LocalNotificationsScheduler _localScheduler = LocalNotificationsScheduler();
  
  bool _isInitialized = false;
  
  /// Initialize the notifications service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize local notifications scheduler
      await _localScheduler.initialize();
      
      _isInitialized = true;
    } catch (e) {
      AnalyticsService.capture('notification_init_error', {
        'error': e.toString(),
      });
      rethrow;
    }
  }
  
  /// Request notification permission and handle different states
  Future<NotificationPermissionResult> requestPermission() async {
    try {
      // iOS/macOS permission prompt via flutter_local_notifications is optional.
      // We avoid platform-specific plugin calls to keep web builds compatible.

      // Request permission using permission_handler (works across platforms)
      final status = await ph.Permission.notification.request();

      NotificationPermissionResult result;
      if (status.isGranted) {
        result = NotificationPermissionResult.granted;
      } else if (status.isPermanentlyDenied) {
        result = NotificationPermissionResult.permanentlyDenied;
      } else if (status.isDenied) {
        result = NotificationPermissionResult.denied;
      } else {
        result = NotificationPermissionResult.notDetermined;
      }

      // Track permission result
      AnalyticsService.capture('notification_permission_request', {
        'result': result.name,
        'platform': f.kIsWeb
            ? 'web'
            : f.describeEnum(f.defaultTargetPlatform).toLowerCase(),
      });
      
      return result;
    } catch (e) {
      AnalyticsService.capture('notification_permission_error', {
        'error': e.toString(),
      });
      return NotificationPermissionResult.error;
    }
  }
  
  /// Get FCM token and register it server-side
  Future<String?> getAndRegisterToken() async {
    try {
      // Push messaging is disabled (Firebase removed). No token to register.
      AnalyticsService.capture('notification_push_disabled', {
        'platform': f.kIsWeb
            ? 'web'
            : f.describeEnum(f.defaultTargetPlatform).toLowerCase(),
      });
      return null;
    } catch (e) {
      AnalyticsService.capture('notification_token_error', {
        'error': e.toString(),
      });
      return null;
    }
  }
  
  /// Handle token refresh lifecycle
  void setupTokenRefreshListener() {
    // No-op: push messaging disabled
  }
  
  /// Register FCM token with Supabase backend
  Future<void> _registerTokenServerSide(String token) async {
    // No-op: push messaging disabled
  }
  
  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  /// Set up message handlers (no-op; push disabled)
  void _setupMessageHandlers() {
    // No-op: push messaging disabled
  }
  
  /// Handle foreground messages
  Future<void> _handleForegroundMessage(Map<String, dynamic> data) async {
    AnalyticsService.capture('notification_delivered', {
      'category': data['category'] ?? 'unknown',
      'state': 'foreground',
    });
  }
  
  /// Handle notification tap
  Future<void> _handleNotificationTap(dynamic message) async {
    // Kept for API compatibility; local notifications tap handled separately
  }
  
  /// Navigate to appropriate screen based on notification category
  void _navigateToScreen(String category) {
    // This would integrate with the app's navigation system
    // The deep link routes are already implemented according to the task file
    switch (category) {
      case 'routine_am':
      case 'routine_pm':
        // Navigate to routine screen with pre-filled context
        // GoRouter.of(context).go('/notifications/routine');
        break;
      case 'daily_log':
        // Navigate to diary logging screen
        // GoRouter.of(context).go('/notifications/log');
        break;
      case 'weekly_insights':
        // Navigate to insights screen
        // GoRouter.of(context).go('/notifications/insights');
        break;
    }
  }
  
  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and handle navigation
      // This would contain the same data as FCM message
    }
  }
  
  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'skincare_app_channel',
      'SkinCare App Notifications',
      channelDescription: 'Notifications for routine reminders and insights',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  /// Check current permission status
  Future<NotificationPermissionResult> getPermissionStatus() async {
    try {
      final status = await ph.Permission.notification.status;
      if (status.isGranted) return NotificationPermissionResult.granted;
      if (status.isPermanentlyDenied) return NotificationPermissionResult.permanentlyDenied;
      if (status.isDenied) return NotificationPermissionResult.denied;
      return NotificationPermissionResult.notDetermined;
    } catch (e) {
      return NotificationPermissionResult.error;
    }
  }
  
  /// Open app settings for notification permissions
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
  
  /// Set up local notifications fallback when push notifications are denied
  Future<void> setupLocalNotificationsFallback() async {
    try {
      await _localScheduler.scheduleAllNotifications();
      
      AnalyticsService.capture('local_notifications_fallback_enabled', {});
    } catch (e) {
      AnalyticsService.capture('local_notifications_fallback_error', {
        'error': e.toString(),
      });
      rethrow;
    }
  }
  
  /// Update notification schedules (both push and local)
  Future<void> updateNotificationSchedules() async {
    try {
      final permissionStatus = await getPermissionStatus();
      
      if (permissionStatus == NotificationPermissionResult.granted ||
          permissionStatus == NotificationPermissionResult.provisional) {
        // Push is disabled; schedule local notifications when allowed
        await _localScheduler.cancelAllNotifications();
        await _localScheduler.scheduleAllNotifications();
      } else {
        // Not allowed; ensure no local notifications are scheduled
        await _localScheduler.cancelAllNotifications();
      }
    } catch (e) {
      AnalyticsService.capture('notification_schedule_update_error', {
        'error': e.toString(),
      });
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(Map<String, dynamic> data) async {
  // Track delivery (background)
  AnalyticsService.capture('notification_delivered', {
    'category': data['category'] ?? 'unknown',
    'state': 'background',
  });
}

/// Notification permission result enum
enum NotificationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  provisional,
  notDetermined,
  error,
}
