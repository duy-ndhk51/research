# Supplier Defaults

**Status**: Not started
**Priority**: HIGH (incorrect backfill silently corrupts invoice amounts)
**Test tier**: Hook
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/supplier-defaults.test.ts`
**Component(s) under test**: `useInitialLineDefaults` from `hooks/useInitialLineDefaults.ts`, `useAutoSaveBuildingSupplierDefaults` from `hooks/useAutoSaveBuildingSupplierDefaults.ts`

## Purpose

Guard the supplier default backfill and auto-save wiring: applying defaults to pristine lines on new invoices, and persisting settings to the building-supplier link on submit.

## Risk

Supplier defaults overwrite user-set values, backfill fires multiple times corrupting amounts, auto-save creates duplicate links, or settings lost on submit.

## Bugs Guarded

- "applies costAccount" / "applies distributionKeyId" tests guard supplier backfill one-shot -- backfill must run exactly once with correct data; `appliedPairRef` tracks `buildingId+senderId` pair
- never-overwrite guard tests guard supplier backfill one-shot -- "never overwrite" policy; `useInitialLineDefaults` only applies when line is pristine (`hasDefaultValues` check)
- "waits for loading" test guards supplier backfill one-shot -- late arrival (loading state) must delay application, not skip entirely; `supplierDefaults.isLoading` gate
- auto-save tests guard race conditions -- concurrent submit + defaults-loading must not create duplicate building-supplier links; `useAutoSaveBuildingSupplierDefaults` must deduplicate by pair

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| applies costAccount on pristine first line | `setValue('amounts.0', ...)` with `costAccount.id` |
| applies distributionKeyId on pristine first line | `setValue('amounts.0', ...)` with `distributionKeyId` |
| does NOT fire in edit mode | `setValue` NOT called |
| does NOT fire with "free" distribution (regression) | Line with `distributionType: 'free'` untouched |
| does NOT fire with non-zero totalAmount | Non-pristine line untouched |
| does NOT fire with existing costAccount | User-set costAccount preserved |
| only fires once (ref guard) | `setValue` called exactly once across re-renders |
| waits for supplier defaults to finish loading | NOT called while loading, called after |
| does NOT fire when no configured defaults | Empty defaults -> no `setValue` |
| auto-save extracts settings from amounts | `saveSupplierDefaults` called with first line's data |
| auto-save creates link for new supplier | `linkSupplier` mutation called |
| auto-save updates empty fields on existing link | `updateSupplier` called for empty fields only |
| auto-save skips when all fields set | No mutation fired |

## Related Specs

- Distribution key application: [amount-distribution-sheet.md](./amount-distribution-sheet.md) — key shares
- Add line defaults: [invoice-lines-table.md](./invoice-lines-table.md) — createDefaultAmountWithDefaults
- Inline supplier select: [inline-selects.md](./inline-selects.md) — supplier selection triggers

## Mocking Strategy

```typescript
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));

vi.mock('@/hooks/financial/useBuildingSuppliers', () => ({
  useLinkBuildingSupplier: vi.fn(() => ({ mutate: vi.fn() })),
  useUpdateBuildingSupplier: vi.fn(() => ({ mutate: vi.fn() })),
}));
```

## Shared Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { UseFormReturn } from 'react-hook-form';
import { renderHook, waitFor } from '@testing-library/react';
import type { PurchaseInvoiceFormV2Data } from '../../../purchase-invoice-v2/schema';
import { useInitialLineDefaults } from '../useInitialLineDefaults';

const mockProperties = [{ id: 'unit-1' }, { id: 'unit-2' }];

const mockLedgerOptions = [
  { id: 'mother-1', type: 'MOTHER', code: '6100', name: 'Maintenance' },
];

const mockDistributionKey = (id: string) => ({
  id,
  name: `Key ${id}`,
  items: mockProperties.map((p) => ({ propertyId: p.id, share: 500 })),
});

type MockMethods = Pick<UseFormReturn<PurchaseInvoiceFormV2Data>, 'setValue' | 'getValues' | 'resetField' | 'trigger'>;

function mockFormMethods(values: Record<string, unknown>): MockMethods {
  return {
    setValue: vi.fn(),
    getValues: vi.fn((key?: string) => (key ? values[key] : values)),
    resetField: vi.fn(),
    trigger: vi.fn(),
  };
}

const makePristineLine = () => ({
  id: 'pristine-1',
  totalAmount: 0,
  amount: 0,
  costAccount: undefined,
  distributionKeyId: undefined,
  distributionType: 'share',
  useDistributionKey: false,
  wholeBuilding: false,
  totalShare: 0,
  units: [],
});

beforeEach(() => {
  vi.clearAllMocks();
});
```

