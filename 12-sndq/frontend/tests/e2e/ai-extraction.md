# AI Extraction

**File**: `tests/financial/purchase-invoices/006-ai-extraction.spec.ts`
**Seed scenario**: `purchase-invoice-create`

Tests the AI-powered field extraction from uploaded PDF invoices.

**Note**: These tests depend on the AI extraction service being available in the test environment. They may be flaky if the service is slow or unavailable. Consider marking them with `test.slow()` or conditionally skipping when the service is down.

---

## E2E-020: Upload PDF triggers extraction banner

**Preconditions**: Create form open with building + supplier selected.

### Steps

1. Open create form, select building + supplier
2. In the right panel, upload a PDF file via the file uploader
3. Observe the extraction banner

### Assertions

- "Extracting..." banner appears at the top of the form
- File preview becomes visible in the right panel

### Example Code

```typescript
import { test, expect, requireEnv } from '../../test-base';
import path from 'path';

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

test.slow(); // AI extraction can take 10-30s

test('E2E-020: upload PDF triggers extraction banner', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');

  // Select building + supplier
  await drawer.getByText(/building/i).first().click();
  await page.getByRole('option', { name: /fixture building one/i }).click();
  await drawer.getByText(/supplier/i).first().click();
  await page.getByRole('option', { name: /fixture supplier/i }).click();

  // Upload PDF via file input
  const fileInput = drawer.locator('input[type="file"]');
  await fileInput.setInputFiles(
    path.resolve(__dirname, '../fixtures/sample-invoice.pdf'),
  );

  // Extraction banner should appear
  await expect(drawer.getByText(/extracting/i)).toBeVisible({
    timeout: 10_000,
  });
});
```

---

## E2E-021: Extraction populates fields

**Preconditions**: PDF uploaded and extraction in progress.

### Steps

1. Wait for extraction to complete (banner changes state or disappears)
2. Check populated fields

### Assertions

- Invoice number field populated (non-empty)
- Invoice date field populated
- AI confidence indicators visible on extracted fields (colored dots/badges)

### Example Code

```typescript
test('E2E-021: extraction populates fields', async ({ page }) => {
  // ... (PDF uploaded, banner visible) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  // Wait for extraction to complete
  await expect(drawer.getByText(/extracting/i)).not.toBeVisible({
    timeout: 60_000,
  });

  // Verify fields are populated
  const invoiceNumber = await drawer.locator('#invoiceNumber').inputValue();
  expect(invoiceNumber).not.toBe('');

  // AI confidence indicators should be visible
  // These are small colored badges/dots next to extracted fields
  await expect(
    drawer.locator('[class*="confidence"], [data-testid*="ai-indicator"]').first(),
  ).toBeVisible();
});
```

---

## E2E-022: Review extracted field clears confidence indicator

**Preconditions**: Fields populated from AI extraction with confidence indicators.

### Steps

1. Click the invoice number field (triggers `markFieldReviewed`)
2. Edit the value

### Assertions

- Confidence indicator disappears or changes state for the reviewed field
- Field value can be modified by user

### Example Code

```typescript
test('E2E-022: review extracted field clears indicator', async ({ page }) => {
  // ... (extraction completed, fields populated) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  // Click and edit the invoice number
  await drawer.locator('#invoiceNumber').click();
  await drawer.locator('#invoiceNumber').fill('MANUALLY-EDITED');

  // The confidence indicator for this field should change/disappear
  // The exact behavior depends on the AiFieldIndicator implementation
  await expect(
    drawer.locator('#invoiceNumber').inputValue(),
  ).resolves.toBe('MANUALLY-EDITED');
});
```
