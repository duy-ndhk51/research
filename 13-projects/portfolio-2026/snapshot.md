# Portfolio 2026 — technical snapshot

**Snapshot date:** 2026-05-03  
**Purpose:** Frozen baseline for stack and layout. Update only when you intentionally re-snapshot after major upgrades.

## Code location

`/Users/admin/projects/private/portfolio-2026/`

## Stack (from `package.json`)

| Item | Version / note |
|------|----------------|
| Next.js | 16.1.6 |
| React / React DOM | 19.2.4 |
| TypeScript | 5.9.x |
| Tailwind CSS | 4.1.18 |
| notion-client / notion-types / notion-utils / react-notion-x | ^7.7.0 |
| motion | ^12.33.0 |
| Package manager | pnpm 10.11.1 |
| Node | >= 18 |

Project name in package.json remains `nextjs-notion-starter-kit` (upstream starter identity).

## Main routes and entry points

| Area | Path in repo |
|------|----------------|
| Home | `app/page.tsx` — full-screen layout with `BackgroundBoxes` and `Sidebar` |
| Blog index | `app/blogs/page.tsx` |
| Blog post | `app/blogs/[pageId]/page.tsx` |
| Blog layout | `app/blogs/layout.tsx` |
| Root layout | `app/layout.tsx` |
| Feed | `app/feed.xml/route.ts` |
| Sitemap | `app/sitemap.ts` |
| Robots | `app/robots.ts` |
| Search API | `app/api/search-notion/route.ts` |
| Social image API | `app/api/social-image/route.tsx` |

## Notion and config

| Area | Path |
|------|------|
| Site config | `site.config.ts` (re-exports `lib/site-config`) |
| Notion API helpers | `lib/notion-api.ts`, `lib/notion.ts`, `lib/resolve-notion-page.ts` |
| Page rendering | `components/NotionPage.tsx`, `components/ClientNotionPage.tsx` |

## Deployment

**Status:** Deferred (Vercel account); production URL remains TBD until Phase A resumes.

**Target:** TBD (Vercel suggested by `pnpm deploy` script). Record production URL here when set:

- Production URL: _TBD_

## Cross-references

| Topic | Related notes |
|-------|----------------|
| Execution order | [tracking.md](./tracking.md) |
| MVP scope | [mvp-roadmap.md](./mvp-roadmap.md) |
