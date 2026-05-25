# AGENTS.md — UI-V2-Dev Routing Restructure

Agent guidance for restructuring `apps/ui-v2-dev` from a single-page tab architecture to Next.js App Router route-based code splitting.

**Scope**: Routing and file organization only. Zero component logic changes.
**Status**: In progress (commit 12/13) — tab files relocated, old code deleted, documentation pending.

---

## What You Are Doing

Converting `apps/ui-v2-dev` from:
- A single `ShowcasePage` client component (15 tabs via `?tab=` + 1 overview)
- ~1,100 source files loaded in one bundle
- External libraries (Coss UI, Tremor) embedded as tabs

To:
- Route-based architecture with automatic code splitting per category
- Nested layouts for persistent navigation (sidebar + sub-tabs)
- External libraries under `/integrations/` with their own browsing UIs
- Deep-linkable URLs (`/primitives`, `/integrations/coss/button`, `/blocks/sndq/building`)

---

## Critical Constraints

### DO

- Import components from route-colocated `_components/` directories
- Add `'use client'` when a page imports components using React hooks
- Follow [execution.md](./execution.md) commit by commit
- Treat Coss UI and Tremor as external library integrations (under `/integrations/`)
- Use `@/` alias imports for cross-directory references

### DO NOT

- Modify any component's internal logic, props, or styling
- Change how components render (only where they're imported from)
- Add new npm dependencies
- Modify `globals.css` or design tokens
- Change anything in `packages/ui-v2/` or `packages/config/`
- Skip verification after each commit
- Import from `@/components/tabs/` (deleted in Commit 12)

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Directories | kebab-case | `data-table/`, `page-shells/` |
| Component files | PascalCase `.tsx` | `Sidebar.tsx`, `ButtonPrimary.tsx` |
| Hook files | camelCase starting with `use` | `useToast.ts` |
| Barrel files | `index.ts` | Every folder gets one |
| Exports | Named only | `export function X()` — never `export default` |
| Route pages | `page.tsx` | Next.js convention |
| Route layouts | `layout.tsx` | Next.js convention |
| Dynamic segments | `[param]` | `[component]/page.tsx` |
| Route groups | `(name)` | `(showcase)/`, `(standalone)/` |

---

## Route Structure

```
src/app/
├── layout.tsx                    # Root: fonts + globals.css
├── page.tsx                      # OverviewTab (landing — 4 layer cards)
├── _components/
│   └── OverviewContent.tsx       # Relocated from tabs/OverviewTab.tsx
│
├── (showcase)/                   # Sidebar + content
│   ├── layout.tsx                # Sidebar nav
│   │
│   ├── primitives/               # /primitives
│   │   ├── layout.tsx            # Category sub-tabs
│   │   ├── page.tsx              # 16 sections grid
│   │   ├── _components/PrimitivesContent.tsx
│   │   └── [component]/page.tsx  # Single primitive (e.g., /primitives/row)
│   │
│   ├── blocks/                   # /blocks
│   │   ├── layout.tsx            # Sub-tabs: ui-v2 | sndq | composable
│   │   ├── ui-v2/page.tsx + _components/BlocksContent.tsx
│   │   ├── sndq/page.tsx + _components/SndqBlocksContent.tsx
│   │   ├── sndq/[domain]/page.tsx
│   │   └── composable/page.tsx   # ComposableTab inlined (47 lines)
│   │
│   ├── patterns/                 # /patterns
│   │   ├── layout.tsx            # Sub-tabs
│   │   ├── forms/page.tsx + _components/FormsContent.tsx
│   │   ├── tables/page.tsx + _components/TableContent.tsx
│   │   ├── filters/page.tsx + _components/FilterContent.tsx
│   │   ├── metrics/page.tsx + _components/MetricContent.tsx
│   │   └── page-shells/page.tsx + _components/FloatingSheetContent.tsx
│   │
│   ├── integrations/             # /integrations — external libraries
│   │   ├── layout.tsx            # Sub-tabs
│   │   ├── coss/page.tsx + _components/CossBrowser.tsx
│   │   ├── coss/[category]/page.tsx
│   │   ├── tremor/page.tsx + _components/TremorBrowser.tsx
│   │   ├── tremor/[category]/page.tsx
│   │   ├── charts/page.tsx       # Placeholder
│   │   ├── data-table/page.tsx   # Placeholder
│   │   ├── forms/page.tsx        # Placeholder
│   │   └── date-pickers/page.tsx # Placeholder
│   │
│   └── foundations/              # /foundations
│       ├── layout.tsx            # Sub-tabs: identity | tokens
│       ├── identity/page.tsx + _components/IdentityContent.tsx + identity/
│       └── tokens/page.tsx + _components/FoundationContent.tsx
│
└── (standalone)/                 # No sidebar
    └── preview/[component]/page.tsx
```

---

## Complete URL Mapping (16 tabs → routes)

| Tab value | Component | Route |
|-----------|-----------|-------|
| `overview` | OverviewTab | `/` |
| `components` | ComponentsTab | `/primitives` |
| `cell` | CellTab (RowTab.tsx) | `/primitives/row` |
| `blocks` | BlocksTab | `/blocks/ui-v2` |
| `sndq-blocks` | SndqBlocksTab | `/blocks/sndq` |
| `composable` | ComposableTab | `/blocks/composable` |
| `forms` | FormsTab | `/patterns/forms` |
| `table` | TableRowTab | `/patterns/tables` |
| `filter` | FilterTab | `/patterns/filters` |
| `metric` | MetricStripTab | `/patterns/metrics` |
| `sheet` | FloatingSheetTab | `/patterns/page-shells` |
| `coss` | CossTab | `/integrations/coss` |
| `tremor-blocks` | TremorBlocksTab | `/integrations/tremor` |
| `identity` | IdentityTab | `/foundations/identity` |
| `foundation` | FoundationTab | `/foundations/tokens` |
| `/particles` route | Particle browser | `/integrations/coss` (merged) |

---

## External Libraries Pattern

Coss UI and Tremor are both external integrated libraries. They follow an identical route pattern:

```
integrations/
├── {library}/
│   ├── page.tsx           # Full browser with sidebar categories
│   └── [category]/
│       └── page.tsx       # Category-filtered view
```

Both use:
- Sidebar with category groups (collapsible)
- Lazy-loaded examples via registry
- Dynamic `[category]` segment for deep linking
- Grid layout for example display

---

## Dropped Content (deleted in Commit 12)

These files were identified as dead code and have been deleted:

| File | Reason |
|------|--------|
| `src/components/tabs/` (entire directory) | Relocated to route-colocated `_components/` dirs |
| `src/modules/showcase/ShowcasePage.tsx` | Replaced by route-based navigation |
| `src/components/tabs/TremorTab.tsx` | Orphaned — never imported |
| `src/components/sections/FoundationsSection.tsx` | Orphaned — never mounted |
| `src/components/forms/*.tsx` (7 files) | Duplicate of `src/patterns/form/` |
| `src/app/particles/` (route + UI files) | Merged into `/integrations/coss`; data relocated |

---

## Verification Commands

Run after every commit:

```bash
pnpm --filter @sndq/ui-v2-dev run type-check
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev dev
```

---

## Commit Order

| # | Message | Key action |
|---|---------|-----------|
| 1 | `feat: add showcase route group with sidebar layout` | Create layout, OverviewTab as root |
| 2 | `feat: add foundations routes (identity + tokens)` | First working routes |
| 3 | `feat: add shared layout and showcase components` | TopTabs, ComponentGrid, etc. |
| 4 | `feat: add component registry scaffolding` | Registry files |
| 5 | `feat: add primitives route with ComponentsTab` | /primitives + [component] |
| 6 | `feat: add blocks routes (ui-v2, sndq, composable)` | Three block sources |
| 7 | `feat: add patterns routes (forms, tables, filters, metrics, shells)` | Five pattern types |
| 8 | `feat: add integrations/coss route (particle browser)` | 492 particles |
| 9 | `feat: add integrations/tremor route (block library)` | ~303 blocks |
| 10 | `feat: add integration placeholder routes` | charts, data-table, forms, date-pickers |
| 11 | `feat: add standalone preview route` | Full-page preview |
| 12 | `refactor: remove old ShowcasePage, tabs, and particles` | Delete old code |
| 13 | `docs: update ui-v2-dev documentation for route structure` | Add cursor rule |

---

## Error Recovery

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Cannot find module '@/components/tabs/...'` | Stale import from deleted tabs/ dir | Update to import from `_components/` or `@/components/showcase/` |
| `useState is not defined` | Server component imports client hook | Add `'use client'` to the page |
| 404 on route | Missing `page.tsx` | Create the file in correct location |
| Hydration mismatch | Server/client render different content | Use `dynamic(import, { ssr: false })` |
| `Module not found: @/examples/...` | Registry references missing path | Create barrel `index.ts` or fix path |
