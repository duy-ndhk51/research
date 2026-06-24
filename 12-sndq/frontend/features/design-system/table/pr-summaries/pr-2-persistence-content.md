# DataTable — Persistence + Content Rendering

**Block:** `DataTable` · **Tier:** 2 (Block)

## Summary

Adds table state persistence (localStorage + URL) wired into `usePersistedTableState`, column layout and grouped-row utilities, and the visual content layer (`DataTableContent`, column headers, group header rows). Delivers flat and grouped rendering through the Layer 1 `Table` primitive with integration tests covering loading, empty state, alignment, pinning, and grouping interactions.

## Design decisions

- **Scope** — `useTablePersistence` hook + serializers (`tablePersistence` utils), persistence wiring in `usePersistedTableState`, shared debounce utilities in `src/lib/`, `columnLayout` + `rows` pure utils, `DataTableContent` / `DataTableColumnHeader` / `DataTableGroupHeaderRow`, test helpers (`renderContentTable`, extended `domHelpers`). Stubs: `DataTableEditableCell` (pass-through), early `DataTableRowContextMenu` (compile dependency).
- **Dependencies** — Reuses `providers/`, `useDataTable`, Layer 1 `Table`, `Checkbox`, `Badge`, `Button`, `Skeleton`. No new npm packages.
- **Key patterns** — Persistence types/constants/utils in dedicated subfolders per AGENTS.md; URL wins over localStorage on hydrate; debounced save without feedback loops; grouped rows use `getTopLevelRows` / `getGroupRowMetadata`; content tests assert visible DOM (`data-selected`, sticky styles, skeleton count) via `__tests__/utils/`.
- **Not included** — Global search, column filters, sort UI, pagination footer, toolbar, settings/column config, full cell editing, context menu behavior tests, barrel export from `@sndq/ui-v2/blocks`, user-facing docs under `apps/docs/`.

## Test coverage

**`utils/tablePersistence/tablePersistence.test.ts`** — 6 tests:

- Sorting serialize/parse round-trip
- Storage key scoping
- URL read/write
- localStorage read/write
- URL precedence over localStorage on load
- QuotaExceededError handled gracefully

**`hooks/useTablePersistence/useTablePersistence.test.ts`** — 5 tests:

- Debounced save does not loop
- Unmount flush
- Strategy-specific hydrate/save behavior

**`hooks/usePersistedTableState/usePersistedTableState.test.tsx`** — 10 tests (includes persistence `describe`):

- State-only cases from foundation (functional updaters, reset slices, baselines)
- Mount with `localStorage` strategy survives reload
- Sort change updates URL when `strategy: 'url'`

**`utils/columnLayout/columnLayout.test.ts`** — 5 tests:

- `mapSortDirection` correctness
- Pinned class/style helpers
- Layout styles when resizing

**`utils/rows/rows.test.ts`** — 5 tests:

- `getTopLevelRows` filters correctly
- `getGroupRowMetadata` returns depth, count, label
- `getGroupSelectionState` returns all / indeterminate / none

**`__tests__/DataTableContentFlat.integration.test.tsx`** — 4 tests:

- Loading skeleton rows
- Custom `emptyState` renders
- Column alignment from meta
- Pinned columns get sticky classes

**`__tests__/DataTableContentGrouped.integration.test.tsx`** — 4 tests:

- Single-level grouping shows group headers
- Expand/collapse toggles child rows
- Group checkbox calls `toggleGroupSelection`
- `renderGroupSummary` slot renders

**`__tests__/DataTableFlat.integration.test.tsx`** — 2 tests (updated smoke):

- Renders headers + rows via `DataTableContent`
- Empty data renders empty-state row

**Verification (2026-06-22):** 39 test files / 250 tests passed; `tsc --noEmit` exit 0; foundation data-table test files (46 tests across 9 files) green — no regressions.

## Package / token changes

- `src/lib/utils/debounce.ts`, `useDebounceCallback`, `useDebounceValue`, `useUnmount` — shared debounce layer (lodash-free)
- `packages/ui-v2/AGENTS.md` — persistence + utils subfolder conventions
- No shared token or CSS changes

## Review checklist

- [x] Scope covers persistence hook, state wiring, layout/row utils, content components, integration tests
- [x] `pnpm --filter @sndq/ui-v2 test` and `type-check` green (39 files / 250 tests)
- [x] No regressions in foundation data-table tests (46/46)
- [ ] Search, filters, pagination, settings intentionally absent
- [ ] `./blocks` barrel still placeholder — expected
