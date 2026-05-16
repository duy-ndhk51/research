# BuildingLedgerSelect Fallback + V2 Form Migration Execution

Step-by-step execution guide for adding mother-options fallback to `BuildingLedgerSelect` and replacing `AccountingLedgerSelectV2` in purchase invoice v2/v3 forms. Each commit should be independently verifiable and revertable.

**Created**: 2026-05-15
**Status**: Implementation complete, pending commit + manual verification
**Branch**: `feat/SQ-21333` (continue from costAccount refactor)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — BuildingLedgerSelect Fallback + V2 Form Migration](#3-pr-1--buildingledgerselect-fallback--v2-form-migration)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Make `BuildingLedgerSelect` resilient to motherId/ledgerId mismatches by adding a `useMotherLedgerOptions` fallback, then replace all `AccountingLedgerSelectV2` usages within the purchase invoice forms with the improved `BuildingLedgerSelect`.

**Structure**: 4 commits across 1 PR.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Fallback logic + v2/v3 form migration | Medium | 1-4 |

**Why 1 PR**: All changes are tightly coupled -- the fallback logic only matters when callers switch from `AccountingLedgerSelectV2` to `BuildingLedgerSelect`.

### Prerequisites

- costAccount grouping refactor is complete and tests passing (771/771)
- Draft schema V4 migration is in place
- Current `BuildingLedgerSelect` has `selectedCostAccount` prop (from prior commit)

### Known constraints

- `AccountingLedgerSelectV2` usages outside purchase-invoice forms (6 call sites in suppliers, allocation section, edit ledger sheets, fiscal year setup) are NOT in scope -- they will be migrated separately
- `useMotherLedgerOptions` relies on `useAccountingMothers` which is workspace-scoped (not building-scoped) -- it's always available as a fallback source
- Some v2 components receive `buildingId: string | null` -- must guard with `buildingId &&` before rendering `BuildingLedgerSelect`

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

- [ ] Confirm files and folders in **Files to create**, **Files to edit**, and **Files to delete** are accurate
- [ ] Confirm current lint, type-check, build, or test failures that predate this phase
- [ ] Confirm existing exports and public entry points before changing them
- [ ] Confirm whether dependencies or lockfiles will change

### Capture baselines

```bash
cd sndq-fe && npx vitest run src/modules/financial/forms/purchase-invoice-v2 src/modules/financial/forms/purchase-invoice-v3 2>&1 | tee /tmp/ledger-fallback-tests-before.txt
```

---

## 3. PR 1 — BuildingLedgerSelect Fallback + V2 Form Migration

Adds `useMotherLedgerOptions` as a secondary fallback in `BuildingLedgerSelect`, then replaces `AccountingLedgerSelectV2` with `BuildingLedgerSelect` in all 4 purchase-invoice form call sites.

---

### Commit 1: Add useMotherLedgerOptions fallback to BuildingLedgerSelect

**What**: Enhance the options-merging logic to use `useMotherLedgerOptions` as a secondary fallback when `selectedCostAccount` is not provided and the value doesn't match any building option. Also remove debug `console.log` statements.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect.tsx` — Add `useMotherLedgerOptions` import, update `useMemo` fallback chain, remove console.log debug lines

**Implementation detail**:

The fallback priority in the `useMemo`:

1. Value found in building options — use as-is
2. `selectedCostAccount` provided — construct option from it (no query needed)
3. Neither — look up value in `useMotherLedgerOptions` data (already cached)

```typescript
const { data: motherOptions } = useMotherLedgerOptions({
  motherCode,
  enabled: !!value,
});

const options = useMemo((): AccountingLedgerOption[] => {
  const baseOptions = data ?? [];
  if (!value || isLoading) return baseOptions;
  if (baseOptions.some((opt) => opt.id === value)) return baseOptions;

  // Priority 1: construct from selectedCostAccount prop
  if (selectedCostAccount) {
    const fallback: AccountingLedgerOption = {
      id: selectedCostAccount.id,
      type: selectedCostAccount.type,
      displayCode: selectedCostAccount.code || '',
      code: selectedCostAccount.code || '',
      name: selectedCostAccount.name || '',
      parentMotherName: selectedCostAccount.parentMotherName,
    };
    return [fallback, ...baseOptions];
  }

  // Priority 2: find in mother options (cached, covers plain motherId callers)
  const motherMatch = motherOptions?.find((opt) => opt.id === value);
  if (motherMatch) return [motherMatch, ...baseOptions];

  return baseOptions;
}, [data, value, selectedCostAccount, isLoading, motherOptions]);
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
| Extra hook call even when not needed | LOW | `enabled: !!value` ensures no fetch when no value selected |
| Mother options stale or missing | LOW | This is the same data source `AccountingLedgerSelectV2` uses today |

**Verification**:

```bash
cd sndq-fe && npx vitest run src/modules/financial/forms/purchase-invoice-v2 src/modules/financial/forms/purchase-invoice-v3
```

**If it fails**:

- **"Cannot read properties of undefined"**: Check that `motherOptions?.find` uses optional chaining
- **"Hook order changed"**: Ensure `useMotherLedgerOptions` is called unconditionally (not inside a condition)

**Deviations from the gate**:

- **No unit test for fallback logic** — This is a UI component with hook dependencies; manual verification against a real invoice with mismatched IDs is the primary check. Unit tests can be added as a follow-up.

**Commit message**: `feat: add mother options fallback to BuildingLedgerSelect`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 2: Replace AccountingLedgerSelectV2 in InvoiceLineEditSheet

**What**: Replace `AccountingLedgerSelectV2` with `BuildingLedgerSelect` in the v2 invoice line edit sheet, passing `buildingId` and `selectedCostAccount`.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/invoice-lines/InvoiceLineEditSheet.tsx` — Replace import and JSX usage

**Change detail**:

```diff
- import AccountingLedgerSelectV2 from '../amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '../amount-section/BuildingLedgerSelect';

- <AccountingLedgerSelectV2
-   value={values.costAccount?.id}
-   onChange={handleLedgerChange}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={values.costAccount?.id}
+     selectedCostAccount={values.costAccount}
+     onChange={handleLedgerChange}
+   />
+ )}
```

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| buildingId is null initially | LOW | Guard with `buildingId &&` consistent with other usages in same file |

**Verification**:

```bash
cd sndq-fe && npx vitest run src/modules/financial/forms/purchase-invoice-v2
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: use BuildingLedgerSelect in InvoiceLineEditSheet`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [ ] Committed

---

### Commit 3: Replace AccountingLedgerSelectV2 in InvoiceLineExpandedEdit

**What**: Same replacement pattern for the inline expanded edit variant of invoice lines.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/invoice-lines/InvoiceLineExpandedEdit.tsx` — Replace import and JSX usage

**Change detail**:

```diff
- import AccountingLedgerSelectV2 from '../amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from '../amount-section/BuildingLedgerSelect';

- <AccountingLedgerSelectV2
-   value={values.costAccount?.id}
-   onChange={handleLedgerChange}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={values.costAccount?.id}
+     selectedCostAccount={values.costAccount}
+     onChange={handleLedgerChange}
+   />
+ )}
```

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| buildingId is null initially | LOW | Guard with `buildingId &&` |

**Verification**:

```bash
cd sndq-fe && npx vitest run src/modules/financial/forms/purchase-invoice-v2
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: use BuildingLedgerSelect in InvoiceLineExpandedEdit`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [ ] Committed

---

### Commit 4: Replace AccountingLedgerSelectV2 in PurchaseInvoiceAmountDistributionSheet

**What**: Replace `AccountingLedgerSelectV2` in the amount distribution sheet with `BuildingLedgerSelect`. This component already has `buildingId` as a prop.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/PurchaseInvoiceAmountDistributionSheet.tsx` — Replace import and JSX usage

