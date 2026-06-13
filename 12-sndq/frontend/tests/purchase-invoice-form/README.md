# Purchase Invoice V3 — Test Execution Guide

Step-by-step execution guide for adding integration and E2E test coverage to the purchase invoice v3 form. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-03
**Updated**: 2026-06-12
**Status**: Planning complete — ready for reimplementation
**Architecture**: [purchase-invoice-v3-tests-planning.md](../refactoring/purchase-invoice-v3-tests-planning.md)
**Branch**: `test/purchase-invoice-v3-coverage`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Integration Tests](#3-pr-1--integration-tests)
4. [PR 2 — E2E Tests](#4-pr-2--e2e-tests)
5. [Final Verification](#5-final-verification)
6. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Add integration and E2E test coverage for `purchase-invoice-v3` form behaviors to catch regressions during refactors and verify end-to-end user flows.

**Structure**: 2 PRs, covering 126 integration test cases (IT-001..IT-126) and 53 E2E test cases.

| PR | Scope | Risk level | Cases |
|----|-------|------------|-------|
| **PR 1** | Integration tests (Vitest + Testing Library) | Low | IT-001..IT-126 (incl. sub-scenarios) |
| **PR 2** | E2E tests (Playwright) | Medium | E2E-001..E2E-052 + E2E-014b |

**Why 2 PRs**: Integration tests have no backend dependency and can be merged first. E2E tests require seed scenarios and staging API stability, making them a separate deliverable.

### Test strategy

```
┌───────────────────────────────────────────────────┐
│  E2E (Playwright) — 53 cases                      │
│  Critical user journeys against staging API        │
│  Catches: routing, auth, real API, network wiring  │
├───────────────────────────────────────────────────┤
│  Integration (Vitest + Testing Library) — 126 cases│
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

---

## 2. Before You Start

### Quality gate before each implementation commit

- [ ] Public API / behavior is stable for this commit scope
- [ ] Public props, types, functions, or commands have minimal useful documentation where applicable
- [ ] Existing project helpers and patterns are reused instead of introducing one-off abstractions
- [ ] Tests or documented manual checks cover the main behavior and likely regressions
- [ ] No unrelated files, app-specific imports, or ownership-boundary leaks are introduced
- [ ] Security-sensitive values, credentials, generated secrets, and local env files are not committed
- [ ] Build, lint, type-check, and any targeted verification commands are known before editing
- [ ] Any skipped verification is recorded as a deviation with a follow-up owner or trigger

### Documentation and comment policy

- Keep code comments minimal and focused on intent, invariants, or non-obvious behavior.
- Put usage examples, migration notes, variant tables, setup steps, and operational runbooks in docs, not inline code comments.

### Capture baselines

```bash
pnpm test --run 2>&1 | tee /tmp/pi-v3-tests-unit-before.txt
pnpm test:e2e --list 2>&1 | tee /tmp/pi-v3-tests-e2e-before.txt
```

### Create branch

```bash
git checkout develop
git pull origin develop
git checkout -b test/purchase-invoice-v3-coverage
```

---

## 3. PR 1 — Integration Tests

Integration tests render form sub-sections with real React Hook Form + real context providers, but mocked API hooks. They run in Vitest with jsdom.

**File location**: `sndq-fe/src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/`

See:
- [integration/README.md](./integration/README.md) — setup patterns, shared wrapper, assertion conventions
- [integration/form-body-conditional.md](./integration/form-body-conditional.md) — IT-001..IT-004
- [integration/lock-state-toggle.md](./integration/lock-state-toggle.md) — IT-005..IT-018
- [integration/mode-switching.md](./integration/mode-switching.md) — IT-019..IT-023
- [integration/right-panel-tabs.md](./integration/right-panel-tabs.md) — IT-024..IT-030
- [integration/invoice-fields.md](./integration/invoice-fields.md) — IT-031..IT-038
- [integration/peppol-to-invoice.md](./integration/peppol-to-invoice.md) — IT-039..IT-046
- [integration/amount-distribution-sheet.md](./integration/amount-distribution-sheet.md) — IT-047..IT-064
- [integration/supplier-defaults.md](./integration/supplier-defaults.md) — IT-065..IT-074
- [integration/invoice-lines-table.md](./integration/invoice-lines-table.md) — IT-075..IT-105
- [integration/grouping-strategy.md](./integration/grouping-strategy.md) — IT-106..IT-125
- [integration/form-orchestration.md](./integration/form-orchestration.md) — IT-126..IT-132
- [integration/form-header.md](./integration/form-header.md) — IT-133..IT-139
- [integration/form-dialogs.md](./integration/form-dialogs.md) — IT-140..IT-144
- [integration/inline-selects.md](./integration/inline-selects.md) — IT-145..IT-150

### Verification

```bash
pnpm test src/modules/financial/forms/purchase-invoice-v3/__tests__/integration/
```

---

## 4. PR 2 — E2E Tests

E2E tests use Playwright against a running dev server (or staging via BrowserStack). They follow the existing pattern from `tests/financial/`.

**File location**: `sndq-fe/tests/financial/purchase-invoices/`

See:
- [e2e/README.md](./e2e/README.md) — seed scenarios, helpers, selectors
- [e2e/create-invoice.md](./e2e/create-invoice.md) — E2E-001..E2E-005
- [e2e/edit-invoice.md](./e2e/edit-invoice.md) — E2E-006..E2E-009 (+ E2E-009b)
- [e2e/credit-note.md](./e2e/credit-note.md) — E2E-010..E2E-012
- [e2e/peppol-import.md](./e2e/peppol-import.md) — E2E-013..E2E-016
- [e2e/draft-save-resume.md](./e2e/draft-save-resume.md) — E2E-017..E2E-019
- [e2e/ai-extraction.md](./e2e/ai-extraction.md) — E2E-020..E2E-022
- [e2e/partial-edit.md](./e2e/partial-edit.md) — E2E-023..E2E-025
- [e2e/validation-errors.md](./e2e/validation-errors.md) — E2E-026..E2E-029
- [e2e/peppol-to-invoice.md](./e2e/peppol-to-invoice.md) — E2E-030..E2E-039 (Peppol full flow)
- [e2e/amount-distribution.md](./e2e/amount-distribution.md) — E2E-040..E2E-047 (distribution sheet journey)
- [e2e/supplier-defaults.md](./e2e/supplier-defaults.md) — E2E-048..E2E-052 (+ E2E-050b) (auto-fill + auto-save flow)

### Verification

```bash
pnpm test:e2e tests/financial/purchase-invoices/
```

---

## 5. Final Verification

After all commits, run the full suite:

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

## Execution Log

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
