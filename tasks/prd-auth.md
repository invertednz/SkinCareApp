# Authentication PRD

## Introduction/Overview
Implement authentication for the Flutter app using Supabase Auth. MVP enables Email/Password sign up/sign in. Google and Apple providers are visually present (buttons/icons) but deferred technically (disabled/stub) for now; architecture must make enabling providers trivial later. No email verification is required. No guest mode. After successful auth, users proceed to onboarding.

## Goals
- Provide reliable Email/Password authentication on iOS, Android, and Web.
- Display Google and Apple sign-in options with correct brand guidelines (disabled until enabled later).
- Establish a provider-agnostic auth layer so Google/Apple can be switched on with minimal code.
- Persist user session securely with Supabase across app launches.

## User Stories
- As a user, I can create an account with email and password so I can use the app.
- As a user, I can sign in with my email and password to access my data.
- As a user, I see Google and Apple sign-in buttons (disabled/coming soon) so I know these methods are supported.
- As a user, I stay signed in until I sign out.

## Functional Requirements
1. The system must support Sign Up and Sign In with Email/Password via Supabase Auth.
2. The system must show Google and Apple buttons on the auth screen, styled per brand guidelines, with tooltip/label “Coming soon”.
3. The system must include Password Reset (email link) flow.
4. The system must maintain session persistence using Supabase’s session on all platforms.
5. The system must provide Sign Out.
6. The system must route new authenticated users directly to onboarding; returning users who completed onboarding to the main app; returning users who haven’t completed onboarding to onboarding.
7. The system must show error messages for invalid credentials, network errors, and generic failures.
8. The system must display links to Terms and Privacy Policy.
9. The system must log auth events for analytics (started, success, failure) without storing sensitive data.

## Non-Goals
- Enabling Google/Apple providers technically (will be enabled in a later iteration).
- Email verification.
- MFA.

## Design Considerations
- Use mockups’ visual language.
- Ordering: show social provider buttons first (Google, Apple – disabled with "Coming soon"), then divider, then Email/Password fields. Rationale: social-first increases perceived choice and matches common patterns.
- Include Google and Apple official button styles (color/monochrome variants as per platform), disabled state.
- Terms/Privacy copy: below primary CTA, show “By continuing, you agree to our Terms and acknowledge our Privacy Policy.” with links.

## Technical Considerations
- Supabase Auth with RLS on app data tables.
- Provider-agnostic abstraction (e.g., `AuthRepository` with methods: signInEmail, signUpEmail, signOut, signInWithGoogle, signInWithApple). Google/Apple methods stubbed to return “not enabled”.
- Session handling via Supabase Flutter SDK; listen for auth state changes.
- Secure storage on mobile; web uses local storage as handled by SDK.
- Route guards to enforce auth + onboarding completion before entering main app.
- Environment-configurable URLs: TERMS_URL=https://skincare.app/terms, PRIVACY_URL=https://skincare.app/privacy (replace with production domain at launch).

## Success Metrics
- >95% successful email sign-in rate after first attempt (excluding wrong credentials).
- Session persistence across app restarts validated on all platforms.
- No PII leaks in analytics logs.

## Open Questions
- None.
