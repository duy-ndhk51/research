# HeroUI — Token Analysis

## TL;DR

HeroUI uses a three-tier CSS token architecture: semantic CSS variables define the design language, Tailwind `@theme inline` bridges them into utilities, and component-local CSS vars provide per-component isolation. Variants only swap local var values, making override reasoning trivial. Built on Tailwind CSS v4 with CSS layers for predictable cascade.

## Key Facts

| Aspect | Detail |
|--------|--------|
| Tech Stack | React 19, TypeScript, Tailwind CSS v4, React Aria Components |
| Token Count | ~80 semantic tokens + per-component local vars |
| Format | CSS custom properties + `@theme inline` + BEM component CSS |
| Dark Mode | `.dark` / `[data-theme="dark"]` + system preference fallback |
| Customization API | CSS var override, `@layer` priority, `data-theme` |
| Source of Truth | `packages/styles/themes/default/variables.css` (hand-authored) |

## Architecture

### File Map

```
packages/styles/
  index.css                     # Entry: @layer theme, base, components, utilities
  themes/
    shared/theme.css            # @theme inline (bridges CSS vars to Tailwind)
    default/
      index.css                 # Composes theme + variables + overrides
      variables.css             # Semantic CSS custom properties (light/dark)
      components/index.css      # Theme-specific component overrides
  components/                   # ~60+ BEM component CSS files
    index.css                   # Ordered import barrel
  utilities/index.css           # @utility definitions
  variants/index.css            # @custom-variant dark, motion-reduce
```

### Three-Tier Token Stack

```
Tier 1: Semantic CSS vars (variables.css)
  --accent, --surface, --foreground, --border, etc.
      |
Tier 2: Tailwind @theme bridge (theme.css)
  --color-background: var(--background);
  --color-accent: var(--accent);
  --radius-field: var(--field-radius);
      |
Tier 3: Component-local vars (component CSS)
  --button-bg: var(--accent);
  --button-fg: var(--accent-foreground);
```

## Token Hierarchy

### Primitives
In `variables.css` `:root`:
- `--white`, `--black`, `--eclipse` (oklch raw values)
- Not meant for direct use in components

### Semantic
Role-based tokens scoped to `:root` / `.light` / `.dark`:
- **Surface**: `--background`, `--foreground`, `--surface`, `--surface-hover`
- **Action**: `--accent`, `--accent-hover`, `--accent-foreground`, `--accent-soft`
- **Status**: `--success`, `--warning`, `--danger`, `--info` (+ hover, soft, foreground)
- **Form**: `--field-background`, `--field-border`, `--field-radius`
- **Border/Focus**: `--border`, `--ring`, `--focus`
- **Overlay**: `--overlay-*`

Derived tokens via `color-mix()`:
```css
--accent-hover: color-mix(in oklab, var(--accent) 85%, black);
--accent-soft: color-mix(in oklab, var(--accent) 12%, transparent);
```

### Component-Local
Per-component CSS vars defined on the base class:
```css
.button {
  --button-bg: transparent;
  --button-fg: currentColor;
  --button-border: transparent;
  background: var(--button-bg);
  color: var(--button-fg);
}
```

Variants only swap values:
```css
.button--primary {
  --button-bg: var(--accent);
  --button-fg: var(--accent-foreground);
}
```

## Dark Mode

Cascading selector approach:
```css
:root, .light, .default, [data-theme="light"] {
  --background: oklch(100% 0 0);
  --foreground: oklch(14.9% 0.02 285.88);
}

.dark, [data-theme="dark"] {
  --background: oklch(14.9% 0.02 285.88);
  --foreground: oklch(98.4% 0 0);
}
```

Custom variant for Tailwind: `@custom-variant dark` with override support via `data-theme` + system preference fallback via `prefers-color-scheme`.

## Generation / Authoring

- **No generation pipeline** — all tokens are hand-authored in CSS
- Semantic vars in `variables.css`, theme bridge in `theme.css`
- Component styles in per-component `.css` files
- `tailwind-variants` (`tv()`) maps props to BEM class names in `.styles.ts` files
- No JSON/DTCG export, no Figma sync from tokens

## Component Integration

Split responsibility:
1. **CSS files** (`components/*.css`): Visual rules, BEM classes, local vars
2. **Style files** (`src/components/*/*.styles.ts`): `tv()` maps React props to class names

```typescript
// button.styles.ts
export const buttonVariants = tv({
  base: "button",
  variants: {
    variant: { primary: "button--primary", secondary: "button--secondary" },
    size: { sm: "button--sm", md: "button--md", lg: "button--lg" },
  },
});
```

Components call `buttonVariants({ variant, size })` to get class strings. Actual styling comes from CSS.

## Customization Surface

1. **Override CSS vars** on any wrapper: `style={{ '--accent': '#custom' }}`
2. **Theme file replacement**: Create `themes/{name}/` with different variables
3. **Component override**: Override `--button-bg` etc. directly
4. **`@layer` priority**: Custom CSS in higher layer wins
5. **`data-vibrant-palette`**: Optional attribute for enhanced soft color variants

## Key Patterns

1. **Component-local vars** — variants swap values, not properties; trivial to reason about
2. **`color-mix()` derivation** — hover/soft/active states derived from base, no manual picking
3. **CSS layers** — `@layer theme, base, components, utilities` for predictable cascade
4. **BEM + tv() split** — CSS owns visuals, TS owns prop-to-class mapping
5. **Default size in base** — base `.button` has md dimensions; `--md` modifier is empty
6. **oklch color space** — perceptually uniform, better for derived states
7. **No runtime JS for tokens** — pure CSS, zero bundle cost

## Cross-References

- [Comparison Overview](../token-architecture/comparison-overview.md)
- [Component Tokens](../token-architecture/component-tokens.md) — HeroUI as Pattern A (recommended)
- [Dark Mode Strategies](../token-architecture/dark-mode-strategies.md) — cascading selector approach
- [SNDQ Recommendations](../token-architecture/sndq-recommendations.md) — HeroUI pattern for Phase 3
