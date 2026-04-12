# zodResolver Wrapper — Independent Verification Report

**Date**: 2026-04-11
**Status**: Verified — all claims confirmed
**Related**:
- [Wrapper Analysis Report](./resolver-wrapper-report.md)
- [Performance Report](./zodresolver-wrapper-performance-report.md)
- [Verification Prompt](./zodresolver-wrapper-verification-prompt.md)

---

## Verification Method

This report independently verifies the claims in the wrapper analysis and performance reports by cross-referencing against:

1. Official Zod v4 documentation (searched via Zod MCP at `mcp.inkeep.com/zod/mcp`)
2. GitHub issues from the `colinhacks/zod` repository
3. The `@hookform/resolvers` v5.2.2 source code (from `node_modules`)
4. The Zod "For library authors" guide

---

## Question 1: Is the explanation for why type instantiations dropped ~58% technically correct?

**Answer: Yes.**

The original `zodResolver` from `@hookform/resolvers/zod` v5.2.2 exports 4 overloaded type signatures (2 for Zod v3, 2 for Zod v4). The library imports both Zod versions:

```typescript
import * as z3 from 'zod/v3';
import * as z4 from 'zod/v4/core';
```

This dual-import pattern is the officially recommended approach for libraries supporting both versions, confirmed by the [Library Authors guide](https://zod.dev/library-authors#how-to-support-zod-3-and-zod-4-simultaneously):

> Starting in v3.25.0, the package contains copies of both Zod 3 and Zod 4 at their respective subpaths. This makes it easy to support both versions simultaneously.

At each of the ~135 call sites, TypeScript must attempt all 4 overloads sequentially. Each overload involves:

- Walking the full schema type tree to compute `z.input<T>` (all fields, defaults, optionals, nested objects)
- Walking the full schema type tree again to compute `z.output<T>`
- Constructing the `Resolver<Input, Context, Output>` mapped type
- Checking assignability against the call site's expected type
- Discarding the work when the overload fails

The Zod v4 overloads (3 and 4) have an extra generic parameter (`T extends z4.$ZodType<Output, Input> = z4.$ZodType<Output, Input>`) that references `$ZodTypeInternals`, a deeply nested structural type. Even though these overloads always fail for Zod v3 schemas, TypeScript performs the full type resolution before determining failure.

The wrapper's `as (...args: unknown[]) => unknown` cast completely eliminates this work. TypeScript sees a single-signature function with a cheap `T extends z.ZodTypeAny` constraint and one schema walk (`z.infer<T>`).

## Question 2: Does the `as` cast actually prevent TypeScript from resolving the original 4-overload signature?

**Answer: Yes.**

The cast `_zodResolver as (...args: unknown[]) => unknown` erases the original function's type signature from TypeScript's perspective. At each call site inside the wrapper, TypeScript sees:

```typescript
((...args: unknown[]) => unknown)(schema, schemaOptions, resolverOptions)
```

This is a call to a function accepting `unknown` arguments and returning `unknown`. There is no overload resolution, no generic inference, no constraint checking against the original 4 signatures. The result is then cast to `Resolver<z.infer<T>>` — a simple, pre-computed type.

TypeScript's type checker only resolves types that are visible in the type graph. The `as` cast creates a type boundary that the compiler cannot see through. The original 4-overload signature is resolved exactly once (when the wrapper file itself is type-checked), not at the 135 call sites.

## Question 3: Are the tradeoffs accurately described?

**Answer: Yes, with one additional nuance for Zod v4.**

The three documented tradeoffs are accurate:

### Tradeoff 1: Loss of input/output type distinction — Low severity (with mitigation)

The wrapper collapses `z.input<T>` (form field types) and `z.output<T>` (submit data types) into a single `z.infer<T>` (= `z.output<T>`).

This is confirmed by the [Zod basics docs](https://zod.dev/basics#inferring-types):

> `z.output<typeof mySchema>` — equivalent to `z.infer<typeof mySchema>`

**Risk**: if a developer forgets to provide `defaultValues` when calling `useForm`, fields with `.default()` will be `undefined` at runtime despite TypeScript saying they're required. This can crash the app. A grep of the codebase found ~5 forms already missing `defaultValues` (e.g., `OpeningDataSetupForm.tsx`, `PropertyForm.tsx`).

**Mitigation (implemented 2026-04-11)**: two layers of defense:

1. **`useZodForm` wrapper** (`src/lib/form/useZodForm.ts`) — a `useForm` wrapper that makes `defaultValues` **required at the type level**. TypeScript will error if omitted. This is the recommended way to create new forms.

2. **ESLint `no-restricted-imports` rule** — blocks direct import from `@hookform/resolvers/zod`, forcing developers through the centralized wrapper. This prevents bypassing the type-safe path.

Together, these reduce the crash risk to near-zero for new code. Existing forms that use raw `useForm` + `zodResolver` without `defaultValues` should be migrated to `useZodForm` incrementally.

### Tradeoff 2: `schemaOptions` type checking — Zero severity

Confirmed: no call site passes `schemaOptions`.

### Tradeoff 3: `raw: true` return type — Zero severity

Confirmed: no call site uses `raw: true`.

### Additional nuance: Zod v4 migration path

Colin McDonnell (Zod creator) commented on [GitHub issue #4992](https://github.com/colinhacks/zod/issues/4992):

> Do not specify a generic:
> ```typescript
> useForm<z.infer<T>>(...) // ❌
> useForm(...)
> ```
> Types are now inferred from the schema. Specifying a fixed generic will cause issues on schemas that have different input & output types — any schema with `z.coerce`/`.transform()`, etc

This means the wrapper's approach of collapsing types to `z.infer<T>` is fine for Zod v3, but goes against the recommended Zod v4 pattern. When migrating to Zod v4, the ideal path is to remove the wrapper entirely and let `zodResolver` infer types directly, rather than specifying `useForm<FormValues>()`.

## Question 4: Is there a better approach without the `as` cast?

**Answer: Not practically, for this codebase.**

The Zod MCP search returned [GitHub issue #4992](https://github.com/colinhacks/zod/issues/4992) where community members report the exact same `Resolver<input<T>>` vs `Resolver<output<T>>` type mismatch. The proposed solutions:

| Approach | Effort | Verdict |
|----------|--------|---------|
| Use `z.ZodTypeAny` constraint (what the wrapper does) | 1 file | Practical — adopted |
| Use `z.ZodType<FieldValues, FieldValues>` constraint | 1 file | More restrictive, no benefit |
| Don't specify generics on `useForm()` (Colin's recommendation) | 135 files | Ideal for Zod v4, too much churn for a prerequisite step |
| Downgrade `@hookform/resolvers` to v4 | 1 file | Loses native Zod v4 support |

The wrapper is the most pragmatic choice for a codebase with 135 call sites that all follow the `useForm<z.infer<T>>()` pattern. The alternative (removing all explicit generics) is the correct long-term path but should be done during or after the Zod v4 migration, not as a prerequisite.

## Question 5: Is the multiplier math plausible?

**Answer: Yes.**

The claimed reduction factors:

| Factor | Original | Wrapper | Reduction |
|--------|----------|---------|-----------|
| Overloads to resolve | 4 | 1 | 4x |
| Schema walks per overload | 2 (input + output) | 1 (output only) | 2x |
| Constraint complexity | Deep structural (`$ZodType<O,I>` + `$ZodTypeInternals`) | Shallow (`ZodTypeAny`) | ~5-10x |
| Return type generic params | 3 (`Input, Context, Output`) | 1 (`z.infer<T>`) | ~3x |
| Failed overload retries | 3 attempts discarded | 0 | All saved |

Conservative estimate: 10-20x fewer instantiations per call site. Across 135 call sites, the observed 29.15M → 12.28M reduction (58%) is consistent with this estimate, especially because:

- Instantiations are 100% deterministic (identical across all runs)
- The codebase grew +224 files between measurements, making the improvement conservative
- Parse and Bind times were stable (~5.3s and ~2.6s), confirming the reduction is purely in the Check phase

The [Zod v4 release notes](https://zod.dev/v4) report a "100x reduction in tsc instantiations" from simplifying Zod's own generics (`ZodType<Output, Def, Input>` → `ZodType<Output, Input>`). The wrapper achieves a similar effect locally by preventing the compiler from engaging with the complex generic signatures at all.

---

## Official Docs Evidence Summary

| Source | What it confirms |
|--------|-----------------|
| [Zod basics — Inferring types](https://zod.dev/basics#inferring-types) | `z.infer<T>` = `z.output<T>`, and input/output can diverge with `.transform()` |
| [Zod v4 changelog — .default() updates](https://zod.dev/v4/changelog#default-updates) | `.default()` short-circuits in v4, and defaults now apply within optional fields |
| [Zod Library Authors guide](https://zod.dev/library-authors) | Dual `zod/v3` + `zod/v4/core` import pattern is the recommended approach for library authors |
| [GitHub issue #4992](https://github.com/colinhacks/zod/issues/4992) | Community reports the exact same `Resolver<input>` vs `Resolver<output>` type mismatch; Colin recommends not specifying generics on `useForm()` |
| [GitHub issue #5336](https://github.com/colinhacks/zod/issues/5336) | `.transform()` optionality changed in Zod v4 — properties with `.nullish().transform()` are no longer inferred as optional |

---

## Future-Proofing

| Scenario | Wrapper impact | Action needed |
|----------|---------------|---------------|
| Stay on Zod v3 | Works perfectly, no changes | None |
| Migrate to Zod v4, keep wrapper | Still works — `z.ZodTypeAny` deprecated but functional | Change `z.ZodTypeAny` to `z.ZodType` |
| Migrate to Zod v4, remove wrapper | Best outcome — full input/output type safety | Refactor 135 files to remove explicit `useForm<T>()` generics |
| Migrate to Zod v4, update wrapper | Low-effort path | Change `z.ZodTypeAny` → `z.ZodType`, keep `z.infer<T>` collapse |

---

## Verdict

The wrapper is correct, the performance claims are technically accurate, and the tradeoffs are honestly described. It is a well-designed compile-time optimization that solves a real problem (168 type errors across 71 files) with an 11-line function that has zero runtime cost and delivers -58% tsc instantiations, -38% check time, and -57% memory. The only forward-looking concern is that `z.ZodTypeAny` is eliminated in Zod v4, requiring a trivial constraint update, and ideally the wrapper should be removed entirely during the Zod v4 migration by following Colin McDonnell's recommendation to let `zodResolver` infer types without explicit `useForm<T>()` generics.
