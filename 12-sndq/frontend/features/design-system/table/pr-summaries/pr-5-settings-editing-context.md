# DataTable — Settings + Editing + Context Menu

**Block:** `DataTable` · **Tier:** 2 (Block)

## Summary

- Grouping utilities — `computeGroupingLevels`, `buildGroupingAfterSelect`, `removeGroupingFromLevel`
- Settings panel — density, page size, and grouping controls
- Column configuration — visibility toggle and column reorder
- Inline cell editing — text, select, and custom editors via `DataTableEditableCell`
- Row context menu — right-click actions with open, handler, escape, and destructive styling coverage
- Empty state — composable zero-data UI integrated with `DataTableContent` colspan
- Completes the settings, editing, and row-interaction layer for DataTable in `@sndq/ui-v2`

## Design decisions

- **Scope** — `utils/grouping`, `DataTableSettings`, `DataTableColumnConfig`, `editors`, `DataTableEditableCell`, `DataTableEmptyState`, `parseEditorValue` in `types/columnMeta`, and co-located tests under `__tests__/components/` (plus `types/columnMeta.test.ts` and `utils/grouping.test.ts`). Row context menu test coverage includes open/action/escape/destructive styling.
- **Dependencies** — Reuses `providers/`, `EditingStoreContext`, `useDataTable`, `reorderColumnIds` from `utils/columnLayout`, Layer 1 `Table` / `TableEmptyRow`, and primitives `Popover`, `Button`, `Input`, `Field`, `Flex`, `Icon`, `Text`, `Checkbox`, `DropdownMenu`. No new npm packages; column reorder uses existing drag-end callback wiring (no extra DnD library).
- **Key patterns** — Grouping helpers are pure functions consumed by settings; settings and column config use Popover panels; editable cell opens a popover form with shared `resolveEditorField` renderers and a single active cell via editing store; empty state composes into `DataTableContent` via `emptyState` prop and spans full table colspan through `TableEmptyRow`; context menu portals to `document.body` with `useDismissLayer` for Escape.
- **Not included** — Locale/i18n (`useUILocale` deferred; hardcoded EN strings for settings, editors, and empty-state default title), currency editor variant, compound `DataTable.*` barrel export, user-facing docs under `apps/docs/`.

## Test coverage

**`utils/grouping.test.ts`** — 5 tests:

- `computeGroupingLevels` empty → empty
- `computeGroupingLevels` one level
- `computeGroupingLevels` max depth
- `buildGroupingAfterSelect` adds level
- `removeGroupingFromLevel` removes level

**`DataTableSettings.test.tsx`** — 3 tests:

- Density toggle updates table density class
- Page size change
- Group field sets grouping state

**`DataTableColumnConfig.test.tsx`** — 2 tests:

- Toggle visibility hides column
- Reorder updates header order (via `reorderColumnIds` drag-end callback)

**`types/columnMeta.test.ts`** — 3 tests:

- `parseEditorValue` text → string
- `parseEditorValue` select → string
- `parseEditorValue` custom → passthrough

**`editors.test.tsx`** — 1 test:

- Each editor renders correct input type (text, select, custom)

**`DataTableEditableCell.test.tsx`** — 5 tests:

- Click opens editor
- Enter saves and calls `onSave`
- Escape cancels without saving
- Only one cell open at a time (editing store)
- `submitOnBlur` behavior

**`DataTableRowContextMenu.test.tsx`** — 8 tests:

- Right-click opens menu
- Action calls handler with row data
- Destructive styling on destructive actions
- Escape closes menu
- Outside click closes; inside click keeps menu open
- Child `onContextMenu` handler still invoked
- Menu suppressed when child calls `preventDefault`

**`DataTableEmptyState.test.tsx`** — 4 tests:

- Default title when `title` omitted
- Custom title and description
- Optional action slot
- Full colspan integration via `DataTableContent` + empty data

**Verification (2026-06-22):** 67 test files / 420 tests passed; `pnpm --filter @sndq/ui-v2 type-check` exit 0; no regressions in prior data-table tests (334 tests at end of pagination/selection stage → 420 after this PR scope).

## Package / token changes

- `src/blocks/data-table/utils/index.ts` — grouping helper exports
- `src/blocks/data-table/types/columnMeta.ts` — `EditorMeta`, `EditorValueMap`, `parseEditorValue` for text/select/custom
- No shared token or CSS changes

## Review checklist

- [x] Scope covers grouping utils, settings, column config, inline editing, context menu tests, empty state
- [x] `pnpm --filter @sndq/ui-v2 test` and `type-check` green (67 files / 420 tests)
- [x] No regressions in prior data-table tests
- [ ] Locale/i18n intentionally absent (hardcoded EN until locale work)
- [ ] Currency editor intentionally absent
- [ ] `./blocks` compound barrel export intentionally absent
