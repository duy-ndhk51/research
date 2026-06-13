# Ant Design — Token Analysis

## TL;DR

Ant Design v5+ uses the most sophisticated token derivation system studied. A minimal set of ~12 seed values are algorithmically expanded into 500+ tokens across 4 layers (Seed, Map, Alias, Component). Dark mode is not different values but a different math function applied to the same seeds.

## Key Facts

| Aspect | Detail |
|--------|--------|
| Tech Stack | React, TypeScript, CSS-in-JS (`@ant-design/cssinjs`) |
| Token Count | ~500+ (most derived algorithmically) |
| Format | JS objects at runtime, CSS vars optional (v6+) |
| Dark Mode | Algorithm swap (`darkAlgorithm`) |
| Customization API | `ConfigProvider theme` prop (seed, algorithm, components) |
| Source of Truth | `components/theme/themes/seed.ts` + algorithms |

## Architecture

### File Map

```
components/theme/
  interface/
    seeds.ts            # SeedToken type (designer layer)
    maps/               # MapToken sub-interfaces (color, size, font, style)
    alias.ts            # AliasToken (developer semantic layer)
    components.ts       # ComponentTokenMap (80+ components)
  themes/
    seed.ts             # Default seed values
    default/            # defaultAlgorithm
    dark/               # darkAlgorithm
    compact/            # compactAlgorithm
    shared/             # genColorMapToken, genSizeMapToken, etc.
  util/
    alias.ts            # formatToken: Map to Alias derivation
    genStyleUtils.ts    # genStyleHooks wiring
  useToken.ts           # Token computation hook
  getDesignToken.ts     # Static token resolver (no React)
```

### Runtime Flow

1. `ConfigProvider` builds `DesignTokenContext` (seed + overrides + algorithm)
2. `useToken()` calls `useCacheToken` with `getComputedToken`
3. `getComputedToken`: algorithm(seed) produces MapToken, then `formatToken` derives AliasToken
4. Per-component `genStyleHooks` receives `FullToken<'ComponentName'>` and returns CSS

## Token Hierarchy

### Layer 1: Seed (Designer)

Minimal knobs (12-15 values): `colorPrimary`, `fontSize`, `borderRadius`, `sizeUnit`, `controlHeight`, 12 preset palette keys. These are what designers tune.

### Layer 2: Map (Algorithmic)

Produced by `DerivativeFunc<SeedToken, MapToken>`. The default algorithm generates:
- 10-step color palettes via `@ant-design/colors`
- Font size/line-height scales
- Size scales from `sizeUnit` + `sizeStep`
- Control heights (SM, default, LG)
- Motion durations
- Border radius variants

### Layer 3: Alias (Developer Semantic)

`formatToken()` maps Map to Alias:
- `colorTextPlaceholder` from `colorTextQuaternary`
- `paddingSM` from `sizeSM`
- `boxShadow` computed from `colorShadow` alpha
- Breakpoints as fixed values

### Layer 4: Component

Per-component tokens extend `FullToken<'ComponentName'>` = AliasToken + component-specific:
- `ButtonToken.primaryShadow`
- `InputToken.activeBorderColor`
- Each has `prepareComponentToken` deriving defaults from alias

## Dark Mode

Dark mode is an algorithm, not a set of values:

```typescript
const derivative: DerivativeFunc<SeedToken, MapToken> = (token, mapToken) => {
  const mergedMapToken = mapToken ?? defaultAlgorithm(token);
  // Re-generates color maps with { theme: 'dark' }
  // Inverts neutral scale, adjusts primary backgrounds
  return { ...mergedMapToken, ...darkColorMaps };
};
```

Algorithms are composable: `[darkAlgorithm, compactAlgorithm]` — each receives the previous output.

## Generation / Authoring

- **No build-time generation** — all derivation happens at runtime via `@ant-design/cssinjs`
- Seed values are hand-authored in `themes/seed.ts`
- Algorithms are hand-authored functions in `themes/default/`, `themes/dark/`, `themes/compact/`
- CSS vars mode (v6+): `cssVar` config controls which tokens become custom properties
- `zeroRuntime` mode skips runtime injection; consumers import prebuilt CSS

## Component Integration

Components register styles via `genStyleHooks`:

```typescript
export default genStyleHooks(
  'Button',
  (token) => [genButtonStyle(token)],
  prepareComponentToken,
  { unitless: { fontWeight: true } },
);
```

This wires: resolved token, style registration via `useStyleRegister`, common reset styles, and component-level unitless/preserve configs for CSS var serialization.

## Customization Surface

```typescript
// Global seeds
<ConfigProvider theme={{ token: { colorPrimary: '#00b96b' } }}>

// Algorithm
<ConfigProvider theme={{ algorithm: theme.darkAlgorithm }}>

// Per-component
<ConfigProvider theme={{
  components: {
    Button: { controlHeight: 40, primaryShadow: 'none' },
  },
}}>

// Component-local algorithm
components: { Button: { algorithm: darkAlgorithm } }

// Nested themes (inherit or reset)
<ConfigProvider theme={{ inherit: false }}>
```

## Key Patterns

1. **Algorithmic derivation** — 12 seeds produce 500+ tokens; changes cascade automatically
2. **Composable algorithms** — dark + compact stack without duplicating definitions
3. **Hash-scoped isolation** — multiple theme versions can coexist on one page
4. **Per-component typed contracts** — `ComponentTokenMap` gives every component a typed override surface
5. **Static access** — `theme.getDesignToken()` works without React for tooling/tests

## Cross-References

- [Comparison Overview](../token-architecture/comparison-overview.md)
- [Component Tokens](../token-architecture/component-tokens.md) — Ant Design as Pattern B
- [Dark Mode Strategies](../token-architecture/dark-mode-strategies.md) — algorithm swap pattern
