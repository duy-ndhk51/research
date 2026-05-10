# Telegram Notifications Execution

Step-by-step execution guide for adding Telegram notifications to Developer Broadcast. Each commit is independently verifiable and revertable.

**Created**: 2026-05-10
**Status**: Local verification complete; remote workflow and live Telegram/Redis verification deferred until current workflow changes are committed/pushed and GitHub secrets are configured
**Architecture**: [README.md](../../../developer-broadcast/README.md)
**Template**: [execution-template.md](../../templates/execution-template.md)
**Branch**: `feature/telegram-notifications`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Shared Planning Template](#3-pr-1--shared-planning-template)
4. [PR 2 — Notification Core Without Side Effects](#4-pr-2--notification-core-without-side-effects)
5. [PR 3 — Telegram Sending And Dedupe](#5-pr-3--telegram-sending-and-dedupe)
6. [PR 4 — Scheduled Execution](#6-pr-4--scheduled-execution)
7. [PR 5 — Topic Support And Operations](#7-pr-5--topic-support-and-operations)
8. [Final Verification](#8-final-verification)
9. [Execution Log](#execution-log)

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

### Known constraints

- Hacker News is configured as an API channel and is excluded from this RSS-only v1.
- Uber Engineering currently returns `404` during RSS fetches; the existing fetcher logs and skips it.
- Netflix Tech Blog currently fails Node certificate verification; the existing fetcher logs and skips it.
- Vercel Blog can intermittently time out during RSS fetches; the existing fetcher logs and skips it.
- Telegram private 1:1 chats do not support topics; topic routing requires a private group with Topics / Forum mode enabled.

---

## 2. Before You Start

### Notification quality gate before each implementation commit

Use this gate for every implementation commit. If an item is intentionally skipped, record it under that commit's **Deviations from the gate** section.

- [ ] Dry-run mode cannot send Telegram messages or write Redis state
- [ ] No Telegram, Redis, or local environment secrets are committed
- [ ] First live run cannot flood the chat with historical RSS items
- [ ] Articles are marked as sent only after Telegram accepts the message
- [ ] Dedupe uses canonical article URLs and survives process restarts
- [ ] Private chat delivery works before topic routing is enabled
- [ ] Topic routing is optional and falls back to the main chat when no thread id exists
- [ ] GitHub Actions scheduled runs are disabled until `TELEGRAM_NOTIFICATIONS_ENABLED=true`
- [ ] Build, lint, and dry-run verification commands are known before editing
- [ ] Any skipped verification is recorded as a deviation with a follow-up

### Documentation and comment policy

- Keep code comments focused on non-obvious safety behavior, such as first-run protection or retry handling.
- Put setup, secrets, workflow dispatch, topic migration, and troubleshooting in `README.md`.
- Keep the execution guide as the implementation checklist; keep operational instructions in the app docs.
- If runtime behavior differs from this plan, record the deviation in the relevant commit and execution log.

### Inspect current app state

Before implementation, inspect and record the current state:

- [ ] `../../../developer-broadcast/src/config/channels.ts` — confirm RSS vs API channel coverage
- [ ] `../../../developer-broadcast/src/lib/fetchers/rss-fetcher.ts` — confirm current failure handling
- [ ] `../../../developer-broadcast/package.json` — confirm scripts and package manager
- [ ] `../../../developer-broadcast/.github/workflows/` — confirm whether notification workflows already exist
- [ ] Existing feed failures are recorded: Uber Engineering `404`, Netflix certificate verification failure
- [ ] Existing dirty work in either repo is identified and not reverted accidentally

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

**Quality gate checklist**:

- [ ] Template language remains generic and not SNDQ-specific
- [ ] Shared checklist sections are reusable across project types
- [ ] Old SNDQ-local template path is intentionally removed or replaced

**Deviations from the gate**:

- **None expected** — docs-only move.

**Status**:

- [x] Quality gate checklist satisfied
- [x] Markdown reviewed
- [x] Committed

### Commit 2: Add Telegram Execution Guide

**What**: Add this app-specific execution guide.

**Files to create**:

- `../research/13-projects/developer-broadcast/telegram-notifications.md`

**Verification**:

```bash
test -f ../research/13-projects/developer-broadcast/telegram-notifications.md
```

**Commit message**: `docs: add telegram execution guide`

**Quality gate checklist**:

- [ ] Guide lives in `research/13-projects/developer-broadcast/`
- [ ] Links back to the app repo and shared template are correct
- [ ] Commit-by-commit verification and rollback notes are present

**Deviations from the gate**:

- **None expected** — docs-only guide.

**Status**:

- [x] Quality gate checklist satisfied
- [x] Markdown reviewed
- [x] Committed

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

**Quality gate checklist**:

- [ ] All RSS channels are enabled, including Product Hunt
- [ ] Hacker News API channel is intentionally excluded from v1
- [ ] Runtime values are read from environment variables with safe defaults
- [ ] No secrets are committed

**Deviations from the gate**:

- **Hacker News excluded** — it is API-based and needs a separate fetcher before notification support.

**Status**:

- [x] Quality gate checklist satisfied
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] Committed

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

**Quality gate checklist**:

- [ ] URL canonicalization removes tracking parameters before dedupe
- [ ] Filtering respects enabled channels and max article age
- [ ] Sorting is deterministic before applying the per-run cap
- [ ] Helpers are pure and side-effect free

**Deviations from the gate**:

- **None expected** — pure logic only.

**Status**:

- [x] Quality gate checklist satisfied
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] Committed

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

**Quality gate checklist**:

- [ ] Telegram HTML escaping covers titles, summaries, authors, channels, and URLs
- [ ] Message length is capped below Telegram's message limit
- [ ] Formatter does not perform network calls
- [ ] Output remains readable in a private chat

**Deviations from the gate**:

- **None expected** — pure formatting only.

**Status**:

- [x] Quality gate checklist satisfied
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] Committed

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

**Quality gate checklist**:

- [ ] Bot token is read only from environment variables
- [ ] Client supports private chats and optional `message_thread_id`
- [ ] Telegram 429 responses honor `retry_after` where available
- [ ] Errors include enough context without logging secrets

**Deviations from the gate**:

- **Live send deferred until secrets exist** — verify with dry run or a test chat first.

**Status**:

- [x] Quality gate checklist satisfied
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] Live smoke test completed or deviation documented
- [x] Committed

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

**Quality gate checklist**:

- [ ] Redis URL and token are read only from environment variables
- [ ] Sent keys use canonical URL hashes, not raw URLs
- [ ] Sent keys use a TTL to avoid unbounded growth
- [ ] First-run initialized state is stored separately from article keys

**Deviations from the gate**:

- **Live Redis verification deferred until credentials exist** — dry-run must avoid Redis writes.

**Status**:

- [x] Quality gate checklist satisfied
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] Duplicate skip behavior verified or deviation documented
- [x] Committed

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

**Quality gate checklist**:

- [ ] Dry-run logs intended sends without contacting Telegram or Redis
- [ ] First live run marks eligible current articles seen and sends nothing by default
- [ ] Articles are marked sent only after Telegram accepts the message
- [ ] Per-run cap protects against notification floods
- [ ] Known feed failures are logged and skipped without failing the whole run

**Deviations from the gate**:

- **Uber Engineering feed returns `404`** — expected current upstream behavior; fetcher skips it.
- **Netflix Tech Blog certificate verification fails** — expected current upstream behavior in Node; fetcher skips it.

**Status**:

- [x] Quality gate checklist satisfied
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] `pnpm notify:telegram -- --dry-run` exits successfully
- [x] Committed

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

**Quality gate checklist**:

- [ ] Script supports `--dry-run`
- [ ] Script supports `--force-first-run`
- [ ] Script exits promptly after completion in CI
- [ ] Script does not require starting the Next.js server

**Deviations from the gate**:

- **None expected** — CLI should be runnable locally and in GitHub Actions.

**Status**:

- [x] Quality gate checklist satisfied
- [x] `pnpm notify:telegram -- --dry-run` exits successfully
- [x] Committed

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

**Quality gate checklist**:

- [ ] Workflow has manual dispatch for dry-run testing
- [ ] Scheduled runs are gated by `TELEGRAM_NOTIFICATIONS_ENABLED=true`
- [ ] Workflow uses repository secrets and does not inline credentials
- [ ] Workflow installs dependencies with the lockfile

**Deviations from the gate**:

- **Live workflow test deferred until GitHub secrets exist** — manual dry-run dispatch should be tested first.

**Status**:

- [x] Quality gate checklist satisfied
- [x] Manual workflow dry-run dispatch attempted and deviation documented
- [x] Scheduled run remains gated until smoke testing
- [x] Committed

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

**Quality gate checklist**:

- [ ] Private chat behavior remains valid when no topic ids are configured
- [ ] Per-channel topic ids are read from secrets/env variables
- [ ] Missing topic id falls back to the main chat
- [ ] Topic routing is tested only in a private group with Topics / Forum mode enabled

**Deviations from the gate**:

- **Private chat has no topics** — topic verification requires a private Telegram group, not a 1:1 chat.

**Status**:

- [x] Quality gate checklist satisfied
- [x] Private chat dry-run still works
- [x] Private group topic smoke test completed or deviation documented
- [x] Committed

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

**Quality gate checklist**:

- [ ] README documents setup, secrets, dry run, scheduling, first-run behavior, and troubleshooting
- [ ] Topic migration instructions explain private group requirement
- [ ] Known feed failures and Hacker News exclusion are documented where useful
- [ ] Docs do not include real secrets

**Deviations from the gate**:

- **None expected** — docs-only operations update.

**Status**:

- [x] Quality gate checklist satisfied
- [x] Docs reviewed from a clean setup perspective
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] Committed

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

