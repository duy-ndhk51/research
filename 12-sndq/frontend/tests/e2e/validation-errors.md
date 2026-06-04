# Validation Errors

**File**: `tests/financial/purchase-invoices/008-validation.spec.ts`
**Seed scenario**: `purchase-invoice-create`

Tests form validation by submitting with missing or invalid data.

---

## E2E-026: Submit empty form shows required field errors

**Preconditions**: Create form open, no fields filled beyond defaults (today's date, empty invoice number).

### Steps

1. Open create form
2. Clear any auto-filled fields
3. Click Submit without filling required fields

### Assertions

- Form does NOT submit (no POST request fired)
- Error indicators appear on required fields (red borders, error messages, `aria-invalid`)

### Example Code

```typescript
import { test, expect, requireEnv } from '../../test-base';

const WORKSPACE_ID = requireEnv('QA_SYNDIC_WORKSPACE_ID');

test.beforeAll(async ({ seedScenario }) => {
  await seedScenario({
    scenario: 'purchase-invoice-create',
    workspaceId: WORKSPACE_ID,
  });
});

test.afterAll(async ({ resetScenario }) => {
  await resetScenario(WORKSPACE_ID);
});

test('E2E-026: submit empty form shows validation errors', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible();

  // Clear invoice number
  await drawer.locator('#invoiceNumber').clear();

  // Try to submit
  await drawer.getByRole('button', { name: /submit|save/i }).click();

  // Wait for validation to run
  await page.waitForTimeout(500);

  // Error indicators should appear
  const errorElements = drawer.locator(
    '[data-error="true"], .text-error-500, [aria-invalid="true"]',
  );
  await expect(errorElements.first()).toBeVisible({ timeout: 5_000 });
});
```

---

## E2E-027: Submit without cost account on amount line

**Preconditions**: Building + supplier selected, amount filled but no cost account (ledger).

### Steps

1. Fill building + supplier
2. Fill amount on first line (e.g. 100)
3. Do NOT select a cost account
4. Submit

### Assertions

- Form does not submit
- Cost account / ledger field shows validation error (required for syndic variant)

### Example Code

```typescript
test('E2E-027: submit without cost account shows error', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');

  // Select building + supplier
  await drawer.getByText(/building/i).first().click();
  await page.getByRole('option', { name: /fixture building one/i }).click();
  await drawer.getByText(/supplier/i).first().click();
  await page.getByRole('option', { name: /fixture supplier/i }).click();

  await expect(drawer.getByText(/payment details/i)).toBeVisible({ timeout: 10_000 });

  // Fill amount but no cost account
  await drawer.locator('#invoiceNumber').fill('VALIDATION-TEST');
  const amountInput = drawer.locator('input[name*="totalAmount"]').first();
  await amountInput.fill('100');

  // Try to submit
  await drawer.getByRole('button', { name: /submit|save/i }).click();
  await page.waitForTimeout(500);

  // Cost account error should appear (required for syndic)
  const errorElements = drawer.locator(
    '[data-error="true"], .text-error-500, [aria-invalid="true"]',
  );
  await expect(errorElements.first()).toBeVisible({ timeout: 5_000 });
});
```

---

## E2E-028: Date outside allowed bounds

**Preconditions**: Form open.

### Steps

1. Open the date picker for invoice date
2. Attempt to select a date before January 1 of current year

### Assertions

- Dates outside the bounds are disabled/greyed in the picker (not selectable)
- The date picker enforces `minInvoiceDate` (Jan 1 current year) and `maxInvoiceDate` (today)

### Example Code

```typescript
test('E2E-028: date picker restricts out-of-bounds dates', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');

  // Open date picker
  await drawer.getByText(/invoice date/i).click();

  // Navigate to previous year in the calendar
  // Check that dates from last year are disabled
  const prevYearButton = page.getByRole('button', { name: /previous/i });
  if (await prevYearButton.isVisible()) {
    // Keep clicking until we're in the previous year
    // Then verify dates are disabled
  }

  // The exact assertion depends on the DatePicker component's disabled-date behavior
  // Generally, dates outside bounds get `aria-disabled="true"` or a disabled class
});
```

---

## E2E-029: Payment method validation (pay_now without accounts)

**Preconditions**: Building + supplier + amounts filled. Payment method is `pay_now` (default).

### Steps

1. Fill all required fields except payment accounts (`paymentFrom` / `paymentTo`)
2. Submit

### Assertions

- Form does not submit
- Payment account fields show error state
- Error message indicates payment accounts are required for `pay_now` method

### Example Code

```typescript
test('E2E-029: pay_now without payment accounts shows error', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');

  // Fill building + supplier
  await drawer.getByText(/building/i).first().click();
  await page.getByRole('option', { name: /fixture building one/i }).click();
  await drawer.getByText(/supplier/i).first().click();
  await page.getByRole('option', { name: /fixture supplier/i }).click();
  await expect(drawer.getByText(/payment details/i)).toBeVisible({ timeout: 10_000 });

  // Fill required fields except payment accounts
  await drawer.locator('#invoiceNumber').fill('PAY-VALIDATION-001');
  const amountInput = drawer.locator('input[name*="totalAmount"]').first();
  await amountInput.fill('100');
  await drawer.getByText(/select.*ledger|cost account/i).first().click();
  await page.getByRole('option').first().click();

  // Ensure payment method is pay_now (default) but do NOT select accounts

  // Try to submit
  await drawer.getByRole('button', { name: /submit|save/i }).click();
  await page.waitForTimeout(500);

  // Payment section should show error indicators
  const paymentSection = drawer.getByText(/payment details/i).locator('..');
  await expect(
    paymentSection.locator('[aria-invalid="true"], .text-error-500').first(),
  ).toBeVisible({ timeout: 5_000 });
});
```
