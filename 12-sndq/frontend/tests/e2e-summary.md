# E2E Tests — Purchase Invoice V3

**Runner**: Playwright (real browser against dev server / staging)
**Location**: `sndq-fe/tests/financial/purchase-invoices/`

## What this covers

- Full user journeys in a real browser with real API responses
- Routing, navigation, URL correctness
- Auth and session handling
- Form submission (POST/PUT/PATCH/DELETE) with response verification
- Drawer open/close lifecycle
- Seed data correctness (pre-filled values match backend state)
- Peppol inbox → detail → form → submit → post-processing flow
- Client-side validation blocking bad submissions
- Amount distribution sheet: unit allocation, distribution types, ledger suggestions
- Supplier defaults: auto-fill on selection, auto-save on submit, "never overwrite" policy

## What this does NOT cover

- State permutation testing (too slow — 1 test = 10-30s)
- Edge cases requiring special seed data (e.g., OGM parsing, empty Peppol amounts)
- Pure logic assertions (type code mappings, date bounds computation)
- Offline or network failure scenarios
- Cross-browser testing (single browser per run)

---

## 1. Create Invoice

Happy path for creating a new purchase invoice from the list page. Foundation flow that all other flows build on.

**Seed**: `purchase-invoice-create`

| Test case | Description | Status |
|-----------|-------------|--------|
| Navigate to list → click "Add invoice" → drawer opens with fields visible | Create form accessible from list page | - [ ] |
| Select building + supplier → placeholder gone, payment + amount sections appear | Prerequisites gate works in real browser | - [ ] |
| Fill invoice number + amount + cost account → total footer shows `€100,00` | Amount calculation and display correct | - [ ] |
| Fill all required fields → submit → POST 2xx → drawer closes | Full create happy path succeeds | - [ ] |
| After submit → list page shows new invoice number + supplier name | Created data persists and displays in list | - [ ] |

## 2. Edit Invoice

Data persistence and modification of existing invoices.

**Seed**: `purchase-invoice-edit`

| Test case | Description | Status |
|-----------|-------------|--------|
| Click row → detail sheet → Actions → Edit → drawer shows pre-filled data (`TEST-2026-001`) | Saved data loads correctly into edit form | - [ ] |
| Change amount to 200 → submit → PUT 2xx → drawer closes | Edit persists via PUT request | - [ ] |
| Open supplier select → choose different supplier → field updates | Supplier change updates dependent fields | - [ ] |
| Modify field → click back → discard confirmation dialog → cancel returns to form | Unsaved changes prompt before leaving | - [ ] |

## 3. Credit Note

Mode switching flow end-to-end with correct `invoiceTypeCode` reaching the backend.

**Seed**: `purchase-invoice-create`

| Test case | Description | Status |
|-----------|-------------|--------|
| Open create form → mode toggle → select "Credit note" → header updates | Mode switch UI reflects credit note state | - [ ] |
| Credit note mode → fill fields → submit → POST with `invoiceTypeCode: '381'` → 2xx | Correct type code reaches backend | - [ ] |
| After submit → list shows credit note number + type badge | Credit note distinguishable in list view | - [ ] |

## 4. Peppol Import — Basics

Basic Peppol-to-form handoff: pre-fill, attachments tab, lock, and submission. The "Peppol Attachments" tab appears whenever `peppolData` exists — showing `PeppolAttachmentsTab` when PDF/XML files are present, or `PeppolParsedPreview` when there are none.

**Seed**: `purchase-invoice-peppol`, `purchase-invoice-peppol-no-attachments`

| Test case | Description | Status |
|-----------|-------------|--------|
| Navigate to Peppol → select invoice → form opens with pre-filled fields | Peppol data populates form in real browser | - [ ] |
| Peppol with attachment files → right panel shows "Peppol attachments" tab with file list | Users see Peppol attachment files first on import | - [ ] |
| Peppol without attachment files → "Peppol attachments" tab shows PeppolParsedPreview | Structured Peppol data visible in attachments tab when no PDF/XML files | - [ ] |
| Peppol present → "Invoice preview" tab shows upload zone (not PeppolParsedPreview) | Upload zone fallback when hideInlineAttachments is true | - [ ] |
| Lock indicator visible, total matches Peppol data | Amounts protected from accidental edits | - [ ] |
| Fill remaining fields → submit → POST with `peppolInvoiceId` → 2xx | Peppol link preserved in submission payload | - [ ] |

## 5. Draft Lifecycle

Save/resume cycle for incomplete invoices.

**Seed**: `purchase-invoice-create` (new draft), `purchase-invoice-draft` (resume)

| Test case | Description | Status |
|-----------|-------------|--------|
| Fill partial data → combo actions → "Save as draft" → POST 2xx, draft badge in list | Incomplete invoices can be saved for later | - [ ] |
| Find draft → Actions → Edit → building, supplier, amount preserved | Draft data persists across sessions | - [ ] |
| Fill remaining fields → submit → PUT 2xx, status changes from draft | Draft completes and transitions to submitted | - [ ] |

## 6. AI Extraction

PDF upload → AI extraction → field population pipeline.

**Seed**: `purchase-invoice-create`

