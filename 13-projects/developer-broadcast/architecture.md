# Developer Broadcast — Architecture

## TL;DR

A Next.js 16 full-stack app that aggregates RSS feeds and API sources into a unified article feed. PostgreSQL stores channels, articles, and subscriptions. A cron job fetches new content on a schedule. TanStack Query handles client-side caching and pagination.

## High-Level Architecture

```mermaid
flowchart TB
  subgraph client [Browser]
    UI["Next.js App Router + shadcn/ui"]
    TQ["TanStack Query (cache + polling)"]
    UI --> TQ
  end

  subgraph server [Next.js Server]
    RSC["React Server Components"]
    SA["Server Actions"]
    RH["Route Handlers (API)"]
    CRON["Cron Route (/api/cron/fetch-feeds)"]
  end

  subgraph fetchers [Feed Fetchers]
    RSS["RSS Parser"]
    API["API Fetcher (HN, etc.)"]
  end

  subgraph data [Data Layer]
    PRISMA["Prisma ORM"]
    PG["PostgreSQL (Docker)"]
    PRISMA --> PG
  end

  TQ --> RH
  RSC --> PRISMA
  SA --> PRISMA
  RH --> PRISMA
  CRON --> fetchers
  fetchers --> PRISMA
```

## Feed Ingestion Data Flow

```mermaid
sequenceDiagram
  participant Cron as Vercel Cron / curl
  participant Route as /api/cron/fetch-feeds
  participant Manager as FetchManager
  participant Fetcher as RSS/API Fetcher
  participant DB as PostgreSQL

  Cron->>Route: POST (with CRON_SECRET)
  Route->>Manager: fetchAll()
  Manager->>DB: Get all channels
  DB-->>Manager: Channel[]

  loop Each channel
    Manager->>Fetcher: fetch(channel)
    Fetcher-->>Manager: Article[]
    Manager->>DB: Upsert articles (dedupe by URL)
    Manager->>DB: Update channel.lastFetchedAt
  end

  Route-->>Cron: 200 OK (summary)
```

## Database Schema (Prisma)

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Channel {
  id            String         @id @default(cuid())
  name          String
  slug          String         @unique
  description   String?
  url           String
  feedUrl       String?
  type          ChannelType
  logoUrl       String?
  category      String
  metadata      Json?
  articles      Article[]
  subscriptions Subscription[]
  lastFetchedAt DateTime?
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt
}

enum ChannelType {
  RSS
  API
  SCRAPE
  WEBHOOK
}

model Article {
  id          String   @id @default(cuid())
  channelId   String
  channel     Channel  @relation(fields: [channelId], references: [id], onDelete: Cascade)
  title       String
  summary     String?
  content     String?
  url         String   @unique
  imageUrl    String?
  author      String?
  tags        String[]
  publishedAt DateTime
  createdAt   DateTime @default(now())

  @@index([channelId, publishedAt(sort: Desc)])
}

model Subscription {
  id        String   @id @default(cuid())
  visitorId String   // Phase 1: anonymous localStorage ID; Phase 2: migrated to userId
  channelId String
  channel   Channel  @relation(fields: [channelId], references: [id], onDelete: Cascade)
  notify    Boolean  @default(true)
  createdAt DateTime @default(now())

  @@unique([visitorId, channelId])
}
```

### Phase 2 additions (not yet implemented)

```prisma
model User {
  id            String         @id @default(cuid())
  name          String?
  email         String         @unique
  image         String?
  accounts      Account[]
  subscriptions Subscription[]
  preferences   UserPreference?
  notifications Notification[]
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?
  user              User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}

model UserPreference {
  id                String  @id @default(cuid())
  userId            String  @unique
  user              User    @relation(fields: [userId], references: [id], onDelete: Cascade)
  emailDigest       Boolean @default(false)
  digestFrequency   String  @default("daily")
  pushNotifications Boolean @default(true)
  quietHoursStart   String?
  quietHoursEnd     String?
  timezone          String  @default("UTC")
}

