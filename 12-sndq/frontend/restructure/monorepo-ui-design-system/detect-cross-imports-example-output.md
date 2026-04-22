# detect-cross-imports.sh — Example Output

Snapshot from `sndq-fe/src` on 2026-04-20. The actual terminal output is color-coded (red/yellow/dim); this document shows plain text.

**Guide**: [detect-cross-imports-guide.md](./detect-cross-imports-guide.md)

---

```
COMPONENT LIFT CANDIDATE REPORT
Source: sndq-fe/src
Generated: 2026-04-20 17:23

──────────────────────────────────────────────────────────────────────

1. SHARED COMPONENT USAGE
Components in src/components/ imported by modules — sorted by import count.
High counts = already shared cross-module = lift candidates for blocks/primitives.

  3104  briicks
  763  ui
  696  icons
  469  form
  200  loading-spinner
  114  contact
  114  action-button
  113  filter
  96  floating-sheet
  92  skeleton
  75  common-table
  66  LocalizedCurrencyInput
  56  common-sheet
  50  detail-view
  45  compact-table
  41  financial
  35  user-tag
  32  layout
  28  IconTag
  20  building
  18  upload-button
  18  prototype
  18  Tiptap
  17  toolbar
  15  property
  14  search-input
  14  divider
  13  reusable-sections
  12  file-uploaded-preview
  12  dialogs
  12  common-hover-card
  12  MinimalTiptapEditor
  11  table-report
  11  common-drawer
  9  phone-input
  6  metric-strip
  6  info-container
  6  copy-button
  5  lease
  4  notes
  3  multilingual
  3  ai-elements
  2  vat-input
  2  timeline
  2  pin-input
  2  patrimony
  2  intercom
  2  history
  2  energy-label
  2  count-badge
  2  common-popover-multi-select
  2  ToggleView
  2  GroupedInfoHoverCard
  1  user
  1  usage
  1  tiptap-mini
  1  table
  1  sort
  1  payment-request-hover-card
  1  password-requirements
  1  number-input-stepper
  1  number-input
  1  localized-image
  1  activity

  Total shared component imports: 6481

──────────────────────────────────────────────────────────────────────

2. CROSS-MODULE COMPONENT IMPORTS
Module A importing components from module B — boundary violations.
These should either be lifted to src/components/ or to @sndq/ui-v2.

  home ← financial
    sndq-fe/src/modules/home/dashboard/CertificateSection.tsx
    @/modules/financial/components/dashboard/components/sections/DashboardSectionLayout

  home ← financial
    sndq-fe/src/modules/home/dashboard/CertificateSection.tsx
    @/modules/financial/components/dashboard/components/DashboardCard

  home ← patrimony
    sndq-fe/src/modules/home/dashboard/NotificationsSection.tsx
    @/modules/patrimony/leases/lease-detail/components

  contact ← broadcasts
    sndq-fe/src/modules/contact/overview/ContactsOverviewV2.tsx
    @/modules/broadcasts/components/letter-generation

  bookkeeping ← financial
    sndq-fe/src/modules/bookkeeping/accounts/supplier-balance/SupplierLedgerContent.tsx
    @/modules/financial/components/account-ledger-detail

  peppol ← financial
    sndq-fe/src/modules/peppol/components/PeppolInvoiceMetrics.tsx
    @/modules/financial/components/breadcrumb/FinancialBuildingSelector

  peppol ← broadcasts
    sndq-fe/src/modules/peppol/components/PeppolInvoiceSheetRoute.tsx
    @/modules/broadcasts/components/create/BroadcastCreateSheetV2

  contact-book ← financial
    sndq-fe/src/modules/contact-book/contact-detail/detail-invoices-content/DetailInvoicesContent.tsx
    @/modules/financial/components/invoices/purchase-invoice/hooks/usePurchaseInvoiceTableFilters

  search-result ← inbox
    sndq-fe/src/modules/search-result/utils/searchResultUtils.tsx
    @/modules/inbox/components/EmailProviderIcon

  search-result ← patrimony
    sndq-fe/src/modules/search-result/utils/searchResultUtils.tsx
    @/modules/patrimony/meters/components/content/MeterIcon

  ... 130 more violations omitted (140 total) ...

  Total cross-module boundary violations: 140

──────────────────────────────────────────────────────────────────────

2b. CROSS-MODULE SUMMARY (by source module)
Which modules' components are most imported by OTHER modules — top lift priorities.

  44  financial/components/
  40  broadcasts/components/
  15  patrimony/components/
  9  contact-book/components/
  6  email-settings/components/
  5  accounts/components/
  4  passport/components/
  3  peppol/components/
  3  bookkeeping/components/
  2  time-tracking/components/
  2  inbox/components/
  2  files/components/
  2  app-library/components/
  1  contact/components/
  1  ai-agent/components/
  1  activity/components/

──────────────────────────────────────────────────────────────────────

3. PENDING TODO(lift) MARKERS
Components flagged for lifting during PR review.

  No pending TODO(lift) markers found.
  Add markers during PR review:
    // TODO(lift): cross-module import, candidate for blocks

──────────────────────────────────────────────────────────────────────

Done.
See component-lifting-process.md for the full process guide.
```
