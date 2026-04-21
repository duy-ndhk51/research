# Developer Broadcast

A personalized news aggregation app for developers — subscribe to big tech blogs, engineering channels, and any RSS feed to get a unified feed of what matters to you.

## Motivation

Keeping up with engineering blogs, product launches, and tech news across dozens of sources is fragmented. Developer Broadcast consolidates everything into one feed you control — subscribe to the channels you care about, skip the rest.

## Goals

1. Aggregate articles from RSS feeds, APIs (Hacker News), and web sources into a single timeline
2. Let users subscribe to channels and customize what appears in their feed
3. Notify users of new content from their subscribed channels
4. Start simple (anonymous, no auth) and layer in authentication and notifications progressively

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | Next.js 16.2.x | App Router, Turbopack, React Server Components |
| Package Manager | pnpm | Strict, fast, good monorepo support |
| Styling | Tailwind CSS v4 | Ships with Next.js 16 |
| Design System | shadcn/ui (latest) | Accessible, composable, open code |
| Data Fetching | TanStack Query v5 | Infinite queries, caching, optimistic updates |
| ORM | Prisma (latest) | Type-safe queries, migrations, seeding |
| Database | PostgreSQL 16 | Docker for local dev |
| Auth (Phase 2) | Auth.js v5 | GitHub + Google OAuth |
| Notifications (Phase 3) | Web Push + Resend | In-app bell, email digest |
| Deployment | Vercel | Native Next.js, built-in cron |
| Feed Parsing | rss-parser | RSS/Atom feed normalization |

## Links

| Resource | Path |
|----------|------|
| App Repository | `/Users/admin/projects/private/developer-broadcast/` |
| Architecture | [architecture.md](./architecture.md) |
| Implementation Plan | [implementation-plan.md](./implementation-plan.md) |
| Progress Tracker | [progress.md](./progress.md) |
| Decision Log | [decisions.md](./decisions.md) |

## Quick Start

> To be filled in once implementation begins.

```bash
# 1. Start database
docker compose up -d

# 2. Install dependencies
pnpm install

# 3. Run migrations and seed
pnpm prisma migrate dev
pnpm prisma db seed

# 4. Start dev server
pnpm dev
```