**Architecture note**: Supplier defaults are applied via two mechanisms:
1. **Initial line defaults** (`useInitialLineDefaults`) -- one-shot update of the pristine first line when creating a new invoice
2. **Add Line** (`createDefaultAmountWithDefaults`) -- event-based, applies defaults at line creation time (tested in invoice-lines-table.md)

The previous `useBackfillSupplierDefaults` hook was removed because it incorrectly overwrote existing lines (including "free" distributions) in edit mode.

**Source reference**: `useInitialLineDefaults.ts`, `useAutoSaveBuildingSupplierDefaults.ts`, `usePurchaseInvoiceForm.ts`

---

## Initial line defaults applies costAccount on pristine first line (new invoice)

**Preconditions**: New invoice (no `invoiceId`). Building + supplier selected. Supplier defaults return `costAccountId: 'mother-1'`. First amount line is pristine (totalAmount = 0, no costAccount, no distributionKeyId).

### Steps

1. Render the hook with `invoiceId: undefined`, `buildingId: 'b-1'`, `senderId: 's-1'`
2. Mock `supplierDefaults` returning `{ costAccountId: 'mother-1', costAccountType: 'MOTHER' }`
3. Provide matching ledger options
4. Wait for effect to fire

### Expected Outcome

- `methods.setValue('amounts.0', ...)` called with updated line
- Updated line's `costAccount.id` is `'mother-1'`
- `costAccount.type` is `CostAccountType.MOTHER`

### Example Code

```typescript
import { describe, it, expect, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useInitialLineDefaults } from '../useInitialLineDefaults';

describe('Supplier Defaults — Initial Line', () => {
  it('applies costAccount to pristine first line on new invoice', async () => {
    const methods = mockFormMethods({
      amounts: [makePristineLine()],
    });

    renderHook(() =>
      useInitialLineDefaults({
        methods,
        invoiceId: undefined,
        buildingId: 'b-1',
        senderId: 's-1',
        supplierDefaults: {
          isLoading: false,
          defaults: { costAccountId: 'mother-1', costAccountType: 'MOTHER' },
        },
        distributionKeys: [],
        properties: mockProperties,
        ledgerOptions: [{ id: 'mother-1', type: 'MOTHER', code: '6100', name: 'Maintenance' }],
      }),
    );

    await waitFor(() => {
      expect(methods.setValue).toHaveBeenCalledWith(
        'amounts.0',
        expect.objectContaining({
          costAccount: expect.objectContaining({ id: 'mother-1' }),
        }),
        { shouldValidate: true },
      );
    });
  });
});
```

---

## Initial line defaults applies distributionKeyId on pristine first line (new invoice)

**Preconditions**: New invoice. Supplier defaults return `distributionKeyId: 'dk-1'`. Distribution key exists and building has properties.

### Steps

1. Render with `invoiceId: undefined`, supplier defaults containing `distributionKeyId: 'dk-1'`
2. Provide matching distribution key and properties

### Expected Outcome

- Updated line has `distributionKeyId: 'dk-1'`
- `useDistributionKey: true` and `wholeBuilding: true` set via `createDefaultAmountWithDefaults`
- Units have calculated shares from the distribution key

### Example Code

