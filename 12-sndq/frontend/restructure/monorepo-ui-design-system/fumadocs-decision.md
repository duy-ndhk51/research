# Fumadocs Decision Record — SNDQ `apps/docs/`

The choices we made for the SNDQ design-system docs site, with rationale and links to the implementation plan and background research.

**Created**: 2026-05-04
**Status**: Decided — implemented as Phase 3, Batch 0
**Migration plan**: [migration-plan.md](./migration-plan.md) (Section 6, "Batch 0: Docs Infrastructure (Fumadocs)")
**Execution doc**: [phase-3-batch-0-execution.md](./phase-3-batch-0-execution.md)
**Background research**: [04-frontend/nextjs/fumadocs/README.md](../../../../04-frontend/nextjs/fumadocs/README.md)

---

## Context

`apps/docs/` is the standardized docs site for `@sndq/ui-v2` (and the foundations from `@sndq/config/tailwind/*`). It is **internal-only**, audience is the SNDQ engineering team, content is bounded (component catalog + foundations + a few blocks). It already exists as a Next 15 App Router placeholder with `@sndq/ui-v2` wired as `workspace:*`.

We needed to choose:

1. The **docs framework** itself (vs Nextra, Docusaurus, Mintlify, Storybook docs)
2. The **layout** (DocsLayout vs HomeLayout vs NotebookLayout vs Flux)
3. The **search backend** (Orama vs Algolia vs Inkeep AI)
4. The **routing convention** (`baseUrl: '/'` vs `baseUrl: '/docs'`)

---

## Choice 1 — Framework: Fumadocs

**Decision**: Use Fumadocs.

**Why**:

- `apps/docs/` is **already** a Next 15 App Router app sharing the monorepo with `@sndq/ui-v2`. Fumadocs is App Router-native — no separate stack to host.
- We want **MDX authoring** for components and foundations (snippets, props tables, code blocks) without owning a docs framework ourselves.
- Search backend is **swappable** behind one route file — we can ship MVP with no infra and upgrade later if needed.
- Theming is **CSS variables**, so we can keep our `@sndq/config/tailwind/*` token system unchanged.

**Why not the alternatives** (full matrix in [alternatives.md](../../../../04-frontend/nextjs/fumadocs/alternatives.md)):

- **Nextra**: simpler to start but less flexible on search and customization; Fumadocs' `slots` + headless `fumadocs-core` give us a real escape hatch.
- **Docusaurus**: a separate stack — duplicates the build, breaks the "one Next monorepo" model.
- **Mintlify**: hosted SaaS — wrong for an internal-only site, plus we want full code control over the chrome.
- **Storybook docs**: documents components but not foundations / blocks / prose well; we still want it as a complementary tool, not the docs site.

---

## Choice 2 — Layout: `DocsLayout`

**Decision**: Use `DocsLayout` from `fumadocs-ui/layouts/docs` for the whole site, with `DocsPage` / `DocsTitle` / `DocsBody` page wrappers.

**Why**:

- The site is a **component + foundations catalog with deep IA** (`Foundations`, `Primitives`, `Blocks`, each with multiple pages). Persistent sidebar wayfinding is the entire point.
- Familiar interaction model — engineers already know "Stripe-style" docs sites.
- Built-in TOC, breadcrumb, theme switch, search dialog — no custom chrome to write.

**Why not the alternatives** (full comparison in [layouts.md](../../../../04-frontend/nextjs/fumadocs/layouts.md)):

- **`HomeLayout`** — no sidebar; fits a marketing landing, not a multi-page docs site. We may add a single `HomeLayout` route later if we want a bespoke landing, but it is not needed for v1.
- **`NotebookLayout`** — more opinionated, less suited for deep nested IA. Our content tree is hierarchical (foundations / primitives / blocks → many pages), which fits the classic sidebar shell better.
- **`Flux`** — distinctive UX, mobile-first; our audience reads on desktop and the team expects a conventional docs interaction.

**Caveat**: page content is wrapped with `DocsPage` / `DocsTitle` / `DocsBody` (from `fumadocs-ui/page`) — those are content wrappers, not a separate layout. Layout choice does not constrain them.

---

## Choice 3 — Search: built-in Orama

