# Developer Broadcast — Architecture Decision Records

This log captures key architectural decisions, their context, and trade-offs. New decisions are appended at the bottom.

---

## ADR-001: Next.js API Routes Over NestJS for Backend

**Status:** Accepted
**Date:** 2026-04-22

### Context

The app needs a backend for API routes, feed fetching cron jobs, and data access. Two options were considered: a separate NestJS backend or using Next.js Route Handlers and Server Actions.

### Decision

Use Next.js Route Handlers and Server Actions for the backend.

### Consequences

**Positive:**
- Single deployment unit — no separate backend to host, monitor, or version
- Server Actions enable calling server logic directly from React components without manual API wiring
- Route Handlers cover REST API needs for TanStack Query integration
- Vercel Cron integrates natively with Next.js route handlers
- Faster iteration: no context switching between two codebases

**Negative:**
- If the backend grows complex (WebSockets, microservices, heavy domain logic), Next.js may not be the right fit
- Less structured than NestJS (no built-in dependency injection, decorators, modules)

**Migration path:** If complexity demands it, extract API routes into a standalone NestJS service. The Prisma schema and fetcher logic are framework-agnostic and portable.

---

## ADR-002: PostgreSQL Over MongoDB and SQLite

**Status:** Accepted
**Date:** 2026-04-22

### Context

The app stores channels, articles, and user subscriptions — inherently relational data with foreign keys and join queries (e.g., "get articles from my subscribed channels"). Three database options were evaluated.

### Decision

Use PostgreSQL 16, running locally via Docker, with Prisma as the ORM.

### Consequences

**Why not MongoDB:**
- Subscriptions are a many-to-many relationship (user ↔ channel) — relational DBs handle this natively with join tables
- Aggregation queries (articles by channel, filtered by subscription) are simpler in SQL
- MongoDB would require denormalization that adds complexity without benefit at this scale

**Why not SQLite:**
- SQLite works well for embedded/single-process apps but doesn't support concurrent writes from cron jobs + API requests
- No built-in JSONB support for flexible channel metadata
- Harder to deploy on Vercel (ephemeral filesystem)

**Why PostgreSQL:**
- Strong relational model for subscription/channel/article joins
- Built-in full-text search (`tsvector`/`tsquery`) for article search later
- JSONB columns for flexible channel metadata without schema changes
- Free hosting options: Neon, Supabase, Railway
- Prisma has first-class PostgreSQL support

---

## ADR-003: Anonymous visitorId for Phase 1 Subscriptions

**Status:** Accepted
**Date:** 2026-04-22

### Context

Phase 1 ships without authentication (MVP scope decision). Users still need to subscribe to channels and persist their subscriptions across page reloads.

### Decision

Generate a random `visitorId` (cuid) client-side, store it in `localStorage`, and use it as the subscription identifier in the database.

### Consequences

**Positive:**
- Zero friction: no signup/login required to start using the app
- Subscriptions persist across page reloads and sessions (same browser)
- Simple implementation: one `useVisitorId` hook

**Negative:**
- Subscriptions are lost if the user clears localStorage or switches browsers/devices
- No cross-device sync until auth is added
- Potential for orphaned subscription records if visitors never return

**Migration path (Phase 2):** When auth is added, a migration script will associate existing `visitorId` subscriptions with the authenticated user (prompt: "We found subscriptions from this browser — import them to your account?"). The `visitorId` column will be replaced with a `userId` FK.

---

## ADR-004: pnpm as Package Manager

**Status:** Accepted
**Date:** 2026-04-22

### Context

The project needs a JavaScript package manager. Options: npm, yarn, pnpm, bun.

### Decision

Use pnpm.

### Consequences

**Positive:**
- Strict dependency resolution — no phantom dependencies (packages only accessible if explicitly declared)
- Content-addressable storage saves disk space across projects
- Fast installation via hard links
- Good monorepo support if the project grows (workspaces)
- Widely adopted in the Next.js/Vercel ecosystem

**Negative:**
- Some CI environments may need explicit pnpm setup (`pnpm/action-setup`)
- Team members unfamiliar with pnpm need minor onboarding

---

## ADR-005: Vercel as Deployment Target

**Status:** Accepted
**Date:** 2026-04-22

### Context

The app needs hosting with support for SSR, API routes, and scheduled cron jobs. Options: Vercel, Netlify, self-hosted (Docker on VPS), AWS.

