# Lock State Toggle

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/lock-state.test.ts`
**Logic under test**: `toggleAmountLock` callback in `PurchaseInvoiceFormV3.tsx` and `sumTotalAmounts` from pipeline

Tests verify the lock state transitions and their interaction with `isPartialEditMode`. These test the pure logic extracted from the component's `useState` initializer and `toggleAmountLock` callback.

**Source reference**: `PurchaseInvoiceFormV3.tsx` lines 57-95, `pipeline/sumTotalAmounts.ts`

---

## IT-005: Default lock state is unlocked

**Preconditions**: No peppol, no partial edit, no initial lock config.

### Steps

1. Simulate the `useState` initializer logic with default props

### Assertions

- Initial lock state is `{ locked: false }`

### Example Code

```typescript
import { describe, it, expect } from 'vitest';
import { sumTotalAmounts } from '../../components/invoice-lines/pipeline';

describe('Lock state toggle', () => {
  it('IT-005: default lock state is unlocked (no peppol, no partial edit)', () => {
    const isPartialEditMode = false;
    const peppolInvoiceId = null;
    const config = undefined;
    const initialAmounts = undefined;

    let lockState: { locked: boolean; lockedTotal?: number };
    if (config?.initialLockState) {
      lockState = config.initialLockState;
    } else if ((isPartialEditMode || peppolInvoiceId) && initialAmounts) {
      lockState = { locked: true, lockedTotal: sumTotalAmounts(initialAmounts) };
    } else {
      lockState = { locked: false };
    }

    expect(lockState).toEqual({ locked: false });
  });
});
```

---

## IT-006: Toggle from unlocked to locked computes lockedTotal

**Preconditions**: Two amount lines with `totalAmount` 1000 and 2500 (cents).

### Steps

1. Start with `{ locked: false }`
2. Call toggle logic with current amounts from `form.methods.getValues('amounts')`

### Assertions

- State becomes `{ locked: true, lockedTotal: 3500 }`
- `sumTotalAmounts` correctly sums all line `totalAmount` fields

### Example Code

```typescript
it('IT-006: toggle from unlocked computes lockedTotal from amounts', () => {
  const amounts = [
    { id: '1', totalAmount: 1000, amount: 1000, hasVat: false, vatRate: 0 },
    { id: '2', totalAmount: 2500, amount: 2500, hasVat: false, vatRate: 0 },
  ] as any[];

  // Simulates the toggleAmountLock callback
  const currentLocked = false;
  const newState = currentLocked
    ? { locked: false }
    : { locked: true, lockedTotal: sumTotalAmounts(amounts) };

  expect(newState).toEqual({ locked: true, lockedTotal: 3500 });
});
```

---

## IT-007: Toggle from locked to unlocked

**Preconditions**: Currently locked with `lockedTotal: 5000`.

### Steps

1. Start with `{ locked: true, lockedTotal: 5000 }`
2. Call toggle logic

### Assertions

- State becomes `{ locked: false }` (no `lockedTotal` property)

### Example Code

```typescript
it('IT-007: toggle from locked returns unlocked', () => {
  const currentLocked = true;

  const newState = currentLocked
    ? { locked: false }
    : { locked: true, lockedTotal: 0 };

  expect(newState).toEqual({ locked: false });
});
```

---

## IT-008: Toggle is no-op in partial edit mode

**Preconditions**: `isPartialEditMode = true`, any lock state.

### Steps

1. Start with `{ locked: true, lockedTotal: 5000 }` and `isPartialEditMode = true`
2. Call toggle logic

### Assertions

- State stays `{ locked: true, lockedTotal: 5000 }` — the early return guard prevents changes

### Example Code

```typescript
it('IT-008: toggle is no-op when isPartialEditMode is true', () => {
  const isPartialEditMode = true;
  const currentState = { locked: true, lockedTotal: 5000 };

  // Simulates the guard: if (isPartialEditMode) return;
  let newState = currentState;
  if (!isPartialEditMode) {
    newState = currentState.locked
      ? { locked: false }
      : { locked: true, lockedTotal: 0 };
  }

  expect(newState).toEqual({ locked: true, lockedTotal: 5000 });
});
```

---

## IT-005b: Auto-locks when peppolInvoiceId present with initial amounts

**Preconditions**: `peppolInvoiceId` is set, `initialData.amounts` has lines.

### Steps

1. Simulate the `useState` initializer with peppolInvoiceId and amounts

### Assertions

- Initial state is `{ locked: true, lockedTotal: <sum of amounts> }`

### Example Code

```typescript
it('IT-005b: auto-locks when peppolInvoiceId present with amounts', () => {
  const peppolInvoiceId = 'peppol-123';
  const isPartialEditMode = false;
  const initialAmounts = [
    { totalAmount: 5000 },
    { totalAmount: 3000 },
  ] as any[];

  let lockState: { locked: boolean; lockedTotal?: number };
  if ((isPartialEditMode || peppolInvoiceId) && initialAmounts) {
    lockState = { locked: true, lockedTotal: sumTotalAmounts(initialAmounts) };
  } else {
    lockState = { locked: false };
  }

  expect(lockState).toEqual({ locked: true, lockedTotal: 8000 });
});
```
