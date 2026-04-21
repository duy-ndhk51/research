# Developer Broadcast — Progress Tracker

Track implementation progress by checking off each step as it's completed.

---

## Phase 1 — MVP Feed Reader

### Setup & Infrastructure

- [ ] **1.1** Scaffold Next.js 16 project (`create-next-app`, pnpm)
- [ ] **1.2** Initialize shadcn/ui and add core components
- [ ] **1.3** Install runtime deps (`@prisma/client`, `@tanstack/react-query`, `rss-parser`)
- [ ] **1.4** Install dev deps (`prisma`, `@tanstack/react-query-devtools`)
- [ ] **1.5** Create `docker-compose.yml` for PostgreSQL 16
- [ ] **1.6** Create `.env` and `.env.example`
- [ ] **1.7** Start Docker Postgres and verify connection

### Database & ORM

- [ ] **1.8** Initialize Prisma (`prisma init`)
- [ ] **1.9** Define Channel, Article, Subscription models in `schema.prisma`
- [ ] **1.10** Run initial migration (`prisma migrate dev --name init`)
- [ ] **1.11** Create Prisma client singleton (`src/lib/prisma.ts`)
- [ ] **1.12** Create seed script (`prisma/seed.ts`) with 11 channels
- [ ] **1.13** Run seed and verify data (`prisma db seed`)

### Feed Ingestion

- [ ] **1.14** Build RSS fetcher (`src/lib/fetchers/rss-fetcher.ts`)
- [ ] **1.15** Build Hacker News API fetcher (`src/lib/fetchers/hn-fetcher.ts`)
- [ ] **1.16** Build fetch manager orchestrator (`src/lib/fetchers/fetch-manager.ts`)
- [ ] **1.17** Create cron API route (`src/app/api/cron/fetch-feeds/route.ts`)
- [ ] **1.18** Test feed fetching locally via curl
- [ ] **1.19** Create `vercel.json` with cron config

### Providers & Layout

- [ ] **1.20** Create TanStack Query provider (`src/providers/query-provider.tsx`)
- [ ] **1.21** Create theme provider (`src/providers/theme-provider.tsx`)
- [ ] **1.22** Set up root layout (`src/app/layout.tsx`) with providers
- [ ] **1.23** Build header component (`src/components/layout/header.tsx`)
- [ ] **1.24** Build sidebar component (`src/components/layout/sidebar.tsx`)
- [ ] **1.25** Build mobile nav component (`src/components/layout/mobile-nav.tsx`)

### API Routes

- [ ] **1.26** Channels route — GET all, GET by category (`src/app/api/channels/route.ts`)
- [ ] **1.27** Articles route — GET paginated, filterable (`src/app/api/articles/route.ts`)
- [ ] **1.28** Subscriptions route — GET/POST/DELETE by visitorId (`src/app/api/subscriptions/route.ts`)

### TanStack Query Hooks

- [ ] **1.29** `use-visitor-id.ts` — generate/persist anonymous ID in localStorage
- [ ] **1.30** `use-articles.ts` — infinite query for paginated articles
- [ ] **1.31** `use-channels.ts` — fetch channel list
- [ ] **1.32** `use-subscriptions.ts` — manage subscriptions with optimistic updates

### UI Components

- [ ] **1.33** `article-card.tsx` — card with title, summary, source, time, tags
- [ ] **1.34** `article-list.tsx` — infinite scroll with intersection observer
- [ ] **1.35** `feed-filters.tsx` — channel, category, date range filters
- [ ] **1.36** `channel-card.tsx` — channel preview with subscribe button
- [ ] **1.37** `channel-grid.tsx` — responsive grid layout
- [ ] **1.38** `subscribe-button.tsx` — toggle with optimistic update

### Pages

- [ ] **1.39** Landing page (`src/app/page.tsx`) — hero, featured channels, CTA
- [ ] **1.40** Feed page (`src/app/feed/page.tsx`) — infinite scroll, sidebar, filters
- [ ] **1.41** Channels page (`src/app/channels/page.tsx`) — browse by category
- [ ] **1.42** Channel detail (`src/app/channels/[slug]/page.tsx`) — info + articles

### Validation

- [ ] **1.43** End-to-end test: seed DB, fetch feeds, browse UI, subscribe, view feed
- [ ] **1.44** Responsive check: mobile, tablet, desktop
- [ ] **1.45** Dark mode toggle works correctly

---

## Phase 2 — Authentication

- [ ] **2.1** Install Auth.js v5 (`next-auth@beta`)
- [ ] **2.2** Add User and Account models to Prisma schema
- [ ] **2.3** Configure GitHub OAuth provider
- [ ] **2.4** Configure Google OAuth provider
- [ ] **2.5** Create auth API route (`src/app/api/auth/[...nextauth]/route.ts`)
- [ ] **2.6** Create auth config (`src/lib/auth.ts`)
- [ ] **2.7** Migrate Subscription.visitorId → Subscription.userId (migration script)
- [ ] **2.8** Add login/logout buttons to header
- [ ] **2.9** Add UserPreference model to schema
- [ ] **2.10** Create settings page (`src/app/(dashboard)/settings/page.tsx`)
- [ ] **2.11** Protect subscription routes with session check
- [ ] **2.12** End-to-end test: OAuth login, persistent subscriptions, settings

---

## Phase 3 — Notifications

- [ ] **3.1** Add Notification model to Prisma schema
- [ ] **3.2** Generate notifications in fetch-manager for subscribed users
- [ ] **3.3** Build notification bell component with unread count
- [ ] **3.4** Create notifications page (`src/app/(dashboard)/notifications/page.tsx`)
- [ ] **3.5** Implement mark-as-read and mark-all-read actions
- [ ] **3.6** Register service worker for Web Push
- [ ] **3.7** Integrate Web Push API for browser notifications
- [ ] **3.8** Install and configure Resend for email
- [ ] **3.9** Build email digest template (daily/weekly summary)
- [ ] **3.10** Create digest cron route (`src/app/api/cron/send-digest/route.ts`)
- [ ] **3.11** Add quiet hours and frequency settings to UserPreference
- [ ] **3.12** Build notification preferences UI in settings page
- [ ] **3.13** End-to-end test: in-app notifications, push, email digest
