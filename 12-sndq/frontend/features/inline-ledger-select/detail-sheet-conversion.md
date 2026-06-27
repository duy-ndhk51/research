# Detail-Sheet Conversion Execution — InlineLedgerSelect 7xx Loading + Credit-Note Conversion

Step-by-step execution guide for wiring 7xx ledger options and credit-note conversion into the three detail-sheet callsites. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-25
**Status**: Not started
**Branch**: `feature/inline-ledger-detail-sheet-conversion`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — 7xx options loading + credit-note conversion wiring](#3-pr-1--7xx-options-loading--credit-note-conversion-wiring)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Ensure all three detail-sheet `InlineLedgerSelect` callsites load Revenue (7xx) ledger options and support credit-note conversion when a 7xx ledger is selected on a non-credit-note invoice.

**Structure**: 4 commits across 1 PR.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | 7xx options + credit-note conversion for all 3 callsites | Medium | 1–4 |

**Why 1 PR**: All changes are tightly coupled — 7xx options must load (commit 1) before conversion can work (commits 2–4). Splitting into separate PRs would leave broken intermediate states.

### Prerequisites

- `InlineLedgerSelect` already swapped into all 3 callsites (done in prior work)
- `usePurchaseInvoiceLedgerOptions` hook exists and pre-fetches both 6xx + 7xx options
- `useUpdatePurchaseInvoice` mutation exists and accepts `Partial<CreatePurchaseInvoiceData>` including `invoiceTypeCode`
- `shouldBulkUpdateCostAccount` utility exists in `useCreditNoteConversion.ts` for identifying 6xx costs

### Known constraints

- `CostSelector` has early returns before JSX — React hooks cannot be called after early returns, so `usePurchaseInvoiceLedgerOptions` must be called in the parent (`AllocationCostsSection`) and passed down
- `EditLedgerFloatingSheetContent` and `EditLedgerSheet` only receive a single `AllocationCost`, not the full list — conversion (which bulk-updates ALL 6xx costs) must be delegated to the parent component
- `useAllocationCostsForm.save()` only calls `useUpdateAllocations` — it does not update `invoiceTypeCode`. The type change requires a separate `useUpdatePurchaseInvoice` call
- `PurchaseInvoiceCostAllocation` (parent of `EditLedgerSheet`) currently receives `data: AllocationCost[]` but NOT the invoice ID or type — new props are needed

### Conversion strategy: hybrid immediate/wait-save

When conversion is confirmed:
1. **Invoice type change** → immediate API call via `useUpdatePurchaseInvoice({ invoiceTypeCode: CREDIT_NOTE })` (confirmed by user, minimal risk)
2. **Bulk 6xx→7xx ledger update** → local state change in `allocationCostsForm`, user sees changes in `AllocationCostsSection` and can review/save via existing Save flow

This avoids complex Save handler rewrites while keeping the bulk ledger change reviewable before persisting.

For `EditLedgerFloatingSheetContent` / `EditLedgerSheet`: on conversion confirm, delegate to parent callback which handles both (1) and (2), then closes the sheet.

For `CostSelector` (inside `AllocationCostsSection`): on conversion confirm, `AllocationCostsSection` handles (1) via direct mutation and (2) via `updateLedger` on local state. User sees dirty state and clicks Save.

---

## 2. Before You Start

### Quality gate before each implementation commit

Use this gate for every implementation commit. If an item is intentionally skipped, record it under that commit's **Deviations from the gate** section.

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
- Add deprecation notices only on the public export or entry point that consumers actually use.
- If docs and code disagree, update the docs in the same commit or record the gap as a deviation.

### Inspect source tree before implementation

Before the first implementation commit, inspect the actual repository state and record any differences from this plan.

- [ ] Confirm `InlineLedgerSelect` is already used in all 3 callsites (prior swap is merged)
- [ ] Confirm `usePurchaseInvoiceLedgerOptions` exists at `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/hooks/usePurchaseInvoiceLedgerOptions.ts`
- [ ] Confirm `shouldBulkUpdateCostAccount` is exported from `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/hooks/useCreditNoteConversion.ts`
- [ ] Confirm `useUpdatePurchaseInvoice` is exported from `sndq-fe/src/hooks/financial/usePurchaseInvoices.ts`
- [ ] Confirm `PurchaseInvoiceDetailFloatingSheet` has access to the full `invoice` object and `allocationCostsForm`
- [ ] Confirm `PurchaseInvoiceCostAllocation` receives `data: AllocationCost[]`, `currency`, `buildingId` — and currently does NOT receive `invoiceId` or `invoiceTypeCode`

### Capture baselines

```bash
cd sndq-fe
pnpm run type-check 2>&1 | tee /tmp/detail-conversion-typecheck-before.txt
pnpm exec eslint --quiet src/modules/financial/components/invoices/purchase-invoice/ 2>&1 | tee /tmp/detail-conversion-lint-before.txt
```

### Create branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/inline-ledger-detail-sheet-conversion
```

---

## 3. PR 1 — 7xx options loading + credit-note conversion wiring

This PR adds Revenue (7xx) ledger options loading and credit-note conversion dialog to all 3 detail-sheet InlineLedgerSelect callsites.

---

### Commit 1: Load 7xx options via externalOptions for all 3 callsites

**What**: Add `usePurchaseInvoiceLedgerOptions` to pre-fetch both 6xx + 7xx options and pass them as `externalOptions` to `InlineLedgerSelect`. This fixes the empty Revenue tab.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx` — add `usePurchaseInvoiceLedgerOptions` hook call, pass `externalOptions` + `isLoadingExternalOptions` to `InlineLedgerSelect`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx` — same change
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/AllocationCostsSection.tsx` — add `usePurchaseInvoiceLedgerOptions` hook call, pass options down to `CostSelector` via new props
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/CostSelector.tsx` — accept new `externalOptions` + `isLoadingExternalOptions` props, pass to `InlineLedgerSelect`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/types.ts` — add optional `externalOptions` + `isLoadingExternalOptions` to `AllocationCostsSectionProps`

**Implementation details**:

For `EditLedgerFloatingSheetContent` and `EditLedgerSheet`:

```typescript
import { usePurchaseInvoiceLedgerOptions } from '@/modules/financial/forms/purchase-invoice-v3/hooks/usePurchaseInvoiceLedgerOptions';

// Inside component:
const { ledgerOptions, isLoadingLedgerOptions } = usePurchaseInvoiceLedgerOptions({ buildingId });

<InlineLedgerSelect
  buildingId={buildingId}
  value={...}
  onChange={handleLedgerChange}
  externalOptions={ledgerOptions}
  isLoadingExternalOptions={isLoadingLedgerOptions}
/>
```

For `CostSelector`, hooks cannot be called after early returns. Call `usePurchaseInvoiceLedgerOptions` in `AllocationCostsSection` instead:

```typescript
// AllocationCostsSection.tsx
const { ledgerOptions, isLoadingLedgerOptions } = usePurchaseInvoiceLedgerOptions({ buildingId });

<CostSelector
  ...existing props...
  externalOptions={ledgerOptions}
  isLoadingExternalOptions={isLoadingLedgerOptions}
/>

// CostSelector.tsx — accept and forward:
<InlineLedgerSelect
  ...existing props...
  externalOptions={externalOptions}
  isLoadingExternalOptions={isLoadingExternalOptions}
/>
```

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `usePurchaseInvoiceLedgerOptions` called with `undefined` buildingId | LOW | Hook handles `undefined` buildingId internally — disables fetch. All 3 callsites already guard with `buildingId &&` |
| Double fetching in AllocationCostsSection (hook + InlineLedgerSelect internal) | LOW | When `externalOptions` is passed, `useBuildingLedgerSelectOptions` skips the internal fetch (`enabled && !externalOptions`) |

**Verification**:

```bash
cd sndq-fe
pnpm exec eslint --fix \
  src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx \
  src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx \
  src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/AllocationCostsSection.tsx \
  src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/CostSelector.tsx
pnpm run type-check
```

Manual smoke:
- Open a saved purchase invoice detail sheet
- Click edit ledger on a cost line → open popover → click Revenue tab → verify 7xx options load
- Same check for CostSelector (group by VAT → select a cost group → open ledger popover → Revenue tab)

**If it fails**:

- **"Revenue tab still empty"**: Check that `usePurchaseInvoiceLedgerOptions` returns non-empty `ledgerOptions`. Verify the building has 7xx mothers configured. Check network tab for the API call with `motherCode=7`.

**Deviations from the gate**:

- **None**

**Commit message**: `feat: load 7xx options via externalOptions in detail-sheet callsites`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 2: Pass invoice mode to InlineLedgerSelect

**What**: Derive `InvoiceFormMode` from the invoice's type/typeCode and pass it as `mode` prop to `InlineLedgerSelect` in all 3 callsites. This ensures the conversion dialog is suppressed when the invoice is already a credit note, and defaults the tab correctly.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx` — accept `invoiceTypeCode` prop, derive mode, pass to `InlineLedgerSelect`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx` — same
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/AllocationCostsSection.tsx` — accept `invoiceTypeCode` prop, pass to `CostSelector`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/CostSelector.tsx` — accept `invoiceTypeCode` prop, derive mode, pass to `InlineLedgerSelect`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/types.ts` — add optional `invoiceTypeCode` to `AllocationCostsSectionProps`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoiceDetailFloatingSheet.tsx` — pass `invoice.invoiceTypeCode` to `EditLedgerFloatingSheetContent` and `AllocationCostsSection`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/PurchaseInvoiceDetail.tsx` — pass `invoice.invoiceTypeCode` to `PurchaseInvoiceCostAllocation`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/PurchaseInvoiceCostAllocation.tsx` — accept `invoiceTypeCode` prop, pass to `EditLedgerSheet`

**Implementation details**:

Derive mode from `invoiceTypeCode`:

```typescript
import { InvoiceTypeCode } from '@/common/constants/invoiceTypeCode';
import type { InvoiceFormMode } from '@/modules/financial/forms/purchase-invoice-v3/types';

const mode: InvoiceFormMode = invoiceTypeCode === InvoiceTypeCode.CREDIT_NOTE ? 'credit_note' : 'invoice';
```

Then pass to `InlineLedgerSelect`:

```typescript
<InlineLedgerSelect
  ...existing props...
  mode={mode}
/>
```

When `mode === 'credit_note'`, `InlineLedgerSelect`:
- Defaults to the Revenue tab (via `getDefaultLedgerTab`)
- Does NOT show the conversion dialog (the `handleSelect` guard checks `mode !== 'credit_note'`)

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `invoiceTypeCode` is `null` or non-standard string | LOW | Mode defaults to `'invoice'`, which is the correct fallback (shows conversion dialog on 7xx) |
| Prop threading through 3 layers for CostSelector | LOW | Mechanical — just pass the string through |

**Verification**:

```bash
cd sndq-fe
pnpm run type-check
```

Manual smoke:
- Open a credit-note invoice detail sheet → edit ledger → verify Revenue tab is default, NO conversion dialog when picking 7xx
- Open a regular invoice detail sheet → edit ledger → verify Expenses tab is default

**If it fails**:

- **"Conversion dialog shows on credit note invoice"**: Check that `invoiceTypeCode` is correctly passed through the prop chain. Log `mode` inside `InlineLedgerSelect` to verify.

**Deviations from the gate**:

- **None**

**Commit message**: `feat: pass invoice mode to InlineLedgerSelect in detail sheets`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 3: Wire credit-note conversion for AllocationCostsSection / CostSelector

**What**: When a user selects a 7xx ledger in `CostSelector` on a non-credit-note invoice, show the conversion dialog. On confirm: (1) immediately call `useUpdatePurchaseInvoice` to change the invoice type, (2) bulk-update all 6xx local amounts to the selected 7xx via `updateLedger`, and (3) user reviews dirty state and clicks Save to persist ledger changes.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/AllocationCostsSection.tsx` — add conversion handler, pass `onCreditNoteConversion` to `CostSelector`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/CostSelector.tsx` — accept and forward `onCreditNoteConversion` to `InlineLedgerSelect`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/types.ts` — add `invoiceId` and `onCreditNoteConversion` to props
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoiceDetailFloatingSheet.tsx` — pass `invoice.id` to `AllocationCostsSection`

**Implementation details**:

In `AllocationCostsSection`:

```typescript
import { useUpdatePurchaseInvoice } from '@/hooks/financial/usePurchaseInvoices';
import { InvoiceTypeCode } from '@/common/constants/invoiceTypeCode';
import { shouldBulkUpdateCostAccount } from '@/modules/financial/forms/purchase-invoice-v3/hooks/useCreditNoteConversion';

const { mutate: updateInvoiceType } = useUpdatePurchaseInvoice();

const handleCreditNoteConversion = useCallback(
  (selectedLedger: LedgerSelectOnChangeValue) => {
    if (!invoiceId) return;

    // 1. Immediately update invoice type
    updateInvoiceType({
      purchaseInvoiceId: invoiceId,
      apiData: { invoiceTypeCode: InvoiceTypeCode.CREDIT_NOTE },
    });

    // 2. Bulk-update all 6xx costs to the selected 7xx in local state
    const costIdsToUpdate = amounts
      .filter((a) => shouldBulkUpdateCostAccount(a.costAccount))
      .map((a) => a.id);

    if (costIdsToUpdate.length > 0) {
      onUpdateLedger(costIdsToUpdate, {
        id: selectedLedger.id,
        type: selectedLedger.type,
        name: selectedLedger.name,
        code: selectedLedger.code,
        parentMotherName: selectedLedger.parentMotherName,
      });
    }
  },
  [invoiceId, amounts, onUpdateLedger, updateInvoiceType],
);
```

Then pass to `CostSelector`:

```typescript
<CostSelector
  ...existing props...
  onCreditNoteConversion={
    mode !== 'credit_note' ? handleCreditNoteConversion : undefined
  }
/>
```

In `CostSelector`, forward to `InlineLedgerSelect`:

```typescript
<InlineLedgerSelect
  ...existing props...
  mode={mode}
  onCreditNoteConversion={onCreditNoteConversion}
/>
```

**Key behavior**: `InlineLedgerSelect` already has the conversion dialog built in. When `onCreditNoteConversion` is provided and `mode !== 'credit_note'`, selecting a 7xx ledger shows the dialog. On confirm, it calls `onCreditNoteConversion(ledger)` then `onChange(ledger)`.

After conversion:
- `invoiceTypeCode` is already updated on the server
- Local amounts show the 7xx ledger on all previously-6xx costs
- `hasChanges` is `true` in `AllocationCostsSection`
- User reviews and clicks Save to persist ledger changes via `useUpdateAllocations`

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `useUpdatePurchaseInvoice` fails but local state already updated | MEDIUM | The mutation's `onError` handler shows a toast. Local state will be dirty but user can reset. On next refetch, invoice data re-syncs. Consider adding `onError` rollback if needed. |
| `shouldBulkUpdateCostAccount` filters unexpectedly | LOW | Function only skips costs with codes starting with `'7'` — all others (6xx, no code, no costAccount) are included. This matches form behavior. |
| Conversion triggered on steward mode | LOW | `CostSelector` returns `<CostCategorySelect>` when `mode === 'steward'` — `InlineLedgerSelect` is never rendered, so conversion cannot trigger. |

**Verification**:

```bash
cd sndq-fe
pnpm run type-check
```

Manual smoke:
- Open a regular (non-credit-note) invoice detail sheet → AllocationCostsSection → group by VAT
- In a cost group, open the ledger popover → Revenue tab → select a 7xx ledger
- Verify conversion dialog appears → click Confirm
- Verify all cost groups now show the 7xx ledger
- Verify Save button is active → click Save → verify API calls succeed
- Reopen the invoice → verify `invoiceTypeCode` is now credit note

**If it fails**:

- **"Conversion dialog doesn't appear"**: Verify `mode` is not `'credit_note'` and `onCreditNoteConversion` is provided. Check `InlineLedgerSelect`'s `handleSelect` guard logic.
- **"Only one cost group updated, not all"**: Check that `shouldBulkUpdateCostAccount` correctly identifies all 6xx costs. Log `costIdsToUpdate`.

**Deviations from the gate**:

- **No rollback on `useUpdatePurchaseInvoice` failure** — acceptable for now; the user sees an error toast and can manually reset. The invoice type change alone is safe (does not corrupt data).

**Commit message**: `feat: wire credit-note conversion for CostSelector in AllocationCostsSection`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 4: Wire credit-note conversion for EditLedgerFloatingSheetContent and EditLedgerSheet

**What**: When a user selects a 7xx ledger in the edit-ledger sheet on a non-credit-note invoice, show the conversion dialog. On confirm: delegate to parent callback which (1) updates invoice type and (2) bulk-updates all 6xx allocation costs.

**Files to edit**:

- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx` — accept `invoiceId`, `onConvertToCreditNote` props; pass `mode` and `onCreditNoteConversion` to `InlineLedgerSelect`; on conversion confirm, call parent callback + close sheet
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx` — same changes
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoiceDetailFloatingSheet.tsx` — create conversion handler using `useUpdatePurchaseInvoice` + `allocationCostsForm.updateLedger`; pass to `EditLedgerFloatingSheetContent`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/PurchaseInvoiceCostAllocation.tsx` — accept `invoiceId`, `invoiceTypeCode` props; create conversion handler; pass to `EditLedgerSheet`
- `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/PurchaseInvoiceDetail.tsx` — pass `invoice.id` and `invoice.invoiceTypeCode` to `PurchaseInvoiceCostAllocation`

**Implementation details**:

In `EditLedgerFloatingSheetContent` and `EditLedgerSheet`, add props and wiring:

```typescript
interface EditLedgerFloatingSheetContentProps {
  onClose: () => void;
  allocationCost: AllocationCost | null;
  currency?: string;
  buildingId?: string;
  invoiceTypeCode?: string | null;  // NEW
  onConvertToCreditNote?: (selectedLedger: LedgerSelectOnChangeValue) => void;  // NEW
}

// Inside component:
const mode: InvoiceFormMode = invoiceTypeCode === InvoiceTypeCode.CREDIT_NOTE ? 'credit_note' : 'invoice';

const handleCreditNoteConversion = useCallback(
  (selectedLedger: LedgerSelectOnChangeValue) => {
    onConvertToCreditNote?.(selectedLedger);
    onClose();
  },
  [onConvertToCreditNote, onClose],
);

<InlineLedgerSelect
  ...existing props...
  mode={mode}
  onCreditNoteConversion={onConvertToCreditNote ? handleCreditNoteConversion : undefined}
/>
```

In `PurchaseInvoiceDetailFloatingSheet`, create the conversion handler:

```typescript
import { shouldBulkUpdateCostAccount } from '@/modules/financial/forms/purchase-invoice-v3/hooks/useCreditNoteConversion';

const { mutate: updateInvoiceType } = useUpdatePurchaseInvoice();

const handleConvertToCreditNote = useCallback(
  (selectedLedger: LedgerSelectOnChangeValue) => {
    // 1. Update invoice type immediately
    updateInvoiceType({
      purchaseInvoiceId: invoice.id,
      apiData: { invoiceTypeCode: InvoiceTypeCode.CREDIT_NOTE },
    });

    // 2. Bulk-update all 6xx costs in local state
    const costIdsToUpdate = allocationCostsForm.amounts
      .filter((a) => shouldBulkUpdateCostAccount(a.costAccount))
      .map((a) => a.id);

    if (costIdsToUpdate.length > 0) {
      allocationCostsForm.updateLedger(costIdsToUpdate, selectedLedger);
    }

    // 3. Close the edit sheet
    setEditLedgerCost(null);
  },
  [invoice.id, allocationCostsForm, updateInvoiceType],
);

// Pass to EditLedgerFloatingSheetContent:
<EditLedgerFloatingSheetContent
  ...existing props...
  invoiceTypeCode={invoice.invoiceTypeCode}
  onConvertToCreditNote={handleConvertToCreditNote}
/>
```

For `PurchaseInvoiceCostAllocation` (parent of `EditLedgerSheet`), a similar handler is needed. However, this component does NOT have `useAllocationCostsForm` — it uses individual `useUpdateAllocationCostLedger` calls. The conversion handler here needs to:

1. Call `useUpdatePurchaseInvoice` for the type change
2. Call `useUpdateAllocationCostLedger` for each 6xx cost (using the `data` prop which has all allocation costs)

```typescript
import { useUpdatePurchaseInvoice, useUpdateAllocationCostLedger } from '@/hooks/financial/usePurchaseInvoices';
import { shouldBulkUpdateCostAccount } from '@/modules/financial/forms/purchase-invoice-v3/hooks/useCreditNoteConversion';

const { mutate: updateInvoiceType } = useUpdatePurchaseInvoice();
const { mutate: updateCostLedger } = useUpdateAllocationCostLedger();

const handleConvertToCreditNote = useCallback(
  (selectedLedger: LedgerSelectOnChangeValue) => {
    if (!invoiceId) return;

    // 1. Update invoice type
    updateInvoiceType({
      purchaseInvoiceId: invoiceId,
      apiData: { invoiceTypeCode: InvoiceTypeCode.CREDIT_NOTE },
    });

    // 2. Update each 6xx cost
    const costsToUpdate = data.filter((cost) =>
      shouldBulkUpdateCostAccount(cost.costAccount ? {
        id: cost.costAccount.id,
        type: cost.costAccount.type,
        code: cost.costAccount.code,
        name: cost.costAccount.name,
      } : undefined),
    );

    costsToUpdate.forEach((cost) => {
      updateCostLedger({
        allocationCostId: cost.id,
        purchaseInvoiceId: cost.purchaseInvoiceId,
        ...(selectedLedger.type === CostAccountType.LEDGER
          ? { ledgerId: selectedLedger.id }
          : { motherId: selectedLedger.id }),
      });
    });

    setEditLedgerSheetOpen(false);
  },
  [invoiceId, data, updateInvoiceType, updateCostLedger],
);
```

> **Note**: The `PurchaseInvoiceCostAllocation` handler issues multiple individual mutation calls. This is less atomic than the `AllocationCostsSection` approach but matches the existing pattern in that component. The `AllocationCost.costAccount` shape may differ from `CostAccountData` — verify the `shouldBulkUpdateCostAccount` argument mapping matches.

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Multiple `useUpdateAllocationCostLedger` calls in `PurchaseInvoiceCostAllocation` — partial failure | MEDIUM | If some calls fail, the invoice is in an inconsistent state. The error toast will show. User can retry by editing individual costs. Consider batching via `useUpdateAllocations` if the component has access to the required data shape. |
| `allocationCostsForm.updateLedger` called from outside `AllocationCostsSection` | LOW | The function is stable (uses functional setState), no side effects. Safe to call from the parent. |
| Edit sheet closes on conversion but dirty state appears in AllocationCostsSection | LOW | This is intentional — user reviews bulk changes and clicks Save. The UX shift is expected. |

**Verification**:

```bash
cd sndq-fe
pnpm run type-check
pnpm exec eslint --fix \
  src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx \
  src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx \
  src/modules/financial/components/invoices/purchase-invoice/PurchaseInvoiceDetailFloatingSheet.tsx \
  src/modules/financial/components/invoices/purchase-invoice/detail/components/PurchaseInvoiceCostAllocation.tsx \
  src/modules/financial/components/invoices/purchase-invoice/detail/PurchaseInvoiceDetail.tsx
```

Manual smoke (floating sheet path):
- Open a regular invoice in the floating detail sheet
- Click edit ledger on a cost line → Revenue tab → select 7xx
- Verify conversion dialog → Confirm → sheet closes
- Verify AllocationCostsSection shows all costs with the 7xx ledger
- Verify Save button is active → Save → API calls succeed

Manual smoke (detail page path):
- Open a regular invoice on the detail page
- Click edit ledger on a cost line → Revenue tab → select 7xx
- Verify conversion dialog → Confirm → sheet closes
- Verify all costs now show the 7xx ledger (page refreshes via cache invalidation)

**If it fails**:

- **"Sheet doesn't close after conversion"**: Verify `onClose()` / `setEditLedgerSheetOpen(false)` is called in the conversion handler.
- **"Costs not updated in AllocationCostsSection after conversion"**: Verify `allocationCostsForm.updateLedger` is called with the correct cost IDs. Check that `shouldBulkUpdateCostAccount` returns the expected costs.
- **"`PurchaseInvoiceCostAllocation` handler — costs not updated"**: Check network tab for individual `useUpdateAllocationCostLedger` calls. Verify `cost.costAccount` shape matches what `shouldBulkUpdateCostAccount` expects.

**Deviations from the gate**:

- **`PurchaseInvoiceCostAllocation` uses N individual mutations instead of batch** — acceptable because this component doesn't have `useAllocationCostsForm` and the number of costs is typically small (< 10). A batch approach would require restructuring the component, which is out of scope.

**Commit message**: `feat: wire credit-note conversion for edit-ledger sheets`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feature/inline-ledger-detail-sheet-conversion
# Create PR targeting develop
# Wait for CI to complete successfully
```

**This validates**: Type-check, lint, and build pass with all 4 commits. No regressions in existing functionality.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Risky behavior has a manual smoke test result
- [ ] Rollback instructions are clear

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. Final Verification

After all 4 commits, run the full suite from the repository root:

```bash
cd sndq-fe
pnpm run type-check
pnpm exec eslint --quiet src/modules/financial/components/invoices/purchase-invoice/
pnpm run build
```

Compare against baselines:

```bash
diff /tmp/detail-conversion-typecheck-before.txt <(cd sndq-fe && pnpm run type-check 2>&1)
diff /tmp/detail-conversion-lint-before.txt <(cd sndq-fe && pnpm exec eslint --quiet src/modules/financial/components/invoices/purchase-invoice/ 2>&1)
```

**Manual verification**:

- [ ] Regular invoice → floating sheet → edit ledger → Revenue tab shows 7xx options
- [ ] Regular invoice → floating sheet → select 7xx → conversion dialog → confirm → all costs updated → Save succeeds
- [ ] Regular invoice → detail page → edit ledger → Revenue tab shows 7xx → conversion → costs updated
- [ ] Regular invoice → AllocationCostsSection → CostSelector → select 7xx → conversion → bulk update → Save
- [ ] Credit-note invoice → edit ledger → NO conversion dialog → 7xx selectable without dialog
- [ ] Credit-note invoice → default tab is Revenue
- [ ] Steward mode → CostCategorySelect renders (no InlineLedgerSelect) → no conversion possible

**Expected result**: All 3 detail-sheet callsites load 7xx options in the Revenue tab and show the credit-note conversion dialog when appropriate. Conversion updates the invoice type and bulk-changes 6xx costs to the selected 7xx ledger.

**Final status**:

- [ ] All 4 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes
- [ ] Manual verification complete
- [ ] PR created and merged, or ready for merge

---

## 5. Team Communication

Send to the team before merging:

> **Heads up: Credit-note conversion now available in detail sheets**
>
> PR [link] adds Revenue (7xx) ledger options and credit-note conversion to the purchase invoice detail sheets (floating sheet, detail page, and bulk selector). After pulling:
>
> 1. Run `pnpm install` (no new deps, but lockfile may change)
> 2. Restart dev server.
>
> Files that changed and may conflict:
> - `detail-sheet/EditLedgerFloatingSheetContent.tsx`
> - `detail/components/EditLedgerSheet.tsx`
> - `detail-sheet/allocation-costs/AllocationCostsSection.tsx`
> - `detail-sheet/allocation-costs/CostSelector.tsx`
> - `detail-sheet/allocation-costs/types.ts`
> - `PurchaseInvoiceDetailFloatingSheet.tsx`
> - `detail/PurchaseInvoiceDetail.tsx`
> - `detail/components/PurchaseInvoiceCostAllocation.tsx`
>
> Known deviations or follow-ups:
> - `PurchaseInvoiceCostAllocation` uses N individual mutations for bulk ledger update (not batched)
> - No rollback on `useUpdatePurchaseInvoice` failure — user sees error toast and can retry

---

## 6. What's Next

After this PR is merged:

- Monitor for edge cases with partial mutation failures
- Consider adding `useUpdateAllocations` batch support to `PurchaseInvoiceCostAllocation` if N-mutation approach causes issues
- Consider adding a loading/progress indicator during bulk conversion

### Lessons to carry forward

- When swapping a component that only showed one data set (6xx) with one that shows tabs (6xx + 7xx), always ensure both data sets are pre-fetched via `externalOptions`
- Credit-note conversion in detail sheets requires fundamentally different wiring than in forms — forms use local state + single save; detail sheets need immediate API calls + local state sync

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
| | 2 | |
| | 3 | |
| | 4 | |
