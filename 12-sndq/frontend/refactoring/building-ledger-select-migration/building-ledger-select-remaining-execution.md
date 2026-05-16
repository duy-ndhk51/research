# Remaining AccountingLedgerSelectV2 Migration Execution

Step-by-step execution guide for replacing all remaining `AccountingLedgerSelectV2` usages with `BuildingLedgerSelect`. Each commit should be independently verifiable and revertable.

**Created**: 2026-05-15
**Updated**: 2026-05-17 (updated diffs for refactored BuildingLedgerSelect discriminated union value type)
**Status**: In progress
**Branch**: `feat/SQ-21333` (continue from prior fallback + v2 form migration)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Remaining AccountingLedgerSelectV2 Migration](#3-pr-1--remaining-accountingledgerselectv2-migration)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Replace every remaining `AccountingLedgerSelectV2` usage with `BuildingLedgerSelect`, threading `buildingId` where it is not yet available, so all cost-category selectors use building-scoped options with mother-options fallback.

**Structure**: 7 commits across 1 PR.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | All remaining V2 select replacements | Medium | 1-7 |

**Why 1 PR**: All changes follow the same mechanical pattern (swap component + optional prop threading). Grouping keeps the migration atomic — after merge, `AccountingLedgerSelectV2` has zero consumers.

### Prioritization rationale

Commits are ordered by priority based on the [API compatibility report](./building-ledger-select-api-compatibility-report.md):

| Priority | Commits | Rationale |
|----------|---------|-----------|
| **Highest** | 1-4 | Purchase invoice flow — API already supports `ledgerId`, can ship immediately |
| **Medium** | 5 | Fiscal year setup — API supports `ledgerId`, non-invoice flow |
| **Lowest** | 6-7 | **BLOCKED on BE** — APIs only accept `accountingMotherId`, not `ledgerId` |

### Prerequisites

- BuildingLedgerSelect fallback + v2/v3 form migration is complete (commits 1-4 from prior execution)
- `BuildingLedgerSelect` uses a **discriminated union** value type: `BuildingLedgerSelectValue = { kind: 'id', id: string } | { kind: 'full', ...CostAccountData }`
- The 3-tier fallback resolves options: building options → full `CostAccountData` (inline fallback) → `useMotherLedgerOptions` (API fallback)
- All 771 purchase-invoice tests passing

### Known constraints

- All remaining usages pass **plain string IDs** (not `costAccount` objects), so value must be wrapped as `{ kind: 'id', id: stringValue }` and they rely on Priority 2 (`useMotherLedgerOptions` fallback)
- 4 files need `buildingId` threaded from a parent — prop additions are required
- `SupplierInvoiceSheet` needs 2 levels of threading (`FiscalYearSetupForm` → `SupplierStep` → `SupplierInvoiceSheet`)
- Commits 6-7 are **blocked on BE API changes**:
  - Commit 6 (`AddBuildingSupplierSheet`): `LinkBuildingSupplierDto` only accepts `accountingMotherId`, not `ledgerId`
  - Commit 7 (`SupplierFloatingSheetContent`): `OpeningDataSetupSupplierInvoiceEntryDto` only accepts `accountingMotherId`, not `ledgerId`
- After all 7 commits, `AccountingLedgerSelectV2` has zero imports and can be deleted in a follow-up

---

## 2. Before You Start

### Quality gate before each implementation commit

- [ ] Public API / behavior is stable for this commit scope
- [ ] Public props, types, functions, or commands have minimal useful documentation where applicable
- [ ] Existing project helpers and patterns are reused instead of introducing one-off abstractions
- [ ] Tests or documented manual checks cover the main behavior and likely regressions
- [ ] No unrelated files, app-specific imports, or ownership-boundary leaks are introduced
- [ ] Security-sensitive values, credentials, generated secrets, and local env files are not committed
- [ ] Build, lint, type-check, and any targeted verification commands are known before editing
- [ ] Any skipped verification is recorded as a deviation with a follow-up owner or trigger

### Documentation and comment policy

- Keep code comments minimal and focused on intent, invariants, or non-obvious behavior.
- Put usage examples, migration notes, variant tables, setup steps, and operational runbooks in docs, not inline code comments.

### Inspect source tree before implementation

Before the first implementation commit, inspect the actual repository state and record any differences from this plan.

- [ ] Confirm files and folders in **Files to edit** are accurate
- [ ] Confirm current lint, type-check, build, or test failures that predate this phase
- [ ] Confirm existing exports and public entry points before changing them
- [ ] Confirm whether dependencies or lockfiles will change

### Capture baselines

```bash
cd sndq-fe && npx vitest run 2>&1 | tee /tmp/ledger-remaining-tests-before.txt
```

---

## 3. PR 1 — Remaining AccountingLedgerSelectV2 Migration

Replaces all 7 remaining `AccountingLedgerSelectV2` usages with `BuildingLedgerSelect`, threading `buildingId` from parent components where needed.

---

### Commit 1: Replace in AmountsAllocationSection (3 usages)

**What**: Direct swap of 3 `AccountingLedgerSelectV2` usages — `buildingId` is already a prop (`string | null | undefined`). Guard each with `buildingId &&`.

**API status**: `POST /purchase-invoices` supports both `motherId` and `ledgerId` in `allocationCosts[]`. No BE changes needed.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/AmountsAllocationSection.tsx` — Replace import and 3 JSX usages

**Change detail**:

```diff
- import AccountingLedgerSelectV2 from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect';
```

Usage A (bulk, ~line 156):
```diff
- <AccountingLedgerSelectV2
-   value={bulkLedger.value}
-   onChange={(ledger) => onGroupLedgerChange(allLineIds, ledger)}
-   placeholder={bulkLedger.isMixed ? mixedLabel : undefined}
-   error={amounts.some((a) => !a.motherId)}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={bulkLedger.value ? { kind: 'id', id: bulkLedger.value } : undefined}
+     onChange={(ledger) => onGroupLedgerChange(allLineIds, ledger)}
+     placeholder={bulkLedger.isMixed ? mixedLabel : undefined}
+     error={amounts.some((a) => !a.motherId)}
+   />
+ )}
```

Usage B (per line, by-VAT view, ~line 214) — uses `kind: 'full'` when `costAccount` data is available:
```diff
- <AccountingLedgerSelectV2
-   value={amount.motherId}
-   onChange={(ledger) => onLedgerChange(index, ledger)}
-   error={!amount.motherId}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={amount.costAccount ? { kind: 'full', ...amount.costAccount } : undefined}
+     onChange={(ledger) => onLedgerChange(index, ledger)}
+     error={!amount.motherId}
+   />
+ )}
```

Usage C (per line, individual view, ~line 259) — same `kind: 'full'` pattern:
```diff
- <AccountingLedgerSelectV2
-   value={amount.motherId}
-   onChange={(ledger) => onLedgerChange(index, ledger)}
-   error={!amount.motherId}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={amount.costAccount ? { kind: 'full', ...amount.costAccount } : undefined}
+     onChange={(ledger) => onLedgerChange(index, ledger)}
+     error={!amount.motherId}
+   />
+ )}
```

Note: `BuildingLedgerSelect` supports `error?: boolean` prop (threaded through `AccountingLedgerSelectBase`). The `value` prop uses the discriminated union `BuildingLedgerSelectValue`: `{ kind: 'id', id }` for plain IDs (triggers mother-options fallback), `{ kind: 'full', ...CostAccountData }` for rich data (creates inline fallback option).

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `error` prop may not be supported on `BuildingLedgerSelect` | MEDIUM | Check `BuildingLedgerSelectProps` — it already has `error?: boolean` |
| `buildingId` could be null | LOW | Guard with `buildingId &&` |

**Verification**:

```bash
cd sndq-fe && pnpm tsc --noEmit 2>&1 | head -30
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: use BuildingLedgerSelect in AmountsAllocationSection`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Committed

---

### Commit 2: Thread buildingId to CostSelector + replace

**What**: Add `buildingId` prop to `CostSelector`, thread from `AllocationCostsSection` which already has it, then swap the select component.

**API status**: `PUT /purchase-invoices/:id/allocations` supports both `motherId` and `ledgerId` via `useAllocationCostsForm`. No BE changes needed.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/CostSelector.tsx` — Add `buildingId` prop, replace import and JSX
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/AllocationCostsSection.tsx` — Pass `buildingId` to `CostSelector`

**Change detail — CostSelector.tsx**:

```diff
- import AccountingLedgerSelectV2 from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect';

  export function CostSelector({
    mode,
    costIds,
    amounts,
    mixedLabel,
+   buildingId,
    onUpdateLedger,
    onUpdateCostCategory,
  }: {
    mode: AllocationCostMode;
    costIds: string[];
    amounts: AmountWithDistributionData[];
    mixedLabel: string;
+   buildingId: string | null | undefined;
    onUpdateLedger: ...;
    onUpdateCostCategory: ...;
  }) {
    ...
    ...
    if (!buildingId) return null;
    return (
-     <AccountingLedgerSelectV2
-       value={bulkValue.value}
-       onChange={(ledger) => onUpdateLedger(costIds, ledger)}
-       placeholder={bulkValue.isMixed ? mixedLabel : undefined}
-     />
+     <BuildingLedgerSelect
+       buildingId={buildingId}
+       value={bulkValue.value ? { kind: 'id', id: bulkValue.value } : undefined}
+       onChange={(ledger) => onUpdateLedger(costIds, ledger)}
+       placeholder={bulkValue.isMixed ? mixedLabel : undefined}
+     />
    );
```

**Change detail — AllocationCostsSection.tsx** (~line 200):

```diff
  <CostSelector
    mode={mode}
    costIds={costIds}
    amounts={group.amounts}
    mixedLabel={mixedLabel}
+   buildingId={buildingId}
    onUpdateLedger={onUpdateLedger}
    onUpdateCostCategory={onUpdateCostCategory}
  />
```

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `buildingId` null before invoice loads | LOW | Guard with `buildingId &&` |

**Verification**:

```bash
cd sndq-fe && pnpm tsc --noEmit 2>&1 | head -30
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: thread buildingId to CostSelector, use BuildingLedgerSelect`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Committed

---

### Commit 3: Thread buildingId to EditLedgerSheet + replace

**What**: Add `buildingId` prop to `EditLedgerSheet`, thread from `PurchaseInvoiceCostAllocation` which already has it.

**API status**: `PATCH /purchase-invoices/:id/allocations` supports both `motherId` and `ledgerId` via `PatchAllocationCostDto`. No BE changes needed.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx` — Add prop, replace import and JSX
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/PurchaseInvoiceCostAllocation.tsx` — Pass `buildingId` to `EditLedgerSheet`

**Change detail — EditLedgerSheet.tsx**:

```diff
- import AccountingLedgerSelectV2 from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect';

  interface EditLedgerSheetProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    allocationCost: AllocationCost | null;
    currency?: string;
+   buildingId?: string;
  }

