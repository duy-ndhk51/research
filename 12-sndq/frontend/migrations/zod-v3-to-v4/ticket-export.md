# [Setup] Create Test Factory + zodResolver Smoke Test

**Type**: Task · `sndq-fe` · Zod v3 → v4 Migration Infrastructure
**Prerequisite**: `zod@3.25.76` installed (ships v3 + v4 engines)
**Estimate**: ~1h infra + ~8-9h per-file (test + migrate) = **~10h total**

---

## Objective

Create reusable test infrastructure for the Zod v3 → v4 migration:

1. **`schema-test-factory.ts`** — a `describeSchema()` factory that generates 3-4 snapshot tests per schema from fixtures
2. **`zod-resolver-compat.test.ts`** — regression guard for `zodResolver` + Zod compatibility

These 2 files are created **once**, then reused for every schema file during migration.

---

## Why

The most dangerous Zod v4 breaking change is **`.default()` short-circuiting** — it silently produces different parsed data with no TypeScript or runtime error. Schema snapshot tests are the only way to catch this.

| Risk | What Happens | Detection |
|------|-------------|-----------|
| `.default()` short-circuits parsing | Fields get default values when they shouldn't — wrong data saved silently | Schema snapshot diff |
| `.transform()` output changes | Computed values differ after migration | Schema snapshot diff |
| `zodResolver` breaks with v4 | All 100+ forms fail validation at once | Smoke test |

Upgraded to `@hookform/resolvers@5.2.2` with native Zod v4 `zodResolver` support (requires RHF >=7.55.0). Type errors from input/output inference resolved via centralized wrapper (`src/lib/form/zod-resolver.ts`). The smoke test is a **regression guard**, not a blocker.

---

## Deliverables

| # | File | Purpose | Lines | Create When |
|---|------|---------|:-----:|-------------|
| A | `src/__tests__/helpers/schema-test-factory.ts` | Reusable `describeSchema()` factory | ~50 | **Once — infra step** |
| B | `src/__tests__/zod-resolver-compat.test.ts` | Regression guard for `zodResolver` | ~65 | **Once — infra step** |
| C | 13 snapshot test files (`*.snapshot.test.ts`) | Baseline snapshots → migration diff | ~30-60 each | **Just-in-time per-file** |

---

## Deliverable A: `schema-test-factory.ts`

### Design

A factory function that generates a standard snapshot test suite for any Zod schema. Per-file boilerplate reduced to: imports + fixtures + one function call.

```typescript
// src/__tests__/helpers/schema-test-factory.ts
import { describe, it, expect } from 'vitest';
import type { ZodSchema } from 'zod';

interface SchemaFixtures {
  valid: Record<string, unknown>;   // all fields — catches .transform() changes
  minimal: Record<string, unknown>; // required fields only — catches .default() changes
  invalid?: Record<string, unknown>; // wrong types — captures error structure (optional)
}

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
          result.error.issues.map((i) => ({ path: i.path, code: i.code })),
        ).toMatchSnapshot();
      }
    });

    if (fixtures.invalid) {
      it('rejects invalid types with expected errors', () => {
        const result = schema.safeParse(fixtures.invalid);
        expect(result.success).toBe(false);
        if (!result.success) {
          expect(
            result.error.issues.map((i) => ({ path: i.path, code: i.code })),
          ).toMatchSnapshot();
        }
      });
    }
  });
}
```

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| `toMatchSnapshot()` over `toEqual()` | Auto-generates expected values — no manual construction of complex nested objects |
| Error snapshots capture `path` + `code` only | `message` text may intentionally change during migration — reduces false positives |
| `minimal` fixture is required | **Primary defense** against `.default()` behavior changes — tests what happens when optional fields are omitted |
| `invalid` fixture is optional | Not all schemas have meaningful "wrong type" cases |

---

## Deliverable B: `zod-resolver-compat.test.ts`

### Context

Upgraded to `@hookform/resolvers@5.2.2` with native Zod v4 `zodResolver` support. Original v4.1.3 used `@standard-schema/utils`; v5.2.2 has direct Zod v4 integration. This test is a **regression guard**, not a blocker.

