# Draft Save and Resume

**File**: `tests/financial/purchase-invoices/005-draft.spec.ts`
**Seed scenario**: `purchase-invoice-create` (for new draft), `purchase-invoice-draft` (for resume)

Tests the draft save and resume lifecycle.

---

## E2E-017: Save as draft

**Preconditions**: Create form with building + supplier + one amount filled, but payment details not complete.

### Steps

1. Open create form, fill building + supplier + amount line
2. Click the combo actions dropdown in the header
3. Select "Save as draft"
4. Wait for POST with draft flag

### Assertions

- Response is 2xx
- Drawer closes
- Draft appears in list with "Draft" badge or status indicator

### Example Code

```typescript
import { test, expect, requireEnv } from '../../test-base';
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

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

test('E2E-017: save as draft', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');

  // Fill building + supplier
  await drawer.getByText(/building/i).first().click();
  await page.getByRole('option', { name: /fixture building one/i }).click();
  await drawer.getByText(/supplier/i).first().click();
  await page.getByRole('option', { name: /fixture supplier/i }).click();

  // Wait for sections, fill amount
  await expect(drawer.getByText(/payment details/i)).toBeVisible({ timeout: 10_000 });
  const amountInput = drawer.locator('input[name*="totalAmount"]').first();
  await amountInput.fill('75');

  // Save as draft via combo actions
  await drawer.getByRole('button', { name: /more|actions/i }).last().click();
  const [response] = await Promise.all([
    page.waitForResponse(
      (res) =>
        res.request().method() === 'POST' &&
        pathnameIncludes(res.url(), '/purchase-invoices') &&
        isOkResponse(res),
      { timeout: 30_000 },
    ),
    page.getByRole('menuitem', { name: /draft/i }).click(),
  ]);

  expect(response.status()).toBeGreaterThanOrEqual(200);
  await expect(drawer).not.toBeVisible({ timeout: 10_000 });
});
```

---

## E2E-018: Resume draft with persisted data

**Preconditions**: Draft exists in seed data.
**Seed scenario**: `purchase-invoice-draft`

### Steps

1. Navigate to list, find draft invoice
2. Click to open detail, then click Edit
3. Verify form populates with draft data

### Assertions

- Building select shows the saved building
- Supplier select shows the saved supplier
- Amount line has saved amount
- Invoice number is preserved (or empty if not entered)

### Example Code

```typescript
test('E2E-018: resume draft preserves data', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');

  // Find the draft (may have a "Draft" badge)
  await page.getByText(/draft/i).first().click();

  const sheet = page.locator('[data-slot="floating-sheet"]');
  await expect(sheet).toBeVisible();

  await sheet.getByRole('button', { name: /actions/i }).click();
  await page.getByRole('menuitem', { name: /edit/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible();

  // Verify persisted data
  await expect(drawer.getByText(/fixture building one/i)).toBeVisible();
  await expect(drawer.getByText(/fixture supplier/i)).toBeVisible();
});
```

---

## E2E-019: Complete draft and submit

**Preconditions**: Draft form open with existing partial data.

### Steps

1. Fill remaining required fields (invoice number, cost account, payment accounts)
2. Submit

### Assertions

- PUT request sent (not POST, since draft already has an ID)
- Response is 2xx
- Invoice status changes from draft to submitted

### Example Code

```typescript
test('E2E-019: complete draft and submit', async ({ page }) => {
  // ... (draft edit form open from E2E-018) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  await drawer.locator('#invoiceNumber').fill('DRAFT-COMPLETED-001');

  // Select cost account on amount line
  await drawer.getByText(/select.*ledger|cost account/i).first().click();
  await page.getByRole('option').first().click();

  // Fill payment details and submit
  const [response] = await Promise.all([
    page.waitForResponse(
      (res) =>
        res.request().method() === 'PUT' &&
        pathnameIncludes(res.url(), '/purchase-invoices/') &&
        isOkResponse(res),
      { timeout: 30_000 },
    ),
    drawer.getByRole('button', { name: /submit|save/i }).click(),
  ]);

  expect(response.status()).toBeGreaterThanOrEqual(200);
  await expect(drawer).not.toBeVisible({ timeout: 10_000 });
});
```
