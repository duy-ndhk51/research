# Transform Peppol to Form Data

**Status**: Not started
**Priority**: HIGH (incorrect transform breaks lock total, OGM parsing, and grouping)
**Test tier**: Unit
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/unit/transformPeppolToFormData.test.ts`
**Function(s) under test**: `transformPeppolToFormData`, `groupAmountsByVatRate` from `purchase-invoice-v2/utils/transformPeppolToFormData.ts`, `sumTotalAmounts` from `components/invoice-lines/pipeline/sumTotalAmounts.ts`

## Purpose

Guard the pure transformation logic that converts Peppol invoice data to form-compatible structures. Covers empty-input edge cases, Belgian OGM structured remittance detection, lock total computation via `sumTotalAmounts`, and VAT-rate grouping with `originalLines` preservation.

## Origin

These tests were extracted from `integration/peppol-to-invoice.md` where they tested the transform/calculation functions directly (pure-logic, no hook rendering). Since `transformPeppolToFormData`, `groupAmountsByVatRate`, and `sumTotalAmounts` are exported standalone utilities, unit tests are the correct tier.

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Empty amounts from Peppol — no zero-lock | `lockedTotal: 0` (known UX edge case on inbox path) |
| Belgian OGM structured remittance detection | Parsed to digits, typed STRUCTURED |
| Lock total matches Peppol amounts sum | `sumTotalAmounts` matches multi-line total |
| Grouping preserves originalLines and total | Same total after grouping, `originalLines` preserved |

## Shared Setup

```typescript
import { describe, it, expect } from 'vitest';
import { sumTotalAmounts } from '../../components/invoice-lines/pipeline';
import {
  transformPeppolToFormData,
  groupAmountsByVatRate,
} from '../../../purchase-invoice-v2/utils/transformPeppolToFormData';
import { PaymentMessageTypeEnum } from '@/common/models/payment';
import type { PeppolInvoiceResponse } from '@/common/api/resources/financial/peppolApi';
import type { AmountWithDistributionData } from '../../../purchase-invoice-v2/schema';

