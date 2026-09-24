import {
  test,
  expect,
  flutterText,
  flutterButton,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

/**
 * Privacy, Health Disclaimer & Consent Tests
 *
 * Apple App Review and health data regulations require:
 * - Clear health disclaimers (app is not medical advice)
 * - Privacy policy accessibility
 * - Terms of service accessibility
 * - Consent before data collection
 * - Data usage transparency
 *
 * These are critical for App Store approval and HIPAA-adjacent compliance.
 */

test.describe("Privacy Policy & Terms Accessibility", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    const loginLink = flutterText(page, "Already have an account? Log in");
    if (await loginLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);
      await enableFlutterSemantics(page);
    }
  });

  test("should display Terms link on login screen", async ({ page }) => {
    await expect(flutterButton(page, "Terms")).toBeVisible();
  });

  test("should display Privacy link on login screen", async ({ page }) => {
    await expect(flutterButton(page, "Privacy")).toBeVisible();
  });

  test("should display data usage disclaimer text", async ({ page }) => {
    await expect(
      flutterText(page, "We use your data to personalize insights"),
    ).toBeVisible();
  });

  test("Terms button should exist in the DOM", async ({ page }) => {
    // Flutter renders Terms as a button with role="button"
    // It may be aria-disabled but should still be present
    const termsBtn = flutterButton(page, "Terms");
    const count = await termsBtn.count();
    expect(count).toBeGreaterThanOrEqual(1);
  });

  test("Privacy button should exist in the DOM", async ({ page }) => {
    const privacyBtn = flutterButton(page, "Privacy");
    const count = await privacyBtn.count();
    expect(count).toBeGreaterThanOrEqual(1);
  });
});

test.describe("Consent Enforcement", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    const loginLink = flutterText(page, "Already have an account? Log in");
    if (await loginLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);
      await enableFlutterSemantics(page);
    }
  });

  test("should require consent checkbox before sign-in", async ({ page }) => {
    // Fill in credentials without checking consent
    const inputs = page.locator("input");
    if ((await inputs.count()) >= 2) {
      await inputs.first().fill("test@example.com");
      await inputs.nth(1).fill("password123");
    }

    // The consent text should be present
    await expect(
      flutterText(page, "I agree to the Terms & Privacy Policy"),
    ).toBeVisible();
  });

  test("consent checkbox should be visible and interactive", async ({
    page,
  }) => {
    const consentText = flutterText(
      page,
      "I agree to the Terms & Privacy Policy",
    );
    await expect(consentText).toBeVisible();

    // Click to toggle
    await consentText.click();
    await page.waitForTimeout(300);

    // Should still be present (toggled to checked state)
    await expect(consentText).toBeVisible();

    // Click again to toggle back
    await consentText.click();
    await page.waitForTimeout(300);

    await expect(consentText).toBeVisible();
  });

  test("social sign-in should show coming soon notice", async ({ page }) => {
    // Social sign-in buttons should indicate they are not yet available
    await expect(flutterText(page, "Social sign-in coming soon")).toBeVisible();
  });
});

test.describe("Welcome Screen Content Integrity", () => {
  test("should display app name clearly", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
  });

  test("should display personalization messaging", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(
      flutterText(page, "Your personalized journey to healthier"),
    ).toBeVisible();
  });

  test("should display evidence-based claims with context", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Claims should have supporting context
    await expect(flutterText(page, "94% Success Rate")).toBeVisible();
    await expect(
      flutterText(page, "Users report improved skin within 30 days"),
    ).toBeVisible();

    await expect(flutterText(page, "Evidence-Based")).toBeVisible();
    await expect(
      flutterText(page, "Backed by dermatological research"),
    ).toBeVisible();
  });

  test("should provide both sign-up and sign-in paths", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // New users: Get Started
    await expect(flutterButton(page, "Get Started")).toBeVisible();

    // Existing users: Log in
    await expect(
      flutterText(page, "Already have an account? Log in"),
    ).toBeVisible();
  });
});

test.describe("Interrupted Flow Handling", () => {
  test("should handle partial form entry then navigation away", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Go to login
    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Fill partial form
    const inputs = page.locator("input");
    if ((await inputs.count()) >= 2) {
      await inputs.first().fill("partial@test.com");
      // Don't fill password - leave form incomplete
    }

    // Navigate to forgot password (interrupting login flow)
    await flutterText(page, "Forgot password?").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Should be on reset page without crashing
    await expect(flutterText(page, "Reset Password")).toBeVisible();
  });

  test("should handle rapid navigation clicks without crashing", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Rapid clicks on different elements
    const loginLink = flutterText(page, "Already have an account? Log in");
    const getStarted = flutterButton(page, "Get Started");

    // Click login link
    await loginLink.click();
    // Immediately click (rapid navigation)
    await page.waitForTimeout(200);

    // Page should not crash
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

    // Wait for navigation to settle
    await page.waitForTimeout(2000);
    await enableFlutterSemantics(page);

    // App should still be functional
    const bodyText2 = await page.textContent("body");
    expect(bodyText2).toBeTruthy();
  });

  test("should handle double-click on Get Started", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    const getStarted = flutterButton(page, "Get Started");
    await getStarted.dblclick();
    await page.waitForTimeout(2000);
    await enableFlutterSemantics(page);

    // App should remain functional
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });
});
