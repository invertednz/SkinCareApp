import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService extends ChangeNotifier {
  Session? _session;
  bool _initialized = false;
  StreamSubscription<AuthState>? _sub;
  bool _mockSignedIn = false; // debug-only mock auth

  static final SessionService instance = SessionService._();
  SessionService._() {
    try {
      _session = Supabase.instance.client.auth.currentSession;
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        _session = event.session;
        notifyListeners();
      });
    } catch (_) {
      // Supabase not initialized; operate in signed-out mode without subscription.
      _session = null;
    } finally {
      _initialized = true;
    }
  }

  /// Rebind to Supabase auth after Supabase.initialize() has been called.
  void rebind() {
    try {
      _sub?.cancel();
      _session = Supabase.instance.client.auth.currentSession;
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        _session = event.session;
        notifyListeners();
      });
      notifyListeners();
    } catch (_) {
      // If still not initialized, ignore.
    }
  }

  bool get initialized => _initialized;
  Session? get session => _session;
  bool get isSignedIn => _mockSignedIn || _session != null;
  bool get isMockSignedIn => _mockSignedIn;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Debug helper to simulate signed-in state without Supabase auth.
  void setMockSignedIn(bool value) {
    if (!kDebugMode) return;
    _mockSignedIn = value;
    notifyListeners();
  }
}
