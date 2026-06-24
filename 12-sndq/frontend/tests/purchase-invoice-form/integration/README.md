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
- **@testing-library/user-event** (already in devDependencies)
- **@testing-library/jest-dom** (globally registered via `vitest.setup.ts` — use `toBeInTheDocument()`, `toHaveClass()`, `toBeDisabled()`, etc.)
- **jsdom** (already configured in `vitest.config.mts`)

## File Location

Tests go in `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/` to match the existing `include: ['src/**/*.test.{js,ts,jsx,tsx}']` vitest config pattern.

## Existing Infrastructure

The shared test utilities are already in place at `__tests__/utils/`:

- `renderProviders.tsx` — `renderWithProviders()` and `createMockContextValue()`
- `mockFactories.ts` — `makeLine()`, `makePristineLine()`, `mockProperties`, `mockDistributionKey`, `mockLedgerOptions`
- `messages.ts` — aggregated i18n messages (`testMessages`)
- `index.ts` — barrel export

These utilities should be reused when implementing the integration test files.

## Shared Test Wrapper

All integration tests use a common wrapper that composes the required providers. This avoids repeating 50+ lines of setup per test.

```typescript
// src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/test-wrapper.tsx
import { render, type RenderOptions } from '@testing-library/react';
import { IntlProvider } from 'next-intl';
import type { ReactElement, ReactNode } from 'react';
import { FormProvider, useForm, type UseFormReturn } from 'react-hook-form';
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
import { GroupingStrategy } from '../../../purchase-invoice-v2/components/invoice-lines/types';
import type { useSheetState } from '../../hooks/useSheetState';
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
    groupingStrategy: GroupingStrategy.NONE,
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
      subSheet: { type: 'none' as const },
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
    } satisfies ReturnType<typeof useSheetState>,
    methods: {
      getValues: vi.fn(),
      setValue: vi.fn(),
      watch: vi.fn(),
      resetField: vi.fn(),
      trigger: vi.fn(),
      control: {} as UseFormReturn<PurchaseInvoiceFormV2Data>['control'],
    } as unknown as UseFormReturn<PurchaseInvoiceFormV2Data>,
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
    supplierDefaults: { isLoading: false, defaults: {} },
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
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/FormBody.test.tsx

# Watch mode
pnpm test --watch src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/

# Coverage
pnpm test --coverage src/modules/financial/forms/purchase-invoice-v3/
```

## Expected Outcome Patterns

jest-dom matchers are globally available via `vitest.setup.ts`. Use them directly:

```typescript
// Presence
expect(screen.getByRole('button')).toBeInTheDocument();
expect(screen.queryByText('missing')).not.toBeInTheDocument();

// State
expect(screen.getByRole('button')).toBeDisabled();
expect(screen.getByRole('textbox')).toHaveValue('hello');
expect(screen.getByRole('checkbox')).toBeChecked();

// Attributes & classes
expect(screen.getByRole('alert')).toHaveClass('text-warning-700');
expect(screen.getByRole('textbox')).toHaveAttribute('aria-invalid', 'true');

// Text content
expect(screen.getByTestId('total')).toHaveTextContent('€ 1,500.00');
```

See `sndq-fe/.cursor/skills/frontend-testing/` for the full testing skill reference.

## Naming Convention

- Test files: `{feature}.test.tsx`
- Describe blocks: match the feature area and sub-behavior
- Test names: descriptive, no sequential IDs
- Bug regressions: tag with `[B{N}]` in the `it()` name only

## Scenario Index

### Form Body — Conditional Rendering (HIGH) ([form-body-conditional.md](./form-body-conditional.md))

**Purpose**: Guard the building + supplier prerequisite gate that controls which form sections are visible.
**Scope**: Placeholder rendering, section visibility toggles, disabled fieldsets in partial edit, AI overlay.
**Risk**: Form shows payment/amount fields before supplier is selected, causing validation errors. Partial edit exposes editable fields on booked invoices.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Placeholder when no building/supplier | Render `FormBody` with no buildingId/senderId → placeholder hint visible, no form sections | - [ ] |
| Full form when building + supplier selected | Render with both IDs → placeholder gone, payment + other sections visible | - [ ] |
| Partial edit mode warning banner | Render with `isPartialEditMode: true` → warning banner visible, fieldsets disabled | - [ ] |
| AI extraction overlay during extraction | Render with `isExtracting: true` → overlay element rendered over form | - [ ] |

