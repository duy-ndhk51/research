# Steward V3 — Feature Sync Commit Playbook

Step-by-step commits to port syndic V3 features into the steward V3 form. Each batch is independently deployable and testable. Execute one batch at a time; test before moving to the next.

Companion doc: [feature-sync-roadmap.md](./feature-sync-roadmap.md) (full feature descriptions and risk analysis).

---

## Batch 1 — Layout + drop-in features

Zero to low risk. All four commits are independent — do in any order.

### Commit 1A · Align form shell layout with syndic V3

**Roadmap**: #0 (Tier 0) · **Risk**: Zero

**What**: CSS-only alignment of the form shell.

**File**: `purchase-invoice-v3-steward/PurchaseInvoiceFormV3Steward.tsx`

**Changes**:
- `<form>` className: add `overflow-hidden rounded-t-2xl`
- Left `<ResizablePanel>`: add `bg-neutral-0` alongside existing `border-r`
- Move `<FormDialogs>` to be a sibling of `<form>` inside `FormProvider` (matching syndic nesting)

**Reference**: `purchase-invoice-v3/PurchaseInvoiceFormV3.tsx` lines 80–140

**Test checklist**:
- [ ] Open **create** steward invoice — form has rounded top corners and white background on left panel
- [ ] Open **edit** steward invoice — same visual
- [ ] Open syndic V3 create form side-by-side — layout matches (rounded corners, panel backgrounds, dialog nesting)
- [ ] Resize panels — drag handle still works, no layout glitches
- [ ] Full-page route (no `onClose`) — `fixed inset-0` still covers viewport correctly
- [ ] Embedded route (with `onClose`) — form fills container without overflow
- [ ] Discard dialog still opens and closes correctly (nesting change)
- [ ] Delete dialog still opens and closes correctly
- [ ] `pnpm test` — existing tests pass (no logic change)

---

### Commit 1B · Add duplicate invoice warning

**Roadmap**: #1 (Tier 1) · **Risk**: None

**What**: Add the existing `DuplicateWarningButton` to the steward header.

**File**: `purchase-invoice-v3-steward/sections/FormHeader.tsx`

**Changes**:
- Import `DuplicateWarningButton` from `purchase-invoice-v2/components/DuplicateWarningBanner`
- Add to header actions, wired to: `senderId`, `invoiceNumber`, `totalAmount`, `invoiceDate`, `invoiceId`
- Pass `buildingId={undefined}` (steward has no single building)

**Reference**: `purchase-invoice-v3/sections/FormHeader.tsx` — see how it places `DuplicateWarningButton`

**Test checklist**:
- [ ] Open create form — no warning initially (no supplier/number yet)
- [ ] Select a supplier and type an invoice number that **matches an existing invoice** — duplicate warning banner appears
- [ ] Change invoice number to a unique one — warning disappears
- [ ] Change supplier — warning recalculates
- [ ] Open **edit** form for an existing invoice — no false positive warning for its own invoice (verify `excludeInvoiceId` is passed)
- [ ] Warning does not appear when fields are empty
- [ ] Warning does not flash/flicker during typing (debounce works)
- [ ] `pnpm test` — existing tests pass

---

### Commit 1C · Add invoice date bounds

**Roadmap**: #2 (Tier 1) · **Risk**: Minimal

**What**: Restrict the invoice date picker to current year → today.

**File**: `purchase-invoice-v3-steward/sections/FormBody.tsx`

**Changes**:
- Import `getInvoiceDateBounds` from `purchase-invoice-v3/constants`
- Call it and pass `minDate` / `maxDate` to `InvoiceInfoSection`
- If `InvoiceInfoSection` doesn't accept these props, add them (check `purchase-invoice-v2/components/InvoiceInfoSection`)

**Reference**: `purchase-invoice-v3/sections/FormBody.tsx` — see how `getInvoiceDateBounds()` is used in `InvoiceFieldsSection`

