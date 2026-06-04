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
- Amount distribution sheet (unit selection, distribution types, suggestions, validation)
- Supplier defaults wiring (backfill empty lines, auto-save on submit)

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

**Purpose**: Guard the tab defaulting logic that determines whether users see the file uploader or Peppol attachments first. Uses `hasPeppolData` (not `hasAttachments`) as the primary condition — the tab appears whenever Peppol data exists, with content varying based on attachment file presence.
**Scope**: Tab selection priority (user override > Peppol default > uploader fallback), content switching (PeppolAttachmentsTab vs PeppolParsedPreview), hideInlineAttachments, lock trigger on Peppol parse.
**Risk**: Users see empty uploader instead of Peppol data. PeppolParsedPreview rendered in both tabs (duplicate). Tab disappears when it should still show parsed data.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-013 | Default tab is uploader (no peppol data) | No `peppolData` → active tab is `'uploader'`, no extra tabs | - [ ] |
| IT-013b | Peppol data without attachments shows PeppolParsedPreview | `peppolData` exists, empty attachments → tab content is `PeppolParsedPreview`, `hideInlineAttachments: true` | - [ ] |
| IT-013c | Peppol data cleared removes tab | `peppolData` cleared → extra tabs empty, falls back to `'uploader'` | - [ ] |
| IT-014 | Peppol with attachment files shows PeppolAttachmentsTab | `peppolData.attachments` has entries → tab content is `PeppolAttachmentsTab` | - [ ] |
| IT-015 | User tab selection overrides default | Peppol data present but user selects `'uploader'` → stays `'uploader'` | - [ ] |
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

### Amount Distribution Sheet ([amount-distribution-sheet.md](./amount-distribution-sheet.md))

**Purpose**: Guard the distribution sheet UI lifecycle: unit initialization from building properties, distribution type switching (share/percentage/free/split_later/DK), share/amount recalculation, ledger and DK suggestions, and form validation.
**Scope**: Sheet open/close, loading states, edit mode pre-fill, all 5 distribution types, whole building toggle, individual/bulk selection, amount redistribution on total change, suggestion chip interactions, total mismatch validation dialog, unit search/sort.
**Risk**: Units not initialized on sheet open, distribution type switch corrupts amounts, DK mode doesn't force whole building, amount mismatch undetected, suggestions don't populate form fields.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-030 | Loading state shows spinner | Sheet open + properties pending → spinner shown, no form | - [ ] |
| IT-031 | Properties loaded initializes units | Sheet open + 3 properties → 3 unit rows, all unselected, amount 0 | - [ ] |
| IT-032 | Edit mode pre-fills from editingItem | Open with saved line → form resets to prior values | - [ ] |
| IT-033 | Share mode sets DEFAULT_SHARE | Select "Share" → `totalShare: 1000`, amounts redistributed | - [ ] |
| IT-034 | Percentage mode sets PERCENTAGE_BASE_VALUE | Select "Percentage" → `totalShare: 10000` | - [ ] |
| IT-035 | Free mode enables per-unit inputs | Select "Free" → unit amount inputs editable, shares hidden | - [ ] |
| IT-036 | Split later clears all allocations | Select "Split later" → all shares/amounts zeroed | - [ ] |
| IT-037 | DK mode forces wholeBuilding + applies shares | Select "Distribution key" → all units selected, key shares applied | - [ ] |
| IT-038 | Changing DK recalculates shares | Switch from dk-1 to dk-2 → shares update to new key ratios | - [ ] |
| IT-039 | Whole building toggle controls selection | ON → all checked; OFF → all unchecked + amounts zeroed | - [ ] |
| IT-040 | Individual unit deselect zeros its values | Deselect one unit → its share and amount become 0 | - [ ] |
| IT-041 | Select all checkbox toggles all units | Header checkbox → all checked; click again → all unchecked | - [ ] |
| IT-042 | totalAmount change recalculates amounts | Change total with non-free mode → proportional redistribution | - [ ] |
| IT-043 | Ledger suggestion chip sets costAccount | Click suggestion → costAccount field populated with ledger | - [ ] |
| IT-044 | DK suggestion chip switches to DK mode | Click DK suggestion → DK mode enabled, key applied | - [ ] |
| IT-045 | Total mismatch shows SplitErrorDialog | Submit with sum != total → error dialog with "divide equally" | - [ ] |
| IT-046 | Unit search filters by name/address/owner | Type "Apt" → only matching units shown | - [ ] |
| IT-047 | Unit sort reorders list | Sort by amount → units ordered ascending/descending | - [ ] |

### Supplier Defaults — Backfill & Auto-save ([supplier-defaults.md](./supplier-defaults.md))

**Purpose**: Guard the integration between supplier default hooks and the form context. `useBackfillSupplierDefaults` patches empty invoice lines when supplier defaults load; `useAutoSaveBuildingSupplierDefaults` persists settings to the building-supplier link on submit. Unit tests exist for internal logic — these tests verify the form-level wiring.
**Scope**: Backfill triggers on supplier selection, "never overwrite" policy, idempotency via ref guard, auto-save on submit (create link vs update link), skip when all fields set.
**Risk**: Supplier defaults silently overwrite user-set values, backfill fires multiple times corrupting amounts, auto-save creates duplicate links, or settings lost on submit.

| ID | Description | User Flow | Status |
|----|-------------|-----------|--------|
| IT-048 | Backfill sets costAccount on empty lines | Select supplier with defaults → empty lines patched | - [ ] |
| IT-049 | Backfill sets distributionKeyId on empty lines | Supplier defaults with DK → empty lines get key applied | - [ ] |
| IT-050 | Backfill does NOT overwrite existing costAccount | Line has user-set ledger → stays untouched | - [ ] |
| IT-051 | Backfill does NOT overwrite existing DK | Line has existing DK → stays untouched | - [ ] |
| IT-052 | Changing supplier triggers new backfill | Switch from supplier A to B → backfill fires for new pair | - [ ] |
| IT-053 | Same supplier does NOT re-trigger backfill | Re-render with same pair → setValue called only once | - [ ] |
| IT-054 | Auto-save extracts settings from amounts | Submit → `saveSupplierDefaults` called with first line's data | - [ ] |
| IT-055 | Auto-save creates link for new supplier | No existing link → `linkSupplier` mutation called | - [ ] |
| IT-056 | Auto-save updates empty fields on existing link | Existing link with empty fields → `updateSupplier` called | - [ ] |
| IT-057 | Auto-save skips when all fields set | Existing link fully configured → no mutation fired | - [ ] |
