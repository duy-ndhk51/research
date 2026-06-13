# Mantine — Token Analysis

## TL;DR

Mantine uses a JS-theme-first, CSS-variable-second architecture. A `MantineTheme` object is the single source of truth; a resolver maps it to `--mantine-*` CSS custom properties. Defaults are pre-generated as static CSS; runtime only injects diffs from the default theme.

## Key Facts

| Aspect | Detail |
|--------|--------|
| Tech Stack | React, TypeScript, CSS Modules |
| Token Count | ~200 base tokens (expanded to ~400+ with per-color semantics) |
| Format | JS object resolved to `--mantine-*` CSS vars |
| Dark Mode | `data-mantine-color-scheme` attribute (light/dark buckets) |
| Customization API | `MantineProvider` theme prop + `createTheme()` deep merge |
| Source of Truth | `DEFAULT_THEME` object in `default-theme.ts` |

## Architecture

### File Map

```
packages/@mantine/core/src/core/MantineProvider/
  theme.types.ts                    # Full MantineTheme interface
  default-theme.ts                  # DEFAULT_THEME values
  default-colors.ts                 # 13 palettes x 10 shades
  create-theme/                     # Identity helper for typed overrides
  merge-mantine-theme/              # Deep merge + validation
  MantineCssVariables/
    default-css-variables-resolver.ts   # Theme to CSS vars mapper
    get-css-color-variables.ts          # Per-color semantic vars
    get-merged-variables.ts             # Merge default + custom resolver
    MantineCssVariables.tsx             # Runtime <style> injection
    remove-default-variables.ts         # Deduplication
  default-css-variables.css         # Pre-generated static CSS
```

### Runtime Flow

1. `MantineProvider` receives theme override
2. `mergeMantineTheme` deep-merges with `DEFAULT_THEME`
3. `defaultCssVariablesResolver` maps to `{ variables, light, dark }` buckets
4. `MantineCssVariables` injects `<style>` with only the diffs from static defaults
5. Components consume via `var(--mantine-*)` in CSS modules or `useMantineTheme()` in JS

## Token Hierarchy

### Layer 1: Raw Palette

13 color palettes (10 shades each, index 0 = lightest, 9 = darkest):
`dark, gray, red, pink, grape, violet, indigo, blue, cyan, teal, green, lime, yellow, orange`

### Layer 2: Global Tokens

Scheme-independent: spacing, font sizes, radius, breakpoints, line heights, shadows, z-index — all exposed as `--mantine-{category}-{key}`.

### Layer 3: Semantic Tokens

Scheme-specific (split into light/dark buckets):
- `--mantine-color-body`, `--mantine-color-text`, `--mantine-color-dimmed`
- Per-color semantics: `--mantine-color-{name}-filled`, `-light`, `-outline`, `-text`
- `--mantine-primary-color-*` aliases to current `primaryColor` palette

### Layer 4: Component Tokens

Via `vars` callback or `theme.components`:
- `--button-height`, `--button-fz` (component-scoped)
- Resolved per-instance based on props

## Dark Mode

Resolver returns three buckets:
- **variables** — scheme-independent (palette hex, spacing, fonts)
- **light** — under `:root[data-mantine-color-scheme='light']`
- **dark** — under `:root[data-mantine-color-scheme='dark']`

`primaryShade: { light: 6, dark: 8 }` picks which palette index drives filled variants per scheme.

## Generation / Authoring

- **Static pre-generation:** `scripts/codegen/generate-default-css-variables.ts` writes `default-css-variables.css` from `DEFAULT_THEME`
- **Runtime diffs:** `MantineCssVariables` compares resolved vars to defaults, injects only changes
- **`rem()` utility:** All size tokens auto-scale via `calc(... * var(--mantine-scale))`
- **No external build tool** — codegen is a Node script run during development

## Component Integration

Components use CSS modules with `var(--mantine-*)` references. Style props (`fz`, `p`, `radius`) resolve theme keys to CSS variables:

```typescript
if (typeof value === 'string' && value in theme.fontSizes) {
  return `var(--mantine-font-size-${value})`;
}
```

## Customization Surface

```typescript
// Provider-level
<MantineProvider theme={{
  primaryColor: 'brand',
  colors: { brand: generateColors('#228be6') },
  spacing: { xs: '8px', sm: '12px' },
  components: { Button: { defaultProps: { radius: 'xl' } } },
}}>

// Custom CSS vars resolver
cssVariablesResolver={(theme) => ({
  variables: { '--custom-token': theme.other.myValue },
  light: {}, dark: {},
})}

// Module augmentation for type safety
declare module '@mantine/core' {
  export interface MantineThemeColorsOverride {
    colors: 'brand' | 'secondary';
  }
}
```

## Key Patterns

1. **Static + runtime hybrid** — pre-generated defaults, runtime diffs only
2. **`--mantine-scale` density control** — single var scales all rem-based tokens
3. **10-shade palettes** — consistent color generation from one hex (`@mantine/colors-generator`)
4. **Virtual colors** — `virtualColor({ name, light, dark })` maps one name to different palettes per scheme
5. **Deep merge simplicity** — `createTheme()` is an identity function; merge happens in provider
6. **Module augmentation** — type-safe custom token keys without modifying library code

## Cross-References

- [Comparison Overview](../token-architecture/comparison-overview.md)
- [Dark Mode Strategies](../token-architecture/dark-mode-strategies.md) — Mantine resolver split pattern
- [Generation Pipelines](../token-architecture/generation-pipelines.md) — hybrid static/runtime model
- [Component Tokens](../token-architecture/component-tokens.md) — Mantine as Pattern C
