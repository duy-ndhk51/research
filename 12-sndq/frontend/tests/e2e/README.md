# E2E Test Strategy — Purchase Invoice V3

## Purpose

E2E tests validate **critical user journeys** against the real application (dev server or staging). They catch issues that integration tests miss: routing, auth, real API responses, network timing, and full form submission flows.

## Tech Stack

- **Playwright** (already configured in `sndq-fe/playwright.config.ts`)
- Auth setup from `tests/setup/auth.setup.ts` (stored session)
- Test base from `tests/test-base.ts` (seed scenarios, env helpers)
- Response helpers from `tests/helpers/response.ts`

## File Location

Tests go in `sndq-fe/tests/financial/purchase-invoices/` following the existing pattern from `tests/financial/payment-initiations/`.

## Navigation Paths

| Goal | Path |
|------|------|
| Purchase invoice list | `/financial/invoices/purchase` |
| Create new invoice | List page -> click "Add invoice" -> CommonDrawer opens |
| View invoice detail | Click row -> `/financial/invoices/purchase/{id}` -> FloatingSheet |
| Edit existing invoice | Detail -> Actions -> Edit -> CommonDrawer opens |
| Peppol inbox (syndic) | `/financial/invoices/peppol` |
| Peppol inbox (steward) | `/financial/buildings/{buildingId}/invoices/peppol` |
| Peppol detail | Click row -> FloatingSheet with detail + "Review & Save" button |

The form mounts inside a `CommonDrawer` (bottom sheet at 95vh with `data-slot="sheet-content"`). The URL does NOT change for create; for edit, the URL stays on the detail route.

## Key Selectors

```typescript
// Create button
page.getByRole('button', { name: /add invoice/i })

// Form drawer (CommonDrawer)
page.locator('[data-slot="sheet-content"]')

// Floating sheet (detail view)
page.locator('[data-slot="floating-sheet"]')

// Building select
page.getByText(/building/i).first()

// Supplier select
page.getByText(/supplier/i).first()

// Invoice number input
page.locator('#invoiceNumber')

// Submit button (in form header)
page.getByRole('button', { name: /submit|save/i })

// Mode toggle (invoice/credit note/expense note)
page.getByRole('button', { name: /invoice|credit note/i })

// Actions menu (in detail floating sheet)
page.getByRole('button', { name: /actions/i })
page.getByRole('menuitem', { name: /edit/i })
```

## Seed Scenarios Required

Each test suite requires specific backend seed data. These scenarios must be created in the backend `test/scenarios/` system.

| Scenario name | What it provides |
|---------------|------------------|
| `purchase-invoice-create` | Building with ledgers + distribution keys, supplier contact with IBAN, Ponto bank account for the building |
| `purchase-invoice-edit` | Same as create + an existing approved invoice with 2 amount lines, supplier link, payment details |
| `purchase-invoice-peppol` | Same as create + a pending Peppol invoice with XML data, 2 attachments (PDF + XML), pre-matched supplier |
| `purchase-invoice-draft` | Same as create + a saved draft invoice with partial data (building + supplier + 1 amount, no payment) |
| `purchase-invoice-partial-edit` | Same as edit + invoice is booked/partially paid (triggers partial edit mode) |
| `peppol-invoice-matched` | Peppol invoice with matched building + matched supplier contact |
| `peppol-invoice-unmatched` | Peppol invoice with unknown supplier (no `supplierPartyContactId`) |
| `peppol-invoice-credit-note` | Peppol credit note (`typeCode: '381'`, `type: CREDIT_NOTE`) |
| `peppol-invoice-duplicate` | Peppol invoice + existing purchase invoice with same supplier + invoice number |

### Seed scenario data contract

Each seed should create entities with predictable names for selector stability:

```typescript
{
  building: { name: 'Fixture Building One' },
  supplier: { name: 'Fixture Supplier NV' },
  bankAccount: { iban: 'BE68539007547034' },
  ledger: { name: 'Maintenance', code: '61200' },
  distributionKey: { name: 'Equal split' },
  invoice: {
    invoiceNumber: 'TEST-2026-001',
    amounts: [{ totalAmount: 10000 }],  // 100.00 EUR
  },
}
```

## Response Wait Helpers

Reuse and extend the existing helpers from `tests/helpers/response.ts`:

```typescript
import { isOkResponse, pathnameIncludes } from '../../helpers/response';
import type { Page } from '@playwright/test';

function waitForCreateInvoice(page: Page) {
  return page.waitForResponse(
    (res) =>
      res.request().method() === 'POST' &&
      pathnameIncludes(res.url(), '/purchase-invoices') &&
      isOkResponse(res),
    { timeout: 30_000 },
  );
}

function waitForUpdateInvoice(page: Page) {
  return page.waitForResponse(
    (res) =>
      res.request().method() === 'PUT' &&
      pathnameIncludes(res.url(), '/purchase-invoices/') &&
      isOkResponse(res),
    { timeout: 30_000 },
  );
}

function waitForDeleteInvoice(page: Page) {
  return page.waitForResponse(
    (res) =>
      res.request().method() === 'DELETE' &&
      pathnameIncludes(res.url(), '/purchase-invoices/') &&
      isOkResponse(res),
    { timeout: 30_000 },
  );
}
```

