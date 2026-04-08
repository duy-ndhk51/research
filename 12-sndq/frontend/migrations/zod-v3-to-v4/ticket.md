# Zod v3 → v4 Migration — Ticket Summary

Concise ticket-ready summary distilled from the full [Migration Plan](./README.md) and [Progress Tracker](./progress.md). Designed to be split into sub-tickets.

**Created**: 2026-03-27
**Updated**: 2026-04-03 (revised approach: just-in-time per-file, V3 form priority)
**Status**: Paused — `PurchaseInvoiceFormV3` has stiff deadline, resume after V3 shipped
**Ticket-ready export**: [ticket-export.md](./ticket-export.md) — standalone markdown for copy-paste into Jira/Linear
**Reference**: [Zod v4 changelog](https://zod.dev/v4/changelog) · [npm versions](https://www.npmjs.com/package/zod?activeTab=versions)

---

## Why

Zod v4 delivers **14x string**, **7x array**, **6.5x object** parsing speedup + simpler generics that improve `tsc` compile time. The `sndq-fe` codebase has **103 schema files** and **100+ forms** — performance gains compound significantly.

## Approach

Upgrade to **zod@3.25.76** (not v4.x directly):

| Reason | Detail |
|--------|--------|
| Ships v3 + v4 engines | `import { z } from "zod/v4"` enables per-file migration |
| 40M+ downloads | Proven stable in production |
| Backward-compatible | Zero breaking changes on install vs current `^3.24.2` |

Migrate **gradually** file-by-file (`"zod"` → `"zod/v4"` import), not big-bang.

---

## Pre-requisites Checklist

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | Catalog breaking changes from Zod v4 changelog | Done | 14 categories — see [Migration Plan §Breaking Changes](./README.md) |
| 2 | Verify `@hookform/resolvers` compatibility with v4 | **Done** | `@hookform/resolvers@4.1.3` uses Standard Schema (`@standard-schema/utils`), peer dep `"zod": "^3.25.76 \|\| ^4.1.8"` — **native compatible** |
| 3 | Define test types with rationale | Done | Schema Snapshot + zodResolver Smoke — see [Migration Plan §Testing](./README.md) |
| 4 | Audit all 100+ forms: list, priority, complexity, route | **Pending** | Identify unused forms, rank by business priority |
| 5 | Capture baseline metrics | **Pending** | `tsc --diagnostics`, `next build`, bundle size |
| 6 | Upgrade `zod` to 3.25.76 in `package.json` | **Pending** | Verify zero regressions after install |

---

## Test Strategy

Two test types only — high ROI, low boilerplate:

| Test | Purpose | Effort |
|------|---------|--------|
| **Schema Snapshot Tests** (Vitest, factory pattern) | Catch silent `.default()` behavior changes, error structure drift | ~3-4h for 13 critical files |
| **zodResolver Smoke Tests** (Vitest) | Regression guard for React Hook Form integration (confirmed compatible) | ~30min, ~60 lines |

### Why these two

- **Schema Snapshots** directly target the most dangerous risk: `.default()` short-circuit produces different data with no TypeScript or runtime error. A reusable `describeSchema()` factory generates 3-4 tests per schema from fixtures — near-zero boilerplate per file.
- **zodResolver Smoke** is a regression guard — `@hookform/resolvers@4.1.3` already confirmed compatible via Standard Schema (`peer dep: "zod": "^3.25.76 || ^4.1.8"`). The test prevents regressions if resolvers/Zod updates change Standard Schema behavior.

### Why NOT other test types

| Rejected | Reason |
|----------|--------|
| E2E (Playwright) | 100+ forms × ~100 LOC each = prohibitive; brittle selectors; slow CI |
| Component Render (RTL) | Deep provider tree mocking; tests React, not Zod behavior |
| Property-Based (fast-check) | Overkill for known breaking changes; complex generator setup |
| Contract/Type Tests | Redundant — `tsc --noEmit` already covers all type changes |

---

## Migration Order (4 Batches)

Start with **low-business-priority, easy-to-test forms** to recognize patterns before touching critical business forms.

| Batch | Files | Risk | Rationale |
|-------|-------|------|-----------|
| 1 — Transform files | 13 | CRITICAL | `.transform()` + `.default()` = silent data change |
| 2 — nativeEnum files | ~30 | HIGH | `.Enum`/`.Values` removed in v4 — runtime crash |
| 3 — Error customization | ~27 | MEDIUM | `required_error`/`invalid_type_error` removed |
| 4 — Simple schemas | remaining | LOW | Straightforward import swap |

### Per-file workflow

```
1. Write snapshot test (import from "zod" — v3 baseline)
2. Run test → generate baseline snapshot
3. Change import: "zod" → "zod/v4"
4. Run test → compare snapshot diff
   - No diff → done
   - Diff → investigate (.default()→.prefault(), restructure, or accept)
5. tsc --noEmit (ensure no type errors)
6. Manual QA in browser
7. Commit
```

---

## Key Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `.default()` short-circuits silently | Wrong data in forms — no error | Schema snapshot tests |
| `@hookform/resolvers` incompatible | ~~100% forms break~~ **RESOLVED** | `@hookform/resolvers@4.1.3` uses Standard Schema — native v4 compatible. Smoke test guards against regressions. |
| `nativeEnum .Enum/.Values` removed | Runtime crash on accessor | Batch 2 systematic replacement |
| `z.object()` defaults in optional fields | Unexpected keys in parsed output | Snapshot tests catch new keys |
| `packages/ui` version mismatch | **None** — ui has no Zod imports | No action needed |

---

## Metrics to Track

> Full measurement guide with scripts, caveats, and reporting templates: [Metrics & Measurement Guide](./metrics-guide.md)

### Primary Metrics (measure every batch)

| Metric | Command | Why Primary |
|--------|---------|-------------|
| **`tsc` Instantiations** | `rm -f tsconfig.tsbuildinfo && tsc --noEmit --diagnostics` | Exact count — deterministic, not affected by CPU. Best for proving value. |
| **`tsc` Check time** | Same command — "Check time" line (median of 3 runs) | Human-readable: "saved X seconds per type-check" |
| Migration progress | `rg -l "from ['\"]zod/v4['\"]" src/ \| wc -l` | Tracking & velocity |
| Deprecated APIs | `rg -c 'nativeEnum\|required_error\|invalid_type_error' src/` | Target: 0 |

### Secondary Metrics (measure start + end only)

| Metric | Command | Why Not Incremental |
|--------|---------|---------------------|
| `next build` time | `rm -rf .next && time pnpm build` | Dual-import temporarily increases build time mid-migration |
| Bundle size | `du -sh .next/static/chunks/` | Both engines bundled during gradual migration (+30-80 kB temp) |

### Key Caveats

1. **Always delete `tsconfig.tsbuildinfo`** before measuring (incremental cache gives wrong results)
2. **Run `tsc` 3 times, use median** — timing fluctuates ±5-10% per run
3. **Bundle size temporarily increases** during dual-import phase — only compare baseline vs. final
4. **Kill `next dev`** before measuring — competing TypeScript checker

---

## Sub-tickets

### Revised Approach (2026-04-03)

**Key change**: Step 3 (test factory) and Step 6 (Batch 1 migration) are **merged** into a single just-in-time workflow. Instead of writing all 13 snapshot tests upfront, each test is written immediately before migrating that file. Benefits:
- Focus on 1 schema at a time (no context switching across 13 files)
- No stale snapshots (test written right before migration)
- Ship value immediately (each migrated file = shippable unit)
- Fixtures informed by reading the schema (understand before you test)

### Phase 1: Setup (1h)

| # | Ticket | Estimate | Status |
|---|--------|----------|--------|
| 1 | **[Research] Verify `@hookform/resolvers` v4 compat** | ~~2h~~ | ✅ Done |
| 2 | **[Setup] Upgrade `zod` to `3.25.76`** — install, verify zero regressions, `pnpm why zod` | 1h | ⬜ |
| 3 | **[Setup] Create test infra only** — `schema-test-factory.ts` + `zod-resolver-compat.test.ts` | 1h | ⬜ (depends #2) |
| 4 | **[Audit] List & prioritize all 100+ forms** | 3h | ⬜ |
| 5 | **[Audit] Capture baseline metrics** | ~~1h~~ | ✅ Done |

### Phase 2: Batch 1 — Test + Migrate per-file (~8-9h)

Each file = write snapshot test (v3) → migrate import → review diff → fix → QA → commit.

| # | Schema File | .default | .transform | Est. | Status |
|---|-------------|----------|------------|------|--------|
| 10 | `patrimony/forms/property/schema.ts` | 0 | 1 | 20m | ⬜ |
| 13 | `contact-book/.../form/schema.ts` | 0 | 1 | 15m | ⬜ |
| 11 | `patrimony/forms/lease/.../lease-deposit/schema.ts` | 1 | 1 | 20m | ⬜ |
| 7 | `patrimony/forms/lease/revision/schema.ts` | 0 | 3 | 30m | ⬜ |
| 8 | `patrimony/forms/building/schema.ts` | 0 | 2 | 30m | ⬜ |
| 9 | `financial/forms/purchase-invoice-v2-steward/schema.ts` | 5 | 3 | 35m | ⬜ |
| 5 | `financial/forms/cost-settlement/.../schema.ts` | 6 | 2 | 45m | ⬜ |
| 6 | `financial/forms/close-fiscal-year/schema.ts` | 9 | 2 | 45m | ⬜ |
| 12 | `fee-management/FeeConfiguratorForm/schema.ts` | 7 | 1 | 45m | ⬜ |
| 2 | `financial/forms/purchase-invoice-v2/schema.ts` | 11 | 3 | 40m | ⬜ |
| 4 | `components/contact/schema.ts` | 9 | 4 | 45m | ⬜ |
| 3 | `financial/forms/purchase-invoice/schema.ts` | 18 | 3 | 60m | ⬜ |
| 1 | `patrimony/forms/lease/schema.ts` | **21** | 4 | 90m | ⬜ |

> **Note**: #2 (`purchase-invoice-v2/schema.ts`) is also used by `PurchaseInvoiceFormV3` — migrating benefits both V2 and V3.

### Phase 3: Batches 2-4 (~3-4d)

| # | Ticket | Estimate | Depends on |
|---|--------|----------|------------|
| 7 | **[Migrate] Batch 2: ~30 nativeEnum files** — `nativeEnum` → `enum` replacement | 1-2d | Phase 2 |
| 8 | **[Migrate] Batch 3: ~27 error customization files** — `required_error` → `error` parameter | 1d | #7 |
| 9 | **[Migrate] Batch 4: Remaining simple files** — straightforward import swap | 1d | #8 |

### Phase 4: Finalize (0.5d)

| # | Ticket | Estimate | Depends on |
|---|--------|----------|------------|
| 10 | **[Finalize] Post-migration metrics + cleanup** — compare with baseline, optional upgrade to `zod@4.x`, revert imports from `"zod/v4"` → `"zod"` | 0.5d | #9 |

---

## Related Documents

- [Ticket Export](./ticket-export.md) — **standalone markdown for copy-paste into ticket system**
- [Full Migration Plan](./README.md) — breaking changes catalog, testing strategy details, risk analysis
- [Step 3 Deep-Dive: Test Setup](./step3-test-setup.md) — factory code, zodResolver smoke test, 13-file audit table
- [Migration Progress Tracker](./progress.md) — per-file checklist, batch tables, metrics dashboard
- [Baseline Analysis](./baseline-analysis.md) — pre-migration tsc + build benchmarks with bottleneck analysis
- [How to Measure](./how-to-measure.md) — practical runbook after each batch
- [Metrics & Measurement Guide](./metrics-guide.md) — detailed guide to measuring migration impact
- [Metrics Record](./metrics-record.md) — actual recorded measurement data per batch
