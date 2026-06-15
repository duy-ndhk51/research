## Summary

Establishes shared test infrastructure for the purchase-invoice-v3 integration test suite and adds 52 integration tests across 6 test files — covering form body conditional rendering, mode switching, form header, lock state toggle, invoice lines table orchestration, and InvoiceLineCard internals (period input, VAT picker, distribution).

## What's included

### Test infrastructure (`__tests__/utils/`)

- `render-providers.tsx` — `renderWithProviders` helper wrapping components with `PurchaseInvoiceFormContext`, `ReactHookForm`, `QueryClientProvider`, and `IntlProvider`
- `mock-factories.ts` — `createMockContextValue`, preset overrides (`withBuildingAndSupplier`, `withAiExtracting`, `defaultHeaderContext`, `withInvoiceLines`), line builders (`makeLine`, `makePristineLine`), and property/ledger helpers (`mockProperties`, `mockPropertiesMap`, `mockLedgerOptions`, `mockDistributionKey`)
- `messages.ts` — i18n message loader combining financial, general, purchase_invoice, properties, common, peppol, and accounting namespaces
- `index.ts` — barrel export for all test utilities

### Vitest config changes

- Added `ResizeObserver` polyfill to `vitest.setup.ts` (jsdom lacks this browser API)
- Added `QueryClientProvider` to test render wrapper
- Added `css: { postcss: {} }` to `vitest.config.mts` to suppress PostCSS warnings

### Test cases covered

| File | Group | Cases |
|------|-------|-------|
| `form-body.test.tsx` | Form body conditional rendering | 4 |
| `mode-switching.test.tsx` | Invoice/credit note mode switching | 5 |
| `form-header.test.tsx` | Form header (save button, total display) | 4 |
| `lock-state-toggle.test.tsx` | Lock state machine (footer + reconciliation) | 12 |
| `invoice-lines-table.test.tsx` | Invoice lines table orchestration | 18 |
| `invoice-line-card.test.tsx` | InvoiceLineCard internals (period, VAT, distribution) | 9 |

**Total: 52 integration tests**

### Behaviors verified

**Form body (4 cases)**
- Shows placeholder when building/supplier not selected
- Renders full form sections when building + supplier selected
- Partial edit mode disables building/supplier/payment fields
- AI extraction overlay displays during extraction

**Mode switching (5 cases)**
- Mode badge renders correctly for invoice and credit note
- Mode toggle switches between invoice/credit note
- Credit note badge styling applied

**Form header (4 cases)**
- Save button enabled/disabled based on form validity
- Total amount display in header

**Lock state toggle (12 cases)**
- Lock/unlock icon reflects state
- Click calls `toggleAmountLock`
- Lock button disabled in partial edit mode
- Footer displays `lockedTotal` when locked, computed total when unlocked
- VAT breakdown display in footer
- Lock reconciliation on add line (remainder, zero)
- Lock reconciliation on duplicate (fits, exceeds)
- No reconciliation when unlocked

**Invoice lines table (18 cases)**
- Add line disabled/enabled based on building selection
- Individual mode renders line cards; simple mode renders SingleTotalView
- Delete line flow (dialog open, confirm, cancel)
- Duplicate line creates new card
- Footer displays VAT breakdown and total
- Credit note warning color on total
- Description section receives auto-fill props
- First card expanded on new invoice, collapsed on edit
- `isDeferredCost` flag passed to cards
- Lock button wired to context

**InvoiceLineCard internals (9 cases)**
- Period button visible when no fromDate; click shows PeriodExpandableSection
- Period pre-shown when line has fromDate
- Remove period clears dates and hides section
- Metered invoice shows meter select and period is available
- Changing VAT rate dispatches SET_VAT and keeps totalAmount
- Selecting VAT rate on no-VAT line enables VAT
- Select ledger calls onUpdate with costAccount
- Distribute equally calls onUpdate with units matching property count

## Test plan

- [x] `pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/` — all 52 passing
- [x] Full suite (`pnpm test --run`) — no regressions on existing tests