```typescript
it('applies distributionKeyId to pristine first line on new invoice', async () => {
  const methods = mockFormMethods({
    amounts: [makePristineLine()],
  });

  renderHook(() =>
    useInitialLineDefaults({
      methods,
      invoiceId: undefined,
      buildingId: 'b-1',
      senderId: 's-1',
      supplierDefaults: {
        isLoading: false,
        defaults: { distributionKeyId: 'dk-1' },
      },
      distributionKeys: [mockDistributionKey('dk-1')],
      properties: [{ id: 'unit-1' }, { id: 'unit-2' }],
      ledgerOptions: [],
    }),
  );

  await waitFor(() => {
    expect(methods.setValue).toHaveBeenCalledWith(
      'amounts.0',
      expect.objectContaining({ distributionKeyId: 'dk-1' }),
      { shouldValidate: true },
    );
  });
});
```

---

## Does NOT fire in edit mode (invoiceId set)

**Preconditions**: Form opened in edit mode (`invoiceId: 'inv-123'`). First line is pristine. Supplier defaults available.

### Steps

1. Render with `invoiceId: 'inv-123'` (edit mode)
2. Supplier defaults load successfully

### Expected Outcome

- `methods.setValue` NOT called
- Existing form data preserved unchanged

### Example Code

```typescript
it('does not fire in edit mode', async () => {
  const methods = mockFormMethods({
    amounts: [makePristineLine()],
  });

  renderHook(() =>
    useInitialLineDefaults({
      methods,
      invoiceId: 'inv-123',
      buildingId: 'b-1',
      senderId: 's-1',
      supplierDefaults: {
        isLoading: false,
        defaults: { costAccountId: 'mother-1', distributionKeyId: 'dk-1' },
      },
      distributionKeys: [mockDistributionKey('dk-1')],
      properties: mockProperties,
      ledgerOptions: mockLedgerOptions,
    }),
  );

  // Wait a tick to ensure effect had chance to run
  await waitFor(() => {
    expect(methods.setValue).not.toHaveBeenCalled();
  });
});
```

---

## Does NOT fire when first line has "free" distribution (REGRESSION)

**Preconditions**: New invoice. First line has `distributionType: 'free'` with custom unit amounts (user previously set via distribute equally). `distributionKeyId` is `undefined` (by design for "free" type). Supplier has defaults configured.

**Bug context**: This is the regression test for the critical bug where `useBackfillSupplierDefaults` incorrectly treated lines with `distributionType: 'free'` as "empty" because they have no `distributionKeyId`.

### Steps

1. Render with first line having `distributionType: 'free'`, units with amounts, and `distributionKeyId: undefined`
2. Supplier defaults provide `distributionKeyId: 'dk-1'`

### Expected Outcome

- `methods.setValue` NOT called
- Line retains `distributionType: 'free'`
- Custom unit amounts preserved (not recalculated)
- `distributionKeyId` remains `undefined`

### Example Code

```typescript
it('does not fire with free distribution', async () => {
  const methods = mockFormMethods({
    amounts: [{
      id: 'line-1',
      totalAmount: 10000,
      amount: 10000,
      costAccount: undefined,
      distributionKeyId: undefined,
      distributionType: 'free',
      useDistributionKey: false,
      wholeBuilding: false,
      totalShare: 10000,
      units: [
        { id: 'unit-1', selected: true, amount: 6000, share: 6000 },
        { id: 'unit-2', selected: true, amount: 4000, share: 4000 },
      ],
    }],
  });

  renderHook(() =>
    useInitialLineDefaults({
      methods,
      invoiceId: undefined,
      buildingId: 'b-1',
      senderId: 's-1',
      supplierDefaults: {
        isLoading: false,
        defaults: { costAccountId: 'mother-1', distributionKeyId: 'dk-1' },
      },
      distributionKeys: [mockDistributionKey('dk-1')],
      properties: mockProperties,
      ledgerOptions: mockLedgerOptions,
    }),
  );

  await waitFor(() => {
    expect(methods.setValue).not.toHaveBeenCalled();
  });
});
```

