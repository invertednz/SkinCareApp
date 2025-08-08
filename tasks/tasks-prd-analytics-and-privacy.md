## Relevant Files

- `lib/services/analytics.dart` - Analytics wrapper and initialization.
- `lib/services/crash_reporting.dart` - Crash reporting integration.
- `lib/settings/privacy_screen.dart` - Data deletion/export links and analytics opt-out.
- `supabase/functions/_shared/analytics.ts` - Optional server-side forwarding.

### Notes

- Do not send PII/PHI; use anon IDs and coarse props.

## Tasks

- [ ] 1.0 Implement analytics wrapper and PostHog initialization
  - [ ] 1.1 Add PostHog dependency and initialize in `lib/services/analytics.dart`
  - [ ] 1.2 Load public key and host from env; ensure no server-secret in client
  - [ ] 1.3 Implement `track(event, props)`, `screen(screenName)`, and safe property filtering (no PII/PHI)
  - [ ] 1.4 Add router observer to emit `screen_view` with `screen_name`
  - [ ] 1.5 Gate analytics with a runtime flag and optional user opt-out

- [ ] 2.0 Add event tracking across auth, onboarding, paywall, logs, photos, insights, chat, notifications
  - [ ] 2.1 Define centralized event constants/types; compile-time lint for unknown events
  - [ ] 2.2 Auth: `auth_start/success/failure` (method, error_code)
  - [ ] 2.3 Onboarding: `onboarding_start/step_submit/complete` (step_key)
  - [ ] 2.4 Paywall/IAP: `paywall_view/select_plan/start_trial/purchase_success/purchase_failure/entitlement_sync`
  - [ ] 2.5 Logging: `log_create_*` with `has_photo`, `ts`; Photos: upload start/success/failure
  - [ ] 2.6 Insights: generate request/success/rate_limited, view, add_to_routine
  - [ ] 2.7 Chat: open, send(has_image), stream_start/end(duration_ms), blocked_moderation(category), thumbsup/thumbsdown
  - [ ] 2.8 Notifications: delivered/open(category), settings_update

- [ ] 3.0 Implement privacy controls (deletion/export links) and document process
  - [ ] 3.1 Add Privacy screen with links to Terms/Privacy and data request email/form
  - [ ] 3.2 Document internal SOP for deletion/export fulfillment (MVP manual)
  - [ ] 3.3 Implement analytics opt-out toggle (optional MVP)

- [ ] 4.0 Integrate crash reporting (optional) and error breadcrumbs
  - [ ] 4.1 Add `lib/services/crash_reporting.dart` with initialization
  - [ ] 4.2 Capture unhandled errors and attach minimal breadcrumbs
  - [ ] 4.3 Ensure no PII/PHI in crash payloads

- [ ] 5.0 QA instrumentation and verify events delivery
  - [ ] 5.1 Use a dev PostHog project to validate events in staging
  - [ ] 5.2 Verify required properties present; check payload size and frequency
  - [ ] 5.3 Create dashboards/funnels for key journeys (auth→onboarding→paywall, log→insights, chat)
  - [ ] 5.4 Add CI step to lint event names against schema
