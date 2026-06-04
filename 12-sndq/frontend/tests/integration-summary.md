# Integration Tests — Purchase Invoice V3

**Runner**: Vitest + Testing Library (jsdom)
**Location**: `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/`

## What this covers

- Cross-component state wiring (form context -> section rendering)
- Conditional rendering based on form state combinations
- Lock state machine transitions and computed totals
- Mode switching side effects (invoice / credit note / expense note type codes)
- Right panel tab defaulting logic
- Auto-generated invoice number format and toggle behavior
- AI confidence indicator lifecycle
- Peppol-to-form field population wiring (the "last mile" after transform)
- Amount distribution sheet: unit selection, distribution types, share recalculation
- Supplier defaults: backfill empty lines on selection, auto-save settings on submit

## What this does NOT cover

- Real API calls (all mocked)
- Routing, navigation, URL changes
- Auth, session, cookies
- Full form submission flow (no POST/PUT)
- Visual layout, styling, responsiveness
- Backend seed data or database state

---

## 1. Form Body — Conditional Rendering

Guards the building + supplier prerequisite gate. The form body renders differently based on selection state, partial edit mode, and AI extraction status.

| Test case | Description | Status |
|-----------|-------------|--------|
| No building/supplier selected → placeholder hint shown, no form sections rendered | Blocks premature form rendering before prerequisites met | - [ ] |
| Both building + supplier set → placeholder gone, payment + other sections visible | Confirms full form appears when prerequisites satisfied | - [ ] |
| `isPartialEditMode: true` → warning banner visible, fieldsets have `disabled` attribute | Prevents editing locked fields on booked invoices | - [ ] |
| `isExtracting: true` → AI extraction overlay element rendered over form | Shows loading state while AI processes uploaded PDF | - [ ] |

## 2. Lock State Toggle

Guards the lock state machine that controls whether invoice amounts can be edited. Lock state transitions affect editability for Peppol imports and partial edits.

| Test case | Description | Status |
|-----------|-------------|--------|
| No peppol, no partial edit → initial state is `{ locked: false }` | Default: amounts editable for manual invoices | - [ ] |
| `peppolInvoiceId` set + initial amounts → auto-locks with computed `lockedTotal` | Peppol amounts auto-protected on import | - [ ] |
| Toggle unlocked→locked with 2 lines (1000 + 2500 cents) → `{ locked: true, lockedTotal: 3500 }` | Lock computes correct total from line items | - [ ] |
| Toggle locked→unlocked → `{ locked: false }`, no `lockedTotal` property | Unlock clears computed total cleanly | - [ ] |
| `isPartialEditMode: true` + toggle → state unchanged (early return guard) | Prevents unlocking amounts on booked invoices | - [ ] |

## 3. Mode Switching

Guards the `MODE_TO_TYPE_CODE` mapping between UI mode and backend `invoiceTypeCode`.

| Test case | Description | Status |
|-----------|-------------|--------|
| Default form values → `invoiceTypeCode` is `undefined` | Regular invoices have no type code | - [ ] |
| Credit note defaults → `invoiceTypeCode` is `'381'` (CREDIT_NOTE) | Credit note form pre-sets correct backend code | - [ ] |
| `MODE_TO_TYPE_CODE['credit_note']` → `'381'` | Mapping sends correct code to backend | - [ ] |
| `MODE_TO_TYPE_CODE['expense_note']` → `EXPENSE_NOTE_TYPE_CODE` | Expense note uses distinct type code | - [ ] |
| `MODE_TO_TYPE_CODE['invoice']` → `undefined` (clears type code) | Switching back to invoice clears type code | - [ ] |

## 4. Right Panel Tabs

Guards tab defaulting logic — whether users see the file uploader or Peppol attachments first. The tab condition uses `hasPeppolData` (not `hasAttachments`) — the "Peppol Attachments" tab appears whenever `peppolData` exists, showing `PeppolParsedPreview` when there are no PDF/XML attachment files.

