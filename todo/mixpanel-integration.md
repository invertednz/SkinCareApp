# Mixpanel Integration TODO

## Relevant Files
- **Analytics service** `app/lib/services/analytics_service.dart`
- **Analytics export** `app/lib/services/analytics.dart`
- **App bootstrap** `app/lib/main.dart`
- **Environment loader** `app/lib/services/env.dart`
- **Flutter dependencies** `app/pubspec.yaml`
- **Environment templates** `app/.env`, `app/.env.local`, `app/android/.env`, `app/ios/.env`, `app/.env.example`
- **Analytics tasks PRD** `tasks/tasks-prd-analytics-and-privacy.md`

## Tasks

### Environment & Dependencies
- [ ] **Sync dependencies** Run `flutter pub get` (and commit `pubspec.lock` changes if applicable).
- [ ] **Update environment values** Replace placeholder `MIXPANEL_TOKEN`/`MIXPANEL_HOST` in each `.env*` file with real project credentials (host optional if using default).
- [ ] **Propagate secrets** Set Mixpanel token/host in build pipelines and Supabase Edge functions if they forward analytics.

### Instrumentation Verification
- [ ] **Sanity check initialization** Launch debug build, confirm `Analytics initialized successfully` log appears only when Mixpanel token present.
- [ ] **Verify event delivery** Trigger key journeys (auth, onboarding, paywall, diary upload, chat) and confirm events in Mixpanel Live View.
- [ ] **Review event schema** Ensure `AnalyticsEvents` names and properties match Mixpanel reporting requirements; create dashboards or rename events if needed.
- [ ] **Check opt-out behavior** Toggle any in-app privacy controls to ensure `optOutTracking` / `optInTracking` works as expected.

### Documentation & Follow-ups
- [ ] **Update analytics PRD** Reflect Mixpanel integration status and next steps in `tasks/tasks-prd-analytics-and-privacy.md` (mark relevant items complete/updated).
- [ ] **Write QA checklist** Add Mixpanel verification steps to release QA docs or handoff notes.
- [ ] **Coordinate product analytics** Align with data/marketing on naming conventions, required properties, and retention policies within Mixpanel.
- [ ] **Plan production rollout** Decide when to enable Mixpanel in production builds and communicate env variable requirements to DevOps.

## Notes
- **Mixpanel project:** Create separate dev/staging projects or use distinct environments to avoid polluting production data.
- **Identity management:** When user auth is implemented, call `mixpanel.identify` / `mixpanel.getPeople` as needed (extend `AnalyticsService` when ready).
- **Extensions:** Consider adding support for super properties, timed events, and in-app A/B testing once base tracking is verified.
