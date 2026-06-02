# Phase-by-Phase Analysis

DESIGN.md relevance assessed per migration phase.

---

## Phase 1a: Structural Foundation

**DESIGN.md relevance**: None.

Phase 1a creates monorepo infrastructure (tsconfig, ESLint, Prettier packages). No design tokens or visual system changes. DESIGN.md has nothing to contribute here.

## Phase 1b / Phase 2: Token Extraction + Prototype Integration

**DESIGN.md relevance**: Medium-High.

This is when tokens are extracted from `globals.css` into `@sndq/config/tailwind/tokens.css`. DESIGN.md could be introduced here as the specification that documents the token set being extracted.

**What DESIGN.md adds at this point**:
- A human-readable document explaining the Briicks color system, type scale, spacing philosophy
- Machine-validated token references (the `broken-ref` lint rule catches errors)
- A Tailwind export that can be compared against the manually extracted `tokens.css` for accuracy
- WCAG contrast checks on any component tokens defined early

**What it does NOT help with**:
- The actual CSS extraction work — `tokens.css` must still be authored manually (or generated from DESIGN.md export, but the export only covers token values, not CSS custom property syntax with `@theme inline`)
- Dark mode / shadcn theme variables — DESIGN.md cannot express `:root` / `.dark` variants
- Component CSS classes (`.sndq-btn`, `.sndq-control`) — these are beyond DESIGN.md's scope

**Risk at this point**: Writing a DESIGN.md before the token set is stabilized means maintaining an additional artifact during a period of active change. Tokens are being reorganized (Briicks primitives → shared tokens, UI-V2 semantic tokens joining). The DESIGN.md would need frequent updates.

## Phase 3: Standardize + Graduate to Package

**DESIGN.md relevance**: High.

This is where DESIGN.md provides the most value. Each standardization batch defines a component's visual contract — exactly what DESIGN.md component tokens express.

**What DESIGN.md adds at this point**:
- **Component tokens as graduation criteria**: Add "component tokens defined in DESIGN.md" to the [Definition of Standardized](../migration-plan.md#6-phase-3-standardize--graduate-to-package) checklist
- **Machine-verifiable contracts**: When a color token is renamed or removed, `broken-ref` immediately flags which components break
- **Batch-level diffing**: After each batch, run `diff` against the previous version to track how the design system evolves
- **WCAG per component**: Every graduated component's `backgroundColor`/`textColor` pair is checked for contrast compliance
- **Agent-assisted standardization**: Agents can read DESIGN.md when implementing or reviewing component standardization work

**Integration with batch workflow**:

```
Per-batch addition to the standardization checklist:
1. Standardize in apps/ui-v2-dev/  (existing)
2. Graduate to packages/ui-v2/     (existing)
3. Define component tokens in DESIGN.md   ← NEW
4. Run `lint` — 0 errors, 0 contrast warnings
5. Run `diff` against previous version — review changes
6. Deprecate legacy counterparts    (existing)
```

## Phase 4: Module-by-Module Migration

**DESIGN.md relevance**: Low.

Phase 4 is about changing import paths and updating prop usage across `sndq-fe` modules. DESIGN.md doesn't directly help with import migration. However, agents performing the migration can reference DESIGN.md to understand the target component's intended appearance and behavior.

## Phase 5: Cleanup

**DESIGN.md relevance**: Low.

Phase 5 removes legacy directories and the old submodule. DESIGN.md is not involved. Post-cleanup, DESIGN.md becomes the ongoing living document for the finalized design system.
