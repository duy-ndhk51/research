# Token Naming & Hierarchy

## TL;DR

Every mature system uses a 2-4 layer naming hierarchy. The universal pattern is **primitives to semantic to component**. Naming should encode role (what it does), not value (what it looks like).

## Key Concepts

### The Universal Layers

```
Layer 1: Primitives (raw values)
  blue-500, gray-200, 16px, 600

Layer 2: Semantic / Alias (role-based)
  action, surface, text-secondary, radius-default

Layer 3: Component (scoped overrides)
  button-bg, input-border, card-shadow

Layer 4 (optional): State derivations
  action-hover, surface-active, text-disabled
```

### How Each System Names Tokens

| System | Primitive | Semantic | Component |
|--------|-----------|----------|-----------|
| Ant Design | `colorPrimary` (seed) | `colorText`, `colorBgContainer` (alias) | `Button.primaryShadow` |
| Mantine | `colors.blue[6]` | `--mantine-color-body` | Component `vars` callback |
| Kumo | `--color-neutral-900` | `--color-kumo-base`, `--text-color-kumo-default` | None (uses semantic directly) |
| HeroUI | `--eclipse`, `--white` | `--accent`, `--surface` | `--button-bg`, `--button-fg` |
| Spectrum S1 | `--spectrum-blue-900` | `--spectrum-accent-color-*` | `--spectrum-button-*` |
| SNDQ | `brand-700`, `neutral-200` | `sndq-action`, `sndq-surface` | `.sndq-btn` CSS vars |

### Naming Conventions Compared

| Convention | Example | Used By |
|------------|---------|---------|
| `{system}-{role}` | `kumo-base`, `sndq-action` | Kumo, SNDQ |
| `{category}-{role}-{state}` | `color-primary-hover` | Ant Design maps |
| `{system}-{category}-{scale}` | `mantine-spacing-md` | Mantine |
| `{component}-{property}` | `button-bg`, `input-border` | HeroUI component layer |
| camelCase JS keys | `colorTextSecondary` | Ant Design |
| kebab-case CSS vars | `--color-kumo-elevated` | Kumo, HeroUI, SNDQ |

## Deep Dive

### Best Practices Distilled

1. **Role over value**: `action` not `blue`, `surface` not `white`, `text-secondary` not `gray-600`
2. **Predictable structure**: Always `{namespace}-{category}-{variant}-{state}`
3. **Flat semantic layer**: Avoid deeply nested paths; `sndq-action-hover` over `sndq.colors.action.states.hover`
4. **State as suffix**: `-hover`, `-active`, `-disabled`, `-focus` — consistent across all tokens
5. **Scale as size keyword**: `xs|sm|md|lg|xl` for relative, numbers for absolute
6. **Separate concerns**: Color tokens never encode size; spacing tokens never encode color

### SNDQ Current Naming Analysis

**Strengths:**
- Clear `sndq-` namespace prefix
- Role-based semantic names (`sndq-action`, `sndq-surface`, `sndq-text`)
- State suffixes (`-hover`, `-subtle`)
- Consistent Tailwind utility derivation

**Gaps:**
- No component-level token layer (e.g. no `--sndq-input-bg` separate from `--sndq-surface`)
- Primitive layer uses two naming schemes (`brand-700` vs `neutral-200`)
- Status tokens mix naming patterns (`sndq-success-*` alongside `sndq-error-*` alongside generic `sndq-warning-*`)
- No explicit layer documentation for contributors

### Recommended SNDQ Naming Schema

```
Primitives (avoid in new code):
  --color-{hue}-{step}         e.g. --color-brand-700, --color-neutral-200

Semantic (preferred):
  --color-sndq-{role}          e.g. --color-sndq-action
  --color-sndq-{role}-{state}  e.g. --color-sndq-action-hover
  --color-sndq-{role}-{mod}    e.g. --color-sndq-action-subtle
  --text-sndq-{role}           e.g. --text-sndq-secondary
  --spacing-sndq-{scale}       e.g. --spacing-sndq-4
  --radius-sndq-{scale}        e.g. --radius-sndq-md
  --shadow-sndq-{scale}        e.g. --shadow-sndq-sm

Component (add when needed):
  --sndq-{component}-{property}  e.g. --sndq-btn-bg, --sndq-input-border
```

## Cross-References

- [Comparison Overview](./comparison-overview.md) — full architecture comparison
- [Component Tokens](./component-tokens.md) — when and how to add component-level tokens
- [SNDQ Recommendations](./sndq-recommendations.md) — actionable naming improvements

## References

- Nathan Curtis, "Naming Tokens in Design Systems": https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676
- W3C Design Tokens Format: https://design-tokens.github.io/community-group/format/
