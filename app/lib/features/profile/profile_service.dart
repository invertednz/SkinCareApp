import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/session.dart';

class ProfileService extends ChangeNotifier {
  bool? _onboardingCompleted;
  bool? _hasActiveSubscription; // Stub for now; integrate payment later
  bool _loading = false;
  Object? _lastError;

  static final ProfileService instance = ProfileService._();
  ProfileService._();

  bool get loading => _loading;
  bool? get onboardingCompleted => _onboardingCompleted;
  bool get hasActiveSubscription => _hasActiveSubscription ?? false; // default to false
  Object? get lastError => _lastError;

  SessionService? _sessionService;
  VoidCallback? _sessionListener;

  void rebind(SessionService session) {
    // Remove old listener
    if (_sessionService != null && _sessionListener != null) {
      _sessionService!.removeListener(_sessionListener!);
    }
    _sessionService = session;
    _sessionListener = () {
      // On auth state change, refetch or clear
      if (_sessionService!.isSignedIn) {
        unawaited(fetchProfile());
      } else {
        _onboardingCompleted = null;
        _hasActiveSubscription = null;
        notifyListeners();
      }
    };
    _sessionService!.addListener(_sessionListener!);
    // Initial state
    if (session.isSignedIn) {
      unawaited(fetchProfile());
    }
  }

  Future<void> fetchProfile() async {
    try {
      _loading = true;
      _lastError = null;
      notifyListeners();
      // Debug mock mode: default to not onboarded and no subscription
      if (SessionService.instance.isMockSignedIn) {
        _onboardingCompleted = false;
        _hasActiveSubscription = false;
        return;
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _onboardingCompleted = null;
        _hasActiveSubscription = null;
        return;
      }
      // Special bypass: skip onboarding for specific test account
      final email = user.email?.toLowerCase();
      if (email == 'skip@gmail.com') {
        _onboardingCompleted = true;
        // Keep subscription gating unchanged (still false by default)
        _hasActiveSubscription = false;
        return;
      }
      final data = await Supabase.instance.client
          .from('profiles')
          .select('onboarding_completed_at')
          .eq('user_id', user.id)
          .maybeSingle();
      final completedAt = data == null ? null : data['onboarding_completed_at'];
      _onboardingCompleted = completedAt != null;
      // Subscription stub: always false until payment integration
      _hasActiveSubscription = false;
    } catch (e) {
      _lastError = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markOnboardingCompleted() async {
    try {
      // Debug mock mode: mark locally without network
      if (SessionService.instance.isMockSignedIn) {
        _onboardingCompleted = true;
        notifyListeners();
        return;
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client
          .from('profiles')
          .update({'onboarding_completed_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id);
      _onboardingCompleted = true;
      notifyListeners();
    } catch (e) {
      _lastError = e;
      notifyListeners();
      rethrow; // Let caller handle the error
    }
  }

  // Debug helper: simulate subscription state in development only
  void setSubscriptionForDebug(bool value) {
    if (!kDebugMode) return;
    _hasActiveSubscription = value;
    notifyListeners();
  }
}
