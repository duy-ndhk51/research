# Next.js Build OOM Optimization Guide — sndq-fe

**Created**: 2026-04-08
**Updated**: 2026-04-08 (added `--experimental-debug-memory-usage` analysis)
**Context**: After the RHF + resolvers v5 + zodResolver wrapper upgrade, `tsc --noEmit` memory dropped 56.5% (6.46 GB → 2.81 GB), but `next build` still OOMs at ~3.95 GB with default Node.js heap limit (~4 GB). A debug build with 8 GB heap reveals the full memory profile.
**Related**: [Zod v4 Migration](../migrations/zod-v3-to-v4/README.md) | [Resolver Wrapper Report](../migrations/zod-v3-to-v4/resolver-wrapper-report.md)

---

## Table of Contents

- [Problem](#problem)
- [Build Memory Profile](#build-memory-profile)
  - [Environment](#environment)
  - [Memory Timeline](#memory-timeline)
  - [Peak Statistics](#peak-statistics)
  - [GC Pressure Analysis](#gc-pressure-analysis)
  - [Phase-by-Phase Breakdown](#phase-by-phase-breakdown)
- [Analysis: Good and Bad](#analysis-good-and-bad)
  - [Good Observations](#good-observations)
  - [Bad Observations](#bad-observations)
- [Bundle Output Analysis](#bundle-output-analysis)
  - [Shared Chunks](#shared-chunks)
  - [Route Size Distribution](#route-size-distribution)
  - [Top 10 Heaviest Routes](#top-10-heaviest-routes)
  - [Prototype Routes in Production](#prototype-routes-in-production)
- [Root Cause](#root-cause)
- [Immediate Fix](#immediate-fix)
- [Diagnostic Tools](#diagnostic-tools)
- [Optimization Strategy](#optimization-strategy)
  - [Priority Matrix](#priority-matrix)
  - [P0: Immediate (< 5 minutes)](#p0-immediate--5-minutes)
  - [P1: Quick Wins (< 1 day)](#p1-quick-wins--1-day)
  - [P2: Medium Effort (1-2 days)](#p2-medium-effort-1-2-days)
  - [P3: Future / When Stable](#p3-future--when-stable)
- [CI Pipeline Recommendations](#ci-pipeline-recommendations)
- [References](#references)

---

## Problem

Running `pnpm build` (via lerna -> `next build`) crashes with OOM when using the default Node.js heap limit (~4 GB):

```
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
Mark-Compact 3946.9 (4112.0) -> 3818.6 (4014.0) MB
```

The crash occurs during the webpack compilation phase — before "Compiled successfully" or "Checking validity of types" appears. The process peaked at ~3.95 GB heap usage, exhausting the default limit.

Key observation: `tsc --noEmit` (standalone type-checker) uses only 2.81 GB after the zodResolver wrapper improvement, but `next build` exceeds 4 GB because it combines webpack bundling, type-checking, Sentry processing, and route compilation into a single Node.js process.

---

## Build Memory Profile

### Environment

| Field | Value |
|-------|-------|
| Date | 2026-04-08 |
| Branch | `chore/SQ-20642` |
| Node.js | v22.13.1 |
| Next.js | 15.5.9 |
| Heap Max | 8,240 MB (`--max-old-space-size=8192`) |
| Command | `NODE_OPTIONS="--max-old-space-size=8192" next build --experimental-debug-memory-usage` |
| Build script | `"build:debug"` in `package.json` |

### Memory Timeline

Captured via `--experimental-debug-memory-usage`. Each row is a snapshot from the Next.js memory reporter.

| Phase | Heap Used (MB) | Heap Allocated (MB) | RSS (MB) | % Heap Used | Notes |
|-------|---------------|---------------------|----------|-------------|-------|
| Starting build | 80 | 102 | 232 | 0.97% | Clean start |
| Webpack (snapshot 1) | 1,145 | 1,190 | 1,429 | 13.90% | Ramping up |
| Webpack (snapshot 2) | 1,979 | 2,052 | 2,340 | 24.02% | Still growing |
| Webpack (snapshot 3) | 1,753 | 2,427 | 2,838 | 21.28% | GC reclaimed some |
| Webpack (snapshot 4) | 3,826 | 3,938 | 3,906 | 46.44% | Near peak heap |
| **Webpack (snapshot 5)** | **3,794** | **4,652** | **6,258** | **46.04%** | **PEAK RSS: 6.96 GB** |
| Webpack (snapshot 6) | 3,795 | 4,426 | 6,201 | 46.06% | Sustained pressure |
| Webpack (post-cache) | 1,938 | 3,175 | 5,055 | 23.52% | GC recovered after webpack cache write |
| Webpack (snapshot 8) | 2,409 | 3,103 | 5,502 | 29.23% | Re-growing |
| Webpack (snapshot 9) | 3,085 | 3,194 | 5,634 | 37.43% | Climbing |
| Webpack (snapshot 10) | 3,500 | 4,928 | 6,962 | 42.48% | Near second RSS peak |
| Webpack (snapshot 11) | 4,132 | 4,839 | 6,068 | 50.14% | Over 50% |
| **Compiled (4.4 min)** | **4,329** | **4,959** | **3,736** | **52.53%** | **PEAK HEAP: 4.33 GB** |
| Finished build | 4,329 | 4,959 | 3,736 | 52.53% | Same as compiled |
| Post-build snapshot | 4,330 | 4,959 | 1,590 | 52.54% | RSS drops, heap retained |
| **After major GC** | **1,248** | **3,197** | **3,458** | **15.14%** | **Huge GC recovery: -3,082 MB** |
| Type checking done | 1,248 | 3,197 | 3,457 | 15.14% | Lightweight phase |
| Page data collected | 1,271 | 3,168 | 3,652 | 15.42% | Stable |
| Static pages (124/124) | 1,599 | 3,077 | 3,841 | 19.41% | Minor bump |
| Build traces | 1,372 | 3,004 | 3,909 | 16.66% | Winding down |

### Peak Statistics

| Metric | Value |
|--------|-------|
| **Peak heap used** | **4,330 MB (4.23 GB)** |
| **Peak RSS** | **6,962 MB (6.80 GB)** |
| **Peak heap allocated** | 4,959 MB (4.84 GB) |
| **Total GC time** | **21,672 ms (21.7 seconds)** |
| RSS-to-heap gap at peak | 2,632 MB (V8 overhead, native buffers, webpack internals) |
| Compile phase duration | 4.4 min |
| Total routes compiled | 174 (all dynamic `f`) |

### GC Pressure Analysis

The build triggered **40+ long-running GC warnings**. Notable pauses:

| GC Duration | Phase | Impact |
|------------|-------|--------|
| **1,222 ms** | After "Finished build" | Over 1 second freeze — worst pause |
| **507 ms** | During webpack compilation | Half-second pause during critical path |
| **229 ms** | After "Finished build" | |
| **200 ms** | After "Finished build" | |
| **175 ms** | During webpack compilation | |
| **142 ms** | During webpack compilation | |
| **114 ms** | During webpack compilation | |
| 15-87 ms | Throughout (30+ instances) | Frequent minor pauses |

**Total GC time: 21.7 seconds** out of the total build. This represents the time the process spent doing nothing but reclaiming memory. A 1.2-second GC pause means the build was completely frozen for over a second while V8 desperately tried to free memory.

The GC pattern reveals two distinct memory pressure regimes:
1. **During webpack compilation**: frequent 15-115 ms pauses as webpack constantly allocates and discards module graphs
2. **After "Finished build"**: three massive GC pauses (1,222 ms + 229 ms + 200 ms = 1.65 seconds) as V8 reclaims the huge webpack allocation (~4.3 GB → 1.2 GB)

### Phase-by-Phase Breakdown

```
Memory (GB)
  7 ┤
    │                          ▲ RSS 6.96 GB
  6 ┤      ╭──────────────────╮
    │     ╱                    ╲
  5 ┤    ╱                      ╲───────────────────────╮
    │   ╱                                                ╲
  4 ┤  ╱    ▲ Heap 4.33 GB                               ╲
    │ ╱     ╭─────────────╮                                ╲
  3 ┤╱     ╱               ╲                                ╲
    │     ╱                 ╲                                 ╲───
  2 ┤    ╱                   ╲                                │
    │   ╱                     ╲                               │
  1 ┤──╱                       ╲──────────────────────────────╯
    │                                                ▲ Heap 1.25 GB
  0 ┤─────────────────────────────────────────────────────────────
    └─────┬───────────┬──────────┬──────┬─────┬──────┬────────┬──
       Start    Webpack      Compiled   GC   Type   Pages   Done
                                      drop  check
```

The critical insight: **webpack compilation is the sole memory crisis**. It drives heap to 4.33 GB and RSS to 6.96 GB. After a massive GC drop, every subsequent phase (type checking, page generation, static pages, build traces) runs comfortably at 1.2-1.6 GB.

---

## Analysis: Good and Bad

### Good Observations

1. **Build completes successfully with 8 GB heap** — 4.4 min compile time, within baseline range (3.5-4.9 min). No regression from the zodResolver wrapper refactor.

2. **No bundle size regression** — First Load JS shared by all routes is **233 kB**, identical to the baseline measured on 2026-03-28. The shared chunk breakdown is unchanged:
   - `38387-*.js`: 134 kB
   - `9e84f066-*.js`: 54.4 kB
   - `e61e4be7-*.js`: 36.9 kB
   - Other: 7.34 kB

3. **Type-checking phase is now lightweight** — after webpack finishes at 4,329 MB, the "Checking validity of types" phase runs at only **1,248 MB**. This confirms the zodResolver wrapper's -57.9% instantiation reduction directly benefits the build's type-checking phase. Before the wrapper, this phase alone would have required ~4+ GB (29.15M instantiations at 6.46 GB standalone).

4. **Memory recovers well between phases** — after compilation peaks at 4.3 GB, a single major GC reclaims 3,082 MB. The phases don't stack their memory requirements.

5. **Heap never exceeds 53% of limit** — with 8 GB heap, the build peaks at 52.53%. There is comfortable headroom. The OOM only occurs with the default ~4 GB limit.

6. **174 routes all compile successfully** — including 124 static page generations.

### Bad Observations

1. **Peak RSS: 6.96 GB** — the process needs nearly 7 GB of physical memory. The heap is 4.3 GB, but RSS is 6.96 GB. The 2.6 GB gap represents V8 internal overhead, native `Buffer` allocations, webpack's native module resolution cache, and memory-mapped files. Any machine with < 8 GB available RAM will struggle.

2. **Peak heap: 4.33 GB** — this is why the default ~4 GB limit causes OOM. webpack compilation alone consumes this much.

3. **GC time: 21.7 seconds** — 2.8% of build time spent on garbage collection alone. The 1.2-second GC pause is particularly concerning for CI environments where builds run alongside other processes.

4. **Long GC pauses indicate sustained memory pressure** — the webpack phase constantly allocates and frees objects. V8's garbage collector runs 40+ times with pauses > 15 ms. This is a sign that webpack is working near the memory ceiling even with 8 GB available.

5. **174 routes, all dynamic** — every route requires full webpack compilation. No routes are statically determined, meaning webpack must analyze the complete dependency tree for each one.

6. **~30 prototype routes compiled in production** — routes like `/prototype/building-switch`, `/prototype/cost-flow`, `/prototype/notary-flow`, etc. add compilation overhead without production value. These account for ~17% of total routes.

7. **80+ routes exceed 1 MB first-load JS** — most application routes have first-load JS between 1.03-1.35 MB. This indicates large shared dependency chains being pulled into nearly every route.

8. **The meeting route is 1.59 MB** — `/patrimony/buildings/detail/[id]/meeting/[meetingId]` has 352 kB page-specific JS plus shared chunks. This is by far the heaviest single page.

9. **RSS-to-heap gap: 2.6 GB** — the 2.6 GB difference between RSS and heap at peak represents memory that V8 cannot GC away (native allocations, Buffers, etc.). This is "invisible" memory that grows with webpack's module graph size.

---

## Bundle Output Analysis

### Shared Chunks

| Chunk | Size | Notes |
|-------|------|-------|
| `38387-*.js` | 134 kB | Largest shared chunk — likely contains React, react-dom, and core UI library |
| `9e84f066-*.js` | 54.4 kB | Second largest — possibly next-intl or routing |
| `e61e4be7-*.js` | 36.9 kB | Third — possibly Zod, form utilities, or state management |
| Other shared chunks | 7.34 kB | Small utilities |
| **Total shared** | **233 kB** | **Identical to baseline** |
| Middleware | 109 kB | Auth/routing middleware |

### Route Size Distribution

| First-Load JS Range | Route Count | % of Total | Examples |
|--------------------|------------|-----------|---------|
| < 300 kB | ~15 | 9% | Login, prototype placeholders, API routes |
| 300-600 kB | ~20 | 11% | Auth pages, simple forms, settings pages |
| 600 kB - 1 MB | ~10 | 6% | Medium-complexity pages |
| **1 MB - 1.1 MB** | **~50** | **29%** | **Most application routes** |
| 1.1 MB - 1.3 MB | ~60 | 34% | Financial detail pages, contact pages |
| **> 1.3 MB** | **~19** | **11%** | **Patrimony, peppol, financial invoices** |

The majority of routes (74%) are between 1-1.3 MB first-load JS. This suggests a large shared dependency tree that nearly every route pulls in. The bundle analyzer would reveal exactly which libraries contribute to this ~1 MB floor.

### Top 10 Heaviest Routes

| # | Route | Page JS | First Load JS |
|---|-------|---------|---------------|
| 1 | `/patrimony/buildings/detail/[id]/meeting/[meetingId]` | 352 kB | **1.59 MB** |
| 2 | `/patrimony` | 8.91 kB | **1.35 MB** |
| 3 | `/peppol` | 2.72 kB | **1.31 MB** |
| 4 | `/financial/buildings/[buildingId]/invoices/peppol/[invoiceId]` | 2.64 kB | **1.31 MB** |
| 5 | `/financial/buildings/[buildingId]/bookkeeping/accounts` | 17.4 kB | **1.30 MB** |
| 6 | `/financial/invoices/sales/[salesId]` | 8.46 kB | **1.28 MB** |
| 7 | `/contacts/contact/detail/[id]` | 22.5 kB | **1.28 MB** |
| 8 | `/financial/invoices/purchase/[purchaseId]` | 778 B | **1.25 MB** |
| 9 | `/financial/buildings/[buildingId]` | 21.1 kB | **1.24 MB** |
| 10 | `/patrimony/buildings/detail/[id]` | 552 B | **1.24 MB** |

The meeting route is the clear outlier with 352 kB page-specific JS. All others have small page-specific JS (< 25 kB) but inherit 1.2+ MB of shared chunks, confirming the shared dependency tree is the primary driver.

### Prototype Routes in Production

These routes exist for internal testing/demos but compile in every production build:

| Route Pattern | Count | Page JS Range | Production Value |
|---------------|-------|---------------|------------------|
| `/prototype/broadcast-content-type/*` | 7 | 1.18-3.19 kB | None |
| `/prototype/building-switch/*` | 2 | 478-758 B | None |
| `/prototype/chart-of-accounts-flow/*` | 2 | 486-739 B | None |
| `/prototype/cost-flow/*` | 2 | 519 B - 1.79 kB | None |
| `/prototype/cost-settlement-flow/*` | 2 | 483-743 B | None |
| `/prototype/dashboard-flow/*` | 2 | 354-761 B | None |
| `/prototype/financial-flow/*` | 2 | 354 B - 1.21 kB | None |
| `/prototype/financial-setup/*` | 2 | 482-749 B | None |
| `/prototype/notary-flow/*` | 4 | 480-811 B | None |
| `/prototype/notes-improvement/*` | 4 | 1.76-14 kB | None |
| `/prototype/payment-flow/*` | 2 | 484-813 B | None |
| `/prototype/supplier-flow/*` | 2 | 478-780 B | None |
| `/prototype` (index) | 1 | 20.7 kB | None |
| **Total** | **~34** | | **0% production value** |

34 prototype routes = **~20% of all 174 routes** being compiled without any production benefit. Each route adds to webpack's dependency graph resolution, chunk analysis, and memory usage.

---

## Root Cause

`next build` runs **multiple heavy workloads in a single Node.js process**:

| Workload | Heap Impact | Phase |
|----------|-------------|-------|
| **Webpack compilation** | **80 MB → 4,330 MB** | Resolves, bundles, and tree-shakes the entire dependency graph (135 deps, 7,845 files, 174 routes) |
| **Webpack cache serialization** | Sustained pressure | Two big string serializations (185 kB + 139 kB) noted in warnings |
| **Sentry processing** | Unknown (embedded in webpack) | `widenClientFileUpload: true` + `reactComponentAnnotation: { enabled: true }` adds AST transforms |
| **next-intl plugin** | Unknown (embedded in webpack) | Translation file processing |
| Major GC recovery | 4,330 MB → 1,248 MB | V8 reclaims webpack allocations |
| **TypeScript type-checking** | **1,248 MB** | "Checking validity of types" — lightweight after zodResolver wrapper |
| **Page data collection** | 1,271 MB | Stable, minor |
| **Static page generation** | 1,599 MB | 124 pages, minor bump |
| **Build trace collection** | 1,372 MB | Stable |

The **webpack compilation phase is responsible for 100% of the memory crisis**. It peaks at 4.33 GB heap / 6.96 GB RSS. Every phase after it runs comfortably at 1.2-1.6 GB.

The default Node.js heap limit (~4 GB) cannot accommodate the webpack peak. The process OOMs during compilation.

---

## Immediate Fix

### Set NODE_OPTIONS for all build commands

```bash
NODE_OPTIONS="--max-old-space-size=8192" pnpm build
```

To make this permanent, update `sndq-fe/package.json`:

```json
"scripts": {
  "build": "NODE_OPTIONS='--max-old-space-size=8192' next build"
}
```

Or, if the monorepo runs builds via lerna, set the env var at the CI/script level so it propagates to child processes.

---

## Diagnostic Tools

### 1. Identify the phase that OOMs

Check the build output for the last message before the crash:
- Crash before "Compiled successfully" → webpack compilation is the bottleneck
- Crash at "Checking validity of types" → TypeScript type-checking is the bottleneck
- Crash after "Compiled" → route optimization or Sentry upload

### 2. Next.js memory debugging (Next.js 15+)

```bash
NODE_OPTIONS="--max-old-space-size=8192" next build --experimental-debug-memory-usage
```

Prints heap usage at each build phase. Already captured — see [Build Memory Profile](#build-memory-profile) above.

### 3. Bundle analyzer (already installed)

`@next/bundle-analyzer` is wired up in `next.config.ts`:

```bash
ANALYZE=true NODE_OPTIONS="--max-old-space-size=8192" pnpm build
```

Generates an interactive treemap showing what's in each chunk. Look for:
- Duplicate libraries bundled multiple times
- Massive dependencies that could be lazy-loaded
- Server-only code leaking into client bundles

### 4. Webpack memory profiling

```bash
NODE_OPTIONS="--max-old-space-size=8192 --heapsnapshot-signal=SIGUSR2" next build &
BUILD_PID=$!
# Send signal at suspected peak to capture heap snapshot
kill -USR2 $BUILD_PID
# Analyze the .heapsnapshot file in Chrome DevTools -> Memory tab
```

---

## Optimization Strategy

### Priority Matrix

| # | Action | Complexity | Impact | Est. Time | Priority |
|---|--------|-----------|--------|-----------|----------|
| 1 | Add `NODE_OPTIONS` to build script | Trivial | Fixes OOM | 2 min | **P0** |
| 2 | Add `typescript: { ignoreBuildErrors: true }` | Trivial | Saves ~1 min + memory | 2 min | **P0** |
| 3 | Make Sentry features CI-only | Low | Reduces local build memory + time | 10 min | **P1** |
| 4 | Exclude prototype routes from production | Low | Eliminates 34 routes (20%) from compilation | 30 min | **P1** |
| 5 | Run bundle analyzer and document findings | Low | Identifies dedup/splitting targets | 1 hour | **P1** |
| 6 | Lazy-load tiptap, recharts, pdf-lib, firebase | Medium | Reduces shared chunk sizes and webpack graph | 2-4 hours | **P2** |
| 7 | Investigate the meeting route (1.59 MB) | Medium | Reduces heaviest route by splitting | 1-2 hours | **P2** |
| 8 | Evaluate Turbopack production builds | Low | Potential 50%+ memory reduction | 1 hour | **P3** |

### P0: Immediate (< 5 minutes)

#### 1. Hardcode `NODE_OPTIONS` in package.json

Prevents OOM for every developer and CI run:

```json
"build": "NODE_OPTIONS='--max-old-space-size=8192' next build"
```

**Reason**: the build peaks at 4.33 GB heap / 6.96 GB RSS. The default ~4 GB heap limit is insufficient. This is the only change that fixes the OOM without any other optimization.

#### 2. Skip type-checking during build

The build runs "Checking validity of types" after webpack. Since `pnpm type-check` runs separately in CI, this phase is redundant:

```typescript
// next.config.ts
const nextConfig: NextConfig = {
  typescript: {
    ignoreBuildErrors: true,
  },
  // ... existing config
};
```

**Reason**: the memory debug shows type-checking at 1,248 MB — not the bottleneck, but it adds ~1 min to build time for zero value when CI runs `pnpm type-check` as a separate step. It also means the build process can release webpack memory sooner.

### P1: Quick Wins (< 1 day)

#### 3. Make Sentry features CI-only

Both `widenClientFileUpload` and `reactComponentAnnotation` add overhead. Sentry's own docs state `widenClientFileUpload` "increases build time":

```typescript
// next.config.ts — in withSentryConfig options
widenClientFileUpload: process.env.CI === 'true',
reactComponentAnnotation: {
  enabled: process.env.CI === 'true',
},
```

**Reason**: `reactComponentAnnotation` runs AST transforms on every React component during webpack compilation — exactly the phase that peaks at 4.33 GB. Disabling it locally reduces both memory and time.

#### 4. Exclude prototype routes from production

34 prototype routes (20% of all routes) compile in every production build with zero production value. Options:

**Option A: Environment-based exclusion (simplest)**

Move prototype routes to a separate directory and conditionally include:

```
app/(prototype)/  → only compiled when INCLUDE_PROTOTYPES=true
```

Use `next.config.ts` `redirects` to return 404 for `/prototype/*` in production.

**Option B: Build-time removal**

Add a `prebuild` script that temporarily moves `app/prototype/` out of the build path and restores it after.

**Option C: Route group with conditional layout**

Use Next.js route groups to isolate prototypes. The prototype layout can check an env var and return a 404 page in production.

**Reason**: each route adds to webpack's dependency graph. 34 fewer routes means webpack processes a smaller graph, allocates less memory, and spends less time in chunk analysis. Even with small page JS, each route still triggers full shared chunk resolution.

#### 5. Run bundle analyzer

```bash
ANALYZE=true NODE_OPTIONS="--max-old-space-size=8192" pnpm build
```

**What to look for**:
- Which libraries appear in the 134 kB shared chunk (`38387-*.js`)
- Whether any library is duplicated across multiple chunks
- Whether server-only code (e.g., Node.js APIs, database clients) appears in client bundles
- What creates the ~1 MB floor that 80+ routes share

**Reason**: 74% of routes are between 1-1.3 MB first-load JS. The shared dependency tree creates this floor. The analyzer will reveal exactly which libraries contribute and which are candidates for lazy-loading.

### P2: Medium Effort (1-2 days)

#### 6. Lazy-load heavy dependencies

From `package.json`, these libraries are large and likely imported at high levels in the component tree:

| Library | Approx Size | Where Used | Lazy-load Strategy |
|---------|-------------|------------|-------------------|
| 20x `@tiptap/*` | ~200 KB | Rich text editor (broadcasts, notes, inbox) | `next/dynamic` — only pages with editors |
| `recharts` | ~150 KB | Dashboard charts, financial reports | `next/dynamic` — only chart-containing pages |
| `react-pdf` + `pdf-lib` | ~300 KB | PDF viewer/editor (invoices, documents) | `next/dynamic` — only document pages |
| `firebase` | ~200 KB | Auth, notifications, realtime | Import specific submodules: `firebase/auth`, `firebase/messaging` |
| `@ai-sdk/react` + `ai` | ~100 KB | AI agent page | `next/dynamic` — only `/ai-agent` |
| `react-signature-canvas` | ~30 KB | Signature capture (lease signing) | `next/dynamic` — only signing pages |

Example implementation:

```typescript
import dynamic from 'next/dynamic';

const RichTextEditor = dynamic(
  () => import('@/components/editor/RichTextEditor'),
  { loading: () => <Skeleton className="h-64" /> },
);
```

**Reason**: if any of these are imported at a layout level or in a widely-used component, they enter the shared chunks that every route loads. Moving them to dynamic imports reduces both the shared chunk size (improving page load) and webpack's compilation workload (fewer modules to analyze per chunk, reducing peak memory).

#### 7. Investigate the meeting route (1.59 MB)

`/patrimony/buildings/detail/[id]/meeting/[meetingId]` has **352 kB page-specific JS** — more than any other route by a factor of 10x. The next heaviest page-specific JS is ~38 kB.

Likely causes:
- Meeting agenda editor (tiptap instance with full toolbar)
- Participant management with RSVP and voting
- Resolution tracking and PDF generation
- Real-time collaboration (socket.io or firebase)

**Action**: run the bundle analyzer scoped to this route and identify which imports contribute to the 352 kB. The page likely bundles libraries that other routes lazy-load or don't use at all.

**Reason**: reducing this one route's page-specific JS from 352 kB to ~30 kB (in line with other routes) would eliminate significant webpack analysis work. The route likely pulls in tiptap, recharts, react-pdf, or firebase directly rather than through dynamic imports.

### P3: Future / When Stable

#### 8. Evaluate Turbopack production builds

Next.js 15.5+ has experimental Turbopack support for production. The dev server already uses Turbopack (`next dev --turbopack`). Turbopack uses a Rust-based bundler with fundamentally different memory characteristics — it doesn't share Node.js heap limits.

```bash
next build --turbopack  # experimental in Next.js 15.5
```

**Reason**: this could eliminate the OOM problem entirely since Rust processes manage their own memory outside the V8 heap. But it's still experimental for production builds and may have edge cases with Sentry plugin (`withSentryConfig`), `next-intl` plugin (`createNextIntlPlugin`), and custom webpack config.

**When**: monitor the [Next.js Turbopack status](https://nextjs.org/docs/architecture/turbopack). Test in a separate branch when all project plugins are confirmed compatible.

---

## CI Pipeline Recommendations

```bash
# Always set NODE_OPTIONS for any process touching the full codebase
export NODE_OPTIONS="--max-old-space-size=8192"

# Step 1: Type-check (separate process)
pnpm type-check

# Step 2: Lint (separate process)
pnpm lint:check

# Step 3: Build (with Sentry features enabled, type-check skipped)
CI=true pnpm build

# Step 4: Tests
pnpm test
```

Key principles:
- **Always set `NODE_OPTIONS`** for type-check, build, and lint — they all touch the full codebase
- **Run type-check separately** from build — if `ignoreBuildErrors: true` is set, the build skips its own type-check phase, saving ~1 min and memory
- **Enable Sentry features only in CI** — `widenClientFileUpload` and `reactComponentAnnotation` add overhead that isn't needed locally
- **CI machine needs >= 8 GB RAM** — peak RSS is 6.96 GB, so the CI runner must have at least 8 GB available

---

## References

- [Next.js Memory Usage](https://nextjs.org/docs/app/building-your-application/optimizing/memory-usage) — official guide for reducing memory in large apps
- [Next.js Turbopack](https://nextjs.org/docs/architecture/turbopack) — Rust-based bundler status
- [Sentry Next.js Manual Setup](https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/) — source map and build options
- [Node.js --max-old-space-size](https://nodejs.org/api/cli.html#--max-old-space-sizesize-in-megabytes) — heap limit configuration
- [Webpack Bundle Analyzer](https://github.com/vercel/next.js/tree/canary/packages/next-bundle-analyzer) — `@next/bundle-analyzer` usage
- [Resolver Wrapper Report](../migrations/zod-v3-to-v4/resolver-wrapper-report.md) — why tsc memory dropped 56.5% (zodResolver wrapper)
- [Metrics Record](../migrations/zod-v3-to-v4/metrics-record.md) — baseline and after-prerequisite tsc measurements
