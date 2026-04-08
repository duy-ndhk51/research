# Purchase Invoice V2 — Zod v4 Migration Checklist

Step-by-step guide for migrating `financial/forms/purchase-invoice-v2/` schema and related files.

**Schema**: `financial/forms/purchase-invoice-v2/schema.ts`
**Risk level**: CRITICAL (3 `.transform()`, 11 `.default()`, 1 `nativeEnum`, 2 `.superRefine()`)
**Related**: [Migration Plan](./README.md) | [Progress Tracker](./progress.md) (Batch 1, item #2)

---

## Phase 1: Understand the Blast Radius

Before touching anything, map out every file that imports from the `purchase-invoice-v2/` module.

- [ ] Confirm the **schema dependency graph** — these files import from `purchase-invoice-v2/schema.ts`:
  - `purchase-invoice-v2/PurchaseInvoiceFormV2.tsx` (syndic form — `purchaseInvoiceFormV2Schema`, `PurchaseInvoiceFormV2Data`)
  - `purchase-invoice-v2/PurchaseInvoiceEditFormV2.tsx` (edit wrapper)
  - `purchase-invoice-v2/schema.test.ts` (existing unit tests)
  - `purchase-invoice-v2-steward/schema.ts` (extends `amountWithDistributionSchema`, `PAYMENT_METHODS`, `PaymentMethod`, `UnitData`)
  - `purchase-invoice-v2-steward/components/StewardAmountDistributionSheet.tsx` (imports `UnitData`)
  - `peppol/components/PeppolInvoiceFloatingSheetContent.tsx` (imports `PurchaseInvoiceFormV2Data`, `AmountWithDistributionData`)
  - `financial/components/invoices/purchase-invoice/PurchaseInvoiceFormFloatingSheetContent.tsx` (imports `AmountWithDistributionData`, `PurchaseInvoiceFormV2Data`)

- [ ] Confirm the **utils dependency graph** — these files import from `purchase-invoice-v2/utils.ts`:
  - `purchase-invoice-v2-steward/utils.ts` (`calculatePurchaseInvoiceAmount`, `isUnitAllocated`, `CLEARED_DISTRIBUTION_FIELDS`, `getPeriodDatesFromAmounts`)
  - `purchase-invoice-v2-steward/PurchaseInvoiceFormV2Steward.tsx` (`CLEARED_DISTRIBUTION_FIELDS`)
  - `purchase-invoice-v2-steward/PurchaseInvoiceEditFormV2Steward.tsx` (`migrateDraftData`)
  - `purchase-invoice-v2-steward/components/AmountItemCard.tsx` (`isUnitAllocated`, `getAmountDescription`)
  - `purchase-invoice-v2-steward/components/StewardAmountDistributionSheet.tsx` (`isUnitAllocated`, `clearUnitAllocation`, `calculatePurchaseInvoiceAmount`)
  - `purchase-invoice-v2-steward/components/PurchaseInvoiceAmountsSectionV2Steward.tsx` (`CLEARED_DISTRIBUTION_FIELDS`)
  - `financial/components/invoices/purchase-invoice/PurchaseInvoiceFormFloatingSheetContent.tsx` (`convertFormDataV2ToApiData`, `CLEARED_DISTRIBUTION_FIELDS`)

- [ ] Confirm the **shared components** imported by both syndic and steward forms:
  - `purchase-invoice-v2/components/InvoiceInfoSection.tsx`
  - `purchase-invoice-v2/components/InvoiceRightPanel.tsx`
  - `purchase-invoice-v2/components/PurchaseInvoicePaymentSectionV2.tsx`
  - `purchase-invoice-v2/components/ConfirmDialogs.tsx`
  - `purchase-invoice-v2/components/amount-section/*` (DistributionMethodSelect, DeleteAmountDialog, etc.)

---

## Phase 2: Audit Zod v4 Breaking Change Exposure

Scan `schema.ts` for each breaking change category and note specific lines.

### 2.1 `.transform()` calls (CRITICAL — silent behavior change)

- [ ] Identify all `.transform()` in `schema.ts`:
  - Line 166: `.transform((data) => data as unknown as FileV2 | undefined)` on `file` field
  - Line 168-171: `.transform((data) => data as unknown as PeppolInvoiceResponse | undefined | null)` on `peppolData` field
  - Line 200-201: `.transform((data) => data as unknown as Payment[])` on `payments` field
- [ ] For each, check if `.default()` appears in the same chain — if yes, `.prefault()` may be needed
  - `file`: `.optional().transform()` — no `.default()`, safe
  - `peppolData`: `.any().transform()` — no `.default()`, but `z.any()` optionality changes (see 2.5)
  - `payments`: `.optional().transform()` — no `.default()`, safe

### 2.2 `.default()` calls (CRITICAL — short-circuit behavior)

- [ ] Identify all `.default()` in `schema.ts`:
  - Line 32: `id: z.string().default(() => uuidv4())` — generates UUID
  - Line 35: `hasVat: z.boolean().default(false)`
  - Line 38: `hasCustomPrice: z.boolean().default(false)`
  - Line 69: `wholeBuilding: z.boolean().default(true)`
  - Line 70: `useDistributionKey: z.boolean().default(true)`
  - Line 183: `isDeferredCost: z.boolean().default(false)`
  - Line 184: `isDirectDebit: z.boolean().default(false)`
  - Line 185: `isUtility: z.boolean().default(false)`
  - Line 186: `setSupplierAsDirectDebit: z.boolean().default(false)`
  - Line 193: `paymentMethod: z.enum(PAYMENT_METHODS).default('pay_now')`
  - Line 210: `remittanceType: z.nativeEnum(PaymentMessageTypeEnum).default(PaymentMessageTypeEnum.NONE)`
- [ ] Check if any `.default()` appears **after** a `.transform()` in the chain — these will short-circuit differently in v4
  - None found in this schema — all `.default()` calls are on primitive types, not after transforms. **Safe.**
- [ ] Check for `.default().optional()` or `.optional().default()` combos — key presence changes in v4
  - None found — `.default()` and `.optional()` are not chained together in this schema. **Safe.**

### 2.3 `z.nativeEnum()` (HIGH — deprecated, `.Enum`/`.Values` removed)

- [ ] Identify all `z.nativeEnum()` in `schema.ts`:
  - Line 25: `splitClearing: z.nativeEnum(AllocationSplitClearing).optional()`
  - Line 210: `remittanceType: z.nativeEnum(PaymentMessageTypeEnum).default(PaymentMessageTypeEnum.NONE)`
- [ ] Check if `.Enum` or `.Values` accessors are used anywhere on these schemas — **these are removed in v4**
- [ ] Plan migration: `z.nativeEnum(X)` → `z.enum(X)`, `.Enum.VALUE` → `.enum.VALUE`

### 2.4 `.superRefine()` (MEDIUM — `ctx.path` removed)

- [ ] Identify all `.superRefine()` in `schema.ts`:
  - Line 76-146: `amountWithDistributionSchema.superRefine()` — validates custom price, date range, distribution total
  - Line 148-157: `amountWithDistributionSchemaSyndic.superRefine()` — validates `motherId` required
  - Line 218-280: `purchaseInvoiceFormV2Schema.superRefine()` — validates payment fields, metered services dates
- [ ] Check if any `.superRefine()` callback accesses `ctx.path` — **removed in v4**
  - All three use `ctx.addIssue()` with explicit `path` in the issue object, not `ctx.path`. **Safe.**

### 2.5 `z.any()` / `z.unknown()` optionality (MEDIUM)

- [ ] Identify all `z.any()` in `schema.ts`:
  - Line 167-171: `peppolData: z.any().transform(...)` — in v4, this field will be **required** in the object (no longer optional)
- [ ] Determine if this needs `.optional()` added explicitly
  - The form always provides `peppolData` (defaults to `undefined` in `defaultInvoiceFormV2Values`), so requiring it should be safe. But verify `safeParse({})` behavior changes.

### 2.6 `z.record()` single-argument (LOW)

- [ ] Check for single-argument `z.record()`:
  - Line 182: `descriptionTranslations: z.record(z.string(), z.string()).optional()` — already two arguments. **Safe.**

### 2.7 Error customization (`message:`, `required_error`, `invalid_type_error`)

- [ ] Check for `required_error` / `invalid_type_error` (REMOVED in v4):
  - Line 203: `z.string({ required_error: 't:error_message.valuemissing' })` on `dueDate` — **WILL BREAK**
- [ ] Plan fix: replace with `error` function parameter

### 2.8 `.date()` string format validation

- [ ] Line 206: `.date('t:error_message.badinput')` — check if `z.string().date()` behavior changes in v4

---

## Phase 3: Run and Verify Existing Tests

- [ ] Run all existing tests to confirm green baseline:
  ```bash
  cd sndq-fe
  pnpm test src/modules/financial/forms/purchase-invoice-v2/
  ```
- [ ] Verify these 6 test files all pass:
  - `schema.test.ts` (68 tests — schema validation rules)
  - `convertFormDataV2ToApiData.test.ts` (20 tests — form → API conversion)
  - `calculatePurchaseInvoiceAmount.test.ts` (8 tests — amount calculations)
  - `utils-helpers.test.ts` (16 tests — utility functions)
  - `utils/transformPeppolToFormData.test.ts` (20 tests — Peppol → form)
  - `utils/transformInvoiceToFormData.test.ts` (19 tests — invoice → form edit)
- [ ] Record pass/fail status and test count for baseline

---

## Phase 4: Write Pre-Migration Snapshot Test

Write a snapshot test using the factory helper that captures exact schema output before migration.

- [ ] Create test file: `schema.migration-snapshot.test.ts`
- [ ] Write fixtures for `amountWithDistributionSchema`:
  - `valid`: complete amount with all fields (VAT, custom price, distribution key, units, dates, allowance charges)
  - `minimal`: only required fields (amount, totalAmount, distributionType, totalShare, units=[])
- [ ] Write fixtures for `amountWithDistributionSchemaSyndic`:
  - `valid`: same as above + `motherId`
  - `minimal`: same as above + `motherId`
- [ ] Write fixtures for `purchaseInvoiceFormV2Schema`:
  - `valid`: complete invoice with all fields (pay_now, structured remittance, amounts, file, etc.)
  - `minimal`: only required fields (pay_later method, single amount, no optional fields)
- [ ] Add dedicated tests for **specific v4 risk areas**:
  - Test `.default()` output: parse without `hasVat`, `hasCustomPrice`, `wholeBuilding`, `useDistributionKey` — verify defaults applied correctly
  - Test `z.any()` on `peppolData`: parse without providing `peppolData` — check if still accepted
  - Test `required_error` on `dueDate`: parse with `dueDate: 123` (wrong type) — capture error structure
  - Test `nativeEnum` values: parse with valid `AllocationSplitClearing` and `PaymentMessageTypeEnum` values
- [ ] Run test to generate baseline snapshots:
  ```bash
  pnpm test src/modules/financial/forms/purchase-invoice-v2/schema.migration-snapshot.test.ts
  ```
- [ ] Review generated `.snap` file — confirm it matches expected behavior

---

## Phase 5: Perform the Migration

### 5.1 Change the import

- [ ] In `schema.ts`, change: `import { z } from 'zod'` → `import { z } from 'zod/v4'`

### 5.2 Run snapshot test — compare diff

- [ ] Run: `pnpm test src/modules/financial/forms/purchase-invoice-v2/schema.migration-snapshot.test.ts`
- [ ] For each snapshot diff:
  - [ ] `.default()` value changed → decide: use `.prefault()` or accept new behavior
  - [ ] New keys appeared in output → decide: restructure schema or accept
  - [ ] Error structure changed → update snapshot if acceptable

### 5.3 Fix TypeScript compilation errors

- [ ] Run: `pnpm tsc --noEmit` (or just check IDE errors)
- [ ] Fix `required_error` on `dueDate` (line 203) → replace with `error` function:
  ```typescript
  // Before
  dueDate: z.string({ required_error: 't:error_message.valuemissing' })
  // After
  dueDate: z.string({ error: (issue) => issue.input === undefined ? 't:error_message.valuemissing' : undefined })
  ```
- [ ] Fix `z.nativeEnum()` calls (lines 25, 210) → change to `z.enum()`:
  ```typescript
  // Before
  splitClearing: z.nativeEnum(AllocationSplitClearing).optional()
  remittanceType: z.nativeEnum(PaymentMessageTypeEnum).default(PaymentMessageTypeEnum.NONE)
  // After
  splitClearing: z.enum(AllocationSplitClearing).optional()
  remittanceType: z.enum(PaymentMessageTypeEnum).default(PaymentMessageTypeEnum.NONE)
  ```
- [ ] Fix `z.any()` optionality on `peppolData` if needed — may need `.optional()` added
- [ ] Check `.date()` on `dueDate` line 206 — may need syntax update

### 5.4 Run all existing tests

- [ ] Run: `pnpm test src/modules/financial/forms/purchase-invoice-v2/`
- [ ] All 6 existing test files must pass
- [ ] Schema migration snapshot test must pass (or diffs must be reviewed and accepted)

### 5.5 Run TypeScript check on full codebase

- [ ] Run: `NODE_OPTIONS="--max-old-space-size=8192" pnpm type-check`
- [ ] Fix any type errors in dependent files caused by type inference changes

---

## Phase 6: Test Downstream Consumers

### 6.1 Steward schema (extends the syndic schema)

- [ ] Verify `purchase-invoice-v2-steward/schema.ts` compiles — it imports `amountWithDistributionSchema`, `PAYMENT_METHODS`, `PaymentMethod`, `UnitData`
- [ ] Run steward tests if they exist
- [ ] If steward also needs `"zod/v4"` import change, do it now (same batch, same risk profile)

### 6.2 Peppol form sheet (imports types)

- [ ] Verify `PurchaseInvoiceFormFloatingSheetContent.tsx` compiles — imports `AmountWithDistributionData`, `PurchaseInvoiceFormV2Data`
- [ ] Verify `PeppolInvoiceFloatingSheetContent.tsx` compiles — imports `PurchaseInvoiceFormV2Data`

### 6.3 Utils consumers

- [ ] Verify all files importing from `purchase-invoice-v2/utils.ts` compile:
  - `purchase-invoice-v2-steward/utils.ts`
  - `PurchaseInvoiceFormFloatingSheetContent.tsx`
  - All steward components

---

## Phase 7: Manual QA in Browser

Test all entry points from [the impact analysis](./README.md).

### 7.1 Syndic: Create new invoice (full-page)

- [ ] Navigate: Purchase invoices → "Add" button
- [ ] Select supplier → verify direct debit / utility flags auto-populate
- [ ] Select building → verify building populates
- [ ] Fill invoice info (name, date, number)
- [ ] Add amount with VAT → verify total calculates correctly
- [ ] Select ledger (motherId) for the amount
- [ ] Select distribution key → verify units populate with split amounts
- [ ] Toggle "Deferred cost" ON → verify distribution data clears
- [ ] Toggle "Deferred cost" OFF
- [ ] Set payment method to "Pay now" → fill from/to accounts
- [ ] Set structured remittance → enter valid OGM (e.g., `+++123/4567/89002+++`)
- [ ] Submit → verify success toast + navigates to detail
- [ ] **Check network tab**: verify API payload matches expected structure

### 7.2 Syndic: Edit existing invoice

- [ ] Open an existing non-draft invoice → click "Edit"
- [ ] Verify form pre-populates correctly from `transformInvoiceToFormData`
- [ ] Change a field → submit
- [ ] Verify update success

### 7.3 Syndic: Draft workflow

- [ ] Create new invoice → click "Save as concept" (combo button)
- [ ] Verify draft saved with building ID required
- [ ] Re-open the draft → verify form pre-populates from draft data
- [ ] Submit draft as final invoice → verify success

### 7.4 Peppol: Quick-save from floating sheet

- [ ] Navigate: Peppol inbox → click a received invoice → "Convert to invoice"
- [ ] Verify form pre-populates (supplier, building, amounts, dates, remittance)
- [ ] Click "Save" → verify invoice created
- [ ] If supplier not found, verify warning message appears

### 7.5 Peppol: Full edit from floating sheet

- [ ] From Peppol quick-save sheet → click "Edit" dropdown
- [ ] Verify full form opens in drawer with pre-filled data
- [ ] Submit → verify success

### 7.6 Credit note

- [ ] Open a credit note Peppol invoice (typeCode = 381)
- [ ] Verify direct debit checkbox is forced OFF
- [ ] Verify "Original invoice" section appears
- [ ] Submit → verify API receives `type: 'credit_note'`

### 7.7 Steward: Smoke test

- [ ] Switch to a steward workspace
- [ ] Create new purchase invoice → fill basic fields → submit
- [ ] Edit an existing invoice → verify pre-population → submit
- [ ] Save a draft → re-open → verify

### 7.8 Validation errors

- [ ] Submit empty form → verify toast: "Supplier/building validation error"
- [ ] Fill supplier/building, submit without invoice details → verify toast: "Invoice details validation error"
- [ ] Fill details, submit without amounts → verify toast: "Amounts validation error"
- [ ] Add amount without ledger → verify toast: "Cost categories validation error"
- [ ] Set "Pay now" without accounts → verify toast: "Payment details validation error"

---

## Phase 8: Record Metrics

- [ ] Run `tsc --diagnostics` after migration:
  ```bash
  rm -f tsconfig.tsbuildinfo
  NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics
  ```
- [ ] Record in [metrics-record.md](./metrics-record.md):
  - Instantiations count
  - Check time
  - Total time
  - Memory used
- [ ] Compare with baseline values

---

## Phase 9: Commit

- [ ] Ensure all tests pass: `pnpm test src/modules/financial/forms/purchase-invoice-v2/`
- [ ] Ensure type-check passes: `pnpm type-check`
- [ ] Update snapshot if changes were intentionally accepted: `pnpm test -- -u`
- [ ] Update [progress.md](./progress.md) Batch 1 table — check all boxes for item #2
- [ ] Commit: `refactor(zod): migrate purchase-invoice-v2 schema to zod/v4`

---

## Quick Reference: Files to Modify

| File | Change |
|------|--------|
| `purchase-invoice-v2/schema.ts` | Change import, fix `nativeEnum`, fix `required_error`, fix `z.any()` optionality |
| `purchase-invoice-v2/schema.migration-snapshot.test.ts` | New file — pre-migration snapshot test |
| `purchase-invoice-v2-steward/schema.ts` | May need import change if it also imports `z` from `'zod'` |

**Do NOT modify** (but verify they still compile):
- `utils.ts`, `utils-helpers.test.ts`, `convertFormDataV2ToApiData.test.ts`, etc. — these don't import `z` from `'zod'` directly
- All component files (`PurchaseInvoiceFormV2.tsx`, etc.) — no schema changes, just verify they compile
