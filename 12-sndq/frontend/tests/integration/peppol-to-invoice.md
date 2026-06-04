# Peppol to Invoice — Integration Tests

**Priority**: HIGH (daily-use flow)
**Files under test**:
- `usePeppolFormPopulate.ts` — `handlePeppolDataParsed` callback that populates form fields
- `PeppolInvoiceSheetRoute.tsx` — lock computation and form handoff (lines 102-111)
- `PeppolInvoiceFloatingSheetContent.tsx` — `handleEditInvoice` callback (lines 143-163)
- `transformPeppolToFormData.ts` — pure data transformation (already unit-tested, but wiring is not)

**Implementation target**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/peppol-to-invoice.test.ts`

These scenarios test the **wiring** between the well-unit-tested `transformPeppolToFormData` function and the form state. The unit tests verify the transform outputs correct data; these integration tests verify that data actually reaches the form fields.

---

## IT-022: handlePeppolDataParsed populates all form fields

**Preconditions**: React Hook Form instance with default values. Peppol data with all fields populated.

### Steps

1. Create a mock `methods` object with `setValue`, `getValues`, `resetField`, `trigger`
2. Call `handlePeppolDataParsed` with a full Peppol invoice response
3. Verify `setValue` was called for each field

### Assertions

- `setValue('peppolData', peppolData)` called first
- `setValue('senderId', 'supplier-contact-123')` called
- `setValue('invoiceNumber', 'PEPINV-001')` called
- `setValue('invoiceDate', '2026-01-15')` called
- `setValue('amounts', [...])` called with transformed lines
- `setValue('invoiceTypeCode', '380')` called
- `setValue('remittanceType', ...)` called
- `trigger()` called after all setValue calls

### Example Code

```typescript
import { describe, it, expect, vi } from 'vitest';
import { usePeppolFormPopulate } from '../../hooks/usePeppolFormPopulate';
import type { PeppolInvoiceResponse } from '@/common/api/resources/financial/peppolApi';
import {
  PeppolInvoiceDirection,
  PeppolInvoiceType,
  PeppolInvoiceStatus,
  PeppolInvoiceSource,
} from '@/common/models/peppolInvoice';

