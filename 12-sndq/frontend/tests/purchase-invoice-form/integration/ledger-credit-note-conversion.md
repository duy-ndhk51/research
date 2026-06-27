# Integration Test Spec — Ledger Select: Credit Note Conversion

**Status**: Partial (Cases 1–10, 12–13 implemented; Case 11 deferred)
**Priority**: High
**Test tier**: Integration (component)
**Target test file**: `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/ledger-credit-note-conversion.test.tsx`
**Component(s) under test**: `InlineLedgerSelect`, `useCreditNoteConversion`, `InvoiceLineCostAndDistribution`, `PurchaseInvoiceAmountDistributionSheet`

---

## Purpose

Verify that the `InlineLedgerSelect` component correctly:

1. Renders tabbed options (Expenses 6xx / Revenue 7xx)
2. Shows a confirmation dialog when a 7xx ledger is selected on a non-credit-note invoice
3. On confirmation, converts the invoice to credit note mode and bulk-updates all 6xx lines to the selected 7xx ledger
4. Skips the dialog when already in credit_note mode
5. Leaves all state unchanged when the dialog is cancelled
6. Preserves existing 7xx lines during bulk conversion

## Risk

- Silent data loss if bulk update overwrites lines that already have a valid 7xx ledger
- Invoice type corruption if `invoiceTypeCode` is set without syncing `mode`
- Dialog appearing when it should not (already credit_note mode) or failing to dismiss
- Conversion writing to the wrong form scope when triggered from inside `PurchaseInvoiceAmountDistributionSheet` (inner vs outer `FormProvider`)

## Bugs guarded

- Regression: bulk update must NOT touch lines where `costAccount.code` starts with `'7'`
- Regression: cancelling the dialog must NOT change mode, `invoiceTypeCode`, or any line's `costAccount`
- Regression: `FormHeader` mode toggle (credit_note → invoice) must NOT trigger any bulk line updates

---

## Scenarios

| # | Test case | Expected outcome | Status |
|---|-----------|------------------|--------|
| 1 | Expense tab renders 6xx options, Revenue tab renders 7xx options | Options correctly split by `displayCode` prefix | - [x] |
| 2 | Select expense option on invoice mode | `onChange` called, no dialog shown, no mode change | - [x] |
| 3 | Select revenue option on invoice mode | Confirmation dialog appears | - [x] |
| 4 | Confirm conversion dialog on invoice mode | `setMode('credit_note')` called, `invoiceTypeCode` set to `'381'` | - [x] |
| 5 | Confirm with 3 lines (2× 6xx, 1× 7xx) | Only the 2 6xx lines updated to selected 7xx; existing 7xx line preserved | - [x] |
| 6 | Cancel conversion dialog | No mode change, no `invoiceTypeCode` change, no line updates | - [x] |
| 7 | Select revenue option on credit_note mode | `onChange` called directly, no dialog shown | - [x] |
| 8 | Select revenue option on expense_note mode | Confirmation dialog appears (same as invoice mode) | - [x] |
| 9 | Lines with `costAccount` but no `code` field | Treated as expense class — included in bulk update | - [x] |
| 10 | Lines with `costAccount: undefined` | Updated during conversion — empty lines receive selected ledger | - [x] |
| 11 | Distribution sheet: select revenue option | Same dialog + bulk update flow triggered on outer invoice form | - [ ] (deferred) |
| 12 | FormHeader mode toggle after conversion | Mode and type code change; line `costAccount` values remain unchanged | - [x] |
| 13 | Backfilled 6xx value → open Revenue tab | Revenue list shows 7xx only; trigger still shows selected 6xx label | - [x] |

---

## Existing coverage

Partial coverage already exists in sndq-fe. These tests are **not** a substitute for this integration spec but avoid duplicating work when implementing:

- `sndq-fe/src/modules/financial/forms/purchase-invoice-v2/__tests__/useCreditNoteConversion.test.tsx` — 8 unit tests for `shouldBulkUpdateCostAccount` and bulk `setValue` behavior (hook: `purchase-invoice-v3/hooks/useCreditNoteConversion.ts`)
- `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/InvoiceLineCard.test.tsx` — ledger selection via mocked `InlineLedgerSelect` (Commit 5)

**Dialog implementation note**: Confirmation uses Briicks `Dialog` in `InlineLedgerSelect.tsx` (Commit 2 deviation), not shadcn `AlertDialog`. Query with `getByRole('dialog')` or by title key `peppol.action_convert_credit_note`.

