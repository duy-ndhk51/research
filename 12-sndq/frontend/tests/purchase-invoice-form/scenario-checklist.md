# Purchase Invoice V3 — Test Scenario Checklist

Grouped by feature area. Each checkbox tracks implementation status.

---

## Integration Tests (Vitest + Testing Library)

### Form Initialization & Conditional Rendering

**Purpose**: Guard the building + supplier prerequisite gate that controls which form sections are visible. The form body renders differently based on selection state, partial edit mode, and AI extraction status.

**Scope**: Placeholder rendering, section visibility toggles, disabled fieldsets in partial edit, AI overlay presence.

**Risk without coverage**: Form shows payment/amount fields before supplier is selected, leading to validation errors and confused users. Partial edit mode could expose editable fields on booked invoices.

- [ ] Placeholder shown when no building/supplier selected
- [ ] Full form visible when building + supplier selected
- [ ] Partial edit mode warning banner with disabled fieldsets
- [ ] AI extraction overlay shown during extraction

### Lock State & Amount Totals

**Purpose**: Guard the lock state machine that controls whether invoice amounts can be edited. Lock state transitions affect form editability for Peppol imports and partial edits.

**Scope**: Initial state derivation, toggle transitions (lock/unlock), computed `lockedTotal`, partial edit guard, Peppol auto-lock.

**Risk without coverage**: Amounts get unlocked on booked invoices (accounting inconsistency), or locked at zero from empty Peppol data (unusable form).

- [ ] Default lock state is unlocked (no peppol, no partial edit)
- [ ] Auto-locks when peppolInvoiceId present with initial amounts
- [ ] Toggle unlocked → locked computes lockedTotal from amounts
- [ ] Toggle locked → unlocked clears lockedTotal
- [ ] Toggle is no-op in partial edit mode

### Mode Switching (Invoice / Credit Note / Expense Note)

**Purpose**: Guard the type code mapping between UI mode and `invoiceTypeCode` form value. The backend uses this code to determine invoice processing behavior.

**Scope**: `MODE_TO_TYPE_CODE` mapping consistency, default values per mode, round-trip switching.

**Risk without coverage**: Credit notes submitted as regular invoices (wrong `invoiceTypeCode`), or expense notes processed with invoice logic. Backend rejects or misclassifies the document.

- [ ] Default mode is invoice with no invoiceTypeCode
- [ ] Credit note defaults include CREDIT_NOTE type code
- [ ] Switch to credit_note maps to type code `'381'`
- [ ] Switch to expense_note maps to EXPENSE_NOTE type code
- [ ] Switch back to invoice clears type code to undefined

### Right Panel Tabs

**Purpose**: Guard the tab defaulting logic that determines whether users see the file uploader or Peppol attachments first. The condition uses `hasPeppolData` (not `hasAttachments`) — the tab appears whenever Peppol data exists, with content varying based on whether attachment files are present.

**Scope**: Tab selection priority (user override > Peppol default > uploader fallback), content switching (PeppolAttachmentsTab vs PeppolParsedPreview), hideInlineAttachments, lock trigger on Peppol parse.

**Risk without coverage**: Users see empty uploader instead of Peppol data. PeppolParsedPreview rendered in both uploader and attachments tabs (duplicate). Tab disappears when it should still show parsed data.

- [ ] Default tab is uploader when no peppol data
- [ ] Peppol data without attachment files → tab shows PeppolParsedPreview
- [ ] Peppol data cleared → extra tab removed, falls back to uploader
- [ ] Peppol data with attachment files → tab shows PeppolAttachmentsTab
- [ ] User tab selection overrides peppol default
- [ ] hideInlineAttachments is true when peppolData exists (regardless of attachments)
- [ ] Peppol data parsed with amounts triggers lock state
- [ ] Peppol data with no amounts does not trigger lock

### Invoice Number & Date Fields

**Purpose**: Guard auto-number generation format, date bounds enforcement, and AI confidence indicator lifecycle. These fields have complex interactions between auto-generation, manual editing, and AI extraction.

**Scope**: Locale-aware number prefixes (`INV`/`AF`/`CN`), toggle on/off behavior, `markFieldReviewed` reset, date formatting for API, bounds validation.

**Risk without coverage**: Invoice numbers in wrong format per locale, dates outside legal fiscal year bounds, AI indicators stuck after manual edit.

- [ ] Auto-generate invoice number matches `INV-{YEAR}-{NNN}` format
- [ ] Toggle off clears invoice number to empty string
- [ ] Manual edit resets auto-generated state and clears AI confidence
- [ ] Date picker change formats date for API and validates
- [ ] Invoice date bounds enforced (Jan 1 to today)
- [ ] AI confidence indicators visible only when confidence defined

### Peppol to Invoice — Data Wiring

