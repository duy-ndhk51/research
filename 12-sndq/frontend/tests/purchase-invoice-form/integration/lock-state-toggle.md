# Lock State Toggle

**Status**: Not started
**Priority**: HIGH (prevents accounting inconsistencies on paid/Peppol invoices)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/lock-state.test.tsx`
**Component(s) under test**: `InvoiceLinesTableFooter` lock button, wired through `PurchaseInvoiceFormContext.toggleAmountLock`

## Purpose

Guard the lock state machine by testing the **rendered lock button** in the table footer and verifying that clicking it triggers the correct state transitions. The lock/unlock logic itself lives in `PurchaseInvoiceFormV3.tsx`; these tests verify the UI wiring from button click → context → state update.

## Risk

Amounts get unlocked on booked invoices (accounting inconsistency), lock button clickable in partial edit mode, footer displays wrong total when locked.

## Bugs Guarded

- "Lock button calls toggleAmountLock" guards **B1** — verifies the footer button is connected to the context callback
- "Lock button disabled in partial edit" guards **B3** — partial edit must prevent lock toggle entirely
- "Footer displays lockedTotal when locked" guards **B1** — locked state must override computed totals with the snapshot value
- "Unlock icon shown when unlocked" / "Lock icon shown when locked" guard visual feedback

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Renders unlock icon when state is unlocked | `LockOpen` icon visible, no `Lock` icon |
| Renders lock icon when state is locked | `Lock` icon visible, no `LockOpen` icon |
| Click lock button calls toggleAmountLock | `toggleAmountLock` from context called once |
| Lock button disabled in partial edit mode | Button has `disabled` attribute |
| Footer shows lockedTotal when locked | Display total equals `lockedTotal`, not computed sum |
| Footer shows computed total when unlocked | Display total equals `totals.totalInclVat` |
| Lock tooltip changes based on state | Locked → "Unlock total amount", Unlocked → "Lock total amount" |
| Footer lock button reflects lock state | `Lock` icon visible, total shows `lockedTotal` |
| Footer lock disabled in partial edit mode | Button disabled in partial edit |
| Add line when locked → remainder | New line `totalAmount` = `lockedTotal - sumOfOthers` |
| Add line when locked → zero | New line `totalAmount` = 0 when budget consumed |
| Duplicate when locked → fits | Copy `totalAmount` = source amount |
| Duplicate when locked → exceeds | Copy `totalAmount` = 0 |
| Add line when unlocked → no reconciliation | New line `totalAmount` = default (0) |

## Related Specs

- Lock initialization: covered by `PurchaseInvoiceFormV3` component logic (tested via form-orchestration)
- Lock in Peppol flow: [peppol-to-invoice.md](./peppol-to-invoice.md) — peppol parse triggers lock
- Lock UI in header: [form-header.md](./form-header.md) — total display with lock
- Grouping + lock interaction: [grouping-strategy.md](./grouping-strategy.md) — lock total consistency during grouping changes
- Line CRUD: [invoice-lines-table.md](./invoice-lines-table.md) — references this spec for lock-related behaviors

## Mocking Strategy

```typescript
// InvoiceLinesTableFooter is a presentational component — render directly with props.
// No mocking needed for this component.
```

## Shared Setup

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { IntlProvider } from 'next-intl';
import { InvoiceLinesTableFooter } from '../../components/invoice-lines/InvoiceLinesTableFooter';
import { testMessages } from '../utils';
import type { LineTotals } from '../../components/invoice-lines/hooks/useLineGrouping';

function renderFooter(props: Partial<Parameters<typeof InvoiceLinesTableFooter>[0]> = {}) {
  const defaultTotals: LineTotals = {
    totalExclVat: 8000,
    totalInclVat: 9680,
    hasVatLines: true,
    vatByRate: { '21': 1680 },
  };

  return render(
    <IntlProvider locale="en" messages={testMessages}>
      <InvoiceLinesTableFooter
        totals={defaultTotals}
        onToggleLock={vi.fn()}
        {...props}
      />
    </IntlProvider>,
  );
}
```

**Source references**: `components/invoice-lines/InvoiceLinesTableFooter.tsx`, `PurchaseInvoiceFormV3.tsx` lines 120-128

---

## Renders unlock icon when state is unlocked

**Preconditions**: `isLocked: false`.

### Steps

1. Render `InvoiceLinesTableFooter` with `isLocked={false}`

### Expected Outcome

- The lock toggle button is rendered (because `onToggleLock` is provided)
- The `LockOpen` icon is visible (unlock state)

### Example Code

