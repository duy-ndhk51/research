# InlineLedgerSelect Execution — Tabbed Ledger Select with Credit Note Conversion

Step-by-step execution guide for the InlineLedgerSelect feature. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-24
**Status**: In progress — Commit 6 done
**Branch**: `feature/inline-ledger-select`

> **IMPORTANT**: Do NOT automatically commit after each step. Implement each commit's changes, then stop and wait for manual review and testing. Only commit after explicit approval.
>
> **STATUS TRACKING**: After completing each commit's implementation, automatically update this file:
> 1. Check off the completed items in that commit's **Status** checklist
> 2. Record the date and any notes in the **Execution Log** table at the bottom
> 3. Update the top-level **Status** field (e.g., "In progress — Commit 3 done")
> This keeps the plan as the single source of truth for progress.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — InlineLedgerSelect Component + Form Integration](#3-pr-1--inlineledgerselect-component--form-integration)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Replace `BuildingLedgerSelect` at all form-level purchase invoice callsites with a new `InlineLedgerSelect` component that renders a tabbed popover (Expenses / Revenue), and triggers credit note conversion with bulk line updates when a user selects a revenue-class (7xx) ledger.

**Structure**: 6 commits across 1 PR.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Component + form integration + test specs | Medium | 1–6 |

**Why 1 PR**: All commits build on the same component and share the same review surface. The component is not useful without the form integration, so splitting adds merge overhead without improving review quality.

### Prerequisites

- `PopoverListContent` with tabs pattern exists at `@/modules/financial/components/popover-list-content`
- `ListItemSelect` trigger exists at `purchase-invoice-v3/components/ListItemSelect.tsx`
- `useBuildingLedgerOptions` hook exists at `@/hooks/financial/useBuildingLedgerOptions.ts`
- `ChartOfAccountsDrawer` exists at `@/modules/financial/components/chart-of-accounts/drawer/`
- `CreateLedgerFloatingSheetContent` exists for "Add account" action
- `BuildingLedgerSelect` and `useBuildingLedgerSelectOptions` are stable at `purchase-invoice-v2/components/amount-section/BuildingLedgerSelect.tsx`

### Known constraints

- `useBuildingLedgerSelectOptions` fetches only 6xx options by default (`motherCode: '6'`); revenue tab needs a separate query with `motherCode: '7'`
- React Query deduplicates the 7xx query across multiple `InlineLedgerSelect` instances on the same page (same query key + params)
- `CostAccountData.code` is optional — lines without `code` must be treated as "unknown class" and updated during bulk conversion
- Detail-sheet callsites (`CostSelector`, `EditLedgerFloatingSheetContent`, `EditLedgerSheet`) are deferred to a follow-up PR because they use direct API mutations, not form context
- `PurchaseInvoiceAmountDistributionSheet` has its own inner `FormProvider` scope but lives inside the outer `PurchaseInvoiceFormContext` tree — this requires care when accessing the outer form

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

- [ ] Confirm `InlineBuildingSelect.tsx` at `purchase-invoice-v3/components/` is stable (reference pattern)
- [ ] Confirm `PopoverListContent` exports `PopoverListAction` and `Tab` types
- [ ] Confirm `useBuildingLedgerOptions` accepts `motherCode: '7'` (no hardcoded class filter)
- [ ] Confirm `BuildingLedgerSelect` exports `useBuildingLedgerSelectOptions` and `BuildingLedgerSelectValue`
- [ ] Confirm `ACCOUNT_CLASS.EXPENSES = '6'` and `ACCOUNT_CLASS.REVENUE = '7'` in `chart-of-accounts/types.ts`
- [ ] Confirm `InvoiceTypeCode.CREDIT_NOTE = '381'` in `common/constants/invoiceTypeCode.ts`
- [ ] Confirm `PurchaseInvoiceAmountDistributionSheet` has access to `usePurchaseInvoiceFormContext()`
- [ ] Confirm whether inner `FormProvider` in the distribution sheet shadows the outer form context
- [ ] Confirm current lint, type-check, and build failures that predate this feature

### Capture baselines

Run these from the repository root and save the output. Diff against these after risky commits.

```bash
cd sndq-fe && pnpm run typecheck 2>&1 | tee /tmp/inline-ledger-typecheck-before.txt
cd sndq-fe && pnpm run build 2>&1 | tee /tmp/inline-ledger-build-before.txt
```

### Create branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/inline-ledger-select
```

---

## 3. PR 1 — InlineLedgerSelect Component + Form Integration

This PR creates the `InlineLedgerSelect` component, a `useCreditNoteConversion` hook, and wires them into the two form-level callsites (`InvoiceLineCostAndDistribution` and `PurchaseInvoiceAmountDistributionSheet`). It also adds test specifications in the research repo.

---

### Commit 1: Create InlineLedgerSelect UI component

**What**: Build the tabbed popover select component with Expenses/Revenue tabs, footer actions, and option rendering. No conversion logic yet — just the raw select UI.

**Files to create**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/components/InlineLedgerSelect.tsx`

**Implementation details**:

Props interface:

```typescript
interface InlineLedgerSelectProps {
  buildingId: string;
  value?: BuildingLedgerSelectValue;
  onChange: (option: LedgerSelectOnChangeValue | undefined) => void;
  mode?: InvoiceFormMode;
  onCreditNoteConversion?: (selectedLedger: LedgerSelectOnChangeValue) => void;
  placeholder?: string;
  error?: boolean;
  externalOptions?: AccountingLedgerOption[];
  isLoadingExternalOptions?: boolean;
}
```

UI structure — mirror `InlineBuildingSelect.tsx` lines 118–178:

- `ListItemSelect` trigger showing selected ledger `name` + `displayCode`
- `Popover` → `PopoverListContent` with two `Tab` entries:
  - `expenses` (default): options where `displayCode.startsWith('6')`
  - `revenue`: options where `displayCode.startsWith('7')`
- Each option renders as `Button` + `ListItem` with ledger name and code as caption
- Footer `PopoverListAction[]`:
  - "Create new ledger" — opens `CreateLedgerFloatingSheetContent` (lazy-loaded)
  - "Chart of Accounts" — opens `ChartOfAccountsDrawer` (lazy-loaded)

Option sources:

- Expense tab: `useBuildingLedgerSelectOptions({ buildingId, externalOptions, ... })` — reuse existing hook from `BuildingLedgerSelect.tsx`
- Revenue tab: `useBuildingLedgerOptions({ buildingId, motherCode: '7' })` — React Query deduplicates across instances

Key file references:

- `InlineBuildingSelect.tsx` lines 118–178 — popover + tab + option rendering pattern
- `BuildingLedgerSelect.tsx` lines 100–140 — lazy-loaded footer actions pattern
- `PopoverListContent` — `tabs`, `actions`, `onSearchChange`, `children` props

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Revenue tab empty for buildings without 7xx ledgers | LOW | Verify `useBuildingLedgerOptions` returns empty array (not error) when no 7xx ledgers exist |
| `PopoverListContent` tab generic type incompatible | LOW | Match `Tab<T>` generic usage from `InlineBuildingSelect` |

**Verification**:

```bash
cd sndq-fe && pnpm run typecheck
pnpm exec oxlint src/modules/financial/forms/purchase-invoice-v3/components/InlineLedgerSelect.tsx
```

**If it fails**:

- **"Cannot find module `popover-list-content`"**: Check re-export in `@/modules/financial/components/popover-list-content/index.ts`
- **"Type 'Tab' is not assignable"**: Match the generic parameter pattern from `InlineBuildingSelect`

**Deviations from the gate**:

- **No automated tests at this stage** — integration tests are specified in Commit 6 (research repo) and implemented separately

**Commit message**: `feat: create InlineLedgerSelect with tabbed popover UI`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 2: Add useCreditNoteConversion hook and integrate dialog into InlineLedgerSelect

**What**: Create a form-level hook that performs mode switch + `invoiceTypeCode` update + bulk 6xx line update. Add a confirmation dialog to `InlineLedgerSelect` that fires when a 7xx option is selected on a non-credit-note invoice.

**Files to create**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/hooks/useCreditNoteConversion.ts`

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/components/InlineLedgerSelect.tsx` — add dialog state and fire it on 7xx selection when `mode !== 'credit_note'`

**`useCreditNoteConversion` hook signature**:

```typescript
interface UseCreditNoteConversionReturn {
  convertToCreditNote: (selectedLedger: LedgerSelectOnChangeValue) => void;
}
```

Logic inside `convertToCreditNote`:

1. `setMode('credit_note')` via `usePurchaseInvoiceFormContext()`
2. `setValue('invoiceTypeCode', InvoiceTypeCode.CREDIT_NOTE)` via `useFormContext<PurchaseInvoiceFormV2Data>()`
3. Loop `getValues('amounts')`:
   - If `costAccount?.code` starts with `ACCOUNT_CLASS.EXPENSES` (`'6'`) or `costAccount` is undefined → update to the selected 7xx ledger
   - If `costAccount?.code` starts with `ACCOUNT_CLASS.REVENUE` (`'7'`) → skip

**Dialog behavior in `InlineLedgerSelect`**:

- State: `pendingRevenueLedger: LedgerSelectOnChangeValue | null`
- On Revenue tab option click:
  - If `mode !== 'credit_note'` and `onCreditNoteConversion` provided → set `pendingRevenueLedger`, show `AlertDialog`
  - On confirm: call `onCreditNoteConversion(pendingRevenueLedger)` then `onChange(pendingRevenueLedger)`, clear state, close popover
  - On cancel: clear `pendingRevenueLedger`, no other changes
- If `mode === 'credit_note'`: call `onChange(option)` directly, no dialog

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Bulk `setValue` across amounts array does not trigger re-render per line | MEDIUM | Verify each `setValue(\`amounts.${index}.costAccount\`, ...)` causes field re-render; add `{ shouldDirty: true }` if needed |
| Lines with `costAccount` but no `code` field missed by prefix check | LOW | Treat `!code` same as expense class — include in bulk update |

**Verification**:

```bash
cd sndq-fe && pnpm run typecheck
pnpm exec oxlint src/modules/financial/forms/purchase-invoice-v3/hooks/useCreditNoteConversion.ts
pnpm exec oxlint src/modules/financial/forms/purchase-invoice-v3/components/InlineLedgerSelect.tsx
```

**If it fails**:

- **"Cannot find `usePurchaseInvoiceFormContext`"**: Import from `../contexts/PurchaseInvoiceFormContext`
- **"Property 'amounts' does not exist"**: Ensure `useFormContext<PurchaseInvoiceFormV2Data>()` uses the correct generic

**Deviations from the gate**:

- **Dialog uses Briicks `Dialog`** (from `@/components/briicks/info-feedback/message`) instead of shadcn `AlertDialog` — matches existing `ConfirmDialogs.tsx` pattern
- **Reused existing i18n keys**: title `peppol.action_convert_credit_note`, description `purchase_invoice.group_confirm_description`, buttons `general.cancel` / `general.confirm`
- **InlineLedgerSelect dialog integration tests deferred to Commit 6** — hook unit tests cover conversion logic; end-to-end dialog smoke requires Commit 3 wiring
- **Type-check**: pre-existing failure in `BuildingLedgerSelect.test.tsx` (`Type 'null' is not assignable to type 'Element'`) — unrelated to Commit 2 files

**Commit message**: `feat: add credit note conversion hook and dialog`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable — pending Commit 3 wiring for end-to-end smoke
- [ ] Committed

---

### Commit 3: Replace BuildingLedgerSelect in InvoiceLineCostAndDistribution

**What**: Swap `BuildingLedgerSelect` for `InlineLedgerSelect` in the per-line cost category field. Thread `mode` and `onCreditNoteConversion` from `InvoiceLinesTableV3` down through the component tree.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/InvoiceLinesTableV3.tsx` — call `useCreditNoteConversion()`, read `mode` from context, pass both down
- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/InvoiceLineCard.tsx` — add `mode` and `onCreditNoteConversion` pass-through props
- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/SingleTotalView.tsx` — add `mode` and `onCreditNoteConversion` pass-through props
- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/InvoiceLineCostAndDistribution.tsx` — replace `BuildingLedgerSelect` with `InlineLedgerSelect`; add `mode` and `onCreditNoteConversion` to props

**Prop threading path**:

```
InvoiceLinesTableV3
  (reads mode from context, calls useCreditNoteConversion)
  ↓ mode, onCreditNoteConversion
InvoiceLineCard          SingleTotalView
  (pass-through)           (pass-through)
  ↓                        ↓
InvoiceLineCostAndDistribution
  ↓ mode, onCreditNoteConversion
InlineLedgerSelect
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
| Intermediate components add logic instead of pass-through | LOW | Keep `InvoiceLineCard` and `SingleTotalView` changes to props interface + forwarding only |
| `useCreditNoteConversion` called outside form context | MEDIUM | Verify `InvoiceLinesTableV3` always renders inside `PurchaseInvoiceFormContext` + outer `FormProvider` |

**Verification**:

```bash
cd sndq-fe && pnpm run typecheck
pnpm exec oxlint --fix src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/
```

Manual test:

1. Open purchase invoice edit form with 2 lines having 6xx ledgers
2. On line 1, open ledger select → switch to Revenue tab → select a 7xx option
3. Confirm dialog → verify mode badge shows "Credit Note" and both lines show the selected 7xx ledger

**If it fails**:

- **"Property 'mode' does not exist on type"**: Verify each intermediate props interface was updated
- **Lines not updating after conversion**: Add `{ shouldDirty: true }` to `setValue` calls in hook

**Deviations from the gate**:

- **Fixed pre-existing type-check error** in `BuildingLedgerSelect.test.tsx` (`LedgerSelectOverlays` mock returned `null` → `<></>`) — unblocks full `pnpm run type-check`

**Commit message**: `feat: wire InlineLedgerSelect into invoice line cost field`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable — smoke test in dev server recommended (revenue tab → dialog → confirm → mode + bulk lines)
- [ ] Committed

---

### Commit 4: Replace BuildingLedgerSelect in PurchaseInvoiceAmountDistributionSheet

**What**: Swap `BuildingLedgerSelect` for `InlineLedgerSelect` in the distribution sheet's cost category field (~line 738). Wire conversion through the outer invoice form context.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/PurchaseInvoiceAmountDistributionSheet.tsx`
  - Replace `BuildingLedgerSelect` import with `InlineLedgerSelect`
  - Read `mode` from `usePurchaseInvoiceFormContext()`
  - Determine the correct form scope for the conversion hook (see risk below)
  - Pass `mode` and `onCreditNoteConversion` to `InlineLedgerSelect`

**Form scope note**: The distribution sheet renders inside `PurchaseInvoiceFormContext` but uses its own inner `FormProvider`. The `useCreditNoteConversion` hook must access the **outer** form's `amounts` array. Before implementing, verify whether `useFormContext()` inside the sheet reads from the outer or inner `FormProvider`. If the inner shadows the outer, pass `convertToCreditNote` as a prop from the parent that opens the sheet (the parent is inside the outer provider scope).

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Inner `FormProvider` shadows outer — hook reads sheet's form instead of invoice form | HIGH | `getValues('amounts')` inside the sheet must return the outer invoice form's amounts, not the sheet's single-line form data |
| Distribution sheet's own `setValue('costAccount', ledger)` and bulk update target different scopes | MEDIUM | Verify the sheet's local write and the hook's bulk write do not interfere |

**Verification**:

```bash
cd sndq-fe && pnpm run typecheck
pnpm exec oxlint --fix src/modules/financial/forms/purchase-invoice-v2/components/PurchaseInvoiceAmountDistributionSheet.tsx
```

Manual test:

1. Open invoice form with 3 lines (all 6xx). Open distribution sheet for line 2
2. In the sheet, open ledger select → Revenue tab → select 7xx
3. Confirm dialog → verify: outer form mode changes to credit note, all 3 invoice lines updated to 7xx, sheet cost category field shows selected 7xx

**If it fails**:

- **`getValues('amounts')` returns sheet-scoped data**: Pass `convertToCreditNote` as a prop from the parent component instead of calling the hook inside the sheet
- **"Mode does not change after confirm"**: Confirm `usePurchaseInvoiceFormContext()` is available inside the sheet (it should be, as it reads from React context, not FormProvider)

**Deviations from the gate**:

- **Form scope**: inner `FormProvider` shadows outer form — did **not** call `useCreditNoteConversion` or `usePurchaseInvoiceFormContext()` inside the sheet; wired via optional props `mode` + `onCreditNoteConversion` from `InvoiceLinesTableV3` (also edited, not listed in original commit file list)
- **v2 callers unchanged** — optional props omitted; ledger select works without conversion dialog

**Commit message**: `feat: wire InlineLedgerSelect into distribution sheet`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable — distribution sheet revenue conversion smoke recommended in dev
- [ ] Committed

---

### Commit 5: Clean up unused code

**What**: Remove unused `BuildingLedgerSelect` imports from edited files. Verify no orphan references remain.

**Files to edit**:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/InvoiceLineCostAndDistribution.tsx` — confirm `BuildingLedgerSelect` import removed
- `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/components/PurchaseInvoiceAmountDistributionSheet.tsx` — confirm `BuildingLedgerSelect` import removed

**Do NOT remove**:

- `BuildingLedgerSelect.tsx` itself — still used by detail-sheet callsites (`CostSelector`, `EditLedgerFloatingSheetContent`, `EditLedgerSheet`) deferred to follow-up PR
- `useBuildingLedgerSelectOptions` export — reused by `InlineLedgerSelect`
- `AccountingLedgerSelectBase.tsx` — still used by `BuildingLedgerSelect`

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Removing import still referenced elsewhere in the same file | LOW | Grep for `BuildingLedgerSelect` in each file before removing |

**Verification**:

```bash
cd sndq-fe && pnpm run typecheck
cd sndq-fe && pnpm run build
pnpm exec oxlint --fix src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/InvoiceLineCostAndDistribution.tsx
pnpm exec oxlint --fix src/modules/financial/forms/purchase-invoice-v2/components/PurchaseInvoiceAmountDistributionSheet.tsx
```

**If it fails**:

- **Build error referencing removed import**: Restore the import and grep the file for any remaining usage

**Deviations from the gate**:

- **Grep audit**: `InvoiceLineCostAndDistribution` and `PurchaseInvoiceAmountDistributionSheet` already had no `BuildingLedgerSelect` component import (only intentional `BuildingLedgerSelectValue` type in cost field) — no import edits required in those files
- **Test mock fix**: Updated `InvoiceLineCard.test.tsx` to mock `InlineLedgerSelect` instead of stale `BuildingLedgerSelect` mock (orphan reference; production uses `InlineLedgerSelect` since Commit 3)
- **`pnpm run build`**: OOM on local agent environment (heap limit) — not caused by this commit; `pnpm run type-check` clean

**Commit message**: `refactor: clean up unused BuildingLedgerSelect imports`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [x] Manual verification complete, if applicable — N/A (import/mock cleanup only)
- [ ] Committed

---

### Commit 6: Test specifications (research repo)

**What**: Create the test spec for credit note conversion behavior. Update the integration summary and inline selects spec. No sndq-fe code changes in this commit.

**Files to create**:

- `research/12-sndq/frontend/tests/purchase-invoice-form/integration/ledger-credit-note-conversion.md`

**Files to edit**:

- `research/12-sndq/frontend/tests/purchase-invoice-form/integration-summary.md` — append section 10
- `research/12-sndq/frontend/tests/purchase-invoice-form/integration/inline-selects.md` — append InlineLedgerSelect UI scenarios
- `research/12-sndq/frontend/tests/purchase-invoice-form/integration/README.md` — cross-link Ledger Credit Note Conversion section (user-approved)

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Test spec references incorrect component or file paths | LOW | Proofread all sndq-fe paths against actual directory structure |

**Verification**: Proofread the markdown. No build or lint needed.

**Deviations from the gate**:

- **Spec files pre-existed** — commit work was alignment + README cross-link (not greenfield authoring)
- **Added IS-L11 + conversion Case 13** for tab class isolation (post-hotfix `matchesMotherCode` + prefix filter behavior)
- **Updated `integration/README.md`** — user-approved, beyond original 3-file list
- **Dialog role in spec**: `getByRole('dialog')` not `alertdialog` (Briicks Dialog, Commit 2 deviation)
- **renderProviders import**: `../utils` barrel, not `../helpers/renderProviders`

**Commit message**: `docs: add ledger credit note conversion test spec`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [x] Manual verification complete, if applicable — proofread markdown paths against sndq-fe tree
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI to pass before continuing.

```bash
git push -u origin feature/inline-ledger-select
# Create PR targeting develop
# Wait for CI to complete successfully
```

**This validates**: Type-check, lint, and build pass with the new component and both refactored callsites.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] 7xx selection on invoice mode → dialog → confirm → mode + all 6xx lines updated (manual smoke test)
- [ ] 7xx selection on credit_note mode → no dialog, normal selection (manual smoke test)
- [ ] 6xx selection on any mode → normal selection, no dialog (manual smoke test)
- [ ] Distribution sheet: 7xx selection triggers same conversion flow (manual smoke test)
- [ ] Footer actions (create ledger + chart of accounts drawer) work in `InlineLedgerSelect`
- [ ] FormHeader mode toggle does NOT trigger any line updates
- [ ] Rollback instructions are clear

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. Final Verification

After all 6 commits, run the full suite from the repository root:

```bash
cd sndq-fe && pnpm run typecheck 2>&1 | tee /tmp/inline-ledger-typecheck-final.txt
cd sndq-fe && pnpm run build 2>&1 | tee /tmp/inline-ledger-build-final.txt
```

Compare against baselines:

```bash
diff /tmp/inline-ledger-typecheck-before.txt /tmp/inline-ledger-typecheck-final.txt
diff /tmp/inline-ledger-build-before.txt /tmp/inline-ledger-build-final.txt
```

**Manual verification**:

- [ ] Ledger select shows tabbed popover with Expenses (default) and Revenue tabs
- [ ] Expense option selection works normally on all modes (invoice, credit_note, expense_note)
- [ ] Revenue option on invoice mode → confirmation dialog → confirm → credit_note mode + bulk 6xx lines updated
- [ ] Revenue option on credit_note mode → no dialog, direct selection
- [ ] Revenue option on expense_note mode → confirmation dialog (same as invoice mode)
- [ ] Cancel dialog → no changes to mode or any line
- [ ] Multi-line: only 6xx lines updated, existing 7xx lines preserved
- [ ] Lines without `costAccount.code` treated as 6xx and updated during conversion
- [ ] Distribution sheet: same conversion flow triggered
- [ ] Footer "Create new ledger" opens floating sheet
- [ ] Footer "Chart of Accounts" opens drawer
- [ ] FormHeader mode toggle (credit_note → invoice) does NOT trigger line updates
- [ ] Detail-sheet callsites (`CostSelector`, `EditLedgerFloatingSheetContent`, `EditLedgerSheet`) still use `BuildingLedgerSelect` unchanged

**Expected result**: All form-level purchase invoice callsites use `InlineLedgerSelect` with working tabbed UI and credit note conversion. Detail-sheet callsites are unaffected and deferred to a follow-up PR.

**Final status**:

- [ ] All 6 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes
- [ ] Manual verification complete
- [ ] PR created and merged, or ready for merge

---

## 5. Team Communication

Send to the team before merging:

> **Heads up: InlineLedgerSelect replaces BuildingLedgerSelect in invoice form lines and distribution sheet**
>
> PR [link] introduces a tabbed ledger select (Expenses / Revenue) in the purchase invoice form. Selecting a revenue (7xx) ledger on a non-credit-note invoice now shows a confirmation dialog and converts the invoice to credit note mode, bulk-updating all expense lines to the selected ledger.
>
> After pulling:
>
> 1. Run `pnpm install` (no new dependencies expected)
> 2. Restart dev server
>
> Files that changed and may conflict:
> - `purchase-invoice-v3/components/InlineLedgerSelect.tsx` (new)
> - `purchase-invoice-v3/hooks/useCreditNoteConversion.ts` (new)
> - `purchase-invoice-v3/components/invoice-lines/InvoiceLineCostAndDistribution.tsx`
> - `purchase-invoice-v3/components/invoice-lines/InvoiceLineCard.tsx`
> - `purchase-invoice-v3/components/invoice-lines/SingleTotalView.tsx`
> - `purchase-invoice-v3/components/invoice-lines/InvoiceLinesTableV3.tsx`
> - `purchase-invoice-v2/components/PurchaseInvoiceAmountDistributionSheet.tsx`
>
> Known follow-ups:
> - Detail-sheet callsites (`CostSelector`, `EditLedgerFloatingSheetContent`, `EditLedgerSheet`) still use `BuildingLedgerSelect` — separate PR planned

---

## 6. What's Next

After PR 1 is merged, proceed to a follow-up PR for **detail-sheet callsites**:

- `CostSelector.tsx` — bulk allocation cost editor (requires API mutation for invoice type conversion, not form context)
- `EditLedgerFloatingSheetContent.tsx` — single cost editor floating sheet
- `EditLedgerSheet.tsx` — single cost editor full sheet

These callsites use direct API mutations (`useUpdateAllocationCostLedger`) instead of form context. The conversion logic will need an API-based approach (PUT endpoint to update `invoiceTypeCode` + batch-update allocation cost ledgers).

### Lessons to carry forward

- (to be filled after execution)

### Known lessons from prior phases

- From Chart of Accounts Drawer: lazy-loaded components (`import()`) need null-check state before rendering — use `useState<ComponentType | null>(null)` pattern
- From Chart of Accounts Drawer: `FloatingSheet` and `CommonDrawer` shell patterns are stable and can be reused directly

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| 2026-06-24 | 1 | Created `InlineLedgerSelect.tsx`. Icon names corrected (`add` not `plus`, `bookBookmark` not `receipt`). Tab labels use existing keys `accounting.mother_cat_expense` / `accounting.mother_cat_revenue`. Typecheck + ESLint clean. Lint command is `pnpm exec eslint` (not oxlint). Type-check command is `pnpm run type-check` (not typecheck). |
| 2026-06-24 | 2 | Created `useCreditNoteConversion.ts` with `shouldBulkUpdateCostAccount` helper and `convertToCreditNote` (setMode + invoiceTypeCode + bulk 6xx/undefined lines). Integrated confirmation dialog into `InlineLedgerSelect` (revenue tab gate when `mode !== 'credit_note'`). Added `useCreditNoteConversion.test.tsx` (8 tests). ESLint clean on Commit 2 files. Full `pnpm run type-check` fails on pre-existing `BuildingLedgerSelect.test.tsx` error — not introduced here. Dialog uses Briicks Dialog not AlertDialog. InlineLedgerSelect dialog UI tests deferred to Commit 6. Manual E2E smoke pending Commit 3. |
| 2026-06-24 | 3 | Wired `useCreditNoteConversion` in `InvoiceLinesTableV3`; pass-through `mode` + `onCreditNoteConversion` via `InvoiceLineCard` and `SingleTotalView` to `InvoiceLineCostAndDistribution`. Replaced `BuildingLedgerSelect` with `InlineLedgerSelect`. Fixed `BuildingLedgerSelect.test.tsx` mock type error. `pnpm run type-check` clean. ESLint clean on invoice-lines files. `InvoiceLinesTable.test.tsx` (17) + `useCreditNoteConversion.test.tsx` (8) pass. Manual smoke pending. |
| 2026-06-24 | 4 | Replaced `BuildingLedgerSelect` with `InlineLedgerSelect` in `PurchaseInvoiceAmountDistributionSheet`. Added optional `mode` + `onCreditNoteConversion` props; passed from `InvoiceLinesTableV3` (`convertToCreditNote` from hook — not called inside sheet due to inner FormProvider). v2 callers unchanged. `pnpm run type-check` clean. ESLint clean. `InvoiceLinesTable.test.tsx` (17) + `useCreditNoteConversion.test.tsx` (8) pass. Manual distribution-sheet smoke pending. |
| 2026-06-24 | 5 | Grep audit: migrated callsites already use `InlineLedgerSelect` (no component import of `BuildingLedgerSelect`). Fixed stale `InvoiceLineCard.test.tsx` mock (`BuildingLedgerSelect` → `InlineLedgerSelect` named export). `pnpm run type-check` + ESLint clean. `InvoiceLineCard.test.tsx` (9) + `InvoiceLinesTable.test.tsx` (17) pass. `pnpm run build` OOM locally — environment limit, not commit-related. |
| 2026-06-24 | 6 | Aligned pre-existing test specs in research repo: `ledger-credit-note-conversion.md` (Dialog role, `../utils` import, Case 11 props wiring, Existing coverage, Case 13 tab isolation); `integration-summary.md` Section 10 (detail link + row 13); `inline-selects.md` (IS-L11, ListItemSelect trigger note, IS-L6 scope); `integration/README.md` (Ledger Credit Note Conversion section + Inline Selects blurb). No sndq-fe changes. Proofread paths. Not committed — awaiting manual review. |
