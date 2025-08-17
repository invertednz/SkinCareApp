import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/onboarding_state.dart';

class OnboardingDraftStore {
  static const _key = 'onboarding_draft_v1';
  OnboardingDraftStore._();
  static final OnboardingDraftStore instance = OnboardingDraftStore._();

  Future<Map<OnboardingStepKey, Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final out = <OnboardingStepKey, Map<String, dynamic>>{};
    for (final s in OnboardingStepKey.values) {
      final payload = map[s.key];
      if (payload is Map) {
        out[s] = payload.cast<String, dynamic>();
      }
    }
    return out;
  }

  Future<void> saveStep(OnboardingStepKey step, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final map = raw == null ? <String, dynamic>{} : (jsonDecode(raw) as Map).cast<String, dynamic>();
    map[step.key] = payload;
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
