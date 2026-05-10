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

---

## 2. Before You Start

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

**Commit message**: `{type}: {message}`

**Status**:

- [ ] Implementation complete
- [ ] Verification passes
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

**Status**:

- [ ] PR created
- [ ] CI passes
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

**Expected result**: {Describe what success looks like.}

**Final status**:

- [ ] All {COMMIT_COUNT} commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Output matches expected baselines
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

---

## 6. What's Next

After {PHASE_NAME} is merged, proceed to **{NEXT_PHASE}**. See [{next-phase-link}]({next-phase-link}).

### Lessons to carry forward

- {lesson 1}
- {lesson 2}

---

## Execution Log

Record notes, issues, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
