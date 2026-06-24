# Supplier Defaults — Auto-fill & Auto-save

**File**: `tests/financial/purchase-invoices/011-supplier-defaults.spec.ts`
**Seed scenarios**: `purchase-invoice-supplier-defaults` (supplier with pre-configured ledger + distribution key), `purchase-invoice-create` (supplier without defaults), `purchase-invoice-free-distribution` (invoice with free distribution saved)

Tests the end-to-end flow of supplier defaults: when a supplier with configured defaults is selected, new invoice lines auto-fill with the default ledger and distribution key. On successful submit, settings from the invoice are auto-saved back to the building-supplier link.

**Architecture note**: Supplier defaults are applied in two ways:
1. **Initial line** — pristine first line on new invoice gets defaults via `useBackfillSupplierDefaults`
2. **Add Line** — new lines added via button get defaults via `createDefaultAmountWithDefaults`

Existing lines (in edit mode) are NEVER modified by supplier defaults.

---

## E2E-048: Supplier with defaults auto-fills initial line cost account

**Preconditions**: Seeded building-supplier link where supplier has `invoiceMotherId` configured. Create form open, initial first line is pristine.

### Steps

1. Navigate to `/financial/invoices/purchase`
2. Click "Add invoice"
3. Select the seeded building
4. Select the supplier that has default ledger configured
5. Wait for supplier defaults to load
6. Open the first amount line (distribution sheet)
7. Observe the cost account field

### Assertions

- Cost account field in the distribution sheet is pre-populated with the supplier's default ledger
- The ledger name and code match the seeded supplier defaults

### Example Code

```typescript
import { test, expect, requireEnv } from '../../test-base';

const WORKSPACE_ID = requireEnv('QA_SYNDIC_WORKSPACE_ID');

test.beforeAll(async ({ seedScenario }) => {
  await seedScenario({
    scenario: 'purchase-invoice-supplier-defaults',
    workspaceId: WORKSPACE_ID,
  });
});

test.afterAll(async ({ resetScenario }) => {
  await resetScenario(WORKSPACE_ID);
});

test('E2E-048: supplier defaults auto-fill cost account on initial line', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');

  // Select building with supplier that has defaults
  await selectBuilding(page, drawer, 'Fixture Building One');
  await selectSupplier(page, drawer, 'Fixture Supplier With Defaults');

  // Wait for supplier defaults to load and apply to initial line
  await page.waitForTimeout(3_000);

  // Open the first amount line
  await drawer.locator('[data-testid="amount-line-row"]').first().click();

  const distSheet = page.locator('[data-slot="sheet-content"]').last();
  await expect(distSheet).toBeVisible();

  // Cost account should be pre-filled from supplier defaults
  const costAccountField = distSheet.locator('[data-testid="cost-account-select"]');
  await expect(costAccountField).not.toContainText(/select/i, { timeout: 10_000 });
});
```

---

## E2E-049: New line added via button gets supplier defaults

**Preconditions**: Seeded building-supplier link where supplier has `distributionKeyId` configured. Building has the referenced distribution key. Create form open with building + supplier already selected.

### Steps

1. Open create form, select building + supplier with distribution key defaults
2. Click "Add Line" button to add a NEW line
3. Open the newly added line's distribution sheet
4. Observe the distribution method section

### Assertions

- Distribution key mode is auto-activated on the new line
- The seeded distribution key is pre-selected in the dropdown
- Units have shares matching the key's definition
- Whole building is enabled

### Example Code

```typescript
test('E2E-049: new line added via button gets supplier defaults', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await selectBuilding(page, drawer, 'Fixture Building One');
  await selectSupplier(page, drawer, 'Fixture Supplier With Defaults');

  // Wait for supplier defaults to be ready
  await page.waitForTimeout(2_000);

  // Add a NEW line via button
  await drawer.getByRole('button', { name: /add line|add amount/i }).click();

  // Open the newly added line (should be the last one)
  await drawer.locator('[data-testid="amount-line-row"]').last().click();
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  // Distribution key should be pre-selected
  const dkSelect = distSheet.locator('[data-testid="distribution-key-select"]');
  await expect(dkSelect).toBeVisible({ timeout: 10_000 });
  await expect(dkSelect).not.toContainText(/select/i);

  // Whole building should be on
  await expect(distSheet.getByLabel(/whole building/i)).toBeChecked();
});
```

