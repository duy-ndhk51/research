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
- Invoice lines table orchestration: mode toggle, line CRUD, delete/duplicate, distribution sheet, footer
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
| No building/supplier selected → placeholder hint shown, no form sections rendered | Blocks premature form rendering before prerequisites met | - [x] |
| Both building + supplier set → placeholder gone, payment + other sections visible | Confirms full form appears when prerequisites satisfied | - [x] |
| `isPartialEditMode: true` → warning banner visible, fieldsets have `disabled` attribute | Prevents editing locked fields on booked invoices | - [x] |
| `isExtracting: true` → AI extraction overlay element rendered over form | Shows loading state while AI processes uploaded PDF | - [x] |

## 2. Lock State Toggle

Guards the lock state machine that controls whether invoice amounts can be edited. Lock state transitions affect editability for Peppol imports and partial edits.

| Test case | Description | Status |
|-----------|-------------|--------|
| No peppol, no partial edit → initial state is `{ locked: false }` | Default: amounts editable for manual invoices | - [x] |
| `peppolInvoiceId` set + initial amounts → auto-locks with computed `lockedTotal` | Peppol amounts auto-protected on import | - [ ] |
| Toggle unlocked→locked with 2 lines (1000 + 2500 cents) → `{ locked: true, lockedTotal: 3500 }` | Lock computes correct total from line items | - [x] |
| Toggle locked→unlocked → `{ locked: false }`, no `lockedTotal` property | Unlock clears computed total cleanly | - [x] |
| `isPartialEditMode: true` + toggle → state unchanged (early return guard) | Prevents unlocking amounts on booked invoices | - [x] |

## 3. Mode Switching

Guards the `MODE_TO_TYPE_CODE` mapping between UI mode and backend `invoiceTypeCode`.

| Test case | Description | Status |
|-----------|-------------|--------|
| Default form values → `invoiceTypeCode` is `undefined` | Regular invoices have no type code | - [x] |
| Credit note defaults → `invoiceTypeCode` is `'381'` (CREDIT_NOTE) | Credit note form pre-sets correct backend code | - [ ] |
| `MODE_TO_TYPE_CODE['credit_note']` → `'381'` | Mapping sends correct code to backend | - [x] |
| `MODE_TO_TYPE_CODE['expense_note']` → `EXPENSE_NOTE_TYPE_CODE` | Expense note uses distinct type code | - [x] |
| `MODE_TO_TYPE_CODE['invoice']` → `undefined` (clears type code) | Switching back to invoice clears type code | - [x] |

## 3b. Form Header

Guards save button states, total amount display, and draft badge visibility in the primary user action zone.

| Test case | Description | Status |
|-----------|-------------|--------|
| `isPending: false` → save button enabled | Save button interactive when not submitting | - [x] |
| `isPending: true` → save button disabled | Prevents double-submit during request | - [x] |
| 2 amounts (10000 + 5000) → total displays `150,00` | Header total computed from form amounts array | - [x] |
| `isDraft: true` + `invoiceId` set → "Draft" badge visible | Draft status indicator shown for saved drafts | - [x] |

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

## 7. Invoice Lines Table — Orchestration

Guards the `InvoiceLinesTableV3` orchestration component that wires form context, CRUD state, grouping mode, and conditional rendering together. The sub-hooks (`useLineCrud`, `useLineGrouping`, `useAmountPipeline`) are unit-tested — these integration tests verify the composed rendering behavior.

