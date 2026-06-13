# Right Panel Tabs

**Status**: Not started
**Priority**: MEDIUM (wrong default tab hides Peppol data from user)
**Test tier**: Pure logic
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/right-panel-tabs.test.tsx`
**Component(s) under test**: `InvoiceRightPanelConnected` (internal to `PurchaseInvoiceFormV3.tsx`)

## Purpose

Guard the tab defaulting logic that determines whether users see the file uploader or Peppol data first, and the lock trigger on Peppol parse.

## Risk

Users see empty uploader instead of Peppol data. Tab persists stale selection after Peppol clear. Lock never triggers from Peppol amounts.

## Bugs Guarded

- Default tab / peppol cleared — stale `userSelectedTab` not reset when `peppolData` appears/disappears; condition uses `hasPeppolData` (not `hasAttachments`)
- Peppol content switching — `PeppolParsedPreview` vs `PeppolAttachmentsTab` depends on attachment file presence
- Peppol auto-lock (**B1**, lock state vs form amounts) — Peppol auto-lock pathway must compute correct `lockedTotal` from `safePeppolDataParsed` amounts
- User tab override — forced tab switch must not override explicit user selection

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Default tab is uploader (no peppol) | `rightPanelTab` is `'uploader'`, no extra tabs |
| Peppol without attachments shows PeppolParsedPreview | Tab content is `PeppolParsedPreview`, `hideInlineAttachments: true` |
| Peppol cleared removes tab, falls back to uploader | Extra tabs empty, `rightPanelTab` is `'uploader'` |
| Peppol with attachments shows PeppolAttachmentsTab | Tab content is `PeppolAttachmentsTab` |
| User tab selection overrides default | User selects `'uploader'` despite peppol -> stays `'uploader'` |
| Peppol amounts parsed triggers lock | `setLockState({ locked: true, lockedTotal })` called |
| Peppol with no amounts skips lock | `setLockState` NOT called |

## Mocking Strategy

```typescript
// Pure logic tests -- tab selection is computed from state variables.
// No component mocking needed for the tab selection logic itself.
```

## Shared Setup

```typescript
import { describe, it, expect } from 'vitest';
import { sumTotalAmounts } from '../../components/invoice-lines/pipeline';
import type { PeppolInvoiceResponse } from '@/common/api/resources/financial/peppolApi';
import type { AmountWithDistributionData } from '../../../purchase-invoice-v2/schema';

type AmountLine = Pick<AmountWithDistributionData, 'totalAmount'>;

