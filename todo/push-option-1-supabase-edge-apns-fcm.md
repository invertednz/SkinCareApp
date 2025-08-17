# Option 1 — Server‑Driven Push via Supabase Edge (APNs/FCM)

Keep Supabase as the system of record (settings, users) and deliver notifications via a Supabase Edge Function that calls APNs (iOS) and FCM (Android). This reintroduces a push transport but keeps business logic and data within Supabase.

---

## Goals
- Reliable, server‑initiated delivery even when the app is closed.
- Use existing `notification_settings` as the source of truth.
- Maintain local notifications as a fallback if permission is denied.

## High‑level Architecture
```
+------------------+         +---------------------------+
| Mobile Client    |         | Supabase                 |
| - iOS: APNs token|  HTTPS  | - DB: notification_settings|
| - Android: FCM   +-------->+ - Edge Function: scheduler |
|   registration   |         | - Secrets: APNs, FCM       |
+---------+--------+         +-----+----------------------+
          ^                        |
          |  Push (APNs/FCM)       | Schedules, reads settings
          |                        v
      +---+----------------------------+
      | Apple APNs / Google FCM        |
      +--------------------------------+
```

---

## Data Model
- Reuse: `notification_settings` (already in `lib/features/notifications/data/notifications_repository.dart`).
- New: `user_push_tokens` table to store per‑device tokens.

```sql
-- user_push_tokens
create table if not exists public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios','android')),
  token text not null,
  device_id text, -- optional: vendor ID / installation ID
  last_seen_at timestamptz default now(),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Ensure unique per (user, platform, token)
create unique index if not exists idx_user_push_tokens_unique
  on public.user_push_tokens(user_id, platform, token);

-- RLS
alter table public.user_push_tokens enable row level security;

create policy "user_owns_tokens" on public.user_push_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

Notes:
- Keep tokens short‑lived validity in mind; expect rotation and duplicate device entries. Use `last_seen_at` and cleanup jobs.

---

## Mobile Client Changes (minimal)
- iOS: collect APNs device token and send to Supabase.
  - Implementation options:
    - Use a lightweight APNs plugin to retrieve the APNs token (no Firebase).
    - Or implement natively via platform channels to expose the APNs token to Dart.
- Android: collect FCM device token and send to Supabase.
  - Requires including a minimal FCM client to obtain the token and receive pushes.
  - This reintroduces Firebase on Android only. If strict "no Firebase" is required, consider Option 2 instead.

Client responsibilities:
- On sign‑in: register or upsert token (`user_push_tokens`).
- On token refresh: update row and `updated_at`.
- On sign‑out/uninstall: best‑effort delete token entry.
- Keep existing local scheduling for denied permission cases.

Payload format (from server):
- Use `category` keys aligned with `NotificationSetting.displayName/description`.
- Include deep‑link route (e.g. `/notifications/log`).

---

## Edge Function(s)
Implement in `supabase/functions/push-scheduler/`:

- `schedule.ts` (cron):
  - Runs periodically (e.g., every 5–15 minutes) via Supabase Scheduled Functions.
  - Reads `notification_settings` for users whose next notification time has arrived (consider timezone and quiet hours).
  - Enqueues push jobs per user category.

- `send.ts` (worker):
  - Fetches tokens from `user_push_tokens` for targeted users.
  - Sends to APNs (iOS) and FCM (Android).
  - Handles HTTP responses; invalid tokens => delete/flag.

- Secrets (set via `supabase secrets set`):
  - `APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_PRIVATE_KEY` (p8 contents), `APNS_BUNDLE_ID`.
  - `GOOGLE_PROJECT_ID`, `FIREBASE_SA_JSON` (for FCM HTTP v1), `FCM_TOPIC_PREFIX` (optional).

- Libraries:
  - APNs: use HTTP/2 with JWT auth (e.g., `apns2` or manual HTTP/2 client in Node/TS).
  - FCM: HTTP v1 API using OAuth (sign with service account).

Pseudo‑code (send path):
```ts
// Type: { userId, category, title, body, deeplink }
async function sendNotification(job) {
  const tokens = await db
    .from('user_push_tokens')
    .select('platform, token')
    .eq('user_id', job.userId);

  const payload = buildPayload(job);

  const iosTokens = tokens.filter(t => t.platform === 'ios');
  const androidTokens = tokens.filter(t => t.platform === 'android');

  await Promise.all([
    sendApnsBatch(iosTokens, payload),
    sendFcmBatch(androidTokens, payload),
  ]);
}
```

Error handling:
- Retry with exponential backoff for 5xx.
- On APNs 410 (Unregistered) or FCM `UNREGISTERED`, remove token.
- Log to PostHog/Analytics for delivery/open (as available).

---

## Security & Compliance
- Store keys in Supabase secrets only (never in repo).
- Restrict Edge Function invocation to cron/service role; user‑invoked endpoints require JWT with RLS checks.
- Audit logging of send attempts and token mutations.
- Respect user opt‑out: check `notification_settings.enabled` and quiet hours before send.

---

## Migration Plan
1. DB: create `user_push_tokens` with RLS (SQL above).
2. Mobile: implement token registration flows (platform‑specific).
3. Edge: scaffold `push-scheduler` function(s) with secrets.
4. Scheduling: configure Supabase Scheduled Functions cadence.
5. QA: test tokens, end‑to‑end delivery, quiet hours, deep links.
6. Observability: add Analytics events for delivered/opened; include category and platform.
7. Rollout: behind a feature flag. Fall back to local notifications if permission denied or send fails.

---

## Testing Checklist
- Permissions prompt flows on iOS/Android.
- Token stored/updated in `user_push_tokens` with correct user and platform.
- Quiet hours honored including cross‑midnight.
- Timezone changes: scheduling matches local time.
- Invalid tokens purged after send.
- Deep‑link navigates to correct screen.

---

## Effort Estimate (rough)
- DB + policies: 0.5 day
- iOS token registration + wiring: 1–2 days
- Android FCM minimal client + wiring: 1–2 days
- Edge Functions (schedule + send + secrets): 2–3 days
- QA + rollout: 1–2 days

Total: ~1–2 weeks calendar time depending on review and store provisioning for APNs/FCM.

---

## Open Decisions
- Accept Android‑only Firebase client dependency? If not, prefer Option 2 (OneSignal) to avoid Firebase code.
- Delivery analytics: which events to capture and where to store.
- Exact cron cadence and server load considerations.
- Token schema additions (app version, locale) for targeting.
