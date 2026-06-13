# Radix Primitives — Token Analysis

## TL;DR

Radix Primitives intentionally ships zero design tokens. It is a headless behavior/accessibility library that provides composable, unstyled components. Styling is entirely the consumer's responsibility. The closest thing to tokens is the separate `@radix-ui/colors` product used in Storybook demos.

## Key Facts

| Aspect | Detail |
|--------|--------|
| Tech Stack | React, TypeScript |
| Token Count | 0 (by design) |
| Format | N/A |
| Dark Mode | Consumer responsibility |
| Customization API | `data-*` attributes as styling hooks + `asChild` composition |
| Source of Truth | N/A (no visual opinions) |

## Architecture

### Philosophy

From `philosophy.md`: "Components ship with zero presentational styles applied by default. Components are built to be themed; no need to override opinionated styles."

### What Ships

```
packages/react/{component}/
  src/{component}.tsx     # Behavior + ARIA + data-* state attributes
  # NO CSS, NO tokens, NO theme files
```

Each component is an independently published package (`@radix-ui/react-checkbox`, etc.).

### The One Exception

`VisuallyHidden` has a frozen inline style object — the only styling in the entire library:
```typescript
const VISUALLY_HIDDEN_STYLES = Object.freeze({
  position: 'absolute',
  border: 0,
  width: 1,
  height: 1,
  padding: 0,
  margin: -1,
  overflow: 'hidden',
  clip: 'rect(0, 0, 0, 0)',
  whiteSpace: 'nowrap',
  wordWrap: 'normal',
});
```

## Token Hierarchy

None. This is intentional.

## Dark Mode

Consumer responsibility. Components expose `data-state`, `data-disabled`, etc. as styling hooks. The consuming design system handles mode switching.

## Generation / Authoring

No token generation. No build step for styles.

## Component Integration

### Styling API: Data Attributes

Components communicate state through attributes that consumers target:
- `data-state="open|closed|checked|unchecked|indeterminate"`
- `data-disabled`
- `data-orientation="horizontal|vertical"`
- `data-highlighted` (menu items)
- `data-side`, `data-align` (popover positioning)

### Consumer Patterns

```css
/* Target via CSS */
[data-state="checked"] { background: var(--accent); }
[data-disabled] { opacity: 0.5; }

/* Or via Tailwind */
<Checkbox className="data-[state=checked]:bg-blue-500" />
```

### Composition via `asChild`

```tsx
<Dialog.Trigger asChild>
  <MyStyledButton>Open</MyStyledButton>
</Dialog.Trigger>
```

`Slot` merges props/refs into the child element — no wrapper DOM needed.

## Customization Surface

- **Target `data-*` attributes** in your CSS
- **Use `asChild`** to pass in your own styled elements
- **Wrap primitives** in your design system's component layer
- **No token API** — you bring your entire visual language

## Key Patterns

1. **Intentional absence of tokens** — forces consumers to own their design language fully
2. **State as styling API** — `data-state` instead of variant props or className injection
3. **1:1 DOM mapping** — each component renders one element (composition over configuration)
4. **Per-package publishing** — no monolithic styles package to tree-shake
5. **Separate color product** — `@radix-ui/colors` is optional, not bundled into primitives
6. **Storybook demos are not product** — all visual styling is development-only

## Relevance to SNDQ

Radix Primitives represents the opposite end of the spectrum from a token-rich system. Its value to SNDQ is architectural:
- Validates that behavior and styling concerns should be separable
- Shows that `data-*` attributes are a universal styling hook
- Demonstrates that a headless layer under a design system is viable
- SNDQ's `@sndq/ui-v2` components could theoretically wrap Radix primitives while applying SNDQ tokens

## Cross-References

- [Comparison Overview](../token-architecture/comparison-overview.md) — Radix as the "no tokens" endpoint
- [HeroUI Token Analysis](../heroui/token-analysis.md) — HeroUI builds on React Aria (similar philosophy to Radix)
