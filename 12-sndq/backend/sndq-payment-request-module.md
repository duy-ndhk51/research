# SNDQ — Payment Request Module Deep Dive

A comprehensive guide to the `src/modules/transaction/` module in sndq-be. Core financial feature that manages payment collection and disbursement in a Belgian property management platform.

**Created**: 2026-03-15

---

## Terminology

| Backend (code) | Frontend (UI) | Description |
|----------------|---------------|-------------|
| Transaction | Payment request | A request to collect or pay money |
| TransactionLine | Line item | Breakdown of amounts within a payment request |
| TransactionGroup | Payment request group | Batch of related payment requests (e.g. capital calls) |
| TransactionReminder | Reminder | Overdue notice sent to payer |
| TransactionForward | Forward | Transferring collected funds to another IBAN |

> Throughout the codebase, "transaction" = "payment request". The mapping happens via i18n (en: "payment request", fr: "demande de paiement", nl: "betalingsverzoek", de: "Zahlungsanfrage").

---

## Architecture Overview

A payment request represents a **financial obligation** between the workspace (property manager) and a contact (tenant, owner, etc.). It supports the full lifecycle: creation → announcement → reminder → payment matching → forwarding.

```
Lease Engine / Cost Engine / Manual
        │
        ▼
  Transaction (payment request)
        │
        ├──→ PDF Generation (cost request with QR code)
        ├──→ Reminders (1st, 2nd, 3rd via BullMQ)
        ├──→ Payment Matching (bank ↔ transaction via PaymentLedger)
        ├──→ Forwarding (re-send collected funds to owner IBAN)
        └──→ Accounting Journal (double-entry bookkeeping)
```

---

## Module Structure

```
src/modules/transaction/
├── transaction.module.ts
├── transaction.service.ts                    # Main orchestration
├── controllers/
│   ├── transaction.controller.ts             # CRUD, PDF, forward
│   ├── transaction-reminder.controller.ts    # Reminder endpoints
│   └── transaction-attachment.controller.ts  # File attachments
├── services/
│   ├── transaction-request.service.ts        # PDF generation (cost request)
│   ├── transaction-reminder.service.ts       # Reminder creation & queueing
│   ├── transaction-timeline.service.ts       # Activity timeline
│   ├── transaction-update.service.ts         # Update logic
│   ├── transaction-forward.service.ts        # Forward management
│   ├── transaction-attachment.service.ts     # Attachment CRUD
│   └── transaction-accounting-journal.service.ts  # Accounting integration
├── entities/
│   ├── transaction.entity.ts                 # Core entity
│   ├── transaction-line.entity.ts            # Line items
│   ├── transaction-reminder.entity.ts        # Reminder batch
│   ├── transaction-reminder-item.entity.ts   # Reminder ↔ transaction link
│   ├── transaction-forward.entity.ts         # Forward record
│   └── transaction-attachment.entity.ts      # Attachments
├── dto/
│   ├── create-transaction.dto.ts
│   ├── update-transaction.dto.ts
│   ├── query-transactions.dto.ts
│   ├── transaction-detail.response.dto.ts
│   └── ... (~15 DTOs)
├── use-cases/
│   ├── forward-transaction.use-case.ts       # Forward flow orchestration
│   └── export-transaction-data.use-case.ts   # Data export
├── consumers/
│   └── transaction-reminder.consumer.ts      # BullMQ: generate reminder PDFs
├── listeners/
│   └── transaction-forward.listener.ts       # React to forward events
├── subscribers/
│   └── transaction.subscriber.ts             # TypeORM entity subscriber
├── events/
│   ├── transaction-created.event.ts
│   └── transaction-updated.event.ts
└── constants/
    ├── transaction-types.ts                  # TransactionType enum
    ├── transaction-reminder-type.ts          # ReminderType enum
    ├── transaction-forward-status.ts         # ForwardStatus enum
    └── queue.constants.ts                    # BullMQ queue names
```

---

## Data Model

### Transaction Entity (Core)

