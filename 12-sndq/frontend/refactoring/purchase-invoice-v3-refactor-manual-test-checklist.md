# Purchase Invoice V3 — Form Init Pipeline Refactor: Manual Test Checklist

Covers scenarios that automated tests cannot verify (UI rendering, API payloads, race conditions, visual regressions).

---

## 1. New Invoice (blank)

- [ ] Open "Add Purchase Invoice" — form loads with default values (empty name, today's date, one empty amount line)
- [ ] Submit succeeds — verify the POST payload contains expected defaults
- [ ] No console errors or warnings on mount

## 2. New Invoice from Peppol URL

- [ ] Navigate with `?peppolInvoiceId=<valid-id>` — loading screen shows while fetching
- [ ] Once loaded: invoice number, date, amounts, and building are populated from Peppol data
- [ ] `invoiceName` field is **empty** (not pre-filled with a leftover default) — this is the intentional behavioral change
- [ ] If supplier is matched: senderId is set, supplier name shows in the dropdown
- [ ] If supplier is unmatched: "Create supplier" banner appears with Peppol supplier data
- [ ] Peppol preview panel displays the raw Peppol data
- [ ] Submit succeeds — verify the payload matches what was shown in the form

## 3. Edit Existing Invoice (with Peppol)

- [ ] Open an invoice that was originally created from Peppol
- [ ] Form fields are populated from saved data, NOT re-prefilled from Peppol
- [ ] Peppol preview panel shows the stored `peppolData`
- [ ] Changing a field and saving preserves the edit

## 4. Edit Existing Invoice (without Peppol)

- [ ] Open a manually created invoice
- [ ] All saved fields are populated correctly
- [ ] No Peppol-related data is injected

## 5. Credit Note

- [ ] Open "Add Credit Note" — `invoiceTypeCode` defaults to credit note
- [ ] `isDirectDebit` is forced to `false`
- [ ] Submit with valid data — verify the payload has the credit note type code

## 6. XML File Upload (post-init)

- [ ] On an already-mounted form, upload an XML invoice file
- [ ] Form fields update with the parsed XML data (this uses `handlePeppolDataParsed`)
- [ ] Supplier matching/unmatching works the same as Peppol URL path
- [ ] Upload a second XML file — fields update again (no stale data)

## 7. AI PDF Extraction (post-init)

- [ ] Upload a PDF file — AI extraction triggers
- [ ] Extracted fields populate the form with confidence indicators
- [ ] Review/dismiss AI suggestions

## 8. Building Change Side Effects

- [ ] Change building on a form with populated distribution lines
- [ ] Distribution fields (units, distribution key, shares) are cleared
- [ ] Supplier defaults re-apply to the cleared lines (if supplier has defaults for the new building)
- [ ] Toast message confirms the clearing

## 9. Supplier Defaults Backfill

- [ ] Create a new invoice, select a building and supplier that has default ledger/distribution key
- [ ] Empty amount lines receive the supplier's default `motherId` and `distributionKeyId`
- [ ] Lines that already have a `motherId` (e.g., from Peppol) are NOT overwritten

## 10. Race Condition: Slow Peppol Fetch

- [ ] Simulate a slow network for Peppol API — form should show loading screen, not mount partially
- [ ] After data arrives, form initializes correctly in one pass (no flash of default values)
- [ ] Navigate away before data arrives, then back — no stale state

## 11. Draft Resume

- [ ] Open a draft invoice — saved draft data is populated
- [ ] If the draft had a `peppolInvoiceId`, Peppol preview shows correctly
- [ ] Draft data fields take priority over defaults

---

## Behavioral Change Log

| Area | Before | After | Risk |
|------|--------|-------|------|
| `invoiceName` from Peppol | Skipped (empty string is falsy) | Set to `''` | Low — Peppol invoices don't have a name concept |
| Peppol init timing | `useEffect` after mount → multiple `setValue` calls | Single `defaultValues` before mount | Low — gated by `isPeppolLoading` |
| `usePeppolPrefill` scope | Fetched query + initial prefill + XML upload | XML upload only | Medium — verify no other codepath depended on the useEffect |
