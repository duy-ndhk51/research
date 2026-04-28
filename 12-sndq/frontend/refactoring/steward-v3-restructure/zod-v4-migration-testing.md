# Zod v4 Migration Testing Guide — Steward Schema

Testing guide for Commit 4C: migrating `purchase-invoice-v2-steward/schema.ts` from Zod v3 to v4 syntax. Covers the 4 syntax substitutions, their risk surface, existing test coverage, and manual verification steps.

Companion: [feature-sync-commits.md](./feature-sync-commits.md) (Commit 4C)

---

## Prerequisites

Before applying the 4 syntax changes, generate the snapshot baseline:

1. Run `pnpm test purchase-invoice-v2-steward` to generate `.snap` files
2. Verify `__tests__/__snapshots__/schema.snapshot.test.ts.snap` and `constants.test.ts.snap` were created
3. Commit the `.snap` files — they are currently untracked

This gives the `describeSchema` factory a baseline to diff against. Without it, snapshot tests pass trivially (no existing snapshot to compare) and cannot catch regressions.

---

## Tier 1 — High Risk

Changed fields that directly affect validation behavior. Failures here break form submission or show wrong error messages.

### 1.1 `remittanceType`: `z.nativeEnum()` to `z.enum()`

**Change**: `z.nativeEnum(PaymentMessageTypeEnum)` to `z.enum(PAYMENT_MESSAGE_TYPE_LIST)`

**What could break**:
- `z.nativeEnum` and `z.enum` produce different error `code` values on invalid input — `invalid_enum_value` vs `invalid_value`. Snapshot tests that pin error structure will fail and need updating.
- `z.enum` uses a string tuple; `z.nativeEnum` uses a TS enum object. If `PAYMENT_MESSAGE_TYPE_LIST` values don't exactly match `PaymentMessageTypeEnum` member values, valid inputs get rejected silently.
- The `.default(PaymentMessageTypeEnum.NONE)` must still work — the default value `'none'` must be a member of the new `z.enum()` values.

**Existing test coverage** (3 tests):
- `schema.test.ts` > "defaults remittanceType to NONE" — verifies default applies
- `schema.test.ts` > "structured remittance validation" — 2 tests parsing `PaymentMessageTypeEnum.STRUCTURED` as input
- `schema.snapshot.test.ts` > "empty input error structure" — pins error code for missing/invalid remittanceType

**Verification**:
- [ ] All three `PaymentMessageTypeEnum` values (`NONE`, `STRUCTURED`, `OPEN`) parse successfully
- [ ] Default still applies when field is omitted
- [ ] Snapshot updated if error `code` changed (review diff, do not blindly accept)

### 1.2 `dueDate`: `required_error` to `error` + `.date()` message format

**Change**: `z.string({ required_error: '...' })` to `z.string({ error: '...' })` and `.date('...')` to `.date({ error: '...' })`

**What could break**:
- Zod v4 `error` param applies to ALL failures on the schema, not just "required" ones. Previously `required_error` only fired when the value was missing; now the same message fires for any string validation failure.
- The `.date()` refinement also gets an `error` param. When both the base string and the date format fail, the error message priority may change — the user could see a different validation message than before.
- `dueDate` is `.nullish()`, meaning `null` and `undefined` are both valid. Verify this still works after the `error` param change.

**Existing test coverage** (4 tests):
- `schema.test.ts` > "accepts dueDate as valid date string" (`'2024-02-15'`)
- `schema.test.ts` > "accepts dueDate as null"
- `schema.test.ts` > "accepts dueDate as undefined"
- `schema.test.ts` > "rejects invalid dueDate format" (`'not-a-date'`)

**Verification**:
- [ ] Valid date string still parses
- [ ] `null` and `undefined` still accepted
- [ ] Invalid date string still rejected
- [ ] Manual: submit form with empty dueDate when pay_now — verify correct error message appears in the UI

### 1.3 `senderId`: `message` to `error` in `.uuid()`

**Change**: `z.string().uuid({ message: '...' })` to `z.string().uuid({ error: '...' })`

**What could break**:
- Minimal risk — `message` is deprecated but still works in v4, and `error` is the direct replacement. Both produce the same runtime behavior.
- The error message string itself is unchanged.

**Existing test coverage** (1 test):
- `schema.test.ts` > "rejects invalid UUID for senderId"

**Verification**:
- [ ] Invalid UUID still rejected
- [ ] Error message string unchanged in parsed error output

---

## Tier 2 — Medium Risk

Unchanged syntax that could be affected by Zod v4 engine-level changes.

### 2.1 `.default()` behavior change

Zod v4 changed `.default()`: the default value must match the output type, not the input type. The schema has 5 `.default()` calls:

