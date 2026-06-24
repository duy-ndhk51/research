# DataTable — Pagination + Selection + Bulk Actions

**Block:** `DataTable` · **Tier:** 2 (Block)

## Summary

Adds pagination utilities and footer components, row selection UI (selection bar with page select and select-all-across-dataset), a floating bulk-actions bar (render-prop API portaled to the document body), and a toolbar that hides while rows are selected. Delivers the client-side pagination, selection, and bulk-action flow needed before CompactTable screen migrations.

## Design decisions

- **Scope** — `utils/pagination`, `DataTablePagination`, `DataTableFooter`, `DataTableSelectionBar`, `DataTableBulkActions`, `DataTableToolbar`, and co-located tests. Selection column wiring remains in `useDataTable`; `selectAllMode` clears when individual rows are deselected via `usePersistedTableState`.
- **Dependencies** — Reuses `providers/`, `useDataTable`, Layer 1 `Table`, `Flex`, `Button`, `Text`, `Checkbox`, `DropdownMenu`. No new npm packages.
- **Key patterns** — Pagination range/summary helpers are pure functions; footer composes pagination slot + custom children; selection bar swaps with toolbar (mutually exclusive by selection count); bulk actions use `createPortal` + fade transition with `lastVisibleProps` for exit animation; Escape deselects all when bulk bar is visible.
- **Not included** — Locale/i18n (`useUILocale` deferred; hardcoded EN strings for pagination and selection), server-side pagination integration tests, settings/column config, compound `DataTable.*` barrel export, user-facing docs under `apps/docs/`.

## Test coverage

**`utils/pagination.test.ts`** — 3 tests:

- `getPaginationRange(0, 10, 25)` → 1–10
- Last page range edge case
- `formatPaginationSummary` empty → "0 results"

**`DataTablePagination.test.tsx`** — 3 tests:

- Next/prev disabled at bounds (first/prev stay enabled on last page; only next/last disabled)
- Page indicator text
- Page size change updates visible row count (client-side)

**`DataTableFooter.test.tsx`** — 1 test:

- Renders children alongside pagination slot

**`DataTableContentSelection.integration.test.tsx`** — 3 tests:

- Row checkbox toggles selection
- Header checkbox selects page
- Indeterminate when partial page selection

**`DataTableSelectionBar.test.tsx`** — 4 tests:

- Hidden when selection count is zero
- Shows N selected
- "Select all {total}" sets `selectAllMode`
- Deselect one row clears `selectAllMode`

**`DataTableBulkActions.test.tsx`** — 3 tests:

- Renders actions slot when rows are selected
- Passes `totalCount` to render prop
- Escape deselects all (row `data-selected` + dialog hidden state)

**`DataTableToolbar.test.tsx`** — 2 tests:

- Hidden when selection is active
- Visible when selection is cleared

**Verification (2026-06-22):** 56 test files / 334 tests passed; `pnpm --filter @sndq/ui-v2 type-check` exit 0; no regressions in prior data-table tests (312 tests at end of filter stage → 334 after this PR scope).

## Package / token changes

- `src/blocks/data-table/utils/index.ts` — pagination helper exports
- No shared token or CSS changes

## Review checklist

- [x] Scope covers pagination utils/components, selection bar, bulk actions, toolbar visibility
- [x] `pnpm --filter @sndq/ui-v2 test` and `type-check` green (56 files / 334 tests)
- [x] No regressions in prior data-table tests
- [ ] Locale/i18n intentionally absent (hardcoded EN until locale commit)
- [ ] Server-side pagination tests intentionally deferred
- [ ] `./blocks` compound barrel export intentionally absent