---

## Related specs

- [mode-switching.md](./mode-switching.md) — `FormHeader` mode toggle behavior
- [inline-selects.md](./inline-selects.md) — `InlineBuildingSelect`, `InlineSupplierSelect`, and `InlineLedgerSelect` UI scenarios
- [invoice-lines-table.md](./invoice-lines-table.md) — Line CRUD, cost category field wiring
- [amount-distribution-sheet.md](./amount-distribution-sheet.md) — Distribution sheet ledger field

---

## Mocking strategy

```typescript
vi.mock('@/hooks/financial/useBuildingLedgerOptions', () => ({
  useBuildingLedgerOptions: vi.fn(),
}));

vi.mock('@/hooks/financial/useMotherLedgerOptions', () => ({
  useMotherLedgerOptions: vi.fn(),
}));

// Prevent lazy-loaded components from breaking jsdom
vi.mock(
  '@/modules/financial/components/chart-of-accounts/drawer/ChartOfAccountsDrawer',
  () => ({ default: () => null }),
);

vi.mock(
  '@/modules/financial/components/chart-of-accounts/forms/CreateLedgerFloatingSheetContent',
  () => ({ default: () => null }),
);
```

---

## Shared setup

```typescript
import { screen } from '@testing-library/react';
import { renderWithProviders } from '../utils';
import { CostAccountType } from '@/common/models/accounting/accountingLedger';
import type { AccountingLedgerOption } from '@/common/models/accounting/accountingLedger';
import type { InvoiceFormMode } from '../../types';

const mockExpenseOptions: AccountingLedgerOption[] = [
  {
    id: 'ledger-601',
    displayCode: '601',
    code: '601',
    name: 'Maintenance',
    type: CostAccountType.LEDGER,
  },
  {
    id: 'ledger-602',
    displayCode: '602',
    code: '602',
    name: 'Cleaning',
    type: CostAccountType.LEDGER,
  },
];

const mockRevenueOptions: AccountingLedgerOption[] = [
  {
    id: 'ledger-701',
    displayCode: '701',
    code: '701',
    name: 'Common charges',
    type: CostAccountType.LEDGER,
  },
  {
    id: 'ledger-702',
    displayCode: '702',
    code: '702',
    name: 'Individual charges',
    type: CostAccountType.LEDGER,
  },
];

function setupMockLedgerOptions() {
  (useBuildingLedgerOptions as Mock).mockImplementation(
    ({ motherCode }: { motherCode?: string }) =>
      motherCode === '7'
        ? { data: mockRevenueOptions, isLoading: false }
        : { data: mockExpenseOptions, isLoading: false },
  );
}

const defaultAmount = {
  id: 'amount-1',
  amount: 0,
  hasVat: false,
  vatRate: 0,
  totalAmount: 0,
  description: '',
  costAccount: undefined,
  useDistributionKey: false,
  distributionType: 'share' as const,
  totalShare: 0,
  hasCustomPrice: false,
  wholeBuilding: false,
  units: [],
};
```

---

## Case 1: Expense tab shows 6xx options, Revenue tab shows 7xx options

**Preconditions**: Form rendered with `buildingId` set, mock options configured.

**Steps**:

1. Render `InvoiceLineCostAndDistribution` (or directly `InlineLedgerSelect`) with `buildingId` and mocked options
2. Click the ledger select trigger to open popover
3. Assert "Expenses" tab is active by default
4. Assert 6xx option names are visible
5. Click "Revenue" tab
6. Assert 7xx option names are visible and 6xx options are not

**Expected outcome**: Options are correctly routed to the corresponding tab by `displayCode` prefix.

**Example code**:

```typescript
it('renders 6xx options in Expenses tab and 7xx options in Revenue tab', async () => {
  setupMockLedgerOptions();
  const { user } = renderWithProviders(
    <InvoiceLineCostAndDistribution {...defaultProps} />,
    { formDefaults: { buildingId: 'building-1', amounts: [defaultAmount] } },
  );

  await user.click(screen.getByRole('button', { name: /cost category/i }));

  expect(screen.getByRole('tab', { name: /expenses/i })).toHaveAttribute(
    'aria-selected',
    'true',
  );
  expect(screen.getByText('Maintenance')).toBeInTheDocument();
  expect(screen.queryByText('Common charges')).not.toBeInTheDocument();

  await user.click(screen.getByRole('tab', { name: /revenue/i }));

  expect(screen.getByText('Common charges')).toBeInTheDocument();
  expect(screen.queryByText('Maintenance')).not.toBeInTheDocument();
});
```

