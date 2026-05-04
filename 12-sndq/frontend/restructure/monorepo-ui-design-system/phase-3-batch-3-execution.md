# Phase 3, Batch 3 Execution — Remaining primitives + blocks

Step-by-step execution guide for Phase 3, Batch 3. Work proceeds in **waves** (logical groupings); each component still uses the **two-commit vertical slice** (standardize → graduate). One PR remains the default; you may merge wave-by-wave if review or CI requires it.

**Created**: 2026-05-04
**Status**: Not started
**Architecture**: [README.md](./README.md) §5 (component inventory)
**Migration plan**: [migration-plan.md](./migration-plan.md)
**Phase 2 execution**: [phase-2-execution.md](./phase-2-execution.md)
**Phase 3, Batch 1 execution**: [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md)
**Phase 3, Batch 2 execution**: [phase-3-batch-2-execution.md](./phase-3-batch-2-execution.md)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Inventory: what Batch 3 covers](#2-inventory-what-batch-3-covers)
3. [Before You Start](#3-before-you-start)
4. [PR 1 — Waves + deprecations](#4-pr-1--waves--deprecations)
5. [Commit pattern template (per component)](#5-commit-pattern-template-per-component)
6. [Final Verification](#6-final-verification)
7. [Team Communication](#7-team-communication)
8. [What's Next](#8-whats-next)
9. [Execution Log](#9-execution-log)

---

## 1. Overview

**Goal**: Graduate **all remaining Tier 1 primitives** listed in README §5 that were not in Batches 1–2, then graduate **Tier 2 blocks** into `packages/ui-v2/src/blocks/`, with MDX under `apps/docs/content/docs/primitives/` and `.../blocks/` as appropriate. Finish Phase 3 legacy signaling with a **grep-driven** JSDoc `@deprecated` pass on remaining `sndq-fe` briicks/ui exports that now have replacements.

**Structure**: **1 + (2 × N) + 1** commits in principle — **Commit 1** inventory, **2N** component commits (standardize + graduate per primitive or block), **final commit** deprecations. N is large (~59 primitives + 10 blocks if following README); **do not squash** wave work if you want bisectable history.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Remaining primitives by wave + blocks + deprecations | High (volume, chart dependencies) | Many (see §2) |

**Why one PR (default)**: Matches agreed batch granularity; **splitting is explicitly OK** after any wave boundary (see end of §4).

### Prerequisites

- Phase 3, Batch 2 merged to dev.

### Blocks dependency rule

Do **not** graduate a block until **every primitive it imports** already lives in `packages/ui-v2/src/components/`. If a block still pulls from `apps/ui-v2-dev`, finish the missing primitive waves first (or temporarily duplicate — **avoid**; fix ordering instead).

---

## 2. Inventory: what Batch 3 covers

Source: [README.md](./README.md) Tier 1 and Tier 2 tables. **Already graduated in Batches 1–2**: Button, ComboButton (with Button), Input, Badge, Select, Dialog, Sheet, Card, Tabs, Tooltip, EmptyState, Skeleton.

### Tier 1 — remaining primitives (alphabetical by wave below)

| Wave | Components (README names) |
|------|---------------------------|
| **A — Extended inputs** | Textarea, SelectNative, Checkbox, RadioGroup, RadioCardGroup, Switch, Slider, OtpField, Autocomplete, Combobox |
| **B — Date** | DatePicker, Calendar |
| **C — Form helpers** | FormField, Label |
| **D — Buttons (remainder)** | Toggle, ToggleGroup |
| **E — Display (remainder)** | MoreBadge, Chip, ChipGroup, Avatar, AvatarGroup, Spinner, Kbd |
| **F — Feedback (remainder)** | Alert, Callout, ProgressBar, ProgressCircle, Toast, Toaster, Tracker, CategoryBar |
| **G — Layout** | Separator, Divider, Row, Frame, Group, ScrollArea |
| **H — Overlays (remainder)** | Drawer, FloatingSheet, Popover, DropdownMenu, Command |
| **I — Navigation (remainder)** | TabNavigation, SegmentedControl, Breadcrumb, Pagination, Toolbar |
| **J — Data** | Table |
| **K — Charts** | AreaChart, BarChart, BarList, LineChart, DonutChart, ComboChart, SparkChart, ChartPrimitives |
| **L — Composition** | Accordion, Collapsible |

If the prototype tree uses different file names, **map README name → path** during Commit 1 and update this table in your branch’s execution log if needed.

### Tier 2 — blocks (graduate after primitives they need)

| Block | Package path target |
|-------|---------------------|
| PageHeader | `packages/ui-v2/src/blocks/page-header.tsx` (names per repo convention) |
| SectionHeader | `packages/ui-v2/src/blocks/...` |
| SectionBanner | `packages/ui-v2/src/blocks/...` |
| DetailHeader | `packages/ui-v2/src/blocks/...` |
| KpiCard | `packages/ui-v2/src/blocks/...` |
| StatList | `packages/ui-v2/src/blocks/...` |
| EntityCard | `packages/ui-v2/src/blocks/...` |
| ConfirmDialog | `packages/ui-v2/src/blocks/...` |
| ActivityItem | `packages/ui-v2/src/blocks/...` |
| FormShell | `packages/ui-v2/src/blocks/...` (from `apps/ui-v2-dev/src/patterns/form/` per README §5 note) |

**Blocks docs**: `apps/docs/content/docs/blocks/<slug>.mdx` + `blocks/meta.json` updates.

**Deprecation messages for blocks**: If `sndq-fe` has no direct barrel for a block, there may be **nothing to deprecate** — blocks are often prototype-only until Phase 4. Only add JSDoc where a legacy export actually existed.

---

## 3. Before You Start

### Standardization gate

Same as [phase-3-batch-1-execution.md §2](./phase-3-batch-1-execution.md#standardization-gate-before-each-graduate-commit).

### Chart / data dependency caution (Wave K)

Confirm chart primitives use only package-safe dependencies (no app-only data hooks). Add peer deps to `@sndq/ui-v2/package.json` only when required and aligned with Phase 2 dependency policy.

### Capture baselines

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build 2>&1 | tee /tmp/phase3-b3-proto-build-before.txt
pnpm --filter @sndq/ui-v2-dev run lint 2>&1 | tee /tmp/phase3-b3-proto-lint-before.txt
pnpm --filter @sndq/ui-v2-dev run type-check 2>&1 | tee /tmp/phase3-b3-proto-typecheck-before.txt

NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build 2>&1 | tee /tmp/phase3-b3-docs-build-before.txt

NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build 2>&1 | tee /tmp/phase3-b3-pkg-build-before.txt

NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase3-b3-fe-build-before.txt
```

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/phase-3-batch-3-remaining-and-blocks
```

---

## 4. PR 1 — Waves + deprecations

### Commit 1: Inventory and gap analysis

**What**:

1. Export list from `packages/ui-v2/src/components/index.ts` (already graduated).
2. `ls` / `rg` under `apps/ui-v2-dev/src/components/ui-v2/` — every remaining folder/file is a candidate.
3. `rg` export patterns under `sndq-fe/src/components/briicks/` and `sndq-fe/src/components/ui/` — build a **spreadsheet or markdown table**: `legacy file` → `replacement export` → `deprecated? (y/n)`.
4. Note any prototype component that **violates** the gate (app imports) — either fix in Wave A before moving, or explicitly defer with ticket (do not graduate dirty components).

**Files to create** (optional but useful):

- `agent-workspace/tmp/phase-3-batch-3-legacy-map.md` (or team wiki) — **do not commit secrets**; if committed, use a path approved by the team

**Files to edit**:

- None required in Commit 1 if the map stays local — alternatively commit a **sanitized** checklist under `research/...` only if your process allows docs-only commits in the same PR

**Verification**:

- Table completeness: every README Tier 1 row not in Batches 1–2 has a row or explicit “deferred” reason.

**Commit message**: `chore(ui-migration): inventory remaining ui-v2 primitives and legacy map`

**Status**:

- [ ] Inventory doc complete
- [ ] Committed (or held local per team policy)

---

### Waves A through L (primitives)

For **each component** in the wave order (see §2 table), execute **two commits** using [§5 template](#5-commit-pattern-template-per-component):

1. `refactor(ui-v2-dev): standardize <Name> for package graduation`
2. `feat(ui-v2): graduate <Name> to package and document`

**Wave-end verification** (after the last graduate commit in that wave):

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
pnpm --filter @sndq/ui-v2 run test
pnpm --filter @sndq/ui-v2-dev run test
```

**Optional PR split**: Open a PR after Wave L primitives (before blocks) if blocks deserve isolated review.

---

### Wave M — Blocks

For **each block** (see §2), after dependency check:

1. `refactor(ui-v2-dev): standardize <BlockName> block for package graduation`
2. `feat(ui-v2): graduate <BlockName> to blocks package and document`

**Files to edit**:

- `packages/ui-v2/src/blocks/index.ts` — export block
- `apps/ui-v2-dev/**` — imports from `@sndq/ui-v2/blocks`
- `apps/docs/content/docs/blocks/meta.json` and new `*.mdx`

**Deprecation**: Use `Use <Block> from @sndq/ui-v2/blocks instead.` only if a matching `sndq-fe` export existed.

**Wave M verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
```

---

### Final commit: Deprecate all remaining mapped legacy exports

**What**: For every row in the Commit 1 table with `deprecated? = y`, add JSDoc `@deprecated` to the **canonical barrel export** (same pattern as Batches 1–2). Prefer one commit per legacy file if messages differ, or one bulk commit if review prefers a single diff — **one commit minimum** for the whole deprecation pass is acceptable.

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
pnpm --filter sndq-fe run lint
pnpm --filter sndq-fe run type-check
```

**Commit message**: `chore(sndq-fe): deprecate remaining briicks/ui exports for ui-v2 (Batch 3)`

**Status**:

- [ ] No mapped replacement left undeprecated (except explicit deferrals)
- [ ] `sndq-fe` builds
- [ ] Committed

---

### PR 1 Checkpoint

```bash
git push -u origin feature/phase-3-batch-3-remaining-and-blocks
```

**This validates**: Full package surface, docs site with Primitives + Blocks populated, prototype consumes workspace packages only.

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Merged

---

## 5. Commit pattern template (per component)

### Commit type A — Standardize `<Name>` in prototype

**What**: JSDoc, props, `cn`/`ref`, tests, no app imports, tokens/CSS from `@sndq/config`.

**Files to edit**: `apps/ui-v2-dev/src/components/ui-v2/...` (paths from inventory)

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Cross-import from another prototype file not yet in package | MEDIUM | Graduate dependency first or extract shared util into package-internal `src/lib/` |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=<kebab-name>
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

### Commit type B — Graduate `<Name>` + MDX + consumers

**What**: Move implementation to `packages/ui-v2/src/components/<name>.tsx` (or folder), export from `src/components/index.ts`, update `apps/ui-v2-dev` and `apps/docs` imports, add or update `apps/docs/content/docs/primitives/<slug>.mdx` and `primitives/meta.json`.

**For blocks** (Wave M): target `packages/ui-v2/src/blocks/`, export from `src/blocks/index.ts`, MDX under `content/docs/blocks/`, import path `@sndq/ui-v2/blocks`.

**Verification**:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
```

---

## 6. Final Verification

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
pnpm test
```

**Expected result**:

- `apps/ui-v2-dev` has **no** remaining `ui-v2` primitives that should live in the package (only patterns, demos, app-specific glue).
- `packages/ui-v2` exports the full Tier 1 + Tier 2 surface from README §5.
- Legacy briicks/ui exports that have replacements carry `@deprecated`.

**Final status**:

- [ ] All waves complete
- [ ] Inventory / deferrals documented
- [ ] Root suite green
- [ ] PR merged

---

## 7. Team Communication

> **Heads up: Phase 3 Batch 3 completes ui-v2 graduation**
>
> PR [link] graduates the remaining primitives and design-system blocks into `@sndq/ui-v2`. Legacy briicks/ui exports gain `@deprecated` where a 1:1 replacement exists. **Module import migration** still happens in Phase 4 — expect strikethrough imports until modules are ported.
>
> After pulling: `pnpm install`, restart TS + ESLint, run tests if you touch shared UI.

---

## 8. What's Next

Phase 3 ends when Batch 3 merges. Proceed to **Phase 4: module-by-module migration** in [migration-plan.md §7](./migration-plan.md#7-phase-4-module-by-module-migration) — pilot on a small module (`peppol` or `search-result`), then larger modules, with direct import and prop changes per the API matrix §10.

### Lessons to carry forward

- **Wave boundaries** are natural merge/rollback points for a large batch.
- **Charts** often need explicit dependency and bundle-size review — do not hide them inside unrelated waves.

### Known lessons

- [phase-3-batch-0-execution.md §6](./phase-3-batch-0-execution.md#6-whats-next)

---

## 9. Execution Log

| Date | Commit / wave | Notes |
|------|---------------|-------|
|      | 1 inventory   |       |
|      | A … L         |       |
|      | M blocks      |       |
|      | deprecations  |       |
