# SNDQ DataTable — Testing & Migration Stages

Reference for **graduating** `packages/ui-v2/src/blocks/data-table` to production-grade `@sndq/ui-v2` exports in stages — each stage ships docs and defines test coverage before the next stage begins.

**Related docs:**

| Doc | Purpose |
|-----|---------|
| [overview.md](./overview.md) | Short architecture reference |
| [architecture.md](./architecture.md) | Full deep-dive, feature matrix, production migration phases |
| [execution.md](./execution.md) | How Phase 0 was built (22 implementation commits) |
| **This doc** | What to graduate when, docs per stage, test ideas per feature |

**Source implementation:** `sndq-clone/packages/ui-v2/src/blocks/data-table`

**Server-side reference app:** `sndq-clone/apps/prototype/src/modules/demo/ServerSideDemo.tsx`

---

## Testing philosophy

Patterns borrowed from libraries in the workspace:

| Pattern | Source | Apply to SNDQ |
|---------|--------|---------------|
| **Feature-split test files** | Ant Design (`Table.filter.test.tsx`, `Table.sorter.test.tsx`, …) | One test file per DataTable sub-feature, not one mega file |
| **Outcome helpers** | Ant Design `renderedNames()`, React Spectrum callback assertions | `getVisibleCellTexts()`, `getSelectedRowIds()` — assert row order, not TanStack internals |
| **Unit-test pure logic first** | TanStack `table-core` | `utils/*`, `types/parseEditorValue`, persistence serializers |
| **Hook tests with `renderHook`** | MRT / TanStack integration style | `useDataTable`, `usePersistedTableState`, `useTablePersistence` |
| **Thin primitive contract tests** | Mantine `Table.test.tsx` | Layer 1 `components/table` — classes, compound exports, density |
| **One integration smoke per stage** | Ant Design base `Table.test.tsx` | Minimal composed tree per graduation gate |
| **Don't test TanStack** | Universal | Assert visible UI + callbacks, not `table.getState()` everywhere |

**SNDQ conventions** (`packages/ui-v2/.cursor/skills/frontend-testing/`):

- Vitest + React Testing Library, co-located `*.test.tsx`
- AAA pattern, one behavior per test
- Prefer `getByRole` over `data-testid`
- Mock only: `localStorage`, `window.location`, timers — not sibling ui-v2 components
- Process order: **utils → hooks → subcomponents → integration**

---

## Shared test infrastructure (Stage 0)

Create under `packages/ui-v2/src/blocks/data-table/__tests__/` (or `test-utils/`):

```typescript
// fixtures.ts
export type Person = {
  id: string;
  name: string;
  status: string;
  amount: number;
  date: string;
};

export const mockPeople: Person[] = [
  { id: '1', name: 'Jack', status: 'draft', amount: 100, date: '2026-06-01' },
  { id: '2', name: 'Lucy', status: 'approved', amount: 200, date: '2026-06-15' },
  { id: '3', name: 'Tom', status: 'draft', amount: 150, date: '2026-06-10' },
];

// renderWithDataTable.tsx
// - build columns via createColumnHelper
// - useDataTable({ ...options, config: { clientSide: true } }) for client-side stages
// - wrap in <DataTable table={table}>{children}</DataTable>

// dom-helpers.ts
export function getVisibleCellTexts(container: HTMLElement, columnIndex?: number): string[];
export function getVisibleRowCount(container: HTMLElement): number;
export function getHeaderTexts(container: HTMLElement): string[];
```

**Docs deliverable (Stage 0):** docs page — "Testing DataTable" with fixture example only.

---

## Exit gate (every stage)

- [ ] `pnpm --filter @sndq/ui-v2 test` green for new files in that stage
- [ ] `pnpm --filter @sndq/ui-v2 type-check` green
- [ ] MDX docs section published for that stage's public API
- [ ] No regressions in prior stage tests

---

## Stage 0 — Foundation: Table primitives + shell

**Graduate:** `components/table/*`, `DataTable.tsx` (context + editing store), `types/index.ts` (editor parsing)

**Docs:** Layer 1 primitive API + `DataTable` provider / `useDataTableContext` / `useEditingStore`

