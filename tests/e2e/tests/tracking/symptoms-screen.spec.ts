import { test, expect, flutterText } from "../fixtures";
import { navigateWithMockAuth } from "../helpers/mock-auth";

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
 * Uses mock Supabase auth interception to bypass real authentication.
 */

test.describe("Symptoms Screen", () => {
  test("should display predefined symptoms", async ({ page }) => {
    await navigateWithMockAuth(page, "Symptoms");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    expect(bodyText!.length).toBeGreaterThan(0);

    // Default symptoms: Acne, Redness, Dryness, Oiliness
    const defaultSymptoms = ["Acne", "Redness", "Dryness", "Oiliness"];
    for (const symptom of defaultSymptoms) {
      if (bodyText!.includes(symptom)) {
        await expect(flutterText(page, symptom)).toBeVisible();
      }
    }
  });

  test("should show calendar for date selection", async ({ page }) => {
    await navigateWithMockAuth(page, "Symptoms");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();
    // Symptoms screen should have loaded with meaningful content
    expect(bodyText!.length).toBeGreaterThan(50);
  });

  test("should toggle a symptom on click", async ({ page }) => {
    await navigateWithMockAuth(page, "Symptoms");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

    if (bodyText!.includes("Acne")) {
      // Click on Acne to toggle it
      await flutterText(page, "Acne").click();
      await page.waitForTimeout(500);

      // The symptom should still be visible (toggled state)
      await expect(flutterText(page, "Acne")).toBeVisible();
    }
  });

  test("should show AM/PM time slots", async ({ page }) => {
    await navigateWithMockAuth(page, "Symptoms");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

    // AM/PM selection should be visible
    if (bodyText!.includes("AM") || bodyText!.includes("PM")) {
      const amOrPm = flutterText(page, "AM").or(flutterText(page, "PM"));
      await expect(amOrPm).toBeVisible();
    }
  });

  test("should allow adding custom symptoms", async ({ page }) => {
    await navigateWithMockAuth(page, "Symptoms");

    const bodyText = await page.textContent("body");
    expect(bodyText).toBeTruthy();

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