---

## Does NOT fire when first line has non-zero totalAmount

**Preconditions**: New invoice. First line already has `totalAmount: 5000` (user typed an amount). No cost account or distribution key set.

### Steps

1. Render with first line having `totalAmount: 5000`

### Expected Outcome

- `methods.setValue` NOT called
- Line is not considered "pristine" because `totalAmount > 0`

### Example Code

```typescript
it('does NOT fire when first line has non-zero totalAmount', async () => {
  const methods = mockFormMethods({
    amounts: [{
      id: 'line-1',
      totalAmount: 5000,
      amount: 5000,
      costAccount: undefined,
      distributionKeyId: undefined,
      distributionType: 'share',
      useDistributionKey: false,
      totalShare: 0,
      units: [],
    }],
  });

  renderHook(() =>
    useInitialLineDefaults({
      methods,
      invoiceId: undefined,
      buildingId: 'b-1',
      senderId: 's-1',
      supplierDefaults: {
        isLoading: false,
        defaults: { costAccountId: 'mother-1' },
      },
      distributionKeys: [],
      properties: mockProperties,
      ledgerOptions: mockLedgerOptions,
    }),
  );

  await waitFor(() => {
    expect(methods.setValue).not.toHaveBeenCalled();
  });
});
```

---

## Does NOT fire when first line already has costAccount

**Preconditions**: New invoice. First line has a user-set `costAccount`. No distribution key.

### Steps

1. Render with first line having `costAccount: { id: 'user-ledger', type: 'MOTHER' }`
2. Supplier defaults load with different `costAccountId`

### Expected Outcome

- `methods.setValue` NOT called
- Line is not considered "pristine" because `costAccount` is set

### Example Code

```typescript
it('does NOT fire when first line already has costAccount', async () => {
  const methods = mockFormMethods({
    amounts: [{
      id: 'line-1',
      totalAmount: 0,
      amount: 0,
      costAccount: { id: 'user-ledger', type: 'MOTHER' },
      distributionKeyId: undefined,
      distributionType: 'share',
      useDistributionKey: false,
      totalShare: 0,
      units: [],
    }],
  });

  renderHook(() =>
    useInitialLineDefaults({
      methods,
      invoiceId: undefined,
      buildingId: 'b-1',
      senderId: 's-1',
      supplierDefaults: {
        isLoading: false,
        defaults: { costAccountId: 'supplier-ledger' },
      },
      distributionKeys: [],
      properties: mockProperties,
      ledgerOptions: [{ id: 'supplier-ledger', type: 'MOTHER' }],
    }),
  );

  await waitFor(() => {
    expect(methods.setValue).not.toHaveBeenCalled();
  });
});
```

---

## Only fires once (ref guard prevents duplicate execution)

**Preconditions**: New invoice. Pristine first line. Supplier defaults available.

### Steps

1. Render hook, wait for initial fire
2. Re-render with same props (simulating unrelated state change)

### Expected Outcome

- `methods.setValue` called exactly once
- `appliedRef` prevents second execution

### Example Code

```typescript
it('only fires once even on re-render', async () => {
  const methods = mockFormMethods({
    amounts: [makePristineLine()],
  });

  const baseProps = {
    methods,
    invoiceId: undefined,
    buildingId: 'b-1',
    senderId: 's-1',
    supplierDefaults: {
      isLoading: false,
      defaults: { costAccountId: 'mother-1' },
    },
    distributionKeys: [],
    properties: mockProperties,
    ledgerOptions: mockLedgerOptions,
  };

  const { rerender } = renderHook(
    (props) => useInitialLineDefaults(props),
    { initialProps: baseProps },
  );

  await waitFor(() => expect(methods.setValue).toHaveBeenCalledTimes(1));

  // Re-render with identical props
  rerender(baseProps);

  // Still only called once
  expect(methods.setValue).toHaveBeenCalledTimes(1);
});
```

---

## Waits for supplier defaults to finish loading

