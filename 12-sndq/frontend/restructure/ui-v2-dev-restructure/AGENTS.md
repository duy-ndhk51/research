# AGENTS.md — UI-V2-Dev Routing Restructure

Agent guidance for restructuring `apps/ui-v2-dev` from a single-page tab architecture to Next.js App Router route-based code splitting.

**Scope**: Routing and file organization only. Zero component logic changes.
**Status**: Complete — all routes migrated, old code deleted, `CategoryBrowserLayout` standardized across all browsable pages.

---

## What Was Done

Converted `apps/ui-v2-dev` from:
- A single `ShowcasePage` client component (15 tabs via `?tab=` + 1 overview)
- ~1,100 source files loaded in one bundle
- External libraries (Coss UI, Tremor) embedded as tabs

To:
- Route-based architecture with automatic code splitting per category
- `CategoryBrowserLayout` as the standard sidebar navigation for all browsable pages
- External libraries under `/integrations/` with their own browsing UIs
- Deep-linkable URLs (`/primitives/button`, `/integrations/coss/button`, `/blocks/sndq/building`)

### Post-migration refinements

- Removed redundant `TopTabs` component — sidebar already provides navigation
- Migrated all custom inline sidebars and top `SegmentedControl` tabs to `CategoryBrowserLayout`
- Routes affected: `primitives`, `blocks/sndq`, `blocks/forms`, `blocks/sheets`, `blocks/composable`, `integrations/coss`, `integrations/tremor`

---

## Critical Constraints

### DO

- Import components from route-colocated `components/` directories
- Add `'use client'` when a page imports components using React hooks
- Treat Coss UI and Tremor as external library integrations (under `/integrations/`)
- Use `@/` alias imports for cross-directory references
- Use `CategoryBrowserLayout` for any page with a secondary sidebar

### DO NOT

- Modify any component's internal logic, props, or styling
- Change how components render (only where they're imported from)
- Add new npm dependencies
- Modify `globals.css` or design tokens
- Change anything in `packages/ui-v2/` or `packages/config/`
- Import from `@/components/tabs/` (deleted)
- Hand-build inline `<nav>` sidebars or top tab bars — use `CategoryBrowserLayout`

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
| Route groups | `(name)` | `(showcase)/` |

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
│   ├── primitives/               # /primitives/[component]
│   │   ├── data/primitivesCategories.ts
│   │   ├── components/PrimitivesCategoryContent.tsx
│   │   ├── layout.tsx            # CategoryBrowserLayout
│   │   ├── page.tsx              # Redirects to /primitives/button
│   │   └── [component]/page.tsx  # Single primitive
│   │
│   ├── blocks/                   # /blocks/*
│   │   ├── layout.tsx            # Passthrough
│   │   ├── ui-v2/page.tsx + components/BlocksContent.tsx
│   │   ├── sndq/data/ + components/ + layout.tsx + [category]/
│   │   ├── forms/data/ + components/ + layout.tsx + [form]/
│   │   ├── sheets/data/ + components/sections/ + layout.tsx + [section]/
│   │   ├── composable/data/ + components/ + layout.tsx + [view]/
│   │   ├── tables/page.tsx + components/TableContent.tsx
│   │   ├── filters/page.tsx + components/FilterContent.tsx
│   │   └── metrics/page.tsx + components/MetricContent.tsx
│   │
│   ├── integrations/             # /integrations — external libraries
│   │   ├── layout.tsx            # Passthrough
│   │   ├── coss/data/ + components/ + layout.tsx + [category]/
│   │   ├── tremor/data/ + components/ + layout.tsx + [category]/
│   │   ├── charts/page.tsx       # Placeholder
│   │   ├── data-table/page.tsx   # Placeholder
│   │   ├── forms/page.tsx        # Placeholder
│   │   └── date-pickers/page.tsx # Placeholder
│   │
│   └── foundations/              # /foundations
│       ├── layout.tsx            # Passthrough
│       ├── identity/page.tsx + components/IdentityContent.tsx
│       └── tokens/page.tsx + components/FoundationContent.tsx
```

---

## Complete URL Mapping

| Old tab/route | Route |
|-----------|-------|
| `overview` | `/` |
| `components` | `/primitives/button` (redirected) |
| `cell` | `/primitives/row` |
| `blocks` | `/blocks/ui-v2` |
| `sndq-blocks` | `/blocks/sndq/building` (redirected) |
| `composable` | `/blocks/composable/financial` (redirected) |
| `forms` | `/blocks/forms/contact` (redirected) |
| `table` | `/blocks/tables` |
| `filter` | `/blocks/filters` |
| `metric` | `/blocks/metrics` |
| `sheet` | `/blocks/sheets/breakdown` (redirected) |
| `coss` | `/integrations/coss` |
| `tremor-blocks` | `/integrations/tremor` |
| `identity` | `/foundations/identity` |
| `foundation` | `/foundations/tokens` |

---

## CategoryBrowserLayout Pattern

All browsable routes with a secondary sidebar use `CategoryBrowserLayout` from `@/components/showcase/category-browser/`. Each follows this structure:

```
route/
├── data/{route}Categories.ts       # CategoryGroup[], CategoryItem[], section loaders
├── components/{Route}Content.tsx    # Lazy-loads component by categoryId
├── layout.tsx                       # CategoryBrowserLayout wrapper
├── page.tsx                         # Redirects to default category
└── [param]/page.tsx                 # Validates param, renders content component
```

---

## Dropped Content

These files were identified as dead code and have been deleted:

| File | Reason |
|------|--------|
| `src/components/tabs/` (entire directory) | Relocated to route-colocated `components/` dirs |
| `src/modules/showcase/ShowcasePage.tsx` | Replaced by route-based navigation |
| `src/components/layout/TopTabs.tsx` | Redundant with sidebar navigation |
| `src/components/tabs/TremorTab.tsx` | Orphaned — never imported |
| `src/components/sections/FoundationsSection.tsx` | Orphaned — never mounted |
| `src/components/forms/*.tsx` (7 files) | Duplicate of `src/patterns/form/` |
| `src/app/particles/` (route + UI files) | Merged into `/integrations/coss` |
| `*Content.tsx` monolith files | Replaced by `data/` + `CategoryBrowserLayout` pattern |

---

## Verification Commands

```bash
pnpm --filter @sndq/ui-v2-dev run type-check
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev dev
```

---

## Error Recovery

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Cannot find module '@/components/tabs/...'` | Stale import from deleted tabs/ dir | Update to import from `components/` or `@/components/showcase/` |
| `useState is not defined` | Server component imports client hook | Add `'use client'` to the page |
| 404 on route | Missing `page.tsx` | Create the file in correct location |
| Hydration mismatch | Server/client render different content | Use `dynamic(import, { ssr: false })` |
| `Module not found: @/examples/...` | Registry references missing path | Create barrel `index.ts` or fix path |
