# Fumadocs — Search

Search backends supported by Fumadocs and how to swap between them. The wire format is **one route file** (`app/api/search/route.ts`) that the client search dialog hits — what changes between backends is the implementation behind that route.

**Source**: [Fumadocs — Search (headless)](https://www.fumadocs.dev/docs/headless/search)

---

## Table of Contents

1. [How search is wired](#1-how-search-is-wired)
2. [Comparison matrix](#2-comparison-matrix)
3. [Built-in Orama (default)](#3-built-in-orama-default)
4. [Algolia](#4-algolia)
5. [Inkeep AI](#5-inkeep-ai)
6. [Swapping backends](#6-swapping-backends)
7. [What stays the same](#7-what-stays-the-same)

---

## 1. How search is wired

```
Client (RootProvider) ──Cmd+K──▶ /api/search?query=…
                                       │
                                       ▼
                            createFromSource(source)   ← swap target
                                       │
                                       ▼
                              Indexed pages (.source)
```

`RootProvider` (from `fumadocs-ui/provider`) ships the search dialog. By default it hits `/api/search`. The route file is the **only** file you change to switch backends.

---

## 2. Comparison matrix

| Backend | Indexing | Hosting | Cost | Privacy | Scale ceiling | Best for |
|---------|----------|---------|------|---------|---------------|----------|
| **Orama (built-in)** | Build-time, in-memory | Self (in your Next app) | Free | Local — index stays in your app | ~hundreds to a few thousand pages before bundle/perf concerns | Internal docs, MVPs, design systems with bounded content |
| **Algolia** | Hosted index, refresh on build | Algolia | Tiered SaaS (free dev tier; paid as records/queries grow) | Index lives on Algolia | Very large content sets, multi-site federation | Public sites at scale, rich filtering, analytics |
| **Inkeep AI** | Hosted, AI-augmented (semantic + LLM answers) | Inkeep | Paid SaaS | Index + queries on Inkeep | Large public docs that want chat-style answers | Sites needing AI-Q&A on top of search |

---

## 3. Built-in Orama (default)

Fumadocs ships an Orama adapter that indexes the same `source` your layout uses. Indexing happens at **build time** — no external service.

**Wiring** (the entire route file):

```ts
// app/api/search/route.ts
import { createFromSource } from 'fumadocs-core/search/server';
import { source } from '@/lib/source';

export const { GET } = createFromSource(source);
```

**Benefits**

- Zero infra, zero cost
- Works offline / on previews / on PRs
- Privacy by default (no third-party calls)
- Same `source` instance the layout uses — no extra schema to maintain

**Tradeoffs**

- Index ships in client bundle for client-side search → bundle grows with content
- Soft ceiling around mid-thousands of pages (depends on page size and queries)
- No semantic / typo tolerance beyond Orama defaults
- No analytics on what users search for

**Good fit when**: internal docs, component catalogs, anything bounded in size.

---

## 4. Algolia

Replace the default route with Algolia's adapter (sync at build, query against Algolia at runtime).

**Wiring sketch**:

```ts
// app/api/search/route.ts
import { createFromSource } from 'fumadocs-core/search/algolia';

export const { GET } = createFromSource({
  // Algolia client config (appId, search-only API key, indexName)
});
```

(The exact import path / signature follows the version of `fumadocs-core` you install — see the [search docs](https://www.fumadocs.dev/docs/headless/search).)

**Benefits**

- Hosted index → no in-bundle search code
- Mature **typo tolerance**, faceting, synonyms, A/B testing
- Search analytics out of the box
- Scales to very large content

**Tradeoffs**

- Paid SaaS once you exit the free tier
- Index must be **synced on build** (or on content change) — adds a build step + an Algolia API key in CI
- Search-only key in client code (Algolia's recommended pattern), admin key only in CI
- Privacy: queries leave your infrastructure

**Good fit when**: public docs at scale, multiple repos federating into one search, you want analytics.

---

## 5. Inkeep AI

Inkeep is an AI-augmented docs search/Q&A. Returns ranked snippets **plus** synthesized answers from your indexed pages.

**Benefits**

- Chat-style "ask the docs" UX on top of classic search
- Better recall on conversational queries ("how do I install on a Mac?")
- Same indexing model as Algolia (hosted)

**Tradeoffs**

- Paid SaaS (subscription tiers)
- Answer quality depends on your content — short / unstructured pages produce weak answers
- Adds an LLM dependency (latency, cost per query, hallucination surface)
- Privacy: queries and content leave your infrastructure

**Good fit when**: public docs where users ask questions you'd otherwise route to support.

---

## 6. Swapping backends

The change is **always the same shape**: replace the body of `app/api/search/route.ts` with the chosen adapter and add any required env vars.

```diff
- import { createFromSource } from 'fumadocs-core/search/server';
+ import { createFromSource } from 'fumadocs-core/search/algolia';

- export const { GET } = createFromSource(source);
+ export const { GET } = createFromSource({ /* algolia config */ });
```

A typical migration path:

1. **Phase 1** — Ship with built-in Orama. Validate IA, search UX, content quality.
2. **Phase 2** — Move to Algolia/Inkeep when (a) bundle grows past comfort, (b) users complain about typo tolerance / synonyms, or (c) you need analytics.

Treat Orama as the **MVP** and the hosted backends as a **scale/UX upgrade**, not a rewrite.

---

## 7. What stays the same

Across all three backends:

- **MDX content** — no changes to author-facing files
- **`source.config.ts`, `loader()`** — same content layer
- **`RootProvider`** — same client search dialog
- **Layout** — `DocsLayout` / `HomeLayout` / etc. unchanged
- **URLs** — page routes unchanged

Only the `/api/search/route.ts` body and any env vars / sync scripts move when you swap.
