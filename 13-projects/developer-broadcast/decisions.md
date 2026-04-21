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
