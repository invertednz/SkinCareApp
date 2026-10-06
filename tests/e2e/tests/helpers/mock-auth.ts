import { type Page } from "@playwright/test";
import { waitForFlutterReady, enableFlutterSemantics } from "../fixtures";

/**
 * Supabase project ref extracted from the SUPABASE_URL in .env.
 */
const SUPABASE_PROJECT_REF = "smixttalmrodkxfdtfbd";
const SUPABASE_URL = `https://${SUPABASE_PROJECT_REF}.supabase.co`;
const AUTH_STORAGE_KEY = `flutter.sb-${SUPABASE_PROJECT_REF}-auth-token`;

/** A mock user ID (UUID format) */
const MOCK_USER_ID = "00000000-1111-2222-3333-444444444444";
const MOCK_EMAIL = "test@test.com";

/**
 * Generate a fake JWT. The base64url segments contain valid JSON payloads
 * that the Supabase SDK can parse. The signature is fake but the SDK
 * only validates structure, not cryptographic validity.
 */
function makeFakeJwt(payload: Record<string, unknown>): string {
  const header = { alg: "HS256", typ: "JWT" };
  const encode = (obj: unknown) =>
    Buffer.from(JSON.stringify(obj)).toString("base64url");
  return `${encode(header)}.${encode(payload)}.fakesig`;
}

/**
 * Build the session object in the exact format that the Supabase Dart SDK
 * stores in and reads from localStorage.
 */
function buildMockSessionForStorage(): string {
  const now = Math.floor(Date.now() / 1000);
  const expiresIn = 3600;
  const expiresAt = now + expiresIn;

  const accessToken = makeFakeJwt({
    iss: `${SUPABASE_URL}/auth/v1`,
    sub: MOCK_USER_ID,
    aud: "authenticated",
    exp: expiresAt,
    iat: now,
    email: MOCK_EMAIL,
    role: "authenticated",
    session_id: "mock-session-id",
  });

  const session = {
    access_token: accessToken,
    expires_in: expiresIn,
    refresh_token: "mock-refresh-token",
    token_type: "bearer",
    user: {
      id: MOCK_USER_ID,
      aud: "authenticated",
      role: "authenticated",
      email: MOCK_EMAIL,
      email_confirmed_at: "2025-01-01T00:00:00.000000Z",
      phone: "",
      confirmed_at: "2025-01-01T00:00:00.000000Z",
      last_sign_in_at: new Date().toISOString(),
      app_metadata: { provider: "email", providers: ["email"] },
      user_metadata: {},
      identities: [
        {
          identity_id: MOCK_USER_ID,
          id: MOCK_USER_ID,
          user_id: MOCK_USER_ID,
          identity_data: { email: MOCK_EMAIL, sub: MOCK_USER_ID },
          provider: "email",
          last_sign_in_at: new Date().toISOString(),
          created_at: "2025-01-01T00:00:00.000000Z",
          updated_at: new Date().toISOString(),
        },
      ],
      created_at: "2025-01-01T00:00:00.000000Z",
      updated_at: new Date().toISOString(),
    },
    expires_at: expiresAt,
  };

  return JSON.stringify(session);
}

/**
 * Set up the page with mock Supabase auth.
 * 1. Injects a mock session into localStorage before the app loads
 * 2. Intercepts Supabase API calls to prevent network errors
 */
async function setupMockAuth(page: Page): Promise<void> {
  const sessionJson = buildMockSessionForStorage();

  // Inject session into localStorage BEFORE any JS runs
  await page.addInitScript(
    ({ key, value }) => {
      localStorage.setItem(key, value);
    },
    { key: AUTH_STORAGE_KEY, value: sessionJson },
  );

  // Intercept all Supabase API calls
  await page.route(`${SUPABASE_URL}/**`, async (route) => {
    const url = route.request().url();
    const method = route.request().method();

    // Auth endpoints
    if (url.includes("/auth/v1/user")) {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          id: MOCK_USER_ID,
          email: MOCK_EMAIL,
          aud: "authenticated",
          role: "authenticated",
        }),
      });
      return;
    }

    if (url.includes("/auth/v1/token")) {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: sessionJson,
      });
      return;
    }

    // Profile endpoint - return onboarded profile
    if (url.includes("/rest/v1/profiles")) {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          user_id: MOCK_USER_ID,
          onboarding_completed_at: "2025-01-01T00:00:00.000000Z",
        }),
      });
      return;
    }

    // All other Supabase calls
    if (method === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify([]),
      });
    } else {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({}),
      });
    }
  });

  // Intercept Mixpanel analytics
  await page.route("**/api.mixpanel.com/**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ status: 1 }),
    });
  });
}

/**
 * Navigate to an authenticated screen.
 *
 * The approach:
 * 1. A mock session is injected into localStorage via addInitScript
 * 2. The Supabase SDK reads this session during initialization
 * 3. The SessionService recognizes the user as signed in
 * 4. The ProfileService fetches the profile (intercepted, returns onboarded)
 * 5. The router allows access to /tabs (subscription check is disabled via JS patch)
 */
export async function navigateWithMockAuth(
  page: Page,
  targetTab?: "Home" | "Routine" | "Supps" | "Symptoms" | "Chat",
): Promise<void> {
  await setupMockAuth(page);

  // Navigate directly to the tabs screen
  await page.goto("/#/tabs");
  await waitForFlutterReady(page);

  // Navigate to the target tab if specified and not Home (default)
  if (targetTab && targetTab !== "Home") {
    const bodyText = await page.textContent("body");
    if (bodyText?.includes(targetTab)) {
      await page
        .getByText(targetTab, { exact: false })
        .first()
        .click({ force: true });
      await page.waitForTimeout(1500);
      await enableFlutterSemantics(page);
    }
  }
}
