## Relevant Files

- `lib/router/app_router.dart` - go_router with guards.
- `lib/app/app_shell.dart` - App shell and bottom tabs.
- `lib/services/session.dart` - Session/auth state.
- `lib/services/analytics.dart` - Screen view tracking.

### Notes

- Web is single column; keep responsive changes minimal in MVP.

## Tasks

- [ ] 1.0 Implement go_router with guards for auth → onboarding → paywall → tabs
  - [ ] 1.1 Define route names and paths; set initial route
  - [ ] 1.2 Implement auth guard using auth state stream
  - [ ] 1.3 Implement onboarding guard using `onboarding_completed_at`
  - [ ] 1.4 Implement paywall guard using subscription entitlement
  - [ ] 1.5 Add deep link handling for notifications and password reset

- [ ] 2.0 Build app shell with bottom tabs (Home/Insights, Diary, Chat, Profile)
  - [ ] 2.1 Create `AppShell` with bottom navigation and state preservation
  - [ ] 2.2 Wire tabs to respective root screens
  - [ ] 2.3 Add app bar titles and actions per tab
  - [ ] 2.4 Implement back-button behavior on Android

- [ ] 3.0 Add global error handling and light theme
  - [ ] 3.1 Central error widget and snackbars
  - [ ] 3.2 Global try/catch boundaries where appropriate
  - [ ] 3.3 Define light theme (colors, typography, buttons)

- [ ] 4.0 Ensure basic web responsiveness and min width
  - [ ] 4.1 Constrain content width on wide screens
  - [ ] 4.2 Test layouts on common breakpoints
  - [ ] 4.3 Adjust paddings and font scaling for web

- [ ] 5.0 Track screen_view events per navigation
  - [ ] 5.1 Hook router observer to analytics wrapper
  - [ ] 5.2 Emit `screen_view` with `screen_name`