- <AccountingLedgerSelectV2
-   value={selectedLedger}
-   onChange={handleLedgerChange}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={selectedLedger ? { kind: 'full', ...selectedLedger } : undefined}
+     onChange={handleLedgerChange}
+   />
+ )}
```

Note: `selectedLedger` is a `LedgerSelectOnChangeValue` built from `buildSelectedLedger(allocationCost)`, which provides `id`, `type`, `name`, `code` — compatible with `kind: 'full'` spread.

**Change detail — PurchaseInvoiceCostAllocation.tsx** (~line 171):

```diff
  <EditLedgerSheet
    open={editLedgerSheetOpen}
    onOpenChange={setEditLedgerSheetOpen}
    allocationCost={selectedCost}
    currency={currency}
+   buildingId={buildingId}
  />
```

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `buildingId` optional — select hidden if undefined | LOW | Parent always passes `invoice?.buildingId \|\| buildingId` |

**Verification**:

```bash
cd sndq-fe && pnpm tsc --noEmit 2>&1 | head -30
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: thread buildingId to EditLedgerSheet, use BuildingLedgerSelect`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Committed

---

### Commit 4: Thread buildingId to EditLedgerFloatingSheetContent + replace

**What**: Add `buildingId` prop to `EditLedgerFloatingSheetContent`, thread from 2 parent components which both have `invoice.buildingId`.

**API status**: `PATCH /purchase-invoices/:id/allocations` supports both `motherId` and `ledgerId`. No BE changes needed.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx` — Add prop, replace import and JSX
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoiceDetailFloatingSheet.tsx` — Pass `buildingId={invoice.buildingId}`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoicePreviewFloatingSheetContent.tsx` — Pass `buildingId={invoice.buildingId}`

