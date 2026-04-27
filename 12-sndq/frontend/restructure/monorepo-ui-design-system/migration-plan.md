# UI Design System Migration Plan

Gradual, five-phase migration from legacy component libraries (`briicks/`, `ui/`, old `@sndq/ui` submodule) to the new `@sndq/ui-v2` package, with shared design tokens via `@sndq/config`.

**Created**: 2026-04-22
**Status**: Planning
**Architecture**: [README.md](./README.md)
**Ticket**: [ticket-migration.md](./ticket-migration.md)
**Phase 1a execution**: [phase-1a-execution.md](./phase-1a-execution.md) — step-by-step commits, risk checklists, verification commands
**Phase 1b execution**: [phase-1b-execution.md](./phase-1b-execution.md) — Briicks token extraction (folded into Phase 2)
**Phase 2 execution**: [phase-2-execution.md](./phase-2-execution.md) — prototype integration, token/CSS extraction, package scaffolding, deprecation

---

## Table of Contents

1. [Overview](#1-overview)
2. [Current vs Target](#2-current-vs-target)
3. [Phase 1a: Structural Foundation](#3-phase-1a-structural-foundation)
4. [Phase 1b: Tailwind Token Infrastructure (folded into Phase 2)](#4-phase-1b-tailwind-token-infrastructure-folded-into-phase-2)
5. [Phase 2: Prototype Integration + Deprecate Old Submodule](#5-phase-2-prototype-integration--deprecate-old-submodule)
6. [Phase 3: Standardize + Graduate to Package](#6-phase-3-standardize--graduate-to-package)
7. [Phase 4: Module-by-Module Migration](#7-phase-4-module-by-module-migration)
8. [Phase 5: Cleanup](#8-phase-5-cleanup)
9. [Deprecation Strategy](#9-deprecation-strategy)
10. [API Compatibility Matrix](#10-api-compatibility-matrix)
11. [Key Decisions Log](#11-key-decisions-log)
12. [Risks and Mitigations](#12-risks-and-mitigations)

---

## 1. Overview

### Goal

Replace three legacy UI component sources in `sndq-fe` with a single, standardized `@sndq/ui-v2` workspace package, backed by centralized design tokens in `@sndq/config`.

### Constraints

- **No big bang** — each phase is independently mergeable and verifiable
- **Old `@sndq/ui` submodule stays** until full cleanup (too many cross-module imports to remove early)
- **`sndq-ui-v2` only exists on a custom branch** (not on main/dev) — Phase 1 must not depend on it
- **UI-V2 components are prototypes** — they need standardization before becoming a formal package
- **APIs are incompatible** between briicks and ui-v2 — no re-export bridge, direct migration per module

### Key decisions summary

| Decision | Rationale |
|----------|-----------|
| Package named `@sndq/ui-v2` (not `@sndq/ui`) | Old submodule at `sndq-fe/packages/ui/` still resolves as `@sndq/ui` via tsconfig paths |
| No re-export bridge | API incompatibility makes adapters more work than direct migration |
| Gradual deprecation per-batch | Deprecation without available replacement is noise that developers learn to ignore |
| `@sndq/ui` submodule deprecated early (Phase 2) | Exception — prevents new imports without needing per-component replacement |
| Tokens extracted in two passes | Phase 1b: Briicks only (sndq-fe's subset). Phase 2: full UI-V2 semantic tokens (when prototype joins) |
| Components stay in `apps/prototype/` until standardized | Prevents polluting the formal package with prototype code |
| Pilot migration on small module first | `financial` has 44 cross-module exports — too risky for first test |

---

## 2. Current vs Target

### Current state

```
sndq/
├── sndq-fe/                         # Main app
│   ├── src/components/briicks/      # 55 wrapper components (3100+ imports)
│   ├── src/components/ui/           # 35 shadcn components (763 imports)
│   ├── packages/ui/                 # Git submodule → @sndq/ui (legacy)
│   └── src/app/globals.css          # 302 lines, Briicks tokens + shadcn vars
├── sndq-ui-v2/                      # Prototype app (custom branch only)
│   ├── src/components/ui-v2/        # 70 primitives + 9 blocks (prototype)
│   └── src/app/globals.css          # 984 lines, full token set + component CSS
├── package.json                     # Lerna root
├── pnpm-workspace.yaml              # ['sndq-fe', 'sndq-ui-v2']
└── lerna.json                       # ['sndq-fe'] (sndq-ui-v2 missing)
```

### Target state (after Phase 5)

```
sndq/
├── sndq-fe/                         # Main app (cleaned up)
│   ├── src/components/              # Business components only
│   ├── src/modules/                 # Domain modules (migrated to @sndq/ui-v2)
│   ├── tsconfig.json                # extends @sndq/tsconfig/nextjs.json
│   ├── eslint.config.mjs            # imports from @sndq/config/eslint.mjs
│   └── src/app/globals.css          # Imports from @sndq/config/tailwind/* + app theme only
├── apps/
│   ├── docs/                        # Standalone docs site — standardized components only
│   └── prototype/                   # Experimental playground (moved from sndq-ui-v2)
├── packages/
│   ├── ui-v2/                       # @sndq/ui-v2 — standardized components
│   │   ├── src/components/          # Primitives
│   │   └── src/blocks/              # Compositions
│   ├── config/                      # @sndq/config — ESLint, Prettier, Tailwind tokens
│   │   ├── eslint.mjs
│   │   ├── prettier.json
│   │   └── tailwind/                # tokens.css, components.css, animations.css
│   └── tsconfig/                    # @sndq/tsconfig — base, nextjs, library
├── package.json
├── pnpm-workspace.yaml              # ['sndq-fe', 'apps/*', 'packages/*']
└── lerna.json                       # ['sndq-fe', 'apps/*', 'packages/*']
```

### Dependency graph

```
sndq-fe ────────────────▶ @sndq/ui-v2
apps/prototype ─────────▶ @sndq/ui-v2
apps/docs ──────────────▶ @sndq/ui-v2

@sndq/ui-v2 ────────────▶ @sndq/config
all apps + packages ────▶ @sndq/config + @sndq/tsconfig
```

### What's removed

- `sndq-fe/src/components/briicks/` — replaced by `@sndq/ui-v2`
- `sndq-fe/src/components/ui/` — replaced by `@sndq/ui-v2`
- `sndq-fe/packages/ui/` — git submodule removed
- `sndq-ui-v2/` at root — moved to `apps/prototype/`

---

## 3. Phase 1a: Structural Foundation

**Goal**: Set up monorepo infrastructure. Zero visual or behavioral changes.

### Steps

1. Create `apps/` and `packages/` directories at monorepo root
2. Create `packages/tsconfig/` (`@sndq/tsconfig`):
   - `package.json`
   - `base.json` — common compiler options extracted from `sndq-fe/tsconfig.json` (minus `paths` and Next.js-specific options)
   - `nextjs.json` — extends base, adds Next.js-specific options (`noEmit`, `incremental`, `plugins`, `include`)
   - `library.json` deferred to Phase 2 (no library package exists yet)
3. Create `packages/config/` (`@sndq/config`) with ESLint + Prettier **only**:
   - `package.json`
   - `eslint.mjs` — `createEslintConfig(dirname)` function extracted from `sndq-fe/eslint.config.mjs`
   - `prettier.json` — extracted from `sndq-fe/.prettierrc.json`
4. Update `pnpm-workspace.yaml`: `['sndq-fe', 'apps/*', 'packages/*']`
5. Update `lerna.json` packages: `['sndq-fe', 'apps/*', 'packages/*']`
6. Update root `package.json` scripts (add `lint`, `type-check`)
7. Update `sndq-fe/tsconfig.json` to extend `@sndq/tsconfig/nextjs.json` + local `paths`
8. Update `sndq-fe/eslint.config.mjs` to import from `@sndq/config/eslint.mjs`
9. Update `sndq-fe/package.json`: replace `.prettierrc.json` with `"prettier": "@sndq/config/prettier.json"`
10. Add `@sndq/tsconfig` and `@sndq/config` as devDependencies in `sndq-fe`

### What's NOT in this phase

- No `sndq-ui-v2` involvement (it's on a custom branch)
- No Tailwind token extraction
- No design system changes

### Verification

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build       # sndq-fe builds successfully
pnpm lint        # ESLint passes with shared config
pnpm type-check  # tsc --noEmit passes with shared tsconfig
```

---

## 4. Phase 1b: Tailwind Token Infrastructure (folded into Phase 2)

> **Note**: Phase 1b was not included in the Phase 1 PR. It has been folded into Phase 2 as its first step, so all CSS/token extraction happens together when `sndq-ui-v2` joins the workspace. Commit 1 (create `tokens.css` + update `package.json` exports) is already done as a harmless pure addition. Commit 2 (swap in `sndq-fe/globals.css`) will execute as part of Phase 2. See [phase-1b-execution.md](./phase-1b-execution.md) for details.

**Goal**: Extract Briicks primitive tokens into `@sndq/config/tailwind/`, establishing the CSS package infrastructure for Phase 2.

### Steps

1. Create `packages/config/tailwind/tokens.css` with Briicks primitives only:
   - Brand colors (`--color-brand-25` through `--color-brand-900`)
   - Neutral colors (`--color-neutral-0` through `--color-neutral-900`)
   - Success colors (`--color-success-25` through `--color-success-900`)
   - Warning colors (`--color-warning-25` through `--color-warning-900`)
   - Error colors (`--color-error-25` through `--color-error-900`)
   - Type scale (`--font-size-xs` through `--font-size-3xl`, weights, line-heights)
   - Spacing scale (`--spacing-1` through `--spacing-12`)
   - Radius (`--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-full`)
   - Source: `sndq-fe/src/app/globals.css` lines 57-156 (inside `@theme inline`)
2. Update `packages/config/package.json` exports to include `./tailwind/tokens.css`
3. Update `sndq-fe/src/app/globals.css`:
   - Add `@import '@sndq/config/tailwind/tokens.css';`
   - Remove the duplicated Briicks color/type/spacing/radius block (~100 lines)
   - Keep the shadcn `@theme inline` mappings, `:root`/`.dark` vars, `@layer base`
4. Add `@sndq/config` as dependency in `sndq-fe` (if not already from Phase 1a)

### What's NOT in this phase

- No UI-V2 semantic tokens (`--ui-action`, `--ui-surface`, etc.) — those only exist in `sndq-ui-v2`
- No component CSS classes (`.ui-btn`, `.ui-control`, etc.)
- No animations

### Verification

- Visual diff: open `sndq-fe` locally, compare against production — zero style changes
- `pnpm build` passes

---

## 5. Phase 2: Prototype Integration + Deprecate Old Submodule

**Goal**: Bring `sndq-ui-v2` into the monorepo, complete the design token extraction, scaffold the `@sndq/ui-v2` package, and prevent new imports from the old submodule.

### Prerequisites

- Phase 1a is merged to dev
- `sndq-ui-v2` custom branch is rebased onto the restructured dev

### Steps

1. `git mv sndq-ui-v2 apps/prototype`
2. Update `apps/prototype/package.json` name to `@sndq/prototype`
3. **Extract Briicks primitive tokens into `sndq-fe`** (from Phase 1b — `tokens.css` already created in Phase 1a branch):
   - Update `sndq-fe/src/app/globals.css`: add `@import '@sndq/config/tailwind/tokens.css';`, remove the duplicated Briicks color/type/spacing/radius block (~100 lines), remove dead shadcn radius lines (52-54)
   - See [phase-1b-execution.md](./phase-1b-execution.md) Commit 2 for full details and risks
4. Add UI-V2 semantic tokens to `packages/config/tailwind/tokens.css`:
   - Action tokens (`--ui-action`, `--ui-action-hover`, `--ui-action-fg`, etc.)
   - Surface tokens (`--ui-surface`, `--ui-surface-subtle`, `--ui-surface-muted`)
   - Text tokens (`--ui-text`, `--ui-text-secondary`, `--ui-text-tertiary`, etc.)
   - Border tokens (`--ui-border`, `--ui-border-strong`, `--ui-border-focus`, `--ui-ring`)
   - Status tokens (success, warning, error, info groups)
   - Typography tokens (`--ui-text-xs` through `--ui-text-7xl`, font families)
   - Control sizing (`--ui-h-sm`, `--ui-h`, `--ui-h-lg`)
   - Radius (`--ui-r-xs` through `--ui-r-full`)
   - Shadow (`--ui-shadow-xs`, `--ui-shadow-sm`, `--ui-shadow-md`, insets)
   - Source: `apps/prototype/src/app/globals.css` lines 164-269
5. Create `packages/config/tailwind/components.css` with UI-V2 component CSS:
   - `.ui-control`, `.ui-input-wrap`, `.ui-btn` + all variants/sizes
   - `.ui-menu`, `.ui-item`, `.ui-menu-label`, `.ui-separator`
   - `.ui-label`, `.ui-helper`, `.ui-error-msg`
   - `.ui-badge`, `.ui-card`, `.font-heading`
   - Source: `apps/prototype/src/app/globals.css` lines 546-975
6. Create `packages/config/tailwind/animations.css` with shared keyframes:
   - `ui-hide`, `ui-slideDownAndFade`, `ui-slideUpAndFade`, `ui-slideLeftAndFade`, `ui-slideRightAndFade`
   - `ui-dialogOverlayShow`, `ui-dialogContentShow`
   - `ui-accordionOpen`, `ui-accordionClose`
   - `ui-drawerSlideIn`, `ui-drawerSlideOut`
   - `collapsible-down`, `collapsible-up`, `ai-progress`
   - Source: `apps/prototype/src/app/globals.css` lines 271-441
7. Update `packages/config/package.json` exports to include all three tailwind files
8. Update `apps/prototype/src/app/globals.css`:
   - Replace the ~700 lines of tokens/components/animations with imports from `@sndq/config/tailwind/*`
   - Keep app-specific `:root`/`.dark` shadcn vars, `@layer base`
9. Add ESLint config to prototype: create `apps/prototype/eslint.config.mjs` importing from `@sndq/config/eslint.mjs`
10. Add Prettier config to prototype via `package.json`: `"prettier": "@sndq/config/prettier.json"`
11. Update `apps/prototype/tsconfig.json` to extend `@sndq/tsconfig/nextjs.json`
12. Create `packages/ui-v2/` (`@sndq/ui-v2`) as **empty skeleton**:
    - `package.json` with name `@sndq/ui-v2`, `workspace:*` dependency on `@sndq/config`
    - `tsconfig.json` extending `@sndq/tsconfig/library.json`
    - Empty `src/components/index.ts` and `src/blocks/index.ts`
13. Create `apps/docs/` as **minimal Next.js app**:
    - `package.json` depending on `@sndq/ui-v2` (`workspace:*`)
    - Placeholder `src/app/page.tsx` ("Component Docs — coming soon")
    - `tsconfig.json` extending `@sndq/tsconfig/nextjs.json`
14. Wire `@sndq/ui-v2` as `workspace:*` dependency in all apps
15. **Deprecate old submodule** — add ESLint `no-restricted-imports` rule to `sndq-fe/eslint.config.mjs`:

```javascript
'no-restricted-imports': ['warn', {
  patterns: [{
    group: ['@sndq/ui', '@sndq/ui/*'],
    message: 'Deprecated: do not add new imports. Will be replaced by @sndq/ui-v2.',
  }],
}],
```

### What stays unchanged

- `sndq-fe/packages/ui/` git submodule — untouched
- `sndq-fe/src/components/briicks/` — no deprecation yet (no replacement available)
- `sndq-fe/src/components/ui/` — no deprecation yet
- Components remain in `apps/prototype/src/components/ui-v2/` — they are prototypes, not graduated
- `apps/docs/` is a placeholder — content arrives as components graduate in Phase 3

### Verification

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build           # both apps build
pnpm lint            # prototype now has ESLint
pnpm type-check      # both apps pass tsc
# Open both apps — visual comparison against before
```

---

## 6. Phase 3: Standardize + Graduate to Package

**Goal**: Standardize prototype components in batches. After each batch passes quality gates, move components into `packages/ui-v2/` and deprecate their legacy counterparts.

### Package state

`packages/ui-v2/` already exists from Phase 2 as an empty skeleton, wired as `workspace:*` in all apps. Ready to receive graduated components.

### Per-batch workflow

```
1. Standardize in apps/prototype/
   - Props audit: define stable interfaces, add JSDoc
   - Ensure extensibility (className forwarding, ref forwarding, asChild where appropriate)
   - Unit tests: rendering, variant coverage, accessibility, keyboard interaction
   - Storybook/playground pages stay in apps/prototype/

2. Graduate to packages/ui-v2/
   - Move component files from apps/prototype/src/components/ui-v2/ to packages/ui-v2/src/components/
   - Move block files to packages/ui-v2/src/blocks/
   - Add to barrel exports (src/components/index.ts or src/blocks/index.ts)
   - Update imports in apps/prototype/ and apps/docs/ to use @sndq/ui-v2/components

3. Deprecate legacy counterparts
   - Add JSDoc @deprecated to the specific briicks/ and ui/ exports that now have a replacement
   - Message: "Use {ComponentName} from @sndq/ui-v2/components instead."

4. Verify
   - pnpm build && pnpm type-check
   - Run component tests
   - Visual check in prototype app and docs app
```

### Batch priority

| Batch | Components | Legacy counterparts to deprecate |
|-------|-----------|----------------------------------|
| **1** | Button, Input, Badge, Select, Dialog, Sheet | `briicks/button`, `briicks/input`, `briicks/badge`, `briicks/select`, `ui/dialog`, `ui/sheet` |
| **2** | Card, Tabs, Tooltip, EmptyState, Skeleton | `briicks/empty-state`, `ui/card`, `ui/tabs`, `ui/tooltip`, `ui/skeleton` |
| **3** | Remaining components | Remaining counterparts |

### Deprecation example (after Batch 1)

```typescript
// sndq-fe/src/components/briicks/button/index.ts

/** @deprecated Use Button from @sndq/ui-v2/components instead. */
export { Button, buttonVariants, type ButtonProps } from './button';

/** @deprecated Use ComboButton from @sndq/ui-v2/components instead. */
export { ComboButton, type ComboButtonProps } from './combo-button';
```

```typescript
// sndq-fe/src/components/ui/dialog.tsx

/** @deprecated Use Dialog from @sndq/ui-v2/components instead. */
export { Dialog, DialogContent, DialogHeader, DialogFooter, ... };
```

### Definition of "standardized"

A component is ready to graduate when it has:

- [ ] Stable prop interface with JSDoc documentation
- [ ] `className` forwarding via `cn()` for style overrides
- [ ] `ref` forwarding where applicable
- [ ] Unit tests covering all variants and key interactions
- [ ] No imports from app-specific code (hooks, services, translations)
- [ ] Uses `@sndq/config/tailwind` tokens and component CSS classes

---

## 7. Phase 4: Module-by-Module Migration

**Goal**: Replace legacy component imports in `sndq-fe` modules with `@sndq/ui-v2` imports, module by module.

### Approach

**Direct migration** — no re-export bridge. Each module PR changes imports AND updates prop usage in the same diff. This is necessary because the APIs are incompatible (see [API Compatibility Matrix](#10-api-compatibility-matrix)).

### Per-module workflow

```
1. Pick a module from the migration order
2. Find all imports from @/components/briicks, @/components/ui, @sndq/ui
3. For each import:
   - Change import path to @sndq/ui-v2/components or @sndq/ui-v2/blocks
   - Update prop usage (variant names, prop shapes — see API matrix)
   - If a component has no ui-v2 equivalent yet, skip it (both imports coexist)
4. Visual regression test the module's pages
5. Submit PR
```

### Migration order

1. **Pilot**: small module (`peppol` or `search-result`) — low risk, few imports, validates the process
2. **Financial**: the most complex module (44 cross-module exports) — with confidence from the pilot
3. **Remaining modules** in waves, grouped by complexity or team ownership:
   - Wave A: `bookkeeping`, `contact-book`, `patrimony`
   - Wave B: `accounts`, `broadcasts`, `passport`
   - Wave C: `home`, `inbox`, `email-settings`, remaining

### What changes per file

```typescript
// BEFORE
import { Button, InputV2, Badge } from '@/components/briicks';
import { Dialog, DialogContent } from '@/components/ui/dialog';

<Button variant="neutralSecondary" tooltip="Save">Save</Button>
<InputV2 leading="search" error={hasError} />
<Badge variant="successSaturated" actionIcon="x" onActionClick={dismiss}>Active</Badge>

// AFTER
import { Button, Input, Badge } from '@sndq/ui-v2/components';
import { Dialog, DialogContent } from '@sndq/ui-v2/components';

<Tooltip content="Save"><Button variant="secondary">Save</Button></Tooltip>
<Input leadingIcon={<Search />} error={errorMessage} />
<Badge variant="success">Active</Badge>
```

---

## 8. Phase 5: Cleanup

**Goal**: Remove all legacy component sources and the old submodule. Final bundle optimization.

### Steps

1. Remove `sndq-fe/src/components/briicks/` directory entirely
2. Remove `sndq-fe/src/components/ui/` directory entirely
3. Remove `sndq-fe/packages/ui/` git submodule:
   - `git submodule deinit sndq-fe/packages/ui`
   - `git rm sndq-fe/packages/ui`
   - Remove entry from `.gitmodules`
4. Remove `@sndq/ui` path aliases from `sndq-fe/tsconfig.json`:
   ```json
   // Remove these lines
   "@sndq/ui": ["./packages/ui/src"],
   "@sndq/ui/*": ["./packages/ui/src/*"]
   ```
5. Remove `no-restricted-imports` ESLint rule for `@sndq/ui` (no imports left)
6. Optional: rename `@sndq/ui-v2` to `@sndq/ui` (bulk find-replace across the codebase)
7. Bundle size audit: compare before/after, ensure no duplicate component code

### Verification

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
pnpm test
# Full visual regression test across all modules
```

---

## 9. Deprecation Strategy

Two-tier approach, timed to maximize signal and minimize noise.

### Tier 1: Old submodule (`@sndq/ui`) — Phase 2

**Method**: ESLint `no-restricted-imports` (cannot edit the submodule directly)

```javascript
// sndq-fe/eslint.config.mjs
{
  rules: {
    'no-restricted-imports': ['warn', {
      patterns: [{
        group: ['@sndq/ui', '@sndq/ui/*'],
        message: 'Deprecated: do not add new imports. Will be replaced by @sndq/ui-v2.',
      }],
    }],
  },
}
```

**Why early**: The old submodule is being replaced wholesale — no per-component timing needed. The rule prevents new debt accumulation while replacements are built.

**What developers see**: Yellow squiggly line in IDE, warning in `pnpm lint` output, visible in CI.

### Tier 2: briicks/ and ui/ — Phase 3, per-batch

**Method**: JSDoc `@deprecated` on barrel exports, added only after the specific replacement has graduated to `packages/ui-v2/`

```typescript
/** @deprecated Use Button from @sndq/ui-v2/components instead. */
export { Button } from './button';
```

**Why gradual**: A deprecation warning without an available replacement is noise. Developers learn to ignore warnings, which undermines the system. Each warning comes with a concrete alternative.

**What developers see**: Strikethrough text on imports in IDE, hover message with migration target.

### Deprecation timeline

| Phase | What gets deprecated | Method |
|-------|---------------------|--------|
| Phase 2 | `@sndq/ui`, `@sndq/ui/*` | ESLint `no-restricted-imports` |
| Phase 3, Batch 1 | Button, Input, Badge, Select, Dialog, Sheet in briicks/ui | JSDoc `@deprecated` |
| Phase 3, Batch 2 | Card, Tabs, Tooltip, EmptyState, Skeleton in briicks/ui | JSDoc `@deprecated` |
| Phase 3, Batch 3 | Remaining briicks/ui exports | JSDoc `@deprecated` |
| Phase 5 | All removed | Directories deleted |

---

## 10. API Compatibility Matrix

The briicks and ui-v2 component APIs are **not drop-in compatible**. Direct migration requires changing prop usage at every call site.

### Button

| Aspect | briicks | ui-v2 | Migration action |
|--------|---------|-------|------------------|
| Variant names | `default`, `neutralSecondary`, `neutralTertiary`, `brandTertiary`, `destructive`, `destructiveSecondary`, `destructiveTertiary`, `outline`, `secondary`, `ghost`, `link`, `primary`, `success`, `successSecondary`, `warning` (15) | `primary`, `secondary`, `ghost`, `destructive`, `light`, `warning`, `white`, `black` (8) | Map variant names per call site |
| Sizes | `default`, `sm`, `lg`, `icon` | `sm`, `md`, `lg`, `icon` | `default` → `md` |
| `tooltip` prop | Supported (wraps in Tooltip) | Not supported | Wrap with standalone `<Tooltip>` |
| `loading` prop | Not supported | Supported (`loading`, `loadingText`) | New capability, no migration needed |
| CSS system | CVA + Tailwind utilities | `.ui-btn` + semantic tokens | Automatic via component swap |

### Input

| Aspect | briicks `InputV2` | ui-v2 `Input` | Migration action |
|--------|-------------------|---------------|------------------|
| Label | Not built-in (external) | `label` prop | Move label into component |
| Error | `error: boolean` | `error: string` (message text) | Change from boolean to error message string |
| Helper text | Not built-in | `helperText` prop | Move helper text into component |
| Leading icon | `leading: IconName \| ReactNode` | `leadingIcon: ReactNode \| null` | Change prop name, use `<Icon />` JSX instead of string |
| Trailing | `trailing: IconName \| ReactNode` | `trailingAction: ReactNode` | Change prop name |
| Validation state | `validationState`, `showValidation`, `validationIcon` | Derived from `error` prop presence | Remove validation props, use `error` string |

### Badge

| Aspect | briicks | ui-v2 | Migration action |
|--------|---------|-------|------------------|
| Variants | 15+ including `*Saturated` variants | `neutral`, `brand`, `success`, `warning`, `error` (5) | Map to closest semantic variant |
| `asChild` | Supported | Not supported | Remove or wrap differently |
| Action/dismiss | `actionIcon`, `onActionClick`, `actionLabel` | Not supported | Build dismiss behavior in consuming code |

---

## 11. Key Decisions Log

### Why `@sndq/ui-v2` not `@sndq/ui`

The old `@sndq/ui` submodule at `sndq-fe/packages/ui/` is still heavily used and resolves via tsconfig path aliases. Creating a new `@sndq/ui` workspace package would conflict. Using `-v2` avoids ambiguity during the coexistence period. Can be renamed after cleanup in Phase 5.

### Why no re-export bridge

The APIs between briicks and ui-v2 are incompatible across all three key components we analyzed:
- Button: 15 variants vs 8, different names, briicks has `tooltip` that ui-v2 lacks
- Input: completely different prop model (briicks: validation-focused, no label; ui-v2: form-field wrapper with built-in label/error)
- Badge: briicks has action/dismiss features that ui-v2 doesn't support

A bridge adapter would need per-component mapping logic that's as much work as direct migration, plus creates an adapter layer that becomes permanent tech debt.

### Why gradual deprecation per-batch (not upfront)

Deprecating all of briicks/ui at once when no replacement exists creates warnings developers can't act on. This teaches the team to ignore warnings, which undermines the deprecation system permanently. Each batch deprecation comes with a concrete "use X instead" message.

### Why `@sndq/ui` submodule is the exception (deprecated early)

Unlike briicks/ui components (which need 1:1 replacements), the submodule is a whole package being sunset. The ESLint rule blocks new imports from accumulating — it's about preventing new debt, not forcing migration of existing code. Also, we can't edit the submodule to add `@deprecated` JSDoc.

### Why pilot on a small module first

The detection script showed `financial` has 44 cross-module component exports — the most of any module. Starting migration there means the first attempt hits the hardest case. A small module like `peppol` (4 cross-module imports) or `search-result` (2 imports) validates the migration process with minimal risk.

### Why extract tokens in two passes

Phase 1b extracts only Briicks primitive tokens (~140 lines) that `sndq-fe` currently uses. UI-V2 semantic tokens and component CSS classes (~680 lines) only exist in `sndq-ui-v2`, which isn't in the monorepo until Phase 2. Extracting the full set in Phase 1b would mean extracting tokens with no consumer — they'd be untested and potentially wrong.

### Why components stay in `apps/prototype/` until standardized

Moving unstandardized prototypes into `packages/ui-v2/` would signal "these are ready to use" when they're not. Developers might import them, build features, then face breaking changes during standardization. Keeping them in the prototype app until they pass quality gates prevents this.

### Why no shared docs package

Both `apps/docs/` and `apps/prototype/` import `@sndq/ui-v2` directly and manage their own showcase UI locally. A shared docs package added indirection without enough benefit — each app has different presentation needs and can evolve independently.

---

## 12. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Import path breakage during restructuring | Build failures | Phase-by-phase approach; each phase verified with `pnpm build && pnpm type-check` |
| Visual regression from token extraction | UI looks different | Extract identical values; visual diff comparison before/after each phase |
| `sndq-ui-v2` branch diverges too far from dev | Painful merge in Phase 2 | Rebase the custom branch onto dev after Phase 1 merges |
| Standardization takes too long, blocks migration | Migration stalls | Batch approach — Phase 4 can start after Batch 1, doesn't wait for all batches |
| Developers ignore deprecation warnings | New legacy imports accumulate | Use `warn` initially; escalate to `error` in ESLint after sufficient time |
| API differences cause subtle bugs during migration | Runtime errors in migrated modules | Visual regression testing per module; pilot on small module first |
| CI/CD path references break | Deploy failures | Update GitHub Actions and Vercel configs in Phase 2 when paths change |
| Old submodule conflicts with new package | Build confusion | Different names (`@sndq/ui` vs `@sndq/ui-v2`), different resolution mechanisms (tsconfig paths vs workspace) |

---

## Related Documents

- [Architecture Document](./README.md) — full target structure, config contents, component inventory
- [Migration Ticket](./ticket-migration.md) — concise summary for Linear
- [Component Structure](./ticket-component-structure.md) — three-tier model
- [Component Lifting Process](./component-lifting-process.md) — four-tier promotion model
- [Detection Script Guide](./detect-cross-imports-guide.md) — how to find lift candidates