**Change detail**:

```diff
- import AccountingLedgerSelectV2 from './amount-section/AccountingLedgerSelectV2';
+ import BuildingLedgerSelect from './amount-section/BuildingLedgerSelect';

- <AccountingLedgerSelectV2
-   value={watch('costAccount')?.id}
-   onChange={(ledger: LedgerSelectOnChangeValue | undefined) => {
-     setValue('costAccount', ledger);
-   }}
- />
+ {buildingId && (
+   <BuildingLedgerSelect
+     buildingId={buildingId}
+     value={watch('costAccount')?.id}
+     selectedCostAccount={watch('costAccount')}
+     onChange={(ledger: LedgerSelectOnChangeValue | undefined) => {
+       setValue('costAccount', ledger);
+     }}
+   />
+ )}
```

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated files included

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| buildingId is `string \| null` | LOW | Guard with `buildingId &&` |
| Ledger suggestions still work | MEDIUM | Verify suggestion chips render after switching select component |

**Verification**:

```bash
cd sndq-fe && npx vitest run src/modules/financial/forms/purchase-invoice-v2 src/modules/financial/forms/purchase-invoice-v3
```

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: use BuildingLedgerSelect in AmountDistributionSheet`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feat/SQ-21333
```

**This validates**: All v2/v3 purchase invoice forms use building-scoped ledger options with proper fallback for existing invoices with motherId/ledgerId mismatches.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Open an existing invoice (created with old motherId) in v3 edit form — ledger select shows the correct selection
- [ ] Create a new invoice in v3 form — ledger select works normally
- [ ] Open an existing invoice in v2 edit sheet — ledger select shows the correct selection

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. Final Verification

