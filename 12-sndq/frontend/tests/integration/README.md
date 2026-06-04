# Integration Test Strategy — Purchase Invoice V3

## Purpose

Integration tests validate **behavioral contracts** across multiple components/providers with controlled dependencies. They sit between unit tests (pure logic) and E2E tests (full browser) in the test pyramid.

## What integration tests cover

- Cross-component state wiring (form context -> section rendering)
- Conditional rendering based on form state
- Mode switching side effects (invoice / credit note / expense note)
- Lock state transitions and their UI impact
- Right panel tab selection logic
- Form field interactions (auto-generate, date changes, AI indicators)

## What integration tests do NOT cover

- Real API calls (mocked via `vi.mock`)
- Routing / navigation
- Auth / session
- Full form submission flow (that is E2E territory)

## Tech Stack

- **Vitest** (test runner, already configured)
- **@testing-library/react** v16 (already in devDependencies)
- **@testing-library/user-event** (needs to be added: `pnpm add -D @testing-library/user-event`)
- **jsdom** (already configured in `vitest.config.mts`)

## File Location

Tests go in `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/` to match the existing `include: ['src/**/*.test.{js,ts,jsx,tsx}']` vitest config pattern.

## Shared Test Wrapper

All integration tests use a common wrapper that composes the required providers. This avoids repeating 50+ lines of setup per test.