## Running Tests

```bash
# All purchase invoice E2E tests
pnpm test:e2e tests/financial/purchase-invoices/

# Specific test file
pnpm test:e2e tests/financial/purchase-invoices/001-create-invoice.spec.ts

# With debug (headed browser)
pnpm test:e2e --headed tests/financial/purchase-invoices/

# Generate new test with codegen
pnpm test:e2e:codegen
```

## File Naming Convention

- Test files: `{NNN}-{feature}.spec.ts` (sequential numbering)
- Helpers: `helpers/{feature}.helper.ts`
- Scenario IDs: `E2E-{NNN}` (sequential across all files)

## Scenario Index

### Create Invoice ([create-invoice.md](./create-invoice.md))

**Purpose**: Validate the complete happy path for creating a new purchase invoice. This is the foundational flow all other flows build on.
**Scope**: Navigation to list, drawer opening, building/supplier selection, amount entry with ledger, form submission, list verification.
**Risk**: Users can't create invoices at all. Any regression in the create path blocks the entire invoicing workflow.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-001 | Open create form | Navigate to list → click "Add invoice" → drawer opens with fields visible | - [ ] |
| E2E-002 | Building + supplier reveals full form | Select building → select supplier → placeholder gone, payment section appears | - [ ] |
| E2E-003 | Fill amount line with ledger | Fill invoice number + amount + cost account → total footer shows `€100,00` | - [ ] |
| E2E-004 | Submit invoice successfully | Fill all required fields → submit → POST 2xx → drawer closes | - [ ] |
| E2E-005 | Created invoice appears in list | After submit → list page shows new invoice number + supplier name | - [ ] |

### Edit Invoice ([edit-invoice.md](./edit-invoice.md))

**Purpose**: Validate data persistence and modification of existing invoices. Ensures saved data loads correctly and changes are properly submitted.
**Scope**: Detail sheet → edit transition, data pre-fill verification, amount modification, supplier change side effects, discard confirmation.
**Risk**: Edits silently lost, wrong data saved, supplier change doesn't update dependent fields, users discard without confirmation.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-006 | Open existing invoice and verify data | Click row → detail sheet → Actions → Edit → drawer shows saved data | - [ ] |
| E2E-007 | Modify amount and submit | Change amount to 200 → submit → PUT 2xx → drawer closes | - [ ] |
| E2E-008 | Change supplier | Open supplier select → choose different supplier → field updates | - [ ] |
| E2E-009 | Discard changes shows confirmation | Modify field → click back → dialog appears → cancel returns to form | - [ ] |

### Credit Note ([credit-note.md](./credit-note.md))

**Purpose**: Validate mode switching end-to-end, ensuring the correct `invoiceTypeCode` reaches the backend and UI reflects credit note state.
**Scope**: Mode toggle interaction, credit note header display, submission with type code `'381'`, list type badge.
**Risk**: Credit notes rejected by backend due to wrong type code, or created as regular invoices causing accounting errors.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-010 | Switch mode to credit note | Open create form → mode toggle → select "Credit note" → header updates | - [ ] |
| E2E-011 | Fill and submit credit note | Credit note mode → fill fields → submit → POST with `invoiceTypeCode: '381'` | - [ ] |
| E2E-012 | Credit note appears in list | After submit → list shows credit note number + type badge | - [ ] |

### Peppol Import — Basics ([peppol-import.md](./peppol-import.md))

**Purpose**: Validate the basic Peppol-to-form handoff: pre-fill, attachments, lock, and submission. Minimum tests for Peppol functionality.
**Scope**: Form data pre-fill from Peppol XML, attachment tab defaulting, amount lock application, `peppolInvoiceId` in POST payload.
**Risk**: Pre-fill broken (empty fields), attachments missing, amounts editable when they should be locked, Peppol link lost on submission.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-013 | Peppol pre-fills form data | Navigate to Peppol → select invoice → form opens with pre-filled fields | - [ ] |
| E2E-014 | Peppol attachments tab visible and default | After form opens → right panel shows "Peppol attachments" tab active | - [ ] |
| E2E-015 | Peppol amounts are locked | After form opens → lock indicator visible, total matches Peppol data | - [ ] |
| E2E-016 | Submit Peppol invoice | Fill remaining fields → submit → POST with `peppolInvoiceId` → 2xx | - [ ] |

### Draft Save & Resume ([draft-save-resume.md](./draft-save-resume.md))

