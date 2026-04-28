# Zod v4 Migration — Manual Test Scripts

Post-migration manual verification for Commit 4C. Run these after all automated tests pass. Priority ordered by risk.

Companion: [feature-sync-commits.md](./feature-sync-commits.md) (Commit 4C)

---

## Prerequisites

Before running manual tests, confirm automated tests pass:

```bash
pnpm test purchase-invoice-v2-steward          # 1278 tests
pnpm test purchase-invoice-v2/__tests__/schema  # syndic snapshots
pnpm test purchase-invoice-v3/__tests__/schema  # v3 snapshots
pnpm test transformExtractedDataToFormData      # AI extraction
pnpm run type-check                             # zero new errors
```

---

## 1. Steward Form — Create Flow (High Priority)

Tests the full steward schema in production context. Catches runtime issues that unit tests miss (e.g., resolver integration, form state management).

### 1.1 Basic submission

1. Open steward create invoice form
2. Select at least one property in the property selector
3. Fill invoice name, date, and number
4. Select a supplier (senderId)
5. Add one amount line with a cost category
6. Set payment method to **Pay Later**
7. Submit the form

**Verify**:
- [ ] Form submits without errors
- [ ] API payload has correct field types (check Network tab)
- [ ] `remittanceType` defaults to `"none"` in payload
- [ ] `isDirectDebit` defaults to `false`
- [ ] `isUtility` defaults to `false`
- [ ] `selectionMode` defaults to `"building"`
- [ ] `paymentMethod` is `"pay_later"`

### 1.2 Full field coverage

1. Open steward create form
2. Fill all fields:
   - File attachment (upload a PDF)
   - Multiple properties
   - Invoice name, date, number
   - Supplier
   - Multiple amount lines with cost categories and distribution
   - Description translations (if available)
   - Due date: pick a valid date
   - Payment method: **Pay Now** with IBAN fields
   - Remittance type: **Structured** with a valid structured message
   - Approval: select an approver, add note
3. Submit

**Verify**:
- [ ] All fields present in API payload
- [ ] `dueDate` is ISO date string format (`YYYY-MM-DD`)
- [ ] `senderId` is a valid UUID
- [ ] `amounts` array has correct structure with `costCategoryId`
- [ ] `remittanceType` is `"structured"`
- [ ] `remittanceInfo` contains the structured message

---

## 2. Steward Form — Validation Errors (High Priority)

Tests error message display after `message`/`required_error` → `error` migration and `.date(string)` → `.date({ error })` change.

### 2.1 Required field errors

1. Open steward create form
2. Do NOT fill any fields
3. Attempt to submit (or trigger validation)

**Verify**:
- [ ] `propertyIds` shows "valuemissing" error
- [ ] `invoiceDate` shows error
- [ ] `invoiceNumber` shows error
- [ ] `senderId` shows error (the `error` param on `.uuid()`)
- [ ] `amounts` shows "valuemissing" error (empty array)
- [ ] Error messages display correctly in the UI (not raw error codes)

### 2.2 dueDate validation

1. Set payment method to **Pay Now**
2. Leave dueDate empty — verify error appears
3. Type an invalid date (e.g., "abc" or "2024-13-45") — verify "badinput" error
4. Enter a valid date (`2024-06-15`) — verify error clears
5. Set dueDate to `null` (clear the field) — verify no error (`.nullish()` allows it)

**Verify**:
- [ ] Empty dueDate when required shows "valuemissing" message
- [ ] Invalid format shows "badinput" message
- [ ] Valid date passes
- [ ] Cleared/null dueDate passes (nullish)

### 2.3 senderId validation

1. Clear the supplier field — verify UUID error appears
2. Select a valid supplier — verify error clears

**Verify**:
- [ ] Missing senderId shows "valuemissing" message (from `error` param)
- [ ] Valid supplier UUID passes

### 2.4 Payment method validation

1. Select **Pay Now**:
   - Leave paymentFrom empty — verify error
   - Leave paymentTo empty — verify error
   - Fill both — errors clear
2. Select **Already Paid**:
   - Leave payments empty — verify error
   - Add a payment entry — error clears
3. Select **Pay Later**:
   - No payment fields required — verify no errors

**Verify**:
- [ ] Pay Now requires paymentFrom and paymentTo
- [ ] Already Paid requires at least one payment
- [ ] Pay Later has no payment requirements

### 2.5 Structured remittance validation

1. Set payment method to **Pay Now**
2. Set remittance type to **Structured**
3. Enter an invalid structured message — verify error
4. Enter a valid structured message (e.g., `+++090/9337/55493+++`) — verify error clears
5. Switch to **Open** — verify structured validation no longer applies

**Verify**:
- [ ] Invalid structured message shows "invalid_structured_message" error
- [ ] Valid structured message passes
- [ ] Switching away from Structured clears the validation

---

## 3. Steward Form — Edit Flow (Medium Priority)

Tests data hydration from API response into the v4 schema.

### 3.1 Edit existing invoice

1. Open an existing steward invoice in edit mode
2. Verify all fields are pre-populated correctly

**Verify**:
- [ ] Invoice name, date, number loaded
- [ ] Supplier loaded (senderId)
- [ ] Amount lines loaded with cost categories
- [ ] Payment method loaded
- [ ] Due date loaded (if set)
- [ ] Remittance type and info loaded
- [ ] Direct debit and utility flags loaded
- [ ] Approver loaded (if set)