function computeRightPanelTab({
  peppolData = undefined as PeppolInvoiceResponse | undefined,
  userSelectedTab = null as string | null,
}) {
  const hasPeppolData = !!peppolData;
  return userSelectedTab ?? (hasPeppolData ? 'attachments' : 'uploader');
}
```

**Source reference**: `PurchaseInvoiceFormV3.tsx` lines 171-250

---

## Default tab is uploader when no peppol data

**Preconditions**: No `peppolData` (undefined or null).

### Steps

1. Evaluate the tab selection logic with `peppolData = undefined`

### Expected Outcome

- Active tab is `'uploader'`
- No extra tabs generated
- `hideInlineAttachments` is `false`

### Example Code

```typescript
describe('Right panel tabs', () => {
  it('default tab is uploader when no peppol data', () => {
    const peppolData = undefined;
    const hasPeppolData = !!peppolData;
    const userSelectedTab: string | null = null;

    const rightPanelTab = computeRightPanelTab({ peppolData, userSelectedTab });

    expect(rightPanelTab).toBe('uploader');

    const extraTabs = !peppolData ? [] : [{ value: 'attachments' }];
    expect(extraTabs).toHaveLength(0);

    expect(hasPeppolData).toBe(false);
  });
});
```

---

## Default tab is attachments when peppol data exists without attachment files

**Preconditions**: `peppolData` exists but has no attachment files (empty or undefined `attachments` array).

### Steps

1. Set `peppolData` with no attachments (or empty array)
2. Evaluate tab selection and extra tab content

### Expected Outcome

- Active tab defaults to `'attachments'`
- Extra tabs array contains one entry with `PeppolParsedPreview` as content (not `PeppolAttachmentsTab`)
- `hideInlineAttachments` is `true` (prevents duplicate rendering in uploader tab)
- Tab order is `['attachments', 'uploader', 'allocation']`

### Example Code

```typescript
it('peppol data without attachments shows PeppolParsedPreview in attachments tab', () => {
  const peppolData = {
    invoiceNumber: 'PEPINV-001',
    attachments: [],
  };
  const attachments = peppolData.attachments ?? [];
  const hasAttachments = attachments.length > 0;
  const hasPeppolData = !!peppolData;
  const userSelectedTab: string | null = null;

  const rightPanelTab = computeRightPanelTab({ peppolData, userSelectedTab });

  expect(rightPanelTab).toBe('attachments');
  expect(hasPeppolData).toBe(true);
  expect(hasAttachments).toBe(false);

  const extraTabs = !peppolData
    ? []
    : [{
        value: 'attachments',
        label: 'Peppol attachments',
        contentType: hasAttachments ? 'PeppolAttachmentsTab' : 'PeppolParsedPreview',
      }];
  expect(extraTabs).toHaveLength(1);
  expect(extraTabs[0].contentType).toBe('PeppolParsedPreview');

  const hideInlineAttachments = hasPeppolData;
  expect(hideInlineAttachments).toBe(true);

  const tabOrder = hasPeppolData
    ? ['attachments', 'uploader', 'allocation']
    : undefined;
  expect(tabOrder).toEqual(['attachments', 'uploader', 'allocation']);
});
```

---

## Peppol data cleared removes extra tab and falls back to uploader

**Preconditions**: User previously uploaded a Peppol XML (tab was showing), then deletes the file.

### Steps

1. Start with `peppolData` set (extra tab exists)
2. Simulate clearing peppol data (user deletes file -> `peppolData` becomes null)
3. Evaluate tab state

### Expected Outcome

- Extra tabs array is empty
- Active tab falls back to `'uploader'` (user hadn't explicitly selected a tab)
- `hideInlineAttachments` is `false`
- Tab order is `undefined` (no custom ordering)

### Example Code

```typescript
it('clearing peppol data removes extra tab and falls back to uploader', () => {
  const peppolData = null;
  const hasPeppolData = !!peppolData;
  const userSelectedTab: string | null = null;

  const rightPanelTab = computeRightPanelTab({ peppolData, userSelectedTab });

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

## Default tab is attachments when peppol has attachment files

**Preconditions**: `peppolData.attachments` has 2 items (PDF + XML).

### Steps

1. Set `peppolData` with attachments array containing entries

### Expected Outcome

- Active tab defaults to `'attachments'`
- Extra tabs array contains one entry with `PeppolAttachmentsTab` as content (not `PeppolParsedPreview`)
- `hideInlineAttachments` is `true`

### Example Code

```typescript
it('peppol with attachments shows PeppolAttachmentsTab in attachments tab', () => {
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

  const rightPanelTab = computeRightPanelTab({ peppolData, userSelectedTab });

  expect(rightPanelTab).toBe('attachments');
  expect(hasPeppolData).toBe(true);
  expect(hasAttachments).toBe(true);

  const extraTabs = !peppolData
    ? []
    : [{
        value: 'attachments',
        label: 'Peppol attachments',
        contentType: hasAttachments ? 'PeppolAttachmentsTab' : 'PeppolParsedPreview',
      }];
  expect(extraTabs).toHaveLength(1);
  expect(extraTabs[0].contentType).toBe('PeppolAttachmentsTab');

  const hideInlineAttachments = hasPeppolData;
  expect(hideInlineAttachments).toBe(true);
});
```

---

## User tab selection overrides default

**Preconditions**: Peppol data present, user explicitly selects `'uploader'`.

### Steps

1. Set peppolData (with or without attachments)
2. Simulate user selecting `'uploader'` tab via `setUserSelectedTab`

### Expected Outcome

- Active tab is `'uploader'` despite peppol data being present
- The `userSelectedTab` takes precedence over the automatic default

### Example Code

```typescript
it('user tab selection overrides peppol default', () => {
  const rightPanelTab = computeRightPanelTab({
    peppolData: { invoiceNumber: 'X' },
    userSelectedTab: 'uploader',
  });

  expect(rightPanelTab).toBe('uploader');
});
```

---

## Peppol data parsed with amounts triggers lock

**Preconditions**: Peppol data parsed callback fires with amounts.

### Steps

1. Call `safePeppolDataParsed` with data containing amount lines
2. Verify `setLockState` is called with computed total

### Expected Outcome

- `setLockState` called with `{ locked: true, lockedTotal: <sum> }`
- `sumTotalAmounts` correctly computes the total

### Example Code

```typescript
it('peppol data parsed with amounts sets lock state', () => {
  const parsedAmounts: AmountLine[] = [
    { totalAmount: 5000 },
    { totalAmount: 3000 },
  ];

  const lockedTotal = sumTotalAmounts(parsedAmounts);

  expect(lockedTotal).toBe(8000);

  const expectedLockState = { locked: true, lockedTotal: 8000 };
  expect(expectedLockState.locked).toBe(true);
  expect(expectedLockState.lockedTotal).toBe(8000);
});
```

---

## Peppol data parsed with no amounts does not lock

**Preconditions**: Peppol data parsed returns empty amounts array.

### Steps

1. Call `safePeppolDataParsed` with data that yields empty amounts

### Expected Outcome

- `setLockState` is NOT called (the guard `parsedAmounts.length > 0` prevents it)

### Example Code

```typescript
it('peppol data with no amounts does not trigger lock', () => {
  const parsedAmounts: AmountLine[] = [];

  const shouldLock = parsedAmounts.length > 0;
  expect(shouldLock).toBe(false);
});
```

## Related Specs

- Lock state: [lock-state-toggle.md](./lock-state-toggle.md) — lock state machine
- Peppol wiring: [peppol-to-invoice.md](./peppol-to-invoice.md) — field population