**Change detail — EditLedgerFloatingSheetContent.tsx**:

```diff
- import AccountingLedgerSelectV2 from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect';

  interface EditLedgerFloatingSheetContentProps {
    onClose: () => void;
    allocationCost: AllocationCost | null;
    currency?: string;
+   buildingId?: string;
  }

- <AccountingLedgerSelectV2
-   value={selectedLedger}
-   onChange={handleLedgerChange}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={selectedLedger ? { kind: 'full', ...selectedLedger } : undefined}
+     onChange={handleLedgerChange}
+   />
+ )}
```

Note: Same `kind: 'full'` pattern as Commit 3 — `selectedLedger` is built from `buildSelectedLedger(allocationCost)`.

**Change detail — PurchaseInvoiceDetailFloatingSheet.tsx** (~line 538):

```diff
  <EditLedgerFloatingSheetContent
    onClose={() => setEditLedgerCost(null)}
    allocationCost={editLedgerCost}
    currency={invoice.currency}
+   buildingId={invoice.buildingId}
  />
```

**Change detail — PurchaseInvoicePreviewFloatingSheetContent.tsx** (~line 139):

```diff
  <EditLedgerFloatingSheetContent
    onClose={() => setEditLedgerCost(null)}
    allocationCost={editLedgerCost}
    currency={invoice.currency}
+   buildingId={invoice.buildingId}
  />
```

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `invoice.buildingId` could be undefined during loading | LOW | Guard with `buildingId &&` in the component |
| Two parent files to update | LOW | Both follow identical pattern |