**Purpose**: Verify the wiring between `transformPeppolToFormData` output and React Hook Form `setValue` calls. The transform utility is unit-tested, but these tests cover the last mile where data actually reaches the form fields. This is the highest-priority integration group because Peppol is the #1 daily user flow.

**Scope**: Full field population via `handlePeppolDataParsed`, supplier matching/unmatching branching, credit note type propagation, Belgian structured communication (OGM) parsing, lock total computation from amounts, amount grouping with `originalLines` preservation.

**Risk without coverage**: Peppol invoices open with empty or wrong fields, unmatched suppliers silently get a stale senderId, credit notes treated as invoices, OGM references lost, lock total miscalculated, grouped amounts lose original line detail.

- [ ] `handlePeppolDataParsed` populates all form fields via `setValue`
- [ ] Empty Peppol amounts produce zero lock total (known edge case)
- [ ] Unmatched supplier resets senderId and stores supplier data
- [ ] Matched supplier sets senderId and clears supplier data
- [ ] Peppol credit note typeCode `'381'` flows to invoiceTypeCode
- [ ] Belgian OGM `+++123/4567/89002+++` parsed to digits, typed STRUCTURED
- [ ] Lock total matches `sumTotalAmounts` of transformed Peppol amounts
- [ ] Grouping strategy change preserves originalLines and lock total

### Invoice Lines Table — Orchestration

**Purpose**: Guard the `InvoiceLinesTableV3` orchestration component that wires form context, CRUD state, grouping mode, and conditional rendering together. Sub-hooks are unit-tested; these verify the composed behavior in the rendered component.

**Scope**: Add line button disabled state, individual vs simple mode rendering, mode toggle wiring, single delete dialog, duplicate, distribution sheet open/close, VAT rate change preserving totalAmount, footer totals + lock + credit note styling, `defaultOpen` on new vs edit, `isDeferredCost` flag.

**Risk without coverage**: Add line possible without building, wrong view mode rendered, delete dialog not wired, distribution sheet doesn't open from line, footer shows wrong totals or lock state, first card collapsed on new invoice (bad UX).

- [ ] Add line button disabled when no building selected
- [ ] Add line button enabled when building set
- [ ] Individual mode renders InvoiceLineCard per amount
- [ ] Simple mode renders SingleTotalView, hides cards and add button
- [ ] Mode toggle calls setGroupingStrategy
- [ ] Delete button opens DeleteAmountDialog; confirm removes, cancel keeps
- [ ] Duplicate calls pipeline DUPLICATE_LINE
- [ ] Custom distribution opens sheet for correct line index
- [ ] Footer shows VAT breakdown and computed total
- [ ] Lock state reflected in footer (icon, lockedTotal, disabled in partial edit)
- [ ] Credit note mode applies warning color to total
- [ ] First card defaultOpen on new invoice, collapsed on edit
- [ ] isDeferredCost disables distribution controls
- [ ] Changing VAT rate recalculates subtotal but keeps totalAmount unchanged
- [ ] Toggling VAT off sets subtotal equal to totalAmount

### Amount Distribution Sheet

**Purpose**: Guard the distribution sheet UI: unit initialization, distribution type switching (share/percentage/free/split_later/distribution_key), share/amount recalculation, ledger and distribution key suggestions, and validation.

**Scope**: Sheet open/close, loading states, edit mode pre-fill, all 5 distribution types, whole building toggle, individual/bulk selection, amount redistribution, suggestion chips, total mismatch dialog, search/sort.

**Risk without coverage**: Units not initialized, distribution type switch corrupts amounts, distribution key mode doesn't force whole building, amount mismatch undetected, suggestions don't populate fields.

- [ ] Loading state shows spinner when properties pending
- [ ] Properties loaded initializes units with zero amounts
- [ ] Edit mode pre-fills form from editingItem
- [ ] Share distribution type sets DEFAULT_SHARE and recalculates
- [ ] Percentage distribution type sets PERCENTAGE_BASE_VALUE
- [ ] Free distribution type enables per-unit amount inputs
- [ ] Split later clears all unit allocations
- [ ] Distribution key mode forces wholeBuilding + applies key shares
- [ ] Changing distribution key recalculates shares from new key
- [ ] Whole building toggle: ON selects all, OFF deselects and zeros
- [ ] Individual unit deselect zeros its share and amount
- [ ] Select all checkbox toggles all units
- [ ] Changing totalAmount recalculates amounts for non-free types
- [ ] Ledger suggestion chip click sets costAccount
- [ ] Distribution key suggestion chip switches to distribution key mode and applies key
- [ ] Total mismatch triggers SplitErrorDialog
- [ ] Unit search filters by name, address, and owner
- [ ] Unit sort reorders by name, owner, or amount