**Purpose**: Validate the save/resume cycle for incomplete invoices. Drafts allow users to partially fill invoices and return later.
**Scope**: Draft save via combo actions, data persistence across sessions, draft completion and status transition.
**Risk**: Draft data lost on resume, status stuck as draft after submission, partial data not persisted.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-017 | Save as draft | Fill partial data → combo actions → "Save as draft" → POST 2xx, draft badge | - [ ] |
| E2E-018 | Resume draft with persisted data | Find draft → Actions → Edit → building/supplier/amount preserved | - [ ] |
| E2E-019 | Complete draft and submit | Fill remaining fields → submit → PUT 2xx, status changes from draft | - [ ] |

### AI Extraction ([ai-extraction.md](./ai-extraction.md))

**Purpose**: Validate the PDF upload → AI extraction → field population pipeline. Extraction is async with complex state transitions.
**Scope**: Upload trigger, extraction banner lifecycle, field population, confidence indicator display and dismissal.
**Risk**: Extraction banner stuck indefinitely, fields not populated after extraction, confidence indicators persist after manual edit.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-020 | Upload PDF triggers extraction banner | Upload PDF in right panel → "Extracting..." banner appears | - [ ] |
| E2E-021 | Extraction populates fields | Wait for extraction → invoice number + date populated, AI indicators visible | - [ ] |
| E2E-022 | Review extracted field clears indicator | Click + edit extracted field → confidence indicator disappears | - [ ] |

### Partial Edit Mode ([partial-edit.md](./partial-edit.md))

**Purpose**: Validate restricted editing on booked or partially-paid invoices. Certain fields must be locked to maintain accounting integrity.
**Scope**: Warning banner visibility, field disabling (building, supplier, amounts), lock toggle restriction, allowed field editing.
**Risk**: Users modify locked fields on booked invoices (accounting inconsistency), or all fields locked including editable ones.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-023 | Partial edit mode warning banner | Open booked/paid invoice → Edit → warning banner visible | - [ ] |
| E2E-024 | Fields disabled, amounts locked | Partial edit → building/supplier disabled, lock toggle disabled | - [ ] |
| E2E-025 | Edit allowed fields and submit | Modify description/due date → submit → PUT 2xx, drawer closes | - [ ] |

### Validation Errors ([validation-errors.md](./validation-errors.md))

**Purpose**: Validate client-side guards that prevent invalid invoices from being submitted to the backend.
**Scope**: Required field validation, cost account requirement (syndic), date bounds enforcement, payment account requirement for `pay_now`.
**Risk**: Invalid invoices submitted causing 4xx errors, users confused by server-side errors that should have been caught client-side.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-026 | Submit empty form shows errors | Open form → submit empty → red error indicators appear, no POST | - [ ] |
| E2E-027 | Submit without cost account | Fill amount but no ledger → submit → cost account error shown | - [ ] |
| E2E-028 | Date outside allowed bounds | Open date picker → dates before Jan 1 or after today disabled | - [ ] |
| E2E-029 | Payment method without accounts | Fill everything except payment accounts → submit → payment error | - [ ] |

### Peppol to Invoice — Full Flow ([peppol-to-invoice.md](./peppol-to-invoice.md))

**Purpose**: Validate the complete Peppol-to-purchase-invoice user journey. Highest-priority E2E group — Peppol processing is the most-used daily flow. The basic Peppol tests above cover the happy path; these cover the full breadth including edge cases.
**Scope**: Inbox navigation, detail sheet content, duplicate detection, full form pre-fill, credit note handling, unmatched supplier workflow, amount grouping, submission with `peppolInvoiceId`, post-processing state, reject flow with broadcast email.
**Risk**: Inbox fails to load, duplicate invoices processed without warning, unmatched suppliers assigned wrong contact, credit notes processed as invoices, reject flow broken, processed invoices not linked back to Peppol source.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| E2E-030 | Peppol inbox loads with pending invoices | Navigate to `/financial/invoices/peppol` → table shows rows + seeded invoice | - [ ] |
| E2E-031 | Peppol detail sheet shows info | Click row → sheet shows number, supplier, amount, status, action buttons | - [ ] |
| E2E-032 | Duplicate warning before form | Open Peppol with matching purchase invoice → warning banner + match score | - [ ] |
| E2E-033 | Review & Save pre-fills form | Click "Review & Save" → drawer with all fields pre-filled + amounts locked | - [ ] |
| E2E-034 | Peppol credit note mode | Open credit note Peppol → form shows credit note badge, typeCode 381 | - [ ] |
| E2E-035 | Unmatched supplier allows manual select | Open unmatched Peppol → empty sender, user searches and selects contact | - [ ] |
| E2E-036 | Grouping preserves lock total | Switch individual → group by VAT → fewer rows, same total | - [ ] |
| E2E-037 | Submit sends peppolInvoiceId | Submit form → POST body contains `peppolInvoiceId` → 2xx, drawer closes | - [ ] |
| E2E-038 | Processed Peppol shows linked invoice | Re-open processed → linked invoice section, no "Review" button | - [ ] |
| E2E-039 | Reject with reason and email | Click Reject → fill reason → confirm → PATCH 2xx, optional broadcast | - [ ] |
