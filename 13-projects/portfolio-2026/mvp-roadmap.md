# MVP roadmap — Portfolio 2026

## MVP definition

**MVP is done when:** a public production URL serves the home page, blog index, and individual posts from Notion, with correct site metadata (title, description, OG where applicable), no broken primary navigation, and acceptable layout on mobile and desktop.

Rauno-style motion and bespoke typography refinements are **out of MVP** unless you explicitly shrink MVP to “marketing home only.”

## Priority tiers

### P0 — Ship blockers

- Production deploy and environment variables for Notion (and Redis only if enabled)
- Smoke tests on home, `/blogs`, and at least one deep-linked post
- Replace starter placeholders in public site config (domain, author, social handles) wherever they surface in UI or metadata

### P1 — Discoverability and trust

- `sitemap` and `robots` verified for production host
- RSS/atom feed reachable if you want syndication (`app/feed.xml/route.ts`)
- Basic performance check (LCP, images) on home and one long post

### P2 — Experience and reference parity

- Motion: route or list transitions, scroll-linked effects, hover states
- Typography and spacing pass aligned with your reference site
- `prefers-reduced-motion` respected for any non-essential animation

## Phase mapping

| Roadmap tier | Tracking phase |
|--------------|------------------|
| P0 | Phase A (and start of B if config touches IA) |
| P1 | End of A / B |
| P2 | Phase D (with C as UX prerequisite) |

## Current execution order

MVP still assumes **P0 production deploy** eventually. Until Phase A is complete, **Phases B, C, and D** may proceed on local development (and any preview URL you add later). Items that require a live host—`sitemap` / `robots` on the production domain, OG or social previews against the public URL—stay tied to Phase A completion. See [tracking.md](./tracking.md) and [decisions.md](./decisions.md) for the active deferral.

## Cross-references

| Topic | Related notes |
|-------|----------------|
| Checklists | [tracking.md](./tracking.md) |
| Baseline | [snapshot.md](./snapshot.md) |
