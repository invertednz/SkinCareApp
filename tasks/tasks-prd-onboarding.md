## Relevant Files

- `app/lib/features/onboarding/presentation/onboarding_wizard.dart` - Multi-step onboarding UI.
- `app/lib/features/onboarding/state/onboarding_state.dart` - State management for onboarding steps.
- `app/lib/features/onboarding/data/onboarding_repository.dart` - Persistence to Supabase.
- `app/lib/router/app_router.dart` - Route to paywall after completion.
- `app/lib/services/analytics.dart` - Onboarding analytics events.
- `supabase/schema.sql` - `profiles`, `onboarding_answers` tables + RLS.

### Notes

- Persist drafts locally and upsert to Supabase per step to avoid data loss.

## Tasks

- [x] 1.0 Define onboarding steps, schema, and validation
  - [x] 1.1 Enumerate steps: skin concerns, skin type, current routine, sensitivities, diet flags, supplements, lifestyle, medications, consent info, timezone
  - [x] 1.2 Define `onboarding_answers` schema (user_id, step_key, payload JSONB, updated_at)
  - [x] 1.3 Add validation rules per step (required fields, allowed values)
  - [x] 1.4 Add localization placeholders for copy
  - [x] 1.5 Unit tests for validation

- [x] 2.0 Implement onboarding wizard UI and progress
  - [x] 2.1 Build paged stepper with progress indicator
  - [x] 2.2 Implement form components (chips, selects, toggles, text)
  - [x] 2.3 Add back/next controls and save-and-exit
  - [x] 2.4 Include consent information step (no toggle required)
  - [x] 2.5 Loading, error, and disabled submit states

- [x] 3.0 Implement persistence (draft resume + Supabase upserts)
  - [x] 3.1 Save draft locally after each change
  - [x] 3.2 Upsert to `onboarding_answers` per step
  - [x] 3.3 Resume unfinished onboarding on app open
  - [x] 3.4 Track `onboarding_step_submit` events

- [x] 4.0 Set `onboarding_completed_at` and route to Paywall
  - [x] 4.1 On final submit, set `profiles.onboarding_completed_at`
  - [x] 4.2 Redirect to Paywall screen
  - [x] 4.3 Prevent returning to onboarding unless reset

- [ ] 5.0 Instrument onboarding analytics events
  - [x] 5.1 Track `onboarding_start`, `onboarding_step_submit` (step_key)
  - [x] 5.2 Track `onboarding_complete`
  - [ ] 5.3 Add funnel dashboard notes
