# Invoice Lines Table

**Status**: Not started
**Priority**: HIGH (core invoice data entry, amount calculation bugs cause accounting errors)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/invoice-lines-table.test.tsx`
**Component(s) under test**: `InvoiceLinesTableV3` from `components/invoice-lines/InvoiceLinesTableV3.tsx`

## Purpose

Guard the `InvoiceLinesTableV3` orchestration wiring: CRUD operations, grouping mode toggle, and conditional rendering based on form context. Lock enforcement and reconciliation are covered in [lock-state-toggle.md](./lock-state-toggle.md); grouping transitions are covered in [grouping-strategy.md](./grouping-strategy.md).

## Risk

Add line possible without building, wrong view rendered for grouping mode, delete not wired, distribution sheet doesn't open, footer shows wrong totals, first card collapsed on new invoice.

## Bugs Guarded

- **Add line disabled (no building)** / **Add line enabled (building set)** guard **B11** (building change effect re-runs) -- building selection must trigger `useBuildingChangeEffect` correctly; add-line gate depends on `!!buildingId`
- **Mode toggle switches strategy** guards **B7/B8** (grouping stale snapshot / totals) -- mode toggle calls `setGroupingStrategy`; full grouping lifecycle in [grouping-strategy.md](./grouping-strategy.md)
- **Footer shows VAT breakdown + total** guards **B12** (footer masks mismatch) -- footer must display correct totals; lock-related display in [lock-state-toggle.md](./lock-state-toggle.md)
- **Lock & reconciliation behavior** moved to [lock-state-toggle.md](./lock-state-toggle.md) — guards B1 (lock state vs form amounts) and B3 (partial edit boundary)
- **VAT rate change keeps totalAmount** / **VAT toggle off equalizes amounts** guard integer math -- VAT rate change keeps `totalAmount` fixed, recalculates `amount`; pipeline must use `Decimal.js` to avoid floating-point drift
- **Rounding edge cases** are covered in dedicated unit tests (`unit/amountCalculationRounding.md`) -- `calculateSubtotalFromTotal` (reverse) and `calculatePurchaseInvoiceAmount` (forward) use different rounding paths; for certain amount/vatRate combinations the round-trip can drift by ±1 cent
- **Period input** guards the `PeriodExpandableSection` lifecycle -- period button visibility, toggle on/off, `CLEAR_PERIOD` dispatch, pre-initialization from `fromDate`, and forced display for metered invoices (`METERED_SERVICES_INVOICE`)
- **Inline cost/distribution** guards the `InvoiceLineCostAndDistribution` wiring -- ledger select → `SET_LEDGER` updates `costAccount`; distribution key select → `APPLY_DISTRIBUTION_KEY` sets `distributionKeyId`/`units`; distribute equally → `DISTRIBUTE_EQUALLY` splits across properties; allocate later → `ALLOCATE_LATER` clears distribution fields; display label reflects current method

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Add line disabled (no building) | Button disabled with tooltip |
| Add line enabled (building set) | Button enabled |
| Individual mode renders line cards | 2 `InvoiceLineCard`s rendered |
| Simple mode renders SingleTotalView | `SingleTotalView` shown, no cards/add button |
| Single delete opens dialog | `DeleteAmountDialog` opens |
| Confirm delete removes line | Dialog closes, line removed |
| Cancel delete keeps line | Dialog closes, line unchanged |
| Duplicate triggers pipeline | `pipeline.execute(DUPLICATE_LINE)` called |
| Custom distribution opens sheet | Sheet opens with line index |
| Footer shows VAT breakdown + total | Subtotal, per-rate VAT, total displayed |
| Credit note warning color | Total has `text-warning-700` |
| Description auto-fill props | Correct auto-fill from context |
| First card expanded on new invoice | `defaultOpen` on first card |
| First card collapsed on edit | First card collapsed |
| isDeferredCost disables distribution | Distribution controls disabled |
| VAT rate change keeps totalAmount | Subtotal recalculated, totalAmount unchanged |
| VAT toggle off equalizes amounts | Subtotal = totalAmount |
| Period button visible when no fromDate | Line with no `fromDate` → "Period" button visible in action bar |
| Click period button shows PeriodExpandableSection | Click → section appears with preset select + date pickers |
| Period pre-shown when line has fromDate | Line with `fromDate: '2026-01-01'` → section already visible, no button |
| Remove period clears dates and hides section | Click remove → `fromDate`/`toDate` cleared, button reappears |
| Metered invoice always shows period + meter | `invoiceTypeCode: METERED_SERVICES_INVOICE` → section visible + required, meter select shown |
| Select ledger updates line costAccount | Open dropdown, click ledger → `line.costAccount` populated with id/code/name |
| Select distribution key applies key and recalculates units | Open distribution select, click a key → `line.distributionKeyId` set, `line.useDistributionKey: true`, `line.units` recalculated |
| Distribute equally splits amount across properties | Click "Distribute equally" → `line.distributionType: 'share'`, units have equal shares |
| Allocate later clears distribution | Click "Allocate later" → `line.distributionKeyId: undefined`, `line.units: []` |
| Distribution select label reflects current method | `distributionKeyId` set → label shows key name; `distributionType: 'share'` → shows "Equal split" |

## Related Specs

- Distribution sheet: [amount-distribution-sheet.md](./amount-distribution-sheet.md) — sheet lifecycle
- Lock state & reconciliation: [lock-state-toggle.md](./lock-state-toggle.md) — footer lock UI, lock disabled in partial edit, and reconciliation behavior during add/duplicate
- Grouping strategy: [grouping-strategy.md](./grouping-strategy.md) — mode toggle (single/individual switching), save/restore originals, merge conflicts
- Supplier defaults: [supplier-defaults.md](./supplier-defaults.md) — add line defaults
- Mode switching: [mode-switching.md](./mode-switching.md) — credit note styling

## Mocking Strategy

```typescript
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));

