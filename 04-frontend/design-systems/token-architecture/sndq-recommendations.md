# SNDQ Token System — Recommendations

## TL;DR

The SNDQ token system has strong foundations (DESIGN.md source, Tailwind v4 @theme, semantic naming). The main gaps are: no dark mode in the shared layer, no component-local token contracts, no multi-theme support, and disconnected state between generated tokens and hand-maintained semantic tokens. Here is the evolution plan.

## Current Architecture Assessment

### What is Working Well

| Aspect | Status | Notes |
|--------|--------|-------|
| Single source of truth | Strong | DESIGN.md drives generation |
| Semantic naming | Strong | `sndq-action`, `sndq-surface`, `sndq-text` |
| Tailwind v4 integration | Strong | `@theme inline` + utility derivation |
| W3C DTCG export | Strong | Future-proof interop format |
| CSS-first (no runtime) | Strong | Zero JS cost for tokens |
| Layered authoring | Good | Generated + hand-maintained separation |

### What Needs Work

| Gap | Impact | Priority |
|-----|--------|----------|
| No dark mode in shared tokens | Apps implement dark mode independently, inconsistently | High |
| No component-local token contracts | Hard to customize individual components | Medium |
| Manual `semantic-tokens.css` disconnected from pipeline | Drift risk, no validation | Medium |
| No multi-theme/brand support | Cannot serve different brand skins | Low (future) |
| No generated documentation of available tokens | Contributors guess at what exists | Medium |
| Missing validation in pipeline | Can generate broken tokens silently | Medium |

## Recommended Evolution Plan

### Phase 1: Dark Mode (High Priority)

**Goal:** Move dark mode from app-level shadcn into the shared SNDQ token layer.

**Steps:**
1. Add `light`/`dark` structure to DESIGN.md color tokens
2. Update `export-design-tokens.mjs` to emit selector-scoped dark overrides
3. Move `semantic-tokens.css` computed colors into the same dark-aware format
4. Add `@custom-variant dark (&:is([data-mode="dark"] *))` to tokens.css
5. Remove app-level shadcn `:root`/`.dark` variables that duplicate SNDQ tokens

**Output:**
```css
/* tokens.css */
@theme inline {
  --color-sndq-surface: var(--color-neutral-50);
  --color-sndq-text: var(--color-neutral-900);
}

/* tokens-dark.css */
[data-mode="dark"] {
  --color-sndq-surface: var(--color-neutral-900);
  --color-sndq-text: var(--color-neutral-100);
}
```

**Migration:** Apps switch from their own `.dark` block to importing `@sndq/config/tailwind/tokens-dark.css`.

### Phase 2: Validation and Documentation (Medium Priority)

**Goal:** Catch errors early and help contributors discover tokens.

**Steps:**
1. Add a lint step to `design:sync` that validates:
   - All semantic tokens reference valid primitive tokens
   - All tokens have both light and dark values
   - No orphaned tokens (defined but never used in components.css)
2. Generate a `TOKEN_REFERENCE.md` during export (or a JSON manifest)
3. Add a `pnpm design:check` command for CI

### Phase 3: Component Token Contracts (Medium Priority)

**Goal:** Enable per-component customization without global side effects.

**Steps:**
1. Identify top 5 components that receive customization requests (Button, Input, Card, Badge, Table)
2. Add CSS local vars following the HeroUI pattern:
   ```css
   .sndq-btn {
     --sndq-btn-bg: transparent;
     --sndq-btn-fg: currentColor;
     background: var(--sndq-btn-bg);
     color: var(--sndq-btn-fg);
   }
   ```
3. Document the customization surface per component
4. Consider adding component token definitions to DESIGN.md

### Phase 4: Semantic Token Unification (Medium Priority)

**Goal:** Eliminate the split between generated `tokens.css` and hand-maintained `semantic-tokens.css`.

**Steps:**
1. Extend DESIGN.md to support `computed` token type for `color-mix()` values
2. Or migrate to a TypeScript config (like Kumo) that can express computations
3. Generate ALL tokens from one source — manual aliasing in tokens.css goes away
4. `semantic-tokens.css` becomes empty or holds only truly dynamic values

### Phase 5: Multi-Theme (Future)

**Goal:** Support brand variants (e.g., white-label, partner themes).

**Steps:**
1. Add theme dimension to DESIGN.md (or TS config)
2. Generate override-only CSS per theme (Kumo pattern)
3. Add `[data-theme="partner-x"]` switching
4. Document theme creation process for new brands

## Architecture Target State

```
DESIGN.md (or future config.ts)
    | pnpm design:sync
tokens.css            (all tokens, light values, @theme inline)
tokens-dark.css       (dark overrides, selector-scoped)
tokens-{theme}.css    (brand overrides, selector-scoped)
tokens.dtcg.json      (W3C interop)
TOKEN_REFERENCE.md    (generated docs)
    |
Components consume via Tailwind utilities
Component CSS uses local vars for customization
Apps @import the layers they need
```

## Decision Log

| Decision | Rationale | Alternative Considered |
|----------|-----------|----------------------|
| Keep DESIGN.md as source (for now) | Working well, designer-readable | TS config (deferred to Phase 4) |
| Attribute-based dark mode | Matches existing patterns, no runtime JS | `light-dark()` (adopt when browser share allows) |
| Component vars on-demand | Avoid over-engineering | Typed component token registry (Ant Design-style, too heavy) |
| Override-only theme files | Minimal surface, clear diffs | Full theme replacement (wasteful) |
| CSS-first, no runtime | Zero cost at runtime, cacheable | JS resolver (Mantine-style, unnecessary for current use case) |

## Cross-References

- [Dark Mode Strategies](./dark-mode-strategies.md) — Phase 1 details
- [Component Tokens](./component-tokens.md) — Phase 3 patterns
- [Multi-Theme Patterns](./multi-theme-patterns.md) — Phase 5 approaches
- [Generation Pipelines](./generation-pipelines.md) — pipeline evolution
- [DESIGN.md Evaluation](../design-md-evaluation/README.md) — source format analysis
- [Kumo AI-Friendly Pattern](../kumo/ai-friendly-pattern.md) — enforcement model
- [SNDQ Table Architecture](../../12-sndq/frontend/features/design-system/table/architecture.md)

## References

- SNDQ config/tailwind source: `sndq-clone/packages/config/tailwind/`
- Kumo theme generator: `kumo/packages/kumo/scripts/theme-generator/`
- Mantine CSS variables: `mantine/packages/@mantine/core/src/core/MantineProvider/MantineCssVariables/`
