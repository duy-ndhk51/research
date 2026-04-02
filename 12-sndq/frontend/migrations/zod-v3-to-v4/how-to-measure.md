# How to Measure — After Migrating a Batch

Practical step-by-step runbook for capturing improvement metrics after successfully migrating a batch of forms from Zod v3 to v4 in `sndq-fe`.

**When to use**: After you finish migrating a batch of files (not after every single file).
**Where to record**: [metrics-record.md](./metrics-record.md) — Per-Batch Records section.
**Full theory**: [metrics-guide.md](./metrics-guide.md) — detailed explanations and caveats.

---

## Table of Contents

- [Before You Measure](#before-you-measure)
- [Step 1: Capture tsc Diagnostics (P0)](#step-1-capture-tsc-diagnostics-p0)
- [Step 2: Count Migration Progress (P1)](#step-2-count-migration-progress-p1)
- [Step 3: Count Deprecated APIs (P1)](#step-3-count-deprecated-apis-p1)
- [Step 4: Record in metrics-record.md](#step-4-record-in-metrics-recordmd)
- [Step 5: Calculate Delta vs Baseline](#step-5-calculate-delta-vs-baseline)
- [When to Measure Build Time and Bundle Size](#when-to-measure-build-time-and-bundle-size)
- [Optional: Per-File Trace Analysis](#optional-per-file-trace-analysis)
- [Automation Script](#automation-script)
- [Baseline Reference Values](#baseline-reference-values)
- [FAQ](#faq)

---

## Before You Measure

Run these **every time** before taking measurements:

```bash
cd sndq-fe

# 1. Kill the dev server — it competes for CPU and memory
pkill -f "next dev" 2>/dev/null || true

# 2. Delete incremental cache — tsconfig.json has "incremental": true,
#    stale cache causes misleadingly low numbers
rm -f tsconfig.tsbuildinfo

# 3. Close any IDE TypeScript server (optional but recommended)
#    Some IDEs run background tsc that competes for memory
```

**Do NOT skip these steps.** Failing to kill the dev server or clear the cache will produce unreliable results.

---

## Step 1: Capture tsc Diagnostics (P0)

This is the **most important metric**. Run 3 times, record all 3, use the **median** (middle value).

```bash
# Run 1
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics --incremental false 2>&1 | \
  grep -E "Types|Instantiations|Memory|Check time|Total time"

# Run 2
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics --incremental false 2>&1 | \
  grep -E "Types|Instantiations|Memory|Check time|Total time"

# Run 3
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics --incremental false 2>&1 | \
  grep -E "Types|Instantiations|Memory|Check time|Total time"
```

### What to record from the output

```
Types:           1,691,552      ← record this
Instantiations: 29,150,241      ← ⭐ PRIMARY metric — record this
Memory used:    6,776,633K      ← record this
Check time:      117.08s        ← ⭐ record this (human-readable impact)
Total time:      121.93s        ← record this
```

### Why 3 runs?

- **Instantiations** is deterministic (same number every run for same code) — 1 run is enough for this
- **Check time** fluctuates ±5-10% due to CPU load and thermal throttling — median of 3 is reliable
- **Memory** varies slightly (±0.1%) — median is fine

### Why Instantiations is the best metric

| Property | Instantiations | Check time |
|----------|:-:|:-:|
| Deterministic (±0 between runs) | ✅ | ❌ (±5-10%) |
| Improves monotonically per file migrated | ✅ | ✅ |
| Not affected by thermal throttling | ✅ | ❌ |
| Easy to report ("reduced 650K instantiations") | ✅ | ✅ ("saved 3s") |

**Use Instantiations for precision. Use Check time for human-readable reporting.**

---

## Step 2: Count Migration Progress (P1)

```bash
echo "Files on v4: $(rg -l "from ['\"]zod/v4['\"]" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | wc -l | tr -d ' ')"
echo "Files on v3: $(rg -l "from ['\"]zod['\"]" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | rg -v 'zod/v4' | wc -l | tr -d ' ')"
```

Expected progression:

| Checkpoint | Files on v3 | Files on v4 |
|------------|:-:|:-:|
| Baseline | 103 | 0 |
| After Batch 1 | ~90 | ~13 |
| After Batch 2 | ~60 | ~43 |
| After Batch 3 | ~30 | ~73 |
| After Batch 4 | 0 | 103 |

---

## Step 3: Count Deprecated APIs (P1)

```bash
echo "nativeEnum:         $(rg -c 'nativeEnum' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo "required_error:     $(rg -c 'required_error' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo "invalid_type_error: $(rg -c 'invalid_type_error' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo ".Enum.:             $(rg -c '\.Enum\.' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo ".Values.:           $(rg -c '\.Values\.' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
```

All these should trend toward **0** as migration progresses.

---

## Step 4: Record in metrics-record.md

Open [metrics-record.md](./metrics-record.md) and fill in the corresponding batch section. Example for Batch 1:

```markdown
#### tsc Diagnostics (3 runs)

| Run | Types | Instantiations | Memory (KB) | Check time (s) | Total time (s) |
|-----|-------|----------------|-------------|-----------------|-----------------|
| 1   | X     | X              | X           | X               | X               |
| 2   | X     | X              | X           | X               | X               |
| 3   | X     | X              | X           | X               | X               |
| **Median** | **X** | **X** | **X** | **X** | **X** |
```

---

## Step 5: Calculate Delta vs Baseline

Use these baseline values (from [baseline-analysis.md](./baseline-analysis.md)):

| Metric | Baseline Value |
|--------|---------------|
| Types | 1,691,552 |
| Instantiations | 29,150,241 |
| Memory (KB) | 6,776,633 |
| Check time (s) | 117.08 |
| Total time (s) | 121.93 |

### How to calculate

```
Delta = After Batch - Baseline
% Change = (Delta / Baseline) × 100

Example:
  Baseline Instantiations:     29,150,241
  After Batch 1 Instantiations: 28,500,000  (hypothetical)
  Delta:                        -650,241
  % Change:                     -2.23%
```

Fill these into the "Delta vs Baseline" table in metrics-record.md:

```markdown
#### Delta vs Baseline

| Metric | Baseline | After Batch 1 | Delta | % Change |
|--------|----------|---------------|-------|----------|
| Instantiations | 29,150,241 | 28,500,000 | -650,241 | -2.23% |
| Check time (s) | 117.08 | 114.50 | -2.58 | -2.20% |
| Total time (s) | 121.93 | 119.20 | -2.73 | -2.24% |
| Memory (KB) | 6,776,633 | 6,750,000 | -26,633 | -0.39% |
```

---

## When to Measure Build Time and Bundle Size

**Short answer**: Only at **Baseline** (already done) and **Final** (after all 103 files migrated).

**Why not per-batch?**

During gradual migration, both Zod engines are in the bundle:

```
File A: import { z } from "zod"      ← v3 engine loaded
File B: import { z } from "zod/v4"   ← v4 engine loaded

Webpack includes BOTH → bundle TEMPORARILY grows
```

This means bundle size and build time **temporarily increase** during migration, then drop below baseline once all files are on v4. Measuring per-batch would show a misleading regression.

```
tsc Instantiations:  ████████░░░░  → Decreases per batch ✓  (measure every batch)
Bundle size:         █████████████  → Temporarily INCREASES  ⚠ (measure start + end only)
Build time:          █████████████  → Temporarily INCREASES  ⚠ (measure start + end only)
```

### When you do measure build (Baseline + Final only)

```bash
rm -rf .next
time pnpm build     # record wall-clock time (run 3×, take median)
```

---

## Optional: Per-File Trace Analysis

Use this when:
- You need to debug why a specific batch didn't improve metrics as expected
- You want to identify the single heaviest schema before migrating it
- You need a flamechart visualization for a report

### How to run

```bash
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --generateTrace ./tsc-trace
```

### How to analyze

1. Open [Perfetto UI](https://ui.perfetto.dev/) in Chrome
2. Drag `./tsc-trace/trace.json` into the browser
3. Look for your schema file (e.g., search for `lease/schema.ts`)
4. Compare the bar width (time spent) before and after migration

### Before/after comparison

```bash
# Before migrating a file
npx tsc --noEmit --generateTrace ./trace-before

# Migrate the file from "zod" → "zod/v4"

# After migrating
npx tsc --noEmit --generateTrace ./trace-after
```

Open both traces in Perfetto UI tabs and compare the bar for the same file.

---

## Automation Script

Instead of running all commands manually, use the all-in-one script from [metrics-guide.md](./metrics-guide.md):

```bash
# After completing Batch 1
bash measure-zod-migration.sh "after-batch-1"

# After completing Batch 2
bash measure-zod-migration.sh "after-batch-2"

# After completing Batch 3
bash measure-zod-migration.sh "after-batch-3"

# After completing Batch 4
bash measure-zod-migration.sh "after-batch-4"

# After switching to zod@4.x and reverting imports from "zod/v4" → "zod"
bash measure-zod-migration.sh "final"
```

This script captures all metrics (tsc diagnostics ×3, migration progress, deprecated API counts, test status) and saves them to a timestamped `.txt` file.

---

## Baseline Reference Values

Quick reference — copy these when filling delta tables:

| Metric | Baseline | Source |
|--------|----------|--------|
| Instantiations | **29,150,241** | [baseline-analysis.md](./baseline-analysis.md) |
| Types | **1,691,552** | [baseline-analysis.md](./baseline-analysis.md) |
| Check time (s) | **117.08** | [baseline-analysis.md](./baseline-analysis.md) |
| Total time (s) | **121.93** | [baseline-analysis.md](./baseline-analysis.md) |
| Memory (KB) | **6,776,633** | [baseline-analysis.md](./baseline-analysis.md) |
| `next build` wall-clock (s) | **491** (median of 3) | [metrics-record.md](./metrics-record.md) |
| Shared JS (all routes) | **232 kB** | [metrics-record.md](./metrics-record.md) |
| Heaviest route first-load JS | **1.57 MB** | [metrics-record.md](./metrics-record.md) |
| Total zod files | **~103** | [README.md](./README.md) |
| Total deprecated APIs | **~280+** | [README.md](./README.md) |

---

## FAQ

### Can I measure after migrating a single form instead of a whole batch?

You can, but it's not recommended:

- **tsc diagnostics** takes ~2 min per run, ×3 for median = **~6 min** of measurement time for a change that may only reduce Instantiations by <1%
- The Instantiations delta for 1 file out of 103 may be too small to distinguish from noise in Check time
- Batch-level measurement (13-30 files) gives a large enough delta to be statistically meaningful

If you still want per-form measurement, **only look at Instantiations** (not Check time). It's the only metric that is deterministic enough to detect small per-file changes.

### What if Instantiations doesn't decrease after a batch?

Possible reasons:
1. The migrated files were "simple" schemas (few generics) — they produce fewer Instantiations to begin with
2. The import was changed but the schema still uses v3 patterns (e.g., `.merge()` instead of spread)
3. Other files were added to the codebase between measurements, offsetting the reduction

**Action**: Run `--generateTrace` and compare the specific files in Perfetto UI. See [Optional: Per-File Trace Analysis](#optional-per-file-trace-analysis).

### What if Check time went UP despite Instantiations going DOWN?

This is normal. Check time fluctuates ±5-10% due to:
- CPU thermal throttling (especially after running tsc 3× back-to-back)
- Background processes (Spotlight indexing, OS updates)
- Memory pressure from other apps

**Trust Instantiations over Check time.** If Instantiations dropped, the migration is working. The Check time improvement will show up in the median of 3 runs as you get further into the migration.

### Should I commit the metrics files to the repo?

The measurement `.txt` files from the automation script go in your local workspace. The **metrics-record.md** file (with filled-in tables) should be committed to the research repo as documentation of the migration's measured impact.

---

## Quick Reference Card

```
┌─────────────────────────────────────────────┐
│  AFTER MIGRATING A BATCH                    │
│                                             │
│  1. pkill -f "next dev"                     │
│  2. rm -f tsconfig.tsbuildinfo              │
│  3. tsc --diagnostics --incremental false   │
│     (×3, record median)                     │
│  4. rg count: files on v3 / v4             │
│  5. rg count: deprecated APIs               │
│  6. Record in metrics-record.md             │
│  7. Calculate delta vs baseline             │
│                                             │
│  PRIMARY METRIC: Instantiations             │
│  (deterministic, monotonic, per-batch)      │
│                                             │
│  Build time + bundle: START + END only      │
└─────────────────────────────────────────────┘
```

---

## References

- [Baseline Analysis](./baseline-analysis.md) — raw benchmark data + bottleneck analysis
- [Metrics Record](./metrics-record.md) — where to fill in measurements
- [Metrics & Measurement Guide](./metrics-guide.md) — full theory, all-in-one script, caveats
- [Migration Plan](./README.md) — breaking changes, testing strategy, execution plan
- [Progress Tracker](./progress.md) — per-file checklists
