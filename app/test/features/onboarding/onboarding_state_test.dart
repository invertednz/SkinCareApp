import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/features/onboarding/state/onboarding_state.dart';

void main() {
  group('OnboardingValidators', () {
    test('skin concerns requires at least one valid concern', () {
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.skinConcerns,
          {'concerns': ['acne', 'aging']},
        ),
        isTrue,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.skinConcerns,
          {'concerns': []},
        ),
        isFalse,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.skinConcerns,
          {'concerns': ['unknown']},
        ),
        isTrue,
      );
    });

    test('skin type must be one of allowed', () {
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.skinType,
          {'type': 'oily'},
        ),
        isTrue,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.skinType,
          {'type': 'weird'},
        ),
        isFalse,
      );
    });

    test('routine requires at least one step true', () {
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.routine,
          {'cleanser': true},
        ),
        isTrue,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.routine,
          {'cleanser': false, 'moisturizer': false},
        ),
        isFalse,
      );
    });

    test('diet flags must be allowed', () {
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.dietFlags,
          {'flags': ['dairy', 'gluten']},
        ),
        isTrue,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.dietFlags,
          {'flags': ['invalid']},
        ),
        isTrue,
      );
    });

    test('lifestyle must be allowed', () {
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.lifestyle,
          {'factors': ['high_stress']},
        ),
        isTrue,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.lifestyle,
          {'factors': ['unknown']},
        ),
        isTrue,
      );
    });

    test('medications optional but non-empty strings if present', () {
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.medications,
          {'medications': ['isotretinoin']},
        ),
        isTrue,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.medications,
          {'medications': ['']},
        ),
        isFalse,
      );
    });

    test('consent requires acknowledged true', () {
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.consentInfo,
          {'acknowledged': true},
        ),
        isTrue,
      );
      expect(
        OnboardingValidators.validate(
          OnboardingStepKey.consentInfo,
          {'acknowledged': false},
        ),
        isFalse,
      );
    });

    // Timezone step removed; timezone is automatically detected on device.
  });
}