| Test file | Type | Test ideas |
|-----------|------|------------|
| `components/table/Table.test.tsx` | Component | Renders `<table>`; density context affects padding classes; `TableRow` `data-selected`; compound exports |
| `blocks/data-table/DataTable.test.tsx` | Component | Renders children; throws when `useDataTableContext` used outside provider; editing store subscribe/notify |

**Skip:** TanStack, sorting, filters.

---

## Stage 1 — Core hook (client-side table)

**Graduate:** `hooks/useDataTable.ts`, `hooks/usePersistedTableState.ts` (without URL)

**Column definitions:** use `createColumnHelper` from `@tanstack/react-table` with `ColumnMeta` from `types/tanstackTable.d.ts` (see prototype `DataTableDemo.tsx`). No ui-v2 column helper utils.

**Docs:** `useDataTable` options, `enable*` flags, `config.clientSide: true` vs server default

| Test file | Type | Test ideas |
|-----------|------|------------|
| `hooks/useDataTable.test.tsx` | Hook | Default `enableSorting: true`; row model length matches data; sort changes row order with `clientSide: true`; `enableSelection` injects `_selection` column; `getSelectionCount()`; `toggleGroupSelection()` on grouped rows |
| `hooks/usePersistedTableState.test.tsx` | Hook | `onSortingChange` functional updater; density toggle; `resetAllState()` clears sorting/filters; selection column pinned left when `enableSelection` |

**Integration smoke:** `DataTableContent.flat.test.tsx` (minimal)

- Renders headers + N rows for flat data
- Empty data → empty state or `TableEmptyRow`
- Click sort header → visible row order changes (Ant Design `renderedNames` pattern)

---

## Stage 2 — Persistence

**Graduate:** `hooks/useTablePersistence.ts`, persistence wiring in `usePersistedTableState`

**Docs:** `PersistenceOptions`, strategy matrix, URL param names (`dt_sort`, `dt_filters`, …)

| Test file | Type | Test ideas |
|-----------|------|------------|
| `hooks/useTablePersistence.test.ts` | Unit | `serializeSorting` / `parseSorting` round-trip; `storageKey` with scope; `readFromUrl` / `writeToUrl`; localStorage read/write; URL wins over localStorage on load; debounced save doesn't loop; `QuotaExceededError` handled gracefully |
| `hooks/usePersistedTableState.persistence.test.tsx` | Hook | Mount with `strategy: 'localStorage'` → reload state; change sort → URL updates when `strategy: 'url'` |

**Mock:** `vi.stubGlobal('localStorage', ...)`, mock `window.location.search`.

---

## Stage 3 — Content rendering (flat + grouped)

**Graduate:** `DataTableContent.tsx`, `DataTableColumnHeader.tsx`, `DataTableGroupHeaderRow.tsx`, `utils/columnLayout.ts`, `utils/rows.ts`

**Docs:** Content props (`loading`, `emptyState`, `renderGroupHeader`, `contextMenuActions`)

| Test file | Type | Test ideas |
|-----------|------|------------|
| `utils/columnLayout.test.ts` | Unit | `mapSortDirection`, pinned class/style helpers, layout styles when resizing |
| `utils/rows.test.ts` | Unit | `getTopLevelRows`, `getGroupRowMetadata`, `getGroupSelectionState` (all / indeterminate / none) |
| `DataTableContent.flat.test.tsx` | Component | Loading skeleton rows; custom `emptyState`; column alignment from meta; pinned columns get sticky classes |
| `DataTableContent.grouped.test.tsx` | Component | Single-level grouping shows group headers; expand/collapse toggles child rows; group checkbox calls `toggleGroupSelection`; `renderGroupSummary` slot renders |

---

## Stage 4 — Sorting + global search

**Graduate:** `DataTableSearch.tsx`, sort wiring in column headers / active filters (sort pill)

**Docs:** Sort interaction, global filter debounce

| Test file | Type | Test ideas |
|-----------|------|------------|
| `DataTableSearch.test.tsx` | Component | Collapsed → expanded on click; typing updates filter after debounce (fake timers); clear resets rows; disabled when `enableGlobalFilter: false` |
| `DataTableColumnHeader.test.tsx` | Component | Sortable header has button; click cycles asc → desc → none; sort indicator matches direction |
| `DataTableActiveFilters.sort.test.tsx` | Component | Sort pill visible when sorting active; dismiss removes sort; pill opens sort editor |

---

## Stage 5 — Filtering

