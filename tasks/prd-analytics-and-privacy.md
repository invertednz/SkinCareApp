# Analytics & Privacy PRD

## Overview
Implement basic analytics and strong privacy. Track key events across auth, onboarding, paywall, logging, insights, and chat. Honor data rights and store data in US West.

## Goals
- Understand funnel and feature usage.
- Protect user data with least-privilege access and clear controls.

## User Stories
- As a product owner, I can see usage across major features.
- As a user, I can delete my data and export it on request.

## Functional Requirements
1. Events (taxonomy):
   - Lifecycle: `app_open`, `app_background`, `screen_view` (props: `screen_name`).
   - Auth: `auth_start` (method), `auth_success` (method), `auth_failure` (method, error_code).
   - Onboarding: `onboarding_start`, `onboarding_step_submit` (step_key), `onboarding_complete`.
   - Paywall/IAP: `paywall_view`, `paywall_select_plan` (plan, price_cents, currency), `paywall_start_trial` (plan), `purchase_success` (platform, product_id), `purchase_failure` (platform, product_id, error_code), `entitlement_sync` (status).
   - Logging: `log_create_skin_health`, `log_create_symptom`, `log_create_diet`, `log_create_supplement`, `log_create_routine_adherence` (all include `has_photo`, `ts`).
   - Photos: `photo_upload_start` (section, count), `photo_upload_success` (section, count, total_bytes), `photo_upload_failure` (section, error_code).
   - Insights: `insights_generate_request`, `insights_generate_success`, `insights_generate_rate_limited`, `insights_view`, `insights_add_to_routine`.
   - Chat: `chat_open`, `chat_send` (has_image), `chat_stream_start`, `chat_stream_end` (duration_ms), `chat_blocked_moderation` (category), `chat_thumbsup`, `chat_thumbsdown`.
   - Notifications: `notification_delivered` (category), `notification_open` (category), `notification_settings_update` (category, enabled).
2. Event properties best practices:
   - Do not send PII/PHI. Use opaque IDs and coarse values.
   - Include `platform`, `app_version`, `anon_id`. User linkage via server-side only if needed.
   - Timestamp `ts` in ISO 8601.
2. Tooling: PostHog (recommended) with privacy mode; configurable via env.
3. Privacy: minimal PII; never send PHI to analytics. Use anonymous IDs linked to user_id server-side if required.
4. Data Rights: in-app links to request deletion/export; implement via support email or simple request form in MVP.
5. Region: Supabase project region US West.
6. RLS: strict on all domain tables, service role only in Edge Functions.

## Non-Goals
- Complex cohort analysis in-app.

## Technical Considerations
- Consent banner not required beyond Terms/Privacy; analytics opt-out toggle in settings (optional MVP).
- Crash reporting (e.g., Sentry/Crashlytics) optional but recommended.
 - PostHog client initialized in `lib/services/analytics.dart`; server key not embedded; use public key for client, secure anything sensitive server-side.
 - Standard wrapper `Analytics.track(event, props)` to centralize schema; lint unknown events in CI.

## Success Metrics
- Analytics events delivery >95%.
- Data deletion requests processed within 30 days.

## Open Questions
 - None.
