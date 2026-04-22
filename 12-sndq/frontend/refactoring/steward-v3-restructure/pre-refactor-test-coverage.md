# Pre-Refactor Test Coverage Report

Test suite added before restructuring the steward purchase invoice form to V3 architecture. Total: **148 tests** across 4 test files, all passing.

## What Is Covered

### 1. Schema Validation — `__tests__/schema.test.ts` (48 tests)

**`amountWithDistributionSchemaSteward`** (6 tests):
- Steward-specific: rejects missing `costCategoryId`, passes when provided
- Inherited base validations: VAT rate bounds, custom price rules, date range ordering, distribution total consistency

**`purchaseInvoiceFormV2StewardSchema`** (42 tests):
- Required fields: `propertyIds` (min 1 UUID), `invoiceName`, `invoiceDate`, `invoiceNumber`, `senderId` (UUID), `amounts` (min 1)
- Steward-specific fields: `selectionMode` defaults, `buildingId` UUID validation
- Default values: `paymentMethod`, `remittanceType`, `isDirectDebit`, `isUtility`
- Payment method validation branches: `pay_later`, `pay_now` (paymentFrom/paymentTo), `already_paid` (payments array)
- Direct debit bypass: skips payment validation when `isDirectDebit: true`
- Structured remittance: Belgian format validation (`123456789002`)
- Optional fields: `dueDate` (date/null/undefined), `approverId`, `descriptionTranslations`, `file`, `approvalNote`
- Multiple amounts with mixed `costCategoryId` presence

### 2. Schema Snapshots — `__tests__/schema.snapshot.test.ts` (4 tests)

Pins the exact parsed output of the schema using the `describeSchema` factory:
- Valid input (all fields) parse result snapshot
- Minimal input (required only) parse result with defaults snapshot
- Empty input error structure snapshot
- Invalid types error structure snapshot

These snapshots catch any accidental changes to transforms, defaults, or error messages during refactoring.

### 3. API Data Converter — `utils.test.ts` (67 tests)

**`convertFormDataV2StewardToApiData`** tests cover:

| Area | Tests | Key behaviors |
|---|---|---|
| Draft mode | 8 | Empty allocationCosts, raw form data in draft field, forced UNSTRUCTURED remittance, undefined paymentMethodId, total/subtotal calculation |
| Basic mapping | 7 | `invoiceName` → `name`, `senderId` → `supplierId`, `dueDate` → `dateDue`, `file.id` → `fileId`, draft=null, currency=EUR |
| Building ID | 2 | Returns `buildingId` for mode=building, undefined for mode=units |
| Payment mapping | 5 | `paymentFrom` → `paymentMethodId`, `paymentTo` → `contactIbanId`, paymentStatus based on method |
| Remittance mapping | 3 | STRUCTURED passthrough, non-STRUCTURED → UNSTRUCTURED, empty string fallback |
| Allocation costs | 10 | motherId=undefined, costCategoryId mapping, VAT rate via percentageToRate, customCalculation toggle, distributionKeyId gating |
| Distribution types | 6 | baseValue: 10000 (percentage), totalAmount (free), totalShare (share); baseCalculation enum mapping |
| Unit allocation | 5 | Only selected units, share mapping per distribution type (Math.round*100 for %, amount for free, share for share) |
| Owner split | 4 | ownerSplit/100 conversion, edge cases (0, 100, undefined → 0.5) |
| Split clearing | 2 | Passthrough when defined, SETTLEMENT fallback when undefined |
| Credit note | 2 | Forces isDirectDebit=false for credit notes, preserves for normal invoices |
| Period dates | 2 | Form-level dates take precedence, derived from amounts when empty |
| Totals | 2 | Subtotal and total as sums of allocation costs |
| Passthrough fields | 3 | approverId, approvalNote, isUtility |

### 4. Settlement Utils — `utils.test.ts` (pre-existing, 22 tests)

Pre-existing tests covering:
- `DEFAULT_SETTLEMENT` constants
- `createDefaultUnitData` factory
- `normalizeUnitSettlement` normalization and immutability
- `detectUniformSettlement` uniform/non-uniform detection with normalization

### 5. Default Values — `__tests__/constants.test.ts` (18 tests)

Verifies the expected shape of `defaultInvoiceFormV2StewardValues`:
- Selection mode, property IDs, amounts, invoice fields
- Payment defaults, boolean flags, optional fields
- Full shape snapshot

## What Is NOT Covered

### Component rendering and React hooks

The 630-LOC `PurchaseInvoiceFormV2Steward.tsx` component contains significant logic in:
- `useEffect` chains that react to property/building changes
- `handlePeppolDataParsed` callback that prefills form fields from Peppol data
- `onSubmit`, `onError`, `onDraft` handlers that orchestrate mutations and toasts
- `useForm` integration with `zodResolver`

**Why not covered**: These are tightly coupled to React rendering and the `react-hook-form` lifecycle. Testing them would require component rendering tests (RTL) which are expensive to write and maintain, and would need to be rewritten anyway during the restructure. The schema + converter tests catch the data transformation logic, which is the critical behavioral contract.

### Peppol prefill side-effects

The `handlePeppolDataParsed` callback applies Peppol-extracted data to the form. This involves `setValue` calls on multiple fields with conditional logic.

**Why not covered**: This is UI-layer logic that depends on `react-hook-form`'s `setValue` API. It will be extracted into the `usePurchaseInvoiceForm` hook during Phase 2, and can be unit-tested at that point with a mocked form instance.

### AmountsSection state management

The `AmountsSection` component manages its own state for adding/removing/editing amount rows. The interaction between unit selection, distribution type changes, and amount recalculation is complex.

**Why not covered**: This component has its own internal state that would require component-level tests. The schema tests validate the _output_ shape and the converter tests validate the _transformation_, which together catch regressions in the data contract.

### UnitsSection UI logic

Per-unit selection, share editing, settlement popover interactions.

**Why not covered**: Same reasoning as AmountsSection — UI interaction logic that is better covered by E2E tests or component tests post-restructure.

### Edit form initial data loading

`PurchaseInvoiceEditFormV2Steward.tsx` fetches and transforms API data into form defaults.

**Why not covered**: This involves API mocking and data mapping that flows _into_ the form. The current tests cover the _outgoing_ transformation (form → API). Adding incoming transformation tests is a good follow-up but lower priority since the edit form component will be preserved largely as-is.

## Benefits for Refactoring Safety

1. **Schema contract is pinned**: Any change to validation rules, defaults, or transforms will break snapshot tests immediately
2. **API payload is verified**: The converter tests guarantee that the same form data produces the same API payload before and after restructuring
3. **Distribution logic is captured**: The complex share/percentage/free mapping and owner split conversion are tested at every edge
4. **Credit note behavior is documented**: The forced `isDirectDebit: false` for credit notes is tested explicitly
5. **Draft vs non-draft divergence is clear**: Tests document the different behavior paths and their expected outputs

## Known Tradeoffs

- **No coverage of `useEffect` chains**: The component's reactive logic (property change → unit refetch → settlement normalization) is not tested. This is the highest-risk area during restructuring.
- **No negative converter tests**: The converter assumes valid parsed data (post-schema-validation). There are no tests for malformed input to the converter, which is acceptable since the schema enforces validity.
