# Unit Tests — Purchase Invoice Form V3

Pure-logic tests for exported utility functions used by the purchase invoice form. These tests were extracted from integration specs where they tested standalone functions directly without component rendering.

## Spec Index

| Spec File | Function(s) Under Test | Source File | Cases |
|-----------|----------------------|-------------|-------|
| [splitAmount.md](./splitAmount.md) | `splitAmount` | `@/common/utils/splitAmount.ts` | 2 |
| [amountCalculationRounding.md](./amountCalculationRounding.md) | `calculateSubtotalFromTotal`, `calculatePurchaseInvoiceAmount` | `components/invoice-lines/utils/amountCalculation.ts` | 3 |
| [transformPeppolToFormData.md](./transformPeppolToFormData.md) | `transformPeppolToFormData`, `groupAmountsByVatRate`, `sumTotalAmounts` | `purchase-invoice-v2/utils/transformPeppolToFormData.ts`, `components/invoice-lines/pipeline/sumTotalAmounts.ts` | 4 |

**Total: 9 unit test cases**

## Relationship to Integration Tests

These unit tests complement the integration specs in `../integration/`. The integration tests cover how these functions are wired into components (e.g., footer displays, form population, lock state). The unit tests here guard the mathematical and parsing guarantees of the functions themselves.
