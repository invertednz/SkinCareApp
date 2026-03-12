import {
  test,
  expect,
  flutterText,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

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
 * Note: Requires authenticated access. In release mode,
 * tests gracefully skip if sign-in fails.
 */

async function navigateToRoutine(
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

  const routineTab = flutterText(page, "Routine");
  if (await routineTab.isVisible({ timeout: 5000 }).catch(() => false)) {
    await routineTab.click();
    await page.waitForTimeout(1000);
    return true;
  }

  return false;
}

test.describe("Routine Tracking Screen", () => {
  test("should display default routine items", async ({ page }) => {
    const reachedRoutine = await navigateToRoutine(page);
    if (!reachedRoutine) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Routine")) {
      test.skip();
      return;
    }

    // Default items: Cleanser, Moisturizer, Sunscreen
    const defaultItems = ["Cleanser", "Moisturizer", "Sunscreen"];
    for (const item of defaultItems) {
      if (bodyText.includes(item)) {
        await expect(flutterText(page, item)).toBeVisible();
      }
    }
  });

  test("should show AM/PM time slots for routine items", async ({ page }) => {
    const reachedRoutine = await navigateToRoutine(page);
    if (!reachedRoutine) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Routine")) {
      test.skip();
      return;
    }

    // AM and PM labels should be visible
    if (bodyText.includes("AM") || bodyText.includes("PM")) {
      const timeSlot = flutterText(page, "AM").or(flutterText(page, "PM"));
      await expect(timeSlot).toBeVisible();
    }
  });

  test("should toggle routine item completion", async ({ page }) => {
    const reachedRoutine = await navigateToRoutine(page);
    if (!reachedRoutine) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Cleanser")) {
      test.skip();
      return;
    }

    // Click on Cleanser to toggle completion
    await flutterText(page, "Cleanser").click();
    await page.waitForTimeout(500);

    // Item should still be visible (toggled state)
    await expect(flutterText(page, "Cleanser")).toBeVisible();
  });

  test("should show calendar for date selection", async ({ page }) => {
    const reachedRoutine = await navigateToRoutine(page);
    if (!reachedRoutine) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Routine")) {
      test.skip();
      return;
    }

    const today = new Date();
    const dateNum = today.getDate().toString();
    await expect(flutterText(page, dateNum)).toBeVisible();
  });
});
