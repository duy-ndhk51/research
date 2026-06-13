# Inline Selects

**Status**: Not started
**Priority**: MEDIUM (building/supplier selection gates entire form -- wrong ID corrupts all downstream data)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/inline-selects.test.tsx`
**Component(s) under test**: `InlineBuildingSelect` from `components/InlineBuildingSelect.tsx`, `ConnectedInlineSupplierSelect` from `components/ConnectedInlineSupplierSelect.tsx`

## Purpose

Verify the inline building and supplier selects: selection handlers, side effects on buildingId/senderId change, search debounce, keyboard navigation, and the supplier quick-create flow.

## Risk

Building change doesn't reset supplier (wrong building-supplier pair), supplier clear doesn't reset `senderId`, keyboard navigation traps focus.

## Bugs Guarded

- "Building selected sets buildingId" / "Building changed resets supplier and amounts" guard **B13** (inline select clearing) -- building change must reset `senderId` and clear amounts; `handleBuildingChange` calls `resetField('senderId')` + `removeAllAmounts()`
- "Supplier cleared resets senderId" guards **B13** -- clearing supplier must reset `senderId` via `resetField` (not `setValue`); UUID validation difference
- "Supplier selected sets senderId" / "Reselecting same supplier is a no-op" guard **B13** -- supplier selection populates `senderId`; already-selected supplier must be a no-op
- "Search debounces API calls" guards debounce -- rapid typing must debounce API calls; `useDebouncedCallback` with 300ms delay
- "Quick-create supplier flow" guards quick-create -- inline supplier creation must populate `senderId` and trigger supplier defaults refresh

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Building selected sets buildingId | `setValue('buildingId', 'b-1')` called |
| Building changed resets supplier + amounts | `resetField('senderId')` + `removeAllAmounts()` called |
| Supplier cleared resets senderId | `resetField('senderId')` called |
| Supplier selected sets senderId | `setValue('senderId', 's-1')` called |
| Reselecting same supplier is a no-op | No `setValue` call |
| Search debounces API calls | Rapid typing -> single API call after 300ms |
| Quick-create supplier flow | Creates contact, sets `senderId`, refreshes defaults |
| Keyboard navigation cycles options | ArrowDown -> first option focused |
| Tab focus management | Tab from building -> focuses supplier |
| Both disabled in partial edit mode | Both selects inside disabled fieldset |

## Related Specs

- Supplier defaults: [supplier-defaults.md](./supplier-defaults.md) — backfill on supplier selection
- Peppol supplier: [peppol-to-invoice.md](./peppol-to-invoice.md) — matched/unmatched supplier
- Form body gate: [form-body-conditional.md](./form-body-conditional.md) — prerequisite check

## Mocking Strategy

```typescript
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));

vi.mock('@/hooks/patrimony/useBuildings', () => ({
  useBuildingSearch: vi.fn(() => ({
    data: [],
    isLoading: false,
    setSearch: vi.fn(),
  })),
}));

vi.mock('@/hooks/financial/useSupplierSearch', () => ({
  useSupplierSearch: vi.fn(() => ({
    data: [],
    isLoading: false,
    setSearch: vi.fn(),
  })),
}));

vi.mock('@/hooks/contacts/useContactMutations', () => ({
  useCreateContact: vi.fn(() => ({
    mutateAsync: vi.fn().mockResolvedValue({ id: 'new-supplier-1' }),
  })),
}));
```

## Shared Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '../utils';
import { InlineBuildingSelect } from '../../components/InlineBuildingSelect';
import { ConnectedInlineSupplierSelect } from '../../components/ConnectedInlineSupplierSelect';

const mockBuildings = [
  { id: 'b-1', name: 'Building Alpha', address: '123 Main St' },
  { id: 'b-2', name: 'Building Beta', address: '456 Oak Ave' },
];

const mockSuppliers = [
  { id: 's-1', name: 'Supplier One', vatNumber: 'BE0123456789' },
  { id: 's-2', name: 'Supplier Two', vatNumber: 'BE9876543210' },
];

beforeEach(() => {
  vi.clearAllMocks();
});
```

