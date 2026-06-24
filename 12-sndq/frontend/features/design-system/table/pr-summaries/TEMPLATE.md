# DataTable — PR summary templates

Two audiences — keep them separate.

| Audience | File | May include |
|----------|------|-------------|
| **GitHub PR description** | `pr-{n}-….md` | What this PR adds, design decisions, tests. Standalone wording. |
| **Internal migration tracking** | `data-table.md`, [migration-execution.md](../migration-execution.md) | PR index, commit ranges, stages, phase gates, sndq-clone source notes |

Fill PR summaries from [migration-execution.md](../migration-execution.md), then **strip internal migration framing** before pasting into GitHub.

---

## PR summary writing guidelines (GitHub-facing)

When editing `pr-*.md` for a pull request description:

- **Do not mention sndq-clone** — describe what lands in `@sndq/ui-v2`, not where it was ported from.
- **Do not reference future PRs or commit numbers** — no “deferred to PR 2”, “Commit 10”, “PR 1 of 6”, or “Stages 0–1” in the pasted body.
- **Use “Not included” for out-of-scope work** — list absent features plainly (e.g. persistence wiring, `DataTableContent`) without saying which later PR adds them.
- **Avoid migration meta** — no “matches migration-execution Commits X–Y” or “PR summary updated in `pr-summaries/`” in the GitHub text.
- **Prefer capability titles** — e.g. `# DataTable — Foundation + Core Hooks`, not `# DataTable — PR 1 Summary`.
- **Documentation section** — include `## Documentation` only when the PR adds or updates user-facing docs under `apps/docs/` (e.g. `content/docs/blocks/data-table.mdx`). If there is no `apps/docs` change, omit the section entirely — do not mention missing docs, AGENTS.md, or “not included” doc notes in the GitHub body.

Commit ranges, stage numbers, and cross-PR planning stay in `migration-execution.md` and `data-table.md` only.

Reference: [pr-1-foundation-core-hooks.md](./pr-1-foundation-core-hooks.md).

---

## PR summary template (paste into GitHub)

```markdown
# DataTable — {Capability title}

**Block:** `DataTable` · **Tier:** 2 (Block)

## Summary

{1–3 sentences: what this PR delivers in @sndq/ui-v2. No future-PR references.}

## Design decisions

- **Scope** — {main deliverables: hooks, components, utils, tests}
- **Dependencies** — {new package deps, lib hooks, Layer 1 primitives used}
- **Key patterns** — {e.g. server-side default, TanStack meta shape, test infra in `__tests__/utils/`}
- **Not included** — {features intentionally absent in this PR; no “→ PR N”}

{Include ## Documentation only when this PR adds or updates MDX under apps/docs/. Otherwise omit the section completely.}

## Test coverage

**`{file}.test.tsx`** — {N} tests:

- {grouped bullets from migration-execution test cases}

{Delete unused test-file subsections.}

**Verification ({date}):** {N} test files / {M} tests passed; `tsc --noEmit` exit 0; {regression note}.

## Package / token changes

{`package.json` / new exports, or "No shared token changes."}

## Review checklist

- [ ] Scope covers {short list of deliverables}
- [ ] `pnpm --filter @sndq/ui-v2 test` and `type-check` green
- [ ] No regressions in prior tests
- [ ] {PR-specific checks — no future-PR references}
```

---

## Feature summary template (`data-table.md`)

**Internal only** — not pasted into GitHub PR descriptions. May reference migration plan, PR index, commits, stages, and phase gates.

```markdown
# DataTable — Feature Summary

**Block:** `DataTable` · **Tier:** 2 (Block)

## Summary

{2–4 sentences: overall DataTable graduation in @sndq/ui-v2, multi-PR plan, consumer phases.}

## PR index

| PR | Summary | Commits | Stages | Doc |
|----|---------|---------|--------|-----|
| 1 | {short} | 1–8 | 0–1 | [pr-1-foundation-core-hooks.md](./pr-1-foundation-core-hooks.md) |
| 2 | {short} | 9–13 | 2–3 | [pr-2-persistence-content.md](./pr-2-persistence-content.md) |
| … | | | | |

## Design decisions (cross-cutting)

- {Layer 1 Table primitive, server-side default, ColumnMeta shape, block folder layout, etc.}

## Phase gates

| Production phase | Stages required | Unlocked by |
|------------------|-----------------|-------------|
| Phase 1: EnrichTable (~20 screens) | 0–3 + 4 (sort only) | PR 3 merge |
| Phase 2: CompactTable (~31 screens) | + 6 + 2 (URL persistence) | PR 4 merge |
| Phase 3: CommonTable (~35 screens) | + 5, 7, 8, 9, 10, 12 | PR 6 merge |

## Review checklist (graduation)

- [ ] All PR summaries complete
- [ ] Full test suite + docs
```

Migration source and sndq-clone notes belong in [migration-execution.md](../migration-execution.md), not in GitHub-facing PR summaries.