vi.mock('../components/invoice-lines/pipeline', () => ({
  sumTotalAmounts: vi.fn((amounts: Array<{ totalAmount: number }>) =>
    amounts.reduce((sum, a) => sum + (a.totalAmount ?? 0), 0),
  ),
}));
```

## Shared Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '../utils';
import { InvoiceLinesTableV3 } from '../../components/invoice-lines/InvoiceLinesTableV3';
import type { AmountWithDistributionData } from '../../../purchase-invoice-v2/schema';

const makeLine = (overrides: Partial<AmountWithDistributionData> = {}) => ({
  id: `line-${Math.random().toString(36).slice(2, 6)}`,
  totalAmount: 12100,
  amount: 10000,
  hasVat: true,
  vatRate: 21,
  ...overrides,
});

beforeEach(() => {
  vi.clearAllMocks();
});
```

**Source reference**: `InvoiceLinesTableV3.tsx` lines 1-228

---

## Add line button disabled when no building selected

**Preconditions**: No `buildingId` in form state.

### Steps

1. Render `InvoiceLinesTableV3` with no `buildingId`
2. Locate the "Add line" button

### Expected Outcome

- Button is disabled
- Tooltip text matches `general.select_building_first`

### Example Code

```typescript
import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import { renderWithProviders } from './test-wrapper';
import { InvoiceLinesTableV3 } from '../../components/invoice-lines/InvoiceLinesTableV3';

describe('Invoice lines table — orchestration', () => {
  it('add line button disabled when no building', () => {
    renderWithProviders(<InvoiceLinesTableV3 />, {
      formDefaults: { buildingId: undefined, amounts: [] },
    });

    const addButton = screen.getByRole('button', { name: /add line/i });
    expect(addButton).toBeDisabled();
  });
});
```

---

## Add line button enabled when building selected

**Preconditions**: `buildingId` set in form state.

### Steps

1. Render `InvoiceLinesTableV3` with a valid `buildingId`
2. Locate the "Add line" button

### Expected Outcome

- Button is NOT disabled
- No tooltip shown

### Example Code

```typescript
it('add line button enabled when building is set', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'building-1', amounts: [] },
  });

  const addButton = screen.getByRole('button', { name: /add line/i });
  expect(addButton).not.toBeDisabled();
});
```

---

## Individual mode renders InvoiceLineCards for each amount