**Test checklist**:
- [ ] Open create form — click date picker
- [ ] Try to select a date **before Jan 1 of current year** — should be disabled/blocked
- [ ] Try to select a date **after today** — should be disabled/blocked
- [ ] Select **today** — works
- [ ] Select **Jan 1 of current year** — works
- [ ] Select a date **in the middle of the year** — works
- [ ] Open **edit** form with an existing date within bounds — date displays correctly, can change within bounds
- [ ] Open **edit** form with a date from a previous year (legacy data) — verify behavior (date shows but may flag as out of bounds)
- [ ] `pnpm test` — existing tests pass

---

### Commit 1D · Add auto invoice number generation

**Roadmap**: #3 (Tier 1) · **Risk**: Low

**What**: Auto-generate invoice numbers with a toggle for manual override.

**Files**:
- `purchase-invoice-v3-steward/sections/FormBody.tsx` — add auto/manual toggle near invoice number field

**Changes**:
- Import `generateInvoiceNumber` from `purchase-invoice-v3/constants`
- Add auto-number toggle (matching syndic V3 behavior)
- On auto: populate on mount; on manual: clear and allow typing
- Verify prefix conventions — steward may need different prefixes than syndic

**Reference**: `purchase-invoice-v3/sections/FormBody.tsx` — `InvoiceFieldsSection` auto-number behavior

**Test checklist**:
- [ ] Open **create** form — invoice number is auto-generated (has expected prefix + year + digits)
- [ ] Verify prefix matches steward conventions (not syndic prefix)
- [ ] Toggle to **manual** — field clears and becomes editable
- [ ] Type a custom invoice number — accepted
- [ ] Toggle back to **auto** — number regenerates (new random digits)
- [ ] Submit with auto-generated number — API payload contains the number
- [ ] Submit with manual number — API payload contains the typed number
- [ ] Open **edit** form — existing invoice number shown, auto toggle is off (manual mode)
- [ ] Verify auto-generated number format: `{PREFIX}-{YEAR}-{3-digit-seq}`
- [ ] Open syndic V3 create form — compare auto-number format
- [ ] `pnpm test` — existing tests pass

---

## Batch 2 — Mode toggle + description

Medium risk. Two commits are independent of each other.

### Commit 2A · Add invoice mode toggle

**Roadmap**: #4 (Tier 2) · **Risk**: Medium

**What**: Toggle between invoice / credit note (and potentially expense note) in the header.

**Files**:
- `purchase-invoice-v3-steward/hooks/useStewardForm.ts` — add `mode` + `setMode` state, derived from `invoiceTypeCode`
- `purchase-invoice-v3-steward/sections/FormHeader.tsx` — add `InvoiceModeToggle`

**Changes**:
- Add `mode: InvoiceFormMode` state to hook, expose via context
- Check if `InvoiceModeToggle` reads from `usePurchaseInvoiceFormContext()` — if yes, either (a) refactor the toggle to accept props, or (b) alias the steward context to match the expected shape
- Wire `MODE_TO_TYPE_CODE` mapping so toggling updates `invoiceTypeCode`
- Verify `convertFormDataV2StewardToApiData` handles all type codes (it already handles credit notes — check expense notes)

**Reference**: `purchase-invoice-v3/sections/InvoiceModeToggle.tsx`

**Pre-check**: Verify the steward API/backend accepts expense note type codes.

**Test checklist**:
- [ ] Open create form — default mode is "Invoice"
- [ ] Toggle to **Credit Note** — header title updates, save button label changes
- [ ] Toggle back to **Invoice** — reverts
- [ ] In Credit Note mode — `isDirectDebit` is forced to `false`
- [ ] Submit as **Invoice** — API payload has correct `invoiceTypeCode`
- [ ] Submit as **Credit Note** — API payload has credit note `invoiceTypeCode`
- [ ] Open **edit** form for a credit note — mode toggle shows Credit Note selected
- [ ] Open **edit** form for a normal invoice — mode toggle shows Invoice selected
- [ ] If expense note is supported: toggle to Expense Note, verify type code and backend acceptance
- [ ] Save button shows **negative** total for credit notes (formatted as negative amount)
- [ ] `pnpm test` — existing tests pass, add unit test for mode ↔ typeCode mapping

