import {
  test as base,
  expect,
  type Page,
  type Locator,
} from "@playwright/test";

/**
 * Flutter Web Testing Helpers (CanvasKit Renderer)
 *
 * Flutter web renders to a canvas via CanvasKit. Text is NOT in the regular DOM.
 * To make elements queryable, we must enable Flutter's semantics tree by
 * triggering the hidden "Enable accessibility" placeholder button.
 *
 * After enabling semantics:
 * - flt-semantics elements are created in the DOM
 * - Buttons get role="button" with text content inside
 * - Text fields get <input> elements inside flt-semantics nodes
 * - Use getByRole('button', { name }) and getByText() to query
 */

/** Enable Flutter's accessibility/semantics tree */
async function enableFlutterSemantics(page: Page): Promise<void> {
  // Flutter places a hidden "Enable accessibility" button off-screen.
  // We must use dispatchEvent since it's outside the viewport.
  const enableBtn = page.getByRole("button", {
    name: "Enable accessibility",
  });
  const count = await enableBtn.count();
  if (count > 0) {
    await enableBtn.dispatchEvent("click");
    // Wait for semantics tree to be built
    await page.waitForTimeout(1500);
  }
}

/** Wait for Flutter web app to fully initialize and enable semantics */
async function waitForFlutterReady(page: Page): Promise<void> {
  // Wait for the Flutter engine to load
  await page.waitForLoadState("networkidle");

  // Wait for Flutter's main element to appear
  await page.waitForFunction(
    () => {
      const body = document.body;
      return (
        body &&
        (body.querySelector("flt-glass-pane") !== null ||
          body.querySelector("flutter-view") !== null)
      );
    },
    { timeout: 30_000 },
  );

  // Wait for Flutter to finish initial rendering
  await page.waitForTimeout(2000);

  // Enable semantics tree so elements are queryable
  await enableFlutterSemantics(page);
}

/**
 * Find a Flutter semantic element by its text content.
 * After enabling accessibility, Flutter creates flt-semantics elements
 * with text content that getByText() can find.
 */
function flutterText(page: Page, text: string | RegExp): Locator {
  return page.getByText(text, { exact: false }).nth(0);
}

/** Find a Flutter button by its label text */
function flutterButton(page: Page, label: string): Locator {
  return page.getByRole("button", { name: label });
}

/** Find a Flutter text input field by label */
function flutterTextField(page: Page, label: string): Locator {
  return page.getByRole("textbox", { name: label }).or(page.getByLabel(label));
}

/** Navigate to a route and re-enable semantics */
async function navigateToRoute(page: Page, route: string): Promise<void> {
  const baseUrl = page.url().split("#")[0].split("?")[0];
  await page.goto(`${baseUrl}#${route}`);
  await page.waitForTimeout(1500);
  await enableFlutterSemantics(page);
}

export type FlutterFixtures = {
  flutterPage: Page;
};

/**
 * Extended test fixture that waits for Flutter to initialize
 */
export const test = base.extend<FlutterFixtures>({
  flutterPage: async ({ page }, use) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await use(page);
  },
});

export {
  expect,
  waitForFlutterReady,
  enableFlutterSemantics,
  flutterText,
  flutterButton,
  flutterTextField,
  navigateToRoute,
};
