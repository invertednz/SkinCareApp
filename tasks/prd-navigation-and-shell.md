# Navigation & App Shell PRD

## Overview
Define the app’s navigation structure and shell across iOS, Android, and Web. Use mockups as inspiration; prioritize clarity and functional parity.

## Goals
- Simple, predictable navigation with bottom tabs and clear routes.
- Guarding for auth, onboarding, and paywall states.

## Structure
- Launch/Splash → Auth
- Auth → Onboarding wizard
- Onboarding completion → Paywall
- Paywall success → Main Tabs

## Main Tabs
1. Home/Insights (default): quick stats and insights overview, CTA to view full insights.
2. Diary: access to Skin Health, Symptoms, Diet, Supplements, Routine screens.
3. Chat: AI assistant.
4. Profile/Settings: account, onboarding answers, notifications, privacy, about.

## Functional Requirements
1. Route Guards: redirect unauthenticated users to Auth; users without onboarding to Onboarding; users without subscription to Paywall.
2. State Management: Riverpod (recommended) for auth/session and feature states.
3. Web Responsiveness: single-column layout; simple scaling; minimum width 360; avoid complex responsive work in MVP.
4. Error States: global error banner for network outages; retry actions.
5. Theming: light mode MVP; accessible contrast.

## Non-Goals
- Deep desktop web layout.

## Technical Considerations
- Centralized router (e.g., go_router) with named routes.
- Route names stable for analytics.
- Persist selected tab between sessions.

## Success Metrics
- <1% navigation-related crash rate.
- Time from app open to usable home < 2.5s (cold start, device dependent).

## Open Questions
- Final tab names/icons.
