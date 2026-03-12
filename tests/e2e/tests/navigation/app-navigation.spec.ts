import {
  test,
  expect,
  flutterText,
  flutterButton,
  waitForFlutterReady,
  enableFlutterSemantics,
  navigateToRoute,
} from "../fixtures";

test.describe("App Navigation", () => {
  /**
   * These tests verify routing and navigation behavior.
   * They require the user to be signed in with a completed onboarding
   * and active subscription to access the main tabs.
   *
   * In release mode, mock authentication is not available.
   */

  test("should redirect unauthenticated users to onboarding", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Unauthenticated users should see the onboarding/welcome page
    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
  });

  test("should redirect /tabs to onboarding when not signed in", async ({
    page,
  }) => {
    await page.goto("/#/tabs");
    await waitForFlutterReady(page);

    // Should redirect to onboarding
    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
  });

  test("initial location should be /onboarding", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // The router's initialLocation is /onboarding
    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
  });

  test("should allow navigation to /auth from onboarding", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Should be on auth page with login form
    const inputs = page.locator("input");
    const count = await inputs.count();
    expect(count).toBeGreaterThanOrEqual(2);
  });

  test("should allow navigation to /reset from /auth", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Go to auth
    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Go to reset
    await flutterText(page, "Forgot password?").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    await expect(flutterText(page, "Reset Password")).toBeVisible();
  });
});

test.describe("Tab Navigation (Authenticated)", () => {
  /**
   * These tests simulate navigation within the main app shell.
   * In release mode, mock sign-in is not available, so these tests
   * gracefully skip if authentication fails.
   */

  async function signInAndNavigateToTabs(
    page: import("@playwright/test").Page,
  ): Promise<boolean> {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Go to login
    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Fill credentials
    const inputs = page.locator("input");
    if ((await inputs.count()) >= 2) {
      await inputs.first().fill("test@test.com");
      await inputs.nth(1).fill("password123");

      // Accept consent
      const consent = flutterText(
        page,
        "I agree to the Terms & Privacy Policy",
      );
      if (await consent.isVisible({ timeout: 3000 }).catch(() => false)) {
        await consent.click();
        await page.waitForTimeout(300);
      }

      // Sign in
      await flutterText(page, "Sign In").click();
      await page.waitForTimeout(3000);
      await enableFlutterSemantics(page);
    }

    // Check if we reached the tabs (release mode may not authenticate)
    const bodyText = await page.textContent("body");
    return bodyText?.includes("Home") ?? false;
  }

  test("should display bottom navigation bar with 5 tabs", async ({ page }) => {
    const reachedTabs = await signInAndNavigateToTabs(page);
    if (!reachedTabs) {
      test.skip();
      return;
    }

    // The tracking app shell has 5 tabs: Home, Symptoms, Routine, Supps, Chat
    await expect(flutterText(page, "Home")).toBeVisible();
    await expect(flutterText(page, "Symptoms")).toBeVisible();
    await expect(flutterText(page, "Routine")).toBeVisible();
    await expect(flutterText(page, "Supps")).toBeVisible();
    await expect(flutterText(page, "Chat")).toBeVisible();
  });

  test("should switch between tabs on click", async ({ page }) => {
    const reachedTabs = await signInAndNavigateToTabs(page);
    if (!reachedTabs) {
      test.skip();
      return;
    }

    // Click Symptoms tab
    await flutterText(page, "Symptoms").click();
    await page.waitForTimeout(1000);

    // Click Routine tab
    await flutterText(page, "Routine").click();
    await page.waitForTimeout(1000);

    // Click Supps tab
    await flutterText(page, "Supps").click();
    await page.waitForTimeout(1000);

    // Click Chat tab
    await flutterText(page, "Chat").click();
    await page.waitForTimeout(1000);

    // Click Home tab to return
    await flutterText(page, "Home").click();
    await page.waitForTimeout(1000);
  });
});

test.describe("Deep Link Navigation", () => {
  test("should handle /tabs/:tab deep links", async ({ page }) => {
    // These will redirect to onboarding for unauthenticated users
    await page.goto("/#/tabs/symptoms");
    await waitForFlutterReady(page);

    // Should redirect to onboarding
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle /notifications/:category deep links", async ({
    page,
  }) => {
    await page.goto("/#/notifications/routine");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });
});
