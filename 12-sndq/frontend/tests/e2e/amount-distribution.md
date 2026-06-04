# Amount Distribution

**File**: `tests/financial/purchase-invoices/010-amount-distribution.spec.ts`
**Seed scenario**: `purchase-invoice-create` (building with multiple units + distribution keys)

Tests the full user journey of the amount distribution sheet: opening from invoice lines, selecting units, allocating amounts across distribution types, applying suggestions, and verifying persistence back to the parent form.

---

## E2E-040: Open distribution sheet from invoice lines

**Preconditions**: Create form open, building + supplier selected. Invoice lines section visible.

### Steps

1. Navigate to `/financial/invoices/purchase`
2. Click "Add invoice", select building + supplier
3. Click "Add line" or the amount row to open the distribution sheet

### Assertions

- Distribution sheet (`[data-slot="sheet-content"]`) becomes visible as a bottom sheet
- All building units are listed in the left panel
- Cost account select and distribution method section visible in right panel

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

test('E2E-040: open distribution sheet from invoice lines', async ({ page }) => {
  await page.goto('/financial/invoices/purchase');
  await page.getByRole('button', { name: /add invoice/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await selectBuildingAndSupplier(page, drawer);

  // Open distribution sheet
  await drawer.getByRole('button', { name: /add line|add amount/i }).click();

  const distSheet = page.locator('[data-slot="sheet-content"]').last();
  await expect(distSheet).toBeVisible();
  await expect(distSheet.getByText(/cost account|cost category/i)).toBeVisible();
});
```

---

## E2E-041: Partial unit selection shows allocation progress

**Preconditions**: Distribution sheet open with 5 building units.

### Steps

1. Check 3 of 5 unit checkboxes
2. Observe allocation progress indicator

### Assertions

- Allocation progress shows partial state (not 100%)
- Unchecked units show zero amounts
- Checked units have non-zero shares (if in share mode)

### Example Code

```typescript
test('E2E-041: partial unit selection reflected in progress', async ({ page }) => {
  // ... distribution sheet open ...
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  // Select 3 units
  const checkboxes = distSheet.locator('[data-testid^="unit-checkbox"]');
  await checkboxes.nth(0).click();
  await checkboxes.nth(1).click();
  await checkboxes.nth(2).click();

  // Allocation progress should show partial
  const progress = distSheet.locator('[data-testid="allocation-progress"]');
  await expect(progress).toBeVisible();
});
```

---

## E2E-042: Share mode distributes total across selected units

**Preconditions**: Distribution sheet open, 3 units selected, total amount set to 500 EUR.

### Steps

1. Set total amount to `500.00`
2. Verify "Share" distribution mode is active (default)
3. Check that amounts are distributed proportionally

### Assertions

- Sum of unit amounts equals total amount (50000 cents)
- Each selected unit has a non-zero amount
- Allocation progress shows 100%

### Example Code

```typescript
test('E2E-042: share mode distributes amount across units', async ({ page }) => {
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  // Enable whole building
  await distSheet.getByLabel(/whole building/i).click();

  // Set total amount
  const totalInput = distSheet.locator('input[name="totalAmount"]');
  await totalInput.fill('500');

  // Verify amounts distributed
  const amountCells = distSheet.locator('[data-testid^="unit-amount"]');
  const count = await amountCells.count();
  expect(count).toBeGreaterThan(0);

  // Check allocation progress shows complete
  await expect(distSheet.getByText(/100%|fully allocated/i)).toBeVisible({
    timeout: 5_000,
  });
});
```

---

## E2E-043: Switch to percentage mode recalculates display

**Preconditions**: Distribution sheet open, share mode active with distributed amounts.

### Steps

1. Click "Percentage" distribution type
2. Observe share values change to percentages

### Assertions

- Share column values are percentages (e.g., displayed as %, sum close to 100)
- Total share input shows `10000` (percentage base)
- Unit amounts remain proportionally correct

### Example Code

```typescript
test('E2E-043: switching to percentage recalculates shares', async ({ page }) => {
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  await distSheet.getByLabel(/whole building/i).click();
  await distSheet.locator('input[name="totalAmount"]').fill('500');

  // Switch to percentage
  await distSheet.getByLabel(/percentage/i).click();

  // Total share should show percentage base
  const totalShareInput = distSheet.locator('input[name="totalShare"]');
  await expect(totalShareInput).toHaveValue('10000');
});
```

---

## E2E-044: Apply distribution key from dropdown

**Preconditions**: Distribution sheet open, building has distribution keys seeded.

### Steps

1. Select "Distribution key" mode
2. Pick a distribution key from the dropdown
3. Observe amounts recalculated

### Assertions

- All units selected (whole building forced)
- Unit shares match the key's ratios
- Amounts recalculated based on key shares and total amount
- `distributionKeyId` visible in the dropdown

### Example Code

```typescript
test('E2E-044: applying distribution key distributes by key ratios', async ({ page }) => {
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  await distSheet.locator('input[name="totalAmount"]').fill('1000');

  // Switch to distribution key mode
  await distSheet.getByLabel(/distribution key/i).click();

  // Select a specific key
  const dkSelect = distSheet.locator('[data-testid="distribution-key-select"]');
  await dkSelect.click();
  await page.getByRole('option').first().click();

  // Whole building should be forced on
  await expect(distSheet.getByLabel(/whole building/i)).toBeChecked();

  // Amounts should be distributed
  await expect(distSheet.getByText(/100%|fully allocated/i)).toBeVisible({
    timeout: 5_000,
  });
});
```

---

## E2E-045: Ledger suggestion chip populates cost account

**Preconditions**: Distribution sheet open, supplier has historical ledger usage (suggestions returned by API).

### Steps

1. Wait for suggestion chips to appear below cost account select
2. Click a suggestion chip

### Assertions

- Cost account field populated with the suggestion's ledger
- Suggestion chip shows selected/active state

### Example Code

```typescript
test('E2E-045: clicking ledger suggestion fills cost account', async ({ page }) => {
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  // Wait for suggestions to load
  const suggestionChip = distSheet.locator('[data-testid="suggestion-chip"]').first();
  await expect(suggestionChip).toBeVisible({ timeout: 10_000 });

  const chipText = await suggestionChip.textContent();
  await suggestionChip.click();

  // Cost account should now show the selected ledger
  const costAccountField = distSheet.locator('[data-testid="cost-account-select"]');
  await expect(costAccountField).toContainText(chipText!);
});
```

---

## E2E-046: Save and close persists line to parent form

**Preconditions**: Distribution sheet open with total amount, cost account, and distribution configured.

### Steps

1. Set total amount to `250.00`
2. Select a cost account
3. Enable whole building with share distribution
4. Click "Save & Close"
5. Verify the line appears in the parent invoice form

### Assertions

- Distribution sheet closes
- Invoice lines table shows a new row with total `€250,00`
- Cost account name visible in the line
- Invoice total footer updates

### Example Code

```typescript
import { isOkResponse } from '../../helpers/response';

test('E2E-046: save & close adds line to parent form', async ({ page }) => {
  const distSheet = page.locator('[data-slot="sheet-content"]').last();

  await distSheet.locator('input[name="totalAmount"]').fill('250');
  await distSheet.getByLabel(/whole building/i).click();

  // Select cost account
  await distSheet.getByText(/select.*ledger|cost account/i).click();
  await page.getByRole('option').first().click();

  // Save
  await distSheet.getByRole('button', { name: /save.*close/i }).click();

  // Sheet should close
  await expect(distSheet).not.toBeVisible({ timeout: 5_000 });

  // Line should appear in parent form
  const parentDrawer = page.locator('[data-slot="sheet-content"]');
  await expect(parentDrawer.getByText('€250,00')).toBeVisible();
});
```

---

## E2E-047: Edit existing line re-opens with saved state

**Preconditions**: Invoice form has an existing amount line (from E2E-046 or seed data).

### Steps

1. Click the existing amount line to open the distribution sheet
2. Observe pre-filled values

### Assertions

- Total amount matches the saved value
- Cost account pre-selected
- Unit selection and shares match saved distribution
- Distribution type preserved

### Example Code

```typescript
test('E2E-047: editing line opens sheet with saved allocations', async ({ page }) => {
  const parentDrawer = page.locator('[data-slot="sheet-content"]');

  // Click existing line to edit
  await parentDrawer.locator('[data-testid="amount-line-row"]').first().click();

  const distSheet = page.locator('[data-slot="sheet-content"]').last();
  await expect(distSheet).toBeVisible();

  // Verify pre-filled values
  const totalInput = distSheet.locator('input[name="totalAmount"]');
  const value = await totalInput.inputValue();
  expect(Number(value)).toBeGreaterThan(0);

  // Cost account should be pre-selected
  const costAccount = distSheet.locator('[data-testid="cost-account-select"]');
  await expect(costAccount).not.toContainText(/select/i);
});
```
