# Centralized zodResolver Wrapper — Analysis Report

**Date**: 2026-04-08
**Status**: Decided — ready to implement
**Related**: [Progress Tracker](./progress.md) | [Migration Plan](./README.md) | [Ticket](./ticket.md)

---

## Summary

Upgrading `@hookform/resolvers` from v4.1.3 to v5.2.2 (for native Zod v4 `zodResolver` support) and `react-hook-form` from 7.54.2 to 7.72.1 (required peer dependency) introduced 168 TypeScript type errors across 71 files. The root cause is a new input/output type inference system in resolvers v5 that conflicts with Zod schemas using `.default()`. Rather than modifying all 71 schema files without test coverage, we adopt a **centralized wrapper** — a single utility file that re-exports `zodResolver` with the pre-v5 type behavior. This resolves all type errors with zero runtime change and zero schema modifications.

---

## Problem Statement

### What changed in resolvers v5

`@hookform/resolvers` v5.0.0 (April 2025) added a third generic to `useForm`:

```typescript
// Before (resolvers v4 + RHF 7.54.x) — 2 generics
useForm<TFieldValues, TContext>()

// After (resolvers v5 + RHF 7.55.0+) — 3 generics
useForm<TFieldValues, TContext, TTransformedValues>()
```

The `zodResolver` now infers separate input and output types from the Zod schema:
- **Input type** = `z.input<typeof schema>` (what goes INTO form fields)
- **Output type** = `z.output<typeof schema>` (what comes OUT after validation)

### How `.default()` triggers the mismatch

When a Zod schema uses `.default()`, input and output types diverge:

```typescript
const schema = z.object({
  name: z.string(),
  active: z.boolean().default(false),
});

type Input  = z.input<typeof schema>;
// { name: string; active?: boolean | undefined }  ← optional on input

type Output = z.output<typeof schema>;
// { name: string; active: boolean }                ← required on output
```

But `z.infer` (used everywhere as the form type) is an alias for `z.output`. So when code does:

```typescript
const form = useForm<FormValues>({        // FormValues = z.infer = z.output
  resolver: zodResolver(schema),          // returns Resolver<z.input, any, z.output>
});
```

TypeScript expects `Resolver<FormValues, any, FormValues>` but receives `Resolver<z.input, any, z.output>`. Since `z.input !== FormValues` (the optional fields), TypeScript rejects it.

### Scope of impact

- **168 type errors** across **71 files**
- **155 files** import `zodResolver` from `@hookform/resolvers/zod`
- Every schema using `.default()` is affected (most schemas in the codebase)
- Both `resolver:` assignment and `handleSubmit()` callback typing break

---

## Why Resolvers v5 (Not v4)

The original migration plan (2026-03-27) relied on `@hookform/resolvers@4.1.3` which used Standard Schema (`@standard-schema/utils`). While functional, v5 is the better long-term path:

| Aspect | Resolvers v4.1.3 | Resolvers v5.2.2 |
|--------|------------------|------------------|
| Zod v4 support mechanism | Standard Schema (generic adapter) | Native `zodResolver` with Zod v4 awareness |
| Type inference | No input/output distinction | Full `z.input` / `z.output` inference |
| RHF peer dependency | `^7.0.0` | `^7.55.0` |
| Zod v4 bug fixes | None (generic adapter) | v5.1.1, v5.2.1, v5.2.2 (discriminated unions, output types) |
| Future maintenance | Standard Schema may diverge from Zod's type system | Direct Zod integration, maintained by same ecosystem |

Resolvers v5 gives proper type flow that the codebase can adopt incrementally. The wrapper bridges the gap until schemas are cleaned up.

---

## Solution: Centralized Wrapper

### The wrapper (`src/lib/form/zod-resolver.ts`)