### Lock State Toggle (HIGH) ([lock-state-toggle.md](./lock-state-toggle.md))

**Purpose**: Guard the rendered lock button in `InvoiceLinesTableFooter` and its wiring to `toggleAmountLock`, plus the reconciliation behavior when adding/duplicating lines under a locked total.
**Scope**: Lock/unlock icon rendering, button click → context callback, disabled state in partial edit, footer total display (locked vs computed), reconciliation on add/duplicate (remainder, zero, fits, exceeds), no-op when unlocked.
**Risk**: Amounts get unlocked on booked invoices (accounting inconsistency), lock button clickable in partial edit, footer shows wrong total. Adding/duplicating lines breaks lock total integrity.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Renders unlock icon when unlocked | `isLocked: false` → `LockOpen` icon visible | - [ ] |
| Renders lock icon when locked | `isLocked: true` → `Lock` icon visible | - [ ] |
| Click lock button calls toggleAmountLock | Click → `onToggleLock` called once | - [ ] |
| Lock button disabled in partial edit | `isLockDisabled: true` → button disabled, click is no-op | - [ ] |
| Footer shows lockedTotal when locked | `lockedTotal: 12000` displayed, not computed total | - [ ] |
| Footer shows computed total when unlocked | `totals.totalInclVat` displayed | - [ ] |
| Lock tooltip changes based on state | Locked/unlocked/disabled → different tooltip text | - [ ] |
| Add line when locked → remainder | Lock 10000, existing 7000 → new line 3000 | - [ ] |
| Add line when locked → zero | Lock 10000, lines sum ≥ 10000 → new line 0 | - [ ] |
| Duplicate when locked → fits | Lock 20000, dup 5000 with 7000 remaining → copy 5000 | - [ ] |
| Duplicate when locked → exceeds | Lock 10000, dup 5000 with -3000 remaining → copy 0 | - [ ] |
| Add line when unlocked → no reconciliation | Unlocked → new line default (0), no clamping | - [ ] |

### Mode Switching (MEDIUM) ([mode-switching.md](./mode-switching.md))

**Purpose**: Guard the end-to-end wiring from mode toggle click through to `setValue('invoiceTypeCode', ...)` on the form.
**Scope**: `InvoiceModeToggle` dropdown interaction, `handleModeChange` callback, `setMode` + `setValue` calls, no-op for same mode.
**Risk**: Credit notes submitted as regular invoices (wrong type code), or expense notes processed with invoice logic. Backend rejects or misclassifies the document.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Renders invoice mode badge by default | Badge with "Purchase Invoice" text visible | - [ ] |
| Click credit note updates mode and typeCode | Open dropdown → click credit note → `setMode('credit_note')` called | - [ ] |
| Click expense note updates mode and typeCode | Open dropdown → click expense note → `setMode('expense_note')` called | - [ ] |
| Click invoice clears typeCode | From credit_note mode → click invoice → `setMode('invoice')` called | - [ ] |
| Same mode click is a no-op | Click current mode → `setMode` NOT called | - [ ] |

### Right Panel Tabs (MEDIUM) ([right-panel-tabs.md](./right-panel-tabs.md))

**Purpose**: Guard the tab defaulting logic that determines whether users see the file uploader or Peppol attachments first. Uses `hasPeppolData` (not `hasAttachments`) as the primary condition — the tab appears whenever Peppol data exists, with content varying based on attachment file presence.
**Scope**: Tab selection priority (user override > Peppol default > uploader fallback), content switching (PeppolAttachmentsTab vs PeppolParsedPreview), hideInlineAttachments, lock trigger on Peppol parse.
**Risk**: Users see empty uploader instead of Peppol data. PeppolParsedPreview rendered in both tabs (duplicate). Tab disappears when it should still show parsed data.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Default tab is uploader (no peppol data) | No `peppolData` → active tab is `'uploader'`, no extra tabs | - [ ] |
| Peppol data without attachments shows PeppolParsedPreview | `peppolData` exists, empty attachments → tab content is `PeppolParsedPreview`, `hideInlineAttachments: true` | - [ ] |
| Peppol data cleared removes tab | `peppolData` cleared → extra tabs empty, falls back to `'uploader'` | - [ ] |
| Peppol with attachment files shows PeppolAttachmentsTab | `peppolData.attachments` has entries → tab content is `PeppolAttachmentsTab` | - [ ] |
| User tab selection overrides default | Peppol data present but user selects `'uploader'` → stays `'uploader'` | - [ ] |
| Peppol amounts parsed triggers lock (uploader path) | `safePeppolDataParsed` with amounts → `setLockState({ locked: true, lockedTotal })` called | - [ ] |
| Peppol with no amounts skips lock (uploader path) | `safePeppolDataParsed` with `[]` → `setLockState` NOT called (guard: `parsedAmounts.length > 0`) | - [ ] |

