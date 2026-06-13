# Component Tokens

## TL;DR

Component tokens create a contract between the design system and individual components. The pattern ranges from "no component tokens" (use semantic directly) to "every component has its own token namespace". The sweet spot is: semantic tokens for 90% of cases, component-local CSS vars for the 10% that need isolation.

## Key Concepts

### The Spectrum of Approaches

| Approach | System | Example |
|----------|--------|---------|
| **No component tokens** | Kumo, early SNDQ | Components use `bg-kumo-base` directly |
| **CSS local vars** | HeroUI | `--button-bg: var(--accent)` on `.button` |
| **Typed component config** | Ant Design | `theme.components.Button.primaryShadow` |
| **Component `vars` callback** | Mantine | `Button.extend({ vars: (theme, props) => {...} })` |
| **Scoped CSS vars** | material-react-table | `--mrt-base-background-color` mapped to `--mantine-color-body` |

### When You Need Component Tokens

| Signal | Example | Solution |
|--------|---------|----------|
| Same semantic token, different component values | Card bg vs Page bg (both "surface") | Component token: `--card-bg` |
| Variant-specific overrides | Primary button hover vs Secondary | Component CSS vars per variant |
| Third-party integration | Table library needs bridge tokens | Scoped `--mrt-*` vars |
| Theme-per-component | Different algorithm for one component | Ant Design `components.Button.algorithm` |
| User customization API | "Change button height without global change" | Named component token |

## Deep Dive

### Pattern A: HeroUI Component-Local Vars (Recommended)

```css
.button {
  --button-bg: transparent;
  --button-fg: currentColor;
  --button-border: transparent;

  background: var(--button-bg);
  color: var(--button-fg);
  border-color: var(--button-border);
}

.button--primary {
  --button-bg: var(--accent);
  --button-fg: var(--accent-foreground);
}

.button--secondary {
  --button-bg: var(--surface);
  --button-fg: var(--foreground);
  --button-border: var(--border);
}
```

Why this works:
- Variants only swap values, not properties
- Consumers can override `--button-bg` without knowing implementation
- States (hover, active) modify the same vars
- Inspectable in DevTools

### Pattern B: Ant Design Typed Component Tokens

```typescript
// components/button/style/token.ts
export interface ButtonToken extends FullToken<'Button'> {
  buttonPaddingHorizontal: number;
  buttonPaddingVertical: number;
  defaultBg: string;
  defaultShadow: string;
  primaryShadow: string;
}

export const prepareComponentToken: GetDefaultToken<'Button'> = (token) => ({
  defaultBg: token.colorBgContainer,
  primaryShadow: `0 2px 0 ${new TinyColor(token.colorPrimary).setAlpha(0.12)}`,
});
```

Why this works:
- Type-safe override surface
- Derived from alias tokens (cascades from seed changes)
- Per-component customization in ConfigProvider

### Pattern C: Mantine Component Vars

```typescript
Button.extend({
  vars: (theme, props) => ({
    root: {
      '--button-height': props.size === 'compact-sm' ? rem(26) : undefined,
      '--button-fz': props.size === 'compact-sm' ? 'var(--mantine-font-size-xs)' : undefined,
    },
  }),
});
```

Why this works:
- Props-driven dynamic tokens
- Scoped to component slots (root, label, etc.)
- Composable with global theme

### SNDQ Current State

SNDQ has implicit component tokens in `components.css`:
```css
.sndq-btn-primary {
  @apply bg-sndq-action text-sndq-action-fg border-sndq-action-border;
  box-shadow: var(--sndq-shadow-inset-top), 0 1px 3px rgba(6, 37, 159, 0.24);
}
```

This works but does not expose a customization surface. If a consumer wants to change just the button's shadow without touching the global shadow token, they must override the entire class.

### Recommended Evolution for SNDQ

**Step 1 — Add component-local vars to frequently customized components:**

```css
.sndq-btn {
  --sndq-btn-bg: transparent;
  --sndq-btn-fg: currentColor;
  --sndq-btn-shadow: none;
  --sndq-btn-radius: var(--radius-sndq);
  --sndq-btn-height: var(--spacing-sndq-h);

  background: var(--sndq-btn-bg);
  color: var(--sndq-btn-fg);
  box-shadow: var(--sndq-btn-shadow);
  border-radius: var(--sndq-btn-radius);
  height: var(--sndq-btn-height);
}

.sndq-btn-primary {
  --sndq-btn-bg: var(--color-sndq-action);
  --sndq-btn-fg: var(--color-sndq-action-fg);
  --sndq-btn-shadow: var(--shadow-sndq-btn-primary);
}
```

**Step 2 — Document the customization surface** per component.

**Step 3 — Only add component tokens when there's a real customization need.** Do not over-engineer — start with semantic tokens, add component vars when a specific override scenario arises.

## Cross-References

- [Naming & Hierarchy](./naming-hierarchy.md) — component token naming conventions
- [HeroUI Token Analysis](../heroui/token-analysis.md) — full component-local var reference
- [Ant Design Token Analysis](../ant-design/token-analysis.md) — typed component token system
- [SNDQ Recommendations](./sndq-recommendations.md) — Phase 3 covers this

## References

- Brad Frost, "The Design System Ecosystem": https://bradfrost.com/blog/post/the-design-system-ecosystem/