**Preconditions**: 2 amount lines in form state, `groupingStrategy` is `NONE`.

### Steps

1. Render with `groupingStrategy: NONE` and 2 amounts
2. Check rendered line cards

### Expected Outcome

- 2 collapsible line cards rendered (each with an index badge `1`, `2`)
- `SingleTotalView` is NOT rendered
- Add line button is visible below the cards

### Example Code

```typescript
it('individual mode renders line cards for each amount', () => {
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

## Simple mode renders SingleTotalView instead of cards

**Preconditions**: At least 1 amount line, `groupingStrategy` is `ALL` (simple/single-total mode).

### Steps

1. Render with `groupingStrategy: ALL` and 1 amount
2. Check rendered view

### Expected Outcome

- `SingleTotalView` hint text (`purchase_invoice.single_total_hint`) is visible
- Individual `InvoiceLineCard` collapsible headers are NOT rendered
- "Add line" button is NOT visible (hidden in simple mode)

### Example Code

```typescript
it('simple mode renders SingleTotalView', () => {
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

## Delete single line opens DeleteAmountDialog

**Preconditions**: 1 amount line rendered, expanded.

### Steps

1. Render with 1 line
2. Expand the line card
3. Click the delete button inside the card

### Expected Outcome

- `DeleteAmountDialog` opens (visible in the DOM)
- Dialog shows the line's amount for confirmation

### Example Code

```typescript
it('delete button opens DeleteAmountDialog', async () => {
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

## Confirming delete removes the line

**Preconditions**: DeleteAmountDialog open for a single line.

### Steps

1. Open the delete dialog for a line
2. Click confirm/delete in the dialog

### Expected Outcome

- The dialog closes
- The line is removed from the form (`pipeline.execute({ type: 'DELETE_LINES' })` called)

### Example Code

```typescript
it('confirm delete removes the line', async () => {
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

## Cancelling delete keeps the line

**Preconditions**: DeleteAmountDialog open.

### Steps

1. Open the delete dialog
2. Click cancel

### Expected Outcome

- Dialog closes
- Line count remains unchanged

### Example Code

```typescript
it('cancel delete keeps the line', async () => {
  // ... (open delete dialog) ...

  const cancelButton = screen.getByRole('button', { name: /cancel/i });
  await userEvent.click(cancelButton);

  // Dialog closed, line still present
  expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument();
});
```

---

## Duplicate line calls pipeline execute

**Preconditions**: 1 line rendered, expanded.

### Steps

1. Expand the line card
2. Click the "Duplicate" button

### Expected Outcome

- `pipeline.execute({ type: 'DUPLICATE_LINE', index: 0 })` is called
- A new line appears in the form

### Example Code

```typescript
it('duplicate line triggers pipeline', async () => {
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

## Custom distribution button opens distribution sheet

**Preconditions**: 1 line rendered.

### Steps

1. Expand the line card
2. Click the custom distribution button (within `InvoiceLineCostAndDistribution`)

### Expected Outcome

- `PurchaseInvoiceAmountDistributionSheet` opens (`open` prop becomes `true`)
- `crud.state.distributionSheetIndex` is set to the line's index

### Example Code

```typescript
it('custom distribution opens sheet for the line', async () => {
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

## Footer displays computed totals

**Preconditions**: 2 lines with VAT.

### Steps

1. Render with 2 lines: line-1 (10000 excl, 12100 incl, 21% VAT) and line-2 (5000 excl, 5300 incl, 6% VAT)

### Expected Outcome

- Footer shows subtotal (excl. VAT): formatted `€150.00` (15000 cents)
- VAT breakdown: `21%: €21.00`, `6%: €3.00`
- Total (incl. VAT): formatted `€174.00` (17400 cents)

### Example Code

```typescript
it('footer displays VAT breakdown and total', () => {
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

## Credit note mode applies warning color to total

**Preconditions**: `mode: 'credit_note'`.

### Steps

1. Render with credit note mode

### Expected Outcome

- Footer total text has `text-warning-700` class (orange/warning color)
- `isCreditNote` is `true` in the footer, causing negative formatting

### Example Code

```typescript
it('credit note total uses warning color', () => {
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

## DescriptionSection receives correct auto-fill props

**Preconditions**: Building, contact, mode, and invoiceId all set in context.

### Steps

1. Render with all context values populated

### Expected Outcome

- `DescriptionSection` receives `autoFill.invoiceId`, `autoFill.mode`, `autoFill.contactName`, `autoFill.building.code`, `autoFill.building.name`
- If `resolvedContact` is null, `contactName` is undefined
- If `resolvedBuilding` is null, `building` is undefined

### Example Code

```typescript
it('description section receives auto-fill from context', () => {
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

## First line card defaultOpen on new invoice

**Preconditions**: `invoiceId` is null (new invoice, not edit), 1 amount line.

### Steps

1. Render with `invoiceId: null` and 1 line

### Expected Outcome

- First `InvoiceLineCard` has `defaultOpen={true}` (expanded by default)
- The expanded content (amount input, VAT rate picker) is visible without clicking

### Example Code

```typescript
it('first card is expanded by default on new invoice', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l-1', totalAmount: 5000 }] },
    contextOverrides: { invoiceId: null },
  });

  // Expanded content should be visible (amount input, VAT picker)
  expect(screen.getByLabelText(/amount incl/i)).toBeVisible();
});
```

---

## First line card NOT defaultOpen on edit

**Preconditions**: `invoiceId` is set (editing existing invoice).

### Steps

1. Render with `invoiceId: 'inv-123'` and 1 line

### Expected Outcome

- First card has `defaultOpen={false}` (collapsed by default)
- Only the collapsed header is visible (amount + VAT badge + category badge)

### Example Code

```typescript
it('first card is collapsed by default on edit', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: { buildingId: 'b-1', amounts: [{ id: 'l-1', totalAmount: 5000 }] },
    contextOverrides: { invoiceId: 'inv-123' },
  });

  // Expanded content should NOT be visible
  expect(screen.queryByLabelText(/amount incl/i)).not.toBeVisible();
});
```

---

## Distribution disabled when isDeferredCost is true

**Preconditions**: `isDeferredCost` form field is `true`.

### Steps

1. Render with `isDeferredCost: true` in form values

### Expected Outcome

- Distribution-related controls are disabled in line cards
- This maps to the `disableDistribution` prop flowing from `useInvoiceLinesData`

### Example Code

```typescript
it('isDeferredCost disables distribution controls', () => {
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

## Changing VAT rate recalculates subtotal but keeps totalAmount unchanged

**Preconditions**: 1 line rendered with `hasVat: true`, `vatRate: 21`, `totalAmount: 12100`.

### Steps

1. Render with 1 line in individual mode (`hasVat: true`, `vatRate: 21`, `totalAmount: 12100`)
2. Expand the line card
3. Change the VAT rate from 21% to 6%
4. Verify `totalAmount` stays at 12100
5. Verify `amount` (subtotal excl. VAT) is recalculated to `12100 / 1.06 = 11415`

### Expected Outcome

- `totalAmount` (incl. VAT) field remains `12100` — unchanged after VAT change
- `amount` (excl. VAT) is recalculated: `Math.round((12100 * 10000) / (10000 + 6 * 100)) = 11415`
- The VAT picker shows the new rate (6%)
- Footer totals update to reflect the new VAT breakdown

### Example Code

```typescript
it('changing VAT rate recalculates subtotal, keeps totalAmount', async () => {
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

## Toggling VAT off sets subtotal equal to totalAmount

**Preconditions**: 1 line rendered with `hasVat: true`, `vatRate: 21`, `totalAmount: 12100`.

### Steps

1. Render with 1 line (`hasVat: true`, `vatRate: 21`, `totalAmount: 12100`)
2. Expand the line card
3. Toggle VAT off (uncheck "VAT applicable")
4. Verify `totalAmount` stays at 12100
5. Verify `amount` (subtotal) equals `totalAmount` (no VAT deducted)

### Expected Outcome

- `totalAmount` remains `12100`
- `amount` becomes `12100` (same as total, since no VAT applies)
- VAT rate is set to `0`

### Example Code

```typescript
it('toggling VAT off sets subtotal equal to totalAmount', async () => {
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

---

# Period Input

**Component(s) under test**: `InvoiceLineCard` → `PeriodExpandableSection` from `components/invoice-lines/PeriodExpandableSection.tsx`

## Purpose

Guard the period section lifecycle within each invoice line card: toggle visibility, date assignment via presets, manual removal, and forced visibility for metered invoices. The `showPeriod` UI state is initialized from `!!values.fromDate` and toggled via `handleAddPeriod` / `handleRemovePeriod`.

## Additional Bugs Guarded

- "Period button visible" guards discoverability — users must be able to add a period when none exists
- "Click shows section" guards the `SHOW_PERIOD` dispatch wiring — button must trigger the expandable section
- "Pre-shown when fromDate exists" guards initialization — editing an invoice with existing period must show the section immediately
- "Remove clears dates" guards the `CLEAR_PERIOD` dispatch — removing period must zero out `fromDate`/`toDate` on form state
- "Metered always shows" guards regulatory compliance — metered services invoices require period fields and meter selection

---

## Period button visible when no fromDate

**Preconditions**: Line rendered with no `fromDate` in form data.

### Steps

1. Render `InvoiceLinesTableV3` with a line that has no `fromDate`
2. Expand the line card

### Expected Outcome

- "Period" button is visible in the action bar (alongside Duplicate and Delete)
- `PeriodExpandableSection` is NOT rendered

### Example Code

```typescript
it('period button visible when line has no fromDate', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [makeLine({ id: 'line-1', totalAmount: 5000, amount: 5000 })],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null, // new invoice → first card expanded
    },
  });

  // Period button should be visible in the action bar
  expect(screen.getByRole('button', { name: /period/i })).toBeVisible();

  // Period section should NOT be rendered
  expect(screen.queryByLabelText(/from date/i)).not.toBeInTheDocument();
});
```

---

## Click period button shows PeriodExpandableSection

**Preconditions**: Line with no `fromDate`, card expanded.

### Steps

1. Render with expanded card (new invoice)
2. Click the "Period" button

### Expected Outcome

- `PeriodExpandableSection` appears with preset select and date pickers
- "Period" button disappears from the action bar (only shown when `!showPeriod`)

### Example Code

```typescript
it('clicking period button renders PeriodExpandableSection', async () => {
  const user = userEvent.setup();

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [makeLine({ id: 'line-1', totalAmount: 5000, amount: 5000 })],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
    },
  });

  const periodButton = screen.getByRole('button', { name: /period/i });
  await user.click(periodButton);

  // Period section now rendered (preset select visible)
  expect(screen.getByText(/custom|quarter|month/i)).toBeInTheDocument();

  // Period button no longer in action bar
  expect(screen.queryByRole('button', { name: /^period$/i })).not.toBeInTheDocument();
});
```

---

## Period pre-shown when line has fromDate

**Preconditions**: Line rendered with `fromDate: '2026-01-01'`, `toDate: '2026-03-31'`.

### Steps

1. Render with a line that has existing period dates

### Expected Outcome

- `PeriodExpandableSection` is already visible (initialized from `!!values.fromDate`)
- "Period" button is NOT in the action bar
- Date pickers show the existing values

### Example Code

```typescript
it('period section pre-shown when line has existing fromDate', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [
        makeLine({
          id: 'line-1',
          totalAmount: 5000,
          amount: 5000,
          fromDate: '2026-01-01',
          toDate: '2026-03-31',
        }),
      ],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
    },
  });

  // Period section already visible
  expect(screen.getByText(/custom|quarter|month/i)).toBeInTheDocument();

  // Period button NOT shown (already expanded)
  expect(screen.queryByRole('button', { name: /^period$/i })).not.toBeInTheDocument();
});
```

---

## Remove period clears dates and hides section

**Preconditions**: Line with period section visible.

### Steps

1. Render with a line that has `fromDate`
2. Click the remove/close button in the period section

### Expected Outcome

- `PeriodExpandableSection` disappears
- `dispatch({ type: 'CLEAR_PERIOD' })` fires → `fromDate` and `toDate` cleared in form state
- "Period" button reappears in the action bar

### Example Code

```typescript
it('removing period clears dates and shows period button again', async () => {
  const user = userEvent.setup();

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [
        makeLine({
          id: 'line-1',
          totalAmount: 5000,
          amount: 5000,
          fromDate: '2026-01-01',
          toDate: '2026-03-31',
        }),
      ],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
    },
  });

  // Period section visible initially
  expect(screen.getByText(/custom|quarter|month/i)).toBeInTheDocument();

  // Click the remove button (trash/X icon within period section)
  const removeButton = screen.getByRole('button', { name: /remove.*period|close/i });
  await user.click(removeButton);

  // Period section hidden
  expect(screen.queryByText(/custom|quarter|month/i)).not.toBeInTheDocument();

  // Period button reappears
  expect(screen.getByRole('button', { name: /period/i })).toBeVisible();
});
```

---

## Metered invoice always shows period + meter

**Preconditions**: `invoiceTypeCode` is `METERED_SERVICES_INVOICE` (e.g. `'751'`), line has no `fromDate`.

### Steps

1. Render with metered invoice type code and a line without `fromDate`

### Expected Outcome

- `PeriodExpandableSection` is rendered regardless of `fromDate` (forced by `isMeteredInvoice`)
- Period section has `required={true}` (visual required indicator)
- `MeterSelect` component is visible (only for metered invoices)
- "Period" button is NOT in the action bar (section already forced)

### Example Code

```typescript
it('metered invoice always shows period section and meter select', () => {
  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      invoiceTypeCode: InvoiceTypeCode.METERED_SERVICES_INVOICE,
      amounts: [makeLine({ id: 'line-1', totalAmount: 5000, amount: 5000 })],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
    },
  });

  // Period section forced visible even without fromDate
  expect(screen.getByText(/custom|quarter|month/i)).toBeInTheDocument();

  // Meter select visible (only for metered invoices)
  expect(screen.getByText(/meter/i)).toBeInTheDocument();

  // Period button NOT shown (section is always visible for metered)
  expect(screen.queryByRole('button', { name: /^period$/i })).not.toBeInTheDocument();
});
```

---

# Inline Cost and Distribution

**Component(s) under test**: `InvoiceLineCostAndDistribution` from `components/invoice-lines/InvoiceLineCostAndDistribution.tsx`, rendered within `InvoiceLineCard` and `SingleTotalView`

## Purpose

Guard the inline cost category (ledger) select and distribution method select interactions. These selects dispatch reducer actions (`SET_LEDGER`, `APPLY_DISTRIBUTION_KEY`, `DISTRIBUTE_EQUALLY`, `ALLOCATE_LATER`) that update the line's form state. The reducer logic is unit-tested; these integration tests verify the full wiring from UI click through to rendered state update.

## Additional Bugs Guarded

- "Select ledger" guards costAccount wiring — clicking a ledger in `BuildingLedgerSelect` must call `onLedgerChange` → `dispatch(SET_LEDGER)` → `line.costAccount` populated
- "Select distribution key" guards distribution wiring — selecting a key must apply shares from `distributionKeys` to `line.units` via `applyDistributionKey`
- "Distribute equally" guards even split — must set `distributionType: 'share'` and distribute `totalAmount` proportionally across all building properties
- "Allocate later" guards cleanup — must clear `distributionKeyId`, `useDistributionKey`, and `units` via `CLEARED_DISTRIBUTION_FIELDS`
- "Label reflects method" guards display — prevents stale labels showing wrong distribution state

---

## Select ledger updates line costAccount

**Preconditions**: 1 line rendered with no `costAccount`, `buildingId` set, `ledgerOptions` provided.

### Steps

1. Render `InvoiceLinesTableV3` with one line (no costAccount) and ledger options available
2. Open the `BuildingLedgerSelect` dropdown
3. Click a ledger option

### Expected Outcome

- `dispatch({ type: 'SET_LEDGER', payload: ledger })` fires
- Line state updates: `costAccount: { id, type, code, name }` populated
- The selected ledger name is visible in the select trigger

### Example Code

```typescript
it('select ledger updates line costAccount', async () => {
  const user = userEvent.setup();

  const mockLedgerOptions = [
    { id: 'ledger-1', code: '61005', name: 'Fire prevention', type: 'mother' },
    { id: 'ledger-2', code: '61006', name: 'Maintenance', type: 'mother' },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [makeLine({ id: 'line-1', totalAmount: 5000, amount: 5000 })],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
      ledgerOptions: mockLedgerOptions,
      isLoadingLedgerOptions: false,
    },
  });

  // Open ledger select (within the expanded first card)
  const ledgerSelect = screen.getByLabelText(/cost_category/i);
  await user.click(ledgerSelect);

  // Click a ledger option
  const option = screen.getByText('Fire prevention');
  await user.click(option);

  // Ledger name now visible as the selected value
  expect(screen.getByText('Fire prevention')).toBeInTheDocument();
});
```

---

## Select distribution key applies key and recalculates units

**Preconditions**: 1 line rendered, `distributionKeys` provided with shares, `properties` provided.

### Steps

1. Render with one line, distribution keys, and properties
2. Open the `DistributionMethodSelect` dropdown
3. Click a distribution key

### Expected Outcome

- `dispatch({ type: 'APPLY_DISTRIBUTION_KEY', payload: keyId })` fires
- Line state updates: `distributionKeyId` set, `useDistributionKey: true`
- `line.units` recalculated with shares from the selected key via `applyDistributionKey`
- Distribution key name visible in the select label

### Example Code

```typescript
it('select distribution key applies key and recalculates units', async () => {
  const user = userEvent.setup();

  const mockDistributionKeys = [
    {
      id: 'dk-1',
      name: 'Equal 3-way',
      base: 3000,
      shares: [
        { propertyId: 'p-1', share: 1000 },
        { propertyId: 'p-2', share: 1000 },
        { propertyId: 'p-3', share: 1000 },
      ],
    },
  ];

  const mockProperties = [
    { id: 'p-1', name: 'Unit 1' },
    { id: 'p-2', name: 'Unit 2' },
    { id: 'p-3', name: 'Unit 3' },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [makeLine({ id: 'line-1', totalAmount: 9000, amount: 9000 })],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
      distributionKeys: mockDistributionKeys,
      isLoadingDistributionKeys: false,
      properties: mockProperties,
    },
  });

  // Open distribution select
  const distSelect = screen.getByLabelText(/distribution/i);
  await user.click(distSelect);

  // Click the distribution key
  const keyOption = screen.getByText('Equal 3-way');
  await user.click(keyOption);

  // Label should now show the key name
  expect(screen.getByText(/equal 3-way/i)).toBeInTheDocument();
});
```

---

## Distribute equally splits amount across properties

**Preconditions**: 1 line with `totalAmount: 9000`, 3 properties available.

### Steps

1. Render with one line and properties
2. Open the `DistributionMethodSelect` dropdown
3. Click "Distribute equally" action button

### Expected Outcome

- `dispatch({ type: 'DISTRIBUTE_EQUALLY' })` fires
- Line state updates: `distributionType: 'share'`, `wholeBuilding: true`
- `line.units` has 3 entries with equal shares, amounts summing to `totalAmount`
- Label shows distribution type (e.g., "Equally / Share")

### Example Code

```typescript
it('distribute equally splits amount across properties', async () => {
  const user = userEvent.setup();

  const mockProperties = [
    { id: 'p-1', name: 'Unit 1' },
    { id: 'p-2', name: 'Unit 2' },
    { id: 'p-3', name: 'Unit 3' },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [makeLine({ id: 'line-1', totalAmount: 9000, amount: 9000 })],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
      properties: mockProperties,
    },
  });

  // Open distribution select
  const distSelect = screen.getByLabelText(/distribution/i);
  await user.click(distSelect);

  // Click "Distribute equally" action button
  const equallyButton = screen.getByRole('button', { name: /cost_split_evenly|equally/i });
  await user.click(equallyButton);

  // Label should reflect the distribution type
  expect(screen.getByText(/share|equally/i)).toBeInTheDocument();
});
```

---

## Allocate later clears distribution

**Preconditions**: 1 line that already has a distribution key applied (`distributionKeyId` set, units populated).

### Steps

1. Render with a line that has `distributionKeyId: 'dk-1'`, `useDistributionKey: true`, units with shares
2. Open the `DistributionMethodSelect` dropdown
3. Click "Allocate later"

### Expected Outcome

- `dispatch({ type: 'ALLOCATE_LATER' })` fires
- Line state updates: `distributionKeyId: undefined`, `useDistributionKey: false`, `units: []`
- All distribution fields cleared via `CLEARED_DISTRIBUTION_FIELDS`
- Label shows "Allocate later" text

### Example Code

```typescript
it('allocate later clears distribution fields', async () => {
  const user = userEvent.setup();

  const mockDistributionKeys = [
    {
      id: 'dk-1',
      name: 'Equal 3-way',
      base: 3000,
      shares: [
        { propertyId: 'p-1', share: 1000 },
        { propertyId: 'p-2', share: 1000 },
        { propertyId: 'p-3', share: 1000 },
      ],
    },
  ];

  renderWithProviders(<InvoiceLinesTableV3 />, {
    formDefaults: {
      buildingId: 'b-1',
      amounts: [
        makeLine({
          id: 'line-1',
          totalAmount: 9000,
          amount: 9000,
          distributionKeyId: 'dk-1',
          useDistributionKey: true,
          distributionType: 'share',
          units: [
            { propertyId: 'p-1', share: 1000, amount: 3000 },
            { propertyId: 'p-2', share: 1000, amount: 3000 },
            { propertyId: 'p-3', share: 1000, amount: 3000 },
          ],
        }),
      ],
    },
    contextOverrides: {
      groupingStrategy: 'NONE',
      invoiceId: null,
      distributionKeys: mockDistributionKeys,
    },
  });

  // Open distribution select
  const distSelect = screen.getByLabelText(/distribution/i);
  await user.click(distSelect);

  // Click "Allocate later"
  const allocateLater = screen.getByText(/allocate_later|allocate later/i);
  await user.click(allocateLater);

  // Label should show "Allocate later"
  expect(screen.getByText(/allocate_later|allocate later/i)).toBeInTheDocument();
});
```

---

## Distribution select label reflects current method

**Preconditions**: Lines with different distribution states.

### Steps

1. Render with a line that has `distributionKeyId: 'dk-1'` → verify label shows key name
2. Render with a line that has `distributionType: 'share'`, `useDistributionKey: false` → verify label shows equal split text
3. Render with a line that has no distribution (allocate later) → verify "Allocate later" label

### Expected Outcome

- Label accurately reflects the current distribution method
- `formatDistributionMethod` produces the correct display string based on `distributionType`, `useDistributionKey`, and `distributionKeyName`

### Example Code

```typescript
describe('distribution select label reflects current method', () => {
  it('shows distribution key name when key is applied', () => {
    const mockDistributionKeys = [
      { id: 'dk-1', name: 'Proportional split', base: 1000, shares: [] },
    ];

    renderWithProviders(<InvoiceLinesTableV3 />, {
      formDefaults: {
        buildingId: 'b-1',
        amounts: [
          makeLine({
            id: 'line-1',
            totalAmount: 5000,
            amount: 5000,
            distributionKeyId: 'dk-1',
            useDistributionKey: true,
            distributionType: 'share',
          }),
        ],
      },
      contextOverrides: {
        groupingStrategy: 'NONE',
        invoiceId: null,
        distributionKeys: mockDistributionKeys,
      },
    });

    // Label should show the key name
    expect(screen.getByText(/proportional split/i)).toBeInTheDocument();
  });

  it('shows "Allocate later" when units count is 0 and no key', () => {
    renderWithProviders(<InvoiceLinesTableV3 />, {
      formDefaults: {
        buildingId: 'b-1',
        amounts: [
          makeLine({
            id: 'line-1',
            totalAmount: 5000,
            amount: 5000,
            distributionKeyId: undefined,
            useDistributionKey: false,
            distributionType: 'share',
            units: [],
          }),
        ],
      },
      contextOverrides: {
        groupingStrategy: 'NONE',
        invoiceId: null,
      },
    });

    // Label should show "Allocate later"
    expect(screen.getByText(/allocate_later|allocate later/i)).toBeInTheDocument();
  });
});
```