### Invoice Fields (MEDIUM) ([invoice-fields.md](./invoice-fields.md))

**Purpose**: Guard the rendered interaction of invoice number auto-generate toggle, date picker, and AI confidence indicators.
**Scope**: Button click → field population, toggle on/off, manual typing resets state, AI indicator conditional rendering, date picker with bounds.
**Risk**: Auto-generate button doesn't populate the field, manual edit doesn't clear auto state, AI indicators stuck after review.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Renders invoice number input and auto button | Input and "Auto" button visible | - [ ] |
| Click auto-generate populates field | Input value matches `INV-{YEAR}-{NNN}` pattern | - [ ] |
| Click auto-generate again clears field | Input becomes empty, button shows "Auto" | - [ ] |
| Button label toggles Auto/Clear | Reflects auto-generated state | - [ ] |
| Manual typing resets auto state | Type → `markFieldReviewed` called, button returns to "Auto" | - [ ] |
| AI indicator visible when confidence defined | `getFieldConfidence` returns 0.85 → indicator rendered | - [ ] |
| AI indicator hidden when confidence undefined | Default → no indicator in DOM | - [ ] |
| Date picker renders with bounds | `minInvoiceDate`/`maxInvoiceDate` props passed through | - [ ] |

### Peppol to Invoice (HIGH) ([peppol-to-invoice.md](./peppol-to-invoice.md))

**Purpose**: Verify the wiring between `transformPeppolToFormData` output and React Hook Form `setValue` calls. The transform is unit-tested; these tests cover the last mile where data reaches the form. Highest-priority group — Peppol is the #1 daily flow.
**Scope**: Full field population, supplier matching/unmatching, credit note type propagation. Pure-logic tests (OGM parsing, lock total computation, grouping) moved to `unit/transformPeppolToFormData.md`.
**Risk**: Peppol invoices open with empty/wrong fields, unmatched suppliers get stale senderId, credit notes treated as invoices.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Peppol populates all form fields | `handlePeppolDataParsed` with full data → all fields set via `setValue` | - [ ] |
| Unmatched supplier resets senderId | No `supplierPartyContactId` → `resetField('senderId')`, supplier data stored | - [ ] |
| Matched supplier sets senderId | `supplierPartyContactId` exists → `setValue('senderId')`, supplier data cleared | - [ ] |
| Peppol credit note typeCode flows to form | `typeCode: '381'` → form `invoiceTypeCode` is `'381'` | - [ ] |

### Invoice Lines Table (HIGH) ([invoice-lines-table.md](./invoice-lines-table.md))

