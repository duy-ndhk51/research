# SNDQ Backend — Accounting Module Deep Dive

A comprehensive guide to the `src/modules/accounting/` module in sndq-be. Belgian double-entry bookkeeping system for property management.

**Created**: 2026-03-14

---

## Architecture Overview

The accounting module implements **double-entry bookkeeping** (ghi sổ kép) following the **Belgian chart of accounts** standard. Every financial event (transaction, invoice, payment) generates journal entries where total debit **must equal** total credit.

```
Financial Events → Integration Services → AccountingJournalService → Journal + Lines → Reports
```

There is **no `financial` module** — all accounting logic lives in `src/modules/accounting/`.

---

## Module Structure

```
src/modules/accounting/
├── controllers/          # 7 controllers
│   ├── accounting-balance.controller.ts
│   ├── accounting-daybook.controller.ts
│   ├── accounting-journal.controller.ts
│   ├── accounting-ledger.controller.ts
│   ├── accounting-mother.controller.ts
│   ├── accounting-report.controller.ts
│   └── accounting-year.controller.ts
├── services/             # 13 services
│   ├── accounting-journal.service.ts        # Core: create/update journals
│   ├── accounting-ledger.service.ts         # CRUD ledgers, tree view
│   ├── accounting-line.service.ts           # Line-level operations
│   ├── accounting-year.service.ts           # Fiscal years + periods
│   ├── accounting-daybook.service.ts        # Daybook management
│   ├── accounting-mother.service.ts         # Chart of accounts
│   ├── accounting-mother-ledger.service.ts  # Per-building mothers
│   ├── accounting-balance.service.ts        # Legacy (deprecated)
│   ├── accounting-report.service.ts         # P&L, Balance Sheet, Trial Balance
│   ├── accounting-owner-report.service.ts   # Owner balance/capital
│   ├── accounting-supplier-report.service.ts # Supplier balance
│   ├── accounting-report-pdf.service.ts     # PDF generation
│   └── accounting-report-xlsx.service.ts    # Excel generation
├── entities/             # 9 entities (see Data Model below)
├── dto/                  # ~35 DTOs
├── use-cases/            # 3 use-cases
│   ├── gen-mothers-are-accounting-ledgers.use-case.ts
│   ├── gen-property-accounting-ledgers.use-case.ts
│   └── set-opening-accounting-journal.use-case.ts
├── listeners/            # Event listeners
│   ├── building-accounting.listener.ts
│   ├── contact-accounting.listener.ts
│   └── mother-ledger.listener.ts
├── consumers/            # BullMQ consumers
├── subscribers/          # TypeORM subscribers
├── constants/            # Daybook codes, ledger code length
├── events/               # Domain events
└── utils/                # Entry ID gen, ledger code, monthly periods
```

---

## Data Model

### Chart of Accounts (3-layer hierarchy)

```
AccountingMother (Belgian standard, seeded from be_accounting_mothers.json)
  ├── category: equity | asset | stock | liability | cash | expense | revenue
  ├── type: income (P&L) | balance_sheet
  ├── nature: debit | credit
  └── self-referencing via motherId (hierarchical)
        │
        ▼
AccountingMotherLedger (enabled per building)
  └── links AccountingMother ↔ Building
        │
        ▼
AccountingLedger (concrete sub-accounts)
  ├── displayCode = mother code + ledger code (8 chars total)
  ├── optional links: propertyId, contactId, buildingSupplierId
  └── types: property-owner (4XXX), bank (55X), supplier, cost (6XX), revenue (7XX)
```

### Journal System

```
AccountingYear (fiscal year per building)
  └── AccountingPeriod (monthly, status: open | closed)

AccountingDaybook (journal type: 50, 60, 70, 90, 99)

AccountingJournal (one entry = one financial event)
  ├── entryId format: YYDDCCCCC (e.g. 245000001)
  ├── totalDebit, totalCredit (must be equal)
  ├── linked to: Period, Daybook
  └── reverse-linked from: Transaction, PurchaseInvoice, Payment
        │
        ▼
AccountingLine (debit/credit per ledger)
  ├── debit OR credit amount (bigint, cents)
  └── linked to AccountingLedger
```

### Key Ledger Codes (Belgian)

