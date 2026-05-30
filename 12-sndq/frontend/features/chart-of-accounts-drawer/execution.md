# Chart of Accounts Drawer Execution — Inline Account Management

Step-by-step execution guide for the Chart of Accounts Drawer feature. Each commit should be independently verifiable and revertable.

**Created**: 2026-05-27
**Status**: In progress — Commit 7 done
**Branch**: `feature/chart-of-accounts-drawer`

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
3. [PR 1 — Extract Headless Forms + Provider Config](#3-pr-1--extract-headless-forms--provider-config)
4. [PR 2 — Drawer UI + Select Integration](#4-pr-2--drawer-ui--select-integration)
5. [Final Verification](#5-final-verification)
6. [Team Communication](#6-team-communication)
7. [What's Next](#7-whats-next)
8. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Allow users to manage (add/edit) chart of accounts entries inline from the purchase invoice form via a split-panel drawer, without navigating away or losing form context.

**Structure**: 7 commits across 2 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Extract headless forms, add provider config, fix cache | Low | 1–4 |
| **PR 2** | Build drawer UI, wire into BuildingLedgerSelect | Medium | 5–7 |

**Why 2 PRs**: PR 1 is pure refactoring — extracts form logic and adds config props without changing any user-visible behavior. Every existing test and manual flow should work identically. PR 2 adds the new drawer UI and wires it in, which is the only PR introducing new behavior.

### Prerequisites

- Chart of Accounts page is working correctly
- `BuildingLedgerSelect` popover dropdown is functional
- `CommonDrawer` component exists at `@/components/common-drawer/CommonDrawer.tsx`

### Known constraints

- `EditAccountFloatingSheetContent` and `AddBuildingAccountSheet` read `buildingId` from `useParams()` — extracted forms must accept it as a prop
- `VirtualizedAccountTable` uses row virtualization — the split panel must preserve enough vertical space for the virtualizer
- The drawer uses `CommonDrawer` (bottom sheet at 95vh), so horizontal split panel has adequate width

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

- [ ] Confirm files and folders in **Files to create**, **Files to edit**, and **Files to delete** are accurate
- [ ] Confirm `pnpm dev`, `pnpm lint`, `pnpm tsc` commands work
- [ ] Confirm current lint or type-check failures that predate this feature
- [ ] Confirm `ChartOfAccountsContent`, `ChartOfAccountsProvider`, `Toolbar`, `EditAccountFloatingSheetContent`, `AddBuildingAccountSheet`, `AddPropertyOwnerAccountSheet` match the structures described in this plan
- [ ] Confirm `BuildingLedgerSelect` has the expected props and usage pattern
- [ ] Confirm `CommonDrawer` accepts `open`, `onOpenChange`, `title`, `children`

### Capture baselines

Run these from `sndq-fe/` and save the output. Diff against these after risky commits.

```bash
pnpm tsc --noEmit 2>&1 | tail -5 | tee /tmp/coa-drawer-tsc-before.txt
pnpm lint 2>&1 | tail -5 | tee /tmp/coa-drawer-lint-before.txt
```

### Create branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/chart-of-accounts-drawer
```

---

## 3. PR 1 — Extract Headless Forms + Provider Config

Pure refactoring: extract form logic from FloatingSheet wrappers into standalone form components, add `initialClass`/`isClassTabsHidden` config to the provider, and fix cache invalidation. Zero user-visible behavior change.

---

### Commit 1: Extract headless edit account form

**What**: Extract the form fields, submit logic, and skeleton from `EditAccountFloatingSheetContent` into a standalone `EditAccountForm` component. The original component becomes a thin wrapper.

**Files to create**:

- `src/modules/financial/components/chart-of-accounts/components/forms/EditAccountForm.tsx` — form fields + submit logic, accepts `buildingId` as prop

**Files to edit**:

- `src/modules/financial/components/chart-of-accounts/components/EditAccountFloatingSheetContent.tsx` — refactor to thin wrapper that renders `FloatingSheetContent > EditAccountForm`

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] `EditAccountFloatingSheetContent` still works identically from the Chart of Accounts page
- [ ] No new imports leak across module boundaries
- [ ] Rollback: revert this commit restores original monolithic component

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Prop threading breaks form behavior | MEDIUM | Edit an account from Chart of Accounts page, verify save works |
| `useParams()` fallback breaks in drawer context | LOW | Only matters in PR 2; for now `EditAccountForm` accepts `buildingId` prop with `useParams()` fallback |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec oxlint src/modules/financial/components/chart-of-accounts/
```

Manual: Open Chart of Accounts page → click edit on any account → verify form loads, edit, save works.

**If it fails**:

- **"Cannot find module './forms/EditAccountForm'"**: Check the file path and export name match
- **"Property 'buildingId' is missing"**: Ensure `EditAccountForm` has a fallback via `useParams()` for backward compatibility

**Deviations from the gate**:

- **None expected**

**Commit message**: `refactor: extract EditAccountForm from floating sheet wrapper`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### Commit 2: Extract headless add account forms

**What**: Extract `AddBuildingAccountForm` and `AddPropertyOwnerAccountForm` from their FloatingSheet wrappers. Create an `AddAccountForm` dispatcher. Original components become thin wrappers.

**Files to create**:

- `src/modules/financial/components/chart-of-accounts/components/forms/AddBuildingAccountForm.tsx` — standard add form, accepts `buildingId` prop
- `src/modules/financial/components/chart-of-accounts/components/forms/AddPropertyOwnerAccountForm.tsx` — 619 group add form with property/owner selects, accepts `buildingId` prop
- `src/modules/financial/components/chart-of-accounts/components/forms/AddAccountForm.tsx` — dispatcher: checks `PROPERTY_OWNER_LEDGER_CODES`, routes to correct form

**Files to edit**:

- `src/modules/financial/components/chart-of-accounts/components/AddBuildingAccountFloatingSheetContent.tsx` — thin wrapper around `AddBuildingAccountForm`
- `src/modules/financial/components/chart-of-accounts/components/AddPropertyOwnerAccountSheet.tsx` — thin wrapper around `AddPropertyOwnerAccountForm`
- `src/modules/financial/components/chart-of-accounts/components/AddAccountFloatingSheetContent.tsx` — thin wrapper around `AddAccountForm`

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Adding accounts from Chart of Accounts page works for both 619 and non-619 groups
- [ ] No new imports leak across module boundaries
- [ ] Rollback: revert restores original components

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| 619 routing logic breaks | MEDIUM | Add account under 619 group → verify property/owner pickers appear |
| Form reset on close breaks | LOW | Add account, cancel, reopen → verify form is clean |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec oxlint src/modules/financial/components/chart-of-accounts/
```

Manual: Chart of Accounts page → add account under a 6xx group (not 619) → verify standard form. Add account under 619 → verify property/owner picker form.

**If it fails**:

- **"PROPERTY_OWNER_LEDGER_CODES is not defined"**: Verify import path from `../constants` is correct in the new `AddAccountForm`
- **"Cannot read property 'code' of null"**: Ensure `account` prop null guard exists in the dispatcher

**Deviations from the gate**:

- **None expected**

**Commit message**: `refactor: extract AddAccountForm family from floating sheet wrappers`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### Commit 3: Add initialClass and isClassTabsHidden config to provider and toolbar

**What**: Add `initialClass` and `isClassTabsHidden` props to `ChartOfAccountsProvider`. Expose `isClassTabsHidden` via context. When `isClassTabsHidden` is true, `ChartOfAccountsToolbar` hides the class `SegmentedTabs` and only renders the search bar.

**Files to edit**:

- `src/modules/financial/components/chart-of-accounts/providers/ChartOfAccountsProvider.tsx` — add `initialClass?: AccountClass` (default `'all'`), `isClassTabsHidden?: boolean` (default `false`). Initialize `activeClass` from `initialClass`. Expose `isClassTabsHidden` in context value.
- `src/modules/financial/components/chart-of-accounts/components/Toolbar.tsx` — add `isClassTabsHidden?: boolean` prop (or read from context). When true, skip rendering the class `SegmentedTabs` and the class 4 sub-tabs.
- `src/modules/financial/components/chart-of-accounts/components/ChartOfAccountsContent.tsx` — pass `isClassTabsHidden` from context to `ChartOfAccountsToolbar`

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Chart of Accounts page still works (no props passed = default `'all'` + unlocked = identical behavior)
- [ ] New props are optional with safe defaults
- [ ] Rollback: revert removes the new props, defaults stay the same

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Default value breaks existing page | LOW | Open Chart of Accounts page → verify tabs are visible and switchable |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec oxlint src/modules/financial/components/chart-of-accounts/
```

Manual: Open Chart of Accounts page → verify all class tabs are visible, switching works, search works.

**If it fails**:

- **"Type 'AccountClass' is not assignable"**: Verify `initialClass` prop type matches `AccountClass`

**Deviations from the gate**:

- **No visual test for isClassTabsHidden=true yet** — will be tested in PR 2 when the drawer is built

**Commit message**: `feat: add initialClass and isClassTabsHidden config to ChartOfAccountsProvider`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### Commit 4: Fix cache invalidation for ledger options

**What**: Add `ACCOUNTING_LEDGER_OPTIONS_QUERY_KEY` invalidation to `useCreateAccountingLedger` and `useUpdateAccountingLedger` mutation `onSuccess` handlers, so `BuildingLedgerSelect` dropdown refreshes after account changes.

**Files to edit**:

- `src/hooks/financial/useAccountingLedger.ts` — import `ACCOUNTING_LEDGER_OPTIONS_QUERY_KEY` from `useBuildingLedgerOptions`, add `queryClient.invalidateQueries({ queryKey: [ACCOUNTING_LEDGER_OPTIONS_QUERY_KEY] })` to both `onSuccess` handlers

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Existing create/update flows still show success toast and refresh data
- [ ] No unrelated query keys are invalidated
- [ ] Rollback: revert removes extra invalidation, no breakage

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Over-invalidation causes unnecessary refetches | LOW | Only `accountingLedgerOptions` is added — scoped enough |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec oxlint src/hooks/financial/useAccountingLedger.ts
```

Manual: Open Chart of Accounts page → edit an account name → save → open a purchase invoice form → verify the renamed account appears in the ledger dropdown.

**If it fails**:

- **"Cannot find name 'ACCOUNTING_LEDGER_OPTIONS_QUERY_KEY'"**: Check import from `@/hooks/financial/useBuildingLedgerOptions`

**Deviations from the gate**:

- **None expected**

**Commit message**: `fix: invalidate ledger options cache on account create/update`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI to pass before continuing.

```bash
git push -u origin feature/chart-of-accounts-drawer
# Create PR targeting develop
# Wait for CI to complete successfully
```

**This validates**: All refactoring is backward compatible — Chart of Accounts page works identically, dropdown select works identically, cache sync is fixed.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Chart of Accounts page: edit, add (619 and non-619), search, tab switching all work
- [ ] BuildingLedgerSelect dropdown still works
- [ ] Rollback instructions are clear

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. PR 2 — Drawer UI + Select Integration

Builds the drawer context, split-panel drawer content, and wires the manage button into `BuildingLedgerSelect`.

---

### Commit 5: Create drawer context and provider

**What**: Create `ChartOfAccountsDrawerProvider` with open/close state and `buildingId`. Create `useChartOfAccountsDrawer()` hook that returns `null` when no provider is present (safe for existing usages).

**Files to create**:

- `src/modules/financial/components/chart-of-accounts/drawer/ChartOfAccountsDrawerProvider.tsx` — context with `isOpen`, `openDrawer()`, `closeDrawer()`, `buildingId`

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] `useChartOfAccountsDrawer()` returns `null` outside provider (tested mentally or via quick console check)
- [ ] No UI changes — context only
- [ ] Rollback: revert removes the new context, nothing depends on it yet

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Context shape doesn't match consumer needs | LOW | Will be validated in commits 6–7 |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec oxlint src/modules/financial/components/chart-of-accounts/drawer/
```

**If it fails**:

- **"Module not found"**: Verify folder `drawer/` exists and file is correctly named

**Deviations from the gate**:

- **No runtime test** — context is not consumed yet, will be tested in commit 7

**Commit message**: `feat: add ChartOfAccountsDrawerProvider context`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 6: Build split-panel drawer content and drawer component

**What**: Create `ChartOfAccountsDrawerContent` (split panel: left = table with search, right = inline form or empty state) and `ChartOfAccountsDrawer` (composes `CommonDrawer` + `ChartOfAccountsProvider` + drawer content). Render the drawer lazily inside the provider using dynamic import.

**Files to create**:

- `src/modules/financial/components/chart-of-accounts/drawer/ChartOfAccountsDrawerContent.tsx` — split panel layout using existing `AccountTable` on the left and extracted form components on the right
- `src/modules/financial/components/chart-of-accounts/drawer/ChartOfAccountsDrawer.tsx` — `CommonDrawer` wrapper with `ChartOfAccountsProvider(initialClass, isClassTabsHidden)`, dynamically imported

**Files to edit**:

- `src/modules/financial/components/chart-of-accounts/drawer/ChartOfAccountsDrawerProvider.tsx` — add lazy rendering of `ChartOfAccountsDrawer` when `isOpen` is true (dynamic import with `ssr: false`)

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Split panel renders table on left, form on right
- [ ] Empty state shows when no account is selected
- [ ] Edit form loads when clicking an account row
- [ ] Add form loads when clicking "Add account" on a group row
- [ ] 619 group routes to property/owner form
- [ ] Class tabs are hidden (isClassTabsHidden=true)
- [ ] Search works in the drawer
- [ ] Rollback: revert removes drawer components, provider stays

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Virtualized table doesn't render properly in split panel | MEDIUM | Open drawer, verify table rows are visible and scrollable |
| Dynamic import fails or shows flash | LOW | Click manage button, verify drawer opens without error |
| Inline forms don't save properly | MEDIUM | Edit an account in drawer, save, verify success toast |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec oxlint src/modules/financial/components/chart-of-accounts/drawer/
```

Manual (requires temporary test harness or commit 7):
- Temporarily render `ChartOfAccountsDrawerProvider` in a test page to verify drawer opens and split panel works.

**If it fails**:

- **"VirtualizedAccountTable height is 0"**: Ensure the left panel has `flex-1 overflow-hidden` and the table container has proper height constraints
- **"Cannot read properties of undefined (reading 'open')"**: Verify `useChartOfAccounts()` is called inside the provider tree
- **"FloatingSheet opens behind drawer"**: Confirm forms use inline rendering, not FloatingSheet wrappers

**Deviations from the gate**:

- **Full manual testing deferred to commit 7** — drawer is not yet accessible from the real UI

**Commit message**: `feat: build split-panel chart of accounts drawer with inline forms`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete (via test harness or after commit 7)
- [ ] Committed

---

### Commit 7: Wire manage button into BuildingLedgerSelect

**What**: Add a "manage accounts" icon button to `BuildingLedgerSelect` that opens the shared drawer. The button only renders when `useChartOfAccountsDrawer()` returns non-null. Wrap one consumer (e.g., purchase invoice v2 or v3 form) with `ChartOfAccountsDrawerProvider` as the initial integration point.

**Files to edit**:

- `src/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect.tsx` — import `useChartOfAccountsDrawer`, conditionally render manage button next to the `AccountingLedgerSelectBase` trigger
- One form-level component that wraps `BuildingLedgerSelect` instances — wrap with `ChartOfAccountsDrawerProvider`. Determine the best candidate:
  - `PurchaseInvoiceAmountDistributionSheet.tsx` (v2)
  - or `InvoiceLineCostAndDistribution.tsx` (v3)
  - Pick the one that covers the most common user flow

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] BuildingLedgerSelect without provider: no manage button (backward compatible)
- [ ] BuildingLedgerSelect with provider: manage button visible, opens drawer
- [ ] Drawer opens, shows 6xx accounts, edit/add works inline
- [ ] After saving in drawer, closing drawer, the popover dropdown reflects changes
- [ ] Multiple BuildingLedgerSelects on the same form share one drawer
- [ ] Rollback: revert removes the button and provider wrapper

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Manage button layout breaks select trigger alignment | LOW | Visual check — button should be small and aligned |
| Provider placement too high causes unnecessary re-renders | LOW | Profile if noticeable lag on form interactions |
| Drawer z-index conflicts with popover | MEDIUM | Open dropdown, then open drawer — verify no visual overlap |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec oxlint src/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect.tsx
```

Manual:
1. Open a purchase invoice form with the wrapped component
2. Verify manage button is visible next to the ledger select
3. Click manage → drawer opens with 6xx accounts
4. Edit an account → save → close drawer → open dropdown → verify updated name
5. Add a new account → save → close drawer → open dropdown → verify new account appears
6. Open a form that does NOT have the provider → verify no manage button

**If it fails**:

- **"useChartOfAccountsDrawer is not a function"**: Verify the hook is exported from the provider file
- **"Manage button appears where it shouldn't"**: Verify `useChartOfAccountsDrawer()` returns `null` outside provider
- **"Dropdown doesn't refresh after drawer save"**: Verify commit 4's cache invalidation is in place

**Deviations from the gate**:

- **Only one consumer is wrapped initially** — other forms (supplier sheet, invoice detail, etc.) can be wrapped in follow-up commits as needed

**Commit message**: `feat: wire manage accounts button into BuildingLedgerSelect`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### PR 2 Checkpoint

Push PR 2 and wait for CI to pass.

```bash
git push origin feature/chart-of-accounts-drawer
# Create PR targeting develop
# Wait for CI to complete successfully
```

**This validates**: The full feature works end-to-end — manage button, drawer, split panel, inline edit/add, cache sync.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Chart of Accounts page: no regressions
- [ ] Purchase invoice form: manage button → drawer → edit/add → cache refresh
- [ ] Forms without provider: no manage button
- [ ] Rollback instructions are clear

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 5. Final Verification

After all 7 commits, run the full suite from `sndq-fe/`:

```bash
pnpm tsc --noEmit
pnpm lint
pnpm test
```

Compare against baselines:

```bash
diff /tmp/coa-drawer-tsc-before.txt <(pnpm tsc --noEmit 2>&1 | tail -5)
diff /tmp/coa-drawer-lint-before.txt <(pnpm lint 2>&1 | tail -5)
```

**Manual verification**:

- [ ] Chart of Accounts page works identically (edit, add, search, tabs)
- [ ] Purchase invoice form: manage button visible, drawer works, cache syncs
- [ ] Forms without provider: no manage button, no errors
- [ ] 619 group add form shows property/owner picker in drawer
- [ ] Dynamic import: first open has brief load, subsequent opens are instant
- [ ] No console errors or warnings related to the new components

**Expected result**: All existing behavior is preserved. The manage button and drawer appear only where the provider is placed. Inline edit/add works without nested sheets.

**Final status**:

- [ ] All 7 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes
- [ ] Tests pass or missing coverage is documented
- [ ] Manual verification complete
- [ ] All PRs created and merged, or ready for merge

---

## 6. Team Communication

Send to the team before merging PR 2:

> **Heads up: Chart of Accounts drawer for purchase invoice forms**
>
> PR [link] adds a "manage accounts" button to the ledger select in purchase invoice forms. Clicking it opens a drawer where users can search, edit, and add 6xx accounts without leaving the form.
>
> After pulling:
>
> 1. Run `pnpm install` (no new dependencies expected, but just in case)
> 2. Restart dev server
>
> Files that changed and may conflict:
> - `src/modules/financial/components/chart-of-accounts/` (new `forms/` and `drawer/` folders, refactored existing components)
> - `src/modules/financial/forms/purchase-invoice-v2/components/amount-section/BuildingLedgerSelect.tsx`
> - `src/hooks/financial/useAccountingLedger.ts`
>
> Known follow-ups:
> - Other consumers of `BuildingLedgerSelect` (supplier sheet, invoice detail) can opt into the drawer by wrapping with `ChartOfAccountsDrawerProvider`

---

## 7. What's Next

After this feature is merged, potential follow-ups:

1. **Wrap additional consumers**: Add `ChartOfAccountsDrawerProvider` to supplier sheet, invoice detail sheet, and other forms that use `BuildingLedgerSelect`
2. **Account selection mode**: Optionally allow the drawer to act as a picker (select an account to populate the dropdown) in addition to manage-only mode
3. **Other account classes**: Allow the drawer to show non-6xx classes when triggered from different contexts (e.g., class 4 for receivables)

### Lessons to carry forward

- Extract headless form logic first (PR 1) to validate backward compatibility before adding new UI
- Use optional context pattern (`returns null outside provider`) for progressive feature adoption without breaking existing consumers

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
| | 2 | |
| | 3 | |
| | 4 | |
| | 5 | |
| | 6 | |
| 2026-05-27 | 7 | Refactored: removed ChartOfAccountsDrawerProvider, moved drawer + state into BuildingLedgerSelect (self-contained via portal). Deleted provider file, cleaned up PurchaseInvoiceAmountDistributionSheet. Button always visible. tsc + lint clean, zero stale imports. |
