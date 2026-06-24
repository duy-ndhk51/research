# DataTable migration — PR summaries

Short, review-facing markdown summaries for each pull request in the [DataTable migration](../migration-execution.md). Based on the [PR summary template](../../../restructure/monorepo-ui-design-system/templates/pr-summary-template.md), adapted for block migration PRs.

## When to create files

| File | Create when |
|------|-------------|
| [data-table.md](./data-table.md) | PR 1 work starts (overall feature umbrella) |
| [pr-1-foundation-core-hooks.md](./pr-1-foundation-core-hooks.md) | Opening PR 1 |
| [pr-2-persistence-content.md](./pr-2-persistence-content.md) | Opening PR 2 |
| [pr-3-sort-search-filters.md](./pr-3-sort-search-filters.md) | Opening PR 3 |
| [pr-4-pagination-selection-bulk.md](./pr-4-pagination-selection-bulk.md) | Opening PR 4 |
| [pr-5-settings-editing-context.md](./pr-5-settings-editing-context.md) | Opening PR 5 |
| [pr-6-locale-integration-docs.md](./pr-6-locale-integration-docs.md) | Opening PR 6 (graduation) |

Copy [TEMPLATE.md](./TEMPLATE.md) (or the feature template in TEMPLATE.md) when creating a file. Fill from the matching PR section in [migration-execution.md](../migration-execution.md). Paste the completed summary into the GitHub PR description.

## Expected files

- `data-table.md` — overall feature summary (6 PRs, phase gates)
- `pr-1-foundation-core-hooks.md` — Commits 1–8, Stages 0–1
- `pr-2-persistence-content.md` — Commits 10–14, Stages 2–3
- `pr-3-sort-search-filters.md` — Commits 15–19, Stages 4–5 (Phase 1 gate)
- `pr-4-pagination-selection-bulk.md` — Commits 20–22, Stages 6–7
- `pr-5-settings-editing-context.md` — Commits 23–26, Stages 8–10
- `pr-6-locale-integration-docs.md` — Commits 27–33, Stages 11–12 (graduation)

## Related

- [migration-execution.md](../migration-execution.md) — commit-level execution guide
- [testing-and-migration-stages.md](../testing-and-migration-stages.md) — stage specs and test cases
- [pr-summary-template.md](../../../restructure/monorepo-ui-design-system/templates/pr-summary-template.md) — parent component PR template
