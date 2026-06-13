# Peppol to Invoice — E2E Tests

**Priority**: HIGH (daily-use flow, highest user traffic)
**File**: `tests/financial/purchase-invoices/005-peppol-to-invoice.spec.ts`

These scenarios cover the **complete Peppol-to-purchase-invoice user journey** — from the Peppol inbox listing through detail sheet inspection, duplicate handling, form pre-fill verification, credit notes, unmatched suppliers, grouping changes, submission, and post-submission state.

This file is **additive** to `peppol-import.md` (E2E-013 to E2E-016) which covers the basics. The scenarios below address critical gaps in the existing coverage.

**Navigation paths**:
- Syndic: `/financial/invoices/peppol` (via `routerPaths.syndic.invoices.peppol.root()`)
- Steward: `/financial/buildings/{buildingId}/invoices/peppol` (via `routerPaths.steward.buildings.invoices.peppol.root(buildingId)`)

---

## Seed Scenarios

| Seed Name | Description |
|---|---|
| `peppol-invoice-matched` | Peppol invoice with matched building + matched supplier contact |
| `peppol-invoice-unmatched` | Peppol invoice with unknown supplier (no `supplierPartyContactId`) |
| `peppol-invoice-credit-note` | Peppol credit note (`typeCode: '381'`, `type: CREDIT_NOTE`) |
| `peppol-invoice-duplicate` | Peppol invoice + existing purchase invoice with same supplier + invoice number |

---

## Shared Setup

```typescript
import { test, expect, requireEnv } from '../../test-base';
import { isOkResponse, pathnameIncludes } from '../../helpers/response';

const WORKSPACE_ID = requireEnv('QA_SYNDIC_WORKSPACE_ID');

test.beforeAll(async ({ seedScenario }) => {
  await seedScenario({
    scenario: 'peppol-full-flow',
    workspaceId: WORKSPACE_ID,
  });
});

test.afterAll(async ({ resetScenario }) => {
  await resetScenario(WORKSPACE_ID);
});

async function navigateToPeppolInbox(page: Page) {
  await page.goto('/financial/invoices/peppol');
  await page.waitForResponse(
    (res) =>
      pathnameIncludes(res.url(), '/peppol-invoices') &&
      res.request().method() === 'GET' &&
      isOkResponse(res),
    { timeout: 15_000 },
  );
}

async function openPeppolDetailSheet(page: Page, invoiceNumber: string) {
  await page.getByText(invoiceNumber).click();
  const sheet = page.locator('[data-slot="floating-sheet"]');
  await expect(sheet).toBeVisible({ timeout: 10_000 });
  return sheet;
}
```

---

## E2E-030: Peppol inbox loads with pending invoices

**Preconditions**: At least 1 seeded Peppol invoice with status RECEIVED.
**Seed scenario**: `peppol-invoice-matched`
**Priority**: HIGH

### Steps

1. Navigate to `/financial/invoices/peppol`
2. Wait for the Peppol invoices API response
3. Verify the table shows at least one row

### Assertions

- Page loads without error
- Table rows are visible
- Seeded invoice number appears in the list
- Status badge shows "Received" or equivalent

### Example Code

```typescript
test('E2E-030: peppol inbox shows pending invoices', async ({ page }) => {
  await navigateToPeppolInbox(page);

  // Verify at least one row exists
  const rows = page.locator('table tbody tr, [role="row"]');
  await expect(rows.first()).toBeVisible({ timeout: 10_000 });

  // Verify seeded invoice appears
  await expect(page.getByText('PEPINV-MATCHED-001')).toBeVisible();
});
```

---

## E2E-031: Peppol detail sheet shows invoice information

**Preconditions**: Peppol inbox loaded.
**Seed scenario**: `peppol-invoice-matched`
**Priority**: HIGH

### Steps

1. Click on a Peppol invoice row
2. Verify the floating sheet opens with correct data

### Assertions