| Test case | Description | Status |
|-----------|-------------|--------|
| No `buildingId` → "Add line" button disabled with tooltip | Prevents adding lines before building prerequisite met | - [x] |
| `buildingId` set → "Add line" button enabled | Button becomes interactive when building selected | - [x] |
| `groupingStrategy: NONE` + 2 amounts → 2 `InvoiceLineCard` collapsibles rendered | Individual mode shows one card per line | - [x] |
| `groupingStrategy: ALL` + 1 amount → `SingleTotalView` rendered, no cards or add button | Simple mode shows single total input with hint | - [x] |
| Mode toggle click → `setGroupingStrategy` called with `ALL` or `NONE` | Toggle switches between single total and line-by-line | - [ ] |
| Delete button on card → `DeleteAmountDialog` opens; confirm → line removed; cancel → line kept | Single-line delete confirmation flow | - [x] |
| Duplicate button → `pipeline.execute({ type: 'DUPLICATE_LINE' })` called | Line duplication via pipeline | - [x] |
| Custom distribution button → distribution sheet opens for that line index | Sheet opens with correct `editingItem` | - [ ] |
| Footer shows VAT breakdown + total from `grouping.totals` | Computed totals displayed in footer | - [x] |
| `lockState.locked: true` → lock icon shown, `lockedTotal` displayed; `isPartialEditMode` → lock disabled | Lock state reflected in footer UI | - [x] |
| `mode: 'credit_note'` → total text uses warning color class | Credit note styling applied | - [x] |
| `invoiceId: null` → first card `defaultOpen`; `invoiceId` set → first card collapsed | Auto-expand first card only on new invoice | - [x] |
| `isDeferredCost: true` → distribution controls disabled | Deferred cost flag disables distribution | - [x] |
| Change VAT rate on line → `totalAmount` unchanged, `amount` (subtotal) recalculated | VAT rate change preserves gross total, derives net amount | - [ ] |
| Toggle VAT off → `amount` equals `totalAmount` | Disabling VAT removes tax deduction from subtotal | - [ ] |

## 8. Amount Distribution Sheet

Guards the distribution sheet UI: opening/closing, unit initialization, distribution type switching, share/amount recalculation, ledger and distribution key suggestions, and validation. Tests render the component with mocked `usePropertiesV2`, `useDistributionKeys`, and `useLedgerSuggestions`.

| Test case | Description | Status |
|-----------|-------------|--------|
| Sheet open with loading state → spinner shown | Properties/distribution key APIs pending shows loading spinner instead of form | - [ ] |
| Sheet open with properties loaded → units initialized with `selected: false, amount: 0` | Building properties map to `UnitData[]` on first open | - [ ] |
| Edit mode → form pre-fills from `editingItem` | Opening with saved line resets form to prior values | - [ ] |
| Distribution type "share" → `totalShare` = `DEFAULT_SHARE`, amounts recalculated | Share mode distributes proportionally using default base | - [ ] |
| Distribution type "percentage" → `totalShare` = `PERCENTAGE_BASE_VALUE` | Percentage mode uses 10000 as base | - [ ] |
| Distribution type "free" → per-unit amount inputs enabled | Free mode allows manual per-unit amounts | - [ ] |
| Distribution type "split_later" → all allocations cleared | Split later zeros out all unit shares/amounts | - [ ] |
| Distribution type "distribution_key" → forces `wholeBuilding` + applies key shares | Distribution key mode selects all units and applies key's share ratios | - [ ] |
| Select distribution key → shares from key applied, amounts computed | Changing distribution key recalculates all unit shares from key definition | - [ ] |
| Whole building ON → all units selected; OFF → all deselected with amounts zeroed | Toggle controls bulk unit selection state | - [ ] |
| Select/deselect individual unit → share and amount updated | Deselecting a unit zeros its share and amount | - [ ] |
| Select all checkbox → toggles all units | Header checkbox controls all unit selection states | - [ ] |
| Change `totalAmount` → amounts recalculated for non-free types | Amount change triggers proportional redistribution | - [ ] |
| Ledger suggestion chip click → `costAccount` field set | Clicking suggestion populates cost account | - [ ] |
| Distribution key suggestion chip click → switches to distribution key mode + applies key | Distribution key suggestion enables distribution key mode automatically | - [ ] |
| Submit with total mismatch → `SplitErrorDialog` shown | Validation error triggers error dialog with "divide equally" option | - [ ] |
| Unit search filters by name/address/owner | Debounced search narrows visible unit list | - [ ] |
| Unit sort by name/owner/amount | Sort controls reorder the unit list | - [ ] |

