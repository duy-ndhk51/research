# Amount Distribution Sheet

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/amount-distribution-sheet.test.tsx`
**Logic under test**: `PurchaseInvoiceAmountDistributionSheet` component from `purchase-invoice-v2/components/`

Tests verify the distribution sheet UI lifecycle: opening, unit initialization from building properties, distribution type switching, share/amount recalculation, ledger and DK suggestions, and validation. All API hooks (`usePropertiesV2`, `useDistributionKeys`, `useLedgerSuggestions`) are mocked.

**Source reference**: `PurchaseInvoiceAmountDistributionSheet.tsx`, `useSplitAmounts.ts`, `distributionKeyForm.ts`

---

## IT-030: Loading state shows spinner

**Preconditions**: `open: true`, `usePropertiesV2` returns `isPending: true`.

### Steps

1. Render `PurchaseInvoiceAmountDistributionSheet` with `open: true` and mocked pending properties

### Assertions

- `LoadingSpinner` is visible inside the sheet
- No unit list or form fields are rendered

### Example Code

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import PurchaseInvoiceAmountDistributionSheet from '../../components/PurchaseInvoiceAmountDistributionSheet';

vi.mock('@/hooks/useProperties', () => ({
  usePropertiesV2: () => ({ properties: [], isPending: true }),
}));
vi.mock('@/hooks/useDistributionKeys', () => ({
  useDistributionKeys: () => ({ data: null, isPending: true }),
}));

describe('Amount Distribution Sheet', () => {
  it('IT-030: shows spinner while properties are loading', () => {
    render(
      <PurchaseInvoiceAmountDistributionSheet
        open={true}
        onOpenChange={vi.fn()}
        onSubmit={vi.fn()}
        editingItem={null}
        isEditing={false}
        buildingId="building-1"
        supplierId="supplier-1"
      />,
    );

    expect(screen.getByRole('status')).toBeInTheDocument();
    expect(screen.queryByText(/cost account/i)).not.toBeInTheDocument();
  });
});
```

---

## IT-031: Properties loaded initializes units

**Preconditions**: `open: true`, `usePropertiesV2` returns 3 properties, no `editingItem`.

### Steps

1. Render with loaded properties
2. Wait for units to be initialized via the `useEffect`

### Assertions

- 3 unit rows rendered in the table
- All units have `selected: false` and `amount: 0`
- `wholeBuilding` is `false`

### Example Code

```typescript
it('IT-031: initializes units from building properties', async () => {
  mockProperties([
    { id: 'unit-1', name: 'Apt 1' },
    { id: 'unit-2', name: 'Apt 2' },
    { id: 'unit-3', name: 'Apt 3' },
  ]);

  render(<DistributionSheet open={true} editingItem={null} />);

  const rows = await screen.findAllByTestId('unit-list-item');
  expect(rows).toHaveLength(3);

  // All amounts should be zero
  const amountInputs = screen.getAllByRole('spinbutton');
  amountInputs.forEach((input) => {
    expect(input).toHaveValue(0);
  });
});
```

---

## IT-032: Edit mode pre-fills from editingItem

**Preconditions**: `open: true`, `editingItem` contains saved distribution data with 2 selected units.

### Steps

1. Render with `editingItem` that has `totalAmount: 50000`, `distributionType: 'share'`, 2 units with shares
2. Verify form resets to editing values

### Assertions

- Total amount field shows the saved value
- Distribution type reflects `'share'`
- Unit shares match the `editingItem` data

### Example Code

```typescript
it('IT-032: pre-fills form from editingItem', async () => {
  const editingItem = {
    id: 'line-1',
    amount: 50000,
    totalAmount: 50000,
    hasVat: false,
    vatRate: 21,
    hasCustomPrice: false,
    wholeBuilding: true,
    useDistributionKey: false,
    distributionType: 'share' as const,
    totalShare: 1000,
    units: [
      { id: 'unit-1', selected: true, amount: 30000, share: 600 },
      { id: 'unit-2', selected: true, amount: 20000, share: 400 },
    ],
  };

  render(<DistributionSheet open={true} editingItem={editingItem} isEditing={true} />);

  await waitFor(() => {
    expect(screen.getByDisplayValue('500,00')).toBeInTheDocument();
  });
});
```

---

## IT-033: Share distribution type sets DEFAULT_SHARE

**Preconditions**: Sheet open with 3 properties, `wholeBuilding: true`.