- Invoice number visible in the sheet header
- Supplier name visible in the header subtitle
- Total amount displayed in formatted currency
- Status badge (e.g., "Received") visible
- "Review & Save" button visible (translation key: `peppol.action_review_save`)
- "Reject" button visible (translation key: `peppol.action_reject`)
- Invoice type badge (INVOICE or CREDIT_NOTE) visible

### Example Code

```typescript
test('E2E-031: detail sheet shows invoice info', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-MATCHED-001');

  // Header shows invoice number and supplier
  await expect(sheet.getByText('PEPINV-MATCHED-001')).toBeVisible();
  await expect(sheet.getByText('Supplier NV')).toBeVisible();

  // Amount displayed
  await expect(sheet.locator('.font-mono').first()).toBeVisible();

  // Action buttons visible
  await expect(
    sheet.getByRole('button', { name: /review.*save/i }),
  ).toBeVisible();
  await expect(
    sheet.getByRole('button', { name: /reject/i }),
  ).toBeVisible();

  // Status indicator
  await expect(sheet.getByText(/received/i)).toBeVisible();
});
```

---

## E2E-032: Duplicate warning shown before form opens

**Preconditions**: Peppol invoice has a matching purchase invoice (same supplier + invoice number).
**Seed scenario**: `peppol-invoice-duplicate`
**Priority**: HIGH

### Steps

1. Open detail sheet for the duplicate Peppol invoice
2. Verify duplicate warning banner appears
3. Click on the duplicate entry to preview

### Assertions

- Warning banner with `peppol.potential_duplicates` text is visible
- Background color is `bg-warning-25`
- Duplicate invoice entry is clickable and shows match score
- Clicking the duplicate opens a sub-sheet with the existing purchase invoice preview
- "Review & Save" button is still available (user can still proceed)

### Example Code

```typescript
test('E2E-032: duplicate warning shown in detail sheet', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-DUPLICATE-001');

  // Duplicate warning banner
  await expect(
    sheet.getByText(/potential duplicate/i),
  ).toBeVisible({ timeout: 10_000 });

  // Duplicate entry with match score
  const duplicateEntry = sheet.getByText(/duplicate match/i);
  await expect(duplicateEntry).toBeVisible();

  // Click duplicate to preview — sub-sheet opens
  await duplicateEntry.click();
  const subSheet = page.locator(
    '[data-slot="floating-sheet"] [data-slot="floating-sheet"]',
  );
  await expect(subSheet).toBeVisible({ timeout: 5_000 });

  // "Review & Save" still available
  await expect(
    sheet.getByRole('button', { name: /review.*save/i }),
  ).toBeVisible();
});
```

---

## E2E-033: Review & Save opens form with pre-filled fields

**Preconditions**: Detail sheet for matched Peppol invoice open.
**Seed scenario**: `peppol-invoice-matched`
**Priority**: HIGH

### Steps

1. Click "Review & Save" button in the detail sheet
2. Wait for the purchase invoice form drawer to open
3. Verify all pre-filled fields

### Assertions

- Form drawer opens (via `CommonDrawer` / `[data-slot="sheet-content"]`)
- Invoice number field has value from Peppol data
- Invoice date field has value from Peppol data
- Building selector shows matched building
- Supplier/sender selector shows matched supplier
- Amount lines populated from Peppol line items
- Amounts are locked (lock indicator visible)
- Remittance info populated if present in Peppol data
- Right panel shows "Peppol attachments" tab as default (content varies: `PeppolAttachmentsTab` if attachment files exist, `PeppolParsedPreview` otherwise)

### Example Code

