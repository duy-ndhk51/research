# Multi-Theme Patterns

## TL;DR

Supporting multiple themes/brands requires: isolated token namespaces per theme, a mechanism to switch them (attribute, class, or provider), and a strategy for what gets overridden (all tokens vs subset). The cleanest pattern is "override-only theme files" (Kumo's approach).

## Key Concepts

### Theme Switching Mechanisms

| Mechanism | System | How |
|-----------|--------|-----|
| CSS class cascade | Spectrum S1 | `.spectrum--light` vs `.spectrum--express` |
| Data attribute | Kumo, HeroUI | `data-theme="fedramp"` |
| JS provider | Ant Design, Mantine | `<ConfigProvider theme={...}>` |
| CSS file swap | Spectrum S1 | Import different `vars/*.css` |
| `@layer` override | HeroUI | `themes/{name}/components/` |

### Override Strategies

| Strategy | Description | Used By |
|----------|-------------|---------|
| **Full replacement** | Each theme defines ALL tokens | Spectrum S1, Mantine (full theme object) |
| **Override-only** | Base theme + diff file | Kumo (`theme-fedramp.css` has only 3 overrides) |
| **Algorithm swap** | Same seeds, different derivation | Ant Design (dark, compact) |
| **Nested providers** | Component subtree gets different theme | Ant Design, Mantine |
| **Virtual colors** | One name maps to different palette per scheme | Mantine `virtualColor()` |

## Deep Dive

### Kumo: Override-Only (Best for Brand Variants)

Base theme (`theme-kumo.css`) defines all ~55 tokens. FedRAMP override (`theme-fedramp.css`) overrides only 3:

```css
/* theme-fedramp.css — generated from config.ts where theme.fedramp exists */
[data-theme="fedramp"] {
  --color-kumo-canvas: light-dark(#f8f9fa, #0d1117);
  --color-kumo-base: light-dark(#ffffff, #161b22);
  --color-kumo-hairline: light-dark(#d1d5db, #30363d);
}
```

Advantages:
- Tiny override file
- Clear diff of what changes between brands
- Base theme always complete (no missing tokens)
- Easy to add new themes (just add entries to config)

### Mantine: Full Theme Object (Best for Deep Customization)

```typescript
const brandTheme = createTheme({
  primaryColor: 'brand',
  colors: { brand: generateColors('#e63946') },
  radius: { md: '12px' },
  components: {
    Button: { defaultProps: { radius: 'xl' } },
  },
});
```

Theme is deep-merged with defaults at runtime.

### Ant Design: Composable Algorithms (Best for Mode Variants)

```typescript
// Stack multiple concerns
<ConfigProvider theme={{
  algorithm: [theme.darkAlgorithm, theme.compactAlgorithm],
  token: { colorPrimary: '#00b96b' },
  components: { Button: { algorithm: true } },
}}>
```

Each algorithm transforms the previous output. New themes are new functions.

### SNDQ Multi-Theme Options

**Current state:** Single light theme. Dark mode is app-level shadcn, not in shared tokens.

**Path 1 — Kumo-style override files:**
```
packages/config/tailwind/
  tokens.css              # Base (all tokens, light values)
  tokens-dark.css         # Dark overrides only
  tokens-brand-x.css     # Brand X overrides only
```

Apply via `[data-theme="brand-x"]` selector in override files.

**Path 2 — Extend DESIGN.md with theme variants:**
```yaml
colors:
  sndq-action:
    default:
      light: "#0A42C6"
      dark: "#4D8BFF"
    brand-x:
      light: "#E63946"
      dark: "#FF6B7A"
```

Export script generates per-theme CSS files.

**Path 3 — Component-level theme props (future):**
```tsx
<SndqProvider theme="brand-x" mode="dark">
  {/* Tokens switch based on provider */}
</SndqProvider>
```

**Recommendation:** Start with Path 1 (override-only CSS files). It is the simplest to implement, requires no runtime JS, and matches the existing `@import` consumption pattern. Migrate to Path 2 when DESIGN.md supports multi-value tokens.

## Cross-References

- [Dark Mode Strategies](./dark-mode-strategies.md) — dark mode as one axis of multi-theme
- [Generation Pipelines](./generation-pipelines.md) — how to generate per-theme outputs
- [Kumo Token Analysis](../kumo/token-analysis.md) — override-only reference implementation
- [SNDQ Recommendations](./sndq-recommendations.md) — multi-theme is Phase 5

## References

- Cristiano Rastelli, "Multi-Brand Design Systems": https://didoo.medium.com/