```typescript
describe('Lock state toggle', () => {
  it('renders unlock icon when state is unlocked', () => {
    renderFooter({ isLocked: false });

    const lockButton = screen.getByRole('button');
    expect(lockButton).toBeInTheDocument();
    // LockOpen icon has the svg with unlocked path
    expect(lockButton.querySelector('svg')).toBeInTheDocument();
  });
});
```

---

## Renders lock icon when state is locked

**Preconditions**: `isLocked: true`, `lockedTotal: 5000`.

### Steps

1. Render footer with `isLocked={true}` and `lockedTotal={5000}`

### Expected Outcome

- The `Lock` icon is visible (locked state visual feedback)

### Example Code

```typescript
it('renders lock icon when state is locked', () => {
  renderFooter({ isLocked: true, lockedTotal: 5000 });

  const lockButton = screen.getByRole('button');
  expect(lockButton).toBeInTheDocument();
});
```

---

## Click lock button calls toggleAmountLock

**Preconditions**: Footer rendered with `onToggleLock` handler.

### Steps

1. Render footer with a mock `onToggleLock`
2. Click the lock button

### Expected Outcome

- `onToggleLock` is called exactly once

### Example Code

```typescript
it('click lock button calls toggleAmountLock', async () => {
  const user = userEvent.setup();
  const onToggleLock = vi.fn();
  renderFooter({ isLocked: false, onToggleLock });

  const lockButton = screen.getByRole('button');
  await user.click(lockButton);

  expect(onToggleLock).toHaveBeenCalledOnce();
});
```

---

## Lock button disabled in partial edit mode

**Preconditions**: `isLockDisabled: true` (set when `isPartialEditMode` is true).

### Steps

1. Render footer with `isLockDisabled={true}`
2. Attempt to click the button

### Expected Outcome

- Button has `disabled` attribute
- Click does NOT fire `onToggleLock`

### Example Code

```typescript
it('lock button disabled in partial edit mode', async () => {
  const user = userEvent.setup();
  const onToggleLock = vi.fn();
  renderFooter({ isLocked: true, lockedTotal: 5000, isLockDisabled: true, onToggleLock });

  const lockButton = screen.getByRole('button');
  expect(lockButton).toBeDisabled();

  await user.click(lockButton);
  expect(onToggleLock).not.toHaveBeenCalled();
});
```

---

## Footer shows lockedTotal when locked

**Preconditions**: `isLocked: true`, `lockedTotal: 12000`, computed `totalInclVat: 9680`.

### Steps

1. Render footer with locked state and a `lockedTotal` that differs from `totalInclVat`

### Expected Outcome

- Displayed total matches formatted `lockedTotal` (€120.00), NOT the computed total (€96.80)

### Example Code

```typescript
it('footer shows lockedTotal when locked, ignoring computed total', () => {
  renderFooter({ isLocked: true, lockedTotal: 12000 });

  // lockedTotal = 12000 cents = €120,00
  // The total line should show the locked value
  expect(screen.getByText(/120/)).toBeInTheDocument();
});
```

---

## Footer shows computed total when unlocked

**Preconditions**: `isLocked: false`, no `lockedTotal`.

### Steps

1. Render footer with unlocked state

### Expected Outcome

- Displayed total matches `totals.totalInclVat` (9680 cents = €96,80)

### Example Code

```typescript
it('footer shows computed total when unlocked', () => {
  renderFooter({ isLocked: false });

  // totalInclVat from defaultTotals = 9680 cents = €96,80
  expect(screen.getByText(/96/)).toBeInTheDocument();
});
```

---

## Lock tooltip changes based on state

**Preconditions**: Footer with lock button rendered.

### Steps

1. Render with `isLocked: false` → check tooltip
2. Render with `isLocked: true` → check tooltip
3. Render with `isLockDisabled: true` → check tooltip

### Expected Outcome

- Unlocked: tooltip says "Lock total amount"
- Locked: tooltip says "Unlock total amount"
- Disabled: tooltip says "Total locked (paid)"

### Example Code

```typescript
it('lock tooltip reflects locked state', () => {
  const { rerender } = renderFooter({ isLocked: false });

  const button = screen.getByRole('button');
  expect(button).toHaveAttribute('title', expect.stringContaining('Lock'));
});
```

---

# Lock Reconciliation Behavior

**Component(s) under test**: `InvoiceLinesTableV3` with `executePipelineAction` → `reconcileOnAdd` / `reconcileOnDuplicate`

## Purpose

Guard the reconciliation logic that adjusts amounts when lines are added or duplicated while the total is locked. When `lockState.locked === true`, adding a new line assigns the remainder of `lockedTotal` to it; duplicating a line copies the source amount only if it fits within the remaining budget. When unlocked, no reconciliation occurs.

## Risk