| Test case | Description | Status |
|-----------|-------------|--------|
| Upload PDF in right panel → "Extracting..." banner appears | Upload triggers AI pipeline with loading state | - [ ] |
| Wait for extraction → invoice number + date populated, AI confidence indicators visible | Extracted data reaches form fields correctly | - [ ] |
| Click + edit extracted field → confidence indicator disappears | Manual review clears AI suggestion state | - [ ] |

## 7. Partial Edit Mode

Restricted editing on booked or partially-paid invoices.

**Seed**: `purchase-invoice-partial-edit`

| Test case | Description | Status |
|-----------|-------------|--------|
| Open booked/paid invoice → Edit → warning banner visible | User warned about restricted editing | - [ ] |
| Building/supplier in disabled fieldset, lock toggle disabled | Accounting-critical fields locked after booking | - [ ] |
| Edit description/due date → submit → PUT/PATCH 2xx → drawer closes | Allowed fields still editable and saveable | - [ ] |

## 8. Validation Errors

Client-side guards preventing invalid submissions.

**Seed**: `purchase-invoice-create`

| Test case | Description | Status |
|-----------|-------------|--------|
| Submit empty form → error indicators appear, no POST fired | Client-side blocks invalid submission | - [ ] |
| Amount filled but no cost account → cost account error shown | Ledger required for syndic accounting | - [ ] |
| Date picker → dates before Jan 1 or after today are disabled | Fiscal year bounds enforced in UI | - [ ] |
| Pay now without payment accounts → payment section error | Payment accounts required for immediate payment | - [ ] |

## 9. Peppol to Invoice — Full Flow

Complete Peppol-to-purchase-invoice journey from inbox to submission/rejection. Highest-priority E2E group — covers edge cases beyond basic Peppol tests.

**Seeds**: `peppol-invoice-matched`, `peppol-invoice-unmatched`, `peppol-invoice-credit-note`, `peppol-invoice-duplicate`

| Test case | Description | Status |
|-----------|-------------|--------|
| Navigate to `/financial/invoices/peppol` → table shows rows + seeded invoice | Inbox loads at correct route with data | - [ ] |
| Click row → sheet shows invoice number, supplier, amount, status, action buttons | Detail sheet renders all key info | - [ ] |
| Peppol with matching purchase invoice → duplicate warning banner + match score visible | Prevents accidental double-processing | - [ ] |
| Click "Review & Save" → drawer with all fields pre-filled + amounts locked | Full pre-fill and lock work end-to-end | - [ ] |
| Credit note Peppol → form shows credit note badge, typeCode `'381'` | Credit note type propagates from Peppol XML | - [ ] |
| Unmatched supplier → empty sender field, user searches and selects contact manually | Unknown suppliers don't block the flow | - [ ] |
| Switch individual→group by VAT → fewer rows, same locked total | Regrouping doesn't alter locked amounts | - [ ] |
| Submit → POST body contains `peppolInvoiceId` → 2xx, drawer closes | Peppol link preserved through submission | - [ ] |
| Re-open processed Peppol → linked invoice section, no "Review & Save" button | Processed state prevents re-processing | - [ ] |
| Click Reject → fill reason + optional note → PATCH 2xx → optional email broadcast | Reject flow with optional supplier notification | - [ ] |

## 10. Amount Distribution

Full user journey for the distribution sheet: opening from invoice lines, selecting units, allocating amounts across distribution types, and verifying persistence back to the parent form.

**Seed**: `purchase-invoice-create` (building with multiple units)

| Test case | Description | Status |
|-----------|-------------|--------|
| Add amount line → distribution sheet opens with all building units listed | Sheet accessible from invoice lines section | - [ ] |
| Select 3 of 5 units → allocation progress shows partial, unselected units zeroed | Partial selection reflected in progress indicator | - [ ] |
| Set total amount 500 EUR → "Share" mode distributes across selected units | Proportional distribution computed and displayed | - [ ] |
| Switch to "Percentage" → shares convert to percentages summing to 100% | Mode switch recalculates display values | - [ ] |
| Apply distribution key from dropdown → amounts match key ratios | DK-based distribution produces correct per-unit amounts | - [ ] |
| Click ledger suggestion chip → cost account field populated | Suggestion shortcut works in real browser | - [ ] |
| Save & close → line appears in invoice with correct total | Distribution data persists back to parent form | - [ ] |
| Edit existing line → sheet opens with saved allocations pre-filled | Re-opening sheet restores prior distribution state | - [ ] |

## 11. Supplier Defaults — Auto-fill & Auto-save

End-to-end flow of supplier defaults being backfilled into invoice lines on supplier selection and auto-saved to the building-supplier link on successful submit.

**Seeds**: `purchase-invoice-supplier-defaults` (supplier with pre-configured ledger + DK), `purchase-invoice-create` (supplier without defaults)

| Test case | Description | Status |
|-----------|-------------|--------|
| Select supplier with defaults → first line's cost account auto-fills | Backfill populates empty ledger from supplier config | - [ ] |
| Select supplier with defaults → first line's distribution key auto-fills | Backfill populates empty DK from supplier config | - [ ] |
| Manually set cost account, then select supplier with defaults → account NOT overwritten | User-set values preserved despite supplier defaults | - [ ] |
| Submit invoice (new supplier) → supplier link created in backend | POST to building-supplier API after successful invoice submit | - [ ] |
| Submit invoice (existing supplier, empty defaults) → supplier defaults updated | PATCH updates only empty fields on existing supplier link | - [ ] |
