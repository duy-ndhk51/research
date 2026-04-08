---
name: Zod test factory setup
overview: Create the schema-test-factory, zodResolver smoke test, and snapshot tests for purchase-invoice-v2 schema (covers both V2 and V3 forms).
todos:
  - id: create-factory
    content: Create `src/__tests__/helpers/schema-test-factory.ts` with `describeSchema()` function
    status: completed
  - id: create-smoke-test
    content: Create `src/__tests__/zod-resolver-compat.test.ts` with 5 zodResolver regression guard tests
    status: completed
  - id: create-snapshot-test
    content: Create `src/modules/financial/forms/purchase-invoice-v2/__tests__/schema.snapshot.test.ts` with snapshot tests for all 3 exported schemas
    status: completed
  - id: run-and-verify
    content: Run tests, generate baseline snapshots, verify `.snap` files are correct
    status: in_progress
isProject: false
---

# Zod Test Factory + Snapshot Tests for Purchase Invoice

## Context

- `PurchaseInvoiceFormV3` imports `purchaseInvoiceFormV2Schema` directly from `../purchase-invoice-v2/schema` (line 55) and uses `zodResolver(purchaseInvoiceFormV2Schema)` (line 134) -- so testing the V2 schema covers both forms.
- Existing fixtures in [schema-fixtures.ts](sndq-fe/src/modules/financial/forms/purchase-invoice-v2/schema/schema-fixtures.ts) (`validUnit`, `validAmountData`, `validAmountDataSyndic`, `validInvoiceData`) will be reused.
- Vitest config at [vitest.config.mts](sndq-fe/vitest.config.mts) uses `tsconfigPaths()` so `@/` aliases work. Test pattern: `src/**/*.test.{js,ts,jsx,tsx}`.

## 3 Files to Create

### File 1: `src/__tests__/helpers/schema-test-factory.ts`

Reusable `describeSchema(name, schema, fixtures)` factory that generates 3-4 snapshot tests per schema:
- Valid input -> snapshot parsed output (catches `.transform()` changes)
- Minimal input -> snapshot defaults (catches `.default()` behavior changes)
- Empty input -> snapshot error structure (catches error format changes)
- Invalid input -> snapshot type errors (optional)

Key design: error snapshots capture `path` + `code` only (not `message`) to avoid false positives from intentional message changes.

### File 2: `src/__tests__/zod-resolver-compat.test.ts`

5 tests as regression guard for `zodResolver` compatibility:
- Creates resolver without throwing (3 schemas)
- Validates valid data correctly
- Returns errors for invalid data
- Applies `.default()` values through resolver
- Applies `.transform()` through resolver

Uses self-contained test schemas (not project schemas) to keep it isolated.

### File 3: `src/modules/financial/forms/purchase-invoice-v2/__tests__/schema.snapshot.test.ts`

Tests 3 exported schemas from [schema.ts](sndq-fe/src/modules/financial/forms/purchase-invoice-v2/schema.ts):

- **`amountWithDistributionSchema`** -- 5 `.default()` fields (`id`, `hasVat`, `hasCustomPrice`, `wholeBuilding`, `useDistributionKey`), 1 `.superRefine()`
- **`amountWithDistributionSchemaSyndic`** -- inherits above + extra `motherId` superRefine
- **`purchaseInvoiceFormV2Schema`** -- 6 `.default()` fields + 3 `.transform()` fields + 1 `.superRefine()` + `nativeEnum` + `required_error` usage

Fixtures: reuse existing from `schema-fixtures.ts`, extend with optional fields for `valid` fixture. `minimal` fixture deliberately omits `.default()` fields to capture their auto-fill behavior.

## Verification

Run all tests after creation:

```bash
pnpm test src/__tests__/ src/modules/financial/forms/purchase-invoice-v2/__tests__/schema.snapshot.test.ts
```

Then generate baseline snapshots:

```bash
pnpm test src/__tests__/ src/modules/financial/forms/purchase-invoice-v2/__tests__/schema.snapshot.test.ts -- -u
```

Review `.snap` files to confirm they look correct, then done.
