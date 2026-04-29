# Steward V3 — Feature Sync Roadmap

## Goal

Gradually bring V3 syndic features into the steward V3 form, moving from low-risk additions to high-complexity structural changes. Each tier can be shipped independently.

## Reference modules

| Module | Path | Role |
|--------|------|------|
| V3 Syndic | `purchase-invoice-v3/` | Full-featured reference implementation |
| V3 Steward | `purchase-invoice-v3-steward/` | Restructured steward form (V3 architecture, V2 steward logic) |
| V2 Steward | `purchase-invoice-v2-steward/` | Legacy steward components reused by V3 steward |

## Steward-specific concepts to preserve

These steward differences must be respected when porting any syndic feature:

- **Multi-property selection**: `propertyIds[]` with `selectionMode` (building vs units), not single `buildingId`
- **Cost categories**: amounts require `costCategoryId` (steward uses cost categories, not `motherId` ledger accounts)
- **Unit settlement**: per-unit `ownerSplit` / `tenantSplit` / `splitClearing` on each amount
- **Distribution model**: share/percentage/free/key/split-later across selected units, with `ownerSplit / 100` conversion for API

## Feature status overview

| # | Feature | Tier | Status | Notes |
|---|---------|------|--------|-------|
| 0 | UI layout consistency (form shell) | 0 | Done | Commit 1A |
| 1 | Duplicate invoice warning | 1 | Done | Commit 1B |
| 2 | Invoice date bounds | 1 | Done | Commit 1C |
| 3 | Auto invoice number generation | 1 | Done | Deferred to 2C (needs mode) |
| 4 | Invoice mode toggle | 2 | Done | Commit 2A |
| 5 | Description section upgrade | 2 | Done | Commit 2B |
| 6 | Partial edit mode | 2 | Done | Commits 3A + 3B |
| 7 | AI document extraction | 3 | Done | Commit 4A+4B |
| 7.5 | Zod v4 steward schema migration | 3 | Done | Commit 4C |
| 8 | Inline invoice lines table | 3 | In progress | Commits 5A–5C done, 5D pending |
| 9 | Line bulk selection + bulk actions | 3 | Not started | Depends on #8 |
| 10 | Amount mode toggle (single total vs line-by-line) | 4 | Not started | Depends on #8 |
| 11 | V3 payment section | 4 | Not started | |
| 12 | V3 inline building/supplier select | 4 | Not started | |

---

## Tier 0 — Layout consistency (zero risk)

Align the steward V3 form shell with the syndic V3 form for visual consistency. Pure CSS/layout changes, no logic or schema impact.

### 0. UI layout consistency (form shell)

Match `PurchaseInvoiceFormV3Steward.tsx` layout to `PurchaseInvoiceFormV3.tsx`:

- **Form className**: add `overflow-hidden rounded-t-2xl` (syndic: `flex h-full flex-col overflow-hidden rounded-t-2xl`, steward currently: `flex h-full flex-col`)
- **Left panel**: add `bg-neutral-0` class (syndic: `border-r bg-neutral-0`, steward currently: `border-r`)
- **Outer wrapper**: steward has an extra `<div>` with conditional `fixed inset-0 z-10` for the full-page route — simplify to match syndic's pattern while preserving full-page support
- **FormDialogs placement**: syndic places `FormDialogs` as sibling to `<form>` inside `AiExtractionProvider`; steward places it outside `<form>` inside `FormProvider` — align nesting order

**Files involved**:
- `purchase-invoice-v3-steward/PurchaseInvoiceFormV3Steward.tsx` — all changes in this single file

**Risk**: Zero. CSS class changes only. No logic, schema, or behavioral change.

---

## Tier 1 — Drop-in additions (low risk)

Self-contained features that can be added without changing schemas or core logic. Each is a 1-2 file change.

### 1. Duplicate invoice warning

Add the existing `DuplicateWarningButton` (from `purchase-invoice-v2/components`) to the steward `FormHeader.tsx`.

**Files involved**:
- `purchase-invoice-v3-steward/sections/FormHeader.tsx` — add component to header actions

**Risk**: None. Component is already battle-tested in syndic V2/V3.

### 2. Invoice date bounds

Import `getInvoiceDateBounds()` from V3 constants and pass `min`/`max` to the invoice date field rendered by `InvoiceInfoSection`.

**Files involved**:
- `purchase-invoice-v3-steward/sections/FormBody.tsx` — pass date bounds to info section
- May need a prop addition to `InvoiceInfoSection` if it doesn't already accept bounds

**Risk**: Minimal. Pure UI constraint, no schema change.

### 3. Auto invoice number generation

Reuse `generateInvoiceNumber` from V3 constants. Add a toggle (auto vs manual) to the invoice number field area.

**Files involved**:
- `purchase-invoice-v3-steward/sections/FormBody.tsx` or a new `InvoiceFieldsSection` wrapper
- Import `generateInvoiceNumber` from `purchase-invoice-v3/constants`