```
transactions
├── id                      uuid, PK
├── workspace_id            uuid, FK → workspaces
├── lease_id                uuid, FK → leases (nullable)
├── lease_period_id         uuid, FK → lease_periods (nullable)
├── cost_settlement_id      uuid, FK → cost_settlements (nullable)
├── transaction_group_id    uuid, FK → transaction_groups (nullable)
├── property_id             uuid, FK → properties (nullable)
├── sales_invoice_id        uuid, FK → sales_invoices (nullable)
├── account_id              uuid, FK → accounts (bank account)
├── beneficiary_contact_id  uuid, FK → contacts (who receives money)
├── payer_contact_id        uuid, FK → contacts (who pays)
├── accounting_journal_id   uuid, FK → accounting_journals (nullable)
│
├── name                    varchar
├── description             text (nullable)
├── currency                varchar (default: EUR)
│
├── amount                  bigint (cents, excl. VAT)
├── amount_vat              bigint (cents)
├── amount_total            bigint (cents, incl. VAT)
├── amount_due              bigint (cents, remaining unpaid)
│
├── date                    date (transaction date)
├── date_due                date (payment deadline)
├── date_paid               date (nullable, when fully paid)
│
├── status                  enum: UNPAID | PARTLY_PAID | PAID | EXPECTED | TOO_LATE
├── type                    enum: (see Transaction Types below)
├── direction               enum: PAYABLE | RECEIVABLE
│
├── remittance_type         enum: UNSTRUCTURED | STRUCTURED | RANDOM
├── remittance_info         varchar (payment reference / structured communication)
│
├── announcement_sent_at    timestamp (nullable)
├── reminder_count          int (default: 0)
├── last_reminder_sent_at   timestamp (nullable)
│
├── created_by_rent_engine      boolean
├── created_by_provision_engine boolean
│
├── created_at              timestamp
├── updated_at              timestamp
├── deleted_at              timestamp (soft delete)
├── created_by              uuid
├── updated_by              uuid
└── deleted_by              uuid
```

### Transaction Types

| Type | Direction | Description |
|------|-----------|-------------|
| `RENT` | RECEIVABLE | Monthly rent payment |
| `PROVISION` | RECEIVABLE | Advance for shared building costs |
| `FLAT_RATE_FOR_COSTS` | RECEIVABLE | Fixed-rate cost charge |
| `ADVANCE_PAYMENT_FOR_COSTS` | RECEIVABLE | Advance payment for costs |
| `ADVANCE_PAYMENT_FOR_PROPERTY_TAX` | RECEIVABLE | Advance for property tax |
| `INTEREST_ON_ARREARS` | RECEIVABLE | Interest charged on overdue amounts |
| `INITIAL_BALANCE` | RECEIVABLE | Opening balance from previous system |
| `SETTLEMENT_OF_COSTS` | RECEIVABLE | Cost settlement result |
| `SETTLEMENT_OF_REAL_ESTATE_TAX` | RECEIVABLE | Property tax settlement |
| `INSTALLMENT_PLAN` | RECEIVABLE | Payment plan installment |
| `ADJUSTMENT_AFTER_INDEXATION` | RECEIVABLE | Rent adjustment after index |
| `OTHERS` | RECEIVABLE | Miscellaneous |
| `LATE_FEE` | RECEIVABLE | Penalty for late payment |
| `LEASE_DEPOSIT` | RECEIVABLE | Security deposit |
| `REFUND` | PAYABLE | Money returned to contact |
| `REBALANCE_SETTLEMENT` | varies | Rebalance after settlement |
| `ASK_FOR_FORWARD` | varies | Request to forward funds |

### Transaction Status Lifecycle

```
                    ┌──────────────┐
                    │   UNPAID     │ ← Initial state
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
      ┌──────────┐  ┌───────────┐  ┌──────────┐
      │ TOO_LATE │  │PARTLY_PAID│  │   PAID   │
      └────┬─────┘  └─────┬─────┘  └──────────┘
           │               │              ▲
           ├───────────────┤              │
           │               └──────────────┘
           └──────────────────────────────┘
```

- **UNPAID** → created, no payments received
- **PARTLY_PAID** → partial payment matched
- **PAID** → fully paid (amount_due = 0)
- **TOO_LATE** → past due date and still unpaid
- **EXPECTED** → (deprecated, legacy)

### Transaction Line Entity

```
transaction_lines
├── id                  uuid, PK
├── transaction_id      uuid, FK → transactions
├── name                varchar
├── amount              bigint (cents)
├── amount_vat          bigint (cents)
├── amount_total        bigint (cents)
├── vat_rate            int (percentage)
└── timestamps + soft delete
```

### Transaction Forward Entity

```
transaction_forwards
├── id                  uuid, PK
├── transaction_id      uuid, FK → transactions (OneToOne)
├── workspace_id        uuid, FK → workspaces
├── status              enum: WAITING | READY | PROCESSING | COMPLETED | FAILED | CANCELLED
├── payment_initiation_id  uuid, FK (nullable)
└── timestamps + soft delete
```

### Transaction Reminder Entities

