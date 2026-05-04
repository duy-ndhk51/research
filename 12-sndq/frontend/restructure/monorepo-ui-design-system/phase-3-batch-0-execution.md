# Phase 3, Batch 0 Execution — Docs Infrastructure (Fumadocs)

Step-by-step execution guide for Phase 3, Batch 0. Each commit is independently verifiable and revertable.

**Created**: 2026-05-04
**Status**: Not started
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
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Deferred: Usage Indexer Feature](#7-deferred-usage-indexer-feature)

---

## 1. Overview

**Goal**: Install Fumadocs in the existing `apps/docs/` placeholder, wire client-side Orama search, and seed an empty Foundations / Primitives / Blocks information architecture — so that Batch 1 onwards only needs to author component MDX, not docs infrastructure.

**Structure**: 5 commits across 1 PR.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Fumadocs install + root provider + root catch-all layout + search API + IA stubs | Low | 1-5 |

**Why 1 PR**: The only consumer of `apps/docs/` is the docs app itself (a placeholder page at `/` until Commit 3 removes it in favor of an optional catch-all). No other workspace package or app reads from it, so the blast radius is contained. Each commit is still independently buildable so a partial revert remains an option during review.

### Prerequisites

- Phase 2 is merged to dev
- `apps/docs/` exists as a placeholder Next 15 App Router app (`apps/docs/src/app/page.tsx` placeholder at `/` — removed in Commit 3 when the catch-all owns `/`, plus `apps/docs/next.config.ts`, `apps/docs/tsconfig.json`)
- `@sndq/ui-v2` workspace dependency is already wired in `apps/docs/package.json`
- `apps/docs/next.config.ts` already declares `transpilePackages: ['@sndq/ui-v2']`

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

**What**: Add Fumadocs dependencies and the MDX content source config so subsequent commits can render and index content.

**Files to edit**:

- `apps/docs/package.json` — add `fumadocs-ui`, `fumadocs-core`, `fumadocs-mdx` dependencies
- `apps/docs/next.config.ts` — wrap with `withMDX()` from `fumadocs-mdx/next` while preserving `transpilePackages: ['@sndq/ui-v2']`

**Files to create**:

- `apps/docs/source.config.ts` — declare the docs content collection (path, schema)
- `apps/docs/src/lib/source.ts` — load the collection via `loader()` so layout and search routes share one source instance

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
import { defineDocs, defineConfig } from 'fumadocs-mdx/config';

export const docs = defineDocs({
  dir: 'content/docs',
});

export default defineConfig();
```

**Target `apps/docs/src/lib/source.ts`**:

```typescript
import { loader } from 'fumadocs-core/source';
import { docs } from '../../.source';

export const source = loader({
  baseUrl: '/',
  source: docs.toFumadocsSource(),
});
```

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

- **`Cannot find module '../../.source'`**: Run `pnpm --filter @sndq/docs run dev` once; the source directory is generated on first MDX scan. Then re-run build.
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

**What**: Replace the bare HTML body in the root layout with Fumadocs `RootProvider` and import its base styles, so all docs pages share theme + search context.

**Files to edit**:

- `apps/docs/src/app/layout.tsx` — wrap children in `<RootProvider>` and import `fumadocs-ui/style.css`

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
import 'fumadocs-ui/style.css';

import type { Metadata } from 'next';
import { RootProvider } from 'fumadocs-ui/provider';

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
      <body>
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

- **`Module not found: 'fumadocs-ui/style.css'`**: Confirm `fumadocs-ui` was installed in Commit 1 and re-check `apps/docs/node_modules/fumadocs-ui/`.
- **Hydration warning persists**: Confirm `suppressHydrationWarning` is on the `<html>` tag, not `<body>`.

**Commit message**: `feat(docs): wire fumadocs root provider in layout`

**Status**:

- [ ] `fumadocs-ui/style.css` imported
- [ ] `RootProvider` wraps children
- [ ] `suppressHydrationWarning` set on `<html>`
- [ ] Build passes
- [ ] Committed

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

- [ ] `[[...slug]]/layout.tsx` created
- [ ] `[[...slug]]/page.tsx` created
- [ ] Placeholder `src/app/page.tsx` deleted
- [ ] `generateStaticParams` exported
- [ ] Build passes
- [ ] Committed

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

- [ ] `api/search/route.ts` created
- [ ] `curl` to `/api/search?query=test` returns 200
- [ ] Build passes
- [ ] Committed

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

This section will cover:

- Color palette (`brand`, `neutral`, `success`, `warning`, `error`)
- Typography scale and font families
- Spacing and radius tokens
- Shadow and elevation

Pages will be added as the foundations are documented from `@sndq/config/tailwind/`.
```

**Target `apps/docs/content/docs/foundations/meta.json`**:

```json
{
  "title": "Foundations",
  "pages": ["index"]
}
```

**Target `apps/docs/content/docs/primitives/index.mdx`**:

```mdx
---
title: Primitives
description: Base components from @sndq/ui-v2 — Button, Input, Badge, Select, Dialog, and more.
---

Component pages arrive in **Phase 3, Batch 1** as components graduate from the
prototype into `@sndq/ui-v2`. See the
[migration plan](./migration-plan.md) for the batch schedule.
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

- [ ] Root `index.mdx` + `meta.json` created
- [ ] Foundations folder seeded
- [ ] Primitives folder seeded
- [ ] Blocks folder seeded
- [ ] Sidebar shows three categories in order
- [ ] Search returns results
- [ ] Build passes
- [ ] Committed

---

### PR 1 Checkpoint

Push your branch and wait for CI / Vercel preview build to pass before continuing.

```bash
git push -u origin <your-branch>
# Create PR targeting dev
# Wait for CI to complete successfully
```

**This validates**: Workspace install resolves the new Fumadocs deps, the docs app builds in CI with the generated `.source` directory, and the search API route is recognized by Next 15's app router in a CI environment.

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Merged (or ready to continue)

---

## 4. Final Verification

After all 5 commits, run the full suite from the monorepo root:

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

- [ ] All 5 commits complete
- [ ] Docs build passes from root
- [ ] Lint passes from root
- [ ] Type-check passes from root
- [ ] `sndq-fe` build output unchanged from baseline
- [ ] Visual check — home at `/`, sidebar, search all functional
- [ ] PR created and merged

---

## 5. Team Communication

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

## 6. What's Next

After Batch 0 is merged to dev, proceed to **Phase 3, Batch 1 — Button, Input, Badge, Select, Dialog, Sheet**. Each component graduating in Batch 1 now adds one MDX file under `apps/docs/content/docs/primitives/<component>.mdx` alongside its move into `packages/ui-v2/src/components/`. No docs-infrastructure work should be needed in Batch 1.

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

## 7. Deferred: Usage Indexer Feature

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
|      | 1      |       |
|      | 2      |       |
|      | 3      |       |
|      | 4      |       |
|      | 5      |       |