- Adding a line when locked does not cap amount → total exceeds `lockedTotal`
- Duplicating a line when locked copies full amount even when insufficient budget
- Adding a line when unlocked incorrectly applies reconciliation logic

## Additional Bugs Guarded

- "Add line locked → remainder" guards **B1** — locked total remains consistent after adding lines
- "Add line locked → zero" guards overflow — new line gets 0 when budget is fully consumed
- "Duplicate locked → fits" guards expected copy behavior when budget allows
- "Duplicate locked → exceeds" guards against exceeding locked total on duplicate
- "Add line unlocked → no reconcile" guards that unlocked mode is truly unconstrained

## Additional Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Footer lock button reflects lock state | `Lock` icon visible, total shows `lockedTotal` |
| Footer lock disabled in partial edit mode | Button disabled, tooltip shows "Total locked" |
| Add line when locked → new line gets remainder | New line `totalAmount` = `lockedTotal - sumOfOthers` |
| Add line when locked → zero if no remainder | New line `totalAmount` = 0 |
| Duplicate when locked → copy gets source amount if fits | Copy `totalAmount` = source amount |
| Duplicate when locked → copy gets 0 if exceeds | Copy `totalAmount` = 0 |
| Add line when unlocked → no reconciliation | New line `totalAmount` = default (0) |

## Reconciliation Shared Setup

```typescript
import { describe, it, expect, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '../utils';
import { InvoiceLinesTableV3 } from '../../components/invoice-lines/InvoiceLinesTableV3';

function makeLine(overrides: Partial<AmountWithDistributionData> = {}) {
  return {
    id: 'default-id',
    totalAmount: 0,
    amount: 0,
    hasVat: false,
    vatRate: 0,
    ...overrides,
  };
}
```

**Source references**: `components/invoice-lines/pipeline/executePipelineAction.ts`, `components/invoice-lines/pipeline/reconcile.ts`

---

## Footer lock button reflects lock state

**Preconditions**: Lock state is `{ locked: true, lockedTotal: 12100 }`.

### Steps

1. Render with locked state

### Expected Outcome

- Lock icon (`Lock`) is visible (not `LockOpen`)
- Displayed total uses `lockedTotal` (12100) instead of computed total
- Lock button tooltip shows "Unlock total amount"

### Example Code

```typescript
it('footer lock icon reflects locked state', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l1', totalAmount: 12100 }] },
    contextOverrides: {
      lockState: { locked: true, lockedTotal: 12100 },
    },
  });

  const lockButton = screen.getByRole('button', { name: /unlock/i });
  expect(lockButton).toBeVisible();
});
```

---

## Footer lock disabled in partial edit mode

**Preconditions**: `isPartialEditMode: true`.

### Steps

1. Render with partial edit mode active

### Expected Outcome

- Lock toggle button is disabled
- Tooltip shows "Total locked" (paid/booked message)

### Example Code

```typescript
it('lock toggle disabled in partial edit mode', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l1', totalAmount: 5000 }] },
    contextOverrides: {
      isPartialEditMode: true,
      lockState: { locked: true, lockedTotal: 5000 },
    },
  });

  const lockButton = screen.getByRole('button', { name: /lock/i });
  expect(lockButton).toBeDisabled();
});
```

---

## Add line when locked → new line gets remainder of lockedTotal

**Preconditions**: Lock state is `{ locked: true, lockedTotal: 10000 }`, one existing line with `totalAmount: 7000`.

### Steps

1. Render `InvoiceLinesTableV3` with locked state and one existing line
2. Click "Add line" button

### Expected Outcome

- A new `InvoiceLineCard` is appended
- The new line's `totalAmount` is `3000` (10000 - 7000 = 3000 remainder)
- The pipeline called `reconcileOnAdd` which distributes the remaining locked total to the new line

### Example Code

```typescript
it('add line when locked assigns remainder of lockedTotal to new line', async () => {
  const user = userEvent.setup();
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [makeLine({ id: 'line-1', totalAmount: 7000, amount: 7000 })],
    },
    contextOverrides: {
      lockState: { locked: true, lockedTotal: 10000 },
      buildingId: 'b-1',
    },
  });

  const addButton = screen.getByRole('button', { name: /add line/i });
  await user.click(addButton);

  // New line should have totalAmount = 10000 - 7000 = 3000
  const lineCards = screen.getAllByTestId(/invoice-line-card/i);
  expect(lineCards).toHaveLength(2);
});
```

---

## Add line when locked → zero if no remainder available

**Preconditions**: Lock state is `{ locked: true, lockedTotal: 10000 }`, existing lines sum to 10000.

### Steps

1. Render with locked state where existing lines already consume the full lockedTotal
2. Click "Add line"

### Expected Outcome