---

### Commit 2B · Replace description with DescriptionSection

**Roadmap**: #5 (Tier 2) · **Risk**: Medium

**What**: Multi-language description tabs with auto-fill and translate.

**File**: `purchase-invoice-v3-steward/sections/FormBody.tsx`

**Changes**:
- Replace the basic description field (currently inside `InvoiceInfoSection`) with `DescriptionSection` from `purchase-invoice-v3/sections/DescriptionSection`
- Import `useDescriptionAutoFill` from V3 hooks
- Adapt `buildStandardDescription` — syndic uses building name; steward should use property names from `selectedProperties`
- Ensure `descriptionTranslations` field exists in steward schema (it does — check `purchaseInvoiceFormV2StewardSchema`)

**Reference**: `purchase-invoice-v3/sections/DescriptionSection.tsx` and `purchase-invoice-v3/sections/FormBody.tsx` (gating logic)

**Pre-check**: Verify steward schema has `descriptionTranslations` with the same shape as syndic.

**Test checklist**:
- [ ] Open create form with **no supplier or properties** selected — description section is hidden or shows placeholder
- [ ] Select supplier + at least one property — description section appears
- [ ] Verify **auto-fill** fires: description populated with property name(s) and supplier name
- [ ] Verify auto-fill uses **property names** (not building name like syndic)
- [ ] Switch to **NL** tab — description in NL
- [ ] Switch to **FR** tab — description in FR
- [ ] Click **Translate** button — translation API called, other languages populated
- [ ] **Manually edit** a description — auto-fill does not overwrite manual edits
- [ ] Add a **new language** tab — empty field appears
- [ ] Remove a language tab — field removed from form data
- [ ] Submit — API payload includes `descriptionTranslations` with all languages
- [ ] Open **edit** form with existing translations — all language tabs pre-filled
- [ ] Verify `MAX_INVOICE_DESCRIPTION_LENGTH` is enforced (character counter visible)
- [ ] `pnpm test` — existing tests + schema snapshot tests pass

---

## Batch 3 — Partial edit mode

Medium risk. Two commits, sequential (3A then 3B).

### Commit 3A · Add partial edit mode detection

**Roadmap**: #6 part 1 (Tier 2) · **Risk**: Low

**What**: Detect when an invoice is partially editable (e.g., has payments).

**Files**:
- `purchase-invoice-v3-steward/hooks/useStewardForm.ts` — add `isPartialEditMode` computation
- Context picks it up automatically (inherits hook return type)

**Changes**:
- Import `isInvoicePartiallyEditable` utility (check where it lives — likely shared or in V3)
- Accept `isPartialEditMode` as a prop on the form (passed from edit form) or compute from initial data
- Return it from the hook

**Reference**: `purchase-invoice-v3/PurchaseInvoiceFormV3.tsx` props — `isPartialEditMode` is a prop passed from the edit page

**Test checklist**:
- [ ] Open create form — `isPartialEditMode` is `false` (verify via React DevTools or `console.log`)
- [ ] Open edit form for invoice **without payments** — `isPartialEditMode` is `false`
- [ ] Open edit form for invoice **with payments** — `isPartialEditMode` is `true`
- [ ] Context value matches hook value (inspect via React DevTools)
- [ ] `pnpm test` — existing tests pass

---

### Commit 3B · Add partial edit UI

**Roadmap**: #6 part 2 (Tier 2) · **Risk**: Medium

**What**: Warning banner + field disabling when partially editing.

