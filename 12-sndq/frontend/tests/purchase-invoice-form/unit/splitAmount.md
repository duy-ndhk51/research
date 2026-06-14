# splitAmount Rounding

**Status**: Not started
**Priority**: HIGH (rounding errors in integer cents math can lose/gain cents across units)
**Test tier**: Unit
**Target file**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/unit/splitAmount.test.ts`
**Function(s) under test**: `splitAmount` from `@/common/utils/splitAmount.ts`

## Purpose

Guard the `splitAmount` rounding guarantees: parts always sum exactly to the total, no part is negative, and equal-share groups differ by at most 1 cent. The function uses `Math.floor` per part then distributes the remainder 1 cent at a time across groups.

## Origin

These tests were extracted from `integration/amount-distribution-sheet.md` where they tested `splitAmount` directly (pure-logic, no component rendering). Since `splitAmount` is an exported standalone utility used by 16+ files, unit tests are the correct tier.

## Scenarios

| Test Name | Expected Outcome |
|-----------|------------------|
| 3 equal shares, non-divisible total | Parts sum exactly to total, no cent lost |
| 2 equal shares, odd total | One unit gets +1 cent, sum still exact |

## Shared Setup

```typescript
import { describe, it, expect } from 'vitest';
import { splitAmount } from '@/common/utils/splitAmount';
```

---

## splitAmount rounding -- 3 equal shares with non-divisible total

> Documents that `splitAmount` guarantees parts sum exactly to the total, even when the total is not evenly divisible. Uses `Math.floor` per part then distributes the remainder 1 cent at a time.

**Preconditions**: Pure calculation test using `splitAmount` directly.

### Steps

1. Call `splitAmount(10000, [333, 333, 334], 1000)` (near-equal shares, total not divisible by 3)
2. Call `splitAmount(10001, [333, 333, 334], 1000)` (odd total)
3. Call `splitAmount(10000, [333, 333, 333], 999)` (exactly equal shares, non-divisible)

### Expected Outcome (current behavior)

- In all cases, `parts.reduce((a, b) => a + b, 0)` equals the original `total` exactly
- No part is negative
- For equal shares, the difference between any two parts is at most 1 cent

### Example Code

```typescript
it('splitAmount with near-equal shares sums exactly to total', () => {
  // 3 near-equal shares, total 10000
  const result1 = splitAmount(10000, [333, 333, 334], 1000);
  expect(result1.reduce((a, b) => a + b, 0)).toBe(10000);
  expect(result1.every((p) => p >= 0)).toBe(true);

  // Odd total
  const result2 = splitAmount(10001, [333, 333, 334], 1000);
  expect(result2.reduce((a, b) => a + b, 0)).toBe(10001);
  expect(result2.every((p) => p >= 0)).toBe(true);

  // Exactly equal shares, non-divisible (10000 / 3 = 3333.33...)
  const result3 = splitAmount(10000, [333, 333, 333], 999);
  expect(result3.reduce((a, b) => a + b, 0)).toBe(10000);
  expect(result3.every((p) => p >= 0)).toBe(true);

  // Equal shares should produce at most 1 cent difference between parts
  const maxPart3 = Math.max(...result3);
  const minPart3 = Math.min(...result3);
  expect(maxPart3 - minPart3).toBeLessThanOrEqual(1);
});
```

---

## splitAmount rounding -- 2 equal shares with odd total

> Documents that when 2 units have identical shares and the total is odd, one unit receives +1 cent. The `splitAmount` function groups by share value and distributes remainder to groups, which may break equality when the remainder is smaller than the group size.

**Preconditions**: Pure calculation test using `splitAmount` directly.

### Steps

1. Call `splitAmount(10001, [500, 500], 1000)` (2 equal shares, odd total)
2. Call `splitAmount(9999, [500, 500], 1000)` (same but different odd total)
3. Call `splitAmount(10000, [500, 500], 1000)` (even total, should be perfectly equal)

### Expected Outcome (current behavior)

- Odd total: one unit gets `5001`, the other `5000` -- sum is `10001`
- Even total: both units get `5000` -- sum is `10000`
- In the odd case, which unit gets +1 depends on the group remainder distribution logic (Pass 2 in `splitAmount`)

### Example Code

```typescript
it('splitAmount with 2 equal shares and odd total', () => {
  // Odd total: 10001 split into 2 equal shares
  const odd = splitAmount(10001, [500, 500], 1000);
  expect(odd.reduce((a, b) => a + b, 0)).toBe(10001);
  expect(odd).toHaveLength(2);
  // One unit gets the extra cent
  expect(odd.toSorted((a, b) => a - b)).toEqual([5000, 5001]);

  // Odd total
  const odd2 = splitAmount(9999, [500, 500], 1000);
  expect(odd2.reduce((a, b) => a + b, 0)).toBe(9999);
  expect(odd2.toSorted((a, b) => a - b)).toEqual([4999, 5000]);

  // Even total: perfectly equal
  const even = splitAmount(10000, [500, 500], 1000);
  expect(even.reduce((a, b) => a + b, 0)).toBe(10000);
  expect(even).toEqual([5000, 5000]);
});
```