```typescript
// src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/test-wrapper.tsx
import { render, type RenderOptions } from '@testing-library/react';
import { IntlProvider } from 'next-intl';
import type { ReactElement, ReactNode } from 'react';
import { FormProvider, useForm } from 'react-hook-form';
import { zodResolver } from '@/lib/form/zod-resolver';
import {
  purchaseInvoiceFormV2Schema,
  type PurchaseInvoiceFormV2Data,
} from '../../../purchase-invoice-v2/schema';
import {
  PurchaseInvoiceFormContext,
  type PurchaseInvoiceFormContextValue,
} from '../../contexts/PurchaseInvoiceFormContext';
import { AiExtractionProvider } from '../../../purchase-invoice-v2/contexts/AiExtractionContext';
import { defaultInvoiceFormV3Values } from '../../constants';
import type { DefaultValues } from 'react-hook-form';
import enMessages from '@/../messages/en/financial.json';
import enGeneral from '@/../messages/en/general.json';
import enPurchaseInvoice from '@/../messages/en/purchase_invoice.json';

const messages = {
  ...enMessages,
  ...enGeneral,
  ...enPurchaseInvoice,
};

export function createMockContextValue(
  overrides?: Partial<PurchaseInvoiceFormContextValue>,
): PurchaseInvoiceFormContextValue {
  return {
    invoiceId: null,
    peppolInvoiceId: null,
    isDraft: false,
    mode: 'invoice',
    setMode: vi.fn(),
    groupingStrategy: 'NONE' as any,
    setGroupingStrategy: vi.fn(),
    isPartialEditMode: false,
    lockState: { locked: false },
    setLockState: vi.fn(),
    toggleAmountLock: vi.fn(),
    sheetState: {
      showDiscardDialog: false,
      setShowDiscardDialog: vi.fn(),
      showDeleteDialog: false,
      setShowDeleteDialog: vi.fn(),
      handleSheetClose: vi.fn(),
      handleRequestDiscard: vi.fn(),
      openPreview: vi.fn(),
      closePreview: vi.fn(),
      closeSubSheet: vi.fn(),
      previewFile: null,
      showSupplierDetail: false,
      openSupplierDetail: vi.fn(),
      closeSupplierDetail: vi.fn(),
      openInvoiceSplit: vi.fn(),
      subSheet: { type: 'none' },
      amountsPreviewOpen: false,
      openAmountsPreview: vi.fn(),
      closeAmountsPreview: vi.fn(),
      mergeDialog: {
        open: false,
        pendingStrategy: null,
        onConfirm: vi.fn(),
        onCancel: vi.fn(),
      },
      setMergeDialog: vi.fn(),
    } as any,
    methods: {} as any,
    handleSubmit: vi.fn(),
    aiExtraction: {
      isExtracting: false,
      isExtracted: false,
      triggerExtraction: vi.fn(),
      dismissBanner: vi.fn(),
      getFieldConfidence: vi.fn().mockReturnValue(undefined),
      markFieldReviewed: vi.fn(),
      supplierVatNumber: undefined,
      customerVatNumber: undefined,
    },
    handleFileUploaded: vi.fn(),
    handleReparse: vi.fn(),
    handleOpenPreview: vi.fn(),
    peppolSupplierData: null,
    setPeppolSupplierData: vi.fn(),
    handlePeppolDataParsed: vi.fn(),
    onSubmit: vi.fn(),
    onError: vi.fn(),
    handleDiscard: vi.fn(),
    handleDelete: vi.fn(),
    isPending: false,
    isSuccess: false,
    isDeleting: false,
    buildingId: undefined,
    senderId: undefined,
    resolvedBuilding: null,
    resolvedContact: null,
    showSetSupplierDirectDebit: false,
    supplierDefaults: { isLoading: false, defaults: null } as any,
    properties: [],
    distributionKeys: [],
    isLoadingDistributionKeys: false,
    ledgerOptions: [],
    isLoadingLedgerOptions: false,
    comboActions: [],
    ...overrides,
  } as PurchaseInvoiceFormContextValue;
}

const mockAiExtraction = {
  isExtracted: false,
  getFieldConfidence: () => undefined,
  markFieldReviewed: vi.fn(),
  supplierVatNumber: undefined,
  customerVatNumber: undefined,
};

interface RenderWithProvidersOptions extends Omit<RenderOptions, 'wrapper'> {
  contextOverrides?: Partial<PurchaseInvoiceFormContextValue>;
  formDefaults?: DefaultValues<PurchaseInvoiceFormV2Data>;
  aiExtractionOverrides?: Partial<typeof mockAiExtraction>;
}

function FormWrapper({
  children,
  formDefaults,
  contextValue,
  aiExtractionValue,
}: {
  children: ReactNode;
  formDefaults: DefaultValues<PurchaseInvoiceFormV2Data>;
  contextValue: PurchaseInvoiceFormContextValue;
  aiExtractionValue: typeof mockAiExtraction;
}) {
  const methods = useForm<PurchaseInvoiceFormV2Data>({
    mode: 'onChange',
    resolver: zodResolver(purchaseInvoiceFormV2Schema),
    defaultValues: formDefaults,
  });

  return (
    <IntlProvider locale="en" messages={messages}>
      <PurchaseInvoiceFormContext.Provider value={contextValue}>
        <FormProvider {...methods}>
          <AiExtractionProvider value={aiExtractionValue}>
            {children}
          </AiExtractionProvider>
        </FormProvider>
      </PurchaseInvoiceFormContext.Provider>
    </IntlProvider>
  );
}

export function renderWithProviders(
  ui: ReactElement,
  options: RenderWithProvidersOptions = {},
) {
  const {
    contextOverrides,
    formDefaults = defaultInvoiceFormV3Values,
    aiExtractionOverrides,
    ...renderOptions
  } = options;

  const contextValue = createMockContextValue(contextOverrides);
  const aiExtractionValue = { ...mockAiExtraction, ...aiExtractionOverrides };

  return {
    ...render(ui, {
      wrapper: ({ children }) => (
        <FormWrapper
          formDefaults={formDefaults}
          contextValue={contextValue}
          aiExtractionValue={aiExtractionValue}
        >
          {children}
        </FormWrapper>
      ),
      ...renderOptions,
    }),
    contextValue,
  };
}
```

## Running Tests

```bash
# All integration tests
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/

# Specific test file
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/form-body.test.tsx

# Watch mode
pnpm test:watch src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/
```

## Naming Convention

- Test files: `{feature}.test.tsx`
- Scenario IDs: `IT-{NNN}` (sequential across all integration test files)
- Describe blocks: match the feature area
- Test names: start with scenario ID for traceability