**Expected result**:

- RSS-only notification flow is implemented for all RSS channels, including Product Hunt.
- Hacker News remains excluded until an API fetcher is added.
- Dry-run mode logs intended sends and never contacts Telegram or writes Redis state.
- First live run marks current eligible articles as seen and sends nothing unless forced.
- GitHub Actions can run on demand and on schedule without Vercel Cron.
- Optional topic routing works only when Telegram group topic ids are configured.

**Known acceptable deviations**:

- Uber Engineering may continue to log `Status code 404` until its feed URL is corrected or removed.
- Netflix Tech Blog may continue to log `UNABLE_TO_VERIFY_LEAF_SIGNATURE` until certificate handling or the feed source is changed.
- Vercel Blog may intermittently log `Request timed out after 10000ms`; current behavior is to skip it for that run.
- GitHub Actions dry-run was attempted against the current remote workflow and failed before install because the remote workflow enables `cache: pnpm` before `pnpm` is available. The local workflow has been corrected, but it needs to be committed and pushed before re-running remote validation.
- GitHub live validation is deferred because repository secrets and variables are not configured yet.
- Private 1:1 chat testing cannot verify topics; topic verification requires a private group with Topics / Forum mode.

**Final status**:

- [x] All planned implementation files exist locally
- [x] `pnpm lint` passes
- [x] `pnpm build` passes
- [x] `pnpm notify:telegram -- --dry-run` exits quickly and sends nothing
- [x] GitHub Actions manual dispatch attempted and failure root cause recorded
- [ ] GitHub Actions manual dispatch dry-run passes after corrected workflow is committed/pushed
- [ ] First live run behavior confirmed in a test destination
- [x] Optional topic routing documented as deferred until a private group with Topics / Forum mode is available
- [x] Known feed deviations recorded in the execution log
- [ ] All PRs created and merged, or ready for merge