**Decision**: Use `createFromSource(source)` from `fumadocs-core/search/server` — Fumadocs' built-in Orama adapter.

**Why**:

- Internal-only docs with a **bounded** content size (low hundreds of pages once Phase 3 finishes) — well within Orama's comfort zone.
- **Zero infrastructure**, zero cost, no external service handling our queries.
- Indexed at build time — works on PR previews, on `pnpm dev`, on local checkouts.
- The whole route is **one file** (`app/api/search/route.ts`); swap to Algolia or Inkeep is mechanical if we ever outgrow Orama.

**Why not the alternatives** (full comparison in [search.md](../../../../04-frontend/nextjs/fumadocs/search.md)):

- **Algolia** — best-in-class typo tolerance and analytics, but adds a paid SaaS, an API key in CI, a sync step, and queries leaving our infra. Not worth it for internal docs.
- **Inkeep AI** — chat-style answers, but adds an LLM dependency (latency, hallucination risk, subscription) that an internal team does not need.

**Upgrade trigger**: revisit if (a) docs grow past low thousands of pages, (b) reader feedback says typo tolerance / synonyms are missing, or (c) we ever expose docs publicly.

---

## Choice 4 — Routing: `baseUrl: '/'` (no `/docs` prefix)

**Decision**: Mount Fumadocs at the **site root** with `loader({ baseUrl: '/' })` and an optional catch-all at `app/[[...slug]]/`. Delete the placeholder `app/page.tsx`.

**Why**:

- `apps/docs/` exists **only** to serve docs. There is no marketing landing, no non-doc routes — so a `/docs` prefix would be wasted URL real estate.
- Cleaner internal links: `localhost:3002/foundations` over `localhost:3002/docs/foundations`.
- One shell, one URL space — fewer asymmetries to remember.

**Tradeoff acknowledged**: if we later add a marketing-style landing (`HomeLayout` at `/`), we will move docs under a `/docs` prefix and update `baseUrl` together. Captured as an open follow-up below.

**Implementation detail**: Next.js prefers `app/page.tsx` over `app/[[...slug]]/page.tsx` for the `/` route, so the placeholder `page.tsx` must be deleted in the same commit that adds the catch-all (Phase 3, Batch 0, Commit 3).

---

## Open follow-ups

- **Marketing landing** — if we want a hand-crafted landing (showcase, "What's new", featured components), introduce a `(home)` route group with `HomeLayout` at `/` and move docs to `/docs` (`baseUrl: '/docs'`). Cost: rename URLs, update sidebar / breadcrumbs / search results — manageable but not free.
- **Search backend** — re-evaluate Algolia or Inkeep if any of the upgrade triggers fire (see Choice 3).
- **i18n** — current decision is **off**; the docs are English-only because the audience is the engineering team. Revisit only if non-English contributors need locale-specific docs.
- **Theming Fumadocs chrome to match SNDQ tokens** — current decision is **keep Fumadocs chrome on its own tokens** so showcased SNDQ components stay visually distinct from the docs shell. Re-open if reviewers find the visual contrast confusing.
- **Usage indexer** (out of scope for Batch 0; tracked in [phase-3-batch-0-execution.md](./phase-3-batch-0-execution.md), Section 7) — three open decisions on granularity, update model, and single source of truth.

---

## See also

- General Fumadocs research: [04-frontend/nextjs/fumadocs/](../../../../04-frontend/nextjs/fumadocs/)
  - [README.md](../../../../04-frontend/nextjs/fumadocs/README.md) — overview, when to use
  - [layouts.md](../../../../04-frontend/nextjs/fumadocs/layouts.md) — layout shells comparison
  - [search.md](../../../../04-frontend/nextjs/fumadocs/search.md) — search backends comparison
  - [content.md](../../../../04-frontend/nextjs/fumadocs/content.md) — `source.config.ts`, `loader()`, `meta.json`, routing patterns
  - [theming-and-i18n.md](../../../../04-frontend/nextjs/fumadocs/theming-and-i18n.md) — `RootProvider`, CSS, Tailwind interop, i18n
  - [alternatives.md](../../../../04-frontend/nextjs/fumadocs/alternatives.md) — Fumadocs vs Nextra vs Docusaurus vs Mintlify vs Storybook
