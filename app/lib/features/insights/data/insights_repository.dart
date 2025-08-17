import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/error_handler.dart';
import '../../../services/analytics.dart';
import '../../../services/analytics_events.dart';

/// Data models for insights
class InsightsSummary {
  final String overallAssessment;
  final List<String> keyTrends;
  final String? dataQualityNote;

  const InsightsSummary({
    required this.overallAssessment,
    required this.keyTrends,
    this.dataQualityNote,
  });

  factory InsightsSummary.fromJson(Map<String, dynamic> json) {
    return InsightsSummary(
      overallAssessment: json['overall_assessment'] ?? '',
      keyTrends: List<String>.from(json['key_trends'] ?? []),
      dataQualityNote: json['data_quality_note'],
    );
  }
}

class InsightsRecommendation {
  final String category; // 'continue', 'start', 'stop'
  final String title;
  final String rationale;
  final String confidenceLevel; // 'high', 'medium', 'low'
  final int priority; // 1-5

  const InsightsRecommendation({
    required this.category,
    required this.title,
    required this.rationale,
    required this.confidenceLevel,
    required this.priority,
  });

  factory InsightsRecommendation.fromJson(Map<String, dynamic> json) {
    return InsightsRecommendation(
      category: json['category'] ?? 'continue',
      title: json['title'] ?? '',
      rationale: json['rationale'] ?? '',
      confidenceLevel: json['confidence_level'] ?? 'low',
      priority: json['priority'] ?? 3,
    );
  }
}

class InsightsActionPlan {
  final List<String> immediateActions;
  final List<String> weeklyGoals;
  final List<String> monitoringFocus;

  const InsightsActionPlan({
    required this.immediateActions,
    required this.weeklyGoals,
    required this.monitoringFocus,
  });

  factory InsightsActionPlan.fromJson(Map<String, dynamic> json) {
    return InsightsActionPlan(
      immediateActions: List<String>.from(json['immediate_actions'] ?? []),
      weeklyGoals: List<String>.from(json['weekly_goals'] ?? []),
      monitoringFocus: List<String>.from(json['monitoring_focus'] ?? []),
    );
  }
}

class InsightsDataPeriod {
  final String startDate;
  final String endDate;
  final int daysAnalyzed;

  const InsightsDataPeriod({
    required this.startDate,
    required this.endDate,
    required this.daysAnalyzed,
  });

  factory InsightsDataPeriod.fromJson(Map<String, dynamic> json) {
    return InsightsDataPeriod(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      daysAnalyzed: json['days_analyzed'] ?? 0,
    );
  }
}

class InsightsData {
  final InsightsSummary summary;
  final List<InsightsRecommendation> recommendations;
  final InsightsActionPlan actionPlan;
  final DateTime generatedAt;
  final InsightsDataPeriod dataPeriod;
  final String disclaimer;

  const InsightsData({
    required this.summary,
    required this.recommendations,
    required this.actionPlan,
    required this.generatedAt,
    required this.dataPeriod,
    required this.disclaimer,
  });

  factory InsightsData.fromJson(Map<String, dynamic> json) {
    return InsightsData(
      summary: InsightsSummary.fromJson(json['summary'] ?? {}),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((r) => InsightsRecommendation.fromJson(r))
          .toList() ?? [],
      actionPlan: InsightsActionPlan.fromJson(json['action_plan'] ?? {}),
      generatedAt: DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
      dataPeriod: InsightsDataPeriod.fromJson(json['data_period'] ?? {}),
      disclaimer: json['disclaimer'] ?? '',
    );
  }

  /// Get recommendations by category
  List<InsightsRecommendation> getRecommendationsByCategory(String category) {
    return recommendations
        .where((r) => r.category == category)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Get continue recommendations
  List<InsightsRecommendation> get continueRecommendations =>
      getRecommendationsByCategory('continue');

  /// Get start recommendations
  List<InsightsRecommendation> get startRecommendations =>
      getRecommendationsByCategory('start');

  /// Get stop recommendations
  List<InsightsRecommendation> get stopRecommendations =>
      getRecommendationsByCategory('stop');
}

/// Repository for managing insights data
class InsightsRepository extends ChangeNotifier {
  InsightsData? _currentInsights;
  bool _loading = false;
  String? _error;
  DateTime? _lastGenerated;

  static final InsightsRepository _instance = InsightsRepository._internal();
  factory InsightsRepository() => _instance;
  InsightsRepository._internal();

  static InsightsRepository get instance => _instance;

  InsightsData? get currentInsights => _currentInsights;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastGenerated => _lastGenerated;

  /// Check if insights can be refreshed (cooldown logic)
  bool get canRefresh {
    if (_lastGenerated == null) return true;
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _lastGenerated!.isBefore(oneHourAgo);
  }

  /// Generate new insights
  Future<void> generateInsights({bool forceRefresh = false}) async {
    if (_loading) return;

    if (!forceRefresh && !canRefresh) {
      _error = 'Please wait before requesting new insights. Last generated: ${_formatTime(_lastGenerated!)}';
      
      // Track rate limited event
      AnalyticsService.capture(AnalyticsEvents.insightsGenerateRateLimited, {
        'last_generated': _lastGenerated?.toIso8601String(),
        'cooldown_remaining_minutes': (60 - DateTime.now().difference(_lastGenerated!).inMinutes).clamp(0, 60),
      });
      
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    // Track generate request
    AnalyticsService.capture(AnalyticsEvents.insightsGenerateRequest, {
      'force_refresh': forceRefresh,
      'has_cached_insights': _currentInsights != null,
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Call the insights-generate Edge Function
      final response = await supabase.functions.invoke(
        'insights-generate',
        body: {
          'force_refresh': forceRefresh,
          'debug': kDebugMode,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        throw Exception(errorData['error'] ?? 'Failed to generate insights');
      }

      final insightsData = InsightsData.fromJson(response.data);
      _currentInsights = insightsData;
      _lastGenerated = insightsData.generatedAt;
      _error = null;

      // Track successful generation
      AnalyticsService.capture(AnalyticsEvents.insightsGenerateSuccess, {
        'recommendations_count': insightsData.recommendations.length,
        'data_period_days': insightsData.dataPeriod.daysAnalyzed,
        'generation_time': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      _error = ErrorHandler.getUserFriendlyMessage(e);
      if (kDebugMode) {
        debugPrint('Insights generation error: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load cached insights from database
  Future<void> loadCachedInsights() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      
      // Get the most recent cached insights
      final response = await supabase
          .from('insights')
          .select('*')
          .order('generated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        // Reconstruct the insights data from cached format
        final cachedData = {
          'summary': response['summary'],
          'recommendations': response['recommendations'],
          'action_plan': response['action_plan'],
          'data_period': response['data_period'],
          'generated_at': response['generated_at'],
          'disclaimer': 'These insights are AI-generated suggestions based on your logged data and should not replace professional medical advice. Always consult with a dermatologist for serious skin concerns.',
        };

        _currentInsights = InsightsData.fromJson(cachedData);
        _lastGenerated = DateTime.tryParse(response['generated_at']) ?? DateTime.now();
      }

      _error = null;

    } catch (e) {
      _error = ErrorHandler.getUserFriendlyMessage(e);
      if (kDebugMode) {
        debugPrint('Load cached insights error: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear current insights
  void clearInsights() {
    _currentInsights = null;
    _lastGenerated = null;
    _error = null;
    notifyListeners();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
