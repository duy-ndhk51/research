# Phase 3, Batch 0 Execution — Docs Infrastructure (Fumadocs)

Step-by-step execution guide for Phase 3, Batch 0. Each commit is independently verifiable and revertable.

**Created**: 2026-05-04
**Status**: PR 1 (Commits 1–5) shipped on **Next.js 16 + Tailwind CSS 4 + Fumadocs 16** baseline. PR 2 (Commits 6–7) adds **Fumadocs Story** integration — Commits 6–7 implemented; pending manual commit.
**Architecture**: [README.md](./README.md)
**Migration plan**: [migration-plan.md](./migration-plan.md)
**Phase 1a execution**: [phase-1a-execution.md](./phase-1a-execution.md)
**Phase 1b execution**: [phase-1b-execution.md](./phase-1b-execution.md)
**Phase 2 execution**: [phase-2-execution.md](./phase-2-execution.md)
**Decision rationale**: [fumadocs-decision.md](./fumadocs-decision.md) — SNDQ-specific picks (framework, layout, search, routing) and tradeoffs. Background library research at [04-frontend/nextjs/fumadocs/](../../../../04-frontend/nextjs/fumadocs/).

**Branching**: Not prescribed here — create and name your branch however you prefer before starting.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Fumadocs Setup + IA Stubs](#3-pr-1--fumadocs-setup--ia-stubs)
4. [PR 2 — Fumadocs Story Integration (follow-up)](#4-pr-2--fumadocs-story-integration-follow-up)
5. [Final Verification](#5-final-verification)
6. [Team Communication](#6-team-communication)
7. [What's Next](#7-whats-next)
8. [Deferred: Usage Indexer Feature](#8-deferred-usage-indexer-feature)

---

## 1. Overview

**Goal**: Install Fumadocs in the existing `apps/docs/` placeholder, wire client-side Orama search, seed an empty Foundations / Primitives / Blocks information architecture — and follow up with **Fumadocs Story** so that Batch 1 onwards only needs to author component MDX (and an optional `*.story.tsx` sibling), not docs infrastructure.

**Structure**: 5 commits across PR 1, then 2 commits across PR 2 (Fumadocs Story).

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Fumadocs install + root provider + root catch-all layout + search API + IA stubs | Low | 1-5 |
| **PR 2** | `@fumadocs/story` install + factory + CSS preset; first `Text` story wired into `text.mdx` | Low | 6-7 |

**Why 1 PR**: The only consumer of `apps/docs/` is the docs app itself (a placeholder page at `/` until Commit 3 removes it in favor of an optional catch-all). No other workspace package or app reads from it, so the blast radius is contained. Each commit is still independently buildable so a partial revert remains an option during review.

### Prerequisites

- Phase 2 is merged to dev
- `apps/docs/` is a **Next.js 16** App Router app (`apps/docs/src/app/page.tsx` placeholder at `/` until Commit 3 removes it in favor of the catch-all), plus `apps/docs/next.config.ts`, `apps/docs/tsconfig.json`
- **Tailwind CSS 4** (pinned to **4.2.4+** in this repo so Fumadocs UI presets compile; older 4.0.x can error on `@source` paths during `next build`)
- `@sndq/ui-v2` workspace dependency is wired in `apps/docs/package.json`
- `apps/docs/next.config.ts` declares `transpilePackages: ['@sndq/ui-v2']`
- **Fumadocs manual install** reference: [Fumadocs — Next.js](https://www.fumadocs.dev/docs/manual-installation/next) (Root provider, global CSS imports, optional `collections/*` path alias)

---

## 2. Before You Start

### Capture baselines

Run these from the monorepo root and save the output. You will diff against these after each commit.

```bash
# docs app baselines
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build 2>&1 | tee /tmp/phase3-b0-docs-build-before.txt
pnpm --filter @sndq/docs run lint 2>&1 | tee /tmp/phase3-b0-docs-lint-before.txt
pnpm --filter @sndq/docs run type-check 2>&1 | tee /tmp/phase3-b0-docs-typecheck-before.txt

# sndq-fe baselines (sanity — Batch 0 should not touch sndq-fe at all)
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase3-b0-fe-build-before.txt
```

The current placeholder builds clean, so the baseline is "exit 0, no errors". After Batch 0, the docs build will be larger (Fumadocs UI + content tree) — that is expected, but `sndq-fe` build output must be byte-identical.

### Visual baseline

Open `apps/docs` locally:

```bash
pnpm --filter @sndq/docs run dev
```

Visit `http://localhost:3002/`. You should see the placeholder "Component Docs — Coming soon" message. Screenshot it. After Batch 0 completes, the same URL should render the Fumadocs home (`content/docs/index.mdx`) with the sidebar — no `/docs` prefix and no redirect.

---

## 3. PR 1 — Fumadocs Setup + IA Stubs

Install Fumadocs into the placeholder docs app, wire layout, search, and seed empty categories. Safe to merge as one PR because no other code depends on `apps/docs/`.

---

### Commit 1: Install Fumadocs and add source config

**What**: Add Fumadocs dependencies (aligned with **Next 16**), MDX source config, Tailwind 4 + PostCSS wiring, TypeScript path alias for generated `.source`, and scripts so CI can type-check before `.source` exists.

**Files to edit**:

- `apps/docs/package.json` — dependencies: `next` **16.x**, `fumadocs-ui`, `fumadocs-core`, `fumadocs-mdx`, `zod` **4.x** (peer of `fumadocs-core`), `react` / `react-dom` **19.2.x**; devDependencies: `eslint-config-next` (same minor as `next`), `@types/mdx`, `tailwindcss` **^4.2.4**, `@tailwindcss/postcss` **^4.2.4**, `postcss`
- `apps/docs/next.config.ts` — wrap with `withMDX()` from `fumadocs-mdx/next` while preserving `transpilePackages: ['@sndq/ui-v2']`
- `apps/docs/tsconfig.json` — add `"collections/*": ["./.source/*"]` under `compilerOptions.paths` (requires `./` prefix when `baseUrl` is unset)
- `apps/docs/.gitignore` — ignore `/.source/`
- `apps/docs/eslint.config.mjs` — ignore `.source/**` in generated MDX output

**Files to create**:

- `apps/docs/postcss.config.mjs` — `plugins: { '@tailwindcss/postcss': {} }` (Tailwind v4)
- `apps/docs/source.config.ts` — declare the docs content collection (path, schema)
- `apps/docs/src/lib/source.ts` — load the collection via `loader()` so layout and search routes share one source instance
- `apps/docs/src/app/global.css` — `@import 'tailwindcss'`, then SNDQ token CSS (`@sndq/config/tailwind/tokens.css`, `@sndq/config/tailwind/semantic-tokens.css`), then `@import 'fumadocs-ui/css/neutral.css'`, `@import 'fumadocs-ui/css/preset.css'` (Fumadocs manual install)

**Scripts** (in `package.json`):

- `"generate:source": "fumadocs-mdx"`
- `"type-check": "pnpm run generate:source && tsc --noEmit"`

**Before** (`apps/docs/next.config.ts`):

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@sndq/ui-v2'],
};

export default nextConfig;
```

**After** (`apps/docs/next.config.ts`):

```typescript
import { createMDX } from 'fumadocs-mdx/next';
import type { NextConfig } from 'next';

const withMDX = createMDX();

const nextConfig: NextConfig = {
  transpilePackages: ['@sndq/ui-v2'],
};

export default withMDX(nextConfig);
```

**Target `apps/docs/source.config.ts`**:

```typescript
import { defineConfig, defineDocs } from 'fumadocs-mdx/config';

export const docs = defineDocs({
  dir: 'content/docs',
});

export default defineConfig();
```

**Target `apps/docs/src/lib/source.ts`**:

```typescript
import { docs } from 'collections/server';
import { loader } from 'fumadocs-core/source';

export const source = loader({
  baseUrl: '/',
  source: docs.toFumadocsSource(),
});
```

**Note**: `collections/server` maps to `./.source/server` via `tsconfig` paths after `pnpm run generate:source` (or `next dev` / `next build`). Do not import `../../.source` without `/server` — there is no package entry on the folder alone.

**Shared ESLint (`@sndq/config`)**: `createEslintConfig(dirname, options?)` in `packages/config/eslint.mjs` defaults to **`nextMajor: 15`** (FlatCompat + `next/core-web-vitals`, `next/typescript`, `plugin:prettier/recommended`). **`eslint-config-next` 16** is flat-first; combining it with `FlatCompat` and the legacy `next/*` presets breaks under ESLint 9 (for example circular JSON errors). Callers on Next 16 pass **`{ nextMajor: 16 }`** so the factory spreads the flat `eslint-config-next/core-web-vitals` + `typescript` arrays and flat `eslint-plugin-prettier/recommended`. **`apps/docs`** passes `{ nextMajor: 16 }`; other apps keep a single-argument call and stay on the default 15 path.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Peer dep mismatch with React 19 | LOW | `pnpm install` resolves cleanly. If Fumadocs requires React 18, pin a Fumadocs version compatible with React 19 (Fumadocs UI v15+). |
| `.source` directory not generated yet | LOW | Expected — gets generated on first `pnpm --filter @sndq/docs dev` or `build`. Type errors in `source.ts` resolve after first build. |
| `withMDX` strips existing config keys | LOW | Verify `transpilePackages` survives by inspecting `apps/docs/.next/required-server-files.json` after build. |

**Verification**:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
# Build should still succeed even without any content yet (Fumadocs tolerates an empty collection).
```

**If it fails**:

- **`Cannot find module 'collections/server'`** (or `../../.source/server`): Run `pnpm --filter @sndq/docs run generate:source` or `dev`/`build` once so `.source/` exists. Ensure `tsconfig` path is `"collections/*": ["./.source/*"]`.
- **`Module not found: Can't resolve 'fumadocs-mdx/next'`**: Confirm the package landed in `apps/docs/node_modules/fumadocs-mdx/`. If not, re-run `pnpm install` from the monorepo root.
- **Peer dep warning for React**: Pin a Fumadocs version that lists `react@^19` as peer. Check the latest minor on npm.

**Commit message**: `chore(docs): install fumadocs and add source config`

**Status**:

- [x] Dependencies added to `apps/docs/package.json`
- [x] `source.config.ts` created
- [x] `src/lib/source.ts` created
- [x] `next.config.ts` wrapped with `withMDX()`
- [x] Build passes
- [x] Committed

---

### Commit 2: Wire Fumadocs root provider in layout

**What**: Replace the bare HTML body in the root layout with Fumadocs `RootProvider`, import **`global.css`** (Tailwind + Fumadocs theme presets from Commit 1 — not the legacy single-file `fumadocs-ui/style.css`), so all docs pages share theme + search context.

**Files to edit**:

- `apps/docs/src/app/layout.tsx` — `import './global.css'`, wrap children in `<RootProvider>` from **`fumadocs-ui/provider/next`**, add Fumadocs’ recommended `body` layout classes

**Before** (`apps/docs/src/app/layout.tsx`):

```typescript
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'SNDQ Component Docs',
  description: 'Component documentation for the SNDQ design system',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

**After** (`apps/docs/src/app/layout.tsx`):

```typescript
import './global.css';

import type { Metadata } from 'next';
import { RootProvider } from 'fumadocs-ui/provider/next';

export const metadata: Metadata = {
  title: 'SNDQ Component Docs',
  description: 'Component documentation for the SNDQ design system',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="flex min-h-screen flex-col">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
```

**Why `suppressHydrationWarning`**: `RootProvider` mounts a theme switcher that toggles `<html class="dark">` on the client. Without the suppression, React logs a hydration mismatch on first paint.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Fumadocs CSS conflicts with `@sndq/ui-v2` styles | LOW | The placeholder home page does not import `@sndq/ui-v2` yet, so Batch 0 cannot expose this conflict. Track for Batch 1. |
| `RootProvider` requires client-only env | LOW | It is a client component shipped by Fumadocs. The layout itself remains a server component. |

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
pnpm --filter @sndq/docs run dev
# Visit http://localhost:3002/ — placeholder still renders, but no console errors and theme cookie is set.
```

**If it fails**:

- **Tailwind / `@source` error during `next build`**: Pin `tailwindcss` and `@tailwindcss/postcss` to **4.2.4+** (Fumadocs UI 16 presets assume a recent Tailwind 4).
- **`Module not found` for `fumadocs-ui/css/*.css`**: Confirm `fumadocs-ui` is installed and paths match [Fumadocs — Styles](https://www.fumadocs.dev/docs/manual-installation/next).
- **Hydration warning persists**: Confirm `suppressHydrationWarning` is on the `<html>` tag, not `<body>`.

**Commit message**: `feat(docs): wire fumadocs root provider in layout`

**Status**:

- [x] `global.css` imported from root layout (Tailwind + Fumadocs neutral + preset)
- [x] `RootProvider` from `fumadocs-ui/provider/next` wraps children
- [x] `suppressHydrationWarning` set on `<html>`
- [x] Build passes
- [x] Committed (when you land the slice)

---

### Commit 3: Add root catch-all routes with sidebar

**What**: Mount Fumadocs at the site root: an optional catch-all `[[...slug]]` under `app/` serves `/`, `/foundations`, `/primitives`, etc. Remove the placeholder `app/page.tsx` so `/` is not claimed by a separate route (Next.js would otherwise prefer `page.tsx` over `[[...slug]]` for `/`).

**Files to create**:

- `apps/docs/src/app/[[...slug]]/layout.tsx` — `DocsLayout` reading `source.pageTree`
- `apps/docs/src/app/[[...slug]]/page.tsx` — catch-all page that resolves the slug via `source.getPage(slug)` and renders the MDX body

**Files to delete**:

- `apps/docs/src/app/page.tsx` — placeholder; must be removed so the optional catch-all can render `/`

**Target `apps/docs/src/app/[[...slug]]/layout.tsx`**:

```typescript
import type { ReactNode } from 'react';
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { source } from '@/lib/source';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout
      tree={source.pageTree}
      nav={{ title: 'SNDQ Design System' }}
    >
      {children}
    </DocsLayout>
  );
}
```

**Target `apps/docs/src/app/[[...slug]]/page.tsx`**:

```typescript
import { notFound } from 'next/navigation';
import { DocsBody, DocsPage, DocsTitle } from 'fumadocs-ui/page';
import { source } from '@/lib/source';

export default async function Page(props: {
  params: Promise<{ slug?: string[] }>;
}) {
  const params = await props.params;
  const slug = params.slug ?? [];
  const page = source.getPage(slug);
  if (!page) notFound();

  const MDX = page.data.body;

  return (
    <DocsPage toc={page.data.toc}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsBody>
        <MDX />
      </DocsBody>
    </DocsPage>
  );
}

export function generateStaticParams() {
  return source.generateParams();
}
```

**Note on path alias**: `apps/docs/tsconfig.json` already maps `"@/*": ["./src/*"]`, so `@/lib/source` resolves correctly.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `source.pageTree` empty causes blank sidebar | LOW | Expected until Commit 5 seeds content. Page renders, sidebar shows empty state. |
| Both `page.tsx` and `[[...slug]]/page.tsx` exist | MEDIUM | If the placeholder `app/page.tsx` is not deleted, `/` still shows "Coming soon" and never reaches Fumadocs. Delete `page.tsx` in this commit. |

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
pnpm --filter @sndq/docs run dev
# Visit http://localhost:3002/ — should 404 cleanly (no content yet) but the layout chrome (header, empty sidebar) should render.
```

**If it fails**:

- **`source.getPage is not a function`**: Verify `src/lib/source.ts` was created in Commit 1 and exports `source` from `loader(...)`.
- **`Cannot read properties of undefined (reading 'body')`**: The page exists but has no MDX body — likely a stale `.source` cache. Delete `apps/docs/.source` and rerun.

**Commit message**: `feat(docs): add root catch-all with docs layout`

**Status**:

- [x] `[[...slug]]/layout.tsx` created
- [x] `[[...slug]]/page.tsx` created
- [x] Placeholder `src/app/page.tsx` deleted
- [x] `generateStaticParams` exported
- [x] Build passes (remove stale `apps/docs/.next` if `tsc` still references deleted `page.tsx`)
- [x] Committed (manual)

**SNDQ note (2026-05-04)**: If `pnpm --filter @sndq/docs run lint` fails with a circular JSON error after upgrading docs to Next 16, ensure **`apps/docs/eslint.config.mjs`** calls **`createEslintConfig(__dirname, { nextMajor: 16 })`** so `@sndq/config` uses the flat Next 16 branch (not the default `nextMajor: 15` + `FlatCompat` path).

---

### Commit 4: Add Orama search API route

**What**: Expose `/api/search` backed by Fumadocs' built-in Orama adapter so client-side `Cmd+K` search can query the indexed content.

**Files to create**:

- `apps/docs/src/app/api/search/route.ts`

**Target `apps/docs/src/app/api/search/route.ts`**:

```typescript
import { createFromSource } from 'fumadocs-core/search/server';
import { source } from '@/lib/source';

export const { GET } = createFromSource(source);
```

That is the entire route. `RootProvider` (added in Commit 2) wires the client search UI to this endpoint by default.

**Why Orama by default**: Client-side, free, indexed at build time, zero infra. Documented as swappable to Algolia or Inkeep later by replacing this single file — no changes to component MDX or layout required.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Search returns empty until content exists | LOW | Expected. Verified in Commit 5 once stub MDX is seeded. |
| Orama bundle size on the docs client | LOW | Internal-only docs, content size is bounded — acceptable. Revisit if site grows past ~500 pages. |
| Route mistakenly cached as static | LOW | Fumadocs handles route config internally. Verify `apps/docs/.next/server/app/api/search/route.js` exists post-build. |

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
pnpm --filter @sndq/docs run dev
curl 'http://localhost:3002/api/search?query=test'
# Should return a JSON array (likely empty until Commit 5 lands).
```

**If it fails**:

- **`Cannot find module 'fumadocs-core/search/server'`**: Re-check `fumadocs-core` is installed.
- **404 on `/api/search`**: Confirm the file is at `apps/docs/src/app/api/search/route.ts` (not `pages/api/...`).

**Commit message**: `feat(docs): add orama search api route`

**Status**:

- [x] `api/search/route.ts` created
- [x] `curl` to `/api/search?query=test` returns 200
- [x] Build passes
- [x] Committed

---

### Commit 5: Seed Foundations / Primitives / Blocks IA

**What**: Create the docs root index plus three category folders, each with a `meta.json` and a placeholder `index.mdx`. This is what makes search return results and the sidebar show the planned IA from day one.

**Files to create**:

- `apps/docs/content/docs/index.mdx` — landing page
- `apps/docs/content/docs/meta.json` — sidebar order for top-level entries
- `apps/docs/content/docs/foundations/index.mdx`
- `apps/docs/content/docs/foundations/meta.json`
- `apps/docs/content/docs/primitives/index.mdx`
- `apps/docs/content/docs/primitives/meta.json`
- `apps/docs/content/docs/blocks/index.mdx`
- `apps/docs/content/docs/blocks/meta.json`

**Target `apps/docs/content/docs/index.mdx`**:

```mdx
---
title: SNDQ Design System
description: Component documentation for the SNDQ design system.
---

The SNDQ design system documents the standardized components in `@sndq/ui-v2`,
the design tokens in `@sndq/config`, and the patterns we use to build screens.

Browse:

- **Foundations** — design tokens, color, typography, spacing
- **Primitives** — base components (Button, Input, Badge, ...)
- **Blocks** — composed patterns built from primitives
```

**Target `apps/docs/content/docs/meta.json`**:

```json
{
  "title": "Design System",
  "pages": ["index", "foundations", "primitives", "blocks"]
}
```

**Target `apps/docs/content/docs/foundations/index.mdx`**:

```mdx
---
title: Foundations
description: Design tokens, color, typography, spacing — the primitives that every component is built on.
---

Foundations define the shared language of the SNDQ UI: color, type, spacing, and the token rules that components must follow.

Start here:

- [Identity](/foundations/identity): the UI-V2 identity spec (tokens, sizing rules, spacing, shadows).
- [Foundation](/foundations/foundation): the token scales and rule tables used to build components.
```

**Target `apps/docs/content/docs/foundations/meta.json`**:

```json
{
  "title": "Foundations",
  "pages": ["index", "identity", "foundation"]
}
```

**MVP pages (Batch 0)**:

- `apps/docs/content/docs/foundations/identity.mdx` — derived from the UI-V2 Identity spec content used in `apps/ui-v2-dev` (`IdentityTab`).
- `apps/docs/content/docs/foundations/foundation.mdx` — derived from the token/rule/scales used in `apps/ui-v2-dev` (`FoundationTab`).

**Target `apps/docs/content/docs/primitives/index.mdx`**:

```mdx
---
title: Primitives
description: Base components from @sndq/ui-v2 — Button, Input, Badge, Select, Dialog, and more.
---

Component pages arrive in **Phase 3, Batch 1** as components graduate from the
prototype into `@sndq/ui-v2`. See the migration plan in the monorepo research docs for the batch schedule.
```

**Target `apps/docs/content/docs/primitives/meta.json`**:

```json
{
  "title": "Primitives",
  "pages": ["index"]
}
```

**Target `apps/docs/content/docs/blocks/index.mdx`**:

```mdx
---
title: Blocks
description: Composed patterns built from primitives — forms, sheets, tables, and more.
---

Block pages arrive after the primitives they depend on have been documented.
```

**Target `apps/docs/content/docs/blocks/meta.json`**:

```json
{
  "title": "Blocks",
  "pages": ["index"]
}
```

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| MDX frontmatter schema mismatch | LOW | Fumadocs default schema requires `title`, optionally `description`. All stubs include both. |
| Sidebar order surprises | LOW | `meta.json` `pages` array controls order. Verified visually after build. |
| Search returns nothing | LOW | After seeding, `curl '/api/search?query=foundations'` should return at least one hit. |

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
pnpm --filter @sndq/docs run dev
# Visit http://localhost:3002/ — landing page renders, sidebar shows Foundations / Primitives / Blocks.
curl 'http://localhost:3002/api/search?query=foundations'
# Should return a non-empty result set referencing the foundations stub.
```

**If it fails**:

- **`The module ".source" was not found`**: Delete `apps/docs/.source` and rerun `pnpm --filter @sndq/docs run dev` to regenerate.
- **Sidebar order wrong**: Check the `pages` array in each `meta.json` — entries must match the file basenames without extension.
- **Empty search**: Confirm Commit 4's `route.ts` is committed and Commit 1's `source.config.ts` references `dir: 'content/docs'` (the same folder you seeded).

**Commit message**: `feat(docs): seed foundations primitives blocks IA`

**Status**:

- [x] Root `index.mdx` + `meta.json` created
- [x] Foundations folder seeded
- [x] Primitives folder seeded
- [x] Blocks folder seeded
- [x] Sidebar shows three categories in order
- [x] Search returns results
- [x] Build passes
- [ ] Committed

---

### PR 1 Checkpoint

Push your branch and wait for CI / Vercel preview build to pass before continuing.

```bash
git push -u origin <your-branch>
# Create PR targeting dev
# Wait for CI to complete successfully
```

**This validates**: Workspace install resolves the new Fumadocs deps, the docs app builds in CI with the generated `.source` directory, and the search API route is recognized by the Next.js App Router in a CI environment.

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Merged (or ready to continue)

---

## 4. PR 2 — Fumadocs Story Integration (follow-up)

Add `@fumadocs/story` so component MDX pages can render live, controllable previews via `<story.WithControl />`. Two commits: a small infra commit (factory + CSS preset) and the first real story (`Text`) wired into `text.mdx`. See [migration-plan.md "Why Fumadocs Story (over Storybook)"](./migration-plan.md#why-fumadocs-story-over-storybook) for rationale.

**Decisions**:

- **Story files live in `apps/docs/src/stories/`**, not co-located in `packages/ui-v2/`. Keeps `@sndq/ui-v2` clean of `@fumadocs/story` deps for `sndq-fe`.
- **Story `Component` must be a client component** ([Fumadocs Story — Next.js](https://www.fumadocs.dev/docs/integrations/story/next)). To preserve `Text` as RSC-compatible, each primitive gets a thin `'use client'` re-export at `apps/docs/src/stories/components/<name>.tsx` instead of marking the package component itself.
- **`text.mdx` adopts ONE `<story.WithControl />` block** at the top of the page. All existing inline JSX previews and `## Examples` sections stay untouched — Story complements them, does not replace them.

---

### Commit 6: Install `@fumadocs/story` and add factory + CSS preset

**What**: Install the package, create the story factory used by every future `*.story.tsx` file, and wire the Tailwind preset into `global.css`. No story files yet — this commit only lights up the infrastructure.

**Files to edit**:

- `apps/docs/package.json` — add `@fumadocs/story` (latest; this implementation pinned `^0.0.14`)
- `apps/docs/src/app/global.css` — append `@import '@fumadocs/story/css/preset.css';` AFTER the existing Fumadocs UI presets so the Story panel inherits theme colors and Tailwind layer ordering survives:
  ```css
  @import 'tailwindcss';
  @import '@sndq/config/tailwind/tokens.css';
  @import '@sndq/config/tailwind/semantic-tokens.css';
  @import 'fumadocs-ui/css/neutral.css';
  @import 'fumadocs-ui/css/preset.css';
  @import '@fumadocs/story/css/preset.css';
  ```

**Files to create**:

- `apps/docs/src/lib/story.ts` — story factory shared by every `*.story.tsx`:
  ```ts
  import { createFileSystemCache, defineStoryFactory } from '@fumadocs/story';

  export const { defineStory } = defineStoryFactory({
    cache:
      process.env.NODE_ENV === 'production'
        ? createFileSystemCache('.next/fumadocs-story')
        : undefined,
    tsc: {},
  });
  ```

**No tsconfig / next.config changes needed**:

- `@/lib/story` resolves via the existing `"@/*": ["./src/*"]` alias in `apps/docs/tsconfig.json`.
- `.gitignore` already ignores `/.next/`, which covers the `fumadocs-story` cache directory.
- `next.config.mjs` needs no change: the factory is module-evaluation-only and uses `import.meta.url`; no MDX plugin to register.
- `custom-mdx-components.ts` needs no change: `<story.WithControl />` is imported per-page, not registered globally.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `@fumadocs/story` is pre-1.0 (`0.0.x`) | LOW-MEDIUM | API may shift before 1.0. We pin via `^0.0.14` so patch updates flow but a major bump requires a deliberate update. Re-check the [installation page](https://www.fumadocs.dev/docs/integrations/story/next) before bumping. |
| Tailwind preset clashes with `fumadocs-ui` preset | LOW | Story preset is appended **after** `fumadocs-ui/css/preset.css`, so its rules win on conflict. Verified in this commit's build. |

**Verification**:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
# Build still produces the same routes — no new pages yet, only infra.
```

**If it fails**:

- **`Cannot find module '@fumadocs/story'`**: re-run `pnpm install` from the monorepo root; confirm `apps/docs/node_modules/@fumadocs/story/` exists.
- **CSS rules from Story panel look broken**: the `@import '@fumadocs/story/css/preset.css';` line must come **after** `@import 'fumadocs-ui/css/preset.css';` in `global.css`.

**Commit message**: `chore(docs): install @fumadocs/story and add factory + css preset`

**Status**:

- [x] `@fumadocs/story` added to `apps/docs/package.json` (pinned `^0.0.14`)
- [x] `apps/docs/src/lib/story.ts` created
- [x] `@import '@fumadocs/story/css/preset.css';` appended to `global.css`
- [x] `pnpm --filter @sndq/docs run build` green
- [ ] Committed *(manual)*

---

### Commit 7: Add first Story (`Text`) and wire into `text.mdx`

**What**: Ship the first real story — a controllable `Text` preview rendered at the top of `apps/docs/content/docs/primitives/text.mdx`. All existing inline JSX preview blocks and `## Examples` sections remain unchanged.

**Files to create**:

- `apps/docs/src/stories/components/text.tsx` — `'use client'` re-export so the package `Text` keeps its RSC-friendly shape:
  ```tsx
  'use client';
  export { Text, type TextProps } from '@sndq/ui-v2/components';
  ```
- `apps/docs/src/stories/text.story.tsx` — server component (no `'use client'`); imports the client wrapper and exports the canonical `story`:
  ```tsx
  import { defineStory } from '@/lib/story';
  import { Text } from './components/text';

  export const story = defineStory(import.meta.url, {
    Component: Text,
    args: {
      initial: {
        children: 'The quick brown fox jumps over the lazy dog.',
        variant: 'body',
        size: 'sm',
      },
    },
  });
  ```

**Files to edit**:

- `apps/docs/content/docs/primitives/text.mdx` — add the story import alongside the existing `Text` import, and render `<story.WithControl />` as the first interactive block. Diff is two added lines plus one block:
  ```mdx
  import { Text } from '@sndq/ui-v2/components';
  import { story } from '@/stories/text.story';

  <story.WithControl />

  <div className="rounded-md border border-sndq-border p-4 grid gap-2">
    {/* existing inline preview grid stays */}
  </div>
  ```
  The four `## Examples` JSX blocks lower in the page are not touched.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Story renders without controls | LOW | Confirm `args.initial.children` is set so the panel has at least one editable prop. |
| Hydration mismatch on the controllable preview | LOW | The wrapper is a `'use client'` re-export, so the boundary is explicit. The `<html suppressHydrationWarning>` from PR 1 Commit 2 covers any theme-related diffs. |
| `Text` accidentally becomes a client component package-wide | LOW | The `'use client'` directive is in `apps/docs/src/stories/components/text.tsx`, **not** in `packages/ui-v2/src/components/Text.tsx`. Verify the package file does not gain `'use client'`. |

**Verification**:

```bash
pnpm --filter @sndq/docs run generate:source
pnpm --filter @sndq/docs run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
pnpm --filter @sndq/docs exec eslint src/lib/story.ts src/stories/components/text.tsx src/stories/text.story.tsx
# Manual smoke: pnpm --filter @sndq/docs run dev → http://localhost:3002/primitives/text
# Confirm the controls panel renders above the existing inline variant grid.
```

**If it fails**:

- **`Component must be a client component`**: ensure `apps/docs/src/stories/components/text.tsx` has `'use client';` on its first line (above the export).
- **`story is not exported`**: the named export must be `story` (or pass `name` in `defineStory` options). Default-exporting will not work.
- **Controls show wrong props**: the factory's `tsc: {}` field gives default TypeScript options for type-driven control generation. Pass `tsc: { compilerOptions: { ... } }` if you need to constrain how types are read.

**Commit message**: `feat(docs): add first fumadocs story (text) and wire into text.mdx`

**Status**:

- [x] `apps/docs/src/stories/components/text.tsx` created (`'use client'`)
- [x] `apps/docs/src/stories/text.story.tsx` created (server component, exports `story`)
- [x] `apps/docs/content/docs/primitives/text.mdx` imports `story` and renders `<story.WithControl />` above the existing inline preview
- [x] Type-check + build green; `/primitives/text` in static export
- [x] Lint clean on touched files
- [ ] Committed *(manual)*

---

### PR 2 Checkpoint

Push the PR 2 branch (separate from PR 1 if PR 1 already merged):

```bash
git push -u origin <your-branch>
# Create PR targeting dev
# Wait for CI to complete successfully
```

**This validates**: `@fumadocs/story` resolves under workspace install, the Story panel renders in production builds, and the new `*.story.tsx` files type-check across the monorepo.

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Merged (or ready to continue)

---

## 5. Final Verification

After all 7 commits (PR 1 = Commits 1–5, PR 2 = Commits 6–7), run the full suite from the monorepo root:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
```

Compare against baselines:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build 2>&1 | tee /tmp/phase3-b0-docs-build-final.txt
pnpm --filter @sndq/docs run lint 2>&1 | tee /tmp/phase3-b0-docs-lint-final.txt
pnpm --filter @sndq/docs run type-check 2>&1 | tee /tmp/phase3-b0-docs-typecheck-final.txt

# sndq-fe sanity: must be byte-identical
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase3-b0-fe-build-final.txt
diff /tmp/phase3-b0-fe-build-before.txt /tmp/phase3-b0-fe-build-final.txt
```

**Expected result**: `apps/docs` build is larger than baseline (Fumadocs + content tree). `sndq-fe` build output is unchanged (Batch 0 does not touch `sndq-fe`).

**Visual verification** (manual):

1. `pnpm --filter @sndq/docs run dev`
2. Visit `http://localhost:3002/` — must show the Fumadocs home (`index.mdx`), not the old placeholder
3. Sidebar shows: Foundations, Primitives, Blocks (in that order)
4. Each category page renders its placeholder content (e.g. `http://localhost:3002/foundations`)
5. Press `Cmd+K` (or `Ctrl+K`) — search dialog opens; type `primitives` and the Primitives index appears in results

**Final status**:

- [x] All 5 commits complete
- [x] Docs build passes from root
- [x] Lint passes from root
- [x] Type-check passes from root
- [x] `sndq-fe` build output unchanged from baseline
- [x] Visual check — home at `/`, sidebar, search all functional
- [x] PR created and merged

---

## 6. Team Communication

Send to the team before merging:

> **Heads up: docs site now uses Fumadocs**
>
> PR [link] installs Fumadocs in `apps/docs/` and seeds the Foundations / Primitives / Blocks information architecture. After pulling:
>
> 1. Run `pnpm install` (lock file changed)
> 2. Restart your TypeScript server in IDE (Cmd+Shift+P > "TypeScript: Restart TS Server")
>
> The docs site home is `http://localhost:3002/` (Fumadocs `loader()` uses `baseUrl: '/'` — no `/docs` URL prefix). Component MDX arrives starting Batch 1 (Button, Input, Badge, Select, Dialog, Sheet) — those PRs only add `apps/docs/content/docs/primitives/<component>.mdx`, no docs infra changes needed.
>
> Search uses built-in Orama (client-side, free, indexed at build). We can swap to Algolia/Inkeep later by replacing `apps/docs/src/app/api/search/route.ts`.
>
> Files that changed:
> - `apps/docs/package.json`
> - `apps/docs/next.config.ts`
> - `apps/docs/source.config.ts` (new)
> - `apps/docs/src/lib/source.ts` (new)
> - `apps/docs/src/app/layout.tsx`
> - `apps/docs/src/app/[[...slug]]/...` (new catch-all layout + page; placeholder `page.tsx` removed)
> - `apps/docs/src/app/api/search/route.ts` (new)
> - `apps/docs/content/docs/...` (new IA stubs)

---

## 7. What's Next

After Batch 0 is merged to dev, proceed to **Phase 3, Batch 1 — Button, Input, Badge, Select, Dialog, Sheet**. Each component graduating in Batch 1 now adds one MDX file under `apps/docs/content/docs/primitives/<component>.mdx` alongside its move into `packages/ui-v2/src/components/`. No docs-infrastructure work should be needed in Batch 1.

### Docs app reference (Cursor / Claude)

- **`apps/docs/AGENTS.md`** — canonical map for the docs app: content paths, `meta.json`, commands, token CSS import order, MDX tags vs shared building blocks, and how to register MDX-exposed components.
- **`src/components/mdx/` vs `src/components/shared/`** — MDX tag components live under `mdx/`; reusable internals used to compose them live under `shared/`. Only MDX-exposed components are listed in `custom-mdx-components.ts` (unless you intentionally expose a shared piece as a tag).
- **`apps/docs/src/mdx/custom-mdx-components.ts`** — typed registry (`satisfies MDXComponents`) merged into `get-mdx-components.tsx`; add new MDX components here instead of growing inline lists in `get-mdx-components.tsx`.

### Lessons to carry forward

- **`.source` directory must exist before type-check resolves `loader()`.** Run `pnpm dev` once after install so MDX scanning generates the directory; otherwise `src/lib/source.ts` shows a phantom missing-module error.
- **`baseUrl` in `loader()` is the contract for every URL Fumadocs emits.** This plan sets `baseUrl: '/'` so the public site has no `/docs` prefix. Changing it later requires updating breadcrumbs, sidebar links, search results, and route structure together.
- **`meta.json` `pages` array is the only sidebar ordering source.** Filename order does not influence display.

### Known lessons from prior phases

- **`include`/`exclude` in shared tsconfigs are dead code.** TypeScript resolves inherited `include`/`exclude` relative to the config that defines them, not the consumer. Every app must define its own locally.
- **`outDir` in shared tsconfigs resolves relative to the defining file.** Same as `include`/`exclude` — inherited `outDir: "dist"` from `library.json` resolves to `packages/tsconfig/dist`, not the consumer's `dist`. Every consumer must override `outDir` locally.
- **`.mjs` exports need `.d.mts` type declarations.** Any shared package exporting `.mjs` files must ship a paired `.d.mts` and use conditional `exports` with `"types"` in `package.json`.
- **Shared config packages use `peerDependencies`, not `devDependencies`.** `@sndq/config` declares ESLint/Prettier tools as `peerDependencies` with relaxed semver ranges. Each consumer app owns the exact pinned versions.
- **CSS `@import` order matters for token dependencies.** `tokens.css` (primitives) must load before `semantic-tokens.css` (references primitives), which must load before `components.css` (references semantic tokens).

---

## 8. Deferred: Usage Indexer Feature

A separate idea was discussed during planning: indexing every `sndq-fe` source file that imports `@/components/ui-v2` (or `@sndq/ui-v2`) and surfacing the call sites under each component's docs page, categorized by `src/modules/` vs `src/components/`.

**Status**: Deferred. Three open decisions need to be revisited once Fumadocs is live:

1. **Granularity** — file-level usage vs per-named-export (Button vs Dialog) usage.
2. **Update model** — regenerate on `main` only, on every PR that touches `sndq-fe`, on every docs build, or locally on demand.
3. **Single source of truth** — keep generated data inside `apps/docs/` only, or commit a machine-readable JSON at a neutral path so other tooling can consume it.

**Why deferred**: The right shape of those answers depends on what the live docs site reveals about navigation patterns, search behavior, and how component owners actually want to expose call sites. Decide after Batch 1 ships and we have at least one real component MDX with real readers.

**Tracked in**: this section. Re-open before Phase 3, Batch 2.

---

## Execution Log

Record notes, issues, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| 2026-05-04 | Platform | Next **16.2.4**, `eslint-config-next` **16.2.4**, Fumadocs **16.8.7** / MDX **14.3.2**, **zod 4**, Tailwind **4.2.4**, `postcss.config.mjs`, `global.css`, `collections/server` path, `@sndq/config` ESLint flat path for Next 16 |
|      | 1      | (Historical) Fumadocs install + source — superseded by platform row if applied in one step |
|      | 2      | Root layout + `RootProvider` + global CSS |
| 2026-05-04 | 3      | Root `[[...slug]]` + `DocsLayout` / `DocsPage`; removed placeholder `page.tsx`; restored `@sndq/config` ESLint Next-16 branch if lint broke |
|      | 4      |       |
|      | 5      |       |
| 2026-05-07 | 6      | Installed `@fumadocs/story@^0.0.14` in `apps/docs`. Created `src/lib/story.ts` factory (file-system cache in production via `.next/fumadocs-story`). Appended `@import '@fumadocs/story/css/preset.css';` after the existing Fumadocs UI presets in `global.css`. No tsconfig / next.config / MDX-registry changes needed. Build green. SHA: _to fill in after manual commit_. |
| 2026-05-07 | 7      | First Story shipped for `Text`. Added `apps/docs/src/stories/components/text.tsx` (`'use client'` re-export — keeps the package `Text` RSC-compatible) and `apps/docs/src/stories/text.story.tsx` (server component, exports `story = defineStory(import.meta.url, { Component: Text, args: { initial: { children, variant: 'body', size: 'sm' } } })`). Edited `text.mdx` to add `import { story } from '@/stories/text.story';` and one `<story.WithControl />` block above the existing inline preview grid; all `## Examples` JSX blocks left intact. Verification: `generate:source`, `type-check`, `build`, and lint on touched files all green; `/primitives/text` still in static export. SHA: _to fill in after manual commit_. |
