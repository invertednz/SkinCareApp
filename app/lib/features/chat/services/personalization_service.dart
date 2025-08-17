import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PersonalizationContext {
  final String userProfileSummary;
  final List<Map<String, dynamic>> recentLogs;
  final Map<String, dynamic>? latestInsights;
  final DateTime contextGeneratedAt;

  PersonalizationContext({
    required this.userProfileSummary,
    required this.recentLogs,
    this.latestInsights,
    required this.contextGeneratedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_profile_summary': userProfileSummary,
      'recent_logs': recentLogs,
      'latest_insights': latestInsights,
      'context_generated_at': contextGeneratedAt.toIso8601String(),
    };
  }
}

class PersonalizationService {
  final SupabaseClient _supabase;

  PersonalizationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // Task 4.1: Fetch recent logs (14–30 days) and latest insights summary
  Future<PersonalizationContext?> getPersonalizationContext({
    bool personalizationEnabled = true,
    int lookbackDays = 14,
  }) async {
    if (!personalizationEnabled) {
      return null;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final lookbackDate = now.subtract(Duration(days: lookbackDays));

      // Fetch recent diary logs
      final recentLogs = await _fetchRecentLogs(user.id, lookbackDate);
      
      // Fetch latest insights
      final latestInsights = await _fetchLatestInsights(user.id);
      
      // Generate user profile summary
      final profileSummary = _generateProfileSummary(recentLogs, latestInsights);

      return PersonalizationContext(
        userProfileSummary: profileSummary,
        recentLogs: recentLogs,
        latestInsights: latestInsights,
        contextGeneratedAt: now,
      );
    } catch (e) {
      debugPrint('Failed to get personalization context: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentLogs(String userId, DateTime since) async {
    try {
      // TODO: Implement actual diary logs fetching
      // For now, return empty list as diary logging structure may not be fully implemented
      // In a real implementation, you would:
      // 1. Query diary_entries table for recent entries
      // 2. Include relevant fields like symptoms, routines, products used
      // 3. Limit to prevent token overflow
      
      final response = await _supabase
          .from('diary_entries')
          .select('*')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Failed to fetch recent logs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestInsights(String userId) async {
    try {
      // Fetch the most recent insights
      final response = await _supabase
          .from('insights')
          .select('summary, recommendations, action_plan, generated_at')
          .eq('user_id', userId)
          .order('generated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Failed to fetch latest insights: $e');
      return null;
    }
  }

  // Task 4.2: Summarize profile to brief context; trim to token budget
  String _generateProfileSummary(List<Map<String, dynamic>> recentLogs, Map<String, dynamic>? insights) {
    final summary = StringBuffer();
    
    // Add basic context
    summary.writeln('User Profile Context:');
    
    // Add recent activity summary
    if (recentLogs.isNotEmpty) {
      summary.writeln('- Recent activity: ${recentLogs.length} diary entries in the past 14 days');
      
      // Summarize common patterns (simplified for now)
      final routineEntries = recentLogs.where((log) => log['routine_completed'] == true).length;
      if (routineEntries > 0) {
        summary.writeln('- Routine adherence: $routineEntries/${recentLogs.length} days');
      }
      
      // Add any notable symptoms or concerns
      final symptomsReported = recentLogs.where((log) => 
        log['symptoms'] != null && (log['symptoms'] as List).isNotEmpty
      ).length;
      if (symptomsReported > 0) {
        summary.writeln('- Symptoms reported: $symptomsReported days');
      }
    } else {
      summary.writeln('- Limited recent activity data');
    }
    
    // Add insights summary if available
    if (insights != null) {
      final insightsSummary = insights['summary'] as Map<String, dynamic>?;
      if (insightsSummary != null) {
        final assessment = insightsSummary['overall_assessment'] as String?;
        if (assessment != null && assessment.isNotEmpty) {
          summary.writeln('- Latest insights: ${assessment.substring(0, assessment.length > 100 ? 100 : assessment.length)}${assessment.length > 100 ? '...' : ''}');
        }
      }
    }
    
    // Keep summary concise to fit token budget
    final result = summary.toString();
    return result.length > 500 ? '${result.substring(0, 497)}...' : result;
  }

  // Task 4.3: Respect settings toggle; exclude sensitive/PII
  Map<String, dynamic> sanitizeContextForAI(PersonalizationContext context) {
    // Remove any potentially sensitive information before sending to AI
    final sanitizedLogs = context.recentLogs.map((log) {
      final sanitized = Map<String, dynamic>.from(log);
      
      // Remove any PII fields
      sanitized.remove('user_id');
      sanitized.remove('email');
      sanitized.remove('phone');
      sanitized.remove('full_name');
      
      // Keep only relevant skincare data
      return {
        'date': sanitized['created_at'],
        'routine_completed': sanitized['routine_completed'],
        'symptoms': sanitized['symptoms'],
        'products_used': sanitized['products_used'],
        'notes': sanitized['notes'] != null ? 
          (sanitized['notes'] as String).length > 100 ? 
            '${(sanitized['notes'] as String).substring(0, 97)}...' : 
            sanitized['notes'] : null,
      };
    }).toList();

    return {
      'profile_summary': context.userProfileSummary,
      'recent_logs_count': sanitizedLogs.length,
      'has_recent_insights': context.latestInsights != null,
      'context_date': context.contextGeneratedAt.toIso8601String(),
      // Include only essential log data to stay within token limits
      'recent_patterns': _extractPatterns(sanitizedLogs),
    };
  }

  Map<String, dynamic> _extractPatterns(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return {};
    
    final patterns = <String, dynamic>{};
    
    // Calculate routine adherence
    final routineCompletedCount = logs.where((log) => log['routine_completed'] == true).length;
    patterns['routine_adherence_rate'] = routineCompletedCount / logs.length;
    
    // Count symptom frequency
    final symptomsCount = logs.where((log) => 
      log['symptoms'] != null && (log['symptoms'] as List).isNotEmpty
    ).length;
    patterns['symptoms_frequency'] = symptomsCount / logs.length;
    
    // Most recent entry date
    if (logs.isNotEmpty) {
      patterns['last_entry_date'] = logs.first['date'];
    }
    
    return patterns;
  }
}
