# Phase 1b Execution — Tailwind Token Infrastructure

Step-by-step execution guide for Phase 1b. Each commit is independently verifiable and revertable.

**Created**: 2026-04-24
**Status**: Folded into Phase 2 — Commit 1 done (tokens.css created), Commit 2 will execute as part of Phase 2
**Architecture**: [README.md](./README.md)
**Migration plan**: [migration-plan.md](./migration-plan.md)
**Phase 1a execution**: [phase-1a-execution.md](./phase-1a-execution.md)
**Branch**: `feature/phase-1b-tailwind-tokens`

> **Consolidation note**: Phase 1b was not included in the Phase 1 PR. Rather than creating a separate small PR for just the Briicks token swap, it has been folded into Phase 2 (step 3) where all CSS/token extraction happens together — primitives, semantic tokens, component CSS, and animations. Commit 1 (`tokens.css` + `package.json` exports) is already done and sits harmlessly in the repo. Commit 2 (the `globals.css` swap) will execute as part of Phase 2.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR — Extract Briicks Primitive Tokens](#3-pr--extract-briicks-primitive-tokens)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)

---

## 1. Overview

**Goal**: Extract Briicks primitive tokens from `sndq-fe/src/app/globals.css` into `packages/config/tailwind/tokens.css`, establishing the CSS package infrastructure for Phase 2. Zero visual or behavioral changes to `sndq-fe`.

**Structure**: 2 commits in 1 PR.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Extract tokens + swap import | Low–Medium | 1-2 |

**Why 1 PR**: The change is small and self-contained. Commit 1 is a pure addition (zero risk). Commit 2 is the swap — if anything breaks, reverting a single commit restores the original `globals.css`.

### What's extracted

From `sndq-fe/src/app/globals.css` lines 57-155 (inside `@theme inline`):

| Token group | Lines | Count | Examples |
|-------------|-------|-------|---------|
| Brand colors | 58-69 | 11 | `--color-brand-25` through `--color-brand-900` |
| Neutral colors | 71-83 | 12 | `--color-neutral-0` through `--color-neutral-900` |
| Success colors | 85-96 | 11 | `--color-success-25` through `--color-success-900` |
| Warning colors | 98-109 | 11 | `--color-warning-25` through `--color-warning-900` |
| Error colors | 111-122 | 11 | `--color-error-25` through `--color-error-900` |
| Type scale | 124-140 | 14 | `--font-size-xs` through `--font-size-3xl`, weights, line-heights |
| Spacing scale | 142-149 | 7 | `--spacing-1` through `--spacing-12` |
| Radius | 151-155 | 4 | `--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-full` |

**Total**: ~99 lines of token definitions.

### What's NOT extracted

- shadcn `@theme inline` mappings (lines 18-51, 55) — these reference `:root`/`.dark` CSS variables and are app-specific
- `@theme` block (lines 158-201) — button component tokens, collapsible/ai-progress animations
- `:root` / `.dark` variable blocks (lines 207-280) — shadcn theme values
- `@layer base` / `@layer utilities` (lines 282-301) — app-specific utility classes

### Radius conflict resolution

The current `@theme inline` block defines `--radius-sm`, `--radius-md`, `--radius-lg` **twice**:

| Source | Lines | Values | Status |
|--------|-------|--------|--------|
| shadcn | 52-54 | `calc(var(--radius) - 4px)`, `calc(var(--radius) - 2px)`, `var(--radius)` | **Dead code** — overridden by Briicks below |
| Briicks | 151-154 | `0.25rem`, `0.375rem`, `0.5rem` | **Active** — these are the values actually used |
| shadcn | 55 | `--radius-xl: calc(var(--radius) + 4px)` | **Active** — shadcn-only, not duplicated |

**Resolution**: Remove the dead shadcn radius lines (52-54). Keep `--radius-xl` (line 55) which is shadcn-only. Extract the Briicks radius values to `tokens.css`.

---

## 2. Before You Start

### Prerequisites

- Phase 1a is merged to dev (shared packages, workspace wiring, config switches all in place)
- `@sndq/config` is already a `workspace:*` devDependency of `sndq-fe`

### Capture baselines

Run these from the monorepo root and save the output. You will diff against these after commit 2.

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase1b-build-before.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase1b-lint-before.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase1b-typecheck-before.txt
```

Also capture a visual baseline: open `sndq-fe` locally and screenshot key pages for comparison after the swap.

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/phase-1b-tailwind-tokens
```

---

## 3. PR — Extract Briicks Primitive Tokens

---

### Commit 1: Create `packages/config/tailwind/tokens.css` + update exports

**What**: Create the shared Briicks token file and register it in `@sndq/config`'s exports. Pure addition — nothing references the file yet.

**Files to create**:

- `packages/config/tailwind/tokens.css`

**Files to edit**:

- `packages/config/package.json` — add export entry and `sideEffects`

**Content of `packages/config/tailwind/tokens.css`**:

```css
@theme inline {
  /* ── Briicks Color System ── */

  /* Brand Colors (SNDQ) */
  --color-brand-25: #f5f7ff;
  --color-brand-50: #eff2ff;
  --color-brand-100: #e9edff;
  --color-brand-200: #d6defd;
  --color-brand-300: #c4cffb;
  --color-brand-400: #8298f0;
  --color-brand-500: #3355df;
  --color-brand-600: #0c31c6;
  --color-brand-700: #06259f;
  --color-brand-800: #021975;
  --color-brand-900: #000f4d;

  /* Neutral Colors */
  --color-neutral-0: #FFFFFF;
  --color-neutral-25: #FBFBFB;
  --color-neutral-50: #F8F8F8;
  --color-neutral-100: #EFEFEF;
  --color-neutral-200: #E6E6E6;
  --color-neutral-300: #C6C6C6;
  --color-neutral-400: #9A9A9A;
  --color-neutral-500: #6A6A6A;
  --color-neutral-600: #414141;
  --color-neutral-700: #242424;
  --color-neutral-800: #131313;
  --color-neutral-900: #0D0D0D;

  /* Success Colors */
  --color-success-25: #F5FFF7;
  --color-success-50: #EAFCED;
  --color-success-100: #E0F9E4;
  --color-success-200: #C9F4D1;
  --color-success-300: #B2EFBF;
  --color-success-400: #6FDF8D;
  --color-success-500: #23C85A;
  --color-success-600: #008A27;
  --color-success-700: #007612;
  --color-success-800: #0A5C0A;
  --color-success-900: #003400;

  /* Warning Colors */
  --color-warning-25: #FFFCF5;
  --color-warning-50: #FCF6E9;
  --color-warning-100: #FAF0DD;
  --color-warning-200: #F5E4C1;
  --color-warning-300: #F1D8A7;
  --color-warning-400: #E3B556;
  --color-warning-500: #CE8B00;
  --color-warning-600: #B17900;
  --color-warning-700: #8D6200;
  --color-warning-800: #654A00;
  --color-warning-900: #403500;

  /* Error Colors */
  --color-error-25: #FFF7F5;
  --color-error-50: #FDEEEB;
  --color-error-100: #FCE6E2;
  --color-error-200: #F9D4CD;
  --color-error-300: #F7C3B8;
  --color-error-400: #EE8B76;
  --color-error-500: #E04827;
  --color-error-600: #C62400;
  --color-error-700: #9E1F00;
  --color-error-800: #671800;
  --color-error-900: #260D00;

  /* ── Type Scale ── */
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-md: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;

  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  --line-height-tight: 1.2;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;

  /* ── Spacing Scale (4px base) ── */
  --spacing-1: 0.25rem;
  --spacing-2: 0.5rem;
  --spacing-3: 0.75rem;
  --spacing-4: 1rem;
  --spacing-6: 1.5rem;
  --spacing-8: 2rem;
  --spacing-12: 3rem;

  /* ── Radius ── */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-full: 9999px;
}
```

**Target `packages/config/package.json`**:

```json
{
  "name": "@sndq/config",
  "private": true,
  "version": "0.0.0",
  "sideEffects": ["./tailwind/*.css"],
  "exports": {
    "./eslint.mjs": {
      "types": "./eslint.d.mts",
      "default": "./eslint.mjs"
    },
    "./prettier.json": "./prettier.json",
    "./tailwind/tokens.css": "./tailwind/tokens.css"
  },
  "peerDependencies": {
    "@eslint/eslintrc": "^3",
    "eslint-config-next": ">=15",
    "eslint-config-prettier": "^10",
    "eslint-plugin-prettier": "^5",
    "prettier": "^3",
    "prettier-plugin-tailwindcss": "^0.6"
  }
}
```

**Risk**: None — pure file addition. No existing file references `tokens.css` yet.

**Verification**:

```bash
# File exists and is valid CSS
cat packages/config/tailwind/tokens.css

# Package exports updated
cat packages/config/package.json | jq '.exports'

# Existing build still works (tokens.css is not referenced yet)
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

**Commit message**: `chore: create @sndq/config/tailwind/tokens.css with Briicks primitives`

**Status**:

- [x] `packages/config/tailwind/tokens.css` created
- [x] `packages/config/package.json` exports + sideEffects updated
- [x] Existing build still passes
- [x] Committed

---

### Commit 2: Replace Briicks tokens in `globals.css` with `@import`

**What**: Replace the ~99-line Briicks token block in `sndq-fe/src/app/globals.css` with a single `@import` of the shared tokens file. Also remove the dead shadcn radius lines (52-54) that were overridden by Briicks.

**File to change**: `sndq-fe/src/app/globals.css`

**Before** (relevant sections of `@theme inline`):

```css
@theme inline {
  --color-background: var(--background);
  /* ... shadcn mappings ... */
  --radius-sm: calc(var(--radius) - 4px);     /* line 52 — DEAD CODE */
  --radius-md: calc(var(--radius) - 2px);     /* line 53 — DEAD CODE */
  --radius-lg: var(--radius);                 /* line 54 — DEAD CODE */
  --radius-xl: calc(var(--radius) + 4px);     /* line 55 — keep (shadcn-only) */

  /* Briicks Color System */                   /* line 57 */
  /* Brand Colors (SNDQ) */
  --color-brand-25: #f5f7ff;
  /* ... ~99 lines of tokens ... */
  --radius-full: 9999px;                      /* line 155 */
}
```

**After** (target):

```css
@import '@sndq/config/tailwind/tokens.css';

@theme inline {
  --color-background: var(--background);
  /* ... shadcn mappings (lines 18-51 unchanged) ... */
  --radius-xl: calc(var(--radius) + 4px);
}
```

**Changes**:

1. Add `@import '@sndq/config/tailwind/tokens.css';` after the `@import 'tailwindcss';` line (line 3)
2. Remove lines 52-54 (dead shadcn radius — overridden by Briicks)
3. Remove lines 57-155 (Briicks tokens — now in `tokens.css`)
4. Keep line 55 `--radius-xl` (shadcn-only, not duplicated)

**How it works in Tailwind v4**: Multiple `@theme inline` blocks merge. The `tokens.css` file defines its own `@theme inline` with the Briicks primitives. The `globals.css` `@theme inline` adds the shadcn mappings on top. No duplicate definitions remain after removing lines 52-54 and 57-155.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Visual regression | HIGH | Compare the running app against the baseline screenshots. Every color, font size, spacing, and border radius must be identical pixel-for-pixel. |
| `@import` order with Tailwind v4 | MEDIUM | `@import 'tailwindcss'` must come before our token import. Tailwind v4 uses `@import 'tailwindcss'` as its entry point. Our `@import '@sndq/config/tailwind/tokens.css'` should come after it so the `@theme inline` in tokens.css is processed after Tailwind's base is loaded. If build fails, try swapping the order. |
| `@theme inline` merge behavior | MEDIUM | Tailwind v4 merges multiple `@theme inline` blocks — last definition wins for duplicates. Since we removed all duplicates (dead shadcn radius lines), there should be no conflicts. Verify with `pnpm build`. |
| pnpm package resolution for CSS `@import` | LOW | The `@import '@sndq/config/tailwind/tokens.css'` path must resolve through pnpm's `node_modules`. Since `@sndq/config` is a `workspace:*` dependency, pnpm creates a symlink. PostCSS / Tailwind should follow it. If not, try the full relative path as a fallback: `@import '../../packages/config/tailwind/tokens.css'`. |

**Verification**:

```bash
# Build must pass
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase1b-build-after.txt

# Lint must pass
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase1b-lint-after.txt

# Type-check must pass
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase1b-typecheck-after.txt

# Diff against baselines
diff /tmp/phase1b-build-before.txt /tmp/phase1b-build-after.txt
diff /tmp/phase1b-lint-before.txt /tmp/phase1b-lint-after.txt
diff /tmp/phase1b-typecheck-before.txt /tmp/phase1b-typecheck-after.txt
```

**Visual verification** (manual):

1. Start the dev server: `pnpm --filter sndq-fe run dev`
2. Open pages that use Briicks colors (any page with brand, success, warning, error colored elements)
3. Open pages that use the spacing/radius tokens
4. Compare against baseline screenshots — must be identical

**If it fails**:

- **"Cannot resolve '@sndq/config/tailwind/tokens.css'"**: The CSS `@import` can't find the package. Try:
  ```bash
  ls -la node_modules/@sndq/config/tailwind/tokens.css
  ls -la sndq-fe/node_modules/@sndq/config/tailwind/tokens.css
  ```
  If the symlink is broken, run `pnpm install`. If PostCSS doesn't follow workspace symlinks, use the relative path fallback: `@import '../../packages/config/tailwind/tokens.css';`

- **Visual differences in radius**: The dead shadcn radius lines (52-54) may have been used somewhere unexpectedly. Check if any component relies on the dynamic `calc(var(--radius) - ...)` values instead of the fixed Briicks values. If so, add those back to the `@theme inline` block.

- **Visual differences in colors/spacing**: Token values were copied byte-for-byte. If colors look different, check the `@import` order — the tokens.css `@theme inline` must not be overridden by another definition.

**Commit message**: `refactor: import briicks tokens from @sndq/config/tailwind in sndq-fe`

**Status**:

- [ ] `@import` added to `globals.css`
- [ ] Dead shadcn radius lines removed
- [ ] Briicks token block removed (~99 lines)
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes
- [ ] Visual check — no regressions
- [ ] Committed

---

## 4. Final Verification

After both commits, run the full suite from the monorepo root:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
```

Compare against baselines:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase1b-build-final.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase1b-lint-final.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase1b-typecheck-final.txt

diff /tmp/phase1b-build-before.txt /tmp/phase1b-build-final.txt
diff /tmp/phase1b-lint-before.txt /tmp/phase1b-lint-final.txt
diff /tmp/phase1b-typecheck-before.txt /tmp/phase1b-typecheck-final.txt
```

**Expected result**: Zero behavioral or visual differences. Build output, lint warnings, and type errors must be identical. The app looks exactly the same.

**Final status**:

- [ ] Both commits complete
- [ ] Build passes from root
- [ ] Lint passes from root
- [ ] Type-check passes from root
- [ ] Output matches baselines
- [ ] Visual check — no regressions
- [ ] PR created and merged

---

## 5. Team Communication

Send to the team before merging:

> **Heads up: Briicks token extraction incoming**
>
> PR [link] extracts Briicks primitive tokens (colors, type scale, spacing, radius) into `@sndq/config/tailwind/tokens.css`. After pulling:
>
> 1. Run `pnpm install` (lock file may change)
> 2. Zero visual changes — all token values are identical
>
> Files that changed (expect merge conflicts if your branch touches these):
> - `packages/config/package.json` (new export added)
> - `packages/config/tailwind/tokens.css` (new file)
> - `sndq-fe/src/app/globals.css` (~99 lines removed, 1 `@import` added)

---

## 6. What's Next

After Phase 1b is merged to dev, proceed to **Phase 2: Prototype Integration + Deprecate Old Submodule** — bring `sndq-ui-v2` into the monorepo, complete design token extraction (semantic tokens, component CSS, animations), scaffold `@sndq/ui-v2` package. See [migration-plan.md section 5](./migration-plan.md#5-phase-2-prototype-integration--deprecate-old-submodule).

### Lessons to carry forward (from Phase 1a)

- **`include`/`exclude` in shared tsconfigs are dead code.** TypeScript resolves inherited `include`/`exclude` relative to the config that defines them, not the consumer. Every app must define its own locally. Do not add `include`/`exclude` to shared tsconfig files.
- **`.mjs` exports need `.d.mts` type declarations.** Any shared package exporting `.mjs` files must ship a paired `.d.mts` and use conditional `exports` with `"types"` in `package.json`. Without this, consumers get `TS7016` IDE errors. Apply this pattern when creating `packages/ui-v2/` or any future package with `.mjs` exports.
- **Shared config packages use `peerDependencies`, not `devDependencies`.** `@sndq/config` declares ESLint/Prettier tools as `peerDependencies` with relaxed semver ranges (e.g. `"^3"`, `">=15"`). Each consumer app (e.g. `sndq-fe`) owns the exact pinned versions in its own `devDependencies`. This avoids duplicate installations, surfaces version mismatches at `pnpm install` time via "unmet peer" warnings, and is safe if the package is ever published. When upgrading a tool in a consumer to a new major version: (1) update the consumer's `devDependencies`, (2) run `pnpm install` — if pnpm warns about an unmet peer, bump the range in `@sndq/config/package.json`, (3) run `pnpm lint` to verify the shared config still works.

---

## Execution Log

Record notes, issues, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
| | 2 | |
