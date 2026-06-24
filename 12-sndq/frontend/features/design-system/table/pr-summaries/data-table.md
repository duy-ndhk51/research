# DataTable — Feature Summary

**Block:** `DataTable` · **Tier:** 2 (Block) · **Migration:** sndq-clone → `@sndq/ui-v2`

## Summary

Graduates the DataTable block from `sndq-clone/packages/ui-v2/src/blocks/data-table` into production `@sndq/ui-v2` across 6 PRs (~32 commits). Builds on the existing Layer 1 `Table` primitive. Column definitions use `@tanstack/react-table` `createColumnHelper` with `ColumnMeta` augmentation — no ui-v2 column helper utils.

## PR index

| PR | Summary | Commits | Stages | Doc |
|----|---------|---------|--------|-----|
| 1 | Foundation + core hooks | 1–8 | 0–1 | [pr-1-foundation-core-hooks.md](./pr-1-foundation-core-hooks.md) |
| 2 | Persistence + content rendering | 9–13 | 2–3 | [pr-2-persistence-content.md](./pr-2-persistence-content.md) |
| 3 | Sort + search + filters (Phase 1 gate) | 14–18 | 4–5 | [pr-3-sort-search-filters.md](./pr-3-sort-search-filters.md) *(create when opening PR 3)* |
| 4 | Pagination + selection + bulk | 19–21 | 6–7 | [pr-4-pagination-selection-bulk.md](./pr-4-pagination-selection-bulk.md) |
| 5 | Settings + editing + context menu | 22–25 | 8–10 | [pr-5-settings-editing-context.md](./pr-5-settings-editing-context.md) *(create when opening PR 5)* |
| 6 | Locale + integration + server-side + docs | 26–32 | 11–12 | [pr-6-locale-integration-docs.md](./pr-6-locale-integration-docs.md) *(create when opening PR 6)* |

## Design decisions (cross-cutting)

- Layer 1 `Table` primitive contract preserved — DataTable composes, does not replace it
- Server-side mode default (`manualSorting` / `manualFiltering` / `manualPagination`) unless `config.clientSide: true`
- `ColumnMeta`: `filter?: FilterMeta`, `editor?: EditorMeta`, `align`, `skeleton`, `groupable`
- Block folder layout: `types/`, `constants/`, `hooks/`, `utils/` (production), `__tests__/utils/` (test helpers)
- Assert visible UI outcomes in tests, not TanStack internal state

## Phase gates

| Production phase | Stages required | Unlocked by |
|------------------|-----------------|-------------|
| Phase 1: EnrichTable (~20 screens) | 0–3 + 4 (sort only) | PR 3 merge |
| Phase 2: CompactTable (~31 screens) | + 6 + 2 (URL persistence) | PR 4 merge |
| Phase 3: CommonTable (~35 screens) | + 5, 7, 8, 9, 10, 12 | PR 6 merge |

## Review checklist (graduation)

- [x] PR 1 summary complete — [pr-1-foundation-core-hooks.md](./pr-1-foundation-core-hooks.md)
- [x] PR 2 summary complete — [pr-2-persistence-content.md](./pr-2-persistence-content.md)
- [x] PR 4 summary complete — [pr-4-pagination-selection-bulk.md](./pr-4-pagination-selection-bulk.md)
- [ ] All 6 PR summaries complete
- [ ] Full test suite + docs (PR 6)