**Risk**: Low. Locale-aware prefix logic is already implemented. Steward may need different prefix conventions — verify with product.

---

## Tier 2 — Moderate additions (medium risk)

These add new UI sections or providers but don't change the core amount/distribution model.

### 4. Invoice mode toggle

Add `InvoiceModeToggle` from V3 to steward `FormHeader`. Steward schema already has `invoiceTypeCode`. Wire `MODE_TO_TYPE_CODE` mapping and adjust header title/save label for credit note vs expense note.

**Files involved**:
- `purchase-invoice-v3-steward/sections/FormHeader.tsx` — add toggle
- `purchase-invoice-v3-steward/hooks/useStewardFormActions.ts` — verify `convertFormDataV2StewardToApiData` handles all type codes

**Risk**: Medium. Need to verify the API converter and backend accept expense note type codes for steward invoices.

### 5. Description section upgrade

Replace the basic description handling from `InvoiceInfoSection` with V3's `DescriptionSection` (multi-language tabs, add/remove languages, auto-translate via `useTranslateText`, auto-fill via `useDescriptionAutoFill`).

**Files involved**:
- `purchase-invoice-v3-steward/sections/FormBody.tsx` — replace description area with `DescriptionSection`
- Import `useDescriptionAutoFill` from V3 hooks
- Import `DescriptionSection` from V3 sections

**Risk**: Medium. Translation API integration needs verification in steward context. The `buildStandardDescription` format may need steward-specific adjustments (building name vs property names).

### 6. Partial edit mode

Add `isPartialEditMode` detection using `isInvoicePartiallyEditable` utility. Show a warning banner in `FormBody` and disable payment fields when active.

**Files involved**:
- `purchase-invoice-v3-steward/hooks/useStewardForm.ts` — add partial edit detection
- `purchase-invoice-v3-steward/contexts/StewardFormContext.tsx` — expose `isPartialEditMode`
- `purchase-invoice-v3-steward/sections/FormBody.tsx` — add warning banner, disable fields

**Risk**: Medium. Needs thorough edit flow testing to ensure field locking covers all steward-specific fields (units, cost categories, settlement).

---

## Tier 3 — Significant additions (higher risk)

New infrastructure (providers, hooks, component trees) that need careful integration testing.

### 7. AI document extraction

Wrap the steward form with `AiExtractionProvider`, add `AiExtractionBanner` and `AiExtractionOverlay`, integrate `useFileHandling` (replacing the current manual file upload wiring).

**Files involved**:
- `purchase-invoice-v3-steward/PurchaseInvoiceFormV3Steward.tsx` — add `AiExtractionProvider`
- `purchase-invoice-v3-steward/sections/FormBody.tsx` — add `AiExtractionOverlay`, confidence indicators
- `purchase-invoice-v3-steward/hooks/useStewardForm.ts` — integrate `useFileHandling`

**Key challenge**: AI extraction maps fields to syndic's schema shape. Steward amounts need `costCategoryId` which AI doesn't extract — amounts will need post-extraction enrichment or a "review required" state for cost categories.

**Risk**: High integration surface. Consider a phased approach: (a) file upload + Peppol prefill first (already working), (b) add AI field confidence indicators, (c) add full extraction with amount mapping.

**Pre-work completed**: `useAiExtraction` made generic via `AiExtractableInvoiceFields` interface — steward form no longer needs `as never` casts. `transformExtractedDataToFormData` returns `Partial<AiExtractableInvoiceFields>` instead of `Partial<PurchaseInvoiceFormV2Data>`. Unit tests added for the transform function.

### 7.5. Zod v4 steward schema migration

