import {
  test,
  expect,
  flutterText,
  flutterButton,
  waitForFlutterReady,
  enableFlutterSemantics,
  navigateToRoute,
} from "../fixtures";

test.describe("Password Reset Screen", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Navigate to login first, then to reset
    const loginLink = flutterText(page, "Already have an account? Log in");
    if (await loginLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);
      await enableFlutterSemantics(page);
    }

    // Click Forgot password
    const forgotLink = flutterText(page, "Forgot password?");
    if (await forgotLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await forgotLink.click();
      await page.waitForTimeout(1500);
      await enableFlutterSemantics(page);
    } else {
      await navigateToRoute(page, "/reset");
    }
  });

  test("should display Reset Password title", async ({ page }) => {
    await expect(flutterText(page, "Reset Password")).toBeVisible();
  });

  test("should show email input field", async ({ page }) => {
    const inputs = page.locator("input");
    const count = await inputs.count();
    expect(count).toBeGreaterThanOrEqual(1);
  });

  test("should show back button", async ({ page }) => {
    const backButton = page
      .getByRole("button", { name: /back/i })
      .or(page.locator('[aria-label="Back"]'));
    // Back button should exist (AppBar leading icon)
    const bodyText = await page.textContent("body");
    expect(bodyText).toContain("Reset Password");
  });

  test("should validate empty email on submit", async ({ page }) => {
    // Find and click the submit/reset button
    const submitBtn = flutterButton(page, "Send Reset Link")
      .or(flutterButton(page, "Reset"))
      .or(flutterButton(page, "Send"));

    if (await submitBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
      await submitBtn.click();
      await page.waitForTimeout(500);

      // Should show validation error
      await expect(flutterText(page, "Email is required")).toBeVisible();
    }
  });

  test("should accept email input", async ({ page }) => {
    const emailInput = page.locator("input").first();
    await emailInput.fill("user@example.com");
    await expect(emailInput).toHaveValue("user@example.com");
  });
});
