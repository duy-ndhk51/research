# FormBody Conditional Rendering

**Status**: Done
**Priority**: HIGH (gates all form sections behind building + supplier prerequisite)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/FormBody.test.tsx`
**Component(s) under test**: `FormBody` from `../sections/FormBody.tsx`

## Purpose

Guard the building + supplier prerequisite gate and partial-edit boundaries that control which form sections are visible and editable.

## Risk

Form exposes payment/amount fields before supplier is selected (causing validation errors on submit). Partial edit mode allows editing locked-down fields on booked invoices.

## Bugs Guarded

- "placeholder" test guards partial edit boundary -- ensures the `hasRequiredInfo` gate (`!!buildingId && !!senderId && !supplierDefaults.isLoading`) hides gated sections (lines, payment, due date, other) while keeping always-visible sections (building/supplier selects, invoice fields) rendered
- "full form" test guards section completeness -- regression catches missing sections after refactors; verifies all 4 gated sections render AND all always-visible sections remain present
- "partial edit disables building/supplier/payment only" test guards partial edit boundary -- verifies disabled fieldsets match what users can actually change in partial edit; `fieldset disabled` only wraps building/supplier + payment, not amounts/dates
- "AI extraction overlay during extraction" test guards the AI overlay lifecycle -- prevents stale overlay remaining after extraction completes

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Placeholder when no building/supplier | Hint text visible; gated sections (lines, payment, due date, other) NOT rendered; always-visible sections (info card, building/supplier selects, invoice fields) still rendered |
| Full form when building + supplier selected | Placeholder gone; all sections rendered: info card (building select, supplier select, invoice number, invoice date), amount lines, payment details (payment method, due date), other (deferred cost, utility toggle) |
| Partial edit disables building/supplier/payment only | Exactly 2 disabled fieldsets; invoice fields, lines, due date, other remain editable |
| AI extraction overlay during extraction | Overlay element rendered when `isExtracting: true` |

## Related Specs

- Lock state in form: [lock-state-toggle.md](./lock-state-toggle.md)
- AI extraction: [form-orchestration.md](./form-orchestration.md) — banner lifecycle

## Mocking Strategy

```typescript
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));

vi.mock('../components/InlineBuildingSelect', () => ({
  InlineBuildingSelect: () => <div data-testid="building-select">Building Select</div>,
}));

vi.mock('../components/InlineSupplierSelect', () => ({
  ConnectedInlineSupplierSelect: () => <div data-testid="supplier-select">Supplier Select</div>,
}));

vi.mock('./InvoiceFieldsSection', () => ({
  InvoiceFieldsSection: () => (
    <div data-testid="invoice-fields-section">
      <div data-testid="invoice-number-field">Invoice Number</div>
      <div data-testid="invoice-date-field">Invoice Date</div>
    </div>
  ),
}));

vi.mock('./CreditNoteSection', () => ({
  CreditNoteSection: () => <div data-testid="credit-note-section" />,
}));

vi.mock('../components/invoice-lines', () => ({
  InvoiceLinesTableV3: () => <div data-testid="invoice-lines-table">Invoice Lines</div>,
}));

vi.mock('./PaymentDetailsSection', () => ({
  PaymentDetailsSection: () => <div data-testid="payment-section">Payment Details</div>,
}));

vi.mock('./DueDateField', () => ({
  ConnectedDueDateField: () => <div data-testid="due-date-field">Due Date</div>,
}));

vi.mock('./OtherSection', () => ({
  OtherSection: () => <div data-testid="other-section">Other Section</div>,
}));

vi.mock('./AiExtractionOverlay', () => ({
  AiExtractionOverlay: ({ isExtracting }: { isExtracting: boolean }) =>
    isExtracting ? <div data-testid="ai-extraction-overlay" /> : null,
}));
```

## Shared Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen } from '@testing-library/react';
import { renderWithProviders } from '../utils';
import { FormBody } from '../../sections/FormBody';
import { defaultInvoiceFormV3Values } from '../../constants';

const withBuildingAndSupplier = {
  contextOverrides: {
    buildingId: 'building-123',
    senderId: 'sender-456',
    supplierDefaults: { isLoading: false, defaults: {} },
  },
  formDefaults: {
    ...defaultInvoiceFormV3Values,
    buildingId: 'building-123',
    senderId: 'sender-456',
  },
};

beforeEach(() => {
  vi.clearAllMocks();
});
```

---

## Shows placeholder when building/supplier not selected

**Preconditions**: Form loaded with default values (no `buildingId`, no `senderId`).

### Steps

1. Render `<FormBody />` with default context (no buildingId, no senderId, `supplierDefaults.isLoading = false`)

