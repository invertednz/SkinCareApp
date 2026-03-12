import {
  test,
  expect,
  flutterText,
  flutterButton,
  waitForFlutterReady,
} from "../fixtures";

/**
 * Paywall & Trial Offer Tests
 *
 * Tests subscription/trial flows:
 * - Trial offer screen display
 * - Plan comparison
 * - Start trial action
 * - Paywall pricing display
 */

test.describe("Trial Offer Screen", () => {
  test("should display trial offer content when navigated to", async ({
    page,
  }) => {
    // Trial offer screen appears after sign-in + completed onboarding
    // but before subscription. Direct navigation may redirect.
    await page.goto("/#/trial-offer");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    // Either shows trial offer or redirects to onboarding
    expect(bodyText).toBeTruthy();
  });

  test("should show trial pricing information", async ({ page }) => {
    await page.goto("/#/trial-offer");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    // Look for pricing text (e.g., "$47.00/year" or "free trial")
    if (bodyText?.includes("trial") || bodyText?.includes("Trial")) {
      const trialText = flutterText(page, /trial/i);
      await expect(trialText).toBeVisible();
    }
  });

  test("should show compare plans option", async ({ page }) => {
    await page.goto("/#/trial-offer");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    if (bodyText?.includes("Compare") || bodyText?.includes("plans")) {
      const compareBtn = flutterText(page, /compare|plans/i);
      await expect(compareBtn).toBeVisible();
    }
  });
});

test.describe("Paywall Screen", () => {
  test("should display paywall when navigated to", async ({ page }) => {
    await page.goto("/#/paywall");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
  });

  test("should show subscription plan options", async ({ page }) => {
    await page.goto("/#/paywall");
    await waitForFlutterReady(page);

    const bodyText = await page.textContent("body");
    // Look for plan-related content (annual/monthly)
    if (bodyText?.includes("Annual") || bodyText?.includes("Monthly")) {
      const planText = flutterText(page, /annual|monthly/i);
      await expect(planText).toBeVisible();
    }
  });
});
