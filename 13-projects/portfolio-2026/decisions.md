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

### 2026-05-03 — Retain default Notion navigation

- **Context:** Phase B asks whether to use `navigationStyle: 'default'` or `custom` with `navigationLinks` in `site.config.ts`.
- **Decision:** Keep **default** navigation until dedicated Notion page IDs are chosen for top-level items (for example About, Contact). No `navigationLinks` block is activated yet.
- **Consequences:** Site navigation follows the starter’s default behavior from the root Notion page. Revisit when IA is finalized; then add `navigationStyle: 'custom'` and real `pageId` values.

### 2026-05-03 — Footer: no extra legal links for MVP

- **Context:** Phase B optional step to add or trim footer/header links for legal or contact.
- **Decision:** No separate legal or contact footer links are required for the current MVP. Social links continue to come from `site.config.ts` / `lib/config` via `Footer`. Before any public launch, remove accidental debug UI in portfolio `components/Footer.tsx` (for example the `test` button and related `useEffect` logging) if still present.
- **Consequences:** If you later need `/privacy` or `/imprint`, add routes or Notion pages and link them explicitly in the footer or header.

### 2026-05-03 — Defer Phase A deploy

- **Context:** Production go-live was planned as Phase A (Vercel). The Vercel account is currently blocked or unavailable.
- **Decision:** Defer Phase A until hosting is sorted (Vercel restored or another host chosen). Continue execution with Phase B (Notion content and information architecture) on local development; do not treat Phase A checkboxes as done.
- **Consequences:** MVP “live URL” criteria remain pending. Production-only checks (OG on live URL, sitemap/robots on prod host) wait for Phase A. If the host changes later, update this entry and the blocker line in [current-focus.md](./current-focus.md).

