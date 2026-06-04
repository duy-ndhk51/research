# Peppol Import

**File**: `tests/financial/purchase-invoices/004-peppol-import.spec.ts`
**Seed scenario**: `purchase-invoice-peppol`

Tests creating a purchase invoice from a Peppol electronic invoice.

**Note**: These tests depend on a seeded Peppol invoice with XML data. The exact navigation to Peppol inbox may vary depending on workspace configuration.

---

## E2E-013: Open Peppol invoice and verify pre-filled data

**Preconditions**: Seeded Peppol invoice with XML data and pre-matched supplier.

### Steps

1. Navigate to Peppol inbox or the Peppol-linked purchase invoice creation
2. Select the pending Peppol invoice
3. Verify form opens with pre-filled data

### Assertions

- Building, supplier, invoice number, date pre-filled from Peppol data
- Amount lines populated from Peppol line items

### Example Code

```typescript
import { test, expect, requireEnv } from '../../test-base';

const WORKSPACE_ID = requireEnv('QA_SYNDIC_WORKSPACE_ID');

test.beforeAll(async ({ seedScenario }) => {
  await seedScenario({
    scenario: 'purchase-invoice-peppol',
    workspaceId: WORKSPACE_ID,
  });
});

test.afterAll(async ({ resetScenario }) => {
  await resetScenario(WORKSPACE_ID);
});

test('E2E-013: peppol invoice pre-fills form data', async ({ page }) => {
  // Navigate to peppol inbox (route depends on workspace config)
  await page.goto('/financial/invoices/purchase');

  // The peppol invoice may appear in a dedicated tab or section
  // Exact selectors depend on peppol inbox UI
  // await page.getByRole('tab', { name: /peppol/i }).click();
  // await page.getByText(/fixture peppol invoice/i).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  // Verify pre-filled fields
  await expect(drawer.locator('#invoiceNumber')).not.toHaveValue('');
});
```

---

## E2E-014: Attachments tab visible and defaulted (with attachment files)

**Preconditions**: Peppol invoice has 2 attachments (PDF + XML).

### Steps

1. Check right panel tabs after Peppol form opens

### Assertions

- "Peppol attachments" tab is visible in the right panel
- Tab is the active/default tab (not uploader)
- Attachment list shows the seeded attachments (PDF + XML files)
- The "Invoice preview" (uploader) tab falls back to the drag-drop upload zone

### Example Code

```typescript
test('E2E-014: peppol attachments tab visible and default', async ({ page }) => {
  // ... (peppol form opened) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  await expect(
    drawer.getByText(/peppol attachments/i),
  ).toBeVisible();

  // The attachments tab should be active by default
  // Verify attachment items are listed
  await expect(drawer.getByText(/\.pdf/i)).toBeVisible();

  // Switch to uploader tab — should show upload zone (not PeppolParsedPreview)
  await drawer.getByText(/invoice preview/i).click();
  await expect(drawer.locator('[data-testid="upload-zone"], .dropzone')).toBeVisible();
});
```

---

## E2E-014b: Attachments tab shows PeppolParsedPreview when no attachment files

**Preconditions**: Peppol invoice with parsed data but no PDF/XML attachment files (empty `attachments` array).

**Seed scenario**: `purchase-invoice-peppol-no-attachments`

### Steps

1. Navigate to a Peppol invoice that has no attachment files
2. Open the form
3. Check right panel tabs

### Assertions

- "Peppol attachments" tab is visible and is the active/default tab
- Tab content shows the structured Peppol parsed preview (supplier info, amounts, line items) instead of attachment file list
- The "Invoice preview" (uploader) tab shows the drag-drop upload zone (not PeppolParsedPreview)
- `hideInlineAttachments` prevents duplicate rendering of the parsed preview in the uploader tab

### Example Code

```typescript
test('E2E-014b: peppol without attachments shows parsed preview in tab', async ({ page }) => {
  // ... (peppol form opened from invoice with no attachments) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  // "Peppol attachments" tab visible and active
  await expect(
    drawer.getByText(/peppol attachments/i),
  ).toBeVisible();

  // No PDF/XML file items — instead, the parsed preview is shown
  // Look for structured preview elements (supplier name, amounts, line items)
  await expect(
    drawer.locator('[data-testid="peppol-parsed-preview"], .peppol-parsed-preview').first(),
  ).toBeVisible();

  // Verify the uploader tab shows the upload zone, not the parsed preview
  await drawer.getByText(/invoice preview/i).click();
  await expect(drawer.locator('[data-testid="upload-zone"], .dropzone')).toBeVisible();
});
```

---

## E2E-015: Amounts are locked

**Preconditions**: Peppol invoice with amounts.

### Steps

1. Check lock state indicator in the form footer

### Assertions

- Lock icon or locked total indicator is visible
- Total amount matches Peppol data
- Lock toggle button is visible but shows locked state

### Example Code

```typescript
test('E2E-015: peppol amounts are locked', async ({ page }) => {
  // ... (peppol form opened) ...
  const drawer = page.locator('[data-slot="sheet-content"]');

  // Look for lock indicator in the invoice lines footer
  // The exact selector depends on the lock UI (icon, badge, etc.)
  await expect(
    drawer.locator('[data-testid="lock-indicator"], [aria-label*="lock"]').first(),
  ).toBeVisible();
});
```

---

## E2E-016: Submit Peppol invoice

**Preconditions**: Pre-filled Peppol data verified, any missing required fields filled.

### Steps

1. Fill any remaining required fields (payment accounts if not pre-filled)
2. Submit the form
3. Wait for POST response

### Assertions

- POST request is sent with `peppolInvoiceId` in the payload
- Response is 2xx
- Drawer closes

### Example Code

```typescript
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

test('E2E-016: submit peppol invoice', async ({ page }) => {
  // ... (peppol form opened and verified) ...
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
  await expect(drawer).not.toBeVisible({ timeout: 10_000 });
});
```
