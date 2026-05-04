# Fumadocs — Layouts

Layout shells available in `fumadocs-ui`, plus the page-level wrappers used inside any of them.

**Sources**: [Layouts overview](https://www.fumadocs.dev/docs/ui/layouts), [Notebook Layout](https://www.fumadocs.dev/docs/ui/layouts/notebook), [Home Layout](https://www.fumadocs.dev/docs/ui/layouts/home-layout)

---

## Table of Contents

1. [Layout vs Page wrappers](#1-layout-vs-page-wrappers)
2. [Comparison matrix](#2-comparison-matrix)
3. [`DocsLayout`](#3-docslayout)
4. [`HomeLayout`](#4-homelayout)
5. [`NotebookLayout`](#5-notebooklayout)
6. [`Flux` layout](#6-flux-layout)
7. [Mixing layouts in one site](#7-mixing-layouts-in-one-site)
8. [Recommendation matrix by site type](#8-recommendation-matrix-by-site-type)

---

## 1. Layout vs Page wrappers

Two distinct concepts that often get conflated:

| Concept | What it is | Imported from | Examples |
|--------|-------------|---------------|----------|
| **Layout shell** | The outer chrome wrapping every page in a route segment: nav, sidebar, theme toggle, search dialog | `fumadocs-ui/layouts/*` | `DocsLayout`, `HomeLayout`, `NotebookLayout`, `Flux` |
| **Page wrappers** | The inner structure of a single article page: title, TOC, MDX body container | `fumadocs-ui/page` | `DocsPage`, `DocsTitle`, `DocsBody` |

Page wrappers are layout-agnostic — you can render `DocsPage` inside `DocsLayout` *or* `HomeLayout` (e.g. a doc-style page hosted on a marketing-shell route). The wrappers control article structure (TOC, breadcrumb, footer); the layout controls site chrome.

```tsx
// Inside any layout shell:
import { DocsBody, DocsPage, DocsTitle } from 'fumadocs-ui/page';
import { source } from '@/lib/source';

export default async function Page({ params }: { params: Promise<{ slug?: string[] }> }) {
  const slug = (await params).slug ?? [];
  const page = source.getPage(slug);
  if (!page) notFound();
  const MDX = page.data.body;
  return (
    <DocsPage toc={page.data.toc}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsBody><MDX /></DocsBody>
    </DocsPage>
  );
}
```

---

## 2. Comparison matrix

| Layout | Sidebar | Top nav | TOC support | Best for | Avoid for |
|--------|---------|---------|-------------|----------|-----------|
| `DocsLayout` | Yes (page tree) | Yes | Yes (via `DocsPage`) | Reference docs, design systems, API guides, deep IA | Marketing landings |
| `HomeLayout` | No | Yes (+ search) | N/A | Landing pages, hub indexes, changelog covers | Hundreds of doc pages as the only shell |
| `NotebookLayout` | Optional | Yes | Yes | Dense technical content, "workspace" feel | Deep nested IA where sidebar persistence matters |
| `Flux` | Floating panel | Mobile-first | Yes | Mobile-leaning sites, distinctive UX | Conventional docs UX expectations |

All shells share `BaseLayoutProps` (nav, links, theme switch, search toggle), so the **chrome cost** of switching one route to a different shell is small.

---

## 3. `DocsLayout`

The classic sidebar-and-nav docs shell.

**Imports**: `import { DocsLayout } from 'fumadocs-ui/layouts/docs'`

**Use cases**

- Component catalogs (design systems)
- API references and SDK guides
- Long-form technical docs with multi-level hierarchy

**Benefits**

- Persistent sidebar with the full page tree → strong **wayfinding** for many pages
- Familiar interaction model (sidebar + breadcrumb + TOC) → low cognitive load for readers
- First-class i18n, theme toggle, and search dialog wiring
- Configurable via `BaseLayoutProps` (nav, links, sidebar tabs, prefetching, custom components)

**Tradeoffs**

- Heavier visual chrome on small viewports — needs the built-in mobile drawer to feel right
- Less suited as the **only** shell for a handful of marketing-style pages
- "Sidebar everywhere" can feel cluttered for very small content trees (under ~5 pages)

```tsx
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { source } from '@/lib/source';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout tree={source.pageTree} nav={{ title: 'My Design System' }}>
      {children}
    </DocsLayout>
  );
}
```

---

## 4. `HomeLayout`

A minimal shell: navbar + search dialog, **no docs sidebar**.

**Imports**: `import { HomeLayout } from 'fumadocs-ui/layouts/home'`

**Use cases**

- Marketing landing at `/`
- Changelog or "What's new" hub
- Standalone pages outside the doc tree (legal, pricing) sharing the docs nav

**Benefits**

- Clean canvas — your content drives the layout, not the chrome
- Same nav, theming, search wiring as `DocsLayout` (consistent header across docs and marketing)
- Cheap to add a single `HomeLayout` route alongside an existing `DocsLayout` site

**Tradeoffs**

- No built-in sidebar / page tree → not a fit if the page is part of the doc IA
- You hand-roll the page body (sections, hero, links) — that flexibility is also the cost
- Easy to drift visually from the docs unless you reuse the same nav/theme tokens

```tsx
import { HomeLayout } from 'fumadocs-ui/layouts/home';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <HomeLayout nav={{ title: 'My Design System' }}>
      {children}
    </HomeLayout>
  );
}
```

---

## 5. `NotebookLayout`

A compact variant of `DocsLayout` — top navbar with an **optional** sidebar, evoking Notion / Jupyter notebooks.

**Imports**: `import { NotebookLayout } from 'fumadocs-ui/layouts/notebook'`

**Use cases**

- Internal handbooks, runbooks, "developer notebook" sites
- Doc sites where horizontal space matters (long code samples, data tables)
- Sites that want a more workspace-like feel than classic sidebar docs

**Benefits**

- Modern, tighter visual rhythm — content gets more horizontal real estate
- Same content model as `DocsLayout` (page tree, frontmatter, MDX) → swap is easy
- `tabMode` and `nav.mode` options give predictable nav behavior across breakpoints

**Tradeoffs**

- More **opinionated** chrome — fewer customization escape hatches than `DocsLayout`
- Discoverability can suffer for **deep** trees (sidebar may be collapsed by default)
- Less familiar to readers used to "Stripe-style" docs

---

## 6. `Flux` layout

A modern, mobile-first shell with a **floating navigation panel** at the bottom of the viewport.

**Use cases**

- Sites whose primary audience is on **mobile**
- Brands that want a distinctive UX departure from classic docs sites

**Benefits**

- Bottom-anchored nav matches mobile thumb reach
- Strong visual differentiation from Stripe/Vercel-style docs
- Same content model (page tree + MDX) — no authoring rewrite

**Tradeoffs**

- Fewest established UX precedents — readers must learn the pattern
- Less proven in the community than `DocsLayout`
- Hardest to retrofit into a site whose users already expect the classic sidebar layout

---

## 7. Mixing layouts in one site

Each Next App Router segment chooses its own layout file. You can run **`HomeLayout` at `/`** and **`DocsLayout` everywhere else** — or any combination.

```
apps/docs/src/app/
├── (home)/                    ← HomeLayout shell
│   ├── layout.tsx             ← <HomeLayout>{children}</HomeLayout>
│   └── page.tsx               ← marketing landing
└── (docs)/                    ← DocsLayout shell
    └── [[...slug]]/
        ├── layout.tsx         ← <DocsLayout tree=...>{children}</DocsLayout>
        └── page.tsx           ← MDX renderer
```

Both segments share the same root `app/layout.tsx` (with `RootProvider`), so theme + search dialog are consistent. The cost of mixing is **two layout files** plus deciding URL ownership.

> **Pitfall**: if `app/page.tsx` and `app/[[...slug]]/page.tsx` both exist, Next.js prefers `page.tsx` for `/`. Either delete the placeholder `page.tsx` (single-shell sites) or move the catch-all into a separate route group (mixed sites).

---

## 8. Recommendation matrix by site type

| Site type | Recommended primary shell | Mix? | Notes |
|-----------|---------------------------|------|-------|
| Component catalog / design system | `DocsLayout` | Optional `HomeLayout` for `/` | Sidebar IA is the whole point; landing-only `HomeLayout` is a nicety |
| API reference (REST/SDK) | `DocsLayout` | Rare | TOC + sidebar are essential for navigating endpoints |
| Internal engineering handbook | `NotebookLayout` or `DocsLayout` | Rare | Notebook fits if pages are dense and few; classic docs if hierarchical |
| Marketing + docs hybrid | `HomeLayout` at `/` + `DocsLayout` under `/docs` | **Yes** | Clean separation of audiences; one root provider |
| Mobile-first content site | `Flux` | Optional | Try `Flux` only if your audience truly skews mobile and you can absorb the UX learning cost |
| Tiny site (≤ 5 pages) | `HomeLayout` | No | A sidebar with 5 entries feels heavy; render TOC inside the body |
