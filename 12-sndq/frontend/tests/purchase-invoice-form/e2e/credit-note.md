# Credit Note

**File**: `tests/financial/purchase-invoices/003-credit-note.spec.ts`
**Seed scenario**: `purchase-invoice-create`

Tests creating a credit note via mode switching.

---

## E2E-010: Switch mode to credit note

**Preconditions**: Create form open.

### Steps

1. Open the create form from purchase invoices list
2. Click the mode toggle / dropdown in the header
3. Select "Credit note"

### Assertions

- Header title updates to show "Credit note" text
- CreditNoteSection becomes visible (original invoice reference field)
- Mode indicator in the UI reflects credit note state

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

test('E2E-010: switch mode to credit note', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible();

  // Click mode toggle and select credit note
  await drawer.getByRole('button', { name: /invoice/i }).first().click();
  await page.getByRole('option', { name: /credit note/i }).click();

  // Verify header shows credit note
  await expect(drawer.getByText(/credit note/i).first()).toBeVisible();
});
```

---

## E2E-011: Fill and submit credit note

**Preconditions**: Credit note mode active, building + supplier selected.

### Steps

1. Select building + supplier
2. Optionally select original invoice reference
3. Fill amount line with cost account
4. Fill payment details
5. Submit

### Assertions

- POST response includes `invoiceTypeCode: '381'` (CREDIT_NOTE)
- Success toast appears
- Drawer closes

### Example Code

```typescript
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

test('E2E-011: fill and submit credit note', async ({ page }) => {
  // ... (mode switched to credit note, building + supplier selected) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  await drawer.locator('#invoiceNumber').fill('CN-TEST-001');

  // Fill amount
  const amountInput = drawer.locator('input[name*="totalAmount"]').first();
  await amountInput.fill('50');

  // Select cost account
  await drawer.getByText(/select.*ledger|cost account/i).first().click();
  await page.getByRole('option').first().click();

  // Submit
  const [response] = await Promise.all([
    page.waitForResponse(
      (res) =>
        res.request().method() === 'POST' &&
        pathnameIncludes(res.url(), '/purchase-invoices') &&
        isOkResponse(res),
      { timeout: 30_000 },
    ),
    drawer.getByRole('button', { name: /submit|save/i }).click(),
  ]);

  expect(response.status()).toBeGreaterThanOrEqual(200);
  await expect(drawer).not.toBeVisible({ timeout: 10_000 });
});
```

---

## E2E-012: Credit note appears in list with correct indicator

**Preconditions**: Credit note just created.

### Steps

1. Verify list page shows the credit note
2. Check type indicator

### Assertions

- Invoice row with `'CN-TEST-001'` is visible
- Row shows credit note badge or type indicator

### Example Code

```typescript
test('E2E-012: credit note visible in list with indicator', async ({ page }) => {
  await expect(page.getByText('CN-TEST-001')).toBeVisible({
    timeout: 15_000,
  });
  // Credit notes typically show a badge or type column
  await expect(page.getByText(/credit note/i)).toBeVisible();
});
```
