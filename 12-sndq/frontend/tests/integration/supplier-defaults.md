# Supplier Defaults — Backfill & Auto-save

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/supplier-defaults.test.tsx`
**Logic under test**: `useBackfillSupplierDefaults` hook and `useAutoSaveBuildingSupplierDefaults` hook

Tests verify the form-level integration of supplier default hooks: backfilling empty invoice lines when supplier defaults become available, and auto-saving ledger/distribution key settings to the building-supplier link on successful submit. Internal logic is already unit-tested — these tests focus on wiring with React Hook Form context and mocked API mutations.

**Source reference**: `useBackfillSupplierDefaults.ts`, `useAutoSaveBuildingSupplierDefaults.ts`, `usePurchaseInvoiceForm.ts`

---

## IT-048: Backfill sets costAccount on empty lines

**Preconditions**: Form mounted with building + supplier selected. Supplier defaults return `costAccountId: 'mother-1'`. One amount line exists with empty `costAccount`.

### Steps

1. Render the form with mocked `useSupplierDefaults` returning `{ costAccountId: 'mother-1', costAccountType: 'MOTHER' }`
2. Wait for `supplierDefaults.isLoading` to become `false`

### Assertions

- `methods.setValue('amounts', ...)` called with patched array
- First line's `costAccount.id` is `'mother-1'`
- `costAccount.type` is `CostAccountType.MOTHER`

### Example Code

```typescript
import { describe, it, expect, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useBackfillSupplierDefaults, backfillAmountsWithDefaults } from '../useBackfillSupplierDefaults';