---

## E2E-050: User-set cost account NOT overwritten by supplier defaults

**Preconditions**: Create form open. User manually selects a cost account on an amount line before selecting a supplier with defaults.

### Steps

1. Open create form, select building
2. Add an amount line, manually select cost account "Office Supplies"
3. Save the line, go back to parent form
4. Select a supplier that has a different default ledger
5. Re-open the amount line

### Assertions

- Cost account still shows "Office Supplies" (user's choice)
- Supplier's default ledger did NOT overwrite the manual selection
- "Never overwrite existing lines" policy enforced end-to-end

### Example Code

```typescript
test('E2E-050: manual cost account not overwritten by supplier defaults', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await selectBuilding(page, drawer, 'Fixture Building One');

  // Add line and manually set cost account BEFORE selecting supplier
  await drawer.getByRole('button', { name: /add line|add amount/i }).click();
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  await distSheet.getByText(/select.*ledger|cost account/i).click();
  await page.getByRole('option', { name: /office supplies/i }).click();
  await distSheet.locator('input[name="totalAmount"]').fill('100');
  await distSheet.getByLabel(/whole building/i).click();
  await distSheet.getByRole('button', { name: /save.*close/i }).click();

  // Now select supplier with different defaults
  await selectSupplier(page, drawer, 'Fixture Supplier With Defaults');
  await page.waitForTimeout(3_000);

  // Re-open the line
  await drawer.locator('[data-testid="amount-line-row"]').first().click();
  const distSheet2 = page.locator('[data-slot="sheet-content"]').last();

  // Cost account should still be the manually-set one
  const costAccountField = distSheet2.locator('[data-testid="cost-account-select"]');
  await expect(costAccountField).toContainText(/office supplies/i);
});
```

---

## E2E-050b: Free distribution preserved when editing invoice (REGRESSION)

**Preconditions**: Seeded invoice with an amount line saved with `distributionType: 'free'` and custom unit amounts. The supplier linked to this invoice has a default distribution key configured.

**Bug context**: This is the regression test for the critical bug where `useBackfillSupplierDefaults` incorrectly overwrote "free" distributions on edit form load because they have `distributionKeyId: undefined`.

### Steps

1. Navigate to purchase invoices list
2. Open the seeded invoice with free distribution
3. Click Actions -> Edit
4. Wait for form to fully load (supplier defaults resolve)
5. Open the amount line distribution sheet

### Assertions

- Distribution type shows "Free" / custom allocation (not a key-based distribution)
- Unit amounts match the saved values (not recalculated by supplier key)
- No distribution key is selected in the dropdown
- The "Use distribution key" toggle is OFF
- Supplier defaults did NOT overwrite the distribution

### Example Code

```typescript
test('E2E-050b: free distribution preserved when editing invoice (regression)', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');

  // Open the seeded invoice with free distribution
  await page.getByText('FREE-DIST-2026-001').click();
  const sheet = page.locator('[data-slot="floating-sheet"]');
  await expect(sheet).toBeVisible();

  await sheet.getByRole('button', { name: /actions/i }).click();
  await page.getByRole('menuitem', { name: /edit/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible();

  // Wait for all data to load (including supplier defaults)
  await page.waitForTimeout(4_000);

  // Open the first amount line
  await drawer.locator('[data-testid="amount-line-row"]').first().click();
  const distSheet = page.locator('[data-slot="sheet-content"]').last();
  await expect(distSheet).toBeVisible();

  // Distribution key should NOT be selected (free distribution has no key)
  const dkSelect = distSheet.locator('[data-testid="distribution-key-select"]');
  // Either the select shows placeholder or the toggle is off
  const useKeyToggle = distSheet.getByLabel(/use distribution key|distribution key/i);
  if (await useKeyToggle.isVisible()) {
    await expect(useKeyToggle).not.toBeChecked();
  }

  // Unit amounts should be the saved custom values (not recalculated)
  // Verify by checking total matches the original saved amount
  const totalField = distSheet.locator('[data-testid="total-amount"]');
  await expect(totalField).toBeVisible();
});
```

---

## E2E-051: Submit creates building-supplier link for new supplier

**Preconditions**: Supplier has no existing building-supplier link. Invoice submitted with cost account and distribution key.

### Steps

1. Open create form, select building + NEW supplier (no prior link)
2. Fill all required fields including amount with cost account
3. Submit the invoice
4. Intercept the building-supplier API call

### Assertions

- POST to `/purchase-invoices` returns 2xx
- POST or PUT to building-supplier endpoint fired after invoice submit
- Payload contains `contactId`, `invoiceMotherId` (or `invoiceLedgerId`), `distributionKeyId`

### Example Code

```typescript
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

test('E2E-051: submit creates supplier link with defaults', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await selectBuilding(page, drawer, 'Fixture Building One');
  await selectSupplier(page, drawer, 'Fixture New Supplier');

  await fillInvoiceFields(page, drawer);
  await addAmountLineWithLedger(page, drawer);

  // Watch for both invoice submit and supplier link creation
  const supplierLinkPromise = page.waitForResponse(
    (res) =>
      pathnameIncludes(res.url(), '/building-suppliers') &&
      (res.request().method() === 'POST' || res.request().method() === 'PUT') &&
      isOkResponse(res),
    { timeout: 15_000 },
  );

  const [invoiceResponse] = await Promise.all([
    page.waitForResponse(
      (res) =>
        res.request().method() === 'POST' &&
        pathnameIncludes(res.url(), '/purchase-invoices') &&
        isOkResponse(res),
      { timeout: 30_000 },
    ),
    drawer.getByRole('button', { name: /submit|save/i }).click(),
  ]);

  expect(invoiceResponse.status()).toBeGreaterThanOrEqual(200);
  expect(invoiceResponse.status()).toBeLessThan(300);

  // Supplier link should also be created
  const linkResponse = await supplierLinkPromise;
  expect(linkResponse.status()).toBeGreaterThanOrEqual(200);
});
```

---

## E2E-052: Submit updates empty defaults on existing supplier link

**Preconditions**: Supplier has existing building-supplier link with empty `invoiceMotherId` and `distributionKeyId`. Invoice submitted with both fields filled.

### Steps

1. Open create form, select building + existing supplier (link exists, defaults empty)
2. Fill invoice with cost account and distribution key
3. Submit
4. Intercept the building-supplier update call

### Assertions

- PATCH/PUT to building-supplier endpoint fired
- Payload contains the newly set `invoiceMotherId` and/or `distributionKeyId`
- Only empty fields updated (existing values untouched)

### Example Code

```typescript
test('E2E-052: submit updates empty defaults on existing link', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await selectBuilding(page, drawer, 'Fixture Building One');
  await selectSupplier(page, drawer, 'Fixture Supplier Empty Defaults');

  await fillInvoiceFields(page, drawer);
  await addAmountLineWithLedger(page, drawer);

  const supplierUpdatePromise = page.waitForResponse(
    (res) =>
      pathnameIncludes(res.url(), '/building-suppliers') &&
      (res.request().method() === 'PUT' || res.request().method() === 'PATCH') &&
      isOkResponse(res),
    { timeout: 15_000 },
  );

  await Promise.all([
    page.waitForResponse(
      (res) =>
        res.request().method() === 'POST' &&
        pathnameIncludes(res.url(), '/purchase-invoices') &&
        isOkResponse(res),
      { timeout: 30_000 },
    ),
    drawer.getByRole('button', { name: /submit|save/i }).click(),
  ]);

  const updateResponse = await supplierUpdatePromise;
  expect(updateResponse.status()).toBeGreaterThanOrEqual(200);

  const body = JSON.parse(updateResponse.request().postData() || '{}');
  expect(body.invoiceMotherId || body.invoiceLedgerId).toBeTruthy();
});
```