```
transaction_reminders (batch)             transaction_reminder_items (link)
├── id              uuid, PK              ├── id                  uuid, PK
├── workspace_id    uuid, FK              ├── transaction_reminder_id  uuid, FK
├── type            enum (FIRST/SECOND/   ├── transaction_id      uuid, FK
│                   THIRD)                └── timestamps
├── sent_at         timestamp
└── timestamps

```

### Transaction Attachment Entity

```
transaction_attachments
├── id              uuid, PK
├── transaction_id  uuid, FK → transactions
├── workspace_id    uuid, FK
├── file_name       varchar
├── file_key        varchar (S3 key)
├── file_size       bigint
├── mime_type       varchar
└── timestamps + soft delete
```

---

## Entity Relationships (Full Map)

```
Workspace (1) ──────< Transaction (N)
Lease (1) ──────────< Transaction (N)
LeasePeriod (1) ────< Transaction (N)
Property (1) ───────< Transaction (N)
Contact (1) ────────< Transaction (N) as payerContact
Contact (1) ────────< Transaction (N) as beneficiaryContact
Account (1) ────────< Transaction (N)
SalesInvoice (1) ──── Transaction (1)
CostSettlement (1) ─< Transaction (N)
TransactionGroup (1) ─< Transaction (N)
AccountingJournal (1) ── Transaction (1)

Transaction (1) ──< TransactionLine (N)
Transaction (1) ──< PaymentLedger (N) ── Payment
Transaction (1) ──── AllocationSplit (1)
Transaction (1) ──── TransactionForward (1)
Transaction (1) ──< TransactionReminderItem (N) ── TransactionReminder
Transaction (1) ──< TransactionAttachment (N)
Transaction (1) ──< LateFeeTransaction (N) (self-ref: original ↔ late fee)
```

---

## API Endpoints

### Transaction Controller (`/transactions`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/transactions` | List with filtering, sorting, pagination |
| `GET` | `/transactions/:transactionId` | Get detail by ID |
| `PATCH` | `/transactions/:transactionId` | Update fields |
| `DELETE` | `/transactions/:transactionId` | Soft delete |
| `DELETE` | `/transactions/bulk` | Bulk soft delete |
| `POST` | `/transactions/restore` | Bulk restore |
| `POST` | `/transactions/:transactionId/generate-pdf` | Generate cost request PDF with QR code |
| `GET` | `/transactions/:transactionId/timeline` | Activity timeline (creation, updates, payments, reminders) |
| `POST` | `/transactions/:transactionId/forward` | Forward paid amount to another IBAN |

### Transaction Reminder Controller

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/transactions/reminders` | Create and queue reminder batch |

### Transaction Attachment Controller

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/transactions/:transactionId/attachments` | List attachments |
| `POST` | `/transactions/:transactionId/attachments` | Upload attachment |
| `DELETE` | `/transactions/:transactionId/attachments/:attachmentId` | Delete attachment |

### Transaction Group Controller (`/transaction-groups`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/transaction-groups` | Create group |
| `GET` | `/transaction-groups` | List groups |
| `GET` | `/transaction-groups/:id` | Get group |
| `PATCH` | `/transaction-groups/:id` | Update group |
| `DELETE` | `/transaction-groups/:id` | Delete group |
| `POST` | `/transaction-groups/:id/transactions` | Add transactions to group |
| `DELETE` | `/transaction-groups/:id/transactions` | Remove transactions from group |

---

## Key Business Logic Flows

### Flow 1: Automated Creation via Engines

Payment requests are rarely created manually. Two engines generate them automatically:

**Rent Engine** (`LeasePeriodService`):
```
Lease → LeasePeriod (monthly) → Transaction (type: RENT)
  - Sets: amount from lease, payerContact from tenant, account from building
  - Marks: created_by_rent_engine = true
```

**Provision Engine** (`ProvisionEngineService`):
```
Lease → Provision config → Transaction (type: PROVISION)
  - Sets: provision amount, payerContact from tenant
  - Marks: created_by_provision_engine = true
```

**Cost Module** (`CostService`):
```
AllocationCost → AllocationSplit → Transaction
  - Types: ADVANCE_PAYMENT_FOR_COSTS, FLAT_RATE_FOR_COSTS, etc.
  - Allocates building costs proportionally to owners/tenants
```

**Cost Settlement** (`CostSettlementService`):
```
CostSettlement → Transaction (type: SETTLEMENT_OF_COSTS)
  - Settles the difference between provisions paid and actual costs
```

### Flow 2: Payment Matching

When bank transactions arrive (via Ponto Connect), they get matched to payment requests:

