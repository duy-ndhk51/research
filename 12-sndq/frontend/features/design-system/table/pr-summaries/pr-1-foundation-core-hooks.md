# DataTable — Foundation + Core Hooks

**Block:** `DataTable` · **Tier:** 2 (Block)

## Summary

Introduces the DataTable block foundation in `@sndq/ui-v2`: package wiring, domain types, a `providers/` layer (table instance context + editing store), the `DataTable` root shell, shared test infrastructure, `usePersistedTableState` (state-only), `useDataTable`, column-pinning utilities, and a flat-table integration smoke test. Delivers a minimal client-side pipeline (`useDataTable` → `<DataTable>` → Layer 1 `Table` + `flexRender`).

## Design decisions

- **Scope** — Types (`columnMeta`, `dataTable`, `persistedTableState`), constants, `providers/` (context + hooks), `DataTable.tsx` layout shell, hooks, pure utils (`columnPinning`, `stateUpdaters`, `persistedTableBaseline`), test helpers under `__tests__/utils/`, integration smoke. No content/toolbar/pagination components yet.
- **Providers layout** — Context concerns live under `providers/`: `DataTableContext.tsx` (table instance + `useDataTableContext`), `EditingStoreContext.tsx` (editing store + `useEditingStore`), `DataTableProviders.tsx` (composes both). `DataTable.tsx` only wraps `DataTableProviders` and the `Flex` layout shell. Internal consumers import hooks from `./providers`, not `./DataTable`.
- **Dependencies** — `@tanstack/react-table ^8.21.2`; `./blocks` export in `package.json` (placeholder barrel). Layer 1 `Table`, `Flex`, `Checkbox` from existing `@sndq/ui-v2/components`.
- **Key patterns** — `types/index.ts` is export portal only; `hooks/index.ts` exports hooks only (no type re-exports). Column defs use `createColumnHelper` from `@tanstack/react-table` + `ColumnMeta` augmentation. Server-side manual mode is default in `useDataTable`; smoke test uses `config.clientSide: true`. Selection column pinning is handled via `utils/columnPinning.ts` and internal `useSelectionSyncedColumnPinning` (not exported from `hooks/index.ts` yet).
- **Not included** — URL/localStorage persistence wiring, `DataTableContent` and related UI, `parseEditorValue` unit tests, sort-click DOM integration tests. `useIsomorphicLayoutEffect` is present but unused by this PR’s hooks.

## Test coverage

**`__tests__/DataTable.test.tsx`** — 1 test:

- Renders children within provider

**`__tests__/DataTableContext.test.tsx`** — 1 test:

- `useDataTableContext` throws outside `<DataTable>`

**`__tests__/EditingStoreContext.test.tsx`** — 4 tests:

- `useEditingStore` throws outside `<DataTable>`
- Editing store: subscribe → setEditingCell → callback fires
- Editing store: getSnapshot returns current cell
- Editing store: setEditingCell(null) clears state

**`hooks/usePersistedTableState.test.tsx`** — 8 tests:

- `onSortingChange` functional updater
- Density toggle
- `resetAllState()` clears session slices when no `initialState`
- `resetAllState()` restores sorting and grouping from `initialState`
- `resetAllState()` clears rowSelection and globalFilter even when set in `initialState`
- `resetAllState()` restores columnPinning baseline with selection pinned
- `resetAllState()` resets columnSizing to initial baseline
- `resetAllState()` restores all TanStack slices and UI flags (density, selectAllMode, showFilters, showColumnConfig) to baseline

**`hooks/useDataTable.test.tsx`** — 7 tests:

- Default `enableSorting: true`
- Row model length matches data
- Sort changes row order with `clientSide: true`
- `enableSelection` injects selection column (`SELECTION_COLUMN_ID`)
- `getSelectionCount()` returns correct count
- `toggleGroupSelection()` on grouped rows
- `toggleGroupSelection()` dedupes overlapping leaf rows

**`hooks/useSelectionSyncedColumnPinning.test.tsx`** — 8 tests:

- Selection column pinned left when `enableSelection` is true
- `onColumnPinningChange` re-inserts selection column when omitted
- `onColumnPinningChange` keeps selection column first when pinning another column left
- `onColumnPinningChange` passes through unchanged when `enableSelection` is false
- Prepends selection column when `enableSelection` toggles false → true
- Removes selection column when `enableSelection` toggles true → false
- Functional updater uses derived pinning after `enableSelection` toggle
- `setColumnPinning` syncs selection column when `enableSelection` is true

**`utils/columnPinning.test.ts`** — 8 tests:

- Strips / prepends / deduplicates selection column in pinning state
- Functional and value updaters preserve user pinning without selection column

**`utils/persistedTableBaseline.test.ts`** — 5 tests:

- Init mirrors full `initialState`
- Reset restores config slices but clears session slices
- Reset stores user column pinning from `initialState`
- Strips selection column from columnPinning baseline
- Empty `initialState` produces hook fallbacks

**`utils/stateUpdaters.test.ts`** — 2 tests:

- Value updater passthrough
- Functional updater applied to old state

**`__tests__/DataTableFlat.integration.test.tsx`** — 2 tests:

- Renders headers + N rows for flat data (`useDataTable` + provider + raw `Table` primitive)
- Empty data → no data rows rendered

**Verification (2026-06-22):** 29 test files / 199 tests passed; `tsc --noEmit` exit 0; no regressions in prior primitive tests.

## Package / token changes

- `packages/ui-v2/package.json` — add `@tanstack/react-table`, `"./blocks"` export
- `packages/ui-v2/src/blocks/index.ts` — placeholder barrel
- `packages/ui-v2/AGENTS.md` — documents `providers/` in blocks folder convention
- No shared token or CSS changes

## Review checklist

- [x] Scope covers types, providers, hooks, utils, test infra, and integration smoke
- [x] `pnpm --filter @sndq/ui-v2 test` and `type-check` green (29 files / 199 tests)
- [x] No regressions in prior primitive tests
- [ ] Persistence wiring intentionally absent
- [ ] `DataTableContent` intentionally absent
- [ ] `./blocks` barrel still placeholder — expected
