# AGENTS.md — UI-V2-Dev Routing Restructure

Agent guidance for restructuring `apps/ui-v2-dev` from a single-page tab architecture to Next.js App Router route-based code splitting.

**Scope**: Routing and file organization only. Zero component logic changes.

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

- Move files to new locations following naming conventions
- Create route `page.tsx` and `layout.tsx` files
- Create `index.ts` barrel files in every component/example folder
- Use named exports only
- Import existing tab components — wrap them in route pages
- Add `'use client'` when a page imports components using React hooks
- Follow [execution.md](./execution.md) commit by commit
- Treat Coss UI and Tremor as external library integrations (under `/integrations/`)

### DO NOT

- Modify any component's internal logic, props, or styling
- Change how components render (only where they're imported from)
- Add new npm dependencies
- Create new UI components (only layout scaffolding)
- Modify `globals.css` or design tokens
- Change anything in `packages/ui-v2/` or `packages/config/`
- Skip verification after each commit
- Move `TremorTab.tsx` or `FoundationsSection.tsx` (they are dropped — orphaned dead code)

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
│
├── (showcase)/                   # Sidebar + content
│   ├── layout.tsx                # Sidebar nav
│   │
│   ├── primitives/               # /primitives — ComponentsTab (masonry gallery)
│   │   ├── layout.tsx            # Category sub-tabs
│   │   ├── page.tsx              # 16 sections grid
│   │   └── [component]/page.tsx  # Single primitive (e.g., /primitives/row)
│   │
│   ├── blocks/                   # /blocks
│   │   ├── layout.tsx            # Sub-tabs: ui-v2 | sndq | composable
│   │   ├── ui-v2/page.tsx        # BlocksTab (generic blocks)
│   │   ├── sndq/page.tsx         # SndqBlocksTab (18 domain categories)
│   │   ├── sndq/[domain]/page.tsx
│   │   └── composable/page.tsx   # ComposableTab (5 patterns)
│   │
│   ├── patterns/                 # /patterns
│   │   ├── layout.tsx            # Sub-tabs: forms | tables | filters | metrics | page-shells
│   │   ├── forms/page.tsx        # FormsTab (6 form patterns)
│   │   ├── tables/page.tsx       # TableRowTab (6 tables)
│   │   ├── filters/page.tsx      # FilterTab (11 patterns)
│   │   ├── metrics/page.tsx      # MetricStripTab (9 patterns)
│   │   └── page-shells/page.tsx  # FloatingSheetTab (4 demos)
│   │
│   ├── integrations/             # /integrations — external libraries
│   │   ├── layout.tsx            # Sub-tabs: coss | tremor | charts | data-table | forms | date-pickers
│   │   ├── coss/page.tsx         # CossTab (492 particles, sidebar categories)
│   │   ├── coss/[category]/page.tsx
│   │   ├── tremor/page.tsx       # TremorBlocksTab (~303 blocks, 28 categories)
│   │   ├── tremor/[category]/page.tsx
│   │   ├── charts/page.tsx       # Recharts integration
│   │   ├── data-table/page.tsx   # @tanstack/react-table
│   │   ├── forms/page.tsx        # react-hook-form + zod
│   │   └── date-pickers/page.tsx # react-day-picker
│   │
│   └── foundations/              # /foundations
│       ├── layout.tsx            # Sub-tabs: identity | tokens
│       ├── identity/page.tsx     # IdentityTab (spec + canvas)
│       └── tokens/page.tsx       # FoundationTab (swatches + scales)
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

## Dropped Content

These files are dead code and should NOT be migrated:

| File | Reason |
|------|--------|
| `src/components/tabs/TremorTab.tsx` | Orphaned — never imported in ShowcasePage |
| `src/components/sections/FoundationsSection.tsx` | Orphaned — never mounted |
| `src/components/forms/*.tsx` (7 files) | Duplicate of `src/patterns/form/` |

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
| `Cannot find module '@/components/tabs/...'` | Route still imports deleted tab | Update to import underlying component directly |
| `useState is not defined` | Server component imports client hook | Add `'use client'` to the page |
| 404 on route | Missing `page.tsx` | Create the file in correct location |
| Hydration mismatch | Server/client render different content | Use `dynamic(import, { ssr: false })` |
| `Module not found: @/examples/...` | Registry references missing path | Create barrel `index.ts` or fix path |
