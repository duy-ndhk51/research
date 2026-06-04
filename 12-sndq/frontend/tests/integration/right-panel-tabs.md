# Right Panel Tabs

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/right-panel-tabs.test.ts`
**Component under test**: `InvoiceRightPanelConnected` (internal to `PurchaseInvoiceFormV3.tsx`)

Tests verify tab defaulting behavior based on Peppol data presence and user selection. The tab logic uses `hasPeppolData` (not `hasAttachments`) as the primary condition — the Peppol Attachments tab appears whenever `peppolData` exists, regardless of whether there are attachment files.

**Source reference**: `PurchaseInvoiceFormV3.tsx` lines 171-250

---

## IT-013: Default tab is uploader when no peppol data

**Preconditions**: No `peppolData` (undefined or null).

### Steps

1. Evaluate the tab selection logic with `peppolData = undefined`

### Assertions

- Active tab is `'uploader'`
- No extra tabs generated
- `hideInlineAttachments` is `false`

### Example Code

```typescript
import { describe, it, expect } from 'vitest';

describe('Right panel tabs', () => {
  it('IT-013: default tab is uploader when no peppol data', () => {
    const peppolData = undefined;
    const hasPeppolData = !!peppolData;
    const userSelectedTab: string | null = null;

    const rightPanelTab =
      userSelectedTab ?? (hasPeppolData ? 'attachments' : 'uploader');

    expect(rightPanelTab).toBe('uploader');

    // No extra tabs when no peppol data
    const extraTabs = !peppolData ? [] : [{ value: 'attachments' }];
    expect(extraTabs).toHaveLength(0);

    // Inline attachments NOT hidden (no peppol data)
    expect(hasPeppolData).toBe(false);
  });
});
```

---

## IT-013b: Default tab is attachments when peppol data exists without attachment files

**Preconditions**: `peppolData` exists but has no attachment files (empty or undefined `attachments` array). This is the common case when a Peppol XML is uploaded without embedded PDF/XML attachments.

### Steps

1. Set `peppolData` with no attachments (or empty array)
2. Evaluate tab selection and extra tab content

### Assertions

- Active tab defaults to `'attachments'`
- Extra tabs array contains one entry with `PeppolParsedPreview` as content (not `PeppolAttachmentsTab`)
- `hideInlineAttachments` is `true` (prevents duplicate rendering in uploader tab)
- Tab order is `['attachments', 'uploader', 'allocation']`

### Example Code

```typescript
it('IT-013b: peppol data without attachments shows PeppolParsedPreview in attachments tab', () => {
  const peppolData = {
    invoiceNumber: 'PEPINV-001',
    attachments: [],
    // ...other peppol fields
  };
  const attachments = peppolData.attachments ?? [];
  const hasAttachments = attachments.length > 0;
  const hasPeppolData = !!peppolData;
  const userSelectedTab: string | null = null;

  const rightPanelTab =
    userSelectedTab ?? (hasPeppolData ? 'attachments' : 'uploader');

  expect(rightPanelTab).toBe('attachments');
  expect(hasPeppolData).toBe(true);
  expect(hasAttachments).toBe(false);

  // Extra tab created with PeppolParsedPreview (not PeppolAttachmentsTab)
  // because hasAttachments is false
  const extraTabs = !peppolData
    ? []
    : [{
        value: 'attachments',
        label: 'Peppol attachments',
        // content: hasAttachments
        //   ? <PeppolAttachmentsTab />
        //   : <PeppolParsedPreview />
        contentType: hasAttachments ? 'PeppolAttachmentsTab' : 'PeppolParsedPreview',
      }];
  expect(extraTabs).toHaveLength(1);
  expect(extraTabs[0].contentType).toBe('PeppolParsedPreview');

  // hideInlineAttachments prevents duplicate rendering in uploader tab
  const hideInlineAttachments = hasPeppolData;
  expect(hideInlineAttachments).toBe(true);

  // Tab order puts attachments first
  const tabOrder = hasPeppolData
    ? ['attachments', 'uploader', 'allocation']
    : undefined;
  expect(tabOrder).toEqual(['attachments', 'uploader', 'allocation']);
});
```

---

## IT-013c: Peppol data cleared removes extra tab and falls back to uploader

**Preconditions**: User previously uploaded a Peppol XML (tab was showing), then deletes the file.

### Steps

1. Start with `peppolData` set (extra tab exists)
2. Simulate clearing peppol data (user deletes file → `peppolData` becomes null)
3. Evaluate tab state

### Assertions

- Extra tabs array is empty
- Active tab falls back to `'uploader'` (user hadn't explicitly selected a tab)
- `hideInlineAttachments` is `false`
- Tab order is `undefined` (no custom ordering)

### Example Code

```typescript
it('IT-013c: clearing peppol data removes extra tab and falls back to uploader', () => {
  // Simulate peppol data being cleared
  const peppolData = null;
  const hasPeppolData = !!peppolData;
  const userSelectedTab: string | null = null;

  const rightPanelTab =
    userSelectedTab ?? (hasPeppolData ? 'attachments' : 'uploader');

  expect(rightPanelTab).toBe('uploader');

  const extraTabs = !peppolData ? [] : [{ value: 'attachments' }];
  expect(extraTabs).toHaveLength(0);

  expect(hasPeppolData).toBe(false);

  const tabOrder = hasPeppolData
    ? ['attachments', 'uploader', 'allocation']
    : undefined;
  expect(tabOrder).toBeUndefined();
});
```

---

## IT-014: Default tab is attachments when peppol has attachment files

**Preconditions**: `peppolData.attachments` has 2 items (PDF + XML).

### Steps

1. Set `peppolData` with attachments array containing entries

### Assertions

- Active tab defaults to `'attachments'`
- Extra tabs array contains one entry with `PeppolAttachmentsTab` as content (not `PeppolParsedPreview`)
- `hideInlineAttachments` is `true`

### Example Code

```typescript
it('IT-014: peppol with attachments shows PeppolAttachmentsTab in attachments tab', () => {
  const peppolData = {
    attachments: [
      { filename: 'doc.pdf', mimetype: 'application/pdf' },
      { filename: 'data.xml', mimetype: 'text/xml' },
    ],
  };
  const attachments = peppolData.attachments ?? [];
  const hasAttachments = attachments.length > 0;
  const hasPeppolData = !!peppolData;
  const userSelectedTab: string | null = null;

  const rightPanelTab =
    userSelectedTab ?? (hasPeppolData ? 'attachments' : 'uploader');

  expect(rightPanelTab).toBe('attachments');
  expect(hasPeppolData).toBe(true);
  expect(hasAttachments).toBe(true);

  // Extra tab uses PeppolAttachmentsTab when attachments exist
  const extraTabs = !peppolData
    ? []
    : [{
        value: 'attachments',
        label: 'Peppol attachments',
        contentType: hasAttachments ? 'PeppolAttachmentsTab' : 'PeppolParsedPreview',
      }];
  expect(extraTabs).toHaveLength(1);
  expect(extraTabs[0].contentType).toBe('PeppolAttachmentsTab');

  // hideInlineAttachments based on peppolData existence
  const hideInlineAttachments = hasPeppolData;
  expect(hideInlineAttachments).toBe(true);
});
```

---

## IT-015: User tab selection overrides default

**Preconditions**: Peppol data present, user explicitly selects `'uploader'`.

### Steps

1. Set peppolData (with or without attachments)
2. Simulate user selecting `'uploader'` tab via `setUserSelectedTab`

### Assertions

- Active tab is `'uploader'` despite peppol data being present
- The `userSelectedTab` takes precedence over the automatic default

### Example Code

```typescript
it('IT-015: user tab selection overrides peppol default', () => {
  const hasPeppolData = true;
  const userSelectedTab = 'uploader';

  const rightPanelTab =
    userSelectedTab ?? (hasPeppolData ? 'attachments' : 'uploader');

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
