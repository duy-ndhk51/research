# DataTable Migration Execution — `sndq-clone` to `@sndq/ui-v2`

Step-by-step execution guide for migrating the DataTable block from `sndq-clone/packages/ui-v2/src/blocks/data-table` into `sndq/packages/ui-v2`. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-21
**Status**: PR 4 Commit 21 complete (pending manual commit)
**Architecture**: [architecture.md](./architecture.md)
**Migration plan**: [testing-and-migration-stages.md](./testing-and-migration-stages.md)
**Source**: `sndq-clone/packages/ui-v2/src/blocks/data-table` (working tree)
**Target**: `sndq/packages/ui-v2/src/blocks/data-table`
**Branch**: `feature/data-table-migration`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Foundation + Core Hooks (Stages 0–1)](#3-pr-1--foundation--core-hooks-stages-01)
4. [PR 2 — Persistence + Content Rendering (Stages 2–3)](#4-pr-2--persistence--content-rendering-stages-23)
5. [PR 3 — Sort + Search + Filters (Stages 4–5)](#5-pr-3--sort--search--filters-stages-45)
6. [PR 4 — Pagination + Selection + Bulk Actions (Stages 6–7)](#6-pr-4--pagination--selection--bulk-actions-stages-67)
7. [PR 5 — Settings + Editing + Context Menu (Stages 8–10)](#7-pr-5--settings--editing--context-menu-stages-810)
8. [PR 6 — Locale + Integration + Server-side Contract (Stages 11–12)](#8-pr-6--locale--integration--server-side-contract-stages-1112)
9. [Final Verification](#9-final-verification)
10. [Team Communication](#10-team-communication)
11. [What's Next](#11-whats-next)
12. [Migration corrections](#migration-corrections)
13. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Graduate the DataTable block from `sndq-clone` prototype into a production-grade `@sndq/ui-v2` export with full test coverage and docs, preserving the existing Layer 1 `Table` primitive contract.


**Feature summary:** [pr-summaries/data-table.md](./pr-summaries/data-table.md)  
**PR summaries:** [pr-summaries/README.md](./pr-summaries/README.md)

**Structure**: ~32 commits across 6 PRs.

| PR | Scope | Stages | Risk | Commits | Summary doc |
|----|-------|--------|------|---------|-------------|
| **PR 1** | Foundation + core hooks: types, test infra, `providers/`, `usePersistedTableState`, `useDataTable`, column-pinning utils, flat-table smoke | 0–1 | Low–Medium | 1–8 (+ providers refactor) | [pr-1-foundation-core-hooks.md](./pr-summaries/pr-1-foundation-core-hooks.md) |
| **PR 2** | Persistence (localStorage + URL) + Content rendering (flat + grouped) | 2–3 | Medium | 9–13 | [pr-2-persistence-content.md](./pr-summaries/pr-2-persistence-content.md) |
| **PR 3** | Sorting + global search + column filtering — **Phase 1 gate** | 4–5 | Medium | 14–18 | [pr-3-sort-search-filters.md](./pr-summaries/pr-3-sort-search-filters.md) |
| **PR 4** | Pagination + footer + selection + bulk actions + toolbar | 6–7 | Medium | 19–21 | [pr-4-pagination-selection-bulk.md](./pr-summaries/pr-4-pagination-selection-bulk.md) |
| **PR 5** | Settings + column config + editing + context menu + empty state | 8–10 | Medium | 22–25 | [pr-5-settings-editing-context.md](./pr-summaries/pr-5-settings-editing-context.md) |
| **PR 6** | Locale, barrel export, integration tests, server-side contract, docs — **Graduation PR** | 11–12 | Low–Medium | 26–32 | [pr-6-locale-integration-docs.md](./pr-summaries/pr-6-locale-integration-docs.md) |

**Why 6 PRs**: Each PR maps to a capability gate from the [testing-and-migration-stages](./testing-and-migration-stages.md). Stages 0–1 ship together in PR 1 (foundation + hooks + smoke test). PRs 1–3 unlock Phase 1 (EnrichTable migration for ~20 screens). PR 4 adds Phase 2 gate. PRs 5–6 complete Phase 3. Each is independently reviewable at ~4–9 commits and ~8–15 files.

### Prerequisites

- Layer 1 `Table` primitive exists and is tested in `sndq/packages/ui-v2/src/components/table/`
- `Flex`, `Checkbox`, `Badge`, `Button`, `Icon`, `Skeleton`, `DropdownMenu`, `Popover` are exported from `@sndq/ui-v2/components`
- `apps/docs` exists with Fumadocs for existing primitives
- Vitest + jsdom + RTL configured in `packages/ui-v2/vitest.config.ts`

### Known constraints

- `sndq-clone` data-table has uncommitted changes — use **working tree** as source of truth
- `@tanstack/react-table` is not in `@sndq/ui-v2` dependencies — must be added in PR 1
- `blocks/index.ts` is empty — `./blocks` export path must be added to `package.json`
- `useIsomorphicLayoutEffect` exists in `sndq-clone/packages/ui-v2/src/lib/hooks/` (17 lines) — **absent in sndq**, will be ported as first file in Commit 6
- `DataTableColumnConfig.tsx` uses manual reorder logic via `reorderColumnIds()` (from `utils/columnLayout.ts`) — no `@dnd-kit` dependency needed
- DataTable defaults to **server-side mode** (`manualSorting/Filtering/Pagination: true`) — this must be preserved

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
- [ ] Touched files diffed against sndq-clone counterpart; deviations recorded

### Source-of-truth and porting rules

1. **Behavior source** — `sndq-clone/packages/ui-v2/src/blocks/data-table` working tree. Diff each touched file against its clone counterpart before marking a commit complete.
2. **No ui-v2-dev** — Do not use `sndq-clone/apps/ui-v2-dev` (or other app layers) as an implementation reference during migration.
3. **No ARIA / a11y attributes** — Do not add or keep `aria-*`, accessibility-only `role=`, or similar in `@sndq/ui-v2` data-table. Strip them when porting from clone. Full a11y pass is out of migration scope.
4. **Allowed deviations** — Only when sndq primitives force it (e.g. Radix `Checkbox` indeterminate API) or when explicitly recorded under **Deviations from the gate** for that commit.
5. **No speculative guards** — Do not add behavior (e.g. early returns) unless a real callsite needs it. Test-only features that clone lacks should not ship unless documented and justified.
6. **Tests** — Test sndq behavior aligned with clone; do not add tests under sndq-clone.

### Documentation and comment policy

- Keep code comments minimal and focused on intent, invariants, or non-obvious behavior.
- Put usage examples, migration notes, variant tables, setup steps, and operational runbooks in docs, not inline code comments.
- Add deprecation notices only on the public export or entry point that consumers actually use.
- If docs and code disagree, update the docs in the same commit or record the gap as a deviation.

### Inspect source tree before implementation

Before the first implementation commit, inspect the actual repository state and record any differences from this plan.

- [ ] Confirm `sndq/packages/ui-v2/src/blocks/index.ts` exists and is empty
- [ ] Confirm `sndq/packages/ui-v2/package.json` has no `./blocks` export
- [ ] Confirm `@tanstack/react-table` is NOT in dependencies
- [ ] Confirm `sndq/packages/ui-v2/src/components/table/Table.tsx` Layer 1 primitive exists and passes tests
- [ ] Confirm existing `pnpm --filter @sndq/ui-v2 test` passes (19 existing test files)
- [ ] Confirm existing `pnpm --filter @sndq/ui-v2 type-check` passes
- [ ] Confirm `sndq-clone/packages/ui-v2/src/blocks/data-table/` has 39 files in working tree
- [x] Confirm `useIsomorphicLayoutEffect` location in sndq-clone and whether it needs porting — **confirmed**: `sndq-clone/packages/ui-v2/src/lib/hooks/useIsomorphicLayoutEffect.ts` (17 lines), absent in sndq, must be ported in Commit 6
- [x] Confirm whether `@dnd-kit` is used in `DataTableColumnConfig.tsx` — **NOT used**; column reorder is handled by `reorderColumnIds()` in `utils/columnLayout.ts`
- [ ] Confirm whether dependencies or lockfiles will change beyond `@tanstack/react-table`

### Capture baselines

Run these from the repository root and save the output. Diff against these after risky commits.

```bash
pnpm --filter @sndq/ui-v2 test 2>&1 | tee /tmp/dt-migration-test-before.txt
pnpm --filter @sndq/ui-v2 type-check 2>&1 | tee /tmp/dt-migration-typecheck-before.txt
```

---

## 3. PR 1 — Foundation + Core Hooks (Stages 0–1)

> **Summary:** Package wiring, types, `providers/`, test infra, state hook, `useDataTable`, column-pinning utils, flat-table smoke test.
> **PR summary doc:** [pr-summaries/pr-1-foundation-core-hooks.md](./pr-summaries/pr-1-foundation-core-hooks.md)

Package wiring, types, DataTable `providers/` layer, shared test infrastructure, state management, `useDataTable`, column-pinning utilities, and flat-table integration smoke test. Column definitions use `createColumnHelper` from `@tanstack/react-table` (not ui-v2 utils). Delivers a minimal client-side table pipeline before persistence lands in PR 2.

### Test file naming

Co-locate tests next to the source they cover. Use `.tsx` when the test file contains JSX; otherwise `.ts`.

| Kind | Pattern | Example |
|------|---------|---------|
| **Component** | `[PascalCase].test.tsx` | `__tests__/DataTable.test.tsx`, `__tests__/DataTableContext.test.tsx` (blocks); `DataTableSearch.test.tsx` (co-located) |
| **Integration** | `[PascalCaseFeature].integration.test.tsx` | `DataTableContentFlat.integration.test.tsx` |
| **Utils / hooks / pure logic** | `[camelCase].test.ts` (or `.tsx` if JSX) | `columnLayout.test.ts`, `useDataTable.test.tsx` |

Feature variants use concatenated PascalCase for integration tests (not dot suffixes): `DataTableContentFlat.integration.test.tsx`, not `DataTableContent.flat.test.tsx`. Hook feature areas may use a nested `describe('feature')` in the main hook test file (e.g. `describe('persistence')` in `usePersistedTableState.test.tsx`) or a separate camelCase sub-suite file when large (e.g. `useDataTableServerSide.test.tsx`).

**Blocks:** centralize block tests and shared helpers under `__tests__/` (component/integration tests + helpers). Module files and exported functions/constants use **camelCase** — e.g. `fixtures.ts` (`mockPeople`), `domHelpers.ts` (`getHeaderTexts`, `getVisibleRowCount`), `renderWithDataTable.tsx`. Types may stay PascalCase (e.g. `Person`).

**Block constants:** shared domain literals (column ids, storage keys, etc.) live in `constants/` — camelCase file names (e.g. `columns.ts`), `SCREAMING_SNAKE_CASE` exports (e.g. `SELECTION_COLUMN_ID`). Import from `constants/` in hooks, components, utils, and tests; do not repeat the raw string.

---

### Commit 1: Package wiring — add `@tanstack/react-table` + `./blocks` export

**What**: Add TanStack Table dependency and wire `./blocks` export path in `package.json`.

**Files to edit**:

- `packages/ui-v2/package.json` — add `@tanstack/react-table` to dependencies, add `"./blocks"` export pointing to `src/blocks/index.ts`
- `packages/ui-v2/src/blocks/index.ts` — placeholder comment (will be populated in later commits)

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| TanStack version mismatch with sndq-clone | LOW | Compare version in sndq-clone lockfile |
| Lockfile churn | LOW | Review `pnpm-lock.yaml` diff for unexpected transitive deps |

**Verification**:

```bash
pnpm install
pnpm --filter @sndq/ui-v2 type-check
pnpm --filter @sndq/ui-v2 test
```

**If it fails**:

- **"Cannot find module @tanstack/react-table"**: Version not resolved — check pnpm workspace protocol or catalog
- **Type-check errors**: Existing code may have TanStack types leaking — verify clean baseline

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add tanstack-table dep and blocks export`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 19 files / 153 tests passed
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [x] Committed

---

### Commit 2: Types — `EditorMeta`, `parseEditorValue`, TanStack `ColumnMeta` augmentation

**What**: Port `types/index.ts` and `types/tanstackTable.d.ts` from sndq-clone. These are self-contained with no component imports.

**Refactor note (applied during migration)**: sndq-clone made two structural changes applied here:
1. Replaced the flat `filterType` / `filterOptions` / `datePresets` / `className` / `editable` fields on `ColumnMeta` with a single `filter?: FilterMeta` discriminated union (`select | date | text`).
2. Extracted `submitOnBlur` out of each `EditorMeta` variant into a dedicated `EditorConfig` interface (`{ enableSubmitOnBlur?: boolean }`), replacing `submitOnBlur?: boolean` with `config?: EditorConfig` across all variants.
The files below reflect both refactored shapes.

**Files to create**:

- `src/blocks/data-table/types/index.ts` — `SelectOption`, `FilterMeta`, `EditorMeta`, `EditorValueMap`, `parseEditorValue`, `EditingOnSave` (component prop re-exports excluded — added incrementally as each component is ported). `FilterDatePreset` is inlined here until `utils/filters.ts` is ported in PR 3.
- `src/blocks/data-table/types/tanstackTable.d.ts` — `ColumnMeta` augmentation with 5 fields: `align`, `filter`, `editor`, `skeleton`, `groupable`

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `ColumnMeta` augmentation conflicts with existing table types | LOW | Verify no other `.d.ts` augments `@tanstack/react-table` |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 type-check
```

**If it fails**:

- **"Duplicate identifier ColumnMeta"**: Another augmentation exists — merge or scope

**Deviations from the gate**:

- **Tests deferred** — `parseEditorValue` unit tests ship in PR 5 (Commit 24) alongside editor components

**Commit message**: `feat: add data-table types and column meta`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 19 files / 153 tests passed; `parseEditorValue` unit tests deferred to PR 5 (Commit 24) per plan
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0; `FilterDatePreset` inlined in `types/index.ts` (import restored when `utils/filters.ts` ships in PR 3); `ColumnMeta` updated to refactored shape (`filter: FilterMeta` replaces stale flat fields)
- [ ] Committed

---

### Commit 3: DataTable provider + editing store

**What**: Port the DataTable context layer — table instance context, editing store, and root shell. Context concerns live under `providers/`; `DataTable.tsx` is the layout shell only.

**Refactor note (2026-06-22)**: Initial port placed all context logic in a single `DataTable.tsx`. Extracted into `providers/` in [Post-Commit 8: Extract `providers/`](#post-commit-8-extract-providers-folder) to match blocks folder convention in `packages/ui-v2/AGENTS.md`.

**Files to create**:

- `src/blocks/data-table/providers/DataTableContext.tsx` — `DataTableContext`, `useDataTableContext`, `DataTableProvider`
- `src/blocks/data-table/providers/EditingStoreContext.tsx` — `EditingCellStore`, `useEditingStore`, `EditingStoreProvider` (ref + listener store factory)
- `src/blocks/data-table/providers/DataTableProviders.tsx` — composes both providers
- `src/blocks/data-table/providers/index.ts` — public provider API re-exports
- `src/blocks/data-table/DataTable.tsx` — wraps `DataTableProviders` + `Flex` layout shell (`DataTableProps` stays here)

**Dependencies used**: `Flex` (exists in `@sndq/ui-v2/components`), `cn` (exists in `lib/utils`). `DataTableInstance` and `EditingCell` imported as `import type` from `./types` in provider files — the hook implementation comes in Commit 7. Internal consumers import hooks from `./providers`, not `./DataTable`.

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `EditingCell` type import from hooks that don't exist yet | LOW | Use `import type` — no runtime dependency |
| Internal import paths differ between sndq-clone and sndq | MEDIUM | Verify `../../components/flex` resolves correctly |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 type-check
```

**If it fails**:

- **"Cannot find module '../../components/flex'"**: Relative path differs — adjust to match sndq package structure

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable context provider`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 19 files / 153 tests passed
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0; `DataTableInstance` and `EditingCell` imported from `./types` in provider files (not re-exported from `DataTable.tsx`); `useDataTableContext` uses a cast (`as DataTableInstance<TData> | null`) to work around TypeScript's generic context assignability check
- [ ] Committed

---

### Commit 4: Shared test infrastructure

**What**: Create test fixtures and DOM helpers under `__tests__/`. These are the Stage 0 test infra deliverables from [testing-and-migration-stages.md](./testing-and-migration-stages.md). The `__tests__/` folder holds shared helpers; block component tests also live here (e.g. `__tests__/DataTable.test.tsx`).

**Files to create**:

- `src/blocks/data-table/__tests__/utils/fixtures.ts` — `Person` type, `mockPeople` array (3 rows with id, name, status, amount, date)
- `src/blocks/data-table/__tests__/utils/domHelpers.ts` — `getVisibleCellTexts(container, columnIndex?)`, `getVisibleRowCount(container)`, `getHeaderTexts(container)` (camelCase module + exports)
- `src/blocks/data-table/__tests__/utils/index.ts` — barrel re-export (added at PR 1 checkpoint)

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| DOM helpers assume specific table markup | LOW | Verify they work with Layer 1 Table component's rendered HTML |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 type-check
```

**If it fails**:

- **Type errors in fixtures**: Ensure `Person` type is self-contained, no external imports

**Deviations from the gate**:

- **No tests for the test infra itself** — these helpers are validated by consumer tests in Commit 5+
- **`renderWithDataTable` deferred to Commits 6–7** — requires hooks; mock-only helper remains inline in `DataTable.test.tsx`; real-hook `renderFlatTable` added in Commit 8 under `__tests__/utils/`

**Commit message**: `feat: add data-table test infrastructure`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 19 files / 153 tests passed; no dedicated test file for infra (validated in Commit 5+)
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed

---

### Commit 5: DataTable provider tests

**What**: Unit tests for the DataTable provider following the testing-and-migration-stages Stage 0 spec. Split by concern after providers extraction (2026-06-22).

**Files to create**:

- `src/blocks/data-table/__tests__/DataTable.test.tsx` — shell only; uses `createMockDataTableInstance` from `__tests__/utils/fixtures.ts`
- `src/blocks/data-table/__tests__/DataTableContext.test.tsx` — imports `useDataTableContext` from `../providers`
- `src/blocks/data-table/__tests__/EditingStoreContext.test.tsx` — imports `useEditingStore` / `DataTableProviders` from `../providers`

**Test cases**:

**`DataTable.test.tsx`** (1):

- [x] Renders children within provider

**`DataTableContext.test.tsx`** (1):

- [x] `useDataTableContext` throws when used outside `<DataTable>`

**`EditingStoreContext.test.tsx`** (4):

- [x] `useEditingStore` throws when used outside `<DataTable>`
- [x] Editing store: `subscribe` → `setEditingCell` → callback fires
- [x] Editing store: `getSnapshot` returns current cell
- [x] Editing store: `setEditingCell(null)` clears state

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Provider test needs a real `DataTableInstance` mock | MEDIUM | May need a minimal mock object satisfying the `Table<any>` interface |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/__tests__/DataTable.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/__tests__/DataTableContext.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/__tests__/EditingStoreContext.test.tsx
pnpm --filter @sndq/ui-v2 test
```

**If it fails**:

- **"Cannot create mock for DataTableInstance"**: Create a minimal mock factory in `__tests__/utils/fixtures.ts` that satisfies the type

**Deviations from the gate**:

- **None expected**

**Commit message**: `test: add DataTable provider tests`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 20 files / 159 tests passed at initial port (6 provider tests; split into 3 files after providers extraction — see Post-Commit 8)
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [x] Manual verification complete, if applicable — N/A (automated tests cover provider + editing store)
- [ ] Committed

---

### Commit 6: `usePersistedTableState` hook + tests

**What**: Port state management layer — all state slices (sorting, filters, pagination, selection, density, visibility, column sizing, column order, column pinning, grouping, expanded), change handlers, and `resetAllState`. **Without** persistence wiring — that ships in PR 2.

**Files to create**:

- `src/lib/hooks/useIsomorphicLayoutEffect.ts` — **must be ported from sndq-clone** (confirmed absent in sndq); 17-line file: `typeof window !== 'undefined' ? useLayoutEffect : useEffect` pattern
- `src/blocks/data-table/constants/columns.ts` — `SELECTION_COLUMN_ID` (`'_selection'`)
- `src/blocks/data-table/constants/index.ts` — constants barrel
- `src/blocks/data-table/hooks/usePersistedTableState.ts`
- `src/blocks/data-table/hooks/usePersistedTableState.test.tsx`
- `src/blocks/data-table/utils/columnPinning.ts` — strip/prepend selection column in pinning state
- `src/blocks/data-table/utils/stateUpdaters.ts` — `resolveUpdater` for TanStack functional updaters
- `src/blocks/data-table/utils/persistedTableBaseline.ts` — init/reset baseline for persisted slices
- `src/blocks/data-table/utils/columnPinning.test.ts`, `stateUpdaters.test.ts`, `persistedTableBaseline.test.ts`
- `src/blocks/data-table/hooks/useSelectionSyncedColumnPinning.ts` — syncs selection column when `enableSelection` toggles (internal; not exported from `hooks/index.ts` yet)
- `src/blocks/data-table/hooks/useSelectionSyncedColumnPinning.test.tsx`

**Test cases** (`usePersistedTableState.test.tsx`):

- [x] `onSortingChange` with functional updater
- [x] Density toggle updates state
- [x] `resetAllState()` clears session slices when no `initialState`
- [x] `resetAllState()` restores sorting and grouping from `initialState`
- [x] `resetAllState()` clears rowSelection and globalFilter even when set in `initialState`
- [x] `resetAllState()` restores columnPinning baseline with selection pinned
- [x] `resetAllState()` resets columnSizing to initial baseline
- [x] `resetAllState()` restores all TanStack slices and UI flags (density, selectAllMode, showFilters, showColumnConfig) to baseline

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `useIsomorphicLayoutEffect` absent in sndq | MEDIUM | **Confirmed absent** — port the 17-line file from sndq-clone as listed above |
| State slice count is large (11 slices) | LOW | Verify all TanStack state types import correctly |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/hooks/usePersistedTableState.test.tsx
pnpm --filter @sndq/ui-v2 type-check
```

**Deviations from the gate**:

- **Persistence wiring deferred** to PR 2 (Commits 9–10) — state management works but does not save/restore
- **`SELECTION_COLUMN_ID`** in `constants/columns.ts` — all selection column id references must import this constant (Commit 7+ when porting `useDataTable`, `columnLayout`, group header row)
- **Persisted hook types** in `types/persistedTableState.ts` — `DataTableTanStackState` / `DataTableUiState` are `Omit` / `Pick` of `DataTableState`; hook file is implementation-only

**Commit message**: `feat: add usePersistedTableState hook`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 21 files / 163 tests passed at initial port (8 in `hooks/usePersistedTableState.test.tsx`; expanded with column-pinning utils + `useSelectionSyncedColumnPinning` — see [pr-1-foundation-core-hooks.md](./pr-summaries/pr-1-foundation-core-hooks.md))
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0; persistence wiring intentionally absent until Commit 10; `useIsomorphicLayoutEffect` ported early (unused until Commit 10)
- [ ] Committed

---

### Commit 7: `useDataTable` hook + tests

**What**: Port the main hook that creates the TanStack Table instance with all feature flags, server/client mode logic, selection column injection, and the extended `DataTableInstance` API.

**Files to create**:

- `src/blocks/data-table/hooks/useDataTable.ts` — hook implementation only
- `src/blocks/data-table/hooks/index.ts` — hooks barrel
- `src/blocks/data-table/hooks/useDataTable.test.tsx`
- `src/blocks/data-table/types/dataTable.ts` — `DataTableOptions`, `DataTableInstance`, `DataTableState`, config types
- `src/blocks/data-table/constants/defaults.ts` — `DEFAULT_PAGE_SIZES`, `DEFAULT_SERVER_SIDE_CONFIG`

**Files to edit**:

- `src/blocks/data-table/types/index.ts` — re-export from `dataTable.ts`
- `src/blocks/data-table/constants/index.ts` — re-export columns + defaults constants
- `src/blocks/data-table/DataTable.tsx` — import `DataTableInstance` from `./types` (layout shell only; context in `providers/`)
- `src/blocks/data-table/__tests__/utils/fixtures.ts` — import `DataTableInstance` from `../../types`

**Test cases** (from testing-and-migration-stages Stage 1):

- [x] Default `enableSorting: true`
- [x] Row model length matches data
- [x] Sort changes row order with `clientSide: true`
- [x] `enableSelection` injects selection column (`SELECTION_COLUMN_ID` from `constants/columns.ts`)
- [x] `getSelectionCount()` returns correct count
- [x] `toggleGroupSelection()` on grouped rows
- [x] `toggleGroupSelection()` dedupes overlapping leaf rows

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `Checkbox` import path from `components/forms/checkbox` | MEDIUM | Verify path resolves in sndq package structure |
| Selection column uses internal `createElement` | LOW | Verify React import is correct |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/hooks/useDataTable.test.tsx
pnpm --filter @sndq/ui-v2 type-check
```

**If it fails**:

- **"Cannot find module '../../../components/forms/checkbox'"**: Adjust relative import path to match sndq's component structure

**Deviations from the gate**:

- **Checkbox indeterminate state** — sndq `Checkbox` uses Radix `checked: 'indeterminate'` instead of clone’s separate `indeterminate` prop
- **`config.persistence` omitted** until Commit 10 (matches state-only `usePersistedTableState`)
- **`DataTableTanStackOptions`** — `Pick<TableOptions, …>` for TanStack fields forwarded unchanged; SNDQ-only flags (`enablePagination`, `enableFiltering`, `enableSelection`, …) on `DataTableOptions`
- **Types/constants split** — hook API types in `types/dataTable.ts`; `DEFAULT_PAGE_SIZES` and `DEFAULT_SERVER_SIDE_CONFIG` in `constants/` (not inline in hook)
- **`SELECTION_COLUMN_ID`** from `constants/columns.ts`; a11y labels deferred (out of migration scope)

**Commit message**: `feat: add useDataTable hook`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 22 files / 169 tests passed at initial port (7 in `hooks/useDataTable.test.tsx`)
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0; `DataTable.tsx` + `fixtures.ts` wired to `types/dataTable.ts`; hook is implementation-only
- [ ] Committed

---

### Commit 8: Integration smoke — flat table renders

**What**: Minimal integration test proving the hook + provider + Layer 1 Table primitive pipeline works end-to-end.

**Files to create**:

- `src/blocks/data-table/__tests__/DataTableFlat.integration.test.tsx`
- `src/blocks/data-table/__tests__/utils/renderFlatTable.tsx` — shared test helper (`FlatTablePreview`, `renderFlatTable`, `basePersonColumns`)

**Test cases**:

- [x] Renders headers + N rows for flat data using `useDataTable` + `<DataTable>` provider + raw `<Table>` primitive
- [x] Empty data → no data rows rendered

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Layer 1 Table markup doesn't match expected structure | LOW | DOM helpers from Commit 4 may need adjustment |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/__tests__/DataTableFlat.integration.test.tsx
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **Sort-click DOM reorder** deferred to PR 2 `DataTableContent` tests (Stage 3) — Commit 8 smoke uses raw `Table` + `flexRender` only; no `DataTableContent` yet
- **`__tests__/utils/` layout** — test helpers moved from `__tests__/` root to `__tests__/utils/` (fixtures, domHelpers, renderFlatTable); column types use `typeof basePersonColumns` (not `ColumnDef<Person, unknown>`)
- **`renderFlatTable.tsx`** separate from mock-only `renderWithDataTable` inline in `DataTable.test.tsx`

**Commit message**: `test: add flat table integration smoke`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — 23 files / 171 tests passed (2 new in `__tests__/DataTableFlat.integration.test.tsx`)
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0; DOM helpers from Commit 4 work with Layer 1 `Table` markup unchanged
- [ ] Committed

---

### Post-Commit 8: Extract `providers/` folder

**What**: Refactor context concerns out of monolithic `DataTable.tsx` into `providers/` — one file per concern, composed by `DataTableProviders`. Aligns with blocks folder convention documented in `packages/ui-v2/AGENTS.md`.

**Files to create**:

- `src/blocks/data-table/providers/DataTableContext.tsx`
- `src/blocks/data-table/providers/EditingStoreContext.tsx`
- `src/blocks/data-table/providers/DataTableProviders.tsx`
- `src/blocks/data-table/providers/index.ts`

**Files to edit**:

- `src/blocks/data-table/DataTable.tsx` — layout shell only (`DataTableProviders` + `Flex`)
- `src/blocks/data-table/__tests__/DataTable.test.tsx` — shell test only (1 test)
- `src/blocks/data-table/__tests__/DataTableContext.test.tsx` — new (1 test)
- `src/blocks/data-table/__tests__/EditingStoreContext.test.tsx` — new (4 tests; moved from `DataTable.test.tsx`)
- `packages/ui-v2/AGENTS.md` — document `providers/` in blocks folder convention

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 type-check
pnpm --filter @sndq/ui-v2 test
```

**Commit message**: `refactor: extract data-table providers`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green — 29 files / 198 tests passed (2026-06-22); provider tests split across 3 files under `__tests__/`
- [x] Build / lint / type-check green — `tsc --noEmit` exit 0
- [ ] Committed

---

### PR 1 Checkpoint

Push after Commit 8 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feature/data-table-migration
# Create PR targeting dev
# Paste pr-summaries/pr-1-foundation-core-hooks.md into GitHub PR description
```

**This validates**: Package wiring works, types compile, `providers/` layer renders, test infra is usable, `usePersistedTableState` works, `useDataTable` creates valid TanStack Table instances (columns defined via `@tanstack/react-table` `createColumnHelper`), hook + provider + primitive pipeline renders. Existing primitive tests unaffected.

**Exit gate** (from testing-and-migration-stages Stages 0–1):

- [x] `pnpm --filter @sndq/ui-v2 test` green for all new + existing files — 29 files / 198 tests (2026-06-22; includes providers refactor + column-pinning utils)
- [x] `pnpm --filter @sndq/ui-v2 type-check` green — `tsc --noEmit` exit 0
- [x] No regressions in prior primitive tests
- [x] PR summary file filled in [pr-summaries/pr-1-foundation-core-hooks.md](./pr-summaries/pr-1-foundation-core-hooks.md) and pasted into GitHub PR description

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [x] Rollback instructions are clear — see [pr-1-foundation-core-hooks.md § Rollback](./pr-summaries/pr-1-foundation-core-hooks.md)

**Rollback** (summary): Revert PR or branch `feature/data-table-migration`. Scope: `packages/ui-v2/` + `pnpm-lock.yaml`. Then `pnpm install && pnpm --filter @sndq/ui-v2 test && pnpm --filter @sndq/ui-v2 type-check`.

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. PR 2 — Persistence + Content Rendering (Stages 2–3)

> **Summary:** URL/localStorage persistence + `DataTableContent` rendering (flat + grouped).
> **PR summary doc:** [pr-summaries/pr-2-persistence-content.md](./pr-summaries/pr-2-persistence-content.md)

Persistence (localStorage + URL) and the visual content layer — `DataTableContent`, `DataTableColumnHeader`, grouped rows, column layout utilities.

---

### Commit 9: `useTablePersistence` + tests

**What**: Port full persistence hook — URL + localStorage strategies, debounced save, sort/filter/group/pagination serialization.

**Files to create**:

- `src/lib/utils/debounce.ts`, `debounce.test.ts` — lodash-free debounce util (`cancel`, `flush`, `leading`, `trailing`)
- `src/lib/hooks/useUnmount.ts`
- `src/lib/hooks/useDebounceCallback.ts`, `useDebounceCallback.test.ts` — aligned with usehooks-ts tests (no lodash)
- `src/lib/hooks/useDebounceValue.ts`, `useDebounceValue.test.ts`
- `src/blocks/data-table/types/persistence.ts` — `PersistenceOptions`, `PersistedTableState`
- `src/blocks/data-table/constants/persistence.ts` — `DEFAULT_PERSISTENCE_PREFIX`, `DEFAULT_PERSISTENCE_DEBOUNCE_MS`
- `src/blocks/data-table/utils/tablePersistence.ts`, `tablePersistence.test.ts` — serializers, URL/localStorage I/O, `loadPersistedTableState`
- `src/blocks/data-table/hooks/useTablePersistence.ts`
- `src/blocks/data-table/hooks/useTablePersistence.test.ts`

**Files to edit**:

- `src/lib/hooks/useDebounce.ts` — thin wrapper over `useDebounceValue`
- `src/blocks/data-table/types/index.ts`, `constants/index.ts`, `utils/index.ts`

**Test cases** (from testing-and-migration-stages Stage 2):

- [x] `serializeSorting` / `parseSorting` round-trip
- [x] `storageKey` with scope
- [x] `readFromUrl` / `writeToUrl`
- [x] localStorage read/write
- [x] URL wins over localStorage on load
- [x] Debounced save doesn't loop
- [x] `QuotaExceededError` handled gracefully

**Mock**: `vi.stubGlobal('localStorage', ...)`, mock `window.location.search`

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| URL manipulation in jsdom | MEDIUM | Verify `window.location` mock works in vitest jsdom env |
| Debounce timer in tests | LOW | Use `vi.useFakeTimers()` + `vi.advanceTimersByTime()` |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/hooks/useTablePersistence.test.ts
```

**Deviations from the gate**:

- **AGENTS.md alignment** — persistence types/constants/utils extracted from hook; shared debounce layer in `src/lib/` without lodash; hook tests split (utils = pure I/O, hook = debounce/dedupe/unmount)

**Commit message**: `feat: add useTablePersistence hook`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — `tablePersistence.test.ts` (6) + `useTablePersistence.test.ts` (5) + lib debounce tests (15); full suite **34 files / 225 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed

---

### Commit 10: Persistence wiring in `usePersistedTableState` + tests

**What**: Wire `useTablePersistence` into `usePersistedTableState` so state hydrates from storage on mount and saves on change.

**Files to edit**:

- `src/blocks/data-table/types/persistedTableState.ts` — add `persistence?: PersistenceOptions` to options type
- `src/blocks/data-table/hooks/usePersistedTableState/usePersistedTableState.ts` — add persistence wiring
- `src/blocks/data-table/hooks/index.ts` — add `useTablePersistence` export

**Files to create**:

- (none — persistence cases live in nested `describe('persistence')` inside `usePersistedTableState.test.tsx`)

**Test cases**:

- [x] Mount with `strategy: 'localStorage'` → reload state survives
- [x] Change sort → URL updates when `strategy: 'url'`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/hooks/usePersistedTableState/usePersistedTableState.test.tsx
pnpm --filter @sndq/ui-v2 type-check
```

**Deviations from the gate**:

- **Subfolder paths** — hook and test live under `hooks/usePersistedTableState/` per AGENTS.md subfolder rule; `persistence` option added to `types/persistedTableState.ts` (not inline in hook); persistence tests merged into `usePersistedTableState.test.tsx` (`describe('persistence')`)

**Commit message**: `feat: wire persistence into table state`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — `usePersistedTableState.test.tsx` (10: 8 state + 2 persistence); full suite green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 11: Column layout + row utilities + tests

**What**: Port `utils/columnLayout.ts` and `utils/rows.ts` — pure functions for pinned columns, sort direction, group metadata.

**Files to create**:

- `src/blocks/data-table/utils/columnLayout/columnLayout.ts`
- `src/blocks/data-table/utils/columnLayout/columnLayout.test.ts`
- `src/blocks/data-table/utils/columnLayout/index.ts`
- `src/blocks/data-table/utils/rows/rows.ts`
- `src/blocks/data-table/utils/rows/rows.test.ts`
- `src/blocks/data-table/utils/rows/index.ts`

**Files to edit**:

- `src/blocks/data-table/utils/index.ts` — re-export columnLayout + rows

**Test cases** (from testing-and-migration-stages Stage 3):

- [x] `mapSortDirection` correctness
- [x] Pinned class/style helpers produce correct CSS
- [x] Layout styles when resizing
- [x] `getTopLevelRows` filters correctly
- [x] `getGroupRowMetadata` returns depth, count, label
- [x] `getGroupSelectionState` returns all / indeterminate / none

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/utils/columnLayout/columnLayout.test.ts
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/utils/rows/rows.test.ts
pnpm --filter @sndq/ui-v2 type-check
```

**Deviations from the gate**:

- **Subfolder paths** — utils live under `utils/columnLayout/` and `utils/rows/` per AGENTS.md subfolder rule (not flat `utils/columnLayout.ts`)

**Commit message**: `feat: add column layout and row utils`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — `columnLayout.test.ts` (16) + `rows.test.ts` (5); full suite **37 files / 253 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 12: `DataTableContent` + `DataTableColumnHeader` + `DataTableGroupHeaderRow`

**What**: Port the visual rendering layer — the main content component, column headers, and group header rows.

**Files to create**:

- `src/blocks/data-table/DataTableContent.tsx`
- `src/blocks/data-table/DataTableColumnHeader.tsx`
- `src/blocks/data-table/DataTableGroupHeaderRow.tsx`
- `src/blocks/data-table/DataTableEditableCell.tsx` — pass-through stub (Commit 24 replaces)
- `src/blocks/data-table/DataTableRowContextMenu.tsx` — early port (Content compile dependency)

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Internal imports to Layer 1 Table compound components | MEDIUM | Verify `TableRow`, `TableHead`, `TableCell`, `TableGroupHeader` etc. are all exported |
| Context dependency on `useDataTableContext` | LOW | `providers/` from PR 1 must be in scope; import from `./providers`, not `./DataTable` |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 type-check
pnpm --filter @sndq/ui-v2 test   # regression guard; no new tests this commit
```

**Deviations from the gate**:

- **Tests in Commit 13** — component code ships separately from tests for reviewability
- **`DataTableEditableCell.tsx` pass-through stub** — full editor/popover impl in Commit 24
- **`DataTableRowContextMenu.tsx` ported early** — Commit 25 adds tests only
- **Context imports from `./providers`** — not `./DataTable` (providers refactor from PR 1)
- **Group checkbox uses Radix `checked="indeterminate"`** — sndq `Checkbox` has no separate `indeterminate` prop (clone used `indeterminate` boolean)

**Commit message**: `feat: add DataTableContent and header components`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — no new tests; existing suite **37 files / 242 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 13: Content tests (flat + grouped)

**What**: Component tests for content rendering.

**Files to create**:

- `src/blocks/data-table/__tests__/DataTableContentFlat.integration.test.tsx`
- `src/blocks/data-table/__tests__/DataTableContentGrouped.integration.test.tsx`
- `src/blocks/data-table/__tests__/utils/renderContentTable.tsx` (helper)
- Update `__tests__/utils/renderFlatTable.tsx` to delegate to `ContentTablePreview`
- Update `__tests__/utils/domHelpers.ts` (`getSkeletonCount`, `getHeaderCell`, `getBodyCell`, `getGroupHeaderRow`)

**Test cases** (from testing-and-migration-stages Stage 3):

Flat:
- [x] Loading skeleton rows
- [x] Custom `emptyState` renders
- [x] Column alignment from meta
- [x] Pinned columns get sticky classes
- [x] Body cell layout updates when columnSizing changes (FlatRow memo regression)

Grouped:
- [x] Single-level grouping shows group headers
- [x] Expand/collapse toggles child rows
- [x] Group checkbox calls `toggleGroupSelection`
- [x] `renderGroupSummary` slot renders

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/__tests__/DataTableContentFlat.integration.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/__tests__/DataTableContentGrouped.integration.test.tsx
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **Tests under `__tests__/`** — per AGENTS.md block test layout (Commit 8 precedent), not block-root paths from the gate doc
- **`renderFlatTable` refactored** — delegates to `ContentTablePreview`; Commit 8 smoke test updated for empty table (`TableEmptyRow` → 1 tbody row)
- **Grouped expand/collapse fixture** — `mockPeople` has Jack + Tom in `draft`, Lucy in `approved` (tests assert Tom, not Lucy)

**Commit message**: `test: add DataTableContent flat and grouped tests`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **8 new tests** (4 flat + 4 grouped); full suite **39 files / 250 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

**Post-port follow-up (FlatRow memo)**:

`FlatRow` uses `React.memo` for row-data/selection perf and relies on `DataTableEditableCell`'s editing store for inline edit updates. The memo comparator must also receive `layoutRevision` (from `columnSizing`, `columnPinning`, `columnVisibility`, `columnOrder`) or body cells show stale widths/pinning/visibility after layout changes while headers update. Fixed in follow-up commit; regression test added to `DataTableContentFlat.integration.test.tsx`.

---

### PR 2 Checkpoint

**This validates**: Full rendering pipeline works. Persistence serializes/deserializes correctly. Column layout math is correct. Grouped rows render with expand/collapse.

**Exit gate**:

- [x] `pnpm --filter @sndq/ui-v2 test` green for all new + existing files — **39 files / 250 tests** (2026-06-22)
- [x] `pnpm --filter @sndq/ui-v2 type-check` green — `tsc --noEmit` exit 0
- [x] No regressions in PR 1 tests — 9 PR 1 data-table test files / **46 tests** green
- [x] PR summary file filled in [pr-summaries/pr-2-persistence-content.md](./pr-summaries/pr-2-persistence-content.md) and pasted into GitHub PR description

**Status**:

- [x] PR created — [#3285](https://github.com/sndqapp/sndq/pull/3285)
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 5. PR 3 — Sort + Search + Filters (Stages 4–5)

> **Summary:** Sort, global search, column filters — unlocks Phase 1 (EnrichTable).
> **PR summary doc:** [pr-summaries/pr-3-sort-search-filters.md](./pr-summaries/pr-3-sort-search-filters.md) *(create when opening this PR)*

The interaction layer — users can sort columns, search globally, and apply column filters. Combined with PRs 1–2, this PR unlocks the **Phase 1 gate** (EnrichTable migration for ~20 screens).

---

### Commit 14: `DataTableSearch` + tests

**What**: Port global search component with debounced input.

**Files to create**:

- `src/blocks/data-table/DataTableSearch.tsx`
- `src/blocks/data-table/DataTableSearch.test.tsx`

**Test cases**:

- [x] Search input visible on mount (always-expanded)
- [x] Typing updates filter after debounce (fake timers)
- [x] Clear button restores all rows when input has value

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableSearch.test.tsx
pnpm --filter @sndq/ui-v2 type-check
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **No `useUILocale`** — `placeholder` defaults to `'Search...'` until Commit 26 (locale)
- **`useDebounceCallback`** — replaces clone's manual `setTimeout` debounce (behavior-equivalent impl diff)
- **Co-located test file** — `DataTableSearch.test.tsx` at block root per migration test naming exception

**Commit message**: `feat: add DataTableSearch component`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **3 co-located tests**; full suite **45 files / 296 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 15: Column header sort wiring + tests

**What**: Port sort header interaction from clone — click on header cell cycles asc → desc → none. `toggleSorting` wiring in `DataTableContent` already done in Commit 12.

**Files to edit**:

- `src/blocks/data-table/DataTableColumnHeader.tsx` — align with clone: `onClick` on `TableHead`, sort icon, no inner button

**Files to create**:

- `src/blocks/data-table/DataTableColumnHeader.test.tsx`

**Test cases**:

- [x] Click cycles asc → desc → none
- [x] Sort indicator matches direction (icon: `arrowUp` / `arrowDown` / `arrowUpDown`)
- [x] Non-sortable header omits sort icon when `onSort` is omitted

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableColumnHeader.test.tsx
pnpm --filter @sndq/ui-v2 type-check
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **`toggleSorting` in `DataTableContent`** — wired in Commit 12; Commit 15 is header + tests only
- **Co-located test file** — `DataTableColumnHeader.test.tsx` at block root per migration test naming exception

**Commit message**: `feat: add column header sorting`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **3 co-located tests**; full suite **45 files / 296 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 16: `utils/filters` + tests

**What**: Port filter utilities — `toggleFilterArrayValue`, `normalizeFilterValues`, `filterOptionsBySearch`, `datePresetFilterFn`, date presets.

**Files to create**:

- `src/blocks/data-table/utils/filters.ts`
- `src/blocks/data-table/utils/filters.test.ts`

**Files to edit**:

- `src/blocks/data-table/utils/index.ts` — add filter exports

**Test cases**:

- [x] `toggleFilterArrayValue` add/remove/clear
- [x] `normalizeFilterValues` handles edge cases
- [x] `filterOptionsBySearch` filters correctly
- [x] `datePresetFilterFn` with frozen `Date`
- [x] `autoRemove` returns true for empty filter

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/utils/filters.test.ts
pnpm --filter @sndq/ui-v2 type-check
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add filter utilities`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **6 unit tests**; full suite **46 files / 302 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 17: `DataTableFilterMenu` + tests

**What**: Port filter menu component — property-based column filtering with multi-select, date presets, and search within options.

**Files to create**:

- `src/blocks/data-table/DataTableFilterMenu.tsx`
- `src/blocks/data-table/DataTableFilterMenu.test.tsx`

**Test cases**:

- [x] Open menu shows properties
- [x] Toggle option filters rows
- [x] Badge count on trigger
- [x] Date preset applies filter
- [x] Search within options

**Pattern**: Assert **visible row names** after filter, not `columnFilters` state.

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableFilterMenu.test.tsx
```

**Deviations from the gate**:

- **Strip a11y from clone port** — remove `role`, `aria-selected`, `aria-hidden` (no a11y attributes in sndq data-table)
- **No `useUILocale`** — hardcoded EN filter strings until Commit 26

**Commit message**: `feat: add DataTableFilterMenu component`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **47 files / 307 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 18: `DataTableActiveFilters` + tests

**What**: Port active filters bar — sort pill, filter pills, clear all.

**Files to create**:

- `src/blocks/data-table/DataTableActiveFilters.tsx`
- `src/blocks/data-table/DataTableActiveFilters.test.tsx`

**Test cases**:

- [x] Sort pill visible when sorting active
- [x] Dismiss removes sort
- [x] One pill per active column filter
- [x] Remove pill clears filter
- [x] "Clear all" resets all filters

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableActiveFilters.test.tsx
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **No `useUILocale`** — hardcoded EN activeFilters strings until Commit 26

**Commit message**: `feat: add DataTableActiveFilters component`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **48 files / 312 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### PR 3 Checkpoint

```bash
git push -u origin feature/data-table-migration
```

**This validates**: Sort, search, and filter interactions work end-to-end. Combined with PRs 1–2, this unlocks the **Phase 1 gate** (EnrichTable migration for ~20 screens).

**Exit gate**:

- [ ] `pnpm --filter @sndq/ui-v2 test` green
- [ ] `pnpm --filter @sndq/ui-v2 type-check` green
- [ ] No regressions
- [ ] PR summary file filled in [pr-summaries/pr-3-sort-search-filters.md](./pr-summaries/pr-3-sort-search-filters.md) and pasted into GitHub PR description

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 6. PR 4 — Pagination + Selection + Bulk Actions (Stages 6–7)

> **Summary:** Pagination, footer, row selection, bulk actions, toolbar.
> **PR summary doc:** [pr-summaries/pr-4-pagination-selection-bulk.md](./pr-summaries/pr-4-pagination-selection-bulk.md) *(create when opening this PR)*

Pagination controls, row selection, and bulk action bar. Unlocks **Phase 2 gate** (CompactTable migration for ~31 screens).

---

### Commit 19: `utils/pagination` + `DataTablePagination` + `DataTableFooter` + tests

**What**: Port pagination utilities and components.

**Files to create**:

- `src/blocks/data-table/utils/pagination.ts`
- `src/blocks/data-table/utils/pagination.test.ts`
- `src/blocks/data-table/DataTablePagination.tsx`
- `src/blocks/data-table/DataTablePagination.test.tsx`
- `src/blocks/data-table/DataTableFooter.tsx`
- `src/blocks/data-table/DataTableFooter.test.tsx`

**Files to edit**:

- `src/blocks/data-table/utils/index.ts` — add pagination exports

**Test cases**:

Utils:
- [x] `getPaginationRange(0, 10, 25)` → 1–10
- [x] Edge: last page range
- [x] `formatPaginationSummary` empty → "0 results"

Pagination:
- [x] Next/prev disabled at bounds
- [x] Page indicator text
- [x] Page size change updates visible row count (client-side)

Footer:
- [x] Renders children alongside pagination slot

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/utils/pagination.test.ts
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTablePagination.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableFooter.test.tsx
```

**Deviations from the gate**:

- **No `useUILocale`** — hardcoded EN pagination strings until Commit 26
- **Server-side pagination tests deferred** to PR 6 (Stage 12b)

**Commit message**: `feat: add pagination and footer components`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **52 files / 322 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 20: Selection + `DataTableSelectionBar` + tests

**What**: Port selection UI — row checkboxes, header select-all, selection bar with count and "select all across dataset".

**Files to create**:

- `src/blocks/data-table/DataTableSelectionBar.tsx`
- `src/blocks/data-table/DataTableContentSelection.integration.test.tsx`
- `src/blocks/data-table/DataTableSelectionBar.test.tsx`

**Test cases**:

Content selection:
- [x] Row checkbox toggles selection
- [x] Header checkbox selects page
- [x] Indeterminate when partial

Selection bar:
- [x] Hidden when count 0
- [x] Shows N selected
- [x] "Select all {total}" sets `selectAllMode`
- [x] Deselect one row clears `selectAllMode`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableContentSelection.integration.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableSelectionBar.test.tsx
```

**Deviations from the gate**:

- **No `useUILocale`** — hardcoded EN selection strings until Commit 26

**Commit message**: `feat: add selection and selection bar`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **54 files / 329 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### Commit 21: `DataTableBulkActions` + `DataTableToolbar` + tests

**What**: Port bulk action bar and toolbar visibility toggling.

**Files to create**:

- `src/blocks/data-table/DataTableBulkActions.tsx`
- `src/blocks/data-table/DataTableToolbar.tsx`
- `src/blocks/data-table/DataTableBulkActions.test.tsx`
- `src/blocks/data-table/DataTableToolbar.test.tsx`

**Test cases**:

BulkActions:
- [x] Renders actions slot
- [x] Passes `totalCount` to render prop
- [x] Escape deselects all

Toolbar:
- [x] Hidden when selection active
- [x] Visible when selection cleared

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableBulkActions.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableToolbar.test.tsx
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **Strip a11y from clone port** — remove `aria-modal` from `DataTableBulkActions` (no a11y attributes in sndq data-table)
- **Toolbar visibility toggling** — clone `DataTableToolbar` is layout-only (`Flex` wrapper); added `useDataTableContext` + early return when `getSelectionCount() > 0` per Commit 21 spec and [architecture.md](./architecture.md)

**Commit message**: `feat: add bulk actions and toolbar`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented — **56 files / 334 tests** green
- [x] Build / lint / type-check green or deviation documented — `tsc --noEmit` exit 0
- [ ] Committed — manual commit by developer

---

### PR 4 Checkpoint

**This validates**: Full pagination, selection, and bulk action flow works. Unlocks **Phase 2 gate** (CompactTable migration for ~31 screens).

**Exit gate**:

- [x] `pnpm --filter @sndq/ui-v2 test` green — **56 files / 334 tests**
- [x] `pnpm --filter @sndq/ui-v2 type-check` green — exit 0
- [x] No regressions — full suite green (312 → 334 tests across Commits 19–21)
- [x] PR summary file filled in [pr-summaries/pr-4-pagination-selection-bulk.md](./pr-summaries/pr-4-pagination-selection-bulk.md) and pasted into GitHub PR description

**Status**:

- [x] PR created — https://github.com/sndqapp/sndq/pull/3301
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 7. PR 5 — Settings + Editing + Context Menu (Stages 8–10)

> **Summary:** Settings, column config, editable cells, context menu, empty state.
> **PR summary doc:** [pr-summaries/pr-5-settings-editing-context.md](./pr-summaries/pr-5-settings-editing-context.md) *(create when opening this PR)*

Column configuration, inline editing, row context menu, and empty state.

---

### Commit 22: `utils/grouping` + tests

**What**: Port grouping utilities — `computeGroupingLevels`, `buildGroupingAfterSelect`, `removeGroupingFromLevel`.

**Files to create**:

- `src/blocks/data-table/utils/grouping.ts`
- `src/blocks/data-table/utils/grouping.test.ts`

**Files to edit**:

- `src/blocks/data-table/utils/index.ts` — add grouping exports

**Test cases**:

- [ ] `computeGroupingLevels` empty → empty
- [ ] `computeGroupingLevels` one level
- [ ] `computeGroupingLevels` max depth
- [ ] `buildGroupingAfterSelect` adds level
- [ ] `removeGroupingFromLevel` removes level

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/utils/grouping.test.ts
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add grouping utilities`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 23: `DataTableSettings` + `DataTableColumnConfig` + tests

**What**: Port settings panel (density, page size, grouping) and column configuration (visibility, reorder).

**Files to create**:

- `src/blocks/data-table/DataTableSettings.tsx`
- `src/blocks/data-table/DataTableColumnConfig.tsx`
- `src/blocks/data-table/DataTableSettings.test.tsx`
- `src/blocks/data-table/DataTableColumnConfig.test.tsx`

**Note**: Column reorder is handled by `reorderColumnIds()` from `utils/columnLayout.ts` (ported in Commit 11). No extra drag-and-drop library is needed.

**Test cases**:

Settings:
- [ ] Density toggle updates table density class
- [ ] Page size change
- [ ] Group field sets grouping state

Column config:
- [ ] Toggle visibility hides column
- [ ] Reorder updates header order (trigger `reorderColumnIds` via drag-end callback)

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Settings panel uses Popover | LOW | `Popover` exists in `@sndq/ui-v2/components` |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableSettings.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableColumnConfig.test.tsx
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add settings and column config`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 24: Editors + `DataTableEditableCell` + tests

**What**: Port inline editing — editor renderers (text, currency, select, custom), editable cell component, and `parseEditorValue` tests.

**Files to create**:

- `src/blocks/data-table/editors.tsx`
- `src/blocks/data-table/DataTableEditableCell.tsx`
- `src/blocks/data-table/editors.test.tsx`
- `src/blocks/data-table/DataTableEditableCell.test.tsx`
- `src/blocks/data-table/parseEditorValue.test.ts`

**Test cases**:

`parseEditorValue`:
- [ ] text → string
- [ ] currency → number
- [ ] select → string
- [ ] custom → passthrough

Editors:
- [ ] Each editor renders correct input type
- [ ] Currency parses number

EditableCell:
- [ ] Click opens editor
- [ ] Enter saves and calls `onSave`
- [ ] Escape cancels without saving
- [ ] Only one cell open at a time (via editing store)
- [ ] `submitOnBlur` behavior

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/parseEditorValue.test.ts
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/editors.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableEditableCell.test.tsx
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add inline editing components`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 25: `DataTableRowContextMenu` + `DataTableEmptyState` + tests

**What**: Port row context menu (right-click actions) and empty state component. `DataTableRowContextMenu.tsx` was ported early in Commit 12; this commit adds tests and strips a11y roles from the existing file.

**Files to create**:

- `src/blocks/data-table/DataTableEmptyState.tsx`
- `src/blocks/data-table/DataTableRowContextMenu.test.tsx`
- `src/blocks/data-table/DataTableEmptyState.test.tsx`

**Files to edit**:

- `src/blocks/data-table/DataTableRowContextMenu.tsx` — strip `role="menu"` / `role="menuitem"` (already exists from Commit 12)

**Test cases**:

Context menu:
- [ ] Right-click opens menu
- [ ] Action calls handler with row data
- [ ] Destructive styling on destructive actions
- [ ] Escape closes menu

Empty state:
- [ ] Renders title/description
- [ ] Spans full colspan via content integration

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableRowContextMenu.test.tsx
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableEmptyState.test.tsx
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **`DataTableRowContextMenu.tsx` ported early in Commit 12** — a11y roles stripped in clone-alignment pass; Commit 25 adds tests only (tests updated to avoid `role` queries)

**Commit message**: `feat: add context menu and empty state`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### PR 5 Checkpoint

```bash
git push -u origin feature/data-table-migration
```

**This validates**: All 15 sub-components exist. Settings panel works. Inline editing lifecycle is correct. Context menu integrates with row data.

**Exit gate**:

- [ ] `pnpm --filter @sndq/ui-v2 test` green
- [ ] `pnpm --filter @sndq/ui-v2 type-check` green
- [ ] No regressions
- [ ] PR summary file filled in [pr-summaries/pr-5-settings-editing-context.md](./pr-summaries/pr-5-settings-editing-context.md) and pasted into GitHub PR description

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 8. PR 6 — Locale + Integration + Server-side Contract (Stages 11–12)

> **Summary:** Locale, public barrel, integration + server-side contract tests, MDX docs — graduation.
> **PR summary doc:** [pr-summaries/pr-6-locale-integration-docs.md](./pr-summaries/pr-6-locale-integration-docs.md) *(create when opening this PR)*

Final graduation: locale support, public barrel export, composition integration tests, server-side contract tests, and docs.

---

### Commit 26: Locale files + tests

**What**: Port all 4 locale files and the locale barrel.

**Files to create**:

- `src/blocks/data-table/locale/types.ts`
- `src/blocks/data-table/locale/en.ts`
- `src/blocks/data-table/locale/nl.ts`
- `src/blocks/data-table/locale/de.ts`
- `src/blocks/data-table/locale/fr.ts`
- `src/blocks/data-table/locale/index.ts`
- `src/blocks/data-table/locale/index.test.ts`

**Test cases**:

- [ ] All locales export required keys
- [ ] EN fallback works when key missing

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/locale/index.test.ts
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add data-table locale support`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 27: Public barrel `index.ts` + types barrel update

**What**: Wire the compound `DataTable` export with all 15 sub-components using `Object.assign`. Update `types/index.ts` with all component prop type re-exports now that all components exist.

**Files to create**:

- `src/blocks/data-table/index.ts` — compound export

**Files to edit**:

- `src/blocks/data-table/types/index.ts` — add all component prop type re-exports (`DataTableContentProps`, `DataTableToolbarProps`, `DataTableSearchProps`, etc.)
- `src/blocks/index.ts` — re-export `data-table` barrel

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 type-check
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: wire data-table public barrel export`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 28: Composition integration tests

**What**: Integration tests validating the three composition patterns from the architecture doc.

**Files to create**:

- `src/blocks/data-table/DataTable.integration.test.tsx`

**Test cases** (from testing-and-migration-stages Stage 11):

- [ ] **Compact**: Content + Pagination only renders without error
- [ ] **Enrich**: Content + Footer renders without error
- [ ] **Full**: Toolbar + Search + FilterMenu + ActiveFilters + SelectionBar + Content + Footer + Pagination renders without error
- [ ] Export surface: `DataTable.*` subcomponents all attach correctly (`DataTable.Content`, `DataTable.Toolbar`, etc.)

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTable.integration.test.tsx
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `test: add DataTable composition integration tests`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 29: Server-side `useDataTable` tests

**What**: Tests validating server-side mode behavior — the default mode where sorting, filtering, and pagination are manual (state changes don't transform data locally).

**Files to create**:

- `src/blocks/data-table/hooks/useDataTableServerSide.test.tsx`

**Test cases** (from testing-and-migration-stages Stage 12a):

- [ ] Default without `clientSide` → `manualSorting`, `manualFiltering`, `manualPagination` are `true` when those features enabled
- [ ] `config.clientSide: true` → all manual flags `false`; row models transform data locally
- [ ] `serverSide.pageCount` + `rowCount` passed → `table.getPageCount()` matches `pageCount`; `table.getRowCount()` matches `rowCount`
- [ ] Sort header clicked in manual mode → `sorting` state updates; **row cell order unchanged** (same `data` prop)
- [ ] Filter applied in manual mode → `columnFilters` updates; **visible rows unchanged** until `data` prop updates
- [ ] Page next in manual mode → `pagination.pageIndex` increments; `getCanNextPage()` respects `pageCount`
- [ ] Partial override: `serverSide: { isManualPagination: false, ... }` merges with defaults

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/hooks/useDataTableServerSide.test.tsx
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `test: add server-side useDataTable tests`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 30: Server-side pagination tests

**What**: Tests validating pagination summary and controls use server totals, not local row count.

**Files to create**:

- `src/blocks/data-table/DataTablePaginationServerSide.integration.test.tsx`

**Test cases** (from testing-and-migration-stages Stage 12b):

- [ ] Manual pagination with `rowCount: 47`, page size 10, page 0 → summary shows **1–10 of 47** (not of 10)
- [ ] Last page partial → **41–47 of 47**
- [ ] `pageCount: 5` → "Page X of 5"; last-page button disabled on page 5
- [ ] `rowCount: 0` → "0 results"; prev/next disabled

**Known library concern**: `DataTablePagination` currently uses `table.getFilteredRowModel().rows.length` for summary totals. In manual mode that equals page size, not server total. Tests should assert use of `table.getRowCount()` when `rowCount` is set.

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTablePaginationServerSide.integration.test.tsx
```

**Deviations from the gate**:

- **May require a fix** to `DataTablePagination.tsx` if it doesn't use `table.getRowCount()` — fix in same commit if needed

**Commit message**: `test: add server-side pagination tests`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 31: Server-side integration contract test

**What**: End-to-end contract test simulating the `ServerSideDemo` pattern — mock fetch + `useState`, no React Query.

**Files to create**:

- `src/blocks/data-table/DataTableServerSide.integration.test.tsx`

**Test cases** (from testing-and-migration-stages Stage 12c):

- [ ] Initial render → mock fetch called with default pagination/sort/filter params
- [ ] Click sort → fetch called with new `sorting`; new `data` prop renders updated rows
- [ ] Change page → fetch params include new `pageIndex`; only new slice rendered
- [ ] Apply filter → fetch params include `columnFilters`; pagination uses server `rowCount`
- [ ] Loading → `DataTable.Content loading` shows skeletons; no data rows

**Verification**:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/DataTableServerSide.integration.test.tsx
pnpm --filter @sndq/ui-v2 test
```

**Deviations from the gate**:

- **None expected**

**Commit message**: `test: add server-side integration contract`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### Commit 32: Docs — DataTable block MDX page

**What**: Create the Fumadocs MDX page using Template B (block page) from [docs-templates.md](../../../restructure/monorepo-ui-design-system/templates/docs-templates.md).

**Files to create**:

- `apps/docs/content/docs/blocks/data-table.mdx`

**Sections**:

- Overview: what DataTable solves, when to use
- Composition tree: `DataTable` + 15 sub-components
- Built from: Layer 1 `Table`, `Button`, `Checkbox`, `Badge`, `DropdownMenu`, `Popover`, `Skeleton`
- Usage: import from `@sndq/ui-v2/blocks`, basic example
- Props: `DataTableProps`, key sub-component props
- Customization: density, locale, persistence strategies
- Examples: Compact (Content + Pagination), Enrich (Content + Footer), Full (all sub-components), Server-side wiring recipe
- Related: `Table` primitive, `Checkbox`, `DropdownMenu`

**Verification**:

```bash
# Verify docs build if applicable
pnpm --filter docs build 2>&1 | tail -20
```

**Deviations from the gate**:

- **Playground deferred** — DataTable is a Tier 2 block; playground is optional per docs-templates.md

**Commit message**: `docs: add DataTable block documentation`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Committed

---

### PR 6 Checkpoint

```bash
git push -u origin feature/data-table-migration
```

**This validates**: Full DataTable API is exported and documented. All 13 stages have passing tests. Server-side contract matches `ServerSideDemo` pattern. **Phase 3 gate** (CommonTable migration for ~35 screens) is unlocked.

**Exit gate** (graduation gate from testing-and-migration-stages):

- [ ] `pnpm --filter @sndq/ui-v2 test` green — all unit + component + server integration tests
- [ ] `pnpm --filter @sndq/ui-v2 type-check` green
- [ ] MDX docs section published for public API
- [ ] No regressions in any prior stage tests

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Risky behavior has a manual smoke test result
- [ ] Rollback instructions are clear
- [ ] PR summary file filled in [pr-summaries/pr-6-locale-integration-docs.md](./pr-summaries/pr-6-locale-integration-docs.md) and pasted into GitHub PR description

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 9. Final Verification

After all ~32 commits across 6 PRs, run the full suite from the repository root:

```bash
pnpm --filter @sndq/ui-v2 test
pnpm --filter @sndq/ui-v2 type-check
pnpm --filter @sndq/ui-v2 test --coverage
```

Compare against baselines:

```bash
diff /tmp/dt-migration-test-before.txt <(pnpm --filter @sndq/ui-v2 test 2>&1)
diff /tmp/dt-migration-typecheck-before.txt <(pnpm --filter @sndq/ui-v2 type-check 2>&1)
```

**Manual verification**:

- [ ] All prior 19 primitive tests still pass
- [ ] New data-table tests pass (~50–60 new tests across ~25 test files)
- [ ] Type-check clean
- [ ] `DataTable` exports correctly from `@sndq/ui-v2/blocks`
- [ ] MDX docs page renders in `apps/docs`
- [ ] Coverage includes all utils, hooks, and component contract tests

**Expected result**: All tests pass. Zero regressions. DataTable is a production-grade export from `@sndq/ui-v2/blocks` with full test coverage across all 13 stages and complete Fumadocs documentation.

**Final status**:

- [ ] All ~32 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes
- [ ] Tests pass or missing coverage is documented
- [ ] Output matches expected baselines
- [ ] Manual verification complete
- [ ] All 6 PRs created and merged

---

## 10. Team Communication

Send to the team before merging PR 6 (the graduation PR):

> **Heads up: DataTable block graduating to `@sndq/ui-v2`**
>
> PR [link] completes the migration of the DataTable block from `sndq-clone` to `packages/ui-v2/src/blocks/data-table/`. After pulling:
>
> 1. Run `pnpm install` (new `@tanstack/react-table` dependency)
> 2. Import from `@sndq/ui-v2/blocks` (not from `sndq-clone`)
>
> Files that changed and may conflict:
> - `packages/ui-v2/package.json` (new dependencies)
> - `packages/ui-v2/src/blocks/index.ts` (new barrel export)
>
> Known follow-ups:
> - Consumer migration (prototype app tables) is a separate track
> - `AGENTS.md` for the package should be created post-merge
> - Visual regression baselines to be added after core is stable

---

## 11. What's Next

After all 6 PRs are merged, proceed to **consumer migration** — moving prototype tables from `sndq-clone/apps/prototype` to use `@sndq/ui-v2/blocks` imports.

See [testing-and-migration-stages.md § Stage → production migration mapping](./testing-and-migration-stages.md) for the phase alignment:

| Production phase | Stages required | Unlocked by |
|------------------|-----------------|-------------|
| Phase 1: EnrichTable (~20 screens) | 0–3 + 4 (sort only) | PR 3 merge |
| Phase 2: CompactTable (~31 screens) | + 6 + 2 (URL persistence) | PR 4 merge |
| Phase 3: CommonTable (~35 screens) | + 5, 7, 8, 9, 10, 12 | PR 6 merge |

### Lessons to carry forward

- Port utils and pure functions first — they have zero dependencies and are easiest to test
- Test infrastructure (fixtures, DOM helpers) pays off immediately in later stages
- Server-side mode is the default — every stage that adds a feature must consider manual mode behavior
- Assert **visible UI outcomes** (row names, cell text), not TanStack internal state
- One test file at a time; run before moving on

### Known lessons from prior phases

- Phase 0 execution (22 commits in sndq-clone) showed that the `DataTablePagination` server-side totals issue needs explicit test coverage — addressed in Stage 12b
- `useIsomorphicLayoutEffect` dependency was non-obvious — verify early in Commit 6 (PR 1)

---

## Migration corrections

Resolved 2026-06-22. Commits 14–15 were initially implemented against ui-v2-dev / Stage 4 a11y spec; corrected to match `sndq-clone/packages/ui-v2` per [Source-of-truth and porting rules](#source-of-truth-and-porting-rules).

| Commit | What drifted | Resolution |
|--------|--------------|------------|
| **14** | ui-v2-dev collapse/expand search + `aria-label` + `enableGlobalFilter` guard | **Done** — always-visible `InputGroup`; 3 tests; no guard |
| **15** | Inner sort `<button>`, `aria-sort`, `aria-label` | **Done** — `onClick` on `TableHead`; 3 tests |
| **12 (early RowContextMenu)** | `role="menu"` / `role="menuitem"` | **Done** — roles stripped; context menu tests use text queries |

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| 2026-06-21 | — | Doc: merged PR 1+2 into single PR (6 PRs total); added pr-summaries/ convention |
| | 1 | |
| | 2 | |
| | 3 | |
| | 4 | |
| | 5 | |
| 2026-06-21 | — | Removed column helper utils (`createColumnHelper` re-export, `compactColumn`, adapters); apps use `@tanstack/react-table` `createColumnHelper` + `ColumnMeta` augmentation; PR 1 commits renumbered 1–8 |
| 2026-06-21 | 6 | usePersistedTableState state-only + 4 hook tests; useIsomorphicLayoutEffect ported |
| 2026-06-21 | 7 | useDataTable hook + 6 hook tests; types in `types/dataTable.ts`; defaults in `constants/defaults.ts`; hooks barrel |
| 2026-06-21 | 8 | flat table integration smoke; `__tests__/utils/renderFlatTable.tsx`; 2 tests in `__tests__/DataTableFlat.integration.test.tsx` |
| 2026-06-21 | PR 1 checkpoint | verify 23/171 + type-check green; pr-1-foundation-core-hooks.md + data-table.md; ready for manual push/PR |
| 2026-06-22 | — | Refactor: extract `providers/` from `DataTable.tsx`; split provider tests; update AGENTS.md + pr-1 summary |
| 2026-06-22 | Post-8 | providers/ folder (`DataTableContext`, `EditingStoreContext`, `DataTableProviders`); 29 files / 198 tests green |
| 2026-06-22 | 9 | `useTablePersistence` + AGENTS split (`types/persistence`, `constants/persistence`, `utils/tablePersistence`); shared debounce (`lib/utils/debounce`, `useDebounceCallback`, `useDebounceValue`, refactor `useDebounce`); **34 files / 225 tests** green; not exported from hooks barrel until Commit 10 |
| 2026-06-22 | 10 | persistence wired into `usePersistedTableState`; merged persistence tests into hook test file; **36 files / 232 tests** green |
| 2026-06-22 | 11 | `utils/columnLayout/` + `utils/rows/` ported with 21 unit tests; **37 files / 253 tests** green |
| 2026-06-22 | 12 | `DataTableContent`, `DataTableColumnHeader`, `DataTableGroupHeaderRow` + EditableCell stub + early RowContextMenu; **37 files / 242 tests** green |
| 2026-06-22 | 13 | Content integration tests (flat + grouped); `renderContentTable` helper; **39 files / 250 tests** green |
| 2026-06-22 | 13+ | FlatRow `layoutRevision` fix + integration test |
| 2026-06-22 | 14 | `DataTableSearch` clone-aligned; **3 co-located tests** |
| 2026-06-22 | 15 | Column header sort clone-aligned; **3 co-located tests**; **45 files / 296 tests** green |
| 2026-06-22 | 14–15 | Clone-alignment pass: search + header + RowContextMenu role strip |
| 2026-06-22 | — | Doc: clone-first porting rules + Commits 14–15 correction spec (no ARIA, no ui-v2-dev) |
| 2026-06-22 | 16 | `utils/filters` + 6 unit tests; **46 files / 302 tests** green |
| 2026-06-22 | 17 | `DataTableFilterMenu` + 5 tests; **47 files / 307 tests** green |
| 2026-06-22 | 18 | `DataTableActiveFilters` + 5 tests; **48 files / 312 tests** green |
| 2026-06-22 | 19 | pagination utils + Pagination + Footer + 7 tests; **52 files / 322 tests** green |
| 2026-06-22 | 20 | `DataTableSelectionBar` + 7 tests; **54 files / 329 tests** green |
| 2026-06-22 | 21 | `DataTableBulkActions` + `DataTableToolbar` + 5 tests; **56 files / 334 tests** green |
| | 22 | |
| | 23 | |
| | 24 | |
| | 25 | |
| | 26 | |
| | 27 | |
| | 28 | |
| | 29 | |
| | 30 | |
| | 31 | |
| | 32 | |
| | 33 | |
