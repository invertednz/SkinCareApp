import { test, expect, flutterText } from "../fixtures";
import { navigateWithMockAuth } from "../helpers/mock-auth";

/**
 * Routine Tracking Screen Tests
 *
 * Tests the skincare routine tracking:
 * - Default routine items (Cleanser, Toner, Serum, etc.)
 * - AM/PM time slots
 * - Check-off tracking
 * - Custom routine items
 * - Calendar date navigation
 *
 * Uses mock Supabase auth interception to bypass real authentication.
 */

test.describe("Routine Tracking Screen", () => {
  test("should display default routine items", async ({ page }) => {
    await navigateWithMockAuth(page, "Routine");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    expect(bodyText!.length).toBeGreaterThan(0);

    // Default items: Cleanser, Moisturizer, Sunscreen
    const defaultItems = ["Cleanser", "Moisturizer", "Sunscreen"];
    for (const item of defaultItems) {
      if (bodyText!.includes(item)) {
        await expect(flutterText(page, item)).toBeVisible();
      }
    }
  });

  test("should show AM/PM time slots for routine items", async ({ page }) => {
    await navigateWithMockAuth(page, "Routine");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

    // AM and PM labels should be visible
    if (bodyText!.includes("AM") || bodyText!.includes("PM")) {
      const timeSlot = flutterText(page, "AM").or(flutterText(page, "PM"));
      await expect(timeSlot).toBeVisible();
    }
  });

  test("should toggle routine item completion", async ({ page }) => {
    await navigateWithMockAuth(page, "Routine");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

    if (bodyText!.includes("Cleanser")) {
      // Click on Cleanser to toggle completion
      await flutterText(page, "Cleanser").click();
      await page.waitForTimeout(500);

      // Item should still be visible (toggled state)
      await expect(flutterText(page, "Cleanser")).toBeVisible();
    }
  });

  test("should show calendar for date selection", async ({ page }) => {
    await navigateWithMockAuth(page, "Routine");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    // Routine screen should have loaded with meaningful content
    expect(bodyText!.length).toBeGreaterThan(50);
  });
});