### Expected Outcome

**Placeholder visible:**
- Placeholder hint text is visible (translation key: `purchase_invoice.select_building_supplier_hint`)

**Gated sections NOT rendered** (behind `hasRequiredInfo` gate):
- `InvoiceLinesTableV3` is NOT rendered
- `PaymentDetailsSection` is NOT rendered
- `ConnectedDueDateField` is NOT rendered
- `OtherSection` is NOT rendered

**Always-visible sections still rendered** (outside gate):
- `InlineBuildingSelect` is rendered
- `ConnectedInlineSupplierSelect` is rendered
- `InvoiceFieldsSection` is rendered (invoice number + invoice date)
- `CreditNoteSection` is rendered (returns null for non-credit-note mode, but the component is mounted)

### Example Code

```typescript
describe('FormBody conditional rendering', () => {
  it('shows placeholder when building/supplier not selected', () => {
    renderWithProviders(<FormBody />, {
      contextOverrides: {
        buildingId: undefined,
        senderId: undefined,
        supplierDefaults: { isLoading: false, defaults: {} },
      },
    });

    // --- Placeholder visible ---
    expect(
      screen.getByText(/purchase_invoice.select_building_supplier_hint/),
    ).toBeInTheDocument();

    // --- Gated sections NOT rendered ---
    expect(screen.queryByTestId('invoice-lines-table')).not.toBeInTheDocument();
    expect(screen.queryByTestId('payment-section')).not.toBeInTheDocument();
    expect(screen.queryByTestId('due-date-field')).not.toBeInTheDocument();
    expect(screen.queryByTestId('other-section')).not.toBeInTheDocument();

    // --- Always-visible sections still rendered ---
    expect(screen.getByTestId('building-select')).toBeInTheDocument();
    expect(screen.getByTestId('supplier-select')).toBeInTheDocument();
    expect(screen.getByTestId('invoice-fields-section')).toBeInTheDocument();
    expect(screen.getByTestId('credit-note-section')).toBeInTheDocument();
  });
});
```

---

## Shows full form when building + supplier selected

**Preconditions**: Form loaded with `buildingId` and `senderId` set, supplier defaults loaded.

### Steps

1. Render `<FormBody />` with both IDs set and `supplierDefaults.isLoading = false`

### Expected Outcome

**Placeholder hidden:**
- Placeholder hint text is NOT visible

**Always-visible sections (Info card):**
- Building select rendered
- Supplier select rendered
- Invoice number field rendered
- Invoice date field rendered
- Credit note section rendered (returns null in invoice mode)

**Gated sections (visible because `hasRequiredInfo = true`):**
- `InvoiceLinesTableV3` -- amount lines section
- `PaymentDetailsSection` -- payment method (bank payment / direct debit)
- `ConnectedDueDateField` -- due date picker (inside payment card, outside the disabled fieldset)
- `OtherSection` -- deferred cost toggle + utility toggle

**Section card headings visible:**
- Info card: `general.info_short`
- Amount card: heading via `InvoiceLinesTableV3` (renders `general.amount`)
- Payment card: `purchase_invoice.payment_details`
- Other card: `general.other`

### Example Code

```typescript
it('shows full form when building + supplier selected', () => {
  renderWithProviders(<FormBody />, {
    ...withBuildingAndSupplier,
  });

  // --- Placeholder hidden ---
  expect(
    screen.queryByText(/purchase_invoice.select_building_supplier_hint/),
  ).not.toBeInTheDocument();

  // --- Always-visible sections (Info card) ---
  expect(screen.getByTestId('building-select')).toBeInTheDocument();
  expect(screen.getByTestId('supplier-select')).toBeInTheDocument();
  expect(screen.getByTestId('invoice-number-field')).toBeInTheDocument();
  expect(screen.getByTestId('invoice-date-field')).toBeInTheDocument();
  expect(screen.getByTestId('credit-note-section')).toBeInTheDocument();

  // --- Gated sections (now visible) ---
  expect(screen.getByTestId('invoice-lines-table')).toBeInTheDocument();
  expect(screen.getByTestId('payment-section')).toBeInTheDocument();
  expect(screen.getByTestId('due-date-field')).toBeInTheDocument();
  expect(screen.getByTestId('other-section')).toBeInTheDocument();

  // --- Section card headings ---
  expect(screen.getByText(/general.info_short/)).toBeInTheDocument();
  expect(screen.getByText(/purchase_invoice.payment_details/)).toBeInTheDocument();
  expect(screen.getByText(/general.other/)).toBeInTheDocument();
});
```

---

