import 'package:flutter/foundation.dart';

enum OnboardingStepKey {
  skinConcerns,
  skinType,
  routine,
  sensitivities,
  dietFlags,
  supplements,
  lifestyle,
  medications,
  consentInfo,
}

extension OnboardingStepKeyX on OnboardingStepKey {
  String get key => toString().split('.').last; // stable key string
}

class OnboardingValidators {
  static const allowedSkinTypes = {
    'normal', 'dry', 'oily', 'combination', 'sensitive'
  };
  static const allowedConcerns = {
    'acne', 'rosacea', 'hyperpigmentation', 'aging', 'dryness', 'oiliness', 'sensitivity'
  };
  static const allowedDietFlags = {
    'dairy', 'gluten', 'sugar', 'alcohol', 'caffeine'
  };
  static const allowedLifestyle = {
    'low sleep', 'high stress', 'low exercise', 'smoker', 'high sun exposure'
  };
  static const allowedSensitivities = {
    'fragrance', 'essential oils', 'alcohol', 'lanolin', 'dyes', 'parabens', 'sulfates'
  };
  static const allowedSupplements = {
    'zinc', 'omega-3', 'vitamin d', 'probiotics', 'collagen'
  };
  static const allowedMedications = {
    'adapalene', 'tretinoin', 'benzoyl peroxide', 'clindamycin', 'isotretinoin', 'spironolactone'
  };

  static bool validate(OnboardingStepKey step, Map<String, dynamic> payload) {
    switch (step) {
      case OnboardingStepKey.skinConcerns:
        final list = (payload['concerns'] as List?)?.cast<String>() ?? const [];
        // Allow any concerns, including custom user-entered ones. Require at least one.
        return list.isNotEmpty;
      case OnboardingStepKey.skinType:
        final v = payload['type'] as String?;
        return v != null && allowedSkinTypes.contains(v);
      case OnboardingStepKey.routine:
        // New format: {'am': [ {key,label,checked,freq}, ...], 'pm': [...], 'skip': bool}
        // Legacy format: boolean flags for known keys
        if (payload['skip'] == true) return true;
        final am = payload['am'];
        final pm = payload['pm'];
        bool anyCheckedInList(dynamic list) {
          if (list is List) {
            for (final e in list) {
              if (e is Map && (e['checked'] == true)) return true;
            }
          }
          return false;
        }
        if (am is List || pm is List) {
          return anyCheckedInList(am) || anyCheckedInList(pm);
        }
        // Fallback to legacy booleans
        final keys = ['cleanser', 'moisturizer', 'sunscreen', 'actives'];
        return keys.any((k) => payload[k] == true);
      case OnboardingStepKey.sensitivities:
        // List of ingredient triggers strings (optional); always valid
        return true;
      case OnboardingStepKey.dietFlags:
        // Allow any diet flags, including custom user-entered ones
        return true;
      case OnboardingStepKey.supplements:
        // Optional free-form list; always valid
        return true;
      case OnboardingStepKey.lifestyle:
        // Allow any lifestyle factors, including custom user-entered ones
        return true;
      case OnboardingStepKey.medications:
        // Optional strings; if present require non-empty names
        final list = (payload['medications'] as List?)?.cast<String>() ?? const [];
        return list.every((e) => e.trim().isNotEmpty);
      case OnboardingStepKey.consentInfo:
        // Require acknowledged = true
        return payload['acknowledged'] == true;
    }
  }
}

class OnboardingState extends ChangeNotifier {
  final List<OnboardingStepKey> steps = const [
    // OnboardingStepKey.skinConcerns, // Handled in new flow
    // OnboardingStepKey.skinType,     // Handled in new flow
    OnboardingStepKey.routine,
    OnboardingStepKey.sensitivities,
    OnboardingStepKey.dietFlags,
    OnboardingStepKey.supplements,
    OnboardingStepKey.lifestyle,
    OnboardingStepKey.medications,
    OnboardingStepKey.consentInfo,
  ];

  final Map<OnboardingStepKey, Map<String, dynamic>> _answers = {};

  Map<String, dynamic> getStepPayload(OnboardingStepKey step) =>
      _answers[step] ?? <String, dynamic>{};

  void setStepPayload(OnboardingStepKey step, Map<String, dynamic> payload) {
    _answers[step] = Map<String, dynamic>.from(payload);
    notifyListeners();
  }

  bool isStepValid(OnboardingStepKey step) =>
      OnboardingValidators.validate(step, getStepPayload(step));

  double get progress {
    if (steps.isEmpty) return 0;
    final validCount = steps.where(isStepValid).length;
    return validCount / steps.length;
  }

  Map<String, dynamic> toJson() => {
        for (final s in steps) s.key: getStepPayload(s),
      };
}