### Steps

1. Select distribution type "Share"
2. Observe `totalShare` and unit amount recalculation

### Assertions

- `totalShare` is set to `DEFAULT_SHARE` (1000)
- `applySharesDistribution` called with `DEFAULT_SHARE` and `SHARE` calculation
- Unit amounts recalculated proportionally

### Example Code

```typescript
it('IT-033: share mode sets DEFAULT_SHARE and recalculates', async () => {
  render(<DistributionSheet open={true} />);
  await selectWholeBuilding();

  await userEvent.click(screen.getByLabelText(/share/i));

  await waitFor(() => {
    const totalShareInput = screen.getByLabelText(/total share/i);
    expect(totalShareInput).toHaveValue(1000);
  });
});
```

---

## IT-034: Percentage distribution type sets PERCENTAGE_BASE_VALUE

**Preconditions**: Sheet open with properties, `wholeBuilding: true`.

### Steps

1. Select distribution type "Percentage"

### Assertions

- `totalShare` is set to `PERCENTAGE_BASE_VALUE` (10000)
- Unit shares reflect percentage values

### Example Code

```typescript
it('IT-034: percentage mode sets PERCENTAGE_BASE_VALUE', async () => {
  render(<DistributionSheet open={true} />);
  await selectWholeBuilding();

  await userEvent.click(screen.getByLabelText(/percentage/i));

  await waitFor(() => {
    const totalShareInput = screen.getByLabelText(/total share/i);
    expect(totalShareInput).toHaveValue(10000);
  });
});
```

---

## IT-035: Free distribution type enables per-unit inputs

**Preconditions**: Sheet open, units selected.

### Steps

1. Select distribution type "Free"

### Assertions

- Per-unit amount inputs become editable (not read-only)
- `totalShare` is set to `totalAmount`
- Share column is hidden

### Example Code

```typescript
it('IT-035: free mode enables manual per-unit amount editing', async () => {
  render(<DistributionSheet open={true} />);
  await selectWholeBuilding();

  await userEvent.click(screen.getByLabelText(/free/i));

  const amountInputs = screen.getAllByRole('spinbutton');
  amountInputs.forEach((input) => {
    expect(input).not.toHaveAttribute('readonly');
  });
});
```

---

## IT-036: Split later clears all allocations

**Preconditions**: Sheet open with units that have existing shares and amounts.

### Steps

1. Set some units with shares and amounts
2. Switch to "Split later"

### Assertions

- All units have `share: 0` and `amount: 0`
- `useDistributionKey` is `false`
- `distributionKeyId` is cleared
- `totalShare` is `0`

### Example Code

```typescript
it('IT-036: split_later clears all unit allocations', async () => {
  render(<DistributionSheet open={true} editingItem={itemWithShares} />);

  await userEvent.click(screen.getByLabelText(/split later/i));

  await waitFor(() => {
    const amountInputs = screen.getAllByRole('spinbutton');
    amountInputs.forEach((input) => {
      expect(input).toHaveValue(0);
    });
  });
});
```

---

## IT-037: Distribution key mode forces wholeBuilding and applies shares

**Preconditions**: Sheet open with 3 properties, distribution keys available.

### Steps

1. Select distribution type "Distribution key"
2. Observe `wholeBuilding`, unit selection, and share values

### Assertions

- `wholeBuilding` set to `true`
- All units marked `selected: true`
- `distributionKeyId` set to first available key
- Unit shares match the key's share definitions
- `distributionType` matches the key's calculation type

### Example Code

```typescript
it('IT-037: DK mode forces wholeBuilding and applies key shares', async () => {
  mockDistributionKeys([
    {
      id: 'dk-1',
      calculation: 'share',
      base: 1000,
      shares: [
        { propertyId: 'unit-1', share: 500 },
        { propertyId: 'unit-2', share: 300 },
        { propertyId: 'unit-3', share: 200 },
      ],
    },
  ]);

  render(<DistributionSheet open={true} />);

  await userEvent.click(screen.getByLabelText(/distribution key/i));

  await waitFor(() => {
    const checkboxes = screen.getAllByRole('checkbox');
    checkboxes.forEach((cb) => expect(cb).toBeChecked());
  });
});
```

---

## IT-038: Changing distribution key recalculates shares

**Preconditions**: Already in DK mode with `dk-1` applied.

### Steps

1. Switch to `dk-2` which has different share ratios

### Assertions