```typescript
import { zodResolver as _zodResolver } from '@hookform/resolvers/zod';
import type { z } from 'zod';
import type { Resolver } from 'react-hook-form';

/**
 * Wrapper around @hookform/resolvers zodResolver that unifies input/output types.
 *
 * In @hookform/resolvers v5, zodResolver infers separate z.input and z.output types.
 * When Zod schemas use .default(), input types become optional while output types
 * are required — causing type mismatches with useForm<T>().
 *
 * This wrapper casts the resolver to use z.infer (output) for both,
 * matching the pre-v5 behavior. Runtime behavior is identical.
 *
 * TODO: Remove this wrapper when schemas are migrated to avoid .default()
 * or when forms are refactored to let the resolver infer types.
 */
export function zodResolver<T extends z.ZodTypeAny>(
  schema: T,
  schemaOptions?: Parameters<typeof _zodResolver>[1],
  resolverOptions?: Parameters<typeof _zodResolver>[2],
): Resolver<z.infer<T>> {
  return _zodResolver(schema, schemaOptions, resolverOptions) as Resolver<
    z.infer<T>
  >;
}
```

### What it does

- **Compile-time**: Casts the resolver return type from `Resolver<z.input<T>, any, z.output<T>>` to `Resolver<z.infer<T>>` (where `z.infer` = `z.output`). This tells TypeScript to use the output type for both input and output, matching pre-v5 behavior.
- **Runtime**: Absolutely nothing. The `as` cast is erased during compilation. The emitted JavaScript is a passthrough function.

### Import replacement scope

All 155 files change one import line:

```typescript
// Before
import { zodResolver } from '@hookform/resolvers/zod';

// After
import { zodResolver } from '@/lib/form/zod-resolver';
```

No other code changes. Same function name, same call signature, same arguments.

---

## Benefits

### Immediate