const basePeppolData: Partial<PeppolInvoiceResponse> = {
  invoiceNumber: 'PEPINV-001',
  supplierParty: { name: 'Test Supplier' },
  lines: [
    {
      id: 'l1',
      name: 'Service A',
      baseQuantity: 1,
      basePrice: 10000,
      quantity: 1,
      vatIncluded: true,
      vatRate: 0.21,
      subtotal: 10000,
      total: 12100,
      currency: 'EUR',
    },
  ],
};
```

---

## Empty amounts from Peppol — no zero-lock

> **Path clarification:** This scenario tests the **inbox path** (`PeppolInvoiceSheetRoute.onCreatePurchaseInvoice`), which always sets `locked: true` regardless of amounts — resulting in `lockedTotal: 0` for empty invoices. The **uploader tab path** (`safePeppolDataParsed` in `PurchaseInvoiceFormV3`) behaves differently: it has a `parsedAmounts.length > 0` guard and skips lock entirely when amounts are empty. The uploader path is tested in [integration/right-panel-tabs.md](../integration/right-panel-tabs.md).

**Preconditions**: Peppol invoice with no lines (empty `lines` array).
**Bug vector**: `PeppolInvoiceSheetRoute.tsx` lines 102-108 always sets `locked: true`. With empty amounts, `lockedTotal` is 0, creating an unusable locked form.

### Steps

1. Call `transformPeppolToFormData` with Peppol data that has `lines: []`
2. Compute `sumTotalAmounts` on the result

### Expected Outcome

- `transformedData.amounts` is an empty array
- `sumTotalAmounts([])` returns `0`
- The config would be `{ initialLockState: { locked: true, lockedTotal: 0 } }` — this is a known design issue where the form locks at zero

### Example Code

```typescript
it('empty peppol lines produce empty amounts and zero lock total', () => {
  const emptyLinesPeppol = { ...basePeppolData, lines: [] };
  const transformed = transformPeppolToFormData(emptyLinesPeppol);

  expect(transformed.amounts).toEqual([]);

  const amounts = transformed.amounts ?? [];
  const lockedTotal = sumTotalAmounts(amounts);

  expect(lockedTotal).toBe(0);

  // Current behavior: locks at zero (potential UX issue)
  // The PeppolInvoiceSheetRoute always sets locked: true
  const config = { initialLockState: { locked: true, lockedTotal } };
  expect(config.initialLockState.locked).toBe(true);
  expect(config.initialLockState.lockedTotal).toBe(0);
});
```

---

## Belgian OGM structured remittance detection

**Preconditions**: Peppol invoice with `paymentMeans[0].id = '+++123/4567/89002+++'`.

### Steps

1. Transform Peppol data with the formatted OGM reference
2. Verify remittance type and cleaned reference

### Expected Outcome

- `remittanceType` is `PaymentMessageTypeEnum.STRUCTURED`
- `remittanceInfo` is `'123456789002'` (digits only, checksum valid)

### Example Code

```typescript
it('Belgian OGM is detected and cleaned to digits', () => {
  const ogmPeppol = {
    ...basePeppolData,
    paymentMeans: [{ code: '30', id: '+++123/4567/89002+++' }],
  };

  const result = transformPeppolToFormData(ogmPeppol);

  expect(result.remittanceType).toBe(PaymentMessageTypeEnum.STRUCTURED);
  expect(result.remittanceInfo).toBe('123456789002');
});
```

---

## Lock total computation in onCreatePurchaseInvoice

**Preconditions**: Peppol data with multiple lines at different VAT rates.

### Steps

1. Transform Peppol data to amounts via `transformPeppolToFormData`
2. Compute `sumTotalAmounts` on the result
3. Verify the lock config

### Expected Outcome

- `sumTotalAmounts(amounts)` equals the expected total from Peppol lines
- Config is `{ initialLockState: { locked: true, lockedTotal: <computed> } }`

### Example Code

```typescript
it('lock total matches sum of transformed peppol amounts', () => {
  const multiLinePeppol = {
    ...basePeppolData,
    lines: [
      {
        id: 'l1', name: 'Service A',
        baseQuantity: 1, basePrice: 10000, quantity: 1,
        vatIncluded: true, vatRate: 0.21,
        subtotal: 10000, total: 12100, currency: 'EUR',
      },
      {
        id: 'l2', name: 'Service B',
        baseQuantity: 1, basePrice: 5000, quantity: 1,
        vatIncluded: false, vatRate: 0,
        subtotal: 5000, total: 5000, currency: 'EUR',
      },
    ],
  };

  const transformed = transformPeppolToFormData(multiLinePeppol);
  const amounts = (transformed.amounts ?? []) as AmountWithDistributionData[];
  const lockedTotal = sumTotalAmounts(amounts);

  // 12100 + 5000 = 17100
  expect(lockedTotal).toBe(17100);

  // Simulates PeppolInvoiceSheetRoute.onCreatePurchaseInvoice
  const config = { initialLockState: { locked: true, lockedTotal } };
  expect(config.initialLockState).toEqual({ locked: true, lockedTotal: 17100 });
});
```

---

## Grouping strategy preserves originalLines and lock total

**Preconditions**: Peppol data with multiple lines at different VAT rates.

### Steps

1. Transform Peppol data to individual amounts
2. Apply `groupAmountsByVatRate` to re-group
3. Verify `originalLines` are preserved and `sumTotalAmounts` stays the same

### Expected Outcome

- Individual: 3 amount entries, total = sum of all three
- Grouped by VAT: 2 entries (21% group + 6% group), same total
- Each grouped entry has `originalLines` from the original Peppol lines
- `sumTotalAmounts` produces the same result before and after grouping

### Example Code

```typescript
it('grouping preserves originalLines and lock total', () => {
  const multiVatPeppol = {
    ...basePeppolData,
    lines: [
      {
        id: 'l1', name: 'Item A',
        baseQuantity: 1, basePrice: 10000, quantity: 1,
        vatIncluded: true, vatRate: 0.21,
        subtotal: 10000, total: 12100, currency: 'EUR',
      },
      {
        id: 'l2', name: 'Item B',
        baseQuantity: 1, basePrice: 5000, quantity: 1,
        vatIncluded: true, vatRate: 0.21,
        subtotal: 5000, total: 6050, currency: 'EUR',
      },
      {
        id: 'l3', name: 'Item C',
        baseQuantity: 1, basePrice: 3000, quantity: 1,
        vatIncluded: true, vatRate: 0.06,
        subtotal: 3000, total: 3180, currency: 'EUR',
      },
    ],
  };

  const transformed = transformPeppolToFormData(multiVatPeppol);
  const individual = transformed.amounts!;
  const grouped = groupAmountsByVatRate(individual);

  // Individual: 3 entries
  expect(individual).toHaveLength(3);

  // Grouped: 2 entries (21% + 6%)
  expect(grouped).toHaveLength(2);

  // Total is preserved
  const individualTotal = sumTotalAmounts(individual);
  const groupedTotal = sumTotalAmounts(grouped);
  expect(individualTotal).toBe(groupedTotal);
  expect(groupedTotal).toBe(12100 + 6050 + 3180); // 21330

  // originalLines preserved in each group
  const vat21Group = grouped.find((g) => g.vatRate === 21)!;
  expect(vat21Group.originalLines).toHaveLength(2);
  expect(vat21Group.originalLines![0].name).toBe('Item A');
  expect(vat21Group.originalLines![1].name).toBe('Item B');

  const vat6Group = grouped.find((g) => g.vatRate === 6)!;
  expect(vat6Group.originalLines).toHaveLength(1);
  expect(vat6Group.originalLines![0].name).toBe('Item C');
});
```
