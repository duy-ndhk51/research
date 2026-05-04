# Phase 3, Batch 2 Execution — Card, Tabs, Tooltip, EmptyState, Skeleton

Step-by-step execution guide for Phase 3, Batch 2. Each commit is independently verifiable and revertable.

**Created**: 2026-05-04
**Status**: Not started
**Architecture**: [README.md](./README.md)
**Migration plan**: [migration-plan.md](./migration-plan.md)
**Phase 2 execution**: [phase-2-execution.md](./phase-2-execution.md)
**Phase 3, Batch 0 execution**: [phase-3-batch-0-execution.md](./phase-3-batch-0-execution.md)
**Phase 3, Batch 1 execution**: [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md)

**Branching**: Single branch / one PR by default; commits ordered so you can split (e.g. deprecations last) if needed.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Standardize, graduate, deprecate (Batch 2)](#3-pr-1--standardize-graduate-deprecate-batch-2)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#7-execution-log)

---

## 1. Overview

**Goal**: Standardize and graduate Card, Tabs, Tooltip, EmptyState, and Skeleton into `packages/ui-v2/`, add Primitives MDX in `apps/docs`, and add JSDoc `@deprecated` on the listed `sndq-fe` legacy exports — without Phase 4 call-site migrations.

**Structure**: **11 commits** across **1 PR**: two commits per component (standardize → graduate + MDX), then one deprecation commit.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Card, Tabs, Tooltip, EmptyState, Skeleton + docs + deprecations | Medium | 1–11 |

### Prerequisites

- Phase 3, Batch 1 is merged to dev (Button, Input, Badge, Select, Dialog, Sheet already in `@sndq/ui-v2`).

### Legacy deprecation mapping (Batch 2)

| Graduated (ui-v2) | Legacy location (sndq-fe) |
|-------------------|---------------------------|
| `Card` and related subcomponents | `sndq-fe/src/components/ui/card.tsx` (and barrel exports) |
| `Tabs` and related | `sndq-fe/src/components/ui/tabs.tsx` |
| `Tooltip` and related | `sndq-fe/src/components/ui/tooltip.tsx` |
| `EmptyState` | `sndq-fe/src/components/briicks/empty-state/` (path may vary — confirm) |
| `Skeleton` | `sndq-fe/src/components/ui/skeleton.tsx` |

Use the same JSDoc message pattern as Batch 1: `Use {Name} from @sndq/ui-v2/components instead.`

---

## 2. Before You Start

### Standardization gate

Same checklist as [phase-3-batch-1-execution.md §2](./phase-3-batch-1-execution.md#standardization-gate-before-each-graduate-commit) (JSDoc, `cn`, `ref`, tests, no app imports, shared tokens/CSS).

### Co-located exports

Before starting **Card**, list files under the Card implementation folder in the prototype; include `CardHeader`, `CardContent`, etc. in the same vertical slice if they ship as one unit. Same for **Tabs** (list, trigger, content) and **Tooltip** (provider, trigger, content).

### Capture baselines

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build 2>&1 | tee /tmp/phase3-b2-proto-build-before.txt
pnpm --filter @sndq/ui-v2-dev run lint 2>&1 | tee /tmp/phase3-b2-proto-lint-before.txt
pnpm --filter @sndq/ui-v2-dev run type-check 2>&1 | tee /tmp/phase3-b2-proto-typecheck-before.txt

NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build 2>&1 | tee /tmp/phase3-b2-docs-build-before.txt

NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build 2>&1 | tee /tmp/phase3-b2-pkg-build-before.txt

NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase3-b2-fe-build-before.txt
```

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/phase-3-batch-2-standardize-graduate
```

---

## 3. PR 1 — Standardize, graduate, deprecate (Batch 2)

---

### Commit 1: Standardize Card in prototype

**What**: Props, composition API, JSDoc, tests, Storybook/playground for Card family.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Compound components partially moved | MEDIUM | Move entire family in Commit 2 |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=card
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Card for package graduation`

**Status**:

- [ ] Gate checklist for Card
- [ ] Committed

---

### Commit 2: Graduate Card + MDX + consumers

**Files to create**: `packages/ui-v2/src/components/card.tsx` (or folder), `apps/docs/content/docs/primitives/card.mdx`

**Files to edit**: `packages/ui-v2/src/components/index.ts`, `apps/docs/content/docs/primitives/meta.json`, prototype imports

**Commit message**: `feat(ui-v2): graduate Card to package and document`

**Verification**:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
```

**Status**:

- [ ] Committed

---

### Commit 3: Standardize Tabs in prototype

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=tabs
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Tabs for package graduation`

**Status**:

- [ ] Gate checklist for Tabs
- [ ] Committed

---

### Commit 4: Graduate Tabs + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Tabs to package and document`

**Status**:

- [ ] Committed

---

### Commit 5: Standardize Tooltip in prototype

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=tooltip
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Tooltip for package graduation`

**Status**:

- [ ] Gate checklist for Tooltip
- [ ] Committed

---

### Commit 6: Graduate Tooltip + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Tooltip to package and document`

**Status**:

- [ ] Committed

---

### Commit 7: Standardize EmptyState in prototype

**What**: briicks `empty-state` maps here; ensure naming aligns with package export (`EmptyState`).

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=empty-state|emptystate
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize EmptyState for package graduation`

**Status**:

- [ ] Gate checklist for EmptyState
- [ ] Committed

---

### Commit 8: Graduate EmptyState + MDX + consumers

**Commit message**: `feat(ui-v2): graduate EmptyState to package and document`

**Status**:

- [ ] Committed

---

### Commit 9: Standardize Skeleton in prototype

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=skeleton
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Skeleton for package graduation`

**Status**:

- [ ] Gate checklist for Skeleton
- [ ] Committed

---

### Commit 10: Graduate Skeleton + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Skeleton to package and document`

**Status**:

- [ ] Committed

---

### Commit 11: Deprecate legacy exports (Batch 2)

**What**: JSDoc `@deprecated` on briicks empty-state and ui card, tabs, tooltip, skeleton barrels — only after Commit 10 is merged in the same branch.

**Files to edit** (confirm paths):

- `sndq-fe/src/components/briicks/empty-state/**` (index / barrel)
- `sndq-fe/src/components/ui/card.tsx`
- `sndq-fe/src/components/ui/tabs.tsx`
- `sndq-fe/src/components/ui/tooltip.tsx`
- `sndq-fe/src/components/ui/skeleton.tsx`

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
pnpm --filter sndq-fe run lint
pnpm --filter sndq-fe run type-check
```

**Commit message**: `chore(sndq-fe): deprecate Batch 2 briicks/ui exports for ui-v2`

**Status**:

- [ ] All mapping rows covered
- [ ] Committed

---

### PR 1 Checkpoint

```bash
git push -u origin feature/phase-3-batch-2-standardize-graduate
```

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Merged

---

## 4. Final Verification

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
```

**Expected result**: Five new primitives in package + docs; legacy exports deprecated.

**Final status**:

- [ ] All 11 commits done
- [ ] Root suite green
- [ ] PR merged

---

## 5. Team Communication

> **Heads up: Batch 2 ui-v2 graduation (Card, Tabs, Tooltip, EmptyState, Skeleton)**
>
> PR [link] extends `@sndq/ui-v2/components` and adds MDX. Legacy `ui/*` and briicks empty-state exports gain `@deprecated` — Phase 4 will migrate call sites.
>
> After pulling: `pnpm install`, restart TS + ESLint.

---

## 6. What's Next

Proceed to [phase-3-batch-3-execution.md](./phase-3-batch-3-execution.md) (remaining primitives + blocks in waves). After Batch 3, Phase 4 module migration begins (see [migration-plan.md §7](./migration-plan.md#7-phase-4-module-by-module-migration)).

### Known lessons

- [phase-3-batch-1-execution.md §6](./phase-3-batch-1-execution.md#6-whats-next)

---

## 7. Execution Log

| Date | Commit | Notes |
|------|--------|-------|
|      | 1      |       |
|      | …      |       |
|      | 11     |       |
