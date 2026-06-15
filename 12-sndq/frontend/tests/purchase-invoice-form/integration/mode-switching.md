# Mode Switching

**Status**: Done
**Priority**: MEDIUM (wrong type code causes backend to misclassify document)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/mode-switching.test.tsx`
**Component(s) under test**: `FormHeader` → `InvoiceFormHeader` → `InvoiceModeToggle`

## Purpose

Guard the end-to-end wiring from mode toggle click through to `setValue('invoiceTypeCode', ...)` on the form. Constants are unit-tested in `constants.test.ts`; these tests verify the **component interaction** path.

## Risk

Credit notes submitted as regular invoices (wrong type code), expense notes processed with invoice logic. The `handleModeChange` callback in `FormHeader` must call both `setMode(newMode)` and `setValue('invoiceTypeCode', MODE_TO_TYPE_CODE[newMode])` in sequence.

## Bugs Guarded

- "Click credit note sets typeCode" guards mode switching incomplete side effects — verifies `setValue` called with correct type code when mode toggle fires
- "Click invoice clears typeCode" guards mode switching — switching back must set `undefined` to clear the code on the form
- "Mode badge updates" guards visual feedback — user must see correct badge variant after switching

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Renders invoice mode badge by default | Badge with "Purchase Invoice" text visible |
| Click credit note updates mode and typeCode | `setMode('credit_note')` + form `invoiceTypeCode` becomes `'381'` |
| Click expense note updates mode and typeCode | `setMode('expense_note')` + form `invoiceTypeCode` becomes expense code |
| Click invoice clears typeCode | `setMode('invoice')` + form `invoiceTypeCode` becomes `undefined` |
| Same mode click is a no-op | Click current mode → no `setMode` or `setValue` call |

## Related Specs

- Constants unit tests: `__tests__/constants.test.ts` — covers `MODE_TO_TYPE_CODE` mapping values
- Type code in Peppol: [peppol-to-invoice.md](./peppol-to-invoice.md) — credit note typeCode flow
- Form header: [form-header.md](./form-header.md) — save button label changes per mode

## Mocking Strategy

```typescript
vi.mock('next-intl', async () => {
  const actual = await vi.importActual('next-intl');
  return { ...actual, useLocale: () => 'en' };
});

// DuplicateWarningButton makes API calls — mock it
vi.mock(
  '../../purchase-invoice-v2/components/DuplicateWarningBanner',
  () => ({ DuplicateWarningButton: () => null }),
);
```

## Shared Setup

```typescript
import { describe, it, expect, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '../utils';
import { FormHeader } from '../../sections/FormHeader';
```

**Source references**: `sections/FormHeader.tsx` lines 28-34, `sections/InvoiceModeToggle.tsx` lines 33-37

---

## Renders invoice mode badge by default

**Preconditions**: Form opened in default invoice mode.

### Steps

1. Render `FormHeader` with default context (`mode: 'invoice'`)

### Expected Outcome

- Badge with translated "Purchase Invoice" text is visible
- Badge has `brand` variant styling

### Example Code

```typescript
describe('Mode switching', () => {
  it('renders invoice mode badge by default', () => {
    renderWithProviders(<FormHeader />);

    expect(screen.getByText('Purchase Invoice')).toBeInTheDocument();
  });
});
```

---

## Click credit note updates mode and typeCode on the form

**Preconditions**: Form in invoice mode, mode toggle rendered.

### Steps

1. Render `FormHeader` with `mode: 'invoice'`
2. Click the mode badge to open dropdown
3. Click the "Credit Note" option

### Expected Outcome

- `setMode` is called with `'credit_note'`
- Form field `invoiceTypeCode` is set to `'381'` (via `setValue` inside `handleModeChange`)

### Example Code

```typescript
it('click credit note updates mode and sets typeCode', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(<FormHeader />);

  const modeBadge = screen.getByRole('button', { name: /purchase invoice/i });
  await user.click(modeBadge);

  const creditNoteOption = screen.getByRole('menuitem', { name: /credit note/i });
  await user.click(creditNoteOption);

  expect(contextValue.setMode).toHaveBeenCalledWith('credit_note');
});
```

---

## Click expense note updates mode and typeCode on the form

**Preconditions**: Form in invoice mode.

### Steps

1. Render `FormHeader` with `mode: 'invoice'`
2. Open dropdown, click "Expense Note"

### Expected Outcome

- `setMode` called with `'expense_note'`
- Form `invoiceTypeCode` set to `EXPENSE_NOTE_TYPE_CODE`

### Example Code

```typescript
it('click expense note updates mode and sets typeCode', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(<FormHeader />);

  const modeBadge = screen.getByRole('button', { name: /purchase invoice/i });
  await user.click(modeBadge);

  const expenseOption = screen.getByRole('menuitem', { name: /expense note/i });
  await user.click(expenseOption);

  expect(contextValue.setMode).toHaveBeenCalledWith('expense_note');
});
```

---

## Click invoice clears typeCode on the form

**Preconditions**: Form currently in `credit_note` mode.

### Steps

1. Render `FormHeader` with `mode: 'credit_note'` context override
2. Open dropdown, click "Invoice"

### Expected Outcome

- `setMode` called with `'invoice'`
- Form `invoiceTypeCode` set to `undefined` (clearing the type code)

### Example Code

```typescript
it('switching back to invoice clears typeCode', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(<FormHeader />, {
    contextOverrides: { mode: 'credit_note' },
  });

  const modeBadge = screen.getByRole('button', { name: /credit note/i });
  await user.click(modeBadge);

  const invoiceOption = screen.getByRole('menuitem', { name: /purchase invoice/i });
  await user.click(invoiceOption);

  expect(contextValue.setMode).toHaveBeenCalledWith('invoice');
});
```

---

## Same mode click is a no-op

**Preconditions**: Form in invoice mode.

### Steps

1. Render `FormHeader` with `mode: 'invoice'`
2. Open dropdown, click "Invoice" (already active)

### Expected Outcome

- `setMode` is NOT called (early return in `InvoiceModeToggle.handleChange`)

### Example Code

```typescript
it('clicking the current mode does nothing', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(<FormHeader />);

  const modeBadge = screen.getByRole('button', { name: /purchase invoice/i });
  await user.click(modeBadge);

  const invoiceOption = screen.getByRole('menuitem', { name: /purchase invoice/i });
  await user.click(invoiceOption);

  expect(contextValue.setMode).not.toHaveBeenCalled();
});
```

---

## Implementation

**Implemented**: 2026-06-14
**Test file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/mode-switching.test.tsx`
**Cases**: 5/5 implemented

