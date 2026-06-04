# Mode Switching

**File**: `src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/mode-switching.test.ts`
**Logic under test**: `FormHeader` mode change callback and `MODE_TO_TYPE_CODE` mapping from `constants.ts`

Tests verify that switching between invoice / credit_note / expense_note sets the correct `invoiceTypeCode` form value.

**Source reference**: `constants.ts` lines 108-116, `sections/FormHeader.tsx` lines 28-34

---

## IT-009: Default mode is invoice with no type code

**Preconditions**: Form opened without mode override.

### Steps

1. Check default form values from `defaultInvoiceFormV3Values`

### Assertions

- `invoiceTypeCode` is `undefined`
- `MODE_TO_TYPE_CODE['invoice']` is `undefined` (no mapping for plain invoice)

### Example Code

```typescript
import { describe, it, expect } from 'vitest';
import {
  MODE_TO_TYPE_CODE,
  defaultInvoiceFormV3Values,
} from '../../constants';

describe('Mode switching', () => {
  it('IT-009: default mode is invoice with undefined invoiceTypeCode', () => {
    expect(defaultInvoiceFormV3Values.invoiceTypeCode).toBeUndefined();
    expect(MODE_TO_TYPE_CODE['invoice']).toBeUndefined();
  });
});
```

---

## IT-010: Switch to credit_note sets CREDIT_NOTE type code

**Preconditions**: Form in invoice mode.

### Steps

1. Look up `MODE_TO_TYPE_CODE['credit_note']`

### Assertions

- Returns `InvoiceTypeCode.CREDIT_NOTE` which is `'381'`

### Example Code

```typescript
import { InvoiceTypeCode } from '@/common/constants/invoiceTypeCode';

it('IT-010: credit_note mode maps to CREDIT_NOTE type code', () => {
  const typeCode = MODE_TO_TYPE_CODE['credit_note'];
  expect(typeCode).toBe(InvoiceTypeCode.CREDIT_NOTE);
});
```

---

## IT-011: Switch to expense_note sets EXPENSE_NOTE type code

**Preconditions**: Form in invoice mode.

### Steps

1. Look up `MODE_TO_TYPE_CODE['expense_note']`

### Assertions

- Returns `EXPENSE_NOTE_TYPE_CODE`

### Example Code

```typescript
import { EXPENSE_NOTE_TYPE_CODE } from '@/common/constants/invoiceTypeCode';

it('IT-011: expense_note mode maps to EXPENSE_NOTE type code', () => {
  const typeCode = MODE_TO_TYPE_CODE['expense_note'];
  expect(typeCode).toBe(EXPENSE_NOTE_TYPE_CODE);
});
```

---

## IT-012: Switch back to invoice clears type code

**Preconditions**: Form was in credit_note or expense_note mode.

### Steps

1. Look up `MODE_TO_TYPE_CODE['invoice']`

### Assertions

- Returns `undefined` — the `handleModeChange` callback in `FormHeader` calls `setValue('invoiceTypeCode', MODE_TO_TYPE_CODE[newMode])` which sets `undefined` for invoice mode

### Example Code

```typescript
it('IT-012: invoice mode has no type code (undefined)', () => {
  expect(MODE_TO_TYPE_CODE['invoice']).toBeUndefined();

  // This means FormHeader.handleModeChange('invoice') will call:
  // setValue('invoiceTypeCode', undefined)
});
```

---

## IT-009b: Default credit note form values have CREDIT_NOTE type code

**Preconditions**: Using `defaultCreditNoteFormV3Values`.

### Steps

1. Check the `invoiceTypeCode` in the credit note defaults

### Assertions

- `defaultCreditNoteFormV3Values.invoiceTypeCode` equals `InvoiceTypeCode.CREDIT_NOTE`

### Example Code

```typescript
import { defaultCreditNoteFormV3Values } from '../../constants';

it('IT-009b: credit note defaults include CREDIT_NOTE type code', () => {
  expect(defaultCreditNoteFormV3Values.invoiceTypeCode).toBe(
    InvoiceTypeCode.CREDIT_NOTE,
  );
});
```
