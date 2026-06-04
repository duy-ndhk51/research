# Edit Invoice

**File**: `tests/financial/purchase-invoices/002-edit-invoice.spec.ts`
**Seed scenario**: `purchase-invoice-edit`

Tests editing an existing approved purchase invoice.

---

## E2E-006: Open existing invoice and verify data

**Preconditions**: Seeded workspace with existing invoice `TEST-2026-001`.

### Steps

1. Navigate to purchase invoices list
2. Click the seeded invoice row
3. Wait for detail floating sheet to open
4. Click Actions -> Edit

### Assertions

- Edit form drawer opens
- Invoice number field shows `'TEST-2026-001'`
- Supplier name visible
- Amount lines populated

### Example Code

```typescript
import { test, expect, requireEnv } from '../../test-base';
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

const WORKSPACE_ID = requireEnv('QA_SYNDIC_WORKSPACE_ID');

test.beforeAll(async ({ seedScenario }) => {
  await seedScenario({
    scenario: 'purchase-invoice-edit',
    workspaceId: WORKSPACE_ID,
  });
});

test.afterAll(async ({ resetScenario }) => {
  await resetScenario(WORKSPACE_ID);
});

test('E2E-006: open existing invoice populates form', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');

  await page.getByText('TEST-2026-001').click();
  const sheet = page.locator('[data-slot="floating-sheet"]');
  await expect(sheet).toBeVisible();

  await sheet.getByRole('button', { name: /actions/i }).click();
  await page.getByRole('menuitem', { name: /edit/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible();
  await expect(drawer.locator('#invoiceNumber')).toHaveValue('TEST-2026-001');
});
```

---

## E2E-007: Modify amount and submit

**Preconditions**: Edit form open with existing invoice.

### Steps

1. Change the first amount line total to `200.00`
2. Submit the form
3. Wait for `PUT /purchase-invoices/:id` response

### Assertions

- Response is 2xx
- Form drawer closes

### Example Code

```typescript
test('E2E-007: modify amount and submit', async ({ page }) => {
  // ... (open edit form as in E2E-006) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  const amountInput = drawer.locator('input[name*="totalAmount"]').first();
  await amountInput.clear();
  await amountInput.fill('200');

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

---

## E2E-008: Change supplier

**Preconditions**: Edit form open. Multiple suppliers exist in seed.

### Steps

1. Open supplier select
2. Choose a different supplier
3. Verify supplier-dependent fields update

### Assertions

- Supplier name changes in the select
- Payment details may reset (IBAN changes if supplier has different bank account)

### Example Code

```typescript
test('E2E-008: change supplier updates form', async ({ page }) => {
  // ... (open edit form) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  await drawer.getByText(/fixture supplier/i).click();
  await page.getByRole('option').filter({ hasNotText: /fixture supplier nv/i }).first().click();

  // Verify the supplier changed (the select should show a different name)
  await expect(drawer.getByText(/fixture supplier nv/i)).not.toBeVisible();
});
```

---

## E2E-009: Discard changes shows confirmation dialog

**Preconditions**: Edit form open with modifications.

### Steps

1. Modify any field (e.g. invoice number)
2. Click back / discard button
3. Dialog appears

### Assertions

- Discard confirmation dialog visible
- Cancel returns to form (dialog closes, form stays open)
- Confirm closes drawer without saving (no PUT request)

### Example Code

```typescript
test('E2E-009: discard changes shows confirmation', async ({ page }) => {
  // ... (open edit form, make a change) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  await drawer.locator('#invoiceNumber').clear();
  await drawer.locator('#invoiceNumber').fill('MODIFIED');

  await drawer.getByRole('button', { name: /back|discard/i }).first().click();

  const dialog = page.getByRole('alertdialog');
  await expect(dialog).toBeVisible();

  // Cancel returns to form
  await dialog.getByRole('button', { name: /cancel/i }).click();
  await expect(dialog).not.toBeVisible();
  await expect(drawer).toBeVisible();
});
```