Migrate `purchase-invoice-v2-steward/schema.ts` from Zod v3 to v4 syntax. Placed after AI extraction (#7) and before inline invoice lines (#8) so all new Batch 5+ code is written in v4 from the start.

**Prerequisite**: Project-wide Zod v4 setup (package version, resolver, hooks) and upstream syndic schema (`purchase-invoice-v2/schema.ts`) already migrated.

**Files involved**:
- `purchase-invoice-v2-steward/schema.ts` — 4 syntax substitutions

**Changes**:
- `z.string().uuid({ message })` → `{ error }` (senderId)
- `z.string({ required_error })` → `{ error }` (dueDate)
- `.date('message')` → `.date({ error })` (dueDate)
- `z.nativeEnum(PaymentMessageTypeEnum)` → `z.enum(PAYMENT_MESSAGE_TYPE_LIST)` (remittanceType)

**Risk**: Low. Pure syntax migration, no behavioral change. All `superRefine`/`addIssue` calls are unchanged (v4-compatible).

### 8. Inline invoice lines table

Replace the current `PurchaseInvoiceAmountsSectionV2Steward` with an adapted version of `InvoiceLinesTableV3`. This is the largest feature port.

**V3 syndic subtree (26 files)**:
```
purchase-invoice-v3/components/invoice-lines/
├── InvoiceLinesTableV3.tsx          — main table component
├── InvoiceLineCard.tsx              — collapsible line row (VAT, period, cost & distribution)
├── InvoiceLineCostAndDistribution   — ledger + distribution per line
├── AmountModeToggle.tsx             — single total vs line-by-line
├── SingleTotalView.tsx              — simplified single-amount view
├── InvoiceLinesTableFooter.tsx      — totals summary
├── VatExpandableSection.tsx         — VAT breakdown
├── PeriodExpandableSection.tsx      — period presets + custom
├── reducer.ts                       — pure line action transforms
├── amountDefaults.ts                — default line factory
├── lineGroupingUtils.ts             — grouping/merging logic
├── types.ts                         — line-level types
└── hooks/
    ├── useInvoiceLinesData.ts       — orchestrator
    ├── useInvoiceLineHandlers.ts    — per-line update dispatch
    ├── useInvoiceLineDispatch.ts    — action → form setValue
    ├── useInvoiceLineUiState.ts     — expand/collapse VAT/period
    ├── useLineSelection.ts          — multi-select state
    ├── useLineGrouping.ts           — grouping strategy
    ├── useGroupingTransition.ts     — merge/restore on toggle
    ├── useLineTotals.ts             — aggregate calculations
    ├── useLineBulkActions.ts         — bulk set ledger/distribution
    ├── useLineCrud.ts               — add/duplicate/delete/distribution sheet
    └── usePeriodPresets.ts          — period preset options
```

**Steward adaptations needed**:
- Replace `motherId` (ledger) references with `costCategoryId` in `InvoiceLineCard`, `InvoiceLineCostAndDistribution`, bulk actions
- Unit settlement controls (owner/tenant split) accessed via the custom distribution sheet (not inline on the line card)
- Adapt distribution methods: steward distributes across selected units (not just building properties)
- `amountDefaults.ts` — `createDefaultStewardAmount` includes `costCategoryId`, `units[]`, settlement defaults; no distribution-key-aware factory (distribution keys applied at action dispatch time, not at line creation)
- `reducer.ts` — line actions handle steward-specific fields (`SET_COST_CATEGORY`)

**Progress**: Commits 5A–5C done (scaffold, line card + cost/distribution components, table wired into FormBody). Commit 5D (bulk selection + bulk actions) pending.

**Risk**: High. This touches the core data entry experience. Built in parallel as `invoice-lines/` within the V3 steward module, swapped into `FormBody` at 5C.

### 9. Line bulk selection + bulk actions

Add multi-select checkboxes on line cards and a floating bulk action bar. Depends on #8 (inline lines table).

**Steward adaptations**:
- Bulk set cost category (instead of ledger)
- Bulk set distribution method across units
- Bulk clear distribution

**Risk**: Medium (after #8 is done). The selection hooks from V3 syndic can be reused as-is; only the bulk action handlers need steward-specific logic.

---

## Tier 4 — Major structural changes (defer until stable)

These replace core steward-specific UI sections. High regression risk due to fundamental model differences. Defer until Tier 1-3 features are stable in production.

### 10. Amount mode toggle (single total vs line-by-line)

Requires `useGroupingTransition` + `lineGroupingUtils` adapted for steward's cost category + unit distribution model. Grouping/merging logic assumes syndic's simpler ledger model.

**Depends on**: #8 (inline invoice lines)

**Risk**: High. Merging lines with different cost categories and unit distributions is complex.

### 11. V3 payment section

Replace `PurchaseInvoicePaymentSectionV2` with `PaymentDetailsSection`. Steward passes different props (`buildingId: undefined`, `requireBuildingId: false`).

**Risk**: High. Need to verify Ponto, direct debit, and "already paid" flows work without a building context. The steward payment model may have edge cases not covered by the syndic component.

### 12. V3 inline building/supplier select

Replace steward's `UnitsSection` + V2 `SupplierSection` with V3-style inline popovers. The steward's units concept (building vs hand-picked units with settlement) is fundamentally different from syndic's single-building model.

**Risk**: High. Would require a new `InlineUnitsSelect` component that doesn't exist in V3 syndic. This is essentially a new feature, not a port.

---

## Dependency graph

```
Tier 0 (do first)
  0. UI layout consistency

Tier 1 (independent, can be done in any order)
  1. Duplicate warning
  2. Date bounds
  3. Auto invoice number

Tier 2 (independent of each other, but after Tier 1 for stability)
  4. Mode toggle
  5. Description upgrade
  6. Partial edit mode

Tier 3
  7. AI extraction (independent)
  7.5. Zod v4 steward schema → after #7, before #8
  8. Inline invoice lines (independent, largest effort)
  9. Bulk selection → depends on #8

Tier 4
  10. Amount mode toggle → depends on #8
  11. V3 payment section (independent)
  12. V3 building/supplier select (independent, new component)
```
