# Commit 5C Manual Test Script — Wire Lines Table into FormBody

## Prerequisites

- Dev server running (`pnpm dev`)
- At least one supplier contact in the system
- At least 2 properties available for selection
- At least one building with distribution keys configured

---

## 1. Automated Tests

```bash
# Run all steward invoice-lines tests (should be 30 pass)
pnpm vitest run src/modules/financial/forms/purchase-invoice-v3-steward/

# Run syndic invoice-lines regression (should be 54 pass)
pnpm vitest run src/modules/financial/forms/purchase-invoice-v3/components/invoice-lines/

# Type-check (only .next/types errors, not in our files)
pnpm tsc --noEmit 2>&1 | grep -v '.next/types'
```

Expected: 84 tests pass (30 steward + 54 syndic), zero type errors in modified files.

---

## 2. Visual Inspection — Create Flow

1. **Open steward create form** (new purchase invoice, steward mode)
2. Verify:
   - No amounts/lines section visible yet (supplier + properties required)
3. **Select a supplier** from the supplier section
4. **Select 2+ properties** from the units section
5. Verify:
   - Lines section appears with an **Add line** button
   - No lines present yet
   - Footer shows `€0.00` totals

---

## 3. Line CRUD Operations

### Add
6. Click **Add line**
7. Verify:
   - New line card appears, expanded by default
   - Line has default amount `€0.00`, no VAT
   - Cost category dropdown is empty
   - Distribution section visible

### Edit Amount
8. Enter amount `€100.00` in the amount field
9. Verify:
   - Footer total updates to `€100.00`
   - Line header (when collapsed) shows `€100.00`

### Set VAT
10. Toggle VAT on, select 21%
11. Verify:
    - Total recalculates to `€121.00`
    - Footer reflects new total
    - VAT badge visible in collapsed header

### Set Cost Category
12. Select a cost category from the dropdown
13. Verify:
    - Cost category name appears in collapsed header
    - Selection persists after collapsing/expanding

### Add Multiple Lines
14. Click **Add line** again (2-3 more lines)
15. Set different amounts on each
16. Verify:
    - All lines display with correct indices
    - Footer totals accumulate correctly

### Duplicate
17. Click duplicate on a line with data
18. Verify:
    - New line appears with same amount, VAT, cost category
    - Footer totals update

### Delete
19. Click delete on a line
20. Verify:
    - Delete confirmation dialog appears
    - Confirm delete — line removed
    - Footer totals update
    - Cancel delete — line stays

---

## 4. Distribution

### Basic Distribution
21. On a line, click to open distribution (via the distribution method dropdown or custom distribution button)
22. Verify:
    - `StewardAmountDistributionSheet` opens (full-screen bottom sheet)
    - All selected properties appear as units
    - Distribution methods available (share, percentage, free, split later)

### Distribution Key (building mode only)
23. If using building selection mode with distribution keys:
    - Select "Distribution key" option
    - Verify keys load and apply shares

### Settlement
24. On the distribution sheet, check unit settlement popovers
25. Verify:
    - Each unit has owner/tenant split controls
    - Uniform settlement toggle works

### Close and Persist
26. Set distribution values and click Save
27. Verify:
    - Sheet closes
    - Line data updated in the form

---

## 5. Add Button Gate

28. **Remove all properties** (clear property selection)
29. Verify:
    - Add line button becomes **disabled**
    - Tooltip shows "Select building first" or similar
30. Re-select properties
31. Verify:
    - Add line button re-enables

---

## 6. Save and Reload

### Draft
32. Fill in form with 2+ lines, various amounts/categories
33. Save as **draft**
34. Verify:
    - Save succeeds
    - Reopen the draft — all lines preserved with correct data

### Submit
35. Fill complete form (all required fields)
36. Submit
37. Verify:
    - Submit succeeds
    - Check network tab: API payload `amounts` array structure matches expected shape
    - Each amount has: `totalAmount`, `hasVat`, `vatRate`, `costCategoryId`, `units[]`, distribution fields

---

## 7. Edit Flow

38. Open an existing steward invoice for editing
39. Verify:
    - Existing lines pre-populated
    - Amounts, VAT, cost categories, distributions all correct
40. Edit a line (change amount, cost category)
41. Save
42. Reopen — changes persisted

---

## 8. Property Change Interaction

43. With lines already created, **change the property selection**
44. Verify:
    - Toast notification appears (units cleared)
    - Distribution data on existing lines is cleared
    - Units array on each line resets to new properties

---

## 9. Credit Note Mode

45. Toggle to **Credit Note** mode (from header toggle)
46. Verify:
    - Footer shows amounts with credit note styling (negative indicator or different color)
    - `isCreditNote` prop correctly passed to footer

---

## 10. Syndic Regression

47. Open **syndic V3** create form
48. Verify:
    - Invoice lines still work identically
    - Add, edit, delete, duplicate all functional
    - Distribution sheet opens (syndic version, not steward)
    - Totals correct
49. `pnpm test` — all tests pass

---

## File Structure Check

Verify these files exist and have correct exports:

```
purchase-invoice-v3-steward/components/invoice-lines/
├── __tests__/
│   ├── amountDefaults.test.ts              (5A)
│   ├── reducer.test.ts                     (5A)
│   └── InvoiceLinesTableV3Steward.test.tsx (5C)
├── hooks/
│   ├── useStewardInvoiceLineDispatch.ts    (5B)
│   ├── useStewardInvoiceLineHandlers.ts    (5B)
│   └── useStewardInvoiceLinesData.ts       (5C)
├── amountDefaults.ts                       (5A)
├── reducer.ts                              (5A)
├── types.ts                                (5A)
├── StewardInvoiceLineCard.tsx              (5B)
├── StewardInvoiceLineCostAndDistribution.tsx (5B)
├── InvoiceLinesTableV3Steward.tsx          (5C)
└── index.ts                                (5A + 5B + 5C)
```
