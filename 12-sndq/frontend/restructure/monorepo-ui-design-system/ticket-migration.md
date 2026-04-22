# UI Design System Migration — Ticket Summary

Gradual migration from legacy UI libraries to `@sndq/ui-v2`, in 5 phases.

**Full plan**: [migration-plan.md](./migration-plan.md)
**Architecture**: [README.md](./README.md)

---

## Approach

No big bang. Each phase is independently mergeable. Old and new imports coexist during transition.

## Phases

### Phase 1a — Structural Foundation

- Create `apps/`, `packages/` directories
- Extract `@sndq/tsconfig` + `@sndq/config` (ESLint, Prettier)
- Wire `sndq-fe` to shared configs
- No visual changes

### Phase 1b — Tailwind Tokens

- Extract Briicks primitive tokens (~140 lines) into `@sndq/config/tailwind/tokens.css`
- Update `sndq-fe/globals.css` to import
- Zero style changes

### Phase 2 — Prototype Integration

- Move `sndq-ui-v2` to `apps/prototype/`
- Add UI-V2 semantic tokens + component CSS + animations to `@sndq/config/tailwind/`
- Add ESLint/Prettier to prototype
- Create empty skeletons: `packages/ui-v2/`, `packages/ui-v2-docs/`, `apps/docs/`
- Deprecate old `@sndq/ui` submodule via ESLint `no-restricted-imports`

### Phase 3 — Standardize + Graduate

- **Setup**: extract showcase infrastructure from prototype into `packages/ui-v2-docs/`, wire `apps/docs/`
- **Per-batch**: standardize components → graduate to `packages/ui-v2/` → graduate docs sections to `packages/ui-v2-docs/` → deprecate legacy counterparts

### Phase 4 — Module Migration

- Direct migration per module: change imports + update props
- First on financial module, then rest by complexity

### Phase 5 — Cleanup

- Remove `briicks/`, `ui/`, old submodule
- Optional rename `@sndq/ui-v2` to `@sndq/ui`
- Bundle audit

## Deprecation

Two-tier, timed to avoid noise:

| Source | When | Method |
|--------|------|--------|
| `@sndq/ui` (old submodule) | Phase 2 | ESLint `no-restricted-imports` — "do not add new imports" |
| `briicks/{component}` | Phase 3, per-batch | JSDoc `@deprecated` — only after replacement graduates |
| `ui/{component}` | Phase 3, per-batch | JSDoc `@deprecated` — only after replacement graduates |

## Standardization Batches

| Batch | Components |
|-------|-----------|
| 1 | Button, Input, Badge, Select, Dialog, Sheet |
| 2 | Card, Tabs, Tooltip, EmptyState, Skeleton |
| 3 | Remaining |

Per-batch flow:

```
1. Standardize in apps/prototype/
2. Graduate to packages/ui-v2/
3. Graduate docs section to packages/ui-v2-docs/
4. Deprecate legacy counterparts
```

## Migration Order (Phase 4)

1. **Financial**: most complex module (validates at scale)
2. **Remaining**: in waves by complexity

## Key Constraints

- Old `@sndq/ui` submodule (`sndq-fe/packages/ui/`) stays until Phase 5
- New package is `@sndq/ui-v2` (avoids naming conflict with submodule)
- No re-export bridge — APIs are incompatible (different variants, different prop shapes)
- Components stay in `apps/prototype/` until standardized — package only holds production-ready code
- Separate docs package (`@sndq/ui-v2-docs`) keeps component library clean — `sndq-fe` never installs docs infrastructure
- `apps/docs/` shows only standardized components; `apps/prototype/` extends it with experimental content

## Risks

| Risk | Mitigation |
|------|------------|
| Branch divergence before Phase 2 | Rebase `sndq-ui-v2` branch onto dev after Phase 1 merges |
| Standardization blocks migration | Batch approach — Phase 4 starts after Batch 1, doesn't wait for all |
| Visual regression from token swap | Extract identical values, visual diff each phase |
| Developers ignore deprecation | Start with `warn`, escalate to `error` after grace period |
