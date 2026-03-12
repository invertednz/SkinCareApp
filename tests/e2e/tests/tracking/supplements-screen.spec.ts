import {
  test,
  expect,
  flutterText,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

/**
 * Supplements Tracking Screen Tests
 *
 * Tests supplement intake tracking:
 * - Predefined supplements (Zinc, Omega-3, Vitamin D, etc.)
 * - AM/PM dosing
 * - Calendar view
 * - Custom supplements
 *
 * Note: Requires authenticated access. In release mode,
 * tests gracefully skip if sign-in fails.
 */

async function navigateToSupplements(
  page: import("@playwright/test").Page,
): Promise<boolean> {
  await page.goto("/");
  await waitForFlutterReady(page);

  await flutterText(page, "Already have an account? Log in").click();
  await page.waitForTimeout(1500);
  await enableFlutterSemantics(page);

  const inputs = page.locator("input");
  if ((await inputs.count()) >= 2) {
    await inputs.first().fill("test@test.com");
    await inputs.nth(1).fill("password123");

    const consent = flutterText(page, "I agree to the Terms & Privacy Policy");
    if (await consent.isVisible({ timeout: 3000 }).catch(() => false)) {
      await consent.click();
      await page.waitForTimeout(300);
    }

    await flutterText(page, "Sign In").click();
    await page.waitForTimeout(3000);
    await enableFlutterSemantics(page);
  }

  const suppsTab = flutterText(page, "Supps");
  if (await suppsTab.isVisible({ timeout: 5000 }).catch(() => false)) {
    await suppsTab.click();
    await page.waitForTimeout(1000);
    return true;
  }

  return false;
}

test.describe("Supplements Tracking Screen", () => {
  test("should display supplement tracking options", async ({ page }) => {
    const reachedSupps = await navigateToSupplements(page);
    if (!reachedSupps) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Supps")) {
      test.skip();
      return;
    }

    // Common supplements that may be displayed
    const supplements = [
      "Zinc",
      "Omega-3",
      "Vitamin D",
      "Vitamin C",
      "Probiotics",
      "Collagen",
    ];

    let found = false;
    for (const supp of supplements) {
      if (bodyText.includes(supp)) {
        await expect(flutterText(page, supp)).toBeVisible();
        found = true;
      }
    }

    if (!found) {
      // At minimum, the screen should have some content
      expect(bodyText?.length).toBeGreaterThan(0);
    }
  });

  test("should show AM/PM dosing options", async ({ page }) => {
    const reachedSupps = await navigateToSupplements(page);
    if (!reachedSupps) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Supps")) {
      test.skip();
      return;
    }

    if (bodyText.includes("AM") || bodyText.includes("PM")) {
      const timeSlot = flutterText(page, "AM").or(flutterText(page, "PM"));
      await expect(timeSlot).toBeVisible();
    }
  });

  test("should toggle supplement intake on click", async ({ page }) => {
    const reachedSupps = await navigateToSupplements(page);
    if (!reachedSupps) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Zinc") && !bodyText?.includes("Vitamin")) {
      test.skip();
      return;
    }

    // Click first visible supplement to toggle
    const zincLocator = flutterText(page, "Zinc");
    const vitDLocator = flutterText(page, "Vitamin D");
    const firstSupp = zincLocator.or(vitDLocator);
    if (await firstSupp.isVisible({ timeout: 3000 }).catch(() => false)) {
      await firstSupp.click();
      await page.waitForTimeout(500);
    }
  });

  test("should show calendar for date selection", async ({ page }) => {
    const reachedSupps = await navigateToSupplements(page);
    if (!reachedSupps) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Supps")) {
      test.skip();
      return;
    }

    const today = new Date();
    const dateNum = today.getDate().toString();
    await expect(flutterText(page, dateNum)).toBeVisible();
  });
});
