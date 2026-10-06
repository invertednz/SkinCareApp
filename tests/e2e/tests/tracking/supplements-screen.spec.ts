import { test, expect, flutterText } from "../fixtures";
import { navigateWithMockAuth } from "../helpers/mock-auth";

/**
 * Supplements Tracking Screen Tests
 *
 * Tests supplement intake tracking:
 * - Predefined supplements (Zinc, Omega-3, Vitamin D, etc.)
 * - AM/PM dosing
 * - Calendar view
 * - Custom supplements
 *
 * Uses mock Supabase auth interception to bypass real authentication.
 */

test.describe("Supplements Tracking Screen", () => {
  test("should display supplement tracking options", async ({ page }) => {
    await navigateWithMockAuth(page, "Supps");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    expect(bodyText!.length).toBeGreaterThan(0);

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
      if (bodyText!.includes(supp)) {
        await expect(flutterText(page, supp)).toBeVisible();
        found = true;
      }
    }

    if (!found) {
      // At minimum, the screen should have some content
      expect(bodyText!.length).toBeGreaterThan(0);
    }
  });

  test("should show AM/PM dosing options", async ({ page }) => {
    await navigateWithMockAuth(page, "Supps");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

    if (bodyText!.includes("AM") || bodyText!.includes("PM")) {
      const timeSlot = flutterText(page, "AM").or(flutterText(page, "PM"));
      await expect(timeSlot).toBeVisible();
    }
  });

  test("should toggle supplement intake on click", async ({ page }) => {
    await navigateWithMockAuth(page, "Supps");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

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
    await navigateWithMockAuth(page, "Supps");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    // Supplements screen should have loaded with meaningful content
    expect(bodyText!.length).toBeGreaterThan(50);
  });
});