**Purpose**: Guard the `InvoiceLinesTableV3` orchestration that wires form context, CRUD state, and conditional rendering. Lock reconciliation tests are in [lock-state-toggle.md](./lock-state-toggle.md); grouping lifecycle tests are in [grouping-strategy.md](./grouping-strategy.md).
**Scope**: Add line disabled state, individual vs simple mode, mode toggle, delete dialog (single), duplicate, distribution sheet trigger, VAT rate change preserving totalAmount, footer totals + credit note styling, `defaultOpen`, `isDeferredCost`.
**Risk**: Add line possible without building, wrong view rendered, delete not wired, distribution sheet doesn't open, footer shows wrong totals, first card collapsed on new invoice.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Add line disabled (no building) | No `buildingId` → button disabled with tooltip | - [ ] |
| Add line enabled (building set) | `buildingId` set → button enabled | - [ ] |
| Individual mode renders line cards | `NONE` + 2 amounts → 2 `InvoiceLineCard`s rendered | - [ ] |
| Simple mode renders SingleTotalView | `ALL` + 1 amount → `SingleTotalView` shown, no cards/add button | - [ ] |
| Single delete opens dialog | Delete on card → `DeleteAmountDialog` opens | - [ ] |
| Confirm delete removes line | Confirm → dialog closes, line removed | - [ ] |
| Cancel delete keeps line | Cancel → dialog closes, line unchanged | - [ ] |
| Duplicate triggers pipeline | Duplicate button → `pipeline.execute(DUPLICATE_LINE)` | - [ ] |
| Custom distribution opens sheet | Distribution button → sheet opens with line index | - [ ] |
| Footer shows VAT breakdown + total | 2 VAT lines → subtotal, per-rate VAT, total displayed | - [ ] |
| Credit note warning color | `mode: 'credit_note'` → total has `text-warning-700` | - [ ] |
| Description auto-fill props | Context values → `DescriptionSection` receives correct auto-fill | - [ ] |
| First card expanded on new invoice | `invoiceId: null` → first card `defaultOpen` | - [ ] |
| First card collapsed on edit | `invoiceId` set → first card collapsed | - [ ] |
| isDeferredCost disables distribution | `isDeferredCost: true` → distribution controls disabled | - [ ] |
| VAT rate change keeps totalAmount | Change VAT 21% → 6% → subtotal recalculated, totalAmount unchanged | - [ ] |
| VAT toggle off equalizes amounts | Toggle VAT off → subtotal = totalAmount | - [ ] |
| Period button visible when no fromDate | No `fromDate` → "Period" button visible in action bar | - [ ] |
| Click period button shows section | Click → `PeriodExpandableSection` appears | - [ ] |
| Period pre-shown when fromDate exists | `fromDate` set → section visible, no button | - [ ] |
| Remove period clears dates | Click remove → dates cleared, button reappears | - [ ] |
| Metered invoice always shows period + meter | `METERED_SERVICES_INVOICE` → section forced, meter select visible | - [ ] |
| Select ledger updates line costAccount | Open dropdown, click ledger → `costAccount` populated | - [ ] |
| Select distribution key applies key and recalculates units | Click key → `distributionKeyId` set, `units` recalculated | - [ ] |
| Distribute equally splits amount across properties | Click equally → `distributionType: 'share'`, equal splits | - [ ] |
| Allocate later clears distribution | Click allocate later → distribution fields cleared | - [ ] |
| Distribution select label reflects current method | Label shows key name / "Equal split" / "Allocate later" | - [ ] |

### Grouping Strategy (HIGH) ([grouping-strategy.md](./grouping-strategy.md))

**Purpose**: Guard the full grouping strategy lifecycle: toggling between individual and single-total mode, saving/restoring original amounts, detecting merge conflicts, the merge confirmation dialog flow, and the resolution outcomes (what the merged line looks like).
**Scope**: AmountModeToggle tab rendering, strategy change callback, save originals on leave, restore originals on return, merge conflict detection (different ledgers/distribution keys), dialog confirm/cancel, `replace()` and `clearSelection()` calls, merge result validation (unanimous ledger/key preservation, sum of totalAmount, period spanning).
**Risk**: Switching to single-total mode loses individual line detail, switching back returns empty/wrong lines, lines with conflicting ledgers get silently merged without confirmation, merged line has wrong total or stale costAccount.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Renders both segment tabs | "Single total" and "Line by line" tabs visible | - [ ] |
| Click "Single total" calls handleGroupingStrategyChange(ALL) | Strategy change to ALL triggered | - [ ] |
| Click "Line by line" calls handleGroupingStrategyChange(NONE) | Strategy change to NONE triggered | - [ ] |
| Same strategy click is a no-op | No `setGroupingStrategy` call | - [ ] |
| Individual → single saves originals and applies grouping | Originals preserved, `replace()` called | - [ ] |
| Single → individual restores original amounts | `replace()` called with saved originals | - [ ] |
| Merge conflict: different ledgers opens dialog | 2 lines, different `costAccount.id` → dialog open | - [ ] |
| Merge conflict: different distribution keys opens dialog | 2 lines, different `distributionKeyId` → dialog open | - [ ] |
| No conflict: same ledger applies directly | Same `costAccount` → no dialog, immediate apply | - [ ] |
| Single line never triggers conflict | 1 line → direct apply | - [ ] |
| Dialog confirm applies strategy and closes | Confirm → `replace()` + `setGroupingStrategy()` | - [ ] |
| Dialog cancel preserves current amounts | Cancel → no change, dialog closes | - [ ] |
| Selection cleared after strategy change | `clearSelection()` fired after `replace()` | - [ ] |
| Merge result: same ledger preserved | Same `costAccount` → merged line keeps it | - [ ] |
| Merge result: different ledgers cleared | Different `costAccount` → merged line has none | - [ ] |
| Merge result: totalAmount is sum | 5000 + 3000 → merged `totalAmount: 8000` | - [ ] |
| Merge result: same distribution key preserved | Same key → merged line keeps key + units recalculated | - [ ] |
| Merge result: different keys cleared | Different keys → `distributionKeyId` cleared | - [ ] |
| Merge result: period earliest/latest | Merged `fromDate` = earliest, `toDate` = latest | - [ ] |

