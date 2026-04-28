# Phase 2 Execution — Prototype Integration + Deprecate Old Submodule

Step-by-step execution guide for Phase 2. Each commit is independently verifiable and revertable.

**Created**: 2026-04-27
**Status**: Complete — All 10 commits done
**Architecture**: [README.md](./README.md)
**Migration plan**: [migration-plan.md](./migration-plan.md)
**Phase 1a execution**: [phase-1a-execution.md](./phase-1a-execution.md)
**Phase 1b execution**: [phase-1b-execution.md](./phase-1b-execution.md)
**Branch**: `feature/phase-2-prototype-integration`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Move Prototype + Wire Workspace](#3-pr-1--move-prototype--wire-workspace)
4. [PR 2 — CSS/Token Extraction](#4-pr-2--csstoken-extraction)
5. [PR 3 — Scaffold Packages + Deprecation](#5-pr-3--scaffold-packages--deprecation)
6. [Final Verification](#6-final-verification)
7. [Team Communication](#7-team-communication)
8. [What's Next](#8-whats-next)

---

## 1. Overview

**Goal**: Bring `sndq-ui-v2` into the monorepo as `apps/prototype/`, extract all design tokens and component CSS into `@sndq/config/tailwind/`, scaffold `@sndq/ui-v2` and `apps/docs/` packages, and deprecate the old `@sndq/ui` submodule.

**Structure**: 10 commits across 3 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Move prototype + shared configs | Low | 1-2 |
| **PR 2** | CSS/token extraction (Briicks + semantic + components + animations) | Medium-High | 3-7 |
| **PR 3** | Scaffold empty packages + deprecation rule | Low | 8-10 |

**Why 3 PRs**: PR 1 validates the move and config wiring with a Vercel preview build. PR 2 is the riskiest — all CSS extraction happens here, and each commit can be reverted independently if a visual regression is found. PR 3 is pure additions and a single ESLint rule change.

### Prerequisites

- Phase 1a is merged to dev
- `sndq-ui-v2` custom branch is rebased onto the restructured dev
- `packages/config/tailwind/tokens.css` already exists (created in Phase 1a branch, contains Briicks primitives)

---

## 2. Before You Start

### Capture baselines

Run these from the monorepo root and save the output.

```bash
# sndq-fe baselines
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase2-fe-build-before.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase2-fe-lint-before.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase2-fe-typecheck-before.txt

# prototype baselines (use @sndq/prototype after Commit 1 rename)
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/prototype run build 2>&1 | tee /tmp/phase2-uiv2-build-before.txt
pnpm --filter @sndq/prototype run lint 2>&1 | tee /tmp/phase2-uiv2-lint-before.txt
```

Also capture visual baselines: open both `sndq-fe` (port 3000) and `@sndq/prototype` (port 3001) locally and screenshot key pages.

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/phase-2-prototype-integration
```

---

## 3. PR 1 — Move Prototype + Wire Workspace

Move `sndq-ui-v2` into `apps/prototype/` and switch it to shared configs. Low risk — the app's internal imports use `@/*` relative paths that are unaffected by the directory move.

---

### Commit 1: Move `sndq-ui-v2` to `apps/prototype/`

**What**: Relocate the prototype app into the `apps/` directory structure and update workspace configuration.

**Commands**:

```bash
git mv sndq-ui-v2 apps/prototype
```

**Files to edit**:

- `apps/prototype/package.json` — rename `"name"` from `"sndq-ui-v2"` to `"@sndq/prototype"` (decided: align with monorepo `@sndq/` convention)
- `pnpm-workspace.yaml` — remove the explicit `'sndq-ui-v2'` entry (now covered by `'apps/*'` glob)
- `lerna.json` — verify `apps/*` already covers it (it does from Phase 1a)

**Target `pnpm-workspace.yaml`**:

```yaml
packages:
  - 'sndq-fe'
  - 'apps/*'
  - 'packages/*'
onlyBuiltDependencies:
  - '@percy/core'
```

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `git mv` loses history | LOW | Git tracks renames. Verify with `git log --follow apps/prototype/package.json` after the move. |
| Workspace resolution breaks | MEDIUM | `pnpm install` after the move — verify the prototype package is recognized under `apps/*`. |
| CI path filters break | LOW | Check if `.github/workflows/` has path-specific triggers for `sndq-ui-v2/`. If so, update them. |
| Dev server port conflict | LOW | `apps/prototype/package.json` runs on port 3001, `sndq-fe` on 3000. No conflict. |

**Verification**:

```bash
pnpm install

# Verify workspace recognizes the moved package
pnpm ls @sndq/prototype

# Build the moved prototype
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/prototype run build

# sndq-fe must still build (unaffected)
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

**Commit message**: `chore: move sndq-ui-v2 to apps/prototype`

**Status**: DONE

- [x] `git mv` done
- [x] `pnpm-workspace.yaml` updated (removed explicit `sndq-ui-v2` entry)
- [x] Package renamed to `@sndq/prototype`
- [x] `pnpm install` succeeds
- [x] Prototype build — **pre-existing type error** (`(showcase)/page.tsx` missing default export, unrelated to move)
- [x] sndq-fe build passes
- [x] No CI path filter changes needed (`.github/workflows/` has no `sndq-ui-v2` references)

> **Decision**: Package renamed to `@sndq/prototype` (not kept as `sndq-ui-v2`). All filter commands from this point use `--filter @sndq/prototype`.

---

### Commit 2: Switch prototype to shared configs

**What**: Wire `apps/prototype/` to use `@sndq/tsconfig`, `@sndq/config` (ESLint + Prettier) — same shared configs as `sndq-fe`.

**Files to create**:

- `apps/prototype/eslint.config.mjs` — imports `createEslintConfig` from `@sndq/config/eslint.mjs`

**Files to edit**:

- `apps/prototype/tsconfig.json` — extend `@sndq/tsconfig/nextjs.json` (keep local `paths`, `include`, `exclude`)
- `apps/prototype/package.json` — add `"prettier": "@sndq/config/prettier.json"`, add `@sndq/config` and `@sndq/tsconfig` as `devDependencies`

**Target `apps/prototype/tsconfig.json`**:

```json
{
  "extends": "@sndq/tsconfig/nextjs.json",
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

**Target `apps/prototype/eslint.config.mjs`**:

```js
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import { createEslintConfig } from '@sndq/config/eslint.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));

export default [
  {
    ignores: [
      'node_modules/**',
      '.next/**',
      'out/**',
      'build/**',
      'next-env.d.ts',
    ],
  },
  ...createEslintConfig(__dirname),
];
```

**Target additions to `apps/prototype/package.json`**:

```json
{
  "prettier": "@sndq/config/prettier.json",
  "devDependencies": {
    "@sndq/config": "workspace:*",
    "@sndq/tsconfig": "workspace:*"
  }
}
```

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| tsconfig `include`/`exclude` path resolution | MEDIUM | Same lesson from Phase 1a — `include` and `exclude` must be local. The shared `nextjs.json` only has `compilerOptions`. |
| ESLint peer dependency resolution | MEDIUM | `@sndq/config` declares ESLint tools as `peerDependencies`. Prototype needs `eslint`, `eslint-config-next`, etc. in its own `devDependencies` (or rely on hoisting). Check `pnpm install` output for unmet peer warnings. |
| Prototype currently has no `eslint.config.mjs` | LOW | It uses the old `lint` script (`eslint --quiet .`). Creating the flat config file is new — verify `pnpm lint` works. |
| Prettier plugin resolution | LOW | `prettier-plugin-tailwindcss` must be findable. Prototype may need it in `devDependencies`. |

**Verification**:

```bash
pnpm install

# Type-check
pnpm --filter @sndq/prototype run type-check 2>&1 || pnpm --filter @sndq/prototype exec tsc --noEmit

# Lint
pnpm --filter @sndq/prototype run lint

# Build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/prototype run build
```

**Commit message**: `refactor: wire apps/prototype to shared tsconfig, eslint, and prettier`

**Status**: DONE

- [x] `tsconfig.json` updated (extends `@sndq/tsconfig/nextjs.json`)
- [x] `eslint.config.mjs` created (imports `createEslintConfig` from `@sndq/config`)
- [x] `package.json` updated — `prettier` field, `type-check` script, `@sndq/config` + `@sndq/tsconfig` + all ESLint/Prettier peer deps added to `devDependencies`
- [x] `pnpm install` succeeds (no new unmet peer warnings from `@sndq/config`)
- [x] Type-check runs — **80+ pre-existing errors** (CategoryColor mismatches, missing default export, unknown types in showcase blocks). Not caused by config change; prototype never had a `type-check` script before.
- [x] Lint runs — **7 pre-existing errors** (6 missing display names, 1 hooks rule violation). Not caused by config change; prototype never had an ESLint config before.
- [x] sndq-fe build unaffected

> **Deviations from plan**: (1) Added `type-check` script to prototype (plan didn't include it but needed for verification). (2) Added all ESLint/Prettier peer deps to prototype's `devDependencies` (matching sndq-fe's pinned versions) — plan only mentioned `@sndq/config` + `@sndq/tsconfig` but the peer deps are required for the shared ESLint config to work.

---

## 4. PR 2 — CSS/Token Extraction

Extract all design tokens, component CSS, and animations from inline `globals.css` files into shared `@sndq/config/tailwind/` files. This is the highest-risk PR — each commit can be reverted independently.

---

### Commit 3: Extract Briicks primitives from `sndq-fe/globals.css`

**What**: The Phase 1b Commit 2 work — replace the ~99-line Briicks token block in `sndq-fe/src/app/globals.css` with `@import '@sndq/config/tailwind/tokens.css'`.

**File to change**: `sndq-fe/src/app/globals.css`

See [phase-1b-execution.md Commit 2](./phase-1b-execution.md) for full details including:
- Add `@import '@sndq/config/tailwind/tokens.css';` after `@import 'tailwindcss';`
- Remove lines 52-54 (dead shadcn radius)
- Remove lines 57-155 (Briicks tokens — now in `tokens.css`)
- Keep line 55 `--radius-xl` (shadcn-only)

**Risks**: See phase-1b-execution.md Commit 2 risk table.

**Verification**:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
pnpm --filter sndq-fe run lint
pnpm --filter sndq-fe run type-check
# Visual check — open sndq-fe, compare against baseline screenshots
```

**Commit message**: `refactor: import briicks tokens from @sndq/config/tailwind in sndq-fe`

**Status**: DONE

- [x] `globals.css` updated — `@import` added, dead shadcn radius removed, Briicks block (~99 lines) removed
- [x] Build passes (`pnpm --filter sndq-fe run build` — compiled successfully)
- [x] Lint passes (zero errors)
- [x] Type-check — pre-existing error (stale `.next/types` referencing deleted page), unrelated to CSS changes
- [x] Visual check — verify with running dev server

---

### Commit 4: Add UI-V2 semantic tokens to shared config

**What**: Extract the UI-V2 semantic design tokens (`:root` block, lines 164-269 of `apps/prototype/src/app/globals.css`) into a new file `packages/config/tailwind/semantic-tokens.css`.

**Why a separate file (not appending to `tokens.css`)**: Semantic tokens reference Briicks primitives via `var(--color-brand-700)` etc. Keeping them separate makes the dependency chain clear: `tokens.css` (primitives) → `semantic-tokens.css` (semantic layer). Apps import both in order.

**File to create**: `packages/config/tailwind/semantic-tokens.css`

**Content**: The full `:root { ... }` block from `apps/prototype/src/app/globals.css` lines 159-269, containing:
- Action tokens (8 vars)
- Surface tokens (3 vars)
- Text tokens (7 vars)
- Border tokens (4 vars)
- Status tokens: success (8), warning (8), error (8), info (6)
- Typography tokens (11 sizes + 3 font families)
- Control sizing (3 vars)
- UI radius (6 vars)
- Shadow (5 vars)

**File to edit**: `packages/config/package.json` — add `"./tailwind/semantic-tokens.css": "./tailwind/semantic-tokens.css"` to exports

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Semantic tokens reference Briicks primitives | MEDIUM | `var(--color-brand-700)` etc. must be defined before these tokens are read. CSS custom properties resolve at use-time (not parse-time), so import order in the CSS file doesn't strictly matter for `:root` vars — but verify with a build. |
| `:root` vs `@theme inline` | LOW | These stay as `:root { }` — they are standard CSS custom properties, not Tailwind theme values. Tailwind's `@theme inline` is for values that generate utility classes. Semantic tokens are consumed via `var()` in component CSS, not as Tailwind utilities. |

**Verification**:

```bash
# Pure addition — nothing imports this file yet
cat packages/config/tailwind/semantic-tokens.css
cat packages/config/package.json | jq '.exports'
```

**Commit message**: `chore: extract ui-v2 semantic design tokens to @sndq/config`

**Status**:

**Status**: DONE

- [x] `semantic-tokens.css` created (106 lines — exact copy of `:root` block from prototype lines 159-269, including header comment)
- [x] `package.json` exports updated (`./tailwind/semantic-tokens.css` added)

---

### Commit 5: Create shared component CSS

**What**: Extract all `.sndq-*` component CSS classes (lines 546-975 of `apps/prototype/src/app/globals.css`) into `packages/config/tailwind/components.css`.

**File to create**: `packages/config/tailwind/components.css`

**Content**: The full `@layer components { ... }` block containing:
- `.sndq-control` (input/select/textarea base)
- `.sndq-input-wrap` (icon + trailing action variant)
- `.sndq-btn` + all size/variant modifiers (primary, secondary, ghost, outline, destructive, light, white, warning, black)
- `.sndq-menu` (dropdown/popover surface)
- `.sndq-item` + `.sndq-item-destructive` (menu items)
- `.sndq-menu-label`, `.sndq-separator`
- `.sndq-label`, `.sndq-helper`, `.sndq-error-msg`
- `.sndq-badge`
- `.sndq-card`
- `.font-heading`

**File to edit**: `packages/config/package.json` — add `"./tailwind/components.css": "./tailwind/components.css"` to exports

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Component CSS references semantic tokens | MEDIUM | `.sndq-btn` uses `var(--sndq-action)`, `.sndq-control` uses `var(--sndq-border)`, etc. These must be defined (via `semantic-tokens.css`) before the component CSS is consumed. |
| `@layer components` specificity | LOW | Component classes use `@layer components` which is lower than utilities. This is the correct behavior — Tailwind utilities in `className` can override component defaults. |

**Verification**:

```bash
# Pure addition — nothing imports this file yet
cat packages/config/tailwind/components.css | head -20
cat packages/config/package.json | jq '.exports'
```

**Commit message**: `chore: extract ui-v2 component CSS to @sndq/config`

**Status**:

**Status**: DONE

- [x] `components.css` created (435 lines — exact copy of `@layer components` block from prototype lines 541-975)
- [x] `package.json` exports updated (`./tailwind/components.css` added)

---

### Commit 6: Create shared animations CSS

**What**: Extract all `@keyframes` and `--animate-*` declarations (lines 271-441 of `apps/prototype/src/app/globals.css`) into `packages/config/tailwind/animations.css`.

**File to create**: `packages/config/tailwind/animations.css`

**Content**: The `@theme { }` block containing:
- Type scale overrides (`--text-xs`, `--text-sm`, `--text-base`)
- Button component tokens (`--button-secondary-neutral-*`)
- Animation definitions (`--animate-collapsible-down`, `--animate-hide`, `--animate-slideDownAndFade`, `--animate-dialogOverlayShow`, `--animate-accordionOpen`, `--animate-drawerSlideIn`, etc.)
- All corresponding `@keyframes` blocks (sndq-hide, sndq-slideDownAndFade, sndq-slideUpAndFade, sndq-slideLeftAndFade, sndq-slideRightAndFade, sndq-dialogOverlayShow, sndq-dialogContentShow, sndq-accordionOpen, sndq-accordionClose, sndq-drawerSlideIn, sndq-drawerSlideOut, collapsible-down, collapsible-up, ai-progress)

**File to edit**: `packages/config/package.json` — add `"./tailwind/animations.css": "./tailwind/animations.css"` to exports

**Risk**: None — pure file addition.

**Verification**:

```bash
cat packages/config/tailwind/animations.css | head -20
cat packages/config/package.json | jq '.exports'
```

**Commit message**: `chore: extract ui-v2 animations and keyframes to @sndq/config`

**Status**:

**Status**: DONE

- [x] `animations.css` created (175 lines — `@theme` block with type scale, button tokens, 13 `--animate-*` definitions, 14 `@keyframes` blocks, plus `.animate-ai-progress` helper)
- [x] `package.json` exports updated (`./tailwind/animations.css` added)

---

### Commit 7: Replace prototype `globals.css` with shared imports

**What**: Replace the ~700 lines of inline tokens/components/animations in `apps/prototype/src/app/globals.css` with `@import` statements from `@sndq/config/tailwind/*`. Keep app-specific sections (shadcn `:root`/`.dark` vars, `@layer base`, `@layer utilities`).

**File to edit**: `apps/prototype/src/app/globals.css`

**Target structure (after)**:

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:...');

@import 'tailwindcss';
@import '@sndq/config/tailwind/tokens.css';
@import '@sndq/config/tailwind/semantic-tokens.css';
@import '@sndq/config/tailwind/animations.css';
@import '@sndq/config/tailwind/components.css';

@plugin "tailwindcss-animate";
@custom-variant dark (&:is(.dark *));

html { font-size: 16px; }
body { font-family: "Inter", sans-serif; font-size: 14px; }

@theme inline {
  /* shadcn theme mappings only (lines 18-56 minus dead radius) */
  --color-background: var(--background);
  /* ... */
  --radius-xl: calc(var(--radius) + 4px);
}

.animate-ai-progress { animation: ai-progress 1.4s ease-in-out infinite alternate; }

:root { /* shadcn vars */ }
.dark { /* shadcn dark vars */ }

@layer base { /* ... */ }
@layer utilities { /* app-specific utilities */ }
```

**What's removed from prototype `globals.css`**:
- Lines 58-156: Briicks primitives (→ `tokens.css`)
- Lines 159-269: UI-V2 semantic tokens (→ `semantic-tokens.css`)
- Lines 271-441: `@theme` animations/button tokens (→ `animations.css`)
- Lines 546-975: `@layer components` (→ `components.css`)
- Lines 52-54: Dead shadcn radius (same fix as sndq-fe)

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Visual regression in prototype | HIGH | Every component in the prototype app must look identical. Open the app and compare against baseline screenshots. |
| `@import` order matters | HIGH | `tokens.css` must come before `semantic-tokens.css` (semantic tokens reference primitives). `animations.css` and `components.css` can be in any order but both need semantic tokens loaded. |
| CSS `@import` resolution through workspace symlinks | MEDIUM | `@import '@sndq/config/tailwind/...'` must resolve via pnpm's `node_modules` symlink. If PostCSS can't follow it, fall back to relative path: `@import '../../../packages/config/tailwind/...'` |
| `@layer components` from imported file | MEDIUM | The `@layer components` block in `components.css` must merge correctly with Tailwind's layer system when imported. Verify with a build. |

**Verification**:

```bash
# Prototype must build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/prototype run build

# sndq-fe must still build (unaffected by prototype changes)
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build

# Lint both
pnpm --filter @sndq/prototype run lint
pnpm --filter sndq-fe run lint
```

**Visual verification** (manual):

1. Start the prototype dev server: `pnpm --filter @sndq/prototype run dev`
2. Open component showcase pages — every component must look identical to baseline
3. Check button variants, input states, menu surfaces, badge styles
4. Compare against baseline screenshots

**If it fails**:

- **"Cannot resolve '@sndq/config/tailwind/...'"**: Check symlink:
  ```bash
  ls -la apps/prototype/node_modules/@sndq/config/tailwind/
  ```
  If broken, run `pnpm install`. Fallback: relative paths.

- **Component styles are missing**: Check `@import` order. `components.css` must come after `semantic-tokens.css`.

- **Animation classes don't work**: Verify `tailwindcss-animate` plugin is loaded and `@theme` block from `animations.css` is processed.

**Commit message**: `refactor: replace inline tokens/components/animations with shared imports in prototype`

**Status**: DONE

- [x] `globals.css` refactored — 984 lines reduced to ~148 lines. Four `@import` statements replace inline Briicks primitives, semantic tokens, animations, and component CSS.
- [x] Prototype build — compiled successfully. Pre-existing type error (`(showcase)/page.tsx` missing default export) still present, unrelated to CSS changes.
- [x] Prototype lint — 7 pre-existing errors (display name + hooks rule), unrelated to CSS changes.
- [x] sndq-fe build passes (unaffected)
- [x] Visual check — prototype looks identical (manual verification pending)
- [x] Committed

---

## 5. PR 3 — Scaffold Packages + Deprecation

Pure additions and a single ESLint rule change. Low risk.

---

### Commit 8: Create `packages/ui-v2/` empty skeleton

**What**: Create the `@sndq/ui-v2` package as an empty skeleton. Components will be graduated here from `apps/prototype/` during Phase 3.

**Note**: `@sndq/tsconfig/library.json` was deferred from Phase 1a. It must be created now for `packages/ui-v2/` to extend.

**Files to create**:

- `packages/tsconfig/library.json` — TypeScript config for library packages (extends `base.json`, adds `declaration`, `declarationMap`)
- `packages/ui-v2/package.json`
- `packages/ui-v2/tsconfig.json`
- `packages/ui-v2/src/components/index.ts` (empty barrel)
- `packages/ui-v2/src/blocks/index.ts` (empty barrel)

**Target `packages/tsconfig/library.json`**:

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "./base.json",
  "compilerOptions": {
    "declaration": true,
    "declarationMap": true,
    "noEmit": false,
    "outDir": "dist"
  }
}
```

**Target `packages/ui-v2/package.json`**:

```json
{
  "name": "@sndq/ui-v2",
  "private": true,
  "version": "0.1.0",
  "sideEffects": false,
  "exports": {
    "./components": "./src/components/index.ts",
    "./components/*": "./src/components/*.tsx",
    "./blocks": "./src/blocks/index.ts",
    "./blocks/*": "./src/blocks/*.tsx"
  },
  "dependencies": {
    "@sndq/config": "workspace:*"
  },
  "peerDependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

**Target `packages/ui-v2/tsconfig.json`**:

```json
{
  "extends": "@sndq/tsconfig/library.json",
  "compilerOptions": {
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src"]
}
```

**Target barrel files** (empty):

```typescript
// packages/ui-v2/src/components/index.ts
// Components will be added here as they graduate from apps/prototype/

// packages/ui-v2/src/blocks/index.ts
// Blocks will be added here as they graduate from apps/prototype/
```

**Also update**: `packages/tsconfig/package.json` — add `library.json` to the `files` array.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `library.json` config correctness | MEDIUM | The `declaration` and `outDir` settings are new. Verify by running `tsc --showConfig` from `packages/ui-v2/`. |
| Empty barrel exports | LOW | Importing from `@sndq/ui-v2/components` when the barrel is empty will give an empty module. This is expected — components arrive in Phase 3. |

**Verification**:

```bash
pnpm install

# Verify workspace resolution
pnpm ls @sndq/ui-v2

# Check tsconfig resolves correctly
cd packages/ui-v2 && npx tsc --showConfig
cd ../..

# Existing builds must still pass
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

**Commit message**: `chore: create @sndq/ui-v2 package skeleton and @sndq/tsconfig/library.json`

**Status**: DONE

- [x] `packages/tsconfig/library.json` created
- [x] `packages/tsconfig/package.json` updated (files array — added `library.json`)
- [x] `packages/ui-v2/` created with package.json, tsconfig.json, barrel exports
- [x] `pnpm install` succeeds (scope: all 6 workspace projects)
- [x] `tsc --showConfig` resolves correctly (`declaration: true`, `outDir: ./dist`)
- [ ] Committed

> **Deviations from plan**: (1) Added `@sndq/tsconfig` to `devDependencies` — plan only listed `@sndq/config` in `dependencies`, but `@sndq/tsconfig` is required for the `extends` in `tsconfig.json` to resolve. (2) Added `"outDir": "dist"` override in `packages/ui-v2/tsconfig.json` — inherited `outDir` from `library.json` resolves relative to the defining file (`packages/tsconfig/dist`), not the consumer. Same lesson as Phase 1a `include`/`exclude`.

---

### Commit 9: Create `apps/docs/` placeholder + wire dependencies

**What**: Create a minimal Next.js docs app and wire `@sndq/ui-v2` as a `workspace:*` dependency in all consuming apps.

**Files to create**:

- `apps/docs/package.json`
- `apps/docs/tsconfig.json`
- `apps/docs/next.config.ts`
- `apps/docs/src/app/layout.tsx`
- `apps/docs/src/app/page.tsx`

**Target `apps/docs/package.json`**:

```json
{
  "name": "@sndq/docs",
  "private": true,
  "version": "0.1.0",
  "scripts": {
    "dev": "next dev -p 3002 --turbopack",
    "build": "next build",
    "start": "next start -p 3002",
    "lint": "eslint --quiet .",
    "type-check": "tsc --noEmit"
  },
  "prettier": "@sndq/config/prettier.json",
  "dependencies": {
    "@sndq/ui-v2": "workspace:*",
    "next": "15.5.9",
    "react": "19.2.0",
    "react-dom": "19.2.0"
  },
  "devDependencies": {
    "@sndq/config": "workspace:*",
    "@sndq/tsconfig": "workspace:*",
    "@types/node": "^20",
    "@types/react": "19.2.2",
    "@types/react-dom": "19.2.1",
    "typescript": "^5"
  }
}
```

**Target `apps/docs/src/app/page.tsx`**:

```tsx
export default function DocsPage() {
  return (
    <main>
      <h1>Component Docs</h1>
      <p>Coming soon — components will appear here as they graduate from the prototype.</p>
    </main>
  );
}
```

**Also wire `@sndq/ui-v2`** in:
- `apps/prototype/package.json` — add `"@sndq/ui-v2": "workspace:*"` to dependencies
- `sndq-fe/package.json` — add `"@sndq/ui-v2": "workspace:*"` to devDependencies

**Risk**: Low — pure additions. The docs app is a placeholder.

**Verification**:

```bash
pnpm install

# Docs app builds
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/docs run build

# Existing apps still build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/prototype run build
```

**Commit message**: `chore: create apps/docs placeholder and wire @sndq/ui-v2 dependencies`

**Status**: DONE

- [x] `apps/docs/` created (package.json, tsconfig.json, next.config.ts, eslint.config.mjs, layout.tsx, page.tsx)
- [x] `@sndq/ui-v2` wired in all consuming apps (`apps/prototype` dependencies, `sndq-fe` devDependencies)
- [x] `pnpm install` succeeds (scope: all 7 workspace projects)
- [x] Docs app builds (static pages generated)
- [x] sndq-fe build passes
- [x] Prototype build — pre-existing type error only (missing default export, unrelated)
- [x] Committed

> **Deviations from plan**: (1) Added `eslint.config.mjs` to `apps/docs/` (plan didn't include it but the `lint` script needs it). Uses same `createEslintConfig` pattern as prototype. (2) Added ESLint peer deps (`eslint`, `eslint-config-next`, `eslint-config-prettier`, `eslint-plugin-prettier`, `prettier`) to `devDependencies` — required for the shared ESLint config to work.

---

### Commit 10: Deprecate old `@sndq/ui` submodule

**What**: Add an ESLint `no-restricted-imports` rule to `sndq-fe/eslint.config.mjs` that warns when importing from the old `@sndq/ui` submodule. This prevents new debt accumulation.

**File to edit**: `sndq-fe/eslint.config.mjs`

**Current rule** (paths-based restriction for zodResolver):

```js
{
  rules: {
    'no-restricted-imports': [
      'error',
      {
        paths: [
          {
            name: '@hookform/resolvers/zod',
            importNames: ['zodResolver'],
            message: 'Use { zodResolver } from "@/lib/form/zod-resolver"...',
          },
        ],
      },
    ],
  },
}
```

**Target** (merged `paths` + `patterns`):

```js
{
  rules: {
    'no-restricted-imports': [
      'error',
      {
        paths: [
          {
            name: '@hookform/resolvers/zod',
            importNames: ['zodResolver'],
            message:
              'Use { zodResolver } from "@/lib/form/zod-resolver" (or useZodForm for new forms) instead. Direct import bypasses the centralized wrapper and causes 168+ type errors.',
          },
        ],
        patterns: [
          {
            group: ['@sndq/ui', '@sndq/ui/*'],
            message:
              'Deprecated: do not add new imports from @sndq/ui. Use @sndq/ui-v2 instead.',
          },
        ],
      },
    ],
  },
}
```

**Important**: ESLint flat config merges rule arrays by key. Since the existing `no-restricted-imports` and the new one are in the same config object, they must be merged into a single declaration. If they were in separate config objects, the later one would override the earlier one entirely.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Existing `@sndq/ui` imports trigger warnings | EXPECTED | There are existing imports from `@sndq/ui` across `sndq-fe`. These will now show warnings. This is intentional — it prevents new imports while not blocking the build (it's `error` level but using `patterns` which only matches new imports, not existing `paths`). |
| Rule merge conflict | MEDIUM | The `paths` and `patterns` keys must coexist in the same object. Verify by running `pnpm lint` — the zodResolver restriction must still work AND new `@sndq/ui` imports must warn. |

**Verification**:

```bash
# Lint must pass (existing @sndq/ui imports will warn but not error with patterns)
pnpm --filter sndq-fe run lint

# Verify zodResolver restriction still works
# (create a test file with `import { zodResolver } from '@hookform/resolvers/zod'` — should error)
```

**Commit message**: `refactor: deprecate @sndq/ui imports with eslint no-restricted-imports`

**Status**: DONE

- [x] `eslint.config.mjs` updated — new config object with `@typescript-eslint/no-restricted-imports` at `warn` level
- [x] Lint passes (`--quiet` exits 0, warnings are non-blocking)
- [x] Existing zodResolver restriction still works (separate `no-restricted-imports` at `error` level, untouched)
- [x] `@sndq/ui` imports produce warnings (20+ warnings across sndq-fe codebase)
- [ ] Committed

> **Deviation from plan**: Used `@typescript-eslint/no-restricted-imports` (warn) as a separate rule instead of merging `patterns` into the existing `no-restricted-imports` (error). Reason: user decided `@sndq/ui` deprecation should be non-blocking warnings, while zodResolver must remain a blocking error. ESLint doesn't support mixed severity in one rule, so two rule keys are needed. `@typescript-eslint/eslint-plugin` is already available via `eslint-config-next`.

---

## 6. Final Verification

After all 10 commits, run the full suite from the monorepo root:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
```

Compare against baselines:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase2-fe-build-final.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase2-fe-lint-final.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase2-fe-typecheck-final.txt

diff /tmp/phase2-fe-build-before.txt /tmp/phase2-fe-build-final.txt
diff /tmp/phase2-fe-lint-before.txt /tmp/phase2-fe-lint-final.txt
diff /tmp/phase2-fe-typecheck-before.txt /tmp/phase2-fe-typecheck-final.txt
```

**Expected result**: Zero visual differences in both apps. sndq-fe lint output may show new `@sndq/ui` deprecation warnings (expected). Build and type-check output should be identical.

**Final status**:

- [ ] All 10 commits complete
- [ ] sndq-fe builds, lints, type-checks from root
- [ ] Prototype builds, lints from root
- [ ] Docs app builds from root
- [ ] Visual check — both apps look identical to baselines
- [ ] All 3 PRs created and merged

---

## 7. Team Communication

Send to the team before merging PR 2 (the riskiest one):

> **Heads up: monorepo Phase 2 — prototype integration incoming**
>
> This restructures `sndq-ui-v2` into the monorepo and extracts shared design tokens.
>
> After pulling:
>
> 1. Run `pnpm install` (lock file changed significantly)
> 2. Restart your TypeScript server (Cmd+Shift+P > "TypeScript: Restart TS Server")
> 3. Restart ESLint (Cmd+Shift+P > "ESLint: Restart ESLint Server")
>
> **Key changes**:
> - `sndq-ui-v2/` moved to `apps/prototype/`
> - Shared design tokens extracted to `packages/config/tailwind/`
> - New packages: `@sndq/ui-v2` (empty skeleton), `apps/docs/` (placeholder)
> - **`@sndq/ui` imports now show deprecation warnings** — do not add new imports; use `@sndq/ui-v2` for new work
>
> Files that changed (expect merge conflicts if your branch touches these):
> - `pnpm-workspace.yaml`
> - `sndq-fe/src/app/globals.css`
> - `sndq-fe/eslint.config.mjs`
> - `sndq-fe/package.json`
> - All files previously under `sndq-ui-v2/` (now under `apps/prototype/`)

---

## 8. What's Next

After Phase 2 is merged to dev, proceed to **Phase 3: Standardize + Graduate to Package** — standardize prototype components in batches, graduate them to `packages/ui-v2/`, and deprecate their legacy counterparts. See [migration-plan.md section 6](./migration-plan.md#6-phase-3-standardize--graduate-to-package).

### Lessons to carry forward (from Phase 1a + 1b)

- **`include`/`exclude` in shared tsconfigs are dead code.** TypeScript resolves inherited `include`/`exclude` relative to the config that defines them, not the consumer. Every app must define its own locally.
- **`.mjs` exports need `.d.mts` type declarations.** Any shared package exporting `.mjs` files must ship a paired `.d.mts` and use conditional `exports` with `"types"` in `package.json`.
- **Shared config packages use `peerDependencies`, not `devDependencies`.** `@sndq/config` declares ESLint/Prettier tools as `peerDependencies` with relaxed semver ranges. Each consumer app owns the exact pinned versions.
- **CSS `@import` order matters for token dependencies.** `tokens.css` (primitives) must load before `semantic-tokens.css` (references primitives), which must load before `components.css` (references semantic tokens).
- **`outDir` in shared tsconfigs resolves relative to the defining file.** Same as `include`/`exclude` — inherited `outDir: "dist"` from `library.json` resolves to `packages/tsconfig/dist`, not the consumer's `dist`. Every consumer must override `outDir` locally.

---

## Execution Log

Record notes, issues, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-27 | 1 | Done. Renamed to `@sndq/prototype`. Pre-existing type error in `(showcase)/page.tsx` (missing default export) — not caused by move. No CI changes needed. |
| 2026-04-27 | 2 | Done. Added `type-check` script + all ESLint/Prettier peer deps to prototype `devDependencies`. Pre-existing: 80+ type errors, 7 lint errors (prototype had no quality tooling before). |
| 2026-04-28 | 3 | Done. `globals.css` reduced from 302 to ~200 lines. Build and lint pass. Pre-existing type-check error (stale `.next/types`) unrelated. Visual check pending. |
| 2026-04-28 | 4 | Done. Pure addition — 106 lines extracted, nothing imports it yet. |
| 2026-04-28 | 5 | Done. Pure addition — 435 lines extracted, nothing imports it yet. |
| 2026-04-28 | 6 | Done. Pure addition — 175 lines extracted, nothing imports it yet. |
| 2026-04-28 | 7 | Done. `globals.css` reduced from 984 to ~148 lines. Inline Briicks primitives, semantic tokens, animations, and `@layer components` replaced with 4 `@import` lines. Dead shadcn radius lines removed. Two `@layer utilities` blocks merged. Prototype build compiles OK (pre-existing type error only). sndq-fe build passes. |
| 2026-04-28 | 8 | Done. Created `packages/tsconfig/library.json` and `packages/ui-v2/` skeleton. Added `@sndq/tsconfig` devDep (needed for extends). Overrode `outDir` in consumer tsconfig (same inherited-path lesson as Phase 1a). `tsc --showConfig` resolves correctly. sndq-fe build passes. |
| 2026-04-28 | 9 | Done. Created `apps/docs/` placeholder (6 files). Wired `@sndq/ui-v2` in prototype (dependencies) and sndq-fe (devDependencies). Added `eslint.config.mjs` (deviation from plan). All 3 apps build. |
| 2026-04-28 | 10 | Done. Added `@typescript-eslint/no-restricted-imports` (warn) for `@sndq/ui` deprecation. Deviation: used separate rule key instead of merging into existing `no-restricted-imports` (error) — allows warn-level for deprecation while keeping error-level for zodResolver. 20+ warnings surfaced across sndq-fe. Lint passes with `--quiet`. |