**Graduate:** `utils/filters.ts`, `DataTableFilterMenu.tsx`, `DataTableActiveFilters.tsx` (filter pills)

**Docs:** Filter property types, date presets, multi-select filter values

| Test file | Type | Test ideas |
|-----------|------|------------|
| `utils/filters.test.ts` | Unit | `toggleFilterArrayValue` add/remove/clear; `normalizeFilterValues`; `filterOptionsBySearch`; `datePresetFilterFn` with frozen `Date`; `autoRemove` |
| `DataTableFilterMenu.test.tsx` | Component | Open menu shows properties; toggle option filters rows; badge count on trigger; date preset applies filter; search within options |
| `DataTableActiveFilters.filters.test.tsx` | Component | One pill per active column filter; remove pill clears filter; "Clear all" resets; edit pill reopens values |

**Pattern:** Assert **visible row names** after filter, not `columnFilters` state.

---

## Stage 6 — Pagination + footer

**Graduate:** `utils/pagination.ts`, `DataTablePagination.tsx`, `DataTableFooter.tsx`

**Docs:** Client vs manual pagination, summary format

| Test file | Type | Test ideas |
|-----------|------|------------|
| `utils/pagination.test.ts` | Unit | `getPaginationRange(0, 10, 25)` → 1–10; edge last page; `formatPaginationSummary` empty → "0 results" |
| `DataTablePagination.test.tsx` | Component | Next/prev disabled at bounds; page indicator text; page size change updates visible row count (**client-side**) |
| `DataTableFooter.test.tsx` | Component | Renders children alongside pagination slot |

---

## Stage 7 — Selection + bulk actions

**Graduate:** selection column in `useDataTable`, `DataTableSelectionBar.tsx`, `DataTableBulkActions.tsx`, `DataTableToolbar.tsx`

**Docs:** Page select vs select-all-across-dataset (`selectAllMode`)

| Test file | Type | Test ideas |
|-----------|------|------------|
| `DataTableContent.selection.test.tsx` | Component | Row checkbox toggles selection; header checkbox selects page; indeterminate when partial |
| `DataTableSelectionBar.test.tsx` | Component | Hidden when count 0; shows N selected; "Select all {total}" sets `selectAllMode`; deselect one row clears selectAllMode |
| `DataTableToolbar.test.tsx` | Component | Hidden when selection active; visible when selection cleared |
| `DataTableBulkActions.test.tsx` | Component | Renders actions slot; passes `totalCount` to render prop; Escape deselects all |

---

## Stage 8 — Settings + column config

**Graduate:** `DataTableSettings.tsx`, `DataTableColumnConfig.tsx`, `utils/grouping.ts`

**Docs:** Density, page size, grouping levels, column visibility/reorder

| Test file | Type | Test ideas |
|-----------|------|------------|
| `utils/grouping.test.ts` | Unit | `computeGroupingLevels` empty / one level / max depth; `buildGroupingAfterSelect`; `removeGroupingFromLevel` |
| `DataTableSettings.test.tsx` | Component | Density toggle updates table density class; page size change; group field sets grouping state |
| `DataTableColumnConfig.test.tsx` | Component | Toggle visibility hides column; reorder updates header order (mock `@dnd-kit` drag end if needed) |

---

## Stage 9 — Editing

**Graduate:** `DataTableEditableCell.tsx`, `editors.tsx`, `types/index.ts` (`parseEditorValue`, `EditorMeta`)

**Docs:** Editor variants (text, currency, select, custom), `onSave` contract — see [editable-cell-v2.md](./editable-cell-v2.md)

| Test file | Type | Test ideas |
|-----------|------|------------|
| `types/editor.test.ts` | Unit | `parseEditorValue` for text/currency/select/custom |
| `editors.test.tsx` | Component | Each editor renders input; currency parses number |
| `DataTableEditableCell.test.tsx` | Component | Click opens editor; Enter saves and calls `onSave`; Escape cancels; only one cell open at a time; `submitOnBlur` behavior |

---

## Stage 10 — Row context menu + empty state

**Graduate:** `DataTableRowContextMenu.tsx`, `DataTableEmptyState.tsx`

**Docs:** Context menu actions API, empty state composition

| Test file | Type | Test ideas |
|-----------|------|------------|
| `DataTableRowContextMenu.test.tsx` | Component | Right-click opens menu; action calls handler with row; destructive styling; Escape closes |
| `DataTableEmptyState.test.tsx` | Component | Renders title/description; spans full colspan via content integration |