| Field | Default value | Type |
|-------|--------------|------|
| `selectionMode` | `'building'` | `z.enum(['building', 'units'])` |
| `paymentMethod` | `'pay_now'` | `z.enum(PAYMENT_METHODS)` |
| `remittanceType` | `PaymentMessageTypeEnum.NONE` | was `z.nativeEnum`, now `z.enum` |
| `isDirectDebit` | `false` | `z.boolean()` |
| `isUtility` | `false` | `z.boolean()` |

All default values are string/boolean literals that match both input and output types, so this change is safe. But verify explicitly.

**Existing test coverage** (5 tests):
- `schema.test.ts` > "default values" group (4 tests: paymentMethod, remittanceType, isDirectDebit, isUtility)
- `schema.test.ts` > "defaults selectionMode to building"

**Verification**:
- [ ] All 5 defaults still applied in parsed output
- [ ] `constants.test.ts` snapshot matches (covers full defaults shape)

### 2.2 `.superRefine()` / `ctx.addIssue()` error structure

The `superRefine` callbacks and `addIssue` calls are unchanged, but Zod v4 may produce different issue structures (e.g., merged issue types, different `code` values for built-in validators).

**Existing test coverage** (11 tests):
- `schema.test.ts` > "pay_now payment validation" (3 tests: missing paymentFrom, missing paymentTo, both provided)
- `schema.test.ts` > "already_paid payment validation" (3 tests: missing payments, empty payments, valid payments)
- `schema.test.ts` > "direct debit bypass" (2 tests)
- `schema.test.ts` > "structured remittance validation" (2 tests)
- `schema.test.ts` > "pay_later payment validation" (1 test)

**Verification**:
- [ ] All 11 payment validation tests pass
- [ ] Snapshot tests for error structure pass (or diff is reviewed and accepted)

### 2.3 `.transform()` type inference

Zod v4 changed transform type inference. The schema has 2 transforms:
- `file`: `.optional().transform((data) => data as unknown as FileV2 | undefined)`
- `peppolData`: `.any().transform((data) => data as unknown as PeppolInvoiceResponse | undefined | null)`

Both use explicit `as unknown as` casts, which bypass inference entirely. Safe.

**Existing test coverage** (1 test):
- `schema.test.ts` > "accepts file object with id"

**Verification**:
- [ ] `pnpm tsc --noEmit` passes — confirms `z.infer<typeof schema>` still produces correct `PurchaseInvoiceFormV2StewardData`

### 2.4 `.uuid()` strictness

Zod v4 validates RFC 9562/4122 variant bits. Could reject UUIDs that v3 accepted.

Test fixtures use `VALID_UUID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'` — this is RFC-compliant (variant bit `b` = `10xx`). Production UUIDs from PostgreSQL are v4 RFC-compliant.

**Verification**:
- [ ] All tests using `VALID_UUID` still pass
- [ ] No production data rejected (PostgreSQL UUIDs are RFC-compliant)

---

## Tier 3 — Low Risk

No-change areas. Sanity-check only.

- `z.enum()` for `selectionMode` and `paymentMethod` — unchanged syntax, v4-compatible
- `z.array()`, `z.record()`, `z.boolean()`, `z.number()` — no breaking changes for these patterns
- `z.string().min(n, message)` — `message` param is deprecated but still works; can optionally update to `error` in a follow-up but not required for this commit
- `amountWithDistributionSchemaSteward` inherits from syndic base schema — if the upstream syndic schema is already migrated, this is covered

**Verification**:
- [ ] `pnpm test purchase-invoice-v2-steward` — all 4 test files pass
- [ ] No unexpected warnings in test output

---

## Test Execution Order

Run in this sequence after applying the 4 syntax changes:

| Step | Command / Action | What it catches |
|------|-----------------|----------------|
| 1 | `pnpm test purchase-invoice-v2-steward` | Schema parse behavior, defaults, error structure |
| 2 | `pnpm tsc --noEmit` | Type inference, `z.infer` compatibility |
| 3 | `pnpm test purchase-invoice-v2/utils/transformExtractedDataToFormData` | AI extraction still compatible with schema |
| 4 | Manual: create steward invoice, fill all fields, submit | End-to-end form + API payload |
| 5 | Manual: edit existing steward invoice, verify data loads | Hydration from API response |
| 6 | Manual: trigger validation errors (empty required fields, invalid remittance, bad dueDate) | Error messages display correctly |

---

## Snapshot Update Policy

When snapshot tests fail after migration:

1. **Review the diff** — do not blindly run `pnpm test -- -u`
2. Expected changes: error `code` may change for `remittanceType` (from `invalid_enum_value` to Zod v4 equivalent)
3. Unexpected changes: if parsed output shape differs (field values, defaults), investigate before accepting
4. After review, update snapshots: `pnpm test purchase-invoice-v2-steward -- -u`
5. Commit updated `.snap` files with the migration commit
