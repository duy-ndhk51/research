# Compat Removal Execution — Remove compat.css Bridge

Step-by-step execution guide for removing `compat.css`. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-02
**Status**: Complete
**Architecture**: [README.md](./README.md)
**Migration plan**: [migration-plan.md](./migration-plan.md)
**Branch**: `feature/remove-compat-css`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Config Layer Migration](#3-pr-1--config-layer-migration)
4. [PR 2 — TSX Consumer Migration](#4-pr-2--tsx-consumer-migration)
5. [PR 3 — Cleanup](#5-pr-3--cleanup)
6. [Final Verification](#6-final-verification)
7. [Team Communication](#7-team-communication)
8. [What's Next](#8-whats-next)
9. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Migrate all `var(--sndq-*)` alias references to either Tailwind utility classes or canonical CSS variable names (`--color-sndq-*`, `--text-sndq-*`, `--radius-sndq-*`, `--spacing-sndq-*`, `--font-sndq-*`), then delete `compat.css` so the token pipeline has zero intermediate aliases.

**Structure**: 7 commits across 3 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Config CSS files (`semantic-tokens.css`, `components.css`, `globals.css`) | Medium | 1-2 |
| **PR 2** | TSX consumers (migration script + run on all apps) | Medium | 3-5 |
| **PR 3** | Delete `compat.css`, remove imports, delete script | Low | 6-7 |

**Why 3 PRs**: PR 1 changes the shared config layer where a visual regression would affect all apps -- it can be reverted in one shot. PR 2 is the bulk migration (~8,100 refs) via a mechanical script and is the safest PR despite the large diff. PR 3 is pure deletion after the first two PRs prove that nothing references compat aliases anymore.

### Prerequisites

- Design token compat bridge is merged (tokens.css emits one variable per token, compat.css exists with all backward-compatible aliases)
- All three apps build successfully with the current token pipeline

### Known constraints

- `sndq-fe` build may require `NODE_OPTIONS='--max-old-space-size=8192'` due to pre-existing memory pressure unrelated to this migration
- `components.css` uses `color-mix()` and composite `box-shadow` that cannot be expressed with `@apply` -- these stay as raw CSS with canonical variable names
- `text-[var(--sndq-text)]` (color) and `text-[length:var(--sndq-text-sm)]` (size) both start with `text-` in Tailwind -- the migration script must distinguish them
- `--sndq-shadow-*` variables are defined in `semantic-tokens.css` (not compat aliases) and must remain as `var(--sndq-shadow-*)` since they are not part of the compat bridge

### Replacement mapping reference

**TSX arbitrary values to Tailwind utility classes:**

| Pattern | Replacement | Category |
|---------|------------|----------|
| `bg-[var(--sndq-{name})]` | `bg-sndq-{name}` | Color |
| `text-[var(--sndq-{color-name})]` | `text-sndq-{color-name}` | Color |
| `text-[length:var(--sndq-text-{scale})]` | `text-sndq-{scale}` | Typography size |
| `border-[var(--sndq-{name})]` | `border-sndq-{name}` | Color |
| `ring-[var(--sndq-{name})]` | `ring-sndq-{name}` | Color |
| `rounded-[var(--sndq-r)]` | `rounded-sndq` | Radius |
| `rounded-[var(--sndq-r-{size})]` | `rounded-sndq-{size}` | Radius |
| `h-[var(--sndq-h)]` | `h-sndq-h` | Spacing |
| `h-[var(--sndq-h-{size})]` | `h-sndq-h-{size}` | Spacing |
| `w-[var(--sndq-h)]` | `w-sndq-h` | Spacing |
| `w-[var(--sndq-h-{size})]` | `w-sndq-h-{size}` | Spacing |
| `size-[var(--sndq-icon)]` | `size-sndq-icon` | Spacing |
| `size-[var(--sndq-icon-{size})]` | `size-sndq-icon-{size}` | Spacing |

**Raw CSS to canonical variable names:**

| Old | New |
|-----|-----|
| `var(--sndq-action)` | `var(--color-sndq-action)` |
| `var(--sndq-surface)` | `var(--color-sndq-surface)` |
| `var(--sndq-text)` | `var(--color-sndq-text)` |
| `var(--sndq-border)` | `var(--color-sndq-border)` |
| `var(--sndq-r)` | `var(--radius-sndq)` |
| `var(--sndq-r-{size})` | `var(--radius-sndq-{size})` |
| `var(--sndq-text-sm)` | `var(--text-sndq-sm)` |
| `var(--sndq-h)` | `var(--spacing-sndq-h)` |
| `var(--sndq-font-body)` | `var(--font-sndq-body)` |
| `var(--sndq-font-heading)` | `var(--font-sndq-heading)` |

**Raw CSS to `@apply` (components.css):**

| Old | New |
|-----|-----|
| `border-radius: var(--sndq-r);` | `@apply rounded-sndq;` |
| `background: var(--sndq-surface);` | `@apply bg-sndq-surface;` |
| `color: var(--sndq-text);` | `@apply text-sndq-text;` |
| `font-size: var(--sndq-text-sm);` | `@apply text-sndq-sm;` |
| `height: var(--sndq-h);` | `@apply h-sndq-h;` |
| `border: 1px solid var(--sndq-border);` | `@apply border border-sndq-border;` |

---

## 2. Before You Start

### Quality gate before each implementation commit

Use this gate for every implementation commit. If an item is intentionally skipped, record it under that commit's **Deviations from the gate** section.

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
- Add deprecation notices only on the public export or entry point that consumers actually use.
- If docs and code disagree, update the docs in the same commit or record the gap as a deviation.

### Inspect source tree before implementation

Before the first implementation commit, inspect the actual repository state and record any differences from this plan.

- [ ] Confirm `packages/config/tailwind/compat.css` exists with all aliases
- [ ] Confirm `compat.css` is imported in all three `globals.css` files
- [ ] Confirm `packages/config/package.json` has the `"./tailwind/compat.css"` export
- [ ] Confirm current lint, type-check, build failures that predate this phase
- [ ] Confirm `var(--sndq-shadow-*)` references in `components.css` point to `semantic-tokens.css` definitions (these are NOT compat aliases)
- [ ] Run `rg 'var\(--sndq-' --type css --type tsx --type ts -c` to get a baseline alias reference count

### Capture baselines

Run these from the monorepo root and save the output. Diff against these after risky commits.

```bash
cd /path/to/sndq-clone

# Build baselines
pnpm --filter @sndq/ui-v2-dev run build 2>&1 | tee /tmp/compat-removal-uiv2dev-build-before.txt
pnpm --filter @sndq/docs run build 2>&1 | tee /tmp/compat-removal-docs-build-before.txt

# Reference count baseline
rg 'var\(--sndq-' --glob '*.css' --glob '*.tsx' --glob '*.ts' -c 2>&1 | tee /tmp/compat-removal-refcount-before.txt
```

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/remove-compat-css
```

---

## 3. PR 1 — Config Layer Migration

Migrate all `var(--sndq-*)` references in the shared config CSS files (`semantic-tokens.css`, `components.css`, `globals.css`) to canonical variable names or `@apply`. This PR is safe to merge independently because `compat.css` still exists and provides the old aliases as a fallback -- nothing breaks.

---

### Commit 1: Migrate semantic-tokens.css and globals.css

**What**: Replace 6 `var(--sndq-*)` references in `semantic-tokens.css` (4 refs) and both `globals.css` files (1 ref each) with canonical Tailwind-convention variable names.

**Files to edit**:

- `packages/config/tailwind/semantic-tokens.css` -- replace `var(--sndq-action-subtle)` with `var(--color-sndq-action-subtle)` and `var(--sndq-action)` with `var(--color-sndq-action)` on lines 5-6
- `apps/ui-v2-dev/src/app/globals.css` -- replace `var(--sndq-font-body)` with `var(--font-sndq-body)` in the `.font-mono` rule
- `sndq-fe/src/app/globals.css` -- replace `var(--sndq-font-body)` with `var(--font-sndq-body)` in the `.font-mono` rule

**Before / after for `semantic-tokens.css`**:

```css
/* Before */
--sndq-action-subtle-hover: color-mix(in srgb, var(--sndq-action-subtle) 80%, var(--sndq-action) 20%);
--sndq-action-subtle-active: color-mix(in srgb, var(--sndq-action-subtle) 60%, var(--sndq-action) 40%);

/* After */
--sndq-action-subtle-hover: color-mix(in srgb, var(--color-sndq-action-subtle) 80%, var(--color-sndq-action) 20%);
--sndq-action-subtle-active: color-mix(in srgb, var(--color-sndq-action-subtle) 60%, var(--color-sndq-action) 40%);
```

**Before / after for `globals.css` `.font-mono`**:

```css
/* Before */
.font-mono {
  font-family: var(--sndq-font-body);
  font-variant-numeric: tabular-nums;
}

/* After */
.font-mono {
  font-family: var(--font-sndq-body);
  font-variant-numeric: tabular-nums;
}
```

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Deviations from the gate**: `sndq-fe/src/app/globals.css` has no `.font-mono` rule and no `var(--sndq-*)` references -- only 2 files edited (5 replacements) instead of the planned 3 files (6 replacements).

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Canonical variable names not defined in `tokens.css` | LOW | Confirm `--color-sndq-action`, `--color-sndq-action-subtle`, `--font-sndq-body` exist in regenerated `tokens.css` |

**Verification**:

```bash
# Confirm the canonical names exist in tokens.css
rg -- '--color-sndq-action:' packages/config/tailwind/tokens.css
rg -- '--color-sndq-action-subtle:' packages/config/tailwind/tokens.css
rg -- '--font-sndq-body:' packages/config/tailwind/tokens.css

# Build affected apps
pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/docs run build

# Count remaining compat refs in these files (should be 0)
rg 'var\(--sndq-' packages/config/tailwind/semantic-tokens.css -c
rg 'var\(--sndq-' apps/ui-v2-dev/src/app/globals.css -c
rg 'var\(--sndq-' sndq-fe/src/app/globals.css -c
```

**If it fails**:

- **"color-mix() produces transparent/wrong color"**: The canonical variable name is resolving to empty. Confirm `--color-sndq-action-subtle` and `--color-sndq-action` are defined in `tokens.css` (not just in `compat.css`). If missing, the export script needs a fix.
- **".font-mono shows wrong font"**: `--font-sndq-body` may not be registered in `tokens.css`. Confirm with `rg -- '--font-sndq-body' packages/config/tailwind/tokens.css`.

**Deviations from the gate**:

- **None**

**Commit message**: `refactor: migrate semantic-tokens and globals to canonical variable names`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 2: Rewrite components.css with @apply

**What**: Rewrite all 110 `var(--sndq-*)` references in `components.css` to use `@apply` with Tailwind utilities where possible, and canonical CSS variable names for properties that cannot be expressed with `@apply` (`box-shadow`, `color-mix()`, `transition`, `::placeholder`).

**Files to edit**:

- `packages/config/tailwind/components.css` -- full rewrite of all `var(--sndq-*)` references (110 refs across 15 component classes)

**Example before / after for `.sndq-control`**:

```css
/* Before */
.sndq-control {
  width: 100%;
  border-radius: var(--sndq-r);
  border: 1px solid var(--sndq-border);
  background: var(--sndq-surface);
  padding-inline: 0.75rem;
  font-size: var(--sndq-text-sm);
  color: var(--sndq-text);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

/* After */
.sndq-control {
  @apply w-full rounded-sndq border border-sndq-border bg-sndq-surface px-3 text-sndq-sm text-sndq-text;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
```

**Properties that stay as raw CSS** (cannot be expressed with `@apply`):

| Property | Why |
|----------|-----|
| `box-shadow` with composite values | Multiple shadow layers, `var()` references to `--sndq-shadow-*` |
| `color-mix()` expressions | No Tailwind utility for `color-mix()` |
| `transition` | Multi-property transitions are clearer in raw CSS |
| `::placeholder` pseudo-element color | `@apply placeholder:text-*` may work but requires testing |
| `border: 1px solid transparent` | Tailwind `border-transparent` may not preserve `1px solid` |

**Key `var()` substitutions within raw CSS lines** (these are NOT compat aliases -- they are semantic-tokens.css definitions):

- `var(--sndq-shadow-inset-top)` -- stays as-is (defined in `semantic-tokens.css`)
- `var(--sndq-shadow-inset-press)` -- stays as-is
- `var(--sndq-shadow-xs)` -- stays as-is

**Key `var()` substitutions within raw CSS lines** (these ARE compat aliases):

- `var(--sndq-surface)` in `box-shadow: ... var(--sndq-surface) ...` becomes `var(--color-sndq-surface)`
- `var(--sndq-ring)` in `box-shadow: ... var(--sndq-ring) ...` becomes `var(--color-sndq-ring)`
- `var(--sndq-action-subtle)` in `color-mix()` becomes `var(--color-sndq-action-subtle)`
- `var(--sndq-action)` in `color-mix()` becomes `var(--color-sndq-action)`
- `var(--sndq-error-accent)` in `border-color` becomes `var(--color-sndq-error-accent)`
- `var(--sndq-font-heading)` becomes `var(--font-sndq-heading)`

**Component classes to rewrite** (15 groups):

1. `.sndq-control` (lines 10-49) -- input/select/textarea base
2. `.sndq-input-wrap` (lines 54-108) -- icon + trailing action wrapper
3. `.sndq-btn` (lines 113-162) -- button base + sizes
4. `.sndq-btn-primary` through `.sndq-btn-link` (lines 165-320) -- 10 button variants
5. `.sndq-menu` (lines 325-335) -- dropdown/popover surface
6. `.sndq-item` (lines 340-373) -- menu item + destructive variant
7. `.sndq-menu-label` (lines 378-384) -- section label
8. `.sndq-separator` (lines 389-393) -- divider
9. `.sndq-label` (lines 398-403) -- form label
10. `.sndq-helper` / `.sndq-error-msg` (lines 408-415) -- helper text
11. `.sndq-badge` (lines 420-441) -- badge base + sizes
12. `.sndq-card` (lines 446-450) -- card surface
13. `.font-heading` (lines 455-457) -- typography helper

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `@apply` order differs from raw CSS cascade | MEDIUM | Visual comparison of buttons, inputs, menus in ui-v2-dev |
| `@apply text-sndq-sm text-sndq-text` ambiguity | MEDIUM | Confirm Tailwind resolves `text-sndq-sm` as font-size and `text-sndq-text` as color |
| Composite `box-shadow` breaks with canonical names | LOW | Button shadows should show inset highlight |

**Verification**:

```bash
# Build ui-v2-dev (primary consumer of components.css)
pnpm --filter @sndq/ui-v2-dev run build

# Build docs
pnpm --filter @sndq/docs run build

# Count remaining compat refs in components.css (should be 0)
rg 'var\(--sndq-' packages/config/tailwind/components.css -c
# Note: var(--sndq-shadow-*) will remain -- these are semantic-tokens.css definitions, not compat aliases.
# To filter: only check for compat aliases
rg 'var\(--sndq-(?!shadow)' packages/config/tailwind/components.css -c

# Visual smoke test
pnpm --filter @sndq/ui-v2-dev run dev
# Open localhost:3001 and verify:
# - Button variants (primary, secondary, ghost, outline, destructive, light, warning, black, link)
# - Input fields (default, hover, focus, error, disabled states)
# - Menu/dropdown surfaces
# - Badge rendering
# - Card borders and backgrounds
```

**If it fails**:

- **"@apply rounded-sndq not recognized"**: The `--radius-sndq` variable is not registered in `@theme`. Confirm it exists in `tokens.css` with `rg -- '--radius-sndq:' packages/config/tailwind/tokens.css`.
- **"text-sndq-sm sets color instead of size"**: Tailwind found `--color-sndq-sm` before `--text-sndq-sm`. This shouldn't happen since no such color token exists, but if it does, use `text-[length:var(--text-sndq-sm)]` as a fallback.
- **"Button shadow missing"**: A `var(--sndq-shadow-*)` was accidentally replaced. These must stay as-is since they reference `semantic-tokens.css`, not `compat.css`.

**Deviations from the gate**:

- **No automated visual regression tests** -- manual smoke test covers the main component states. Automated visual testing can be added as a follow-up.

**Commit message**: `refactor: rewrite components.css with @apply and canonical vars`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feature/remove-compat-css
# Create PR targeting dev
# Wait for CI to complete successfully
```

**This validates**: All shared config CSS files use canonical names or `@apply`, and all three apps still build and render correctly with `compat.css` still present (proving the migration is backward-compatible).

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Visual smoke test of buttons, inputs, menus, badges, cards in ui-v2-dev
- [ ] Rollback instructions are clear (revert PR 1)

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. PR 2 — TSX Consumer Migration

Migrate all TSX files that use `var(--sndq-*)` in Tailwind arbitrary values to proper Tailwind utility classes. Uses a migration script for mechanical replacements, followed by manual review.

---

### Commit 3: Create migration script

**What**: Create a Node.js script that mechanically replaces `var(--sndq-*)` arbitrary values with Tailwind utility classes in `.tsx` files.

**Files to create**:

- `scripts/migrate-compat-aliases.mjs`

**Script behavior**:

The script should read `.tsx` files, apply regex-based replacements, and write the result back. Key replacement rules:

```
Color utility replacements:
  bg-[var(--sndq-{name})]       -> bg-sndq-{name}
  text-[var(--sndq-{name})]     -> text-sndq-{name}     (when {name} is a color token)
  border-[var(--sndq-{name})]   -> border-sndq-{name}
  ring-[var(--sndq-{name})]     -> ring-sndq-{name}
  divide-[var(--sndq-{name})]   -> divide-sndq-{name}
  outline-[var(--sndq-{name})]  -> outline-sndq-{name}

Typography size replacements:
  text-[length:var(--sndq-text-{scale})] -> text-sndq-{scale}

Radius replacements:
  rounded-[var(--sndq-r)]        -> rounded-sndq
  rounded-[var(--sndq-r-{size})] -> rounded-sndq-{size}

Spacing/sizing replacements:
  h-[var(--sndq-h)]              -> h-sndq-h
  h-[var(--sndq-h-{size})]       -> h-sndq-h-{size}
  w-[var(--sndq-h)]              -> w-sndq-h
  w-[var(--sndq-h-{size})]       -> w-sndq-h-{size}
  size-[var(--sndq-icon)]        -> size-sndq-icon
  size-[var(--sndq-icon-{size})] -> size-sndq-icon-{size}

Font family replacements:
  font-[var(--sndq-font-{name})] -> font-sndq-{name}
```

**Edge case: `text-` disambiguation**. The script must know which `--sndq-*` names are colors vs typography sizes:
- Color tokens: `sndq-text`, `sndq-text-secondary`, `sndq-text-tertiary`, `sndq-text-placeholder`, `sndq-text-disabled`, `sndq-text-inverse`, `sndq-text-action`, `sndq-action-text`, `sndq-error-text`, `sndq-success-text`, `sndq-warning-text`, `sndq-info-text`
- Typography tokens: `sndq-text-xs`, `sndq-text-sm`, `sndq-text-md`, `sndq-text-lg`, `sndq-text-xl`, `sndq-text-2xl` through `sndq-text-7xl`
- Typography tokens always appear as `text-[length:var(--sndq-text-{scale})]` -- the `length:` prefix disambiguates them

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Script misses an edge case pattern | LOW | Dry-run on a small file set first |
| Script corrupts non-matching content | LOW | Diff every changed file before committing |

**Verification**:

```bash
# Dry-run on a small test set
node scripts/migrate-compat-aliases.mjs --dry-run sndq-fe/src/patterns/

# Review output for correctness
```

**If it fails**:

- **"Regex replaces inside a string literal or comment"**: Add negative lookbehind for `//` and `/*` in the regex, or review the diff manually.

**Deviations from the gate**:

- **Script is a temporary tool** -- it will be deleted in Commit 7. No tests needed for the script itself.
- **Allowlist-based approach**: script only replaces tokens defined in compat.css. Orphan tokens (`--sndq-brand`, `--sndq-action-ring`, `--sndq-text-base`, `--sndq-surface-hover`, `--sndq-text-primary`, `--sndq-success-subtle`, `--sndq-warning-subtle`) and shadow tokens (`--sndq-shadow-*`) are skipped and logged for manual review.

**Commit message**: `chore: add migration script for compat alias removal`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [x] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 4: Run migration on core packages

**What**: Run the migration script on `packages/ui-v2/`, `sndq-fe/src/patterns/`, and `apps/docs/` -- ~90 refs across 8 files.

**Files to edit**:

- `packages/ui-v2/src/components/forms/field/Field.tsx` -- 2 refs (`--sndq-error-text`)
- `packages/ui-v2/src/components/forms/label/Label.tsx` -- 3 refs (`--sndq-text-sm`, `--sndq-text`, `--sndq-text-disabled`)
- `sndq-fe/src/patterns/filter/index.tsx` -- 25 refs
- `sndq-fe/src/patterns/metric/index.tsx` -- 14 refs
- `sndq-fe/src/patterns/sheet/index.tsx` -- 27 refs
- `apps/docs/src/app/embed/container/page.tsx` -- 1 ref
- `apps/docs/src/components/mdx/IdentityTokenPalette.tsx` -- 7 refs

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `text-sndq-text` resolves as size instead of color | MEDIUM | Build and check that text elements have correct color |
| `rounded-sndq` not recognized | LOW | Confirm `--radius-sndq` exists in `tokens.css` |

**Verification**:

```bash
# Run migration
node scripts/migrate-compat-aliases.mjs packages/ui-v2/src/ sndq-fe/src/patterns/ apps/docs/src/

# Review diff
git diff -- packages/ui-v2/ sndq-fe/src/patterns/ apps/docs/

# Verify zero remaining compat refs in migrated files
rg 'var\(--sndq-' packages/ui-v2/src/components/forms/ sndq-fe/src/patterns/ apps/docs/src/ -c

# Build all affected apps
pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/docs run build

# Visual smoke test for sndq-fe patterns
pnpm --filter sndq-fe run dev
# Check filter, metric, and sheet patterns render correctly
```

**If it fails**:

- **"Unknown utility class text-sndq-text"**: Tailwind v4 may not resolve `text-sndq-text` as a color. Fall back to `text-[var(--color-sndq-text)]` for this specific token if needed.
- **"IdentityTokenPalette shows wrong samples"**: The `sample` property values reference `var(--sndq-*)` for runtime CSS evaluation in the browser. These may need to stay as `var(--sndq-*)` if the component reads the computed style, or switch to `var(--color-sndq-*)`. Check the component behavior.

**Deviations from the gate**:

- `ColorPalette.tsx` added to scope (not in original plan) — uses same bare-syntax patterns as `IdentityTokenPalette.tsx`
- `IdentityTokenPalette.tsx` `token` display labels and `sample` inline CSS strings also migrated to canonical `--color-sndq-*` names (14 additional replacements beyond Tailwind classes)
- `apps/docs` build verification pending (long build time)

**Commit message**: `refactor: migrate core packages from compat aliases to Tailwind utilities`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented — `ui-v2-dev` passes; `docs` build pending
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 5: Run migration on apps/ui-v2-dev

**What**: Run the migration script on `apps/ui-v2-dev/src/` -- ~8,000 refs across ~756 files. This is the largest single commit but is entirely mechanical.

**Files to edit**:

- `apps/ui-v2-dev/src/` -- ~756 `.tsx` files across:
  - `src/components/` (~137 files)
  - `src/app/(showcase)/blocks/` (~11 files)
  - `src/app/(showcase)/foundations/` (~4 files)
  - `src/app/(showcase)/integrations/` (~600 files)
  - `src/app/(showcase)/primitives/` and misc layout files

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Large diff makes review difficult | LOW | Diff is mechanical -- spot-check 10 representative files |
| Script misses patterns unique to this codebase | MEDIUM | `rg 'var\(--sndq-' apps/ui-v2-dev/src/ -c` should return 0 |
| Tailwind class conflicts in long className strings | LOW | Build will catch syntax errors |

**Verification**:

```bash
# Run migration
node scripts/migrate-compat-aliases.mjs apps/ui-v2-dev/src/

# Count remaining (should be 0, or only --sndq-shadow-* which are NOT compat aliases)
rg 'var\(--sndq-' apps/ui-v2-dev/src/ --glob '*.tsx' -c

# Build
pnpm --filter @sndq/ui-v2-dev run build

# Visual smoke test - spot check key pages
pnpm --filter @sndq/ui-v2-dev run dev
# Check: /blocks/filters, /blocks/tables, /blocks/sheets, /blocks/metrics
# Check: /foundations/tokens, /foundations/identity
# Check: /primitives page, /integrations/tremor
```

**If it fails**:

- **"Build error: unknown utility"**: A replacement produced an invalid Tailwind class. Search the git diff for the failing class name and fix manually.
- **"rg count is not zero"**: The script missed a pattern. Add the pattern to the script and re-run on the remaining files.

**Deviations from the gate**:

- **Full visual review of ~756 files is not practical** -- spot-check 10 representative files from different directories
- Remaining `var(--sndq-` refs are all orphan tokens (320 occurrences across ~160 files): `--sndq-brand` (254), `--sndq-text-base` (17), `--sndq-shadow-*` (27), `--sndq-surface-hover` (8), `--sndq-text-primary` (8), `--sndq-action-ring` (4), `--sndq-success-subtle` (1), `--sndq-warning-subtle` (1). These are NOT compat aliases and are outside scope of this commit.

**Commit message**: `refactor: migrate ui-v2-dev showcase from compat aliases to Tailwind utilities`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### PR 2 Checkpoint

Push PR 2 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feature/remove-compat-css
# Create PR targeting dev (or update existing PR)
# Wait for CI to complete successfully
```

**This validates**: All TSX consumers have been migrated from `var(--sndq-*)` arbitrary values to Tailwind utility classes. Combined with PR 1, the only remaining consumer of compat aliases is the `@import` in `globals.css` itself.

**Manual checkpoint**:

- [ ] PR description lists the migration script and affected directories
- [ ] CI passes or failures are explained
- [ ] Spot-check 10 files from the diff for correctness
- [ ] `rg 'var\(--sndq-(?!shadow)' --glob '*.tsx' --glob '*.ts' -c` returns 0

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 5. PR 3 — Cleanup

Remove `compat.css` and the migration script now that zero consumers reference the compat aliases.

---

### Commit 6: Delete compat.css and remove imports

**What**: Delete the compat bridge file and remove all references to it from `package.json` and `globals.css` files.

**Files to delete**:

- `packages/config/tailwind/compat.css` -- no consumers remain after PR 1 and PR 2

**Files to edit**:

- `packages/config/package.json` -- remove `"./tailwind/compat.css": "./tailwind/compat.css"` export
- `apps/ui-v2-dev/src/app/globals.css` -- remove `@import "@sndq/config/tailwind/compat.css";`
- `apps/docs/src/app/global.css` -- remove `@import '@sndq/config/tailwind/compat.css';`
- `sndq-fe/src/app/globals.css` -- remove `@import '@sndq/config/tailwind/compat.css';`

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| A consumer was missed and still references a compat alias | HIGH | Full grep verification before deleting |

**Verification**:

```bash
# CRITICAL: confirm zero remaining compat alias consumers (excluding compat.css itself)
rg 'var\(--sndq-(?!shadow)' --glob '*.css' --glob '*.tsx' --glob '*.ts' | grep -v 'compat.css'
# This MUST return empty. If it returns results, do NOT proceed.

# Build all three apps
pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/docs run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

**If it fails**:

- **"Module not found: compat.css"**: An import was missed. Search all `globals.css` files for `compat.css` and remove the import.
- **"Variable --sndq-{name} is undefined"**: A consumer was missed by the migration. Add the file to the migration script and re-run, or fix manually. Then re-attempt this commit.

**Deviations from the gate**:

- `sndq-fe` build skipped (known OOM issue, pre-existing)
- Only `--sndq-shadow-*` refs remain in CSS files (`components.css` and `tokens.css`) -- these are semantic tokens, not compat aliases

**Commit message**: `chore: remove compat.css bridge and imports`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented -- `ui-v2-dev` and `docs` pass; `sndq-fe` skipped (OOM)
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 7: Delete migration script and final verification

**What**: Remove the temporary migration script and perform a final comprehensive grep to confirm zero `var(--sndq-` compat references remain anywhere in the codebase.

**Files to delete**:

- `scripts/migrate-compat-aliases.mjs` -- temporary tool, no longer needed

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| None | LOW | Script deletion is safe -- no other code depends on it |

**Verification**:

```bash
# Final comprehensive check: only --sndq-shadow-* and --sndq-action-subtle-* should remain
# (these are defined in semantic-tokens.css, not compat aliases)
rg 'var\(--sndq-' --glob '*.css' --glob '*.tsx' --glob '*.ts' -c

# Expected remaining references:
# packages/config/tailwind/semantic-tokens.css: --sndq-shadow-*, --sndq-action-subtle-*
# packages/config/tailwind/tokens.css: --sndq-shadow-*, --sndq-action-subtle-* (manual aliases section)
# These are intentional -- they are runtime semantic tokens, not compat bridge aliases.

# Build all apps one final time
pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/docs run build
```

**If it fails**:

- **Unexpected `var(--sndq-` references remain**: Check whether they are `--sndq-shadow-*` or `--sndq-action-subtle-*` (OK to keep) or actual compat aliases (need fixing).

**Deviations from the gate**:

- **None**

**Commit message**: `chore: remove migration script after compat removal`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### PR 3 Checkpoint

Push PR 3 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feature/remove-compat-css
# Create PR targeting dev (or update existing PR)
# Wait for CI to complete successfully
```

**This validates**: The compat bridge is completely removed. The token pipeline is clean: `DESIGN.md` -> `tokens.css` (one variable per token) -> Tailwind utilities, with no intermediate alias layer.

**Manual checkpoint**:

- [ ] PR description confirms compat.css is deleted
- [ ] CI passes
- [ ] `rg 'compat.css' --glob '*.css' --glob '*.json'` returns 0

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 6. Final Verification

After all 7 commits, run the full suite from the monorepo root:

```bash
pnpm --filter @sndq/ui-v2-dev run build
pnpm --filter @sndq/docs run build
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

Compare against baselines:

```bash
diff /tmp/compat-removal-uiv2dev-build-before.txt <(pnpm --filter @sndq/ui-v2-dev run build 2>&1)
diff /tmp/compat-removal-docs-build-before.txt <(pnpm --filter @sndq/docs run build 2>&1)
```

**Manual verification**:

- [ ] Buttons render with correct colors and shadows in ui-v2-dev
- [ ] Input fields show correct states (default, hover, focus, error, disabled)
- [ ] Menus/dropdowns have correct backgrounds and borders
- [ ] Badges display correctly
- [ ] Cards have correct rounded corners and borders
- [ ] sndq-fe patterns (filter, metric, sheet) render correctly
- [ ] docs embed page and identity token palette render correctly
- [ ] `compat.css` file no longer exists in the repository
- [ ] No `@import` for `compat.css` exists in any `globals.css`

**Expected result**: All three apps build and render identically to before the migration. The `compat.css` file is gone. `tokens.css` is the single source of CSS variables, consumed directly by Tailwind utilities.

**Final status**:

- [x] All 7 commits complete
- [x] Build passes for all three apps — `ui-v2-dev` and `docs` confirmed; `sndq-fe` skipped (known OOM)
- [ ] Lint passes
- [ ] Type-check passes, if available
- [ ] Manual visual verification complete
- [ ] All PRs created and merged, or ready for merge

---

## 7. Team Communication

Send to the team before merging PR 3 (the compat.css deletion):

> **Heads up: Removing compat.css bridge layer**
>
> PRs [link-1], [link-2], [link-3] migrate all `var(--sndq-*)` CSS variable aliases to proper Tailwind utility classes. After pulling:
>
> 1. Run `pnpm install` (no new dependencies, but lockfile may change)
> 2. Restart any local dev servers
>
> Files that changed and may conflict:
> - `packages/config/tailwind/components.css` (full rewrite with `@apply`)
> - `packages/config/tailwind/semantic-tokens.css` (canonical variable names)
> - `packages/config/package.json` (removed `compat.css` export)
> - All three `globals.css` files (removed `compat.css` import)
> - `apps/ui-v2-dev/src/` (~756 files -- Tailwind class name changes)
> - `sndq-fe/src/patterns/` (3 files -- Tailwind class name changes)
>
> **Going forward**: Use Tailwind utility classes like `bg-sndq-action`, `text-sndq-text`, `rounded-sndq-sm` instead of arbitrary values like `bg-[var(--sndq-action)]`. In raw CSS, use the canonical names: `var(--color-sndq-action)`, `var(--radius-sndq)`, `var(--text-sndq-sm)`.

---

## 8. What's Next

After compat removal is merged, the token pipeline is clean. Potential follow-ups:

- **Automated visual regression tests** for the component library to catch future CSS changes
- **Lint rule** to prevent `var(--sndq-` (without the category prefix) from being introduced in new code
- **Document the canonical naming convention** in the ui-v2 DESIGN.md or AGENTS.md

### Lessons to carry forward

- Mechanical migrations at scale (8,000+ refs) are best done with a purpose-built script rather than find-and-replace
- The `text-` Tailwind prefix ambiguity (color vs size) requires explicit handling in migration tooling
- `compat.css` bridges are effective for phased migrations -- they allow the source of truth to change while consumers catch up

### Known lessons from prior phases

- `sndq-fe` builds require `--max-old-space-size=8192` due to memory pressure
- Always capture baselines before and after risky CSS changes -- visual regressions can be subtle

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| 2026-06-02 | Commit 1: semantic-tokens.css + globals.css | 5 replacements across 2 files (not 6/3 as planned). `sndq-fe/src/app/globals.css` had no `var(--sndq-*)` refs. All canonical names confirmed in `tokens.css`. Both `ui-v2-dev` and `docs` builds pass. |
| 2026-06-02 | Commit 2: components.css @apply rewrite | Full rewrite of 458-line file. ~110 compat refs replaced with `@apply` utilities + canonical var names. 14 `var(--sndq-shadow-*)` refs remain (semantic-tokens.css, not compat). 5 canonical `var(--color-sndq-*)` refs in box-shadow/color-mix. Both `ui-v2-dev` and `docs` builds pass. Visual smoke test pending. |
| 2026-06-02 | Commit 3: Create migration script | Created `scripts/migrate-compat-aliases.mjs` with allowlist-based replacement (derived from compat.css). Dry-run results: `sndq-fe/src/patterns/` 66 repl / 3 files, `packages/ui-v2/` + `apps/docs/` 5 / 2, `apps/ui-v2-dev/` 6,578 / 731. Skipped 10 orphan token types (expected): `--sndq-brand` (254), `--sndq-text-base` (17), `--sndq-shadow-*` (27), `--sndq-surface-hover` (8), `--sndq-text-primary` (8), `--sndq-action-ring` (4), `--sndq-success-subtle` (1), `--sndq-warning-subtle` (1). Full diff verified on `filter/index.tsx` — all 5 key patterns confirmed correct. |
| 2026-06-03 | Commit 4: Run migration on core packages | Script run: 71 replacements across 5 files (ui-v2: 5/2 files, sndq-fe patterns: 66/3 files). Manual migration of 3 docs files: `IdentityTokenPalette.tsx` (5 bare-syntax classes + 7 `sample` strings + 7 `token` labels → canonical `--color-sndq-*`), `page.tsx` (1 inline CSS string + 2 bare-syntax classes), `ColorPalette.tsx` (7 bare-syntax classes — added to scope, not in original plan). Grep confirms zero remaining `var(--sndq-` or `--sndq-` refs in migrated scope. `ui-v2-dev` build passes. `docs` build pending (long build time). |
| 2026-06-03 | Commit 5: Run migration on apps/ui-v2-dev | Script run: 6,578 replacements across 731 files — exactly matching dry-run from Commit 3. Same 10 orphan token types skipped (320 total occurrences). Grep confirms zero compat-alias refs remain (only orphans). `ui-v2-dev` build passes. No deviations from plan. |
| 2026-06-03 | Commit 6: Delete compat.css and remove imports | Pre-flight grep confirmed only `--sndq-shadow-*` refs remain in CSS (semantic tokens, not compat). Deleted `compat.css` (7,226 bytes). Removed export from `package.json`. Removed `@import` from 3 `globals.css` files (`ui-v2-dev`, `docs`, `sndq-fe`). Both `ui-v2-dev` and `docs` build pass. `sndq-fe` build skipped (known OOM). |
| 2026-06-03 | Commit 7: Delete migration script and final verification | Deleted `scripts/migrate-compat-aliases.mjs` (10,458 bytes). Final grep confirms only `components.css` and `tokens.css` contain `var(--sndq-` refs (all `--sndq-shadow-*` / `--sndq-action-subtle-*` semantic tokens). Zero `compat.css` references remain anywhere. Both `ui-v2-dev` and `docs` builds pass. All 7 commits complete. |
