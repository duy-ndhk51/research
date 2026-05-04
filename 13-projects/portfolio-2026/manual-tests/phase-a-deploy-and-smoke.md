# Manual tests — Phase A: deploy and smoke

When Phase A is **deferred** (no production URL yet), skip the prod-oriented sections below until a URL exists; optional local smoke (`pnpm dev`, `pnpm build`) is still useful.

Run against **production** (or staging URL that matches prod config). Record pass/fail and date.

## Environment and URL

- [ ] Production base URL is recorded in [../snapshot.md](../snapshot.md)
- [ ] Required env vars are set on the host (Notion token; Redis only if project enables it)

## Core routes

- [ ] Home (`/`) loads without console errors (check once with devtools)
- [ ] Blog index (`/blogs`) loads and lists expected entries
- [ ] One deep-linked blog post loads (copy URL from index)
- [ ] Hard refresh on post page still succeeds
- [ ] Same checks in a private/incognito window (cache bypass sanity)

## Metadata

- [ ] Browser tab title is sensible on home and on a post
- [ ] Optional: social/OG debugger shows intended title or image for one post

## Notes

_Date run:_ ___  
_Tester:_ ___  
_Failures / follow-ups:_ ___
