# Notion publishing workflow — Portfolio 2026

Use this as your single checklist for what appears on the site vs what stays in Notion as drafts or private.

## How this app decides what shows

- The site is rooted at the Notion page ID configured in `site.config.ts` as `rootNotionPageId` (code: `/Users/admin/projects/private/portfolio-2026/site.config.ts`).
- The blog index at `/blogs` resolves the same domain root page and renders it via `resolveNotionPage` and `ClientNotionPage` (see `app/blogs/page.tsx`).
- Child pages linked from that root (and discoverable per the starter’s sitemap / navigation rules) are what visitors can open. Exact inclusion rules follow `nextjs-notion-starter-kit` / your `lib/get-site-map.ts` and ACL helpers.

## Public vs draft (your process)

Fill in for your workspace:

| Rule | Your choice |
|------|----------------|
| Where do you write drafts? (same page tree vs separate database) | _TBD_ |
| How do you mark “ready to publish”? (move page, toggle property, share to web, etc.) | _TBD_ |
| Who can see the Notion page before go-live? (workspace only vs public link) | _TBD_ |

## Verification: blog index matches intent

Run locally with valid Notion env vars (`pnpm dev`), open `/blogs`, and list what you expect vs what you see:

| Expected title or slug (from Notion) | Visible on `/blogs`? (Y/N) | Notes |
|--------------------------------------|----------------------------|-------|
| | | |
| | | |

When this table is complete and every expected row is **Y**, check off **Confirm blog index lists expected posts only** in [tracking.md](./tracking.md).

## Follow-up in code (portfolio repo)

The app `components/Footer.tsx` may still contain a temporary `test` button and debug logging. Remove those before launch.

## Cross-references

| Topic | Related notes |
|-------|----------------|
| Progress | [tracking.md](./tracking.md) |
| Navigation choice | [decisions.md](./decisions.md) |
| Stack / routes | [snapshot.md](./snapshot.md) |
