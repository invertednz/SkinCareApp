## Relevant Files

- `lib/features/auth/presentation/auth_screen.dart` - Auth UI with Email/Password and disabled Google/Apple buttons.
- `lib/features/auth/presentation/password_reset_screen.dart` - Password reset flow.
- `lib/features/auth/data/auth_repository.dart` - Provider-agnostic auth abstraction.
- `lib/router/app_router.dart` - App routes and guards for auth/onboarding/paywall.
- `lib/services/analytics.dart` - Analytics wrapper for auth events.
- `lib/services/env.dart` - Config for TERMS_URL and PRIVACY_URL.
- `supabase/schema.sql` - Auth-related tables/columns (e.g., profiles), RLS policies.
- `supabase/auth-settings.md` - Dashboard configuration for Email/Password, email confirmation, redirects.
- `supabase/functions/_shared/supabaseClient.ts` - Shared client for Edge Functions (future providers).
- `.env.example` - Example environment variables (TERMS_URL, PRIVACY_URL).
- `docs/env.md` - Environment variable documentation and usage.
- `scripts/seed-dev-user.ps1` - Dev seeding script to create a confirmed user (local/staging only).
- `docs/seeding.md` - Instructions for developer seeding.

### Notes

- Unit tests should sit alongside files where practical.
- Use official Google/Apple button styles but keep disabled for MVP.

## Tasks

- [ ] 1.0 Configure Supabase Auth and profiles
  - [x] 1.1 Create `profiles` table with `user_id` PK, `created_at`, `onboarding_completed_at`, `time_zone`
  - [x] 1.2 Enable RLS and add policies for `user_id = auth.uid()`
  - [x] 1.3 Set Supabase Auth settings: email/password enabled; email verification off for MVP
  - [x] 1.4 Add trigger to auto-insert profile row on user signup
  - [x] 1.5 Add `TERMS_URL` and `PRIVACY_URL` to config/env
  - [x] 1.6 Seed local dev user via Supabase CLI (optional)

- [ ] 2.0 Build Auth UI (Email/Password + disabled Google/Apple) with Terms/Privacy links
  - [ ] 2.1 Implement social-first layout with Google/Apple buttons disabled and “Coming soon” labels
  - [ ] 2.2 Implement email/password fields with validation and submit button
  - [ ] 2.3 Add Terms and Privacy links below primary CTA
  - [ ] 2.4 Show loading and error states; prevent double submits
  - [ ] 2.5 Basic widget tests for validation and disabled states

- [ ] 3.0 Implement AuthRepository and session persistence across launches
  - [ ] 3.1 Wrap Supabase auth methods: signInWithPassword, signUp, signOut
  - [ ] 3.2 Persist/restore session on app start; subscribe to auth state changes
  - [ ] 3.3 Handle token refresh and recover from expired sessions
  - [ ] 3.4 Expose auth state stream to router guards

- [ ] 4.0 Implement Password Reset flow
  - [ ] 4.1 Create password reset request screen; call Supabase reset API
  - [ ] 4.2 Handle success and error UX; copy with expectations about email
  - [ ] 4.3 Add deep link handler if needed for in-app reset flow (optional)

- [ ] 5.0 Add route guards to direct new users to onboarding and returning users appropriately
  - [ ] 5.1 Implement go_router redirect based on auth state
  - [ ] 5.2 Fetch `onboarding_completed_at` to gate paywall
  - [ ] 5.3 Guard main app behind active subscription (stub until payment complete)

- [ ] 6.0 Instrument analytics for auth start/success/failure and errors
  - [ ] 6.1 Track `auth_start` with method, `auth_success`/`auth_failure` with error_code
  - [ ] 6.2 Track `screen_view` for auth screens