---

## Case 2: Select expense option on invoice mode — no dialog

**Preconditions**: Form in `invoice` mode, popover open on Expenses tab.

**Steps**:

1. Click an expense option ("Maintenance")
2. Assert no dialog appears
3. Assert `setMode` was NOT called

**Expected outcome**: Normal selection — no conversion side effects.

**Example code**:

```typescript
it('selects expense option without dialog on invoice mode', async () => {
  setupMockLedgerOptions();
  const { user, contextValue } = renderWithProviders(
    <InvoiceLineCostAndDistribution {...defaultProps} />,
    { contextOverrides: { mode: 'invoice' } },
  );

  await user.click(screen.getByRole('button', { name: /cost category/i }));
  await user.click(screen.getByText('Maintenance'));

  expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  expect(contextValue.setMode).not.toHaveBeenCalled();
});
```

---

## Case 3: Select revenue option on invoice mode — dialog appears

**Preconditions**: Form in `invoice` mode, popover open on Revenue tab.

**Steps**:

1. Switch to Revenue tab
2. Click "Common charges"
3. Assert confirmation dialog is visible

**Expected outcome**: Dialog appears before any state is modified.

**Example code**:

```typescript
it('shows confirmation dialog when selecting revenue option on invoice mode', async () => {
  setupMockLedgerOptions();
  const { user } = renderWithProviders(
    <InvoiceLineCostAndDistribution {...defaultProps} />,
    { contextOverrides: { mode: 'invoice' } },
  );

  await user.click(screen.getByRole('button', { name: /cost category/i }));
  await user.click(screen.getByRole('tab', { name: /revenue/i }));
  await user.click(screen.getByText('Common charges'));

  expect(screen.getByRole('dialog')).toBeInTheDocument();
});
```

---

## Case 4: Confirm conversion — mode and type code updated

**Preconditions**: Dialog is visible after selecting revenue option on invoice mode.

**Steps**:

1. Click "Confirm" in the dialog
2. Assert `setMode('credit_note')` was called
3. Assert `invoiceTypeCode` form value equals `'381'`

**Expected outcome**: Mode and type code updated synchronously on confirmation.

**Example code**:

```typescript
it('calls setMode credit_note and sets invoiceTypeCode to 381 on confirm', async () => {
  setupMockLedgerOptions();
  const { user, contextValue } = renderWithProviders(
    <InvoiceLineCostAndDistribution {...defaultProps} />,
    { contextOverrides: { mode: 'invoice' } },
  );

  await user.click(screen.getByRole('button', { name: /cost category/i }));
  await user.click(screen.getByRole('tab', { name: /revenue/i }));
  await user.click(screen.getByText('Common charges'));
  await user.click(screen.getByRole('button', { name: /confirm/i }));

  expect(contextValue.setMode).toHaveBeenCalledWith('credit_note');
});
```

---

## Case 5: Confirm with mixed lines — only 6xx lines updated

**Preconditions**: Form with 3 amounts: line 0 code `'601'`, line 1 code `'602'`, line 2 code `'701'`.

**Steps**:

1. On line 0, select revenue option "Common charges" (id `'ledger-701'`, code `'701'`)
2. Confirm dialog
3. Assert lines 0 and 1 have `costAccount` updated to `{ id: 'ledger-701', code: '701', name: 'Common charges' }`
4. Assert line 2's `costAccount.id` is still `'existing-7xx-id'` (unchanged)

**Expected outcome**: Bulk update applies only to 6xx lines; existing 7xx line is preserved.

**Example code**:

```typescript
it('bulk updates only 6xx lines and preserves existing 7xx lines', async () => {
  setupMockLedgerOptions();
  const amounts = [
    {
      ...defaultAmount,
      id: 'a1',
      costAccount: { id: 'c601', type: CostAccountType.LEDGER, code: '601', name: 'Maintenance' },
    },
    {
      ...defaultAmount,
      id: 'a2',
      costAccount: { id: 'c602', type: CostAccountType.LEDGER, code: '602', name: 'Cleaning' },
    },
    {
      ...defaultAmount,
      id: 'a3',
      costAccount: { id: 'existing-7xx-id', type: CostAccountType.LEDGER, code: '701', name: 'Existing revenue' },
    },
  ];

  const { user, getFormValues } = renderWithProviders(
    <InvoiceLinesTableV3 />,
    { formDefaults: { buildingId: 'building-1', amounts } },
  );

  // Open ledger select on line 0, pick revenue, confirm
  // ...

  const updatedAmounts = getFormValues().amounts;
  expect(updatedAmounts[0].costAccount?.id).toBe('ledger-701');
  expect(updatedAmounts[1].costAccount?.id).toBe('ledger-701');
  // Line 2 unchanged
  expect(updatedAmounts[2].costAccount?.id).toBe('existing-7xx-id');
});
```