### Amount Distribution Sheet (HIGH) ([amount-distribution-sheet.md](./amount-distribution-sheet.md))

**Purpose**: Guard the distribution sheet UI lifecycle: unit initialization from building properties, distribution type switching (share/percentage/free/split_later/distribution_key), share/amount recalculation, ledger and distribution key suggestions, and form validation.
**Scope**: Sheet open/close, loading states, edit mode pre-fill, all 5 distribution types, whole building toggle, individual/unit selection, amount redistribution on total change, suggestion chip interactions, total mismatch validation dialog, unit search/sort.
**Risk**: Units not initialized on sheet open, distribution type switch corrupts amounts, distribution key mode doesn't force whole building, amount mismatch undetected, suggestions don't populate form fields.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Loading state shows spinner | Sheet open + properties pending → spinner shown, no form | - [ ] |
| Properties loaded initializes units | Sheet open + 3 properties → 3 unit rows, all unselected, amount 0 | - [ ] |
| Edit mode pre-fills from editingItem | Open with saved line → form resets to prior values | - [ ] |
| Share mode sets DEFAULT_SHARE | Select "Share" → `totalShare: 1000`, amounts redistributed | - [ ] |
| Percentage mode sets PERCENTAGE_BASE_VALUE | Select "Percentage" → `totalShare: 10000` | - [ ] |
| Free mode enables per-unit inputs | Select "Free" → unit amount inputs editable, shares hidden | - [ ] |
| Split later clears all allocations | Select "Split later" → all shares/amounts zeroed | - [ ] |
| Distribution key mode forces wholeBuilding + applies shares | Select "Distribution key" → all units selected, key shares applied | - [ ] |
| Changing distribution key recalculates shares | Switch from dk-1 to dk-2 → shares update to new key ratios | - [ ] |
| Whole building toggle controls selection | ON → all checked; OFF → all unchecked + amounts zeroed | - [ ] |
| Individual unit deselect zeros its values | Deselect one unit → its share and amount become 0 | - [ ] |
| Select all checkbox toggles all units | Header checkbox → all checked; click again → all unchecked | - [ ] |
| totalAmount change recalculates amounts | Change total with non-free mode → proportional redistribution | - [ ] |
| Ledger suggestion chip sets costAccount | Click suggestion → costAccount field populated with ledger | - [ ] |
| Distribution key suggestion chip switches to distribution key mode | Click distribution key suggestion → distribution key mode enabled, key applied | - [ ] |
| Total mismatch shows SplitErrorDialog | Submit with sum != total → error dialog with "divide equally" | - [ ] |
| Unit search filters by name/address/owner | Type "Apt" → only matching units shown | - [ ] |
| Unit sort reorders list | Sort by amount → units ordered ascending/descending | - [ ] |

### Supplier Defaults (HIGH) ([supplier-defaults.md](./supplier-defaults.md))

