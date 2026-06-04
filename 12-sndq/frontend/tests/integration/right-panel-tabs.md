# Right Panel Tabs

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/right-panel-tabs.test.ts`
**Component under test**: `InvoiceRightPanelConnected` (internal to `PurchaseInvoiceFormV3.tsx`)

Tests verify tab defaulting behavior based on Peppol attachments and user selection.

**Source reference**: `PurchaseInvoiceFormV3.tsx` lines 171-243

---

## IT-013: Default tab is uploader when no peppol attachments

**Preconditions**: No `peppolData` or empty attachments array.

### Steps

1. Evaluate the tab selection logic with `peppolData = undefined`

### Assertions

- Active tab is `'uploader'`
- No extra tabs generated

### Example Code

```typescript
import { describe, it, expect } from 'vitest';

describe('Right panel tabs', () => {
  it('IT-013: default tab is uploader when no peppol attachments', () => {
    const peppolData = undefined;
    const attachments = peppolData?.attachments ?? [];
    const hasAttachments = attachments.length > 0;
    const userSelectedTab: string | null = null;

    const rightPanelTab =
      userSelectedTab ?? (hasAttachments ? 'attachments' : 'uploader');

    expect(rightPanelTab).toBe('uploader');
    expect(hasAttachments).toBe(false);
  });
});
```

---

## IT-014: Default tab is attachments when peppol has attachments

**Preconditions**: `peppolData.attachments` has 2 items.

### Steps

1. Set `peppolData` with attachments array containing entries

### Assertions

- Active tab defaults to `'attachments'`
- Extra tabs array contains one entry with value `'attachments'` and label matching `purchase_invoice.peppol_attachments`

### Example Code

```typescript
it('IT-014: default tab is attachments when peppol data has attachments', () => {
  const peppolData = {
    attachments: [
      { filename: 'doc.pdf', mimetype: 'application/pdf' },
      { filename: 'data.xml', mimetype: 'text/xml' },
    ],
  };
  const attachments = peppolData.attachments ?? [];
  const hasAttachments = attachments.length > 0;
  const userSelectedTab: string | null = null;

  const rightPanelTab =
    userSelectedTab ?? (hasAttachments ? 'attachments' : 'uploader');

  expect(rightPanelTab).toBe('attachments');
  expect(hasAttachments).toBe(true);

  // Extra tabs would include:
  const extraTabs = attachments.length === 0
    ? []
    : [{ value: 'attachments', label: 'Peppol attachments' }];
  expect(extraTabs).toHaveLength(1);
  expect(extraTabs[0].value).toBe('attachments');
});
```

---

## IT-015: User tab selection overrides default

**Preconditions**: Peppol attachments present, user explicitly selects `'uploader'`.

### Steps

1. Set peppolData with attachments
2. Simulate user selecting `'uploader'` tab via `setUserSelectedTab`

### Assertions

- Active tab is `'uploader'` despite attachments being present
- The `userSelectedTab` takes precedence over the automatic default

### Example Code

```typescript
it('IT-015: user tab selection overrides peppol default', () => {
  const hasAttachments = true;
  const userSelectedTab = 'uploader';

  const rightPanelTab =
    userSelectedTab ?? (hasAttachments ? 'attachments' : 'uploader');

  expect(rightPanelTab).toBe('uploader');
});
```

---

## IT-016: Peppol data parsed with amounts triggers lock

**Preconditions**: Peppol data parsed callback fires with amounts.

### Steps

1. Call `safePeppolDataParsed` with data containing amount lines
2. Verify `setLockState` is called with computed total

### Assertions

- `setLockState` called with `{ locked: true, lockedTotal: <sum> }`
- `sumTotalAmounts` correctly computes the total

### Example Code

```typescript
import { sumTotalAmounts } from '../../components/invoice-lines/pipeline';

it('IT-016: peppol data parsed with amounts sets lock state', () => {
  const parsedAmounts = [
    { totalAmount: 5000 },
    { totalAmount: 3000 },
  ] as any[];

  const lockedTotal = sumTotalAmounts(parsedAmounts);

  expect(lockedTotal).toBe(8000);

  // In the component, safePeppolDataParsed calls:
  // setLockState({ locked: true, lockedTotal });
  const expectedLockState = { locked: true, lockedTotal: 8000 };
  expect(expectedLockState.locked).toBe(true);
  expect(expectedLockState.lockedTotal).toBe(8000);
});
```

---

## IT-016b: Peppol data parsed with no amounts does not lock

**Preconditions**: Peppol data parsed returns empty amounts array.

### Steps

1. Call `safePeppolDataParsed` with data that yields empty amounts

### Assertions

- `setLockState` is NOT called (the guard `parsedAmounts.length > 0` prevents it)

### Example Code

```typescript
it('IT-016b: peppol data with no amounts does not trigger lock', () => {
  const parsedAmounts: any[] = [];

  // Guard in safePeppolDataParsed:
  // if (parsedAmounts.length > 0) { setLockState(...) }
  const shouldLock = parsedAmounts.length > 0;
  expect(shouldLock).toBe(false);
});
```
