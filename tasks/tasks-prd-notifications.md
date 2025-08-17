## Relevant Files

- `app/lib/features/notifications/settings_screen.dart` - Notification preferences UI with permission handling and time pickers.
- `app/lib/features/notifications/data/notifications_repository.dart` - Preference persistence and CRUD operations.
- `app/lib/services/notifications_service.dart` - FCM token management, permissions, and message handlers.
- `supabase/functions/push-scheduler/index.ts` - Edge Function (cron) to send push notifications.
- `supabase/schema.sql` - `notification_settings` and `user_fcm_tokens` tables with RLS policies.

### Notes

- Defaults: AM 08:00, PM 20:00, Daily 19:30, Weekly Sun 17:00; quiet hours 22:00–07:00.
- Current codebase: no notifications (APNs/FCM) or preferences implementation found yet; leaving tasks unchecked until implemented.
 - Deep link routes implemented in `app/lib/router/app_router.dart`: `/notifications/:category` opens app to appropriate tab.

## Tasks

- [x] 1.0 Implement permissions and token registration (APNs/FCM)
  - [x] 1.1 Request notification permission; handle denied/permanently denied flows
  - [x] 1.2 Obtain FCM/APNs token and securely register it server-side
  - [x] 1.3 Handle token refresh lifecycle and re-register
  - [x] 1.4 Foreground/Background message handlers (basic)

- [x] 2.0 Build preferences UI and persistence with quiet hours
  - [x] 2.1 UI toggles for Routine AM, Routine PM, Daily Log, Weekly Insights
  - [x] 2.2 Time pickers with defaults (AM 08:00, PM 20:00, Daily 19:30, Weekly Sun 17:00)
  - [x] 2.3 Quiet hours pickers with validation (22:00–07:00; allow cross-midnight)
  - [x] 2.4 Persist to `notification_settings` (user_id, category, enabled, time, quiet_from/to)
  - [x] 2.5 Error states and disabled UI when permission is denied

- [x] 3.0 Implement scheduling (Edge function cron) and local fallback
  - [x] 3.1 Edge Function reads prefs and enqueues push payloads per user/timezone
  - [x] 3.2 Configure Cloud Scheduler/Cron to invoke Edge Function on schedule
  - [x] 3.3 Local notifications fallback when push denied; mirror server schedule client-side
  - [x] 3.4 DST and timezone handling using stored `time_zone` in profile

- [x] 4.0 Add deep links to target screens from notifications
  - [x] 4.1 Define deep link routes for each category (routine, log, insights)
  - [x] 4.2 Open app to specific screen and pre-fill context where applicable
  - [x] 4.3 Include minimal metadata for analytics (category, campaign)

- [x] 5.0 Instrument analytics for delivery/open/settings updates
  - [x] 5.1 Track `notification_delivered`/`notification_open` with category
  - [x] 5.2 Track `notification_settings_update` on save
  - [x] 5.3 Error tracking for delivery failures and permission denials