| Code | Meaning | Used for |
|------|---------|----------|
| **4100** | Owner - Savings | Property owner receivable (savings account) |
| **4101** | Owner - Checking | Property owner receivable (checking/card/PSP) |
| **499** | Suspense | Unmatched/pending amounts |
| **550** | Bank - Savings | Bank account (savings) |
| **551** | Bank - Checking | Bank account (checking/card/PSP) |
| **700** | Revenue - Savings | Revenue from savings transactions |
| **701** | Revenue - Checking | Revenue from checking transactions |
| **6XX** | Expenses | Cost ledgers from AllocationCost |

### Default Daybooks

| Code | Name | Purpose |
|------|------|---------|
| **50** | Financial | Bank transactions |
| **60** | Expense | Purchase invoices (costs) |
| **70** | Earnings | Income entries |
| **90** | General | Miscellaneous journal entries |
| **99** | Opening balance | Year-start balances |

---

## Entity Relationships (Full)

```
AccountingMother (1) ──< AccountingMotherLedger (N) ──< AccountingLedger (N)
       │                           │
       │                           └── Building
       └── self-reference (motherId)

AccountingLedger ──< AccountingLine (N)
       │
       ├── Property (optional)
       ├── Contact (optional)
       ├── BuildingSupplier (optional)
       └── AccountingMotherLedger

AccountingJournal ──< AccountingLine (N)
       │
       ├── AccountingPeriod ── AccountingYear
       ├── AccountingDaybook
       ├── Payment (N)
       ├── Transaction (N)
       └── PurchaseInvoice (N)

AccountLedger ──< Account (1)             # from account module
       │
       ├── AccountingDaybook
       ├── AccountingLedger (bank)
       └── AccountingLedger (revenue)

IncomeLedger ──> AccountingJournal         # from payment-matching module
       │
       └── PaymentLedger (N) ── Transaction | PurchaseInvoice | CostSettlement | Payout
```

---

## Journal Creation Flows (Core Logic)

### Flow 1: Transaction → Journal (Syndic income)

**Service**: `TransactionAccountingJournalService` (in `src/modules/transaction/`)
**Daybook**: Uses `AccountLedger.daybookId`
**Trigger**: `CostService` or `ProvisionEngineService`

| Line | Incoming (receipt) | Outgoing (refund) |
|------|-------------------|-------------------|
| Revenue (7XX) | Credit | Debit |
| Owner (4XX) | Debit | Credit |

- Groups transactions by: workspace, account, date, building
- Uses `AccountLedger` to resolve: daybook, bank ledger, revenue ledger
- Updates `Transaction.accountingJournalId`
- On amount/payer/property change: adds **correction lines** (not edit existing)

### Flow 2: Purchase Invoice → Journal (Expense recognition)

**Service**: `PurchaseInvoiceJournalService` (in `src/modules/invoices/`)
**Daybook**: 60 (Expense)
**Trigger**: Invoice approved (non-draft, has invoiceDate, buildingId, supplierId)

| Line | Regular invoice | Credit note |
|------|----------------|-------------|
| Supplier ledger | Credit | Debit |
| Cost ledgers (from AllocationCost) | Debit | Credit |

- Sets `PurchaseInvoice.accountingJournalId`
- On allocation change: calls `recreateJournalLines()`

### Flow 3: Payment Matching → Journal (Payment ↔ Transaction)

**Service**: `PaymentMatchingService` (in `src/modules/payment-matching/`)
**Daybook**: From `AccountLedger`
**Trigger**: Matching a payment to transactions

| Line | Incoming payment | Outgoing payment |
|------|-----------------|------------------|
| Bank (55X) | Debit | Credit |
| Owner (4XX) | Credit | Debit |

- Creates `IncomeLedger` + `PaymentLedger` records
- Sets `IncomeLedger.accountingJournalId`

### Flow 4: Invoice Payment → Journal (Payment ↔ Invoice)

**Service**: `PurchaseInvoiceLinkPaymentsService` (in `src/modules/invoices/`)
**Daybook**: From `AccountLedger`
**Trigger**: Linking payment to purchase invoice

| Line | Regular invoice payment | Credit note payment |
|------|------------------------|---------------------|
| Bank (55X) | Credit | Debit |
| Supplier ledger | Debit | Credit |

### Flow 5: Opening Balance

