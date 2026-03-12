import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright configuration for SkinCare Flutter Web App.
 *
 * Flutter web apps render via CanvasKit (canvas) or HTML renderer.
 * With `--web-renderer html`, Flutter produces accessible DOM elements
 * that Playwright can query by text, role, and semantics attributes.
 *
 * Start the app before running tests:
 *   cd app && flutter run -d chrome --web-renderer html --web-port 8080
 *
 * Or use the webServer config below to auto-start.
 */
export default defineConfig({
  testDir: "./tests",
  fullyParallel: false, // Flutter web app is stateful — run sequentially
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [["html", { open: "never" }], ["list"]],
  timeout: 60_000,
  expect: {
    timeout: 15_000,
  },
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:8080",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    actionTimeout: 10_000,
    navigationTimeout: 30_000,
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "mobile-chrome",
      use: { ...devices["Pixel 5"] },
    },
  ],
});
