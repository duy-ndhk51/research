# AccountingLedgerSelectV2 → BuildingLedgerSelect: API Compatibility Report

Investigation report for all remaining `AccountingLedgerSelectV2` usages. Covers backend API support for `ledgerId` vs `motherId`, and `buildingId` availability for each consumer component.

**Created**: 2026-05-16
**Related files**:
- [building-ledger-select-fallback-execution.md](./building-ledger-select-fallback-execution.md) — Fallback logic + v2/v3 form migration
- [building-ledger-select-remaining-execution.md](./building-ledger-select-remaining-execution.md) — Remaining migration execution plan

---

## Table of Contents

1. [Context](#1-context)
2. [Component-by-Component Analysis](#2-component-by-component-analysis)
3. [Summary Table](#3-summary-table)
4. [Key Findings](#4-key-findings)
5. [Recommended BE Feature Requests](#5-recommended-be-feature-requests)
6. [buildingId Threading Guide](#6-buildingid-threading-guide)

---

## 1. Context

### Problem

`BuildingLedgerSelect` requires a `buildingId` prop and returns options that can be either a `motherId` or a `ledgerId` (determined by `CostAccountType`). When migrating from `AccountingLedgerSelectV2`, two questions arise per consumer:

1. **Does the backend API accept `ledgerId`?** If the API only accepts `motherId` (or `accountingMotherId`), sending a `ledgerId` from `BuildingLedgerSelect` will fail or be silently ignored.
2. **Is `buildingId` available?** `BuildingLedgerSelect` requires it to fetch building-scoped ledger options. If not in props, it must be threaded from a parent.

### Scope

This report covers **all 7 components** that consume `AccountingLedgerSelectV2` (excluding the definition file itself and the already-migrated purchase invoice v2/v3 form components from the [fallback execution](./building-ledger-select-fallback-execution.md)).

---

## 2. Component-by-Component Analysis

### 2.1 AddBuildingSupplierSheet

> Status: NOT migrated — BLOCKED on BE (`LinkBuildingSupplierDto` does not support `ledgerId`)

| Field | Value |
|-------|-------|
| **File** | `sndq-fe/src/modules/financial/components/suppliers/AddBuildingSupplierSheet.tsx` |
| **API endpoint** | `POST /buildings/{buildingId}/suppliers` |
| **Backend DTO** | `LinkBuildingSupplierDto` |
| **Field submitted** | `accountingMotherId` (UUID, optional) |
| **Supports ledgerId?** | NO |
| **buildingId available?** | YES (required prop) |
| **BE change needed?** | YES |

**Details**: The `LinkBuildingSupplierDto` only has `accountingMotherId?: string`. There is no `ledgerId` field. The frontend currently stores `mother?.id` into `accountingMotherId`, which works when the user selects a mother-type option but will break if a ledger-type option is selected (the id would be a ledgerId but submitted as `accountingMotherId`).

**Backend DTO** (`sndq-be/src/modules/building/dto/link-building-supplier.dto.ts`):
```typescript
@IsOptional()
@IsUUID()
accountingMotherId?: string | null;
```

**Update DTO** (`sndq-be/src/modules/building/dto/update-building-supplier.dto.ts`) has the same field.

---

### 2.2 SupplierFloatingSheetContent (Opening Data Setup)

| Field | Value |
|-------|-------|
| **File** | `sndq-fe/src/modules/financial/forms/opening-data-setup/sheets/SupplierFloatingSheetContent.tsx` |
| **API endpoint** | `PATCH /opening-data-setup/buildings/{buildingId}` (draft save) |
| **Backend DTO** | `OpeningDataSetupSupplierInvoiceEntryDto` |
| **Field submitted** | `accountingMotherId` (UUID, required) |
| **Supports ledgerId?** | NO |
| **buildingId available?** | YES (required `string` prop from `SuppliersTab`) |
| **BE change needed?** | YES |

**Details**: The form schema uses `accountingMotherId: z.string().min(1)`. The backend DTO only accepts `accountingMotherId: string` (required UUID). No `ledgerId` field exists.

**Backend DTO** (`sndq-be/src/modules/opening-data-setup/dto/opening-data-setup-payload.dto.ts`):
```typescript
@ApiProperty({ description: 'Accounting mother ID (isLedger mother) for allocation ledger' })
@IsUUID()
accountingMotherId: string;
```

**Submission flow**: Sheet save -> parent `SuppliersTab.handleSaveInvoiceEntry` -> form state update -> `OpeningDataSetupForm.handleSaveDraft` -> `PATCH /opening-data-setup/buildings/{buildingId}` with full payload including `suppliers[].financial.invoiceEntries[].accountingMotherId`.

---

### 2.3 AmountsAllocationSection (Peppol Invoice Form)

| Field | Value |
|-------|-------|
| **File** | `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/AmountsAllocationSection.tsx` |
| **API endpoint** | `POST /purchase-invoices` (via `convertFormDataV2ToApiData`) |
| **Backend DTO** | `CreatePurchaseInvoiceData` -> `allocationCosts[]` |
| **Field submitted** | Both `motherId` and `ledgerId` (via `costAccount.type` discriminator) |
| **Supports ledgerId?** | YES |
| **buildingId available?** | YES (prop `buildingId: string \| null \| undefined`) |
| **BE change needed?** | NO |

**Details**: The `POST /purchase-invoices` endpoint accepts `allocationCosts[].motherId` and `allocationCosts[].ledgerId` as optional fields. The `convertFormDataV2ToApiData` mapper reads `costAccount.type` to decide which field to populate.

**FE caveat**: The `onChange` handlers in parent `PurchaseInvoiceFormFloatingSheetContent` currently set flat `motherId`/`motherName`/`motherCode`/`parentMotherName` fields on each amount, NOT the `costAccount` object. The mapper (`convertFormDataV2ToApiData`) reads `costAccount`, not those flat fields. This means the flat fields written by the Peppol form handlers are ignored during API submission — they need to be aligned to write `costAccount` instead, or the mapper needs to fall back to flat fields.

---

### 2.4 EditLedgerSheet (Invoice Detail Page)

| Field | Value |
|-------|-------|
| **File** | `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail/components/EditLedgerSheet.tsx` |
| **API endpoint** | `PATCH /purchase-invoices/{invoiceId}/allocations` (via `useUpdateAllocationCostLedger`) |
| **Backend DTO** | `PatchAllocationCostDto` (picks `ledgerId`, `motherId`, `costCategoryId` from `CreateAllocationCostDto`) |
| **Field submitted** | `motherId` only (hard-coded in `handleSave`) |
| **Supports ledgerId?** | YES |
| **buildingId available?** | NO (not in props) |
| **BE change needed?** | NO |

**Details**: The backend `PatchAllocationCostDto` supports both `ledgerId` and `motherId`. When `motherId` is sent and the invoice has a `buildingId`, the backend resolves/creates a ledger via `accountingLedgerService.createLedgerForMotherIsLedger`. When `ledgerId` is sent, it's assigned directly.

The frontend currently hard-codes `motherId: selectedLedger` in the save handler:
```typescript
const data: UpdateAllocationCostLedgerData = {
  allocationCostId: allocationCost.id,
  purchaseInvoiceId: allocationCost.purchaseInvoiceId,
  motherId: selectedLedger, // always motherId, never ledgerId
};
```

**buildingId source**: Parent `PurchaseInvoiceCostAllocation` receives `buildingId={invoice?.buildingId || buildingId}` but does NOT pass it to `EditLedgerSheet`.

---

### 2.5 EditLedgerFloatingSheetContent (Invoice Detail Floating Sheet)

| Field | Value |
|-------|-------|
| **File** | `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/EditLedgerFloatingSheetContent.tsx` |
| **API endpoint** | `PATCH /purchase-invoices/{invoiceId}/allocations` (via `useUpdateAllocationCostLedger`) |
| **Backend DTO** | `PatchAllocationCostDto` |
| **Field submitted** | `motherId` only |
| **Supports ledgerId?** | YES |
| **buildingId available?** | NO (not in props) |
| **BE change needed?** | NO |

**Details**: Same API and DTO as EditLedgerSheet (section 2.4). Same hard-coded `motherId` pattern.

**buildingId source**: Parent `PurchaseInvoiceDetailFloatingSheetContent` has `invoice.buildingId` (used for `EditDistributionFloatingSheetContent` but not passed to this component). Similarly, `PurchaseInvoicePreviewFloatingSheetContent` has the same access.

---

### 2.6 CostSelector (Allocation Costs Section in Detail Floating Sheet)

| Field | Value |
|-------|-------|
| **File** | `sndq-fe/src/modules/financial/components/invoices/purchase-invoice/detail-sheet/allocation-costs/CostSelector.tsx` |
| **API endpoint** | `PUT /purchase-invoices/{invoiceId}/allocations` (via `useUpdateAllocations` on save) |
| **Backend DTO** | `UpdateAllocationsData` -> `allocationCosts[]` |
| **Field submitted** | Both `motherId` and `ledgerId` (via `costAccount.type` in `useAllocationCostsForm`) |
| **Supports ledgerId?** | YES |
| **buildingId available?** | NO on `CostSelector`, YES on parent `AllocationCostsSection` |
| **BE change needed?** | NO |

**Details**: The save path in `useAllocationCostsForm` already maps `costAccount.type` to the correct field:
```typescript
motherId: amount.costAccount?.type === CostAccountType.LEDGER ? undefined : amount.costAccount?.id,
ledgerId: amount.costAccount?.type === CostAccountType.LEDGER ? amount.costAccount?.id : undefined,
```

**buildingId source**: `AllocationCostsSection` already has `buildingId` as a prop (used for `DistributionKeySelect`). It just needs to pass it down to `CostSelector`.

---

### 2.7 SupplierInvoiceSheet (Fiscal Year Setup Wizard)

| Field | Value |
|-------|-------|
| **File** | `sndq-fe/src/modules/financial/forms/fiscal-year-setup/components/SupplierInvoiceSheet.tsx` |
| **API endpoint** | `POST /buildings/{buildingId}/financial/setup` |
| **Backend DTO** | `SetupPurchaseInvoiceDto` |
| **Field submitted** | `motherId` only (from `utils.ts` transformer) |
| **Supports ledgerId?** | YES |
| **buildingId available?** | NO (not in props or parent `SupplierStep`) |
| **BE change needed?** | NO |

**Details**: The `SetupPurchaseInvoiceDto` already supports both fields with cross-validation:
```typescript
@IsUUID()
@RequiredIf((o: SetupPurchaseInvoiceDto) => o.motherId === undefined)
ledgerId?: string;

@IsUUID()
@RequiredIf((o: SetupPurchaseInvoiceDto) => o.ledgerId === undefined)
motherId?: string;
```

When `motherId` is sent, the backend resolves it via `createLedgerForMotherIsLedger`.

The frontend `transformFormDataToDto` only sends `motherId`:
```typescript
motherId: invoice.motherId || undefined,
```

**buildingId source**: `FiscalYearSetupForm` has `buildingId` as a required prop (from route params). It needs to be threaded through: `FiscalYearSetupForm` -> `SupplierStep` -> `SupplierInvoiceSheet` (2 levels).

---

## 3. Summary Table

| # | Component | API Endpoint | Supports ledgerId? | buildingId available? | BE change needed? |
|---|-----------|-------------|--------------------|-----------------------|-------------------|
| 1 | AddBuildingSupplierSheet | `POST /buildings/:id/suppliers` | NO | YES | YES |
| 2 | SupplierFloatingSheetContent | `PATCH /opening-data-setup/buildings/:id` | NO | YES | YES |
| 3 | AmountsAllocationSection | `POST /purchase-invoices` | YES | YES | NO |
| 4 | EditLedgerSheet | `PATCH /purchase-invoices/:id/allocations` | YES | NO (thread from parent) | NO |
| 5 | EditLedgerFloatingSheetContent | `PATCH /purchase-invoices/:id/allocations` | YES | NO (thread from parent) | NO |
| 6 | CostSelector | `PUT /purchase-invoices/:id/allocations` | YES | NO (thread from parent) | NO |
| 7 | SupplierInvoiceSheet | `POST /buildings/:id/financial/setup` | YES | NO (thread 2 levels) | NO |

---

## 4. Key Findings

### API Support

- **2 APIs need BE changes** to support `ledgerId`:
  - `LinkBuildingSupplierDto` (`POST /buildings/:id/suppliers`)
  - `OpeningDataSetupSupplierInvoiceEntryDto` (`PATCH /opening-data-setup/buildings/:id`)
- **5 APIs already support both** `motherId` and `ledgerId`

### buildingId Availability

- **3 components already have `buildingId`**: AddBuildingSupplierSheet, SupplierFloatingSheetContent, AmountsAllocationSection
- **3 components need 1 level of prop threading**: EditLedgerSheet, EditLedgerFloatingSheetContent, CostSelector
- **1 component needs 2 levels of prop threading**: SupplierInvoiceSheet (grandparent -> parent -> component)

### Migration Blocking Dependencies

Components 1 and 2 are **blocked on BE changes** — cannot fully migrate to `BuildingLedgerSelect` until the APIs support `ledgerId`. Components 3-7 can proceed with **FE-only changes**.

---

## 5. Recommended BE Feature Requests

### Request 1: `LinkBuildingSupplierDto` — Add `ledgerId` support

**Endpoint**: `POST /buildings/:buildingId/suppliers` and `PATCH /buildings/:buildingId/suppliers/:supplierId`

**DTOs to update**:
- `sndq-be/src/modules/building/dto/link-building-supplier.dto.ts`
- `sndq-be/src/modules/building/dto/update-building-supplier.dto.ts`

**Change**: Add optional `ledgerId?: string` field. Use `RequiredIf` or either/or validation:
- If `ledgerId` is provided, store it directly as the default ledger
- If `accountingMotherId` is provided, resolve the ledger via `createLedgerForMotherIsLedger` (existing behavior)
- At most one of the two should be provided

**Reference pattern**: `SetupPurchaseInvoiceDto` (`sndq-be/src/modules/building/dto/setup-building-financial.dto.ts`) already implements this exact pattern.

### Request 2: `OpeningDataSetupSupplierInvoiceEntryDto` — Add `ledgerId` support

**Endpoint**: `PATCH /opening-data-setup/buildings/:id`

**DTO to update**:
- `sndq-be/src/modules/opening-data-setup/dto/opening-data-setup-payload.dto.ts` (class `OpeningDataSetupSupplierInvoiceEntryDto`)

**Change**: Add optional `ledgerId?: string` field with `RequiredIf` cross-validation (exactly one of `accountingMotherId` or `ledgerId` must be provided).

**Service change**: Update the opening data setup confirm flow to handle `ledgerId` directly when provided, or resolve from `accountingMotherId` via `createLedgerForMotherIsLedger` (existing behavior).

**Reference pattern**: Same as `SetupPurchaseInvoiceDto`.

---

## 6. buildingId Threading Guide

For components where `buildingId` is not directly available, here is the source and threading path:

### EditLedgerSheet (1 level)

```
PurchaseInvoiceDetail (has invoice?.buildingId || buildingId)
  └── PurchaseInvoiceCostAllocation (receives buildingId)
        └── EditLedgerSheet ← ADD buildingId prop
```

### EditLedgerFloatingSheetContent (1 level)

```
PurchaseInvoiceDetailFloatingSheetContent (has invoice.buildingId)
  └── EditLedgerFloatingSheetContent ← ADD buildingId prop

PurchaseInvoicePreviewFloatingSheetContent (has invoice.buildingId)
  └── EditLedgerFloatingSheetContent ← ADD buildingId prop
```

### CostSelector (1 level)

```
AllocationCostsSection (already has buildingId prop)
  └── CostSelector ← ADD buildingId prop
```

### SupplierInvoiceSheet (2 levels)

```
FiscalYearSetupForm (has buildingId as required prop)
  └── SupplierStep ← ADD buildingId prop
        └── SupplierInvoiceSheet ← ADD buildingId prop
```
