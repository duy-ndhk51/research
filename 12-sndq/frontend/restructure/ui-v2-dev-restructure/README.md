# UI-V2-Dev Routing Restructure

Restructure `apps/ui-v2-dev` from a single-page tab-based architecture to Next.js App Router route-based code splitting.

**Created**: 2026-05-20
**Status**: In progress (commit 12/13)
**Branch**: `feat/SQ-21402`
**Naming conventions**: `apps/docs/.cursor/rules/naming-conventions.mdc`

---

## Problem

The current `apps/ui-v2-dev` renders everything through a single client component (`ShowcasePage`) that switches between 15+ tabs via `?tab=` query params. All ~1,100 source files (492 Coss UI particles, 303 Tremor blocks, 98 SNDQ blocks, 16 component sections, forms, patterns) contribute to a single JS bundle. As the codebase grows with new integrations, the initial load and hot-reload times degrade linearly.

**Symptoms**:
- Slow initial page load (all tab content hydrated regardless of active tab)
- Slow HMR during development (full dependency graph re-evaluated)
- No per-component deep links (cannot bookmark `/primitives/button`)
- No route-level code splitting (the shell itself is monolithic)

---

## Target

Convert to a route-based architecture with automatic code splitting:

- **6 top-level categories** as routes: `/primitives`, `/blocks`, `/patterns`, `/integrations`, `/foundations`, plus `/` as landing
- **Nested layouts** that persist sidebar/tabs across sub-navigation
- **Dynamic segments** for deep linking (`[component]`, `[category]`, `[domain]`)
- **External libraries** (Coss UI, Tremor) under `/integrations/` with identical browsing patterns
- **Two route groups**: `(showcase)` with sidebar+tabs, `(standalone)` for full-page previews

---

## Constraints

- **Routing only** — zero component logic changes, no prop modifications, no styling changes
- **Zero content loss** — every tab, section, and example must have a route (see mapping below)
- **No new dependencies** — restructure uses only what's already installed
- **Naming conventions** — kebab-case dirs, PascalCase component files, `index.ts` barrels, named exports

---

## Documents

| File | Purpose |
|------|---------|
| [architecture.md](./architecture.md) | Target route tree, naming conventions, layout hierarchy, migration mapping |
| [execution.md](./execution.md) | Step-by-step commits following the execution template |
| [AGENTS.md](./AGENTS.md) | Agent guidance for Claude Code and GitHub Copilot |
| [cursor-rule.mdc](./cursor-rule.mdc) | Cursor IDE rule file (copy to `apps/ui-v2-dev/.cursor/rules/` at execution time) |

---

## Complete URL Mapping (zero gaps)

| Current tab / route | Component | New route |
|---------------------|-----------|-----------|
| `/?tab=overview` | OverviewTab | `/` |
| `/?tab=identity` | IdentityTab | `/foundations/identity` |
| `/?tab=foundation` | FoundationTab | `/foundations/tokens` |
| `/?tab=components` | ComponentsTab | `/primitives` |
| `/?tab=cell` | CellTab (RowTab.tsx) | `/primitives/row` |
| `/?tab=forms` | FormsTab | `/patterns/forms` |
| `/?tab=table` | TableRowTab | `/patterns/tables` |
| `/?tab=filter` | FilterTab | `/patterns/filters` |
| `/?tab=metric` | MetricStripTab | `/patterns/metrics` |
| `/?tab=sheet` | FloatingSheetTab | `/patterns/page-shells` |
| `/?tab=blocks` | BlocksTab | `/blocks/ui-v2` |
| `/?tab=sndq-blocks` | SndqBlocksTab | `/blocks/sndq` |
| `/?tab=composable` | ComposableTab | `/blocks/composable` |
| `/?tab=coss` | CossTab | `/integrations/coss` |
| `/?tab=tremor-blocks` | TremorBlocksTab | `/integrations/tremor` |
| `/particles` | Particle browser | `/integrations/coss` (merged) |

---

## Explicitly Dropped Content (deleted in Commit 12)

| File | Reason | Status |
|------|--------|--------|
| `TremorTab.tsx` | Orphaned — never wired to ShowcasePage, unreachable | Deleted |
| `FoundationsSection.tsx` | Orphaned — never mounted | Deleted |
| `components/forms/*.tsx` (7 files) | Duplicate of `patterns/form/` — FormsTab uses the patterns version | Deleted |
| `modules/showcase/ShowcasePage.tsx` | Replaced by route-based navigation | Deleted |
| `app/particles/` (route + UI files) | Merged into `/integrations/coss` | Deleted |

---

## Content Inventory (what must NOT be lost)

| Category | Content | File count |
|----------|---------|------------|
| Coss UI particles | 492 atomic component examples (6 sidebar groups) | ~493 files |
| Tremor blocks | 303 pre-built blocks (28 categories, 8 groups) | ~351 files |
| SNDQ blocks | 98 domain-specific blocks (18 categories) | ~98 files |
| Component sections | 16 masonry sections (Button, Input, Badge, etc.) | 17 files |
| Composable patterns | 5 assembled patterns (Financial, Info, Content, List, Text) | 5 files |
| Form patterns | 6 production forms + FormShell | 8 files |
| Identity | Markdown spec (12 sections) + design canvas (30+ vignettes) | 3 files |
| Foundation | Token swatches, color scales, type scale, icon grid | 1 file |
| Filter patterns | 11 filter UI patterns | 1 file |
| Table patterns | 6 table demos | 1 file |
| Metric patterns | 9 metric strip patterns | 1 file |
| Sheet patterns | 4 floating sheet demos | 1 file |
| Row/Cell patterns | 12 row component demos | 1 file |
| Generic blocks | KPI Cards, Headers, EntityCards, StatList, etc. | 1 file |
