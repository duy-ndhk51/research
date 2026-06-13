# React Spectrum (Adobe) — Token Analysis

## TL;DR

React Spectrum has two distinct token architectures in one repo: Spectrum 1 (S1) uses vendored CSS files with class-based theme switching, while Spectrum 2 (S2) uses a JSON token package consumed at compile time via style macros with CSS `light-dark()`. S2 represents the modern direction with zero-runtime token resolution.

## Key Facts

| Aspect | S1 (@adobe/react-spectrum) | S2 (@react-spectrum/s2) |
|--------|---------------------------|-------------------------|
| Token Count | ~1000+ CSS vars | ~500 JSON tokens |
| Format | CSS custom properties | JSON, compiled to CSS |
| Dark Mode | Class swap (`.spectrum--dark`) | `color-scheme` + `light-dark()` |
| Customization | Theme object + CSS var override | Style macro theme |
| Source | Vendored `spectrum-css-temp/` | `@adobe/spectrum-tokens` (npm) |

## Architecture

### S1 File Map

```
packages/@adobe/spectrum-css-temp/
  vars/
    spectrum-global.css        # Global tokens (.spectrum class)
    spectrum-light.css         # Light color scheme
    spectrum-dark.css          # Dark color scheme
    spectrum-medium.css        # Medium scale
    spectrum-large.css         # Large scale (touch)
    express.css                # Express theme overrides
  components/{name}/
    index.css                  # Structure/layout
    skin.css                   # Colors/states
```

### S2 File Map

```
packages/@react-spectrum/s2/
  style/
    tokens.ts                  # JSON accessors (colorToken, colorScale)
    spectrum-theme.ts          # createTheme for style() macro
  src/
    page.macro.ts              # Generates :root CSS from tokens
```

### Theme Interface (S1)

```typescript
interface Theme {
  global?: CSSModule;
  light?: CSSModule;
  dark?: CSSModule;
  medium?: CSSModule;
  large?: CSSModule;
}
```

Provider applies the active scheme + scale CSS modules as classes.

## Token Hierarchy

### S1 Layers

1. **Raw scales**: `--spectrum-{hue}-{100-1400}` (theme-dependent values)
2. **Global aliases**: `--spectrum-accent-color-*` (maps to a specific hue)
3. **Semantic**: `--spectrum-negative-*`, `--spectrum-positive-*`, `--spectrum-informative-*`
4. **Component**: `--spectrum-button-*`, `--spectrum-alert-*`

### S2 Layers

1. **Raw scales**: Full hue arrays in JSON (gray, blue, red, etc.)
2. **Role scales**: `accent-color`, `informative-color`, `negative-color`
3. **Semantic content/background**: `accent-content-color-default`, `neutral-background-color-default`
4. **Derived states**: `nextColorStop()` for hover/pressed automatically

## Dark Mode

### S1: Class-Based Switching

```typescript
// Provider applies CSS module classes
className = clsx(
  theme[colorScheme],  // light or dark CSS module
  theme[scale],        // medium or large
  theme.global,
);
```

Different theme objects can map different CSS files:
- default theme: `light` = spectrum-light, `dark` = spectrum-darkest
- dark theme: `light` = spectrum-dark, `dark` = spectrum-darkest

### S2: Native `light-dark()`

```typescript
function colorTokenToString(token: ColorToken) {
  return token.light === token.dark
    ? token.light
    : `light-dark(${token.light}, ${token.dark})`;
}
```

Provider sets `--s2-color-scheme` and `color-scheme` property. No class toggling needed.

## Generation / Authoring

### S1
- CSS files are vendored from Adobe's internal Spectrum CSS system
- No generation within this repo — consumed as-is from `spectrum-css-temp/`
- Component skins reference tokens directly

### S2
- `@adobe/spectrum-tokens` published as npm package (external JSON)
- `tokens.ts` reads JSON, resolves ref chains, returns `{ light, dark }` pairs
- `spectrum-theme.ts` builds a compile-time theme consumed by `style()` macro
- `page.macro.ts` generates root CSS with all resolved values
- Build step (Parcel macro) resolves everything at compile time — zero runtime

## Component Integration

### S1
Components use Spectrum CSS classes + token vars:
```css
.spectrum-Alert {
  background-color: var(--spectrum-alert-background-color);
  color: var(--spectrum-alert-text-color);
}
```

### S2
Components use `style()` macro with semantic names:
```typescript
style({ backgroundColor: 'accent-subtle', color: 'neutral' })
```

The macro resolves names through `spectrum-theme.ts` to final CSS values at build time.

## Customization Surface

### S1
- Swap `Theme` object (different CSS modules)
- Override CSS vars on a wrapper element
- `colorScheme` and `scale` props on Provider
- Express theme remaps accent to indigo, overrides radii

### S2
- `colorScheme` prop (light/dark/inherit)
- `background` layer context (adapts child colors)
- Style macro theme can be extended with custom properties
- Container context via `--s2-container-bg`

## Key Patterns

1. **Scale dimension** — `medium` vs `large` is a first-class axis (touch target sizes), not just density
2. **S2 compile-time resolution** — zero `var()` lookups in final CSS for most values
3. **Color ref chains** — JSON tokens reference other tokens; resolver follows chains to raw values
4. **`nextColorStop()`** — hover/pressed states automatically use next shade, no manual picking
5. **Two architectures coexist** — gradual migration, `style-macro-s1` bridges old tokens into new macro system
6. **Overlay color generation** — `lch(from ...)` for adaptive transparent overlays

## Cross-References

- [Comparison Overview](../token-architecture/comparison-overview.md)
- [Dark Mode Strategies](../token-architecture/dark-mode-strategies.md) — class swap (S1) vs light-dark (S2)
- [Generation Pipelines](../token-architecture/generation-pipelines.md) — compile-time macro approach
