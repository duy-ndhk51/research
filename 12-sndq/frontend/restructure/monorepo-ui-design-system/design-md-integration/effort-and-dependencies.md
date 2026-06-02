# Effort Estimates & Dependencies

---

## Effort Estimates

| Task | Phase | Effort | Dependencies |
|------|-------|--------|--------------|
| Write DESIGN.md (tokens + prose, no components) | Phase 2 | 2-3 hours | Token extraction complete |
| Add to CI (lint) | Phase 2 | 30 min | DESIGN.md exists |
| Batch 1 component tokens (Button, Input, Badge, Select, Dialog, Sheet) | Phase 3 | 45-60 min | Batch 1 graduated |
| Batch 2 component tokens (Card, Tabs, Tooltip, EmptyState, Skeleton) | Phase 3 | 30-45 min | Batch 2 graduated |
| Batch 3 component tokens (remaining) | Phase 3 | 30-45 min | Batch 3 graduated |
| Add diff regression check to CI | Phase 3 | 30 min | DESIGN.md in CI |
| Export drift detection script | Phase 3+ | 1-2 hours | DESIGN.md covers full token set |

**Total incremental effort**: ~6-8 hours spread across Phases 2-3.

---

## Dependencies

### Before creating DESIGN.md ~~(Phase 2)~~ (now Commit 19, Batch 1)

- [x] Phase 1a merged (monorepo structure exists)
- [x] Token extraction to `@sndq/config/tailwind/tokens.css` complete (Briicks primitives)
- [x] UI-V2 semantic tokens added to `semantic-tokens.css`
- [ ] `@google/design.md` added as devDependency in root `package.json` ← will be checked after Commit 19 execution

### Before adding component tokens (Phase 3)

- [ ] DESIGN.md exists with token-only YAML (from Phase 2 step)
- [ ] Batch N components graduated to `packages/ui-v2/`
- [ ] Component prop interfaces stable (no breaking changes expected)

### Before CI integration

- [ ] DESIGN.md committed to the repository
- [ ] `@google/design.md` available in CI environment (via devDependency or npx)

---

## Open Questions (Resolved)

All questions resolved as of 2026-05-15 (Commit 19 planning):

| # | Question | Resolution |
|---|----------|------------|
| 1 | Where does DESIGN.md live in the repo? | **Resolved** — `packages/ui-v2/DESIGN.md`. It describes the `@sndq/ui-v2` package's visual contract. The original recommendation of monorepo root was reconsidered: DESIGN.md is scoped to the graduated component library, not the legacy `sndq-fe` surface. |
| 2 | Should the Tailwind export replace manual `tokens.css` authoring? | **Resolved** — No. They coexist. `tokens.css` / `semantic-tokens.css` remain the CSS runtime artifacts. DESIGN.md is a specification + validation layer. Export drift is monitored via `pnpm run design:export:tailwind` roundtrip comparison. |
| 3 | How to handle the alpha-stage risk? | **Resolved** — Pin `^0.1.1`, wrap CLI calls in npm scripts (`design:lint`, `design:export:tailwind`, `design:export:dtcg`), monitor changelog. Low risk given Google authorship and standalone CLI with no native deps. |
| 4 | Should `@google/design.md` be a root devDep or per-package? | **Resolved** — Root devDependency. It's a monorepo-wide development tool, not a package runtime dependency. |
| 5 | How to handle dark mode tokens? | **Resolved** — Light-mode canonical values in YAML. Dark mode stays in CSS (`:root` / `.dark` in `semantic-tokens.css`). A custom Theming note in the Overview prose section explains the dark mode strategy. |