### 3.2 Edit and save

1. Modify a field (e.g., change invoice number)
2. Submit

**Verify**:
- [ ] Form saves without errors
- [ ] Modified field reflected in API payload
- [ ] Unmodified fields unchanged

### 3.3 Edit with "Already Paid" payment

1. Open an invoice that has `paymentMethod: 'already_paid'`
2. Verify payment entries are displayed
3. Modify a payment entry
4. Save

**Verify**:
- [ ] Payment entries loaded and displayed
- [ ] Modifications saved correctly

---

## 4. Syndic Form — Regression (Medium Priority)

The syndic schema was also migrated to v4. Verify no regression.

### 4.1 Syndic create flow

1. Open syndic create invoice form
2. Select a building
3. Fill basic fields (name, date, number, supplier)
4. Add an amount line with a mother account (motherId)
5. Set payment method to **Pay Now** with IBAN fields
6. Submit

**Verify**:
- [ ] Form submits without errors
- [ ] API payload structure matches pre-migration
- [ ] `remittanceType` defaults correctly (now uses `z.enum(PaymentMessageTypeEnum)` instead of `z.nativeEnum`)
- [ ] Mother account validation still works (`motherId` required in syndic)

### 4.2 Syndic validation errors

1. Submit empty syndic form
2. Verify error messages display correctly

**Verify**:
- [ ] `buildingId` error appears
- [ ] `senderId` error appears (uses `error` param now instead of `message`)
- [ ] `amounts` error appears
- [ ] Error messages are user-friendly (not raw codes)

### 4.3 Syndic edit flow

1. Open existing syndic invoice in edit mode
2. Verify data loads correctly
3. Save without changes

**Verify**:
- [ ] All fields hydrated correctly
- [ ] No-op save works (no validation errors for existing valid data)

---

## 5. Cross-Schema Composition (Medium Priority)

Tests the `amountWithDistributionSchemaSteward` which extends the syndic `amountWithDistributionSchema`.

### 5.1 Amount distribution sheet

1. Open steward create form
2. Click "Add amount line" or open the amount distribution sheet
3. Fill amount, total, distribution key
4. Leave cost category empty — verify validation error from steward superRefine
5. Fill cost category — verify error clears
6. Save the amount line

**Verify**:
- [ ] Distribution sheet opens without runtime errors
- [ ] Base schema validation works (amount, totalAmount, distributionType required)
- [ ] Steward-specific validation works (costCategoryId required)
- [ ] Custom price validation works (if `hasCustomPrice` is true)
- [ ] Date range validation works (fromDate/toDate consistency)

---

## 6. AI Data Extraction (Low Priority)

Tests that AI extraction still works with v4 schemas (already covered by 16 automated tests).

### 6.1 Peppol data extraction

1. Upload a Peppol XML invoice to steward form
2. Verify extracted data fills form fields

**Verify**:
- [ ] Supplier auto-selected
- [ ] Invoice number populated
- [ ] Amount lines created from Peppol data
- [ ] Date fields populated

### 6.2 AI OCR extraction (if available)

1. Upload an invoice PDF to steward form
2. Trigger AI extraction
3. Verify extracted fields populate form

**Verify**:
- [ ] Extracted data fills relevant fields
- [ ] No type errors in console

---

## 7. Direct Debit Bypass (Low Priority)

### 7.1 Direct debit toggle

1. Open steward create form
2. Toggle `isDirectDebit` on
3. Set payment method to **Pay Now**
4. Leave paymentFrom and paymentTo empty
5. Submit

**Verify**:
- [ ] No paymentFrom/paymentTo validation errors (direct debit bypasses)
- [ ] Form submits successfully
- [ ] `isDirectDebit: true` in API payload

---

## Expected Behavioral Differences from v4

These are **expected** changes. Do not treat them as bugs:

| Behavior | v3 | v4 | Impact |
|----------|----|----|--------|
| Error code for invalid enum | `invalid_type` | `invalid_value` | Snapshot tests updated |
| Error code for invalid UUID | `invalid_string` | `invalid_format` | Snapshot tests updated |
| `z.any()` field optionality | Optional in `z.input` | Required in `z.input` | Fixture updated, no UI impact |
| `.optional().transform()` output | Omitted when undefined | Present as `undefined` | Snapshot updated, no UI impact |
| `.uuid()` strictness | Lenient | RFC 9562 variant bits | All UUIDs are PostgreSQL-generated (compliant) |

---

## Troubleshooting

### "Cannot read properties of undefined (reading 'run')"

This error means a v3 schema object is being parsed by the v4 runtime. Check that ALL schema files in the import chain use `import { z } from 'zod/v4'`. The most likely cause is a schema file that still imports from `'zod'` (v3).

### Type error: `_output` does not satisfy `FieldValues`

The `zodResolver` wrapper uses a structural `ZodLike` interface. If you see this error, the schema's output type doesn't extend `Record<string, any>`. This typically means you're passing a non-object schema (like `z.string()`) to `zodResolver`, which is incorrect — forms always need object schemas.

### Snapshot mismatches after clean checkout

Snapshots were regenerated with v4 error codes. If a snapshot test fails after a clean checkout, run `pnpm test -- --update <test-file>` and review the diff. Expected changes are listed in the table above.
