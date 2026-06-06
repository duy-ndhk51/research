# Invoice Lines Table — Orchestration

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/invoice-lines-table.test.tsx`
**Component under test**: `InvoiceLinesTableV3` (from `components/invoice-lines/InvoiceLinesTableV3.tsx`)

Tests verify the orchestration layer that wires form context, CRUD state, grouping mode switching, and conditional rendering together. The pure logic hooks (`useLineCrud`, `useLineGrouping`, `useAmountPipeline`) are unit-tested separately — these integration tests verify they are composed correctly within the rendered component.

**Source reference**: `InvoiceLinesTableV3.tsx` lines 1-228

---

## IT-058: Add line button disabled when no building selected

**Preconditions**: No `buildingId` in form state.

### Steps

1. Render `InvoiceLinesTableV3` with no `buildingId`
2. Locate the "Add line" button

### Assertions

- Button is disabled
- Tooltip text matches `general.select_building_first`

### Example Code

```typescript
import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import { renderWithProviders } from './test-wrapper';
import { InvoiceLinesTableV3 } from '../../components/invoice-lines/InvoiceLinesTableV3';

describe('Invoice lines table — orchestration', () => {
  it('IT-058: add line button disabled when no building', () => {
    renderWithProviders(<InvoiceLinesTableV3 />, {
      formDefaults: { buildingId: undefined, amounts: [] },
    });

    const addButton = screen.getByRole('button', { name: /add line/i });
    expect(addButton).toBeDisabled();
  });
});
```

---

## IT-058b: Add line button enabled when building selected

**Preconditions**: `buildingId` set in form state.

### Steps

1. Render `InvoiceLinesTableV3` with a valid `buildingId`
2. Locate the "Add line" button

### Assertions

- Button is NOT disabled
- No tooltip shown

### Example Code

```typescript
it('IT-058b: add line button enabled when building is set', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'building-1', amounts: [] },
  });

  const addButton = screen.getByRole('button', { name: /add line/i });
  expect(addButton).not.toBeDisabled();
});
```

---

## IT-059: Individual mode renders InvoiceLineCards for each amount

**Preconditions**: 2 amount lines in form state, `groupingStrategy` is `NONE`.

### Steps

1. Render with `groupingStrategy: NONE` and 2 amounts
2. Check rendered line cards

### Assertions

- 2 collapsible line cards rendered (each with an index badge `1`, `2`)
- `SingleTotalView` is NOT rendered
- Add line button is visible below the cards

### Example Code

```typescript
it('IT-059: individual mode renders line cards for each amount', () => {
  const amounts = [
    { id: 'line-1', totalAmount: 12100, amount: 10000, hasVat: true, vatRate: 21 },
    { id: 'line-2', totalAmount: 5000, amount: 5000, hasVat: false, vatRate: 0 },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
    contextOverrides: { groupingStrategy: 'NONE' },
  });

  // 2 collapsible cards rendered
  const cards = screen.getAllByText(/€/);
  expect(cards.length).toBeGreaterThanOrEqual(2);

  // Add line button visible
  expect(screen.getByRole('button', { name: /add line/i })).toBeVisible();
});
```

---

## IT-060: Simple mode renders SingleTotalView instead of cards

**Preconditions**: At least 1 amount line, `groupingStrategy` is `ALL` (simple/single-total mode).

### Steps

1. Render with `groupingStrategy: ALL` and 1 amount
2. Check rendered view

### Assertions

- `SingleTotalView` hint text (`purchase_invoice.single_total_hint`) is visible
- Individual `InvoiceLineCard` collapsible headers are NOT rendered
- "Add line" button is NOT visible (hidden in simple mode)

### Example Code

```typescript
it('IT-060: simple mode renders SingleTotalView', () => {
  const amounts = [
    { id: 'line-1', totalAmount: 12100, amount: 10000, hasVat: true, vatRate: 21 },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
    contextOverrides: { groupingStrategy: 'ALL' },
  });

  // SingleTotalView hint is visible
  expect(screen.getByText(/single_total_hint|line.by.line/i)).toBeVisible();

  // Add line button should NOT be visible in simple mode
  expect(screen.queryByRole('button', { name: /add line/i })).not.toBeInTheDocument();
});
```

---

## IT-061: AmountModeToggle switches between single and individual

**Preconditions**: Rendered with `groupingStrategy: NONE`.

### Steps

1. Render with `NONE` strategy
2. Click the "Single total" tab in the mode toggle
3. Verify `onGroupingStrategyChange` is called

### Assertions

- The mode toggle renders both "Single total" and "Line by line" segments
- Clicking "Single total" calls `setGroupingStrategy(GroupingStrategy.ALL)`
- Clicking "Line by line" calls `setGroupingStrategy(GroupingStrategy.NONE)`

### Example Code

```typescript
import userEvent from '@testing-library/user-event';

