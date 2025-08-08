# Notifications & Reminders PRD

## Overview
Implement push notifications for routine reminders, daily log nudges, and weekly insights summaries using FCM (Android) and APNs (iOS). Provide fallback to local notifications when push permission is denied.

## Goals
- Drive healthy engagement with timely, respectful nudges.
- Respect user preferences and quiet hours.

## User Stories
- As a user, I can receive AM/PM routine reminders at my chosen times.
- As a user, I can receive a daily reminder to log.
- As a user, I can receive a weekly insights summary.

## Functional Requirements
1. Opt-in permission prompt on first need.
2. Preferences in Settings: toggle for each category (Routine AM/PM, Daily Log, Weekly Insights), time pickers, quiet hours.
3. Push delivery via FCM/APNs with payloads that deep-link into the relevant screen.
4. Fallback to local scheduled notifications if push denied.
5. Timezone-aware scheduling; handle DST.
6. Basic rate limiting to avoid spam.
 7. Defaults:
    - Routine AM reminder default 08:00 local time.
    - Routine PM reminder default 20:00 local time.
    - Daily Log nudge default 19:30 local time.
    - Weekly Insights summary default Sunday 17:00 local time.
    - Quiet hours default 22:00–07:00 (suppress non-critical notifications; routine reminders may be deferred to next window).

## Non-Goals
- Complex notification automation rules.

## Technical Considerations
- Store preferences in `notification_settings` table (user_id, category, enabled, time, quiet_hours_from/to).
- Use Supabase Edge Functions or client scheduling for local notifications; push scheduling via backend cron or cloud scheduler hitting an Edge Function.
- Notification content localized (English MVP).

## Success Metrics
- Opt-in rate for push >50%.
- Open rate of routine reminders >15%.

## Open Questions
 - None.
