import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'analytics_events.dart';

/// Singleton analytics service that wraps Mixpanel functionality
class AnalyticsService {
  static AnalyticsService? _instance;
  static bool _enabled = false;
  static bool _optedOut = false;
  static Mixpanel? _client;

  AnalyticsService._();

  /// Get the singleton instance
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  /// Factory constructor for easy instantiation
  factory AnalyticsService() => instance;

  /// Initialize analytics with API key and optional host override
  static Future<void> init({String? apiKey, String? host}) async {
    try {
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('Analytics disabled: missing API key');
        _enabled = false;
        return;
      }

      // Initialize Mixpanel client
      final client = await Mixpanel.init(
        apiKey,
        trackAutomaticEvents: true,
        optOutTrackingDefault: false,
      );

      if (host != null && host.isNotEmpty) {
        client.setServerURL(host);
      }

      client.setLoggingEnabled(kDebugMode);
      _client = client;
      _enabled = true;
      debugPrint('Analytics initialized successfully');
      
      // Track app launch
      capture(AnalyticsEvents.appLaunch);
      
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Analytics initialization failed: $error');
      }
      _enabled = false;
      _client = null;
    }
  }

  /// Track screen views
  void screenView(String name) {
    try {
      if (!_enabled || _optedOut) return;
      
      // Filter out any PII/PHI from screen names
      final sanitizedName = _sanitizeString(name);
      
      captureEvent(
        AnalyticsEvents.screenView,
        {
          'screen_name': sanitizedName,
        },
      );
      
      if (kDebugMode) {
        debugPrint('Analytics screen view: $sanitizedName');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Analytics screen view failed: $error');
      }
    }
  }

  /// Capture analytics events (instance method)
  void captureEvent(String event, [Map<String, Object?>? properties]) {
    try {
      if (!_enabled || _optedOut) return;
      
      // Sanitize event name and properties
      final sanitizedEvent = _sanitizeString(event);
      final sanitizedProperties = _sanitizeProperties(properties ?? {});
      
      // Add standard properties
      final finalProperties = <String, Object>{
        ...sanitizedProperties.cast<String, Object>(),
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
      };
      
      _client?.track(sanitizedEvent, properties: finalProperties);
      
      if (kDebugMode) {
        debugPrint('Analytics capture: $sanitizedEvent with ${finalProperties.length} properties');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Analytics capture failed: $error');
      }
    }
  }

  /// Static version of capture for backwards compatibility
  static void capture(String event, [Map<String, Object?>? properties]) {
    instance.captureEvent(event, properties);
  }

  /// Set analytics opt-out status
  void setOptOut(bool optOut) {
    _optedOut = optOut;
    if (_enabled) {
      if (optOut) {
        _client?.optOutTracking();
      } else {
        _client?.optInTracking();
      }
    }
    if (kDebugMode) {
      debugPrint('Analytics opt-out: $optOut');
    }
  }

  /// Get current opt-out status
  bool get isOptedOut => _optedOut;

  /// Check if analytics is enabled and user hasn't opted out
  bool get isActive => _enabled && !_optedOut;

  /// Sanitize string to remove potential PII/PHI
  String _sanitizeString(String input) {
    // Remove email patterns
    String sanitized = input.replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '[email]');
    
    // Remove phone patterns
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'), '[phone]');
    
    // Remove potential user IDs (long alphanumeric strings)
    sanitized = sanitized.replaceAll(RegExp(r'\b[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\b'), '[uuid]');
    
    return sanitized;
  }

  /// Sanitize properties map to remove PII/PHI
  Map<String, Object?> _sanitizeProperties(Map<String, Object?> properties) {
    final sanitized = <String, Object?>{};
    
    for (final entry in properties.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      // Skip potentially sensitive keys
      if (_isSensitiveKey(key)) {
        continue;
      }
      
      // Sanitize string values
      if (value is String) {
        sanitized[entry.key] = _sanitizeString(value);
      } else if (value is num || value is bool || value == null) {
        sanitized[entry.key] = value;
      } else {
        // Convert other types to string and sanitize
        sanitized[entry.key] = _sanitizeString(value.toString());
      }
    }
    
    return sanitized;
  }

  /// Check if a property key is potentially sensitive
  bool _isSensitiveKey(String key) {
    const sensitiveKeys = {
      'email', 'phone', 'name', 'address', 'ssn', 'password', 'token',
      'secret', 'key', 'auth', 'personal', 'private', 'medical', 'health',
      'symptom', 'condition', 'medication', 'treatment', 'diagnosis'
    };
    
    return sensitiveKeys.any((sensitive) => key.contains(sensitive));
  }
}
