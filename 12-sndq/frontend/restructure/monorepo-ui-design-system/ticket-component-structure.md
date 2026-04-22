# Component Structure for @sndq/ui-v2 — Ticket Summary

**Created**: 2026-04-17
**Detail**: [Full architecture](./README.md) | [Monorepo ticket](./ticket.md)

---

## Three-Tier Model

| Tier | Location | Rule |
|------|----------|------|
| **Primitives** | `@sndq/ui-v2/components` | Well-known UI atoms (found on Radix/shadcn/MUI) — zero business logic |
| **Blocks** | `@sndq/ui-v2/blocks` | Compositions of primitives — no APIs, hooks, or translations |
| **Business** | `sndq-fe/src/components` | Logic-bound — calls hooks, services, translations, app context |

## Primitives (`@sndq/ui-v2/components`)

General-purpose building blocks. Each component is self-contained, fully controlled via props, and has no dependency on any app-specific code.

Examples: Button, Input, Dialog, Table, Select, Tabs, Badge, Card, Avatar, Toast, Chart, etc.

New components will be added here as the design system evolves.

## Blocks (`@sndq/ui-v2/blocks`)

Reusable compositions that combine primitives into opinionated layouts. No business logic — no APIs, hooks, or translations. Any app can use them.

**Example: DetailHeader block**

Currently `briicks/navigation/Header.tsx` — used in 70+ module pages (BuildingDetailHeader, LeaseDetailHeader, ContactDetailHeader, CaseHeader, TaskHeader, etc.). It composes back button + title + caption + tags + action buttons + tabs into a single reusable layout. The component itself has zero business logic — each module page wraps it with its own data fetching and translations.

```
DetailHeader (block — in @sndq/ui-v2)       BuildingDetailHeader (business — in sndq-fe)
┌──────────────────────────────────┐     ┌──────────────────────────────────────────┐
│ ← Back  Title  Caption  [Actions]│     │ Uses useTranslations(), useWorkspaceType()│
│ Tab1 | Tab2 | Tab3               │     │ Fetches building data, formats address    │
└──────────────────────────────────┘     │ Passes props → DetailHeader              │
                                         └──────────────────────────────────────────┘
```

This same split applies to other blocks: ConfirmDialog, KpiCard, FormShell, etc. The block handles layout, the business component handles data and logic.

## Business Components (stays in each app)

Domain-specific components that fetch data, use translations, and depend on app context. They compose primitives and blocks with real business logic. These cannot go into `@sndq/ui-v2`.

**Example: ContactHoverCard**

Lazy-fetches a contact via `useContactV2(contactId)` on hover, formats the address with locale, displays domain-specific labels (`SUPPLIER_TYPE_LABELS`), and navigates to the contact detail page. Used across financial, patrimony, bookkeeping, broadcasts, and contact-book modules.

**Example: BuildingHoverCard**

Same pattern — calls `useBuildingV2(buildingId)`, formats building address, navigates to building detail. Used across peppol, activity, financial, certificates, and home modules.

Both depend on app hooks, routing, translations, and entity types — exactly the kind of code that must stay in `sndq-fe/src/components/`.

## Import Flow

Imports only flow downward:

```
@sndq/ui-v2/components   ← no imports from blocks or apps
       ↑
@sndq/ui-v2/blocks       ← imports only from components
       ↑
sndq-fe/src/components ← imports from components + blocks
       ↑
sndq-fe/src/modules    ← imports from all above
```