---

## Stage 11 — Locale + integration contracts

**Graduate:** `locale/*`, public barrel `index.ts`, types barrel

**Docs:** Full compound API reference, composition recipes (CommonTable / CompactTable / EnrichTable)

| Test file | Type | Test ideas |
|-----------|------|------------|
| `locale/index.test.ts` | Unit | All locales export required keys; EN fallback |
| `DataTable.integration.test.tsx` | Integration | **Compact:** Content + Pagination only; **Enrich:** Content + Footer; **Full:** Toolbar + Search + FilterMenu + ActiveFilters + SelectionBar + Content + Footer + Pagination; export surface: `DataTable.*` subcomponents attach correctly |

**Graduation gate** before sndq-fe Phase 1 (EnrichTable migration).

---

## Stage 12 — Server-side mode

Server-side is the **default** in `useDataTable` (`manualSorting`, `manualFiltering`, `manualPagination: true` unless `config.clientSide: true`). Reference wiring: `ServerSideDemo.tsx`.

### Application pattern (outside ui-v2)

1. `data` prop = **current page slice** from API
2. `config.serverSide.rowCount` / `pageCount` = server totals
3. Sync `table.getState()` → fetch params → refetch → update `data`
4. `DataTable.Content loading={isLoading}` during fetch
5. `DataTable.BulkActions totalCount={totalRows}` for cross-dataset context

### Known library concern

`DataTablePagination` currently uses `table.getFilteredRowModel().rows.length` for summary totals. In manual mode that equals **page size**, not server total. Tests should assert use of `table.getRowCount()` when `rowCount` is set (see `ServerSideDemo` with 50+ total rows and 10 per page).

### 12a — `useDataTable` server config

**File:** `hooks/useDataTable.serverSide.test.tsx`

| Test idea | Assert |
|-----------|--------|
| Default without `clientSide` | `manualSorting`, `manualFiltering`, `manualPagination` are `true` when those features enabled |
| `config.clientSide: true` | All manual flags `false`; row models transform data locally |
| `serverSide.pageCount` + `rowCount` passed | `table.getPageCount()` matches `pageCount`; `table.getRowCount()` matches `rowCount` |
| Sort header clicked in manual mode | `sorting` state updates; **row cell order unchanged** (same `data` prop) |
| Filter applied in manual mode | `columnFilters` updates; **visible rows unchanged** until `data` prop updates |
| Page next in manual mode | `pagination.pageIndex` increments; `getCanNextPage()` respects `pageCount` |
| Partial override | `serverSide: { isManualPagination: false, ... }` merges with defaults |

### 12b — `DataTablePagination` server totals

**File:** `DataTablePagination.serverSide.test.tsx`

| Test idea | Assert |
|-----------|--------|
| Manual pagination with `rowCount: 47`, page size 10, page 0 | Summary shows **1–10 of 47** (not of 10) |
| Last page partial | Page 4 → **41–47 of 47** |
| `pageCount: 5` | "Page X of 5"; last-page button disabled on page 5 |
| `rowCount: 0` | "0 results"; prev/next disabled |

### 12c — Server-side integration contract

**File:** `DataTable.serverSide.integration.test.tsx`

Simulate `ServerSideDemo` pattern without React Query — mock fetch + `useState`:

| Test idea | Assert |
|-----------|--------|
| Initial render | Mock fetch called with default pagination/sort/filter |
| Click sort | Fetch called with new `sorting`; new `data` prop renders updated rows |
| Change page | Fetch params include new `pageIndex`; only new slice rendered |
| Apply filter | Fetch params include `columnFilters`; pagination uses server `rowCount` |
| Loading | `DataTable.Content loading` shows skeletons; no data rows |

### 12d — App-level tests (prototype / sndq-fe)

Not `@sndq/ui-v2` package tests:

| Test idea | Where |
|-----------|--------|
| React Query key includes table params | `ServerSideDemo.test.tsx` in prototype |
| Optimistic edit rollback on error | mutation `onError` restores cache |
| Bulk action passes selected page IDs vs `selectAllMode` | integration with API contract |
| URL persistence + server refetch | `strategy: 'url'` restores page/sort then fetches |

