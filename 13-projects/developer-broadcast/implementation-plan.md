# Developer Broadcast — Implementation Plan

## TL;DR

Build a news aggregation app in 3 phases. Phase 1 delivers a working MVP feed reader with no auth. Phase 2 adds authentication. Phase 3 adds notifications. This document contains every command, schema, and pattern needed to build each phase.

## Tech Stack (Locked In)

| Technology | Version | Role |
|-----------|---------|------|
| Next.js | 16.2.x | Full-stack framework (App Router, Turbopack) |
| pnpm | latest | Package manager |
| Tailwind CSS | v4 | Styling (ships with Next.js 16) |
| shadcn/ui | latest | Design system (accessible, composable) |
| TanStack Query | v5 | Client-side data fetching, caching, pagination |
| Prisma | latest | ORM with type-safe queries and migrations |
| PostgreSQL | 16 | Database (Docker for local dev) |
| Auth.js | v5 | Authentication (Phase 2) |
| Resend | latest | Email notifications (Phase 3) |
| rss-parser | latest | RSS/Atom feed parsing |
| Vercel | — | Deployment target with built-in cron |

---

## Phase 1 — MVP Feed Reader

### Step 1: Project Scaffolding

```bash
cd /Users/admin/projects/private/developer-broadcast

# Scaffold Next.js 16 with all recommended defaults
pnpm dlx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --turbopack --use-pnpm

# Initialize shadcn/ui
pnpm dlx shadcn@latest init

# Add core shadcn components
pnpm dlx shadcn@latest add button card input badge dialog sheet tabs avatar separator scroll-area toast switch skeleton command dropdown-menu

# Install runtime dependencies
pnpm add @prisma/client @tanstack/react-query rss-parser

# Install dev dependencies
pnpm add -D prisma @tanstack/react-query-devtools
```

### Step 2: Docker Postgres Setup

Create `docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: broadcast
      POSTGRES_PASSWORD: broadcast
      POSTGRES_DB: developer_broadcast
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
```

Create `.env`:

```
DATABASE_URL="postgresql://broadcast:broadcast@localhost:5432/developer_broadcast"
CRON_SECRET="dev-secret-change-in-production"
```

Create `.env.example` (same keys, no values):

```
DATABASE_URL=
CRON_SECRET=
```

Start the database:

```bash
docker compose up -d
```

### Step 3: Prisma Schema

Initialize Prisma:

```bash
pnpm prisma init --datasource-provider postgresql
```

Models for Phase 1:

- **Channel** — id (cuid), name, slug (unique), description, url, feedUrl, type (enum: RSS/API/SCRAPE/WEBHOOK), logoUrl, category, metadata (Json), lastFetchedAt, createdAt, updatedAt
- **Article** — id (cuid), channelId (FK → Channel), title, summary, content, url (unique), imageUrl, author, tags (String[]), publishedAt, createdAt. Compound index on `[channelId, publishedAt DESC]`
- **Subscription** — id (cuid), visitorId (String), channelId (FK → Channel), notify (Boolean, default true), createdAt. Unique constraint on `[visitorId, channelId]`

The `visitorId` is a random ID generated client-side and stored in `localStorage`. This lets anonymous users subscribe without authentication. In Phase 2, this field migrates to a `userId` foreign key.

Run migrations:

```bash
pnpm prisma migrate dev --name init
```

Create `src/lib/prisma.ts` — singleton pattern for the Prisma client:

```typescript
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
```

### Step 4: Feed Fetcher Infrastructure

Three modules in `src/lib/fetchers/`:

**rss-fetcher.ts**
- Uses `rss-parser` to fetch and parse any RSS/Atom feed URL
- Normalizes each item into the Article shape: `{ title, summary, url, author, publishedAt, imageUrl }`
- Handles missing fields gracefully (summary fallback from content, date parsing)

**hn-fetcher.ts**
- Fetches top 30 stories from `https://hacker-news.firebaseio.com/v0/topstories.json`
- Fetches each story detail from `/v0/item/{id}.json`
- Maps to Article shape (HN stories have `title`, `url`, `by`, `time`)
- Parallelizes detail fetches with `Promise.all` (batched)

**fetch-manager.ts**
- Loads all channels from DB
- For each channel, dispatches to the correct fetcher based on `channel.type`
- Upserts articles using `prisma.article.upsert({ where: { url }, ... })` to deduplicate
- Updates `channel.lastFetchedAt` after successful fetch
- Returns a summary: `{ channelsProcessed, articlesAdded, errors }`

### Step 5: Cron API Route

Create `src/app/api/cron/fetch-feeds/route.ts`:

- POST handler protected by `Authorization: Bearer ${CRON_SECRET}` header check
- Calls `fetchManager.fetchAll()`
- Returns JSON summary of what was fetched
- On Vercel: configure in `vercel.json` to run every 15 minutes
- Locally: trigger with `curl -X POST -H "Authorization: Bearer dev-secret" http://localhost:3000/api/cron/fetch-feeds`

`vercel.json` (for production):

```json
{
  "crons": [
    {
      "path": "/api/cron/fetch-feeds",
      "schedule": "*/15 * * * *"
    }
  ]
}
```

### Step 6: Pre-Seeded Channels

Create `prisma/seed.ts` that inserts 11 channels:

| Name | Slug | Category | Type |
|------|------|----------|------|
| Hacker News | hacker-news | Aggregator | API |
| TechCrunch | techcrunch | Tech News | RSS |
| The Verge | the-verge | Tech News | RSS |
| GitHub Blog | github-blog | Developer | RSS |
| AWS What's New | aws-whats-new | Cloud | RSS |
| Google Blog | google-blog | Big Tech | RSS |
| Netflix Tech Blog | netflix-tech-blog | Big Tech | RSS |
| Uber Engineering | uber-engineering | Big Tech | RSS |
| Engineering at Meta | engineering-at-meta | Big Tech | RSS |
| Vercel Blog | vercel-blog | Developer | RSS |
| Next.js Blog | nextjs-blog | Framework | RSS |

