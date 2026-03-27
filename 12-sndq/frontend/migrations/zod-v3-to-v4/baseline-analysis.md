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
