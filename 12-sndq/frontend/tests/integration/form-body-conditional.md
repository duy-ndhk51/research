# FormBody Conditional Rendering

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/form-body.test.tsx`
**Component under test**: `FormBody` from `../sections/FormBody.tsx`

Tests verify that `FormBody` renders the correct sections based on form state (building/supplier selection, partial edit mode, AI extraction).

---

## IT-001: Shows placeholder when building/supplier not selected

**Preconditions**: Form loaded with default values (no `buildingId`, no `senderId`).

### Steps

1. Render `<FormBody />` with default context (no buildingId, no senderId, `supplierDefaults.isLoading = false`)

### Assertions

- Placeholder hint text is visible (translation key: `purchase_invoice.select_building_supplier_hint`)
- `InvoiceLinesTableV3` is NOT rendered
- `PaymentDetailsSection` is NOT rendered
- `OtherSection` is NOT rendered

### Example Code

```typescript
import { describe, it, expect, vi } from 'vitest';
import { screen } from '@testing-library/react';
import { renderWithProviders } from './test-wrapper';
import { FormBody } from '../../sections/FormBody';

describe('FormBody conditional rendering', () => {
  it('IT-001: shows placeholder when building/supplier not selected', () => {
    renderWithProviders(<FormBody />, {
      contextOverrides: {
        buildingId: undefined,
        senderId: undefined,
        supplierDefaults: { isLoading: false, defaults: null } as any,
      },
    });

    expect(
      screen.getByText(/select.*building.*supplier/i),
    ).toBeInTheDocument();

    expect(
      screen.queryByText(/payment details/i),
    ).not.toBeInTheDocument();
  });
});
```

---

## IT-002: Shows full form when building + supplier selected

**Preconditions**: Form loaded with `buildingId` and `senderId` set, supplier defaults loaded.

### Steps

1. Render `<FormBody />` with both IDs set and `supplierDefaults.isLoading = false`

### Assertions

- Placeholder hint is NOT visible
- Payment details section renders (look for "Payment details" heading)
- Other section renders (look for "Other" heading)

### Example Code

```typescript
import { defaultInvoiceFormV3Values } from '../../constants';

it('IT-002: shows full form when building + supplier selected', () => {
  renderWithProviders(<FormBody />, {
    contextOverrides: {
      buildingId: 'building-123',
      senderId: 'sender-456',
      supplierDefaults: { isLoading: false, defaults: null } as any,
    },
    formDefaults: {
      ...defaultInvoiceFormV3Values,
      buildingId: 'building-123',
      senderId: 'sender-456',
    },
  });

  expect(
    screen.queryByText(/select.*building.*supplier/i),
  ).not.toBeInTheDocument();

  expect(screen.getByText(/payment details/i)).toBeInTheDocument();
  expect(screen.getByText(/other/i)).toBeInTheDocument();
});
```

---

## IT-003: Shows partial edit mode warning

**Preconditions**: `isPartialEditMode = true`, buildingId + senderId set.

### Steps

1. Render `<FormBody />` with `isPartialEditMode: true`

### Assertions

- Warning banner visible with text matching `purchase_invoice.partial_edit_mode_title`
- At least one `<fieldset>` element has the `disabled` attribute
- Warning banner has warning styling class

### Example Code

```typescript
it('IT-003: shows partial edit mode warning banner', () => {
  renderWithProviders(<FormBody />, {
    contextOverrides: {
      isPartialEditMode: true,
      buildingId: 'building-123',
      senderId: 'sender-456',
      supplierDefaults: { isLoading: false, defaults: null } as any,
    },
    formDefaults: {
      ...defaultInvoiceFormV3Values,
      buildingId: 'building-123',
      senderId: 'sender-456',
    },
  });

  expect(
    screen.getByText(/partial edit mode/i),
  ).toBeInTheDocument();

  const fieldsets = document.querySelectorAll('fieldset[disabled]');
  expect(fieldsets.length).toBeGreaterThan(0);
});
```

---

## IT-004: Shows AI extraction overlay when extracting

**Preconditions**: AI extraction is in progress (`isExtracting = true`).

### Steps

1. Render `<FormBody />` with `aiExtraction.isExtracting = true`, buildingId + senderId set

### Assertions

- `AiExtractionOverlay` is present (renders an overlay element with absolute positioning)

### Example Code

```typescript
it('IT-004: shows AI extraction overlay when extracting', () => {
  renderWithProviders(<FormBody />, {
    contextOverrides: {
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
      buildingId: 'building-123',
      senderId: 'sender-456',
      supplierDefaults: { isLoading: false, defaults: null } as any,
    },
    formDefaults: {
      ...defaultInvoiceFormV3Values,
      buildingId: 'building-123',
      senderId: 'sender-456',
    },
  });

  // AiExtractionOverlay renders a positioned div when isExtracting is true
  const overlay = document.querySelector('[class*="absolute"]');
  expect(overlay).toBeInTheDocument();
});
```
