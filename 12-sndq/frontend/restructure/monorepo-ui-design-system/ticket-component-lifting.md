# Component Lifting Process — Ticket Summary

**Created**: 2026-04-17
**Detail**: [Full process guide](./component-lifting-process.md) | [Component structure](./ticket-component-structure.md)

---

## Goal

Establish a repeatable process for gradually promoting components from feature-scoped code into the shared `@sndq/ui` package, without pre-cataloging or big-bang migrations.

## Four-Tier Model

Components promote through 4 tiers when they cross a scope boundary.

```
Local → Shared → Blocks → Primitives
```

| Tier | Location | Rule |
|------|----------|------|
| **Local** | `modules/{mod}/**/components/` | Used within one module |
| **Shared** | `sndq-fe/src/components/` | Used by 2+ modules (business logic allowed) |
| **Blocks** | `@sndq/ui/blocks` | Props-only compositions, zero business logic |
| **Primitives** | `@sndq/ui/components` | Single-element atoms (Button, Dialog, Table, etc.) |

Local to Shared is a file move. Shared to Blocks/Primitives requires stripping all business dependencies (hooks, translations, services) and converting to a props-only API.

## Three Signals to Lift

1. **Cross-boundary import exists** — module A already imports from module B's `components/` folder
2. **Copy-paste detected** — reviewer spots duplicated component logic during PR review
3. **Developer requests it** — "I need this component from another module" during a PR

## Daily Process

- **During PRs**: If a cross-boundary import is added, mark it with a `// TODO(lift)` comment
- **Monthly**: Run the detection script to surface candidates
- **Per sprint**: Pick 2-3 candidates and lift them in focused PRs

```bash
# Run from monorepo root (defaults to sndq-fe/src)
bash detect-cross-imports.sh
```

## Acceptance Criteria

- [ ] Detection script (`detect-cross-imports.sh`) committed to the repo
- [ ] PR review checklist updated with: "No new cross-module component imports without `TODO(lift)` comment"
- [ ] First wave of lifts completed (top 3-5 most-imported shared components moved to `@sndq/ui/blocks`)
- [ ] Process documented and linked from the monorepo README