Configure seed in `package.json`:

```json
{
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
```

Run: `pnpm prisma db seed`

### Step 7: UI Pages and Components

**Layout components** (`src/components/layout/`):
- `header.tsx` — App name, navigation links (Feed, Channels), theme toggle button, notification bell placeholder
- `sidebar.tsx` — List of subscribed channels with unsubscribe option, channel count badge
- `mobile-nav.tsx` — Sheet-based hamburger menu for mobile viewports

**Feed components** (`src/components/feed/`):
- `article-card.tsx` — Card with: channel logo + name, article title (linked), summary (truncated), published time (relative), tag badges
- `article-list.tsx` — Infinite scroll container using `useInfiniteQuery`, intersection observer for "load more"
- `feed-filters.tsx` — Dropdown filters for channel, category, date range

**Channel components** (`src/components/channels/`):
- `channel-card.tsx` — Card with: logo, name, description, category badge, article count, subscribe button
- `channel-grid.tsx` — Responsive grid (1 col mobile, 2 col tablet, 3 col desktop)
- `subscribe-button.tsx` — Toggle button using `visitorId` from localStorage, optimistic update via TanStack Query mutation

**Pages** (`src/app/`):
- `page.tsx` — Landing: hero section, featured channels grid, CTA to browse all
- `feed/page.tsx` — Main feed with infinite scroll, sidebar, filters
- `channels/page.tsx` — Browse all channels grouped by category
- `channels/[slug]/page.tsx` — Channel detail: header info + paginated article list

**Key UI patterns:**
- Dark mode via `next-themes` with `ThemeProvider` in root layout
- Mobile-first responsive design using Tailwind breakpoints
- Loading states with shadcn Skeleton components
- Toast notifications for subscribe/unsubscribe feedback

### Step 8: TanStack Query Setup

**Provider** (`src/providers/query-provider.tsx`):

```typescript
"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { useState } from "react";

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 5 * 60 * 1000,
            refetchOnWindowFocus: true,
          },
        },
      })
  );

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}
```

**Hook patterns:**

```typescript
// Infinite scroll articles
export function useArticles(filters: ArticleFilters) {
  return useInfiniteQuery({
    queryKey: ["articles", filters],
    queryFn: ({ pageParam }) =>
      fetchArticles({ ...filters, cursor: pageParam }),
    getNextPageParam: (lastPage) => lastPage.nextCursor,
  });
}

// Subscribe mutation with optimistic update
export function useSubscribe() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (channelId: string) => postSubscription(channelId),
    onMutate: async (channelId) => {
      await queryClient.cancelQueries({ queryKey: ["subscriptions"] });
      // optimistic update logic
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["subscriptions"] });
    },
  });
}
```

---

## Phase 2 — Authentication (Future)

1. Install Auth.js v5: `pnpm add next-auth@beta`
2. Add `User` and `Account` models to Prisma schema (see [architecture.md](./architecture.md))
3. Configure GitHub + Google OAuth providers in `src/lib/auth.ts`
4. Create `src/app/api/auth/[...nextauth]/route.ts`
5. Migrate `Subscription.visitorId` to `Subscription.userId` (FK to User)
6. Add login/logout UI to header
7. Create `src/app/(dashboard)/settings/page.tsx` for user preferences
8. Add `UserPreference` model for email digest, push notifications, quiet hours

## Phase 3 — Notifications (Future)

1. Add `Notification` model to Prisma schema
2. Create notification on new articles for subscribed users (in fetch-manager)
3. Build notification bell component with unread count badge
4. Create `src/app/(dashboard)/notifications/page.tsx` — notification center
5. Integrate Web Push API with service worker for browser push
6. Add Resend integration for email digest (daily/weekly)
7. Build preferences UI for quiet hours, frequency, per-channel notify toggle

---

## File-by-File Creation Order

| # | Files | Description |
|---|-------|-------------|
| 1 | `docker-compose.yml`, `.env`, `.env.example` | Database and environment |
| 2 | `prisma/schema.prisma`, `src/lib/prisma.ts`, `prisma/seed.ts` | Data layer |
| 3 | `src/providers/query-provider.tsx`, `src/providers/theme-provider.tsx` | Client providers |
| 4 | `src/app/layout.tsx` | Root layout with providers |
| 5 | `src/components/layout/header.tsx`, `sidebar.tsx`, `mobile-nav.tsx` | Shell components |
| 6 | `src/lib/fetchers/rss-fetcher.ts`, `hn-fetcher.ts`, `fetch-manager.ts` | Feed ingestion |
| 7 | `src/app/api/channels/route.ts`, `articles/route.ts`, `subscriptions/route.ts`, `cron/fetch-feeds/route.ts` | API routes |
| 8 | `src/hooks/use-visitor-id.ts`, `use-articles.ts`, `use-channels.ts`, `use-subscriptions.ts` | Query hooks |
| 9 | `src/components/feed/article-card.tsx`, `article-list.tsx`, `feed-filters.tsx` | Feed UI |
| 10 | `src/components/channels/channel-card.tsx`, `channel-grid.tsx`, `subscribe-button.tsx` | Channel UI |
| 11 | `src/app/page.tsx`, `feed/page.tsx`, `channels/page.tsx`, `channels/[slug]/page.tsx` | Pages |
| 12 | Seed DB, trigger fetch, verify flow | End-to-end validation |
