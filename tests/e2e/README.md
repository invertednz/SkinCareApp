# SkinCare App - Playwright E2E Tests

End-to-end tests for the SkinCare Flutter Web application using Playwright.

## Prerequisites

- Node.js 18+
- Flutter SDK (for building/running the web app)

## Setup

```bash
cd tests/e2e
npm install
npx playwright install chromium
```

## Running the Flutter Web App

Before running tests, start the Flutter web app with the HTML renderer:

```bash
cd app
flutter run -d chrome --web-renderer html --web-port 8080
```

Or build and serve statically:

```bash
cd app
flutter build web --web-renderer html
npx serve build/web -l 8080
```

## Running Tests

```bash
# Run all tests
npm test

# Run specific test suite
npm run test:auth
npm run test:onboarding
npm run test:tracking
npm run test:chat
npm run test:navigation
npm run test:paywall

# Run with browser visible
npm run test:headed

# Run with Playwright UI
npm run test:ui

# Debug mode
npm run test:debug

# View HTML report
npm run report
```

## Custom Base URL

```bash
BASE_URL=http://localhost:3000 npm test
```

## Test Structure

```
tests/e2e/
├── playwright.config.ts       # Playwright configuration
├── package.json               # Dependencies and scripts
├── tests/
│   ├── fixtures.ts            # Flutter web test helpers & fixtures
│   ├── auth/
│   │   ├── login.spec.ts      # Login screen tests
│   │   └── password-reset.spec.ts
│   ├── onboarding/
│   │   └── onboarding-flow.spec.ts  # Multi-step onboarding wizard
│   ├── navigation/
│   │   └── app-navigation.spec.ts   # Routing & tab navigation
│   ├── tracking/
│   │   ├── home-screen.spec.ts      # Home/tracking dashboard
│   │   ├── symptoms-screen.spec.ts  # Symptom tracking
│   │   ├── routine-screen.spec.ts   # Routine tracking
│   │   └── supplements-screen.spec.ts
│   ├── chat/
│   │   └── chat-screen.spec.ts      # AI chat interface
│   ├── paywall/
│   │   └── paywall.spec.ts          # Trial & subscription
│   ├── accessibility/
│   │   └── a11y.spec.ts             # Accessibility & responsive
│   └── visual/
│       └── screenshots.spec.ts      # Visual regression
```

## Flutter Web Testing Notes

Flutter web apps render differently depending on the renderer:

- **HTML renderer** (`--web-renderer html`): Generates semantic DOM nodes.
  Playwright can query text, roles, and inputs directly. **Recommended for testing.**

- **CanvasKit renderer** (default): Renders to a canvas element.
  Limited DOM access, but Flutter still exposes a semantics tree via ARIA.

Tests use these strategies to find elements:

- `page.getByText()` — find text content
- `page.getByRole('button')` — find buttons by role
- `page.locator('input')` — find input fields
- `page.locator('[aria-label="..."]')` — find by ARIA label

## Test Categories

| Suite         | Tests | What it covers                                                  |
| ------------- | ----- | --------------------------------------------------------------- |
| Auth          | 11    | Login form, validation, social buttons, consent, password reset |
| Onboarding    | 8     | Welcome page, social proof, multi-step flow, back navigation    |
| Navigation    | 8     | Route redirects, tab switching, deep links                      |
| Tracking      | 16    | Home, symptoms, routine, supplements screens                    |
| Chat          | 6     | Chat interface, message input, attachments                      |
| Paywall       | 4     | Trial offer, plan comparison                                    |
| Accessibility | 10    | Text readability, responsive design, semantic structure         |
| Visual        | 3     | Screenshot regression for key pages                             |
