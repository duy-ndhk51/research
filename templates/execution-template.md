# {PHASE_NAME} Execution — {PHASE_TITLE}

Step-by-step execution guide for {PHASE_NAME}. Each commit should be independently verifiable and revertable.

**Created**: {DATE}
**Status**: Not started
**Architecture**: [{ARCHITECTURE_DOC}]({ARCHITECTURE_DOC})
**Migration plan**: [{MIGRATION_PLAN}]({MIGRATION_PLAN})
**Branch**: `feature/{BRANCH_NAME}`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — {PR_1_TITLE}](#3-pr-1--pr-1-title)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: {One sentence describing what this phase achieves and which invariant it preserves.}

**Structure**: {COMMIT_COUNT} commits across {PR_COUNT} PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | {scope} | {Low / Medium / High} | {range} |

**Why {PR_COUNT} PRs**: {Explain why this split keeps each review independently understandable and verifiable.}

### Prerequisites

- {Prerequisite 1}
- {Prerequisite 2}

### Known constraints

- {Constraint, existing failure, migration rule, or compatibility requirement}
- {Constraint, existing failure, migration rule, or compatibility requirement}

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

- [ ] Confirm files and folders in **Files to create**, **Files to edit**, and **Files to delete** are accurate
- [ ] Confirm package scripts and verification commands exist
- [ ] Confirm current lint, type-check, build, or test failures that predate this phase
- [ ] Confirm existing exports, public entry points, routes, workflows, or generated files before changing them
- [ ] Confirm whether dependencies or lockfiles will change
- [ ] Confirm rollback path for side-effecting integrations, migrations, or external services

### Capture baselines

Run these from the repository root and save the output. Diff against these after risky commits.

```bash
{baseline-command-1} 2>&1 | tee /tmp/{phase-slug}-{check}-before.txt
{baseline-command-2} 2>&1 | tee /tmp/{phase-slug}-{check-2}-before.txt
```

### Create branch

```bash
git checkout {base-branch}
git pull origin {base-branch}
git checkout -b feature/{BRANCH_NAME}
```

---

## 3. PR 1 — {PR_1_TITLE}

{One sentence describing this PR scope and why it is safe to merge independently.}

---

### Commit {N}: {Commit title}

**What**: {One sentence describing the change.}

**Files to create**:

- `{path/to/new-file}`

**Files to edit**:

- `{path/to/existing-file}` — {what changes}

**Files to delete**:

- `{path/to/deleted-file}` — {why it is safe to remove}

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| {description} | {LOW / MEDIUM / HIGH} | {verification steps} |

**Verification**:

```bash
{commands to run}
```

**If it fails**:

- **"{error message or symptom}"**: {diagnosis steps and likely fix}

**Deviations from the gate**:

- **{Deviation or "None"}** — {why it is acceptable and when it will be resolved}

**Commit message**: `{type}: {message}`

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
git push -u origin feature/{BRANCH_NAME}
# Create PR targeting {base-branch}
# Wait for CI to complete successfully
```

**This validates**: {what the CI run proves.}

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Risky behavior has a manual smoke test result
- [ ] Rollback instructions are clear

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. Final Verification

After all {COMMIT_COUNT} commits, run the full suite from the repository root:

```bash
{final-command-1}
{final-command-2}
{final-command-3}
```

Compare against baselines:

```bash
diff /tmp/{phase-slug}-{check}-before.txt /tmp/{phase-slug}-{check}-final.txt
diff /tmp/{phase-slug}-{check-2}-before.txt /tmp/{phase-slug}-{check-2}-final.txt
```

**Manual verification**:

- [ ] Key user-facing flows still work
- [ ] New docs, routes, workflows, or generated outputs are visible where expected
- [ ] External integrations are verified in dry-run or test mode before live mode
- [ ] Any known deviations are recorded in the execution log

**Expected result**: {Describe what success looks like.}

**Final status**:

- [ ] All {COMMIT_COUNT} commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes, if available
- [ ] Tests pass or missing coverage is documented
- [ ] Output matches expected baselines
- [ ] Manual verification complete
- [ ] All PRs created and merged, or ready for merge

---

## 5. Team Communication

Send to the team before merging the riskiest PR:

> **Heads up: {short description of what's incoming}**
>
> PR [link] {short description of what changes}. After pulling:
>
> 1. Run `{setup-command}`
> 2. Restart any local dev services affected by the change.
>
> Files that changed and may conflict:
> - `{file1}`
> - `{file2}`
>
> Known deviations or follow-ups:
> - `{deviation-or-follow-up}`

---

## 6. What's Next

After {PHASE_NAME} is merged, proceed to **{NEXT_PHASE}**. See [{next-phase-link}]({next-phase-link}).

### Lessons to carry forward

- {lesson 1}
- {lesson 2}

### Known lessons from prior phases

- {prior lesson 1}
- {prior lesson 2}

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
