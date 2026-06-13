# Dark Mode Strategies

## TL;DR

There are 4 strategies for dark mode in token systems. The modern best practice is **attribute-driven with CSS `light-dark()`** (Kumo, Spectrum S2). SNDQ currently lacks dark mode in its shared token layer — adding it requires choosing between selector-scoped overrides vs the `light-dark()` function.

## Key Concepts

### The Four Strategies

| Strategy | How | Used By | Tailwind v4 Compat |
|----------|-----|---------|-------------------|
| **Class swap** | `.dark` class toggles token values | HeroUI, shadcn | Yes (`darkMode: 'class'`) |
| **Attribute swap** | `data-mode="dark"` / `data-theme` | Kumo | Yes (`darkMode: ['selector', '...']`) |
| **Algorithm swap** | Different derivation function | Ant Design | N/A (CSS-in-JS) |
| **CSS `light-dark()`** | Native function in token values | Kumo, Spectrum S2 | Yes (Tailwind respects it) |

### Detailed Comparison

| | Class Swap | Attribute Swap | Algorithm | `light-dark()` |
|---|---|---|---|---|
| **Runtime cost** | CSS class toggle | Attribute set | Re-compute all tokens | Zero (CSS-native) |
| **SSR flash** | Needs inline script | Needs inline script | Server decides | `color-scheme` meta handles |
| **Nesting** | Tricky (`.dark .dark`) | Clean (scoped attribute) | Prop on provider | Automatic |
| **Browser support** | All | All | N/A | Chrome 123+, Safari 17.5+, FF 120+ |
| **Intermediate states** | Hard | Hard | Easy (custom algorithm) | Hard |
| **CSS bundle** | 2x token declarations | 2x token declarations | Single (JS handles) | 1x with `light-dark()` |

## Deep Dive

### Pattern 1: Kumo Dual Delivery (Recommended for New Systems)

Kumo uses both `light-dark()` and explicit attribute selectors:

```css
/* In @theme — single declaration */
@theme {
  --color-kumo-base: light-dark(#fff, oklch(17% 0 0));
}

/* Fallback layer — explicit selectors */
@layer base {
  :root, [data-theme="kumo"] {
    --color-kumo-base: #fff;
  }
  [data-mode="dark"] {
    --color-kumo-base: oklch(17% 0 0);
  }
}
```

Why dual: `light-dark()` depends on `color-scheme` being set; the explicit layer handles cases where DOM mutations happen before `color-scheme` updates.

### Pattern 2: Mantine Resolver Split

```css
/* Scheme-independent */
:root { --mantine-color-blue-5: #339af0; }

/* Scheme-specific */
:root[data-mantine-color-scheme="light"] {
  --mantine-color-body: #fff;
  --mantine-color-text: #000;
}
:root[data-mantine-color-scheme="dark"] {
  --mantine-color-body: #1a1b1e;
  --mantine-color-text: #c1c2c5;
}
```

Clean separation: palette values are universal, semantic roles switch.

### Pattern 3: HeroUI Cascading Selectors

```css
:root, .light, [data-theme="light"] {
  --background: oklch(100% 0 0);
  --foreground: oklch(14.9% 0.02 285.88);
  --accent: oklch(48.4% 0.2 264.05);
}

.dark, [data-theme="dark"] {
  --background: oklch(14.9% 0.02 285.88);
  --foreground: oklch(98.4% 0 0);
  --accent: oklch(62.3% 0.18 264.05);
}
```

Light is default; dark overrides only changed values.

### Pattern 4: Ant Design Algorithmic

```typescript
// Same seed, different algorithm = different output
<ConfigProvider theme={{ algorithm: theme.darkAlgorithm }}>
// Internally: darkAlgorithm inverts color derivation math
// colorBgContainer: light = white, dark = #141414
```

Most flexible for intermediate states (compact+dark, high-contrast+dark).

### SNDQ Current State

- `tokens.css` defines light mode only values
- `semantic-tokens.css` has no `.dark` block
- Dark mode lives in app-level `globals.css` (shadcn pattern: `:root` + `.dark`)
- The two dark mode sources are disconnected

### Recommended Path for SNDQ

**Option A — Attribute + explicit overrides** (simpler, broadest support):

```css
/* In semantic-tokens.css */
:root {
  --color-sndq-surface: var(--color-neutral-50);
  --color-sndq-text: var(--color-neutral-900);
}
[data-mode="dark"], .dark {
  --color-sndq-surface: var(--color-neutral-900);
  --color-sndq-text: var(--color-neutral-100);
}
```

**Option B — `light-dark()` in @theme** (modern, less CSS):

```css
@theme inline {
  --color-sndq-surface: light-dark(var(--color-neutral-50), var(--color-neutral-900));
}
```

Requires `color-scheme: light dark` on `:root` and toggling via `color-scheme: dark`.

**Recommendation:** Option A for now (matches existing shadcn pattern, easier migration). Adopt `light-dark()` when the DESIGN.md export script can generate it.

## Cross-References

- [Multi-Theme Patterns](./multi-theme-patterns.md) — dark mode is one axis of multi-theme
- [Generation Pipelines](./generation-pipelines.md) — how to generate dark values
- [SNDQ Recommendations](./sndq-recommendations.md) — dark mode is Phase 1
- [Kumo Token Analysis](../kumo/token-analysis.md) — dual delivery reference

## References

- MDN light-dark(): https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark
- Tailwind v4 dark mode: https://tailwindcss.com/docs/dark-mode