## Scenario Index

### Form Body — Conditional Rendering ([form-body-conditional.md](./form-body-conditional.md))

**Purpose**: Guard the building + supplier prerequisite gate that controls which form sections are visible.
**Scope**: Placeholder rendering, section visibility toggles, disabled fieldsets in partial edit, AI overlay.
**Risk**: Form shows payment/amount fields before supplier is selected, causing validation errors. Partial edit exposes editable fields on booked invoices.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-001 | Placeholder when no building/supplier | Render `FormBody` with no buildingId/senderId → placeholder hint visible, no form sections | - [ ] |
| IT-002 | Full form when building + supplier selected | Render with both IDs → placeholder gone, payment + other sections visible | - [ ] |
| IT-003 | Partial edit mode warning banner | Render with `isPartialEditMode: true` → warning banner visible, fieldsets disabled | - [ ] |
| IT-004 | AI extraction overlay during extraction | Render with `isExtracting: true` → overlay element rendered over form | - [ ] |

### Lock State Toggle ([lock-state-toggle.md](./lock-state-toggle.md))

**Purpose**: Guard the lock state machine that controls whether invoice amounts can be edited.
**Scope**: Initial state derivation, toggle transitions (lock/unlock), computed `lockedTotal`, partial edit guard, Peppol auto-lock.
**Risk**: Amounts get unlocked on booked invoices (accounting inconsistency), or locked at zero from empty Peppol data (unusable form).

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-005 | Default lock state is unlocked | No peppol, no partial edit, no config → `{ locked: false }` | - [ ] |
| IT-005b | Auto-locks when peppolInvoiceId present | `peppolInvoiceId` set + initial amounts → `{ locked: true, lockedTotal: sum }` | - [ ] |
| IT-006 | Toggle unlocked → locked computes total | Start unlocked, toggle with 2 lines → `{ locked: true, lockedTotal: 3500 }` | - [ ] |
| IT-007 | Toggle locked → unlocked | Start `{ locked: true, lockedTotal: 5000 }`, toggle → `{ locked: false }` | - [ ] |
| IT-008 | Toggle is no-op in partial edit mode | `isPartialEditMode: true`, toggle → state unchanged | - [ ] |

### Mode Switching ([mode-switching.md](./mode-switching.md))

**Purpose**: Guard the type code mapping between UI mode and `invoiceTypeCode` form value. The backend uses this code to determine invoice processing.
**Scope**: `MODE_TO_TYPE_CODE` mapping consistency, default values per mode, round-trip switching.
**Risk**: Credit notes submitted as regular invoices (wrong type code), or expense notes processed with invoice logic. Backend rejects or misclassifies the document.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-009 | Default mode is invoice (no type code) | Check `defaultInvoiceFormV3Values.invoiceTypeCode` → `undefined` | - [ ] |
| IT-009b | Credit note defaults have CREDIT_NOTE code | Check `defaultCreditNoteFormV3Values.invoiceTypeCode` → `'381'` | - [ ] |
| IT-010 | Switch to credit_note sets type code | Lookup `MODE_TO_TYPE_CODE['credit_note']` → `'381'` | - [ ] |
| IT-011 | Switch to expense_note sets type code | Lookup `MODE_TO_TYPE_CODE['expense_note']` → `EXPENSE_NOTE_TYPE_CODE` | - [ ] |
| IT-012 | Switch back to invoice clears type code | Lookup `MODE_TO_TYPE_CODE['invoice']` → `undefined` | - [ ] |

### Right Panel Tabs ([right-panel-tabs.md](./right-panel-tabs.md))

