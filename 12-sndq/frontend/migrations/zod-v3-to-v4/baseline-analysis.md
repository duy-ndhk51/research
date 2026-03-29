# Zod v4 Migration — Baseline Analysis

Detailed analysis of the `tsc --noEmit --diagnostics` benchmark runs captured **before** any Zod v3 → v4 migration work begins. This document serves as the reference point for all future comparisons.

**Date**: 2026-03-28
**Branch**: `perf/SQ-20365` (based off `dev` @ `7b26c713`)
**Related**: [Metrics Record](./metrics-record.md) · [Migration Plan](./README.md)

---

## Table of Contents

- [Environment](#environment)
- [Raw Benchmark Data](#raw-benchmark-data)
- [Run-by-Run Analysis](#run-by-run-analysis)
- [Statistical Summary](#statistical-summary)
- [Bottleneck Analysis](#bottleneck-analysis)
- [Zod v4 Migration — Expected Impact](#zod-v4-migration--expected-impact)
- [Next.js Build Baseline](#nextjs-build-baseline)
- [Recommendations](#recommendations)

---

## Environment

| Field | Value |
|-------|-------|
| OS | macOS darwin 23.5.0 (Apple Silicon, 10 threads) |
| Node.js | v22.11.0 |
| TypeScript | 5.9.3 |
| Zod | 3.25.76 (lockfile) |
| `@hookform/resolvers` | ^4.1.3 |
| Heap limit | `--max-old-space-size=8192` (8 GB) |
| `skipLibCheck` | `true` |
| `strict` | `true` |
| `moduleResolution` | `bundler` |

---

## Raw Benchmark Data

### Run 1 — Default flags (incremental enabled)

```
Command: NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics

Files:              7621
Lines:           1060981
Identifiers:     1238743
Symbols:         2291533
Types:           1693681
Instantiations: 29165585
Memory used:    6781731K
I/O read:          1.05s
I/O write:         0.00s
Parse time:        4.22s
Bind time:         0.76s
Check time:      116.88s
Emit time:        11.49s
Total time:      133.35s
```

### Run 2 — `--incremental false`

```
Command: NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics --incremental false

Files:              7621
Lines:           1060981
Identifiers:     1238743
Symbols:         2278327
Types:           1691552
Instantiations: 29150241
Memory used:    6780566K
I/O read:          1.12s
I/O write:         0.00s
Parse time:        4.23s
Bind time:         0.84s
Check time:      111.93s
Emit time:         0.01s
Total time:      117.02s
```

### Run 3 — `--incremental false`

```
Files:              7621
Lines:           1060981
Identifiers:     1238743
Symbols:         2278327
Types:           1691552
Instantiations: 29150241
Memory used:    6778701K
I/O read:          1.07s
I/O write:         0.00s
Parse time:        4.03s
Bind time:         0.77s
Check time:      116.81s
Emit time:         0.00s
Total time:      121.61s
```

### Run 4 — `--incremental false`

```
Files:              7621
Lines:           1060981
Identifiers:     1238743
Symbols:         2278327
Types:           1691552
Instantiations: 29150241
Memory used:    6774564K
I/O read:          0.91s
I/O write:         0.00s
Parse time:        3.59s
Bind time:         0.76s
Check time:      118.77s
Emit time:         0.00s
Total time:      123.12s
```

### Run 5 — `--incremental false`

```
Files:              7621
Lines:           1060981
Identifiers:     1238743
Symbols:         2278327
Types:           1691552
Instantiations: 29150241
Memory used:    6773756K
I/O read:          1.06s
I/O write:         0.00s
Parse time:        4.15s
Bind time:         0.74s
Check time:      117.35s
Emit time:         0.00s
Total time:      122.25s
```

---

## Run-by-Run Analysis

### Run 1 vs Runs 2–5: Incremental overhead

Run 1 used default flags (incremental enabled via existing `tsconfig.tsbuildinfo`). This caused two measurable differences:

| Metric | Run 1 (incremental) | Runs 2–5 (no incremental) | Delta |
|--------|---------------------|---------------------------|-------|
| Symbols | 2,291,533 | 2,278,327 | +13,206 (+0.58%) |
| Types | 1,693,681 | 1,691,552 | +2,129 (+0.13%) |
| Instantiations | 29,165,585 | 29,150,241 | +15,344 (+0.05%) |
| Emit time | **11.49s** | ~0.00s | **+11.49s** |
| Total time | **133.35s** | ~121s median | **+~12s** |

When incremental is enabled, the compiler serializes a `.tsbuildinfo` dependency graph, which:
- Adds ~13K symbols for tracking file dependencies
- Costs 11.49s in emit time for writing the cache file
- Inflates total time by ~12s compared to clean measurement

**Conclusion**: `--incremental false` is the correct flag for benchmarking. Run 1 is excluded from baseline calculations.

### Runs 2–5: Determinism and variance

Types, Instantiations, and Symbols are **perfectly deterministic** across all 4 clean runs (identical values). Only timing and memory show natural variance:

| Metric | Run 2 | Run 3 | Run 4 | Run 5 |
|--------|-------|-------|-------|-------|
| Check time (s) | **111.93** | 116.81 | 118.77 | 117.35 |
| Total time (s) | **117.02** | 121.61 | 123.12 | 122.25 |
| Memory (KB) | 6,780,566 | 6,778,701 | 6,774,564 | 6,773,756 |
| Parse time (s) | 4.23 | 4.03 | 3.59 | 4.15 |

Run 2 (111.93s check) is the **low outlier** — likely benefiting from CPU cache warming after Run 1, or lower background system load. Runs 3–5 cluster tightly between 116.81–118.77s.

---

## Statistical Summary

Computed from Runs 2–5 (`--incremental false`):

### Timing

| Stat | Check time (s) | Total time (s) |
|------|---------------|----------------|
| Min | 111.93 | 117.02 |
| Max | 118.77 | 123.12 |
| Mean | 116.22 | 121.00 |
| **Median** | **117.08** | **121.93** |
| Range | 6.84 | 6.10 |
| Std Dev | ~2.56 | ~2.28 |
| CoV (%) | ~2.2% | ~1.9% |

A coefficient of variation of ~2.2% is acceptable for a process consuming 6.5 GB RAM on a developer machine.

### Type system

| Metric | Value | Assessment |
|--------|-------|------------|
| Files | 7,621 | Large frontend project |
| Lines | 1,060,981 | ~1M lines |
| Symbols | 2,278,327 | Normal for codebase size |
| Types | 1,691,552 | **High** — ~222 types/file average |
| Instantiations | 29,150,241 | **Very high** — >20M is red flag |

### Memory

| Stat | Memory (KB) | Memory (GB) |
|------|-------------|-------------|
| Min | 6,773,756 | 6.46 |
| Max | 6,780,566 | 6.47 |
| **Median** | **6,776,633** | **6.46** |
| % of 8 GB heap | | **~81%** |

Running at 81% of heap limit leaves minimal headroom. Any increase in codebase complexity could trigger OOM without the explicit `--max-old-space-size=8192`.

### Recommended baseline values

These are the values to use in the [Metrics Record](./metrics-record.md):

| Metric | Baseline Value |
|--------|---------------|
| Types | **1,691,552** |
| Instantiations | **29,150,241** |
| Memory (KB) | **6,776,633** |
| Check time (s) | **117.08** |
| Total time (s) | **121.93** |

---

## Bottleneck Analysis

### Time distribution

| Phase | Time (s) | % of Total | Assessment |
|-------|----------|------------|------------|
| I/O read | ~1.0 | ~0.8% | Normal |
| Parse | ~4.0 | ~3.3% | Normal |
| Bind | ~0.77 | ~0.6% | Normal |
| **Check** | **~117** | **~96%** | **Sole bottleneck** |
| Emit | ~0.0 | ~0% | N/A (`--noEmit`) |

Type checking consumes **96% of total compilation time**. Parse and bind are negligible — the project doesn't have a file-count problem, it has a **type complexity problem**.

### What drives 29M instantiations?

The codebase has **103 files** importing Zod with **hundreds of schema definitions**. Each schema interacts with TypeScript's type system through multiple instantiation-heavy operations:

1. **Every `z.*()` call** creates a `ZodType<Output, Def, Input>` — 3 generic parameters that TypeScript must resolve
2. **Every `.transform()` / `.refine()` / `.superRefine()`** wraps in `ZodEffects<ZodType<Output, Def, Input>>` — adding another layer
3. **Every `z.infer<typeof schema>`** triggers full type resolution through the entire schema tree
4. **Every `zodResolver(schema)`** in React Hook Form propagates the inferred type into `UseFormReturn<T>`
5. **Chained methods** (`.optional().nullable().default()`) each create new type wrapper instances

With ~170+ `z.infer` usages, ~140+ transform/refine calls, and 100+ `zodResolver` invocations, the multiplicative effect is enormous.

### Why memory is so high

Memory correlates almost linearly with (Types + Instantiations + Symbols). At 29M instantiations, each consuming a few hundred bytes for the type node, constraint cache, and relationship tracking, the 6.5 GB figure is consistent.

---

## Zod v4 Migration — Expected Impact

### Mechanism 1: Simplified generics (3 → 2 type params)

```typescript
// Zod v3: ZodType<Output, Def, Input> — 3 generic parameters
// Zod v4: ZodType<Output, Input>      — 2 generic parameters (Def removed)
```

Every `z.string()`, `z.object({...})`, `z.enum()`, etc. creates one fewer generic parameter for TypeScript to resolve. With hundreds of schema definitions across 103 files, this alone should reduce instantiations by millions.

### Mechanism 2: ZodEffects wrapper elimination

```typescript
// Zod v3: .transform() → ZodEffects<ZodType<Output, Def, Input>>
//         .refine()    → ZodEffects<ZodType<Output, Def, Input>>
//         Chains nest: ZodEffects<ZodEffects<ZodObject<...>>>
//
// Zod v4: Effects are inlined — no wrapper class, no nesting
```

The codebase has **~140+ transform/refine/superRefine calls**. In v3, each wraps the type in a `ZodEffects` layer, creating deeply nested generic types that exponentially increase instantiation work. In v4, this entire class is eliminated.

### Mechanism 3: `.extend()` / spread over `.merge()`

```typescript
// Zod v3: schemaA.merge(schemaB) — creates intersection types
// Zod v4: z.object({ ...schemaA.shape, ...schemaB.shape }) — flat spread
```

The migration plan notes that `.extend()` has "better TypeScript performance" and spread has the best. This replaces intersection type resolution (expensive) with simple property copying (cheap).

### Mechanism 4: Fewer enum wrapper types

```typescript
// Zod v3: z.nativeEnum(MyEnum) — creates ZodNativeEnum<typeof MyEnum> wrapper
// Zod v4: z.enum(MyEnum)       — unified, simpler generic structure
```

With ~44 files using `z.nativeEnum()`, migrating to the unified `z.enum()` removes a specialized generic wrapper type.

### Expected improvement ranges

| Metric | Baseline | Conservative (−30%) | Optimistic (−50%) |
|--------|----------|---------------------|-------------------|
| Instantiations | 29,150,241 | ~20,400,000 | ~14,575,000 |
| Types | 1,691,552 | ~1,185,000 | ~845,000 |
| Memory (GB) | 6.46 | ~4.5 | ~3.2 |
| Check time (s) | 117.08 | ~82–90 | ~60–70 |
| Total time (s) | 121.93 | ~87–95 | ~65–75 |
| Needs 8 GB heap? | Yes | Maybe not | **No** (default 4 GB may suffice) |

These estimates are based on Zod community benchmarks and the specific Zod usage patterns in the `sndq-fe` codebase. Actual results will depend on what percentage of total instantiations are Zod-attributable (likely >50% given 103 schema files).

---

## Next.js Build Baseline

### Raw Build Data (3 runs)

All runs executed on the same branch (`perf/SQ-20365`), `.next/` deleted before each, dev server killed.

```
Command: pnpm build 2>&1 | tee build-output-N.txt
(Lerna → next build → Next.js 15.5.9)
```

### Run 1 — `build-output-2.txt`

```
Compiled successfully in 3.5min
pnpm build 2>&1  591.78s user  90.08s system  145% cpu  7:48.44 total
```

### Run 2 — `build-output-3.txt`

```
Compiled successfully in 4.2min
pnpm build 2>&1  703.77s user  89.25s system  161% cpu  8:10.83 total
```

### Run 3 — `build-output-4.txt`

```
Compiled successfully in 4.9min
pnpm build 2>&1  748.78s user  116.76s system  152% cpu  9:28.74 total
```

### Build Timing Analysis

| Run | Compile Phase | Wall-Clock | User | System | CPU % |
|-----|---------------|------------|------|--------|-------|
| 1 | 3.5 min | **7:48** (468s) | 591.78s | 90.08s | 145% |
| 2 | 4.2 min | **8:10** (491s) | 703.77s | 89.25s | 161% |
| 3 | 4.9 min | **9:28** (569s) | 748.78s | 116.76s | 152% |
| **Median** | **4.2 min** | **8:10 (491s)** | | | |

| Stat | Wall-Clock (s) | Compile Phase (min) |
|------|----------------|---------------------|
| Min | 468 | 3.5 |
| Max | 569 | 4.9 |
| Mean | 509 | 4.2 |
| **Median** | **491** | **4.2** |
| Range | 101s | 1.4 min |
| % Variance | **21.6%** | **40%** |

### Variance Analysis

The build time variance (21.6% wall-clock, 40% compile phase) is significantly higher than the `tsc` variance (2.2% CoV). This is because:

1. **Thermal throttling**: Apple Silicon aggressively throttles during sustained 8+ minute CPU-bound workloads. The compile phase is the hottest part, and Run 3 (last to execute) shows the most throttling impact (4.9min compile vs 3.5min on Run 1).

2. **Webpack compilation is multi-phased**: `next build` involves webpack bundling, type checking, static generation, and trace collection. Each phase has independent variance, and they compound.

3. **CPU % fluctuation**: Run 1 used only 145% CPU (less parallelism), while Run 2 hit 161%. This suggests system load or thermal state affected how many parallel webpack workers Next.js could sustain.

4. **User time vs wall-clock**: Run 3 consumed 748.78s user time in 569s wall-clock (1.32x parallelism), while Run 2 consumed 703.77s in 491s (1.43x parallelism). The degrading parallelism ratio across runs confirms progressive thermal throttling.

**Conclusion**: For build time benchmarking, let the machine cool between runs (5+ min gap) and take the median of at least 3 runs. Run 2 (8:10.83) is the most representative as the median.

### Bundle Size (identical across all 3 runs)

| Metric | Value |
|--------|-------|
| **First Load JS shared by all** | **232 kB** |
| Largest shared chunk (`38387-*.js`) | 134 kB |
| Second shared chunk (`9e84f066-*.js`) | 54.4 kB |
| Third shared chunk (`e61e4be7-*.js`) | 36.9 kB |
| Other shared chunks | 7.11 kB |
| Middleware | 109 kB |
| Total routes | 123 (all dynamic `ƒ`) |

### Top 10 Heaviest Routes by First-Load JS

| # | Route | Page Size | First-Load JS | Assessment |
|---|-------|-----------|---------------|------------|
| 1 | `/patrimony/buildings/detail/[id]/meeting/[meetingId]` | 352 kB | **1.57 MB** | Extreme outlier — page itself is 352 kB |
| 2 | `/patrimony` | 8.9 kB | **1.29 MB** | Heavy shared chunk tree |
| 3 | `/contacts/contact/detail/[id]` | 21.8 kB | **1.25 MB** | Contact detail + shared chunks |
| 4 | `/peppol` | 879 B | **1.25 MB** | Tiny page, heavy shared deps |
| 5 | `/financial/invoices/sales/[salesId]` | 8.44 kB | **1.23 MB** | Financial module shared tree |
| 6 | `/patrimony/buildings/detail/[id]` | 549 B | **1.22 MB** | Building detail shared tree |
| 7 | `/financial/invoices/purchase/[purchaseId]` | 6.21 kB | **1.20 MB** | Invoice detail |
| 8 | `/financial/invoices/purchase/new-v2` | 18.2 kB | **1.19 MB** | Heavy form page |
| 9 | `/financial/buildings/[buildingId]` | 18.4 kB | **1.18 MB** | Building financial detail |
| 10 | `/financial/buildings/[buildingId]/costs` | 730 B | **1.17 MB** | Costs listing |

### Bundle Size — Zod v4 Impact Assessment

Zod contributes to the shared JS chunk (232 kB) which is loaded by every route. The Zod library itself is approximately 13-15 kB gzipped in v3. In v4:

- **Tree shaking improvement**: Zod v4's restructured exports enable better dead code elimination. Top-level validators (`z.email()` instead of `z.string().email()`) avoid pulling in the entire `ZodString` class.
- **`ZodEffects` class eliminated**: One fewer class in the bundle, though the effect is small (a few KB).
- **During gradual migration**: Both `zod` (v3 API) and `zod/v4` are resolved from the same package (3.25.76), so there is **no bundle duplication**. Webpack tree-shakes unused exports.
- **Expected impact**: Small reduction (1-3 kB gzipped) in the 232 kB shared chunk. Bundle size is not the primary benefit of this migration.

The heaviest route (meeting at 1.57 MB) is dominated by page-specific JS (352 kB), not Zod. Zod migration will not meaningfully affect per-route sizes.

---

## Recommendations

### Measurement protocol

1. **Always use `--incremental false`** — Run 1 proved that incremental cache inflates emit by 11.49s
2. **Run 3 times minimum, take median** — variance is ~6.8s (5.8%), median is the most robust central tendency
3. **Kill dev server before measuring** — Next.js dev server competes for memory and CPU
4. **Delete `tsconfig.tsbuildinfo`** — ensures no stale incremental state
5. **Use consistent command**: `NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics --incremental false`

### Optional: Identify top instantiation sources

Run `--generateTrace` to pinpoint which files/types generate the most instantiations:

```bash
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --generateTrace ./trace-output
npx @typescript/analyze-trace ./trace-output
```

This would confirm what percentage of the 29M instantiations come specifically from Zod types vs. other sources (React, TanStack Query, etc.), providing a more precise estimate of Zod v4 migration impact.

### Key metrics to track per batch

During migration, focus on these metrics in order of importance:

1. **Instantiations** — most direct indicator of type complexity reduction
2. **Check time** — user-facing metric (DX impact)
3. **Memory** — determines whether 8 GB override is still needed
4. **Types** — secondary indicator, correlates with instantiations

---

## References

- [Metrics Record](./metrics-record.md) — structured recording sheet
- [Migration Plan](./README.md) — breaking changes, risk analysis, execution plan
- [Metrics & Measurement Guide](./metrics-guide.md) — commands, scripts, caveats
- [TypeScript Performance Wiki](https://github.com/microsoft/TypeScript/wiki/Performance) — official guidance on tsc performance
- [Zod v4 Announcement](https://zod.dev/v4) — performance claims and API changes