### Decision

Target Vercel for production deployment.

### Consequences

**Positive:**
- Zero-config Next.js deployment (built by the same team)
- Built-in cron jobs via `vercel.json` — no external scheduler needed
- Edge functions, ISR, and streaming SSR out of the box
- Preview deployments per git branch/PR
- Generous free tier for personal projects

**Negative:**
- Vendor lock-in to Vercel's infrastructure (mitigated by Next.js 16.2's stable Adapter API)
- Serverless function cold starts for infrequent API routes
- Vercel Cron has limits on free tier (daily invocations)

**Note:** Local development uses Docker Postgres directly. The Vercel deployment will connect to a hosted PostgreSQL (Neon or Supabase) configured via `DATABASE_URL`.

---

## ADR-006: TanStack Query Over SWR

**Status:** Accepted
**Date:** 2026-04-22

### Context

The app needs client-side data fetching with caching, pagination, and mutation support. The two main options in the React ecosystem are SWR (by Vercel) and TanStack Query (formerly React Query).

### Decision

Use TanStack Query v5.

### Consequences

**Positive:**
- First-class `useInfiniteQuery` for the article feed's infinite scroll
- Built-in mutation support with optimistic updates (subscribe/unsubscribe)
- Rich devtools for debugging cache state during development
- Query invalidation and refetching patterns are more explicit and predictable
- Larger ecosystem of community plugins and patterns

**Negative:**
- Slightly larger bundle than SWR (~13KB vs ~4KB gzipped)
- More boilerplate for simple cases (SWR's API is more minimal)

**Note:** SWR would also work fine. TanStack Query was chosen specifically for its infinite query support and mutation/optimistic update capabilities, which are core to the feed and subscription UX.

---

## ADR-007: Gradual Micro-Phase Approach (Defer Database and Client-Side Fetching)

**Status:** Accepted
**Date:** 2026-04-23

### Context

The original implementation plan required Postgres + Docker + Prisma + API routes + TanStack Query + cron as the very first steps (Phase 1, items 1.1–1.45). This is the right architecture for a multi-user product, but the app currently has a single user. The overhead of maintaining database infrastructure, writing API routes, and setting up client-side data fetching is not justified until either the app is shared with others or article history/search is needed.

### Decision

Restructure the build plan into 6 micro-phases (Phase 0–5), each producing a usable app. Defer database, API routes, and TanStack Query to Phase 5. Start with zero infrastructure: React Server Components fetch RSS feeds directly, Next.js ISR handles caching, and localStorage stores channel preferences.

### Consequences

**Positive:**
- Phase 0 is achievable in a single session (~2-3 hours) and delivers core value (unified feed)
- No Docker, no database migrations, no seed scripts needed to get started
- Each phase is independently useful — you can stop at any phase and have a working app
- Infrastructure decisions can be deferred until real usage reveals what's actually needed
- Reduces risk of over-engineering before product-market fit (even for a personal tool)

**Negative:**
- No article history — articles disappear from the feed as they fall off the RSS feed (typically 10-30 most recent per source)
- No full-text search until database is added
- No cross-device subscription sync (localStorage only)
- ISR caching means the first load after 15 minutes is slower while re-fetching
- Some work in Phase 0-4 gets rewritten in Phase 5 (e.g., feed page moves from RSC to TanStack Query infinite scroll)

**What gets deferred:**
- PostgreSQL + Docker → Phase 5
- Prisma ORM → Phase 5
- API routes → Phase 5
- TanStack Query → Phase 5
- Cron-based feed fetching → Phase 5
- visitorId subscriptions → Phase 5 (replaced by localStorage preferences in Phase 4)
- Authentication → Indefinitely (original Phase 2)
- Notifications → Indefinitely (original Phase 3)

**ADR-002 amendment:** The decision to use PostgreSQL (ADR-002) remains valid as the target architecture. This ADR does not change the database choice — it only defers when the database is introduced. SQLite was reconsidered for the intermediate phases but deemed unnecessary since ISR caching provides sufficient performance for a single user.

**ADR-006 amendment:** The decision to use TanStack Query (ADR-006) also remains valid for Phase 5. In Phases 0-4, React Server Components handle all data fetching without any client-side JavaScript, making TanStack Query unnecessary until infinite scroll and optimistic mutations are needed.
