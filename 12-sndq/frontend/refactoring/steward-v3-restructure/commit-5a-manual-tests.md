# Commit 5A — Manual Verification Scripts

Commit 5A is a **data-layer-only** change (no UI components). Verification focuses on automated tests, type safety, and import correctness. No browser testing is needed yet — the UI wiring happens in Commit 5B/5C.

---

## 1. Automated Test Verification

### Run the new steward invoice-lines tests

```bash
pnpm vitest run src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/__tests__/
```

**Expected**: 23 tests pass (12 amountDefaults + 11 reducer), 0 failures.

### Run existing tests to check for regressions

```bash
# Syndic invoice-lines tests (must not be affected)
pnpm vitest run src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/amountDefaults.test.ts

# Schema snapshot tests
pnpm vitest run src/modules/financial/forms/purchase-invoice-v2-steward/__tests__/
pnpm vitest run src/modules/financial/forms/purchase-invoice-v2/__tests__/
pnpm vitest run src/modules/financial/forms/purchase-invoice-v3/__tests__/

# Full test suite (optional, takes longer)
pnpm vitest run
```

**Expected**: All existing tests pass with zero changes.

---

## 2. Type-Check Verification

```bash
pnpm run type-check
```

**Expected**: No new type errors. Only pre-existing `.next/types/` errors (unrelated).

### Verify no type errors in new files specifically

```bash
pnpm tsc --noEmit 2>&1 | grep "purchase-invoice-v3-steward/components/invoice-lines"
```

**Expected**: No output (no errors in our new files).

---

## 3. Import Verification

Verify the import chain works correctly:

### Steward types import from syndic

Open `purchase-invoice-v3-steward/components/invoice-lines/types.ts` and verify:
- `InvoiceLineUiAction` and `InvoiceLineUiState` re-exported from syndic types
- `StewardAmountsFieldArray` uses `PurchaseInvoiceFormV2StewardData` (not syndic `PurchaseInvoiceFormV2Data`)

### Steward defaults use steward unit factory

Open `purchase-invoice-v3-steward/components/invoice-lines/amountDefaults.ts` and verify:
- Imports `createDefaultUnitData` from `purchase-invoice-v2-steward/utils`
- Does NOT import `createDefaultAmount` from syndic amountDefaults

### Steward reducer delegates to shared reducer

Open `purchase-invoice-v3-steward/components/invoice-lines/reducer.ts` and verify:
- Imports `applyInvoiceLineAction` from syndic reducer
- `SET_COST_CATEGORY` is handled locally before delegation
- Cast to `InvoiceLineAction` (shared type) for delegation

---

## 4. Behavioral Spot-Checks

### Default amount includes settlement fields

In a Node REPL or test:

```typescript
import { createDefaultStewardAmount } from './amountDefaults';

const result = createDefaultStewardAmount([
  { id: 'p1', name: 'Unit 1' },
  { id: 'p2', name: 'Unit 2' },
]);

// Verify:
// - result.costCategoryId === undefined
// - result.motherId === undefined (field not set)
// - result.units[0].splitClearing === 'settlement'
// - result.units[0].ownerSplit === 50
// - result.units[0].tenantSplit === 50
```

### SET_COST_CATEGORY preserves distribution

```typescript
import { applyStewardInvoiceLineAction } from './reducer';

const state = {
  /* ... state with distribution already applied ... */
  useDistributionKey: true,
  distributionKeyId: 'dk-1',
};

const result = applyStewardInvoiceLineAction(
  state,
  { type: 'SET_COST_CATEGORY', payload: { id: 'cat-1', name: 'Repairs' } },
  { distributionKeys: [], properties: [] },
);

// Verify: result.costCategoryId === 'cat-1'
// Verify: result.distributionKeyId === 'dk-1' (preserved)
// Verify: result.useDistributionKey === true (preserved)
```

---

## 5. File Structure Check

Verify the new directory was created with the correct structure:

```bash
find src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines -type f | sort
```

**Expected output**:
```
src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/__tests__/amountDefaults.test.ts
src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/__tests__/reducer.test.ts
src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/amountDefaults.ts
src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/index.ts
src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/reducer.ts
src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/types.ts
```

---

## 6. Regression Matrix

| Area | What to check | Expected |
|------|---------------|----------|
| Syndic V3 invoice lines | Existing amountDefaults tests | All pass, unchanged |
| Syndic V3 reducer | Existing reducer behavior | Unmodified, tests pass |
| Steward schema | Snapshot tests | Unchanged from Commit 4C |
| Syndic schema | Snapshot tests | Unchanged from Commit 4C |
| Type safety | `pnpm run type-check` | No new errors |
| Barrel exports | Import from `invoice-lines/` | All symbols exported |

---

## Summary Checklist

- [x] 23 new tests pass (amountDefaults: 12, reducer: 11)
- [x] Existing syndic invoice-lines tests pass (no regressions)
- [x] Schema snapshot tests pass (no changes)
- [x] Type-check passes (no new errors)
- [x] File structure matches expected layout
- [x] No syndic files were modified