## 9. Supplier Defaults — Backfill & Auto-save

Guards the integration between supplier default hooks and the form. `useBackfillSupplierDefaults` patches empty lines when supplier defaults load; `useAutoSaveBuildingSupplierDefaults` persists settings on submit. Unit tests exist for internal logic — these integration tests verify form-level wiring.

| Test case | Description | Status |
|-----------|-------------|--------|
| Edit mode (`invoiceId` set) → backfill skipped entirely | `invoiceId` early return blocks all supplier default application | - [x] |
| Select building + supplier with defaults → empty lines get `costAccount` backfilled | Backfill triggers when supplier defaults load, patches empty fields | - [ ] |
| Select building + supplier with defaults → empty lines get `distributionKeyId` backfilled | Distribution key default applied to lines missing distribution key | - [ ] |
| Lines with existing `costAccount` → NOT overwritten by backfill | "Never overwrite" policy preserved for user/Peppol-set values | - [ ] |
| Lines with existing `distributionKeyId` → NOT overwritten by backfill | Existing distribution key stays untouched during backfill | - [ ] |
| Change supplier → backfill fires again for new pair | Ref guard resets when `buildingId`+`senderId` changes | - [ ] |
| Same supplier re-selected → backfill does NOT fire twice | Idempotency: same pair key skips re-application | - [ ] |
| Submit invoice → `saveSupplierDefaults` called with first line's `costAccount` + distribution key | Auto-save extracts settings from amount lines on successful submit | - [ ] |
| Submit with no existing link → `linkSupplier` mutation called | Creates new building-supplier association | - [ ] |
| Submit with existing link (empty fields) → `updateSupplier` called | Updates only the missing fields on existing link | - [ ] |
| Submit with existing link (all fields set) → no mutation fired | "Never overwrite" skips API call entirely | - [ ] |

## 10. Ledger Select — Credit Note Conversion

Detailed spec: [ledger-credit-note-conversion.md](./integration/ledger-credit-note-conversion.md)

Guards the `InlineLedgerSelect` tabbed UI and the credit note conversion flow: showing a confirmation dialog when a revenue-class (7xx) ledger is selected on a non-credit-note invoice, bulk-updating all expense lines to the selected ledger, and preserving existing revenue lines.

| Test case | Description | Status |
|-----------|-------------|--------|
| Expense tab renders 6xx options, Revenue tab renders 7xx options | Options correctly split by `displayCode` prefix | - [ ] |
| Select expense option on invoice mode → `onChange` called, no dialog | Normal expense selection, no conversion side effects | - [ ] |
| Select revenue option on invoice mode → confirmation dialog appears | Dialog gate before any state change | - [ ] |
| Confirm dialog → mode becomes `'credit_note'`, `invoiceTypeCode` set to `'381'` | Mode and type code updated on confirmation | - [ ] |
| Confirm with 3 lines (2× 6xx, 1× 7xx) → only 6xx lines updated | Bulk update respects existing 7xx lines | - [ ] |
| Cancel dialog → no mode change, no line updates | Cancel is a no-op | - [ ] |
| Select revenue option on credit_note mode → no dialog, `onChange` called | Already credit_note skips confirmation | - [ ] |
| Select revenue option on expense_note mode → confirmation dialog appears | `expense_note` treated same as `invoice` for conversion | - [ ] |
| Lines with `costAccount` but no `code` → treated as 6xx during bulk update | Missing code included in bulk update | - [ ] |
| Lines with `costAccount: undefined` → updated during conversion | Empty costAccount lines populated | - [ ] |
| Distribution sheet: revenue selection triggers conversion on outer invoice form | Conversion works from distribution sheet context | - [ ] |
| FormHeader mode toggle → line `costAccount` values NOT modified | Mode toggle never modifies line data | - [ ] |
| Revenue tab excludes wrong-class options when selected value is backfilled 6xx | No 6xx in Revenue list; trigger still shows selected 6xx label | - [ ] |
