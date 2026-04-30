# Commit 6B Manual Tests — V3 Payment Section + Utility Toggle

## Prerequisites

- Steward V3 form accessible (create + edit routes)
- At least one supplier with payment info
- At least one property selected
- Syndic V3 form accessible for regression checks

---

## Test 1: Payment Section Renders in SectionCard

1. Open steward **create** invoice form
2. Select a supplier and at least one property
3. Scroll to the payment section

**Expected**:
- Payment section is wrapped in a `SectionCard` with a credit card icon and "Payment details" title
- Two payment method cards visible: "Direct debit" (Landmark icon) and "Bank payment" (CreditCard icon)
- Due date field visible below the method cards
- No "Set supplier as direct debit" checkbox visible anywhere

---

## Test 2: Payment Method — Direct Debit

1. From Test 1, click the **Direct debit** card

**Expected**:
- Direct debit card highlighted with brand styling (`border-brand-700 bg-brand-25`)
- Bank payment card deselected (neutral styling)
- Ponto/bank payment fields are hidden (collapsed)
- "Set supplier as direct debit" checkbox is NOT shown (hidden in steward)

---

## Test 3: Payment Method — Bank Payment

1. Click the **Bank payment** card

**Expected**:
- Bank payment card highlighted
- `PayNowViaPontoSection` appears below
- IBAN dropdowns visible (payment from / payment to)
- If Ponto is connected, Ponto status indicator visible

---

## Test 4: Credit Note Mode — Payment Section

1. Toggle invoice mode to **Credit Note** via the header mode toggle

**Expected**:
- Payment method cards disappear
- Only `PayNowViaPontoSection` is shown directly (credit notes skip method selection)
- Due date field still visible

---

## Test 5: Due Date Field

1. In the payment section, locate the **Due date** field
2. Click the date picker
3. Select a valid date

**Expected**:
- Date picker opens with selectable dates
- Selected date appears in the field
- AI confidence indicator shows if AI extraction was used

---

## Test 6: Utility Toggle in "Other" Section

1. Scroll below the payment section

**Expected**:
- A separate `SectionCard` with MoreVertical icon and "Other" title
- `UtilityToggle` visible inside — switch with "Utility" label and description
- Toggle switch is off by default

2. Toggle the utility switch **on**

**Expected**:
- Switch activates (checked state)
- `isUtility` form value is `true`

3. Toggle the utility switch **off**

**Expected**:
- Switch deactivates
- `isUtility` form value is `false`

---

## Test 7: Partial Edit Mode — Fields Disabled

1. Open **edit** form for an invoice that has payments (partial edit mode)

**Expected**:
- Warning banner at top of form
- Payment section fields are disabled (`opacity-60`, inputs not focusable)
- Utility toggle should still be interactable (it's outside the disabled fieldset) — verify this is the expected behavior

---

## Test 8: Submit — API Payload Verification

1. Create a new steward invoice with:
   - Bank payment selected
   - Payment from/to IBAN selected
   - Due date set
   - Utility toggle ON
2. Submit the form

**Expected**:
- API payload includes:
  - `isDirectDebit: false` (bank payment)
  - `paymentFrom` / `paymentTo` IBANs
  - `dueDate` with selected date
  - `isUtility: true`
- Compare structure with V2 steward payment output — should match

---

## Test 9: Submit — Direct Debit API Payload

1. Create a new steward invoice with direct debit selected
2. Submit

**Expected**:
- API payload includes `isDirectDebit: true`
- No Ponto payment fields in payload

---

## Test 10: Edit Existing Invoice — Pre-fill

1. Open edit form for an existing steward invoice with bank payment

**Expected**:
- Bank payment card is selected
- IBAN fields pre-filled with saved values
- Due date pre-filled

2. Open edit form for an existing steward invoice with direct debit

**Expected**:
- Direct debit card is selected

---

## Test 11: Syndic V3 Regression Check

1. Open syndic V3 **create** form
2. Select a building and supplier

**Expected**:
- Payment section works identically to before the refactor
- "Set supplier as direct debit" checkbox appears when applicable
- Due date field works
- "Other" section with `UtilityToggle` works
- Submit produces correct API payload

---

## Test 12: Visual Consistency

1. Open steward V3 and syndic V3 forms side by side

**Expected**:
- Payment section card styling matches (same `SectionCard` look)
- Payment method cards have same layout and hover effects
- "Other" section has consistent styling
