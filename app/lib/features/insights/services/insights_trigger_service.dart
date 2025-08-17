import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/analytics_service.dart';
import '../../../services/error_handler.dart';
import '../data/insights_repository.dart';

/// Service to handle insights generation triggers and cooldown logic
class InsightsTriggerService {
  static final InsightsTriggerService _instance = InsightsTriggerService._internal();
  factory InsightsTriggerService() => _instance;
  InsightsTriggerService._internal();

  static InsightsTriggerService get instance => _instance;

  final InsightsRepository _repository = InsightsRepository.instance;
  // Use static analytics methods

  /// Trigger insights generation after a diary log is created
  Future<void> triggerAfterLogCreation({
    required String logType, // 'skin_health', 'symptoms', 'diet', etc.
    bool hasSignificantData = false,
  }) async {
    try {
      // Track the trigger attempt
      AnalyticsService.capture('insights_generate_request', {
        'trigger_type': 'post_log',
        'log_type': logType,
        'has_significant_data': hasSignificantData,
        'can_refresh': _repository.canRefresh,
      });

      // Check if we can generate insights (cooldown logic)
      if (!_repository.canRefresh && !hasSignificantData) {
        if (kDebugMode) {
          debugPrint('Insights generation skipped - cooldown active and no significant data');
        }
        
        AnalyticsService.capture('insights_generate_rate_limited', {
          'trigger_type': 'post_log',
          'reason': 'cooldown_active',
        });
        return;
      }

      // Generate insights
      await _repository.generateInsights(forceRefresh: hasSignificantData);
      
      AnalyticsService.capture('insights_generate_success', {
        'trigger_type': 'post_log',
        'log_type': logType,
        'forced': hasSignificantData,
      });

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Insights trigger after log creation failed: $e');
      }
      
      AnalyticsService.capture('insights_generate_error', {
        'trigger_type': 'post_log',
        'error': ErrorHandler.getUserFriendlyMessage(e),
      });
    }
  }

  /// Trigger insights generation manually (on-demand)
  Future<bool> triggerManualRefresh({
    bool bypassCooldown = false,
  }) async {
    try {
      // Track the manual trigger attempt
      AnalyticsService.capture('insights_generate_request', {
        'trigger_type': 'manual',
        'bypass_cooldown': bypassCooldown,
        'can_refresh': _repository.canRefresh,
      });

      // Check cooldown unless bypassed
      if (!bypassCooldown && !_repository.canRefresh) {
        if (kDebugMode) {
          debugPrint('Manual insights refresh blocked by cooldown');
        }
        
        AnalyticsService.capture('insights_generate_rate_limited', {
          'trigger_type': 'manual',
          'reason': 'cooldown_active',
        });
        return false;
      }

      // Generate insights
      await _repository.generateInsights(forceRefresh: bypassCooldown);
      
      AnalyticsService.capture('insights_generate_success', {
        'trigger_type': 'manual',
        'bypassed_cooldown': bypassCooldown,
      });

      return true;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Manual insights refresh failed: $e');
      }
      
      AnalyticsService.capture('insights_generate_error', {
        'trigger_type': 'manual',
        'error': ErrorHandler.getUserFriendlyMessage(e),
      });
      
      return false;
    }
  }

  /// Check if there's significant new data that warrants bypassing cooldown
  /// This is a heuristic based on recent activity
  Future<bool> hasSignificantNewData() async {
    try {
      // This would typically check:
      // 1. Number of new entries since last insights generation
      // 2. Types of entries (photos might be more significant)
      // 3. Time since last generation vs amount of new data
      
      // For now, return false - this will be implemented when diary logging is complete
      // TODO: Implement significant data detection logic
      return false;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking for significant new data: $e');
      }
      return false;
    }
  }

  /// Get cooldown status information
  Map<String, dynamic> getCooldownStatus() {
    final lastGenerated = _repository.lastGenerated;
    if (lastGenerated == null) {
      return {
        'can_refresh': true,
        'cooldown_active': false,
        'time_remaining': 0,
        'last_generated': null,
      };
    }

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final canRefresh = lastGenerated.isBefore(oneHourAgo);
    
    final timeRemaining = canRefresh 
        ? 0 
        : const Duration(hours: 1).inSeconds - now.difference(lastGenerated).inSeconds;

    return {
      'can_refresh': canRefresh,
      'cooldown_active': !canRefresh,
      'time_remaining': timeRemaining,
      'last_generated': lastGenerated.toIso8601String(),
    };
  }

  /// Format cooldown remaining time for UI display
  String formatCooldownRemaining() {
    final status = getCooldownStatus();
    if (status['can_refresh'] == true) {
      return 'Ready to refresh';
    }

    final timeRemaining = status['time_remaining'] as int;
    if (timeRemaining <= 0) {
      return 'Ready to refresh';
    }

    final minutes = (timeRemaining / 60).ceil();
    if (minutes < 60) {
      return 'Available in ${minutes}m';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return 'Available in ${hours}h';
      } else {
        return 'Available in ${hours}h ${remainingMinutes}m';
      }
    }
  }

  /// Dispose of any resources
  void dispose() {
    // Currently no resources to dispose
  }
}
