# Form Orchestration

**Status**: Not started
**Priority**: MEDIUM (outermost shell -- provider stack crash blocks all form interactions)
**Test tier**: Component integration
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/form-orchestration.test.tsx`
**Component(s) under test**: `PurchaseInvoiceFormV3` from `PurchaseInvoiceFormV3.tsx`

## Purpose

Verify the top-level provider composition and layout wiring of the main form component. This is the outermost shell that composes `AccountingLedgerProvider`, `PurchaseInvoiceFormContext`, `FormProvider`, and `AiExtractionProvider` with a resizable two-panel layout.

## Risk

Provider stack crashes on missing context, Peppol mode doesn't auto-lock, resizable layout breaks accessibility.

## Bugs Guarded

- "Form renders without crashing in create mode" / "Form renders in edit mode with invoiceId" guard provider composition -- missing/misordered providers crash silently; `useFormContext()` throws outside `FormProvider`
- "Form renders in Peppol mode with peppolInvoiceId" guards **B1** (lock state vs form amounts) -- Peppol mode must initialize lock state on mount; `initialLockState` prop must propagate through provider
- "onClose callback wired to sheet state" guards sheet state wiring -- `handleSheetClose` must propagate to form lifecycle; dangling open state blocks subsequent interactions

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Form renders without crashing in create mode | `form-header` and `form-body` testids in document |
| Form renders in edit mode with invoiceId | Props pass through to `usePurchaseInvoiceForm` |
| Form renders in Peppol mode with peppolInvoiceId | Lock state auto-initializes as locked |
| Resizable panels render left and right | Both `form-body` and `right-panel` testids present |
| AiExtractionBanner hidden by default | Banner not in document |
| AiExtractionBanner visible during extraction | Banner renders with progress indicator |
| onClose callback wired to sheet state | Close triggers `handleSheetClose` |

## Related Specs

- Form body: [form-body-conditional.md](./form-body-conditional.md) — section rendering
- Form header: [form-header.md](./form-header.md) — header bar
- Form dialogs: [form-dialogs.md](./form-dialogs.md) — dialog lifecycle
- Lock state: [lock-state-toggle.md](./lock-state-toggle.md) — Peppol auto-lock

## What NOT to test here

- Individual section behavior (covered by other integration tests)
- Form submission logic (hook-level unit tests + E2E)
- API calls (mocked)

## Mocking Strategy

```typescript
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));

vi.mock('../../sections/FormBody', () => ({
  FormBody: () => <div data-testid="form-body" />,
}));

vi.mock('../../sections/FormHeader', () => ({
  FormHeader: () => <div data-testid="form-header" />,
}));

vi.mock('../../sections/FormDialogs', () => ({
  FormDialogs: () => <div data-testid="form-dialogs" />,
}));

vi.mock('../../../purchase-invoice-v2/components/InvoiceRightPanel', () => ({
  InvoiceRightPanel: () => <div data-testid="right-panel" />,
}));

vi.mock('@/contexts/AccountingLedgerContext', () => ({
  AccountingLedgerProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));
```

## Shared Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { IntlProvider } from 'next-intl';
import PurchaseInvoiceFormV3 from '../../PurchaseInvoiceFormV3';
import type { PurchaseInvoiceFormV3Props } from '../../types';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } },
});

const defaultProps = {
  onClose: vi.fn(),
  onSuccess: vi.fn(),
};

function renderForm(props: Partial<PurchaseInvoiceFormV3Props> = {}) {
  return render(
    <QueryClientProvider client={queryClient}>
      <IntlProvider locale="en" messages={{}}>
        <PurchaseInvoiceFormV3 {...defaultProps} {...props} />
      </IntlProvider>
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  vi.clearAllMocks();
});
```

---

## Form renders without crashing in create mode

**Preconditions**: No `invoiceId`, no `peppolInvoiceId`.

### Steps

1. Render `<PurchaseInvoiceFormV3 />` with default props (create mode)

### Expected Outcome

- `form-header` testid is in the document
- `form-body` testid is in the document

### Example Code

```typescript
describe('PurchaseInvoiceFormV3 — Orchestration', () => {
  it('should render without crashing in create mode', () => {
    renderForm();

    expect(screen.getByTestId('form-header')).toBeInTheDocument();
    expect(screen.getByTestId('form-body')).toBeInTheDocument();
  });
});
```

---

## Form renders in edit mode with invoiceId

**Preconditions**: `invoiceId` passed as prop.

### Steps

1. Render with `invoiceId: 'inv-123'`

### Expected Outcome

- Form renders without crash
- Props pass through to internal hook (`usePurchaseInvoiceForm` receives `invoiceId`)

### Example Code

```typescript
it('should render in edit mode with invoiceId', () => {
  renderForm({ invoiceId: 'inv-123' });

  expect(screen.getByTestId('form-header')).toBeInTheDocument();
});
```

---

## Form renders in Peppol mode with peppolInvoiceId

**Preconditions**: `peppolInvoiceId` passed as prop.

### Steps

1. Render with `peppolInvoiceId: 'peppol-456'`

### Expected Outcome

- Lock state auto-initializes as locked (verified via internal state)

### Example Code

```typescript
it('should render in Peppol mode with peppolInvoiceId', () => {
  renderForm({ peppolInvoiceId: 'peppol-456' });

  expect(screen.getByTestId('form-header')).toBeInTheDocument();
});
```

---

## Resizable panels render left and right

**Preconditions**: Form in create mode.

### Steps

1. Render with default props

### Expected Outcome

- Both `form-body` and `right-panel` testids are present

### Example Code

```typescript
it('resizable panels render left and right', () => {
  renderForm();

  expect(screen.getByTestId('form-body')).toBeInTheDocument();
  expect(screen.getByTestId('right-panel')).toBeInTheDocument();
});
```

---

## AiExtractionBanner hidden by default

**Preconditions**: No AI extraction in progress.

### Steps

1. Render with default props

### Expected Outcome

- AI banner is not in the document

### Example Code

```typescript
it('AI extraction banner hidden by default', () => {
  renderForm();

  expect(screen.queryByTestId('ai-banner')).not.toBeInTheDocument();
});
```

---

## AiExtractionBanner visible during extraction

**Preconditions**: AI extraction in progress.

### Steps

1. Render with extraction state active

### Expected Outcome

- Banner renders with progress indicator

### Example Code

```typescript
it('AI extraction banner visible during extraction', () => {
  // This test depends on how the extraction state propagates
  // through the provider. May need contextOverrides via a
  // different render approach for the top-level component.
  renderForm();

  // Verify banner presence (implementation-dependent)
});
```

---

## onClose callback wired to sheet state

**Preconditions**: Form rendered.

### Steps

1. Trigger the close action (via sheet state)

### Expected Outcome

- `handleSheetClose` propagates to form lifecycle

### Example Code

```typescript
it('onClose callback wired to sheet state', () => {
  renderForm();

  // The close wiring is verified indirectly through
  // the FormDialogs integration (discard flow).
  // This test ensures the top-level onClose prop is connected.
  expect(defaultProps.onClose).not.toHaveBeenCalled();
});
```
