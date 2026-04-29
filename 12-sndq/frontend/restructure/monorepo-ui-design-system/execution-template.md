# {PHASE_NAME} Execution — {PHASE_TITLE}

Step-by-step execution guide for {PHASE_NAME}. Each commit is independently verifiable and revertable.

**Created**: {DATE}
**Status**: Not started
**Architecture**: [README.md](./README.md)
**Migration plan**: [migration-plan.md](./migration-plan.md)
<!-- Add links to prior phase execution files if applicable -->
**Branch**: `feature/{BRANCH_NAME}`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
<!-- Add one entry per PR section -->
3. [PR 1 — {PR_1_TITLE}](#3-pr-1--{pr-1-slug})
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)

---

## 1. Overview

**Goal**: {One sentence describing what this phase achieves and the invariant it preserves (e.g. "Zero visual or behavioral changes to sndq-fe").}

**Structure**: {COMMIT_COUNT} commits across {PR_COUNT} PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | {scope} | {Low / Medium / High} | {range} |
<!-- Add rows for additional PRs -->

**Why {PR_COUNT} PRs**: {Explain the rationale for splitting work into these PRs — what does merging each one independently validate?}

### Prerequisites

<!-- List anything that must be true before starting this phase -->
- {Prior phase} is merged to dev
- {Any package/file/tool} already exists from a previous phase

---

## 2. Before You Start

### Capture baselines

Run these from the monorepo root and save the output. You will diff against these after each risky commit.

```bash
# sndq-fe baselines
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/{phase-slug}-fe-build-before.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/{phase-slug}-fe-lint-before.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/{phase-slug}-fe-typecheck-before.txt
```

<!-- Add baselines for other apps if this phase touches them -->
<!-- Example:
```bash
# prototype baselines
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter @sndq/prototype run build 2>&1 | tee /tmp/{phase-slug}-proto-build-before.txt
pnpm --filter @sndq/prototype run lint 2>&1 | tee /tmp/{phase-slug}-proto-lint-before.txt
```
-->

<!-- If CSS/visual changes are involved, add: -->
<!-- Also capture visual baselines: open the affected app(s) locally and screenshot key pages for comparison after the swap. -->

### Create branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/{BRANCH_NAME}
```

---

## 3. PR 1 — {PR_1_TITLE}

{One sentence describing the PR scope and why it's safe to merge independently.}

---

### Commit {N}: {Commit title}

**What**: {One sentence describing the change.}

<!-- Use "Files to create" for new files, "Files to edit" for modifications, or both -->

**Files to create**:

- `{path/to/new-file}`

**Files to edit**:

- `{path/to/existing-file}` — {what changes}

<!-- For modifications, show before/after. For new files, show full target content. -->

**Before** (current):

```{language}
{current content}
```

**After** (target):

```{language}
{target content}
```

<!-- Explain what changed and why it's safe -->

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| {description} | {LOW / MEDIUM / HIGH} | {verification steps} |

**Verification**:

```bash
{commands to run — build, lint, type-check, diff against baselines}
```

**If it fails**:

<!-- Describe the most likely failure mode and how to diagnose/fix it -->
- **"{error message or symptom}"**: {diagnosis steps and fix}

**Commit message**: `{type}: {message}`

**Status**:

- [ ] {checklist item 1}
- [ ] {checklist item 2}
- [ ] Build passes
- [ ] Committed

---

<!-- Repeat "### Commit {N}" blocks for each commit in this PR -->

### PR 1 Checkpoint

Push PR 1 and wait for CI / Vercel preview build to pass before continuing.

```bash
git push -u origin feature/{BRANCH_NAME}
# Create PR targeting dev
# Wait for CI to complete successfully
```

**This validates**: {what the CI run proves — e.g. workspace resolution, postinstall, build in CI environment}

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Merged (or ready to continue)

---

<!-- Repeat "## {N}. PR {M}" sections for additional PRs -->
<!-- Include a "PR Checkpoint" between each PR -->

## 4. Final Verification

After all {COMMIT_COUNT} commits, run the full suite from the monorepo root:

```bash
pnpm install
NODE_OPTIONS='--max-old-space-size=8192' pnpm build
pnpm lint
pnpm type-check
```

Compare against baselines:

```bash
NODE_OPTIONS='--max-old-space-size=8192' pnpm --filter sndq-fe run build 2>&1 | tee /tmp/{phase-slug}-fe-build-final.txt
pnpm --filter sndq-fe run lint 2>&1 | tee /tmp/{phase-slug}-fe-lint-final.txt
pnpm --filter sndq-fe run type-check 2>&1 | tee /tmp/{phase-slug}-fe-typecheck-final.txt

