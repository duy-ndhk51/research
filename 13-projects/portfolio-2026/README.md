# Portfolio 2026

Personal site and blog: Notion as CMS, Next.js App Router, with a minimal home shell and a Rauno-inspired polish track for motion and typography.

## Motivation

Ship a production URL quickly, then iterate on content, UX, and motion without blocking the MVP.

## Goals

1. Live deployment with correct metadata and smoke-tested routes
2. Notion-backed blog listing and post pages
3. Accurate public-facing site config (domain, author, socials)
4. Optional later: motion and layout parity with a reference portfolio aesthetic

## Design reference

External inspiration (URL only): `https://2023.rauno.me/`

## Build strategy

| Phase | Focus |
|-------|--------|
| **A** | Deploy, env, smoke tests, site config cleanup |
| **B** | Notion publishing workflow and navigation / IA |
| **C** | UX baseline: readability, accessibility, theme |
| **D** | Motion and interaction polish |

See [mvp-roadmap.md](./mvp-roadmap.md) for P0/P1/P2 ordering. Execute steps in [tracking.md](./tracking.md). For each phase completion, run the matching checklist under [manual-tests/](./manual-tests/).

## Tech stack (summary)

| Layer | Technology |
|-------|------------|
| Framework | Next.js 16, React 19, App Router |
| CMS | Notion (`notion-client`, `react-notion-x`) |
| Styling | Tailwind CSS 4 |
| Motion | `motion` (Framer Motion successor) |
| Package manager | pnpm |

Full pinned baseline: [snapshot.md](./snapshot.md).

## Links

| Resource | Path |
|----------|------|
| Code repository | `/Users/admin/projects/private/portfolio-2026/` |
| Baseline snapshot | [snapshot.md](./snapshot.md) |
| MVP roadmap | [mvp-roadmap.md](./mvp-roadmap.md) |
| Progress tracker | [tracking.md](./tracking.md) |
| Current focus (read first each session) | [current-focus.md](./current-focus.md) |
| Decision log | [decisions.md](./decisions.md) |
| Manual tests — Phase A | [manual-tests/phase-a-deploy-and-smoke.md](./manual-tests/phase-a-deploy-and-smoke.md) |
| Manual tests — Phase B | [manual-tests/phase-b-notion-content.md](./manual-tests/phase-b-notion-content.md) |
| Manual tests — Phase C | [manual-tests/phase-c-ux-a11y-theme.md](./manual-tests/phase-c-ux-a11y-theme.md) |
| Manual tests — Phase D | [manual-tests/phase-d-motion.md](./manual-tests/phase-d-motion.md) |

## Quick start (local)

```bash
cd /Users/admin/projects/private/portfolio-2026
pnpm install
pnpm dev
```

Notion integration requires environment variables as documented in the app repository README.
