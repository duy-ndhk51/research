# Architecture — UI-V2-Dev Route Structure

Target route-based architecture for `apps/ui-v2-dev`. Replaces the single-page tab shell with Next.js App Router conventions.

---

## Table of Contents

1. [Route Tree](#1-route-tree)
2. [Naming Conventions](#2-naming-conventions)
3. [Layout Hierarchy](#3-layout-hierarchy)
4. [Registry Pattern](#4-registry-pattern)
5. [File Placement Rules](#5-file-placement-rules)
6. [Migration Mapping](#6-migration-mapping)
7. [Dropped Content](#7-dropped-content)

---

## 1. Route Tree

```
apps/ui-v2-dev/
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── tsconfig.json
│
└── src/
    ├── app/
    │   ├── globals.css
    │   ├── layout.tsx                        # Root: fonts, providers
    │   ├── page.tsx                          # "/" = OverviewTab (4 layer cards landing)
    │   │
    │   ├── _components/
    │   │   └── OverviewContent.tsx            # Relocated from tabs/OverviewTab.tsx
    │   │
    │   ├── (showcase)/                       # Route group: sidebar + content shell
    │   │   ├── layout.tsx                    # Sidebar nav + content area
    │   │   │
    │   │   ├── primitives/                   # /primitives — ComponentsTab gallery
    │   │   │   ├── layout.tsx                # Category sub-tabs (inputs, display, feedback, etc.)
    │   │   │   ├── page.tsx                  # Masonry grid of all primitives (16 sections)
    │   │   │   ├── _components/
    │   │   │   │   └── PrimitivesContent.tsx  # Relocated from tabs/ComponentsTab.tsx
    │   │   │   └── [component]/              # /primitives/button, /primitives/row
    │   │   │       └── page.tsx              # Focused view of one primitive
    │   │   │
    │   │   ├── blocks/                       # /blocks
    │   │   │   ├── layout.tsx                # Sub-tabs: ui-v2 | sndq | composable
    │   │   │   ├── page.tsx                  # Overview / redirect to ui-v2
    │   │   │   ├── ui-v2/                    # BlocksTab (generic: KPI, Headers, EntityCards, etc.)
    │   │   │   │   ├── page.tsx
    │   │   │   │   └── _components/
    │   │   │   │       └── BlocksContent.tsx  # Relocated from tabs/BlocksTab.tsx
    │   │   │   ├── sndq/                     # SndqBlocksTab (domain blocks, 18 categories)
    │   │   │   │   ├── page.tsx              # Category grid
    │   │   │   │   ├── _components/
    │   │   │   │   │   └── SndqBlocksContent.tsx  # Relocated from tabs/SndqBlocksTab.tsx
    │   │   │   │   └── [domain]/             # /blocks/sndq/building
    │   │   │   │       └── page.tsx
    │   │   │   └── composable/               # ComposableTab (5 assembled patterns, inlined)
    │   │   │       └── page.tsx
    │   │   │
    │   │   ├── patterns/                     # /patterns
    │   │   │   ├── layout.tsx                # Sub-tabs: forms | tables | filters | metrics | page-shells
    │   │   │   ├── page.tsx                  # Overview / redirect
    │   │   │   ├── forms/                    # FormsTab (6 form patterns)
    │   │   │   │   ├── page.tsx
    │   │   │   │   └── _components/
    │   │   │   │       └── FormsContent.tsx   # Relocated from tabs/FormsTab.tsx
    │   │   │   ├── tables/                   # TableRowTab (6 table demos)
    │   │   │   │   ├── page.tsx
    │   │   │   │   └── _components/
    │   │   │   │       └── TableContent.tsx   # Relocated from tabs/TableRowTab.tsx
    │   │   │   ├── filters/                  # FilterTab (11 filter patterns)
    │   │   │   │   ├── page.tsx
    │   │   │   │   └── _components/
    │   │   │   │       └── FilterContent.tsx  # Relocated from tabs/FilterTab.tsx
    │   │   │   ├── metrics/                  # MetricStripTab (9 metric patterns)
    │   │   │   │   ├── page.tsx
    │   │   │   │   └── _components/
    │   │   │   │       └── MetricContent.tsx  # Relocated from tabs/MetricStripTab.tsx
    │   │   │   └── page-shells/              # FloatingSheetTab (4 sheet demos)
    │   │   │       ├── page.tsx
    │   │   │       └── _components/
    │   │   │           └── FloatingSheetContent.tsx  # Relocated from tabs/FloatingSheetTab.tsx
    │   │   │
    │   │   ├── integrations/                 # /integrations — external library showcases
    │   │   │   ├── layout.tsx                # Sub-tabs: coss | tremor | charts | data-table | forms | date-pickers
    │   │   │   ├── page.tsx                  # Overview / redirect
    │   │   │   ├── coss/                     # CossTab (492 particles, 6 sidebar groups)
    │   │   │   │   ├── page.tsx              # Full particle browser with sidebar categories
    │   │   │   │   ├── _components/
    │   │   │   │   │   └── CossBrowser.tsx   # Relocated from tabs/CossTab.tsx
    │   │   │   │   └── [category]/           # /integrations/coss/button
    │   │   │   │       └── page.tsx
    │   │   │   ├── tremor/                   # TremorBlocksTab (~303 blocks, 28 categories)
    │   │   │   │   ├── page.tsx              # Category grid
    │   │   │   │   ├── _components/
    │   │   │   │   │   └── TremorBrowser.tsx  # Relocated from tabs/TremorBlocksTab.tsx
    │   │   │   │   └── [category]/           # /integrations/tremor/kpi-cards
    │   │   │   │       └── page.tsx
    │   │   │   ├── charts/                   # Chart integration (Recharts)
    │   │   │   │   └── page.tsx
    │   │   │   ├── data-table/               # @tanstack/react-table
    │   │   │   │   └── page.tsx
    │   │   │   ├── forms/                    # react-hook-form + zod
    │   │   │   │   └── page.tsx
    │   │   │   └── date-pickers/             # react-day-picker
    │   │   │       └── page.tsx
    │   │   │
    │   │   └── foundations/                   # /foundations
    │   │       ├── layout.tsx                # Sub-tabs: identity | tokens
    │   │       ├── page.tsx                  # Redirect to /foundations/identity
    │   │       ├── identity/                 # IdentityTab (spec + design canvas)
    │   │       │   ├── page.tsx
    │   │       │   └── _components/
    │   │       │       ├── IdentityContent.tsx  # Relocated from tabs/IdentityTab.tsx
    │   │       │       └── identity/           # Relocated from tabs/identity/
    │   │       │           ├── identity-data.ts
    │   │       │           ├── MarkdownRenderer.tsx
    │   │       │           └── DesignCanvas.tsx
    │   │       └── tokens/                   # FoundationTab (swatches + scales)
    │   │           ├── page.tsx
    │   │           └── _components/
    │   │               └── FoundationContent.tsx  # Relocated from tabs/FoundationTab.tsx
    │   │
    │   └── (standalone)/                     # Route group: full-screen previews
    │       └── preview/
    │           └── [component]/
    │               └── page.tsx
    │
    ├── components/                           # Dev-app internal components
    │   ├── layout/
    │   │   ├── Sidebar.tsx
    │   │   ├── TopTabs.tsx
    │   │   ├── ComponentGrid.tsx
    │   │   └── index.ts
    │   ├── showcase/
    │   │   ├── ExampleCard.tsx
    │   │   ├── VariantSection.tsx
    │   │   ├── LazyExample.tsx
    │   │   ├── CellView.tsx                  # Relocated from tabs/RowTab.tsx (shared cross-group)
    │   │   └── index.ts
    │   ├── sections/                          # 16 primitive demo sections (kept in place)
    │   │   ├── ButtonSection.tsx
    │   │   ├── InputSection.tsx
    │   │   └── ...
    │   ├── composable/                        # 5 composable examples (kept in place)
    │   │   ├── FinancialExample.tsx
    │   │   └── ...
    │   ├── sndq-blocks/                       # 18 SNDQ domain block categories (kept in place)
    │   │   ├── building/
    │   │   └── ...
    │   ├── blocks/                            # 28 Tremor block categories (kept in place)
    │   │   ├── kpi-cards/
    │   │   └── ...
    │   ├── ComponentCard.tsx                  # Legacy card wrapper (still used by sections + relocated tabs)
    │   └── ui-v2/                             # Prototype UI components
    │       └── index.ts
    │
    ├── registry/                             # Metadata (NOT component source)
    │   ├── primitives.ts
    │   ├── blocks.ts
    │   ├── integrations.ts
    │   ├── categories.ts
    │   ├── particles.ts                      # Relocated from app/particles/registry-particles.ts
    │   └── particle-categories.ts            # Relocated from app/particles/registry-categories.ts
    │
    ├── examples/
    │   └── particles/                        # Relocated from app/particles/examples/ (492 files)
    │       ├── index.ts                      # Lazy-loads all p-*.tsx via React.lazy
    │       ├── p-accordion-1.tsx
    │       ├── p-button-1.tsx
    │       └── ...
    │
    ├── patterns/
    │   └── form/                             # Stays in place (FormsTab source)
    │       ├── FormShell.tsx
    │       ├── AddContactForm.tsx
    │       └── ...
    │
    └── lib/
        ├── utils.ts
        └── hooks/
            └── useToast.ts
```

---

## 2. Naming Conventions

Source of truth: `apps/docs/.cursor/rules/naming-conventions.mdc`

| Element | Convention | Example |
|---------|-----------|---------|
| Directories | kebab-case | `data-table/`, `page-shells/`, `floating-sheet/` |
| Component files | PascalCase | `Sidebar.tsx`, `ExampleCard.tsx`, `ButtonPrimary.tsx` |
| Hook files | camelCase, starts with `use` | `useToast.ts` |
| Barrel files | `index.ts` in every component folder | Re-exports named public API |
| Exports | Named only | `export function Sidebar()`, never `export default` |
| Route files | Next.js convention | `page.tsx`, `layout.tsx`, `loading.tsx` |
| Route directories | kebab-case | `primitives/`, `data-table/`, `page-shells/` |
| Dynamic segments | bracketed kebab-case | `[component]/`, `[category]/`, `[domain]/` |
| Route groups | parenthesized kebab-case | `(showcase)/`, `(standalone)/` |

---

## 3. Layout Hierarchy

```mermaid
graph TD
    RootLayout["src/app/layout.tsx<br/>(fonts, globals.css)"]
    OverviewPage["src/app/page.tsx<br/>(OverviewTab landing)"]

    RootLayout --> OverviewPage
    RootLayout --> ShowcaseLayout
    RootLayout --> StandaloneLayout

    subgraph showcase ["(showcase) route group"]
        ShowcaseLayout["(showcase)/layout.tsx<br/>(Sidebar + content area)"]
        ShowcaseLayout --> PrimitivesLayout
        ShowcaseLayout --> BlocksLayout
        ShowcaseLayout --> PatternsLayout
        ShowcaseLayout --> IntegrationsLayout
        ShowcaseLayout --> FoundationsLayout

        PrimitivesLayout["primitives/layout.tsx<br/>(category sub-tabs)"]
        PrimitivesLayout --> PrimitivesPage["primitives/page.tsx<br/>(masonry grid)"]
        PrimitivesLayout --> ComponentPage["[component]/page.tsx"]

        BlocksLayout["blocks/layout.tsx<br/>(source sub-tabs)"]
        BlocksLayout --> BlocksUiV2["ui-v2/page.tsx"]
        BlocksLayout --> BlocksSndq["sndq/page.tsx"]
        BlocksLayout --> BlocksSndqDomain["sndq/[domain]/page.tsx"]
        BlocksLayout --> BlocksComposable["composable/page.tsx"]

        PatternsLayout["patterns/layout.tsx<br/>(type sub-tabs)"]
        PatternsLayout --> PatternsForms["forms/page.tsx"]
        PatternsLayout --> PatternsTables["tables/page.tsx"]
        PatternsLayout --> PatternsFilters["filters/page.tsx"]
        PatternsLayout --> PatternsMetrics["metrics/page.tsx"]
        PatternsLayout --> PatternsShells["page-shells/page.tsx"]

        IntegrationsLayout["integrations/layout.tsx<br/>(library sub-tabs)"]
        IntegrationsLayout --> IntCoss["coss/page.tsx"]
        IntegrationsLayout --> IntCossCategory["coss/[category]/page.tsx"]
        IntegrationsLayout --> IntTremor["tremor/page.tsx"]
        IntegrationsLayout --> IntTremorCategory["tremor/[category]/page.tsx"]
        IntegrationsLayout --> IntCharts["charts/page.tsx"]
        IntegrationsLayout --> IntDataTable["data-table/page.tsx"]
        IntegrationsLayout --> IntForms["forms/page.tsx"]
        IntegrationsLayout --> IntDatePickers["date-pickers/page.tsx"]

        FoundationsLayout["foundations/layout.tsx<br/>(sub-tabs)"]
        FoundationsLayout --> FoundIdentity["identity/page.tsx"]
        FoundationsLayout --> FoundTokens["tokens/page.tsx"]
    end

    subgraph standalone ["(standalone) route group"]
        StandaloneLayout["(standalone)<br/>(no sidebar)"]
        StandaloneLayout --> PreviewPage["preview/[component]/page.tsx"]
    end
```

### Layout responsibilities

| Layout | Renders | Persists across |
|--------|---------|-----------------|
| `src/app/layout.tsx` | Fonts, `globals.css`, base HTML | All routes |
| `src/app/page.tsx` | OverviewTab (landing) | Only `/` |
| `(showcase)/layout.tsx` | Sidebar navigation + content wrapper | All showcase routes |
| `primitives/layout.tsx` | Category sub-tabs (Inputs, Display, Feedback, Navigation, etc.) | `/primitives` and `/primitives/[component]` |
| `blocks/layout.tsx` | Source sub-tabs (UI-V2, SNDQ, Composable) | All `/blocks/*` |
| `patterns/layout.tsx` | Type sub-tabs (Forms, Tables, Filters, Metrics, Page Shells) | All `/patterns/*` |
| `integrations/layout.tsx` | Library sub-tabs (Coss, Tremor, Charts, Data Table, Forms, Date Pickers) | All `/integrations/*` |
| `foundations/layout.tsx` | Sub-tabs (Identity, Tokens) | All `/foundations/*` |

---

## 4. Registry Pattern

The registry bridges routes and examples. It provides metadata for rendering grids and lazy-loading.

### Registry type

```typescript
// src/registry/integrations.ts
export type IntegrationEntry = {
  name: string;
  slug: string;
  library: 'coss' | 'tremor' | 'charts' | 'data-table' | 'forms' | 'date-pickers';
  category?: string;
  tags: string[];
  importFn: () => Promise<Record<string, React.ComponentType>>;
};
```

### How routes use it

```typescript
// src/app/(showcase)/integrations/coss/[category]/page.tsx
import { notFound } from 'next/navigation';
import { cossRegistry } from '@/registry/integrations';
import { LazyExample } from '@/components/showcase';

export function generateStaticParams() {
  return cossRegistry.map((entry) => ({ category: entry.slug }));
}

export default function CossCategoryPage({ params }: { params: { category: string } }) {
  const entries = cossRegistry.filter((e) => e.category === params.category);
  if (entries.length === 0) notFound();

  return (
    <div className="grid gap-6">
      {entries.map((entry) => (
        <LazyExample key={entry.slug} importFn={entry.importFn} title={entry.name} />
      ))}
    </div>
  );
}
```

---

## 5. File Placement Rules

| File type | Location | Import pattern |
|-----------|----------|----------------|
| Route pages | `src/app/(showcase)/[category]/page.tsx` | N/A (Next.js) |
| Route layouts | `src/app/(showcase)/[category]/layout.tsx` | N/A (Next.js) |
| Route-colocated content | `src/app/(showcase)/[category]/_components/` | Relative `./_components/X` |
| Layout UI (Sidebar, TopTabs) | `src/components/layout/` | `@/components/layout` |
| Showcase utilities (ExampleCard, LazyExample, CellView) | `src/components/showcase/` | `@/components/showcase` |
| Registry metadata | `src/registry/` | `@/registry/primitives` |
| Particle registry + categories | `src/registry/particles.ts`, `particle-categories.ts` | `@/registry/particles` |
| Particle examples (492 files) | `src/examples/particles/` | `@/examples/particles` |
| Primitive sections (16 sections) | `src/components/sections/` | `@/components/sections/*` |
| Tremor block source | `src/components/blocks/` | `@/components/blocks/*` (dynamic) |
| SNDQ block source | `src/components/sndq-blocks/` | `@/components/sndq-blocks/*` (dynamic) |
| Composable examples | `src/components/composable/` | `@/components/composable/*` |
| Form patterns | `src/patterns/form/` | `@/patterns/form` |
| Identity helpers | `src/app/(showcase)/foundations/identity/_components/identity/` | Relative `./identity/*` |
| Hooks | `src/lib/hooks/` | `@/lib/hooks/useX` |
| Utilities | `src/lib/` | `@/lib/utils` |

---

## 6. Migration Mapping

### Current file → Final location (after Commit 12)

| Original location | Final location | Status |
|-------------------|----------------|--------|
| `src/modules/showcase/ShowcasePage.tsx` | **DELETED** | Replaced by route-based navigation |
| `src/components/tabs/OverviewTab.tsx` | `src/app/_components/OverviewContent.tsx` | Relocated |
| `src/components/tabs/IdentityTab.tsx` | `(showcase)/foundations/identity/_components/IdentityContent.tsx` | Relocated |
| `src/components/tabs/identity/*.tsx` | `(showcase)/foundations/identity/_components/identity/` | Relocated |
| `src/components/tabs/FoundationTab.tsx` | `(showcase)/foundations/tokens/_components/FoundationContent.tsx` | Relocated |
| `src/components/tabs/ComponentsTab.tsx` | `(showcase)/primitives/_components/PrimitivesContent.tsx` | Relocated |
| `src/components/tabs/CossTab.tsx` | `(showcase)/integrations/coss/_components/CossBrowser.tsx` | Relocated |
| `src/components/tabs/TremorBlocksTab.tsx` | `(showcase)/integrations/tremor/_components/TremorBrowser.tsx` | Relocated |
| `src/components/tabs/BlocksTab.tsx` | `(showcase)/blocks/ui-v2/_components/BlocksContent.tsx` | Relocated |
| `src/components/tabs/SndqBlocksTab.tsx` | `(showcase)/blocks/sndq/_components/SndqBlocksContent.tsx` | Relocated |
| `src/components/tabs/ComposableTab.tsx` | Inlined into `(showcase)/blocks/composable/page.tsx` | Inlined |
| `src/components/tabs/FormsTab.tsx` | `(showcase)/patterns/forms/_components/FormsContent.tsx` | Relocated |
| `src/components/tabs/TableRowTab.tsx` | `(showcase)/patterns/tables/_components/TableContent.tsx` | Relocated |
| `src/components/tabs/FilterTab.tsx` | `(showcase)/patterns/filters/_components/FilterContent.tsx` | Relocated |
| `src/components/tabs/MetricStripTab.tsx` | `(showcase)/patterns/metrics/_components/MetricContent.tsx` | Relocated |
| `src/components/tabs/FloatingSheetTab.tsx` | `(showcase)/patterns/page-shells/_components/FloatingSheetContent.tsx` | Relocated |
| `src/components/tabs/RowTab.tsx` | `src/components/showcase/CellView.tsx` | Relocated (shared) |
| `src/components/tabs/TremorTab.tsx` | **DELETED** | Orphaned |
| `src/components/sections/*.tsx` | Stay in place | No change |
| `src/components/blocks/` | Stay in place | No change |
| `src/components/sndq-blocks/` | Stay in place | No change |
| `src/components/composable/` | Stay in place | No change |
| `src/app/particles/examples/` | `src/examples/particles/` | Relocated |
| `src/app/particles/registry-particles.ts` | `src/registry/particles.ts` | Relocated |
| `src/app/particles/registry-categories.ts` | `src/registry/particle-categories.ts` | Relocated |
| `src/app/particles/page.tsx` + UI files | **DELETED** | Merged into `/integrations/coss` |
| `src/components/sections/FoundationsSection.tsx` | **DELETED** | Orphaned |
| `src/components/forms/` | **DELETED** | Duplicate of `src/patterns/form/` |
| `src/patterns/form/*.tsx` | Stay in place | No change |
| `src/components/ui-v2/*.tsx` | Stay in place | Prototype source |
| `src/lib/*.ts` | Stay in place | No change |
| `src/components/ComponentCard.tsx` | Stay in place | Deferred -- still used by sections + relocated tabs |

### Current URL → Target URL

| Current | Target |
|---------|--------|
| `/` (with `?tab=overview`) | `/` |
| `/?tab=identity` | `/foundations/identity` |
| `/?tab=foundation` | `/foundations/tokens` |
| `/?tab=components` | `/primitives` |
| `/?tab=cell` | `/primitives/row` |
| `/?tab=forms` | `/patterns/forms` |
| `/?tab=table` | `/patterns/tables` |
| `/?tab=filter` | `/patterns/filters` |
| `/?tab=metric` | `/patterns/metrics` |
| `/?tab=sheet` | `/patterns/page-shells` |
| `/?tab=blocks` | `/blocks/ui-v2` |
| `/?tab=sndq-blocks` | `/blocks/sndq` |
| `/?tab=composable` | `/blocks/composable` |
| `/?tab=coss` | `/integrations/coss` |
| `/?tab=tremor-blocks` | `/integrations/tremor` |
| `/particles` | `/integrations/coss` |
| `/particles?tags=button` | `/integrations/coss/button` |

---

## 7. Dropped Content (deleted in Commit 12)

These files were identified as dead code and deleted:

| File | Reason |
|------|--------|
| `src/components/tabs/TremorTab.tsx` | Orphaned — never imported in ShowcasePage |
| `src/components/sections/FoundationsSection.tsx` | Orphaned — never mounted in ComponentsTab |
| `src/components/forms/*.tsx` (7 files) | Exact duplicates of `src/patterns/form/*.tsx` |
| `src/modules/showcase/ShowcasePage.tsx` | Replaced by route-based navigation |
| `src/app/particles/` (route + 6 UI files) | Route merged into `/integrations/coss`; data files relocated |
