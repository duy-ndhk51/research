# Routing Restructure Execution — UI-V2-Dev Route Splitting

Step-by-step execution guide for the ui-v2-dev routing restructure. Each commit should be independently verifiable and revertable.

**Created**: 2026-05-20
**Status**: In progress (commit 6/13)
**Architecture**: [architecture.md](./architecture.md)
**Branch**: `feat/SQ-21402`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Scaffold Route Shell](#3-pr-1--scaffold-route-shell)
4. [PR 2 — Migrate Categories](#4-pr-2--migrate-categories)
5. [PR 3 — Cleanup](#5-pr-3--cleanup)
6. [Final Verification](#6-final-verification)
7. [Team Communication](#7-team-communication)
8. [What's Next](#8-whats-next)
9. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Convert `apps/ui-v2-dev` from a single-page tab-based architecture to route-based code splitting. Zero component logic changes — only routing and file organization.

**Structure**: 13 commits across 3 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Scaffold route shell + layouts + registry | Low | 1-4 |
| **PR 2** | Migrate all 15 tabs to route-based pages | Medium | 5-11 |
| **PR 3** | Remove old tab-based code + cleanup | Low | 12-13 |

**Why 3 PRs**: PR 1 adds new routes alongside the existing tab system (no breaking changes). PR 2 moves content into routes (validates each category). PR 3 removes old code only after routes are fully verified.

### Prerequisites

- `pnpm --filter @sndq/ui-v2-dev dev` runs without errors on current `dev` branch
- Monorepo workspace packages (`@sndq/config`, `@sndq/ui-v2`) are available

### Known constraints

- `CossTab` and `/particles` both use `registry-particles.ts` + `examples/` — must consolidate into `/integrations/coss`
- Tab components may use client hooks — route pages wrapping them need `'use client'`
- `ShowcasePage` uses `useSearchParams()` — removing it in PR 3 eliminates client-only navigation
- `RowTab.tsx` exports as `CellTab` (tab value `cell`) — route is `/primitives/row`

---

## 2. Before You Start

### Quality gate before each implementation commit

- [ ] Public API / behavior is stable for this commit scope
- [ ] Existing project helpers and patterns are reused
- [ ] No unrelated files, app-specific imports, or ownership-boundary leaks
- [ ] Security-sensitive values are not committed
- [ ] Build, lint, type-check commands are known before editing
- [ ] Any skipped verification is recorded as a deviation

### Capture baselines

```bash
pnpm --filter @sndq/ui-v2-dev run build 2>&1 | tee /tmp/ui-v2-dev-restructure-build-before.txt
pnpm --filter @sndq/ui-v2-dev run type-check 2>&1 | tee /tmp/ui-v2-dev-restructure-typecheck-before.txt
pnpm --filter @sndq/ui-v2-dev run lint 2>&1 | tee /tmp/ui-v2-dev-restructure-lint-before.txt
```

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/ui-v2-dev-route-restructure
```

---

## 3. PR 1 — Scaffold Route Shell

Pure additions alongside existing code. Old `ShowcasePage` continues to work. New routes are accessible at their target URLs.

---

### Commit 1: Add showcase route group with sidebar layout

**What**: Create `(showcase)/layout.tsx` with sidebar navigation. Root `page.tsx` renders OverviewTab directly (no redirect).

**Files to create**:

- `src/app/(showcase)/layout.tsx`
- `src/components/layout/Sidebar.tsx`
- `src/components/layout/index.ts`

**Files to edit**:

- `src/app/page.tsx` — change from `<ShowcasePage />` to `<OverviewTab />`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit http://localhost:3001/ — should render OverviewTab (4 layer cards)
# Visit http://localhost:3001/primitives — should show sidebar layout (placeholder)
```

**Commit message**: `feat: add showcase route group with sidebar layout`

---

### Commit 2: Add foundations routes (identity + tokens)

**What**: Create `/foundations/identity` and `/foundations/tokens` routes. First working routes to validate layout hierarchy.

**Files to create**:

- `src/app/(showcase)/foundations/layout.tsx` — sub-tabs (Identity | Tokens)
- `src/app/(showcase)/foundations/page.tsx` — redirect to `/foundations/identity`
- `src/app/(showcase)/foundations/identity/page.tsx` — wraps `IdentityTab`
- `src/app/(showcase)/foundations/tokens/page.tsx` — wraps `FoundationTab`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit /foundations/identity — should render IdentityTab (spec + canvas)
# Visit /foundations/tokens — should render FoundationTab (swatches)
```

**Commit message**: `feat: add foundations routes (identity + tokens)`

---

### Commit 3: Add shared layout and showcase components

**What**: Create TopTabs, ComponentGrid, ExampleCard, LazyExample, VariantSection.

**Files to create**:

- `src/components/layout/TopTabs.tsx`
- `src/components/layout/ComponentGrid.tsx`
- `src/components/showcase/ExampleCard.tsx`
- `src/components/showcase/VariantSection.tsx`
- `src/components/showcase/LazyExample.tsx`
- `src/components/showcase/index.ts`

**Files to edit**:

- `src/components/layout/index.ts` — add new exports

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `feat: add shared layout and showcase components`

---

### Commit 4: Add registry scaffolding

**What**: Create registry files for primitives, blocks, and integrations.

**Files to create**:

- `src/registry/primitives.ts`
- `src/registry/blocks.ts`
- `src/registry/integrations.ts`
- `src/registry/categories.ts`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `feat: add component registry scaffolding`

---

### PR 1 Checkpoint

```bash
git push -u origin feature/ui-v2-dev-route-restructure
```

**This validates**: Route groups render, sidebar works, layout hierarchy correct, no type errors.

---

## 4. PR 2 — Migrate Categories

Moves existing tab content into route-based pages. Each commit migrates one category group.

---

### Commit 5: Add primitives route (ComponentsTab)

**What**: Create `/primitives` route rendering ComponentsTab content (masonry grid, 16 sections). Add `/primitives/[component]` for deep-linking (e.g., `/primitives/row` renders CellTab/RowTab).

**Files to create**:

- `src/app/(showcase)/primitives/layout.tsx` — category sub-tabs
- `src/app/(showcase)/primitives/page.tsx` — wraps `ComponentsTab`
- `src/app/(showcase)/primitives/[component]/page.tsx` — per-primitive view

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit /primitives — should show ComponentsTab masonry grid
# Visit /primitives/row — should show CellTab (Row component patterns)
```

**Commit message**: `feat: add primitives route with ComponentsTab`

---

### Commit 6: Add blocks routes (ui-v2, sndq, composable)

**What**: Create `/blocks` routes for all three block sources.

**Files to create**:

- `src/app/(showcase)/blocks/layout.tsx` — sub-tabs (UI-V2 | SNDQ | Composable)
- `src/app/(showcase)/blocks/page.tsx` — redirect to ui-v2
- `src/app/(showcase)/blocks/ui-v2/page.tsx` — wraps `BlocksTab`
- `src/app/(showcase)/blocks/sndq/page.tsx` — wraps `SndqBlocksTab`
- `src/app/(showcase)/blocks/sndq/[domain]/page.tsx` — per-domain view
- `src/app/(showcase)/blocks/composable/page.tsx` — wraps `ComposableTab`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit /blocks/ui-v2 — BlocksTab (KPI, Headers, EntityCards, etc.)
# Visit /blocks/sndq — SndqBlocksTab category grid
# Visit /blocks/sndq/building — building domain blocks
# Visit /blocks/composable — ComposableTab (5 patterns)
```

**Commit message**: `feat: add blocks routes (ui-v2, sndq, composable)`

---

### Commit 7: Add patterns routes (forms, tables, filters, metrics, page-shells)

**What**: Create `/patterns` routes for all five pattern types.

**Files to create**:

- `src/app/(showcase)/patterns/layout.tsx` — sub-tabs
- `src/app/(showcase)/patterns/page.tsx` — redirect to forms
- `src/app/(showcase)/patterns/forms/page.tsx` — wraps `FormsTab`
- `src/app/(showcase)/patterns/tables/page.tsx` — wraps `TableRowTab`
- `src/app/(showcase)/patterns/filters/page.tsx` — wraps `FilterTab`
- `src/app/(showcase)/patterns/metrics/page.tsx` — wraps `MetricStripTab`
- `src/app/(showcase)/patterns/page-shells/page.tsx` — wraps `FloatingSheetTab`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit /patterns/forms — FormsTab (6 form patterns)
# Visit /patterns/tables — TableRowTab (6 tables)
# Visit /patterns/filters — FilterTab (11 patterns)
# Visit /patterns/metrics — MetricStripTab (9 patterns)
# Visit /patterns/page-shells — FloatingSheetTab (4 demos)
```

**Commit message**: `feat: add patterns routes (forms, tables, filters, metrics, shells)`

---

### Commit 8: Add integrations/coss route (particle browser)

**What**: Create `/integrations/coss` route rendering CossTab (492 particles). Move particle examples from `src/app/particles/examples/` to `src/examples/integrations/coss/`.

**Files to create**:

- `src/app/(showcase)/integrations/layout.tsx` — library sub-tabs
- `src/app/(showcase)/integrations/page.tsx` — redirect to coss
- `src/app/(showcase)/integrations/coss/page.tsx` — wraps `CossTab`
- `src/app/(showcase)/integrations/coss/[category]/page.tsx` — category-filtered view

**Files to move**:

- `src/app/particles/examples/p-*.tsx` → `src/examples/integrations/coss/[category]/`
- `src/app/particles/registry-particles.ts` → `src/registry/integrations.ts` (coss entries)

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit /integrations/coss — full particle browser (6 sidebar groups)
# Visit /integrations/coss/button — button category particles
```

**Commit message**: `feat: add integrations/coss route (particle browser)`

---

### Commit 9: Add integrations/tremor route (block library)

**What**: Create `/integrations/tremor` route rendering TremorBlocksTab (~303 blocks). Move block files from `src/components/blocks/` to `src/examples/integrations/tremor/`.

**Files to create**:

- `src/app/(showcase)/integrations/tremor/page.tsx` — wraps `TremorBlocksTab`
- `src/app/(showcase)/integrations/tremor/[category]/page.tsx` — category view

**Files to move**:

- `src/components/blocks/[category]/*.tsx` → `src/examples/integrations/tremor/[category]/`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit /integrations/tremor — category grid (28 categories)
# Visit /integrations/tremor/kpi-cards — KPI card variants
```

**Commit message**: `feat: add integrations/tremor route (block library)`

---

### Commit 10: Add remaining integration routes (charts, data-table, forms, date-pickers)

**What**: Create placeholder routes for future integration content.

**Files to create**:

- `src/app/(showcase)/integrations/charts/page.tsx`
- `src/app/(showcase)/integrations/data-table/page.tsx`
- `src/app/(showcase)/integrations/forms/page.tsx`
- `src/app/(showcase)/integrations/date-pickers/page.tsx`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run type-check
# Visit /integrations/charts — placeholder page
```

**Commit message**: `feat: add integration placeholder routes`

---

### Commit 11: Add standalone preview route

**What**: Create `(standalone)/preview/[component]/` for full-page previews without sidebar.

**Files to create**:

- `src/app/(standalone)/preview/[component]/page.tsx`

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev dev
# Visit /preview/button — renders without sidebar
```

**Commit message**: `feat: add standalone preview route`

---

### PR 2 Checkpoint

```bash
git push origin feature/ui-v2-dev-route-restructure
```

**This validates**: All 15 tabs have corresponding routes, external libraries are under `/integrations/`, lazy loading works.

**Manual checkpoint — verify every route**:

- [ ] `/` — OverviewTab (4 layer cards)
- [ ] `/primitives` — ComponentsTab masonry grid
- [ ] `/primitives/row` — CellTab (Row patterns)
- [ ] `/blocks/ui-v2` — BlocksTab (generic blocks)
- [ ] `/blocks/sndq` — SndqBlocksTab (domain blocks)
- [ ] `/blocks/sndq/building` — building domain
- [ ] `/blocks/composable` — ComposableTab
- [ ] `/patterns/forms` — FormsTab
- [ ] `/patterns/tables` — TableRowTab
- [ ] `/patterns/filters` — FilterTab
- [ ] `/patterns/metrics` — MetricStripTab
- [ ] `/patterns/page-shells` — FloatingSheetTab
- [ ] `/integrations/coss` — CossTab (492 particles)
- [ ] `/integrations/coss/button` — button category
- [ ] `/integrations/tremor` — TremorBlocksTab
- [ ] `/integrations/tremor/kpi-cards` — KPI category
- [ ] `/foundations/identity` — IdentityTab
- [ ] `/foundations/tokens` — FoundationTab
- [ ] `/preview/button` — standalone preview

---

## 5. PR 3 — Cleanup

Removes old tab-based code after all routes are verified.

---

### Commit 12: Remove old ShowcasePage, tabs, and particles route

**What**: Delete the monolithic `ShowcasePage`, all tab wrapper components, and the old `/particles` route.

**Files to delete**:

- `src/modules/showcase/ShowcasePage.tsx`
- `src/components/tabs/OverviewTab.tsx`
- `src/components/tabs/IdentityTab.tsx`
- `src/components/tabs/FoundationTab.tsx`
- `src/components/tabs/ComponentsTab.tsx`
- `src/components/tabs/FormsTab.tsx`
- `src/components/tabs/SndqBlocksTab.tsx`
- `src/components/tabs/BlocksTab.tsx`
- `src/components/tabs/ComposableTab.tsx`
- `src/components/tabs/RowTab.tsx`
- `src/components/tabs/FloatingSheetTab.tsx`
- `src/components/tabs/TableRowTab.tsx`
- `src/components/tabs/MetricStripTab.tsx`
- `src/components/tabs/FilterTab.tsx`
- `src/components/tabs/CossTab.tsx`
- `src/components/tabs/TremorBlocksTab.tsx`
- `src/components/tabs/TremorTab.tsx` (orphaned)
- `src/components/tabs/identity/` (entire folder)
- `src/app/particles/` (entire folder — merged into `/integrations/coss`)
- `src/components/sections/FoundationsSection.tsx` (orphaned)
- `src/components/forms/` (entire folder — duplicate)
- `src/components/ComponentCard.tsx` (replaced by ExampleCard)

**Note**: Only delete tab files AFTER confirming route pages have been updated to import directly from the underlying components/sections rather than through the tab wrappers.

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run type-check
pnpm --filter @sndq/ui-v2-dev run build
```

**Commit message**: `refactor: remove old ShowcasePage, tabs, and particles`

---

### Commit 13: Update documentation and add cursor rule

**What**: Update AGENTS.md in the app, add the cursor rule file.

**Files to create**:

- `apps/ui-v2-dev/.cursor/rules/ui-v2-dev-routing.mdc` — from `cursor-rule.mdc` in this plan

**Files to edit**:

- `apps/ui-v2-dev/AGENTS.md` (if exists) — update to reflect new structure

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run type-check
pnpm --filter @sndq/ui-v2-dev run lint
```

**Commit message**: `docs: update ui-v2-dev documentation for route structure`

---

### PR 3 Checkpoint

```bash
git push origin feature/ui-v2-dev-route-restructure
```

**This validates**: No orphan imports, build passes, all old code cleanly removed.

---

## 6. Final Verification

After all 13 commits:

```bash
pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run type-check
pnpm --filter @sndq/ui-v2-dev run lint
```

**Manual verification** — all 19 routes from PR 2 checkpoint must still work.

**Expected result**: All routes work, build succeeds, bundle is smaller per-route (code splitting confirmed via Network tab).

---

## 7. Team Communication

> **Heads up: ui-v2-dev route restructure**
>
> PR [link] restructures the dev playground from tab-based to route-based navigation. After pulling:
>
> 1. Run `pnpm install`
> 2. Access at `http://localhost:3001/` (landing) or directly at `/primitives`, `/integrations/coss`, etc.
>
> Key URL changes:
> - `/?tab=coss` → `/integrations/coss`
> - `/?tab=tremor-blocks` → `/integrations/tremor`
> - `/?tab=components` → `/primitives`
> - `/particles` → `/integrations/coss`
>
> Old `/?tab=` URLs no longer work after merge.

---

## 8. What's Next

1. **Populate integration routes** — add chart, data-table, form, date-picker examples
2. **Graduation workflow** — move prototypes to `packages/ui-v2/` as they mature
3. **Search** — add global search across registry entries
4. **Loading states** — add `loading.tsx` to heavy routes

---

## Execution Log

| Date | Commit | Notes |
|------|--------|-------|
| 2026-05-20 | 1 | Done. Added placeholder `primitives/page.tsx` (not in original plan) to validate layout renders at `/primitives`. |
| 2026-05-20 | 2 | Done. All 3 routes verified: /foundations/identity, /foundations/tokens, /foundations (redirect). |
| 2026-05-20 | 3 | Done. TopTabs, ComponentGrid, ExampleCard, VariantSection, LazyExample created. Type-check clean. |
| 2026-05-20 | 4 | Done. Registry scaffolding: categories.ts, primitives.ts, blocks.ts, integrations.ts. Type-check clean. |
| 2026-05-20 | 5 | Done. /primitives wraps ComponentsTab, /primitives/row renders CellTab via dynamic route. Both verified 200. |
| 2026-05-20 | 6 | Done. All 5 routes verified: /blocks (redirect), /blocks/ui-v2, /blocks/sndq, /blocks/sndq/building, /blocks/composable. Layout needed 'use client' for icon props. |
| | 7 | |
| | 8 | |
| | 9 | |
| | 10 | |
| | 11 | |
| | 12 | |
| | 13 | |