---

## Building selected sets buildingId

**Preconditions**: No building selected, search returns results.

### Steps

1. Render `<InlineBuildingSelect />`
2. Type "Alpha" in the search input
3. Click "Building Alpha" from the dropdown

### Expected Outcome

- `setValue('buildingId', 'b-1')` called with the selected building's ID

### Example Code

```typescript
describe('Inline Selects', () => {
  it('should set buildingId when building is selected', async () => {
    const user = userEvent.setup();
    const { contextValue } = renderWithProviders(<InlineBuildingSelect />, {
      formDefaults: { buildingId: undefined },
    });

    const input = screen.getByRole('combobox', { name: /building/i });
    await user.type(input, 'Alpha');
    await user.click(screen.getByText(/Building Alpha/i));

    expect(contextValue.formMethods.setValue).toHaveBeenCalledWith(
      'buildingId',
      'b-1',
      expect.any(Object),
    );
  });
});
```

---

## Building changed resets supplier and amounts

**Preconditions**: Building already selected (building-1), supplier set.

### Steps

1. Render with existing `buildingId: 'b-1'`, `senderId: 's-1'`
2. Select a different building "Building Beta"

### Expected Outcome

- `resetField('senderId')` called (clears supplier)
- `removeAllAmounts()` called (clears amount lines)

### Example Code

```typescript
it('should reset supplier and amounts when building changes', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(<InlineBuildingSelect />, {
    formDefaults: { buildingId: 'b-1', senderId: 's-1' },
  });

  const input = screen.getByRole('combobox', { name: /building/i });
  await user.clear(input);
  await user.type(input, 'Beta');
  await user.click(screen.getByText(/Building Beta/i));

  expect(contextValue.formMethods.resetField).toHaveBeenCalledWith('senderId');
});
```

---

## Supplier cleared resets senderId

**Preconditions**: Supplier already selected.

### Steps

1. Render with `senderId: 's-1'`
2. Click the clear (x) button on the supplier select

### Expected Outcome

- `resetField('senderId')` called (not `setValue('senderId', '')`)

### Example Code

```typescript
it('should call resetField when supplier is cleared', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(
    <ConnectedInlineSupplierSelect />,
    { formDefaults: { buildingId: 'b-1', senderId: 's-1' } },
  );

  await user.click(screen.getByRole('button', { name: /clear/i }));

  expect(contextValue.formMethods.resetField).toHaveBeenCalledWith('senderId');
});
```

---

## Supplier selected sets senderId

**Preconditions**: No supplier selected, search returns results.

### Steps

1. Render `<ConnectedInlineSupplierSelect />` with `buildingId: 'b-1'`
2. Search for "Supplier One"
3. Click the result

### Expected Outcome

- `setValue('senderId', 's-1')` called

### Example Code

```typescript
it('should set senderId when supplier is selected', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(
    <ConnectedInlineSupplierSelect />,
    { formDefaults: { buildingId: 'b-1' } },
  );

  const input = screen.getByRole('combobox', { name: /supplier/i });
  await user.type(input, 'Supplier One');
  await user.click(screen.getByText(/Supplier One/i));

  expect(contextValue.formMethods.setValue).toHaveBeenCalledWith(
    'senderId',
    's-1',
    expect.any(Object),
  );
});
```

---

## Reselecting same supplier is a no-op

**Preconditions**: Supplier `s-1` already selected.

### Steps

1. Render with `senderId: 's-1'`
2. Open dropdown and click the same supplier again

### Expected Outcome

- `setValue` not called (no redundant update)

### Example Code

```typescript
it('reselecting same supplier is a no-op', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(
    <ConnectedInlineSupplierSelect />,
    { formDefaults: { buildingId: 'b-1', senderId: 's-1' } },
  );

  const input = screen.getByRole('combobox', { name: /supplier/i });
  await user.click(input);
  await user.click(screen.getByText(/Supplier One/i));

  expect(contextValue.formMethods.setValue).not.toHaveBeenCalled();
});
```

