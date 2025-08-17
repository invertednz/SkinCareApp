## Relevant Files

- `app/lib/router/app_router.dart` - go_router with guards.
- `app/lib/app/app_shell.dart` - App shell and bottom tabs.
- `app/lib/main.dart` - App entry; wires MaterialApp.router and theme.
- `app/lib/theme/light_theme.dart` - Central light theme (colors, typography, buttons).
- `app/lib/router/router_refresh.dart` - Listenable to refresh GoRouter on auth/profile changes.
- `app/lib/services/session.dart` - Session/auth state.
- `app/lib/services/analytics.dart` - Screen view tracking.
- `app/lib/router/analytics_observer.dart` - Router observer emitting `screen_view`.
- `app/lib/services/error_handler.dart` - Central error handling service with global error capture and user-friendly snackbars.
- `app/lib/widgets/error_widget.dart` - Reusable error widgets (full-screen and compact) with consistent styling.
- `app/lib/widgets/responsive_wrapper.dart` - Responsive wrapper and layout utilities with breakpoint management.
- `app/lib/widgets/responsive_test_widget.dart` - Test widget for verifying responsive behavior at different breakpoints.
- `app/lib/features/insights/insights_screen.dart` - Root screen for Home/Insights tab with responsive layouts.
- `app/lib/features/diary/diary_screen.dart` - Root screen for Diary tab.
- `app/lib/features/chat/chat_screen.dart` - Root screen for Chat tab.
- `app/lib/features/profile/profile_screen.dart` - Root screen for Profile tab.

### Notes

- Web is single column; keep responsive changes minimal in MVP.
- Light theme is defined in `app/lib/theme/light_theme.dart` and applied in `app/lib/main.dart` via `MaterialApp.router(theme: LightTheme.theme)`.
- No global error boundary found yet (`FlutterError.onError`, `runZonedGuarded`, `ErrorWidget.builder`); leave 3.1/3.2 unchecked until implemented.
- Some responsive widgets are present (e.g., `FractionallySizedBox` in `app/lib/features/onboarding/presentation/onboarding_wizard.dart`), but no app-wide max-width constraint; leave 4.x tasks unchecked.
 - Deep link routes found in `app/lib/router/app_router.dart`: `/reset` (password reset) and `/notifications/:category` (notifications).

## Tasks

- [x] 0.0 Scaffold Flutter app
  - [x] 0.1 Initialize Flutter project in `app/`
  - [x] 0.2 Add base dependencies (`go_router`, `supabase_flutter`, `posthog_flutter`)
  - [x] 0.3 Set up directory structure and base light theme
 
- [x] 1.0 Implement go_router with guards for auth → onboarding → paywall → tabs
  - [x] 1.1 Define route names and paths; set initial route
  - [x] 1.2 Implement auth guard using auth state stream
  - [x] 1.3 Implement onboarding guard using `onboarding_completed_at`
  - [x] 1.4 Implement paywall guard using subscription entitlement
  - [x] 1.5 Add deep link handling for notifications and password reset
 
- [x] 2.0 Build app shell with bottom tabs (Home/Insights, Diary, Chat, Profile)
  - [x] 2.1 Create `AppShell` with bottom navigation and state preservation
  - [x] 2.2 Wire tabs to respective root screens
  - [x] 2.3 Add app bar titles and actions per tab
  - [x] 2.4 Implement back-button behavior on Android
 
- [x] 3.0 Add global error handling and light theme
  - [x] 3.1 Central error widget and snackbars
  - [x] 3.2 Global try/catch boundaries where appropriate
  - [x] 3.3 Define light theme (colors, typography, buttons)
 
- [x] 4.0 Ensure basic web responsiveness and min width
  - [x] 4.1 Constrain content width on wide screens
  - [x] 4.2 Test layouts on common breakpoints
  - [x] 4.3 Adjust paddings and font scaling for web
 
- [x] 5.0 Track screen_view events per navigation
  - [x] 5.1 Hook router observer to analytics wrapper
  - [x] 5.2 Emit `screen_view` with `screen_name`
