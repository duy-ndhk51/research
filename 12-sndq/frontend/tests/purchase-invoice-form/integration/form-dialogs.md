# Form Dialogs

**Status**: Not started
**Priority**: MEDIUM (gates irreversible operations -- discard, delete draft, merge)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/form-dialogs.test.tsx`
**Component(s) under test**: `FormDialogs` from `sections/FormDialogs.tsx`

## Purpose

Verify the confirmation dialog lifecycle for destructive actions: discard changes, delete **draft** invoice, and merge grouping strategy. These dialogs gate irreversible operations.

## Risk

Discard fires without user confirmation (data loss), delete proceeds on non-draft invoice or without loading guard (double-delete), merge dialog uses stale amounts.

## Bugs Guarded

- Discard dialog hidden by default / opens when triggered / confirm calls handleDiscard guard dialog gate -- destructive action must require explicit confirmation; bypass causes instant data loss
- Delete draft dialog shows loading during deletion guards loading state -- button must be disabled during async delete to prevent double-fire; `isDeleting` state controls UI; delete action only available when `invoiceId && isDraft` (see `useComboActions.ts` line 32)
- Delete action hidden when not a draft guards draft-only visibility -- delete action must not appear for non-draft invoices
- Merge dialog shows when strategy changes guards **B7** (grouping stale snapshot) -- merge dialog must open before applying grouping change; `originalAmountsRef` captured on leave must be fresh

## Scenarios

| Test Name | Expected Outcome |
|-----------|-------------------|
| Discard dialog hidden by default | `showDiscardDialog: false` -> dialog not in document |
| Discard dialog opens when triggered | `showDiscardDialog: true` -> dialog visible |
| Discard confirm calls handleDiscard | Click confirm -> `handleDiscard` called once |
| Delete draft dialog shows loading during deletion | `isDraft: true`, `isDeleting: true` -> confirm button disabled + spinner |
| Delete action hidden when not a draft | `isDraft: false` -> delete dialog trigger absent |
| Merge dialog shows when strategy changes | `mergeDialog.open: true` -> dialog visible with merge options |

## Related Specs

- Form orchestration: [form-orchestration.md](./form-orchestration.md) — onClose wiring
- Invoice lines: [invoice-lines-table.md](./invoice-lines-table.md) — grouping merge

## Mocking Strategy

```typescript
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));
```

## Shared Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '../utils';
import { FormDialogs } from '../../sections/FormDialogs';
import type { useSheetState } from '../../hooks/useSheetState';

type SheetState = ReturnType<typeof useSheetState>;

const baseSheetState: SheetState = {
  showDiscardDialog: false,
  setShowDiscardDialog: vi.fn(),
  showDeleteDialog: false,
  setShowDeleteDialog: vi.fn(),
  handleSheetClose: vi.fn(),
  handleRequestDiscard: vi.fn(),
  openPreview: vi.fn(),
  closePreview: vi.fn(),
  closeSubSheet: vi.fn(),
  previewFile: null,
  showSupplierDetail: false,
  openSupplierDetail: vi.fn(),
  closeSupplierDetail: vi.fn(),
  openInvoiceSplit: vi.fn(),
  subSheet: { type: 'none' as const },
  amountsPreviewOpen: false,
  openAmountsPreview: vi.fn(),
  closeAmountsPreview: vi.fn(),
  mergeDialog: {
    open: false,
    pendingStrategy: null,
    onConfirm: vi.fn(),
    onCancel: vi.fn(),
  },
  setMergeDialog: vi.fn(),
};

beforeEach(() => {
  vi.clearAllMocks();
});
```

---

## Discard dialog hidden by default

**Preconditions**: No dialog triggers active.

### Steps

1. Render `<FormDialogs />` with `showDiscardDialog: false`, `showDeleteDialog: false`

### Expected Outcome

- No `alertdialog` element in the document

### Example Code

