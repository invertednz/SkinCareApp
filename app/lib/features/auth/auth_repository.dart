import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analytics.dart';
import '../../services/analytics_events.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signInWithPassword({required String email, required String password}) async {
    try {
      AnalyticsService.capture(AnalyticsEvents.authStart, {
        AnalyticsProperties.authMethod: 'email_password',
      });
      
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      
      if (response.user != null) {
        AnalyticsService.capture(AnalyticsEvents.authSuccess, {
          AnalyticsProperties.authMethod: 'email_password',
        });
      } else {
        AnalyticsService.capture(AnalyticsEvents.authFailure, {
          AnalyticsProperties.authMethod: 'email_password',
          AnalyticsProperties.errorCode: 'no_user_returned',
        });
      }
      
      return response;
    } catch (e) {
      AnalyticsService.capture(AnalyticsEvents.authFailure, {
        AnalyticsProperties.authMethod: 'email_password',
        AnalyticsProperties.error: e.toString(),
        AnalyticsProperties.errorCode: e.runtimeType.toString(),
      });
      rethrow;
    }
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    try {
      AnalyticsService.capture(AnalyticsEvents.authStart, {
        AnalyticsProperties.authMethod: 'email_signup',
      });
      
      final response = await _client.auth.signUp(email: email, password: password);
      
      if (response.user != null) {
        AnalyticsService.capture(AnalyticsEvents.authSuccess, {
          AnalyticsProperties.authMethod: 'email_signup',
        });
      } else {
        AnalyticsService.capture(AnalyticsEvents.authFailure, {
          AnalyticsProperties.authMethod: 'email_signup',
          AnalyticsProperties.errorCode: 'no_user_returned',
        });
      }
      
      return response;
    } catch (e) {
      AnalyticsService.capture(AnalyticsEvents.authFailure, {
        AnalyticsProperties.authMethod: 'email_signup',
        AnalyticsProperties.error: e.toString(),
        AnalyticsProperties.errorCode: e.runtimeType.toString(),
      });
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      AnalyticsService.capture(AnalyticsEvents.authSignOut);
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      // Still track the attempt even if it fails
      AnalyticsService.capture(AnalyticsEvents.authSignOut, {
        AnalyticsProperties.error: e.toString(),
      });
      rethrow;
    }
  }

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  // Bridge to go_router guards
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
