# SNDQ DataTable Execution — Table Infrastructure & Domain Integration

Step-by-step execution guide for building the unified SNDQ DataTable component. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-03
**Status**: Not started
**Architecture**: [architecture.md](./architecture.md)
**Branch**: `feature/data-table`

> **IMPORTANT**: Do NOT automatically commit after each step. Implement each commit's changes, then stop and wait for manual review and testing. Only commit after explicit approval. This allows the implementer to verify each stage before moving forward.
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
3. [PR 1 — Table Infrastructure (Layers 1-3)](#3-pr-1--table-infrastructure-layers-1-3)
4. [PR 2 — Domain Integration & Showcase (Layer 4)](#4-pr-2--domain-integration--showcase-layer-4)
5. [Final Verification](#5-final-verification)
6. [Team Communication](#6-team-communication)
7. [What's Next](#7-whats-next)
8. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Build a unified DataTable component in `apps/ui-v2-dev` that replaces the 7 fragmented table implementations with a single composable, TanStack-powered compound component covering all 35 features from the RawTable prototype — without touching any production code.

**Structure**: 22 commits across 2 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Primitives, `useDataTable` hook, all feature shell components | Low | 1–16 |
| **PR 2** | Column helpers, property defs, PaymentInitiations demo, showcase page | Low | 17–22 |

**Why 2 PRs**: PR 1 is pure infrastructure — zero domain code, verifiable with mock data via Storybook or a minimal showcase page. PR 2 adds domain-specific integration (column helpers, real data shapes, full showcase) that validates the architecture against the RawTable prototype. Either PR can be reviewed and reverted independently.

### Prerequisites

- `apps/ui-v2-dev` builds successfully (`pnpm build` from workspace root)
- `@tanstack/react-table` `^8.21.2` is installed in `apps/ui-v2-dev`
- Dev server runs (`pnpm dev` in `apps/ui-v2-dev`)
- Existing `Table.tsx` primitive exists at `src/components/ui-v2/Table.tsx`

### Known constraints

- The `DataTable` folder (`src/components/ui-v2/DataTable/`) breaks the single-file convention in ui-v2. This is justified by the component count (13+ files) and has precedent in the `blocks/` directory.
- TanStack v8's `grouping` array supports nested grouping logically, but the rendering of nested group headers requires custom UI orchestration in `DataTable.Content`.
- TanStack's `rowSelection` does not natively support "select all across dataset" or "select all within a group" — both require custom Tier 2 state extensions.
- All existing `@sndq/ui-v2` primitives (Button, DropdownMenu, Checkbox, Input, Popover, etc.) should be reused. No new external UI dependencies beyond TanStack.

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

- [ ] Confirm `src/components/ui-v2/Table.tsx` exists and exports `Table`, `TableHeader`, `TableBody`, `TableRow`, `TableHead`, `TableCell`, `TableCaption`
- [ ] Confirm `src/components/ui-v2/index.ts` has categorized export sections
- [ ] Confirm `src/lib/hooks/` directory exists for hook placement
- [ ] Confirm `@tanstack/react-table` is in `package.json` dependencies
- [ ] Confirm existing primitives are available: `Button`, `DropdownMenu`, `Checkbox`, `Input`, `Popover`, `Badge`, `ScrollArea`
- [ ] Confirm dev server starts without errors
- [ ] Confirm current lint, type-check, build status — record any pre-existing failures

### Capture baselines

Run these from the `apps/ui-v2-dev/` directory and save the output. Diff against these after risky commits.

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit 2>&1 | tee /tmp/datatable-tsc-before.txt
pnpm lint 2>&1 | tee /tmp/datatable-lint-before.txt
pnpm build 2>&1 | tee /tmp/datatable-build-before.txt
```

### Create branch

```bash
git checkout main
git pull origin main
git checkout -b feature/data-table
```

---

## 3. PR 1 — Table Infrastructure (Layers 1-3)

All primitives, the core hook, and every feature shell component. Zero domain code. Verifiable via Storybook or a minimal showcase page with hardcoded mock data.

---

### Commit 1: Extend Table primitives

**What**: Add `TableFooter`, `TableGroupHeader`, `TableSummaryRow`, `TableEmptyRow` to the existing `Table.tsx` primitive. Add density context and selection visual states on `TableRow`.

**Files to edit**:

- `src/components/ui-v2/Table.tsx` — add four new subcomponents:
  - `TableFooter` — `<tfoot>` with border-top styling, flex layout for pagination/summary
  - `TableGroupHeader` — `<tr>` spanning all columns with chevron icon, label, count badge, action slot, and `data-expanded` attribute for collapse state
  - `TableSummaryRow` — `<tr>` with muted background for aggregation values (count, total)
  - `TableEmptyRow` — `<tr><td colSpan={colCount}>` centered empty state placeholder
  - Add `data-selected` and `data-selecting` visual states to `TableRow` (background color change)
  - Add `TableDensityContext` provider and consumer — `compact | default` controlling padding on `TableHead` and `TableCell`

**Files to create**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Breaking existing `Table` usages | LOW | Existing exports unchanged; new components are additive |
| Density context leaking outside table | LOW | Context scoped to `<Table>` provider only |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
pnpm build
```

Manual: Existing table showcase page still renders correctly.

**If it fails**:

- **"Cannot find name 'TableFooter'"**: Verify the component is exported from `Table.tsx` and re-exported in `index.ts`
- **Styling conflicts**: Check that `TableGroupHeader` uses `@apply` classes consistent with existing `Table` primitives

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: extend table primitives with footer, group header, summary, empty row`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 2: Create useDataTable hook (core)

**What**: Create the core `useDataTable` hook wrapping TanStack's `useReactTable` with SNDQ defaults. Conditionally attaches row models based on `enable*` flags. Exports typed `DataTableInstance`.

**Files to create**:

- `src/lib/hooks/useDataTable.ts`

```typescript
interface DataTableOptions<TData> {
  // --- Primary ---
  columns: ColumnDef<TData, any>[];
  data: TData[];
  getRowId?: (row: TData) => string;

  // --- Feature flags ---
  enableSorting?: boolean;       // default true
  enableFiltering?: boolean;     // default false
  enableGlobalFilter?: boolean;  // default false
  enableSelection?: boolean;     // default false
  enablePagination?: boolean;    // default false
  enableColumnVisibility?: boolean; // default false
  enableColumnResizing?: boolean;   // default false
  enableColumnOrdering?: boolean;   // default false
  enableGrouping?: boolean;         // default false
  enableExpanding?: boolean;        // default false
  enableEditing?: boolean;          // default false

  // --- Config (grouped settings) ---
  config?: {
    density?: 'compact' | 'default';
    pageSizeOptions?: number[];
    persistence?: PersistenceOptions;
    serverSide?: {
      isManualPagination?: boolean;
      isManualSorting?: boolean;
      isManualFiltering?: boolean;
      pageCount?: number;
      rowCount?: number;
    };
  };

  // --- Callbacks ---
  onStateChange?: (state: DataTableState) => void;

  // --- TanStack passthrough ---
  initialState?: Partial<TableState>;
  state?: Partial<TableState>;
}

function useDataTable<TData>(options: DataTableOptions<TData>): DataTableInstance<TData>
```

The hook:
- Merges user options with SNDQ defaults
- Conditionally includes `getSortedRowModel()`, `getFilteredRowModel()`, `getPaginationRowModel()`, `getGroupedRowModel()`, `getExpandedRowModel()` based on enabled features
- Calls `useReactTable(...)` with merged config
- Returns the TanStack table instance (extended in commit 3)

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Row model imports increase bundle size even when unused | LOW | TanStack tree-shakes row models; conditional import is fine |
| Type inference breaks with generic TData | MEDIUM | Verify column accessor types resolve correctly with a test type |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

**If it fails**:

- **"Module '@tanstack/react-table' has no exported member..."**: Verify `@tanstack/react-table` version is `^8.21.2` and re-install if needed
- **Type errors in conditional row model attachment**: Ensure optional chaining or ternary guards for undefined row models

**Deviations from the gate**:

- **No tests yet** — hook is not consumed; will be tested via `DataTable.Content` in commit 6

**Commit message**: `feat: create useDataTable hook wrapping TanStack useReactTable`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 3: Add two-tier state management

**What**: Extend `useDataTable` with Tier 2 SNDQ-managed state (density, showFilters, showColumnConfig, selectAllMode, editingCell) and custom helper methods (toggleGroupSelection, getSelectionCount, resetAllState).

**Files to edit**:

- `src/lib/hooks/useDataTable.ts` — add:
  - `useState` for each Tier 2 field
  - `toggleGroupSelection(groupRows)` helper that iterates rows and calls `row.toggleSelected()`
  - `getSelectionCount()` returning `Object.keys(rowSelection).length`
  - `resetAllState()` clearing all TanStack and Tier 2 state
  - Merge Tier 2 state and helpers onto the returned `DataTableInstance`
  - Export `DataTableInstance<TData>` type extending `Table<TData>` with SNDQ extensions

**Files to create**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Tier 2 state causes unnecessary re-renders | LOW | Each state setter is independent; consumers only re-render when their consumed state changes |
| toggleGroupSelection mutates selection incorrectly | MEDIUM | Verify with grouped data that group rows' leaf rows are toggled |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

**If it fails**:

- **"Property 'density' does not exist on type 'Table<TData>'"**: Ensure `DataTableInstance` properly extends/intersects `Table<TData>` with custom fields

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add two-tier state management to useDataTable`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 4: Add state persistence adapter

**What**: Create `useTablePersistence` hook handling URL parameter sync and localStorage persistence with configurable strategies. Integrate into `useDataTable` via `config.persistence`.

**Files to create**:

- `src/lib/hooks/useTablePersistence.ts`

```typescript
interface PersistenceOptions {
  key: string;
  strategy: 'url+localStorage' | 'url' | 'localStorage' | 'none';
  scope?: string;
  persistSearch?: boolean;
}

function useTablePersistence(options?: PersistenceOptions): {
  loadState: () => Partial<TableState>;
  saveState: (state: Partial<TableState>) => void;
}
```

The hook:
- Reads from URL params and localStorage on mount with priority: URL > localStorage > defaults
- Writes to URL params and/or localStorage on state change (debounced)
- Uses `{scope}_{key}` isolation pattern
- Serializes sorting as `field:direction`, filters as JSON, column visibility as key array
- Integrates with `useSearchParams()` from the router

**Files to edit**:

- `src/lib/hooks/useDataTable.ts` — read `config.persistence` from options, call `useTablePersistence`, merge loaded state into `initialState`, subscribe to state changes via `onStateChange`

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| URL params conflict with existing route params | MEDIUM | Use table-specific prefixed params (e.g., `dt_page`, `dt_sort`) or configurable prefix |
| localStorage quota exceeded | LOW | Catch `QuotaExceededError` and degrade gracefully |
| Persistence triggers infinite re-renders | MEDIUM | Debounce writes, use `useRef` for previous state comparison |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Instantiate `useDataTable` with `config: { persistence: { key: 'test', strategy: 'url' } }`. Change a page. Reload the page. Confirm the page state is restored from URL params.

**If it fails**:

- **Infinite render loop**: Add a `prevStateRef` comparison before writing to URL/localStorage
- **URL params not updating**: Check that the router's `useSearchParams` setter is being called correctly

**Deviations from the gate**:

- **Persistence strategy is a stub** — `url+localStorage` may initially only support `url` until the full integration is validated. Record as deviation and complete in a follow-up if needed.

**Commit message**: `feat: add state persistence adapter for URL and localStorage`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 5: Create DataTable shell + context

**What**: Create the root `DataTable` component with React Context that provides the table instance to all child components.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTable.tsx`

```typescript
interface DataTableProps<TData> {
  table: DataTableInstance<TData>;
  children: React.ReactNode;
  className?: string;
}

const DataTableContext = createContext<DataTableInstance<any> | null>(null);

function useDataTableContext<TData>(): DataTableInstance<TData>;

function DataTable<TData>({ table, children, className }: DataTableProps<TData>): JSX.Element;
```

The component:
- Wraps children in `DataTableContext.Provider` with the table instance
- Provides `useDataTableContext()` hook that throws if used outside the provider
- Renders a container `<div>` with optional className for layout

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Generic TData lost through context | LOW | Context stores `any`; consumer hook casts via generic parameter |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

**If it fails**:

- **"useDataTableContext must be used within a DataTable"**: Context provider is missing; wrap children in the provider

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: create DataTable shell component with context provider`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 6: DataTable.Content (flat rendering)

**What**: Create `DataTableContent` that renders a flat `<Table>` with header groups and body rows using TanStack's `flexRender`. Includes sort indicators on column headers and optional selection checkbox column.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableContent.tsx`

The component:
- Reads table instance from context
- Iterates `table.getHeaderGroups()` to render `<TableHeader>` with `<TableHead>` per column
- Sort-enabled headers show sort direction via `TableHead`'s `sortDirection` + `onSort` props, wired to `column.toggleSorting()`
- Selection-enabled tables auto-inject a checkbox column via TanStack's display column pattern
- Iterates `table.getRowModel().rows` to render `<TableBody>` with `<TableRow>` + `<TableCell>` per cell using `flexRender(cell.column.columnDef.cell, cell.getContext())`
- Handles `meta.align` for cell alignment
- Uses `TableEmptyRow` when no rows

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `flexRender` returns unexpected types | LOW | TanStack's `flexRender` handles string, JSX, and function column defs |
| Selection checkbox column shifts column indices | MEDIUM | Use TanStack's display column (id-only, no accessor) to avoid index conflicts |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Create a minimal test with 3 columns and 5 rows of mock data. Render `<DataTable table={table}><DataTable.Content /></DataTable>`. Verify headers render, rows display data, clicking a header sorts. If selection is enabled, verify checkboxes appear and toggle selection state.

**If it fails**:

- **"cell.getContext is not a function"**: Verify TanStack cell objects are the correct type from `row.getVisibleCells()`
- **Sort not toggling**: Check that `column.getCanSort()` returns `true` and `enableSorting` is set

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable.Content with flat row rendering and sort`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 7: DataTable.Content (grouped rendering)

**What**: Extend `DataTableContent` to detect grouped rows from TanStack and render nested group headers, sub-group headers, collapsible sections, group-level selection checkboxes, and group summary rows.

**Files to edit**:

- `src/components/ui-v2/DataTable/DataTableContent.tsx` — add grouped rendering path:
  - Detect grouping via `table.getState().grouping.length > 0`
  - Iterate `table.getRowModel().rows` which are now group rows when grouping is active
  - For each group row: render `<TableGroupHeader>` with group label, item count, collapse toggle, optional selection checkbox, and action slot
  - For each group row's `subRows`: render child rows (or sub-group rows if nested)
  - Collapse/expand animation via CSS grid `grid-template-rows: 0fr / 1fr` transition on the group body wrapper
  - Group summary rows via `<TableSummaryRow>` at the end of each group
  - Accept optional `renderGroupHeader` and `renderGroupSummary` render props for customization

**Files to create**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| TanStack v8 multi-level grouping row model is flat, not nested | MEDIUM | Verify `row.subRows` contains sub-group rows when `grouping: ['field1', 'field2']` |
| CSS grid collapse animation not smooth | LOW | Test with 20+ rows per group |
| Group-level selection toggles leaf rows correctly | MEDIUM | `toggleGroupSelection` from commit 3 must iterate leaf rows, not sub-group rows |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Create mock data with a `status` and `building` field. Enable grouping with `grouping: ['status']`. Verify group headers appear with correct labels and counts. Click collapse — rows animate away. Enable `grouping: ['status', 'building']` — verify nested sub-groups render. Check group-level selection checkbox selects all leaf rows.

**If it fails**:

- **Sub-groups not nesting**: TanStack v8 may represent multi-level groups differently. Inspect `row.subRows` and `row.depth` to understand the tree structure.
- **Animation jank**: Replace CSS grid transition with `max-height` transition or `@keyframes` if grid approach doesn't work

**Deviations from the gate**:

- **Sub-group rendering may be simplified** — if TanStack v8's multi-level grouping is too complex to render correctly in this commit, implement single-level grouping first and defer two-level to a follow-up

**Commit message**: `feat: add grouped rendering with collapse animation to DataTable.Content`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 8: DataTable.Toolbar + DataTable.Search

**What**: Create the toolbar container and expandable search input. The toolbar is a flex row that houses action slots (filter, sort, settings buttons) and children.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableToolbar.tsx`
  - Flex row container with `justify-between` layout
  - Left side: search + filter/sort controls
  - Right side: children (action buttons, settings)
  - Hides when `DataTable.SelectionBar` is active (controlled by selection count > 0)

- `src/components/ui-v2/DataTable/DataTableSearch.tsx`
  - Expandable search input bound to `table.setGlobalFilter()`
  - Collapsed state shows a search icon button
  - Expanded state shows a text input with clear button
  - Debounced input (300ms default, configurable via `debounceMs` prop)
  - Reads current `globalFilter` from context on mount

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Debounce causes stale filter state | LOW | Use `useRef` for timeout, cancel on unmount |
| Search icon button keyboard accessibility | LOW | Must be focusable and trigger expand on Enter/Space |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Render toolbar with search. Type in search — rows filter after debounce. Clear search — all rows return. Click icon to collapse/expand.

**If it fails**:

- **"table.setGlobalFilter is not a function"**: Ensure `enableGlobalFilter: true` is passed to `useDataTable`

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable.Toolbar and DataTable.Search`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 9: DataTable.FilterMenu (Linear/Notion style)

**What**: Create the filter menu with a property list and hover-to-reveal sub-panels for value selection. Supports multi-select checkboxes, search within options, and date preset filters.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableFilterMenu.tsx`

```typescript
interface FilterProperty {
  id: string;
  label: string;
  icon?: React.ReactNode;
  type: 'select' | 'date' | 'text';
  options?: { value: string; label: string }[];
  datePresets?: { label: string; value: string }[];
}

interface DataTableFilterMenuProps {
  properties: FilterProperty[];
}
```

The component:
- Trigger button ("Filter") opens a `Popover` with the property list
- Hovering a property reveals a sub-panel to the right with value checkboxes
- Each sub-panel has a search input for filtering options
- Date-type properties show preset buttons (1d, 3d, 1w, 1m, 3m, 6m, 1y) plus a custom date picker
- Selecting/deselecting a value updates `table.getColumn(id)?.setFilterValue()`
- Active filter count shown as a badge on the trigger button

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Hover sub-panel disappears when mouse moves between panels | MEDIUM | Use a delay on `onMouseLeave` or shared hover area covering both panels |
| TanStack `columnFilter` value type must be array for multi-select | LOW | Custom `filterFn` that checks `value.includes(row.getValue())` |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Open filter menu. Hover over a property — sub-panel appears. Select values — rows filter. Deselect — rows return. Search within options. Use date presets.

**If it fails**:

- **"column.setFilterValue is not a function"**: Ensure `enableColumnFilters: true` on the column and `enableFiltering: true` on the table
- **Sub-panel flickers**: Increase the `onMouseLeave` delay or use a bridge element between panels

**Deviations from the gate**:

- **Date picker integration may be deferred** — if the existing date picker primitive is not ready, date presets work as buttons and custom date picker is a follow-up

**Commit message**: `feat: add DataTable.FilterMenu with property sub-panels`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 10: DataTable.ActiveFilters (pills bar)

**What**: Create the active filters bar showing sort pill and filter pills as editable/dismissible badges. Includes `FilterPillPopover` and `SortPillPopover` for inline editing.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableActiveFilters.tsx`

The component:
- Reads `sorting` and `columnFilters` from table state
- Renders a horizontal scrollable row of pill badges
- Sort pill: shows current sort field + direction, click opens `SortPillPopover` to change field/direction, X button dismisses
- Filter pills: one per active column filter, shows "property: value1, value2", click opens `FilterPillPopover` to edit values, X button dismisses
- `SortPillPopover`: dropdown with sortable column list + asc/desc toggle
- `FilterPillPopover`: same sub-panel as `DataTableFilterMenu` for that specific property
- "Clear all" button at the end when multiple filters are active

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Pill overflow on small screens | LOW | Horizontal scroll with fade gradient |
| Removing last filter pill leaves empty bar | LOW | Hide the bar when no active filters |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Apply sort and filters. Verify pills appear. Click X on a pill — filter/sort removed. Click pill — popover opens for editing. Click "Clear all" — all filters and sort reset.

**If it fails**:

- **Pills not appearing**: Check that `table.getState().sorting` and `table.getState().columnFilters` are populated

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable.ActiveFilters with sort and filter pills`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 11: DataTable.SelectionBar

**What**: Create the selection bar that replaces the toolbar when rows are selected. Shows selected count, bulk action slots, and the "Select all N across dataset" banner.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableSelectionBar.tsx`

```typescript
interface DataTableSelectionBarProps {
  children: React.ReactNode;  // bulk action buttons
  totalCount?: number;         // total dataset size for "select all N" banner
}
```

The component:
- Visible when `table.getSelectionCount() > 0` (animates in, replacing toolbar)
- Left side: "{N} selected" text + "Deselect all" button
- Center: children (bulk action buttons passed by consumer)
- When all page rows selected and `totalCount` provided: shows "Select all {totalCount} items" banner
  - Clicking it sets `table.setSelectAllMode(true)`
  - When `selectAllMode` is true: shows "All {totalCount} items selected" with "Clear selection" button

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| selectAllMode persists after deselecting rows | LOW | Deselecting any row should reset selectAllMode to false |
| Animation between toolbar and selection bar jank | LOW | Use CSS transition or AnimatePresence |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Select rows. Bar appears. Click "Deselect all" — bar disappears. Select all on page — "Select all N" banner appears. Click it — mode switches. Deselect one row — banner clears.

**If it fails**:

- **Selection bar doesn't appear**: Check that `getSelectionCount()` returns > 0 and the visibility conditional works

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable.SelectionBar with bulk action slots`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 12: DataTable.Settings (view settings panel)

**What**: Create the settings panel for column visibility toggle, column drag-and-drop reorder, group/sub-group picker, and page size control. Notion-style property picker UX.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableSettings.tsx`

```typescript
interface DataTableSettingsProps {
  groupableFields?: { id: string; label: string }[];
  pageSizeOptions?: number[];  // default [10, 25, 50, 100]
}
```

The component:
- Trigger button (gear icon) opens a `Popover` or side sheet
- **Properties section**: list of all columns with visibility toggle (eye icon) and drag handle for reorder. Uses `table.getColumn(id)?.toggleVisibility()` and updates `columnOrder` state on drag end.
- **Group section**: dropdown to select primary grouping field from `groupableFields`. Setting a group calls `table.setGrouping([field])`.
- **Sub-group section**: dropdown for secondary grouping (only shows when primary is set). Calls `table.setGrouping([primary, secondary])`.
- **Page size section**: radio group or segmented control for page size options. Calls `table.setPageSize(size)`.
- **Reset button**: resets all settings to defaults

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Drag-and-drop library dependency | MEDIUM | Use native HTML drag-and-drop or `@dnd-kit/sortable` if already available |
| Column order state desyncs with visibility | LOW | Ensure hidden columns are excluded from the rendered order but preserved in the full order |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Open settings. Toggle column visibility — column appears/disappears. Drag reorder columns — table column order changes. Set group — rows group. Change page size — pagination updates.

**If it fails**:

- **Drag not working**: Check drag-and-drop library setup or native drag events
- **Column order not persisting**: Verify `columnOrder` state is being set correctly

**Deviations from the gate**:

- **Drag-and-drop may use a simplified approach** — if `@dnd-kit` is not available, implement with native drag events or defer drag reorder to a follow-up

**Commit message**: `feat: add DataTable.Settings with column config and group picker`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 13: DataTable.Pagination + DataTable.Footer

**What**: Create pagination controls (prev/next, page indicator, row count) and a footer container.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTablePagination.tsx`

```typescript
interface DataTablePaginationProps {
  showPageSize?: boolean;
}
```

The component:
- Page navigation: "Previous" / "Next" buttons using `table.previousPage()` / `table.nextPage()`
- Page indicator: "Page {current} of {total}" or "1–10 of 250"
- Disabled states when at first/last page
- Optional page size selector (if not shown in Settings)

- `src/components/ui-v2/DataTable/DataTableFooter.tsx`

```typescript
interface DataTableFooterProps {
  children: React.ReactNode;
}
```

The component:
- Wrapper using `<TableFooter>` primitive
- Flex layout for placing pagination, row count, custom content
- Example: `<DataTable.Footer><DataTable.Pagination /><span>Total: €1,234.56</span></DataTable.Footer>`

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Pagination state desync with server-side data | LOW | `config.serverSide.isManualPagination` mode requires `pageCount` |
| Footer layout breaks on narrow screens | LOW | Test responsive behavior |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Render paginated table with 100 rows, page size 10. Click next — page 2 shows. Click previous — page 1. Page indicator updates. Footer shows custom content.

**If it fails**:

- **"table.getPageCount() returns -1"**: Set `config.serverSide.pageCount` when using `isManualPagination`, or ensure `getPaginationRowModel` is attached

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable.Pagination and DataTable.Footer`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 14: DataTable.EditableCell

**What**: Create inline cell editing with popover editors for text, currency, date, and select types.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableEditableCell.tsx`

```typescript
interface DataTableEditableCellProps<TData> {
  row: Row<TData>;
  field: string;
  editorType: 'text' | 'currency' | 'date' | 'select';
  options?: { value: string; label: string }[];  // for select type
  onSave: (rowId: string, field: string, value: any) => void;
}
```

The component:
- `CellEditTrigger`: wraps cell content, shows edit affordance on hover (pencil icon or underline), opens popover on click
- `CellPopover`: positioned relative to the cell, contains the editor:
  - **text**: `<Input>` with save on Enter, cancel on Escape
  - **currency**: `<Input type="number">` with currency formatting
  - **date**: Date picker component
  - **select**: Dropdown/combobox with options
- Reads/writes `editingCell` from context (Tier 2 state)
- Only one cell editable at a time — opening a new cell closes the current one
- Calls `onSave` callback when editing completes

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Popover positioning conflicts with table scroll | MEDIUM | Use `Popover` with `collision` boundary set to the table container |
| Enter key submits form instead of saving cell | LOW | `event.preventDefault()` in the cell editor's Enter handler |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Click a cell — popover opens with editor. Edit value, press Enter — value saves. Press Escape — edit cancelled. Click another cell — previous closes, new opens.

**If it fails**:

- **Popover appears in wrong position**: Check `Popover` anchor element and boundary settings
- **Value not saving**: Verify `onSave` callback is wired correctly

**Deviations from the gate**:

- **Date and select editors may be simplified** — implement text and currency first, add date/select in a follow-up if primitives aren't ready

**Commit message**: `feat: add DataTable.EditableCell with popover editors`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 15: DataTable.RowContextMenu

**What**: Create a right-click context menu for table rows with configurable actions.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTableRowContextMenu.tsx`

```typescript
interface ContextMenuAction<TData> {
  label: string;
  icon?: React.ReactNode;
  onClick: (row: Row<TData>) => void;
  variant?: 'default' | 'destructive';
  separator?: boolean;  // show separator after this item
}

interface DataTableRowContextMenuProps<TData> {
  actions: ContextMenuAction<TData>[] | ((row: Row<TData>) => ContextMenuAction<TData>[]);
}
```

The component:
- Attaches `onContextMenu` handler to each `<TableRow>` in `DataTable.Content`
- Opens a context menu (using existing `DropdownMenu` primitive) at cursor position
- Renders action items with icons, labels, and destructive styling
- Common actions: Edit, Copy ID, Select row, Separator, Delete
- Closes on click outside, Escape, or item selection

**Files to edit**:

- `src/components/ui-v2/DataTable/DataTableContent.tsx` — integrate `onContextMenu` handler on `<TableRow>` when `DataTable.RowContextMenu` is composed

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Context menu conflicts with browser default | LOW | `event.preventDefault()` in `onContextMenu` handler |
| Context menu positioning off-screen | LOW | Collision detection to flip menu position |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Right-click a row — context menu appears at cursor. Click "Edit" — action fires. Click "Delete" — destructive action fires. Click outside — menu closes.

**If it fails**:

- **Browser context menu still shows**: Ensure `event.preventDefault()` is called
- **Menu appears in wrong position**: Check `{ x: event.clientX, y: event.clientY }` positioning

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable.RowContextMenu with configurable actions`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 16: Barrel exports + SavedViews stub

**What**: Create barrel exports for the DataTable compound component, add `DataTable.EmptyState`, create `DataTable.SavedViews` as a stub, and wire everything into the ui-v2 index.

**Files to create**:

- `src/components/ui-v2/DataTable/index.ts` — barrel export attaching all subcomponents to the root `DataTable` via `Object.assign`:

```typescript
import { DataTable as DataTableRoot } from './DataTable';
import { DataTableContent } from './DataTableContent';
import { DataTableToolbar } from './DataTableToolbar';
import { DataTableSearch } from './DataTableSearch';
import { DataTableFilterMenu } from './DataTableFilterMenu';
import { DataTableActiveFilters } from './DataTableActiveFilters';
import { DataTableSelectionBar } from './DataTableSelectionBar';
import { DataTableSettings } from './DataTableSettings';
import { DataTablePagination } from './DataTablePagination';
import { DataTableFooter } from './DataTableFooter';
import { DataTableEditableCell } from './DataTableEditableCell';
import { DataTableRowContextMenu } from './DataTableRowContextMenu';
import { DataTableEmptyState } from './DataTableEmptyState';
import { DataTableSavedViews } from './DataTableSavedViews';

const DataTable = Object.assign(DataTableRoot, {
  Content: DataTableContent,
  Toolbar: DataTableToolbar,
  Search: DataTableSearch,
  FilterMenu: DataTableFilterMenu,
  ActiveFilters: DataTableActiveFilters,
  SelectionBar: DataTableSelectionBar,
  Settings: DataTableSettings,
  Pagination: DataTablePagination,
  Footer: DataTableFooter,
  EditableCell: DataTableEditableCell,
  RowContextMenu: DataTableRowContextMenu,
  EmptyState: DataTableEmptyState,
  SavedViews: DataTableSavedViews,
});

export { DataTable };
export type { DataTableProps } from './DataTable';
export { useDataTableContext } from './DataTable';
```

- `src/components/ui-v2/DataTable/DataTableEmptyState.tsx` — simple component rendering custom empty state content within `TableEmptyRow`

- `src/components/ui-v2/DataTable/DataTableSavedViews.tsx` — stub with basic saved views UI:

```typescript
interface SavedView {
  id: string;
  label: string;
  state: Partial<TableState>;
}

interface DataTableSavedViewsProps {
  views: SavedView[];
  activeViewId?: string;
  onSave: (view: SavedView) => void;
  onSwitch: (viewId: string) => void;
  onDelete: (viewId: string) => void;
  onRename: (viewId: string, label: string) => void;
  onDuplicate: (viewId: string) => void;
}
```

The stub renders tab-style view switcher with basic create/switch/delete, full CRUD deferred to commit 20.

**Files to edit**:

- `src/components/ui-v2/index.ts` — add `export * from './DataTable'`
- `src/lib/hooks/index.ts` — add `export { useDataTable } from './useDataTable'` and `export { useTablePersistence } from './useTablePersistence'`

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Circular imports between DataTable subcomponents | LOW | Barrel export is one-directional; subcomponents import from context, not from each other |
| Export collisions with existing components | LOW | DataTable namespace is unique |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
pnpm build
```

Manual: Import `DataTable` from `@/components/ui-v2`. Verify `DataTable.Content`, `DataTable.Toolbar`, etc. are accessible. Verify `useDataTable` is importable from `@/lib/hooks`.

**If it fails**:

- **"Module not found" on DataTable subcomponent**: Check barrel export paths
- **Build fails with circular dependency**: Ensure subcomponents don't import from the barrel

**Deviations from the gate**:

- **SavedViews is a stub** — full CRUD implementation in commit 20

**Commit message**: `feat: add barrel exports, EmptyState, SavedViews stub`

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
git push -u origin feature/data-table
# Create PR targeting main
# Wait for CI to complete successfully
```

**This validates**: All infrastructure compiles, lint passes, build succeeds. DataTable compound component is importable and renders with mock data. No production code is affected.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] DataTable renders flat table with sort, filter, search, pagination
- [ ] DataTable renders grouped table with collapse/expand
- [ ] Selection bar appears when rows are selected
- [ ] Settings panel toggles column visibility
- [ ] All 13 DataTable subcomponents are importable
- [ ] Rollback: revert the branch; no production impact

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. PR 2 — Domain Integration & Showcase (Layer 4)

Column helpers, property definitions, PaymentInitiations demo table, full SavedViews implementation, showcase integration page, and type cleanup. Validates the architecture against the RawTable prototype.

---

### Commit 17: Column helper utilities

**What**: Create typed column factory with `compactColumn` helpers for common SNDQ column types and migration adapters for existing column APIs.

**Files to create**:

- `src/lib/hooks/createColumnHelper.ts`

```typescript
import { createColumnHelper as tanstackCreateColumnHelper } from '@tanstack/react-table';

// Re-export TanStack's helper for direct use
export { tanstackCreateColumnHelper as createColumnHelper };

// SNDQ column factory helpers for common column types
export const compactColumn = {
  currency: <TData,>(columnHelper, key, opts) => { ... },
  date: <TData,>(columnHelper, key, opts) => { ... },
  text: <TData,>(columnHelper, key, opts) => { ... },
  avatarText: <TData,>(columnHelper, key, opts) => { ... },
  status: <TData,>(columnHelper, key, opts) => { ... },
};

// Migration adapters
export function fromExtendedColumnConfig<TData>(configs: any[]): ColumnDef<TData, any>[];
export function fromCompactTableColumn<TData>(columns: any[]): ColumnDef<TData, any>[];
```

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Migration adapters lose type safety | LOW | Adapters accept `any[]` input but output typed `ColumnDef[]` |
| compactColumn helpers have incorrect accessor types | MEDIUM | Test with real SNDQ data types |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

**If it fails**:

- **Type inference broken**: Check that `columnHelper.accessor()` correctly infers the accessor key type

**Deviations from the gate**:

- **Migration adapters are best-effort** — they handle the most common field mappings. Edge cases may need manual column definition.

**Commit message**: `feat: add column helper utilities and migration adapters`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 18: PropertyDef system

**What**: Create the `PropertyDef` type system for describing table properties (columns) with their capabilities, and the `NIcon` component for Notion-style property type icons.

**Files to create**:

- `src/components/ui-v2/DataTable/DataTablePropertyDef.ts`

```typescript
export interface PropertyDef {
  id: string;
  label: string;
  notionType: 'text' | 'number' | 'currency' | 'date' | 'select' | 'multiSelect' | 'person' | 'status' | 'checkbox';
  sortable?: boolean;
  filterable?: boolean;
  groupable?: boolean;
  editable?: boolean;
  filterOptions?: { value: string; label: string }[];
  datePresets?: { label: string; value: string }[];
}

// Utility to generate PropertyDef[] from column definitions
export function derivePropertyDefs<TData>(columns: ColumnDef<TData, any>[]): PropertyDef[];

// Utility to generate filter value options from data
export function deriveFilterOptions<TData>(data: TData[], propertyId: string): { value: string; label: string }[];
```

- `src/components/ui-v2/DataTable/NIcon.tsx` — Notion-style property type icons:

```typescript
interface NIconProps {
  type: PropertyDef['notionType'];
  className?: string;
}
```

Maps each `notionType` to an appropriate icon from the icon library (text → Type, number → Hash, currency → DollarSign, date → Calendar, etc.)

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| derivePropertyDefs doesn't extract all needed metadata | LOW | Test with various column configurations |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

**If it fails**:

- **Icon not rendering**: Check icon library imports

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add PropertyDef system and NIcon component`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 19: PaymentInitiations demo table

**What**: Create a full-featured demo table reproducing the RawTable prototype's PaymentInitiations table using the DataTable compound API with mock data.

**Files to create**:

- `src/components/sections/DataTableSection.tsx`

The demo:
- Defines `PaymentItem` type matching the RawTable prototype
- Generates mock data (50+ items with realistic building names, amounts, statuses, dates)
- Defines columns using `createColumnHelper<PaymentItem>()` with:
  - Selection checkbox column
  - Building (avatarText), Amount (currency), Status (badge), Date (date), Method (text)
  - Editable cells for amount and status
  - Context menu for each row
- Instantiates `useDataTable` with all features enabled:
  - `enableSorting`, `enableFiltering`, `enableGlobalFilter`, `enableSelection`, `enablePagination`, `enableColumnVisibility`, `enableGrouping`, `enableExpanding`, `enableEditing`, plus `config.persistence` and `config.density`
- Composes the full DataTable:

```tsx
<DataTable table={table}>
  <DataTable.Toolbar>
    <DataTable.Search />
    <DataTable.FilterMenu properties={paymentProperties} />
    <DataTable.Settings groupableFields={[...]} />
  </DataTable.Toolbar>

  <DataTable.SelectionBar totalCount={data.length}>
    <Button size="sm">Approve</Button>
    <Button size="sm">Export</Button>
  </DataTable.SelectionBar>

  <DataTable.ActiveFilters />

  <DataTable.Content
    renderGroupHeader={...}
    renderGroupSummary={...}
  />

  <DataTable.Footer>
    <DataTable.Pagination />
    <span>Total: {formattedTotal}</span>
  </DataTable.Footer>
</DataTable>
```

**Files to edit**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Integration reveals API mismatches between components | MEDIUM | Fix APIs in PR 1 components if needed (amend or follow-up commit) |
| Mock data doesn't exercise all grouping/filtering paths | LOW | Include diverse statuses, dates, and amounts |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
pnpm build
```

Manual: Navigate to the showcase section. Verify all 35 features work:
1. Sort by clicking headers
2. Search via toolbar
3. Open filter menu, select values
4. See active filter pills
5. Group by status — groups appear with collapse
6. Group by status + building — nested sub-groups
7. Select rows — selection bar appears
8. Select all across dataset
9. Bulk actions visible
10. Settings panel — toggle columns, change page size
11. Pagination works
12. Inline edit a cell
13. Right-click context menu
14. Footer shows total
15. Empty state when all filtered out

**If it fails**:

- **Component API mismatch**: Adjust component props/context to match actual usage patterns
- **Grouping doesn't nest**: Verify TanStack v8 grouping model with the mock data structure

**Deviations from the gate**:

- **Some features may be partially implemented** — note which of the 35 features need follow-up

**Commit message**: `feat: add PaymentInitiations demo table with full DataTable API`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 20: SavedViews full implementation

**What**: Complete the SavedViews component with state snapshot/restore, inline rename, context menu (duplicate, delete), and view tab switching.

**Files to edit**:

- `src/components/ui-v2/DataTable/DataTableSavedViews.tsx` — replace stub with full implementation:
  - View tabs rendered as horizontal scrollable tab list
  - Active view highlighted
  - "+" button to create new view (snapshots current table state: sorting, columnFilters, grouping, columnVisibility, columnOrder, pagination.pageSize)
  - Double-click tab label to rename inline
  - Right-click tab for context menu: Duplicate, Delete
  - Switching view restores the snapshotted state via `table.setState()`
  - Unsaved changes indicator (dot) when current state differs from saved view state

**Files to create**: None

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| State snapshot/restore misses some fields | LOW | Verify all TanStack state fields are captured |
| Unsaved changes detection is too aggressive (triggers on every interaction) | LOW | Deep compare only the persisted fields, not ephemeral state |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
```

Manual: Create a view. Apply filters and sort. Switch to another view — state changes. Switch back — original state restored. Rename a view. Duplicate a view. Delete a view.

**If it fails**:

- **State not restoring**: Check that `table.setState()` is called with the correct state shape
- **Deep comparison fails**: Verify JSON serialization of state for comparison

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: implement full SavedViews with state snapshot and restore`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 21: Showcase integration page

**What**: Create or update the showcase route under `(showcase)/primitives/data-table/` with multiple demo sections demonstrating the DataTable at different complexity levels.

**Files to create**:

- Showcase route file (path depends on existing routing convention, e.g., `src/app/(showcase)/primitives/data-table/page.tsx` or similar)

Demo sections:
1. **Basic** — minimal table with 3 columns, no features
2. **Sorting** — sortable columns, sort pill display
3. **Filtering** — column filters + global search + filter pills
4. **Grouping** — single group + nested sub-group with collapse
5. **Selection** — row selection, bulk actions, select all across dataset
6. **Editing** — inline cell editing with different editor types
7. **Full-featured** — the PaymentInitiations demo from commit 19, embedded as the capstone demo

Each section includes a heading, description, and the rendered DataTable with appropriate configuration.

**Files to edit**: None (unless updating an existing showcase index/navigation)

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Showcase page layout conflicts with existing pages | LOW | Follow existing showcase page patterns |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
pnpm build
```

Manual: Navigate to the showcase page. All 7 demo sections render. Each demo is interactive and demonstrates its targeted feature set.

**If it fails**:

- **Routing error**: Check the app router structure and add the page in the correct location

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add DataTable showcase page with progressive demos`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 22: Documentation + types cleanup

**What**: Consolidate all public type exports into a single types file, add JSDoc documentation on all public props, and add usage examples to the showcase.

**Files to create**:

- `src/components/ui-v2/DataTable/types.ts` — consolidated public type exports:

```typescript
export type { DataTableProps } from './DataTable';
export type { DataTableContentProps } from './DataTableContent';
export type { DataTableToolbarProps } from './DataTableToolbar';
export type { DataTableSearchProps } from './DataTableSearch';
export type { DataTableFilterMenuProps, FilterProperty } from './DataTableFilterMenu';
export type { DataTableActiveFiltersProps } from './DataTableActiveFilters';
export type { DataTableSelectionBarProps } from './DataTableSelectionBar';
export type { DataTableSettingsProps } from './DataTableSettings';
export type { DataTablePaginationProps } from './DataTablePagination';
export type { DataTableFooterProps } from './DataTableFooter';
export type { DataTableEditableCellProps } from './DataTableEditableCell';
export type { DataTableRowContextMenuProps, ContextMenuAction } from './DataTableRowContextMenu';
export type { DataTableEmptyStateProps } from './DataTableEmptyState';
export type { DataTableSavedViewsProps, SavedView } from './DataTableSavedViews';
export type { PropertyDef } from './DataTablePropertyDef';
export type { DataTableOptions, DataTableInstance } from '../../lib/hooks/useDataTable';
export type { PersistenceOptions } from '../../lib/hooks/useTablePersistence';
```

**Files to edit**:

- All DataTable component files — add JSDoc on exported props interfaces
- `src/components/ui-v2/DataTable/index.ts` — re-export types from `types.ts`

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Type re-exports cause circular imports | LOW | types.ts only imports type-only references |

**Verification**:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit
pnpm lint
pnpm build
```

**If it fails**:

- **Circular dependency**: Use `import type` exclusively in `types.ts`

**Deviations from the gate**:

- **None expected**

**Commit message**: `docs: consolidate DataTable types and add JSDoc`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### PR 2 Checkpoint

Push PR 2 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feature/data-table
# Create PR targeting main (or update existing)
# Wait for CI to complete successfully
```

**This validates**: Column helpers work with real data types. PaymentInitiations demo exercises all 35 features. SavedViews CRUD works. Showcase page demonstrates progressive complexity. All types are clean and documented.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] PaymentInitiations demo matches RawTable prototype behavior
- [ ] SavedViews create/switch/rename/duplicate/delete all work
- [ ] Showcase page is navigable with 7 demo sections
- [ ] Types are importable from `@/components/ui-v2/DataTable/types`
- [ ] Rollback: revert commits 17-22; PR 1 infrastructure is unaffected

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 5. Final Verification

After all 22 commits, run the full suite from the `apps/ui-v2-dev/` directory:

```bash
cd apps/ui-v2-dev
pnpm tsc --noEmit 2>&1 | tee /tmp/datatable-tsc-final.txt
pnpm lint 2>&1 | tee /tmp/datatable-lint-final.txt
pnpm build 2>&1 | tee /tmp/datatable-build-final.txt
```

Compare against baselines:

```bash
diff /tmp/datatable-tsc-before.txt /tmp/datatable-tsc-final.txt
diff /tmp/datatable-lint-before.txt /tmp/datatable-lint-final.txt
diff /tmp/datatable-build-before.txt /tmp/datatable-build-final.txt
```

**Manual verification**:

- [ ] Basic table renders with mock data
- [ ] Sorting works (click header, sort pill appears)
- [ ] Filtering works (filter menu, pills, global search)
- [ ] Grouping works (single level, nested, collapse/expand)
- [ ] Selection works (row, page, across dataset, group-level)
- [ ] Bulk actions visible in selection bar
- [ ] Column visibility toggle works
- [ ] Column drag reorder works
- [ ] Pagination works (prev/next, page size)
- [ ] Inline cell editing works (text, currency)
- [ ] Right-click context menu works
- [ ] Saved views CRUD works
- [ ] Footer shows custom content
- [ ] Empty state renders when no data
- [ ] Settings panel controls work
- [ ] No production code is affected
- [ ] All existing table showcase pages still work

**Expected result**: A fully functional DataTable compound component in `apps/ui-v2-dev` that covers all 35 features from the RawTable prototype. The component is composable, typed, and documented. Production code is unaffected.

**Final status**:

- [ ] All 22 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes
- [ ] Manual verification complete
- [ ] All PRs created and merged, or ready for merge

---

## 6. Team Communication

Send to the team before merging PR 1:

> **Heads up: DataTable component infrastructure in ui-v2-dev**
>
> PR [link] adds a new `DataTable` compound component to `apps/ui-v2-dev` built on TanStack Table v8. This is the foundation for consolidating our 7 table implementations into one composable API.
>
> After pulling:
>
> 1. Run `pnpm install` (no new dependencies)
> 2. Check the showcase page for demos
>
> Files that changed and may conflict:
> - `src/components/ui-v2/Table.tsx` (primitives extended)
> - `src/components/ui-v2/index.ts` (new exports)
> - `src/lib/hooks/index.ts` (new hook exports)
>
> New files (no conflicts):
> - `src/components/ui-v2/DataTable/` (13 files)
> - `src/lib/hooks/useDataTable.ts`
> - `src/lib/hooks/useTablePersistence.ts`
>
> Known deviations or follow-ups:
> - SavedViews is a stub in PR 1, full implementation in PR 2
> - Drag-and-drop column reorder may use simplified approach
> - No production code is affected — this is ui-v2-dev only

---

## 7. What's Next

After both PRs are merged, the DataTable infrastructure is complete. Next steps:

### Phase 1: EnrichTable Migration (~20 screens)

Migrate the simplest production tables that use `EnrichTable` directly. Replace with `DataTable` using `useDataTable` in client-side mode. Use `fromExtendedColumnConfig()` adapter for quick migration.

### Phase 2: CompactTable Migration (~31 screens)

Migrate financial compact tables. Use `compactColumn` helpers for typed column definitions. Configure `useDataTable` for URL persistence.

### Phase 3: CommonTable Migration (~35 screens)

Migrate the most complex tables. Configure `useDataTable` with `config.serverSide: { isManualPagination, isManualSorting, isManualFiltering }`. Full toolbar, filter menu, saved views, selection bar.

### Lessons to carry forward

- Composition over configuration solves the "7 different tables" problem
- TanStack v8's grouping array handles nested groups logically; the rendering complexity is in the UI layer
- Context-based instance sharing (not prop-drilling) keeps compound components clean
- `enable*` flags are the right granularity for feature activation
- State persistence must be debounced and scoped to avoid infinite loops and cross-table conflicts

### Known lessons from prior phases

- Column definitions should not contain controlled state (Ant Design lesson)
- Separate data operations from rendering completely (HeroUI lesson)
- Feature shells on TanStack are portable across design systems (MRT/MR lesson)
- Register reusable cell components at the app level (TanStack v9 lesson)

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
| | 7 | |
| | 8 | |
| | 9 | |
| | 10 | |
| | 11 | |
| | 12 | |
| | 13 | |
| | 14 | |
| | 15 | |
| | 16 | |
| | 17 | |
| | 18 | |
| | 19 | |
| | 20 | |
| | 21 | |
| | 22 | |