```typescript
describe('FormDialogs', () => {
  it('should not render discard dialog by default', () => {
    renderWithProviders(<FormDialogs />, {
      contextOverrides: {
        sheetState: { ...baseSheetState },
      },
    });

    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument();
  });
});
```

---

## Discard dialog opens when triggered

**Preconditions**: `showDiscardDialog: true`.

### Steps

1. Render `<FormDialogs />` with `showDiscardDialog: true`

### Expected Outcome

- `alertdialog` element is in the document
- Dialog contains "discard" text

### Example Code

```typescript
it('should show discard dialog when triggered', () => {
  renderWithProviders(<FormDialogs />, {
    contextOverrides: {
      sheetState: { ...baseSheetState, showDiscardDialog: true },
    },
  });

  expect(screen.getByRole('alertdialog')).toBeInTheDocument();
  expect(screen.getByText(/discard/i)).toBeInTheDocument();
});
```

---

## Discard confirm calls handleDiscard

**Preconditions**: Discard dialog is open.

### Steps

1. Render with `showDiscardDialog: true`
2. Click the confirm button

### Expected Outcome

- `handleDiscard` called exactly once

### Example Code

```typescript
it('should call handleDiscard on confirm', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(<FormDialogs />, {
    contextOverrides: {
      sheetState: { ...baseSheetState, showDiscardDialog: true },
    },
  });

  await user.click(screen.getByRole('button', { name: /confirm/i }));

  expect(contextValue.handleDiscard).toHaveBeenCalledTimes(1);
});
```

---

## Delete draft dialog shows loading during deletion

**Preconditions**: Invoice is a draft (`invoiceId` set, `isDraft: true`). Delete dialog open. `isDeleting: true`.

### Steps

1. Render with `showDeleteDialog: true`, `invoiceId: 'inv-123'`, `isDraft: true`, `isDeleting: true`

### Expected Outcome

- Delete dialog is visible
- Confirm button is disabled (loading state)

### Example Code

```typescript
it('delete draft dialog shows loading during deletion', () => {
  renderWithProviders(<FormDialogs />, {
    contextOverrides: {
      invoiceId: 'inv-123',
      isDraft: true,
      isDeleting: true,
      sheetState: { ...baseSheetState, showDeleteDialog: true },
    },
  });

  expect(screen.getByRole('alertdialog')).toBeInTheDocument();

  const confirmButton = screen.getByRole('button', { name: /delete|confirm/i });
  expect(confirmButton).toBeDisabled();
});
```

---

## Delete action hidden when not a draft

**Preconditions**: Invoice exists but is NOT a draft (`invoiceId` set, `isDraft: false`).

### Steps

1. Render with `invoiceId: 'inv-123'`, `isDraft: false`
2. Check that no delete dialog trigger is present

### Expected Outcome

- Delete dialog is not in the document
- The combo actions from `useComboActions` do not include a delete action (the condition `invoiceId && isDraft` is false)

### Example Code

```typescript
it('delete action hidden when not a draft', () => {
  renderWithProviders(<FormDialogs />, {
    contextOverrides: {
      invoiceId: 'inv-123',
      isDraft: false,
      sheetState: { ...baseSheetState },
    },
  });

  expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument();
  expect(screen.queryByText(/delete/i)).not.toBeInTheDocument();
});
```

---

## Merge dialog shows when strategy changes

**Preconditions**: `mergeDialog.open: true` with a pending strategy.

### Steps

1. Render with `mergeDialog.open: true`

### Expected Outcome

- Merge dialog is visible with merge options

### Example Code

```typescript
it('merge dialog shows when strategy changes', () => {
  renderWithProviders(<FormDialogs />, {
    contextOverrides: {
      sheetState: {
        ...baseSheetState,
        mergeDialog: {
          open: true,
          pendingStrategy: 'ALL',
          onConfirm: vi.fn(),
          onCancel: vi.fn(),
        },
      },
    },
  });

  expect(screen.getByRole('alertdialog')).toBeInTheDocument();
});
```
