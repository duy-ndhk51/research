# Fumadocs — Content Layer

How Fumadocs goes from MDX files on disk to typed content the layout and search consume. Covers `source.config.ts`, `loader()` and `baseUrl`, `meta.json`, frontmatter, the generated `.source` directory, `generateParams()`, and common routing pitfalls.

**Sources**: [Fumadocs MDX](https://www.fumadocs.dev/docs/mdx), [Fumadocs Core — Source](https://www.fumadocs.dev/docs/headless/source)

---

## Table of Contents

1. [Pipeline at a glance](#1-pipeline-at-a-glance)
2. [`source.config.ts`](#2-sourceconfigts)
3. [`loader()` and `baseUrl`](#3-loader-and-baseurl)
4. [`meta.json` rules](#4-metajson-rules)
5. [Frontmatter and custom schemas](#5-frontmatter-and-custom-schemas)
6. [The `.source` directory](#6-the-source-directory)
7. [Routing patterns](#7-routing-patterns)
8. [`generateParams()` and static export](#8-generateparams-and-static-export)
9. [Common pitfalls](#9-common-pitfalls)

---

## 1. Pipeline at a glance

```
content/docs/**/*.mdx ─┐
content/docs/**/meta.json ─┼─▶ fumadocs-mdx scan ─▶ .source/  ─▶ loader() ─▶ source
                         │   (build-time)               (typed)            ▲
source.config.ts ────────┘                                                 │
                                                                  Layout, page, search
```

Three artifacts you control:

- `content/docs/**` — MDX + `meta.json`
- `source.config.ts` — declares the collection
- `src/lib/source.ts` — wraps the generated source with `loader()` so layout and search routes share one instance

One artifact Fumadocs **generates**:

- `.source/` — typed exports the app imports from. Re-generated on dev/build.

---

## 2. `source.config.ts`

Declares the content collection (path, schema). Lives at the app root.

```ts
// apps/docs/source.config.ts
import { defineDocs, defineConfig } from 'fumadocs-mdx/config';

export const docs = defineDocs({
  dir: 'content/docs',
});

export default defineConfig();
```

`dir` is **on disk**, not URL. The default frontmatter schema requires `title` (and accepts `description` + a few others). You can pass a custom Zod schema to extend.

`next.config.ts` must wrap the app with `withMDX()`:

```ts
import { createMDX } from 'fumadocs-mdx/next';
const withMDX = createMDX();
export default withMDX(nextConfig);
```

---

## 3. `loader()` and `baseUrl`

`loader()` consumes the generated `.source` and exposes the **typed source** the rest of the app uses.

```ts
// apps/docs/src/lib/source.ts
import { loader } from 'fumadocs-core/source';
import { docs } from '../../.source';

export const source = loader({
  baseUrl: '/',
  source: docs.toFumadocsSource(),
});
```

**`baseUrl` is the URL contract.** Every URL Fumadocs emits — sidebar links, breadcrumbs, search results, `getPage()` resolution — is relative to it.

| `baseUrl` | URL for `content/docs/index.mdx` | URL for `content/docs/foundations/colors.mdx` |
|-----------|----------------------------------|------------------------------------------------|
| `'/'` | `/` | `/foundations/colors` |
| `'/docs'` | `/docs` | `/docs/foundations/colors` |

> Changing `baseUrl` later is a refactor: sidebar links, breadcrumbs, search results, route segments, and any hard-coded redirects must move together.

---

## 4. `meta.json` rules

A `meta.json` next to MDX files configures the **sidebar and group metadata** for that folder. The most common keys:

```json
{
  "title": "Foundations",
  "pages": ["index", "colors", "typography", "spacing"]
}
```

- `title` — display name in the sidebar / page tree
- `pages` — explicit ordering. Each entry is a **basename without extension** matching a sibling MDX or subfolder. Files **omitted** from `pages` are **omitted** from the sidebar
- Nested folders inherit the same rules; the parent's `pages` references the child folder name (e.g. `"foundations"`) and the folder's own `meta.json` orders pages within

Filename order does **not** drive sidebar order — `meta.json` `pages` is the only source.

---

## 5. Frontmatter and custom schemas

Default schema requires `title`; `description` is optional but recommended (used in search snippets and `<head>`).

```mdx
---
title: Button
description: Primary action element with variants and sizes.
---

The `Button` component …
```

For richer pages, extend with a Zod schema in `defineDocs`:

```ts
import { defineDocs } from 'fumadocs-mdx/config';
import { frontmatterSchema } from 'fumadocs-mdx/config';
import { z } from 'zod';

export const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: frontmatterSchema.extend({
      status: z.enum(['stable', 'beta', 'deprecated']).optional(),
      since: z.string().optional(),
    }),
  },
});
```

The extra fields are **typed** in `page.data.*` everywhere you read pages.

---

## 6. The `.source` directory

`fumadocs-mdx` generates `.source/` at the app root. It contains typed exports your app imports (`import { docs } from '../../.source'`). Treat it like a generated file:

- **Generated**: on first `pnpm dev` or `pnpm build` after a content change
- **Should be gitignored**
- **Stale-state debugging**: delete `.source/` and rerun `pnpm dev` if you see "module not found", phantom missing pages, or wrong frontmatter
- **First-time TypeScript noise**: `src/lib/source.ts` may show a missing-module error until `.source/` exists. Run `pnpm dev` once to generate it.

---

## 7. Routing patterns

Two common shapes. Pick by **whether the docs own the site root**.

### A. Docs at site root (`baseUrl: '/'`)

```
src/app/
├── layout.tsx                  ← root layout, RootProvider
├── api/search/route.ts
└── [[...slug]]/                ← optional catch-all owns "/"
    ├── layout.tsx              ← <DocsLayout tree=…>{children}</DocsLayout>
    └── page.tsx                ← MDX renderer
```

Delete any placeholder `app/page.tsx` — Next.js prefers it over `[[...slug]]` for `/`.

### B. Docs prefixed (`baseUrl: '/docs'`)

```
src/app/
├── layout.tsx                  ← root layout, RootProvider
├── api/search/route.ts
├── page.tsx                    ← marketing landing (HomeLayout or custom)
└── (docs)/
    └── [[...slug]]/
        ├── layout.tsx          ← <DocsLayout tree=…>{children}</DocsLayout>
        └── page.tsx
```

Useful for marketing + docs hybrids. The route group `(docs)` does not appear in URLs — only the file location matters.

---

## 8. `generateParams()` and static export

`source.generateParams()` returns the slug list for static export. Wire it in the catch-all page:

```tsx
import { source } from '@/lib/source';

export function generateStaticParams() {
  return source.generateParams();
}

export default async function Page(props: { params: Promise<{ slug?: string[] }> }) {
  const params = await props.params;
  const slug = params.slug ?? [];
  const page = source.getPage(slug);
  if (!page) notFound();
  // render…
}
```

Notes:

- `slug ?? []` is required for the **root** page (`/`) — `params.slug` is `undefined` there.
- With `output: 'export'` (full SSG), every page in `generateParams()` is built ahead of time.
- Without it, the same code works as on-demand SSR / ISR.

---

## 9. Common pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Placeholder `app/page.tsx` competes with `app/[[...slug]]/page.tsx` | `/` shows the old placeholder, never the docs home | Delete `app/page.tsx` (single-shell setup) or move the catch-all to a route group |
| `baseUrl: '/docs'` with content at `content/docs/` and routes under `app/[[...slug]]` | URLs render under `/`, but sidebar / breadcrumb point to `/docs/...` (404s) | Match `baseUrl` to the **route segment** that hosts the catch-all |
| Stale `.source/` after deleting/renaming MDX | "Cannot find module …", or wrong page tree | Delete `.source/` and rerun `pnpm dev` |
| Forgot `slug ?? []` | `/` returns 404 even though `index.mdx` exists | Default the slug to `[]` before `getPage()` |
| `meta.json` lists a basename that does not exist | Page silently missing from sidebar | Match `pages` entries to actual file/folder basenames |
| Type-only fields read from `page.data.*` undefined at build | Schema extension not picked up | Confirm the extended schema is passed to `defineDocs({ docs: { schema } })` and `.source/` regenerated |
| Files without frontmatter | Build fails with schema error | Add at least `title`; configure schema if you want optional `title` |
