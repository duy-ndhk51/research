# Component Lifting Process

**Created**: 2026-04-17
**Status**: Active process
**Related**: [Component structure ticket](./ticket-component-structure.md) | [Monorepo architecture](./README.md) | [Lifting ticket](./ticket-component-lifting.md)

---

## Table of Contents

1. [Promotion Ladder](#1-promotion-ladder)
2. [Tier Definitions](#2-tier-definitions)
3. [The App-World vs Package-World Boundary](#3-the-app-world-vs-package-world-boundary)
4. [Signals for Lifting](#4-signals-for-lifting)
5. [Day-to-Day Process](#5-day-to-day-process)
6. [Detection Script](#6-detection-script)
7. [Wave-Based Rollout](#7-wave-based-rollout)
8. [Current Inventory Snapshot](#8-current-inventory-snapshot)

---

## 1. Promotion Ladder

Components promote through 4 tiers. Each promotion happens only when a component crosses a scope boundary.

```
Local → Shared → Blocks → Primitives
```

| Tier | Location | Rule |
|------|----------|------|
| **Local** | `modules/{mod}/**/components/` | Used within one module |
| **Shared** | `sndq-fe/src/components/` | Used by 2+ modules (business logic allowed) |
| **Blocks** | `@sndq/ui/blocks` | Props-only compositions, zero business logic |
| **Primitives** | `@sndq/ui/components` | Single-element well-known atoms |

### Promotion triggers

| Transition | Trigger | Effort |
|-----------|---------|--------|
| Local → Shared | Another module needs the component | File move |
| Shared → Blocks | Component can be stripped of all business logic and made props-only | Refactoring |
| Blocks → Primitives | Component reduces to a single semantic element matching a well-known global name (Button, Dialog, Table, etc.) | File move |

### Folder depth detail (for reference)

The "Local" tier encompasses three natural folder depths inside a module. Developers move components between these levels organically — no formal process needed.

| Sub-level | Folder pattern | Scope | Count |
|-----------|---------------|-------|-------|
| Screen | `modules/{mod}/{feat}/{view}/components/` | Single page/view | ~40 dirs |
| Feature | `modules/{mod}/{feat}/components/` | All views in one feature | ~20 dirs |
| Module | `modules/{mod}/components/` | All features in one module | ~22 dirs |

Moving a component from `lease-detail/components/` up to `patrimony/components/` is just a refactor within the Local tier — it stays inside the same module and requires no lift decision.

---

## 2. Tier Definitions

### Local (`modules/{mod}/**/components/`)

All components scoped to a single module. Developers organize them at whatever depth makes sense — screen-level, feature-level, or module-level — without a formal process.

**Real examples from sndq-fe**:

- **Screen-level** — `modules/patrimony/leases/lease-detail/components/` — `DeleteLeaseDialog`, `LeaseDetailHeader`, `TerminateLeaseSheet`
- **Screen-level** — `modules/patrimony/buildings/building-detail/components/` — `DeleteBuildingDialog`, `Header`, `DistributionKeyFormSheet`
- **Feature-level** — `modules/patrimony/leases/components/` — indexation letter used by both lease table and lease detail
- **Feature-level** — `modules/activity/tasks/components/` — `ActivityTaskMetrics` shared across task views
- **Module-level** — `modules/activity/components/` — `ActivityOverview`, `BaseActivityTableV2`, `ActivitySort`, `UpdateStatusSheet`, chat components — used by tasks, cases, and notifications features
- **Module-level** — `modules/patrimony/components/common/` — `PatrimonyHeader`, `PatrimonyFilter` — used by buildings, leases, meters, facilities, meeting features
- **Module-level** — `modules/financial/components/` — dashboard, chart-of-accounts, invoices, payouts — the largest module-level component set

**Total**: ~82 directories across all depths.

### Shared (`sndq-fe/src/components/`)

Components imported by multiple modules. Business logic is allowed — they live inside the app.

**Folder**: `sndq-fe/src/components/`

**Real examples (65+ items)**:

- `briicks/` — 55 Briicks wrapper components (button, input, select, navigation, text, etc.)
- `ui/` — 35 shadcn/ui primitives (dialog, table, badge, sheet, tabs, etc.)
- `common-table/` — `CommonTable` used by 20+ modules
- `common-sheet/` — `CommonSheet` used by 15+ modules
- `action-button/` — `ActionButton` used by 15+ modules
- `filter/` — `CommonFilterBar` used by 10+ modules
- `form/` — `FormField`, `FormLayout` used by 10+ modules
- `contact/` — `ContactHoverCard`, `ContactSelect` — business components with hooks
- `building/` — `BuildingHoverCard`, `BuildingOwnersHoverCard` — business components with hooks

### Blocks (`@sndq/ui/blocks`)

Reusable compositions of primitives. Zero business logic — no API calls, no hooks, no translations, no routing. Any app can use them.

**Folder**: `packages/ui/src/blocks/`

**Examples** (target state): `DetailHeader`, `PageHeader`, `KpiCard`, `ConfirmDialog`, `FormShell`, `CommonTable` (after stripping hooks), `CommonSheet` (after stripping hooks)

### Primitives (`@sndq/ui/components`)

Single-element, well-known UI atoms. Found on Radix/shadcn/Material UI. Fully controlled via props.

**Folder**: `packages/ui/src/components/`

**Examples**: Button, Input, Dialog, Table, Select, Tabs, Badge, Card, Avatar, Toast, Chart, Checkbox, Switch, Slider, etc.

---

## 3. The App-World vs Package-World Boundary

The most important boundary in the ladder is between **Shared** and **Blocks**.

```
┌─────────────────────────────────────────────────────┐
│  APP WORLD (Local + Shared)                         │
│  Business logic allowed:                            │
│  - useTranslations(), useRouter()                   │
│  - useContactV2(), useBuildingV2()                  │
│  - API calls, services, contexts                    │
│  - next-intl, app-specific routing                  │
│                                                     │
│  Imports flow: Local ← Shared                       │
└─────────────────────────┬───────────────────────────┘
                          │
              LIFTING BOUNDARY (requires refactoring)
              Strip ALL business dependencies:
              - Remove hook calls → accept data via props
              - Remove translations → accept strings via props
              - Remove routing → accept callbacks via props
              - Remove services → accept handlers via props
                          │
┌─────────────────────────┴───────────────────────────┐
│  PACKAGE WORLD (Blocks + Primitives)                │
│  Zero business logic:                               │
│  - Props-only API                                   │
│  - No imports from @/hooks, @/services, @/contexts  │
│  - No next-intl, no app routing                     │
│                                                     │
│  Imports flow: Blocks ← Primitives                  │
└─────────────────────────────────────────────────────┘
```

**Crossing this boundary is a refactoring, not just a file move.** This is why lifting to Blocks/Primitives requires a proposal and review, while Local → Shared is a simple file move.

### Refactoring pattern: inversion of control

When lifting a component from Shared to Blocks, the pattern is always the same — invert control from "component fetches its own data" to "parent passes data as props":

```tsx
// BEFORE (in Shared tier — has business logic)
function ContactCard({ contactId }: { contactId: string }) {
  const contact = useContactV2(contactId);      // hook = business logic
  const t = useTranslations('contact');          // translation = business logic
  const router = useRouter();                    // routing = business logic
  return (
    <Card onClick={() => router.push(`/contacts/${contactId}`)}>
      <Avatar src={contact.avatar} />
      <Heading>{contact.name}</Heading>
      <Caption>{t('supplier')}</Caption>
    </Card>
  );
}

// AFTER (in Blocks tier — props only)
function EntityCard({ avatar, title, caption, onClick }: EntityCardProps) {
  return (
    <Card onClick={onClick}>
      <Avatar src={avatar} />
      <Heading>{title}</Heading>
      <Caption>{caption}</Caption>
    </Card>
  );
}

// Shared-tier wrapper stays in sndq-fe
function ContactCard({ contactId }: { contactId: string }) {
  const contact = useContactV2(contactId);
  const t = useTranslations('contact');
  const router = useRouter();
  return (
    <EntityCard
      avatar={contact.avatar}
      title={contact.name}
      caption={t('supplier')}
      onClick={() => router.push(`/contacts/${contactId}`)}
    />
  );
}
```

---

## 4. Signals for Lifting

Three signals indicate a component should be promoted to a higher tier.

### Signal 1: Cross-boundary import already exists (highest confidence)

A component in one scope is imported by code in another scope. This is detectable by grep and the detection script.

**Examples found in current codebase**:

- `broadcasts/components/` is imported by patrimony, financial, peppol, contact-book, home, meeting (7+ modules)
- `financial/components/dashboard/DashboardSectionLayout` is imported by activity, home, prototype (3+ modules)
- `patrimony/components/common/PatrimonyHeader` is imported by passport (cross-module)

**Action**: Run `detect-cross-imports.sh` monthly to find these.

### Signal 2: Copy-paste detected (medium confidence)

A developer copies a component from one module to another instead of importing it. Caught during PR review when a reviewer recognizes duplicated patterns.

**Action**: During review, comment "This looks like a copy of `{module}/components/{X}` — consider lifting instead."

### Signal 3: Developer requests it during a PR (organic)

"I need `DashboardSectionLayout` in my module" — the developer reaches for a component that lives in another scope.

**Action**: Decide in the PR: lift now (if straightforward) or mark with `TODO(lift)` for the next sprint.

---

## 5. Day-to-Day Process

### PR convention: `TODO(lift)` comments

When a developer imports a component across a scope boundary, they add a comment at the import site:

```tsx
// TODO(lift): cross-module import, candidate for blocks
import { DashboardSectionLayout } from '@/modules/financial/components/dashboard/components/sections/DashboardSectionLayout';
```

These comments are searchable:

```bash
grep -r "TODO(lift)" sndq-fe/src/modules/ --include="*.tsx" --include="*.ts"
```

### Review checklist addition

Add to the PR review checklist:

- [ ] No new cross-module component imports without `TODO(lift)` comment
- [ ] No copy-paste of components from other modules

### Sprint cadence

```
Daily:    PR adds cross-module import? → add TODO(lift) comment
Monthly:  Run detect-cross-imports.sh → review candidates in 15 min standup
Sprint:   Pick 2-3 candidates → lift in focused PRs
```

---

## 6. Detection Script

The `detect-cross-imports.sh` script automates signal detection. It lives alongside this document.

### What it reports

1. **Shared Component Usage** — which `src/components/` folders are most imported by modules (candidates for blocks/primitives)
2. **Cross-Module Imports** — which modules import `components/` from other modules (boundary violations)
3. **Pending Lift TODOs** — all `TODO(lift)` comments in the codebase

### How to run

```bash
# From monorepo root (defaults to sndq-fe/src)
bash detect-cross-imports.sh

# Or specify the src directory
bash detect-cross-imports.sh /path/to/src
```

### When to run

- **Before sprint planning**: Generates the candidate list for the sprint's lift PRs
- **After major feature work**: New features often introduce cross-boundary imports
- **Monthly at minimum**: Catches gradual drift

---

## 7. Wave-Based Rollout

The initial migration from the current flat structure to the tiered model follows a wave plan. Each wave is independent and can be done in separate sprints.

### Wave 1: Blocks candidates (already in `src/components/`, used cross-module, no business logic)

Move these from `sndq-fe/src/components/` to `@sndq/ui/blocks` after stripping any remaining business dependencies:

| Component | Current path | Import count | Action |
|-----------|-------------|--------------|--------|
| Header (DetailHeader) | `briicks/navigation/Header.tsx` | 70+ pages | Lift to blocks, rename to DetailHeader |
| CommonTable | `common-table/` | 20+ modules | Lift to blocks (strip hook coupling) |
| CommonSheet | `common-sheet/` | 15+ modules | Lift to blocks (strip hook coupling) |
| ActionButton | `action-button/` | 15+ modules | Lift to blocks |
| CommonFilterBar | `filter/common-filter-bar/` | 10+ modules | Lift to blocks |
| FormField + FormLayout | `form/` | 10+ modules | Lift to blocks |

### Wave 2: Primitives (already in `src/components/ui/` and `briicks/`, single-element)

Move these from `sndq-fe/src/components/` to `@sndq/ui/components`:

| Component | Current path | Target |
|-----------|-------------|--------|
| All shadcn/ui components | `ui/*.tsx` (35 files) | `@sndq/ui/components` |
| Briicks button, input, select, etc. | `briicks/button/`, `briicks/input/`, etc. | `@sndq/ui/components` (replace shadcn equivalents) |
| Briicks text (Heading, Caption, Paragraph) | `briicks/text/` | `@sndq/ui/components` |
| Icon | `icons/` | `@sndq/ui/components` |

### Wave 3: Cross-module boundary fixes (imports from other modules' `components/`)

These are components inside one module that other modules already import. First move to Shared tier, then evaluate for blocks:

| Component | Source module | Consuming modules | Action |
|-----------|-------------|-------------------|--------|
| `broadcasts/components/*` | broadcasts | patrimony, financial, peppol, contact-book, home, meeting | Move to `src/components/broadcasts/` first |
| `financial/components/dashboard/DashboardSectionLayout` | financial | activity, home, prototype | Move to `src/components/` or evaluate for blocks |
| `patrimony/components/common/PatrimonyHeader` | patrimony | passport | Evaluate: rename + move to `src/components/` |
| `financial/components/invoices/PurchaseInvoiceStatusBadge` | financial | contact-book | Move to `src/components/financial/` |
| `bookkeeping/components/tree-item/TreeFront` | bookkeeping | bookkeeping/accounts | Internal to module — no action needed |

### Wave 4: Business components (stay in Shared tier)

These are already in `src/components/` but contain hooks, translations, and domain logic. They stay:

| Component | Why it stays |
|-----------|-------------|
| `contact/ContactHoverCard` | Uses `useContactV2()`, locale formatting, domain labels, routing |
| `building/BuildingHoverCard` | Uses `useBuildingV2()`, address formatting, routing |
| `building/BuildingOwnersHoverCard` | Uses building hooks, renders owner list with domain logic |
| `property/PropertyHoverCard` | Uses domain hooks |
| `financial/*` | Uses financial-specific hooks and services |
| `payment-request-hover-card/` | Uses payment domain hooks |

---

## 8. Current Inventory Snapshot

Data gathered 2026-04-17 by scanning `sndq-fe/src/`.

### Component directory distribution

| Tier | Location | Count |
|------|----------|-------|
| Shared | `src/components/` | 65+ items |
| Local (module-level) | `modules/{mod}/components/` | 22 dirs |
| Local (feature-level) | `modules/{mod}/{feat}/components/` | 20 dirs |
| Local (screen-level) | `modules/{mod}/{feat}/{view}/components/` | 40+ dirs |

### Top-level modules (32 modules)

accounts, activity, ai-agent, app-library, billing-history, bookkeeping, broadcasts, certificates, contact-book, contact, email-settings, export, fee-management, files, financial, history-log, home, inbox, invitation, isabel-integrate, notes, onboarding, passport, patrimony, peppol, personal-settings, ponto-integrate, prototype, search-result, time-tracking, workspace-engine, workspace-settings

### Largest module-level component sets

- `financial/components/` — dashboard, chart-of-accounts, invoices, payouts, late-fee, payment-initiations, payment-matches, costs, suppliers, provisions, breadcrumb, accounting, lists
- `activity/components/` — 20 files including `BaseActivityTableV2`, `ActivityOverview`, `UpdateStatusSheet`, chat sub-components
- `passport/components/` — certificates, cost, estimations, insurances, overview, renovations, `PassportDetailHeader`
- `contact-book/components/` — `DetailItemContainer`, table, tabs, shared

### Cross-module import hotspots

These modules have their `components/` imported by other modules (boundary violations):

| Source module | Imported by | Import count |
|--------------|-------------|--------------|
| `broadcasts/components/` | patrimony, financial, peppol, contact-book, home, meeting | ~15 imports |
| `financial/components/dashboard/` | activity, home, prototype | ~6 imports |
| `financial/components/invoices/` | contact-book, bookkeeping | ~3 imports |
| `patrimony/components/common/` | passport | ~4 imports |
| `bookkeeping/components/` | bookkeeping/accounts (internal) | ~2 imports |
| `files/components/` | financial (DragDropOverlay) | ~1 import |
