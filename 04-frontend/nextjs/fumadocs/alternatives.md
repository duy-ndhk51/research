# Fumadocs — Alternatives

Side-by-side comparison of Fumadocs against the other common documentation stacks. The goal is to know **when Fumadocs is the right choice** and when one of the alternatives wins.

For Fumadocs internals, see [README.md](./README.md), [layouts.md](./layouts.md), [search.md](./search.md), [content.md](./content.md).

---

## Comparison matrix

| Dimension | **Fumadocs** | **Nextra** | **Docusaurus** | **Mintlify** | **Storybook (docs)** |
|-----------|--------------|------------|----------------|--------------|------------------------|
| Framework | Next.js (App Router) | Next.js | Own (React + Webpack) | Hosted SaaS | Storybook (own) |
| MDX authoring | Yes (`fumadocs-mdx`) | Yes (Next MDX) | Yes (built-in) | Yes (proprietary MDX flavor) | Yes (`@storybook/addon-docs`) |
| Hosted vs self-hosted | Self (your Next app) | Self | Self | Hosted | Self (with Storybook host) |
| App Router native | Yes | Yes (recent versions) | No | N/A | N/A |
| Sidebar / IA | Built-in (`meta.json`) | Built-in (`_meta.json`) | Built-in (`sidebars.js`) | Built-in (config UI) | Auto from story tree |
| Search (default) | **Orama** (free, build-time) | Built-in (FlexSearch) | Algolia (free DocSearch program) or local | Built-in hosted | None (third-party addons) |
| Search swap | Easy (route file) | Plugin / config | Plugin / config | N/A (vendor) | Manual addon |
| Theming | CSS vars + `slots` | CSS + Tailwind | Custom CSS / SwizzleCSS | Config UI | Storybook theme API |
| Tailwind v4 | Friendly | Friendly | Possible (more setup) | N/A | Possible |
| i18n | Yes | Yes | Yes (mature) | Yes | Limited |
| Customization ceiling | High (headless `fumadocs-core`) | Medium-High | High (most flexibility) | Low (vendor-bounded) | Medium |
| Hosting cost | Your infra | Your infra | Your infra | Subscription | Your infra (Storybook host) |
| Best for | App Router teams wanting docs co-located with product | Quick MDX docs in an existing Next site | Standalone, very large public docs | Polished public docs without owning the stack | Component sandbox + docs in one |
| Worst for | Non-Next sites | Sites needing very deep custom UX | Tightly co-located with a Next product | Teams needing full code control | Long-form prose / non-component docs |

---

## One-line verdict per option

- **Fumadocs** — Best when you already use Next.js App Router and want **MDX docs co-located with your product** while keeping full control of code, theme, and hosting. Search swap path (Orama → Algolia/Inkeep) is its standout flexibility.
- **Nextra** — Best when you want **the simplest path** to MDX docs inside Next.js and Fumadocs feels like overkill. Less flexible on search and customization, but very fast to start.
- **Docusaurus** — Best for **standalone public docs sites** (Meta, Babel, Jest pattern) that aren't tied to a Next product. Most mature i18n, most plugins, biggest customization ceiling — at the cost of being a separate stack.
- **Mintlify** — Best when you want **polished public docs without owning the framework** and you can absorb a SaaS subscription + vendor lock-in. Excellent default UX; limited if you need deep custom UI or to embed app components.
- **Storybook (docs only)** — Best when **the docs ARE the components** (design system, component sandbox). Pairs naturally with `@storybook/addon-docs` MDX. Weak as a long-form prose site or for non-component pages.

---

## Decision shortcuts

- **Already on Next App Router + want a docs framework?** → **Fumadocs** (this folder)
- **Already on Next + just want quick MDX with sidebar?** → **Nextra**
- **No framework constraint, want a dedicated docs stack?** → **Docusaurus**
- **Want hosted with minimal ops?** → **Mintlify**
- **Documenting components only?** → **Storybook docs**
- **Documenting components AND prose, want one site?** → Fumadocs (host) + reference Storybook for live demos, or Mintlify if you accept the SaaS

---

## What this comparison **does not** cover

- Detailed pricing of Mintlify / Algolia / Inkeep (changes frequently — check vendor pages)
- Exact plugin counts for Docusaurus / Nextra (large and moving)
- Performance benchmarks — all four self-hosted options ship comparable static output for typical doc sizes; differences emerge only at unusual scale