```
Bank Transaction (Payment)
    │
    ▼
PaymentMatchingService.matchPayment()
    │
    ├── Create PaymentLedger (links Payment ↔ Transaction)
    ├── Update Transaction.amount_due (subtract matched amount)
    ├── Update Transaction.status:
    │     amount_due === 0 → PAID (set date_paid)
    │     amount_due > 0   → PARTLY_PAID
    └── Create AccountingJournal entry:
          Debit: Bank (55X)
          Credit: Owner (4XX)
```

### Flow 3: Reminders

```
User selects overdue transactions
    │
    ▼
TransactionReminderService.createReminders()
    │
    ├── Create TransactionReminder batch
    ├── Create TransactionReminderItem for each transaction
    ├── Queue BullMQ job: 'generate-reminder-pdf'
    │
    ▼
TransactionReminderConsumer
    │
    ├── Generate PDF for each reminder item
    ├── Update Transaction.reminder_count++
    └── Update Transaction.last_reminder_sent_at
```

Reminder types escalate: `FIRST` → `SECOND` → `THIRD`

### Flow 4: Forwarding

After collecting rent from tenants, the property manager forwards funds to the property owner:

```
Transaction (PAID, direction: RECEIVABLE)
    │
    ▼
ForwardTransactionUseCase.execute()
    │
    ├── Create TransactionForward (status: WAITING)
    ├── Create PaymentInitiation (Ponto/Isabel API)
    │     - beneficiary = owner's IBAN
    │     - amount = transaction.amount_total
    │     - reference = remittance_info
    ├── Update TransactionForward.status → PROCESSING
    │
    ▼ (async, via payment initiation service)
    │
    ├── Success → TransactionForward.status = COMPLETED
    └── Failure → TransactionForward.status = FAILED
```

### Flow 5: Accounting Integration

Every payment request generates double-entry journal entries:

```
TransactionAccountingJournalService.createOrUpdateJournal()
    │
    ├── Resolve AccountLedger → daybook, bank ledger, revenue ledger
    ├── Create AccountingJournal
    └── Create AccountingLines:
          RECEIVABLE:
            Debit:  Owner ledger (4XXX)
            Credit: Revenue ledger (7XX)
          PAYABLE (refund):
            Debit:  Revenue ledger (7XX)
            Credit: Owner ledger (4XXX)
```

On amount/payer/property changes: **correction lines** are added (original lines preserved for audit trail).

---

## Frontend Access

### Routes

| Context | URL | Component |
|---------|-----|-----------|
| Building costs | `/financial/buildings/[buildingId]/costs` | `CostSyndicOverview` |
| Building detail | `.../costs/transactions/[transactionId]` | `PaymentRequestFloatingSheetContent` |
| Global costs | `/financial/costs` | `CostStewardOverview` |
| Global detail | `/financial/costs/transactions/[transactionId]` | `CostDetail` |
| Edit | `.../transactions/[transactionId]/edit` | Edit form |
| Lease-scoped | `/financial/costs/[leaseId]/detail/[transactionId]` | Lease cost detail |

### Route Helpers (`src/common/constants/system.ts`)

```typescript
routerPaths.financial.buildings.costs.root(buildingId)
routerPaths.financial.buildings.costs.transactions.detail(buildingId, transactionId)
routerPaths.financial.cost.root()
routerPaths.financial.cost.detail(transactionId)
routerPaths.financial.cost.edit(transactionId)
routerPaths.financial.cost.lease.detail(transactionId, leaseId)
```

### Data Flow

```
financialCostApi.tsx (HTTP) → financialCostService.ts (wrapper) → React Query hooks → Components
```

| Layer | File | Key exports |
|-------|------|-------------|
| API | `src/common/api/resources/financial/financialCostApi.tsx` | CRUD, reminders, timeline, forward |
| Service | `src/services/financial/financialCostService.ts` | Typed wrappers |
| Hooks | `src/hooks/financial/useFinancialCost.ts` | `useTransactionById`, `useCosts`, `useDeleteTransaction` |
| Hooks | `src/hooks/financial/useTransaction.ts` | `useTransactionsPaginated`, `useTransactionTimeline` |
| Models | `src/common/models/transaction.ts` | `Transaction`, `TransactionStatus`, `TransactionType` |
| Store | `src/modules/financial/stores/selectedTransactionsStore.ts` | Zustand multi-select |

### Key Components

| Component | Purpose |
|-----------|---------|
| `CostSyndicOverview` | Building payment requests table |
| `AllTransactionTable` | Global transaction table |
| `CostDetail` | Full-page detail view |
| `PaymentRequestFloatingSheetContent` | Floating sheet detail (building context) |
| `PaymentRequestHoverCard` | Hover preview card |
| `DeleteTransactionDialog` | Delete confirmation |
| `TransactionAttachmentsSection` | File attachments UI |

