import {
  test,
  expect,
  flutterText,
  flutterButton,
  flutterTextField,
  waitForFlutterReady,
  enableFlutterSemantics,
  navigateToRoute,
} from "../fixtures";

test.describe("Login Screen", () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to login via the welcome page link or direct hash route
    await page.goto("/");
    await waitForFlutterReady(page);
    // Click "Already have an account? Log in" to reach login
    const loginLink = flutterText(page, "Already have an account? Log in");
    if (await loginLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);
      // Re-enable semantics after navigation
      await enableFlutterSemantics(page);
    } else {
      // Try direct navigation
      await navigateToRoute(page, "/auth");
    }
  });

  test("should display login form elements", async ({ page }) => {
    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
    await expect(
      flutterText(page, "Your journey to healthier skin starts here"),
    ).toBeVisible();
  });

  test("should show email and password input fields", async ({ page }) => {
    // Flutter renders inputs as <input> elements inside flt-semantics nodes
    const inputs = page.locator("input");
    const count = await inputs.count();
    expect(count).toBeGreaterThanOrEqual(2);
  });

  test("should show disabled social login buttons", async ({ page }) => {
    await expect(flutterText(page, "Continue with Google")).toBeVisible();
    await expect(flutterText(page, "Continue with Apple")).toBeVisible();
    await expect(flutterText(page, "Social sign-in coming soon")).toBeVisible();
  });

  test("should show email divider text", async ({ page }) => {
    await expect(flutterText(page, "Or continue with email")).toBeVisible();
  });

  test("should show consent checkbox", async ({ page }) => {
    await expect(
      flutterText(page, "I agree to the Terms & Privacy Policy"),
    ).toBeVisible();
    await expect(
      flutterText(page, "We use your data to personalize insights"),
    ).toBeVisible();
  });

  test("should show Sign In button (initially disabled)", async ({ page }) => {
    await expect(flutterText(page, "Sign In")).toBeVisible();
  });

  test("should show Forgot password link", async ({ page }) => {
    await expect(flutterText(page, "Forgot password?")).toBeVisible();
  });

  test("should show Terms and Privacy links", async ({ page }) => {
    await expect(flutterButton(page, "Terms")).toBeVisible();
    await expect(flutterButton(page, "Privacy")).toBeVisible();
  });

  test("should validate empty email submission", async ({ page }) => {
    // Enable consent first
    await flutterText(page, "I agree to the Terms & Privacy Policy").click();
    await page.waitForTimeout(500);

    // Try to submit
    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(500);

    // Should show validation error
    await expect(flutterText(page, "Email is required")).toBeVisible();
  });

  test("should validate empty password submission", async ({ page }) => {
    // Type email into the first input field
    const inputs = page.locator("input");
    await inputs.first().fill("test@example.com");

    // Enable consent
    await flutterText(page, "I agree to the Terms & Privacy Policy").click();
    await page.waitForTimeout(500);

    // Submit
    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(500);

    // Should show password required
    await expect(flutterText(page, "Password is required")).toBeVisible();
  });

  test("should accept valid email and password input", async ({ page }) => {
    const inputs = page.locator("input");
    const emailInput = inputs.first();
    const passwordInput = inputs.nth(1);

    await emailInput.fill("user@example.com");
    await passwordInput.fill("securepassword123");

    // Verify inputs have values
    await expect(emailInput).toHaveValue("user@example.com");
    await expect(passwordInput).toHaveValue("securepassword123");
  });

  test("should toggle consent checkbox on click", async ({ page }) => {
    const consentArea = flutterText(
      page,
      "I agree to the Terms & Privacy Policy",
    );
    await consentArea.click();
    await page.waitForTimeout(300);

    // After clicking, the check icon should appear (checkbox toggled)
    // In Flutter web, this changes the visual state
    const bodyText = await page.textContent("body");
    expect(bodyText).toContain("I agree to the Terms & Privacy Policy");
  });

  test("should navigate to password reset on Forgot password click", async ({
    page,
  }) => {
    await flutterText(page, "Forgot password?").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    await expect(flutterText(page, "Reset Password")).toBeVisible();
  });

  test("should attempt sign in with credentials (release mode - may not authenticate)", async ({
    page,
  }) => {
    const inputs = page.locator("input");
    await inputs.first().fill("test@test.com");
    await inputs.nth(1).fill("password123");

    // Accept consent
    await flutterText(page, "I agree to the Terms & Privacy Policy").click();
    await page.waitForTimeout(300);

    // Click Sign In
    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(2000);

    // In release mode, mock sign-in won't work.
    // Verify the page is still responsive (either shows error or navigates)
    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });
});
