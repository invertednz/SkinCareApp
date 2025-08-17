## Relevant Files

- `app/lib/services/analytics.dart` - Analytics wrapper and initialization (stubbed).
- `app/lib/services/env.dart` - Provides PostHog keys/host from env.
- `app/lib/main.dart` - Calls `AnalyticsService.init(...)` at startup.
- `app/lib/router/analytics_observer.dart` - Emits `screen_view` events via `AnalyticsService`.
- `app/pubspec.yaml` - Declares dependencies (`go_router`, `supabase_flutter`, `posthog_flutter`).
- `app/lib/settings/privacy_screen.dart` - Data deletion/export links and analytics opt-out.
- `supabase/functions/_shared/analytics.ts` - Optional server-side forwarding.

### Notes

- Do not send PII/PHI; use anon IDs and coarse props.

## Tasks

- [x] 1.0 Implement analytics wrapper and PostHog initialization
  - [x] 1.1 Add PostHog dependency and initialize in `app/lib/services/analytics.dart`
  - [x] 1.2 Load public key and host from env; ensure no server-secret in client
  - [x] 1.3 Implement `track(event, props)`, `screen(screenName)`, and safe property filtering (no PII/PHI)
  - [x] 1.4 Add router observer to emit `screen_view` with `screen_name`
  - [x] 1.5 Gate analytics with a runtime flag and optional user opt-out

- [ ] 2.0 Add event tracking across auth, onboarding, paywall, logs, photos, insights, chat, notifications
  - [x] 2.1 Define centralized event constants/types; compile-time lint for unknown events
  - [x] 2.2 Auth: `auth_start/success/failure` (method, error_code)
  - [x] 2.3 Onboarding: `onboarding_start/step_submit/complete` (step_key)
  - [x] 2.4 Paywall/IAP events
    - [x] `paywall_view`
    - [x] `paywall_select_plan`
    - [x] `start_trial`
    - [x] `purchase_success`
    - [x] `purchase_failure`
    - [x] `entitlement_sync`
  - [x] 2.5a Logging: `log_create_*` with `has_photo`, `ts`
  - [x] 2.5b Photos: upload start/success/failure; analyze start/success/failure; delete; moderation_block
  - [x] 2.6 Insights: generate request/success/rate_limited, view, add_to_routine
  - [ ] 2.7 Chat: open, send(has_image), stream_start/end(duration_ms), blocked_moderation(category), thumbsup/thumbsdown
  - [ ] 2.8 Notifications: delivered/open(category), settings_update

- [ ] 3.0 Implement privacy controls (deletion/export links) and document process
  - [ ] 3.1 Add Privacy screen with links to Terms/Privacy and data request email/form
  - [ ] 3.2 Document internal SOP for deletion/export fulfillment (MVP manual)
  - [ ] 3.3 Implement analytics opt-out toggle (optional MVP)

- [ ] 4.0 Integrate crash reporting (optional) and error breadcrumbs
  - [ ] 4.1 Add `app/lib/services/crash_reporting.dart` with initialization
  - [ ] 4.2 Capture unhandled errors and attach minimal breadcrumbs
  - [ ] 4.3 Ensure no PII/PHI in crash payloads

- [ ] 5.0 QA instrumentation and verify events delivery
  - [ ] 5.1 Use a dev PostHog project to validate events in staging
  - [ ] 5.2 Verify required properties present; check payload size and frequency
  - [ ] 5.3 Create dashboards/funnels for key journeys (auth→onboarding→paywall, log→insights, chat)
  - [ ] 5.4 Add CI step to lint event names against schema
