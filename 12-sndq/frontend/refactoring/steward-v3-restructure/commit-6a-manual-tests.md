# Commit 6A — Amount Mode Toggle: Manual Test Script

## Prerequisites

- Dev server running (`pnpm dev`)
- At least one building with properties created
- At least one supplier created
- At least two cost categories available

---

## Test 1: Default Mode

1. Open the steward purchase invoice **create** form
2. Verify the **Amount Mode Toggle** appears at the top of the lines section
3. Verify default mode is **"Line by line"** (individual lines)
4. Verify you can add lines normally (add button visible, line cards render)

**Expected**: Toggle visible, default is individual mode, line cards display.

---

## Test 2: Toggle to Single Total (One Line)

1. Create a new steward invoice
2. Add **one line** with amount 500.00, set VAT to 21%, set a cost category
3. Click the **"Single total"** toggle

**Expected**:
- Line cards disappear
- A single total view appears with a large amount input
- The amount shows the total from the original line
- An info hint is visible ("Use line-by-line for multiple amounts")
- VAT toggle is available
- Cost category select is available
- Distribution select is available

---

## Test 3: Edit in Single Total Mode

1. Continue from Test 2 (single total mode)
2. Change the total amount to 1000.00
3. Toggle VAT on → verify subtotal and VAT amount display
4. Change the cost category
5. Select a distribution key (or open custom distribution)

**Expected**: All edits apply to the single merged line. Values persist when toggling VAT.

---

## Test 4: Toggle Back to Line-by-Line

1. Continue from Test 2/3 (single total mode)
2. Click the **"Line by line"** toggle

**Expected**:
- Single total view disappears
- Original line(s) are restored
- Add button reappears
- Line cards show the original data (not the merged values)

---

## Test 5: Merge Without Conflict

1. Create a new steward invoice
2. Add **two lines**, both with:
   - Same cost category (e.g., "Electricity")
   - Same distribution key (or both "none")
3. Set different amounts (e.g., 100.00 and 200.00)
4. Click **"Single total"**

**Expected**:
- Lines merge directly into single total (no dialog)
- Total amount = 300.00 (sum of both)
- Cost category preserved

---

## Test 6: Merge With Cost Category Conflict

1. Create a new steward invoice
2. Add **two lines**:
   - Line 1: cost category "Electricity", amount 100.00
   - Line 2: cost category "Water", amount 200.00
3. Click **"Single total"**

**Expected**:
- A **warning dialog** appears: "Group confirm" title with description
- Two buttons: "Cancel" and "Group all"
- Click **Cancel** → stays in line-by-line mode, lines unchanged
- Click **"Single total"** again, then click **"Group all"** → lines merge into one

---

## Test 7: Merge With Distribution Key Conflict

1. Create a new steward invoice
2. Add **two lines**:
   - Line 1: distribution key "Key A"
   - Line 2: distribution key "Key B"
   - Same cost category on both
3. Click **"Single total"**

**Expected**: Warning dialog appears (conflict on distribution key).

---

## Test 8: Round-Trip Preservation

1. Create a new steward invoice
2. Add **three lines** with different amounts and cost categories
3. Record the exact values of each line
4. Click **"Single total"** (confirm merge if dialog appears)
5. Click **"Line by line"**

**Expected**: Original three lines are restored with their original amounts and cost categories.

---

## Test 9: Footer Totals in Both Modes

1. Create a steward invoice with two lines: 100.00 (21% VAT) and 200.00 (no VAT)
2. Verify footer shows: subtotal = 282.64 + excl, VAT amount, total = 300.00 + 21.00 = ~321.00
3. Toggle to **single total** → verify footer totals remain consistent
4. Toggle back → verify footer totals match original

**Expected**: Footer totals are correct and consistent in both modes.

---

## Test 10: Custom Distribution in Single Total

1. Toggle to **single total** mode
2. Click the distribution select → choose "Custom distribution"
3. Verify the `StewardAmountDistributionSheet` opens
4. Set custom distribution values and submit

**Expected**: Custom distribution applies to the single merged line. Sheet opens and closes correctly.

---

## Test 11: Submit in Both Modes

1. Fill a complete steward invoice in **line-by-line** mode and submit
2. Verify API payload has `amounts` array with multiple entries
3. Create another invoice, toggle to **single total**, fill, and submit
4. Verify API payload has `amounts` array with one entry

**Expected**: API payloads are correct in both modes.

---

## Test 12: Interaction with Properties

1. Create a steward invoice, select properties, add lines
2. Toggle to **single total** mode
3. Change the selected properties

**Expected**: Distribution is cleared with toast notification (existing behavior). Single total view updates accordingly.
