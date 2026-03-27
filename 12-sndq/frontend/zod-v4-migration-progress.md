# Zod v4 Migration Progress Tracker — sndq-fe

Tracks the gradual file-by-file migration from `"zod"` (v3) to `"zod/v4"` imports using Zod 3.25.76's subpath strategy. Each schema file is migrated independently with snapshot tests and manual QA.

**Created**: 2026-03-27
**Status**: Not started
**Approach**: Gradual migration via `"zod/v4"` subpath (no big-bang upgrade)
**Related**: [Zod v3 → v4 Migration Plan](./zod-v3-to-v4-migration-plan.md) — full breaking changes catalog, testing strategy, and risk analysis
**Ticket**: [Zod v4 Migration — Ticket Summary](./zod-v4-migration-ticket.md) — concise version for task tracking
**Metrics record**: [Metrics Record](./zod-v4-migration-metrics-record.md) — actual recorded measurements

---

## Table of Contents

- [Migration Approach](#migration-approach)
- [Baseline Metrics](#baseline-metrics)
- [Batch Progress](#batch-progress)
  - [Batch 1: Transform Files (Highest Risk)](#batch-1-transform-files-highest-risk)
  - [Batch 2: nativeEnum Files](#batch-2-nativeenum-files)
  - [Batch 3: Error Customization Files](#batch-3-error-customization-files)
  - [Batch 4: Remaining Simple Files](#batch-4-remaining-simple-files)
  - [Final: Switch to zod@4.x](#final-switch-to-zod4x)
- [Metrics Dashboard](#metrics-dashboard)
- [Per-File Migration Checklist](#per-file-migration-checklist)
- [Commands Reference](#commands-reference)
- [Decision Log](#decision-log)

---

## Migration Approach

### Why Gradual via `"zod/v4"` Subpath

Zod 3.25.0+ ships both v3 and v4 engines in the same npm package via subpath imports. This enables file-by-file migration with zero version conflicts:

```typescript
// Before migration (current state) — every file
import { z } from 'zod';        // ← Zod v3 engine

// During migration — per-file switch
import { z } from 'zod/v4';     // ← Zod v4 engine (same package)

// After all files migrated — optional final cleanup
// Change package.json from "zod": "^3.24.2" to "zod": "^4.0.0"
// Then revert imports from "zod/v4" back to "zod"
```

**Advantages over big-bang upgrade:**
- Each file is an independent, reviewable commit
- If one form breaks, only that PR is affected
- Can pause migration at any point — mixed v3/v4 imports work fine
- No risk of `packages/ui` version mismatch (both use the same `zod@3.25.x` package)
- Metrics measured incrementally show improvement trend

### Per-File Migration Workflow

```
For each schema file:
  1. Write snapshot test (import from "zod" — v3 baseline)
  2. Run test → generate baseline snapshot
  3. Change import: "zod" → "zod/v4"
  4. Run test → compare snapshot diff
     - No diff → migration complete for this file
     - Diff found → investigate:
       a. .default() behavior → use .prefault() if Zod 3 behavior needed
       b. .optional() + .default() key presence → restructure or accept new behavior
       c. Error structure change → update snapshot if acceptable
  5. Run tsc --noEmit (ensure no type errors)
  6. Manually test the form in browser
  7. Commit with descriptive message
```

---

## Baseline Metrics

> Run these commands **before starting any migration** and record values below.
> For detailed measurement instructions, caveats, and the all-in-one script, see the [Metrics & Measurement Guide](./zod-v4-migration-metrics-guide.md).

### How to Capture

```bash
cd sndq-fe

# CRITICAL: Always delete incremental cache before measuring
# (tsconfig.json has "incremental": true — cached results give wrong numbers)
rm -f tsconfig.tsbuildinfo

# Kill dev server if running (competes for CPU/memory)
pkill -f "next dev" 2>/dev/null || true

# 1. TypeScript diagnostics (run 3 times, use median)
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics 2>&1 | tee ~/baseline-tsc-v3.txt

# 2. TypeScript trace (for deep analysis in https://ui.perfetto.dev/)
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --generateTrace ./tsc-trace-baseline

# 3. Next.js build time
rm -rf .next && time pnpm build 2>&1 | tee ~/baseline-build-v3.txt

# 4. Bundle size (after build)
du -sh .next/static/chunks/

# 5. Zod-specific counts
echo "Files importing zod: $(rg -l "from 'zod'" src/ --glob '*.ts' --glob '*.tsx' | wc -l | tr -d ' ')"
echo "nativeEnum usage: $(rg 'nativeEnum' src/ --glob '*.ts' --glob '*.tsx' | wc -l | tr -d ' ')"
echo "deprecated APIs: $(rg 'required_error|invalid_type_error|\.Enum\.|\.Values\.' src/ --glob '*.ts' | wc -l | tr -d ' ')"

# Or use the all-in-one script:
# bash measure-zod-migration.sh "baseline"
```

### Measurement Caveats

1. **Always delete `tsconfig.tsbuildinfo`** before running `tsc --diagnostics` — incremental cache skips files
2. **Run 3 times, take median** — `tsc` timing fluctuates ±5-10% per run
3. **Instantiations is deterministic** — exact count, not affected by CPU load (best metric to report)
4. **Kill `next dev`** before measuring — competing TypeScript checker affects results
5. **Same machine, same conditions** — don't compare laptop-on-battery vs plugged-in

### Recorded Baseline

| Metric | Value | Date |
|--------|-------|------|
| Zod version (lockfile) | 3.25.76 | — |
| `tsc --noEmit` total time | ___ ms | |
| `tsc` check time | ___ ms | |
| `tsc` instantiations | ___ | |
| `tsc` types | ___ | |
| `tsc` memory used | ___ MB | |
| `next build` total time | ___ s | |
| `.next/static/chunks/` size | ___ MB | |
| First-load JS (heaviest route) | ___ kB | |
| Files importing `zod` | ~103 | |
| `nativeEnum` usage count | ~100+ | |
| Deprecated API usage count | ~244 | |
| Schema test files | 1 | |

---

## Batch Progress

### Batch 1: Transform Files (Highest Risk)

**Priority**: CRITICAL — these files have `.transform()` + `.default()` combos that produce silent behavior changes.

**Target**: 13 files

| # | Schema File | Test Written | Snapshot OK | Import Changed | Test Passed | Manual QA | Committed |
|---|-------------|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | `patrimony/forms/lease/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 2 | `financial/forms/purchase-invoice-v2/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 3 | `financial/forms/purchase-invoice/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 4 | `components/contact/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 5 | `financial/forms/cost-settlement/.../schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 6 | `financial/forms/close-fiscal-year/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 7 | `patrimony/forms/lease/revision/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 8 | `patrimony/forms/building/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 9 | `financial/forms/purchase-invoice-v2-steward/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 10 | `patrimony/forms/property/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 11 | `patrimony/forms/lease/.../lease-deposit/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 12 | `fee-management/FeeConfiguratorForm/schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 13 | `contact-book/.../detail-overview-content/.../schema.ts` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

**Batch 1 metrics after completion:**

| Metric | Baseline | After Batch 1 | Delta | % Change |
|--------|----------|---------------|-------|----------|
| `tsc` instantiations | ___ | | | |
| `tsc` check time | ___ ms | | | |
| `tsc` total time | ___ ms | | | |
| `tsc` memory | ___ MB | | | |
| Deprecated APIs remaining | ~244 | | | |

**Notes:**
- 

---

### Batch 2: nativeEnum Files

**Priority**: HIGH — `z.nativeEnum()` is deprecated, `.Enum` and `.Values` accessors are removed entirely in v4.

**Target**: ~30 files with `nativeEnum` but no `.transform()` (already handled in Batch 1).

**Discovery command:**
```bash
# Files with nativeEnum NOT already in Batch 1
rg -l 'nativeEnum' src/ --glob '*.ts' | rg -v 'node_modules' | sort
```

| # | Schema File | Test Written | Import Changed | Test Passed | Manual QA | Committed |
|---|-------------|:---:|:---:|:---:|:---:|:---:|
| 1 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| 2 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| 3 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| _... populate after running discovery command ..._ | | | | | | |

**Batch 2 metrics after completion:**

| Metric | After Batch 1 | After Batch 2 | Delta | % Change |
|--------|---------------|---------------|-------|----------|
| `tsc` instantiations | | | | |
| `tsc` check time | | | | |
| `nativeEnum` usage remaining | | 0 | | |

**Notes:**
- 

---

### Batch 3: Error Customization Files

**Priority**: MEDIUM — files using `required_error`, `invalid_type_error`, or `message:` parameter.

**Target**: ~27 files with error customization patterns.

**Discovery command:**
```bash
rg -l 'required_error|invalid_type_error' src/ --glob '*.ts' | sort
```

| # | Schema File | Test Written | Import Changed | Test Passed | Manual QA | Committed |
|---|-------------|:---:|:---:|:---:|:---:|:---:|
| 1 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| 2 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| _... populate after running discovery command ..._ | | | | | | |

**Batch 3 metrics after completion:**

| Metric | After Batch 2 | After Batch 3 | Delta | % Change |
|--------|---------------|---------------|-------|----------|
| `tsc` instantiations | | | | |
| `tsc` check time | | | | |
| `required_error` / `invalid_type_error` remaining | | 0 | | |

**Notes:**
- `required_error` and `invalid_type_error` are **removed** in v4 (not deprecated). These files will fail `tsc` after import change, guiding the fix.
- Replace with the `error` function pattern: `error: (issue) => issue.input === undefined ? "Required" : "Not a string"`

---

### Batch 4: Remaining Simple Files

**Priority**: LOW — files with only primitives, validators, and structural combinators. `tsc` catches all issues.

**Target**: Remaining ~30 files.

**Discovery command:**
```bash
# All files still importing from "zod" (not "zod/v4") after Batches 1-3
rg -l "from 'zod'" src/ --glob '*.ts' --glob '*.tsx' | rg -v "zod/v4" | sort
```

| # | Schema File | Import Changed | tsc Passes | Committed |
|---|-------------|:---:|:---:|:---:|
| 1 | | [ ] | [ ] | [ ] |
| 2 | | [ ] | [ ] | [ ] |
| _... populate after Batches 1-3 complete ..._ | | | | |

**Batch 4 metrics after completion:**

| Metric | After Batch 3 | After Batch 4 (all v4) | Delta | % Change |
|--------|---------------|------------------------|-------|----------|
| `tsc` instantiations | | | | |
| `tsc` check time | | | | |
| `tsc` total time | | | | |
| `tsc` memory | | | | |
| Files still on v3 | | 0 | | |

**Notes:**
- These files are lowest risk — no `.transform()`, no `.default()` interactions, no removed APIs.
- Snapshot tests optional for this batch. `tsc --noEmit` passing is sufficient.

---

### Final: Switch to zod@4.x

**When**: After all 103 files are importing from `"zod/v4"`.

**Steps:**
- [ ] Verify zero files import from `"zod"` (v3): `rg "from 'zod'" src/ --glob '*.ts' | rg -v "zod/v" | wc -l` returns 0
- [ ] Update `sndq-fe/package.json`: `"zod": "^4.0.0"`
- [ ] Update `packages/ui/package.json`: `"zod": "^4.0.0"`
- [ ] Run `pnpm install`
- [ ] Verify single Zod version: `pnpm why zod`
- [ ] Change all imports from `"zod/v4"` back to `"zod"`: `find src -name '*.ts' -exec sed -i '' "s/from 'zod\/v4'/from 'zod'/g" {} +`
- [ ] Run `pnpm test` — all snapshots pass
- [ ] Run `pnpm tsc` — zero errors
- [ ] Run `pnpm build` — success
- [ ] Record final metrics below
- [ ] Update `.cursor/rules/sndq.mdc`: change "Zod v3" to "Zod v4"

**Final metrics:**

| Metric | Baseline (v3) | Final (v4) | Delta | % Change |
|--------|---------------|------------|-------|----------|
| `tsc --noEmit` total time | ___ ms | | | |
| `tsc` check time | ___ ms | | | |
| `tsc` instantiations | ___ | | | |
| `tsc` types | ___ | | | |
| `tsc` memory | ___ MB | | | |
| `next build` total time | ___ s | | | |
| `.next/static/chunks/` size | ___ MB | | | |
| First-load JS (heaviest route) | ___ kB | | | |
| Schema test files | 1 | | | |
| Deprecated API usage | ~244 | 0 | | |

---

## Metrics Dashboard

### TypeScript Compilation Trend

Track after each batch to show progressive improvement.

| Checkpoint | Files on v4 | Instantiations | Check Time (ms) | Total Time (ms) | Memory (MB) |
|------------|------------|---------------|----------------|----------------|-------------|
| Baseline | 0/103 | | | | |
| Batch 1 complete | 13/103 | | | | |
| Batch 2 complete | ~43/103 | | | | |
| Batch 3 complete | ~70/103 | | | | |
| Batch 4 complete | 103/103 | | | | |
| Final (zod@4.x) | 103/103 | | | | |

### Bundle Size Trend

| Checkpoint | Zod in bundle (kB) | Total first-load JS (kB) | Heaviest route (kB) |
|------------|-------------------|-------------------------|---------------------|
| Baseline | | | |
| Batch 1 | | | |
| All complete | | | |
| Final | | | |

### Test Coverage Growth

| Checkpoint | Schema test files | Total test files | Snapshot files |
|------------|------------------|-----------------|----------------|
| Baseline | 1 | 6 | 0 |
| Batch 1 | | | |
| Batch 2 | | | |
| All complete | | | |

### Migration Progress

| Checkpoint | Files on v3 | Files on v4 | nativeEnum left | Deprecated APIs left |
|------------|------------|------------|----------------|---------------------|
| Baseline | 103 | 0 | ~100+ | ~244 |
| Batch 1 | | | | |
| Batch 2 | | | 0 | |
| Batch 3 | | | 0 | |
| Batch 4 | 0 | 103 | 0 | 0 |

---

## Per-File Migration Checklist

Standard checklist for migrating any individual schema file. Copy this for each file in the batch tables above.

### Pre-migration (on v3 import)
- [ ] Write snapshot test with `valid` and `minimal` fixtures
- [ ] Run `pnpm test` → snapshot generated (`.snap` file created)
- [ ] Review snapshot file — confirm it matches expected behavior

### Migration
- [ ] Change `import { z } from 'zod'` → `import { z } from 'zod/v4'`
- [ ] Run `pnpm test` → compare snapshot diff
  - [ ] If snapshot unchanged → proceed
  - [ ] If snapshot changed → for each diff:
    - [ ] `.default()` produces different value → use `.prefault()` or accept new behavior
    - [ ] `.default()` + `.optional()` adds new key → restructure or accept
    - [ ] Error structure changed → update snapshot if acceptable
- [ ] Fix any `tsc` errors:
  - [ ] `required_error` → replace with `error` function
  - [ ] `invalid_type_error` → replace with `error` function
  - [ ] `z.nativeEnum()` → `z.enum()`
  - [ ] `.Enum.` → `.enum.`
  - [ ] `.Values.` → `.enum.`
  - [ ] `z.record()` single argument → add key schema
  - [ ] `z.any()` / `z.unknown()` in objects → add `.optional()` if needed
- [ ] Run `pnpm tsc` → zero errors in this file

### Post-migration
- [ ] Manually test the form in browser:
  - [ ] Happy path submission works
  - [ ] Validation errors display correctly
  - [ ] Default values populate correctly
  - [ ] Transform outputs correct data (check network tab)
- [ ] Update snapshot if behavior changes were intentional: `pnpm test -- -u`
- [ ] Commit with message: `refactor(zod): migrate <module>/<schema> to zod/v4`

---

## Commands Reference

> For comprehensive measurement guide with scripts and caveats, see [Metrics & Measurement Guide](./zod-v4-migration-metrics-guide.md).

```bash
# === Metrics ===
# IMPORTANT: Always delete incremental cache before measuring
rm -f tsconfig.tsbuildinfo

# TypeScript diagnostics (run 3 times, use median)
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics

# TypeScript trace (open in https://ui.perfetto.dev/)
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --generateTrace ./tsc-trace

# Build time (only measure at start + end, not mid-migration)
rm -rf .next && time pnpm build

# Bundle size (only measure at start + end, not mid-migration)
du -sh .next/static/chunks/

# All-in-one measurement script (see metrics guide for full script)
# bash measure-zod-migration.sh "baseline"
# bash measure-zod-migration.sh "after-batch-1"

# === Migration Progress ===
# Files still on v3
rg -l "from 'zod'" src/ --glob '*.ts' --glob '*.tsx' | rg -v "zod/v" | wc -l

# Files already on v4
rg -l "from 'zod/v4'" src/ --glob '*.ts' --glob '*.tsx' | wc -l

# Remaining nativeEnum usage
rg 'nativeEnum' src/ --glob '*.ts' --glob '*.tsx' | wc -l

# Remaining deprecated APIs
rg 'required_error|invalid_type_error|\.Enum\.|\.Values\.' src/ --glob '*.ts' | wc -l

# === Testing ===
# Run all tests
pnpm test

# Run specific schema test
pnpm test src/modules/patrimony/forms/lease/__tests__/schema.test.ts

# Update snapshots after intentional changes
pnpm test -- -u

# === Discovery (populate batch tables) ===
# Files with .transform() (Batch 1)
rg -l '\.transform\(' src/ --glob '*schema*.ts' | sort

# Files with nativeEnum (Batch 2 candidates)
rg -l 'nativeEnum' src/ --glob '*.ts' | sort

# Files with required_error/invalid_type_error (Batch 3 candidates)
rg -l 'required_error|invalid_type_error' src/ --glob '*.ts' | sort
```

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-27 | Use gradual `"zod/v4"` subpath migration instead of big-bang upgrade | Zod 3.25.76 already installed; subpath approach allows file-by-file migration with zero version conflicts; can pause at any point |
| 2026-03-27 | Use Schema Snapshot Tests + zodResolver Smoke Tests only | High ROI, low maintenance, ~550 lines total; catches silent `.default()` behavior changes that compiler cannot detect. See [testing strategy](./zod-v3-to-v4-migration-plan.md#pre-migration-testing-strategy) |
| 2026-03-27 | Batch by risk level (transform → nativeEnum → error APIs → simple) | `.transform()` + `.default()` files are the only ones with silent runtime behavior changes; other batches have compiler-guided fixes |
| | | |

---

## References

- [Migration Plan (full)](./zod-v3-to-v4-migration-plan.md) — Breaking changes catalog, testing strategy, risk analysis
- [Metrics & Measurement Guide](./zod-v4-migration-metrics-guide.md) — Detailed guide to measuring migration impact with scripts, caveats, and incremental strategy
- [Ticket Summary](./zod-v4-migration-ticket.md) — Concise version for task tracking and sub-ticket splitting
- [Zod Versioning Strategy](https://zod.dev/v4/versioning) — Official docs on the `"zod/v4"` subpath approach
- [Zod v4 Changelog](https://v4.zod.dev/v4/changelog) — Complete breaking changes list
- [SNDQ Contribution Plan](../sndq-contribution-plan.md) — Pillar 1: FE optimization (this migration is a concrete initiative)
