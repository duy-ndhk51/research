# Fumadocs — Library Evaluation

## TL;DR

Fumadocs is a Next.js App Router-native documentation framework. It provides a typed MDX content layer (`fumadocs-mdx` + `fumadocs-core`) and a default UI theme (`fumadocs-ui`) with sidebar/nav layouts, a swappable search backend (built-in Orama by default, with adapters for Algolia and Inkeep AI), theming via CSS, and i18n. It is the leanest "real" docs framework when you already use Next.js App Router and want to own the host app.

## Status

| Field | Value |
|-------|-------|
| **Decision** | Reference (general); SNDQ adoption tracked in [fumadocs-decision.md](../../../12-sndq/frontend/restructure/monorepo-ui-design-system/fumadocs-decision.md) |
| **Stack** | Next.js 13+ (App Router), React 18/19, MDX |
| **Source** | [fumadocs.dev](https://www.fumadocs.dev), [GitHub](https://github.com/fuma-nama/fumadocs) |
| **Packages** | `fumadocs-ui`, `fumadocs-core`, `fumadocs-mdx` |
| **Last reviewed** | 2026-05-04 |

## What is Fumadocs?

Fumadocs is split into three layers, each replaceable:

1. **`fumadocs-mdx`** — Build-time MDX scanner. `defineDocs({ dir })` declares a content collection; the framework generates a `.source` directory the app imports from.
2. **`fumadocs-core`** — Headless primitives: `loader({ baseUrl, source })` returns the page tree, `getPage()`, `generateParams()`, plus search server adapters (`createFromSource`).
3. **`fumadocs-ui`** — Default theme. Layout components (`DocsLayout`, `HomeLayout`, `NotebookLayout`, `Flux`), page wrappers (`DocsPage`, `DocsTitle`, `DocsBody`), `RootProvider` (theme + search dialog), and a `style.css` bundle.

You can use `fumadocs-core` without `fumadocs-ui` (custom theme), and you can use any search backend behind the same `/api/search` route.

## When to use

- You already build with **Next.js App Router** and want docs **co-located** with the app or in the same monorepo.
- You want **MDX-authored** docs with sidebar IA, breadcrumbs, TOC, search — without owning a separate Docusaurus stack.
- You want **swappable search** (free Orama in dev, Algolia/Inkeep in production) without rewriting content.
- You want a **single design language** (the docs site shares Tailwind / tokens with your product app).

## When not to use

- You are **not** on Next.js → use Docusaurus, Nextra (also Next, simpler), or Mintlify.
- You need **plug-and-play hosted docs** with editorial UI and analytics dashboards → Mintlify.
- Your "docs" are **API references generated from OpenAPI/source** with no prose → use a generator (e.g. Redoc, Scalar) or Storybook for component docs.
- You need **non-React** themes / heavy customization outside MDX.

## Companion notes

| Document | Topic |
|----------|-------|
| [layouts.md](./layouts.md) | Layout shells: `DocsLayout`, `HomeLayout`, `NotebookLayout`, `Flux`. Use cases, benefits, tradeoffs, and how `DocsPage` content wrappers fit in |
| [search.md](./search.md) | Search backends: built-in Orama, Algolia, Inkeep AI. Indexing model, cost/privacy, swap procedure |
| [content.md](./content.md) | `source.config.ts`, `loader()` and `baseUrl`, `meta.json`, frontmatter, the `.source` directory, `generateParams()`, routing patterns |
| [theming-and-i18n.md](./theming-and-i18n.md) | `RootProvider`, `style.css`, Tailwind v4 interop, i18n setup, `slots` |
| [alternatives.md](./alternatives.md) | Fumadocs vs Nextra vs Docusaurus vs Mintlify vs Storybook docs |

## SNDQ application

Fumadocs is the docs framework for the SNDQ design-system docs site (`apps/docs/`). Decision rationale and choices (layout = `DocsLayout`, search = Orama, routing = `baseUrl: '/'`) are captured in [fumadocs-decision.md](../../../12-sndq/frontend/restructure/monorepo-ui-design-system/fumadocs-decision.md). The setup is sequenced as Phase 3, Batch 0 in the migration plan ([phase-3-batch-0-execution.md](../../../12-sndq/frontend/restructure/monorepo-ui-design-system/phase-3-batch-0-execution.md)).

## Sources

- [Fumadocs — Layouts](https://www.fumadocs.dev/docs/ui/layouts)
- [Fumadocs — Notebook Layout](https://www.fumadocs.dev/docs/ui/layouts/notebook)
- [Fumadocs — Home Layout](https://www.fumadocs.dev/docs/ui/layouts/home-layout)
- [Fumadocs UI — Page primitives (`DocsPage`, `DocsTitle`, `DocsBody`)](https://www.fumadocs.dev/docs/ui/page-conventions)
- [Fumadocs MDX — `defineDocs`, source config](https://www.fumadocs.dev/docs/mdx)
- [Fumadocs Core — Search server adapters](https://www.fumadocs.dev/docs/headless/search)
- [GitHub — fuma-nama/fumadocs](https://github.com/fuma-nama/fumadocs)