## Partial edit disables building/supplier/payment but keeps invoice fields, lines, due date, and other editable

**Preconditions**: `isPartialEditMode = true`, buildingId + senderId set.

### Steps

1. Render `<FormBody />` with `isPartialEditMode: true`

### Expected Outcome

- Warning banner visible with text matching `purchase_invoice.partial_edit_mode_title`
- Exactly 2 `<fieldset>` elements have the `disabled` attribute (building/supplier fieldset + payment fieldset)
- Building select label is inside a disabled fieldset
- Supplier select label is inside a disabled fieldset
- Payment method label is inside a disabled fieldset
- Invoice number input is NOT inside a disabled fieldset
- Invoice date label is NOT inside a disabled fieldset
- Due date label is NOT inside a disabled fieldset

### Example Code

```typescript
it('disables building/supplier/payment but keeps invoice fields, lines, due date, and other editable', () => {
  renderWithProviders(<FormBody />, {
    ...withBuildingAndSupplier,
    contextOverrides: {
      ...withBuildingAndSupplier.contextOverrides,
      isPartialEditMode: true,
    },
  });

  // Warning banner is visible
  expect(screen.getByText(/partial edit mode/i)).toBeInTheDocument();

  // Exactly 2 disabled fieldsets (building/supplier + payment)
  const disabledFieldsets = document.querySelectorAll('fieldset[disabled]');
  expect(disabledFieldsets).toHaveLength(2);

  // Building select is inside a disabled fieldset
  const buildingLabel = screen.getByText(/building/i);
  expect(buildingLabel.closest('fieldset')).toHaveAttribute('disabled');

  // Supplier select is inside a disabled fieldset
  const supplierLabel = screen.getByText(/supplier/i);
  expect(supplierLabel.closest('fieldset')).toHaveAttribute('disabled');

  // Payment method section is inside a disabled fieldset
  const paymentMethodLabel = screen.getByText(/payment method/i);
  expect(paymentMethodLabel.closest('fieldset')).toHaveAttribute('disabled');

  // --- Fields that MUST remain editable ---

  // Invoice number input is NOT inside a disabled fieldset
  const invoiceNumberInput = screen.getByPlaceholderText(/placeholder/i);
  expect(invoiceNumberInput.closest('fieldset[disabled]')).toBeNull();

  // Invoice date is NOT disabled
  const invoiceDateLabel = screen.getByText(/invoice date/i);
  expect(invoiceDateLabel.closest('fieldset[disabled]')).toBeNull();

  // Due date is NOT disabled
  const dueDateLabel = screen.getByText(/due date/i);
  expect(dueDateLabel.closest('fieldset[disabled]')).toBeNull();
});
```

---

## Shows AI extraction overlay when extracting

**Preconditions**: AI extraction is in progress (`isExtracting = true`).

### Steps

1. Render `<FormBody />` with `aiExtraction.isExtracting = true`, buildingId + senderId set

### Expected Outcome

- `AiExtractionOverlay` is present (`data-testid="ai-extraction-overlay"`)
- All form sections still render underneath the overlay

### Example Code

```typescript
it('shows AI extraction overlay when extracting', () => {
  renderWithProviders(<FormBody />, {
    ...withBuildingAndSupplier,
    contextOverrides: {
      ...withBuildingAndSupplier.contextOverrides,
      aiExtraction: {
        isExtracting: true,
        isExtracted: false,
        triggerExtraction: vi.fn(),
        dismissBanner: vi.fn(),
        getFieldConfidence: vi.fn(),
        markFieldReviewed: vi.fn(),
        supplierVatNumber: undefined,
        customerVatNumber: undefined,
      },
    },
  });

  expect(screen.getByTestId('ai-extraction-overlay')).toBeInTheDocument();

  // Form sections still render underneath
  expect(screen.getByTestId('invoice-lines-table')).toBeInTheDocument();
  expect(screen.getByTestId('payment-section')).toBeInTheDocument();
});
```

---

## Implementation

