# DataTable — PR {N} Summary

**Block:** `DataTable` · **Tier:** 2 (Block) · **PR:** {N} of 6 · **Commits:** {range} · **Stages:** {list}

## Summary

{1–3 sentences: what this PR delivers and what it unlocks.}

## Design decisions

- **Scope** — {main deliverables: hooks, components, utils}
- **Dependencies** — {new package deps, ported lib hooks, Layer 1 primitives used}
- **Key patterns** — {e.g. server-side default, TanStack meta shape, test infra in `__tests__/`}
- {Add or remove bullets as needed}

## Documentation

{MDX path if applicable; otherwise "Deferred to PR 6" or "No docs in this PR."}

## Test coverage

**`{file}.test.tsx`** — {N} tests:

- {grouped bullets from migration-execution commit test cases}

{Delete unused test-file subsections.}

## Package / token changes

{`package.json` / new exports, or "No shared token changes."}

## Review checklist

- [ ] Scope matches migration-execution Commits {range}
- [ ] `pnpm --filter @sndq/ui-v2 test` and `type-check` green
- [ ] No regressions in prior PR tests
- [ ] PR summary file updated in `pr-summaries/`
- [ ] {PR-specific checks}

---

## Feature summary template (`data-table.md`)

Use this structure for the overall feature file instead of the PR template above.

```markdown
# DataTable — Feature Summary

**Block:** `DataTable` · **Tier:** 2 (Block) · **Migration:** sndq-clone → @sndq/ui-v2

## Summary

{2–4 sentences: graduate DataTable block, 6 PRs / 33 commits, consumer phases.}

## PR index

| PR | Summary | Commits | Stages | Doc |
|----|---------|---------|-------|-----|
| 1 | {short} | 1–9 | 0–1 | [pr-1-foundation-core-hooks.md](./pr-1-foundation-core-hooks.md) |
| 2 | {short} | 10–14 | 2–3 | [pr-2-persistence-content.md](./pr-2-persistence-content.md) |
| 3 | {short} | 15–19 | 4–5 | [pr-3-sort-search-filters.md](./pr-3-sort-search-filters.md) |
| 4 | {short} | 20–22 | 6–7 | [pr-4-pagination-selection-bulk.md](./pr-4-pagination-selection-bulk.md) |
| 5 | {short} | 23–26 | 8–10 | [pr-5-settings-editing-context.md](./pr-5-settings-editing-context.md) |
| 6 | {short} | 27–33 | 11–12 | [pr-6-locale-integration-docs.md](./pr-6-locale-integration-docs.md) |

## Design decisions (cross-cutting)

- {Layer 1 Table primitive, server-side default, ColumnMeta refactor, etc.}

## Phase gates

| Production phase | Stages required | Unlocked by |
|------------------|-----------------|-------------|
| Phase 1: EnrichTable (~20 screens) | 0–3 + 4 (sort only) | PR 3 merge |
| Phase 2: CompactTable (~31 screens) | + 6 + 2 (URL persistence) | PR 4 merge |
| Phase 3: CommonTable (~35 screens) | + 5, 7, 8, 9, 10, 12 | PR 6 merge |

## Review checklist (graduation)

- [ ] All 6 PR summaries complete
- [ ] Full test suite + docs (PR 6)
```
