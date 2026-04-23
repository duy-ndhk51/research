# Developer Broadcast

A personalized news aggregation app for developers — subscribe to big tech blogs, engineering channels, and any RSS feed to get a unified feed of what matters to you.

## Motivation

Keeping up with engineering blogs, product launches, and tech news across dozens of sources is fragmented. Developer Broadcast consolidates everything into one feed you control — subscribe to the channels you care about, skip the rest.

## Goals

1. Aggregate articles from RSS feeds, APIs (Hacker News), and web sources into a single timeline
2. Let users customize what appears in their feed (show/hide channels)
3. Start with zero infrastructure and layer in complexity only when needed
4. Each build phase produces a usable app

## Build Strategy

The app is built in 6 micro-phases. Each phase is independently useful. Infrastructure (database, API routes, cron) is deferred to Phase 5.

| Phase | What You Get | Infrastructure |
|-------|-------------|----------------|
| **0** | Working RSS feed from 11 sources | None (SSR only) |
| **1** | Fast page loads (cached) | ISR (15 min) |
| **2** | Polished UI, channel pages, responsive | Same |
| **3** | Hacker News + mixed sources | Same |
| **4** | Channel show/hide preferences | localStorage |
| **5** | Full persistence, infinite scroll, subscriptions | Postgres + Docker |

## Tech Stack

Introduced incrementally per phase. Only install what the current phase needs.

| Layer | Technology | Phase | Notes |
|-------|-----------|-------|-------|
| Framework | Next.js 16.2.x | 0 | App Router, Turbopack, React Server Components |
| Package Manager | pnpm | 0 | Strict, fast, good monorepo support |
| Styling | Tailwind CSS v4 | 0 | Ships with Next.js 16 |
| Design System | shadcn/ui (latest) | 0 | Accessible, composable, open code |
| Feed Parsing | rss-parser | 0 | RSS/Atom feed normalization |
| Theme | next-themes | 0 | Dark mode support |
| ORM | Prisma (latest) | 5 | Type-safe queries, migrations, seeding |
| Database | PostgreSQL 16 | 5 | Docker for local dev |
| Data Fetching | TanStack Query v5 | 5 | Infinite queries, optimistic updates |
| Deployment | Vercel | 5 | Native Next.js, built-in cron |
| Auth | Auth.js v5 | Future | GitHub + Google OAuth |
| Notifications | Web Push + Resend | Future | In-app bell, email digest |

## Links

| Resource | Path |
|----------|------|
| App Repository | `/Users/admin/projects/private/developer-broadcast/` |
| Architecture | [architecture.md](./architecture.md) |
| Implementation Plan | [implementation-plan.md](./implementation-plan.md) |
| Progress Tracker | [progress.md](./progress.md) |
| Decision Log | [decisions.md](./decisions.md) |

## Quick Start (Phase 0)

```bash
# 1. Install dependencies
pnpm install

# 2. Start dev server
pnpm dev

# 3. Open the feed
open http://localhost:3000/feed
```

No database, no Docker, no environment variables needed for Phase 0-4.
