# Zod v3 → v4 Migration Plan — sndq-fe

## TL;DR

Zod v4 delivers **14x faster string parsing**, **7x faster array parsing**, and **6.5x faster object parsing** with a smaller bundle via improved tree shaking. The `sndq-fe` codebase has **~103 files** importing Zod across **100+ form schemas**, making this a high-impact but high-effort migration. The biggest risks are silent behavior changes in `.default()`, `@hookform/resolvers` compatibility, and `z.nativeEnum()` removal across ~44 files.

**Created**: 2026-03-27
**Updated**: 2026-03-27 (testing strategy finalized)
**Status**: Planning
**Estimated effort**: 5–8 days (including pre-migration tests + validation)
**Testing strategy**: Schema Snapshot Tests (primary) + zodResolver Smoke Tests (secondary) — ~550 lines, 15 files, 3-4 hours
**Ticket summary**: [Zod v4 Migration — Ticket Summary](./ticket.md) — concise version for task tracking
**Metrics guide**: [Metrics & Measurement Guide](./metrics-guide.md) — how to measure migration impact incrementally
**Metrics record**: [Metrics Record](./metrics-record.md) — actual recorded measurements

---

## Table of Contents

- [Current State Audit](#current-state-audit)
- [Zod v4 Breaking Changes — Full Catalog](#zod-v4-breaking-changes--full-catalog)
- [Impact Analysis on sndq-fe](#impact-analysis-on-sndq-fe)
- [Benefits](#benefits)
- [Risks & Mitigation](#risks--mitigation)
- [Pre-Migration Testing Strategy](#pre-migration-testing-strategy)
  - [Schema Snapshot Tests — PRIMARY](#selected-schema-snapshot-tests-vitest--primary)
  - [zodResolver Smoke Tests — SECONDARY](#selected-zodresolver-smoke-tests-vitest--secondary)
  - [Combined Testing Approach](#combined-testing-approach-how-the-two-types-work-together)
- [TypeScript Compile Time Benchmarking](#typescript-compile-time-benchmarking)
- [Migration Execution Plan](#migration-execution-plan)
- [Rollback Strategy](#rollback-strategy)
- [Post-Migration Validation Checklist](#post-migration-validation-checklist)
- [Cross-References](#cross-references)
- [References](#references)

---

## Current State Audit

### Dependency Versions

| Package | Location | Current Version |
|---------|----------|-----------------|
| `zod` | `sndq-fe/package.json` | `^3.24.2` |
| `zod` | `sndq-fe/packages/ui/package.json` | `^3.24.3` |
| `@hookform/resolvers` | Both `package.json` files | `^4.1.3` |
| `react-hook-form` | `sndq-fe/package.json` | v7 |

### Zod Usage Scale

| Pattern | Files Affected | Occurrences |
|---------|---------------|-------------|
| `import ... from 'zod'` | **~103 files** | 103 |
| `z.infer<>` / `z.input<>` / `z.output<>` | ~100 files | **~170+** |
| `z.object()` / `z.string()` / `z.number()` / `z.boolean()` / `z.date()` / `z.optional()` / `z.nullable()` | ~100 files | **Hundreds** |
| `.transform()` / `.refine()` / `.superRefine()` / `.coerce` / `.pipe()` | ~70 files | **~140+** |
| `z.enum()` / `z.nativeEnum()` / `z.literal()` / `z.union()` / `z.discriminatedUnion()` / `z.intersection()` | ~75 files | **~200+** |
| `.describe()` / `.merge()` / `.superRefine()` (deprecated patterns) | ~50 files | ~100+ |
| `message:` / `invalid_type_error` / `required_error` / `errorMap` / `.or()` / `.and()` | ~27 files | ~80+ |
| `z.nativeEnum()` / `.Enum` / `.Values` (removed/deprecated) | ~44 files | ~100+ |
| `z.record()` (single argument) | ~7 files | ~8 |
| `zodResolver` usage (via `@hookform/resolvers`) | **100+ form components** | 100+ |

### Heaviest Schema Files (highest migration complexity)

| File | Primitive calls | Transform/Refine calls |
|------|----------------|----------------------|
| `patrimony/forms/lease/schema.ts` | 69 | 14+15 (.transform+.refine+.enum) |
| `financial/forms/purchase-invoice-v2/schema.ts` | 61 | 6+4+4 |
| `financial/forms/purchase-invoice/schema.ts` | 54 | 7+6+8+2 |
| `components/contact/schema.ts` | 54 | 11+7+22+24 |
| `fee-management/FeeConfiguratorForm/schema.ts` | 45 | 3+9+12+8 |
| `financial/forms/cost-settlement/schema.ts` | 40 | 2+2 |
| `financial/forms/fiscal-year-setup/schema.ts` | 38 | 3+9 |
| `financial/forms/provision/schema.ts` | 42 | 5+1+4+3 |
| `patrimony/forms/lease/revision/schema.ts` | 41 | 7+4+3+8 |
| `broadcasts/schemas/broadcastFormSchema.ts` | 33 | 4+5+14+9 |

### Current Test Coverage

| Area | Test Files | Coverage |
|------|-----------|----------|
| Zod schema unit tests | **1 file** (`accountSchemas.test.ts`) | Near zero |
| Other unit tests | 4 files (utility functions) | Very low |
| Total test files in `src/` | **5 files** | Minimal |

---

## Zod v4 Breaking Changes — Full Catalog

### Category 1: Error Customization (HIGH IMPACT)

#### 1.1 `message` parameter deprecated

The `message` param is replaced with `error`. The old `message` is still supported but deprecated.

```typescript
// Zod 3
z.string().min(5, { message: "Too short." });

// Zod 4
z.string().min(5, { error: "Too short." });
```

**Impact on sndq-fe**: ~27+ files use `message:` in schema definitions. These will still work (deprecated, not removed) but should be migrated for forward-compatibility.

#### 1.2 `invalid_type_error` and `required_error` REMOVED

These parameters are **completely dropped** (not just deprecated).

```typescript
// Zod 3
z.string({ invalid_type_error: "Not a string", required_error: "Required" });

// Zod 4
z.string({
  error: (issue) => issue.input === undefined
    ? "Required"
    : "Not a string"
});
```

**Impact on sndq-fe**: Must audit all schema files for these parameters. Any file using them will **break at compile time or runtime**.

#### 1.3 `errorMap` renamed to `error`

Error maps now return a plain `string` (instead of `{ message: string }`) and can return `undefined` to yield to the next error map.

```typescript
// Zod 3
z.string().min(5, {
  errorMap: (issue) => ({ message: `Value must be >${issue.minimum}` }),
});

// Zod 4
z.string().min(5, {
  error: (issue) => {
    if (issue.code === "too_small") {
      return `Value must be >${issue.minimum}`;
    }
  },
});
```

#### 1.4 Error map precedence change

In Zod 3, a contextual error map passed to `.parse()` takes precedence over a schema-level error map. In Zod 4, **schema-level error maps now take precedence**. This is a silent behavior change.

```typescript
const schema = z.string({ error: () => "Schema-level" });

// Zod 3: "Contextual error" wins
// Zod 4: "Schema-level" wins
schema.parse(12, { error: () => "Contextual error" });
```

### Category 2: ZodError Structure Changes (MEDIUM IMPACT)

#### 2.1 Issue type renames

| Zod 3 | Zod 4 | Status |
|-------|-------|--------|
| `ZodInvalidTypeIssue` | `z.core.$ZodIssueInvalidType` | Renamed |
| `ZodTooBigIssue` | `z.core.$ZodIssueTooBig` | Renamed |
| `ZodTooSmallIssue` | `z.core.$ZodIssueTooSmall` | Renamed |
| `ZodInvalidStringIssue` | `z.core.$ZodIssueInvalidStringFormat` | Renamed |
| `ZodNotMultipleOfIssue` | `z.core.$ZodIssueNotMultipleOf` | Renamed |
| `ZodUnrecognizedKeysIssue` | `z.core.$ZodIssueUnrecognizedKeys` | Renamed |
| `ZodInvalidUnionIssue` | `z.core.$ZodIssueInvalidUnion` | Renamed |
| `ZodCustomIssue` | `z.core.$ZodIssueCustom` | Renamed |
| `ZodInvalidEnumValueIssue` | `z.core.$ZodIssueInvalidValue` | Merged |
| `ZodInvalidLiteralIssue` | `z.core.$ZodIssueInvalidValue` | Merged |
| `ZodInvalidUnionDiscriminatorIssue` | (throws Error at creation) | Removed |
| `ZodInvalidArgumentsIssue` | (ZodError thrown directly) | Removed |
| `ZodInvalidReturnTypeIssue` | (ZodError thrown directly) | Removed |
| `ZodInvalidDateIssue` | `invalid_type` | Merged |
| `ZodInvalidIntersectionTypesIssue` | (throws regular Error) | Removed |
| `ZodNotFiniteIssue` | `invalid_type` | Merged |

All issues still conform to the same base interface:

```typescript
interface $ZodIssueBase {
  readonly code?: string;
  readonly input?: unknown;
  readonly path: PropertyKey[];
  readonly message: string;
}
```

#### 2.2 `.format()` and `.flatten()` deprecated

```typescript
// Zod 3
error.format();
error.flatten();

// Zod 4
z.treeifyError(error);
```

#### 2.3 `.addIssue()` and `.addIssues()` deprecated

```typescript
// Zod 3
myError.addIssue({ /* ... */ });

// Zod 4
myError.issues.push({ /* ... */ });
```

### Category 3: z.string() Changes (MEDIUM IMPACT)

#### 3.1 Format validators moved to top-level (deprecated as methods)

```typescript
// Zod 3 (method form — still works but deprecated)
z.string().email();
z.string().uuid();
z.string().url();

// Zod 4 (top-level — recommended)
z.email();
z.uuid();
z.url();
z.iso.datetime();
z.iso.date();
z.iso.time();
z.iso.duration();
z.base64();
z.base64url();
z.nanoid();
z.cuid();
z.cuid2();
z.ulid();
z.ipv4();
z.ipv6();
z.cidrv4();
z.cidrv6();
```

**Impact on sndq-fe**: ~4 files use `z.string().email()`. Low urgency since method forms are still supported (deprecated but functional).

#### 3.2 Stricter `.uuid()` validation

Zod 4 validates UUIDs against RFC 9562/4122 spec (variant bits must be `10`). For permissive validation, use `z.guid()`.

#### 3.3 `.ip()` and `.cidr()` dropped

```typescript
// Zod 3
z.string().ip();
z.string().cidr();

// Zod 4
z.ipv4();     // or z.ipv6()
z.cidrv4();   // or z.cidrv6()
```

### Category 4: z.object() Changes (HIGH IMPACT)

#### 4.1 `.default()` inside `.optional()` now applies

This is a **silent behavior change**. Defaults inside optional properties are now applied even if the key is missing from the input.

```typescript
const schema = z.object({
  a: z.string().default("tuna").optional(),
});

schema.parse({});
// Zod 3: {}
// Zod 4: { a: "tuna" }
```

**Impact on sndq-fe**: Any schema combining `.default()` with `.optional()` will produce different output. Code that checks key existence (`"a" in obj`) will behave differently.

#### 4.2 `.strict()` and `.passthrough()` deprecated

```typescript
// Zod 3
z.object({ name: z.string() }).strict();
z.object({ name: z.string() }).passthrough();

// Zod 4 (recommended)
z.strictObject({ name: z.string() });
z.looseObject({ name: z.string() });
```

These methods still work (deprecated, not removed).

#### 4.3 `.nonstrict()` REMOVED

The long-deprecated alias for `.strip()` is completely removed.

#### 4.4 `.deepPartial()` REMOVED

No direct replacement. Its use was considered an anti-pattern.

#### 4.5 `.merge()` deprecated

```typescript
// Zod 3
const Extended = BaseSchema.merge(AdditionalSchema);

// Zod 4 (recommended — better tsc performance)
const Extended = BaseSchema.extend(AdditionalSchema.shape);

// Zod 4 (best tsc performance)
const Extended = z.object({
  ...BaseSchema.shape,
  ...AdditionalSchema.shape,
});
```

**Impact on sndq-fe**: ~50 files may use `.merge()`. While still functional (deprecated), migrating to `.extend()` or spread improves TypeScript performance.

#### 4.6 `z.unknown()` and `z.any()` optionality change

```typescript
const schema = z.object({
  a: z.any(),
  b: z.unknown(),
});

// Zod 3: { a?: any; b?: unknown }
// Zod 4: { a: any; b: unknown }
```

**Impact on sndq-fe**: Any object schema using `z.any()` or `z.unknown()` as properties will require those keys to be explicitly provided.

### Category 5: z.nativeEnum() Deprecated (HIGH IMPACT)

`z.nativeEnum()` is deprecated. `z.enum()` now accepts TypeScript `enum` values directly.

```typescript
enum Color {
  Red = "red",
  Green = "green",
  Blue = "blue",
}

// Zod 3
const schema = z.nativeEnum(Color);
schema.enum.Red;    // works
schema.Enum.Red;    // works
schema.Values.Red;  // works

// Zod 4
const schema = z.enum(Color);
schema.enum.Red;    // works (canonical)
schema.Enum.Red;    // REMOVED
schema.Values.Red;  // REMOVED
```

**Impact on sndq-fe**: ~44 files use `z.nativeEnum()`, `.Enum`, or `.Values`. The `.Enum` and `.Values` accessors are **removed entirely** (not deprecated), causing **runtime errors** if missed.

### Category 6: z.coerce Changes (LOW IMPACT)

The input type of all `z.coerce` schemas is now `unknown` instead of the target type.

```typescript
const schema = z.coerce.string();
type Input = z.input<typeof schema>;
// Zod 3: string
// Zod 4: unknown
```

### Category 7: .default() Behavior Change (CRITICAL)

The `.default()` method now **short-circuits** and returns the default value directly when input is `undefined`. The default value must match the **output** type (not the input type).

```typescript
// Zod 3: default parsed through the full pipeline
const schema = z.string().transform(val => val.length).default("tuna");
schema.parse(undefined); // => 4 (parses "tuna" → "tuna".length)

// Zod 4: default short-circuits
const schema = z.string().transform(val => val.length).default(0);
schema.parse(undefined); // => 0 (returns default directly)
```

To replicate the old behavior, use `.prefault()`:

```typescript
// Zod 4 — replicates Zod 3 behavior
const schema = z.string().transform(val => val.length).prefault("tuna");
schema.parse(undefined); // => 4
```

**Impact on sndq-fe**: With ~140+ uses of `.transform()` across ~70 files, any `.transform()` + `.default()` combination will silently change behavior. This is the **single most dangerous breaking change**.

### Category 8: z.number() Changes (LOW IMPACT)

- `POSITIVE_INFINITY` and `NEGATIVE_INFINITY` are no longer valid
- `.safe()` no longer accepts floats (behaves like `.int()`)
- `.int()` only accepts safe integers (`Number.MIN_SAFE_INTEGER` to `Number.MAX_SAFE_INTEGER`)

### Category 9: z.array() Changes (LOW IMPACT)

`.nonempty()` type inference changes:

```typescript
const schema = z.array(z.string()).nonempty();
type T = z.infer<typeof schema>;
// Zod 3: [string, ...string[]]
// Zod 4: string[]
```

**Impact on sndq-fe**: No `.nonempty()` usage found. No impact.

### Category 10: z.record() Changes (LOW-MEDIUM IMPACT)

#### 10.1 Single argument dropped

```typescript
// Zod 3
z.record(z.string());

// Zod 4 — requires key schema
z.record(z.string(), z.string());
```

**Impact on sndq-fe**: ~7 files use `z.record()`. Must audit each for single-argument usage.

#### 10.2 Enum key records are now exhaustive

```typescript
const schema = z.record(z.enum(["a", "b"]), z.number());
// Zod 3: { a?: number; b?: number }    (partial)
// Zod 4: { a: number; b: number }      (exhaustive)
```

Use `z.partialRecord()` for the old behavior.

### Category 11: .refine() Changes (MEDIUM IMPACT)

#### 11.1 Type predicates ignored

```typescript
// Zod 3: narrows to string
// Zod 4: stays unknown
z.unknown().refine((val): val is string => typeof val === "string");
```

#### 11.2 `ctx.path` dropped in .superRefine()

```typescript
z.string().superRefine((val, ctx) => {
  ctx.path; // Zod 3: available
             // Zod 4: no longer available
});
```

#### 11.3 Function as second argument to .refine() dropped

```typescript
// Zod 3 — overload removed in v4
z.string().refine(
  (val) => val.length > 10,
  (val) => ({ message: `${val} is too short` }) // removed
);
```

### Category 12: z.function() Rewrite (LOW IMPACT)

`z.function()` is now a standalone factory, not a schema. The API changed from `.args()` + `.returns()` to an object with `input` and `output`.

**Impact on sndq-fe**: Unlikely used in form schemas. Low risk.

### Category 13: Internal/TypeScript Changes (MEDIUM IMPACT)

#### 13.1 Generic structure change

```typescript
// Zod 3
class ZodType<Output, Def extends z.ZodTypeDef, Input = Output> { }

// Zod 4
class ZodType<Output = unknown, Input = unknown> { }
```

`ZodTypeAny` is eliminated — use `ZodType` directly.

#### 13.2 `._def` moved to `._zod.def`

Any code or library accessing `._def` will break.

#### 13.3 `.describe()` changed

```typescript
// Zod 3
z.string().describe("A name");

// Zod 4
z.string().meta({ description: "A name" });
```

**Impact on sndq-fe**: ~50 files use `.describe()`. While the method still exists in v4, its behavior may differ. Need to audit.

### Category 14: Miscellaneous Removals

| Removed | Replacement |
|---------|-------------|
| `z.ostring()`, `z.onumber()`, etc. | `z.string().optional()` |
| `z.literal()` with symbols | Not supported |
| `ZodType.create()` static factories | Use `z.string()` etc. directly |
| `z.promise()` | `await` before parsing |
| `.formErrors` on ZodError | Use `z.treeifyError()` |

---

## Impact Analysis on sndq-fe

### Impact Heat Map by Module

| Module | Schema Files | Complexity | Risk Level |
|--------|-------------|------------|------------|
| `financial/` | ~25 files | Very High (purchase invoices, provisions, costs, fiscal year) | **CRITICAL** |
| `patrimony/` | ~20 files | Very High (lease schemas with 69+ primitive calls) | **CRITICAL** |
| `app-library/tenant-screening/` | ~7 files | High (public-facing forms) | **HIGH** |
| `passport/` | ~7 files | Medium | **MEDIUM** |
| `broadcasts/` | ~3 files | High (complex transforms) | **HIGH** |
| `contact/` (shared components) | ~3 files | Very High (54 primitive calls in schema.ts) | **CRITICAL** |
| `workspace-settings/` | ~5 files | Medium | **MEDIUM** |
| `activity/` | ~4 files | Low-Medium | **LOW** |
| `email-settings/` | ~2 files | Low | **LOW** |
| `fee-management/` | 1 file | High (45 primitives, 12 enum, 8 nativeEnum) | **HIGH** |
| `packages/ui` (submodule) | 1+ files | Medium | **MEDIUM** |

### Dependency Chain Risk

```
@hookform/resolvers (zodResolver)
        ↓ depends on
      zod (v3 internal API: ._def, ZodEffects, ZodType generics)
        ↓ consumed by
    ~103 schema files
        ↓ used by
    ~100+ React form components
```

If `@hookform/resolvers` does not support Zod v4's internal structure, **the entire form system breaks**. This is the #1 blocker.

---

## Benefits

### 1. Runtime Performance

| Operation | Zod 3 | Zod 4 | Speedup |
|-----------|-------|-------|---------|
| String parsing | baseline | 14x faster | **14x** |
| Array parsing | baseline | 7x faster | **7x** |
| Object parsing | baseline | 6.5x faster | **6.5x** |

In context of sndq-fe: Every form submission, every field validation, every blur event that triggers Zod parsing will be significantly faster. With ~100+ forms, this compounds into a noticeable UX improvement, especially on complex multi-step forms like lease creation or purchase invoice entry.

### 2. TypeScript Compilation Performance

- **Simplified generics**: `ZodType<Output, Input>` instead of `ZodType<Output, Def, Input>` — reduces type instantiations that TypeScript must resolve
- **`.extend()` over `.merge()`**: Official docs state this has "better TypeScript performance"
- **Spread over `.extend()`**: `z.object({ ...A.shape, ...B.shape })` has the best tsc performance
- With 103 schema files generating hundreds of inferred types, the reduction in type instantiations should measurably improve `tsc --noEmit` time

### 3. Bundle Size

- Top-level format validators (`z.email()` instead of `z.string().email()`) enable better tree shaking
- `zod/mini` package available for code-split entry points that need minimal validation
- `ZodEffects` wrapper class eliminated — fewer intermediate objects

### 4. API Quality Improvements

- **Unified error customization**: Single `error` parameter instead of fragmented `message` / `errorMap` / `invalid_type_error` / `required_error`
- **`z.enum()` accepts TypeScript enums**: No more `z.nativeEnum()` / `z.enum()` confusion
- **Better `z.record()` inference**: Enum keys produce exhaustive types by default
- **`.default()` is more intuitive**: Short-circuits instead of re-parsing (once understood, reduces bugs)

### 5. Future-Proofing

- Zod v3 will receive security patches only — no new features
- Ecosystem libraries (tRPC, react-hook-form adapters, etc.) will gradually require Zod v4
- Community codemod tooling available now — easier migration sooner than later

---

## Risks & Mitigation

### RISK 1: `.default()` Behavior Change — CRITICAL

**What**: `.default()` now short-circuits the pipeline, returning the default value directly instead of parsing it through transforms. Any `.transform() + .default()` combo will silently produce different output.

**Why dangerous**: No TypeScript error. No runtime error. Just different data flowing through your application.

**Mitigation**:
1. Run a codebase-wide search for `.default(` in all schema files
2. For each `.default()`, check if it appears **after** a `.transform()` in the chain
3. If so, replace `.default()` with `.prefault()` to preserve Zod 3 behavior
4. Write snapshot tests for all affected schemas before migration

**Search command**:
```bash
rg '\.default\(' --glob '*.ts' --glob '*.tsx' sndq-fe/src/ | grep -v node_modules
```

### RISK 2: `@hookform/resolvers` Compatibility — CRITICAL BLOCKER

**What**: `@hookform/resolvers@^4.1.3` uses `zodResolver` which internally accesses Zod's `._def` property and relies on class-checking against `ZodEffects`, `ZodType` generics, etc. Zod v4 moves `._def` to `._zod.def` and removes `ZodEffects`.

**Why dangerous**: 100% of forms use `zodResolver`. If incompatible, no form in the entire app will work.

**Mitigation**:
1. **Before any migration work**, check the `@hookform/resolvers` changelog and GitHub issues for Zod v4 support
2. Test in isolation: create a throwaway branch, upgrade Zod, and test a single form
3. If resolvers don't support v4, either:
   - Wait for the `@hookform/resolvers` update
   - Fork and patch the resolver temporarily
   - Use Zod v4's compatibility layer (if available)

**Verification**:
```bash
npm info @hookform/resolvers versions --json | tail -20
# Check if any version mentions Zod 4 support in its changelog
```

### RISK 3: `z.nativeEnum()` + `.Enum` / `.Values` — HIGH

**What**: `z.nativeEnum()` is deprecated (still works), but `.Enum` and `.Values` accessors are **completely removed** (will throw at runtime).

**Why dangerous**: ~44 files use these patterns. TypeScript may not catch all usages if they're accessed dynamically.

**Mitigation**:
1. Search for all `z.nativeEnum(` usages and migrate to `z.enum()`
2. Search for `.Enum.` and `.Values.` accessors and replace with `.enum.`
3. The codemod tool can automate most of this

**Search commands**:
```bash
rg '\.nativeEnum\(' --glob '*.ts' --glob '*.tsx' sndq-fe/src/
rg '\.Enum\.' --glob '*.ts' --glob '*.tsx' sndq-fe/src/
rg '\.Values\.' --glob '*.ts' --glob '*.tsx' sndq-fe/src/
```

### RISK 4: `z.object()` Defaults Applied in Optional Fields — HIGH

**What**: Defaults inside optional properties are now applied even when the key is absent from input.

**Why dangerous**: Code that relies on checking whether a key exists in parsed output will behave differently. Spread operations may include unexpected keys.

**Mitigation**:
1. Audit all schemas combining `.default()` with `.optional()` on object properties
2. If the old behavior is required, restructure the schema to avoid the `.default().optional()` chain
3. Write explicit tests for schemas where key presence matters

### RISK 5: `z.unknown()` / `z.any()` Optionality — MEDIUM

**What**: These types are no longer marked as "key optional" in object schemas.

**Why dangerous**: TypeScript will now require these keys to be explicitly provided when constructing objects matching the schema type.

**Mitigation**:
1. Search for `z.any()` and `z.unknown()` used as object properties
2. Add `.optional()` explicitly where the old behavior is needed

### RISK 6: `packages/ui` Submodule Version Mismatch — MEDIUM

**What**: The `@sndq/ui` submodule (`packages/ui/`) has its own `zod@^3.24.3` dependency. If main app upgrades to v4 but the submodule stays on v3, there will be two Zod versions in the bundle.

**Why dangerous**: Dual Zod versions cause `instanceof` checks to fail, schema types to be incompatible, and bundle size to bloat.

**Mitigation**:
1. Upgrade both `sndq-fe/package.json` and `packages/ui/package.json` simultaneously
2. Ensure pnpm deduplicates to a single Zod version: `pnpm why zod`
3. Test UI components that accept Zod schemas as props

### RISK 7: `z.record()` Single-Argument Removal — LOW-MEDIUM

**What**: `z.record(z.string())` no longer works; must provide both key and value schemas.

**Mitigation**:
1. Search for `z.record(` with a single argument
2. Add `z.string()` as the key schema where missing: `z.record(z.string(), z.string())`

### RISK 8: `.superRefine()` `ctx.path` Removal — LOW

**What**: `ctx.path` is no longer available inside `.superRefine()` callbacks.

**Mitigation**:
1. Search for `ctx.path` in refinement callbacks
2. If path is needed, compute it outside the refinement or restructure validation logic

---

## Pre-Migration Testing Strategy

### Testing Decision: Selection Criteria

The testing strategy for this migration was evaluated against four criteria:

1. **High ROI** — Each test must catch real migration regressions, not theoretical edge cases
2. **Low maintenance cost** — Tests should not become a burden after migration is complete
3. **High coverage-to-effort ratio** — Maximize the number of breaking changes detected per line of test code
4. **Minimal boilerplate** — Reusable patterns over repetitive per-schema test files

### Why Tests Are Essential

With only **6 test files** in the entire `src/` directory (and only 1 testing a Zod schema), the codebase has near-zero safety net for schema changes. The `.default()` behavior change alone can silently alter data flowing through dozens of forms without any TypeScript or runtime error. Tests are the **only way** to catch these silent regressions.

The TypeScript compiler (`tsc --noEmit`) will catch many breaking changes — removed APIs like `invalid_type_error`, `required_error`, single-argument `z.record()`, `.Enum`/`.Values` accessor removal, and type signature changes. But the compiler **cannot** catch:

- `.default()` short-circuit behavior producing different runtime output
- `.default()` + `.optional()` now populating keys that were previously absent
- `.transform()` + `.default()` chain producing different values
- Error map precedence changes (schema-level now wins over contextual)
- `z.any()` / `z.unknown()` no longer being optional in objects
- `zodResolver` internal API breakage (`._def` → `._zod.def`)

These silent behavior changes are precisely what the testing strategy targets.

### Test Types Evaluated

| Test Type | ROI | Maintenance | Boilerplate | Coverage | Decision |
|-----------|-----|-------------|-------------|----------|----------|
| **Schema Snapshot Tests (Vitest)** | Very High | Very Low | Low (factory pattern) | Very High | **SELECTED — PRIMARY** |
| **zodResolver Smoke Tests (Vitest)** | Critical | Very Low | Very Low (~30 lines) | High for #1 blocker | **SELECTED — SECONDARY** |
| E2E Tests (Playwright) | High per test | Very High | Very High | Low per test | Rejected |
| Component Render Tests (RTL) | Medium | High | Very High | Medium | Rejected |
| Property-Based Tests (fast-check) | Medium | Low | High initial | Very High | Rejected |
| Contract/Type Tests | Low | Low | Low | Medium | Redundant (`tsc` covers this) |
| nativeEnum Accessor Tests | Medium | Low | Low | Low (narrow scope) | Absorbed into snapshot tests |

### Why Other Test Types Were Rejected

#### E2E Tests (Playwright) — Rejected

**What it would do**: Navigate to a form page, fill in fields, submit, verify success/error states in a real browser.

**Why rejected**:
- The codebase has **100+ forms using zodResolver**. Writing an E2E test for each is prohibitively expensive (~50-100 lines per form, authentication setup, staging API dependency, seed data management).
- Playwright tests are **inherently brittle** — they break when CSS selectors change, when API responses differ, when staging is down. This violates the "low maintenance" criterion.
- Playwright tests are **slow** — a full suite of 100+ form tests would add 10-30 minutes to CI.
- The ROI per test is high (true end-to-end validation), but the ROI per hour of engineering time is low compared to schema snapshots.
- **Better use**: Manual QA of the 6 most critical forms (lease, purchase invoice v1/v2, contact, broadcast, fee configurator) after migration. Not automated.

#### Component Render Tests (React Testing Library) — Rejected

**What it would do**: Render a form component, simulate user input, verify that validation messages appear and form data is correct.

**Why rejected**:
- Form components in `sndq-fe` depend on **deep provider trees**: `WorkspacesContext`, `QueryClientProvider`, `IntlProvider` (next-intl), React Hook Form's `FormProvider`, and often module-specific context providers.
- Mocking all providers for 100+ forms creates **massive boilerplate** that is fragile and expensive to maintain.
- The actual risk being tested (Zod parsing behavior) is **buried under layers of React component logic**. A schema snapshot test isolates the exact layer at risk with zero component dependencies.
- Component render tests are valuable for testing **UI behavior** (conditional rendering, user interactions), not for testing **data transformation correctness** (which is what this migration risks).

#### Property-Based Tests (fast-check) — Rejected

**What it would do**: Generate random inputs conforming to (or violating) schema constraints, verify that parsing behavior is consistent across thousands of generated cases.

**Why rejected**:
- The migration risk is about **specific, known behavior changes** (`.default()` short-circuits, `nativeEnum` removal, error format changes), not about unknown edge cases. Property-based testing excels at finding edge cases but is overkill for known-issue detection.
- Setting up `Arbitrary` generators for complex nested schemas (e.g., `leaseFormSchema` with 492 lines, deeply nested objects, conditional refinements, enum dependencies) requires **significant upfront investment** (~100-200 lines per schema).
- The `.transform()` calls in schemas often cast to external types (e.g., `.transform((data) => data as unknown as ContactV2)`), which makes it difficult for property-based generators to produce meaningful output validation.
- **Better use**: After migration stabilizes, property-based tests could be added for long-term schema correctness. Not justified for a one-time migration safety net.

#### Contract/Type Tests — Rejected (Redundant)

**What it would do**: Verify that `z.infer<typeof schema>` produces the expected TypeScript type, and that certain type assignments compile.

**Why rejected**:
- `tsc --noEmit` already performs this exact check across the entire codebase. Every `z.infer<>` usage (170+ occurrences across ~100 files) is type-checked at compile time.
- Writing separate type tests duplicates what the compiler does for free.
- The real danger is **runtime behavior changes that pass type-checking**, which is exactly what snapshot tests catch.

#### nativeEnum Accessor Tests — Absorbed

**What it would do**: Verify that `.enum.VALUE` works after migrating from `.Enum.VALUE` and `.Values.VALUE`.

**Why absorbed into snapshot tests**:
- Schema snapshot tests already exercise enum values through the `valid` fixture (which must provide valid enum values to pass parsing).
- If a `nativeEnum` → `enum` migration is incomplete, the `valid` fixture will fail to parse, and the snapshot test will catch it.
- The `tsc` compiler will also catch `.Enum` and `.Values` accessor usage as type errors (these properties are removed entirely in v4).
- A dedicated test type for this narrow concern adds maintenance overhead without meaningful additional coverage.

---

### SELECTED: Schema Snapshot Tests (Vitest) — PRIMARY

#### What This Test Type Does

Schema snapshot tests call `schema.safeParse()` with predetermined fixture data and use Vitest's `toMatchSnapshot()` to capture the **exact output**. On subsequent runs, any difference in output causes the test to fail, showing a precise diff of what changed.

This approach creates a "behavioral fingerprint" of each schema: the exact parsed output for valid data, the exact default values applied, the exact error structure for invalid data. Any silent behavior change in Zod v4 that alters these outputs will be immediately detected.

#### Why This Is the Highest ROI Choice

**1. Directly targets the most dangerous risk**

The `.default()` behavior change (Category 7 in the breaking changes catalog) is the single most dangerous aspect of this migration. It produces:
- No TypeScript compile error
- No runtime error
- No console warning
- Just **different data** flowing through the application

Example from the actual codebase — `leaseFormSchema` has 21 `.default()` calls:

```typescript
// src/modules/patrimony/forms/lease/schema.ts (actual code)
isNewRentalContract: z.boolean().default(true),
silentRenewal: z.boolean().default(false),
hasVat: z.boolean().default(false),
hasIndexation: z.boolean().default(false),
indexable: z.boolean().default(false),
payers: z.array(payerSchema).default([]),
extraCosts: z.array(extraCostSchema).default([]),
discounts: z.array(discountSchema).default([]),
// ... 13 more .default() calls
```

If any of these defaults interact with `.optional()` or `.transform()` in the chain, Zod v4 may produce different output. A snapshot test catches this with zero manual verification effort.

**2. Covers multiple breaking change categories simultaneously**

A single snapshot test file for one schema catches breaking changes across:

| Breaking Change | How Snapshot Catches It |
|----------------|------------------------|
| `.default()` short-circuit (Cat. 7) | Parsed output snapshot differs |
| `.default()` + `.optional()` key presence (Cat. 4.1) | Minimal input snapshot shows new keys |
| `.transform()` + `.default()` combo (Cat. 7) | Transformed output snapshot differs |
| `nativeEnum` validation (Cat. 5) | Valid fixture uses enum values; fails if enum broken |
| `required_error` removal (Cat. 1.2) | Error snapshot shows different error structure |
| `z.any()` / `z.unknown()` optionality (Cat. 4.6) | Minimal input snapshot fails if key now required |
| Error map format change (Cat. 2) | Error snapshot captures exact issue structure |
| `z.record()` single-arg removal (Cat. 10) | Record-containing schemas fail to parse |

**3. Self-generating baseline with `toMatchSnapshot()`**

Unlike explicit assertion tests (where you manually write `expect(result).toEqual({...})`), snapshot tests **auto-generate the expected value** on first run. This means:
- No need to manually construct expected output objects for complex schemas
- The snapshot file serves as human-readable documentation of schema behavior
- Updating after an intentional change is a single command: `pnpm test -- -u`

**4. Near-zero maintenance after migration**

Once the migration is complete and snapshots are updated:
- Tests only break if someone changes the schema definition (which is exactly when you want regression detection)
- No external dependencies (no API, no browser, no database)
- Sub-second execution time per file
- No mocking or provider setup needed

#### Design: Reusable Test Factory

To minimize boilerplate across 13+ schema test files, a **factory helper** generates the standard test suite from fixtures:

```typescript
// src/__tests__/helpers/schema-test-factory.ts
import { describe, it, expect } from 'vitest';
import type { ZodSchema } from 'zod';

interface SchemaFixtures {
  /** Complete valid input — exercises all fields, transforms, and enum values */
  valid: Record<string, unknown>;
  /** Only required fields — exposes default value behavior */
  minimal: Record<string, unknown>;
  /** Fields with wrong types — captures error format and structure */
  invalid?: Record<string, unknown>;
}

/**
 * Generates a standard snapshot test suite for a Zod schema.
 *
 * Produces 3-4 tests per schema:
 * 1. Valid input → snapshots full parsed output (catches .transform() changes)
 * 2. Minimal input → snapshots defaults (catches .default() behavior changes)
 * 3. Empty input → snapshots error structure (catches error format changes)
 * 4. Invalid input → snapshots type error structure (optional)
 *
 * Usage:
 *   describeSchema('LeaseForm', leaseFormSchema, { valid: {...}, minimal: {...} });
 */
export function describeSchema(
  name: string,
  schema: ZodSchema,
  fixtures: SchemaFixtures,
): void {
  describe(`${name} — migration snapshot`, () => {
    it('parses valid input and produces expected output', () => {
      const result = schema.safeParse(fixtures.valid);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data).toMatchSnapshot();
      }
    });

    it('parses minimal input with correct defaults', () => {
      const result = schema.safeParse(fixtures.minimal);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data).toMatchSnapshot();
      }
    });

    it('rejects empty input with expected error structure', () => {
      const result = schema.safeParse({});
      if (!result.success) {
        expect(
          result.error.issues.map((i) => ({
            path: i.path,
            code: i.code,
          })),
        ).toMatchSnapshot();
      }
    });

    if (fixtures.invalid) {
      it('rejects invalid types with expected errors', () => {
        const result = schema.safeParse(fixtures.invalid);
        expect(result.success).toBe(false);
        if (!result.success) {
          expect(
            result.error.issues.map((i) => ({
              path: i.path,
              code: i.code,
            })),
          ).toMatchSnapshot();
        }
      });
    }
  });
}
```

**Why this pattern is optimal:**

- **30 lines of reusable code** replaces what would otherwise be 50-80 lines per schema file
- Each schema test file reduces to **~20-40 lines** (just import + fixtures + one `describeSchema()` call)
- The factory enforces consistent test structure across all schemas
- Adding a new schema test takes <5 minutes (just write fixtures)
- Error snapshots intentionally capture `path` + `code` only (not `message`), because error messages may intentionally change in the `message` → `error` migration, while `path` and `code` should remain stable

**Why error snapshots exclude `message`:**

The migration plan notes that `message:` is deprecated in favor of `error:`. Error message strings may change as part of the migration (e.g., from `required_error: "..."` to `error: (issue) => "..."`). Including `message` in the snapshot would cause false positives — tests that break due to intentional migration changes rather than actual regressions. Capturing only `path` + `code` ensures snapshots detect **structural** changes (wrong field flagged, wrong error type) without being brittle to message text changes.

#### Target Files: 13 High-Risk Schemas

These files were selected because they contain `.transform()` calls (the highest-risk pattern when combined with `.default()`). Files without `.transform()` are adequately covered by `tsc --noEmit` for compile-time changes.

| # | Schema File | .transform | .default | nativeEnum | superRefine | Risk |
|---|-------------|-----------|----------|------------|-------------|------|
| 1 | `patrimony/forms/lease/schema.ts` | 4 | 21 | 6 | 5 | **CRITICAL** |
| 2 | `financial/forms/purchase-invoice-v2/schema.ts` | 3 | 11 | 1 | 2 | **CRITICAL** |
| 3 | `financial/forms/purchase-invoice/schema.ts` | 3 | 18 | 2 | 3 | **CRITICAL** |
| 4 | `components/contact/schema.ts` | 4 | 9 | 0 | 4 | **CRITICAL** |
| 5 | `financial/forms/cost-settlement/schema.ts` | 2 | 6 | 0 | 1 | **HIGH** |
| 6 | `financial/forms/close-fiscal-year/schema.ts` | 2 | 9 | 0 | 0 | **HIGH** |
| 7 | `patrimony/forms/lease/revision/schema.ts` | 3 | — | — | — | **HIGH** |
| 8 | `patrimony/forms/building/schema.ts` | 2 | — | — | — | **HIGH** |
| 9 | `financial/forms/purchase-invoice-v2-steward/schema.ts` | 3 | 2 | — | — | **HIGH** |
| 10 | `patrimony/forms/property/schema.ts` | 1 | — | — | — | **MEDIUM** |
| 11 | `patrimony/forms/lease/components/lease-deposit/schema.ts` | 1 | 1 | — | — | **MEDIUM** |
| 12 | `fee-management/FeeConfiguratorForm/schema.ts` | 1 | — | — | — | **MEDIUM** |
| 13 | `contact-book/.../detail-overview-content/form/schema.ts` | 1 | — | — | — | **MEDIUM** |

**Why only 13 files instead of all 103:**

- These 13 files account for **all `.transform()` usage** in schema files. The `.transform()` + `.default()` combo is the only pattern that produces silent runtime behavior changes.
- The remaining ~90 schema files use only primitives (`.string()`, `.number()`, `.boolean()`), validators (`.min()`, `.max()`, `.email()`), and structural combinators (`.object()`, `.array()`, `.union()`). For these files, `tsc --noEmit` catches all v4 breaking changes at compile time (removed APIs, changed generics, type signature changes).
- Testing 13 files instead of 103 reduces effort by **87%** while covering **100%** of the silent behavior change risk.

#### Example: Lease Schema Test File

This shows what an actual test file looks like using the factory pattern. The lease schema (`leaseFormSchema`) is a multi-step form with deeply nested objects, making it the most complex schema in the codebase.

```typescript
// src/modules/patrimony/forms/lease/__tests__/schema.test.ts
import { describeSchema } from '@/__tests__/helpers/schema-test-factory';
import {
  generalInfoSchema,
  vatRuleSchema,
  indexationRuleSchema,
  extraCostSchema,
  discountSchema,
  propertyRentConfigSchema,
  financialDetailsSchema,
  leaseFormSchema,
} from '../schema';

const UUID = '550e8400-e29b-41d4-a716-446655440000';
const UUID2 = '660e8400-e29b-41d4-a716-446655440001';

// Test individual sub-schemas (more granular failure detection)
describeSchema('GeneralInfoSchema', generalInfoSchema, {
  valid: {
    isNewRentalContract: true,
    silentRenewal: false,
    owner: { id: UUID },
    contractName: 'Test Lease 2026',
    language: 'en',
    type: 'residential',
    creationDate: '2026-01-01',
    startDate: '2026-02-01',
    initialDuration: '9_YEARS',
    endDate: '2035-01-31',
    propertyIds: [UUID],
    tenants: [{ id: UUID }],
    primaryTenantId: UUID,
  },
  minimal: {
    owner: { id: UUID },
    contractName: 'X',
    language: 'en',
    type: 'residential',
    creationDate: '2026-01-01',
    startDate: '2026-02-01',
    initialDuration: '9_YEARS',
    endDate: null,
    propertyIds: [UUID],
    tenants: [{ id: UUID }],
    primaryTenantId: UUID,
  },
});

describeSchema('VatRuleSchema', vatRuleSchema, {
  valid: { name: 'Standard', percentage: 21, rate: '21' },
  minimal: { name: 'X', percentage: 0 }, // tests .default('21') on rate
});

describeSchema('ExtraCostSchema', extraCostSchema, {
  valid: {
    rootType: 'lump_sum',
    type: 'heating',
    name: 'Heating',
    amount: 5000,
    totalAmount: 6050,
    hasVat: true,
    vatRate: '21',
    indexable: false,
    interval: 'month',
  },
  minimal: {
    rootType: 'lump_sum',
    type: 'heating',
    amount: 1000,
    totalAmount: 1000,
  },
});

// Test the full composite schema
describeSchema('LeaseFormSchema (full)', leaseFormSchema, {
  valid: {
    general: {
      isNewRentalContract: true,
      silentRenewal: false,
      owner: { id: UUID },
      contractName: 'Full Lease Test',
      language: 'en',
      type: 'residential',
      creationDate: '2026-01-01',
      startDate: '2026-02-01',
      initialDuration: '9_YEARS',
      endDate: '2035-01-31',
      propertyIds: [UUID],
      tenants: [{ id: UUID }],
      primaryTenantId: UUID,
    },
    rentConfig: {
      [UUID]: {
        baseRent: 85000,
        payers: [{ contactId: UUID, name: 'Tenant A', role: 'tenant', percentage: 100 }],
        extraCosts: [],
        discounts: [],
      },
    },
    financial: {
      rentGeneration: {
        period: 'calendar',
        paymentFrequency: '1',
        documentType: 'expiry_notice',
      },
      message: { type: 'structured', content: '+++123/4567/89012+++' },
      payment: { period: 'current', dateDue: 1 },
      bankAccounts: [{
        action: 'create',
        accountId: UUID2,
        accountHolder: 'Owner',
        iban: 'BE68539007547034',
        usage: ['rent'],
      }],
    },
  },
  minimal: {
    general: {
      owner: { id: UUID },
      contractName: 'X',
      language: 'en',
      type: 'residential',
      creationDate: '2026-01-01',
      startDate: '2026-02-01',
      initialDuration: '9_YEARS',
      endDate: null,
      propertyIds: [UUID],
      tenants: [{ id: UUID }],
      primaryTenantId: UUID,
    },
    rentConfig: {
      [UUID]: {
        baseRent: 50000,
        payers: [{ contactId: UUID, name: 'T', role: 'tenant', percentage: 100 }],
      },
    },
    financial: {
      rentGeneration: {},
      message: { type: 'structured', content: '+++000/0000/00000+++' },
      payment: {},
      bankAccounts: [{
        action: 'create',
        accountId: UUID,
        accountHolder: 'O',
        iban: 'BE68539007547034',
        usage: ['rent'],
      }],
    },
  },
});
```

**Key observations about this pattern:**

- Sub-schemas are tested individually (`generalInfoSchema`, `vatRuleSchema`, `extraCostSchema`) for **granular failure detection** — if the full `leaseFormSchema` test fails, the sub-schema tests pinpoint which part broke.
- The `minimal` fixture deliberately omits optional fields and fields with `.default()` — this is where `.default()` behavior changes will surface.
- UUIDs are hardcoded constants, not generated — this ensures snapshot stability across runs.
- Enum values use string literals that match the actual enum values in the codebase (e.g., `'residential'`, `'lump_sum'`, `'calendar'`, `'expiry_notice'`).

#### Example: Contact Schema Test File

The contact schema demonstrates a different pattern — `.optional().default([]).superRefine().transform()` chains on `emails` and `phone_numbers` fields. This chain is particularly susceptible to the `.default()` short-circuit change.

```typescript
// src/components/contact/__tests__/schema.test.ts
import { describe, it, expect } from 'vitest';
import { describeSchema } from '@/__tests__/helpers/schema-test-factory';
import { contactFormSchema, supplierFormSchema, eidContactFormSchema } from '../schema';

describeSchema('ContactFormSchema', contactFormSchema, {
  valid: {
    capacity: 'company',
    contact_type: 'owner',
    company_name: 'Test Corp',
    vat_liable: true,
    vat_number: 'BE0123456789',
    emails: [{ value: 'test@example.com', type: 'work' }],
    phone_numbers: [{ phone_number: '+32470123456', type: 'work' }],
    language: 'en',
    correspondence: 'email',
    address: { street: 'Rue Test 1', city: 'Brussels', postalCode: '1000', country: 'BE' },
    use_alternative_address: false,
    representative: 'person',
    representative_name: 'John Doe',
  },
  minimal: {
    capacity: 'individual',
    contact_type: 'owner',
    first_name: 'Jane',
    language: 'en',
    correspondence: 'email',
    address: { street: 'X', city: 'X', postalCode: '1000', country: 'BE' },
    use_alternative_address: false,
    // emails and phone_numbers omitted — tests .optional().default([]) behavior
  },
});

// Dedicated test for the .optional().default([]).superRefine().transform() chain
// This is the exact pattern most at risk from .default() short-circuit change
describe('ContactFormSchema — transform chain behavior', () => {
  it('trims and filters empty emails when provided', () => {
    const result = contactFormSchema.safeParse({
      capacity: 'individual',
      contact_type: 'owner',
      first_name: 'Test',
      emails: [
        { value: '  test@example.com  ', type: 'work' },
        { value: '  ', type: 'work' },
        { value: '', type: 'work' },
      ],
      phone_numbers: [],
      language: 'en',
      correspondence: 'email',
      address: { street: 'X', city: 'X', postalCode: '1000', country: 'BE' },
      use_alternative_address: false,
    });
    expect(result.success).toBe(true);
    if (result.success) {
      // Should trim whitespace and filter out empty values
      expect(result.data.emails).toMatchSnapshot();
      expect(result.data.phone_numbers).toMatchSnapshot();
    }
  });

  it('applies default empty array when emails/phone_numbers omitted', () => {
    const result = contactFormSchema.safeParse({
      capacity: 'individual',
      contact_type: 'owner',
      first_name: 'Test',
      language: 'en',
      correspondence: 'email',
      address: { street: 'X', city: 'X', postalCode: '1000', country: 'BE' },
      use_alternative_address: false,
    });
    expect(result.success).toBe(true);
    if (result.success) {
      // CRITICAL: In Zod 3, .optional().default([]) returns []
      // In Zod 4, behavior may differ — snapshot catches this
      expect(result.data.emails).toMatchSnapshot();
      expect(result.data.phone_numbers).toMatchSnapshot();
    }
  });
});

describeSchema('SupplierFormSchema', supplierFormSchema, {
  valid: {
    supplier_type: 'plumber',
    company_name: 'Fix-It Corp',
    vat_liable: false,
    language: 'en',
    correspondence: 'email',
    representative: 'none',
  },
  minimal: {
    supplier_type: 'plumber',
    company_name: 'X',
    vat_liable: false,
    language: 'en',
    correspondence: 'email',
    representative: 'none',
  },
});

describeSchema('EidContactFormSchema', eidContactFormSchema, {
  valid: {
    first_name: 'Jean',
    last_name: 'Dupont',
    date_of_birth: '1990-01-15',
    national_id_number: '90011512345',
    capacity: 'individual',
    contact_type: 'owner',
    emails: [{ value: 'jean@example.com', type: 'personal' }],
    phone_numbers: [{ phone_number: '+32470123456', type: 'personal' }],
    language: 'fr',
    correspondence: 'email',
    address: { street: 'Rue de la Loi 1', city: 'Bruxelles', postalCode: '1000', country: 'BE' },
    use_alternative_address: false,
  },
  minimal: {
    first_name: 'J',
    language: 'en',
    correspondence: 'email',
    address: { street: 'X', city: 'X', postalCode: '1000', country: 'BE' },
    use_alternative_address: false,
    // Tests .default(true) on remind_expiry
    // Tests .default(CapacityTypeEnum.INDIVIDUAL) on capacity
    // Tests .default(ContactTypeEnum.OWNER) on contact_type
    // Tests .optional().default([]).transform() on emails/phone_numbers
  },
});
```

#### Benefits Summary

| Benefit | Explanation |
|---------|-------------|
| **Catches silent data changes** | The `.default()` + `.transform()` behavior change produces zero errors but different data. Snapshots are the only automated detection mechanism. |
| **Zero manual expected-value authoring** | `toMatchSnapshot()` generates the expected value file automatically on first run. No need to manually construct complex nested objects as expected output. |
| **Self-documenting** | Snapshot files serve as human-readable documentation of "what does this schema produce for these inputs?" — useful beyond just migration. |
| **Extreme precision** | Snapshot diffs show exactly which field, in which nested path, changed its value. Pinpoints the exact `.default()` or `.transform()` that needs attention. |
| **Composable with sub-schemas** | Testing `generalInfoSchema`, `extraCostSchema`, `vatRuleSchema` individually (not just the composite `leaseFormSchema`) gives granular failure isolation. |
| **Fast execution** | Schema snapshot tests run in <100ms per file. No DOM, no API, no browser. Can run on every commit. |
| **Low false-positive rate** | Snapshots only fail when actual output changes. No flaky tests from network timeouts, race conditions, or CSS changes. |
| **Reusable beyond migration** | After migration, these tests continue to serve as regression tests for any future schema changes (field additions, validation rule changes, refactoring). |

#### Trade-offs

| Trade-off | Impact | Mitigation |
|-----------|--------|------------|
| **Fixture authoring effort** | Each schema needs valid + minimal fixture objects. For complex schemas like `leaseFormSchema` (492 lines, deeply nested), this takes 15-30 minutes. | The factory pattern reduces per-schema boilerplate to fixtures only. Sub-schema testing (e.g., `generalInfoSchema` independently) uses simpler fixtures. |
| **Snapshot files are opaque** | `.snap` files can be large and hard to review in PRs. Reviewers may rubber-stamp snapshot updates. | Keep error snapshots to `path` + `code` only (no `message`). Name snapshot tests descriptively so the `.snap` file is self-explanatory. |
| **Snapshot updates required for intentional changes** | After migration, many snapshots will change intentionally (e.g., `.default()` now populates keys that were previously absent). Each must be reviewed. | Run `pnpm test` first (see what failed), review each diff, then `pnpm test -- -u` to update. The review step is the actual value — it forces conscious acknowledgment of each behavior change. |
| **Does not test UI rendering** | Snapshot tests verify schema parsing only, not whether the form component renders validation errors correctly. | Manual QA of 6 critical forms covers UI rendering. `zodResolver` smoke tests (below) cover the schema→form integration point. |
| **Fixtures may not cover all code paths** | A single `valid` + `minimal` fixture pair may not exercise every `.superRefine()` branch or conditional validation. | For critical schemas (lease, contact), add dedicated tests for specific `.superRefine()` paths (see the "transform chain behavior" example above). |
| **Enum value dependency** | Fixtures hardcode enum string values. If enums change independently of the Zod migration, fixtures break. | Use imported enum constants where possible (e.g., `CapacityTypeEnum.COMPANY`), falling back to string literals only for `as const` arrays where the enum type isn't exported. |

---

### SELECTED: zodResolver Smoke Tests (Vitest) — SECONDARY

#### What This Test Type Does

zodResolver smoke tests verify that `@hookform/resolvers`'s `zodResolver()` function can:
1. Accept a Zod schema without throwing (instantiation check)
2. Validate correct data and return no errors (happy path)
3. Validate incorrect data and return errors (error path)

This is a **compatibility test**, not a behavior test. It does not verify specific error messages or parsed values — it verifies that the integration between `zodResolver` and Zod's internal API still works.

#### Why This Is a Critical Secondary Choice

**The dependency chain risk:**

```
@hookform/resolvers (zodResolver)
        ↓ internally accesses
    schema._def (Zod 3) → schema._zod.def (Zod 4)
    instanceof ZodEffects (Zod 3) → eliminated (Zod 4)
    ZodType<Output, Def, Input> (Zod 3) → ZodType<Output, Input> (Zod 4)
        ↓ consumed by
    ~103 schema files via zodResolver(schema)
        ↓ used by
    ~100+ React form components
```

If `@hookform/resolvers` does not support Zod v4's internal structure, **100% of forms in the entire application break**. No amount of schema snapshot testing can catch this — it's an integration point between two libraries.

This test must be run **before any migration work begins**:
1. Install Zod v4 on a throwaway branch
2. Run the zodResolver smoke test
3. If it fails → migration is **blocked** until `@hookform/resolvers` ships a compatible version
4. If it passes → proceed with confidence

#### Design: Single File, Minimal Boilerplate

The entire zodResolver smoke test suite fits in one file (~50 lines):

```typescript
// src/__tests__/zod-resolver-compat.test.ts
import { describe, it, expect } from 'vitest';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// Import representative schemas of varying complexity
import { leaseFormSchema } from '@/modules/patrimony/forms/lease/schema';
import { contactFormSchema } from '@/components/contact/schema';
import { amountWithDistributionSchema } from '@/modules/financial/forms/purchase-invoice-v2/schema';

// Simple schema for end-to-end validation test
const simpleSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().min(0),
});

describe('zodResolver — Zod version compatibility', () => {
  describe('instantiation (does not throw)', () => {
    const schemas = [
      { name: 'simple object', schema: simpleSchema },
      { name: 'lease (deeply nested + superRefine)', schema: leaseFormSchema },
      { name: 'contact (transform chains)', schema: contactFormSchema },
      { name: 'amount distribution (defaults + enums)', schema: amountWithDistributionSchema },
    ];

    it.each(schemas)(
      'creates resolver for "$name" without error',
      ({ schema }) => {
        expect(() => zodResolver(schema)).not.toThrow();
      },
    );
  });

  describe('validation (resolves correctly)', () => {
    it('returns no errors for valid data', async () => {
      const resolver = zodResolver(simpleSchema);
      const result = await resolver(
        { name: 'Test', email: 'test@example.com', age: 25 },
        {},
        { fields: {}, shouldUseNativeValidation: false } as any,
      );
      expect(result.errors).toEqual({});
      expect(result.values).toBeDefined();
    });

    it('returns errors for invalid data', async () => {
      const resolver = zodResolver(simpleSchema);
      const result = await resolver(
        { name: '', email: 'not-an-email', age: -1 },
        {},
        { fields: {}, shouldUseNativeValidation: false } as any,
      );
      expect(Object.keys(result.errors).length).toBeGreaterThan(0);
    });

    it('returns errors for empty data', async () => {
      const resolver = zodResolver(simpleSchema);
      const result = await resolver(
        {},
        {},
        { fields: {}, shouldUseNativeValidation: false } as any,
      );
      expect(Object.keys(result.errors).length).toBeGreaterThan(0);
    });
  });
});
```

**Why this design:**

- **`it.each` for instantiation** — Tests multiple schema complexity levels (simple object, deeply nested with superRefine, transform chains, defaults + enums) with zero code duplication.
- **Simple schema for validation tests** — Uses a trivial schema for the valid/invalid/empty path tests because the goal is testing `zodResolver`'s behavior, not the schema's behavior (that's what snapshot tests are for).
- **Complex schemas for instantiation only** — The `leaseFormSchema` and `contactFormSchema` are included to verify that `zodResolver` can handle Zod v4's internal representation of complex schemas (effects, transforms, nested objects). Full validation of these schemas would require constructing complete fixture objects, which is already covered by snapshot tests.
- **`shouldUseNativeValidation: false`** — Matches the default React Hook Form configuration used in the codebase.

#### Benefits Summary

| Benefit | Explanation |
|---------|-------------|
| **Catches the #1 migration blocker** | If `zodResolver` breaks, every form breaks. This test detects incompatibility before any migration effort is invested. |
| **Extremely low cost** | ~50 lines, one file, sub-second execution. Near-zero maintenance. |
| **Binary pass/fail** | Either `zodResolver` works with Zod v4 or it doesn't. No ambiguity in results. |
| **Guards against future resolver updates** | Even after migration, this test catches regressions if `@hookform/resolvers` ships a breaking update. |
| **Works as a pre-flight check** | Can be run on a throwaway branch with Zod v4 installed to determine if the migration is even feasible, before investing days of work. |

#### Trade-offs

| Trade-off | Impact | Mitigation |
|-----------|--------|------------|
| **Does not test form UI** | Verifies resolver function, not that error messages render correctly in components. | Manual QA of 6 critical forms covers UI rendering. |
| **Does not test all 103 schemas** | Only instantiates 4 representative schemas. A schema with a unique Zod pattern not represented here could still break. | The 4 selected schemas cover the major pattern categories: simple objects, nested objects with superRefine, transform chains, defaults with enums. If these work, simpler schemas will also work (zodResolver processes all schemas through the same internal API). |
| **Mock-ish `fields` parameter** | The `fields` parameter is cast to `any` because constructing a real `FieldValues` object for complex schemas would require the full React Hook Form context. | This is acceptable because the test targets zodResolver's Zod interaction, not its React Hook Form field mapping. The `fields` parameter is only used for `shouldUseNativeValidation` behavior, which is disabled. |
| **Does not detect subtle error format differences** | zodResolver may succeed but produce differently formatted error objects that React Hook Form displays incorrectly. | Schema snapshot tests (primary) catch error structure changes at the Zod level. The manual QA step catches display issues. |

---

### Combined Testing Approach: How the Two Types Work Together

```
Layer 1: tsc --noEmit (FREE — already in CI)
├── Catches: removed APIs, type signature changes, generic changes
├── Covers: ~90 schema files with no .transform()
└── Cost: zero additional effort

Layer 2: Schema Snapshot Tests (PRIMARY — ~500 lines across 13 files)
├── Catches: silent .default() changes, .transform() output changes, error structure changes
├── Covers: 13 high-risk schema files (100% of .transform() usage)
└── Cost: ~2-3 hours to write fixtures

Layer 3: zodResolver Smoke Tests (SECONDARY — ~50 lines, 1 file)
├── Catches: @hookform/resolvers internal API incompatibility
├── Covers: the single integration point between Zod and React Hook Form
└── Cost: ~30 minutes to write

Layer 4: Manual QA (POST-MIGRATION — no code)
├── Catches: UI rendering issues, real-world edge cases
├── Covers: 6 most critical forms (lease, purchase invoice v1/v2, contact, broadcast, fee configurator)
└── Cost: ~2-3 hours of manual testing
```

**Total automated test code**: ~550 lines across 15 files
**Total risk coverage**: All 14 breaking change categories from the catalog
**Total estimated writing time**: 3-4 hours
**Ongoing maintenance cost**: Near zero (snapshots only break on intentional schema changes)

---

## TypeScript Compile Time Benchmarking

### Why This Matters for Persuasion

TypeScript compile time is a tangible, measurable metric that directly impacts:
- **Developer experience**: Every `tsc --noEmit` run during development
- **CI/CD pipeline time**: Build time affects deployment speed
- **Code review feedback loop**: Slower builds = slower iteration

With 103 schema files generating complex inferred types, Zod's generic structure directly impacts TypeScript performance. Zod v4's simpler generics (`ZodType<Output, Input>` vs `ZodType<Output, Def, Input>`) should reduce type instantiations.

### Benchmark Script

```bash
#!/bin/bash
# benchmark-tsc.sh — Run from sndq-fe/

set -euo pipefail

echo "======================================"
echo "  TypeScript Compile Time Benchmark"
echo "======================================"
echo "Node:    $(node --version)"
echo "TSC:     $(npx tsc --version)"
echo "Date:    $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Zod:     $(node -e "console.log(require('zod/package.json').version)")"
echo ""

# 1. Clean all caches for fair comparison
echo "--- Cleaning caches ---"
rm -rf .next/types tsconfig.tsbuildinfo node_modules/.cache
echo "Caches cleared."
echo ""

# 2. Warm-up run (populates OS filesystem cache)
echo "--- Warm-up run ---"
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit > /dev/null 2>&1 || true
echo "Warm-up complete."
echo ""

# 3. Benchmark: tsc --noEmit (5 iterations)
echo "--- tsc --noEmit (5 runs) ---"
total_noEmit=0
for i in {1..5}; do
  rm -f tsconfig.tsbuildinfo
  start=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
  NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit 2>&1
  end=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1e9))")
  elapsed=$(( (end - start) / 1000000 ))
  echo "  Run $i: ${elapsed}ms"
  total_noEmit=$((total_noEmit + elapsed))
done
avg_noEmit=$((total_noEmit / 5))
echo "  Average: ${avg_noEmit}ms"
echo ""

# 4. Diagnostics run (detailed breakdown)
echo "--- tsc --noEmit --diagnostics ---"
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --diagnostics 2>&1 | tee "tsc-diagnostics-$(date +%Y%m%d-%H%M%S).txt"
echo ""

# 5. Generate trace for deep analysis
echo "--- Generating tsc trace ---"
rm -rf tsc-trace
rm -f tsconfig.tsbuildinfo
NODE_OPTIONS="--max-old-space-size=8192" npx tsc --noEmit --generateTrace ./tsc-trace 2>&1
echo "Trace saved to ./tsc-trace/"
echo "Open trace.json in chrome://tracing or https://ui.perfetto.dev/"
echo ""

echo "======================================"
echo "  Benchmark complete"
echo "  Average tsc --noEmit: ${avg_noEmit}ms"
echo "======================================"
```

### How to Use

```bash
# Before migration (on current Zod v3 branch)
cd sndq-fe
bash benchmark-tsc.sh 2>&1 | tee benchmark-zod-v3.txt

# After migration (on Zod v4 branch)
bash benchmark-tsc.sh 2>&1 | tee benchmark-zod-v4.txt

# Compare
diff benchmark-zod-v3.txt benchmark-zod-v4.txt
```

### Key Metrics to Extract

From `tsc --diagnostics`, extract these specific values:

| Metric | What It Measures | Expected Zod v4 Impact |
|--------|------------------|----------------------|
| **Check time** | Time spent on type-checking | Should decrease (simpler generics) |
| **Types** | Total number of types resolved | Should decrease (no `Def` generic) |
| **Instantiations** | Number of generic instantiations | Should significantly decrease |
| **Memory used** | Peak memory during compilation | Should decrease |
| **Total time** | End-to-end tsc time | Should decrease |

From `--generateTrace`, look for:
- `checkExpression` events involving `ZodType`, `ZodObject`, `ZodEffects`
- Compare total time spent in Zod-related type resolutions

### Additional Build-Time Metrics

```bash
# Next.js build time comparison
time NODE_OPTIONS="--max-old-space-size=8192" pnpm build 2>&1 | tee build-zod-v3.txt
# After migration:
time NODE_OPTIONS="--max-old-space-size=8192" pnpm build 2>&1 | tee build-zod-v4.txt
```

### Bundle Size Comparison

```bash
# Install bundle analyzer (if not already present)
pnpm add -D @next/bundle-analyzer

# Build with analysis
ANALYZE=true pnpm build

# Compare .next/analyze/ reports before and after
```

### Presentation Format for Metrics

Create a comparison table like:

| Metric | Zod v3 | Zod v4 | Delta | % Change |
|--------|--------|--------|-------|----------|
| `tsc --noEmit` avg (5 runs) | Xms | Yms | -Zms | -W% |
| Type instantiations | A | B | -(A-B) | -X% |
| Memory used | AmMB | BmMB | -CmMB | -D% |
| `next build` total | As | Bs | -Cs | -E% |
| Bundle size (main) | AkB | BkB | -CkB | -F% |

---

## Migration Execution Plan

### Prerequisites (Before Starting)

- [ ] Run zodResolver smoke test on throwaway branch with Zod v4 installed (see "zodResolver Smoke Tests" section) — **if this fails, migration is BLOCKED**
- [ ] Verify `@hookform/resolvers` changelog and GitHub issues for Zod v4 support
- [ ] Run and save baseline `tsc --diagnostics` and `tsc --generateTrace`
- [ ] Run and save baseline `next build` timing
- [ ] Write schema snapshot tests for 13 high-risk files + zodResolver smoke tests (see "Pre-Migration Testing Strategy" section)
- [ ] Run `pnpm test` to generate baseline snapshots on Zod v3
- [ ] Ensure all existing tests pass
- [ ] Create a dedicated migration branch: `feat/zod-v4-migration`

### Step 1: Install Zod v4 (Day 1)

```bash
cd sndq-fe
pnpm add zod@^4.0.0
cd packages/ui
pnpm add zod@^4.0.0
```

Verify single version:
```bash
pnpm why zod
```

### Step 2: Run the Community Codemod (Day 1)

```bash
npx @codemod/cli run zod-3-4 --target sndq-fe/src/
```

This automates many mechanical changes:
- `z.nativeEnum()` → `z.enum()`
- `.Enum.` → `.enum.`
- `.Values.` → `.enum.`
- `invalid_type_error` / `required_error` → `error` function
- `z.string().email()` → `z.email()`
- etc.

**Important**: Always review codemod output manually. Do NOT blindly commit.

### Step 3: Fix TypeScript Compilation Errors (Day 2–3)

Run `tsc --noEmit` and fix errors iteratively:

```bash
NODE_OPTIONS="--max-old-space-size=8192" pnpm type-check 2>&1 | head -100
```

Expected error categories:
1. `z.nativeEnum()` / `.Enum` / `.Values` → change to `z.enum()` / `.enum`
2. `invalid_type_error` / `required_error` → replace with `error` function
3. `z.record()` single argument → add key schema
4. `ZodTypeAny` references → replace with `ZodType`
5. `z.unknown()` / `z.any()` optionality → add `.optional()` where needed

### Step 4: Address Silent Behavior Changes (Day 3–4)

These won't cause TypeScript errors but will change runtime behavior:

1. **`.default()` + `.transform()` audit**:
   ```bash
   rg -l '\.transform\(' src/ --glob '*.ts' | xargs rg -l '\.default\('
   ```
   For each match, determine if `.prefault()` is needed.

2. **`.default()` + `.optional()` in objects audit**:
   ```bash
   rg '\.default\(.*\)\.optional\(\)' src/ --glob '*.ts'
   rg '\.optional\(\)\.default\(' src/ --glob '*.ts'
   ```

3. **Error map precedence audit**: Search for `.parse(` or `.safeParse(` calls that pass an error map.

### Step 5: Run All Tests (Day 4)

```bash
pnpm test
```

- All 13 schema snapshot tests should still pass — if any snapshot changed, it means Zod v4 produces different output for that schema
- For each snapshot diff: determine if the change is expected (e.g., `.default()` now populates a key) or a regression
- If expected: decide whether to accept the new behavior or use `.prefault()` to restore Zod 3 behavior
- zodResolver smoke tests must pass — if they fail after Step 3 fixes, the `@hookform/resolvers` version needs updating
- Update snapshots only after confirming each behavior change is intentional: `pnpm test -- -u`

### Step 6: Manual QA of Critical Forms (Day 4–5)

Test these forms manually in the browser:

1. **Lease creation form** (most complex: 69+ schema calls)
2. **Purchase invoice form** (multiple variants: v1, v2, steward)
3. **Cost settlement form**
4. **Contact form** (shared across modules)
5. **Broadcast creation form**
6. **Fee configurator form**

For each form, test:
- Happy path submission
- Validation error display
- Default value population
- Transform outputs (check submitted data in network tab)

### Step 7: Run Post-Migration Benchmarks (Day 5)

Run the benchmark script from the "TypeScript Compile Time Benchmarking" section and compare with baseline.

### Step 8: Update Deprecated Patterns (Optional, Day 5+)

These are deprecated but still functional. Can be done later:
- `message:` → `error:`
- `z.string().email()` → `z.email()`
- `.merge()` → `.extend()` or spread
- `.strict()` / `.passthrough()` → `z.strictObject()` / `z.looseObject()`

---

## Rollback Strategy

### Git-Based Rollback

```bash
# If migration causes unexpected issues in production
git revert <migration-commit-hash>
pnpm install
```

### Feature Flag Approach (Alternative)

If needed, Zod v4 provides a compatibility import:

```typescript
// Temporary: use Zod 3 compatibility mode
import * as z from "zod/v3";
```

This allows gradual migration file-by-file if a big-bang approach is too risky.

---

## Post-Migration Validation Checklist

- [ ] `pnpm type-check` passes with zero errors
- [ ] `pnpm test` passes (all snapshot tests match or are reviewed)
- [ ] `pnpm lint` passes
- [ ] `pnpm build` succeeds
- [ ] `pnpm why zod` shows single version (no duplicates)
- [ ] All 6 critical forms tested manually (lease, purchase invoice, cost settlement, contact, broadcast, fee configurator)
- [ ] Benchmark comparison documented (tsc time, instantiations, memory, bundle size)
- [ ] No `z.nativeEnum()` references remain (`rg 'nativeEnum' src/`)
- [ ] No `.Enum.` or `.Values.` accessors remain
- [ ] No `invalid_type_error` or `required_error` references remain
- [ ] `packages/ui` upgraded and tested
- [ ] PR reviewed by at least one team member

---

## Cross-References

| Topic | Related Notes | Relevance |
|-------|--------------|-----------|
| **Migration progress tracker** | [progress.md](./progress.md) | **Tracks batch-by-batch progress, metrics, and per-file checklist** |
| React rendering behavior | [react-rendering-behavior.md](../../../../04-frontend/react/react-rendering-behavior.md) | Form re-render performance benefits from faster Zod parsing |
| Learning patterns | [learning-patterns.md](../../../../04-frontend/react/learning-patterns.md) | Tree shaking patterns relevant to Zod v4 bundle improvements |
| sndq-fe reading plan | [sndq-fe-reading-plan.md](../../sndq-fe-reading-plan.md) | Form patterns section maps to Zod usage |
| sndq contribution plan | [sndq-contribution-plan.md](../../../sndq-contribution-plan.md) | FE optimization pillar — this migration is a concrete initiative |

---

## References

- [Zod v4 Release Notes](https://zod.dev/v4/) — Official announcement with performance benchmarks
- [Zod v4 Migration Guide](https://v4.zod.dev/v4/changelog) — Complete list of breaking changes
- [Zod v4 Documentation](https://v4.zod.dev/) — Full API documentation
- [zod-v3-to-v4 Codemod](https://github.com/nicoespeon/zod-v3-to-v4) — Community-maintained migration codemod
- [Codemod.com — Zod 3→4 Guide](https://docs.codemod.com/guides/migrations/zod-3-4) — Automated migration tooling
- [Migrating to Zod 4 (DEV Community)](https://dev.to/pockit_tools/migrating-to-zod-4-the-complete-guide-to-breaking-changes-performance-gains-and-new-features-3ll0) — Community guide with examples
- [@hookform/resolvers GitHub](https://github.com/react-hook-form/resolvers) — Check for Zod v4 compatibility updates

---

## My Notes

- The `.default()` behavior change is by far the most dangerous aspect of this migration. It produces no errors, only different data. Prioritize this in testing above everything else.
- The codebase has almost no schema-level tests. This migration is an opportunity to establish a testing baseline that pays dividends beyond just the Zod upgrade.
- Consider doing the migration in two PRs: (1) pre-migration tests, (2) actual Zod upgrade. This way the safety net is reviewed and merged independently.
- The `@hookform/resolvers` compatibility check should be done **before** spending any time on migration work. If it's not compatible, the entire effort is blocked.
- Post-migration, update the `.cursor/rules/sndq.mdc` rule to reference "Zod v4" instead of "Zod v3".

### Testing Decision Log (2026-03-27)

**Decision**: Use **Schema Snapshot Tests** (primary) + **zodResolver Smoke Tests** (secondary) only.

**Rationale**: The migration's highest risk is silent runtime behavior changes (`.default()` short-circuit, `.transform()` + `.default()` combo, `.optional()` + `.default()` key presence). These cannot be caught by the compiler or by E2E tests cost-effectively. Schema snapshot tests target exactly this risk with minimal boilerplate via a factory helper pattern.

**Rejected alternatives and why**:
- **E2E (Playwright)**: 100+ forms makes this prohibitively expensive (~50-100 lines per form, staging dependency, auth setup). Maintenance cost too high for a one-time migration.
- **Component Render Tests (RTL)**: Deep provider tree dependency (`WorkspacesContext`, `QueryClientProvider`, `IntlProvider`, `FormProvider`) makes mocking impractical for 100+ forms.
- **Property-Based (fast-check)**: Overkill — risk is known behavior changes, not unknown edge cases. Setting up arbitraries for deeply nested schemas (lease = 492 lines) too expensive.
- **Contract/Type Tests**: Redundant with `tsc --noEmit` which already type-checks all 170+ `z.infer<>` usages.
- **nativeEnum Accessor Tests**: Absorbed into snapshot tests (valid fixtures exercise enum values; `tsc` catches `.Enum`/`.Values` removal).

**Key numbers**: 13 schema files targeted (100% of `.transform()` usage), ~550 lines total test code, ~3-4 hours writing time, near-zero ongoing maintenance.