After all 4 commits, run the full suite from the repository root:

```bash
cd sndq-fe && npx vitest run src/modules/financial/forms/purchase-invoice-v2 src/modules/financial/forms/purchase-invoice-v3
```

Compare against baselines:

```bash
diff /tmp/ledger-fallback-tests-before.txt /tmp/ledger-fallback-tests-final.txt
```

**Manual verification**:

- [ ] Edit existing invoice with motherId-based cost account — selection displays correctly
- [ ] Edit existing invoice with ledgerId-based cost account — selection displays correctly
- [ ] Create new invoice — ledger select works as before
- [ ] Amount distribution sheet shows correct selection on open
- [ ] Inline expanded edit shows correct selection on open
- [ ] Edit sheet shows correct selection on open

**Expected result**: All 771+ tests pass. No visual regression in any purchase invoice form. Selected cost account always displays correctly regardless of motherId vs ledgerId.

**Final status**:

- [x] All 4 commits complete
- [ ] Build passes
- [x] Lint passes
- [x] Tests pass or missing coverage is documented
- [ ] Manual verification complete
- [ ] PR created and merged, or ready for merge

---

## 5. Team Communication

Send to the team before merging:

> **Heads up: BuildingLedgerSelect now replaces AccountingLedgerSelectV2 in purchase invoice forms**
>
> PR [link] switches the cost category selector to use building-scoped options with a fallback to mother options for backward compatibility. After pulling:
>
> 1. Run `pnpm install` (no new deps, but good practice)
> 2. Test editing existing invoices — the cost category should display correctly
>
> Files that changed and may conflict:
> - `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect.tsx`
> - `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/PurchaseInvoiceAmountDistributionSheet.tsx`
> - `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/invoice-lines/InvoiceLineEditSheet.tsx`
> - `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/invoice-lines/InvoiceLineExpandedEdit.tsx`
>
> Known deviations or follow-ups:
> - 6 other `AccountingLedgerSelectV2` usages outside purchase-invoice forms will be migrated separately

---

## 6. What's Next

After this PR is merged, the remaining `AccountingLedgerSelectV2` usages in other modules can be migrated in a follow-up execution:

- `AmountsAllocationSection.tsx` (3 usages)
- `CostSelector.tsx`
- `EditLedgerSheet.tsx`
- `EditLedgerFloatingSheetContent.tsx`
- `AddBuildingSupplierSheet.tsx`
- `SupplierFloatingSheetContent.tsx`
- `SupplierInvoiceSheet.tsx`

### Lessons to carry forward

- The `useMotherLedgerOptions` fallback pattern can be reused when migrating the remaining call sites
- Components that only have a plain string ID (no costAccount object) work thanks to the mother options lookup

---

## Execution Log

| Date | Commit | Notes |
|------|--------|-------|
| 2026-05-15 | 1 | Done. Added `useMotherLedgerOptions` fallback with `needsMotherFallback` gate. 771/771 tests pass. |
| 2026-05-15 | 2 | Done. Replaced in InvoiceLineEditSheet. 556/556 v2 tests pass. |
| 2026-05-15 | 3 | Done. Replaced in InvoiceLineExpandedEdit. 556/556 v2 tests pass. |
| 2026-05-15 | 4 | Done. Replaced in AmountDistributionSheet. 771/771 full v2+v3 tests pass. |
