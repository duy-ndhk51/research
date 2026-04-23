# Developer Broadcast — Progress Tracker

Track implementation progress by checking off each step as it's completed. Each micro-phase produces a usable app.

---

## Phase 0 — Working Feed

> **Goal:** Fetch RSS feeds server-side and display a unified article timeline. No database, no API routes, no client-side fetching.

### Scaffolding

- [ ] **0.1** Scaffold Next.js 16 project (`create-next-app`, pnpm)
- [ ] **0.2** Initialize shadcn/ui and add Phase 0 components (`button`, `card`, `badge`, `separator`, `skeleton`)
- [ ] **0.3** Install Phase 0 deps (`rss-parser`, `next-themes`)

### Data Layer (Config-Based)

- [ ] **0.4** Create `src/config/channels.ts` with typed channel array (11 RSS channels)

### Feed Fetching

- [ ] **0.5** Build RSS fetcher (`src/lib/fetchers/rss-fetcher.ts`)
- [ ] **0.6** Define common `Article` type (`src/lib/types.ts`)

### UI

- [ ] **0.7** Build article card (`src/components/feed/article-card.tsx`)
- [ ] **0.8** Set up root layout with `ThemeProvider` (`src/app/layout.tsx`)
- [ ] **0.9** Build feed page as RSC — fetch all, merge, sort, render (`src/app/feed/page.tsx`)

### Verification

- [ ] **0.10** `pnpm dev` — feed page shows articles from multiple RSS sources
- [ ] **0.11** Dark mode toggle works
- [ ] **0.12** A broken feed URL does not crash the page

---

## Phase 1 — Fast Page Loads

> **Goal:** Cache fetched articles so the page loads instantly instead of re-fetching 11 feeds every time.

- [ ] **1.1** Add `revalidate = 900` (15 min ISR) to the feed page
- [ ] **1.2** Add per-channel error isolation (try/catch per fetch)
- [ ] **1.3** Verify: second load within 15 min is instant from cache
- [ ] **1.4** Verify: broken feed does not prevent caching

---

## Phase 2 — Polished UI

> **Goal:** Make the app look and feel good enough to use daily.

### Enhanced Components

- [ ] **2.1** Enhanced article card — logo, summary, tags, open-in-new-tab icon
- [ ] **2.2** Header component — nav links (Feed, Channels), theme toggle, responsive

### Pages

- [ ] **2.3** Channels browse page — grouped by category (`src/app/channels/page.tsx`)
- [ ] **2.4** Channel detail page — channel info + filtered articles (`src/app/channels/[slug]/page.tsx`)
- [ ] **2.5** Landing page — hero, featured channels, CTA (`src/app/page.tsx`)

### Polish

- [ ] **2.6** Skeleton loading states via `loading.tsx` in each route folder
- [ ] **2.7** Mobile-first responsive layout (Tailwind breakpoints)

### Verification

- [ ] **2.8** All pages render correctly on mobile, tablet, desktop
- [ ] **2.9** Dark mode works on all pages
- [ ] **2.10** Loading skeletons appear during navigation

---

## Phase 3 — Mixed Sources (Hacker News)

> **Goal:** Add non-RSS sources, starting with the Hacker News API.

- [ ] **3.1** Build HN fetcher (`src/lib/fetchers/hn-fetcher.ts`) — top 30 stories, batched detail fetches
- [ ] **3.2** Build fetch manager (`src/lib/fetchers/fetch-manager.ts`) — dispatch by channel type
- [ ] **3.3** Update channel config to include Hacker News (type: "API")
- [ ] **3.4** Update feed page and channel detail to use fetch manager
- [ ] **3.5** Verify: `/feed` interleaves RSS and HN articles by date
- [ ] **3.6** Verify: `/channels/hacker-news` shows only HN stories

---

## Phase 4 — Channel Preferences

> **Goal:** Show/hide channels from the feed via localStorage. No server-side storage.

