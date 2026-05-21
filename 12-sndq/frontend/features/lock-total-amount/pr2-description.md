# PR 2 — Wire Pipeline into Form and UI

## What

Connects the amount pipeline (from PR 1) to the purchase invoice form. Adds lock state to the form context, routes all CRUD operations through the pipeline, and adds a lock/unlock toggle button next to the invoice total in the footer.

## Why

PR 1 introduced the pipeline as pure, untouched logic. This PR is the integration layer that makes it functional — replacing direct RHF field-array calls with pipeline-routed mutations so that locked mode can auto-fill created lines and preserve the locked total.

## Changes

### Commit 4 — Add lock state to context and instantiate pipeline

- Added `lockState` and `toggleAmountLock` to `PurchaseInvoiceFormContext`
- Instantiated `useAmountPipeline` in `useInvoiceLinesData` with granular RHF methods (`append`/`remove`/`update`) and lock state from context
- Default state is `{ locked: false }` — pipeline acts as a passthrough, zero behavior change

### Commit 5 — Route CRUD operations through pipeline

- Replaced direct `append`/`remove` calls in `useLineCrud` with `pipeline.execute()` for add, duplicate, and delete
- Updated `useInvoiceLineDispatch` to route locked single-line edits through the pipeline (`EDIT_AMOUNT` when totalAmount changes, `UPDATE_LINE` otherwise); unlocked edits still call `update()` directly
- Threaded `pipeline` prop through `useInvoiceLineHandlers`, `InvoiceLinesTableV3`, `InvoiceLineCard`, and `SingleTotalView`
- Updated steward form (`useStewardInvoiceLinesData`) to use `useAmountPipeline` in unlocked passthrough mode to satisfy the updated `useLineCrud` interface

### Commit 6 — Add lock toggle UI to footer

- Added lock/unlock icon button (`Lock`/`LockOpen` from lucide-react) next to the total amount in `InvoiceLinesTableFooter`
- Wired `lockState.locked` and `toggleAmountLock` from context through `InvoiceLinesTableV3`
- Made `isLocked`/`onToggleLock` props optional so steward form footer works without locking

## Key files changed

| File | Change |
|------|--------|
| `PurchaseInvoiceFormContext.tsx` | Added `lockState`, `toggleAmountLock` to context |
| `PurchaseInvoiceFormV3.tsx` | Lock state management, context provider wiring |
| `hooks/useInvoiceLinesData.ts` | Pipeline instantiation with RHF methods |
| `hooks/useLineCrud.ts` | CRUD ops routed through `pipeline.execute()` |
| `hooks/useInvoiceLineDispatch.ts` | Locked edits routed through pipeline |
| `hooks/useInvoiceLineHandlers.ts` | Forwards pipeline to dispatch |
| `InvoiceLinesTableV3.tsx` | Passes lock state and toggle to footer |
| `InvoiceLinesTableFooter.tsx` | Lock/unlock icon button |
| `InvoiceLineCard.tsx`, `SingleTotalView.tsx` | Thread `AmountPipeline` prop |
| `useStewardInvoiceLinesData.ts` | Unlocked passthrough pipeline for steward form |

## How it works

- **Unlocked mode**: Pipeline is a transparent passthrough — all mutations behave identically to before
- **Locked mode**: Pipeline routes through `computeNewLines` → `applyReconciliation` → `commitToForm`
  - Add/Duplicate: created line auto-filled from remaining amount
  - Edit/Delete: no redistribution, mismatch left for user to fix manually
- **Toggle**: Clicking the lock icon captures the current total as the locked value; clicking unlock restores normal behavior

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Unlocked mode regression | HIGH | Pipeline passthrough is identity — full manual regression test |
| Steward form breakage | MEDIUM | Steward uses unlocked passthrough pipeline, no lock UI exposed |
| Distribution sheet bypass | LOW | Distribution updates fields other than totalAmount, not routed through pipeline |

## Testing

### Unlocked mode (must be identical to pre-pipeline)

- [ ] Add a line → line appears with default values
- [ ] Edit a line's total amount → excl-VAT recalculates correctly
- [ ] Change VAT rate → total stays, excl-VAT recalculates
- [ ] Duplicate a line → copy appears with same values
- [ ] Delete a line → line is removed
- [ ] Bulk delete → selected lines removed
- [ ] Distribution sheet submit → line updates correctly

### Locked mode

- [ ] Lock at 1000 with lines [600, 400], add line → new line gets 0
- [ ] Lock at 1000 with lines [600], add line → new line gets 400
- [ ] Edit line in locked mode → no other line changes
- [ ] Delete line in locked mode → remaining lines stay as-is
- [ ] Duplicate when remaining can fit source → copy keeps source amount
- [ ] Duplicate when remaining cannot fit → copy gets 0
- [ ] Unlock → normal behavior restored, amounts preserved

## Rollback

Revert commits 4–6. Form reverts to pre-pipeline direct field-array calls. No data migration needed.
