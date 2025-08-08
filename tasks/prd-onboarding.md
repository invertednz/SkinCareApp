# Onboarding PRD

## Overview
After authentication, users complete an onboarding flow to collect baseline information for personalization and insights. Use the mockups as guidance but prioritize functionality over visuals. The flow should be concise (7–10 steps) and require completion before hitting the paywall and main app.

## Goals
- Collect key profile data to power insights, recommendations, and chat personalization.
- Keep the flow fast and mobile-optimized with clear progress indication.
- Store structured answers in Supabase with strict RLS.

## User Stories
- As a new user, I can answer questions about my skin so I get personalized recommendations.
- As a new user, I understand what data is collected and why.
- As a returning user, I can review and edit my onboarding answers later in Settings/Profile.

## Functional Requirements
1. Onboarding starts immediately after first successful authentication.
2. Steps and inputs (exact wording TBC):
   - Primary skin concerns (multi-select): acne, redness/irritation, dryness/flakiness, texture, hyperpigmentation, sensitivity.
   - Skin type (single select): dry, normal, combination, oily, sensitive, not sure.
   - Current routine (repeatable list; AM/PM; product name, type, actives, frequency).
   - Known sensitivities/allergies (multi-select + free text): fragrance, AHAs, BHAs, retinoids, essential oils, sunscreen filters, other.
   - Diet flags (multi-select): dairy, gluten, sugar, spicy, processed, alcohol, caffeine, other.
   - Supplements (repeatable list; name, dosage, frequency, purpose).
   - Lifestyle: average sleep hours (slider), stress level (1–5).
   - Medications/conditions relevant to skin (free text optional).
   - Consent: photo analysis and storage consent. Note: implicit consent also occurs upon upload; surface rationale.
   - Location/timezone (auto or select) for reminders and scheduling.
3. Progress UI with step indicator and the ability to go back; no hard skip, but allow “Prefer not to say” for non-critical items.
4. Validation: required fields for concerns, skin type, and consent; others optional but encouraged.
5. Save draft between steps; resume on app restart.
6. Completion sets `onboarding_completed_at` on the user profile.
7. Immediately route to Paywall after onboarding completion.

## Data Model
- `profiles` (user_id PK, timezone, onboarding_completed_at, ...)
- `onboarding_answers` (user_id FK, key, value_json, created_at)
- `routines` seed from onboarding current routine (optional)
- RLS: user_id = auth.uid(); block access to other users’ data.

## Non-Goals
- Deep clinical history beyond high-level items.
- Extensive product database import during onboarding.

## Technical Considerations
- Flutter: wizard with Riverpod/Provider state; persists step data locally until saved.
- Supabase: upsert on each step to avoid data loss.
- Accessibility: larger touch targets; clear labels.

## Success Metrics
- >85% onboarding completion after start.
- Median completion time < 4 minutes.

## Open Questions
- Final wording and ordering of questions.
- Which items are strictly mandatory beyond consent, concerns, and skin type?