### Supplier Defaults — Backfill & Auto-save

**Purpose**: Guard the integration between supplier default hooks and the form. `useBackfillSupplierDefaults` patches empty lines when defaults load; `useAutoSaveBuildingSupplierDefaults` persists settings on submit. Unit tests cover internal logic — these test form-level wiring.

**Scope**: Backfill triggers, "never overwrite" policy, idempotency via ref guard, auto-save create vs update link, skip when all fields set.

**Risk without coverage**: Defaults silently overwrite user values, backfill fires multiple times, auto-save creates duplicate links, settings lost on submit.

- [ ] Backfill sets costAccount on empty lines when supplier selected
- [ ] Backfill sets distributionKeyId on empty lines
- [ ] Existing costAccount NOT overwritten by backfill
- [ ] Existing distributionKeyId NOT overwritten by backfill
- [ ] Changing supplier triggers backfill for new pair
- [ ] Same supplier re-selected does NOT re-trigger backfill
- [ ] Submit calls saveSupplierDefaults with line settings
- [ ] Submit with no link creates new building-supplier link
- [ ] Submit with existing link updates only empty fields
- [ ] Submit with fully configured link fires no mutation

---

## E2E Tests (Playwright)

### Create Invoice

**Purpose**: Validate the complete happy path for creating a new purchase invoice from the list page. This is the foundational flow that all other flows build on.

**Scope**: Navigation to list, drawer opening, building/supplier selection, amount entry with ledger, form submission, list verification.

**Risk without coverage**: Users can't create invoices at all. Any regression in the create path blocks the entire invoicing workflow.

- [ ] Open create form from purchase invoice list
- [ ] Select building + supplier reveals payment and amount sections
- [ ] Fill amount line with ledger and verify total footer
- [ ] Submit invoice with all required fields (POST 2xx)
- [ ] Created invoice appears in list with correct data

### Edit Invoice

**Purpose**: Validate data persistence and modification of existing invoices. Ensures saved data loads correctly and changes are properly submitted.

**Scope**: Detail sheet → edit transition, data pre-fill verification, amount modification, supplier change side effects, discard confirmation dialog.

**Risk without coverage**: Edits silently lost, wrong data saved, supplier change doesn't update dependent fields, users can discard without confirmation.

- [ ] Open existing invoice and verify pre-filled data
- [ ] Modify amount and submit (PUT 2xx)
- [ ] Change supplier and verify dependent fields update
- [ ] Discard changes shows confirmation dialog

### Credit Note

**Purpose**: Validate the mode switching flow end-to-end, ensuring the correct `invoiceTypeCode` reaches the backend and the UI reflects credit note state.

**Scope**: Mode toggle interaction, credit note header display, form submission with type code `'381'`, list type badge.

**Risk without coverage**: Credit notes rejected by backend due to wrong type code, or created as regular invoices causing accounting errors.

- [ ] Switch mode to credit note in create form
- [ ] Fill and submit credit note with correct type code
- [ ] Credit note appears in list with type badge

### Peppol Import — Basics

**Purpose**: Validate the basic Peppol-to-form handoff: pre-fill, attachments tab content, lock, and submission. The "Peppol Attachments" tab appears whenever `peppolData` exists — showing `PeppolAttachmentsTab` with files or `PeppolParsedPreview` without.

**Scope**: Form data pre-fill from Peppol XML, attachment tab defaulting and content switching, upload zone fallback, amount lock application, `peppolInvoiceId` in POST payload.

**Risk without coverage**: Pre-fill broken (empty fields), PeppolParsedPreview not shown when no attachments, duplicate parsed preview in uploader tab, amounts editable when they should be locked, Peppol link lost on submission.

- [ ] Peppol pre-fills form data from detail sheet
- [ ] Peppol with attachment files → tab shows file list
- [ ] Peppol without attachment files → tab shows PeppolParsedPreview
- [ ] Peppol present → uploader tab shows upload zone (not parsed preview)
- [ ] Peppol amounts locked after form opens
- [ ] Submit Peppol invoice with peppolInvoiceId

### Draft Lifecycle

**Purpose**: Validate the save/resume cycle for incomplete invoices. Drafts allow users to partially fill invoices and return later.

**Scope**: Draft save via combo actions, data persistence across sessions, draft completion and status transition.

**Risk without coverage**: Draft data lost on resume, status stuck as draft after submission, partial data not persisted.

- [ ] Save as draft via combo actions (POST 2xx, draft badge)
- [ ] Resume draft preserves building, supplier, and amounts
- [ ] Complete draft and submit (PUT 2xx, status changes)

### AI Extraction

**Purpose**: Validate the PDF upload → AI extraction → field population pipeline. Extraction is async and has complex state transitions (uploading → extracting → extracted → reviewed).