**Verification**:

```bash
cd sndq-fe && pnpm tsc --noEmit 2>&1 | head -30
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: thread buildingId to EditLedgerFloatingSheet, use BuildingLedgerSelect`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Committed

---

### Commit 5: Thread buildingId to SupplierInvoiceSheet (2 levels) + replace

**What**: Thread `buildingId` from `FiscalYearSetupForm` → `SupplierStep` → `SupplierInvoiceSheet`, then swap the select.

**API status**: `POST /buildings/:id/financial/setup` supports both `motherId` and `ledgerId` via `SetupPurchaseInvoiceDto` with `RequiredIf` cross-validation. No BE changes needed.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/fiscal-year-setup/FiscalYearSetupForm.tsx` — Pass `buildingId` to `SupplierStep`
- `sndq-fe/src/modules/financial/forms/fiscal-year-setup/steps/SupplierStep.tsx` — Add `buildingId` prop, pass to `SupplierInvoiceSheet`
- `sndq-fe/src/modules/financial/forms/fiscal-year-setup/components/SupplierInvoiceSheet.tsx` — Add `buildingId` prop, replace import and JSX

**Change detail — FiscalYearSetupForm.tsx** (~line 70):

```diff
  <SupplierStep
    suppliersMap={suppliersMap}
    setSuppliersMap={setSuppliersMap}
+   buildingId={buildingId}
  />