| Test case | Description | Status |
|-----------|-------------|--------|
| No peppol data → active tab is `'uploader'`, no extra tabs | Default tab for manual invoice upload | - [ ] |
| Peppol data without attachment files → active tab is `'attachments'`, content is `PeppolParsedPreview` | Parsed Peppol data visible in attachments tab even without PDF/XML files | - [ ] |
| Peppol data cleared → extra tab removed, falls back to `'uploader'` | Deleting the Peppol file removes the tab | - [ ] |
| Peppol with 2 attachment files → active tab is `'attachments'`, content is `PeppolAttachmentsTab` | Users see Peppol attachment files first on import | - [ ] |
| User explicitly selects `'uploader'` → overrides peppol default | Manual tab choice takes priority | - [ ] |
| `hideInlineAttachments` is `true` when `peppolData` exists (regardless of attachments) | Prevents duplicate PeppolParsedPreview in uploader tab | - [ ] |
| Peppol parsed with amounts → `setLockState({ locked: true, lockedTotal: 8000 })` | Parsing triggers amount lock automatically | - [ ] |
| Peppol parsed with empty amounts → `setLockState` NOT called | Avoids locking form at zero on empty data | - [ ] |

## 5. Invoice Number & Date Fields

Guards auto-number generation format, date bounds, and AI confidence indicator lifecycle.

| Test case | Description | Status |
|-----------|-------------|--------|
| `generateInvoiceNumber('invoice', 'en')` → matches `INV-{YEAR}-{NNN}` | Correct number format for English invoices | - [ ] |
| Credit note mode → `CN-{YEAR}-{NNN}` | Credit notes use distinct prefix | - [ ] |
| Dutch locale → `AF-{YEAR}-{NNN}` | Locale-aware prefix for NL users | - [ ] |
| Expense note prefixes: en=`EN`, nl=`ON`, fr=`NF`, de=`SB` | All 4 locale prefixes verified | - [ ] |
| Toggle auto-generate off → `setValue('invoiceNumber', '')` | Clearing auto-number empties the field | - [ ] |
| Manual edit → `markFieldReviewed('invoiceNumber')` + `autoNumber.reset()` called | Manual input clears AI indicator and auto state | - [ ] |
| Date picker selects June 15 → `setValue('invoiceDate', '2026-06-15')` + `markFieldReviewed` | Date formatted as `YYYY-MM-DD` for API, clears AI indicator | - [ ] |
| `getInvoiceDateBounds()` → min is Jan 1 current year, max is today | Prevents dates outside current fiscal year (Belgian compliance) | - [ ] |
| `getFieldConfidence` returns `0.85` → indicator visible; `undefined` → hidden | AI indicator only shows when confidence exists | - [ ] |

## 6. Peppol to Invoice — Data Wiring

Verifies the last mile between `transformPeppolToFormData` output and React Hook Form `setValue` calls. Highest-priority group
| Test case | Description | Status |
|-----------|-------------|--------|
| `handlePeppolDataParsed` with full data → `setValue` called for `peppolData`, `senderId`, `invoiceNumber`, `invoiceDate`, `amounts`, `invoiceTypeCode`, `remittanceType`; then `trigger()` | All Peppol fields reach the form correctly | - [ ] |
| Peppol with `lines: []` → `amounts` is empty, `lockedTotal` is `0` (known edge case: locks at zero) | Documents known edge case with empty Peppol data | - [ ] |
| No `supplierPartyContactId` → `resetField('senderId')`, supplier data stored; `setValue('senderId')` NOT called | Unmatched supplier clears sender, stores info for display | - [ ] |
| `supplierPartyContactId` exists → `setValue('senderId', 'contact-123')`, supplier data cleared | Matched supplier auto-selects correct contact | - [ ] |
| Peppol `typeCode: '381'` → `setValue('invoiceTypeCode', '381')` | Credit note type propagates from Peppol to form | - [ ] |
| `paymentMeans.id = '+++123/4567/89002+++'` → `remittanceType` = STRUCTURED, `remittanceInfo` = `'123456789002'` | Belgian OGM reference detected and cleaned to digits | - [ ] |
| Multi-line Peppol (12100 + 5000) → `lockedTotal: 17100`, config `{ locked: true, lockedTotal: 17100 }` | Lock total computed correctly from multiple lines | - [ ] |
| Grouping individual→VAT: 3 entries become 2, same total (21330), each group has `originalLines` preserved | Regrouping preserves total and original line detail | - [ ] |

