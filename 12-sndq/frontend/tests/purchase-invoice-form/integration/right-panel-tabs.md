# Right Panel Tabs

**Status**: Not started
**Priority**: MEDIUM (wrong default tab hides Peppol data from user)
**Test tier**: Integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/right-panel-tabs.test.tsx`
**Component(s) under test**: `InvoiceRightPanelConnected` (internal to `PurchaseInvoiceFormV3.tsx`)

## Purpose

Guard the tab defaulting logic that determines whether users see the file uploader or Peppol data first, and the lock trigger on Peppol parse. These tests render the actual component rather than a synthetic replica, ensuring refactors or deletions are caught.

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
| Default tab is uploader (no peppol) | Uploader tab is active, no peppol tab rendered |
| Peppol without attachments shows PeppolParsedPreview | Attachments tab active, PeppolParsedPreview content visible |
| Peppol cleared removes tab, falls back to uploader | Extra tabs removed, uploader tab active |
| Peppol with attachments shows PeppolAttachmentsTab | Attachments tab active, PeppolAttachmentsTab content visible |
| User tab selection overrides default | User clicks uploader despite peppol → uploader tab stays active |
| Peppol amounts parsed triggers lock (uploader path) | `setLockState({ locked: true, lockedTotal })` called |
| Peppol with no amounts skips lock (uploader path) | `setLockState` NOT called |

## Mocking Strategy

```typescript
// Render InvoiceRightPanelConnected via renderWithProviders.
// Mock handlePeppolDataParsed return value to control parsed amounts.
// Mock setLockState via context overrides to assert lock triggers.
// Use form defaults to inject peppolData into the form context.
```

## Shared Setup

```typescript
import { describe, it, expect, vi } from 'vitest';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '../utils/render-providers';
import { PurchaseInvoiceFormV3 } from '../../PurchaseInvoiceFormV3';
import type { PeppolInvoiceResponse } from '@/common/api/resources/financial/peppolApi';

