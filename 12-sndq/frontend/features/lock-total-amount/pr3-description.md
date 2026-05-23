# PR 3 — Peppol Auto-Lock, Validation, and Cleanup

## What

Auto-locks the total when a Peppol invoice is converted or an XML file is uploaded. Adds submit-time validation as a safety net. Removes real-time mismatch toast, shows the frozen locked total in the footer, and extracts a shared `sumTotalAmounts` utility.

## Why

Users importing Peppol invoices or uploading XML files expect the locked total to activate automatically. Submit-time validation is the hard block for mismatches — real-time toasts on every edit were noisy and unhelpful.

## Changes

### Commit 7 — Auto-enable lock for Peppol invoices

- `PeppolInvoiceSheetRoute` computes `lockedTotal` from `initialData.amounts` and passes it as `config.initialLockState` prop — fully deterministic, no effects
- Added `PurchaseInvoiceFormConfig` interface with `initialLockState?: LockState` to `types.ts`
- Removed URL navigation callback chain (Path B) — only conversion path is the Sheet "Edit" button

### Commit 8 — Submit-time validation

- Threaded `lockState` from `PurchaseInvoiceFormV3` through `usePurchaseInvoiceForm` to `useInvoiceFormActions`
- Added mismatch check in both `onSubmit` and `onError` handlers — early return with toast when sum differs from `lockedTotal`
- Translation keys already existed in all 4 languages

### Post-8 — Remove real-time mismatch toast

- Removed `onMismatch` callback from `useAmountPipeline` and `useInvoiceLinesData`
- Submit-time validation is now the sole mismatch notification

### Post-8 — Footer displays locked total

- `InvoiceLinesTableFooter` shows `lockedTotal` instead of live sum when locked
- Passed `lockedTotal` prop from `InvoiceLinesTableV3`

### Post-8 — XML upload auto-lock

- Changed `handlePeppolDataParsed` return type to `Promise<AmountWithDistributionData[]>`
- Added `setLockState` to `PurchaseInvoiceFormContextValue`
- `safePeppolDataParsed` in `InvoiceRightPanelConnected` awaits returned amounts, computes `lockedTotal`, and calls `setLockState`

### Post-8 — Extract `sumTotalAmounts` and remove dead code

- Extracted `sumTotalAmounts` into `pipeline/sumTotalAmounts.ts` — replaces inline `.reduce()` in 3 call sites
- Removed dead `assertTotalMatch` function and its tests (no production callers after toast removal)

## Key files changed

| File | Change |
|------|--------|
| `types.ts` | `PurchaseInvoiceFormConfig` with `initialLockState` |
| `PurchaseInvoiceFormV3.tsx` | Config prop, `setLockState` on context, XML auto-lock in `safePeppolDataParsed` |
| `PeppolInvoiceSheetRoute.tsx` | Computes and passes `initialLockState` |
| `usePeppolPrefill.ts` | Returns `AmountWithDistributionData[]`, removed callback chain |
| `usePurchaseInvoiceForm.ts` | Threads `lockState` to `useInvoiceFormActions` |
| `useInvoiceFormActions.ts` | Submit-time mismatch validation, uses `sumTotalAmounts` |
| `PurchaseInvoiceFormContext.tsx` | Added `setLockState` |
| `useAmountPipeline.ts` | Removed `onMismatch` |
| `useInvoiceLinesData.ts` | Removed mismatch toast callback |
| `InvoiceLinesTableFooter.tsx` | Shows `lockedTotal` when locked |
| `InvoiceLinesTableV3.tsx` | Passes `lockedTotal` to footer |
| `pipeline/sumTotalAmounts.ts` | Shared `sumTotalAmounts` utility (renamed from `assertTotalMatch.ts`) |

## Testing

- [ ] Peppol Sheet "Edit" -> form auto-locks with correct total
- [ ] XML file upload -> form auto-locks with correct total
- [ ] Submit with mismatch -> toast error, form does not submit
- [ ] Submit without mismatch -> succeeds
- [ ] Unlock -> normal behavior restored
- [ ] Footer shows frozen locked total, not live sum

## Rollback

Revert commits 7-8 and post-8 changes. Peppol flow and XML upload work normally without auto-lock. No data migration needed.