## 7. Amount Distribution Sheet

Guards the distribution sheet UI: opening/closing, unit initialization, distribution type switching, share/amount recalculation, ledger and DK suggestions, and validation. Tests render the component with mocked `usePropertiesV2`, `useDistributionKeys`, and `useLedgerSuggestions`.

| Test case | Description | Status |
|-----------|-------------|--------|
| Sheet open with loading state → spinner shown | Properties/DK APIs pending shows loading spinner instead of form | - [ ] |
| Sheet open with properties loaded → units initialized with `selected: false, amount: 0` | Building properties map to `UnitData[]` on first open | - [ ] |
| Edit mode → form pre-fills from `editingItem` | Opening with saved line resets form to prior values | - [ ] |
| Distribution type "share" → `totalShare` = `DEFAULT_SHARE`, amounts recalculated | Share mode distributes proportionally using default base | - [ ] |
| Distribution type "percentage" → `totalShare` = `PERCENTAGE_BASE_VALUE` | Percentage mode uses 10000 as base | - [ ] |
| Distribution type "free" → per-unit amount inputs enabled | Free mode allows manual per-unit amounts | - [ ] |
| Distribution type "split_later" → all allocations cleared | Split later zeros out all unit shares/amounts | - [ ] |
| Distribution type "distribution_key" → forces `wholeBuilding` + applies key shares | DK mode selects all units and applies key's share ratios | - [ ] |
| Select distribution key → shares from key applied, amounts computed | Changing DK recalculates all unit shares from key definition | - [ ] |
| Whole building ON → all units selected; OFF → all deselected with amounts zeroed | Toggle controls bulk unit selection state | - [ ] |
| Select/deselect individual unit → share and amount updated | Deselecting a unit zeros its share and amount | - [ ] |
| Select all checkbox → toggles all units | Header checkbox controls all unit selection states | - [ ] |
| Change `totalAmount` → amounts recalculated for non-free types | Amount change triggers proportional redistribution | - [ ] |
| Ledger suggestion chip click → `costAccount` field set | Clicking suggestion populates cost account | - [ ] |
| DK suggestion chip click → switches to DK mode + applies key | DK suggestion enables distribution key mode automatically | - [ ] |
| Submit with total mismatch → `SplitErrorDialog` shown | Validation error triggers error dialog with "divide equally" option | - [ ] |
| Unit search filters by name/address/owner | Debounced search narrows visible unit list | - [ ] |
| Unit sort by name/owner/amount | Sort controls reorder the unit list | - [ ] |

## 8. Supplier Defaults — Backfill & Auto-save

Guards the integration between supplier default hooks and the form. `useBackfillSupplierDefaults` patches empty lines when supplier defaults load; `useAutoSaveBuildingSupplierDefaults` persists settings on submit. Unit tests exist for internal logic — these integration tests verify form-level wiring.

| Test case | Description | Status |
|-----------|-------------|--------|
| Select building + supplier with defaults → empty lines get `costAccount` backfilled | Backfill triggers when supplier defaults load, patches empty fields | - [ ] |
| Select building + supplier with defaults → empty lines get `distributionKeyId` backfilled | DK default applied to lines missing distribution key | - [ ] |
| Lines with existing `costAccount` → NOT overwritten by backfill | "Never overwrite" policy preserved for user/Peppol-set values | - [ ] |
| Lines with existing `distributionKeyId` → NOT overwritten by backfill | Existing DK stays untouched during backfill | - [ ] |
| Change supplier → backfill fires again for new pair | Ref guard resets when `buildingId`+`senderId` changes | - [ ] |
| Same supplier re-selected → backfill does NOT fire twice | Idempotency: same pair key skips re-application | - [ ] |
| Submit invoice → `saveSupplierDefaults` called with first line's `costAccount` + DK | Auto-save extracts settings from amount lines on successful submit | - [ ] |
| Submit with no existing link → `linkSupplier` mutation called | Creates new building-supplier association | - [ ] |
| Submit with existing link (empty fields) → `updateSupplier` called | Updates only the missing fields on existing link | - [ ] |
| Submit with existing link (all fields set) → no mutation fired | "Never overwrite" skips API call entirely | - [ ] |