- Unit shares update to match `dk-2`'s definitions
- Amounts recalculated based on new shares

### Example Code

```typescript
it('IT-038: switching DK recalculates all unit shares', async () => {
  mockDistributionKeys([
    { id: 'dk-1', calculation: 'share', base: 1000, shares: [/*...*/] },
    { id: 'dk-2', calculation: 'percentage', base: 10000, shares: [/*...*/] },
  ]);

  render(<DistributionSheet open={true} />);
  await selectDistributionKeyMode();

  // Switch to dk-2
  await userEvent.selectOptions(screen.getByLabelText(/distribution key/i), 'dk-2');

  await waitFor(() => {
    expect(screen.getByLabelText(/total share/i)).toHaveValue(10000);
  });
});
```

---

## IT-039: Whole building toggle controls bulk selection

**Preconditions**: Sheet open with 3 units, none selected.

### Steps

1. Toggle "Whole building" ON → all units selected
2. Toggle "Whole building" OFF → all units deselected with amounts zeroed

### Assertions

- ON: all checkboxes checked
- OFF: all checkboxes unchecked, all `share: 0`, all `amount: 0`
- `useDistributionKey` set to `false` on OFF

### Example Code

```typescript
it('IT-039: whole building toggle controls bulk selection', async () => {
  render(<DistributionSheet open={true} />);

  // Toggle ON
  await userEvent.click(screen.getByLabelText(/whole building/i));
  let checkboxes = screen.getAllByRole('checkbox', { name: /unit/i });
  checkboxes.forEach((cb) => expect(cb).toBeChecked());

  // Toggle OFF
  await userEvent.click(screen.getByLabelText(/whole building/i));
  checkboxes = screen.getAllByRole('checkbox', { name: /unit/i });
  checkboxes.forEach((cb) => expect(cb).not.toBeChecked());
});
```

---

## IT-040: Individual unit selection zeros share on deselect

**Preconditions**: Sheet open, whole building ON, share mode with amounts distributed.

### Steps

1. Deselect one unit

### Assertions

- Deselected unit has `share: 0` and `amount: 0`
- Other units retain their values

### Example Code

```typescript
it('IT-040: deselecting a unit zeros its share and amount', async () => {
  render(<DistributionSheet open={true} />);
  await selectWholeBuilding();
  await setTotalAmount(30000);

  // Deselect unit-2
  await userEvent.click(screen.getByTestId('unit-checkbox-unit-2'));

  await waitFor(() => {
    const unit2Amount = screen.getByTestId('unit-amount-unit-2');
    expect(unit2Amount).toHaveValue(0);
  });
});
```

---

## IT-041: Select all checkbox toggles all units

**Preconditions**: Sheet open with 3 units, none selected.

### Steps

1. Click the header "select all" checkbox

### Assertions

- All unit checkboxes become checked
- Clicking again unchecks all

### Example Code

```typescript
it('IT-041: header select-all toggles all units', async () => {
  render(<DistributionSheet open={true} />);

  await userEvent.click(screen.getByLabelText(/select all/i));

  const checkboxes = screen.getAllByRole('checkbox', { name: /unit/i });
  checkboxes.forEach((cb) => expect(cb).toBeChecked());

  await userEvent.click(screen.getByLabelText(/select all/i));
  checkboxes.forEach((cb) => expect(cb).not.toBeChecked());
});
```

---

## IT-042: Changing totalAmount recalculates amounts for non-free types

**Preconditions**: Sheet open, share mode, 2 units with equal shares, `totalAmount: 20000`.

### Steps

1. Change `totalAmount` to `40000`

### Assertions

- Unit amounts double (from 10000 each to 20000 each)
- Shares stay the same
- Only fires for non-free types (`type !== 'free'`)

### Example Code

```typescript
it('IT-042: totalAmount change triggers proportional redistribution', async () => {
  render(<DistributionSheet open={true} />);
  await selectWholeBuilding();
  await setTotalAmount(20000);

  // Both units should have 10000 each (equal shares)
  await waitFor(() => {
    expect(screen.getByTestId('unit-amount-unit-1')).toHaveValue(10000);
  });

  // Change total
  await setTotalAmount(40000);

  await waitFor(() => {
    expect(screen.getByTestId('unit-amount-unit-1')).toHaveValue(20000);
    expect(screen.getByTestId('unit-amount-unit-2')).toHaveValue(20000);
  });
});
```

---

## IT-043: Ledger suggestion chip sets costAccount