**Purpose**: Guard the `useBackfillSupplierDefaults` hook that applies supplier defaults to pristine first lines on form mount. Unit tests exist for internal logic — these tests verify the form-level wiring. Also covers `useAutoSaveBuildingSupplierDefaults` which persists settings on submit.
**Scope**: Initial defaults triggers, guard conditions (edit mode, free distribution, non-zero amount, existing values), ref-based single-fire, loading wait, auto-save on submit.
**Risk**: Defaults silently overwrite user-set values, fire multiple times, fire in edit mode, auto-save creates duplicate links, or settings lost on submit.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Initial defaults applies costAccount on pristine first line | Mount with supplier defaults → costAccount patched | - [ ] |
| Initial defaults applies distributionKeyId on pristine first line | Supplier defaults with distribution key → key applied | - [ ] |
| Does NOT fire in edit mode | Edit mode → hook skips entirely | - [ ] |
| Does NOT fire with free distribution (regression) | Free distribution strategy → no defaults applied | - [ ] |
| Does NOT fire with non-zero totalAmount | Line has amount > 0 → treated as non-pristine, skipped | - [ ] |
| Does NOT fire with existing costAccount | Line has user-set ledger → stays untouched | - [ ] |
| Only fires once (ref guard) | Re-render with same data → setValue called only once | - [ ] |
| Waits for supplier defaults to finish loading | Defaults still loading → defers until ready | - [ ] |
| Does NOT fire when no configured defaults | No supplier defaults configured → no mutations | - [ ] |
| Auto-save extracts settings from amounts | Submit → `saveSupplierDefaults` called with first line's data | - [ ] |
| Auto-save creates link for new supplier | No existing link → `linkSupplier` mutation called | - [ ] |
| Auto-save updates empty fields on existing link | Existing link with empty fields → `updateSupplier` called | - [ ] |
| Auto-save skips when all fields set | Existing link fully configured → no mutation fired | - [ ] |

### Form Orchestration (MEDIUM) ([form-orchestration.md](./form-orchestration.md))

**Purpose**: Verify the top-level provider composition and layout wiring. Outermost shell that composes all providers with a resizable two-panel layout.
**Scope**: Provider stack renders, create/edit/Peppol mode mounting, resizable panels, AI extraction banner, onClose wiring.
**Risk**: Provider stack crashes on missing context, Peppol mode doesn't auto-lock, resizable layout breaks accessibility.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Form renders without crashing (create mode) | Render with defaults → `form-header` and `form-body` present | - [ ] |
| Form renders in edit mode with invoiceId | Pass `invoiceId` → form renders | - [ ] |
| Form renders in Peppol mode with peppolInvoiceId | Pass `peppolInvoiceId` → lock auto-initializes | - [ ] |
| Resizable panels render left and right | Default render → `form-body` and `right-panel` present | - [ ] |
| AiExtractionBanner hidden by default | No extraction → banner absent | - [ ] |
| AiExtractionBanner visible during extraction | Extraction active → banner with progress | - [ ] |
| onClose callback wired to sheet state | Close action → `handleSheetClose` propagates | - [ ] |

### Form Header (MEDIUM) ([form-header.md](./form-header.md))

**Purpose**: Verify the header bar that shows save/submit button states, total amount display, lock indicator, mode toggle, and draft status.
**Scope**: Save button disabled during submission, total display, lock icon, draft badge, mode toggle.
**Risk**: Save button stays enabled during submission (double-submit), total displays stale value, mode toggle doesn't propagate.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Save button enabled when form is valid | Valid form → button not disabled | - [ ] |
| Save button disabled during submission | `isPending: true` → button disabled + spinner | - [ ] |
| Total amount shows computed sum | 2 lines totaling 15000 → displays "150.00" | - [ ] |
| Lock icon shows when locked | `locked: true` → lock icon visible | - [ ] |
| Lock icon hidden when unlocked | `locked: false` → lock icon absent | - [ ] |
| Draft badge visible for drafts | `isDraft: true` → "Draft" badge | - [ ] |

### Form Dialogs (MEDIUM) ([form-dialogs.md](./form-dialogs.md))

