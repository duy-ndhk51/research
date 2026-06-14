# Amount Calculation Rounding

**Status**: Not started
**Priority**: HIGH (rounding drift can cause ±1 cent inconsistencies in stored amounts)
**Test tier**: Unit
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/unit/amountCalculationRounding.test.ts`
**Function(s) under test**: `calculateSubtotalFromTotal`, `calculatePurchaseInvoiceAmount` from `components/invoice-lines/utils/amountCalculation.ts`

## Purpose

Document and guard the known rounding behavior between the reverse calculation (`calculateSubtotalFromTotal`) and forward calculation (`calculatePurchaseInvoiceAmount`). For certain `totalAmount`/`vatRate` combinations, the round-trip drifts by ±1 cent. The footer uses a difference method (`totalAmount - exclVat`) that masks the drift in the UI, but the stored `amount` field may be inconsistent with forward calculation.

## Origin

These tests were extracted from `integration/invoice-lines-table.md` where they tested the calculation functions directly (pure-logic, no component rendering). Since `calculateSubtotalFromTotal` and `calculatePurchaseInvoiceAmount` are exported standalone utilities, unit tests are the correct tier.

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| Rounding: 6% VAT on 3333 cents (known drift) | Footer subtotal + VAT = total, but forward calc drifts by +1 |
| Rounding: multi-line mixed rates with odd cents | Footer grand total = sum of `totalAmount` fields, per-rate VAT correct |
| Round-trip: stored `amount` may not reproduce `totalAmount` | Documents known ±1 cent drift cases across vatRate/amount combos |

## Shared Setup

```typescript
import { describe, it, expect } from 'vitest';
import {
  calculateSubtotalFromTotal,
  calculatePurchaseInvoiceAmount,
} from '../../components/invoice-lines/utils/amountCalculation';
```

---

## Rounding -- non-round amount at 6% VAT (known 1-cent drift)

> **Known issue**: `calculateSubtotalFromTotal` (reverse) and `calculatePurchaseInvoiceAmount` (forward) use different rounding paths. For `totalAmount: 3333, vatRate: 6`, the reverse gives `amount: 3145`, but the forward from 3145 gives `vatAmount: 189` and `totalAmount: 3334` (off by 1). The footer uses the difference method (`lineVat = totalAmount - exclVat = 188`) which masks the drift in the displayed breakdown, but the stored `amount` is inconsistent with the forward calculation.

**Preconditions**: Pure calculation test, no rendering needed.

### Steps

1. Compute `calculateSubtotalFromTotal(3333, 6)`
2. Verify footer difference method sums correctly
3. Verify forward calc disagrees

### Expected Outcome (current behavior)

- `calculateSubtotalFromTotal(3333, 6)` returns `3145` -- stored as `line.amount`
- Footer difference: `3333 - 3145 = 188` (VAT via difference)
- `subtotal + footerVat = 3333` -- **looks correct in UI**
- But: `calculatePurchaseInvoiceAmount({ amount: 3145, hasVat: true, vatRate: 6 }).vatAmount` = `189` (forward calc disagrees by 1 cent)
- And: `calculatePurchaseInvoiceAmount({ amount: 3145, hasVat: true, vatRate: 6 }).totalAmount` = `3334` (forward total ≠ stored total)

### Example Code

```typescript
it('rounding -- 6% VAT on 3333 cents shows correct footer but forward calc drifts by 1', () => {
  // --- Verify the reverse calculation (what setTotalAmountForLine does) ---
  const subtotal = calculateSubtotalFromTotal(3333, 6);
  expect(subtotal).toBe(3145);

  // --- Verify the footer difference method (what useLineTotals does) ---
  const footerVat = 3333 - subtotal; // difference method
  expect(footerVat).toBe(188);
  expect(subtotal + footerVat).toBe(3333); // footer adds up correctly

  // --- Verify forward calc disagrees ---
  const forward = calculatePurchaseInvoiceAmount({
    amount: 3145,
    hasVat: true,
    vatRate: 6,
  });
  expect(forward.vatAmount).toBe(189); // forward says 189, not 188
  expect(forward.totalAmount).toBe(3334); // forward total is 3334, not 3333

  // The round-trip is NOT consistent:
  // setTotalAmountForLine(line, 3333) stores amount=3145
  // calculatePurchaseInvoiceAmount({ amount: 3145, vatRate: 6 }) gives totalAmount=3334
  expect(forward.totalAmount).not.toBe(3333);
});
```

---

## Rounding -- multi-line mixed rates with odd cent totals

> Documents current footer behavior with non-round amounts across multiple VAT rates.

**Preconditions**: Pure calculation test, no rendering needed.

### Steps

1. Compute reverse calculations for 3 lines:
   - Line A: `totalAmount: 3333, hasVat: false, vatRate: 0`
   - Line B: `totalAmount: 5555, hasVat: true, vatRate: 6`
   - Line C: `totalAmount: 7777, hasVat: true, vatRate: 21`
2. Verify footer totals and VAT by rate

### Expected Outcome (current behavior)

- Footer grand total: `16665` cents (sum of all `totalAmount` fields)
- Per-line subtotals via `calculateSubtotalFromTotal`
- Footer adds up: `totalExclVat + vat6 + vat21 = totalInclVat`
- Forward calcs may or may not round-trip cleanly depending on specific values

### Example Code

```typescript
it('multi-line mixed rates with odd cent totals', () => {
  // Verify the reverse calculations for each line
  const subtotalB = calculateSubtotalFromTotal(5555, 6);
  const subtotalC = calculateSubtotalFromTotal(7777, 21);

  // Line B: Math.round((5555 * 10000) / 10600) = Math.round(5240.566...) = 5241
  expect(subtotalB).toBe(5241);

  // Line C: Math.round((7777 * 10000) / 12100) = Math.round(6427.27...) = 6427
  expect(subtotalC).toBe(6427);

  // Footer totals (useLineTotals accumulation)
  const totalExclVat = 3333 + subtotalB + subtotalC;
  const totalInclVat = 3333 + 5555 + 7777;
  expect(totalInclVat).toBe(16665);

  // VAT by rate (difference method per line)
  const vat6 = 5555 - subtotalB; // 5555 - 5241 = 314
  const vat21 = 7777 - subtotalC; // 7777 - 6427 = 1350
  expect(vat6).toBe(314);
  expect(vat21).toBe(1350);

  // Footer adds up: totalExclVat + vat6 + vat21 = totalInclVat
  expect(totalExclVat + vat6 + vat21).toBe(totalInclVat);

  // Verify forward calcs to document drift
  const forwardB = calculatePurchaseInvoiceAmount({
    amount: subtotalB,
    hasVat: true,
    vatRate: 6,
  });
  const forwardC = calculatePurchaseInvoiceAmount({
    amount: subtotalC,
    hasVat: true,
    vatRate: 21,
  });

  // Forward totals may not match stored totalAmount
  expect(forwardB.totalAmount).toBe(5555);
  expect(forwardC.totalAmount).toBe(7777);
});
```

---

## Round-trip -- stored `amount` may not reproduce `totalAmount` via forward calc

> Systematically documents the round-trip inconsistency between `calculateSubtotalFromTotal` (reverse) and `calculatePurchaseInvoiceAmount` (forward) for known problematic inputs.

**Preconditions**: Pure calculation test, no rendering needed.

### Steps

1. For each `{ totalAmount, vatRate }` pair, compute `subtotal = calculateSubtotalFromTotal(totalAmount, vatRate)`
2. Feed subtotal back into `calculatePurchaseInvoiceAmount({ amount: subtotal, hasVat: true, vatRate })`
3. Compare forward `totalAmount` with original `totalAmount`

### Expected Outcome (current behavior)

Known drifting cases (forward total ≠ original total):

| totalAmount | vatRate | reverse subtotal | forward VAT | forward total | drift |
|-------------|---------|-----------------|-------------|---------------|-------|
| 3333 | 6 | 3145 | 189 | 3334 | +1 |
| 6667 | 6 | 6290 | 377 | 6667 | 0 |
| 9999 | 6 | 9433 | 566 | 9999 | 0 |
| 1111 | 21 | 918 | 193 | 1111 | 0 |
| 3333 | 21 | 2754 | 578 | 3332 | -1 |
| 9999 | 21 | 8264 | 1735 | 9999 | 0 |

### Example Code

```typescript
it('round-trip consistency -- documents known ±1 cent drift cases', () => {
  const cases = [
    { totalAmount: 3333, vatRate: 6, expectedDrift: 1 },
    { totalAmount: 6667, vatRate: 6, expectedDrift: 0 },
    { totalAmount: 9999, vatRate: 6, expectedDrift: 0 },
    { totalAmount: 1111, vatRate: 21, expectedDrift: 0 },
    { totalAmount: 3333, vatRate: 21, expectedDrift: -1 },
    { totalAmount: 9999, vatRate: 21, expectedDrift: 0 },
  ];

  for (const { totalAmount, vatRate, expectedDrift } of cases) {
    const subtotal = calculateSubtotalFromTotal(totalAmount, vatRate);
    const forward = calculatePurchaseInvoiceAmount({
      amount: subtotal,
      hasVat: true,
      vatRate,
    });
    const drift = forward.totalAmount - totalAmount;

    expect(drift).toBe(expectedDrift);

    // The footer difference method always sums correctly
    // (because it uses totalAmount - subtotal, not forward VAT)
    const footerVat = totalAmount - subtotal;
    expect(subtotal + footerVat).toBe(totalAmount);
  }
});
```