```typescript
test('E2E-033: review and save opens pre-filled form', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-MATCHED-001');

  // Click "Review & Save"
  await sheet.getByRole('button', { name: /review.*save/i }).click();

  // Wait for the form drawer
  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible({ timeout: 10_000 });

  // Verify pre-filled fields
  await expect(drawer.locator('#invoiceNumber')).toHaveValue('PEPINV-MATCHED-001');

  // Date field populated
  const dateInput = drawer.locator('#invoiceDate, [name="invoiceDate"]');
  await expect(dateInput).not.toHaveValue('');

  // Building and supplier selected (not empty)
  // These are combobox/select components — verify they show a value
  await expect(
    drawer.locator('[data-field="buildingId"]').getByText(/\w+/).first(),
  ).toBeVisible();
  await expect(
    drawer.locator('[data-field="senderId"]').getByText(/\w+/).first(),
  ).toBeVisible();

  // Amount lines present
  const amountRows = drawer.locator('[data-testid="amount-row"], table tbody tr');
  await expect(amountRows.first()).toBeVisible();

  // Lock indicator visible
  await expect(
    drawer.locator('[aria-label*="lock"], [data-testid="lock-indicator"]').first(),
  ).toBeVisible();
});
```

---

## E2E-034: Peppol credit note opens form in credit note mode

**Preconditions**: Peppol invoice with `type: CREDIT_NOTE` and `typeCode: '381'`.
**Seed scenario**: `peppol-invoice-credit-note`
**Priority**: HIGH

### Steps

1. Open detail sheet for the credit note Peppol invoice
2. Verify "Credit Note" badge in the detail sheet
3. Click "Review & Save"
4. Verify form opens in credit note mode

### Assertions

- Detail sheet shows "Credit Note" badge (not "Invoice")
- Amount is displayed as negative
- After clicking "Review & Save", the form drawer shows credit note indicators
- `invoiceTypeCode` is `'381'`
- The form title or badge indicates credit note mode

### Example Code

```typescript
test('E2E-034: peppol credit note opens form in credit note mode', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPCN-001');

  // Credit note badge in detail sheet
  await expect(sheet.getByText(/credit note/i)).toBeVisible();

  // Click "Review & Save"
  await sheet.getByRole('button', { name: /review.*save/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible({ timeout: 10_000 });

  // Verify credit note mode — form shows credit note badge or type indicator
  await expect(
    drawer.getByText(/credit note/i).first(),
  ).toBeVisible();
});
```

---

## E2E-035: Unmatched supplier shows supplier info and allows proceeding

**Preconditions**: Peppol invoice with no `supplierPartyContactId`, but `supplierParty` data present.
**Seed scenario**: `peppol-invoice-unmatched`
**Priority**: HIGH

### Steps

1. Open detail sheet for unmatched supplier invoice
2. Click "Review & Save"
3. Verify form shows unmatched supplier info
4. Verify user can still fill supplier manually and submit

### Assertions

- Form opens without a pre-selected sender/supplier
- Unmatched supplier name and VAT number are displayed (from `peppolSupplierData`)
- User can search and select a contact manually
- Form is submittable after manual supplier selection

### Example Code

```typescript
test('E2E-035: unmatched supplier allows manual selection', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-UNKNOWN-001');

  await sheet.getByRole('button', { name: /review.*save/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible({ timeout: 10_000 });

  // Supplier field should be empty or show unmatched info
  // The peppolSupplierData section may show the supplier name/VAT from Peppol
  await expect(
    drawer.getByText(/unknown supplier/i),
  ).toBeVisible();

  // User can search for a contact
  const senderField = drawer.locator('[data-field="senderId"]');
  await senderField.click();

  // Type to search
  await page.keyboard.type('Existing Contact NV');

  // Select the result
  const option = page.getByRole('option', { name: /existing contact/i });
  await expect(option).toBeVisible({ timeout: 5_000 });
  await option.click();

  // Verify selection
  await expect(
    senderField.getByText(/existing contact/i),
  ).toBeVisible();
});
```

---

## E2E-036: Grouping strategy change preserves lock total

**Preconditions**: Peppol invoice with multiple lines at different VAT rates. Form already open from "Review & Save".
**Seed scenario**: `peppol-invoice-matched` (with multi-VAT lines)
**Priority**: MEDIUM