```typescript
// src/__tests__/zod-resolver-compat.test.ts
import { describe, it, expect } from 'vitest';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const simpleSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().positive().optional(),
});

const schemaWithDefaults = z.object({
  title: z.string(),
  isActive: z.boolean().default(true),
  tags: z.array(z.string()).default([]),
});

const schemaWithTransform = z.object({
  amount: z.string().transform((v) => Number(v)),
});

describe('zodResolver — Zod version compatibility', () => {
  it('creates resolver without throwing', () => {
    expect(() => zodResolver(simpleSchema)).not.toThrow();
    expect(() => zodResolver(schemaWithDefaults)).not.toThrow();
    expect(() => zodResolver(schemaWithTransform)).not.toThrow();
  });

  it('validates valid data correctly', async () => {
    const resolver = zodResolver(simpleSchema);
    const result = await resolver(
      { name: 'John', email: 'john@example.com' },
      undefined,
      { fields: {}, shouldUseNativeValidation: false } as any,
    );
    expect(result.errors).toEqual({});
    expect(result.values).toBeDefined();
  });

  it('returns errors for invalid data', async () => {
    const resolver = zodResolver(simpleSchema);
    const result = await resolver(
      { name: '', email: 'not-email' },
      undefined,
      { fields: {}, shouldUseNativeValidation: false } as any,
    );
    expect(result.errors.name).toBeDefined();
    expect(result.errors.email).toBeDefined();
  });

  it('applies .default() values through resolver', async () => {
    const resolver = zodResolver(schemaWithDefaults);
    const result = await resolver(
      { title: 'Test' },
      undefined,
      { fields: {}, shouldUseNativeValidation: false } as any,
    );
    expect(result.values.isActive).toBe(true);
    expect(result.values.tags).toEqual([]);
  });

  it('applies .transform() through resolver', async () => {
    const resolver = zodResolver(schemaWithTransform);
    const result = await resolver(
      { amount: '42' },
      undefined,
      { fields: {}, shouldUseNativeValidation: false } as any,
    );
    expect(result.values.amount).toBe(42);
  });
});
```

After full migration: change `import { z } from 'zod'` → `'zod/v4'`. If all 5 tests pass → confirmed safe.

---

## Deliverable C: 13 Schema Snapshot Tests (Just-in-Time)

### Approach

Instead of writing all 13 tests upfront, each test is written **immediately before migrating** that specific file. Benefits:

- Focus on 1 schema at a time (no context switching)
- No stale snapshots (test written right before migration)
- Each migrated file is a shippable unit
- Fixtures informed by reading the schema first

### File Naming

```
src/modules/patrimony/forms/lease/__tests__/schema.snapshot.test.ts
src/modules/financial/forms/purchase-invoice-v2/__tests__/schema.snapshot.test.ts
src/components/contact/__tests__/schema.snapshot.test.ts
...
```

`.snapshot.test.ts` suffix distinguishes migration tests from existing unit tests.

### Per-file Pattern

```typescript
// src/modules/patrimony/forms/property/__tests__/schema.snapshot.test.ts
import { describeSchema } from '@/__tests__/helpers/schema-test-factory';
import { propertyFormSchema } from '../schema';

const UUID = '550e8400-e29b-41d4-a716-446655440000';

describeSchema('propertyFormSchema', propertyFormSchema, {
  valid: {
    name: 'Apartment 4B',
    type: 'apartment',
    floor: 2,
    buildingId: UUID,
    // ... all required + optional fields
  },
  minimal: {
    name: 'X',
    buildingId: UUID,
  },
});
```

For schemas with sub-schemas, test each individually:

```typescript
describeSchema('GeneralInfoSchema', generalInfoSchema, { valid: {...}, minimal: {...} });
describeSchema('VatRuleSchema', vatRuleSchema, { valid: {...}, minimal: {...} });
describeSchema('LeaseFormSchema (full)', leaseFormSchema, { valid: {...}, minimal: {...} });
```

---

## 13-File Audit

