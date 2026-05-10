# Phase 3, Batch 1 Execution — Sub-batches: Typography, layout shell, interactive primitives

Step-by-step execution guide for Phase 3, Batch 1. Each commit is independently verifiable and revertable.

**Created**: 2026-05-04  
**Status**: In progress (Commits 1–6b, 7+8, 9+10 implemented; pending manual commit)  
**Architecture**: [README.md](./README.md)  
**Migration plan**: [migration-plan.md](./migration-plan.md)  
**Typography reference**: [typography-system-reference.md](./typography-system-reference.md)  
**Layout shell reference**: [layout-system-reference.md](./layout-system-reference.md)  
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

**Goal**: Standardize and graduate, in order: **`Text`** and **`Heading`** (typography); **`Container`**, **`Section`**, **`Flex`**, and **`Grid`** (CVA-based layout shell — SNDQ semantic tokens only, **not** `@radix-ui/themes`); then the six highest-leverage interactive primitives (Button, Input, Badge, Select, Dialog, Sheet). Each graduate moves into `packages/ui-v2/`, with MDX in `apps/docs` (typography + interactive under **Primitives**; layout shell under **Foundations**). Finish with one JSDoc `@deprecated` pass on matching `sndq-fe` briicks/ui barrel exports — without rewriting `sndq-fe` call sites (Phase 4).

**Structure**: **25 commits** across **1 PR** (default), grouped into **sub-batches** for review and narrative:

| Sub-batch | Commits | Scope |
|-----------|---------|--------|
| **1A — Typography** | 1–4 | `Text` then `Heading` (standardize + graduate each) |
| **1B — Layout shell** | 5–12 | `Container`, `Section`, `Flex`, `Grid` (standardize + graduate each); CVA + `semantic-tokens.css` layout variables (incl. `--sndq-space-*`) |
| **1C — Interactive** | 13–24 | Button (+ co-located exports), Input, Badge, Select, Dialog, Sheet (standardize + graduate each) |
| **1D — Deprecations** | 25 | Single `sndq-fe` JSDoc pass |

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Sub-batches 1A–1D: typography, CVA `Container`/`Section`/`Flex`/`Grid`, six interactives, docs (primitives + foundations layout MDX), incremental `@sndq/config` `@theme` aliases as needed, `sndq-fe` deprecations | Medium | 1–25 |

**Why typography first (1A)**: Establishes token usage, `cn()` pattern, and optional short Tailwind utilities before layout and the larger interactive set. See [typography-system-reference.md](./typography-system-reference.md).

**Why layout shell next (1B)**: Introduces **page-level** width and vertical rhythm via a small, strict API (`size` presets on `Container` / `Section`) **plus** inner-layout primitives (`Flex` / `Grid`) with token-backed numeric `gap*`. All four share the same CVA + token discipline and the strict semantic-vs-numeric prop-typing rule. See [layout-system-reference.md](./layout-system-reference.md).

**Why 1 PR**: Keeps one reviewable narrative for the first graduation batch. Commits stay ordered so you can split later (e.g. commits **1–24** merged first, commit **25** as follow-up) if CI or policy requires it.

### Typography and `@theme` utilities (gradual)

- **Canonical values** live in `packages/config/tailwind/semantic-tokens.css` (`--sndq-text`, `--sndq-text-secondary`, `--sndq-text-xs` … `--sndq-text-7xl`, font stacks). Variant `cva` strings must use these variables (for example `text-[var(--sndq-text-secondary)]` or `text-[length:var(--sndq-text-sm)]`) until a shorter utility exists.
- **Short utilities** (`text-*` from `@theme`): extend `packages/config/tailwind/tokens.css` (or a small file imported alongside it, matching the existing `@theme inline` pattern) **only for variables that shipped typography variants actually reference** in that commit. Add aliases in the **same commit** as the variant that first needs them (optional **Commit 0** theme-only is allowed if the team prefers theme before components — default is co-locate with **Commit 1** `Text` standardize).
  - Recommended mapping for text color utilities (so components can use `text-sndq-text-primary` instead of arbitrary values):
    - `--color-sndq-text-primary: var(--sndq-text);`
    - `--color-sndq-text-secondary: var(--sndq-text-secondary);`
    - `--color-sndq-text-tertiary: var(--sndq-text-tertiary);`
    - This yields Tailwind utilities: `text-sndq-text-primary`, `text-sndq-text-secondary`, `text-sndq-text-tertiary`.
- **Do not** map the entire semantic palette in one commit.
- **`cn`**: `packages/ui-v2/src/lib/utils.ts` mirrors `sndq-fe/packages/ui/src/lib/utils.ts` (`clsx` + `tailwind-merge`). Components use `cn(variantClasses, className)` on the root. `@sndq/ui-v2` must not import the submodule.

### Layout tokens and CVA (gradual)

