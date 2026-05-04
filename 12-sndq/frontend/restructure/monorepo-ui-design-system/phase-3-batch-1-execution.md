# Phase 3, Batch 1 Execution — Typography (`Text`, `Heading`), then Button, Input, Badge, Select, Dialog, Sheet

Step-by-step execution guide for Phase 3, Batch 1. Each commit is independently verifiable and revertable.

**Created**: 2026-05-04  
**Status**: Not started  
**Architecture**: [README.md](./README.md)  
**Migration plan**: [migration-plan.md](./migration-plan.md)  
**Typography reference**: [typography-system-reference.md](./typography-system-reference.md)  
**Phase 2 execution**: [phase-2-execution.md](./phase-2-execution.md)  
**Phase 3, Batch 0 execution**: [phase-3-batch-0-execution.md](./phase-3-batch-0-execution.md)

**Branching**: Use a single long-lived branch for this batch (one PR), or split later at natural boundaries (see [PR 1 note](#3-pr-1--standardize-graduate-deprecate-batch-1)).

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Standardize, graduate, deprecate (Batch 1)](#3-pr-1--standardize-graduate-deprecate-batch-1)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#7-execution-log)

---

## 1. Overview

**Goal**: Standardize **`Text`** and **`Heading`** first (foundations-aligned typography), then the six highest-leverage interactive primitives in `apps/ui-v2-dev/`, graduate them into `packages/ui-v2/`, document each in `apps/docs` under Primitives, and add JSDoc `@deprecated` on the matching `sndq-fe` briicks/ui barrel exports — without rewriting `sndq-fe` call sites (Phase 4).

**Structure**: **17 commits** across **1 PR** (default). Typography uses four commits (`Text` standardize + graduate, `Heading` standardize + graduate). Each remaining component uses two commits (standardize + graduate). The last commit applies all legacy deprecations together.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | `Text`, `Heading`, then Button (+ co-located button exports), Input, Badge, Select, Dialog, Sheet + docs MDX + incremental `@sndq/config` `@theme` aliases as needed + `sndq-fe` deprecations | Medium | 1–17 |

**Why typography first**: Establishes token usage, `cn()` pattern, and optional short Tailwind utilities before the larger interactive set. See [typography-system-reference.md](./typography-system-reference.md).

**Why 1 PR**: Keeps one reviewable narrative for the first graduation batch. Commits stay ordered so you can split later (e.g. commits 1–16 merged first, commit 17 as follow-up) if CI or policy requires it.

### Typography and `@theme` utilities (gradual)

- **Canonical values** live in `packages/config/tailwind/semantic-tokens.css` (`--sndq-text`, `--sndq-text-secondary`, `--sndq-text-xs` … `--sndq-text-7xl`, font stacks). Variant `cva` strings must use these variables (for example `text-[var(--sndq-text-secondary)]` or `text-[length:var(--sndq-text-sm)]`) until a shorter utility exists.
- **Short utilities** (`text-*` from `@theme`): extend `packages/config/tailwind/tokens.css` (or a small file imported alongside it, matching the existing `@theme inline` pattern) **only for variables that shipped typography variants actually reference** in that commit. Add aliases in the **same commit** as the variant that first needs them (optional **Commit 0** theme-only is allowed if the team prefers theme before components — default is co-locate with **Commit 1** `Text` standardize).
- **Do not** map the entire semantic palette in one commit.
- **`cn`**: `packages/ui-v2/src/lib/utils.ts` mirrors `sndq-fe/packages/ui/src/lib/utils.ts` (`clsx` + `tailwind-merge`). Components use `cn(variantClasses, className)` on the root. `@sndq/ui-v2` must not import the submodule.

### Prerequisites

- Phase 2 is merged to dev (`packages/ui-v2` skeleton, `apps/ui-v2-dev`, `apps/docs`, `@sndq/config` tailwind pipeline).
- Phase 3, Batch 0 is merged to dev (Fumadocs at `/`, Primitives IA exists under `apps/docs/content/docs/primitives/`).

### Legacy deprecation mapping (Batch 1)

Apply JSDoc `@deprecated` on barrel exports only **after** the replacement exists in `@sndq/ui-v2/components`. Message pattern: `Use {Name} from @sndq/ui-v2/components instead.`

| Graduated (ui-v2) | Legacy location (sndq-fe) | Notes |
|-------------------|---------------------------|--------|
| `Text`, related types / variant helpers | `sndq-fe/src/components/briicks/text/` (and briicks barrel) | `Paragraph` / `Caption` map to `Text` variants in Phase 4; deprecate after package exports exist |
| `Heading`, related types / variant helpers | same folder / barrel | Align briicks `Heading` with ui-v2 `Heading` API |
| `Button`, `buttonVariants`, `ButtonProps`, and any co-located exports (e.g. `ComboButton`) | `sndq-fe/src/components/briicks/button/` (or barrel `briicks/button/index.ts`) | Inspect actual folder layout before Commit 17 |
| `Input` and related types | `sndq-fe/src/components/briicks/input/` | briicks may expose `InputV2` — deprecate the exported surface that maps to ui-v2 `Input` |
| `Badge` | `sndq-fe/src/components/briicks/badge/` | |
| `Select` and subcomponents | `sndq-fe/src/components/briicks/select/` | Match export names to ui-v2 Select API |
| `Dialog`, `DialogContent`, … | `sndq-fe/src/components/ui/dialog.tsx` (and barrel if any) | shadcn-style exports |
| `Sheet`, … | `sndq-fe/src/components/ui/sheet.tsx` | |

### API notes (standardization only — Phase 4 migrates call sites)

See [migration-plan.md §10](./migration-plan.md#10-api-compatibility-matrix). briicks and ui-v2 are **not** drop-in compatible; Batch 1 only stabilizes the **package** API and docs. Do not bulk-change `sndq-fe` imports in this batch.

---

## 2. Before You Start

### Standardization gate (before each “graduate” commit)

A component may graduate only when:

- [ ] Stable prop interface with JSDoc on public props
- [ ] `className` forwarding via `cn()` where applicable (`cn(variantClasses, className)` so overrides merge correctly)
- [ ] `ref` forwarding where applicable (and `asChild` if the design requires it)
- [ ] Unit tests: variants, a11y basics, keyboard interaction as relevant
- [ ] No imports from app-specific code (hooks, services, `next-intl`, `@/modules`, etc.)
- [ ] Uses `@sndq/config/tailwind` tokens / shared component CSS (no hardcoded one-off theme in the component file)
- [ ] **Typography only**: variant styles reference `semantic-tokens.css` variables; any new **`@theme`** alias for shorter utilities is added **incrementally** in the same change that introduces the variant needing it (see [Typography and `@theme` utilities (gradual)](#typography-and-theme-utilities-gradual))

### Inspect prototype tree (once)

Before **Commit 5**, list `apps/ui-v2-dev/src/components/ui-v2/` for `Text` / `Heading` and (separately) any `button/` subfolder. If `ComboButton`, `buttonVariants`, or other exports live beside `Button`, include them in the **Button** vertical slice (commits 5–6) so the briicks barrel deprecation stays truthful.

### Capture baselines

Run from monorepo root; save outputs to diff after risky commits.

```bash
# Prototype
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build 2>&1 | tee /tmp/phase3-b1-proto-build-before.txt
pnpm --filter @sndq/ui-v2-dev run lint 2>&1 | tee /tmp/phase3-b1-proto-lint-before.txt
pnpm --filter @sndq/ui-v2-dev run type-check 2>&1 | tee /tmp/phase3-b1-proto-typecheck-before.txt

# Docs
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build 2>&1 | tee /tmp/phase3-b1-docs-build-before.txt

# Package (if it has build/test scripts wired)
pnpm --filter @sndq/ui-v2 run build 2>&1 | tee /tmp/phase3-b1-pkg-build-before.txt 2>/dev/null || true

# sndq-fe (should still build; batch adds comments only until you touch more)
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase3-b1-fe-build-before.txt
```

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/phase-3-batch-1-standardize-graduate
```

---

## 3. PR 1 — Standardize, graduate, deprecate (Batch 1)

**Scope**: `Text` and `Heading` graduate first; then six primitives move from prototype to `packages/ui-v2/src/components/`, barrels and consumers in `apps/ui-v2-dev` and `apps/docs` update, MDX pages added, then one deprecation pass on `sndq-fe`.

**PR split note**: If review load is high, merge through **Commit 16** first (all moves + docs), then **Commit 17** (deprecations only) as a tiny follow-up PR.

---

### Commit 1: Standardize `Text` in prototype

**What**: Finalize props, JSDoc, `cn`/`ref`/variants, tests, and playground references for `Text` (body, caption, label-style variants as designed). Variant classes must use `semantic-tokens.css` variables; add **minimal** `@theme` aliases in `tokens.css` (or agreed import) **only** for tokens this commit introduces into variant strings.

**Files to edit** (adjust paths to match repo):

- `apps/ui-v2-dev/src/components/ui-v2/**/text*.tsx` — prop stability, a11y, `as` unions if applicable
- Colocated tests covering variants

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=text
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Text for package graduation`

**Status**:

- [ ] Standardization gate checklist satisfied for `Text`
- [ ] Tests green
- [ ] Build / lint / type-check green
- [ ] Committed

---

### Commit 2: Graduate `Text` to package + MDX + update consumers

**What**: Move `Text` into `packages/ui-v2`, export from `src/components/index.ts`, fix imports in `apps/ui-v2-dev` and `apps/docs`, add `apps/docs/content/docs/primitives/text.mdx` and `meta.json` entry **above** Button in sidebar order if applicable.

**Files to create**:

- `packages/ui-v2/src/lib/utils.ts` — same `cn` as `sndq-fe/packages/ui/src/lib/utils.ts` (if not created yet)
- `packages/ui-v2/src/components/text.tsx` (or folder per convention)
- `apps/docs/content/docs/primitives/text.mdx`

**Files to edit**:

- `packages/ui-v2/src/components/index.ts` — export `Text` (+ types)
- Consumers → `@sndq/ui-v2/components`

**Commit message**: `feat(ui-v2): graduate Text to package and document`

**Status**:

- [ ] `Text` lives in package; prototype updated
- [ ] Docs page renders
- [ ] Committed

---

### Commit 3: Standardize `Heading` in prototype

**What**: Same pattern as Commit 1 for `Heading` (levels, sizes, semantic element defaults).

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=heading
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Heading for package graduation`

**Status**:

- [ ] Gate checklist for `Heading`
- [ ] Committed

---

### Commit 4: Graduate `Heading` + MDX + consumers

**What**: Move `Heading` to `packages/ui-v2`, export, add `primitives/heading.mdx`, update `meta.json`.

**Commit message**: `feat(ui-v2): graduate Heading to package and document`

**Status**:

- [ ] Committed

---

### Commit 5: Standardize Button (+ co-located exports) in prototype

**What**: Finalize props, JSDoc, `cn`/`ref`/variants, tests, and Storybook/playground references for `Button` (and any co-located button primitives in the same directory).

**Files to edit** (adjust paths to match repo):

- `apps/ui-v2-dev/src/components/ui-v2/**/button*.tsx` — prop stability, a11y
- Colocated tests: `apps/ui-v2-dev/.../**/*.spec.tsx` or package test folder per project convention
- Storybook or dev routes under `apps/ui-v2-dev/` that demo Button

**Files to create** (if missing):

- Unit test file(s) covering variants and disabled/loading states

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Tests flaky in CI | LOW | Run tests twice locally |
| Hidden import from app | MEDIUM | `rg "@/modules\|useTranslations\|next-intl" apps/ui-v2-dev/src/components/ui-v2` on touched files |

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=button
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Button for package graduation`

**Status**:

- [ ] Standardization gate checklist satisfied for Button
- [ ] Tests green
- [ ] Build / lint / type-check green
- [ ] Committed

---

### Commit 6: Graduate Button to package + MDX + update consumers

**What**: Move Button implementation into `packages/ui-v2`, export from `src/components/index.ts`, fix imports in `apps/ui-v2-dev` and `apps/docs`, add `apps/docs/content/docs/primitives/button.mdx` (and update `meta.json` `pages` if required).

**Files to create**:

- `packages/ui-v2/src/components/button.tsx` (or folder structure matching package conventions)
- `apps/docs/content/docs/primitives/button.mdx`

**Files to edit**:

- `packages/ui-v2/src/components/index.ts` — export Button (+ variants/types)
- `packages/ui-v2/package.json` — only if new subpath exports are needed (usually not for components barrel)
- All prototype files that imported local Button → `@sndq/ui-v2/components`
- `apps/docs/content/docs/primitives/meta.json` — add `button` to `pages` array in desired order

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Duplicate React | MEDIUM | `pnpm why react` if runtime errors |
| MDX code samples wrong path | LOW | Open `/primitives/button` in docs dev |

**Verification**:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
pnpm --filter @sndq/ui-v2 run test -- --testPathPattern=button
```

**Commit message**: `feat(ui-v2): graduate Button to package and document`

**Status**:

- [ ] Button lives only in `packages/ui-v2` (prototype re-exports removed or deleted)
- [ ] Docs page renders
- [ ] Consumers updated
- [ ] Committed

---

### Commit 7: Standardize Input in prototype

**What**: Same as prior batch pattern for `Input` (label, `error` as string, `helperText`, icons as `ReactNode`, etc. per migration plan matrix).

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=input
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Input for package graduation`

**Status**:

- [ ] Gate checklist for Input
- [ ] Committed

---

### Commit 8: Graduate Input + MDX + consumers

**What**: Move to `packages/ui-v2`, export, update apps, add `primitives/input.mdx` + `meta.json`.

**Commit message**: `feat(ui-v2): graduate Input to package and document`

**Status**:

- [ ] Committed

---

### Commit 9: Standardize Badge in prototype

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=badge
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Badge for package graduation`

**Status**:

- [ ] Gate checklist for Badge
- [ ] Committed

---

### Commit 10: Graduate Badge + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Badge to package and document`

**Status**:

- [ ] Committed

---

### Commit 11: Standardize Select in prototype

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=select
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Select for package graduation`

**Status**:

- [ ] Gate checklist for Select
- [ ] Committed

---

### Commit 12: Graduate Select + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Select to package and document`

**Status**:

- [ ] Committed

---

### Commit 13: Standardize Dialog in prototype

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=dialog
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Dialog for package graduation`

**Status**:

- [ ] Gate checklist for Dialog
- [ ] Committed

---

### Commit 14: Graduate Dialog + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Dialog to package and document`

**Status**:

- [ ] Committed

---

### Commit 15: Standardize Sheet in prototype

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=sheet
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Sheet for package graduation`

**Status**:

- [ ] Gate checklist for Sheet
- [ ] Committed

---

### Commit 16: Graduate Sheet + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Sheet to package and document`

**Status**:

- [ ] Committed

---

### Commit 17: Deprecate legacy briicks/ui exports (Batch 1)

**What**: Add `/** @deprecated Use … from @sndq/ui-v2/components instead. */` above each relevant re-export in the briicks/ui barrel files listed in [Legacy deprecation mapping](#legacy-deprecation-mapping-batch-1). Do not change implementation bodies.

**Files to edit**:

- `sndq-fe/src/components/briicks/text/` (or barrel) — `Heading`, `Paragraph`, `Caption`, `Text` if re-exported
- `sndq-fe/src/components/briicks/button/index.ts` (and related)
- `sndq-fe/src/components/briicks/input/index.ts` (or equivalent)
- `sndq-fe/src/components/briicks/badge/index.ts`
- `sndq-fe/src/components/briicks/select/index.ts`
- `sndq-fe/src/components/ui/dialog.tsx`
- `sndq-fe/src/components/ui/sheet.tsx`
- Any central `briicks/index.ts` that re-exports these — prefer deprecating at the **canonical export** the app uses (avoid double warnings)

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Deprecated symbol still needed without v2 migration | LOW | Expected — Phase 4 removes usage; IDE shows strikethrough |
| Wrong import path in message | LOW | Copy exact string: `@sndq/ui-v2/components` |

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
pnpm --filter sndq-fe run lint
pnpm --filter sndq-fe run type-check
```

**Commit message**: `chore(sndq-fe): deprecate Batch 1 briicks/ui exports for ui-v2`

**Status**:

- [ ] Every mapping row has matching JSDoc on export
- [ ] `sndq-fe` still builds (no behavior change)
- [ ] Committed

---

### PR 1 Checkpoint

```bash
git push -u origin feature/phase-3-batch-1-standardize-graduate
# Open PR targeting dev; wait for CI
```

**This validates**: Workspace resolution for `@sndq/ui-v2`, docs MDX pipeline, prototype + package builds, and that deprecation comments do not break TypeScript.

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Merged (or ready for follow-up)

---

## 4. Final Verification

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
```

Optional targeted tests:

```bash
pnpm --filter @sndq/ui-v2 run test
pnpm --filter @sndq/ui-v2-dev run test
```

Compare builds to baselines (same commands as §2 with `-final` suffix).

**Expected result**: All apps and packages build; `Text`, `Heading`, and the six interactive primitives importable from `@sndq/ui-v2/components`; docs Primitives list `text`, `heading`, and Button through Sheet; legacy exports show deprecation in IDE.

**Final status**:

- [ ] All 17 commits complete
- [ ] Root build / lint / type-check pass
- [ ] Manual: docs `/primitives/...` pages render
- [ ] Manual: ui-v2-dev playground still exercises graduated components
- [ ] PR merged

---

## 5. Team Communication

> **Heads up: first `@sndq/ui-v2` component graduation (Batch 1)**
>
> PR [link] graduates **typography first** (`Text`, `Heading`), then Button, Input, Badge, Select, Dialog, and Sheet from the prototype into `packages/ui-v2/`. Typography uses `semantic-tokens.css` and incremental `@sndq/config` `@theme` aliases; see [typography-system-reference.md](./typography-system-reference.md). The main app is **not** bulk-migrated yet — you will see `@deprecated` JSDoc on legacy briicks/ui exports (including **briicks text**). New feature work should import from `@sndq/ui-v2/components` where possible.
>
> After pulling:
>
> 1. `pnpm install`
> 2. Restart TS server and ESLint server in the IDE
>
> Touch points:
> - `packages/ui-v2/src/components/*`, `packages/ui-v2/src/lib/utils.ts`
> - `packages/config/tailwind/tokens.css` (incremental `@theme` aliases)
> - `apps/ui-v2-dev/` imports
> - `apps/docs/content/docs/primitives/*`
> - `sndq-fe/src/components/briicks/{text,button,input,badge,select}/`, `sndq-fe/src/components/ui/{dialog,sheet}.tsx`

---

## 6. What's Next

After Batch 1 merges, open [phase-3-batch-2-execution.md](./phase-3-batch-2-execution.md) (Card, Tabs, Tooltip, EmptyState, Skeleton).

### Lessons to carry forward

- **Vertical slices** per component keep bisect/revert sane.
- **Deprecate only after the export exists** in the package — avoids warning fatigue.
- **Typography + gradual `@theme`** reduces token drift before scaling interactive primitives.

### Known lessons from prior phases

- See [phase-3-batch-0-execution.md §6](./phase-3-batch-0-execution.md#6-whats-next) (Fumadocs, `.source`, `meta.json` ordering, shared tsconfig lessons).

---

## 7. Execution Log

| Date | Commit | Notes |
|------|--------|-------|
|      | 1      |       |
|      | 2      |       |
|      | 3      |       |
|      | 4      |       |
|      | 5      |       |
|      | 6      |       |
|      | 7      |       |
|      | 8      |       |
|      | 9      |       |
|      | 10     |       |
|      | 11     |       |
|      | 12     |       |
|      | 13     |       |
|      | 14     |       |
|      | 15     |       |
|      | 16     |       |
|      | 17     |       |