**Preconditions**: New invoice. `supplierDefaults.isLoading` is initially `true`.

### Steps

1. Render with `supplierDefaults.isLoading: true`
2. Re-render with `supplierDefaults.isLoading: false` and defaults populated

### Expected Outcome

- `methods.setValue` NOT called while loading
- `methods.setValue` called after loading completes

### Example Code

```typescript
it('waits for supplier defaults to finish loading', async () => {
  const methods = mockFormMethods({
    amounts: [makePristineLine()],
  });

  const { rerender } = renderHook(
    (props) => useInitialLineDefaults(props),
    {
      initialProps: {
        methods,
        invoiceId: undefined,
        buildingId: 'b-1',
        senderId: 's-1',
        supplierDefaults: { isLoading: true, defaults: {} },
        distributionKeys: [],
        properties: mockProperties,
        ledgerOptions: mockLedgerOptions,
      },
    },
  );

  // Not called while loading
  expect(methods.setValue).not.toHaveBeenCalled();

  // Simulate defaults finishing loading
  rerender({
    methods,
    invoiceId: undefined,
    buildingId: 'b-1',
    senderId: 's-1',
    supplierDefaults: {
      isLoading: false,
      defaults: { costAccountId: 'mother-1' },
    },
    distributionKeys: [],
    properties: mockProperties,
    ledgerOptions: mockLedgerOptions,
  });

  await waitFor(() => {
    expect(methods.setValue).toHaveBeenCalledTimes(1);
  });
});
```

---

## Does NOT fire when supplier has no configured defaults

**Preconditions**: New invoice. Pristine first line. Supplier defaults return empty `{}`.

### Steps

1. Render with supplier defaults `{ costAccountId: undefined, distributionKeyId: undefined }`

### Expected Outcome

- `methods.setValue` NOT called
- Pristine line remains unchanged

### Example Code

```typescript
it('does NOT fire when supplier has no configured defaults', async () => {
  const methods = mockFormMethods({
    amounts: [makePristineLine()],
  });

  renderHook(() =>
    useInitialLineDefaults({
      methods,
      invoiceId: undefined,
      buildingId: 'b-1',
      senderId: 's-1',
      supplierDefaults: { isLoading: false, defaults: {} },
      distributionKeys: [],
      properties: mockProperties,
      ledgerOptions: mockLedgerOptions,
    }),
  );

  await waitFor(() => {
    expect(methods.setValue).not.toHaveBeenCalled();
  });
});
```

---

## Auto-save calls saveSupplierDefaults with correct args on submit

**Preconditions**: Form submitted successfully. Amount lines contain `costAccount` and `distributionKeyId`.

### Steps

1. Set up `useAutoSaveBuildingSupplierDefaults` with `hasSupplierLink: false`
2. Call `saveSupplierDefaults({ amounts: [line with costAccount + distribution key] })`

### Expected Outcome

- `linkSupplier` mutation called (since no existing link)
- Payload includes `invoiceMotherId` from first line's cost account
- Payload includes `distributionKeyId` from first line

### Example Code

```typescript
describe('Supplier Defaults — Auto-save', () => {
  it('saveSupplierDefaults extracts settings from amount lines', () => {
    const linkSupplier = vi.fn();
    vi.mocked(useLinkBuildingSupplier).mockReturnValue({ mutate: linkSupplier });

    const { result } = renderHook(() =>
      useAutoSaveBuildingSupplierDefaults({
        buildingId: 'b-1',
        senderId: 's-1',
        hasSupplierLink: false,
        supplier: undefined,
      }),
    );

    result.current.saveSupplierDefaults({
      amounts: [
        {
          id: 'line-1',
          costAccount: { id: 'mother-1', type: 'MOTHER' },
          distributionKeyId: 'dk-1',
        },
      ],
    });

    expect(linkSupplier).toHaveBeenCalledWith(
      expect.objectContaining({
        contactId: 's-1',
        invoiceMotherId: 'mother-1',
        distributionKeyId: 'dk-1',
      }),
    );
  });
});
```