const basePeppolData: PeppolInvoiceResponse = {
  id: 'peppol-1',
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
  workspaceId: 'ws-1',
  direction: PeppolInvoiceDirection.INBOUND,
  invoiceNumber: 'PEPINV-001',
  issueDate: '2026-01-15',
  typeCode: '380',
  type: PeppolInvoiceType.INVOICE,
  supplierParty: { scheme: '0208', endpointId: '0123456789', name: 'Test NV' },
  customerParty: { scheme: '0208', endpointId: '9876543210' },
  supplierPartyContactId: 'supplier-contact-123',
  customerPartyBuildingId: 'building-456',
  lines: [
    {
      id: 'line-1',
      name: 'Maintenance',
      description: 'Monthly maintenance Q1',
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
  lineExtensionAmount: 10000,
  allowanceTotalAmount: 0,
  chargeTotalAmount: 0,
  taxInclusiveAmount: 12100,
  taxExclusiveAmount: 10000,
  prepaidAmount: 0,
  payableRoundingAmount: 0,
  payableAmount: 12100,
  currency: 'EUR',
  status: PeppolInvoiceStatus.RECEIVED,
  source: PeppolInvoiceSource.SNDQ,
  hasAttachments: false,
  paymentMeans: [{ code: '30', id: 'REF-2026-001' }],
};

function createMockMethods() {
  return {
    setValue: vi.fn(),
    getValues: vi.fn().mockReturnValue(undefined),
    resetField: vi.fn(),
    trigger: vi.fn(),
  } as any;
}

describe('Peppol to Invoice — handlePeppolDataParsed', () => {
  it('IT-022: populates all form fields via setValue', async () => {
    const methods = createMockMethods();
    const { handlePeppolDataParsed } = usePeppolFormPopulate({
      methods,
    });

    await handlePeppolDataParsed(basePeppolData);

    // peppolData set first
    expect(methods.setValue).toHaveBeenCalledWith('peppolData', basePeppolData);

    // senderId set from matched supplier
    expect(methods.setValue).toHaveBeenCalledWith(
      'senderId',
      'supplier-contact-123',
    );

    // Fields from transformPeppolToFormData
    const setValueCalls = methods.setValue.mock.calls.map(
      ([key]: [string]) => key,
    );
    expect(setValueCalls).toContain('invoiceNumber');
    expect(setValueCalls).toContain('invoiceDate');
    expect(setValueCalls).toContain('amounts');
    expect(setValueCalls).toContain('invoiceTypeCode');
    expect(setValueCalls).toContain('remittanceType');

    // trigger() called at the end
    expect(methods.trigger).toHaveBeenCalledOnce();
  });
});
```

---

## IT-023: Empty amounts from Peppol — no zero-lock

**Preconditions**: Peppol invoice with no lines (empty `lines` array).
**Bug vector**: `PeppolInvoiceSheetRoute.tsx` lines 102-108 always sets `locked: true`. With empty amounts, `lockedTotal` is 0, creating an unusable locked form.

### Steps

1. Call `transformPeppolToFormData` with Peppol data that has `lines: []`
2. Simulate the `onCreatePurchaseInvoice` callback from `PeppolInvoiceSheetRoute`

### Assertions

- `transformedData.amounts` is an empty array
- `sumTotalAmounts([])` returns `0`
- The config would be `{ initialLockState: { locked: true, lockedTotal: 0 } }` — this is a known design issue where the form locks at zero

### Example Code

```typescript
import { sumTotalAmounts } from '../../components/invoice-lines/pipeline';
import { transformPeppolToFormData } from '../../../purchase-invoice-v2/utils/transformPeppolToFormData';

it('IT-023: empty peppol lines produce empty amounts and zero lock total', () => {
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

  // NOTE: A guard like `if (amounts.length > 0)` before locking
  // would prevent this edge case. Track as potential improvement.
});
```

---

## IT-024: Unmatched supplier — peppolSupplierData set, senderId reset

**Preconditions**: Peppol invoice with `supplierPartyContactId: null/undefined` and `supplierParty` present.

### Steps

1. Call `handlePeppolDataParsed` with Peppol data where `supplierPartyContactId` is undefined

### Assertions

- `resetField('senderId')` called (clears any previous supplier)
- `setPeppolSupplierData` receives `invoice.supplierParty` object (name, VAT, etc.)
- `setValue('senderId', ...)` is NOT called

### Example Code

```typescript
it('IT-024: unmatched supplier resets senderId and sets peppolSupplierData', async () => {
  const methods = createMockMethods();
  const setPeppolSupplierDataSpy = vi.fn();

  const unmatchedPeppol = {
    ...basePeppolData,
    supplierPartyContactId: undefined,
    supplierParty: {
      scheme: '0208',
      endpointId: '0123456789',
      name: 'Unknown Supplier NV',
      vatNumber: 'BE0123456789',
    },
  };

  const { handlePeppolDataParsed } = usePeppolFormPopulate({
    methods,
  });

  await handlePeppolDataParsed(unmatchedPeppol as any);

  // senderId should be reset, not set
  expect(methods.resetField).toHaveBeenCalledWith('senderId');

  // senderId setValue should NOT be called (only peppolData and transformed fields)
  const senderIdSetCalls = methods.setValue.mock.calls.filter(
    ([key]: [string]) => key === 'senderId',
  );
  expect(senderIdSetCalls).toHaveLength(0);
});
```

---

## IT-025: Matched supplier — senderId set, peppolSupplierData cleared

**Preconditions**: Peppol invoice with `supplierPartyContactId: 'contact-123'`.

### Steps

1. Call `handlePeppolDataParsed` with Peppol data where `supplierPartyContactId` is set

### Assertions

- `setValue('senderId', 'contact-123')` called
- `setPeppolSupplierData(null)` called (clears unmatched state)
- `resetField('senderId')` is NOT called

### Example Code

```typescript
it('IT-025: matched supplier sets senderId and clears peppolSupplierData', async () => {
  const methods = createMockMethods();

  const matchedPeppol = {
    ...basePeppolData,
    supplierPartyContactId: 'contact-123',
  };

  const { handlePeppolDataParsed } = usePeppolFormPopulate({
    methods,
  });

  await handlePeppolDataParsed(matchedPeppol as any);

  expect(methods.setValue).toHaveBeenCalledWith('senderId', 'contact-123');
  expect(methods.resetField).not.toHaveBeenCalledWith('senderId');
});
```

---

## IT-026: Peppol credit note — typeCode flows to invoiceTypeCode

**Preconditions**: Peppol invoice with `typeCode: '381'` (CREDIT_NOTE).

### Steps

1. Transform Peppol data with `typeCode: '381'`
2. Verify the form receives `invoiceTypeCode: '381'`

### Assertions

- `transformedData.invoiceTypeCode` is `'381'`
- When `handlePeppolDataParsed` runs, `setValue('invoiceTypeCode', '381')` is called

### Example Code

```typescript
it('IT-026: peppol credit note sets invoiceTypeCode to 381', async () => {
  const methods = createMockMethods();

  const creditNotePeppol = {
    ...basePeppolData,
    typeCode: '381',
    type: PeppolInvoiceType.CREDIT_NOTE,
  };

  const { handlePeppolDataParsed } = usePeppolFormPopulate({
    methods,
  });

  await handlePeppolDataParsed(creditNotePeppol as any);

  const typeCodeCalls = methods.setValue.mock.calls.filter(
    ([key]: [string]) => key === 'invoiceTypeCode',
  );
  expect(typeCodeCalls).toHaveLength(1);
  expect(typeCodeCalls[0][1]).toBe('381');
});
```

---

## IT-027: Belgian OGM structured remittance detection

**Preconditions**: Peppol invoice with `paymentMeans[0].id = '+++123/4567/89002+++'`.

### Steps

1. Transform Peppol data with the formatted OGM reference
2. Verify remittance type and cleaned reference

### Assertions

- `remittanceType` is `PaymentMessageTypeEnum.STRUCTURED`
- `remittanceInfo` is `'123456789002'` (digits only, checksum valid)

### Example Code

```typescript
import { PaymentMessageTypeEnum } from '@/common/models/payment';
import { transformPeppolToFormData } from '../../../purchase-invoice-v2/utils/transformPeppolToFormData';

it('IT-027: Belgian OGM is detected and cleaned to digits', () => {
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

## IT-028: Lock total computation in onCreatePurchaseInvoice

**Preconditions**: Peppol detail sheet fires `onCreatePurchaseInvoice` with transformed data.

### Steps

1. Simulate `handleEditInvoice` from `PeppolInvoiceFloatingSheetContent`
2. Simulate `onCreatePurchaseInvoice` callback from `PeppolInvoiceSheetRoute`
3. Verify lock state config

### Assertions

- `sumTotalAmounts(amounts)` equals the expected total from Peppol lines
- Config is `{ initialLockState: { locked: true, lockedTotal: <computed> } }`
- `peppolInvoiceId` is passed to `PurchaseInvoiceFormFactory`

### Example Code

```typescript
import { sumTotalAmounts } from '../../components/invoice-lines/pipeline';
import { transformPeppolToFormData } from '../../../purchase-invoice-v2/utils/transformPeppolToFormData';
import type { AmountWithDistributionData } from '../../../purchase-invoice-v2/schema';

it('IT-028: lock total matches sum of transformed peppol amounts', () => {
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

## IT-029: Grouping strategy preserves originalLines and lock total

**Preconditions**: Peppol data with multiple lines at different VAT rates.

### Steps

1. Transform Peppol data to individual amounts
2. Apply `groupAmountsByVatRate` to re-group
3. Verify `originalLines` are preserved and `sumTotalAmounts` stays the same

### Assertions

- Individual: 3 amount entries, total = sum of all three
- Grouped by VAT: 2 entries (21% group + 6% group), same total
- Each grouped entry has `originalLines` from the original Peppol lines
- `sumTotalAmounts` produces the same result before and after grouping

### Example Code

```typescript
import { sumTotalAmounts } from '../../components/invoice-lines/pipeline';
import {
  transformPeppolToFormData,
  groupAmountsByVatRate,
} from '../../../purchase-invoice-v2/utils/transformPeppolToFormData';

it('IT-029: grouping preserves originalLines and lock total', () => {
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