const basePeppolData: Partial<PeppolInvoiceResponse> = {
  invoiceNumber: 'PEPINV-001',
  supplierParty: { name: 'Test Supplier' },
  lines: [
    {
      id: 'l1',
      name: 'Service A',
      baseQuantity: 1,
      basePrice: 5000,
      quantity: 1,
      vatIncluded: true,
      vatRate: 0.21,
      subtotal: 5000,
      total: 6050,
      currency: 'EUR',
    },
  ],
};
```

**Source reference**: `PurchaseInvoiceFormV3.tsx` lines 171-250

---

## Default tab is uploader when no peppol data

**Preconditions**: No `peppolData` in form context.

### Steps

1. Render `InvoiceRightPanelConnected` without peppolData

### Expected Outcome

- Uploader tab is the active tab (aria-selected)
- No peppol-related tab is rendered
- `hideInlineAttachments` is `false` (uploader shows inline attachments)

### Example Code

```typescript
describe('Right panel tabs', () => {
  it('default tab is uploader when no peppol data', () => {
    renderWithProviders(<PurchaseInvoiceFormV3 />, {
      formDefaults: { peppolData: undefined },
    });

    const uploaderTab = screen.getByRole('tab', { name: /uploader/i });
    expect(uploaderTab).toHaveAttribute('aria-selected', 'true');

    expect(screen.queryByRole('tab', { name: /attachments/i })).not.toBeInTheDocument();
  });
});
```

---

## Default tab is attachments when peppol data exists without attachment files

**Preconditions**: `peppolData` exists but has no attachment files (empty or undefined `attachments` array).

### Steps

1. Render with `peppolData` that has an empty `attachments` array

### Expected Outcome

- Attachments tab defaults to active
- Tab panel shows `PeppolParsedPreview` content (not `PeppolAttachmentsTab`)
- `hideInlineAttachments` is `true` (prevents duplicate rendering in uploader tab)

### Example Code

```typescript
it('peppol data without attachments shows PeppolParsedPreview in attachments tab', () => {
  renderWithProviders(<PurchaseInvoiceFormV3 />, {
    formDefaults: {
      peppolData: { ...basePeppolData, attachments: [] },
    },
  });

  const attachmentsTab = screen.getByRole('tab', { name: /attachments/i });
  expect(attachmentsTab).toHaveAttribute('aria-selected', 'true');

  expect(screen.getByTestId('peppol-parsed-preview')).toBeInTheDocument();
  expect(screen.queryByTestId('peppol-attachments-tab')).not.toBeInTheDocument();
});
```

---

## Peppol data cleared removes extra tab and falls back to uploader

**Preconditions**: User previously uploaded a Peppol XML (tab was showing), then deletes the file.

### Steps

1. Render with `peppolData` set (extra tab exists)
2. Simulate clearing peppol data (user deletes file -> peppolData becomes null)

### Expected Outcome

- Extra tabs removed
- Active tab falls back to `'uploader'`
- No peppol-related tab content visible

### Example Code

```typescript
it('clearing peppol data removes extra tab and falls back to uploader', async () => {
  const { rerender } = renderWithProviders(<PurchaseInvoiceFormV3 />, {
    formDefaults: {
      peppolData: { ...basePeppolData, attachments: [] },
    },
  });

  // Initially attachments tab is active
  expect(screen.getByRole('tab', { name: /attachments/i })).toHaveAttribute(
    'aria-selected',
    'true',
  );

  // Clear peppol data (simulates file deletion)
  rerender(<PurchaseInvoiceFormV3 />, {
    formDefaults: { peppolData: undefined },
  });

  await waitFor(() => {
    const uploaderTab = screen.getByRole('tab', { name: /uploader/i });
    expect(uploaderTab).toHaveAttribute('aria-selected', 'true');
  });

  expect(screen.queryByRole('tab', { name: /attachments/i })).not.toBeInTheDocument();
});
```

---

## Default tab is attachments when peppol has attachment files

**Preconditions**: `peppolData.attachments` has 2 items (PDF + XML).

### Steps

1. Render with `peppolData` that has attachments

### Expected Outcome

- Attachments tab defaults to active
- Tab panel shows `PeppolAttachmentsTab` content (not `PeppolParsedPreview`)
- `hideInlineAttachments` is `true`

### Example Code

```typescript
it('peppol with attachments shows PeppolAttachmentsTab in attachments tab', () => {
  renderWithProviders(<PurchaseInvoiceFormV3 />, {
    formDefaults: {
      peppolData: {
        ...basePeppolData,
        attachments: [
          { filename: 'doc.pdf', mimetype: 'application/pdf' },
          { filename: 'data.xml', mimetype: 'text/xml' },
        ],
      },
    },
  });

  const attachmentsTab = screen.getByRole('tab', { name: /attachments/i });
  expect(attachmentsTab).toHaveAttribute('aria-selected', 'true');

  expect(screen.getByTestId('peppol-attachments-tab')).toBeInTheDocument();
  expect(screen.queryByTestId('peppol-parsed-preview')).not.toBeInTheDocument();
});
```

---

## User tab selection overrides default

**Preconditions**: Peppol data present, user explicitly clicks the `'uploader'` tab.

### Steps

1. Render with peppolData (default tab would be attachments)
2. User clicks the uploader tab

### Expected Outcome

- Active tab switches to `'uploader'` despite peppol data being present
- The `userSelectedTab` takes precedence over the automatic default

### Example Code

```typescript
it('user tab selection overrides peppol default', async () => {
  renderWithProviders(<PurchaseInvoiceFormV3 />, {
    formDefaults: {
      peppolData: { ...basePeppolData, attachments: [] },
    },
  });

  // Default should be attachments
  expect(screen.getByRole('tab', { name: /attachments/i })).toHaveAttribute(
    'aria-selected',
    'true',
  );

  // User clicks uploader tab
  await userEvent.click(screen.getByRole('tab', { name: /uploader/i }));

  expect(screen.getByRole('tab', { name: /uploader/i })).toHaveAttribute(
    'aria-selected',
    'true',
  );
});
```

---

## Peppol amounts parsed triggers lock (uploader path)

**Preconditions**: User uploads a Peppol XML via the uploader tab. `safePeppolDataParsed` is called with data that contains amount lines. This tests the **uploader tab path** (`PurchaseInvoiceFormV3.safePeppolDataParsed`), which has a `parsedAmounts.length > 0` guard before calling `setLockState`.

> **Note:** The inbox path (`PeppolInvoiceSheetRoute.onCreatePurchaseInvoice`) always locks, even at `lockedTotal: 0`. That path is tested in [peppol-to-invoice.md](./peppol-to-invoice.md).

### Steps

1. Render `PurchaseInvoiceFormV3` with a mocked `setLockState` via context overrides
2. Trigger the Peppol upload flow with data that produces amount lines
3. Wait for async `handlePeppolDataParsed` to resolve

### Expected Outcome

- `setLockState` is called with `{ locked: true, lockedTotal: <sum> }` where `<sum>` matches `sumTotalAmounts` of the parsed amounts

### Example Code

```typescript
it('safePeppolDataParsed calls setLockState when amounts are present', async () => {
  const mockSetLockState = vi.fn();

  renderWithProviders(<PurchaseInvoiceFormV3 />, {
    contextOverrides: { setLockState: mockSetLockState },
    formDefaults: { peppolData: undefined },
  });

  // Simulate peppol file upload that triggers safePeppolDataParsed
  // The exact trigger depends on the uploader component wiring
  // (e.g., file input change -> onPeppolParsed callback)
  const fileInput = screen.getByLabelText(/upload/i);
  await userEvent.upload(fileInput, mockPeppolFile);

  await waitFor(() => {
    expect(mockSetLockState).toHaveBeenCalledWith(
      expect.objectContaining({
        locked: true,
        lockedTotal: expect.any(Number),
      }),
    );
  });
});
```

---

## Peppol with no amounts skips lock (uploader path)

**Preconditions**: User uploads a Peppol XML that contains no line items. `safePeppolDataParsed` is called but the guard `parsedAmounts.length > 0` prevents `setLockState` from being called. This tests the **uploader tab path** only.

> **Note:** The inbox path behaves differently — it always locks, even with `lockedTotal: 0`. See `unit/transformPeppolToFormData.md` "Empty amounts from Peppol — no zero-lock".

### Steps

1. Render with a mocked `setLockState`
2. Trigger Peppol upload with data that produces an empty amounts array

### Expected Outcome

- `setLockState` is NOT called (guard: `parsedAmounts.length > 0`)
- Any existing lock state remains unchanged

### Example Code

```typescript
it('safePeppolDataParsed skips setLockState when no amounts', async () => {
  const mockSetLockState = vi.fn();

  renderWithProviders(<PurchaseInvoiceFormV3 />, {
    contextOverrides: { setLockState: mockSetLockState },
    formDefaults: { peppolData: undefined },
  });

  // Upload peppol file that has no line items
  const fileInput = screen.getByLabelText(/upload/i);
  await userEvent.upload(fileInput, mockEmptyPeppolFile);

  // Wait for async processing to complete
  await waitFor(() => {
    expect(screen.getByTestId('peppol-parsed-preview')).toBeInTheDocument();
  });

  expect(mockSetLockState).not.toHaveBeenCalled();
});
```

## Related Specs

- Lock state: [lock-state-toggle.md](./lock-state-toggle.md) — lock state machine
- Peppol wiring: [peppol-to-invoice.md](./peppol-to-invoice.md) — field population
- Pure-logic guards (empty amounts zero-lock, OGM parsing, grouping): see `unit/transformPeppolToFormData.md`
