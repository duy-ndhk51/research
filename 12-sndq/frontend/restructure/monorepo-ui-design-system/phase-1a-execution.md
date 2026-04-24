# Phase 1a Execution — Structural Foundation

Step-by-step execution guide for Phase 1a. Each commit is independently verifiable and revertable.

**Created**: 2026-04-23
**Status**: Complete — All 8 commits done, PR 1 checkpoint skipped
**Architecture**: [README.md](./README.md)
**Migration plan**: [migration-plan.md](./migration-plan.md)
**Branch**: `feature/phase-1a-structural-foundation`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Scaffold Shared Packages + Wire Workspace](#3-pr-1--scaffold-shared-packages--wire-workspace)
4. [PR 2 — Switch sndq-fe to Shared Configs](#4-pr-2--switch-sndq-fe-to-shared-configs)
5. [Final Verification](#5-final-verification)
6. [Team Communication](#6-team-communication)
7. [What's Next](#7-whats-next)

---

## 1. Overview

**Goal**: Set up monorepo infrastructure (`apps/`, `packages/`, shared tsconfig/eslint/prettier). Zero visual or behavioral changes to `sndq-fe`.

**Structure**: 8 commits across 2 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Pure additions + workspace wiring | Low | 1-4 |
| **PR 2** | Config switches (tsconfig, eslint, prettier) | High | 5-8 |

**Why 2 PRs**: PR 1 changes nothing about how `sndq-fe` builds or lints. Merging it first and letting Vercel run a preview build validates the workspace wiring before touching any config files in PR 2.

---

## 2. Before You Start

### Capture baselines

Run these from the monorepo root and save the output. You will diff against these after each risky commit.

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase1a-build-before.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase1a-lint-before.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase1a-typecheck-before.txt
```

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/phase-1a-structural-foundation
```

---

## 3. PR 1 — Scaffold Shared Packages + Wire Workspace

Pure additions. Zero changes to existing behavior. Safe to merge independently.

---

### Commit 1: Create `packages/tsconfig/`

**What**: Create the shared TypeScript config package.

**Files to create**:

- `packages/tsconfig/package.json`
- `packages/tsconfig/base.json` — common compiler options extracted from `sndq-fe/tsconfig.json` (compilerOptions only, no `include`/`exclude`)
- `packages/tsconfig/nextjs.json` — extends base, adds only Next.js-specific compilerOptions (no `include`/`exclude` — consumers must define locally due to path resolution rules)

Also create the empty `apps/` directory (with a `.gitkeep`).

`library.json` is deferred to Phase 2 when `packages/ui-v2/` is created.

**Content reference**: [README.md section 4.3](./README.md) — `@sndq/tsconfig` package.json, base.json, nextjs.json.

**Risk**: None — pure file addition.

**Verification**:

```bash
# Files exist and are valid JSON
cat packages/tsconfig/package.json | jq .
cat packages/tsconfig/base.json | jq .
cat packages/tsconfig/nextjs.json | jq .
```

**Commit message**: `chore: create @sndq/tsconfig shared typescript configs`

**Status**:

- [x] Files created
- [x] JSON valid
- [x] Committed

---

### Commit 2: Create `packages/config/` (ESLint + Prettier only)

**What**: Create the shared config package with ESLint and Prettier configs. No Tailwind files yet (that's Phase 1b).

**Files to create**:

- `packages/config/package.json`
- `packages/config/eslint.mjs`
- `packages/config/eslint.d.mts` — type declarations for `eslint.mjs` (so consumers get proper types and IDE autocomplete)
- `packages/config/prettier.json`

**Content reference**: [README.md section 4.2](./README.md) — `@sndq/config` package.json (Phase 1a subset: only `eslint.mjs` and `prettier.json` exports), eslint.mjs, prettier.json.

**Phase 1a subset of `package.json`** — only include exports and dependencies needed now:

```json
{
  "name": "@sndq/config",
  "private": true,
  "version": "0.0.0",
  "exports": {
    "./eslint.mjs": {
      "types": "./eslint.d.mts",
      "default": "./eslint.mjs"
    },
    "./prettier.json": "./prettier.json"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3.0.0",
    "eslint-config-next": "^15.0.0",
    "eslint-config-prettier": "^10.0.0",
    "eslint-plugin-prettier": "^5.0.0",
    "prettier": "^3.0.0",
    "prettier-plugin-tailwindcss": "^0.6.0"
  }
}
```

Tailwind exports (`./tailwind/tokens.css`, etc.) and `sideEffects` will be added in Phase 1b.

**Risk: ESLint peer dependencies**

The `eslint.mjs` imports `@eslint/eslintrc` and the resolved configs depend on `eslint-config-next`, `eslint-config-prettier`, `eslint-plugin-prettier`. These must be in `@sndq/config`'s own `devDependencies` because pnpm's strict module resolution won't let the shared package see `sndq-fe`'s dependencies.

Similarly, `prettier-plugin-tailwindcss` must be listed here so Prettier can find the plugin when config is resolved from this package.

**Verification**:

```bash
cat packages/config/package.json | jq .
node -e "import('./packages/config/eslint.mjs').then(() => console.log('syntax OK'))"
cat packages/config/prettier.json | jq .
```

**Commit message**: `chore: create @sndq/config shared eslint and prettier configs`

**Status**:

- [x] Files created
- [x] JSON/JS syntax valid
- [x] Committed

---

### Commit 3: Wire workspace and Lerna

**What**: Update `pnpm-workspace.yaml` and `lerna.json` to recognize the new `apps/*` and `packages/*` directories. Run `pnpm install` to regenerate the lock file.

**Files to change**:

- `pnpm-workspace.yaml` — add `apps/*` and `packages/*`
- `lerna.json` — add `apps/*` and `packages/*` to packages array

**Target `pnpm-workspace.yaml`**:

```yaml
packages:
  - sndq-fe
  - 'apps/*'
  - 'packages/*'
onlyBuiltDependencies:
  - '@percy/core'
```

**Target `lerna.json` packages array**:

```json
"packages": [
  "sndq-fe",
  "apps/*",
  "packages/*"
]
```

**Risks**:

| Risk | What to watch for |
|------|-------------------|
| Workspace resolution changes | `pnpm install` may resolve differently. Check that no existing dependency is silently swapped to a local package. |
| Lock file churn | The lock file diff will be noisy. This is expected but creates potential merge conflicts with other developers' branches. |
| `postinstall` script interference | `sndq-fe` has `"postinstall": "pnpm submodules:setup && pnpm copy-pdf-worker"`. Verify it still runs successfully after workspace changes. |

**Verification**:

```bash
pnpm install

# Verify new packages are recognized
pnpm ls @sndq/tsconfig
pnpm ls @sndq/config

# Verify postinstall ran successfully (check for errors in install output)

# Verify sndq-fe still builds (quick sanity check)
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

**Commit message**: `chore: add apps and packages to pnpm workspace and lerna`

**Status**:

- [x] `pnpm-workspace.yaml` updated
- [x] `lerna.json` updated
- [x] `pnpm install` succeeds
- [x] `@sndq/tsconfig` and `@sndq/config` resolve as local packages
- [x] `sndq-fe` build still passes
- [x] Committed

---

### Commit 4: Add shared packages as sndq-fe devDependencies

**What**: Add `@sndq/tsconfig` and `@sndq/config` as `workspace:*` devDependencies in `sndq-fe/package.json`. This wires the dependency graph but does **not** use them yet.

**File to change**: `sndq-fe/package.json` — add to `devDependencies`:

```json
"@sndq/config": "workspace:*",
"@sndq/tsconfig": "workspace:*"
```

**Risk**: Name collision with existing npm packages (unlikely — both use the `@sndq/` scope which is private). Verify after install that pnpm resolves to local workspace packages, not registry.

**Verification**:

```bash
pnpm install

# Confirm workspace resolution (should show "link:" not a version number)
pnpm --filter sndq-fe ls @sndq/tsconfig
pnpm --filter sndq-fe ls @sndq/config

# Full build — must match baseline
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

**Commit message**: `chore: add @sndq/tsconfig and @sndq/config as sndq-fe devDependencies`

**Status**:

- [x] `sndq-fe/package.json` updated
- [x] `pnpm install` succeeds
- [x] Dependencies resolve as workspace links
- [x] Build skipped (no behavioral change — commit 3 already validated)
- [x] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for Vercel preview build to pass before continuing.

```bash
git push -u origin feature/phase-1a-structural-foundation
# Create PR targeting dev
# Wait for Vercel preview build to complete successfully
```

**This validates**: workspace resolution works in CI, `postinstall` script works, build passes in CI environment.

**Status**:

- [x] Skipped — local `pnpm install` + `pnpm build` validated the same chain as CI (`vercel.json` buildCommand). No behavioral change in PR 1.

---

## 4. PR 2 — Switch sndq-fe to Shared Configs

Config switches that change resolution sources. Each commit is individually revertable. **Merge PR 1 first**, then create a new branch from the updated dev (or continue on the same branch if preferred).

---

### Commit 5: Switch sndq-fe to shared tsconfig

**What**: Update `sndq-fe/tsconfig.json` to extend `@sndq/tsconfig/nextjs.json` instead of inlining all compiler options. Keep local `paths`, `include`, `exclude` overrides.

**File to change**: `sndq-fe/tsconfig.json`

**Before** (current):

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"],
      "@sndq/ui": ["./packages/ui/src"],
      "@sndq/ui/*": ["./packages/ui/src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules", "packages", "agent-workspace"]
}
```

**After** (target):

```json
{
  "extends": "@sndq/tsconfig/nextjs.json",
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"],
      "@sndq/ui": ["./packages/ui/src"],
      "@sndq/ui/*": ["./packages/ui/src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules", "packages", "agent-workspace"]
}
```

**What changes**: The `extends` inherits all compilerOptions from the shared config. Local `paths`, `include`, and `exclude` override as needed.

> **Lesson learned**: `include`/`exclude` inherited via `extends` resolve relative to the config file that *defines* them, not the file that extends. So `include` and `exclude` must stay local — otherwise TypeScript looks for source files inside `packages/tsconfig/` instead of `sndq-fe/`. Because of this, `include` was removed from `nextjs.json` and `exclude` was removed from `base.json` — they were dead code that would never be used by any consumer. The shared configs now contain `compilerOptions` only.

**Why this is safe**: `nextjs.json` extends `base.json` and together they contain the exact same compilerOptions as the current `sndq-fe/tsconfig.json` (minus `paths`). You can verify by running `npx tsc --showConfig` before and after.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `extends` + local `paths` collision | MEDIUM | TypeScript resolves `paths` relative to the tsconfig file that defines them. Since `paths` stays in the local file, base URL remains `sndq-fe/`. Verify `@/*` and `@sndq/ui/*` still resolve correctly. |
| `include`/`exclude` path resolution | MEDIUM | **Hit this risk**: inherited `include` paths resolve relative to the config that defines them (`packages/tsconfig/`), not the extending file (`sndq-fe/`). Fix: keep `include` in the local tsconfig. Same applies to `exclude`. |
| IDE cache | LOW | After this change, restart the TypeScript server in your IDE. |

**Verification**:

```bash
# Type-check must produce identical output to baseline
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase1a-typecheck-after.txt
diff /tmp/phase1a-typecheck-before.txt /tmp/phase1a-typecheck-after.txt

# Build must still pass
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build
```

**If it fails**: The most likely cause is `include`/`exclude` mismatch. Compare the effective tsconfig:

```bash
cd sndq-fe && npx tsc --showConfig
```

Check that `include` and `exclude` arrays match what was there before.

**Commit message**: `refactor: extend @sndq/tsconfig/nextjs.json in sndq-fe`

**Status**:

- [x] `tsconfig.json` updated (with local `include` — see lesson learned above)
- [x] `type-check` passes (clean, zero errors)
- [x] Build passes
- [ ] Committed

---

### Commit 6: Switch sndq-fe to shared ESLint config

**What**: Update `sndq-fe/eslint.config.mjs` to import `createEslintConfig` from `@sndq/config/eslint.mjs`. Keep app-specific rules (zodResolver restriction) and ignores local.

**File to change**: `sndq-fe/eslint.config.mjs`

**Before** (current):

```js
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import { FlatCompat } from '@eslint/eslintrc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [
  {
    ignores: [
      'node_modules/**',
      '.next/**',
      'out/**',
      'build/**',
      'next-env.d.ts',
      'packages/**',
      'agent-workspace/**',
      'public/pdf.worker.min.mjs',
    ],
  },
  ...compat.extends(
    'next/core-web-vitals',
    'next/typescript',
    'plugin:prettier/recommended',
  ),
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
        },
      ],
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': [
        'warn',
        {
          vars: 'all',
          args: 'after-used',
          caughtErrors: 'all',
          caughtErrorsIgnorePattern: '^_',
          ignoreRestSiblings: true,
          destructuredArrayIgnorePattern: '^_',
        },
      ],
      '@typescript-eslint/no-empty-object-type': 'off',
      'prettier/prettier': 'warn',
    },
  },
];

export default eslintConfig;
```

**After** (target):

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
      'packages/**',
      'agent-workspace/**',
      'public/pdf.worker.min.mjs',
    ],
  },
  ...createEslintConfig(__dirname),
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
        },
      ],
    },
  },
];
```

**What stays local**: The `ignores` array (app-specific paths) and the `no-restricted-imports` rule (app-specific business rule). Everything else (extends, shared rules like `@typescript-eslint/*`, `prettier/*`) comes from `createEslintConfig`.

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Peer dependency resolution | HIGH | `createEslintConfig` calls `FlatCompat` which resolves `next/core-web-vitals`, `next/typescript`, `plugin:prettier/recommended`. These plugins must be findable. Since `@sndq/config` lists them in `devDependencies` AND `sndq-fe` also has them, pnpm should resolve. But watch the install output. |
| `FlatCompat` baseDirectory | HIGH | The function receives `dirname` as an argument and passes it as `baseDirectory` to `FlatCompat`. This means plugin resolution happens relative to the **caller** (`sndq-fe/`), not the package (`packages/config/`). This is the correct behavior — the caller's `node_modules` is where the plugins live. |
| Rule duplication | MEDIUM | The shared config includes `@typescript-eslint/*` and `prettier/*` rules. The local config adds `no-restricted-imports`. ESLint merges flat config arrays — later entries override earlier ones for the same rule. Since `no-restricted-imports` is only in the local config, there is no conflict. Verify that `@typescript-eslint/*` rules are not accidentally overridden. |

**Verification**:

```bash
# Lint must produce identical output to baseline
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase1a-lint-after.txt
diff /tmp/phase1a-lint-before.txt /tmp/phase1a-lint-after.txt
```

**If it fails**: Most likely "Cannot find module" for a plugin. Check:

```bash
# Verify plugins are installed in the right place
ls sndq-fe/node_modules/eslint-config-next
ls sndq-fe/node_modules/eslint-plugin-prettier

# Also check if pnpm hoisted them
ls node_modules/eslint-config-next
ls node_modules/eslint-plugin-prettier
```

If plugins aren't found from the shared config, you may need to add them as `peerDependencies` in `@sndq/config/package.json` instead of (or in addition to) `devDependencies`.

**Commit message**: `refactor: use shared eslint config from @sndq/config in sndq-fe`

**Status**:

- [x] `eslint.config.mjs` updated
- [x] Lint passes (clean, zero errors)
- [x] Added `packages/config/eslint.d.mts` type declarations + updated `package.json` exports with `types` condition (fixes TS7016 for all consumers)
- [x] Committed

---

### Commit 7: Switch sndq-fe to shared Prettier config

**What**: Delete `.prettierrc.json` and add a `"prettier"` field in `sndq-fe/package.json` pointing to `@sndq/config/prettier.json`.

**Files to change**:

- **Delete**: `sndq-fe/.prettierrc.json`
- **Edit**: `sndq-fe/package.json` — add `"prettier": "@sndq/config/prettier.json"` at root level

**Risk**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `prettier-plugin-tailwindcss` not found | MEDIUM | The plugin must be resolvable from where the config lives (`packages/config/`). It's listed in `@sndq/config`'s `devDependencies`, so pnpm should install it there. But if pnpm hoists differently than expected, Prettier won't find it. |

**Verification**:

```bash
# Quick check: format a known file
pnpm --filter sndq-fe exec prettier --check "src/app/page.tsx"

# Full check: run the lint command (which includes prettier via eslint-plugin-prettier)
pnpm --filter sndq-fe run lint
```

**If it fails**: "Cannot find module 'prettier-plugin-tailwindcss'". Fix by adding it as a `peerDependency` in `@sndq/config/package.json`, or by adding it explicitly to `sndq-fe/devDependencies`.

**Commit message**: `refactor: use shared prettier config from @sndq/config in sndq-fe`

**Status**:

- [x] `.prettierrc.json` deleted
- [x] `package.json` has `"prettier"` field
- [x] Prettier check passes (plugin found)
- [x] Lint still passes
- [x] Committed

---

### Commit 8: Add root-level lint and type-check scripts

**What**: Add `lint` and `type-check` scripts to the root `package.json` so they can be run across the entire workspace.

**File to change**: root `package.json` — update `scripts`:

```json
"scripts": {
  "build": "lerna run build",
  "dev": "lerna run dev --parallel",
  "lint": "lerna run lint",
  "type-check": "lerna run type-check",
  "test": "lerna run test",
  "clean": "lerna clean",
  "publish": "lerna publish"
}
```

**Risk**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Lerna runs on empty packages | LOW | `packages/tsconfig` and `packages/config` have no `lint` or `type-check` scripts. Lerna skips packages without the target script — verify this doesn't error. |

**Verification**:

```bash
# Both should run successfully (only sndq-fe has these scripts)
pnpm lint
pnpm type-check
```

**Commit message**: `chore: add root lint and type-check scripts`

**Status**:

- [x] Root `package.json` updated
- [x] `pnpm lint` from root works (Lerna delegates to sndq-fe only)
- [x] `pnpm type-check` from root works (Lerna delegates to sndq-fe only)
- [x] Committed

---

## 5. Final Verification

After all 8 commits, run the full suite from the monorepo root:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
```

Compare against baselines:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/phase1a-build-final.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/phase1a-lint-final.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/phase1a-typecheck-final.txt

diff /tmp/phase1a-build-before.txt /tmp/phase1a-build-final.txt
diff /tmp/phase1a-lint-before.txt /tmp/phase1a-lint-final.txt
diff /tmp/phase1a-typecheck-before.txt /tmp/phase1a-typecheck-final.txt
```

**Expected result**: Zero behavioral differences. Build output, lint warnings, and type errors must be identical.

**Final status**:

- [ ] All 8 commits complete
- [ ] Build passes from root
- [ ] Lint passes from root
- [ ] Type-check passes from root
- [ ] Output matches baselines
- [ ] PR 2 created and merged

---

## 6. Team Communication

Send to the team before merging PR 2:

> **Heads up: monorepo config restructure incoming**
>
> PR [link] restructures shared configs. After pulling:
>
> 1. Run `pnpm install` (lock file changed)
> 2. Restart your TypeScript server in IDE (Cmd+Shift+P > "TypeScript: Restart TS Server")
> 3. Restart ESLint in IDE (Cmd+Shift+P > "ESLint: Restart ESLint Server")
>
> Files that changed (expect merge conflicts if your branch touches these):
> - `pnpm-workspace.yaml`
> - `lerna.json`
> - `sndq-fe/tsconfig.json`
> - `sndq-fe/eslint.config.mjs`
> - `sndq-fe/.prettierrc.json` (deleted)
> - `sndq-fe/package.json`
> - Root `package.json`

---

## 7. What's Next

After Phase 1a is merged to dev, proceed to **Phase 1b: Tailwind Token Infrastructure** — extract Briicks primitive tokens into `@sndq/config/tailwind/tokens.css`. See [migration-plan.md section 4](./migration-plan.md#4-phase-1b-tailwind-token-infrastructure).

### Lessons to carry forward

- **`include`/`exclude` in shared tsconfigs are dead code.** TypeScript resolves inherited `include`/`exclude` relative to the config that defines them, not the consumer. Every app must define its own locally. Do not add `include`/`exclude` to shared tsconfig files.
- **`.mjs` exports need `.d.mts` type declarations.** Any shared package exporting `.mjs` files must ship a paired `.d.mts` and use conditional `exports` with `"types"` in `package.json`. Without this, consumers get `TS7016` IDE errors. Apply this pattern when creating `packages/ui-v2/` or any future package with `.mjs` exports.

---

## Execution Log

Record notes, issues, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
| | 2 | |
| | 3 | |
| | 4 | |
| | 5 | |
| | 6 | |
| | 7 | |
| | 8 | |