```

**Change detail — SupplierStep.tsx**:

```diff
  interface SupplierStepProps {
    suppliersMap: Map<string, ContactV2>;
    setSuppliersMap: React.Dispatch<React.SetStateAction<Map<string, ContactV2>>>;
+   buildingId: string;
  }

  export default function SupplierStep({
    suppliersMap,
    setSuppliersMap,
+   buildingId,
  }: SupplierStepProps) {
    ...
    <SupplierInvoiceSheet
      isOpen={isInvoiceSheetOpen}
      onClose={handleCloseInvoiceSheet}
      onSave={handleSaveInvoice}
      initialData={editingInvoice}
      contactId={currentSupplier?.id || null}
+     buildingId={buildingId}
    />
```

**Change detail — SupplierInvoiceSheet.tsx**:

```diff
- import AccountingLedgerSelectV2 from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect';
+ import type { LedgerSelectOnChangeValue } from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectBase';

  interface SupplierInvoiceSheetProps {
    isOpen: boolean;
    onClose: () => void;
    onSave: (data: SupplierInvoice) => void;
    initialData?: SupplierInvoice | null;
    contactId: string | null;
+   buildingId: string;
  }

  // Update handler type signature:
  const handleLedgerChange = (
-   ledger: { id: string; name: string } | undefined,
+   ledger: LedgerSelectOnChangeValue | undefined,
  ) => {
    setValue('motherId', ledger?.id || '', { shouldValidate: true });
    setValue('motherName', ledger?.name || '', { shouldValidate: true });
  };

  // JSX (~line 266):
- <AccountingLedgerSelectV2
-   value={watch('motherId')}
-   onChange={handleLedgerChange}
- />
+ <BuildingLedgerSelect
+   buildingId={buildingId}
+   value={watch('motherId') ? { kind: 'id', id: watch('motherId') } : undefined}
+   onChange={handleLedgerChange}
+ />
```

Note: No `buildingId &&` guard needed — `buildingId` is a required `string` prop (always available from URL params via `FiscalYearSetupForm`). Uses `kind: 'id'` since only `motherId` (plain string) is stored in the form schema.

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| 2 levels of prop threading | LOW | `buildingId` is always a string from URL params via `FiscalYearSetupForm` |
| Supplier step rendered as JSX in step config | LOW | Confirm `buildingId` is in scope where `<SupplierStep>` is defined |

**Verification**:

```bash
cd sndq-fe && pnpm tsc --noEmit 2>&1 | head -30
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: thread buildingId to SupplierInvoiceSheet, use BuildingLedgerSelect`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Committed

---

### Commit 6: Replace in AddBuildingSupplierSheet (BLOCKED ON BE)

> **BLOCKED**: This commit requires a BE change to `LinkBuildingSupplierDto` to add `ledgerId` support. See [API compatibility report](./building-ledger-select-api-compatibility-report.md) section 2.1 and Recommended BE Feature Request #1.

**What**: Direct swap — `buildingId` is already a prop (string, required).

**API status**: `POST /buildings/:id/suppliers` and `PATCH /buildings/:id/suppliers/:supplierId` only accept `accountingMotherId`. **Does NOT support `ledgerId`**. BE must add `ledgerId` field to `LinkBuildingSupplierDto` and `UpdateBuildingSupplierDto` before this migration is safe.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/suppliers/AddBuildingSupplierSheet.tsx` — Replace import and JSX

**Change detail**:

```diff
- import AccountingLedgerSelectV2 from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect';

- <AccountingLedgerSelectV2
-   value={accountingMotherId}
-   onChange={(mother: { id: string } | undefined) =>
-     setValue('accountingMotherId', mother?.id)
-   }
- />
+ <BuildingLedgerSelect
+   buildingId={buildingId}
+   value={accountingMotherId ? { kind: 'id', id: accountingMotherId } : undefined}
+   onChange={(ledger) =>
+     setValue('accountingMotherId', ledger?.id)
+   }
+ />
```

`buildingId` is available as a prop on `AddBuildingSupplierSheetContent` (line 48, type `string`). No guard needed since it's required. Uses `kind: 'id'` since only the `accountingMotherId` string is stored in form state.

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| BE does not accept `ledgerId` | **HIGH** | Must wait for BE to add `ledgerId` to `LinkBuildingSupplierDto` |
| Options differ from mother-only list | LOW | Building options are a superset (includes ledgerIds); fallback resolves any existing motherId |

**Verification**:

```bash
cd sndq-fe && pnpm tsc --noEmit 2>&1 | head -30
```

**Deviations from the gate**:

- **No automated test for this component** — UI component; manual verification by opening the Add Building Supplier sheet.
- **Blocked on BE** — Do not execute until BE adds `ledgerId` support.

**Commit message**: `refactor: use BuildingLedgerSelect in AddBuildingSupplierSheet`

**Status**:

- [ ] BE change deployed (`LinkBuildingSupplierDto` supports `ledgerId`)
- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Committed

---

### Commit 7: Replace in SupplierFloatingSheetContent (BLOCKED ON BE)

> **BLOCKED**: This commit requires a BE change to `OpeningDataSetupSupplierInvoiceEntryDto` to add `ledgerId` support. See [API compatibility report](./building-ledger-select-api-compatibility-report.md) section 2.2 and Recommended BE Feature Request #2.

**What**: Thread `buildingId` from `SupplierFloatingSheetContent` to `InvoiceEntrySubSheetContent` (internal child component in same file), then swap the select.

**API status**: `PATCH /opening-data-setup/buildings/:id` only accepts `accountingMotherId`. **Does NOT support `ledgerId`**. BE must add `ledgerId` field to `OpeningDataSetupSupplierInvoiceEntryDto` before this migration is safe.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/opening-data-setup/sheets/SupplierFloatingSheetContent.tsx` — Replace import, thread `buildingId` to `InvoiceEntrySubSheetContent`, and swap JSX

**Change detail**:

```diff
- import AccountingLedgerSelectV2 from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '@/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect';
```

Thread `buildingId` to `InvoiceEntrySubSheetContent` (~line 208):
```diff
  <InvoiceEntrySubSheetContent
    defaultAmount={Math.abs(remaining)}
    accountingYearFromDate={firstYear?.fromDate}
    accountingYearToDate={firstYear?.toDate}
    initialData={editingIndex !== null ? invoiceEntries[editingIndex] : undefined}
    onSave={handleSaveInvoiceEntry}
    onClose={closeSubSheet}
+   buildingId={buildingId}
  />
```

Add `buildingId` prop to `InvoiceEntrySubSheetContent` (~line 582):
```diff
  function InvoiceEntrySubSheetContent({
    defaultAmount,
    accountingYearFromDate,
    accountingYearToDate,
    initialData,
    onSave,
    onClose,
+   buildingId,
  }: {
    defaultAmount: number;
    accountingYearFromDate?: string;
    accountingYearToDate?: string;
    initialData?: SupplierInvoiceEntryFormData;
    onSave: (entry: SupplierInvoiceEntryFormData) => void;
    onClose: () => void;
+   buildingId: string;
  })
```

Swap the select in `InvoiceEntrySubSheetContent` (~line 731):
```diff
  <Controller
    name="accountingMotherId"
    control={methods.control}
    render={({ field }) => (
      <FormField
        id="accountingMotherId"
        label={t('financial.cost_category')}
      >
-       <AccountingLedgerSelectV2
-         value={field.value}
-         onChange={(mother) => field.onChange(mother?.id ?? '')}
-         placeholder={t('general.select')}
-       />
+       <BuildingLedgerSelect
+         buildingId={buildingId}
+         value={field.value ? { kind: 'id', id: field.value } : undefined}
+         onChange={(ledger) => field.onChange(ledger?.id ?? '')}
+         placeholder={t('general.select')}
+       />
      </FormField>
    )}
  />
```

Note: `buildingId` is already a required prop on `SupplierFloatingSheetContent` (line 63, type `string`). The `InvoiceEntrySubSheetContent` is a private function component in the same file, so the threading is straightforward. Uses `kind: 'id'` since only `accountingMotherId` string is stored.

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| BE does not accept `ledgerId` | **HIGH** | Must wait for BE to add `ledgerId` to `OpeningDataSetupSupplierInvoiceEntryDto` |
| Same fallback pattern as other commits | LOW | Same fallback pattern |

**Verification**:

```bash
cd sndq-fe && pnpm tsc --noEmit 2>&1 | head -30
```

**Deviations from the gate**:

- **No automated test** — UI component in opening-data-setup; manual verification.
- **Blocked on BE** — Do not execute until BE adds `ledgerId` support.

**Commit message**: `refactor: use BuildingLedgerSelect in SupplierFloatingSheetContent`

**Status**:

- [ ] BE change deployed (`OpeningDataSetupSupplierInvoiceEntryDto` supports `ledgerId`)
- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feat/SQ-21333
```

**This validates**: All `AccountingLedgerSelectV2` usages have been replaced with `BuildingLedgerSelect` across the entire codebase.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Amounts allocation section — bulk and per-line ledger selects work
- [ ] Edit a ledger on an existing invoice (detail view) — selection displays correctly
- [ ] Edit a ledger on an existing invoice (floating sheet) — selection displays correctly
- [ ] Open a supplier invoice in fiscal year setup — ledger select works
- [ ] Open Add Building Supplier sheet — ledger select shows building-scoped options (only after BE change)
- [ ] Opening data setup supplier sheet — ledger select works (only after BE change)

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. Final Verification

After all 7 commits, run the full suite from the repository root:

```bash
cd sndq-fe && npx vitest run 2>&1 | tee /tmp/ledger-remaining-tests-final.txt
```

Compare against baselines:

```bash
diff /tmp/ledger-remaining-tests-before.txt /tmp/ledger-remaining-tests-final.txt
```

**Manual verification**:

- [ ] Amounts allocation section — all 3 views (bulk, by-VAT, individual) show correct selection
- [ ] Invoice detail (both sheet and floating variants) — edit ledger works
- [ ] Fiscal year setup — supplier invoice sheet shows correct ledger options
- [ ] Add building supplier — ledger select works with building-scoped options (only after BE change)
- [ ] Opening data setup supplier sheet — ledger select works (only after BE change)
- [ ] No `AccountingLedgerSelectV2` imports remain in codebase (verify with grep)

**Expected result**: All tests pass. Zero remaining `AccountingLedgerSelectV2` imports. All cost-category selectors use building-scoped options with mother-options fallback.

**Final status**:

- [ ] All 7 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Tests pass or missing coverage is documented
- [ ] Manual verification complete
- [ ] PR created and merged, or ready for merge

---

## 5. Team Communication

Send to the team before merging:

> **Heads up: AccountingLedgerSelectV2 fully replaced by BuildingLedgerSelect**
>
> PR [link] completes the migration of all cost-category selectors to use building-scoped options with fallback to mother options. After pulling:
>
> 1. Run `pnpm install` (no new deps, but good practice)
> 2. Test editing invoices, adding suppliers, and fiscal year setup — all cost category selects should work
>
> Files that changed and may conflict:
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/AmountsAllocationSection.tsx`
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/CostSelector.tsx`
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/AllocationCostsSection.tsx`
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx`
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/PurchaseInvoiceCostAllocation.tsx`
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx`
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoiceDetailFloatingSheet.tsx`
> - `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoicePreviewFloatingSheetContent.tsx`
> - `sndq-fe/src/modules/financial/forms/fiscal-year-setup/FiscalYearSetupForm.tsx`
> - `sndq-fe/src/modules/financial/forms/fiscal-year-setup/steps/SupplierStep.tsx`
> - `sndq-fe/src/modules/financial/forms/fiscal-year-setup/components/SupplierInvoiceSheet.tsx`
> - `sndq-fe/src/modules/financial/components/suppliers/AddBuildingSupplierSheet.tsx` (after BE change)
> - `sndq-fe/src/modules/financial/forms/opening-data-setup/sheets/SupplierFloatingSheetContent.tsx` (after BE change)
>
> Known deviations or follow-ups:
> - `AccountingLedgerSelectV2.tsx` can be deleted in a cleanup commit (zero imports remain)
> - Commits 6-7 are blocked on BE API changes (see API compatibility report)

---

## 6. What's Next

After this migration is merged, `AccountingLedgerSelectV2` has zero consumers and can be deleted in a cleanup commit. The building-scoped ledger selection with mother-options fallback is now the standard pattern across the entire codebase.

### Lessons to carry forward

- The `useMotherLedgerOptions` fallback with `needsMotherFallback` gate pattern works reliably for all existing data
- Threading `buildingId` from parent components is straightforward when the parent already has it — the challenge is identifying where it lives
- The discriminated union value type (`BuildingLedgerSelectValue`) cleanly separates two usage patterns:
  - `{ kind: 'id', id }` — for consumers that only store a plain string ID (triggers `useMotherLedgerOptions` fallback if not found in building options)
  - `{ kind: 'full', id, type, code?, name?, parentMotherName? }` — for consumers with rich `CostAccountData` or `LedgerSelectOnChangeValue` (creates inline fallback option without an API call)
- The `kind` discriminator prevents ambiguity: previously it was unclear whether a plain string was a ledger ID, mother ID, or something else

### Known lessons from prior phases

- `BuildingLedgerSelect` needs `buildingId &&` guard whenever `buildingId` can be `null | undefined`
- The `needsMotherFallback` flag prevents unnecessary API calls when building options already contain the match
- When converting `LedgerSelectOnChangeValue` (from `buildSelectedLedger`) to `BuildingLedgerSelectValue`, spread with `kind: 'full'`: `selectedLedger ? { kind: 'full', ...selectedLedger } : undefined`

---

## Execution Log

| Date | Commit | Notes |
|------|--------|-------|
| 2026-05-16 | 1 | Done. Replaced 3 usages in AmountsAllocationSection. No new TS errors (pre-existing `motherId` errors from costAccount refactor). |
| 2026-05-16 | 2 | Done. Threaded buildingId to CostSelector, replaced AccountingLedgerSelectV2 with BuildingLedgerSelect. Zero new TS errors. |
| 2026-05-16 | 3 | Done. Threaded buildingId to EditLedgerSheet, replaced AccountingLedgerSelectV2 with BuildingLedgerSelect. Zero new TS errors. |
| 2026-05-16 | 4 | Done. Threaded buildingId to EditLedgerFloatingSheetContent from 2 parents, replaced AccountingLedgerSelectV2 with BuildingLedgerSelect. Zero new TS errors. |
| | 5 | |
| | 6 | BLOCKED on BE — waiting for `LinkBuildingSupplierDto` to add `ledgerId` support |
| | 7 | BLOCKED on BE — waiting for `OpeningDataSetupSupplierInvoiceEntryDto` to add `ledgerId` support |
