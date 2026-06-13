# Purchase Invoice V3 — Test Execution Guide

Step-by-step execution guide for adding integration and E2E test coverage to the purchase invoice v3 form. Each PR should be independently verifiable, reviewable (< 1500 lines), and revertable.

**Created**: 2026-06-03
**Updated**: 2026-06-14
**Status**: Planning complete — ready for implementation
**Architecture**: [purchase-invoice-v3-tests-planning.md](../refactoring/purchase-invoice-v3-tests-planning.md)
**Branch prefix**: `test/pi-v3-`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Test Infra + Form Basics](#3-pr-1--test-infra--form-basics)
4. [PR 2 — Lock State + Invoice Lines](#4-pr-2--lock-state--invoice-lines)
5. [PR 3 — Grouping + Distribution Sheet](#5-pr-3--grouping--distribution-sheet)
6. [PR 4 — Fields + Selects + Orchestration](#6-pr-4--fields--selects--orchestration)
7. [PR 5 — E2E CRUD Journeys](#7-pr-5--e2e-crud-journeys)
8. [PR 6 — E2E Peppol + AI + Validation](#8-pr-6--e2e-peppol--ai--validation)
9. [PR 7 — E2E Distribution + Supplier](#9-pr-7--e2e-distribution--supplier)
10. [Final Verification](#10-final-verification)
11. [Execution Log](#11-execution-log)

---

## 1. Overview

**Goal**: Add integration and E2E test coverage for `purchase-invoice-v3` form behaviors to catch regressions during refactors and verify end-to-end user flows.

**Structure**: 7 PRs, covering 122 integration test cases and 53 E2E test cases. Each PR targets < 1500 lines changed for reviewability.

| PR | Name | Risk | Cases | Depends on |
|----|------|------|-------|------------|
| **PR 1** | Test infra + form basics | Low | ~15 | — |
| **PR 2** | Lock state + invoice lines | Low | ~42 | PR 1 |
| **PR 3** | Grouping + distribution sheet | Low | ~38 | PR 1 |
| **PR 4** | Fields + selects + orchestration | Low | ~27 | PR 1 |
| **PR 5** | E2E CRUD journeys | Medium | ~19 | — |
| **PR 6** | E2E Peppol + AI + validation | Medium | ~20 | PR 5 |
| **PR 7** | E2E Distribution + supplier | Medium | ~14 | PR 5 |

**Why 7 PRs**: Large test PRs (1500+ lines) are hard to review meaningfully. Splitting by feature cluster keeps each PR focused, allows parallel review of independent PRs (PR 2/3/4 can be reviewed in parallel once PR 1 is merged), and makes it easy to revert a specific test group if it causes flakiness.

**Merge order**:
- Integration: PR 1 → then PR 2, PR 3, PR 4 (can be parallel after PR 1)
- E2E: PR 5 → then PR 6, PR 7 (can be parallel after PR 5)
- Integration and E2E tracks are independent of each other

### Test strategy

```
┌───────────────────────────────────────────────────┐
│  E2E (Playwright) — 53 cases                      │
│  Critical user journeys against staging API        │
│  Catches: routing, auth, real API, network wiring  │
├───────────────────────────────────────────────────┤
│  Integration (Vitest + Testing Library) — 122 cases│
│  Form sections with real providers, mocked APIs    │
│  Catches: context wiring, conditional render,      │
│  state transitions, validation, mode switching,    │
│  distribution sheet, supplier defaults wiring,     │
│  grouping strategy, lock reconciliation,           │
│  merge resolution, period input                    │
├───────────────────────────────────────────────────┤
│  Unit (existing) — 14 test files                   │
│  Pure logic: pipeline, reducer, utils, hooks       │
│  Catches: calculation errors, state machine bugs   │
└───────────────────────────────────────────────────┘
```

### Existing unit test coverage (already in codebase)

- `__tests__/utils.test.ts` — attachment URL, file type detection
- `__tests__/schema.snapshot.test.ts` — schema shape regression
- `__tests__/constants.test.ts` — constant values
- `__tests__/useFileHandling.test.ts` — file upload hook
- `hooks/useBackfillSupplierDefaults.test.ts` — supplier backfill logic
- `hooks/useDescriptionAutoFill.test.ts` — description generation
- `hooks/useAutoSaveBuildingSupplierDefaults.test.ts` — auto-save defaults
- `components/invoice-lines/__tests__/reducer.test.ts` — line reducer actions
- `components/invoice-lines/pipeline/__tests__/executePipelineAction.test.ts` — pipeline add/delete/edit
- `components/invoice-lines/pipeline/__tests__/reconcile.test.ts` — lock reconciliation
- `components/invoice-lines/utils/__tests__/amountCalculation.test.ts` — VAT/subtotal math
- `components/invoice-lines/amountDefaults.test.ts` — default line values
- `components/invoice-lines/lineGroupingUtils.test.ts` — grouping logic
- `utils/buildStandardDescription.test.ts` — standard description builder

### Prerequisites

- Node.js 20+, pnpm installed
- `sndq-fe/.env` with QA credentials configured
- `@testing-library/react` (already in devDependencies)
- `@testing-library/user-event` (already in devDependencies)
- `@testing-library/jest-dom` (configured globally via `vitest.setup.ts`)
- Playwright installed for E2E (`pnpm exec playwright install`)

### Known constraints

- `vitest.config.mts` includes only `src/**/*.test.{js,ts,jsx,tsx}` — integration tests must follow this pattern
- `vitest.setup.ts` registers `@testing-library/jest-dom` globally — use `toBeInTheDocument()`, `toHaveClass()`, etc.
- E2E Playwright config uses `tests/` directory with serial execution (`workers: 1`)
- Seed scenarios referenced in E2E docs do not exist yet — backend work required
- Each PR should target < 1500 lines of implementation code — verify with `git diff --stat` before opening

---

## 2. Before You Start

### Quality gate before each PR

- [ ] Public API / behavior is stable for this PR scope
- [ ] Public props, types, functions, or commands have minimal useful documentation where applicable
- [ ] Existing project helpers and patterns are reused instead of introducing one-off abstractions
- [ ] Tests or documented manual checks cover the main behavior and likely regressions
- [ ] No unrelated files, app-specific imports, or ownership-boundary leaks are introduced
- [ ] Security-sensitive values, credentials, generated secrets, and local env files are not committed
- [ ] Build, lint, type-check, and any targeted verification commands pass
- [ ] Any skipped verification is recorded as a deviation with a follow-up owner or trigger
- [ ] `git diff --stat` shows < 1500 lines changed (guideline — if exceeded, consider splitting further)

### Documentation and comment policy

- Keep code comments minimal and focused on intent, invariants, or non-obvious behavior.
- Put usage examples, migration notes, variant tables, setup steps, and operational runbooks in docs, not inline code comments.

### Capture baselines

```bash
pnpm test --run 2>&1 | tee /tmp/pi-v3-tests-unit-before.txt
pnpm test:e2e --list 2>&1 | tee /tmp/pi-v3-tests-e2e-before.txt
```

### Create branches

```bash
git checkout develop && git pull origin develop

# Integration track
git checkout -b test/pi-v3-infra-basics        # PR 1
git checkout -b test/pi-v3-lock-lines          # PR 2 (from PR 1)
git checkout -b test/pi-v3-grouping-dist       # PR 3 (from PR 1)
git checkout -b test/pi-v3-fields-selects      # PR 4 (from PR 1)

# E2E track
git checkout -b test/pi-v3-e2e-crud            # PR 5
git checkout -b test/pi-v3-e2e-peppol-ai       # PR 6 (from PR 5)
git checkout -b test/pi-v3-e2e-dist-supplier   # PR 7 (from PR 5)
```

---

## 3. PR 1 — Test Infra + Form Basics

**Branch**: `test/pi-v3-infra-basics`
**Depends on**: nothing (base PR)
**Cases**: ~15

Establishes the shared test infrastructure that all other integration PRs depend on, plus the simplest integration specs.

### Scope

1. Shared utilities (`__tests__/utils/`): `renderWithProviders`, `createMockContextValue`, `makeLine`, `makePristineLine`, mock factories, i18n messages
2. [integration/form-body-conditional.md](./integration/form-body-conditional.md) — IT-001..IT-004 (4 cases)
3. [integration/mode-switching.md](./integration/mode-switching.md) — IT-019..IT-023 (5 cases)
4. [integration/form-header.md](./integration/form-header.md) — IT-133..IT-138 (6 cases)

### File location

`sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/`

### Verification

```bash
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/form-body-conditional.test.tsx
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/mode-switching.test.tsx
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/form-header.test.tsx
```

---

## 4. PR 2 — Lock State + Invoice Lines

**Branch**: `test/pi-v3-lock-lines`
**Depends on**: PR 1 merged
**Cases**: ~42

The largest integration PR — covers the lock state machine and all invoice line interactions (CRUD, VAT, period input, inline cost/distribution). These are tightly coupled since lock state directly constrains line editing behavior.

### Scope

1. [integration/lock-state-toggle.md](./integration/lock-state-toggle.md) — IT-005..IT-016 (12 cases)
2. [integration/invoice-lines-table.md](./integration/invoice-lines-table.md) — IT-075..IT-104 (30 cases)

### Verification

```bash
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/lock-state-toggle.test.tsx
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/invoice-lines-table.test.tsx
```

### Note

If this PR exceeds 1500 lines, split into PR 2a (lock-state-toggle, 14 cases) and PR 2b (invoice-lines-table, 31 cases).

---

## 5. PR 3 — Grouping + Distribution Sheet

**Branch**: `test/pi-v3-grouping-dist`
**Depends on**: PR 1 merged
**Cases**: ~38

Covers the grouping strategy lifecycle (individual/single-total switching, merge conflicts, resolution outcomes) and the full amount distribution sheet interactions.

### Scope

1. [integration/grouping-strategy.md](./integration/grouping-strategy.md) — IT-106..IT-125 (20 cases)
2. [integration/amount-distribution-sheet.md](./integration/amount-distribution-sheet.md) — IT-047..IT-064 (18 cases)

### Verification

```bash
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/grouping-strategy.test.tsx
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/amount-distribution-sheet.test.tsx
```

---

## 6. PR 4 — Fields + Selects + Orchestration

**Branch**: `test/pi-v3-fields-selects`
**Depends on**: PR 1 merged
**Cases**: ~27

Sweeps up the remaining thin integration specs — each file is small individually but together they cover form field interactions, right panel, inline selects, Peppol population, supplier defaults, form orchestration, and dialog lifecycle.

### Scope

1. [integration/invoice-fields.md](./integration/invoice-fields.md) — IT-031..IT-038 (8 cases)
2. [integration/right-panel-tabs.md](./integration/right-panel-tabs.md) — IT-024..IT-030 (7 cases)
3. [integration/inline-selects.md](./integration/inline-selects.md) — IT-145..IT-150 (6 cases)
4. [integration/peppol-to-invoice.md](./integration/peppol-to-invoice.md) — IT-039..IT-046 (8 cases)
5. [integration/supplier-defaults.md](./integration/supplier-defaults.md) — IT-065..IT-074 (10 cases)
6. [integration/form-orchestration.md](./integration/form-orchestration.md) — IT-126..IT-132 (7 cases)
7. [integration/form-dialogs.md](./integration/form-dialogs.md) — IT-140..IT-144 (5 cases)

### Verification

```bash
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/
```

### Note

If this PR exceeds 1500 lines, split by grouping: PR 4a (invoice-fields + right-panel-tabs + inline-selects) and PR 4b (peppol + supplier + orchestration + dialogs).

---

## 7. PR 5 — E2E CRUD Journeys

**Branch**: `test/pi-v3-e2e-crud`
**Depends on**: nothing (independent of integration track)
**Cases**: ~19

Core user flows: creating, editing, credit notes, and draft lifecycle. Establishes E2E helpers, page objects, and seed scenario patterns.

### Scope

1. E2E shared infrastructure: page objects, helpers, seed fixtures
2. [e2e/create-invoice.md](./e2e/create-invoice.md) — E2E-001..E2E-005 (5 cases)
3. [e2e/edit-invoice.md](./e2e/edit-invoice.md) — E2E-006..E2E-009 + E2E-009b (5 cases)
4. [e2e/credit-note.md](./e2e/credit-note.md) — E2E-010..E2E-012 (3 cases)
5. [e2e/draft-save-resume.md](./e2e/draft-save-resume.md) — E2E-017..E2E-019 (3 cases)

### File location

`sndq-fe/tests/financial/purchase-invoices/`

### Verification

```bash
pnpm test:e2e tests/financial/purchase-invoices/
```

---

## 8. PR 6 — E2E Peppol + AI + Validation

**Branch**: `test/pi-v3-e2e-peppol-ai`
**Depends on**: PR 5 merged (uses shared helpers/page objects)
**Cases**: ~20

Import and extraction flows: Peppol XML import, AI-assisted extraction, partial edits, and validation error display.

### Scope

1. [e2e/peppol-import.md](./e2e/peppol-import.md) — E2E-013..E2E-016 (4 cases)
2. [e2e/peppol-to-invoice.md](./e2e/peppol-to-invoice.md) — E2E-030..E2E-039 (10 cases)
3. [e2e/ai-extraction.md](./e2e/ai-extraction.md) — E2E-020..E2E-022 (3 cases)
4. [e2e/partial-edit.md](./e2e/partial-edit.md) — E2E-023..E2E-025 (3 cases)
5. [e2e/validation-errors.md](./e2e/validation-errors.md) — E2E-026..E2E-029 (4 cases)

### Verification

```bash
pnpm test:e2e tests/financial/purchase-invoices/peppol*.spec.ts tests/financial/purchase-invoices/ai*.spec.ts tests/financial/purchase-invoices/validation*.spec.ts
```

---

## 9. PR 7 — E2E Distribution + Supplier

**Branch**: `test/pi-v3-e2e-dist-supplier`
**Depends on**: PR 5 merged (uses shared helpers/page objects)
**Cases**: ~14

Advanced feature flows: the full distribution sheet journey and supplier defaults auto-fill/auto-save lifecycle.

### Scope

1. [e2e/amount-distribution.md](./e2e/amount-distribution.md) — E2E-040..E2E-047 (8 cases)
2. [e2e/supplier-defaults.md](./e2e/supplier-defaults.md) — E2E-048..E2E-052 + E2E-050b (6 cases)

### Verification

```bash
pnpm test:e2e tests/financial/purchase-invoices/distribution*.spec.ts tests/financial/purchase-invoices/supplier*.spec.ts
```

---

## 10. Final Verification

After all PRs are merged, run the full suite:

```bash
pnpm test --run
pnpm test:e2e
pnpm lint
pnpm tsc
```

Compare against baselines:

```bash
diff /tmp/pi-v3-tests-unit-before.txt /tmp/pi-v3-tests-unit-after.txt
diff /tmp/pi-v3-tests-e2e-before.txt /tmp/pi-v3-tests-e2e-after.txt
```

**Expected result**: All new tests pass. No existing tests regress. Build, lint, and type-check remain green.

---

## 11. Execution Log

| Date | PR | Branch | Lines | Notes |
|------|-----|--------|-------|-------|
| | PR 1 | `test/pi-v3-infra-basics` | | |
| | PR 2 | `test/pi-v3-lock-lines` | | |
| | PR 3 | `test/pi-v3-grouping-dist` | | |
| | PR 4 | `test/pi-v3-fields-selects` | | |
| | PR 5 | `test/pi-v3-e2e-crud` | | |
| | PR 6 | `test/pi-v3-e2e-peppol-ai` | | |
| | PR 7 | `test/pi-v3-e2e-dist-supplier` | | |