**Purpose**: Guard the tab defaulting logic that determines whether users see the file uploader or Peppol attachments first.
**Scope**: Tab selection priority (user override > Peppol default > uploader fallback), lock trigger on Peppol parse.
**Risk**: Users see empty uploader instead of Peppol attachments. Or Peppol data parsing silently fails to trigger lock state.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-013 | Default tab is uploader (no peppol) | No `peppolData` → active tab is `'uploader'` | - [ ] |
| IT-014 | Default tab is attachments (peppol has files) | `peppolData.attachments` has entries → active tab is `'attachments'` | - [ ] |
| IT-015 | User tab selection overrides default | Peppol attachments present but user selects `'uploader'` → stays `'uploader'` | - [ ] |
| IT-016 | Peppol amounts parsed triggers lock | `safePeppolDataParsed` with amounts → `setLockState({ locked: true, lockedTotal })` | - [ ] |
| IT-016b | Peppol with no amounts skips lock | `safePeppolDataParsed` with `[]` → `setLockState` NOT called | - [ ] |

### Invoice Fields ([invoice-fields.md](./invoice-fields.md))

**Purpose**: Guard auto-number generation format, date bounds enforcement, and AI confidence indicator lifecycle.
**Scope**: Locale-aware number prefixes (`INV`/`AF`/`CN`), toggle on/off, `markFieldReviewed` reset, date formatting, bounds validation.
**Risk**: Invoice numbers in wrong format per locale, dates outside legal fiscal year bounds, AI indicators stuck after manual edit.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-017 | Auto-generate invoice number | `generateInvoiceNumber('invoice', 'en')` → matches `INV-{YEAR}-{NNN}` | - [ ] |
| IT-018 | Toggle off clears invoice number | Toggle auto-generate off → `setValue('invoiceNumber', '')` | - [ ] |
| IT-019 | Manual edit resets auto-generated state | Type in number → `markFieldReviewed` + `autoNumber.reset()` called | - [ ] |
| IT-020 | Date picker sets formatted date | Select June 15 → `setValue('invoiceDate', '2026-06-15')` + `markFieldReviewed` | - [ ] |
| IT-020b | Invoice date bounds enforced | `getInvoiceDateBounds()` → min is Jan 1, max is today | - [ ] |
| IT-021 | AI confidence indicators visibility | `getFieldConfidence` returns 0.85 → indicator visible; undefined → hidden | - [ ] |

### Peppol to Invoice ([peppol-to-invoice.md](./peppol-to-invoice.md))

**Purpose**: Verify the wiring between `transformPeppolToFormData` output and React Hook Form `setValue` calls. The transform is unit-tested; these tests cover the last mile where data reaches the form. Highest-priority group — Peppol is the #1 daily flow.
**Scope**: Full field population, supplier matching/unmatching, credit note type propagation, Belgian OGM parsing, lock total computation, amount grouping with `originalLines`.
**Risk**: Peppol invoices open with empty/wrong fields, unmatched suppliers get stale senderId, credit notes treated as invoices, OGM references lost, lock total miscalculated, grouped amounts lose original line detail.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-022 | Peppol populates all form fields | `handlePeppolDataParsed` with full data → all fields set via `setValue` | - [ ] |
| IT-023 | Empty Peppol amounts produce zero-lock | Peppol `lines: []` → `lockedTotal: 0` (known UX edge case) | - [ ] |
| IT-024 | Unmatched supplier resets senderId | No `supplierPartyContactId` → `resetField('senderId')`, supplier data stored | - [ ] |
| IT-025 | Matched supplier sets senderId | `supplierPartyContactId` exists → `setValue('senderId')`, supplier data cleared | - [ ] |
| IT-026 | Peppol credit note typeCode flows to form | `typeCode: '381'` → form `invoiceTypeCode` is `'381'` | - [ ] |
| IT-027 | Belgian OGM structured remittance | `+++123/4567/89002+++` → parsed to `'123456789002'`, typed STRUCTURED | - [ ] |
| IT-028 | Lock total matches Peppol amounts sum | Multi-line Peppol → `sumTotalAmounts` → config `{ locked: true, lockedTotal }` | - [ ] |
| IT-029 | Grouping preserves originalLines and total | Switch individual → group by VAT → same total, `originalLines` preserved | - [ ] |