**Preconditions**: Sheet open, `useLedgerSuggestions` returns suggestions.

### Steps

1. Click a ledger suggestion chip

### Assertions

- `costAccount` form field set with `id`, `type`, `code`, `name` from suggestion
- Suggestion chip shows as selected

### Example Code

```typescript
it('IT-043: clicking ledger suggestion populates costAccount', async () => {
  mockLedgerSuggestions([
    { value: 'ledger-1', code: '6100', name: 'Maintenance', parentMotherName: 'Costs' },
  ]);

  render(<DistributionSheet open={true} />);

  await userEvent.click(screen.getByText('Maintenance'));

  await waitFor(() => {
    expect(screen.getByText('6100')).toBeInTheDocument();
  });
});
```

---

## IT-044: DK suggestion chip switches to DK mode

**Preconditions**: Sheet open in share mode, DK suggestions available.

### Steps

1. Click a distribution key suggestion chip

### Assertions

- `useDistributionKey` set to `true`
- `distributionKeyId` set to the clicked suggestion's value
- Shares recalculated from the key's definition

### Example Code

```typescript
it('IT-044: clicking DK suggestion enables DK mode and applies key', async () => {
  mockDistributionKeySuggestions([
    { value: 'dk-1', name: 'Equal shares' },
  ]);

  render(<DistributionSheet open={true} />);

  await userEvent.click(screen.getByText('Equal shares'));

  await waitFor(() => {
    expect(screen.getByLabelText(/distribution key/i)).toHaveValue('dk-1');
  });
});
```

---

## IT-045: Total mismatch validation shows SplitErrorDialog

**Preconditions**: Sheet open, free mode, unit amounts don't sum to `totalAmount`.

### Steps

1. Set `totalAmount: 30000`
2. Set unit-1 amount to `20000`, unit-2 amount to `5000` (sum = 25000, mismatch)
3. Click submit

### Assertions

- `SplitErrorDialog` opens with expected vs actual amounts
- Dialog offers "Divide equally" action

### Example Code

```typescript
it('IT-045: total mismatch triggers SplitErrorDialog', async () => {
  render(<DistributionSheet open={true} />);
  await selectWholeBuilding();
  await selectFreeMode();
  await setTotalAmount(30000);
  await setUnitAmount('unit-1', 20000);
  await setUnitAmount('unit-2', 5000);

  await userEvent.click(screen.getByRole('button', { name: /save/i }));

  await waitFor(() => {
    expect(screen.getByText(/amount mismatch/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /divide equally/i })).toBeInTheDocument();
  });
});
```

---

## IT-046: Unit search filters by name, address, and owner

**Preconditions**: Sheet open with 3 units: "Apt 101", "Apt 202", "Garage B1".

### Steps

1. Type "Apt" in search input
2. Observe filtered list

### Assertions

- Only "Apt 101" and "Apt 202" visible
- "Garage B1" hidden
- Clearing search restores all units

### Example Code

```typescript
it('IT-046: search filters units by name', async () => {
  mockProperties([
    { id: 'u1', name: 'Apt 101' },
    { id: 'u2', name: 'Apt 202' },
    { id: 'u3', name: 'Garage B1' },
  ]);

  render(<DistributionSheet open={true} />);

  await userEvent.type(screen.getByPlaceholderText(/search/i), 'Apt');

  await waitFor(() => {
    expect(screen.getByText('Apt 101')).toBeInTheDocument();
    expect(screen.getByText('Apt 202')).toBeInTheDocument();
    expect(screen.queryByText('Garage B1')).not.toBeInTheDocument();
  });
});
```

---

## IT-047: Unit sort reorders by name, owner, or amount

**Preconditions**: Sheet open with 3 units in arbitrary order.

### Steps

1. Click sort by "amount" ascending
2. Observe order

### Assertions

- Units ordered by amount ascending
- Switching to descending reverses order

### Example Code

```typescript
it('IT-047: sort by amount reorders unit list', async () => {
  render(<DistributionSheet open={true} editingItem={itemWithVariousAmounts} />);

  await userEvent.click(screen.getByText(/amount/i));

  const rows = screen.getAllByTestId('unit-list-item');
  const amounts = rows.map((row) =>
    Number(row.querySelector('[data-testid*="unit-amount"]')?.getAttribute('value')),
  );
  expect(amounts).toEqual([...amounts].sort((a, b) => a - b));
});
```