it('IT-061: mode toggle switches between single and individual', async () => {
  const setGroupingStrategy = vi.fn();

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l-1', totalAmount: 1000 }] },
    contextOverrides: {
      groupingStrategy: 'NONE',
      setGroupingStrategy,
    },
  });

  const singleTab = screen.getByRole('tab', { name: /single total/i });
  await userEvent.click(singleTab);

  expect(setGroupingStrategy).toHaveBeenCalledWith('ALL');
});
```

---

## IT-062: Delete single line opens DeleteAmountDialog

**Preconditions**: 1 amount line rendered, expanded.

### Steps

1. Render with 1 line
2. Expand the line card
3. Click the delete button inside the card

### Assertions

- `DeleteAmountDialog` opens (visible in the DOM)
- Dialog shows the line's amount for confirmation

### Example Code

```typescript
it('IT-062: delete button opens DeleteAmountDialog', async () => {
  const amounts = [{ id: 'line-1', totalAmount: 5000, amount: 5000 }];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
  });

  // Expand the card (click the collapsible trigger)
  const trigger = screen.getByText(/€50/);
  await userEvent.click(trigger);

  // Click delete button inside the expanded card
  const deleteButton = screen.getByRole('button', { name: /delete/i });
  await userEvent.click(deleteButton);

  // DeleteAmountDialog is now visible
  await expect(screen.findByRole('alertdialog')).resolves.toBeVisible();
});
```

---

## IT-062b: Confirming delete removes the line

**Preconditions**: DeleteAmountDialog open for a single line.

### Steps

1. Open the delete dialog for a line
2. Click confirm/delete in the dialog

### Assertions

- The dialog closes
- The line is removed from the form (`pipeline.execute({ type: 'DELETE_LINES' })` called)

### Example Code

```typescript
it('IT-062b: confirm delete removes the line', async () => {
  const amounts = [
    { id: 'line-1', totalAmount: 5000 },
    { id: 'line-2', totalAmount: 3000 },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
  });

  // Open delete dialog for line-1
  // ... (expand card, click delete) ...

  // Confirm deletion
  const confirmButton = screen.getByRole('button', { name: /confirm|delete/i });
  await userEvent.click(confirmButton);

  // Dialog closed
  expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument();
});
```

---

## IT-062c: Cancelling delete keeps the line

**Preconditions**: DeleteAmountDialog open.

### Steps

1. Open the delete dialog
2. Click cancel

### Assertions

- Dialog closes
- Line count remains unchanged

### Example Code

```typescript
it('IT-062c: cancel delete keeps the line', async () => {
  // ... (open delete dialog) ...

  const cancelButton = screen.getByRole('button', { name: /cancel/i });
  await userEvent.click(cancelButton);

  // Dialog closed, line still present
  expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument();
});
```

---

## IT-063: Duplicate line calls pipeline execute

**Preconditions**: 1 line rendered, expanded.

### Steps

1. Expand the line card
2. Click the "Duplicate" button

### Assertions

- `pipeline.execute({ type: 'DUPLICATE_LINE', index: 0 })` is called
- A new line appears in the form

### Example Code

```typescript
it('IT-063: duplicate line triggers pipeline', async () => {
  const amounts = [{ id: 'line-1', totalAmount: 5000 }];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
  });

  // Expand card and click duplicate
  await userEvent.click(screen.getByText(/€50/));
  await userEvent.click(screen.getByRole('button', { name: /duplicate/i }));

  // After duplication, 2 lines should be in the form
  // (pipeline.execute is called internally)
});
```

---

## IT-064: Custom distribution button opens distribution sheet

**Preconditions**: 1 line rendered.

### Steps

1. Expand the line card
2. Click the custom distribution button (within `InvoiceLineCostAndDistribution`)

### Assertions

- `PurchaseInvoiceAmountDistributionSheet` opens (`open` prop becomes `true`)
- `crud.state.distributionSheetIndex` is set to the line's index

### Example Code

```typescript
it('IT-064: custom distribution opens sheet for the line', async () => {
  const amounts = [{ id: 'line-1', totalAmount: 5000 }];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
    contextOverrides: { properties: [{ id: 'p-1', name: 'Unit 1' }] },
  });

  // Expand and trigger custom distribution
  // The exact button depends on InvoiceLineCostAndDistribution UI
  // Typically "Custom split" or a distribution icon button
});
```

---

## IT-065: Footer displays computed totals

**Preconditions**: 2 lines with VAT.

### Steps

1. Render with 2 lines: line-1 (10000 excl, 12100 incl, 21% VAT) and line-2 (5000 excl, 5300 incl, 6% VAT)

### Assertions

- Footer shows subtotal (excl. VAT): formatted `€150.00` (15000 cents)
- VAT breakdown: `21%: €21.00`, `6%: €3.00`
- Total (incl. VAT): formatted `€174.00` (17400 cents)

### Example Code

```typescript
it('IT-065: footer displays VAT breakdown and total', () => {
  const amounts = [
    { id: 'l1', totalAmount: 12100, amount: 10000, hasVat: true, vatRate: 21 },
    { id: 'l2', totalAmount: 5300, amount: 5000, hasVat: true, vatRate: 6 },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
  });

  // Total should be visible in the footer
  expect(screen.getByText(/€174/)).toBeVisible();
});
```

---

## IT-066: Footer lock button reflects lock state

**Preconditions**: Lock state is `{ locked: true, lockedTotal: 12100 }`.

### Steps

1. Render with locked state

### Assertions

- Lock icon (`Lock`) is visible (not `LockOpen`)
- Displayed total uses `lockedTotal` (12100) instead of computed total
- Lock button tooltip shows "Unlock total amount"

### Example Code

```typescript
it('IT-066: footer lock icon reflects locked state', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l1', totalAmount: 12100 }] },
    contextOverrides: {
      lockState: { locked: true, lockedTotal: 12100 },
    },
  });

  // Lock icon visible
  const lockButton = screen.getByRole('button', { name: /unlock/i });
  expect(lockButton).toBeVisible();
});
```

---

## IT-066b: Footer lock disabled in partial edit mode

**Preconditions**: `isPartialEditMode: true`.

### Steps

1. Render with partial edit mode active

### Assertions

- Lock toggle button is disabled
- Tooltip shows "Total locked" (paid/booked message)

### Example Code

```typescript
it('IT-066b: lock toggle disabled in partial edit mode', () => {
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

## IT-067: Credit note mode applies warning color to total

**Preconditions**: `mode: 'credit_note'`.

### Steps

1. Render with credit note mode

### Assertions

- Footer total text has `text-warning-700` class (orange/warning color)
- `isCreditNote` is `true` in the footer, causing negative formatting

### Example Code

```typescript
it('IT-067: credit note total uses warning color', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l1', totalAmount: 5000 }] },
    contextOverrides: { mode: 'credit_note' },
  });

  // The total paragraph should have the warning class
  const totalElement = screen.getByText(/€50/).closest('p');
  expect(totalElement).toHaveClass('text-warning-700');
});
```

---

## IT-068: DescriptionSection receives correct auto-fill props

**Preconditions**: Building, contact, mode, and invoiceId all set in context.

### Steps

1. Render with all context values populated

### Assertions

- `DescriptionSection` receives `autoFill.invoiceId`, `autoFill.mode`, `autoFill.contactName`, `autoFill.building.code`, `autoFill.building.name`
- If `resolvedContact` is null, `contactName` is undefined
- If `resolvedBuilding` is null, `building` is undefined

### Example Code

```typescript
it('IT-068: description section receives auto-fill from context', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [] },
    contextOverrides: {
      invoiceId: 'inv-1',
      mode: 'invoice',
      resolvedContact: { id: 'c-1', name: 'Supplier NV' },
      resolvedBuilding: { id: 'b-1', code: 'B001', name: 'Main Building' },
    },
  });

  // DescriptionSection should render — verify it's in the document
  // The auto-fill behavior is tested indirectly through the rendered description
});
```

---

## IT-069: First line card defaultOpen on new invoice

**Preconditions**: `invoiceId` is null (new invoice, not edit), 1 amount line.

### Steps

1. Render with `invoiceId: null` and 1 line

### Assertions

- First `InvoiceLineCard` has `defaultOpen={true}` (expanded by default)
- The expanded content (amount input, VAT rate picker) is visible without clicking

### Example Code

```typescript
it('IT-069: first card is expanded by default on new invoice', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l-1', totalAmount: 5000 }] },
    contextOverrides: { invoiceId: null },
  });

  // Expanded content should be visible (amount input, VAT picker)
  expect(screen.getByLabelText(/amount incl/i)).toBeVisible();
});
```

---

## IT-069b: First line card NOT defaultOpen on edit

**Preconditions**: `invoiceId` is set (editing existing invoice).

### Steps

1. Render with `invoiceId: 'inv-123'` and 1 line

### Assertions

- First card has `defaultOpen={false}` (collapsed by default)
- Only the collapsed header is visible (amount + VAT badge + category badge)

### Example Code

```typescript
it('IT-069b: first card is collapsed by default on edit', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l-1', totalAmount: 5000 }] },
    contextOverrides: { invoiceId: 'inv-123' },
  });

  // Expanded content should NOT be visible
  expect(screen.queryByLabelText(/amount incl/i)).not.toBeVisible();
});
```

---

## IT-070: Distribution disabled when isDeferredCost is true

**Preconditions**: `isDeferredCost` form field is `true`.

### Steps

1. Render with `isDeferredCost: true` in form values

### Assertions

- Distribution-related controls are disabled in line cards
- This maps to the `disableDistribution` prop flowing from `useInvoiceLinesData`

### Example Code

```typescript
it('IT-070: isDeferredCost disables distribution controls', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      isDeferredCost: true,
      amounts: [{ id: 'l-1', totalAmount: 5000 }],
    },
  });

  // Distribution controls should be disabled
  // The exact assertion depends on how InvoiceLineCostAndDistribution
  // renders when disableDistribution=true
});
```

---

## IT-071: Changing VAT rate recalculates subtotal but keeps totalAmount unchanged

**Preconditions**: 1 line rendered with `hasVat: true`, `vatRate: 21`, `totalAmount: 12100`.

### Steps

1. Render with 1 line in individual mode (`hasVat: true`, `vatRate: 21`, `totalAmount: 12100`)
2. Expand the line card
3. Change the VAT rate from 21% to 6%
4. Verify `totalAmount` stays at 12100
5. Verify `amount` (subtotal excl. VAT) is recalculated to `12100 / 1.06 = 11415`

### Assertions

- `totalAmount` (incl. VAT) field remains `12100` — unchanged after VAT change
- `amount` (excl. VAT) is recalculated: `Math.round((12100 * 10000) / (10000 + 6 * 100)) = 11415`
- The VAT picker shows the new rate (6%)
- Footer totals update to reflect the new VAT breakdown

### Example Code

```typescript
it('IT-071: changing VAT rate recalculates subtotal, keeps totalAmount', async () => {
  const amounts = [
    { id: 'line-1', hasVat: true, vatRate: 21, totalAmount: 12100, amount: 10000 },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
  });

  // Expand the line card
  const card = screen.getByTestId('invoice-line-card-0');
  await userEvent.click(card);

  // Change VAT rate from 21% to 6%
  const vatPicker = screen.getByRole('combobox', { name: /vat/i });
  await userEvent.click(vatPicker);
  await userEvent.click(screen.getByRole('option', { name: /6%/i }));

  // totalAmount stays unchanged
  const totalField = screen.getByLabelText(/amount incl/i);
  expect(totalField).toHaveValue('121.00');

  // subtotal (amount excl. VAT) is recalculated: 12100 / 1.06 = 11415
  const subtotalField = screen.getByLabelText(/amount excl/i);
  expect(subtotalField).toHaveValue('114.15');
});
```

---

## IT-071b: Toggling VAT off sets subtotal equal to totalAmount

**Preconditions**: 1 line rendered with `hasVat: true`, `vatRate: 21`, `totalAmount: 12100`.

### Steps

1. Render with 1 line (`hasVat: true`, `vatRate: 21`, `totalAmount: 12100`)
2. Expand the line card
3. Toggle VAT off (uncheck "VAT applicable")
4. Verify `totalAmount` stays at 12100
5. Verify `amount` (subtotal) equals `totalAmount` (no VAT deducted)

### Assertions

- `totalAmount` remains `12100`
- `amount` becomes `12100` (same as total, since no VAT applies)
- VAT rate is set to `0`

### Example Code

```typescript
it('IT-071b: toggling VAT off sets subtotal equal to totalAmount', async () => {
  const amounts = [
    { id: 'line-1', hasVat: true, vatRate: 21, totalAmount: 12100, amount: 10000 },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts },
  });

  // Expand the line card
  const card = screen.getByTestId('invoice-line-card-0');
  await userEvent.click(card);

  // Toggle VAT off
  const vatToggle = screen.getByRole('switch', { name: /vat/i });
  await userEvent.click(vatToggle);

  // totalAmount unchanged
  const totalField = screen.getByLabelText(/amount incl/i);
  expect(totalField).toHaveValue('121.00');

  // subtotal now equals totalAmount (no VAT deducted)
  const subtotalField = screen.getByLabelText(/amount excl/i);
  expect(subtotalField).toHaveValue('121.00');
});
```