**Implemented**: 2026-06-14
**Test file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/FormBody.test.tsx`
**Cases**: 4/4 implemented

### Deviations from spec

- **Translation handling**: `renderWithProviders` wraps components in a real `IntlProvider` with `testMessages`, so assertions use literal English strings (`'Select a building and supplier to continue'`, `'Limited editing'`) instead of translation keys (`purchase_invoice.select_building_supplier_hint`).
- **Mock import paths**: Mocks use `../../sections/` and `../../components/` (relative from test file location inside `__tests__/integration/`), not `./` as in the spec's proposed mocking strategy.
- **InvoiceFieldsSection mock simplified**: Spec proposed sub-testids (`invoice-number-field`, `invoice-date-field`) inside the mock. Implementation uses a single `<div data-testid="invoice-fields-section">` since the test only checks section presence, not individual fields.
- **Partial edit case strengthened**: Originally implemented with only fieldset count assertion (`toHaveLength(2)`). Improved with 7 per-component fieldset boundary assertions using `closest('fieldset[disabled]')` to verify exactly which components are inside/outside disabled fieldsets.
- **Shared fixtures extracted**: Spec defined `withBuildingAndSupplier` inline in Shared Setup. Implementation extracts it to `mockFactories.ts` for reuse across test files. `withAiExtracting` extends it with AI extraction state.
- **DOM cleanup**: Added `cleanup()` in `beforeEach` (not in spec) to ensure DOM isolation between tests.

### Dropped cases

None — all 4 cases implemented.

### Coverage gaps

- **Section card headings** (`general.info_short`, `purchase_invoice.payment_details`, `general.other`) from the "full form" spec are not asserted. The test verifies section presence via `data-testid` but not heading text.
- **Partial edit**: Does not assert that invoice lines and "other" sections remain *editable* (only that they are not inside disabled fieldsets). True editability depends on child component internals, which are mocked.

### Actual mocking strategy

Mock paths differ from spec (`../../sections/` vs `./`). `next-intl` is NOT mocked — handled by `renderWithProviders` with real `IntlProvider`.

```typescript
vi.mock('../../components/InlineBuildingSelect', () => ({
  InlineBuildingSelect: () => <div data-testid="building-select">Building Select</div>,
}));
vi.mock('../../components/InlineSupplierSelect', () => ({
  ConnectedInlineSupplierSelect: () => <div data-testid="supplier-select">Supplier Select</div>,
}));
vi.mock('../../sections/InvoiceFieldsSection', () => ({
  InvoiceFieldsSection: () => <div data-testid="invoice-fields-section">Invoice Fields</div>,
}));
vi.mock('../../sections/CreditNoteSection', () => ({
  CreditNoteSection: () => <div data-testid="credit-note-section" />,
}));
vi.mock('../../components/invoice-lines', () => ({
  InvoiceLinesTableV3: () => <div data-testid="invoice-lines-table">Invoice Lines</div>,
}));
vi.mock('../../sections/PaymentDetailsSection', () => ({
  PaymentDetailsSection: () => <div data-testid="payment-section">Payment Details</div>,
}));
vi.mock('../../sections/DueDateField', () => ({
  ConnectedDueDateField: () => <div data-testid="due-date-field">Due Date</div>,
}));
vi.mock('../../sections/OtherSection', () => ({
  OtherSection: () => <div data-testid="other-section">Other Section</div>,
}));
vi.mock('../../sections/AiExtractionOverlay', () => ({
  AiExtractionOverlay: ({ isExtracting }: { isExtracting: boolean }) =>
    isExtracting ? <div data-testid="ai-extraction-overlay" /> : null,
}));
```

### Shared fixtures

- `withBuildingAndSupplier` from `mockFactories.ts` — provides `buildingId`, `senderId`, `supplierDefaults` context + matching form defaults
- `withAiExtracting` from `mockFactories.ts` — extends `withBuildingAndSupplier` with `aiExtraction.isExtracting: true`

### Condensed test code

```typescript
describe('FormBody conditional rendering', () => {
  it('shows placeholder when building/supplier not selected', () => {
    renderWithProviders(<FormBody />, { contextOverrides: { supplierDefaults: { isLoading: false, defaults: null } } });
    expect(screen.getByText('Select a building and supplier to continue')).toBeInTheDocument();
    // 4 gated sections NOT rendered, 4 always-visible sections rendered
  });

  it('shows full form when building + supplier selected', () => {
    renderWithProviders(<FormBody />, withBuildingAndSupplier);
    // placeholder gone, all 8 sections rendered
  });

  it('disables building/supplier/payment in partial edit mode', () => {
    renderWithProviders(<FormBody />, { ...withBuildingAndSupplier, contextOverrides: { isPartialEditMode: true } });
    expect(screen.getByText('Limited editing')).toBeInTheDocument();
    expect(document.querySelectorAll('fieldset[disabled]')).toHaveLength(2);
    // building-select, supplier-select, payment-section inside disabled fieldset
    // invoice-fields, lines, due-date, other outside disabled fieldset
  });

  it('shows AI extraction overlay when extracting', () => {
    renderWithProviders(<FormBody />, withAiExtracting);
    expect(screen.getByTestId('ai-extraction-overlay')).toBeInTheDocument();
    // form sections still render underneath
  });
});
```