---

## Auto-save creates link when no existing link

**Preconditions**: `hasSupplierLink: false`, amounts with cost account.

### Steps

1. Call `saveSupplierDefaults` with amounts

### Expected Outcome

- `linkSupplier` mutation called (not `updateSupplier`)
- Payload contains `contactId`, `invoiceMotherId`, `distributionKeyId`

### Example Code

```typescript
it('creates link when no existing supplier link', () => {
  const linkSupplier = vi.fn();
  const updateSupplier = vi.fn();

  const { result } = renderHook(() =>
    useAutoSaveBuildingSupplierDefaults({
      buildingId: 'b-1',
      senderId: 's-1',
      hasSupplierLink: false,
      supplier: undefined,
    }),
  );

  result.current.saveSupplierDefaults({
    amounts: [{ id: 'l-1', costAccount: { id: 'm-1', type: 'MOTHER' } }],
  });

  expect(linkSupplier).toHaveBeenCalled();
  expect(updateSupplier).not.toHaveBeenCalled();
});
```

---

## Auto-save updates only empty fields on existing link

**Preconditions**: `hasSupplierLink: true`, existing supplier has `invoiceMotherId: null` (empty), amounts contain a cost account.

### Steps

1. Call `saveSupplierDefaults` with amounts that have a `costAccount`

### Expected Outcome

- `updateSupplier` called (not `linkSupplier`)
- Payload includes `invoiceMotherId` (filling the empty field)
- No `distributionKeyId` in payload if supplier already has one

### Example Code

```typescript
it('updates only empty fields on existing link', () => {
  const updateSupplier = vi.fn();

  const { result } = renderHook(() =>
    useAutoSaveBuildingSupplierDefaults({
      buildingId: 'b-1',
      senderId: 's-1',
      hasSupplierLink: true,
      supplier: {
        invoiceMotherId: null,
        invoiceLedgerId: null,
        distributionKeyId: 'dk-existing',
      },
    }),
  );

  result.current.saveSupplierDefaults({
    amounts: [{
      id: 'l-1',
      costAccount: { id: 'm-1', type: 'MOTHER' },
      distributionKeyId: 'dk-new',
    }],
  });

  expect(updateSupplier).toHaveBeenCalledWith(
    expect.objectContaining({
      data: expect.objectContaining({ invoiceMotherId: 'm-1' }),
    }),
  );
  // distributionKeyId NOT in payload because supplier already has one
  expect(updateSupplier).toHaveBeenCalledWith(
    expect.objectContaining({
      data: expect.not.objectContaining({ distributionKeyId: expect.anything() }),
    }),
  );
});
```

---

## Auto-save skips when existing link has all fields set

**Preconditions**: `hasSupplierLink: true`, supplier has both `invoiceMotherId` and `distributionKeyId` already set.

### Steps

1. Call `saveSupplierDefaults` with amounts

### Expected Outcome

- Neither `linkSupplier` nor `updateSupplier` called
- Early return due to `!needsLedgerUpdate && !needsDistKeyUpdate`

### Example Code

```typescript
it('skips API call when existing link has all fields set', () => {
  const linkSupplier = vi.fn();
  const updateSupplier = vi.fn();

  const { result } = renderHook(() =>
    useAutoSaveBuildingSupplierDefaults({
      buildingId: 'b-1',
      senderId: 's-1',
      hasSupplierLink: true,
      supplier: {
        invoiceMotherId: 'existing-mother',
        invoiceLedgerId: null,
        distributionKeyId: 'existing-dk',
      },
    }),
  );

  result.current.saveSupplierDefaults({
    amounts: [{
      id: 'l-1',
      costAccount: { id: 'new-mother', type: 'MOTHER' },
      distributionKeyId: 'new-dk',
    }],
  });

  expect(linkSupplier).not.toHaveBeenCalled();
  expect(updateSupplier).not.toHaveBeenCalled();
});
```