**File**: `purchase-invoice-v3-steward/sections/FormBody.tsx`

**Changes**:
- Read `isPartialEditMode` from context
- Add warning `Message` banner at top of form body when active
- Wrap amount and payment sections in `<fieldset disabled={isPartialEditMode}>`
- Steward-specific: also disable unit/property selection and settlement controls

**Reference**: `purchase-invoice-v3/sections/FormBody.tsx` — partial edit banner and `fieldset disabled` pattern

**Test checklist**:
- [ ] Open **create** form — no banner, all fields editable
- [ ] Open **edit** form for invoice **without payments** — no banner, all fields editable
- [ ] Open **edit** form for invoice **with payments** — warning banner visible at top
- [ ] Banner text is correct and translated
- [ ] **Disabled sections** (when partial edit):
  - [ ] Amount rows — cannot add/edit/remove
  - [ ] Payment section — all fields disabled
  - [ ] Property/unit selection — cannot change
  - [ ] Settlement controls — cannot change
- [ ] **Enabled sections** (when partial edit):
  - [ ] Invoice name — editable
  - [ ] Invoice date — editable
  - [ ] Description — editable
  - [ ] Supplier — editable (or disabled? — check syndic behavior)
- [ ] Submit with allowed field changes — save succeeds
- [ ] Visual: disabled fields appear greyed out, inputs are not focusable
- [ ] `pnpm test` — existing tests pass

---

## Batch 4 — AI document extraction

High risk. Two commits, sequential (4A then 4B).

### Commit 4A · Wire AiExtractionProvider + UI chrome

**Roadmap**: #7 part 1 (Tier 3) · **Risk**: Medium

**What**: Provider infrastructure + visual indicators (no field mapping yet).

**Files**:
- `purchase-invoice-v3-steward/PurchaseInvoiceFormV3Steward.tsx` — add `AiExtractionProvider` wrapper
- `purchase-invoice-v3-steward/sections/FormBody.tsx` — add `AiExtractionOverlay`
- Main form layout — add `AiExtractionBanner` after header

**Changes**:
- Wrap inner form with `AiExtractionProvider` (same position as syndic V3)
- Add overlay that covers form body during extraction
- Add banner showing extraction status
- Wire `isExtracting` / `isExtracted` from the AI extraction context

**Reference**:
- `purchase-invoice-v3/PurchaseInvoiceFormV3.tsx` — provider wrapping pattern
- `purchase-invoice-v2/contexts/AiExtractionContext.tsx` — provider definition
- `purchase-invoice-v3/sections/AiExtractionOverlay.tsx` — overlay component