---

## Case 6: Cancel dialog — no state changes

**Preconditions**: Dialog is visible after selecting revenue option on invoice mode.

**Steps**:

1. Click "Cancel" in the dialog
2. Assert `setMode` was NOT called
3. Assert no line `costAccount` values changed
4. Assert dialog is dismissed

**Expected outcome**: Cancel is a complete no-op.

**Example code**:

```typescript
it('does not change mode or lines when dialog is cancelled', async () => {
  setupMockLedgerOptions();
  const { user, contextValue } = renderWithProviders(
    <InvoiceLineCostAndDistribution {...defaultProps} />,
    { contextOverrides: { mode: 'invoice' } },
  );

  await user.click(screen.getByRole('button', { name: /cost category/i }));
  await user.click(screen.getByRole('tab', { name: /revenue/i }));
  await user.click(screen.getByText('Common charges'));
  await user.click(screen.getByRole('button', { name: /cancel/i }));

  expect(contextValue.setMode).not.toHaveBeenCalled();
  expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
});
```

---

## Case 7: Revenue selection on credit_note mode — no dialog

**Preconditions**: Form in `credit_note` mode.

**Steps**:

1. Open ledger select → Revenue tab → click "Common charges"
2. Assert no dialog appears
3. Assert `setMode` was NOT called (already credit_note)

**Expected outcome**: Direct selection without confirmation when already in credit note mode.

**Example code**:

```typescript
it('selects revenue option directly without dialog on credit_note mode', async () => {
  setupMockLedgerOptions();
  const { user, contextValue } = renderWithProviders(
    <InvoiceLineCostAndDistribution {...defaultProps} />,
    { contextOverrides: { mode: 'credit_note' } },
  );

  await user.click(screen.getByRole('button', { name: /cost category/i }));
  await user.click(screen.getByRole('tab', { name: /revenue/i }));
  await user.click(screen.getByText('Common charges'));

  expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  expect(contextValue.setMode).not.toHaveBeenCalled();
});
```

---

## Case 8: Revenue selection on expense_note mode — dialog appears

**Preconditions**: Form in `expense_note` mode.

**Steps**:

1. Open ledger select → Revenue tab → click "Common charges"
2. Assert confirmation dialog appears

**Expected outcome**: `expense_note` mode triggers the same dialog as `invoice` mode.

**Example code**:

```typescript
it('shows dialog when selecting revenue option on expense_note mode', async () => {
  setupMockLedgerOptions();
  const { user } = renderWithProviders(
    <InvoiceLineCostAndDistribution {...defaultProps} />,
    { contextOverrides: { mode: 'expense_note' } },
  );

  await user.click(screen.getByRole('button', { name: /cost category/i }));
  await user.click(screen.getByRole('tab', { name: /revenue/i }));
  await user.click(screen.getByText('Common charges'));

  expect(screen.getByRole('dialog')).toBeInTheDocument();
});
```

---

## Case 9: Lines with costAccount but no code — treated as expense

**Preconditions**: Form with 2 amounts: line 0 has `costAccount: { id: 'a', type: 'ledger' }` (no `code`); line 1 has `costAccount: { id: 'b', type: 'ledger', code: '601' }`.

**Steps**:

1. Select revenue option and confirm
2. Assert both lines have `costAccount` updated to the selected 7xx ledger

**Expected outcome**: Absent `code` defaults to expense-class behavior — line is included in bulk update.

---

## Case 10: Lines with no costAccount (undefined) — updated

**Preconditions**: Form with 1 amount where `costAccount` is `undefined`.

**Steps**:

1. Select revenue option and confirm
2. Assert the line's `costAccount` is set to the selected 7xx ledger

**Expected outcome**: Empty `costAccount` lines are populated during conversion.

---

## Case 11: Distribution sheet conversion flow

**Preconditions**: Invoice form with 3 lines (all 6xx). Distribution sheet opened for line 2. `InvoiceLinesTableV3` passes `mode` and `onCreditNoteConversion={convertToCreditNote}` into `PurchaseInvoiceAmountDistributionSheet` as props.