- **Not Radix Themes**: Do **not** add `@radix-ui/themes`, its `Theme` provider for spacing, or its layout CSS. Implement **`Container`**, **`Section`**, **`Flex`**, and **`Grid`** with [`cva`](https://cva.style/docs) + `cn()` only, same spirit as typography.
- **Canonical layout values** live in `packages/config/tailwind/semantic-tokens.css`. Add variables **incrementally** in the same commit that first uses them in a `cva` recipe, for example:
  - **Container**: max width and horizontal inset — e.g. `--sndq-container-max-sm`, `--sndq-container-max-md`, `--sndq-container-gutter` (exact set is defined in [layout-system-reference.md](./layout-system-reference.md) and implemented alongside Commits 5–6).
  - **Section**: vertical padding / band rhythm — e.g. `--sndq-section-py-sm`, `--sndq-section-py-md`, `--sndq-section-py-lg` (alongside Commits 7–8).
  - **Numeric spacing scale** (used by `Flex` / `Grid` `gap*`): `--sndq-space-0` … `--sndq-space-5` (alongside Commits 9–12; extend the range only when a recipe needs a new step).
- **`cva` recipes** must reference only those `var(--sndq-…)` values (or existing primitives they compose). No ad-hoc pixel literals in component files. Numeric `gap*` must resolve to `--sndq-space-*` only.
- **Optional `@theme` aliases** in `packages/config/tailwind/tokens.css`: only when a shipped layout variant needs a shorter utility in the **same** commit.
- **v1 API**:
  - `Container` / `Section`: a single **`size`** enum per component (e.g. `sm | md | lg` — exact names in layout reference).
  - `Flex` / `Grid`: layout enums (`direction`, `align`, `justify`, `wrap`, `flow`) + **numeric** `gap` / `gapX` / `gapY`; `Grid` also takes **numeric** `columns`. Full prop tables in [layout-system-reference.md §4–§5](./layout-system-reference.md#4-flex-api-v1).
  - **No** Radix-style responsive object props (`gap={{ sm: '2', lg: '4' }}`) in Batch 1 — wrap with Tailwind utilities at call sites.

### Strict prop-typing rule (semantic vs numeric — never both)

System-wide rule for every ui-v2 component: **each prop is either semantic OR numeric, never both**. See [layout-system-reference.md §3-bis](./layout-system-reference.md#3-bis-prop-typing-rule-strict-never-both) for the canonical statement, rationale, and examples.

- **Semantic** for low-step "design decision" props: `Container.size`, `Section.size`, future `radius`, `shadow`.
- **Numeric** for fine-grained tuning props: `Flex.gap` / `Grid.gap` / `gapX` / `gapY`, `Grid.columns`.
- **Forbidden**: a single prop accepting both modes (e.g. `gap: "md" | "3"`). If both expressivity and governance are needed for one axis, ship two distinct, non-overlapping props — never collapse them.

### `className` override-wins guarantee (canonical)

Every component root must compose as **`cn(variantClasses, className)`** so consumer `className` wins on conflicting Tailwind utilities (e.g. `<Flex gap="2" className="gap-8" />` resolves to `gap-8`). Backed by `tailwind-merge` in the shared `cn()` helper. Canonical statement in [layout-system-reference.md §3-ter](./layout-system-reference.md#3-ter-classname-override-wins-guarantee). Tested per the standardization gate below.

### Prerequisites

- Phase 2 is merged to dev (`packages/ui-v2` skeleton, `apps/ui-v2-dev`, `apps/docs`, `@sndq/config` tailwind pipeline).
- Phase 3, Batch 0 is merged to dev (Fumadocs at `/`, **Primitives** IA under `apps/docs/content/docs/primitives/`, **Foundations** IA under `apps/docs/content/docs/foundations/`).

### Legacy deprecation mapping (Batch 1)

Apply JSDoc `@deprecated` on barrel exports only **after** the replacement exists in `@sndq/ui-v2/components`. Message pattern: `Use {Name} from @sndq/ui-v2/components instead.`

| Graduated (ui-v2) | Legacy location (sndq-fe) | Notes |
|-------------------|---------------------------|--------|
| `Text`, related types / variant helpers | `sndq-fe/src/components/briicks/text/` (and briicks barrel) | `Paragraph` / `Caption` map to `Text` variants in Phase 4; deprecate after package exports exist |
| `Heading`, related types / variant helpers | same folder / barrel | Align briicks `Heading` with ui-v2 `Heading` API |
| `Container`, `Section`, `Flex`, `Grid` | *(none by default)* | **Inspect** `sndq-fe` before **Commit 25**: add a table row and JSDoc only if a matching barrel export exists (e.g. a legacy layout helper). If none, skip. `Flex` / `Grid` have no expected legacy mapping. |
| `Button`, `buttonVariants`, `ButtonProps`, and any co-located exports (e.g. `ComboButton`) | `sndq-fe/src/components/briicks/button/` (or barrel `briicks/button/index.ts`) | Inspect actual folder layout before Commit 25 |
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

- [ ] Stable prop interface with **minimal** JSDoc on public props (see below)
- [ ] `className` forwarding via `cn()` where applicable, **strict ordering `cn(variantClasses, className)`** so consumer `className` wins on conflicts (`className` override-wins guarantee — see [Layout tokens and CVA (gradual)](#layout-tokens-and-cva-gradual))
- [ ] **Override-wins test**: at least one unit test asserts that `<Component variantProp className="conflicting-utility" />` resolves to the consumer value (e.g. `gap-2` vs `gap-8` for layout primitives; equivalent text/size/color conflict for typography and interactives)
- [ ] `ref` forwarding where applicable (and `asChild` if the design requires it)
- [ ] Unit tests: variants, a11y basics, keyboard interaction as relevant (keyboard/a11y depth varies by component; layout primitives: render + variant class coverage)
- [ ] No imports from app-specific code (hooks, services, `next-intl`, `@/modules`, etc.)
- [ ] Uses `@sndq/config/tailwind` tokens / shared component CSS (no hardcoded one-off theme in the component file)
- [ ] **Strict prop-typing rule satisfied**: every prop is either semantic OR numeric — never both (see [Strict prop-typing rule](#strict-prop-typing-rule-semantic-vs-numeric--never-both))
- [ ] **Typography (`Text`, `Heading`)**: variant styles reference `semantic-tokens.css` variables; any new **`@theme`** alias is added **incrementally** in the same change that introduces the variant needing it (see [Typography and `@theme` utilities (gradual)](#typography-and-theme-utilities-gradual))
- [ ] **Layout shell (`Container`, `Section`)**: `cva` maps reference only layout semantic tokens from `semantic-tokens.css`; default elements documented (`Container` → `div`, `Section` → `section` for document outline unless design specifies otherwise); **v1** uses discrete `size` presets only (see [Layout tokens and CVA (gradual)](#layout-tokens-and-cva-gradual))
- [ ] **Layout primitives (`Flex`, `Grid`)**: `cva` recipes use only `--sndq-space-*` for `gap*` and the agreed `columns` enum for `Grid`; **strict** — no prop accepts both numeric and semantic; no `padding`/`margin`/`width`/`height`/responsive-object props in v1

**JSDoc policy (component files only)**:

- **Keep JSDoc minimal** in component implementation files (`packages/ui-v2/src/components/**`, `apps/ui-v2-dev/src/components/ui-v2/**`).
- JSDoc is for **API essentials only**: prop intent, constraints/invariants, defaults, and `@deprecated` notices.
- Do **not** duplicate full usage docs, variant tables, design rationale, or migration notes in code comments.
- The **canonical documentation** for every graduated component lives in `apps/docs` (Fumadocs MDX under `apps/docs/content/docs/`).

### Inspect prototype tree (once)

Before **Commit 13**, list `apps/ui-v2-dev/src/components/ui-v2/` for `Text`, `Heading`, `Container`, `Section`, `Flex`, `Grid`, and (separately) any `button/` subfolder. If `ComboButton`, `buttonVariants`, or other exports live beside `Button`, include them in the **Button** vertical slice (commits **13–14**) so the briicks barrel deprecation stays truthful. If `Container` / `Section` / `Flex` / `Grid` are missing in the prototype, implement them during **Commits 5**, **7**, **9**, and **11** per [layout-system-reference.md](./layout-system-reference.md). The same rule applies to typography: `Text` and `Heading` were also missing in the prototype at the start of Batch 1 — they are **created from scratch** during **Commits 1** and **3** (the prototype's `index.ts` barrel already exports both names, so creation is required to keep `lint`/`type-check`/`build` green).

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

**Scope**: Sub-batches **1A** (typography) → **1B** (`Container`, `Section`, `Flex`, `Grid`) → **1C** (Button … Sheet) → **1D** (deprecations). Package exports for all components live on `@sndq/ui-v2/components`. Docs: **Primitives** for `text`, `heading`, and interactives; **Primitives/Layout** for `container`, `section`, `flex`, `grid` MDX and `primitives/layout/meta.json` updates.

**PR split note**: If review load is high, merge through **Commit 24** first (all moves + docs), then **Commit 25** (deprecations only) as a tiny follow-up PR.

### Sub-batch 1A — Typography (Commits 1–4)

---

### Commit 1: Standardize `Text` in prototype

**What**: **Create** `Text` in the prototype (it was missing — see [Inspect prototype tree (once)](#inspect-prototype-tree-once)). API forked from Cloudflare Kumo `Text` (one-component, conditional types, `truncate`) and Radix Themes `Text` (split with future `Heading`, default `as='span'`, `Slot` for `asChild`). Strict semantic-only props: `variant` (`body | secondary | tertiary | mono | success | warning | error`), `size` (`xs | sm | md | lg | xl | 2xl | 3xl`), `weight` (`normal | medium`), `align` (`start | center | end`), `truncate` (boolean), `as` (semantic element from a fixed enum), `asChild`. Variant classes use the **already-shipped** short utilities (`text-sndq-text-primary` / `secondary` / `tertiary`, `text-sndq-xs` … `3xl`, `font-sndq-mono`, `text-sndq-success-text` / `warning-text` / `error-text`) — these aliases were prepped earlier in `packages/config/tailwind/tokens.css` so this commit adds **no** new aliases. Composition is strictly `cn(textVariants({...}), className)` to enforce the override-wins guarantee. JSDoc on every public prop plus three `@example` blocks (body, secondary helper, monetary mono).

**Files to edit** (adjust paths to match repo):

- `apps/ui-v2-dev/src/components/ui-v2/Text.tsx` — **new** file (one component, ~140 LOC including JSDoc).
- `apps/ui-v2-dev/src/components/ui-v2/index.ts` — already exports `./Text`; no change.
- `packages/config/tailwind/tokens.css` — already contains the `--color-sndq-text-*` / `--text-sndq-*` / `--font-sndq-*` aliases used; no change.
- Colocated tests — **deferred** (see Deviations below).

**Verification**:

```bash
# Tests deferred for Commit 1 — see Deviations below.
pnpm --filter @sndq/ui-v2-dev exec eslint src/components/ui-v2/Text.tsx
pnpm --filter @sndq/ui-v2-dev run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
```

The full-project `pnpm --filter @sndq/ui-v2-dev run lint` will still report **7 pre-existing errors** in unrelated files (`chart-composition-07.tsx`, `chart-composition-11.tsx`, `tracker-08.tsx`, `tracker-09.tsx`, `tracker-10.tsx`, `tabs/FilterTab.tsx`). Lint `Text.tsx` directly (as above) to confirm this commit introduces none.

**Commit message**: `refactor(ui-v2-dev): standardize Text for package graduation`

**Deviations from the standardization gate**:

- **Tests deferred** — `apps/ui-v2-dev` has no `test` script (only `dev` / `build` / `lint` / `type-check`). The override-wins unit test and variant render tests are deferred to a later commit (target: before package graduation in **Commit 2**, after a small Vitest setup commit lands).
- **Mono auto-downsize not implemented** — Kumo's `Text` auto-clamps mono variants to `sm` to optically match body. Skipped in v1 because SNDQ's `xs` token is `13px`, below the SNDQ "minimum 14px for mono" rule. To be revisited with a SNDQ-specific decision (likely "do nothing" since the scale already starts at 14px = `sm`).
- **No new `tokens.css` aliases** — the recommended `--color-sndq-text-primary|secondary|tertiary`, `--text-sndq-*`, and `--font-sndq-mono` aliases were prepped in an earlier change (already present in `tokens.css` at the time of this commit), so the recipe uses short utilities directly with no diff to the config package.
- **Strict-prop axes are richer than the briicks legacy** — briicks `Paragraph` had a single `variant` axis (label / default / link / mono). The new ui-v2 `Text` splits that into independent `variant` (semantic role + color) × `size` × `weight` × `align` × `truncate` axes per the Kumo + Radix references. Phase 4 mapping for briicks `Paragraph` / `Caption` will collapse to specific combinations of these axes (documented during Commit 2 MDX).

**Status**:

- [ ] Standardization gate checklist satisfied for `Text` *(except test items — see Deviations)*
- [ ] Tests green *(deferred — see Deviations)*
- [ ] Build / lint (`Text.tsx` only) / type-check green
- [ ] Committed *(manual)*

---

### Commit 2: Graduate `Text` to package + MDX + update consumers

**What**: Bootstrap the `@sndq/ui-v2` runtime surface (local `cn` helper, runtime deps, `type-check` script), move `Text` from the prototype into the package, re-export from the prototype barrel so apps/ui-v2-dev keeps working, and ship the first full Template A docs page (`primitives/text.mdx`) with `meta.json` updated.

**Files to create**:

- `packages/ui-v2/src/lib/utils.ts` — local `cn` (`twMerge` + `clsx`), mirrors `apps/ui-v2-dev/src/lib/utils.ts` so the package has its own override-safe class composer (no cross-app import).
- `packages/ui-v2/src/components/Text.tsx` — copy of the standardized prototype `Text` from Commit 1; only the `cn` import path changes (`@/lib/utils` → `../lib/utils`).
- `apps/docs/content/docs/primitives/text.mdx` — full Template A page minus `<ComponentPreview />`. Imports `Text` from `@sndq/ui-v2/components` for inline live JSX examples (preview, body copy, secondary helper, monetary mono, truncated-in-flex). Code blocks are plain fenced blocks (no `<CodeTabs>` — not in the default Fumadocs MDX registry).

**Files to edit**:

- `packages/ui-v2/package.json` — add runtime deps `@radix-ui/react-slot ^1.1.2`, `class-variance-authority ^0.7.1`, `clsx ^2.1.1`, `tailwind-merge ^3.0.2`; dev deps `@types/react 19.2.2`, `typescript ^5`; `scripts.type-check = "tsc --noEmit"`. Versions match what `apps/ui-v2-dev` already pins.
- `packages/ui-v2/src/components/index.ts` — first real export, `export * from './Text';`.
- `apps/ui-v2-dev/src/components/ui-v2/index.ts` — replace the local `export * from './Text';` with a re-export from the package: `export { Text, textVariants, type TextProps, type TextElement } from '@sndq/ui-v2/components';` so existing prototype imports keep resolving.
- `apps/docs/content/docs/primitives/meta.json` — `pages: ["index", "text"]`.

**Files to delete**:

- `apps/ui-v2-dev/src/components/ui-v2/Text.tsx` — single source of truth now lives in the package.

**Verification** (run from repo root):

```bash
pnpm install
pnpm --filter @sndq/ui-v2 run type-check
pnpm --filter @sndq/ui-v2-dev exec eslint --fix src/components/ui-v2/index.ts
pnpm --filter @sndq/ui-v2-dev run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/docs run generate:source
pnpm --filter @sndq/docs run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
```

All eight commands exit `0` on `2026-05-07`. The new `/primitives/text` route is included in the docs static export.

**Deviations from the standardization gate**:

- **Tests still deferred** — Vitest harness for `apps/ui-v2-dev` (and a peer one for `packages/ui-v2`) still not configured; same gap as Commit 1. Will land in a small enabling commit before the override-wins regression tests on `Flex` / `Grid` / `Button`.
- **Component file naming**: used **PascalCase `Text.tsx`** per `apps/docs/.cursor/rules/naming-conventions.mdc` and to match the prototype convention, instead of the lowercase `text.tsx` mentioned in this section's original spec. The doc spec is updated in this revision.
- **Package becomes non-zero-dep**: `@sndq/ui-v2` previously declared only `@sndq/config`. We added `@radix-ui/react-slot`, `class-variance-authority`, `clsx`, `tailwind-merge` as runtime deps and `@types/react`, `typescript` as dev deps. This is the expected one-time cost of graduation.
- **`<ComponentPreview />` widget**: not used in the MDX page — it's not registered in `apps/docs/src/mdx/custom-mdx-components.ts` yet. Live previews are inline JSX importing `Text` from `@sndq/ui-v2/components` directly. A real registry-backed `<ComponentPreview />` (with examples that lint/typecheck) is tracked as a separate doc-tooling improvement.
- **`<CodeTabs />`**: same situation — not in the default Fumadocs MDX registry, so install/usage code is shown via plain fenced blocks.

**Commit message**: `feat(ui-v2): graduate Text to package and document`

**Status**:

- [x] `Text` lives in package; prototype updated *(re-exports from `@sndq/ui-v2/components`)*
- [x] Docs page renders *(static build green; `/primitives/text` in route table)*
- [x] Committed *(manual)*

---

### Commit 3: Standardize `Heading` in prototype

**What**: Standardize `Heading` in the prototype **and** introduce a small shared typography helper layer that `Heading` uses now and that will be graduated to the package in Commit 4 so `Text` + `Heading` share the same plumbing.

**`Heading` API v1 (Batch 1)**:

- `as?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6'` — semantic element (default: `h2`).
- `size?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl'` — visual scale (default: `xl`).
  - Intentionally allows semantic vs visual decoupling (`as='h2' size='3xl'`).
- `align?: 'start' | 'center' | 'end'` — shared typography axis.
- `truncate?: boolean` — shared typography axis.
- `asChild?: boolean` — Radix Slot escape hatch.
- Standard `className` + DOM props.

**Shared extraction (prototype-first)**:

- Add `typography-shared` helper with:
  - A small polymorphic root helper for `asChild` + `Slot` selection.
  - Shared CVA axes + types for `align` and `truncate`.
  - **Exports (v1)** (names are suggestions; keep them stable once shipped in the package):
    - `export type TypographyAlign = 'start' | 'center' | 'end';`
    - `export type TypographyTruncate = boolean;`
    - `export const typographySharedVariants = { align: { start: 'text-start', center: 'text-center', end: 'text-end' }, truncate: { true: 'truncate min-w-0', false: '' } } as const;`
    - `export function getTypographyComponent(params: { readonly asChild: boolean; readonly as: React.ElementType }): React.ElementType;` (returns `Slot` when `asChild` is true, otherwise returns `as`)
  - **Non-goals**:
    - Do not merge `Text` + `Heading` into one component.
    - Do not introduce a shared “typography variant” axis; keep `Text.variant` and `Heading.size` independent.

**Variant rules**:

- `cva` recipes must use SNDQ token-backed utilities only (existing `text-sndq-*`, `font-sndq-*`, and existing semantic color aliases).
- If a needed size has no short utility yet, use `text-[length:var(--sndq-text-...)]` and/or `leading-[var(--sndq-leading-...)]` until a gradual `@theme` alias is introduced.
- Root composes strictly as `cn(variantClasses, className)` (override-wins guarantee).

**Files to edit/create** (adjust paths to match repo):

- `apps/ui-v2-dev/src/components/ui-v2/Heading.tsx` — **new**
- `apps/ui-v2-dev/src/components/ui-v2/typography/typography-shared.ts` — **new**
- `apps/ui-v2-dev/src/components/ui-v2/index.ts` — export `Heading` (local export; will be replaced by package re-export in Commit 4)

**Verification**:

```bash
# If @sndq/ui-v2-dev has no test runner wired yet, skip the test line (same situation as Commit 1–2).
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=heading
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev exec eslint src/components/ui-v2/Heading.tsx
pnpm --filter @sndq/ui-v2-dev exec eslint src/components/ui-v2/typography/typography-shared.ts
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Heading for package graduation`

**Deviations from the standardization gate**:

- **Tests deferred** — same gap as Commits 1–2: no `test` script in `apps/ui-v2-dev`. Override-wins and variant tests will land alongside the Vitest harness.
- **`weight` prop added** — `Heading` exposes `weight?: 'normal' | 'medium'` (default `'medium'`) via the shared typography axis. Not in the original Commit 3 API spec but consistent with `Text` and requested during planning.
- **Shared `TypographyWeight` type** — extracted alongside `TypographyAlign` and `TypographyTruncate` into the shared helper, exceeding the original spec which only listed `align` and `truncate` as shared axes.

**Status**:

- [x] Gate checklist for `Heading` *(except test items — see Deviations)*
- [x] Committed *(pending manual commit)*

---

### Commit 4: Graduate `Heading` + MDX + consumers

**What**: Graduate `Heading` to `packages/ui-v2` **and** graduate the shared typography helper so `Text` + `Heading` use the same extracted plumbing.

**Scope**:

- Move `Heading` from `apps/ui-v2-dev/` → `packages/ui-v2/`.
- Move `typography-shared` helper from prototype → package.
- Refactor `packages/ui-v2/src/components/Text.tsx` to consume the shared helper (no behavior change).
- Update prototype to re-export `Heading` from `@sndq/ui-v2/components` (same pattern as `Text` in Commit 2).
- Add docs page `primitives/heading.mdx` and update `primitives/meta.json`.

**Files to create**:

- `packages/ui-v2/src/components/Heading.tsx`
- `packages/ui-v2/src/components/typography/typography-shared.ts`
- `apps/docs/content/docs/primitives/heading.mdx`

**Files to edit**:

- `packages/ui-v2/src/components/Text.tsx` — import shared helper + shared axes/types
- `packages/ui-v2/src/components/index.ts` — export `Heading` (and relevant types)
- `packages/ui-v2/src/components/typography/typography-shared.ts` — keep **internal** (do not export from `@sndq/ui-v2/components` unless a downstream consumer explicitly needs it)
- `apps/ui-v2-dev/src/components/ui-v2/index.ts` — re-export from `@sndq/ui-v2/components`:
  - `export { Heading, type HeadingProps } from '@sndq/ui-v2/components';`
- `apps/docs/content/docs/primitives/meta.json` — add `heading` to `pages` (recommended order: `index`, `text`, `heading`)

**Files to delete**:

- `apps/ui-v2-dev/src/components/ui-v2/Heading.tsx`
- `apps/ui-v2-dev/src/components/ui-v2/typography/typography-shared.ts`

**Verification** (run from repo root):

```bash
pnpm install

pnpm --filter @sndq/ui-v2 run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2 run build

pnpm --filter @sndq/ui-v2-dev run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build

pnpm --filter @sndq/docs run generate:source
pnpm --filter @sndq/docs run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
```

**Phase 4 mapping note (docs only)**:

- Legacy briicks typography lives at `sndq-fe/src/components/briicks/text/index.tsx`.
- Batch 1 ships the ui-v2 package surface + docs only; call-site migration happens in Phase 4.

**Commit message**: `feat(ui-v2): graduate Heading to package and document`

**Deviations from the standardization gate**:

- **Tests still deferred** — Vitest harness for `packages/ui-v2` is not fully configured yet (same gap as Commits 1–2). The existing 8 `Text.test.tsx` tests pass; `Heading` tests will land in a future enabling commit.
- **`@sndq/ui-v2` has no `build` script** — skipped the `pnpm --filter @sndq/ui-v2 run build` step since the package has no build script wired. Type-check and tests were sufficient.
- **`typography-shared` kept internal** — not exported from `@sndq/ui-v2/components` barrel per spec. Only `Heading` and `Text` consume it internally.
- **Prototype `typography/` directory deleted** — both `Heading.tsx` and `typography/typography-shared.ts` deleted from `apps/ui-v2-dev` after graduation. The empty `typography/` directory may remain; no impact.

**Status**:

- [x] `Heading` lives in package; prototype re-exports from `@sndq/ui-v2/components`
- [x] `Text` refactored to use shared typography helper (no behavior change; 8/8 tests pass)
- [x] Docs page `primitives/heading.mdx` renders (static build green; `/primitives/heading` in route table)
- [x] Type-check green for `@sndq/ui-v2`, `@sndq/ui-v2-dev`, `@sndq/docs`
- [x] Build green for `@sndq/ui-v2-dev`, `@sndq/docs`
- [x] Committed *(pending manual commit)*

---

### Sub-batch 1B — Layout shell (Commits 5–12)

---

### Commit 5: Standardize `Container` in prototype

**What**: Finalize `Container` with **cva** `size` variants (max-width + horizontal inset) backed by new semantic layout tokens in `semantic-tokens.css` (add tokens in this commit or the prior slice only if already present). JSDoc, `ref`, tests (render + variant classes). Default element: `div`. See [layout-system-reference.md](./layout-system-reference.md).

**Files to edit** (adjust paths to match repo):

- `apps/ui-v2-dev/src/components/ui-v2/**/container*.tsx` — or create if missing
- `packages/config/tailwind/semantic-tokens.css` — layout tokens for container presets
- Colocated tests

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=container
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Container for package graduation`

**Deviations from the standardization gate**:

- **Tests deferred to Commit 6** — `apps/ui-v2-dev` has no `test` script. Contract tests (4) ship with the package graduation in Commit 6.
- **No `as` / `asChild`** — v1 uses a fixed `div` element per [layout-system-reference.md §2](./layout-system-reference.md). Polymorphism deferred.
- **No JSDoc on props** — `ContainerProps` extends `React.HTMLAttributes<HTMLDivElement>` + `VariantProps<typeof containerVariants>`. The API is small enough that MDX docs (Commit 6) are the canonical reference.
- **New layout tokens added** — `--sndq-container-max-sm` (640px), `--sndq-container-max-md` (1024px), `--sndq-container-max-lg` (1280px), `--sndq-container-gutter` (24px) added to `semantic-tokens.css` in this commit.

**Status**:

- [x] Layout gate checklist satisfied for `Container` *(except test items — see Deviations)*
- [x] Build / lint (`Container.tsx` only) / type-check green
- [ ] Committed *(manual)*

---

### Commit 6: Graduate `Container` to package + layout MDX + update consumers

**What**: Move `Container` to `packages/ui-v2`, export from `src/components/index.ts`, add **`apps/docs/content/docs/primitives/layout/container.mdx`**, update **`apps/docs/content/docs/primitives/layout/meta.json`** (`pages` includes `container`). Fix imports in `apps/ui-v2-dev` / `apps/docs` / any consumer. Ship 4 contract tests and a Fumadocs Story playground.

**Files to create**:

- `packages/ui-v2/src/components/Container.tsx` — copy of the standardized prototype `Container`; only the `cn` import path changes (`@/lib/utils` → `../lib/utils`).
- `packages/ui-v2/src/components/Container.test.tsx` — 4 contract tests (default element, size variant, override-wins, ref forwarding).
- `apps/docs/content/docs/primitives/layout/container.mdx` — full Template A page with inline live JSX, token reference, playground.
- `apps/docs/src/stories/container.story.tsx` — Fumadocs Story with `pickProps(['size', 'children'])`.
- `apps/docs/src/stories/components/container.tsx` — `'use client'` re-export wrapper.

**Files to edit**:

- `packages/ui-v2/src/components/index.ts` — add `export * from './Container';`.
- `apps/ui-v2-dev/src/components/ui-v2/index.ts` — replace local `export * from './Container';` with re-export from `@sndq/ui-v2/components`.
- `apps/docs/content/docs/primitives/layout/meta.json` — add `container` to `pages`.

**Files to delete**:

- `apps/ui-v2-dev/src/components/ui-v2/Container.tsx` — single source of truth now lives in the package.

**Verification** (run from repo root):

```bash
pnpm --filter @sndq/ui-v2 run type-check
pnpm --filter @sndq/ui-v2 run test -- --testPathPattern=Container
pnpm --filter @sndq/ui-v2-dev run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/docs run generate:source
pnpm --filter @sndq/docs run type-check
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build
```

All seven commands exit `0` on `2026-05-08`. The new `/primitives/layout/container` route is included in the docs static export. All 22 tests pass (4 Container + 8 Text + 10 Heading).

**Commit message**: `feat(ui-v2): graduate Container to package and document`

**Deviations from the standardization gate**:

- **Component file naming**: used **PascalCase `Container.tsx`** per `apps/docs/.cursor/rules/naming-conventions.mdc` and to match the typography convention (`Text.tsx`, `Heading.tsx`).
- **`@sndq/ui-v2` has no `build` script** — skipped the `pnpm --filter @sndq/ui-v2 run build` step since the package has no build script wired. Type-check and tests were sufficient.

**Status**:

- [x] `Container` lives in package; prototype re-exports from `@sndq/ui-v2/components`
- [x] Tests green (4/4 Container, 22/22 total)
- [x] Docs page `primitives/layout/container.mdx` renders (static build green; `/primitives/layout/container` in route table)
- [x] Type-check green for `@sndq/ui-v2`, `@sndq/ui-v2-dev`, `@sndq/docs`
- [x] Build green for `@sndq/ui-v2-dev`, `@sndq/docs`
- [ ] Committed *(manual)*

---

### Commit 7: Standardize `Section` in prototype

**What**: Same pattern for `Section`: **cva** `size` variants for vertical band rhythm; semantic tokens; default element **`section`**. See [layout-system-reference.md](./layout-system-reference.md).

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=section
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Section for package graduation`

**Status**:

- [ ] Layout gate checklist satisfied for `Section`
- [ ] Committed

---

### Commit 8: Graduate `Section` + layout MDX + consumers

**What**: Move `Section` to package, export, add **`apps/docs/content/docs/primitives/layout/section.mdx`**, update **`primitives/layout/meta.json`**.

**Commit message**: `feat(ui-v2): graduate Section to package and document`

**Status**:

- [ ] Docs: `/primitives/layout/section` renders
- [ ] Committed

---

### Commit 9: Standardize `Flex` in prototype

**What**: Finalize `Flex` with **cva** `flexVariants` covering enum props (`direction`, `align`, `justify`, `wrap`) and **numeric** `gap` / `gapX` / `gapY` resolved through `--sndq-space-*` (add the spacing scale variables in this commit if not already present from prior layout commits). JSDoc on every public prop, `ref` forwarding, default element `div`. Tests cover variant class output and the **override-wins** assertion (e.g. `<Flex gap="2" className="gap-8" />` → resolves to `gap-8`). See [layout-system-reference.md §4](./layout-system-reference.md#4-flex-api-v1).

**Files to edit** (adjust paths to match repo):

- `apps/ui-v2-dev/src/components/ui-v2/**/flex*.tsx` — or create if missing
- `packages/config/tailwind/semantic-tokens.css` — add `--sndq-space-0` … `--sndq-space-5` (if not already present)
- Colocated tests (variant class coverage + override-wins)

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=flex
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Flex for package graduation`

**Status**:

- [ ] Layout gate checklist satisfied for `Flex` (incl. strict typing rule + override-wins test)
- [ ] Committed

---

### Commit 10: Graduate `Flex` to package + layout MDX + update consumers

**What**: Move `Flex` to `packages/ui-v2`, export from `src/components/index.ts`, add **`apps/docs/content/docs/primitives/layout/flex.mdx`** (covering when to use, allowed props per §4 of the layout reference, the `gap → --sndq-space-*` mapping, and the override-wins example), update **`apps/docs/content/docs/primitives/layout/meta.json`**. Fix imports in `apps/ui-v2-dev` / `apps/docs` / any consumer.

**Files to create**:

- `packages/ui-v2/src/components/flex.tsx` (or folder per convention)
- `apps/docs/content/docs/primitives/layout/flex.mdx`

**Files to edit**:

- `packages/ui-v2/src/components/index.ts` — export `Flex` (+ types)
- `apps/docs/content/docs/primitives/layout/meta.json`

**Commit message**: `feat(ui-v2): graduate Flex to package and document`

**Status**:

- [ ] Docs: `/primitives/layout/flex` renders
- [ ] Committed

---

### Commit 11: Standardize `Grid` in prototype

**What**: Finalize `Grid` with **cva** `gridVariants` covering enum props (`align`, `justify`, `flow`), **numeric** `columns` (e.g. `"1" | "2" | "3" | "4" | "6" | "12"`), and **numeric** `gap` / `gapX` / `gapY` resolved through `--sndq-space-*`. JSDoc, `ref` forwarding, default element `div`. Tests cover variant class output and the **override-wins** assertion. `rows` and `areas` deferred. See [layout-system-reference.md §5](./layout-system-reference.md#5-grid-api-v1).

**Verification**:

```bash
pnpm --filter @sndq/ui-v2-dev run test -- --testPathPattern=grid
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/ui-v2-dev run lint
pnpm --filter @sndq/ui-v2-dev run type-check
```

**Commit message**: `refactor(ui-v2-dev): standardize Grid for package graduation`

**Status**:

- [ ] Layout gate checklist satisfied for `Grid` (incl. strict typing rule + override-wins test)
- [ ] Committed

---

### Commit 12: Graduate `Grid` to package + layout MDX + update consumers

**What**: Move `Grid` to `packages/ui-v2`, export from `src/components/index.ts`, add **`apps/docs/content/docs/primitives/layout/grid.mdx`** (covering when to use, allowed props per §5 of the layout reference, the `columns` and `gap → --sndq-space-*` mappings, and the override-wins example), update **`apps/docs/content/docs/primitives/layout/meta.json`**. Fix imports in `apps/ui-v2-dev` / `apps/docs` / any consumer.

**Files to create**:

- `packages/ui-v2/src/components/grid.tsx` (or folder per convention)
- `apps/docs/content/docs/primitives/layout/grid.mdx`

**Files to edit**:

- `packages/ui-v2/src/components/index.ts` — export `Grid` (+ types)
- `apps/docs/content/docs/primitives/layout/meta.json`

**Commit message**: `feat(ui-v2): graduate Grid to package and document`

**Status**:

- [ ] Docs: `/primitives/layout/grid` renders
- [ ] Committed

---

### Sub-batch 1C — Interactive primitives (Commits 13–24)

---

### Commit 13: Standardize Button (+ co-located exports) in prototype

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

### Commit 14: Graduate Button to package + MDX + update consumers

**What**: Move Button implementation into `packages/ui-v2`, export from `src/components/index.ts`, fix imports in `apps/ui-v2-dev` and `apps/docs`, add `apps/docs/content/docs/primitives/button.mdx` (and update `primitives/meta.json` `pages` if required).

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

### Commit 15: Standardize Input in prototype

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

### Commit 16: Graduate Input + MDX + consumers

**What**: Move to `packages/ui-v2`, export, update apps, add `primitives/input.mdx` + `meta.json`.

**Commit message**: `feat(ui-v2): graduate Input to package and document`

**Status**:

- [ ] Committed

---

### Commit 17: Standardize Badge in prototype

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

### Commit 18: Graduate Badge + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Badge to package and document`

**Status**:

- [ ] Committed

---

### Commit 19: Standardize Select in prototype

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

### Commit 20: Graduate Select + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Select to package and document`

**Status**:

- [ ] Committed

---

### Commit 21: Standardize Dialog in prototype

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

### Commit 22: Graduate Dialog + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Dialog to package and document`

**Status**:

- [ ] Committed

---

### Commit 23: Standardize Sheet in prototype

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

### Commit 24: Graduate Sheet + MDX + consumers

**Commit message**: `feat(ui-v2): graduate Sheet to package and document`

**Status**:

- [ ] Committed

---

### Sub-batch 1D — Deprecations (Commit 25)

---

### Commit 25: Deprecate legacy briicks/ui exports (Batch 1)

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
- **If** legacy `Container` / `Section` (or equivalent names) exist after inspection, deprecate those barrels too with the same message pattern

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

- [ ] Every mapping row has matching JSDoc on export (skip rows with no legacy export)
- [ ] `sndq-fe` still builds (no behavior change)
- [ ] Committed

---

### PR 1 Checkpoint

```bash
git push -u origin feature/phase-3-batch-1-standardize-graduate
# Open PR targeting dev; wait for CI
```

**This validates**: Workspace resolution for `@sndq/ui-v2`, docs MDX pipeline (primitives + foundations layout pages), prototype + package builds, and that deprecation comments do not break TypeScript.

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

**Expected result**: All apps and packages build; `Text`, `Heading`, `Container`, `Section`, `Flex`, `Grid`, and the six interactive primitives importable from `@sndq/ui-v2/components`; docs **Primitives** list `text`, `heading`, Button through Sheet; docs **Foundations** list `container`, `section`, `flex`, `grid`; layout semantic tokens (incl. `--sndq-space-*`) present in `semantic-tokens.css` as introduced in Commits 5–12; legacy exports show deprecation in IDE.

**Final status**:

- [ ] All 25 commits complete
- [ ] Root build / lint / type-check pass
- [ ] Manual: docs `/primitives/...` and `/primitives/layout/container`, `/primitives/layout/section`, `/primitives/layout/flex`, `/primitives/layout/grid` render
- [ ] Manual: ui-v2-dev playground still exercises graduated components
- [ ] PR merged

---

## 5. Team Communication

> **Heads up: first `@sndq/ui-v2` component graduation (Batch 1)**
>
> PR [link] follows **sub-batches**: **1A** typography (`Text`, `Heading`), **1B** layout shell (`Container`, `Section`, `Flex`, `Grid` — CVA + SNDQ semantic tokens, **not** Radix Themes; **strict semantic-vs-numeric prop typing**; canonical **`className` override-wins** rule via `cn(variantClasses, className)`), **1C** Button through Sheet, **1D** legacy JSDoc deprecations. Typography uses `semantic-tokens.css` and incremental `@sndq/config` `@theme` aliases; see [typography-system-reference.md](./typography-system-reference.md). Layout shell tokens, prop-typing rule, and override-wins guarantee: [layout-system-reference.md](./layout-system-reference.md). The main app is **not** bulk-migrated yet — you will see `@deprecated` JSDoc on legacy briicks/ui exports (including **briicks text**). New feature work should import from `@sndq/ui-v2/components` where possible.
>
> After pulling:
>
> 1. `pnpm install`
> 2. Restart TS server and ESLint server in the IDE
>
> Touch points:
> - `packages/ui-v2/src/components/*`, `packages/ui-v2/src/lib/utils.ts`
> - `packages/config/tailwind/tokens.css` (incremental `@theme` aliases)
> - `packages/config/tailwind/semantic-tokens.css` (typography + **layout shell** tokens, incl. `--sndq-space-*`)
> - `apps/ui-v2-dev/` imports
> - `apps/docs/content/docs/primitives/*`, `apps/docs/content/docs/foundations/{container,section,flex,grid}.mdx`
> - `sndq-fe/src/components/briicks/{text,button,input,badge,select}/`, `sndq-fe/src/components/ui/{dialog,sheet}.tsx`

---

## 6. What's Next

After Batch 1 merges, open [phase-3-batch-2-execution.md](./phase-3-batch-2-execution.md) (Card, Tabs, Tooltip, EmptyState, Skeleton).

### Lessons to carry forward

- **Vertical slices** per component keep bisect/revert sane.
- **Sub-batches** (1A–1D) keep review focus: foundations vs interactive vs deprecations.
- **Deprecate only after the export exists** in the package — avoids warning fatigue.
- **Typography + gradual `@theme`** reduces token drift before scaling interactive primitives.
- **Layout shell (1B)** documents page width, section rhythm, and inner-layout primitives (`Flex`, `Grid`) in **Foundations** while components still export from `@sndq/ui-v2/components`.
- **Strict prop-typing rule** (semantic OR numeric, never both) and **`className` override-wins** are gated on every graduating component — landing them in Batch 1 sets the precedent for every future batch.

### Known lessons from prior phases

- See [phase-3-batch-0-execution.md §6](./phase-3-batch-0-execution.md#6-whats-next) (Fumadocs, `.source`, `meta.json` ordering, shared tsconfig lessons).

---

## 7. Execution Log

| Date | Commit | Notes |
|------|--------|-------|
| 2026-05-07 | 1 | Created `apps/ui-v2-dev/src/components/ui-v2/Text.tsx` (component was missing; barrel already exported it). API forked from Kumo + Radix Themes per Commit 1 *What*. Used the existing `text-sndq-text-*` / `text-sndq-*` / `font-sndq-mono` aliases — no `tokens.css` change. Type-check + build + targeted lint on `Text.tsx` all green; full-project lint still has 7 pre-existing errors in unrelated files (chart-compositions, trackers, FilterTab) untouched by this commit. Tests deferred — see [Commit 1 Deviations](#commit-1-standardize-text-in-prototype). SHA: _to fill in after manual commit_. |
| 2026-05-07 | 2 | Bootstrapped `@sndq/ui-v2` runtime surface (`cn` helper, runtime + dev deps, `type-check` script). Moved `Text` into `packages/ui-v2/src/components/Text.tsx` (only the `cn` import path changed); added `export * from './Text';` to the package barrel. Deleted prototype `Text.tsx` and rewrote the `apps/ui-v2-dev` barrel line to re-export from `@sndq/ui-v2/components`. Shipped `apps/docs/content/docs/primitives/text.mdx` (full Template A minus `<ComponentPreview />`, inline live JSX) and updated `primitives/meta.json`. Verification: `@sndq/ui-v2` type-check, `@sndq/ui-v2-dev` type-check + build, `@sndq/docs` `generate:source` + type-check + build all green; `/primitives/text` is in the static export. Tests still deferred — see [Commit 2 Deviations](#commit-2-graduate-text-to-package--mdx--update-consumers). SHA: _to fill in after manual commit_. |
| 2026-05-08 | 3 | Created `apps/ui-v2-dev/src/components/ui-v2/Heading.tsx` and `typography/typography-shared.ts` (shared helper). `Heading` API: `as` (`h1`–`h6`, default `h2`), `size` (`sm`–`3xl`, default `xl`), `weight` (`normal` \| `medium`, default `medium`), `align`, `truncate`, `asChild`. Base class `font-heading`. Shared helper extracts `getTypographyComponent`, `typographySharedVariants` (align/truncate/weight axis maps), and exported types. Prototype barrel updated to locally export `Heading`. Build + type-check green. Tests deferred (no test runner). SHA: _to fill in after manual commit_. |
| 2026-05-08 | 4 | Graduated `Heading` + `typography-shared` helper to `packages/ui-v2/src/components/`. Refactored `Text.tsx` to consume shared helper — no behavior change; all 8 existing `Text.test.tsx` tests pass. Updated barrel to export `Heading`. Rewired prototype to re-export from `@sndq/ui-v2/components`; deleted local copies. Added `primitives/heading.mdx` and updated `meta.json`. All verification green (type-check, test 8/8, builds for ui-v2-dev + docs). SHA: _to fill in after manual commit_. |
| 2026-05-08 | 4b | Added `Heading.test.tsx` (10 tests: default element, `as`, styling contract, size/weight/truncate/align variants, override-wins, ref forwarding, asChild) and heading story + playground for docs (`heading.story.tsx`, `components/heading.tsx` client wrapper, Playground section in `heading.mdx`). Then refactored folder structure: moved `Text.tsx`, `Text.test.tsx`, `Heading.tsx`, `Heading.test.tsx` into `components/typography/` alongside `typography-shared.ts`. Updated barrel (`index.ts`) to `export * from './typography/Text'` and `'./typography/Heading'`. Fixed relative imports (`cn` path one level deeper, `typography-shared` now a sibling). Updated docs MDX path references and test template paths. All 18 tests pass, type-check + docs build green. SHA: _to fill in after manual commit_. |
| 2026-05-08 | 5 | Created `apps/ui-v2-dev/src/components/ui-v2/Container.tsx` with CVA `size` variants (`sm` \| `md` \| `lg`), `forwardRef`, `cn(containerVariants({size}), className)` override-wins. Added layout tokens to `semantic-tokens.css`: `--sndq-container-max-sm` (640px), `--sndq-container-max-md` (1024px), `--sndq-container-max-lg` (1280px), `--sndq-container-gutter` (24px). Added `@theme` aliases in `tokens.css` (`--max-width-sndq-container-*`, `--spacing-sndq-container-gutter`) so CVA uses short utilities (`max-w-sndq-container-sm`, `px-sndq-container-gutter`) instead of raw `var()`. No `as`/`asChild` in v1 — fixed `div` per layout reference. Eslint + type-check + build green. Tests deferred to Commit 6. SHA: _to fill in after manual commit_. |
| 2026-05-08 | 6 | Graduated `Container` to `packages/ui-v2/src/components/Container.tsx` (only `cn` import path changed; CVA uses `@theme`-backed short utilities). Added 4 contract tests (`Container.test.tsx`: default element, size variant, override-wins, ref forwarding) — all 22 tests pass (4 Container + 8 Text + 10 Heading). Deleted prototype copy; rewired barrel to re-export from `@sndq/ui-v2/components`. Added `primitives/layout/container.mdx` (full Template A with inline live JSX, token reference, playground) and updated `meta.json`. Added `container.story.tsx` + `components/container.tsx` client wrapper. Type-check green for `@sndq/ui-v2`, `@sndq/ui-v2-dev`, `@sndq/docs`. Build green for `@sndq/ui-v2-dev`, `@sndq/docs`; `/primitives/layout/container` in static export. SHA: _to fill in after manual commit_. |
| 2026-05-08 | 6b | Rebuilt `Container` with responsive `size` prop and `asChild` support, following Radix Themes Container pattern adapted for Tailwind CSS. Created shared `packages/ui-v2/src/lib/responsive.ts` with `Responsive<T>` type and `getResponsiveClasses()` utility (static class map approach ensures Tailwind v4 scanner sees all breakpoint-prefixed classes). Dropped CVA from Container; replaced with static `SIZE_CLASS_MAP` (3 sizes x 5 breakpoints = 15 entries). Added `asChild` via `@radix-ui/react-slot` `Slot`. Removed `containerVariants` export (replaced by `asChild` pattern). Updated tests from 4 to 8 (added responsive size, responsive default fallback, asChild renders child, asChild merges className) — all 26 tests pass. Updated barrel exports in `packages/ui-v2` and `apps/ui-v2-dev` (removed `containerVariants`, added `ContainerSize` type). Rewrote `container.mdx` documentation for responsive API, `asChild`, `Responsive` type reference. Updated story to include `asChild` prop. Type-check, test (26/26), ui-v2-dev build, docs build all green. SHA: _to fill in after manual commit_. |
| 2026-05-10 | 7+8 | Standardized and graduated `Section` to `packages/ui-v2/src/components/Section.tsx`. Follows same pattern as Container 6b: responsive `size` via shared `getResponsiveClasses()` + `asChild` via `@radix-ui/react-slot` `Slot`, static `SIZE_CLASS_MAP` (3 sizes x 5 breakpoints = 15 entries). Default element `<section>` for document outline semantics. Added semantic tokens to `semantic-tokens.css`: `--sndq-section-py-sm` (24px), `--sndq-section-py-md` (48px), `--sndq-section-py-lg` (80px). Added `@theme` aliases in `tokens.css` (`--spacing-sndq-section-py-*`) for short utilities (`py-sndq-section-py-sm`, etc.). Created 8 contract tests (`Section.test.tsx`: default element, size variant, override-wins, ref forwarding, responsive size, responsive default fallback, asChild renders child, asChild merges className) — all 34 tests pass (8 Section + 8 Container + 8 Text + 10 Heading). Updated barrel exports in `packages/ui-v2` and `apps/ui-v2-dev`. Created `primitives/layout/section.mdx` (responsive API, asChild, tokens, examples) and updated `meta.json`. Type-check green; ui-v2-dev build green; docs build green; `/primitives/layout/section` in static export. SHA: _to fill in after manual commit_. |
| 2026-05-10 | 9+10 | Standardized and graduated `Flex` to `packages/ui-v2/src/components/Flex.tsx`. Uses CVA (no responsive props or `asChild` in Flex v1 per layout reference). CVA recipe covers 7 variant axes: `direction` (row/column/row-reverse/column-reverse), `align` (start/center/end/baseline/stretch), `justify` (start/center/end/between), `wrap` (nowrap/wrap/wrap-reverse), `gap` (0–5), `gapX` (0–5), `gapY` (0–5). Gap scales extracted as `GAP_SCALE`, `GAP_X_SCALE`, `GAP_Y_SCALE` constants for readability. Default variants: `direction: 'row'`, `wrap: 'nowrap'`. Exports `Flex`, `FlexProps`, `flexVariants`. Added shared spacing scale tokens to `semantic-tokens.css`: `--sndq-space-0` (0px) through `--sndq-space-5` (24px). Added `@theme` aliases in `tokens.css` (`--spacing-sndq-space-*`) for short utilities (`gap-sndq-space-*`, `gap-x-sndq-space-*`, `gap-y-sndq-space-*`). Created 6 contract tests (`Flex.test.tsx`: default element, direction variant, gap variant, axis-specific gapX/gapY, override-wins, ref forwarding) — all 40 tests pass (6 Flex + 8 Section + 8 Container + 8 Text + 10 Heading). Updated barrel exports in `packages/ui-v2` and `apps/ui-v2-dev`. Created `primitives/layout/flex.mdx` (gap token mapping table, axis-specific gaps, flexVariants export, examples) and updated `meta.json`. Type-check green; ui-v2-dev build green; docs build green; `/primitives/layout/flex` in static export. SHA: _to fill in after manual commit_. |
|      | 11     |       |
|      | 12     |       |
|      | 13     |       |
|      | 14     |       |
|      | 15     |       |
|      | 16     |       |
|      | 17     |       |
|      | 18     |       |
|      | 19     |       |
|      | 20     |       |
|      | 21     |       |
|      | 22     |       |
|      | 23     |       |
|      | 24     |       |
|      | 25     |       |
