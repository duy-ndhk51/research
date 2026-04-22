# Monorepo Restructure & UI Design System — Ticket Summary

Concise ticket-ready summary distilled from the full [Architecture Document](./README.md).

**Created**: 2026-04-17
**Status**: Planning

---

## Why

The `sndq` monorepo has two Next.js apps (`sndq-fe`, `sndq-ui-v2`) with no proper package boundaries:

- **~160 lines of Briicks design tokens duplicated** identically across both apps, prone to drift
- **Shared UI library (`@sndq/ui`) consumed via git submodule + tsconfig path alias** — fragile, no dependency graph awareness
- **`sndq-ui-v2` missing ESLint and Prettier** — no quality tooling enforcement
- **TypeScript configs 95% identical** but maintained separately
- **UI-V2 components trapped inside an app** — cannot be shared without copy-paste

## What

Reorganize into a hybrid `sndq-fe` + `apps/` + `packages/` monorepo structure:

| Before | After |
|--------|-------|
| `sndq-fe/` (top-level) | `sndq-fe/` (stays at root to avoid conflicts) |
| `sndq-ui-v2/` (top-level) | `apps/prototype/` |
| `sndq-ui-v2/src/components/ui-v2/` (inside app) | `packages/ui-v2/` (`@sndq/ui-v2`) — after standardization |
| Git submodule `sndq-fe/packages/ui/` | Stays until full cleanup (Phase 5) — deprecated via ESLint in Phase 2 |
| Duplicated design tokens in globals.css | `packages/config/` (`@sndq/config`) |
| Duplicated tsconfig.json | `packages/tsconfig/` (`@sndq/tsconfig`) |

## Scope

### New packages

- **`@sndq/ui-v2`** — three-tier component library (primitives + blocks), zero business logic
- **`@sndq/ui-v2-docs`** — showcase infrastructure + demo sections (consumed by `apps/docs/` and `apps/prototype/`)
- **`@sndq/config`** — shared ESLint, Prettier, Tailwind design tokens (Briicks colors, semantic tokens, component CSS)
- **`@sndq/tsconfig`** — shared TypeScript config bases (base, nextjs, library)

### New apps

- **`apps/docs/`** — standalone docs site for standardized components
- **`apps/prototype/`** — experimental playground (moved from `sndq-ui-v2/`)

### Component classification

| Tier | Location | Rule |
|------|----------|------|
| Primitives | `@sndq/ui-v2/components` | Well-known UI atoms (Button, Dialog, Table, etc.) |
| Blocks | `@sndq/ui-v2/blocks` | Reusable compositions (PageHeader, KpiCard, ConfirmDialog, etc.) |
| Business | `sndq-fe/src/components` | Logic-bound, app-specific (CommonTable, ActionButton, etc.) |

### Tooling

- **Lerna** stays for task orchestration + versioning (no Turborepo — overkill for current scale)
- **PNPM workspaces** with `workspace:*` protocol for internal dependencies

## Key changes

- `pnpm-workspace.yaml`: `['sndq-fe', 'apps/*', 'packages/*']`
- `lerna.json` packages: `['sndq-fe', 'apps/*', 'packages/*']`
- Root scripts delegate to `lerna run` (build, dev, lint, type-check, test)
- All apps import `@sndq/config/tailwind/tokens.css` — single source of truth for design tokens
- All apps extend `@sndq/tsconfig/nextjs.json` — single source of truth for TypeScript config

## Migration

Five-phase gradual approach — see **[migration-plan.md](./migration-plan.md)** for full details and **[ticket-migration.md](./ticket-migration.md)** for the concise ticket.

| Phase | Name | Key scope |
|-------|------|-----------|
| **1a** | Structural Foundation | Create dirs, extract `@sndq/tsconfig` + `@sndq/config` (ESLint, Prettier) |
| **1b** | Tailwind Tokens | Extract Briicks primitives into `@sndq/config/tailwind/` |
| **2** | Prototype Integration | Move `sndq-ui-v2`, add UI-V2 tokens, create `packages/ui-v2/` + `packages/ui-v2-docs/` + `apps/docs/` skeletons, deprecate old submodule |
| **3** | Standardize + Graduate | Batch standardization, graduate to `packages/ui-v2/`, deprecate legacy per-batch |
| **4** | Module Migration | Direct per-module migration of imports |
| **5** | Cleanup | Remove legacy, optional rename `@sndq/ui-v2` → `@sndq/ui` |

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Import path breakage | Build failures | Phase-by-phase approach, verify with `pnpm build && pnpm type-check` |
| CI/CD path references | Deploy failures | Update GitHub Actions workflows before merge |
| Vercel project config | Wrong build root | Update Vercel project settings for prototype app |
| Branch divergence before Phase 2 | Painful merge | Rebase `sndq-ui-v2` branch onto dev after Phase 1 merges |

## Related documents

- [Full Architecture Document](./README.md) — target structure, config contents, dependency graph, component inventory
- [Component Structure Ticket](./ticket-component-structure.md) — three-tier component model, classification rule, inventory
- [Migration Plan](./migration-plan.md) — five-phase gradual migration, deprecation strategy, API compatibility
- [Migration Ticket](./ticket-migration.md) — concise Linear-ready migration summary
- [Overview](./overview.md) — folder structure and dependency flow at a glance