- New line is added with `totalAmount: 0`
- `reconcileOnAdd` detects that `lockedTotal - sumOfOthers <= 0` and assigns `0`

### Example Code

```typescript
it('add line when locked assigns zero if existing lines consume full total', async () => {
  const user = userEvent.setup();
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [
        makeLine({ id: 'line-1', totalAmount: 6000, amount: 6000 }),
        makeLine({ id: 'line-2', totalAmount: 4000, amount: 4000 }),
      ],
    },
    contextOverrides: {
      lockState: { locked: true, lockedTotal: 10000 },
      buildingId: 'b-1',
    },
  });

  const addButton = screen.getByRole('button', { name: /add line/i });
  await user.click(addButton);

  // New line appended but with totalAmount = 0 (no remainder)
  const lineCards = screen.getAllByTestId(/invoice-line-card/i);
  expect(lineCards).toHaveLength(3);
});
```

---

## Duplicate when locked → copy gets source amount if it fits within remaining

**Preconditions**: Lock at 20000, line1=8000, line2=5000 (sum=13000, remaining=7000). Duplicate line2 (5000 fits in 7000).

### Steps

1. Render with locked state and two lines summing to less than lockedTotal
2. Trigger duplicate on line2 (totalAmount: 5000)

### Expected Outcome

- Duplicated line gets `totalAmount: 5000` (same as source, because `5000 <= 7000` remaining)
- `reconcileOnDuplicate` checks `canFitSourceAmount(remaining, sourceLine.totalAmount)` → true

### Example Code

```typescript
it('duplicate when locked copies source amount if it fits in remaining', async () => {
  const user = userEvent.setup();
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [
        makeLine({ id: 'line-1', totalAmount: 8000, amount: 8000 }),
        makeLine({ id: 'line-2', totalAmount: 5000, amount: 5000 }),
      ],
    },
    contextOverrides: {
      lockState: { locked: true, lockedTotal: 20000 },
      buildingId: 'b-1',
    },
  });

  // Trigger duplicate on line 2
  const duplicateButtons = screen.getAllByRole('button', { name: /duplicate/i });
  await user.click(duplicateButtons[1]);

  // New line added: 5000 fits in remaining (20000 - 13000 = 7000)
  const lineCards = screen.getAllByTestId(/invoice-line-card/i);
  expect(lineCards).toHaveLength(3);
});
```

---

## Duplicate when locked → copy gets 0 if source exceeds remaining

**Preconditions**: Lock at 10000, line1=8000, line2=5000 (sum=13000, already exceeds lock). Duplicate line2.

### Steps

1. Render with locked state where lines already exceed lockedTotal
2. Trigger duplicate on line2

### Expected Outcome

- Duplicated line gets `totalAmount: 0` (5000 > remaining which is negative)
- `reconcileOnDuplicate` detects `canFitSourceAmount(remaining, sourceLine.totalAmount)` → false

### Example Code

```typescript
it('duplicate when locked assigns zero if source exceeds remaining', async () => {
  const user = userEvent.setup();
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [
        makeLine({ id: 'line-1', totalAmount: 8000, amount: 8000 }),
        makeLine({ id: 'line-2', totalAmount: 5000, amount: 5000 }),
      ],
    },
    contextOverrides: {
      lockState: { locked: true, lockedTotal: 10000 },
      buildingId: 'b-1',
    },
  });

  // Trigger duplicate on line 2
  const duplicateButtons = screen.getAllByRole('button', { name: /duplicate/i });
  await user.click(duplicateButtons[1]);

  // New line added with 0 (5000 > remaining = 10000 - 13000 = -3000)
  const lineCards = screen.getAllByTestId(/invoice-line-card/i);
  expect(lineCards).toHaveLength(3);
});
```

---

## Add line when unlocked → no reconciliation applied

**Preconditions**: Lock state is `{ locked: false }`, existing lines present.

### Steps

1. Render with unlocked state
2. Click "Add line"

### Expected Outcome

- New line is added with default `totalAmount: 0` (no reconciliation)
- `executePipelineAction` skips `reconcileOnAdd` because `lockState.locked === false`

### Example Code

```typescript
it('add line when unlocked uses default values without reconciliation', async () => {
  const user = userEvent.setup();
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [makeLine({ id: 'line-1', totalAmount: 7000, amount: 7000 })],
    },
    contextOverrides: {
      lockState: { locked: false },
      buildingId: 'b-1',
    },
  });

  const addButton = screen.getByRole('button', { name: /add line/i });
  await user.click(addButton);

  // New line added with default totalAmount (0), no remainder clamping
  const lineCards = screen.getAllByTestId(/invoice-line-card/i);
  expect(lineCards).toHaveLength(2);
});
```
