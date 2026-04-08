# PurchaseInvoiceFormV3 -- Known Bugs

Discovered during the structural refactoring of `PurchaseInvoiceFormV3.tsx`.
These bugs were **intentionally preserved** to keep the refactor strictly behavioral-equivalent.

---

## BUG-1: InternalCommentSection -- orphaned local state

**Severity**: High (data loss)
**File**: `sections/InternalCommentSection.tsx`
**Original lines**: 776-791

The component uses `useState('')` for the comment textarea. This value is never wired to react-hook-form -- it is silently discarded on submit. The `approvalNote` field exists in the Zod schema (`purchaseInvoiceFormV2Schema`) and in `defaultInvoiceFormV3Values` but is not connected to this UI.

**Suggested fix**: Replace `useState` with `useController({ name: 'approvalNote' })` or `register('approvalNote')` and bind the textarea to the form field.

---

## BUG-2: OptionalInfoSection -- dead props

**Severity**: Low (missing constraint)
**File**: `sections/OptionalInfoSection.tsx`
**Original lines**: 692-697

The component receives `minInvoiceDate` and `maxInvoiceDate` as props but never passes them to the `DatePicker` for `dueDate`. The due date picker therefore has no min/max constraint, allowing users to select any date.

**Suggested fix**: Pass `minDate={minInvoiceDate}` and `maxDate={maxInvoiceDate}` to the `DatePicker` component (verify the DatePicker API supports these props first).

---

## BUG-3: handleOpenPreview -- stale closure risk

**Severity**: Medium (UX glitch)
**File**: `PurchaseInvoiceFormV3.tsx`
**Original lines**: 259-282

`handleOpenPreview` depends on `file` from `watch('file')` and is used in a `useEffect` (auto-preview after AI extraction) via the dependency array. The effect re-fires on every file change even when extraction state hasn't changed, because `file` changes cause `handleOpenPreview` to get a new identity.

**Suggested fix**: Use a ref for the file value inside the effect, or gate the effect more precisely on `aiExtraction.isExtracted` transitioning from `false` to `true`.

---

## BUG-4: date bounds recreated every render

**Severity**: Low (minor performance)
**File**: `PurchaseInvoiceFormV3.tsx` (now via `constants.ts` -> `getInvoiceDateBounds()`)
**Original lines**: 235-236

`new Date()` objects are created on every render for `minInvoiceDate` and `maxInvoiceDate`. While functionally correct, this creates unnecessary object allocations and can cause child components receiving these as props to re-render.

**Suggested fix**: Memoize with `useMemo(() => getInvoiceDateBounds(), [])` in the main component, or compute once at module level if the bounds don't need to update within a session.
