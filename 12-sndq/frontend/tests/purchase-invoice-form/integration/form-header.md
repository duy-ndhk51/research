# Form Header

**Status**: Not started
**Priority**: MEDIUM (primary user action zone -- save, total, lock, mode toggle)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/form-header.test.tsx`
**Component(s) under test**: `FormHeader` from `sections/FormHeader.tsx`, `InvoiceFormHeader` from `sections/InvoiceFormHeader.tsx`

## Purpose

Verify the header bar that shows save/submit button states, total amount display, lock indicator, mode toggle, and draft status. This is the primary user action zone.

## Risk

Save button stays enabled during submission (double-submit), total displays stale value, mode toggle doesn't propagate type code change.

## Bugs Guarded

- Save button enabled when form is valid / Save button disabled during submission guard **B9** (draft save skips lock validation) -- save must be disabled while `isPending`; draft vs full submit have different validation paths
- Total amount shows computed sum guards **B12** (footer masks mismatch) -- total in header must use live sum (not `lockedTotal`) to prevent user confusion
- Lock icon shows when locked / Lock icon hidden when unlocked guard **B1** (lock state vs form amounts) -- lock indicator must reflect actual `lockState.locked`; icon mismatch causes user to edit locked amounts
- Mode toggle calls setMode guards **B2** (mode switching) -- mode toggle must call `setMode` which triggers `handleModeChange`; side effects include type code + `originalInvoiceId` management

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Save button enabled when form is valid | Button not disabled, no aria-disabled |
| Save button disabled during submission | `isPending: true` -> button disabled + spinner |
| Total amount shows computed sum | 2 lines totaling 15000 -> displays "150.00" |
| Lock icon shows when locked | `lockState.locked: true` -> lock icon visible |
| Lock icon hidden when unlocked | `lockState.locked: false` -> lock icon not in document |
| Draft badge visible for drafts | `isDraft: true` -> badge with "Draft" text |

## Related Specs

- Lock state: [lock-state-toggle.md](./lock-state-toggle.md) — lock state machine
- Mode switching: [mode-switching.md](./mode-switching.md) — full mode toggle tests (setMode + invoiceTypeCode)
- Invoice lines footer: [invoice-lines-table.md](./invoice-lines-table.md) — footer total/lock

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
import { FormHeader } from '../../sections/FormHeader';

const defaultProps = {
  contextOverrides: { isPending: false },
  formDefaults: {
    buildingId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    senderId: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
  },
};

beforeEach(() => {
  vi.clearAllMocks();
});
```

---

## Save button enabled when form is valid

**Preconditions**: Form has valid building + supplier, not pending.

### Steps

1. Render `<FormHeader />` with `isPending: false` and valid form defaults

### Expected Outcome

- Save button is not disabled

### Example Code

```typescript
describe('FormHeader', () => {
  it('should enable save button when form is valid', () => {
    renderWithProviders(<FormHeader />, {
      ...defaultProps,
    });

    expect(screen.getByRole('button', { name: /save/i })).not.toBeDisabled();
  });
});
```

---

## Save button disabled during submission

**Preconditions**: `isPending: true`.

### Steps

1. Render `<FormHeader />` with `isPending: true`

### Expected Outcome

- Save button is disabled

### Example Code

```typescript
it('should disable save button during submission', () => {
  renderWithProviders(<FormHeader />, {
    contextOverrides: { isPending: true },
  });

  expect(screen.getByRole('button', { name: /save/i })).toBeDisabled();
});
```

---

## Total amount shows computed sum

**Preconditions**: Form with 2 amount lines totaling 15000 cents.

### Steps

1. Render with 2 lines (totalAmount: 10000, totalAmount: 5000)

### Expected Outcome

- Header displays formatted total (e.g. "150.00")

### Example Code

```typescript
it('total amount shows computed sum from form amounts', () => {
  renderWithProviders(<FormHeader />, {
    formDefaults: {
      ...defaultProps.formDefaults,
      amounts: [
        { id: 'l1', totalAmount: 10000 },
        { id: 'l2', totalAmount: 5000 },
      ],
    },
  });

  expect(screen.getByText(/150/)).toBeVisible();
});
```

---

## Lock icon shows when locked

**Preconditions**: `lockState.locked: true`.

### Steps

1. Render with locked state

### Expected Outcome

- Lock icon is visible in the header

### Example Code

```typescript
it('lock icon shows when locked', () => {
  renderWithProviders(<FormHeader />, {
    ...defaultProps,
    contextOverrides: {
      ...defaultProps.contextOverrides,
      lockState: { locked: true, lockedTotal: 12100 },
    },
  });

  const lockButton = screen.getByRole('button', { name: /lock/i });
  expect(lockButton).toBeVisible();
});
```

---

## Lock icon hidden when unlocked

**Preconditions**: `lockState.locked: false`.

### Steps

1. Render with unlocked state

### Expected Outcome

- Lock icon is not in the document (or shows unlock variant)

### Example Code

```typescript
it('lock icon hidden when unlocked', () => {
  renderWithProviders(<FormHeader />, {
    ...defaultProps,
    contextOverrides: {
      ...defaultProps.contextOverrides,
      lockState: { locked: false },
    },
  });

  expect(screen.queryByRole('button', { name: /unlock/i })).not.toBeInTheDocument();
});
```

---

## Draft badge visible for drafts

**Preconditions**: `isDraft: true`.

### Steps

1. Render with `isDraft: true`

### Expected Outcome

- Badge with "Draft" text is visible

### Example Code

```typescript
it('draft badge visible for drafts', () => {
  renderWithProviders(<FormHeader />, {
    ...defaultProps,
    contextOverrides: {
      ...defaultProps.contextOverrides,
      isDraft: true,
    },
  });

  expect(screen.getByText(/draft/i)).toBeVisible();
});
```

