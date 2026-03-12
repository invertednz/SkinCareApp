import {
  test,
  expect,
  flutterText,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

/**
 * Visual Regression Tests
 *
 * Captures screenshots of key screens for visual comparison.
 * On first run, these create baseline screenshots.
 * On subsequent runs, they compare against baselines.
 *
 * Run with: npx playwright test tests/visual --update-snapshots
 * to update baselines.
 */

test.describe("Visual Regression", () => {
  test("welcome page screenshot", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();

    await expect(page).toHaveScreenshot("welcome-page.png", {
      maxDiffPixelRatio: 0.1,
      timeout: 15_000,
    });
  });

  test("login page screenshot", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    await expect(flutterText(page, "Sign In")).toBeVisible();

    await expect(page).toHaveScreenshot("login-page.png", {
      maxDiffPixelRatio: 0.1,
      timeout: 15_000,
    });
  });

  test("password reset page screenshot", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    await flutterText(page, "Forgot password?").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    await expect(flutterText(page, "Reset Password")).toBeVisible();

    await expect(page).toHaveScreenshot("password-reset-page.png", {
      maxDiffPixelRatio: 0.1,
      timeout: 15_000,
    });
  });
});