**Scope**: Upload trigger, extraction banner lifecycle, field population, confidence indicator display and dismissal.

**Risk without coverage**: Extraction banner stuck indefinitely, fields not populated after extraction completes, confidence indicators persist after manual edit.

- [ ] Upload PDF triggers extraction banner
- [ ] Extraction populates invoice number + date with AI indicators
- [ ] Review extracted field clears confidence indicator

### Partial Edit Mode

**Purpose**: Validate restricted editing on booked or partially-paid invoices. Certain fields must be locked to maintain accounting integrity.

**Scope**: Warning banner visibility, field disabling (building, supplier, amounts), lock toggle restriction, allowed field editing (description, due date).

**Risk without coverage**: Users modify locked fields on booked invoices, causing accounting inconsistency. Or all fields locked including the ones that should remain editable.

- [ ] Partial edit mode warning banner visible on booked/paid invoice
- [ ] Building/supplier fields disabled and amounts locked in partial edit
- [ ] Edit allowed fields (description, due date) and submit in partial edit

### Validation Errors

**Purpose**: Validate client-side guards that prevent invalid invoices from being submitted. These tests ensure the form catches errors before hitting the backend.

**Scope**: Required field validation (empty form), cost account requirement (syndic variant), date bounds enforcement, payment account requirement for `pay_now` method.

**Risk without coverage**: Invalid invoices submitted to backend causing 4xx errors, users confused by server-side errors that should have been caught client-side.

- [ ] Submit empty form shows required field errors (no POST)
- [ ] Submit without cost account shows ledger field error
- [ ] Date picker restricts out-of-bounds dates
- [ ] Pay now without payment accounts shows payment section error

### Peppol to Invoice — Full Flow

**Purpose**: Validate the complete Peppol-to-purchase-invoice user journey from inbox to submission/rejection. This is the highest-priority E2E group because Peppol processing is the most-used daily flow. The basic Peppol tests (above) cover the happy path; these cover the full breadth including edge cases.

**Scope**: Inbox navigation and loading, detail sheet content verification, duplicate invoice detection, form pre-fill with all field types, credit note handling, unmatched supplier workflow, amount grouping, `peppolInvoiceId` submission, post-processing state, reject flow with broadcast email.

**Risk without coverage**: Inbox fails to load at correct URL, duplicate invoices processed without warning, unmatched suppliers silently assigned wrong contact, credit notes processed as invoices, reject flow broken or email not sent, processed invoices not linked back to Peppol source.

- [ ] Peppol inbox loads with pending invoices at correct URL
- [ ] Peppol detail sheet shows invoice number, supplier, amount, status, actions
- [ ] Duplicate warning banner shown when matching purchase invoice exists
- [ ] "Review & Save" opens form with all fields pre-filled and amounts locked
- [ ] Peppol credit note opens form in credit note mode
- [ ] Unmatched supplier shows supplier info, allows manual contact selection
- [ ] Grouping strategy change preserves lock total
- [ ] Submit sends `peppolInvoiceId` in POST body (2xx, drawer closes)
- [ ] Processed Peppol shows linked purchase invoice, no "Review" button
- [ ] Reject flow with reason code, optional note, optional email broadcast

### Amount Distribution

**Purpose**: Validate the full user journey through the distribution sheet: opening from invoice lines, unit allocation, distribution types, suggestions, and persistence.

**Scope**: Sheet open/close, partial/full unit selection, share/percentage/distribution key distribution, ledger suggestions, save/close, edit pre-fill.

**Risk without coverage**: Sheet doesn't open, amounts miscalculated on type switch, allocations lost on save, edit mode doesn't restore state.

- [ ] Add amount line opens distribution sheet with all building units
- [ ] Partial unit selection reflected in allocation progress
- [ ] Share mode distributes total across selected units
- [ ] Switch to percentage mode recalculates shares
- [ ] Apply distribution key with correct ratios
- [ ] Ledger suggestion chip populates cost account
- [ ] Save & close persists line to parent form
- [ ] Edit existing line opens with saved allocations

### Supplier Defaults — Auto-fill & Auto-save

**Purpose**: Validate end-to-end flow of supplier defaults being backfilled on selection and auto-saved to the building-supplier link on submit.

**Scope**: Cost account/distribution key backfill, "never overwrite" policy, link creation, link update.

**Risk without coverage**: Defaults don't populate (silent failure), user values overwritten, link not created/updated after submit.

- [ ] Supplier with defaults auto-fills cost account on line
- [ ] Supplier with defaults auto-fills distribution key on line
- [ ] Manual cost account NOT overwritten by supplier defaults
- [ ] Submit with new supplier creates building-supplier link
- [ ] Submit with existing supplier updates empty defaults only