---

## Cross-Module Integration Map

| Source Module | How it connects |
|---------------|-----------------|
| **lease** | Lease + LeasePeriod → auto-creates RENT transactions via rent engine |
| **provision** | Provision config → auto-creates PROVISION transactions |
| **cost** | AllocationCost → AllocationSplit → creates cost-type transactions |
| **cost-settlement** | Settles provisions vs actuals → creates SETTLEMENT_OF_COSTS |
| **payment-matching** | Matches bank payments → updates amount_due and status |
| **account** | Bank account (IBAN) for payment collection |
| **accounting** | Creates journal entries (debit/credit) per transaction |
| **invoices** | SalesInvoice can be linked to transactions |
| **payment-initiation** | Ponto/Isabel for forwarding payments |
| **contact** | Payer (tenant) and beneficiary (owner) contacts |
| **property** | Property linked to transaction for allocation |
| **broadcast** | Can target transactions via `BroadcastEntityType.TRANSACTION` |
| **late-fee** | Creates LATE_FEE transactions linked to overdue originals |

---

## External Service Integration

### Ponto Connect (Belgian Banking API)

- **Payment request activation**: Workspace can activate payment requests through Ponto (`paymentRequestsActivated` / `paymentRequestsActivationRequested` flags)
- **Payment initiation**: Used for forwarding — creates SEPA credit transfers to owner IBANs
- **Bank sync**: Incoming bank transactions are matched against payment requests

### PDF Generation

- `TransactionRequestService` uses `PdfService` to generate cost request PDFs
- PDFs include: payment details, amounts, due date, **structured communication** (Belgian payment reference), **QR code** for easy payment
- Reminder PDFs generated asynchronously via BullMQ queue

---

## Reading Order (Recommended)

### Phase 1 — Data Model

1. `entities/transaction.entity.ts` — Core entity, all columns and relations
2. `entities/transaction-line.entity.ts` — Line items
3. `constants/transaction-types.ts` — All type and status enums
4. `entities/transaction-forward.entity.ts` — Forward model
5. `entities/transaction-reminder.entity.ts` + `transaction-reminder-item.entity.ts`
6. `entities/transaction-attachment.entity.ts`

### Phase 2 — CRUD & Business Logic

7. `transaction.service.ts` — Main service (list, detail, delete)
8. `services/transaction-update.service.ts` — Update logic
9. `dto/create-transaction.dto.ts` + `update-transaction.dto.ts` — Validation rules
10. `dto/query-transactions.dto.ts` — Filtering/sorting options
11. `controllers/transaction.controller.ts` — API layer

### Phase 3 — Integrations

12. `services/transaction-accounting-journal.service.ts` — Accounting entries
13. `services/transaction-forward.service.ts` — Forward logic
14. `use-cases/forward-transaction.use-case.ts` — Forward orchestration
15. `services/transaction-request.service.ts` — PDF generation
16. `services/transaction-reminder.service.ts` — Reminder creation
17. `consumers/transaction-reminder.consumer.ts` — BullMQ consumer

### Phase 4 — Supporting Features

18. `services/transaction-timeline.service.ts` — Activity timeline
19. `services/transaction-attachment.service.ts` — File attachments
20. `subscribers/transaction.subscriber.ts` — TypeORM lifecycle hooks
21. `listeners/transaction-forward.listener.ts` — Event handlers
22. `events/` — Domain events

---

## Key Gotchas

- **Money = bigint (cents)**: All amounts stored in cents. Use `Decimal.js` for calculations, never floating point
- **Multi-tenant**: Every query MUST be scoped by `workspaceId`
- **Soft deletes**: `deletedAt` column — TypeORM auto-filters in repository methods. Only add `deleted_at IS NULL` in raw SQL subqueries
- **Structured communication**: Belgian-specific payment reference format (+++XXX/XXXX/XXXXX+++) used for automatic bank reconciliation
- **Correction, not mutation**: When transaction amounts change, the accounting journal adds correction lines rather than editing existing ones
- **Two detail views on frontend**: Building context uses a floating sheet, global context uses a full page — same data, different UX
- **Transaction ≠ bank transaction**: In this codebase, "Transaction" means payment request. Bank transactions are called "Payment" (from the `payment` / `payment-matching` modules)
- **Engines create, humans manage**: Most payment requests are auto-generated by rent/provision engines. Users primarily view, send reminders, match payments, and forward
- **Direction matters**: RECEIVABLE = workspace collects from contact. PAYABLE = workspace pays to contact (refunds)
