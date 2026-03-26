# Zod v3 → v4 Migration Plan — sndq-fe

## TL;DR

Zod v4 delivers **14x faster string parsing**, **7x faster array parsing**, and **6.5x faster object parsing** with a smaller bundle via improved tree shaking. The `sndq-fe` codebase has **~103 files** importing Zod across **100+ form schemas**, making this a high-impact but high-effort migration. The biggest risks are silent behavior changes in `.default()`, `@hookform/resolvers` compatibility, and `z.nativeEnum()` removal across ~44 files.

**Created**: 2026-03-27
**Status**: Planning
**Estimated effort**: 5–8 days (including pre-migration tests + validation)

---

## Table of Contents

- [Current State Audit](#current-state-audit)
- [Zod v4 Breaking Changes — Full Catalog](#zod-v4-breaking-changes--full-catalog)
- [Impact Analysis on sndq-fe](#impact-analysis-on-sndq-fe)
- [Benefits](#benefits)
- [Risks & Mitigation](#risks--mitigation)
- [Pre-Migration Testing Strategy](#pre-migration-testing-strategy)
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

### Why Tests Are Essential

With only **5 test files** in the entire `src/` directory (and only 1 testing a Zod schema), the codebase has near-zero safety net for schema changes. The `.default()` behavior change alone can silently alter data flowing through dozens of forms without any TypeScript or runtime error. Tests are the **only way** to catch these silent regressions.

### Phase 1: Schema Behavior Snapshot Tests (Priority: CRITICAL)

**Goal**: Capture exact parsing behavior of all critical schemas before migration.

**Target**: All schema files in the top-10 complexity list, plus all schemas using `.transform()` + `.default()` combinations.

**Test pattern**:

```typescript
// __tests__/schema-snapshots/lease-schema.test.ts
import { describe, it, expect } from 'vitest';
import { leaseFormSchema } from '@/modules/patrimony/forms/lease/schema';

describe('Lease Form Schema — Pre-migration snapshot', () => {
  const validInput = {
    // ... complete valid lease form data
  };

  const minimalInput = {
    // ... only required fields
  };

  it('should parse valid input and produce expected output', () => {
    const result = leaseFormSchema.safeParse(validInput);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data).toMatchSnapshot();
    }
  });

  it('should parse minimal input with correct defaults', () => {
    const result = leaseFormSchema.safeParse(minimalInput);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data).toMatchSnapshot();
    }
  });

  it('should reject empty input with expected error structure', () => {
    const result = leaseFormSchema.safeParse({});
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.map(i => ({
        path: i.path,
        code: i.code,
        message: i.message,
      }))).toMatchSnapshot();
    }
  });

  it('should reject invalid types with expected errors', () => {
    const result = leaseFormSchema.safeParse({
      // ... fields with wrong types
    });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.map(i => ({
        path: i.path,
        code: i.code,
        message: i.message,
      }))).toMatchSnapshot();
    }
  });
});
```

**Files to cover (minimum)**:
1. `src/modules/patrimony/forms/lease/schema.ts`
2. `src/modules/financial/forms/purchase-invoice-v2/schema.ts`
3. `src/modules/financial/forms/purchase-invoice/schema.ts`
4. `src/components/contact/schema.ts`
5. `src/modules/fee-management/FeeConfiguratorForm/schema.ts`
6. `src/modules/financial/forms/cost-settlement/CostSettlementForm/schema.ts`
7. `src/modules/financial/forms/fiscal-year-setup/schema.ts`
8. `src/modules/financial/forms/provision/ProvisionForm/schema.ts`
9. `src/modules/patrimony/forms/lease/revision/schema.ts`
10. `src/modules/broadcasts/schemas/broadcastFormSchema.ts`

### Phase 2: Transform + Default Combo Tests (Priority: CRITICAL)

**Goal**: Specifically test all schemas where `.transform()` and `.default()` coexist — these are the most likely to break silently.

**Discovery command**:
```bash
# Find files that have BOTH .transform and .default
rg -l '\.transform\(' sndq-fe/src/ --glob '*.ts' | \
  xargs rg -l '\.default\(' --glob '*.ts'
```

For each file found, write a test that:
1. Parses `undefined` for the field with `.default()` + `.transform()`
2. Snapshots the result
3. After migration, if snapshot changes → need `.prefault()` instead

### Phase 3: zodResolver Integration Tests (Priority: HIGH)

**Goal**: Verify that form submission works end-to-end with zodResolver.

```typescript
// __tests__/integration/form-resolver.test.ts
import { zodResolver } from '@hookform/resolvers/zod';
import { leaseFormSchema } from '@/modules/patrimony/forms/lease/schema';

describe('zodResolver compatibility', () => {
  it('should create a resolver without errors', () => {
    expect(() => zodResolver(leaseFormSchema)).not.toThrow();
  });

  it('should validate valid data', async () => {
    const resolver = zodResolver(leaseFormSchema);
    const result = await resolver(validData, {}, { fields: {} });
    expect(result.errors).toEqual({});
  });

  it('should return expected errors for invalid data', async () => {
    const resolver = zodResolver(leaseFormSchema);
    const result = await resolver({}, {}, { fields: {} });
    expect(Object.keys(result.errors).length).toBeGreaterThan(0);
  });
});
```

### Phase 4: nativeEnum Accessor Tests (Priority: MEDIUM)

**Goal**: Verify that all `z.nativeEnum()` migrations preserve enum value access.

```typescript
// Test that enum values are accessible via .enum (not .Enum or .Values)
import { myEnumSchema } from '@/path/to/schema';

describe('Enum accessor migration', () => {
  it('should access values via .enum', () => {
    expect(myEnumSchema.enum.SomeValue).toBeDefined();
  });
});
```

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

- [ ] Verify `@hookform/resolvers` supports Zod v4 (check changelog, GitHub issues, or test in isolation)
- [ ] Run and save baseline `tsc --diagnostics` and `tsc --generateTrace`
- [ ] Run and save baseline `next build` timing
- [ ] Write pre-migration snapshot tests (Phase 1 & 2 from testing strategy)
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

- All pre-migration snapshot tests should still pass
- If any snapshot changed → investigate the behavior change
- Update snapshots only after confirming the new behavior is correct

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
| React rendering behavior | [react-rendering-behavior.md](../../04-frontend/react/react-rendering-behavior.md) | Form re-render performance benefits from faster Zod parsing |
| Learning patterns | [learning-patterns.md](../../04-frontend/react/learning-patterns.md) | Tree shaking patterns relevant to Zod v4 bundle improvements |
| sndq-fe reading plan | [sndq-fe-reading-plan.md](./sndq-fe-reading-plan.md) | Form patterns section maps to Zod usage |
| sndq contribution plan | [sndq-contribution-plan.md](../sndq-contribution-plan.md) | FE optimization pillar — this migration is a concrete initiative |

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