**Test checklist**:
- [ ] Open create form — no banner or overlay initially
- [ ] Upload a **PDF** document — overlay appears, covering the form body
- [ ] Overlay shows a loading/spinner indicator
- [ ] Banner appears between header and panels, shows "extracting" status
- [ ] Wait for extraction to complete — overlay dismisses
- [ ] Banner updates to "extracted" or success state
- [ ] Dismiss banner — disappears
- [ ] Form fields are **NOT populated** yet (that's commit 4B)
- [ ] Upload a **Peppol XML** — existing Peppol prefill still works as before (no regression)
- [ ] Right panel document preview still works
- [ ] Resize panels during extraction — overlay covers correctly
- [ ] `pnpm test` — existing tests pass

---

### Commit 4B · Integrate useFileHandling + AI field mapping

**Roadmap**: #7 part 2 (Tier 3) · **Risk**: High

**What**: Replace manual file/peppol wiring with `useFileHandling` and map extracted fields.

**Files**:
- `purchase-invoice-v3-steward/hooks/useStewardForm.ts` — integrate `useFileHandling`
- `purchase-invoice-v3-steward/PurchaseInvoiceFormV3Steward.tsx` — simplify right panel wiring

**Changes**:
- Import and compose `useFileHandling` (from V3 or shared hooks)
- Map AI-extracted fields to steward form: supplier, dates, invoice number, description
- For amounts: AI won't extract `costCategoryId` — leave as empty/unset
- Add confidence indicators on AI-filled fields (via `AiExtractionProvider` context)
- Preserve existing Peppol XML prefill as a parallel path

**Key challenge**: AI extraction maps to syndic schema shape. Steward amounts need `costCategoryId` which AI doesn't extract. Consider a "review required" marker on cost category after extraction.

**Test checklist**:
- [ ] Upload a **PDF** invoice — extraction runs
- [ ] After extraction, verify **populated fields**:
  - [ ] Supplier — matched and selected
  - [ ] Invoice date — filled
  - [ ] Invoice number — filled
  - [ ] Description — filled (if extractable)
  - [ ] Due date — filled (if extractable)
- [ ] After extraction, verify **amount rows** created:
  - [ ] Amounts appear with extracted totals/VAT
  - [ ] `costCategoryId` is **empty** (not auto-filled)
  - [ ] Visual indicator that cost category needs review (if implemented)
- [ ] Upload a **Peppol XML** — existing prefill flow works as before
  - [ ] Supplier, dates, invoice number populated from Peppol data
  - [ ] Amounts created with correct totals
- [ ] Upload a new PDF **over** an already-extracted form — fields update to new extraction
- [ ] Confidence indicators visible on AI-filled fields (highlight or icon)
- [ ] Manually edit an AI-filled field — confidence indicator clears
- [ ] Submit extracted form (after setting cost categories) — API payload is correct
- [ ] Submit Peppol-prefilled form — API payload matches previous behavior
- [ ] Right panel preview shows the uploaded document
- [ ] `pnpm test` — existing tests pass, schema snapshot tests unchanged

---

## Batch 5 — Inline invoice lines table

Largest effort. Four sequential commits. Consider building in a parallel directory (`invoice-lines-steward/`) and swapping in at 5C.

### Commit 5A · Scaffold steward invoice lines (types + defaults + reducer)

**Roadmap**: #8 part 1 (Tier 3) · **Risk**: Medium

**What**: Adapted data layer for steward invoice lines.

**New directory**: `purchase-invoice-v3-steward/components/invoice-lines-steward/`

**Changes**:
- Copy from syndic `purchase-invoice-v3/components/invoice-lines/`:
  - `types.ts` — replace `motherId` with `costCategoryId`, add `units[]` and settlement fields
  - `amountDefaults.ts` — default line includes `costCategoryId: undefined`, `units: []`, settlement defaults
  - `reducer.ts` — line actions handle steward-specific fields (cost category, units, settlement)
- Keep everything else unchanged for now

**Reference**: `purchase-invoice-v3/components/invoice-lines/types.ts`, `amountDefaults.ts`, `reducer.ts`

**Test checklist**:
- [ ] **Unit tests** for adapted types:
  - [ ] Default line factory produces object with `costCategoryId`, `units`, settlement fields
  - [ ] Default line factory does NOT have `motherId`
- [ ] **Unit tests** for reducer:
  - [ ] `ADD_LINE` action — creates line with steward defaults
  - [ ] `UPDATE_LINE` action — updates `costCategoryId`
  - [ ] `UPDATE_LINE` action — updates `units` array
  - [ ] `UPDATE_LINE` action — updates settlement fields (`ownerSplit`, `tenantSplit`, `splitClearing`)
  - [ ] `DELETE_LINE` action — removes line
  - [ ] `DUPLICATE_LINE` action — copies all steward fields
- [ ] Existing `pnpm test` — schema snapshot tests still pass (no production code changed yet)
- [ ] TypeScript compiles without errors

---

### Commit 5B · Adapt line card + cost/distribution components

**Roadmap**: #8 part 2 (Tier 3) · **Risk**: High

**What**: UI components for individual invoice lines, adapted for steward model.

**New files in**: `purchase-invoice-v3-steward/components/invoice-lines-steward/`

**Changes**:
- Adapt `InvoiceLineCard` — replace ledger/mother account select with cost category select
- Adapt `InvoiceLineCostAndDistribution` — distribution across selected units (not building properties)
- Add unit settlement controls per line — reuse `UnitSettlementPopover` from `purchase-invoice-v2-steward/components/`
- Adapt hooks: `useInvoiceLineHandlers`, `useInvoiceLineDispatch` for steward fields

**Reference**:
- Syndic: `purchase-invoice-v3/components/invoice-lines/InvoiceLineCard.tsx`, `InvoiceLineCostAndDistribution/`
- Steward settlement: `purchase-invoice-v2-steward/components/UnitSettlementPopover`

**Test checklist** (isolated rendering — Storybook or dev test page):
- [ ] Line card renders without errors
- [ ] **Cost category dropdown**:
  - [ ] Opens and shows available cost categories
  - [ ] Selecting a category updates the line
  - [ ] No "ledger" or "mother account" references visible
- [ ] **Distribution section**:
  - [ ] Shows selected units (from parent form's property selection)
  - [ ] Distribution method selector: share / percentage / free / key / split-later
  - [ ] Changing method updates distribution inputs per unit
  - [ ] Distribution total validates correctly
- [ ] **Settlement controls**:
  - [ ] `UnitSettlementPopover` opens on each unit row
  - [ ] Can set `ownerSplit` percentage (0–100)
  - [ ] Can set `tenantSplit` percentage
  - [ ] Can set `splitClearing` mode
  - [ ] Values persist after closing popover
- [ ] **VAT section** — expand/collapse, rate selection works
- [ ] **Period section** — expand/collapse, date range works
- [ ] TypeScript compiles without errors

---

### Commit 5C · Wire lines table into FormBody

**Roadmap**: #8 part 3 (Tier 3) · **Risk**: High

**What**: Replace the V2 amounts section with the new lines table.

**Files**:
- `purchase-invoice-v3-steward/sections/FormBody.tsx` — swap `PurchaseInvoiceAmountsSectionV2Steward` for `InvoiceLinesTableV3Steward`
- Wire orchestrator hooks: `useInvoiceLinesData` (adapted), `useInvoiceLineHandlers`

**Changes**:
- Import adapted `InvoiceLinesTableV3Steward` from `invoice-lines-steward/`
- Wire to form context (amounts field, selected properties, cost categories)
- Verify save/draft flow — `convertFormDataV2StewardToApiData` should still produce correct payloads from the new line structure

**Test checklist**:
- [ ] Open create form — empty lines section shown (add button visible)
- [ ] **Add a line** — new line row appears with steward defaults
- [ ] **Set cost category** on a line — persists
- [ ] **Set VAT rate** — persists, total recalculates
- [ ] **Set amount** — total in header updates
- [ ] **Add multiple lines** — all display, totals accumulate
- [ ] **Delete a line** — removed, totals update
- [ ] **Duplicate a line** — copy appears with all fields preserved
- [ ] **Distribution per line**:
  - [ ] Select properties first, then add a line — units available for distribution
  - [ ] Set distribution method — inputs appear per unit
  - [ ] Enter distribution values — validates (total must match)
- [ ] **Settlement per unit** — set ownerSplit/tenantSplit on each unit
- [ ] **Save as draft** — succeeds, API payload has correct amounts structure
- [ ] **Submit** — succeeds, API payload matches expected shape
- [ ] Compare API payload with V2 steward output for the same data — **structure matches**
- [ ] **Edit existing invoice** — lines pre-populated from saved data
- [ ] Edit a line and save — changes persisted
- [ ] **Change properties** after lines exist — distribution cleared (existing behavior), toast shown
- [ ] Footer totals (subtotal, VAT, total) — correct
- [ ] `pnpm test` — schema snapshot tests pass, converter tests pass

---

### Commit 5D · Line bulk selection + bulk actions

**Roadmap**: #9 (Tier 3) · **Risk**: Medium (after 5C)

**What**: Multi-select lines and apply bulk operations.

**Files**: `purchase-invoice-v3-steward/components/invoice-lines-steward/` — new bulk components + hooks

**Changes**:
- Reuse `useLineSelection` from syndic as-is (no steward-specific logic needed)
- Adapt `useLineBulkActions`:
  - Bulk set cost category (replaces syndic's bulk set ledger)
  - Bulk set distribution method across units
  - Bulk clear distribution
- Add multi-select checkboxes to steward line cards
- Add floating bulk action bar

**Reference**: `purchase-invoice-v3/components/invoice-lines/hooks/useLineSelection.ts`, `useLineBulkActions.ts`

**Test checklist**:
- [ ] Add 3+ lines to the form
- [ ] **Select** — checkbox appears on each line card
- [ ] Click checkbox on one line — selected (visual highlight)
- [ ] Click checkboxes on multiple lines — all selected
- [ ] **Select all** — if available, all lines selected
- [ ] **Bulk action bar** appears when 1+ lines selected
- [ ] **Bulk set cost category**:
  - [ ] Pick a category from bulk action dropdown
  - [ ] All selected lines update to that cost category
  - [ ] Unselected lines unchanged
- [ ] **Bulk set distribution method**:
  - [ ] Pick a method from bulk action dropdown
  - [ ] All selected lines update distribution method
- [ ] **Bulk clear distribution**:
  - [ ] Click clear action
  - [ ] All selected lines have distribution cleared
- [ ] **Deselect all** — bulk action bar hides
- [ ] Submit after bulk operations — API payload reflects bulk-set values
- [ ] `pnpm test` — existing tests pass

---

## Batch 6 — Amount mode + payment

High risk. Defer until Batch 5 is stable. Two independent commits.

### Commit 6A · Amount mode toggle (single total vs line-by-line)

**Roadmap**: #10 (Tier 4) · **Depends on**: Batch 5 · **Risk**: High

**What**: Toggle between single total amount and line-by-line entry.

**Changes**:
- Adapt `useGroupingTransition` for steward's cost category + unit distribution model
- Adapt `lineGroupingUtils` — merging lines with different cost categories and unit distributions
- Add `AmountModeToggle` to the lines section header

**Key challenge**: Grouping/merging assumes syndic's simpler ledger model. Steward has cost categories + per-unit settlement, making merge logic much more complex.

**Test checklist**:
- [ ] Open create form — default mode (check which: single total or line-by-line)
- [ ] **Toggle to single total** (from line-by-line):
  - [ ] Multiple lines merge into one
  - [ ] Merged total equals sum of individual lines
  - [ ] Cost category: merged line uses majority or first? (verify strategy)
  - [ ] Unit distributions: merged correctly or cleared with warning?
- [ ] **Toggle to line-by-line** (from single total):
  - [ ] Single line can be split (add more lines)
  - [ ] Original data preserved
- [ ] **Round-trip test**: line-by-line → single total → line-by-line
  - [ ] Data not lost (or clear warning shown if merge is lossy)
- [ ] Save in **single total mode** — API payload correct
- [ ] Save in **line-by-line mode** — API payload correct
- [ ] Edit form with single total — shows single total mode
- [ ] Edit form with multiple lines — shows line-by-line mode
- [ ] `pnpm test` — existing tests pass

---

### Commit 6B · Replace payment section with V3 PaymentDetailsSection

**Roadmap**: #11 (Tier 4) · **Risk**: High

**What**: Swap V2 payment section for V3's `PaymentDetailsSection`.

**File**: `purchase-invoice-v3-steward/sections/FormBody.tsx`

**Changes**:
- Replace `PurchaseInvoicePaymentSectionV2` with `PaymentDetailsSection` from V3
- Pass `buildingId={undefined}`, `requireBuildingId={false}`
- Verify: Ponto flow, direct debit toggle, "already paid" with payment entries, due date field

**Pre-check**: Confirm Ponto and direct debit work without a building context. Check if payment section queries are building-scoped.

**Test checklist**:
- [ ] Open create form — payment section renders without errors
- [ ] **Pay Later** mode:
  - [ ] Selected by default (or verify expected default)
  - [ ] No payment fields shown beyond due date
  - [ ] Submit — API payload has correct `paymentMethod: 'pay_later'`
- [ ] **Pay Now** mode:
  - [ ] Select pay now — IBAN dropdown appears
  - [ ] Select payment origin (paymentFrom) — works
  - [ ] Select destination (paymentTo / contactIban) — works
  - [ ] Submit — API payload has `paymentMethodId`, `contactIbanId`
- [ ] **Already Paid** mode:
  - [ ] Select already paid — payment entries section appears
  - [ ] Add a payment entry — date + amount fields
  - [ ] Submit — API payload includes payments array
- [ ] **Direct debit toggle**:
  - [ ] Toggle on — direct debit flag set
  - [ ] Toggle off — cleared
  - [ ] In credit note mode — direct debit forced off (not toggleable)
- [ ] **Ponto** (if applicable):
  - [ ] Ponto-connected IBAN appears in dropdown
  - [ ] Ponto status indicator visible
  - [ ] (Skip if Ponto not available in dev)
- [ ] **Due date field** — date picker works, bounds respected
- [ ] **Edit** existing invoice — payment section pre-filled correctly
- [ ] Edit invoice with "already paid" — payment entries shown
- [ ] Compare API payload with V2 steward payment output — **structure matches**
- [ ] `pnpm test` — existing tests pass, converter tests pass

---

## Batch 7 — Inline selects (defer, needs design)

### Commit 7A · Inline units/supplier select

**Roadmap**: #12 (Tier 4) · **Risk**: High

**What**: Replace `UnitsSection` + `SupplierSection` with inline popover selects. This is essentially a **new component** since steward's multi-property + unit selection model differs fundamentally from syndic's single-building model.

**Requires**: Design input for the UX of inline multi-property selection with settlement.

**Changes**:
- Design and build `InlineUnitsSelect` (or `InlinePropertySelect`) — multi-property search, building mode toggle, unit sub-selection
- Adapt `InlineSupplierSelect` from syndic (may work as-is if not building-scoped)
- Replace current sections in `FormBody.tsx`

**Test checklist**:
- [ ] Open create form — inline property select visible (no separate section)
- [ ] **Property search**:
  - [ ] Type to search — filtered results appear
  - [ ] Select a property — added to selection
  - [ ] Select multiple properties — all shown as chips/tags
  - [ ] Remove a property — removed from selection
- [ ] **Building mode toggle**:
  - [ ] Switch to building mode — building dropdown appears
  - [ ] Select building — `buildingId` set
  - [ ] Switch back to units — `buildingId` cleared, property selection shown
- [ ] **Unit sub-selection** (within a property):
  - [ ] Expand a selected property — units listed
  - [ ] Select/deselect individual units
  - [ ] Select all units in a property
- [ ] **Supplier inline select**:
  - [ ] Search for supplier — results appear
  - [ ] Select supplier — `senderId` set
  - [ ] Peppol supplier data populates if available
  - [ ] Clear supplier — `senderId` cleared
- [ ] **Interaction with amounts**:
  - [ ] Change properties — distribution cleared, toast shown
  - [ ] Line unit dropdowns update to reflect new properties
- [ ] Submit — API payload has correct `propertyIds`, `selectionMode`, `buildingId`
- [ ] Edit form — inline selects pre-populated with saved data
- [ ] `pnpm test` — existing tests pass
