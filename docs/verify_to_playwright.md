# Verify UI: Builder Options → Playwright Assertions

This maps the Verify builder options in `mockups/verify_mockup_concept_b.html` to Playwright assertion snippets. Replace `locator` with your actual selector (e.g., `page.getByRole('button', { name: 'Save' })`).

Notes
- For textual comparisons (contain, equal, start with, end with), we assert BOTH element text and input/select value, as requested.
- Negations use `.not`.
- Some assertions apply only to certain element types (e.g., `toHaveValue` for inputs/selects/textarea). Keep them if relevant; harmless if the element has no value.

## Visibility (Step 2)

- is present
```ts
await expect(locator).toBeAttached();
```
- is not present
```ts
await expect(locator).not.toBeAttached();
```
- is visible
```ts
await expect(locator).toBeVisible();
```
- is not visible
```ts
await expect(locator).not.toBeVisible();
```
- is enabled
```ts
await expect(locator).toBeEnabled();
```
- is not enabled
```ts
await expect(locator).toBeDisabled();
```
- is checked (for checkbox, radio, switch)
```ts
await expect(locator).toBeChecked();
```
- is not checked
```ts
await expect(locator).not.toBeChecked();
```
- is editable (content-editable or input)
```ts
await expect(locator).toBeEditable();
```
- is not editable
```ts
await expect(locator).not.toBeEditable();
```
- is selected (option within a <select>)
```ts
// locator should point to <option> or a select with value
await expect(locator).toBeSelected();
```
- is not selected
```ts
await expect(locator).not.toBeSelected();
```

## Verification (Step 3)
Use “should / should not” to toggle `.not`.

Below, `value` is the user-provided string/regex. For value-based checks, we verify BOTH text and input value.

- contain
```ts
// Text contains
await expect(locator).toContainText(value);
// Input/select/textarea value contains (string contains)
await expect(locator).toHaveValue(new RegExp(escapeRegex(String(value))));
```

- equal
```ts
// Text equals
await expect(locator).toHaveText(value);
// Value equals
await expect(locator).toHaveValue(String(value));
```

- start with
```ts
// Text starts with
await expect(locator).toHaveText(new RegExp('^' + escapeRegex(String(value))));
// Value starts with
await expect(locator).toHaveValue(new RegExp('^' + escapeRegex(String(value))));
```

- end with
```ts
// Text ends with
await expect(locator).toHaveText(new RegExp(escapeRegex(String(value)) + '$'));
// Value ends with
await expect(locator).toHaveValue(new RegExp(escapeRegex(String(value)) + '$'));
```

- be less than (numeric)
```ts
const text = (await locator.textContent())?.trim() ?? '';
const val = await locator.inputValue().catch(() => null);
const num = Number(val ?? text);
expect(num).toBeLessThan(Number(value));
```

- be greater than (numeric)
```ts
const text = (await locator.textContent())?.trim() ?? '';
const val = await locator.inputValue().catch(() => null);
const num = Number(val ?? text);
expect(num).toBeGreaterThan(Number(value));
```

- match regex
```ts
// Text matches regex
await expect(locator).toHaveText(value); // value is a RegExp
// Value matches regex
await expect(locator).toHaveValue(value);
```

- have dom attribute
```ts
// value may be just the attribute name (presence) or name=value
// Presence only
await expect(locator).toHaveAttribute(attrName, /[\s\S]*/);
// Name = exact value
await expect(locator).toHaveAttribute(attrName, attrValue);
// Name = regex
await expect(locator).toHaveAttribute(attrName, attrRegex);
```

- have css property
```ts
await expect(locator).toHaveCSS(propertyName, expectedValue);
```

### Negation examples ("should not")
Just prefix `.not`:
```ts
await expect(locator).not.toContainText(value);
await expect(locator).not.toHaveValue(new RegExp(escapeRegex(String(value))));
```

## Timeout (Step 4)
Use Playwright expect options:
```ts
await expect(locator).toBeVisible({ timeout });
```

## Failure message (Step 5)
Playwright attaches its own detailed messages; to customize, wrap in try/catch and throw your message:
```ts
try {
  await expect(locator).toBeVisible({ timeout });
} catch (e) {
  throw new Error(customMessage || String(e));
}
```

## Failure action (Step 6)
To continue on failure, catch and log without throwing:
```ts
try {
  // ... assertion(s)
} catch (e) {
  console.warn('Verification failed:', e);
}
```

## Helper: escapeRegex
```ts
function escapeRegex(s: string) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
```
