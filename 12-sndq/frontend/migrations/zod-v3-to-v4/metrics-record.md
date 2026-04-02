# Zod v4 Migration — Metrics Record

Live data sheet for recording all measurements taken during the Zod v3 → v4 migration of `sndq-fe`. Fill in values as you run the measurement commands at each checkpoint.

**Created**: 2026-03-27
**How to measure**: See [How to Measure](./how-to-measure.md) for the step-by-step runbook after each batch.
**Full theory**: See [Metrics & Measurement Guide](./metrics-guide.md) for detailed explanations, scripts, and caveats.
**Migration tracking**: See [Progress Tracker](./progress.md) for per-file checklists.
**Related**: [Migration Plan](./README.md) · [Ticket Summary](./ticket.md)

---

## Table of Contents

- [Quick Measurement Commands](#quick-measurement-commands)
- [1. Baseline Snapshot](#1-baseline-snapshot)
- [2. Per-Batch Records](#2-per-batch-records)
- [3. Final Snapshot](#3-final-snapshot)
- [4. Trends & Comparison](#4-trends--comparison)
- [5. Raw Logs Archive](#5-raw-logs-archive)

---

## Quick Measurement Commands

Copy-paste reference for each measurement session. Full explanations in [Metrics Guide](./metrics-guide.md).

```bash
cd sndq-fe

# --- BEFORE EVERY MEASUREMENT SESSION ---
pkill -f "next dev" 2>/dev/null || true    # Kill dev server
rm -f tsconfig.tsbuildinfo                  # Clear incremental cache

# --- P0: tsc diagnostics (run 3x, record median) ---
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics 2>&1 | \
  grep -E "Types|Instantiations|Memory|Check time|Total time"

# --- P1: Migration progress ---
echo "On v4: $(rg -l "from ['\"]zod/v4['\"]" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | wc -l | tr -d ' ')"
echo "On v3: $(rg -l "from ['\"]zod['\"]" src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | rg -v 'zod/v4' | wc -l | tr -d ' ')"

# --- P1: Deprecated API counts ---
echo "nativeEnum:        $(rg -c 'nativeEnum' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo "required_error:    $(rg -c 'required_error' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo "invalid_type_error:$(rg -c 'invalid_type_error' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo ".Enum.:            $(rg -c '\.Enum\.' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"
echo ".Values.:          $(rg -c '\.Values\.' src/ --glob '*.ts' --glob '*.tsx' 2>/dev/null | cut -d: -f2 | paste -sd+ | bc 2>/dev/null || echo 0)"

# --- P2: Build time + bundle size (start + end only) ---
rm -rf .next && time pnpm build
du -sh .next/static/chunks/
```

---

## 1. Baseline Snapshot

> Captured **before** any migration work. This is the reference point for all deltas.

### Environment

| Field | Value |
|-------|-------|
| Date | 2026-03-28 |
| Machine | macOS darwin 23.5.0 (Apple Silicon, 10 threads) |
| Node.js version | v22.11.0 |
| TypeScript version | 5.9.3 |
| pnpm version | _(TBD)_ |
| Zod version (lockfile) | 3.25.76 |
| `@hookform/resolvers` version | ^4.1.3 |
| Branch / commit | `perf/SQ-20365` (based off `dev` @ `7b26c713`) |

### TypeScript Compiler (4 runs, `--incremental false`)

> Run 1 used default flags (incremental enabled) — inflated emit by 11.49s due to `.tsbuildinfo` serialization.
> Runs 2–5 used `--incremental false` for clean measurement. All 4 are recorded; median calculated from runs 2–5.

| Run | Flags | Types | Instantiations | Memory (KB) | Check (s) | Emit (s) | Total (s) |
|-----|-------|-------|----------------|-------------|-----------|----------|-----------|
| 1 _(incremental)_ | default | 1,693,681 | 29,165,585 | 6,781,731 | 116.88 | 11.49 | 133.35 |
| 2 | `--incremental false` | 1,691,552 | 29,150,241 | 6,780,566 | 111.93 | 0.01 | 117.02 |
| 3 | `--incremental false` | 1,691,552 | 29,150,241 | 6,778,701 | 116.81 | 0.00 | 121.61 |
| 4 | `--incremental false` | 1,691,552 | 29,150,241 | 6,774,564 | 118.77 | 0.00 | 123.12 |
| 5 | `--incremental false` | 1,691,552 | 29,150,241 | 6,773,756 | 117.35 | 0.00 | 122.25 |
| **Median (2–5)** | | **1,691,552** | **29,150,241** | **6,776,633** | **117.08** | **0.00** | **121.93** |

Additional constant metrics across all runs:

| Metric | Value |
|--------|-------|
| Files | 7,621 |
| Lines | 1,060,981 |
| Identifiers | 1,238,743 |
| Symbols (incremental) | 2,291,533 |
| Symbols (no incremental) | 2,278,327 |
| Parse time range | 3.59–4.23s |
| Bind time range | 0.74–0.84s |

### Next.js Build (3 runs)

> Command: `pnpm build 2>&1 | tee build-output-N.txt` (via Lerna → `next build`)
> All runs on same branch `perf/SQ-20365`, `.next/` deleted before each run.

| Run | Source File | Compile Phase | Wall-Clock (`time`) | User | System | CPU % |
|-----|-------------|---------------|---------------------|------|--------|-------|
| 1 | `build-output-2.txt` | 3.5 min | **7:48.44** (468s) | 591.78s | 90.08s | 145% |
| 2 | `build-output-3.txt` | 4.2 min | **8:10.83** (491s) | 703.77s | 89.25s | 161% |
| 3 | `build-output-4.txt` | 4.9 min | **9:28.74** (569s) | 748.78s | 116.76s | 152% |
| **Median** | | **4.2 min** | **8:10.83 (491s)** | **703.77s** | **90.08s** | **152%** |

| Stat | Wall-Clock (s) | Compile Phase (min) |
|------|----------------|---------------------|
| Min | 468 | 3.5 |
| Max | 569 | 4.9 |
| Mean | 509 | 4.2 |
| **Median** | **491** | **4.2** |
| Range | 101 (21.6%) | 1.4 (40%) |

> **Note**: High variance (21.6% wall-clock range) is expected due to thermal throttling on Apple Silicon during sustained 8+ min builds. The compile phase shows even higher variance (40%) because it's CPU-bound and most affected by throttling. Median is the most reliable reference.

### Bundle Size (consistent across all 3 runs)

| Metric | Value |
|--------|-------|
| First Load JS shared by all | **232 kB** |
| Shared chunk: `38387-*.js` | 134 kB |
| Shared chunk: `9e84f066-*.js` | 54.4 kB |
| Shared chunk: `e61e4be7-*.js` | 36.9 kB |
| Other shared chunks | 7.11 kB |
| Middleware | 109 kB |
| Total routes | 123 (all dynamic `ƒ`) |
| Next.js version | 15.5.9 |

### Top 10 Heaviest Routes by First-Load JS

| # | Route | Size | First Load JS |
|---|-------|------|---------------|
| 1 | `/patrimony/buildings/detail/[id]/meeting/[meetingId]` | 352 kB | **1.57 MB** |
| 2 | `/patrimony` | 8.9 kB | **1.29 MB** |
| 3 | `/contacts/contact/detail/[id]` | 21.8 kB | **1.25 MB** |
| 4 | `/peppol` | 879 B | **1.25 MB** |
| 5 | `/financial/invoices/sales/[salesId]` | 8.44 kB | **1.23 MB** |
| 6 | `/patrimony/buildings/detail/[id]` | 549 B | **1.22 MB** |
| 7 | `/financial/invoices/purchase/[purchaseId]` | 6.21 kB | **1.20 MB** |
| 8 | `/financial/invoices/purchase/new-v2` | 18.2 kB | **1.19 MB** |
| 9 | `/financial/buildings/[buildingId]` | 18.4 kB | **1.18 MB** |
| 10 | `/financial/buildings/[buildingId]/costs` | 730 B | **1.17 MB** |

> Most routes above 1 MB first-load share the same large chunk tree. The outlier is the meeting route at 1.57 MB (352 kB page-specific JS).

### Codebase Counts

> Values from [Migration Plan audit](./README.md#current-state-audit). Exact counts TBD via measurement commands.

| Count | Value |
|-------|-------|
| Total files importing `zod` | ~103 |
| Files on `"zod"` (v3) | ~103 |
| Files on `"zod/v4"` (v4) | 0 |
| `z.nativeEnum()` usages | ~44 files, ~100+ |
| `.Enum.` accessor usages | _(included in nativeEnum count)_ |
| `.Values.` accessor usages | _(included in nativeEnum count)_ |
| `required_error` usages | ~27 files, ~80+ |
| `invalid_type_error` usages | _(included in required_error count)_ |
| **Total deprecated API usages** | ~280+ |
| Schema test files | 1 (`accountSchemas.test.ts`) |
| Snapshot (`.snap`) files | 0 |

---

## 2. Per-Batch Records

### Batch 1: Transform Files (13 files — CRITICAL risk)

> Files with `.transform()` + `.default()` combos that produce silent behavior changes.

**Date started**: ___
**Date completed**: ___
**Files migrated this batch**: ___ / 13

#### tsc Diagnostics (3 runs)

| Run | Types | Instantiations | Memory (KB) | Check time (s) | Total time (s) |
|-----|-------|----------------|-------------|-----------------|-----------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| **Median** | | | | | |

#### Delta vs Baseline

| Metric | Baseline | After Batch 1 | Delta | % Change |
|--------|----------|---------------|-------|----------|
| Instantiations | 29,150,241 | | | |
| Check time (s) | 117.08 | | | |
| Total time (s) | 121.93 | | | |
| Memory (KB) | 6,776,633 | | | |

#### Codebase Counts

| Count | Before | After | Delta |
|-------|--------|-------|-------|
| Files on v3 | ~103 | | |
| Files on v4 | 0 | | |
| Deprecated APIs total | ~280+ | | |
| Schema test files | 1 | | |
| Snapshot files | 0 | | |

#### Notes

- 

---

### Batch 2: nativeEnum Files (~30 files — HIGH risk)

> Files with `z.nativeEnum()` — deprecated in v4, `.Enum`/`.Values` accessors removed entirely.

**Date started**: ___
**Date completed**: ___
**Files migrated this batch**: ___ / ~30

#### tsc Diagnostics (3 runs)

| Run | Types | Instantiations | Memory (KB) | Check time (s) | Total time (s) |
|-----|-------|----------------|-------------|-----------------|-----------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| **Median** | | | | | |

#### Delta vs Baseline

| Metric | Baseline | After Batch 2 | Delta | % Change |
|--------|----------|---------------|-------|----------|
| Instantiations | 29,150,241 | | | |
| Check time (s) | 117.08 | | | |
| Total time (s) | 121.93 | | | |
| Memory (KB) | 6,776,633 | | | |

#### Delta vs Previous Batch

| Metric | After Batch 1 | After Batch 2 | Delta | % Change |
|--------|---------------|---------------|-------|----------|
| Instantiations | | | | |
| Check time (s) | | | | |

#### Codebase Counts

| Count | Before | After | Delta |
|-------|--------|-------|-------|
| Files on v3 | | | |
| Files on v4 | | | |
| `nativeEnum` usages | | 0 | |
| `.Enum.` usages | | 0 | |
| `.Values.` usages | | 0 | |
| Deprecated APIs total | | | |

#### Notes

- 

---

### Batch 3: Error Customization Files (~27 files — MEDIUM risk)

> Files using `required_error`, `invalid_type_error` — removed in v4, `tsc` will catch them.

**Date started**: ___
**Date completed**: ___
**Files migrated this batch**: ___ / ~27

#### tsc Diagnostics (3 runs)

| Run | Types | Instantiations | Memory (KB) | Check time (s) | Total time (s) |
|-----|-------|----------------|-------------|-----------------|-----------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| **Median** | | | | | |

#### Delta vs Baseline

| Metric | Baseline | After Batch 3 | Delta | % Change |
|--------|----------|---------------|-------|----------|
| Instantiations | 29,150,241 | | | |
| Check time (s) | 117.08 | | | |
| Total time (s) | 121.93 | | | |
| Memory (KB) | 6,776,633 | | | |

#### Delta vs Previous Batch

| Metric | After Batch 2 | After Batch 3 | Delta | % Change |
|--------|---------------|---------------|-------|----------|
| Instantiations | | | | |
| Check time (s) | | | | |

#### Codebase Counts

| Count | Before | After | Delta |
|-------|--------|-------|-------|
| Files on v3 | | | |
| Files on v4 | | | |
| `required_error` usages | | 0 | |
| `invalid_type_error` usages | | 0 | |
| Deprecated APIs total | | | |

#### Notes

- 

---

### Batch 4: Remaining Simple Files (~30 files — LOW risk)

> Straightforward import swap. `tsc --noEmit` passing is sufficient — snapshot tests optional.

**Date started**: ___
**Date completed**: ___
**Files migrated this batch**: ___ / ~30

#### tsc Diagnostics (3 runs)

| Run | Types | Instantiations | Memory (KB) | Check time (s) | Total time (s) |
|-----|-------|----------------|-------------|-----------------|-----------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| **Median** | | | | | |

#### Delta vs Baseline

| Metric | Baseline | After Batch 4 | Delta | % Change |
|--------|----------|---------------|-------|----------|
| Instantiations | 29,150,241 | | | |
| Check time (s) | 117.08 | | | |
| Total time (s) | 121.93 | | | |
| Memory (KB) | 6,776,633 | | | |

#### Delta vs Previous Batch

| Metric | After Batch 3 | After Batch 4 | Delta | % Change |
|--------|---------------|---------------|-------|----------|
| Instantiations | | | | |
| Check time (s) | | | | |

#### Codebase Counts

| Count | Before | After | Delta |
|-------|--------|-------|-------|
| Files on v3 | | 0 | |
| Files on v4 | | 103 | |
| Deprecated APIs total | | 0 | |

#### Notes

- 

---

## 3. Final Snapshot

> Captured **after** all files migrated + optional upgrade to `zod@4.x` + imports reverted from `"zod/v4"` → `"zod"`.

### Environment

| Field | Value |
|-------|-------|
| Date | |
| Zod version (lockfile) | |
| Branch / commit | |

### TypeScript Compiler (3 runs)

| Run | Types | Instantiations | Memory (KB) | Check time (s) | Total time (s) |
|-----|-------|----------------|-------------|-----------------|-----------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| **Median** | | | | | |

### Next.js Build

| Field | Value |
|-------|-------|
| `next build` wall-clock time (median of 3) | |
| Shared JS (all routes) | |
| Heaviest route first-load JS | |
| Heaviest route name | |

### Codebase Counts

| Count | Value |
|-------|-------|
| Total files importing `zod` | |
| `z.nativeEnum()` usages | 0 |
| `required_error` usages | 0 |
| `invalid_type_error` usages | 0 |
| `.Enum.` / `.Values.` usages | 0 |
| **Total deprecated API usages** | 0 |
| Schema test files | |
| Snapshot (`.snap`) files | |

---

## 4. Trends & Comparison

### Overall Summary: Baseline vs Final

| Metric | Baseline | Final | Delta | % Change | Verdict |
|--------|----------|-------|-------|----------|---------|
| `tsc` Instantiations | 29,150,241 | | | | |
| `tsc` Check time (s) | 117.08 | | | | |
| `tsc` Total time (s) | 121.93 | | | | |
| `tsc` Memory (KB) | 6,776,633 | | | | |
| `next build` wall-clock (s) | 491 | | | | |
| Shared JS (all routes) | 232 kB | | | | |
| Heaviest route first-load JS | 1.57 MB | | | | |
| Deprecated APIs | ~280+ | 0 | | -100% | |
| Schema test files | 1 | | | | |

### TypeScript Compilation Trend (per batch)

| Checkpoint | Date | Files on v4 | Instantiations | Inst. Δ from prev | Check time (s) | Check Δ from prev |
|------------|------|-------------|----------------|--------------------|----------------|-------------------|
| Baseline | 2026-03-28 | 0 / 103 | 29,150,241 | — | 117.08 | — |
| Batch 1 | | / 103 | | | | |
| Batch 2 | | / 103 | | | | |
| Batch 3 | | / 103 | | | | |
| Batch 4 | | 103 / 103 | | | | |
| Final | | 103 / 103 | | | | |

### Bundle Size Trend (start + end only)

| Checkpoint | Shared JS (all routes) | Heaviest Route First-Load JS | Notes |
|------------|------------------------|------------------------------|-------|
| Baseline | 232 kB | 1.57 MB | Single Zod v3 engine |
| Final | | | Single Zod v4 engine |
| Delta | | | |
| % Change | | | |

### Migration Progress Trend

| Checkpoint | Files on v3 | Files on v4 | nativeEnum | required_error | invalid_type_error | .Enum/.Values | Total deprecated |
|------------|------------|------------|------------|----------------|--------------------|----|---------|
| Baseline | 103 | 0 | | | | | |
| Batch 1 | | | | | | | |
| Batch 2 | | | 0 | | | 0 | |
| Batch 3 | | | 0 | 0 | 0 | 0 | |
| Batch 4 | 0 | 103 | 0 | 0 | 0 | 0 | 0 |

### Test Coverage Growth

| Checkpoint | Schema test files | Snapshot (`.snap`) files | Total test files |
|------------|------------------|-------------------------|-----------------|
| Baseline | | 0 | |
| Batch 1 | | | |
| Batch 2 | | | |
| Batch 3 | | | |
| Batch 4 | | | |

---

## 5. Raw Logs Archive

Reference to saved measurement output files (from the `measure-zod-migration.sh` script or manual runs).

| Label | Filename | Date | Notes |
|-------|----------|------|-------|
| Baseline (tsc) | [baseline-analysis.md](./baseline-analysis.md) | 2026-03-28 | 5 tsc runs + detailed analysis |
| Baseline (build run 1) | `sndq/build-output-2.txt` | 2026-03-28 | 7:48.44 wall-clock, 3.5min compile |
| Baseline (build run 2) | `sndq/build-output-3.txt` | 2026-03-28 | 8:10.83 wall-clock, 4.2min compile |
| Baseline (build run 3) | `sndq/build-output-4.txt` | 2026-03-28 | 9:28.74 wall-clock, 4.9min compile |
| After Batch 1 | `metrics-after-batch-1-YYYYMMDD-HHMMSS.txt` | | |
| After Batch 2 | `metrics-after-batch-2-YYYYMMDD-HHMMSS.txt` | | |
| After Batch 3 | `metrics-after-batch-3-YYYYMMDD-HHMMSS.txt` | | |
| After Batch 4 | `metrics-after-batch-4-YYYYMMDD-HHMMSS.txt` | | |
| Final | `metrics-final-YYYYMMDD-HHMMSS.txt` | | |

---

## References

- [Baseline Analysis](./baseline-analysis.md) — Detailed analysis of pre-migration benchmark runs, bottleneck identification, Zod v4 impact projections
- [Metrics & Measurement Guide](./metrics-guide.md) — How to measure, scripts, caveats, incremental strategy
- [Migration Progress Tracker](./progress.md) — Per-file checklists and batch tables
- [Migration Plan](./README.md) — Breaking changes catalog, testing strategy, risk analysis
- [Ticket Summary](./ticket.md) — Concise version for task tracking
