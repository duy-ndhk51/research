# Telegram Notifications Execution

Step-by-step execution guide for adding Telegram notifications to Developer Broadcast. Each commit is independently verifiable and revertable.

**Created**: 2026-05-10
**Status**: In progress
**Architecture**: [README.md](../../../developer-broadcast/README.md)
**Template**: [execution-template.md](../../templates/execution-template.md)
**Branch**: `feature/telegram-notifications`

---

## 1. Overview

**Goal**: Send new RSS articles to Telegram with safe dedupe, dry-run verification, and scheduled execution.

**Structure**: 12 commits across 5 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Shared planning docs | Low | 1-2 |
| **PR 2** | Pure notification core | Low | 3-5 |
| **PR 3** | Telegram sending and dedupe | Medium | 6-8 |
| **PR 4** | Scheduled execution | Medium | 9-10 |
| **PR 5** | Topic support and operations | Low | 11-12 |

**Why 5 PRs**: docs, pure logic, side-effecting integrations, scheduling, and operations can each be reviewed and rolled back independently.

### Prerequisites

- Telegram bot created with BotFather.
- Private chat or test group available for live smoke tests.
- Upstash Redis or compatible REST Redis credentials available before enabling live sends.
- GitHub Actions secrets can be configured in the repository.

---

## 2. Before You Start

### Capture baselines

Run these from the `developer-broadcast` root and save the output:

```bash
pnpm install
pnpm lint 2>&1 | tee /tmp/developer-broadcast-telegram-lint-before.txt
pnpm build 2>&1 | tee /tmp/developer-broadcast-telegram-build-before.txt
```

### Create branch

```bash
git checkout main
git pull origin main
git checkout -b feature/telegram-notifications
```

---

## 3. PR 1 — Shared Planning Template

Move the generic execution template into a shared location and add this implementation guide.

### Commit 1: Share Execution Template

**What**: Move the reusable template to `research/templates/execution-template.md`.

**Files to create**:

- `../research/templates/execution-template.md`

**Files to remove**:

- `../research/12-sndq/frontend/restructure/monorepo-ui-design-system/execution-template.md`

**Verification**:

```bash
test -f ../research/templates/execution-template.md
test ! -f ../research/12-sndq/frontend/restructure/monorepo-ui-design-system/execution-template.md
```

**Commit message**: `docs: share execution template`

### Commit 2: Add Telegram Execution Guide

**What**: Add this app-specific execution guide.

**Files to create**:

- `../research/13-projects/developer-broadcast/telegram-notifications.md`

**Verification**:

```bash
test -f ../research/13-projects/developer-broadcast/telegram-notifications.md
```

**Commit message**: `docs: add telegram execution guide`

---

## 4. PR 2 — Notification Core Without Side Effects

Add configuration and pure helpers before adding network calls.

### Commit 3: Add Notification Config

**What**: Add notification config for all RSS channels, caps, age limits, and optional topic mapping.

**Files to create**:

- `src/config/notifications.ts`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `feat: add notification config`

### Commit 4: Add Article Filtering

**What**: Add pure helpers to canonicalize URLs, filter eligible articles, sort by recency, and cap each run.

**Files to create**:

- `src/lib/notifications/filter.ts`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `feat: add article filtering`

### Commit 5: Add Telegram Message Formatter

**What**: Add HTML-safe Telegram formatting for articles.

**Files to create**:

- `src/lib/notifications/format.ts`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `feat: add Telegram message formatter`

---

## 5. PR 3 — Telegram Sending And Dedupe

Add side-effecting integrations behind dry-run checks.

### Commit 6: Add Telegram Client

**What**: Add a native `fetch` Telegram Bot API client.

**Files to create**:

- `src/lib/notifications/telegram.ts`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `feat: add Telegram client`

### Commit 7: Add Redis Dedupe Store

**What**: Add Redis REST dedupe tracking by canonical article URL.

**Files to create**:

- `src/lib/notifications/dedupe.ts`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `feat: add Redis dedupe store`

### Commit 8: Add Broadcast Orchestrator

**What**: Fetch feeds, filter articles, check dedupe, send messages, and record successful sends.

**Files to create**:

- `src/lib/notifications/broadcast.ts`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `feat: add broadcast orchestrator`

---

## 6. PR 4 — Scheduled Execution

Run the notification job without relying on Vercel Cron.

### Commit 9: Add Notification Script

**What**: Add a CLI entry point and package script for dry-run and live notification runs.

**Files to create**:

- `scripts/notify-telegram.ts`

**Files to edit**:

- `package.json`

**Verification**:

```bash
pnpm notify:telegram -- --dry-run
```

**Commit message**: `feat: add notification script`

### Commit 10: Schedule Telegram Notifications

**What**: Add a GitHub Actions workflow with manual dispatch and a 30-minute schedule.

**Files to create**:

- `.github/workflows/telegram-notifications.yml`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `ci: schedule Telegram notifications`

---

## 7. PR 5 — Topic Support And Operations

Keep private chat working while allowing private group topics later.

### Commit 11: Support Telegram Topics

**What**: Route articles to optional `message_thread_id` values per channel when configured.

**Files to edit**:

- `src/config/notifications.ts`
- `src/lib/notifications/broadcast.ts`
- `src/lib/notifications/telegram.ts`

**Verification**:

```bash
pnpm notify:telegram -- --dry-run
```

**Commit message**: `feat: support Telegram topics`

### Commit 12: Document Notification Operations

**What**: Document setup, secrets, smoke tests, troubleshooting, and topic migration.

**Files to edit**:

- `README.md`

**Verification**:

```bash
pnpm lint
pnpm build
```

**Commit message**: `docs: document notification operations`

---

## 8. Final Verification

Run from the `developer-broadcast` root:

```bash
pnpm install
pnpm lint
pnpm build
pnpm notify:telegram -- --dry-run
```

Then manually trigger the GitHub Actions workflow in dry-run mode. After secrets are configured and a test chat is ready, run one live workflow dispatch and confirm the expected capped set of messages appears in Telegram.

---

## Execution Log

| Date | Commit | Notes |
|------|--------|-------|
| 2026-05-10 | 1 | Shared generic execution template. |
| 2026-05-10 | 2 | Added Telegram notification execution guide. |
