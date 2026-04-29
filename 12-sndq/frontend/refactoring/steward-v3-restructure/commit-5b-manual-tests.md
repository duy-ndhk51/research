# Commit 5B — Manual Test Script

## 1. Automated Tests

```bash
# Run all steward invoice-lines tests (should be 30 passing)
cd sndq-fe && pnpm vitest run src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/__tests__/

# Run syndic + steward regression tests (should be 194 passing)
pnpm vitest run src/modules/financial/forms/purchase-invoice-v2-steward/ src/modules/financial/forms/purchase-invoice-v2/__tests__/

# Type-check (filter for our files — expect zero errors)
pnpm tsc --noEmit 2>&1 | grep 'purchase-invoice-v3-steward'
```

## 2. Syndic Regression — InvoiceLinesTableFooter

The footer was refactored to accept `isCreditNote` prop instead of reading from context.

- [ ] Open syndic purchase invoice create form
- [ ] Add invoice lines with VAT — footer should display correct totals
- [ ] Switch to credit note mode — footer should show warning-colored total
- [ ] Verify no console errors related to `usePurchaseInvoiceFormContext` missing

## 3. Type/Import Verification

```bash
# Verify barrel export resolves all new exports
cd sndq-fe && node -e "
  const idx = require.resolve('./src/modules/financial/forms/purchase-invoice-v3-steward/components/invoice-lines/index.ts');
  console.log('Barrel exists:', idx);
"
```

- [ ] `StewardInvoiceLineCard` is exported from barrel
- [ ] `StewardInvoiceLineCostAndDistribution` is exported from barrel
- [ ] `useStewardInvoiceLineDispatch` is exported from barrel
- [ ] `useStewardInvoiceLineHandlers` is exported from barrel

## 4. Component Spot-Checks (requires wiring in Commit 5C)

These cannot be fully tested until Commit 5C wires the components into FormBody, but you can verify the component structure:

### StewardInvoiceLineCard
- [ ] Renders as a collapsible card (collapsed by default)
- [ ] Collapsed header shows: line number, total amount, VAT badge, cost category name
- [ ] Expanded content shows: amount input, VAT picker, cost/distribution section, action bar
- [ ] No "meter" section (steward doesn't support `METERED_SERVICES_INVOICE`)
- [ ] Duplicate and Delete buttons in action bar
- [ ] Period section can be toggled via action bar button

### StewardInvoiceLineCostAndDistribution
- [ ] Cost category select populated from `useCostCategoryContext`
- [ ] Distribution method select for key/equal/custom/later
- [ ] 2-column grid layout (cost category + distribution)

> **Note**: Uniform settlement (owner/tenant split) was removed from this inline component. Users access settlement controls within the custom distribution sheet instead.

## 5. File Structure Check

```
purchase-invoice-v3-steward/components/invoice-lines/
├── __tests__/
│   ├── amountDefaults.test.ts        (from 5A)
│   └── reducer.test.ts               (from 5A)
├── hooks/
│   ├── useStewardInvoiceLineDispatch.ts
│   └── useStewardInvoiceLineHandlers.ts
├── amountDefaults.ts                  (from 5A)
├── index.ts                           (updated barrel)
├── reducer.ts                         (from 5A)
├── StewardInvoiceLineCard.tsx
├── StewardInvoiceLineCostAndDistribution.tsx
└── types.ts                           (from 5A)
```
