# PR Description: Upgrade react-hook-form + @hookform/resolvers

Copy-paste ready for GitHub PR.

---

## What

- Upgrade `@hookform/resolvers` from v4.1.3 to **v5.2.2** (native Zod v4 `zodResolver` support since [v5.1.0](https://github.com/react-hook-form/resolvers/releases/tag/v5.1.0))
- Upgrade `react-hook-form` from 7.54.2 to **7.72.1** (required peer dep `>=7.55.0`)
- Add centralized `zodResolver` wrapper (`src/lib/form/zod-resolver.ts`)
- Add `useZodForm` helper (`src/lib/form/useZodForm.ts`) — enforces `defaultValues` at the type level
- Add ESLint `no-restricted-imports` rule to prevent direct `@hookform/resolvers/zod` import

## Why

Resolvers v5 introduced separate `z.input` / `z.output` type inference. Our schemas use `.default()` extensively (~170 calls across ~40 files), which makes input and output types diverge — causing **168 type errors** across 71 files.

Rather than modifying 71 schema files without test coverage, the wrapper collapses both types back to `z.infer` (= `z.output`), restoring pre-v5 behavior. **Zero runtime change** — the `as` cast is erased at compile time.

This is a prerequisite for the Zod v4 migration. Resolvers v5.1.0+ has a native `zodResolver` for Zod v4 schemas, which v4.x did not.

## Impact

### TypeScript compiler (3 runs, median, `--incremental false`)

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Instantiations | 29,150,241 | 12,282,340 | **-57.9%** |
| Types | 1,691,552 | 811,954 | **-52.0%** |
| Check time | 117.08s | 72.93s | **-37.7%** |
| Memory | 6.46 GB | 2.81 GB | **-56.5%** |

The improvement comes from the wrapper eliminating 4-overload resolution at ~135 call sites. The original resolver tries 4 signatures (Zod v3 non-raw, v3 raw, v4 non-raw, v4 raw) — each walking the full schema type tree twice (input + output). The wrapper short-circuits this to 1 signature with 1 schema walk.

### Runtime

**Zero change.** The wrapper is a compile-time passthrough. No form logic, validation, or submit behavior is affected.

## Tradeoffs

The wrapper suppresses the v5 input/output type distinction:

| Tradeoff | Severity | Detail |
|----------|----------|--------|
| Fields with `.default()` typed as required instead of optional in form state | Low | Safe when `defaultValues` is provided. `useZodForm` enforces this at the type level for new forms. |
| `schemaOptions` loses specific type checking | Zero | No call site uses it |
| `raw: true` return type not differentiated | Zero | No call site uses it |

## Migration path

The wrapper is temporary. When migrating to Zod v4, the ideal path is to remove explicit `useForm<T>()` generics and let `zodResolver` infer types directly ([per Zod creator's recommendation](https://github.com/colinhacks/zod/issues/4992)). At that point, the wrapper can be deleted.

## Test plan

- [x] `pnpm type-check` passes (0 errors)
- [x] `pnpm lint` passes
- [x] `pnpm build` succeeds (compile phase 4.7 min — within baseline range 3.5–4.9 min)
- [x] Manual QA: tested forms with `.default()` fields (purchase invoice, lease, cost settlement) — no behavior change
- [x] Verified `useZodForm` enforces `defaultValues` at compile time