describe('Supplier Defaults — Backfill', () => {
  it('IT-048: backfills costAccount on empty lines', async () => {
    const methods = mockFormMethods({
      amounts: [{ id: 'line-1', costAccount: undefined, distributionKeyId: undefined }],
    });

    const supplierDefaults = {
      isLoading: false,
      defaults: { costAccountId: 'mother-1', costAccountType: 'MOTHER' },
    };

    renderHook(() =>
      useBackfillSupplierDefaults({
        methods,
        supplierDefaults,
        distributionKeys: [],
        properties: [],
        buildingId: 'b-1',
        senderId: 's-1',
        ledgerOptions: [{ id: 'mother-1', type: 'MOTHER', code: '6100', name: 'Maintenance' }],
      }),
    );

    await waitFor(() => {
      expect(methods.setValue).toHaveBeenCalledWith(
        'amounts',
        expect.arrayContaining([
          expect.objectContaining({ costAccount: expect.objectContaining({ id: 'mother-1' }) }),
        ]),
        { shouldValidate: true },
      );
    });
  });
});
```

---

## IT-049: Backfill sets distributionKeyId on empty lines

**Preconditions**: Supplier defaults return `distributionKeyId: 'dk-1'`. Amount line has no distribution key. Distribution key `dk-1` exists and building has properties.

### Steps

1. Render with supplier defaults containing `distributionKeyId: 'dk-1'`
2. Provide matching distribution key and properties

### Assertions

- Line patched with `distributionKeyId: 'dk-1'`
- `applyDistributionKey` called to compute unit shares
- `methods.setValue('amounts', ...)` called with updated array

### Example Code

```typescript
it('IT-049: backfills distributionKeyId on empty lines', async () => {
  const methods = mockFormMethods({
    amounts: [{ id: 'line-1', costAccount: undefined, distributionKeyId: undefined, totalAmount: 10000 }],
  });

  renderHook(() =>
    useBackfillSupplierDefaults({
      methods,
      supplierDefaults: {
        isLoading: false,
        defaults: { distributionKeyId: 'dk-1' },
      },
      distributionKeys: [mockDistributionKey('dk-1')],
      properties: [{ id: 'unit-1' }, { id: 'unit-2' }],
      buildingId: 'b-1',
      senderId: 's-1',
      ledgerOptions: [],
    }),
  );

  await waitFor(() => {
    const patchedAmounts = methods.setValue.mock.calls[0][1];
    expect(patchedAmounts[0].distributionKeyId).toBe('dk-1');
  });
});
```

---

## IT-050: Backfill does NOT overwrite existing costAccount

**Preconditions**: Amount line already has `costAccount: { id: 'user-set-ledger' }`. Supplier defaults provide a different `costAccountId`.

### Steps

1. Render with line that has existing `costAccount`
2. Supplier defaults load with different `costAccountId`

### Assertions

- `costAccount.id` remains `'user-set-ledger'`
- `methods.setValue` NOT called (or called without changing the line)

### Example Code

```typescript
it('IT-050: does not overwrite existing costAccount', async () => {
  const methods = mockFormMethods({
    amounts: [{ id: 'line-1', costAccount: { id: 'user-set-ledger', type: 'MOTHER' } }],
  });

  renderHook(() =>
    useBackfillSupplierDefaults({
      methods,
      supplierDefaults: {
        isLoading: false,
        defaults: { costAccountId: 'supplier-ledger' },
      },
      distributionKeys: [],
      properties: [],
      buildingId: 'b-1',
      senderId: 's-1',
      ledgerOptions: [{ id: 'supplier-ledger', type: 'MOTHER' }],
    }),
  );

  // setValue should not be called since no changes were needed
  await waitFor(() => {
    expect(methods.setValue).not.toHaveBeenCalled();
  });
});
```

---

## IT-051: Backfill does NOT overwrite existing distributionKeyId

**Preconditions**: Amount line has `distributionKeyId: 'dk-existing'`. Supplier defaults provide `distributionKeyId: 'dk-new'`.

### Steps

1. Render with line that has existing distribution key

### Assertions

- `distributionKeyId` remains `'dk-existing'`

### Example Code

```typescript
it('IT-051: does not overwrite existing distributionKeyId', async () => {
  const methods = mockFormMethods({
    amounts: [{
      id: 'line-1',
      costAccount: undefined,
      distributionKeyId: 'dk-existing',
    }],
  });

  renderHook(() =>
    useBackfillSupplierDefaults({
      methods,
      supplierDefaults: {
        isLoading: false,
        defaults: { costAccountId: 'mother-1', distributionKeyId: 'dk-new' },
      },
      distributionKeys: [mockDistributionKey('dk-new')],
      properties: mockProperties,
      buildingId: 'b-1',
      senderId: 's-1',
      ledgerOptions: [{ id: 'mother-1', type: 'MOTHER' }],
    }),
  );

  await waitFor(() => {
    // Only costAccount should be patched, not distribution key
    const patchedAmounts = methods.setValue.mock.calls[0][1];
    expect(patchedAmounts[0].distributionKeyId).toBe('dk-existing');
    expect(patchedAmounts[0].costAccount.id).toBe('mother-1');
  });
});
```

---

## IT-052: Changing supplier triggers backfill for new pair

**Preconditions**: First supplier already backfilled (pair key = `b-1:s-1`). User switches to supplier `s-2`.

### Steps

1. Render with `senderId: 's-1'`, wait for backfill
2. Re-render with `senderId: 's-2'` and new defaults

### Assertions

- Backfill fires again for the new pair
- `methods.setValue` called a second time with new defaults

### Example Code

```typescript
it('IT-052: backfill fires again when supplier changes', async () => {
  const { rerender } = renderHook(
    ({ senderId, defaults }) =>
      useBackfillSupplierDefaults({
        methods,
        supplierDefaults: { isLoading: false, defaults },
        distributionKeys: [],
        properties: [],
        buildingId: 'b-1',
        senderId,
        ledgerOptions: mockLedgerOptions,
      }),
    {
      initialProps: {
        senderId: 's-1',
        defaults: { costAccountId: 'ledger-a' },
      },
    },
  );

  await waitFor(() => expect(methods.setValue).toHaveBeenCalledTimes(1));

  rerender({ senderId: 's-2', defaults: { costAccountId: 'ledger-b' } });

  await waitFor(() => expect(methods.setValue).toHaveBeenCalledTimes(2));
});
```

---

## IT-053: Same supplier re-selected does NOT re-trigger backfill

**Preconditions**: Backfill already applied for pair `b-1:s-1`.

### Steps

1. Render with `senderId: 's-1'`, backfill fires
2. Re-render with same `senderId: 's-1'` (e.g., from unrelated re-render)

### Assertions

- `methods.setValue` called exactly once (not twice)
- `appliedPairRef` prevents duplicate execution

### Example Code

```typescript
it('IT-053: same supplier does not re-trigger backfill', async () => {
  const { rerender } = renderHook(
    (props) => useBackfillSupplierDefaults(props),
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

## IT-054: Auto-save calls saveSupplierDefaults with correct args on submit

**Preconditions**: Form submitted successfully. Amount lines contain `costAccount` and `distributionKeyId`.

### Steps

1. Set up `useAutoSaveBuildingSupplierDefaults` with `hasSupplierLink: false`
2. Call `saveSupplierDefaults({ amounts: [line with costAccount + distribution key] })`

### Assertions

- `linkSupplier` mutation called (since no existing link)
- Payload includes `invoiceMotherId` from first line's cost account
- Payload includes `distributionKeyId` from first line

### Example Code

```typescript
describe('Supplier Defaults — Auto-save', () => {
  it('IT-054: saveSupplierDefaults extracts settings from amount lines', () => {
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

## IT-055: Auto-save creates link when no existing link

**Preconditions**: `hasSupplierLink: false`, amounts with cost account.

### Steps

1. Call `saveSupplierDefaults` with amounts

### Assertions

- `linkSupplier` mutation called (not `updateSupplier`)
- Payload contains `contactId`, `invoiceMotherId`, `distributionKeyId`

### Example Code

```typescript
it('IT-055: creates link when no existing supplier link', () => {
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

## IT-056: Auto-save updates only empty fields on existing link

**Preconditions**: `hasSupplierLink: true`, existing supplier has `invoiceMotherId: null` (empty), amounts contain a cost account.

### Steps

1. Call `saveSupplierDefaults` with amounts that have a `costAccount`

### Assertions

- `updateSupplier` called (not `linkSupplier`)
- Payload includes `invoiceMotherId` (filling the empty field)
- No `distributionKeyId` in payload if supplier already has one

### Example Code

```typescript
it('IT-056: updates only empty fields on existing link', () => {
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

## IT-057: Auto-save skips when existing link has all fields set

**Preconditions**: `hasSupplierLink: true`, supplier has both `invoiceMotherId` and `distributionKeyId` already set.

### Steps

1. Call `saveSupplierDefaults` with amounts

### Assertions

- Neither `linkSupplier` nor `updateSupplier` called
- Early return due to `!needsLedgerUpdate && !needsDistKeyUpdate`

### Example Code

```typescript
it('IT-057: skips API call when existing link has all fields set', () => {
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
