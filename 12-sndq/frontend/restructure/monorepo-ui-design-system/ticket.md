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
| `sndq-ui-v2/src/components/ui-v2/` (inside app) | `packages/ui/` (`@sndq/ui`) |
| Git submodule `sndq-fe/packages/ui/` | Removed — replaced by `workspace:*` |
| Duplicated design tokens in globals.css | `packages/config/` (`@sndq/config`) |
| Duplicated tsconfig.json | `packages/tsconfig/` (`@sndq/tsconfig`) |

## Scope

### New packages

- **`@sndq/ui`** — three-tier component library (primitives + patterns), zero business logic
- **`@sndq/config`** — shared ESLint, Prettier, Tailwind design tokens (Briicks colors, semantic tokens, component CSS)
- **`@sndq/tsconfig`** — shared TypeScript config bases (base, nextjs, library)

### Component classification

| Tier | Location | Rule |
|------|----------|------|
| Primitives | `@sndq/ui/components` | Well-known UI atoms (Button, Dialog, Table, etc.) |
| Patterns | `@sndq/ui/patterns` | Reusable compositions (PageHeader, KpiCard, ConfirmDialog, etc.) |
| Business | `sndq-fe/src/components` | Logic-bound, app-specific (CommonTable, ActionButton, etc.) |

### Tooling

- **Lerna** stays for task orchestration + versioning (no Turborepo — overkill for 3 packages)
- **PNPM workspaces** with `workspace:*` protocol for internal dependencies

## Key changes

- `pnpm-workspace.yaml`: `['sndq-fe', 'apps/*', 'packages/*']`
- `lerna.json` packages: `['sndq-fe', 'apps/*', 'packages/*']`
- Root scripts delegate to `lerna run` (build, dev, lint, type-check, test)
- All apps import `@sndq/config/tailwind/tokens.css` — single source of truth for design tokens
- All apps extend `@sndq/tsconfig/nextjs.json` — single source of truth for TypeScript config

## Migration phases

| # | Phase | Estimate |
|---|-------|----------|
| 1 | Create `apps/` and `packages/` directories, move prototype app | 0.5d |
| 2 | Extract `@sndq/ui` from `sndq-ui-v2/src/components/ui-v2/` | 1d |
| 3 | Extract `@sndq/config` (tokens, ESLint, Prettier) | 0.5d |
| 4 | Extract `@sndq/tsconfig` (base, nextjs, library) | 0.5d |
| 5 | Update imports in both apps, wire `workspace:*` dependencies | 1-2d |
| 6 | Remove git submodule, update CI/CD for new paths | 0.5d |
| 7 | Verify builds, lint, type-check pass in both apps | 0.5d |

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Import path breakage | Build failures | Systematic find-and-replace, verify with `tsc --noEmit` |
| CI/CD path references | Deploy failures | Update GitHub Actions workflows before merge |
| Vercel project config | Wrong build root | Update Vercel project settings for prototype app |
| Git history for moved files | Harder `git blame` | Use `git mv` to preserve history where possible |

## Related documents

- [Full Architecture Document](./README.md) — target structure, config contents, dependency graph, component inventory
- [Component Structure Ticket](./ticket-component-structure.md) — three-tier component model, classification rule, inventory
- [Overview](./overview.md) — folder structure and dependency flow at a glance