**Service**: `SetOpeningAccountingJournalUseCase`
**Daybook**: 99
**Trigger**: Manual — sets initial balances for first accounting year

---

## Reports

Generated from `AccountingReportService` (reads `AccountingLine` data, NOT the deprecated `AccountingBalance` entity):

| Report | Endpoint | Description |
|--------|----------|-------------|
| **Trial Balance** | `GET /accounting/reports/trial-balance` | All ledger balances (debit vs credit totals) |
| **Balance Sheet** | `GET /accounting/reports/balance-sheet` | Assets vs Liabilities + Equity |
| **Profit & Loss** | `GET /accounting/reports/profit-loss` | Revenue vs Expenses |
| **Balance** | `GET /accounting/reports/balance` | General balance overview |
| **Owner Capital** | `GET /accounting/reports/owners/capital` | Per-owner capital report |
| **Owner Balance** | `GET /accounting/reports/owners/balance` | Per-owner balance report |
| **Supplier Balance** | `GET /accounting/reports/suppliers/balance` | Per-supplier balance report |

Export formats: **PDF** (`AccountingReportPdfService`) and **XLSX** (`AccountingReportXlsxService`).

---

## Cross-Module Integration Map

| Source Module | Entity | Link to Accounting |
|---------------|--------|-------------------|
| **transaction** | Transaction | `accountingJournalId` → AccountingJournal |
| **invoices** | PurchaseInvoice | `accountingJournalId` → AccountingJournal |
| **payment-matching** | IncomeLedger | `accountingJournalId` → AccountingJournal |
| **account** | AccountLedger | `daybookId`, `ledgerId` (bank), `revenueLedgerId` |
| **building** | BuildingSupplier | OneToOne → AccountingLedger (supplier ledger) |
| **building** | AllocationCost | `ledgerId` → AccountingLedger (cost ledger) |

---

## Reading Order (Recommended)

### Phase 1 — Data Model (understand what exists)

1. `entities/accounting-mother.entity.ts` — Chart of accounts root
2. `entities/accounting-mother-ledger.entity.ts` — Per-building enablement
3. `entities/accounting-ledger.entity.ts` — Concrete sub-accounts
4. `entities/accounting-journal.entity.ts` — Journal entries
5. `entities/accounting-line.entity.ts` — Debit/credit lines
6. `entities/accounting-year.entity.ts` + `accounting-period.entity.ts` — Fiscal structure
7. `entities/accounting-daybook.entity.ts` — Journal types
8. `constants/default-daybooks.ts` + `constants/ledger.ts` — Magic values

### Phase 2 — Integration (how journals get created)

9. `src/modules/transaction/services/transaction-accounting-journal.service.ts`
10. `src/modules/invoices/services/purchase-invoice-journal.service.ts`
11. `src/modules/payment-matching/services/payment-matching.service.ts`
12. `src/modules/invoices/services/purchase-invoice-link-payments.service.ts`

### Phase 3 — Core Services

13. `services/accounting-journal.service.ts` — Journal CRUD + validation
14. `services/accounting-ledger.service.ts` — Ledger CRUD + auto-creation
15. `services/accounting-report.service.ts` — P&L, Balance Sheet, Trial Balance

### Phase 4 — Reports & Export

16. `services/accounting-report-pdf.service.ts`
17. `services/accounting-report-xlsx.service.ts`
18. `services/accounting-owner-report.service.ts`
19. `services/accounting-supplier-report.service.ts`

---

## Key Gotchas

- **Double-entry enforced**: Every journal MUST have totalDebit === totalCredit
- **Multi-tenant**: All queries scoped by `buildingId` + `workspaceId`
- **Money = bigint (cents)**: Never use decimal, calculate with `Decimal.js`
- **Entry ID format**: `YYDDCCCCC` — year (2 digits) + daybook code (2 digits) + counter (5 digits)
- **AccountingBalance is deprecated**: Use `AccountingReportService` for balance calculations
- **Correction, not mutation**: When transaction amounts change, correction lines are **added** to the journal (original lines stay)
- **Soft deletes cascade**: Deleting a transaction soft-deletes its journal + lines
- **Belgian specifics**: Chart of accounts seeded from `be_accounting_mothers.json`, categories and codes follow Belgian PCMN standard