model Notification {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  title     String
  body      String
  url       String?
  read      Boolean  @default(false)
  createdAt DateTime @default(now())

  @@index([userId, read, createdAt(sort: Desc)])
}
```

## Project Directory Structure

```
developer-broadcast/
├── docker-compose.yml
├── .env / .env.example
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── package.json
├── prisma/
│   ├── schema.prisma
│   └── seed.ts
├── src/
│   ├── app/
│   │   ├── layout.tsx                    # Root layout, providers
│   │   ├── page.tsx                      # Landing page / hero + featured channels
│   │   ├── feed/
│   │   │   └── page.tsx                  # Main feed: aggregated articles
│   │   ├── channels/
│   │   │   ├── page.tsx                  # Browse all channels by category
│   │   │   └── [slug]/
│   │   │       └── page.tsx              # Channel detail + article list
│   │   └── api/
│   │       ├── channels/
│   │       │   └── route.ts              # GET channels
│   │       ├── articles/
│   │       │   └── route.ts              # GET articles (paginated)
│   │       ├── subscriptions/
│   │       │   └── route.ts              # GET/POST/DELETE subscriptions
│   │       └── cron/
│   │           └── fetch-feeds/
│   │               └── route.ts          # POST trigger feed fetch
│   ├── components/
│   │   ├── ui/                           # shadcn/ui generated components
│   │   ├── layout/
│   │   │   ├── header.tsx                # Nav, theme toggle, notification placeholder
│   │   │   ├── sidebar.tsx               # Subscribed channels list
│   │   │   └── mobile-nav.tsx            # Responsive mobile navigation
│   │   ├── feed/
│   │   │   ├── article-card.tsx          # Title, summary, source, time, tags
│   │   │   ├── article-list.tsx          # Infinite scroll list
│   │   │   └── feed-filters.tsx          # Filter by channel, category, date
│   │   └── channels/
│   │       ├── channel-card.tsx          # Channel preview with subscribe button
│   │       ├── channel-grid.tsx          # Grid layout of channel cards
│   │       └── subscribe-button.tsx      # Toggle subscribe/unsubscribe
│   ├── hooks/
│   │   ├── use-visitor-id.ts             # Anonymous visitorId from localStorage
│   │   ├── use-articles.ts              # TanStack Query: paginated articles
│   │   ├── use-channels.ts             # TanStack Query: channel list
│   │   └── use-subscriptions.ts         # TanStack Query: manage subscriptions
│   ├── lib/
│   │   ├── prisma.ts                     # Prisma client singleton
│   │   ├── utils.ts                      # cn(), formatDate, etc.
│   │   └── fetchers/
│   │       ├── rss-fetcher.ts            # Generic RSS/Atom parser
│   │       ├── hn-fetcher.ts             # Hacker News Firebase API
│   │       └── fetch-manager.ts          # Orchestrator: dispatch + upsert
│   └── providers/
│       ├── query-provider.tsx            # TanStack QueryClientProvider
│       └── theme-provider.tsx            # next-themes provider
└── public/
```

## Pre-Seeded Channels

| Name | Category | Type | Feed URL |
|------|----------|------|----------|
| Hacker News | Aggregator | API | `https://hacker-news.firebaseio.com/v0` |
| TechCrunch | Tech News | RSS | `https://techcrunch.com/feed/` |
| The Verge | Tech News | RSS | `https://www.theverge.com/rss/index.xml` |
| GitHub Blog | Developer | RSS | `https://github.blog/feed/` |
| AWS What's New | Cloud | RSS | `https://aws.amazon.com/about-aws/whats-new/recent/feed/` |
| Google Blog | Big Tech | RSS | `https://blog.google/rss/` |
| Netflix Tech Blog | Big Tech | RSS | `https://netflixtechblog.com/feed` |
| Uber Engineering | Big Tech | RSS | `https://eng.uber.com/feed/` |
| Engineering at Meta | Big Tech | RSS | `https://engineering.fb.com/feed/` |
| Vercel Blog | Developer | RSS | `https://vercel.com/atom` |
| Next.js Blog | Framework | RSS | `https://nextjs.org/feed.xml` |

## Key Design Decisions

- **Anonymous subscriptions (Phase 1)**: Uses a `visitorId` generated client-side and stored in localStorage. No auth required. Migrated to `userId` FK in Phase 2.
- **Cursor-based pagination**: Articles use cursor pagination (`lastPublishedAt` + `id`) for stable infinite scroll.
- **Upsert by URL**: Feed fetching deduplicates articles by their unique `url` field, so re-fetching the same feed never creates duplicates.
- **Channel type dispatch**: `FetchManager` reads `channel.type` to pick the right fetcher (RSS parser vs HN API client vs scraper).

## References

- [decisions.md](./decisions.md) — Full ADR log explaining each architectural choice
- [implementation-plan.md](./implementation-plan.md) — Step-by-step build plan