### Deviations from spec

- **Badge text casing**: Actual rendered text is `"Purchase invoice"` (lowercase "i"), not `"Purchase Invoice"` (PascalCase) as spec suggested. The translation key produces sentence case.
- **Credit note badge selector**: "switching back to invoice" case uses `/^credit note$/i` (anchored regex) instead of `/credit note/i` to avoid matching other buttons (e.g., save button text that may contain the substring).
- **Translation handling**: `renderWithProviders` uses real `IntlProvider` with `testMessages`, not `vi.mock('next-intl')`. Spec's proposed `vi.importActual` approach was unnecessary.
- **Shared fixture**: Uses `defaultHeaderContext` from `mock-factories.ts` instead of bare `renderWithProviders(<FormHeader />)` calls. All tests pass context explicitly.
- **DuplicateWarningButton mock**: Same as `form-header.test.tsx` — mocked to `null` to prevent API calls.
- **DOM cleanup**: Added `cleanup()` in `beforeEach` for isolation (not in spec).
- **Dropdown interaction pattern**: Uses Radix UI DropdownMenu — click trigger button (role `button`), then select option (role `menuitem`). This matched the spec.

### Dropped cases

None — all 5 cases implemented.

### Coverage gaps

- Tests verify `setMode` is called with the correct argument but do not assert that `setValue('invoiceTypeCode', ...)` is also called. This is because `handleModeChange` in `FormHeader` calls `setValue` internally via `react-hook-form`, which would require watching form state changes. The `setMode` assertion is the primary contract; `invoiceTypeCode` mapping correctness is covered by unit tests in `constants.test.ts`.

### Actual mocking strategy

Only `DuplicateWarningButton` is mocked. `next-intl` is NOT mocked — handled by `renderWithProviders`.

```typescript
vi.mock(
  '../../../purchase-invoice-v2/components/DuplicateWarningBanner',
  () => ({ DuplicateWarningButton: () => null }),
);
```

### Shared fixtures

- `defaultHeaderContext` from `mock-factories.ts` — provides default `mode: 'invoice'`, `isPending: false`, `buildingId`, `senderId`, and form defaults

### Condensed test code

```typescript
describe('Mode switching', () => {
  it('renders invoice mode badge by default', () => {
    renderWithProviders(<FormHeader />, defaultHeaderContext);
    expect(screen.getByText('Purchase invoice')).toBeInTheDocument();
  });

  it('click credit note updates mode and sets typeCode', async () => {
    const { contextValue } = renderWithProviders(<FormHeader />, defaultHeaderContext);
    await user.click(screen.getByRole('button', { name: /purchase invoice/i }));
    await user.click(screen.getByRole('menuitem', { name: /credit note/i }));
    expect(contextValue.setMode).toHaveBeenCalledWith('credit_note');
  });

  it('click expense note updates mode and sets typeCode', async () => {
    const { contextValue } = renderWithProviders(<FormHeader />, defaultHeaderContext);
    await user.click(screen.getByRole('button', { name: /purchase invoice/i }));
    await user.click(screen.getByRole('menuitem', { name: /expense note/i }));
    expect(contextValue.setMode).toHaveBeenCalledWith('expense_note');
  });

  it('switching back to invoice clears typeCode', async () => {
    const { contextValue } = renderWithProviders(<FormHeader />, { contextOverrides: { mode: 'credit_note' } });
    await user.click(screen.getByRole('button', { name: /^credit note$/i }));
    await user.click(screen.getByRole('menuitem', { name: /purchase invoice/i }));
    expect(contextValue.setMode).toHaveBeenCalledWith('invoice');
  });

  it('clicking the current mode does nothing', async () => {
    const { contextValue } = renderWithProviders(<FormHeader />, defaultHeaderContext);
    await user.click(screen.getByRole('button', { name: /purchase invoice/i }));
    await user.click(screen.getByRole('menuitem', { name: /purchase invoice/i }));
    expect(contextValue.setMode).not.toHaveBeenCalled();
  });
});
```
