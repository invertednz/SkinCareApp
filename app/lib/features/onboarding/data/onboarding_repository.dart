import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/onboarding_state.dart';

class OnboardingRepository {
  OnboardingRepository._();
  static final OnboardingRepository instance = OnboardingRepository._();

  SupabaseClient get _db => Supabase.instance.client;

  String _stepKey(OnboardingStepKey step) => step.key;

  Future<void> upsertStep(OnboardingStepKey step, Map<String, dynamic> payload) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      // In debug/mock mode, skip remote upsert when no user
      if (kDebugMode) return;
      throw StateError('Not signed in');
    }
    await _db.from('onboarding_answers').upsert({
      'user_id': user.id,
      'step_key': _stepKey(step),
      'payload': payload,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> fetchStep(OnboardingStepKey step) async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    final res = await _db
        .from('onboarding_answers')
        .select('payload')
        .eq('user_id', user.id)
        .eq('step_key', _stepKey(step))
        .maybeSingle();
    return (res == null) ? null : (res['payload'] as Map<String, dynamic>?);
  }

  Future<Map<OnboardingStepKey, Map<String, dynamic>>> fetchAll() async {
    final user = _db.auth.currentUser;
    if (user == null) return {};
    final rows = await _db
        .from('onboarding_answers')
        .select('step_key, payload')
        .eq('user_id', user.id);
    final Map<OnboardingStepKey, Map<String, dynamic>> out = {};
    for (final row in rows as List) {
      final keyStr = row['step_key'] as String;
      final payload = (row['payload'] as Map).cast<String, dynamic>();
      final step = OnboardingStepKey.values.firstWhere(
        (e) => e.key == keyStr,
        orElse: () => OnboardingStepKey.consentInfo, // default fallback
      );
      out[step] = payload;
    }
    return out;
  }
}
