# Create Invoice

**File**: `tests/financial/purchase-invoices/001-create-invoice.spec.ts`
**Seed scenario**: `purchase-invoice-create`

Tests the happy path for creating a new purchase invoice from the list page.

---

## E2E-001: Open create form

**Preconditions**: Seeded workspace with building + supplier. On purchase invoice list page.

### Steps

1. Navigate to `/financial/invoices/purchase`
2. Click "Add invoice" button

### Assertions

- Form drawer (`[data-slot="sheet-content"]`) becomes visible
- Building select and supplier select are visible
- Invoice number and date fields are visible

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

test('E2E-001: open create form from list', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible();
  await expect(drawer.locator('#invoiceNumber')).toBeVisible();
});
```

---

## E2E-002: Select building and supplier reveals form sections

**Preconditions**: Create form open. Building and supplier exist in seed data.

### Steps

1. Select "Fixture Building One" in building select
2. Select "Fixture Supplier NV" in supplier select
3. Wait for supplier defaults to load

### Assertions

- Placeholder hint disappears
- Invoice lines section appears
- Payment details section appears

### Example Code

```typescript
test('E2E-002: selecting building + supplier reveals full form', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');

  // Select building
  await drawer.getByText(/building/i).first().click();
  await page.getByRole('option', { name: /fixture building one/i }).click();

  // Select supplier
  await drawer.getByText(/supplier/i).first().click();
  await page.getByRole('option', { name: /fixture supplier/i }).click();

  // Wait for form sections to appear
  await expect(drawer.getByText(/payment details/i)).toBeVisible({
    timeout: 10_000,
  });
  await expect(
    drawer.getByText(/select.*building.*supplier/i),
  ).not.toBeVisible();
});
```

---

## E2E-003: Fill amount line with ledger and distribution

**Preconditions**: Building + supplier selected. Invoice lines section visible.

### Steps

1. Fill invoice number with `'TEST-CREATE-001'`
2. In the first amount line, set total amount to `100.00` (10000 cents)
3. Select a cost account (ledger)

### Assertions

- Total footer updates to show `€100,00`
- Cost account selection persists

### Example Code

```typescript
test('E2E-003: fill amount line with ledger', async ({ page }) => {
  // ... (building + supplier selected from prior steps) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  await drawer.locator('#invoiceNumber').fill('TEST-CREATE-001');

  // Fill amount on first line
  const amountInput = drawer.locator('input[name*="totalAmount"]').first();
  await amountInput.fill('100');

  // Select cost account
  await drawer.getByText(/select.*ledger|cost account/i).first().click();
  await page.getByRole('option', { name: /maintenance/i }).first().click();

  // Verify total in footer
  await expect(drawer.getByText('€100,00')).toBeVisible();
});
```

---

## E2E-004: Submit invoice successfully

**Preconditions**: All required fields filled (building, supplier, invoice number, date, amount with ledger, payment accounts).

### Steps

1. Fill payment details (select payment from/to bank accounts)
2. Click "Submit" button
3. Wait for `POST /purchase-invoices` response

### Assertions

- Response status is 2xx
- Form drawer closes
- Success toast appears

### Example Code

```typescript
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

test('E2E-004: submit invoice successfully', async ({ page }) => {
  // ... (all fields filled from prior steps) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

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
  expect(response.status()).toBeLessThan(300);

  await expect(drawer).not.toBeVisible({ timeout: 10_000 });
});
```

---

## E2E-005: Created invoice appears in list

**Preconditions**: Invoice just created from E2E-004.

### Steps

1. Verify the purchase invoice list page is visible
2. Look for the created invoice

### Assertions

- Row with invoice number `'TEST-CREATE-001'` is visible in the table
- Supplier name `'Fixture Supplier NV'` appears in the row

### Example Code

```typescript
test('E2E-005: created invoice visible in list', async ({ page }) => {
  await expect(page.getByText('TEST-CREATE-001')).toBeVisible({
    timeout: 15_000,
  });
  await expect(page.getByText(/fixture supplier/i)).toBeVisible();
});
```