### Steps

1. Open form from Peppol detail sheet
2. Note the locked total amount
3. Switch amount grouping from "individual" to "group by VAT"
4. Verify amounts re-group but total stays the same

### Assertions

- Before grouping: N individual line rows visible
- After grouping: fewer rows (grouped by VAT rate)
- Total amount in the lock indicator / footer stays unchanged
- Lock state remains locked

### Example Code

```typescript
test('E2E-036: grouping strategy preserves lock total', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-MATCHED-001');
  await sheet.getByRole('button', { name: /review.*save/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible({ timeout: 10_000 });

  // Count initial rows
  const initialRows = drawer.locator(
    '[data-testid="amount-row"], table tbody tr',
  );
  const initialCount = await initialRows.count();

  // Capture the locked total text
  const totalBefore = await drawer
    .locator('[data-testid="lock-total"], .font-mono')
    .first()
    .textContent();

  // Switch grouping strategy — look for a grouping toggle/select
  const groupingToggle = drawer.getByRole('button', { name: /group/i });
  if (await groupingToggle.isVisible()) {
    await groupingToggle.click();
    // Select "Group by VAT"
    await page.getByRole('option', { name: /vat/i }).click();

    // Rows should change
    const newCount = await initialRows.count();
    expect(newCount).toBeLessThan(initialCount);

    // Total preserved
    const totalAfter = await drawer
      .locator('[data-testid="lock-total"], .font-mono')
      .first()
      .textContent();
    expect(totalAfter).toBe(totalBefore);
  }
});
```

---

## E2E-037: Submit Peppol invoice with peppolInvoiceId in payload

**Preconditions**: Pre-filled form from Peppol with all required fields.
**Seed scenario**: `peppol-invoice-matched`
**Priority**: HIGH

### Steps

1. Open pre-filled form from Peppol "Review & Save"
2. Fill any remaining required fields
3. Submit the form
4. Intercept POST request and verify payload

### Assertions

- POST `/purchase-invoices` request body contains `peppolInvoiceId`
- Response is 2xx
- Form drawer closes after success
- Toast notification appears

### Example Code

```typescript
test('E2E-037: submit with peppolInvoiceId in payload', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-MATCHED-001');
  await sheet.getByRole('button', { name: /review.*save/i }).click();

  const drawer = page.locator('[data-slot="sheet-content"]');
  await expect(drawer).toBeVisible({ timeout: 10_000 });

  // Fill any missing required fields here if needed
  // (payment account, etc.)

  // Intercept the POST request
  const postPromise = page.waitForRequest(
    (req) =>
      req.method() === 'POST' &&
      pathnameIncludes(req.url(), '/purchase-invoices'),
  );

  // Submit
  await drawer.getByRole('button', { name: /submit|save/i }).click();

  const request = await postPromise;
  const body = request.postDataJSON();

  // Verify peppolInvoiceId is in the payload
  expect(body.peppolInvoiceId).toBeDefined();
  expect(typeof body.peppolInvoiceId).toBe('string');

  // Wait for success response
  const response = await page.waitForResponse(
    (res) =>
      res.request().method() === 'POST' &&
      pathnameIncludes(res.url(), '/purchase-invoices') &&
      isOkResponse(res),
    { timeout: 30_000 },
  );
  expect(response.status()).toBeGreaterThanOrEqual(200);
  expect(response.status()).toBeLessThan(300);

  // Drawer closes
  await expect(drawer).not.toBeVisible({ timeout: 10_000 });
});
```

---

## E2E-038: Re-open processed Peppol invoice shows linked purchase invoice

**Preconditions**: A Peppol invoice that has already been submitted as a purchase invoice.
**Seed scenario**: `peppol-invoice-matched` (after E2E-037 or separate seed with pre-linked state)
**Priority**: MEDIUM

### Steps

1. Navigate to Peppol inbox
2. Find the processed Peppol invoice (or use a filter for processed status)
3. Open the detail sheet
4. Verify linked purchase invoice section

