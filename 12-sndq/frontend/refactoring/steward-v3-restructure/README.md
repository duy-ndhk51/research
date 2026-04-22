# Steward Purchase Invoice Form — V3 Restructure

## Goal

Restructure the steward purchase invoice form from a monolithic "God Component" (630 LOC) to the modular composition pattern used by the syndic V3 form. The logic stays tightly coupled with the V2-steward data model; only the component architecture changes.

## Source & Target

| Aspect | Current (V2 Steward) | Target (V3 pattern) |
|---|---|---|
| Main component | `PurchaseInvoiceFormV2Steward.tsx` (630 LOC) | Thin orchestrator (~200 LOC) |
| State management | `useState` + `useRef` | `useReducer` + Context |
| Form logic | Inline in component | `usePurchaseInvoiceForm` hook |
| UI sections | Inline JSX | `FormHeader`, `FormBody`, `FormDialogs` |
| Sheet/dialog state | Individual `useState` flags | `useSheetState` reducer |
| Type definitions | Scattered | Dedicated `types.ts` |

## Phase Plan

### Phase 1 — Safety-net tests (DONE)

Add unit tests for schema validation, API data converter, and default values to pin current behavior before any code moves. See [pre-refactor-test-coverage.md](./pre-refactor-test-coverage.md) for details.

### Phase 2 — Extract hooks

- `usePurchaseInvoiceForm.ts` — form setup, mutations, submit/draft/error handlers, Peppol callback
- `useSheetState.ts` — reducer for preview, supplier detail, discard, delete, merge dialogs

### Phase 3 — Extract sections

- `FormHeader.tsx` — title, mode toggle, action buttons, duplicate warning
- `FormBody.tsx` — section cards (Info, Amounts, Payment, Other)
- `FormDialogs.tsx` — discard, delete, merge confirmation dialogs

### Phase 4 — Wire context

- `PurchaseInvoiceFormContext.tsx` — provides form state, actions, and sheet state to all sections
- Replace prop drilling with `usePurchaseInvoiceFormContext()` in child components
- Slim down the main component to a thin provider + layout shell

## Reference Architecture

The syndic V3 form at `purchase-invoice-v3/` is the reference implementation:

```
purchase-invoice-v3/
├── PurchaseInvoiceFormV3.tsx    # thin orchestrator
├── types.ts                     # InvoiceFormMode, props
├── contexts/
│   └── PurchaseInvoiceFormContext.tsx
├── hooks/
│   ├── usePurchaseInvoiceForm.ts
│   └── useSheetState.ts
└── sections/
    ├── FormBody.tsx
    ├── FormDialogs.tsx
    └── FormHeader.tsx
```

## Key Differences from Syndic V3

The steward form differs from the syndic form in several ways that must be preserved:

- **Multi-property selection**: `propertyIds[]` instead of single `buildingId`
- **Selection mode**: toggle between `building` and `units`
- **Cost categories**: amounts require `costCategoryId` (no `motherId`)
- **Settlement data**: per-unit `ownerSplit`/`tenantSplit`/`splitClearing`
- **Distribution to API**: `ownerSplit / 100` conversion for `distribution` field

## Previous Analysis

Initial comparison and approach analysis was conducted in a prior conversation. Recommended approach: "Steward V3" — new component mirroring V3 structure, delegating to V2-steward schema and utils.