**Wiring note (Commit 4 deviation)**: The distribution sheet has an inner `FormProvider` that shadows the outer invoice form. `useCreditNoteConversion` is **not** called inside the sheet — conversion uses props from `InvoiceLinesTableV3` so bulk updates target the outer form's `amounts` array.

**Steps**:

1. In distribution sheet, open ledger select → Revenue tab → click "Common charges"
2. Confirm dialog
3. Assert outer form `mode` changed to `'credit_note'`
4. Assert all 3 outer form invoice lines have `costAccount` updated to selected 7xx ledger
5. Assert sheet's own cost category field shows selected 7xx

**Expected outcome**: Conversion triggered from within the distribution sheet applies to the entire outer invoice form.

---

## Case 12: FormHeader mode toggle does NOT update lines

**Preconditions**: Invoice has been converted to credit_note (all lines are 7xx). User uses FormHeader toggle to switch back to invoice mode.

**Steps**:

1. Via FormHeader, click mode toggle to switch from `credit_note` to `invoice`
2. Assert `setMode('invoice')` was called
3. Assert `invoiceTypeCode` is set to `undefined`
4. Assert all line `costAccount` values remain unchanged (still 7xx)

**Expected outcome**: The `FormHeader` mode toggle only changes `mode` and `invoiceTypeCode`. It never modifies line data. This is the key behavioral distinction from the `InlineLedgerSelect` 7xx selection.

**Example code**:

```typescript
it('FormHeader mode toggle does not modify line costAccount values', async () => {
  const amounts = [
    {
      ...defaultAmount,
      costAccount: { id: 'ledger-701', type: CostAccountType.LEDGER, code: '701', name: 'Common charges' },
    },
  ];

  const { user, getFormValues, contextValue } = renderWithProviders(
    <FormHeader />,
    {
      formDefaults: { amounts, invoiceTypeCode: '381' },
      contextOverrides: { mode: 'credit_note' },
    },
  );

  // Click mode toggle back to invoice
  await user.click(screen.getByRole('button', { name: /invoice/i }));

  expect(contextValue.setMode).toHaveBeenCalledWith('invoice');
  // Lines unchanged
  const updatedAmounts = getFormValues().amounts;
  expect(updatedAmounts[0].costAccount?.id).toBe('ledger-701');
});
```

---

## Case 13: Revenue tab excludes wrong-class options when value is backfilled 6xx

**Preconditions**: Supplier backfill (or manual set) has populated a line's `costAccount` with a full 6xx value (`code`, `name`, `id`). Mock options return both 6xx and 7xx ledgers.

**Steps**:

1. Open ledger select on the line with backfilled 6xx value
2. Assert trigger shows the 6xx label (name + code)
3. Switch to Revenue tab
4. Assert 7xx option names are visible
5. Assert 6xx option names are **not** in the Revenue list (including the selected 6xx — it must not be prepended onto the wrong tab)

**Expected outcome**: Tab class isolation via `matchesMotherCode` + `prepareAccountingLedgerOptions` prefix filter in `BuildingLedgerSelect.tsx` / `accountingLedgerOptionUtils.ts`. Trigger display is unchanged; only the Revenue tab list is filtered.

**Related**: [inline-selects.md](./inline-selects.md) IS-L11 covers the same UI behavior at the component level.

---

## Implementation

- **Date**: 2026-06-25
- **Cases done**: 12 / 13 (Case 11 deferred)
- **Test files**:
  - `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/ledger-credit-note-conversion.test.tsx` — Cases 1–10, 13
  - `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/ledgerSelectIntegrationHelpers.tsx` — shared mocks, UI helpers, `CreditNoteConversionHarness`
  - `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/ModeSwitching.test.tsx` — Case 12
- **Deviations**:
  - Trigger query uses `/select a cost category/i` (placeholder) or clicks the Cost category field button when a value is already set — not `/cost category/i`
  - `setupMockLedgerOptions` branches on `ACCOUNT_CLASS.REVENUE` (`'7'`) vs expenses default
  - Case 13 asserts `getAllByText('601 - Maintenance')` length is 1 (trigger only) because the selected label remains visible while the popover is open
  - Cases 9–10 also covered at hook level; integration tests assert end-to-end dialog → form state
  - Case 11 (distribution sheet) deferred to follow-up PR
- **Dropped cases**: none
- **Coverage gaps**: Case 11 — `PurchaseInvoiceAmountDistributionSheet` outer-form conversion