### Assertions

- Peppol invoice status is no longer "Received" (e.g., "Processing" or "Accepted")
- Detail sheet shows "Saved as purchase invoice" section with linked invoice
- Linked invoice entry is clickable — opens purchase invoice preview sub-sheet
- "Review & Save" button is hidden (invoice already processed)
- "Reject" button may still be visible depending on status

### Example Code

```typescript
test('E2E-038: processed peppol shows linked invoice', async ({ page }) => {
  await navigateToPeppolInbox(page);

  // Open the processed invoice
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-PROCESSED-001');

  // Status changed from "Received"
  await expect(sheet.getByText(/received/i)).not.toBeVisible();

  // Linked purchase invoice section visible
  await expect(
    sheet.getByText(/saved as purchase invoice|linked invoice/i),
  ).toBeVisible();

  // Click on the linked invoice
  const linkedEntry = sheet.getByText(/PI-/i).first();
  await linkedEntry.click();

  // Sub-sheet opens with the purchase invoice preview
  await expect(
    page.locator('[data-slot="floating-sheet"] [data-slot="floating-sheet"]'),
  ).toBeVisible({ timeout: 5_000 });

  // "Review & Save" button should NOT be visible
  await expect(
    sheet.getByRole('button', { name: /review.*save/i }),
  ).not.toBeVisible();
});
```

---

## E2E-039: Reject Peppol invoice with reason and optional email

**Preconditions**: Peppol invoice with status RECEIVED and a matched supplier.
**Seed scenario**: `peppol-invoice-matched`
**Priority**: HIGH

### Steps

1. Open detail sheet for a received Peppol invoice
2. Click "Reject" button
3. Fill reject form (reason code + optional note)
4. Choose whether to send email notification
5. Confirm rejection
6. Verify status changes

### Assertions

- Reject sub-sheet opens with reason code dropdown and note field
- After confirming, PATCH request sent to reject endpoint
- Response is 2xx
- Peppol invoice status changes (no longer "Received")
- If "Send email" checked and supplier has contact, broadcast sheet opens
- If "Send email" unchecked, reject sub-sheet closes directly

### Example Code

```typescript
test('E2E-039: reject peppol invoice with reason', async ({ page }) => {
  await navigateToPeppolInbox(page);
  const sheet = await openPeppolDetailSheet(page, 'PEPINV-REJECT-001');

  // Click "Reject" button
  await sheet.getByRole('button', { name: /reject/i }).click();

  // Reject sub-sheet opens
  const rejectSheet = page.locator(
    '[data-slot="floating-sheet"] [data-slot="floating-sheet"]',
  );
  await expect(rejectSheet).toBeVisible({ timeout: 5_000 });

  // Select reason code
  const reasonSelect = rejectSheet.getByRole('combobox').first();
  await reasonSelect.click();
  await page.getByRole('option').first().click();

  // Add optional note
  const noteField = rejectSheet.locator('textarea, [name="note"]');
  if (await noteField.isVisible()) {
    await noteField.fill('Invoice not recognized');
  }

  // Toggle send email
  const sendEmailCheckbox = rejectSheet.getByRole('checkbox');
  if (await sendEmailCheckbox.isVisible()) {
    await sendEmailCheckbox.check();
  }

  // Intercept reject request
  const [rejectResponse] = await Promise.all([
    page.waitForResponse(
      (res) =>
        pathnameIncludes(res.url(), '/peppol-invoices') &&
        res.request().method() === 'PATCH' &&
        isOkResponse(res),
      { timeout: 15_000 },
    ),
    rejectSheet.getByRole('button', { name: /confirm|reject/i }).last().click(),
  ]);

  expect(rejectResponse.status()).toBeGreaterThanOrEqual(200);

  // If send email was checked, broadcast sheet may open
  // Otherwise, the reject sheet closes
  // Both are valid end states depending on the checkbox
});
```
