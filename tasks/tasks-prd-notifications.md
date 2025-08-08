## Relevant Files

- `lib/features/notifications/settings_screen.dart` - Notification preferences UI.
- `lib/features/notifications/data/notifications_repository.dart` - Preference persistence and scheduling.
- `supabase/functions/push-scheduler/index.ts` - Edge Function (cron) to send push notifications.
- `supabase/schema.sql` - `notification_settings` table.

### Notes

- Defaults: AM 08:00, PM 20:00, Daily 19:30, Weekly Sun 17:00; quiet hours 22:00–07:00.

## Tasks

- [ ] 1.0 Implement permissions and token registration (APNs/FCM)
  - [ ] 1.1 Request notification permission; handle denied/permanently denied flows
  - [ ] 1.2 Obtain FCM/APNs token and securely register it server-side
  - [ ] 1.3 Handle token refresh lifecycle and re-register
  - [ ] 1.4 Foreground/Background message handlers (basic)

- [ ] 2.0 Build preferences UI and persistence with quiet hours
  - [ ] 2.1 UI toggles for Routine AM, Routine PM, Daily Log, Weekly Insights
  - [ ] 2.2 Time pickers with defaults (AM 08:00, PM 20:00, Daily 19:30, Weekly Sun 17:00)
  - [ ] 2.3 Quiet hours pickers with validation (22:00–07:00; allow cross-midnight)
  - [ ] 2.4 Persist to `notification_settings` (user_id, category, enabled, time, quiet_from/to)
  - [ ] 2.5 Error states and disabled UI when permission is denied

- [ ] 3.0 Implement scheduling (Edge function cron) and local fallback
  - [ ] 3.1 Edge Function reads prefs and enqueues push payloads per user/timezone
  - [ ] 3.2 Configure Cloud Scheduler/Cron to invoke Edge Function on schedule
  - [ ] 3.3 Local notifications fallback when push denied; mirror server schedule client-side
  - [ ] 3.4 DST and timezone handling using stored `time_zone` in profile

- [ ] 4.0 Add deep links to target screens from notifications
  - [ ] 4.1 Define deep link routes for each category (routine, log, insights)
  - [ ] 4.2 Open app to specific screen and pre-fill context where applicable
  - [ ] 4.3 Include minimal metadata for analytics (category, campaign)

- [ ] 5.0 Instrument analytics for delivery/open/settings updates
  - [ ] 5.1 Track `notification_delivered`/`notification_open` with category
  - [ ] 5.2 Track `notification_settings_update` on save
  - [ ] 5.3 Error tracking for delivery failures and permission denials
