import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_mode.dart';

class SessionService extends ChangeNotifier {
  Session? _session;
  bool _initialized = false;
  StreamSubscription<AuthState>? _sub;
  bool _mockSignedIn = false; // debug-only mock auth

  static final SessionService instance = SessionService._();
  SessionService._() {
    if (DataModeService.isSupabase) {
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
    } else {
      _session = null;
      _initialized = true;
    }
  }

  /// Rebind to Supabase auth after Supabase.initialize() has been called.
  void rebind() {
    if (!DataModeService.isSupabase) {
      notifyListeners();
      return;
    }
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

  /// Helper to simulate signed-in state without Supabase auth.
  /// Always allowed in mock/firebase modes; restricted to debug otherwise.
  void setMockSignedIn(bool value) {
    if (!kDebugMode && DataModeService.isSupabase) return;
    _mockSignedIn = value;
    notifyListeners();
  }
}
