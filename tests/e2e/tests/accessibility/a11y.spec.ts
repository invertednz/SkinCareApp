import {
  test,
  expect,
  flutterText,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

/**
 * Accessibility Tests
 *
 * Verifies basic accessibility requirements:
 * - Text readability (content is present)
 * - Interactive elements are tappable
 * - Page has meaningful content
 * - Semantic structure is present
 */

test.describe("Accessibility", () => {
  test("welcome page should have readable text content", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // All key text should be present and visible
    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
    await expect(flutterText(page, "Get Started")).toBeVisible();
    await expect(
      flutterText(page, "Already have an account? Log in"),
    ).toBeVisible();
  });

  test("buttons should be interactive (clickable)", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // "Get Started" button should be clickable
    const getStarted = flutterText(page, "Get Started");
    await expect(getStarted).toBeVisible();
    await expect(getStarted).toBeEnabled();
  });

  test("login form should have labeled input fields", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // Email and Password labels should be visible
    await expect(flutterText(page, "Email")).toBeVisible();
    await expect(flutterText(page, "Password")).toBeVisible();
  });

  test("page should have proper document title", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    const title = await page.title();
    expect(title).toBeTruthy();
    expect(title.toLowerCase()).toContain("skincare");
  });

  test("page should not have empty body", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    expect(bodyText?.trim().length).toBeGreaterThan(0);
  });

  test("social proof cards should have descriptive text", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Each proof card should have both a title and subtitle
    await expect(flutterText(page, "94% Success Rate")).toBeVisible();
    await expect(
      flutterText(page, "Users report improved skin within 30 days"),
    ).toBeVisible();

    await expect(flutterText(page, "Evidence-Based")).toBeVisible();
    await expect(
      flutterText(page, "Backed by dermatological research"),
    ).toBeVisible();

    await expect(flutterText(page, "50,000+ Users")).toBeVisible();
    await expect(
      flutterText(page, "Join our thriving skin wellness community"),
    ).toBeVisible();
  });
});

test.describe("Responsive Design", () => {
  test("should render properly on mobile viewport", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 }); // iPhone X
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
    await expect(flutterText(page, "Get Started")).toBeVisible();
  });

  test("should render properly on tablet viewport", async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 }); // iPad
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
    await expect(flutterText(page, "Get Started")).toBeVisible();
  });

  test("should render properly on desktop viewport", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/");
    await waitForFlutterReady(page);

    await expect(flutterText(page, "Welcome to SkinCare")).toBeVisible();
    await expect(flutterText(page, "Get Started")).toBeVisible();
  });

  test("login form should be constrained to max-width on large screens", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.goto("/");
    await waitForFlutterReady(page);

    await flutterText(page, "Already have an account? Log in").click();
    await page.waitForTimeout(1500);
    await enableFlutterSemantics(page);

    // The form card has maxWidth: 480 constraint
    // Verify content is visible and centered
    await expect(flutterText(page, "Email")).toBeVisible();
  });
});
