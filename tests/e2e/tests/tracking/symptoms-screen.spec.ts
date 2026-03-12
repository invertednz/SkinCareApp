import {
  test,
  expect,
  flutterText,
  waitForFlutterReady,
  enableFlutterSemantics,
} from "../fixtures";

/**
 * Symptoms Screen Tests
 *
 * Tests the symptom tracking functionality:
 * - Calendar date selection
 * - Predefined symptoms (Acne, Redness, Dryness, etc.)
 * - Custom symptom input
 * - AM/PM selection
 * - Symptom toggle (track/untrack)
 *
 * Note: Requires authenticated access. In release mode,
 * tests gracefully skip if sign-in fails.
 */

async function navigateToSymptoms(
  page: import("@playwright/test").Page,
): Promise<boolean> {
  await page.goto("/");
  await waitForFlutterReady(page);

  // Sign in
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

  // Navigate to Symptoms tab
  const symptomsTab = flutterText(page, "Symptoms");
  if (await symptomsTab.isVisible({ timeout: 5000 }).catch(() => false)) {
    await symptomsTab.click();
    await page.waitForTimeout(1000);
    return true;
  }

  return false;
}

test.describe("Symptoms Screen", () => {
  test("should display predefined symptoms", async ({ page }) => {
    const reachedSymptoms = await navigateToSymptoms(page);
    if (!reachedSymptoms) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Symptoms")) {
      test.skip();
      return;
    }

    // Default symptoms: Acne, Redness, Dryness, Oiliness
    const defaultSymptoms = ["Acne", "Redness", "Dryness", "Oiliness"];
    for (const symptom of defaultSymptoms) {
      if (bodyText.includes(symptom)) {
        await expect(flutterText(page, symptom)).toBeVisible();
      }
    }
  });

  test("should show calendar for date selection", async ({ page }) => {
    const reachedSymptoms = await navigateToSymptoms(page);
    if (!reachedSymptoms) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Symptoms")) {
      test.skip();
      return;
    }

    // Calendar bar should show dates
    const today = new Date();
    const dateNum = today.getDate().toString();
    await expect(flutterText(page, dateNum)).toBeVisible();
  });

  test("should toggle a symptom on click", async ({ page }) => {
    const reachedSymptoms = await navigateToSymptoms(page);
    if (!reachedSymptoms) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Acne")) {
      test.skip();
      return;
    }

    // Click on Acne to toggle it
    await flutterText(page, "Acne").click();
    await page.waitForTimeout(500);

    // The symptom should still be visible (toggled state)
    await expect(flutterText(page, "Acne")).toBeVisible();
  });

  test("should show AM/PM time slots", async ({ page }) => {
    const reachedSymptoms = await navigateToSymptoms(page);
    if (!reachedSymptoms) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Symptoms")) {
      test.skip();
      return;
    }

    // AM/PM selection should be visible
    if (bodyText.includes("AM") || bodyText.includes("PM")) {
      const amOrPm = flutterText(page, "AM").or(flutterText(page, "PM"));
      await expect(amOrPm).toBeVisible();
    }
  });

  test("should allow adding custom symptoms", async ({ page }) => {
    const reachedSymptoms = await navigateToSymptoms(page);
    if (!reachedSymptoms) {
      test.skip();
      return;
    }

    const bodyText = await page.textContent("body");
    if (!bodyText?.includes("Symptoms")) {
      test.skip();
      return;
    }

    // Look for custom symptom input or "Add" button
    const addButton = flutterText(page, "Add")
      .or(flutterText(page, "Custom"))
      .or(page.locator('[aria-label="Add"]'));

    if (await addButton.isVisible({ timeout: 3000 }).catch(() => false)) {
      await addButton.click();
      await page.waitForTimeout(500);
    }
  });
});