- [ ] **4.1** Build `use-channel-preferences` hook (localStorage-based toggle)
- [ ] **4.2** Add toggle button on each channel card
- [ ] **4.3** Filter feed articles client-side based on enabled channels
- [ ] **4.4** Build sidebar — list enabled channels, desktop only
- [ ] **4.5** Build mobile nav for channel access on small screens
- [ ] **4.6** Verify: disabling a channel removes it from feed
- [ ] **4.7** Verify: preferences persist across reloads

---

## Phase 5 — Full Persistence

> **Goal:** Move to a real database with API routes, cron-based fetching, and TanStack Query. Required for article history, search, or multi-user.

### Infrastructure

- [ ] **5.1** Create `docker-compose.yml` for PostgreSQL 16
- [ ] **5.2** Create `.env` and `.env.example`
- [ ] **5.3** Start Docker Postgres and verify connection

### Database & ORM

- [ ] **5.4** Initialize Prisma (`prisma init`)
- [ ] **5.5** Define Channel, Article, Subscription models in `schema.prisma`
- [ ] **5.6** Run initial migration (`prisma migrate dev --name init`)
- [ ] **5.7** Create Prisma client singleton (`src/lib/prisma.ts`)
- [ ] **5.8** Create seed script (`prisma/seed.ts`) with 11 channels
- [ ] **5.9** Run seed and verify data

### Feed Ingestion (Database-Backed)

- [ ] **5.10** Migrate fetch manager to load channels from DB and upsert articles
- [ ] **5.11** Create cron API route (`src/app/api/cron/fetch-feeds/route.ts`)
- [ ] **5.12** Test feed fetching locally via curl
- [ ] **5.13** Create `vercel.json` with cron config

### API Routes

- [ ] **5.14** Channels route — GET all, filter by category
- [ ] **5.15** Articles route — GET cursor-paginated, filterable
- [ ] **5.16** Subscriptions route — GET/POST/DELETE by visitorId

### Client-Side Data Layer

- [ ] **5.17** Install TanStack Query v5
- [ ] **5.18** Create QueryProvider (`src/providers/query-provider.tsx`)
- [ ] **5.19** Build `use-visitor-id` hook (anonymous localStorage ID)
- [ ] **5.20** Build `use-articles` hook (infinite query)
- [ ] **5.21** Build `use-channels` hook
- [ ] **5.22** Build `use-subscriptions` hook (optimistic mutations)

### UI Updates

- [ ] **5.23** Convert feed page to client-side infinite scroll
- [ ] **5.24** Add feed filters (channel, category, date range)
- [ ] **5.25** Build subscribe button with optimistic toggle
- [ ] **5.26** Update sidebar to show subscriptions from database

### Verification

- [ ] **5.27** End-to-end: seed DB, trigger cron, browse feed, subscribe, view personalized feed
- [ ] **5.28** Infinite scroll loads more articles on scroll
- [ ] **5.29** Subscribe/unsubscribe is instant and persists
- [ ] **5.30** Responsive check: mobile, tablet, desktop

---

## Future — Authentication (Deferred)

> Only proceed when opening the app to other users.

- [ ] **F.1** Install Auth.js v5
- [ ] **F.2** Add User and Account models to Prisma schema
- [ ] **F.3** Configure GitHub OAuth provider
- [ ] **F.4** Configure Google OAuth provider
- [ ] **F.5** Create auth API route and config
- [ ] **F.6** Migrate Subscription.visitorId to Subscription.userId
- [ ] **F.7** Add login/logout UI to header
- [ ] **F.8** Create settings page
- [ ] **F.9** End-to-end test: OAuth login, persistent subscriptions

---

## Future — Notifications (Deferred)

> Only proceed when you want proactive alerts.

- [ ] **F.10** Add Notification model to Prisma schema
- [ ] **F.11** Generate notifications in fetch-manager for subscribed users
- [ ] **F.12** Build notification bell with unread count
- [ ] **F.13** Create notifications page
- [ ] **F.14** Integrate Web Push API
- [ ] **F.15** Integrate Resend for email digest
- [ ] **F.16** Build notification preferences UI
- [ ] **F.17** End-to-end test: in-app, push, and email notifications
