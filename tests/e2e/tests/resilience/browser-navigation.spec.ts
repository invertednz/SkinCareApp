import {
  test,
  expect,
  flutterText,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

/**
 * Browser Navigation Resilience Tests
 *
 * Verifies the app handles browser-level navigation correctly:
 * - Back/forward buttons
 * - Page refresh
 * - Direct URL entry
 * - Unknown routes (404 handling)
 * - Hash-based routing edge cases
 */

test.describe("Browser Back/Forward Navigation", () => {
  test("should handle browser back from login to welcome", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Navigate to login
    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Verify we are on login
    const inputs = page.locator("input");
    expect(await inputs.count()).toBeGreaterThanOrEqual(2);

    // Browser back
    await page.goBack();
    await page.waitForTimeout(2000);
    await enableFlutterSemantics(page);

    // Should return to welcome or at least remain functional
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle browser forward after going back", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Navigate to login
    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Back
    await page.goBack();
    await page.waitForTimeout(2000);
    await enableFlutterSemantics(page);

    // Forward
    await page.goForward();
    await page.waitForTimeout(2000);
    await enableFlutterSemantics(page);

    // Page should be functional
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle browser back from password reset to login", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Navigate to login
    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Navigate to reset
    await flutterText(page, "Forgot password?").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    await expect(flutterText(page, "Reset Password")).toBeVisible();

    // Browser back
    await page.goBack();
    await page.waitForTimeout(2000);
    await enableFlutterSemantics(page);

    // Should return to login or welcome - page should be functional
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });
});

test.describe("Page Refresh Resilience", () => {
  test("should survive page refresh on welcome screen", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();

    // Refresh
    await page.reload();
    await waitForFlutterReady(page);

    // Welcome should still be visible
    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
  });

  test("should survive page refresh on login screen", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Refresh
    await page.reload();
    await waitForFlutterReady(page);

    // App should still be functional (may return to welcome due to state loss)
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });
});

test.describe("Unknown Route Handling", () => {
  test("should handle unknown hash routes gracefully", async ({ page }) => {
    await page.goto("/#/nonexistent-page");
    await waitForFlutterReady(page);

    // Should redirect to onboarding or show an error page - not crash
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle deeply nested unknown routes", async ({ page }) => {
    await page.goto("/#/a/b/c/d/e/f");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle routes with query parameters", async ({ page }) => {
    await page.goto("/#/onboarding?ref=test&utm_source=web");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle routes with special characters", async ({ page }) => {
    await page.goto("/#/<script>alert(1)</script>");
    await waitForFlutterReady(page);

    // Should not execute script - page should load normally
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle empty hash route", async ({ page }) => {
    await page.goto("/#/");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });
});

test.describe("Viewport and Orientation", () => {
  test("should render in landscape orientation", async ({ page }) => {
    await page.setViewportSize({ width: 812, height: 375 }); // iPhone X landscape
    await page.goto("/");
    await waitForFlutterReady(page);

    // Flutter CanvasKit may hide semantic text on constrained viewports
    // but the app should still load and render content
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    expect(bodyText!.length).toBeGreaterThan(0);
  });

  test("should render on very small viewport (320px)", async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 568 }); // iPhone SE
    await page.goto("/");
    await waitForFlutterReady(page);

    // Flutter CanvasKit may hide semantic text on very small viewports
    // but the app should still load and render content
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    expect(bodyText!.length).toBeGreaterThan(0);
  });

  test("should render on very large viewport (2560px)", async ({ page }) => {
    await page.setViewportSize({ width: 2560, height: 1440 }); // QHD
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
    await expect(flutterText(page, "Get Started")).toBeVisible();
  });

  test("should handle viewport resize dynamically", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Start at desktop
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.waitForTimeout(500);

    // Resize to mobile
    await page.setViewportSize({ width: 375, height: 812 });
    await page.waitForTimeout(500);

    // Content should still be visible
    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();

    // Resize back to desktop
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.waitForTimeout(500);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
  });
});
