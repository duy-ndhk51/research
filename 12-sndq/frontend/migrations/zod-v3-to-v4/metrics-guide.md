# Zod v4 Migration — Metrics & Measurement Guide

Comprehensive guide to measuring the performance impact of migrating `sndq-fe` from Zod v3 to Zod v4. Covers what metrics to track, exactly how to measure them, and the strategy for incremental measurement during a gradual file-by-file migration.

**Created**: 2026-03-27
**Related**: [Migration Plan](./README.md) · [Progress Tracker](./progress.md) · [Ticket Summary](./ticket.md)
**Record sheet**: [Metrics Record](./metrics-record.md) — fill in actual measurements here

---

## Table of Contents

- [Overview: What Zod v4 Actually Improves](#overview-what-zod-v4-actually-improves)
- [Three Impact Layers](#three-impact-layers)
- [Metric 1: TypeScript Compiler Diagnostics (PRIMARY)](#metric-1-typescript-compiler-diagnostics-primary)
- [Metric 2: TypeScript Trace Analysis (DEEP DEBUG)](#metric-2-typescript-trace-analysis-deep-debug)
- [Metric 3: Next.js Build Time (SECONDARY)](#metric-3-nextjs-build-time-secondary)
- [Metric 4: Bundle Size (SECONDARY)](#metric-4-bundle-size-secondary)
- [Metric 5: Migration Progress Counter (TRACKING)](#metric-5-migration-progress-counter-tracking)
- [Metric 6: Deprecated API Count (TRACKING)](#metric-6-deprecated-api-count-tracking)
- [Metric 7: Runtime Validation Performance (OPTIONAL)](#metric-7-runtime-validation-performance-optional)
- [All-in-One Measurement Script](#all-in-one-measurement-script)
- [Incremental Measurement Strategy](#incremental-measurement-strategy)
- [Bundle Size Behavior During Gradual Migration](#bundle-size-behavior-during-gradual-migration)
- [Reporting Template](#reporting-template)
- [Critical Caveats](#critical-caveats)
- [Priority Summary](#priority-summary)

---

## Overview: What Zod v4 Actually Improves

Zod v4 is a ground-up rewrite that affects **three separate layers** of a frontend application. Each layer has different metrics, different measurement tools, and different behavior during a gradual migration.

Understanding this is critical: **not all metrics improve linearly during gradual migration**. Some improve per-file, some only improve after full completion, and some temporarily regress in the middle.

---

## Three Impact Layers

| Layer | What Changes | Metric | Incremental? | When to Measure |
|-------|-------------|--------|-------------|-----------------|
| **TypeScript Compiler** | Simpler generics: `ZodType<Output, Input>` instead of `ZodType<Output, Def, Input>`. Fewer type instantiations per schema. | `tsc` Instantiations, Check time | **Yes** — improves per-file | Every batch |
| **Build & Bundle** | Better tree-shaking with top-level validators (`z.email()` vs `z.string().email()`). `ZodEffects` wrapper eliminated. | `next build` time, chunk sizes | **No** — temporarily worsens during dual-import, then improves | Start + End only |
| **Runtime** | New parsing engine: 14x string, 7x array, 6.5x object speedup (micro-benchmarks). | Form validation latency | **Yes** — each migrated form is faster | Optional / hard to measure |

### Key Insight for Gradual Migration

```
Metric behavior during gradual migration:

tsc Instantiations:  ████████████████░░░░  → Steadily decreases per batch ✓
tsc Check time:      ████████████████░░░░  → Steadily decreases per batch ✓
Bundle size:         ████████████████████████  → TEMPORARILY INCREASES then drops ⚠
Build time:          ████████████████████████  → TEMPORARILY INCREASES then drops ⚠
Runtime perf:        ████████████████░░░░  → Per-form improvement ✓
```

During gradual migration, both `"zod"` (v3 engine) and `"zod/v4"` (v4 engine) are imported. The bundler includes **both engines**, temporarily increasing bundle size and build time. This resolves once all files are on v4.

**This is why `tsc` diagnostics are the PRIMARY metric** — they improve monotonically with each migrated file and are not affected by the dual-import issue.

---

## Metric 1: TypeScript Compiler Diagnostics (PRIMARY)

**Priority**: P0 — This is the most important metric. Measure every batch.

### Why This Metric Is Best for Gradual Migration

Zod v4 simplifies its generic type signatures. Each schema file that switches from `"zod"` to `"zod/v4"` reduces the number of type instantiations TypeScript must resolve. This improvement is:

- **Monotonic** — each migrated file reduces Instantiations; never goes up
- **Deterministic** — not affected by CPU load, background processes, or caching
- **Directly caused by Zod** — not confounded by other code changes
- **Precisely measurable** — exact numbers from `tsc --diagnostics`

### How to Measure

```bash
cd sndq-fe

# CRITICAL: Delete incremental cache first.
# tsconfig.json has "incremental": true — if you don't delete the cache,
# tsc will skip unchanged files and report misleadingly low numbers.
rm -f tsconfig.tsbuildinfo

# Run diagnostics
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics --incremental false
```

### Output Explained

```
Files:            4532       ← Total .ts/.tsx files processed
Lines:            312847     ← Total lines of code
Identifiers:      298745     ← Variable/function/type names resolved
Symbols:          452381     ← Internal compiler symbols created
Types:            198234     ← Unique types resolved
Instantiations:   1847293    ← ⭐ KEY METRIC: Generic type instantiations
Memory used:      892431K    ← Peak memory during compilation
I/O read:         0.12s      ← File reading time (disk-bound)
I/O write:        0.00s      ← Not applicable (--noEmit)
Parse time:       2.41s      ← Tokenizing + AST building
Bind time:        0.92s      ← Scope analysis
Check time:       18.74s     ← ⭐ KEY METRIC: Type checking duration
Emit time:        0.00s      ← Not applicable (--noEmit)
Total time:       22.07s     ← ⭐ KEY METRIC: Full compilation
```

### The Three Numbers to Record

| Field | What It Means | Why Zod v4 Reduces It |
|-------|--------------|----------------------|
| **Instantiations** | Number of times TypeScript creates a concrete type from a generic template. E.g., `ZodType<string, ZodStringDef, string>` is one instantiation. | Zod v4 has fewer generic parameters (`ZodType<Output, Input>` vs `ZodType<Output, Def, Input>`). Each schema produces fewer instantiations. With 103 schema files each generating dozens of inferred types, the compound reduction is significant. |
| **Check time** | Wall-clock time spent resolving all type relationships. This is where 80%+ of `tsc` time goes. | Fewer Instantiations = less work = faster check. The relationship is roughly linear. |
| **Total time** | Parse + Bind + Check + Emit. Dominated by Check time. | Improves proportionally with Check time. |

### Measurement Protocol

To get reliable numbers, always follow this exact protocol:

1. **Close IDE** (or at least all open `.ts`/`.tsx` files) — some IDEs lock files or run background `tsc`
2. **Kill any running `next dev`** — dev server runs its own TypeScript checker
3. **Delete incremental cache**: `rm -f tsconfig.tsbuildinfo`
4. **Run 3 times** — record all 3, use the **median** (middle value)
5. **Same machine, same power state** — don't compare laptop-on-battery vs plugged-in

```bash
# Full measurement protocol
pkill -f "next dev" 2>/dev/null || true
rm -f tsconfig.tsbuildinfo

echo "=== Run 1 ==="
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics 2>&1 | \
  grep -E "Instantiations|Check time|Total time|Types|Memory"

rm -f tsconfig.tsbuildinfo
echo "=== Run 2 ==="
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics 2>&1 | \
  grep -E "Instantiations|Check time|Total time|Types|Memory"

rm -f tsconfig.tsbuildinfo
echo "=== Run 3 ==="
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics 2>&1 | \
  grep -E "Instantiations|Check time|Total time|Types|Memory"
```

### Why Instantiations Is Better Than Check Time

**Instantiations** is the single most precise metric because:

- It's a **count**, not a duration — immune to CPU speed, thermal throttling, background processes
- If Instantiations drops from 1,847,293 to 1,623,000 between batches, you know **exactly** that 224,293 type instantiations were eliminated by the migration
- Check time can fluctuate ±5-10% between runs even on the same code. Instantiations is deterministic (±0 between runs of identical code).

**Use Instantiations for reporting accuracy. Use Check time for "human-readable" impact (people understand "saved 3 seconds" better than "reduced 200K instantiations").**

---

## Metric 2: TypeScript Trace Analysis (DEEP DEBUG)

**Priority**: P3 — Only when you need to debug which specific file/type is the bottleneck.

### When to Use

- Before migration: identify which schema files contribute most to compile time
- If a batch doesn't produce expected improvement: find what's still slow
- For the migration plan report: produce flamechart visualizations

### How to Measure

```bash
cd sndq-fe
rm -f tsconfig.tsbuildinfo

# Generate trace files
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --generateTrace ./tsc-trace

# Output: ./tsc-trace/trace.json (+ types.json for symbol lookup)
```

### How to Analyze

1. Open [Perfetto UI](https://ui.perfetto.dev/) in Chrome
2. Drag and drop `./tsc-trace/trace.json`
3. Navigate the flamechart:
   - **Horizontal axis** = time
   - **Vertical stack** = file → function → type being resolved
   - Look for wide bars (slow files) and deep stacks (complex type resolution)

### What to Look For

- **Widest bars**: These are the files that take the longest to type-check. After migrating them to v4, these bars should shrink.
- **`checkExpression` calls on Zod schemas**: These are the type instantiations. Zod v4 reduces the depth of each.
- **`structuredTypeRelatedTo`**: This is where TypeScript compares types. Fewer generic parameters = fewer comparisons.

### Per-File Impact Analysis

To measure the exact impact of migrating a single file, run `--generateTrace` before and after:

```bash
# Before migrating patrimony/forms/lease/schema.ts
rm -f tsconfig.tsbuildinfo
npx tsc --noEmit --generateTrace ./tsc-trace-before-lease

# After changing import to "zod/v4"
rm -f tsconfig.tsbuildinfo
npx tsc --noEmit --generateTrace ./tsc-trace-after-lease

# Compare the lease/schema.ts bar width in Perfetto
```

---

## Metric 3: Next.js Build Time (SECONDARY)

**Priority**: P2 — Measure at start and end only. Not useful for incremental tracking.

### Why Not Incremental?

Next.js build includes: TypeScript checking + Webpack/Turbopack bundling + code splitting + optimization. During gradual migration, both Zod engines are bundled, so build time can temporarily increase. The improvement only appears once all files are on v4.

### How to Measure

```bash
cd sndq-fe

# CRITICAL: Delete all caches for clean measurement
rm -rf .next
rm -f tsconfig.tsbuildinfo

# Measure build time (real = wall-clock, user = CPU time)
time pnpm build 2>&1 | tee build-output.txt

# The `time` output shows:
# real    2m34.567s   ← Wall-clock time (this is what matters)
# user    4m12.345s   ← Total CPU time across all cores
# sys     0m23.456s   ← Kernel time
```

### What to Record

| Field | Where to Find | Notes |
|-------|--------------|-------|
| `real` time | `time` output | Primary: wall-clock build duration |
| Route sizes | `pnpm build` output table | Next.js prints per-route first-load JS size |
| Heaviest route | Same output | Identify the route with largest first-load JS |

### Expected Behavior

| Phase | Build Time Trend | Reason |
|-------|-----------------|--------|
| Baseline (100% v3) | Normal | Single Zod engine |
| Mid-migration (v3 + v4) | **+5-15% slower** | Both engines bundled; more code to process |
| Complete (100% v4) | **-10-20% faster** | Simpler types + better tree-shaking |
| Final (zod@4.x clean) | **-10-20% faster** | Same as above, cleaner imports |

---

## Metric 4: Bundle Size (SECONDARY)

**Priority**: P2 — Measure at start and end only. Same dual-import caveat as build time.

### How to Measure

Project does not have `@next/bundle-analyzer` installed, so use filesystem measurements:

```bash
cd sndq-fe

# After a clean build (rm -rf .next && pnpm build)

# 1. Total chunks size
du -sh .next/static/chunks/

# 2. Top 20 largest chunks
find .next/static/chunks -name "*.js" -exec du -sk {} \; | sort -rn | head -20

# 3. Zod-specific: find which chunk contains Zod
rg -l "ZodType\|ZodString\|ZodObject" .next/static/chunks/ 2>/dev/null | head -5

# 4. Size of the chunk containing Zod
for f in $(rg -l "ZodType\|ZodString" .next/static/chunks/ 2>/dev/null | head -3); do
  echo "$(du -sk "$f" | cut -f1)K  $f"
done
```

### Optional: Install Bundle Analyzer

For visual analysis (pie chart of bundle composition):

```bash
pnpm add -D @next/bundle-analyzer

# In next.config.ts, wrap the config:
# const withBundleAnalyzer = require('@next/bundle-analyzer')({ enabled: process.env.ANALYZE === 'true' });
# module.exports = withBundleAnalyzer(nextConfig);

# Then:
ANALYZE=true pnpm build
# Opens browser with interactive treemap
```

### Expected Behavior

| Phase | Bundle Size Trend | Reason |
|-------|------------------|--------|
| Baseline (100% v3) | Normal | Single Zod engine |
| Mid-migration | **+30-80 kB** | Both v3 and v4 engines included in bundle |
| Complete (100% v4) | **-15-30 kB vs baseline** | Better tree-shaking, `ZodEffects` eliminated |

---

## Metric 5: Migration Progress Counter (TRACKING)

**Priority**: P1 — Track continuously for reporting and motivation.

### How to Measure

```bash
cd sndq-fe

# Files already migrated to v4
MIGRATED=$(rg -l "from ['\"]zod/v4['\"]" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | wc -l | tr -d ' ')

# Files still on v3 (exclude test files and "zod/v4" lines)
REMAINING=$(rg -l "from ['\"]zod['\"]" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | \
  rg -v "zod/v4" | wc -l | tr -d ' ')

TOTAL=$((MIGRATED + REMAINING))
if [ "$TOTAL" -gt 0 ]; then
  PERCENT=$(echo "scale=1; $MIGRATED * 100 / $TOTAL" | bc)
else
  PERCENT="0"
fi

echo "Migrated: $MIGRATED / $TOTAL files ($PERCENT%)"
```

### Visual Progress Bar

```bash
# Generate ASCII progress bar
BAR_WIDTH=40
FILLED=$((MIGRATED * BAR_WIDTH / TOTAL))
EMPTY=$((BAR_WIDTH - FILLED))
printf "Progress: [%s%s] %s/%s (%s%%)\n" \
  "$(printf '█%.0s' $(seq 1 $FILLED 2>/dev/null) 2>/dev/null)" \
  "$(printf '░%.0s' $(seq 1 $EMPTY 2>/dev/null) 2>/dev/null)" \
  "$MIGRATED" "$TOTAL" "$PERCENT"
```

---

## Metric 6: Deprecated API Count (TRACKING)

**Priority**: P1 — Track per-batch to show migration completeness.

### How to Measure

```bash
cd sndq-fe

echo "=== Deprecated API Usage ==="

# nativeEnum (deprecated in v4, .Enum/.Values removed)
NATIVE_ENUM=$(rg -c 'nativeEnum' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | \
  cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)
echo "z.nativeEnum():     $NATIVE_ENUM usages"

# .Enum. accessor (removed in v4 — runtime crash)
DOT_ENUM=$(rg -c '\.Enum\.' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | \
  cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)
echo ".Enum. accessor:    $DOT_ENUM usages"

# .Values. accessor (removed in v4 — runtime crash)
DOT_VALUES=$(rg -c '\.Values\.' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | \
  cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)
echo ".Values. accessor:  $DOT_VALUES usages"

# required_error (removed in v4 — tsc error)
REQ_ERR=$(rg -c 'required_error' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | \
  cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)
echo "required_error:     $REQ_ERR usages"

# invalid_type_error (removed in v4 — tsc error)
INV_ERR=$(rg -c 'invalid_type_error' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | \
  cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)
echo "invalid_type_error: $INV_ERR usages"

TOTAL_DEPRECATED=$((NATIVE_ENUM + DOT_ENUM + DOT_VALUES + REQ_ERR + INV_ERR))
echo "---"
echo "TOTAL deprecated:   $TOTAL_DEPRECATED usages"
```

---

## Metric 7: Runtime Validation Performance (OPTIONAL)

**Priority**: P3 — Nice-to-have but hard to measure accurately in a real app.

### Why This Is Optional

The 14x/7x/6.5x speedup numbers come from **isolated micro-benchmarks** (`z.string().parse("hello")` called 1 million times). In a real form:

- Zod parsing typically takes **<1ms** per form submission
- The total form interaction time is dominated by React re-renders (10-50ms), API calls (100-2000ms), and UI animations
- Users cannot perceive a 0.1ms → 0.01ms improvement

**This metric is useful for internal reporting ("validation is 10x faster") but not for user-facing UX impact claims.**

### How to Measure (If Desired)

Create a benchmark test file:

```typescript
// src/__tests__/zod-perf-benchmark.test.ts
import { describe, it, expect } from 'vitest';
import { z } from 'zod'; // or 'zod/v4' after migration

// Import your actual heaviest schema
import { leaseFormSchema } from '@/modules/patrimony/forms/lease/schema';

const ITERATIONS = 10_000;

const validInput = {
  // ... complete valid fixture for leaseFormSchema
};

describe('Zod parsing performance', () => {
  it(`parses leaseFormSchema ${ITERATIONS} times`, () => {
    const start = performance.now();
    for (let i = 0; i < ITERATIONS; i++) {
      leaseFormSchema.safeParse(validInput);
    }
    const elapsed = performance.now() - start;
    const perParse = elapsed / ITERATIONS;

    console.log(`Total: ${elapsed.toFixed(1)}ms`);
    console.log(`Per parse: ${perParse.toFixed(4)}ms`);
    console.log(`Parses/sec: ${(1000 / perParse).toFixed(0)}`);

    // Sanity check — should complete within reasonable time
    expect(elapsed).toBeLessThan(30_000);
  });
});
```

Run before and after migration:

```bash
# Before (v3)
pnpm test src/__tests__/zod-perf-benchmark.test.ts

# After changing schema import to "zod/v4"
pnpm test src/__tests__/zod-perf-benchmark.test.ts
```

---

## All-in-One Measurement Script

A single script that captures all metrics at once. Run before migration and after each batch.

```bash
#!/bin/bash
# measure-zod-migration.sh
# Usage: bash measure-zod-migration.sh [label]
# Examples:
#   bash measure-zod-migration.sh "baseline"
#   bash measure-zod-migration.sh "after-batch-1"
#   bash measure-zod-migration.sh "after-batch-2"
#   bash measure-zod-migration.sh "final"

set -euo pipefail

LABEL=${1:-"snapshot"}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTFILE="metrics-${LABEL}-${TIMESTAMP}.txt"

cd sndq-fe

echo "=============================================" | tee "$OUTFILE"
echo " Zod Migration Metrics: $LABEL" | tee -a "$OUTFILE"
echo " Date: $(date)" | tee -a "$OUTFILE"
echo " Machine: $(uname -n)" | tee -a "$OUTFILE"
echo "=============================================" | tee -a "$OUTFILE"
echo "" | tee -a "$OUTFILE"

# --- Section 1: Migration Progress ---
echo "--- 1. Migration Progress ---" | tee -a "$OUTFILE"

MIGRATED=$(rg -l "from ['\"]zod/v4['\"]" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | wc -l | tr -d ' ')
TOTAL_ZOD=$(rg -l "from ['\"]zod" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | sort -u | wc -l | tr -d ' ')

echo "Files on zod/v4: $MIGRATED" | tee -a "$OUTFILE"
echo "Total zod files: $TOTAL_ZOD" | tee -a "$OUTFILE"
if [ "$TOTAL_ZOD" -gt 0 ]; then
  echo "Progress:        $(echo "scale=1; $MIGRATED * 100 / $TOTAL_ZOD" | bc)%" | tee -a "$OUTFILE"
fi
echo "" | tee -a "$OUTFILE"

# --- Section 2: Deprecated API Counts ---
echo "--- 2. Deprecated APIs ---" | tee -a "$OUTFILE"

count_usage() {
  rg -c "$1" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0
}

NATIVE_ENUM=$(count_usage 'nativeEnum')
DOT_ENUM=$(count_usage '\.Enum\.')
DOT_VALUES=$(count_usage '\.Values\.')
REQ_ERR=$(count_usage 'required_error')
INV_ERR=$(count_usage 'invalid_type_error')

echo "z.nativeEnum():     $NATIVE_ENUM" | tee -a "$OUTFILE"
echo ".Enum. accessor:    $DOT_ENUM" | tee -a "$OUTFILE"
echo ".Values. accessor:  $DOT_VALUES" | tee -a "$OUTFILE"
echo "required_error:     $REQ_ERR" | tee -a "$OUTFILE"
echo "invalid_type_error: $INV_ERR" | tee -a "$OUTFILE"
echo "TOTAL deprecated:   $((NATIVE_ENUM + DOT_ENUM + DOT_VALUES + REQ_ERR + INV_ERR))" | tee -a "$OUTFILE"
echo "" | tee -a "$OUTFILE"

# --- Section 3: TypeScript Diagnostics (3 runs) ---
echo "--- 3. tsc --diagnostics (3 runs, use median) ---" | tee -a "$OUTFILE"

# Kill any running dev server that might interfere
pkill -f "next dev" 2>/dev/null || true
sleep 1

for i in 1 2 3; do
  echo "" | tee -a "$OUTFILE"
  echo "Run $i:" | tee -a "$OUTFILE"
  rm -f tsconfig.tsbuildinfo
  NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics 2>&1 | \
    grep -E "Types|Instantiations|Memory|Check time|Total time" | tee -a "$OUTFILE"
done

echo "" | tee -a "$OUTFILE"

# --- Section 4: Test suite status ---
echo "--- 4. Test Suite ---" | tee -a "$OUTFILE"
SCHEMA_TESTS=$(find src -name "*.test.ts" -o -name "*.test.tsx" 2>/dev/null | wc -l | tr -d ' ')
SNAP_FILES=$(find src -name "*.snap" 2>/dev/null | wc -l | tr -d ' ')
echo "Test files:     $SCHEMA_TESTS" | tee -a "$OUTFILE"
echo "Snapshot files: $SNAP_FILES" | tee -a "$OUTFILE"
echo "" | tee -a "$OUTFILE"

echo "=============================================" | tee -a "$OUTFILE"
echo "Saved to: $OUTFILE"
echo ""
echo "TIP: For build time + bundle size (slow), run separately:"
echo "  rm -rf .next && time pnpm build"
echo "  du -sh .next/static/chunks/"
```

### Usage

```bash
# Before starting migration
bash measure-zod-migration.sh "baseline"

# After completing Batch 1 (13 transform files)
bash measure-zod-migration.sh "after-batch-1"

# After completing Batch 2 (~30 nativeEnum files)
bash measure-zod-migration.sh "after-batch-2"

# After completing Batch 3 (~27 error customization files)
bash measure-zod-migration.sh "after-batch-3"

# After completing Batch 4 (remaining simple files)
bash measure-zod-migration.sh "after-batch-4"

# After switching to zod@4.x and reverting imports
bash measure-zod-migration.sh "final"
```

All results are saved as timestamped text files for historical comparison.

---

## Incremental Measurement Strategy

### When to Measure What

| Checkpoint | tsc diagnostics | Build time | Bundle size | Progress count | Deprecated APIs |
|------------|:-:|:-:|:-:|:-:|:-:|
| **Baseline** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **After Batch 1** (13 transform) | ✅ | ⬜ | ⬜ | ✅ | ✅ |
| **After Batch 2** (~30 nativeEnum) | ✅ | ⬜ | ⬜ | ✅ | ✅ |
| **After Batch 3** (~27 error) | ✅ | ⬜ | ⬜ | ✅ | ✅ |
| **After Batch 4** (remaining) | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Final** (zod@4.x) | ✅ | ✅ | ✅ | ✅ | ✅ |

Legend: ✅ = Measure · ⬜ = Skip (not meaningful during dual-import phase)

### Recording Table

Copy this table and fill in after each measurement:

| Checkpoint | Date | Files on v4 | Instantiations | Check time (ms) | Total time (ms) | Memory (MB) | Deprecated APIs |
|------------|------|-------------|----------------|-----------------|-----------------|-------------|-----------------|
| Baseline | | 0/103 | | | | | |
| After Batch 1 | | 13/103 | | | | | |
| After Batch 2 | | ~43/103 | | | | | |
| After Batch 3 | | ~70/103 | | | | | |
| After Batch 4 | | 103/103 | | | | | |
| Final (zod@4.x) | | 103/103 | | | | | |

### Build & Bundle (Start + End Only)

| Checkpoint | `next build` time | `.next/static/chunks/` | Heaviest route first-load JS |
|------------|-------------------|------------------------|------------------------------|
| Baseline | | | |
| Final (zod@4.x) | | | |
| Delta | | | |
| % Change | | | |

---

## Bundle Size Behavior During Gradual Migration

This is the most counter-intuitive aspect of the gradual migration. Understanding it prevents false alarms.

### Why Bundle Size Temporarily Increases

```
package: zod@3.25.76
├── /node_modules/zod/lib/       ← v3 engine (~45 kB minified)
└── /node_modules/zod/lib/v4/    ← v4 engine (~35 kB minified)
```

When any file imports `from "zod"` (v3) AND any other file imports `from "zod/v4"` (v4), the bundler includes **both** engines. The total Zod contribution to the bundle is ~80 kB instead of ~45 kB.

```
Timeline:

Baseline:     [===== v3 (45 kB) =====]                    Total: ~45 kB
Mid-migration: [===== v3 (45 kB) =====][==== v4 (35 kB) ====]  Total: ~80 kB ⚠
All on v4:    [==== v4 (35 kB) ====]                       Total: ~35 kB ✓
```

### Implications

- **Do NOT report bundle size during mid-migration** — it will show a regression
- **Do NOT let this discourage migration** — the increase is temporary
- **Only compare baseline vs. final** for accurate bundle impact reporting
- **The v4 engine is smaller** (~35 kB vs ~45 kB) due to eliminated `ZodEffects` and better tree-shaking

---

## Reporting Template

Use this template for Slack/Jira updates after each batch:

```markdown
## Zod Migration — Batch [N] Complete

**Files migrated**: [X]/103 ([Y]%)
**This batch**: [N files] — [batch description]

### TypeScript Compiler Impact
| Metric | Baseline | Current | Delta |
|--------|----------|---------|-------|
| Instantiations | [N] | [N] | -[N] ([X]%) |
| Check time | [N]ms | [N]ms | -[N]ms ([X]%) |

### Deprecated APIs Remaining
- nativeEnum: [N]
- required_error / invalid_type_error: [N]
- Total: [N] (down from [baseline])

### Notes
- [Any issues encountered]
- [Any decisions made]
```

---

## Critical Caveats

### 1. Always Delete `tsconfig.tsbuildinfo` Before Measuring

The `sndq-fe` project has `"incremental": true` in `tsconfig.json`. This creates a cache file that lets `tsc` skip unchanged files on subsequent runs. For measurement, you need a **full** check, so always delete the cache:

```bash
rm -f tsconfig.tsbuildinfo
```

If you forget, you'll see artificially low Total time and Check time because `tsc` is reusing cached results.

### 2. Run 3 Times and Use the Median

`tsc` execution time varies ±5-10% between runs due to:
- CPU thermal throttling (especially on laptops)
- macOS background processes (Spotlight indexing, Time Machine, etc.)
- Node.js garbage collection timing
- File system cache state

**Instantiations is NOT affected** (it's a count, not a duration). Always report both Instantiations (exact) and Check time (median of 3 runs).

### 3. Don't Compare Measurements from Different Machines

Battery vs. plugged-in, different RAM, different CPU — all affect timing. Always measure on the same machine in the same conditions.

### 4. Kill Dev Server Before Measuring

`next dev` runs its own TypeScript checker. Having it running simultaneously affects:
- Memory available for `tsc`
- CPU contention
- File system lock contention

```bash
pkill -f "next dev" 2>/dev/null || true
sleep 2  # Wait for process to fully exit
```

### 5. Runtime Performance Claims Need Caution

The 14x/7x/6.5x numbers are **micro-benchmark results**, not real-app measurements. In a real form submission:

- Network latency: 100-2000ms
- React re-renders: 10-50ms
- Zod validation: 0.1-2ms

Zod being 14x faster means going from 0.5ms to 0.035ms — invisible to the user. **Claim TypeScript compilation speedup, not runtime UX improvement.**

### 6. Some Code Changes (Non-Zod) Can Affect Metrics

If you or teammates push other changes between measurements, the delta might not be purely from Zod migration. Ideally, measure right before and after the migration commit on the same branch with no other changes.

---

## Priority Summary

| Priority | Metric | Why | Measure When |
|----------|--------|-----|-------------|
| **P0** | `tsc` Instantiations | Exact count, deterministic, directly caused by Zod generics simplification. Best for proving migration value. | Every batch |
| **P0** | `tsc` Check time (median of 3) | Human-readable compilation speedup. "Saved X seconds on every type-check." | Every batch |
| **P1** | Migration progress (files migrated) | Tracking & motivation. Shows team velocity. | Every file/batch |
| **P1** | Deprecated API count | Shows code modernization progress. Target: 0. | Every batch |
| **P2** | `next build` time | Overall build improvement. Only meaningful start vs. end. | Start + end |
| **P2** | Bundle size (chunks/) | Bundle reduction from better tree-shaking. Only meaningful start vs. end. | Start + end |
| **P3** | `tsc --generateTrace` | Deep debugging. Per-file flame chart in Perfetto UI. | When debugging |
| **P3** | Runtime validation perf | Micro-benchmark. Not user-perceptible. Nice for reports. | Optional |

---

## References

- [TypeScript Performance Wiki — Using `--diagnostics`](https://github.com/microsoft/TypeScript/wiki/Performance#using---diagnostics)
- [TypeScript Performance Wiki — Using `--generateTrace`](https://github.com/microsoft/TypeScript/wiki/Performance#using---generatetrace)
- [Perfetto UI](https://ui.perfetto.dev/) — Trace visualization tool
- [Zod v4 Changelog](https://zod.dev/v4/changelog) — Performance claims and benchmarks
- [Migration Plan](./README.md) — Full breaking changes catalog and risk analysis
- [Migration Progress Tracker](./progress.md) — Per-file checklists and metrics dashboard
- [Ticket Summary](./ticket.md) — Concise version for task tracking
