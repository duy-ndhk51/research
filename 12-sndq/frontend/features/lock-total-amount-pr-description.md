# Lock Total Amount — Purchase Invoice V3

## What

Adds a lock/unlock toggle next to the invoice total (incl. VAT) in the purchase invoice lines footer. When locked, all line mutations automatically redistribute amounts to maintain the locked total.

## Why

Users importing Peppol invoices need to ensure the sum of allocation lines always matches the original invoice total. Without this, manual edits can silently drift the total, causing reconciliation errors at submission.

## How it works

- **Lock toggle**: Icon button next to the total amount in `InvoiceLinesTableFooter`. Clicking it captures the current total as the locked value.
- **Pipeline architecture**: All line mutations (add, edit, delete, duplicate) flow through `useAmountPipeline` — a single hook that applies raw changes, reconciles amounts when locked, validates the total, and commits via `replace()`.
- **Reconciliation rules**:
  - **Add**: New line gets `max(0, lockedTotal - sumOfExisting)`
  - **Edit**: Other lines redistribute proportionally by their current ratio
  - **Delete**: Remaining lines redistribute proportionally to fill the locked total
  - **Duplicate**: No redistribution — both keep amounts; toast fires on mismatch
- **VAT handling**: Redistribution operates on `totalAmount` (incl. VAT), then back-calculates `amount` (excl. VAT) per line's VAT rate. Unit distribution is NOT recalculated (deferred to explicit user action).
- **Rounding**: Integer cents arithmetic with deterministic rounding — any remainder cent goes to the first eligible line.
- **Validation**: Real-time toast on every mismatch after any action + submit-time guard that blocks submission if totals don't match.
- **Peppol default**: Auto-enabled for Peppol invoices (user can still unlock).

## Key files

| Area | Files |
|------|-------|
| Pure logic | `pipeline/types.ts`, `computeNewLines.ts`, `reconcile.ts`, `assertTotalMatch.ts` |
| Hook | `pipeline/useAmountPipeline.ts` (uses vendored `useStableCallback`) |
| Shared utility | `utils/amountCalculation.ts` (`calculateSubtotalFromTotal`, `setTotalAmountForLine`) |
| Integration | `hooks/useLineCrud.ts`, `hooks/useInvoiceLineDispatch.ts`, `hooks/useInvoiceLinesData.ts` |
| UI | `InvoiceLinesTableFooter.tsx` (lock icon), `InvoiceLinesTableV3.tsx` |
| Context | `PurchaseInvoiceFormContext.tsx` (lockState, toggleAmountLock) |
| Validation | `hooks/useInvoiceFormActions.ts` (submit-time check) |
| Vendored hooks | `src/hooks/lib/useStableCallback.ts` (replaces manual ref pattern; will be replaced by `useEffectEvent` when stable) |

## Testing

- 25 unit tests for pipeline functions (reconcile, computeNewLines, assertTotalMatch)
- 15 unit tests for amount calculation utilities
- Existing 75 tests (reducer, amountDefaults, lineGrouping) pass with zero regressions

## Manual test checklist

- [ ] Unlocked mode: add/edit/delete/duplicate work identically to before
- [ ] Lock at 1000, add line -> gets remainder
- [ ] Lock at 1000, edit a line -> others redistribute proportionally
- [ ] Lock at 1000, delete a line -> remaining lines redistribute
- [ ] Duplicate in locked mode -> toast fires on mismatch
- [ ] Unlock -> normal behavior restored
- [ ] Peppol create -> auto-locks with correct total
- [ ] Submit with mismatch -> blocked with toast
