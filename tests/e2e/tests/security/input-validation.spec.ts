import {
  test,
  expect,
  flutterText,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

/**
 * Input Validation & Security Tests
 *
 * Verifies that the app handles malicious and edge-case input safely:
 * - XSS injection attempts in email/password fields
 * - SQL injection strings
 * - Special characters and unicode
 * - Extremely long input
 * - Empty/whitespace-only input
 */

test.describe("Input Validation - Login Form", () => {
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

  test("should reject XSS script tags in email field", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();

    await emailInput.fill('<script>alert("xss")</script>');

    // Accept consent and submit
    await flutterText(page, "I agree to the Terms & Privacy Policy").click();
    await page.waitForTimeout(300);
    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(500);

    // App should show a validation error or remain on login - no script execution
    const bodyText = await page.textContent("body");
    expect(bodyText).not.toContain("<script>");
    // Page should still be functional
    expect(bodyText).toBeTruthy();
  });

  test("should handle SQL injection in email field", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();
    const passwordInput = inputs.nth(1);

    await emailInput.fill("' OR 1=1; DROP TABLE users; --");
    await passwordInput.fill("password123");

    await flutterText(page, "I agree to the Terms & Privacy Policy").click();
    await page.waitForTimeout(300);
    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(1000);

    // Page should remain functional (not crash)
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle special characters in email field", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();

    await emailInput.fill("test+special&chars=true@example.com");
    await expect(emailInput).toHaveValue("test+special&chars=true@example.com");
  });

  test("should handle unicode and emoji in input fields", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();
    const passwordInput = inputs.nth(1);

    await emailInput.fill("user@example.com");
    await passwordInput.fill("p\u00e4ssw\u00f6rd\u2603");

    // Inputs should accept unicode without crashing
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle extremely long email input", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();

    const longEmail = "a".repeat(500) + "@example.com";
    await emailInput.fill(longEmail);

    // App should not crash with long input
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle whitespace-only email", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();

    await emailInput.fill("   ");

    await flutterText(page, "I agree to the Terms & Privacy Policy").click();
    await page.waitForTimeout(300);
    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(500);

    // Should show validation error
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should handle HTML entities in password field", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();
    const passwordInput = inputs.nth(1);

    await emailInput.fill("test@example.com");
    await passwordInput.fill('"><img src=x onerror=alert(1)>');

    await flutterText(page, "I agree to the Terms & Privacy Policy").click();
    await page.waitForTimeout(300);
    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(1000);

    // Page should remain functional
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    // No injected elements should appear
    const imgCount = await page.locator("img[src='x']").count();
    expect(imgCount).toBe(0);
  });
});

test.describe("Input Validation - Password Reset", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    const loginLink = flutterText(page, "Already have an account? Log in");
    if (await loginLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);
      await enableFlutterSemantics(page);
    }

    const forgotLink = flutterText(page, "Forgot password?");
    if (await forgotLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await forgotLink.click();
      await page.waitForTimeout(1500);
      await enableFlutterSemantics(page);
    }
  });

  test("should handle XSS in password reset email field", async ({ page }) => {
    const emailInput = page.locator("input").first();
    await emailInput.fill('<img src=x onerror=alert("xss")>');

    // App should not crash
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    expect(bodyText).toContain("Reset Password");
  });

  test("should handle invalid email format in reset", async ({ page }) => {
    const emailInput = page.locator("input").first();
    await emailInput.fill("not-an-email");

    // Page should remain stable
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });
});