**Purpose**: Verify confirmation dialog lifecycle for destructive actions: discard changes and delete **draft** invoice.
**Scope**: Discard dialog open/close/confirm, delete draft dialog with loading state, draft-only visibility.
**Risk**: Discard fires without confirmation (data loss), delete proceeds on non-draft invoice.
**Note**: Merge dialog tests live in [grouping-strategy.md](./grouping-strategy.md) which covers trigger, confirm, and cancel flows comprehensively.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Discard dialog hidden by default | No triggers → dialog absent | - [ ] |
| Discard dialog opens when triggered | `showDiscardDialog: true` → dialog visible | - [ ] |
| Discard confirm calls handleDiscard | Click confirm → `handleDiscard` called | - [ ] |
| Delete draft dialog shows loading | `isDraft: true`, `isDeleting: true` → confirm disabled | - [ ] |
| Delete action hidden when not a draft | `isDraft: false` → no delete trigger | - [ ] |

### Inline Selects (MEDIUM) ([inline-selects.md](./inline-selects.md))

**Purpose**: Verify the inline building and supplier selects plus `InlineLedgerSelect` base UI (IS-L*): selection handlers, side effects on buildingId/senderId change, search debounce, keyboard navigation, supplier quick-create flow, and tabbed ledger popover behavior.
**Scope**: Building/supplier selection, building change resets supplier, supplier clear, debounce, quick-create, keyboard nav, tab management; ledger tab rendering, search, footer actions, tab class isolation (IS-L1–L11).
**Risk**: Building change doesn't reset supplier (wrong pair), supplier clear doesn't reset senderId, keyboard navigation traps focus; wrong-class ledger options shown on Revenue tab after supplier backfill.

| Test Name | Key Behavior | Status |
|-----------|--------------|--------|
| Building selected sets buildingId | Select building → `setValue('buildingId')` | - [ ] |
| Building changed resets supplier + amounts | Change building → `resetField('senderId')` + `removeAllAmounts()` | - [ ] |
| Supplier cleared resets senderId | Clear supplier → `resetField('senderId')` | - [ ] |
| Supplier selected sets senderId | Select supplier → `setValue('senderId')` | - [ ] |
| Reselecting same supplier is a no-op | Same supplier → no `setValue` | - [ ] |
| Search debounces API calls | Rapid typing → single API call after 300ms | - [ ] |
| Quick-create supplier flow | Create new → `senderId` set, defaults refreshed | - [ ] |
| Keyboard navigation cycles options | ArrowDown → first option focused | - [ ] |
| Tab focus management | Tab from building → supplier focused | - [ ] |

### Ledger Credit Note Conversion (HIGH) ([ledger-credit-note-conversion.md](./ledger-credit-note-conversion.md))

**Purpose**: Tabbed ledger select + confirmation dialog + bulk credit note conversion when a 7xx ledger is selected on a non-credit-note invoice.
**Scope**: 6xx/7xx tab split, dialog gate, bulk line update, distribution sheet outer-form scope (props from `InvoiceLinesTableV3`), FormHeader toggle must not mutate lines, Revenue tab class isolation after supplier backfill.
**Risk**: Wrong form scope in distribution sheet; bulk overwrite of existing 7xx lines; 6xx options leaking into Revenue tab list.

| Test case | Key behavior | Status |
|-----------|--------------|--------|
| Expense tab renders 6xx, Revenue tab renders 7xx | Options split by `displayCode` prefix | - [ ] |
| Select expense on invoice mode → no dialog | Normal selection, no conversion | - [ ] |
| Select revenue on invoice mode → dialog | Confirmation before state change | - [ ] |
| Confirm → credit_note mode + type code 381 | Mode and `invoiceTypeCode` updated | - [ ] |
| Confirm with mixed lines → only 6xx updated | Existing 7xx lines preserved | - [ ] |
| Cancel dialog → no changes | Cancel is a no-op | - [ ] |
| Revenue on credit_note mode → no dialog | Direct selection | - [ ] |
| Revenue on expense_note mode → dialog | Same gate as invoice mode | - [ ] |
| Lines without `code` → bulk updated | Treated as expense class | - [ ] |
| Lines with undefined costAccount → updated | Empty lines populated | - [ ] |
| Distribution sheet → outer form conversion | Props-based conversion from sheet | - [ ] |
| FormHeader toggle → lines unchanged | Mode toggle never mutates lines | - [ ] |
| Backfilled 6xx → Revenue tab excludes 6xx | Tab class isolation; trigger unchanged | - [ ] |