| # | Schema File | `.default()` | `.transform()` | Sub-schemas | Est. |
|---|-------------|:------------:|:--------------:|:-----------:|------|
| 1 | `patrimony/forms/property/schema.ts` | 0 | 1 | 1 | 20m |
| 2 | `contact-book/.../form/schema.ts` | 0 | 1 | 2 | 15m |
| 3 | `patrimony/forms/lease/.../lease-deposit/schema.ts` | 1 | 1 | 2 | 20m |
| 4 | `patrimony/forms/lease/revision/schema.ts` | 0 | 3 | 4 | 30m |
| 5 | `patrimony/forms/building/schema.ts` | 0 | 2 | 5 | 30m |
| 6 | `financial/forms/purchase-invoice-v2-steward/schema.ts` | 5 | 3 | 2 | 35m |
| 7 | `financial/forms/cost-settlement/.../schema.ts` | 6 | 2 | 4 | 45m |
| 8 | `financial/forms/close-fiscal-year/schema.ts` | 9 | 2 | 5 | 45m |
| 9 | `fee-management/FeeConfiguratorForm/schema.ts` | 7 | 1 | 1 | 45m |
| 10 | `financial/forms/purchase-invoice-v2/schema.ts` ⭐ | 11 | 3 | 4 | 40m |
| 11 | `components/contact/schema.ts` | 9 | 4 | 6 | 45m |
| 12 | `financial/forms/purchase-invoice/schema.ts` | 18 | 3 | 3 | 60m |
| 13 | `patrimony/forms/lease/schema.ts` | **21** | 4 | **11** | 90m |

> ⭐ #10 (`purchase-invoice-v2/schema.ts`) is also used by `PurchaseInvoiceFormV3` — migrating benefits both forms.

### Recommended Order

| Phase | Files | Reason | Time |
|-------|-------|--------|------|
| Start (learn patterns) | #1, #2, #3 | Simplest — 0-1 `.default()`, single schema | ~55m |
| Medium | #4, #5, #6 | 0-5 `.default()`, multiple sub-schemas | ~95m |
| Complex | #7, #8, #9, #10, #11 | 6-11 `.default()`, many sub-schemas | ~3.5h |
| Most complex | #12, #13 | 18-21 `.default()`, deeply nested | ~2.5h |

---

## Per-file Workflow

For each of the 13 files:

```
1. Read the schema — understand exports, sub-schemas, .default()/.transform() chains
2. Write __tests__/schema.snapshot.test.ts (import from "zod" — v3)
3. Run test → pnpm test path/to/__tests__/schema.snapshot.test.ts
4. Generate baseline snapshot → pnpm test path/to/__tests__/schema.snapshot.test.ts -- -u
5. Change import: "zod" → "zod/v4" in the schema file
6. Run test → compare snapshot diff
   - No diff → ✅ done
   - Diff → investigate: .default()→.prefault(), restructure, or accept new behavior
7. tsc --noEmit (ensure no type errors)
8. Manual QA in browser
9. Commit
```

---

## Dangerous Patterns to Watch

| Pattern | Found In | Why Dangerous |
|---------|----------|---------------|
| `.optional().default([]).superRefine().transform()` | #11 (contact — emails, phones) | `.default()` short-circuit skips `.superRefine()` + `.transform()` in v4 |
| `.boolean().default(true/false)` in `z.object()` | #13 (lease — 8+ boolean defaults) | v4 may inject keys where v3 didn't when parent is optional |
| `z.array(subSchema).default([])` | #13 (lease — payers, extraCosts) | Array defaults may interact differently with parent object defaults |
| `createBuildingFormSchema(type)` | #5 (building) | Dynamic factory — needs testing with multiple workspace types |
| `nativeEnum` with `.Enum` / `.Values` | #4, #13, #9 | Runtime crash in v4 — needs systematic replacement |

---

## Acceptance Criteria

- [ ] `schema-test-factory.ts` created with `describeSchema()` function
- [ ] `zod-resolver-compat.test.ts` created with 5 tests (all passing on v3)
- [ ] Both infra tests run in <1s
- [ ] Per-file: snapshot test written before migration, baseline `.snap` committed
- [ ] Per-file: after `"zod"` → `"zod/v4"` import change, all snapshot diffs reviewed and accepted
- [ ] Per-file: `tsc --noEmit` passes
- [ ] Per-file: manual QA confirms form behavior unchanged

---

## Notes

- `.snap` files must be committed to git — they are the v3 behavioral baseline
- Existing test fixtures (e.g., `purchase-invoice-v2/schema.test.ts`) can be reused to save fixture authoring time
- Schema snapshot tests run `safeParse()` only — no DOM, no API. Expected runtime: <2s for all 13 files
- AI agents can help generate fixture objects but review cross-field `superRefine` rules carefully