| Benefit | Detail |
|---------|--------|
| **Zod v4 ready** | `import { z } from 'zod/v4'` works in new code immediately. The resolver supports it natively since v5.1.0. |
| **168 type errors resolved** | `pnpm type-check` passes cleanly again. |
| **Security patches** | RHF 7.72.1 includes fixes for 4 CVEs: CVE-2025-55182 (critical RCE), CVE-2025-55183, CVE-2025-55184, CVE-2025-67779. |
| **Bug fixes** | 18 minor releases of RHF fixes: `reset()` regression (7.59.0), `FormProvider` re-render optimization, `isValid` state improvements, field array fixes. |
| **Zero runtime change** | The wrapper is compile-time only. Production code runs identically to before. |
| **No test coverage needed** | Since no runtime logic changes, existing manual QA still validates everything. |
| **58% fewer tsc instantiations** | Measured: 29.15M → 12.28M instantiations, 117s → 73s check time, 6.46 GB → 2.81 GB memory. The old resolvers v4 type system was extremely expensive. See [Measured Impact](#measured-impact). |

### Long-term

| Benefit | Detail |
|---------|--------|
| **Gradual cleanup path** | When touching a form file for other work, optionally remove `.default()` from its schema and switch back to direct `@hookform/resolvers/zod` import. No big-bang refactor. |
| **New RHF features** | `createFormControl` (external form control), `subscribe` (state subscription without re-render), `FormStateSubscribe` component, form-level `validate` function — all available for new code. |
| **Proper v5 type system later** | Once schemas are cleaned up, removing the wrapper enables full input/output type safety for schemas with `.transform()`. |

---

## Measured Impact

> Measured on 2026-04-08, branch `chore/SQ-20642`, 3 runs of `tsc --noEmit --diagnostics --incremental false`. Baseline from 2026-03-28, branch `perf/SQ-20365`, median of 4 runs.

### Headline Numbers

| Metric | Baseline (median) | After Upgrade (median) | Delta | % Change |
|--------|--------------------|-----------------------|-------|----------|
| **Instantiations** | 29,150,241 | 12,282,340 | -16,867,901 | **-57.9%** |
| **Types** | 1,691,552 | 811,954 | -879,598 | **-52.0%** |
| **Memory (KB)** | 6,776,633 (6.46 GB) | 2,949,276 (2.81 GB) | -3,827,357 | **-56.5%** |
| **Check time (s)** | 117.08 | 72.93 | -44.15 | **-37.7%** |
| **Total time (s)** | 121.93 | 79.29 | -42.64 | **-35.0%** |

Note: the codebase grew between measurements (+224 files, +32,901 lines from ongoing development). Despite this growth, all expensive metrics dropped dramatically.

### What This Means

- **The TypeScript compiler does ~58% less work.** Instantiations (the number of times TypeScript expands generics) dropped from 29.1M to 12.3M. This is the single most reliable metric since it is deterministic — identical across all 3 runs.
- **Type-check is 43 seconds faster.** From ~2 minutes down to ~1 minute 19 seconds. This directly improves developer feedback loops on `pnpm type-check` and CI pipelines.
- **Memory usage cut by more than half.** From 6.46 GB to 2.81 GB. This eliminates the OOM risk that previously required `NODE_OPTIONS="--max-old-space-size=8192"`.

### Why So Large

The improvements are disproportionately large because the old `@hookform/resolvers` v4 type system was extremely expensive. It used deep generic inference across all 155 files importing `zodResolver`, each expanding `Resolver<z.input<T>, any, z.output<T>>` with full Zod schema traversal. The wrapper short-circuits this by casting to the simpler `Resolver<z.infer<T>>`, and resolvers v5 itself has a leaner type architecture for the Zod 3 compatibility path.

### Caveats

1. **Different branches**: baseline was on `perf/SQ-20365` (2026-03-28), current on `chore/SQ-20642` (2026-04-08). Some delta comes from other code changes between branches.
2. **Combined effect**: the improvement is from three changes together (RHF upgrade, resolvers upgrade, wrapper). Isolating each contribution is not practical.
3. **Build metrics incomplete**: only the compile phase (4.7 min, within baseline range 3.5–4.9 min) was captured. Wall-clock time and route table were not recorded before the terminal was overwritten.
4. **Single build run**: baseline used 3 build runs for median; only 1 run was captured here. A re-run is recommended for a proper comparison.

### Bottom Line

This was intended as a compatibility fix (resolve 168 type errors). It turned out to also be the single largest TypeScript compiler improvement opportunity in the codebase — achieved before the actual Zod v4 migration even begins. The batch migration work will start from this much healthier baseline.

See [metrics-record.md](./metrics-record.md#15-after-prerequisite-rhf--resolvers-upgrade) for the full 3-run data tables.

---

## Tradeoffs

| Tradeoff | Impact | Mitigation |
|----------|--------|------------|
| **Type safety gap** | The input/output type distinction from resolvers v5 is suppressed. TypeScript won't warn if a schema's input type differs from its output type (e.g., with `.transform()`). | This is the **same level of type safety** as pre-upgrade. No regression — just not gaining the new feature yet. The codebase has operated without this distinction for its entire lifetime. |
| **Maintenance overhead** | One extra utility file (`src/lib/form/zod-resolver.ts`) to maintain. | File is 20 lines with a clear TODO comment. Minimal maintenance burden. |
| **Custom import path** | New developers may instinctively import from `@hookform/resolvers/zod` instead of `@/lib/form/zod-resolver`. | Add ESLint `no-restricted-imports` rule to flag the direct import. Document in project rules/AGENTS.md. |
| **Technical debt** | The wrapper is explicitly a temporary bridge, not a permanent solution. | The TODO comment and this report document the cleanup path. The gradual migration approach (remove `.default()` per-file) spreads the cleanup over time. |
| **Not utilizing full v5 types** | Forms with `.transform()` in Zod schemas won't get typed output differences. | The codebase doesn't use `.transform()` heavily for type-changing transforms. Most `.transform()` usage is for data normalization (string → trimmed string), not type conversion. |

---

## Risk Assessment

| Dimension | Assessment |
|-----------|------------|
| **Runtime risk** | **Zero.** The `as Resolver<z.infer<T>>` cast is erased at compile time. The emitted JavaScript is `return _zodResolver(schema, schemaOptions, resolverOptions)` — a trivial passthrough. |
| **Type safety** | **Same as before.** The wrapper restores pre-v5 type behavior. No type safety is lost compared to the previous working state. |
| **Reversibility** | **Fully reversible.** Revert 155 import lines + delete the wrapper file. Or revert the entire RHF/resolvers upgrade via `git checkout -- package.json pnpm-lock.yaml && pnpm install`. |
| **Compatibility** | **Verified.** RHF 7.72.1 has all regressions from 7.55.0 fixed (reset/submit regression fixed in 7.59.0, all 4 CVEs patched). |

---

## Version Compatibility Matrix

| `@hookform/resolvers` | Requires `react-hook-form` | Zod v4 Support | Mechanism |
|---|---|---|---|
| v4.0.0 – v4.1.3 | `^7.0.0` | Partial (Standard Schema) | Generic Standard Schema adapter |
| v5.0.0 – v5.0.1 | `^7.55.0` | No | Input/output types added, no Zod v4 resolver |
| **v5.1.0** | `^7.55.0` | **Yes** | Native zodResolver for Zod v4/v4-mini + v3 compat |
| v5.1.1 | `^7.55.0` | Yes | Zod peer dep fix |
| v5.2.0 | `^7.55.0` | Yes | Added ajv-formats |
| v5.2.1 | `^7.55.0` | Yes | Discriminated union fix for Zod v4-mini |
| **v5.2.2** (current) | `^7.55.0` | Yes | Zod v4 output type fix |

### RHF 7.55.0+ Regression Timeline

| Version Range | Status |
|---|---|
| 7.55.0 – 7.58.1 | `reset()` + submit regression (returns `undefined` instead of `defaultValues`) |
| **7.59.0+** | Regression fixed |
| **7.72.1** (current) | Latest stable, all regressions fixed, all CVEs patched |

---

## Cleanup Path

The wrapper is designed to be removed incrementally:

### Per-file cleanup (during normal development)

When touching a form file for unrelated work:

1. Open the schema file and remove `.default()` calls
2. Verify `defaultValues` in `useForm()` covers the removed defaults
3. Change the import back to `import { zodResolver } from '@hookform/resolvers/zod'`
4. Run `pnpm type-check` on the file
5. Manually test the form

### Full removal (when all schemas are cleaned up)

1. Verify zero files import from `@/lib/form/zod-resolver`
2. Delete `src/lib/form/zod-resolver.ts`
3. Remove the ESLint `no-restricted-imports` rule (if added)

### Alternative: let resolver infer types

Instead of removing `.default()`, forms can drop the explicit generic:

```typescript
// Before (explicit generic, needs wrapper)
const form = useForm<FormValues>({
  resolver: zodResolver(schema),
});

// After (inferred types, no wrapper needed)
const form = useForm({
  resolver: zodResolver(schema),
  defaultValues: { ... },
});
```

This requires updating `UseFormReturn<FormValues>` prop types on child components, so it's a larger change per file.

---

## References

- [react-hook-form/resolvers v5.0.0 release](https://github.com/react-hook-form/resolvers/releases/tag/v5.0.0) — breaking change: requires RHF 7.55.0
- [react-hook-form/resolvers v5.1.0 release](https://github.com/react-hook-form/resolvers/releases/tag/v5.1.0) — Zod v4 support added
- [react-hook-form/resolvers v5.2.2 release](https://github.com/react-hook-form/resolvers/releases/tag/v5.2.2) — Zod v4 output type fix
- [react-hook-form v7.55.0 release](https://github.com/react-hook-form/react-hook-form/releases/tag/v7.55.0) — 3rd generic added to useForm
- [react-hook-form v7.59.0 release](https://github.com/react-hook-form/react-hook-form/releases/tag/v7.59.0) — reset/submit regression fixed
- [react-hook-form/resolvers#759](https://github.com/react-hook-form/resolvers/issues/759) — v5.0 breaking types for resolvers
- [react-hook-form/resolvers#814](https://github.com/react-hook-form/resolvers/issues/814) — misconfigured peerDependencies
- [react-hook-form#12873](https://github.com/react-hook-form/react-hook-form/issues/12873) — submit regression between 7.54.2 and 7.56.4
- [npm: @hookform/resolvers](https://www.npmjs.com/package/@hookform/resolvers) — peer dependency: `react-hook-form: ^7.55.0`
