# Decision log — Portfolio 2026

Short ADRs for choices that affect scope, hosting, or UX. Add newest entries at the top.

## Template

```markdown
### YYYY-MM-DD — Short title

- **Context:** …
- **Decision:** …
- **Consequences:** …
```

## Decisions

### 2026-05-03 — Defer Phase A deploy

- **Context:** Production go-live was planned as Phase A (Vercel). The Vercel account is currently blocked or unavailable.
- **Decision:** Defer Phase A until hosting is sorted (Vercel restored or another host chosen). Continue execution with Phase B (Notion content and information architecture) on local development; do not treat Phase A checkboxes as done.
- **Consequences:** MVP “live URL” criteria remain pending. Production-only checks (OG on live URL, sitemap/robots on prod host) wait for Phase A. If the host changes later, update this entry and the blocker line in [current-focus.md](./current-focus.md).