**Graduation gate** before Phase 3 CommonTable migration (server-driven production lists).

**Docs deliverable:** "Server-side wiring recipe" mirroring `ServerSideDemo` (state sync, `rowCount`, loading, no `clientSide: true`).

---

## Stage → production migration mapping

Align test completion with [architecture.md](./architecture.md) production phases:

| Production phase | Stages required | Minimum test coverage |
|------------------|-----------------|------------------------|
| Graduate to `@sndq/ui-v2` stable export | Stages 0–12 | All unit + component + server integration tests |
| Phase 1: EnrichTable (~20 screens) | 0–3 + 4 (sort only) | Integration compact + sort |
| Phase 2: CompactTable (~31 screens) | + 6 + 2 (URL persistence) | Pagination + persistence |
| Phase 3: CommonTable (~35 screens) | + 5, 7, 8, 9, 10, **12** | Full feature tests + server-side contract |

**Out of scope for this block:** `SavedViews` (in architecture but not in current barrel), `InfiniteTable` / virtualization — separate track.

---

## Test case template (per feature)

```markdown
### DataTable.FilterMenu

**Rendering**
- [ ] should render filter trigger when properties provided
- [ ] should show active filter count badge

**Interactions**
- [ ] should filter visible rows when option toggled
- [ ] should remove filter when option deselected

**Edge cases**
- [ ] should handle empty properties array
- [ ] should handle column with no filterFn

**Accessibility**
- [ ] should expose filter trigger as button with accessible name
```

---

## Suggested implementation order

1. `utils/filters.test.ts`, `utils/pagination.test.ts`, `utils/grouping.test.ts`
2. `utils/columnLayout.test.ts`, `utils/rows.test.ts`, `types/editor.test.ts`
3. `hooks/useTablePersistence.test.ts`
4. `hooks/usePersistedTableState.test.tsx`
5. `hooks/useDataTable.test.tsx`
6. `DataTable.test.tsx` → `DataTableContent.flat.test.tsx`
7. Feature files in stage order (4 → 10)
8. `DataTable.integration.test.tsx`
9. **Stage 12:** `useDataTable.serverSide.test.tsx`, `DataTablePagination.serverSide.test.tsx`, `DataTable.serverSide.integration.test.tsx`

Run after each file:

```bash
pnpm --filter @sndq/ui-v2 test src/blocks/data-table/<path>
```

Process **one file at a time**; do not batch all tests before running.

---

## Cross-reference to feature matrix

Maps to [architecture.md](./architecture.md) §8 (35 features):

| Feature # | Topic | Primary test file(s) |
|-----------|-------|----------------------|
| 1–3 | Sort | `useDataTable`, `DataTableColumnHeader`, `ActiveFilters.sort` |
| 4–8 | Filter | `utils/filters`, `DataTableFilterMenu`, `ActiveFilters.filters` |
| 9 | Search | `DataTableSearch` |
| 10–14 | Grouping | `utils/grouping`, `DataTableContent.grouped`, `DataTableSettings` |
| 15–19 | Selection | `useDataTable`, `Content.selection`, `SelectionBar`, `Toolbar`, `BulkActions` |
| 21–23 | Column config | `DataTableColumnConfig`, `DataTableSettings` |
| 24–25 | Editing | `DataTableEditableCell`, `editors`, `types/editor` |
| 26 | Context menu | `DataTableRowContextMenu` |
| 29–30 | Pagination | `utils/pagination`, `DataTablePagination`, **Stage 12 server-side** |
| 35 | Empty state | `DataTableEmptyState`, `Content.flat` |

---

## Server-side demo feature map

| `ServerSideDemo` feature | ui-v2 test stage | App test |
|--------------------------|------------------|----------|
| `simulateServerFetch` | Mock in 12c integration helper | Optional e2e |
| `tableParams` sync from `getState()` | 12c integration contract | `ServerSideDemo.test.tsx` |
| `serverSide.pageCount/rowCount` | 12a + 12b | — |
| `loading={isLoading}` | Stage 3 + 12c | ServerSideDemo |
| `isFetching` toolbar hint | Out of scope (domain UI) | Optional |
| `BulkActions totalCount` | Stage 7 + 12c | ServerSideDemo |
| Field/bulk mutations | — | React Query tests |
| URL persistence | Stage 2 + 12c | ServerSideDemo |