diff /tmp/{phase-slug}-fe-build-before.txt /tmp/{phase-slug}-fe-build-final.txt
diff /tmp/{phase-slug}-fe-lint-before.txt /tmp/{phase-slug}-fe-lint-final.txt
diff /tmp/{phase-slug}-fe-typecheck-before.txt /tmp/{phase-slug}-fe-typecheck-final.txt
```

<!-- Add diff commands for other apps if applicable -->

**Expected result**: {Describe what "success" looks like — e.g. "Zero behavioral or visual differences. Build output, lint warnings, and type errors must be identical."}

<!-- If visual changes are involved, add manual verification steps -->
<!-- **Visual verification** (manual):
1. Start the dev server: `pnpm --filter {app} run dev`
2. Open pages that use {relevant features}
3. Compare against baseline screenshots — must be identical
-->

**Final status**:

- [ ] All {COMMIT_COUNT} commits complete
- [ ] Build passes from root
- [ ] Lint passes from root
- [ ] Type-check passes from root
- [ ] Output matches baselines
<!-- - [ ] Visual check — no regressions -->
- [ ] All PRs created and merged

---

## 5. Team Communication

Send to the team before merging the riskiest PR:

> **Heads up: {short description of what's incoming}**
>
> PR [link] {short description of what changes}. After pulling:
>
> 1. Run `pnpm install` (lock file changed)
> 2. Restart your TypeScript server in IDE (Cmd+Shift+P > "TypeScript: Restart TS Server")
> 3. Restart ESLint in IDE (Cmd+Shift+P > "ESLint: Restart ESLint Server")
>
> Files that changed (expect merge conflicts if your branch touches these):
> - `{file1}`
> - `{file2}`

---

## 6. What's Next

After {PHASE_NAME} is merged to dev, proceed to **{NEXT_PHASE}**. See [{next-phase-link}]({next-phase-link}).

### Lessons to carry forward

<!-- Copy lessons from prior phases that are still relevant, then add new ones discovered during this phase -->

- {lesson 1}
- {lesson 2}

### Known lessons from prior phases

- **`include`/`exclude` in shared tsconfigs are dead code.** TypeScript resolves inherited `include`/`exclude` relative to the config that defines them, not the consumer. Every app must define its own locally.
- **`outDir` in shared tsconfigs resolves relative to the defining file.** Same as `include`/`exclude` — inherited `outDir: "dist"` from `library.json` resolves to `packages/tsconfig/dist`, not the consumer's `dist`. Every consumer must override `outDir` locally.
- **`.mjs` exports need `.d.mts` type declarations.** Any shared package exporting `.mjs` files must ship a paired `.d.mts` and use conditional `exports` with `"types"` in `package.json`.
- **Shared config packages use `peerDependencies`, not `devDependencies`.** `@sndq/config` declares ESLint/Prettier tools as `peerDependencies` with relaxed semver ranges. Each consumer app owns the exact pinned versions.
- **CSS `@import` order matters for token dependencies.** `tokens.css` (primitives) must load before `semantic-tokens.css` (references primitives), which must load before `components.css` (references semantic tokens).

---

## Execution Log

Record notes, issues, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
<!-- Add one row per commit as you execute -->
| | 1 | |