---

## Search debounces API calls

**Preconditions**: Building select rendered.

### Steps

1. Rapidly type "Alp" character by character with < 300ms delay

### Expected Outcome

- API search called once after debounce settles (not 3 times)

### Example Code

```typescript
it('should debounce search API calls', async () => {
  const user = userEvent.setup();
  const setSearch = vi.fn();

  renderWithProviders(<InlineBuildingSelect />);

  const input = screen.getByRole('combobox', { name: /building/i });
  await user.type(input, 'Alp');

  await waitFor(() => {
    expect(setSearch).toHaveBeenCalledTimes(1);
    expect(setSearch).toHaveBeenCalledWith('Alp');
  });
});
```

---

## Quick-create supplier flow

**Preconditions**: Building selected, search finds no match.

### Steps

1. Type a new supplier name
2. Click "Create new supplier" button
3. Fill in the quick-create form and submit

### Expected Outcome

- `createContact` mutation called with supplier data
- `setValue('senderId', 'new-supplier-1')` called with the newly created ID
- Supplier defaults refresh triggered

### Example Code

```typescript
it('should create supplier and set senderId', async () => {
  const user = userEvent.setup();
  const { contextValue } = renderWithProviders(
    <ConnectedInlineSupplierSelect />,
    { formDefaults: { buildingId: 'b-1' } },
  );

  const input = screen.getByRole('combobox', { name: /supplier/i });
  await user.type(input, 'New Supplier NV');

  await user.click(screen.getByText(/create/i));

  await waitFor(() => {
    expect(contextValue.formMethods.setValue).toHaveBeenCalledWith(
      'senderId',
      'new-supplier-1',
      expect.any(Object),
    );
  });
});
```

---

## Keyboard navigation cycles options

**Preconditions**: Dropdown open with results.

### Steps

1. Open the building select dropdown
2. Press ArrowDown

### Expected Outcome

- First option gains visual focus
- ArrowDown again moves to second option

### Example Code

```typescript
it('keyboard ArrowDown focuses first option', async () => {
  const user = userEvent.setup();
  renderWithProviders(<InlineBuildingSelect />);

  const input = screen.getByRole('combobox', { name: /building/i });
  await user.click(input);
  await user.keyboard('{ArrowDown}');

  const option = screen.getByRole('option', { name: /Building Alpha/i });
  expect(option).toHaveAttribute('data-active-item');
});
```

---

## Tab focus management

**Preconditions**: Building select focused.

### Steps

1. Focus building select
2. Press Tab

### Expected Outcome

- Focus moves to supplier select

### Example Code

```typescript
it('Tab from building select focuses supplier select', async () => {
  const user = userEvent.setup();
  renderWithProviders(
    <>
      <InlineBuildingSelect />
      <ConnectedInlineSupplierSelect />
    </>,
  );

  const buildingInput = screen.getByRole('combobox', { name: /building/i });
  await user.click(buildingInput);
  await user.tab();

  const supplierInput = screen.getByRole('combobox', { name: /supplier/i });
  expect(supplierInput).toHaveFocus();
});
```

---

## Both selects disabled in partial edit mode

**Preconditions**: `isPartialEditMode: true`.

### Steps

1. Render both selects with `isPartialEditMode: true`

### Expected Outcome

- Both combobox inputs are inside a disabled fieldset

### Example Code

```typescript
it('both selects disabled in partial edit mode', () => {
  renderWithProviders(
    <>
      <InlineBuildingSelect />
      <ConnectedInlineSupplierSelect />
    </>,
    { contextOverrides: { isPartialEditMode: true } },
  );

  const buildingInput = screen.getByRole('combobox', { name: /building/i });
  expect(buildingInput.closest('fieldset[disabled]')).not.toBeNull();

  const supplierInput = screen.getByRole('combobox', { name: /supplier/i });
  expect(supplierInput.closest('fieldset[disabled]')).not.toBeNull();
});
```
