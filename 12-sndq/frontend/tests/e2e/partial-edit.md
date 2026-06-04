# Partial Edit Mode

**File**: `tests/financial/purchase-invoices/007-partial-edit.spec.ts`
**Seed scenario**: `purchase-invoice-partial-edit`

Tests editing a booked/partially-paid invoice where only certain fields can be modified.

---

## E2E-023: Partial edit mode warning banner visible

**Preconditions**: Invoice is booked or partially paid (triggers partial edit mode in `PurchaseInvoiceEditFormV3`).

### Steps

1. Navigate to the seeded invoice in the list
2. Open the detail floating sheet
3. Click Actions -> Edit

### Assertions

- Warning banner visible with partial edit mode message
- Banner has warning styling (yellow/orange color scheme)

### Example Code

```typescript
import { test, expect, requireEnv } from '../../test-base';

const WORKSPACE_ID = requireEnv('QA_SYNDIC_WORKSPACE_ID');

test.beforeAll(async ({ seedScenario }) => {
  await seedScenario({
    scenario: 'purchase-invoice-partial-edit',
    workspaceId: WORKSPACE_ID,
  });
});

test.afterAll(async ({ resetScenario }) => {
  await resetScenario(WORKSPACE_ID);
});

test('E2E-023: partial edit mode shows warning banner', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByText('TEST-2026-001').click();

  const sheet = page.locator('[data-slot="floating-sheet"]');
  await expect(sheet).toBeVisible();

  await sheet.getByRole('button', { name: /actions/i }).click();
  await page.getByRole('menuitem', { name: /edit/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible();

  await expect(
    drawer.getByText(/partial edit mode/i),
  ).toBeVisible();
});
```

---

## E2E-024: Building and supplier fields disabled, amounts locked

**Preconditions**: Partial edit form open.

### Steps

1. Check building and supplier fields
2. Check lock state in the invoice lines footer

### Assertions

- Building select is disabled (inside disabled fieldset with `opacity-60` styling)
- Supplier select is disabled
- Lock toggle is disabled (cannot unlock — tooltip may say "total locked because paid")
- Amount total shows locked value

### Example Code

```typescript
test('E2E-024: fields disabled and amounts locked', async ({ page }) => {
  // ... (partial edit form opened) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  // Building/supplier fieldset should be disabled
  const disabledFieldset = drawer.locator('fieldset[disabled]').first();
  await expect(disabledFieldset).toBeVisible();

  // Verify the building select is within the disabled fieldset
  await expect(
    disabledFieldset.getByText(/fixture building one/i),
  ).toBeVisible();
});
```

---

## E2E-025: Edit allowed fields and submit

**Preconditions**: Partial edit form open.

### Steps

1. Edit the description field (editable in partial edit mode)
2. Edit the due date (editable in partial edit mode)
3. Submit

### Assertions

- PUT or PATCH request succeeds (2xx)
- Drawer closes
- Modified fields are persisted

### Example Code

```typescript
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

test('E2E-025: edit allowed fields and submit', async ({ page }) => {
  // ... (partial edit form opened) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  // Edit description (should be editable even in partial edit mode)
  const descriptionField = drawer.locator('textarea, input[name*="description"]').first();
  if (await descriptionField.isVisible()) {
    await descriptionField.fill('Updated description in partial edit');
  }

  // Submit
  const [response] = await Promise.all([
    page.waitForResponse(
      (res) =>
        (res.request().method() === 'PUT' || res.request().method() === 'PATCH') &&
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