---

## Execution Log

| Date | Commit | Notes |
|------|--------|-------|
| 2026-05-10 | 1 | Shared generic execution template. |
| 2026-05-10 | 2 | Added Telegram notification execution guide. |
| 2026-05-10 | Known deviation | Uber Engineering feed returns `404`; current fetcher logs and skips it. |
| 2026-05-10 | Known deviation | Netflix Tech Blog feed fails Node certificate verification; current fetcher logs and skips it. |
| 2026-05-10 | 3-12 | Local implementation present. Added Spotify topic coverage to README and optional topic secret propagation in `.github/workflows/telegram-notifications.yml`. |
| 2026-05-10 | Local verification | `pnpm lint` passed. `pnpm build` passed with documented Uber `404` and Netflix certificate warnings. `pnpm notify:telegram -- --dry-run` passed in about 11s, logged 10 intended sends, and did not contact Telegram or Redis. |
| 2026-05-10 | GitHub Actions dry-run | Manual workflow dispatch attempted for run `25621479050`; it failed in `Setup Node.js` because the remote workflow used `cache: pnpm` before `pnpm` was available. Local workflow is corrected but must be committed and pushed before re-running remote validation. |
| 2026-05-10 | Live verification | Deferred. GitHub repository has no configured secrets or variables yet, so Telegram, Redis, first-run safety, duplicate-skip, and topic-routing live tests cannot be completed safely. |
