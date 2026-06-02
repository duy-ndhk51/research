# Token Mapping Strategy

How to map SNDQ's current CSS custom properties to DESIGN.md YAML tokens.

---

## Briicks Primitive Tokens

| CSS variable pattern | DESIGN.md token group | Example |
|---------------------|----------------------|---------|
| `--color-brand-{25-900}` | `colors.brand-{25-900}` | `brand-500: "#4F46E5"` |
| `--color-neutral-{0-900}` | `colors.neutral-{0-900}` | `neutral-100: "#F5F5F5"` |
| `--color-success-{25-900}` | `colors.success-{25-900}` | `success-500: "#22C55E"` |
| `--color-warning-{25-900}` | `colors.warning-{25-900}` | `warning-500: "#F59E0B"` |
| `--color-error-{25-900}` | `colors.error-{25-900}` | `error-500: "#EF4444"` |
| `--font-size-{xs-3xl}` | `typography.{level}` | `body-md: { fontSize: 16px, ... }` |
| `--spacing-{1-12}` | `spacing.{1-12}` | `4: 16px` |
| `--radius-{sm,md,lg,full}` | `rounded.{sm,md,lg,full}` | `md: 8px` |

## UI-V2 Semantic Tokens

| CSS variable pattern | DESIGN.md token group | Notes |
|---------------------|----------------------|-------|
| `--sndq-action`, `--sndq-action-hover`, etc. | `colors.sndq-action`, `colors.sndq-action-hover` | Semantic role tokens, reference Briicks primitives |
| `--sndq-surface`, `--sndq-surface-subtle`, etc. | `colors.sndq-surface`, etc. | Surface hierarchy |
| `--sndq-text`, `--sndq-text-secondary`, etc. | `colors.sndq-text`, etc. | Text hierarchy |
| `--sndq-border`, `--sndq-border-strong`, etc. | `colors.sndq-border`, etc. | Border variations |
| `--sndq-h-sm`, `--sndq-h`, `--sndq-h-lg` | `spacing.control-sm`, `spacing.control`, `spacing.control-lg` | Control sizing |
| `--sndq-r-{xs-full}` | `rounded.sndq-{xs-full}` | Component radius scale |
| `--sndq-shadow-{xs-md}` | Cannot express in DESIGN.md | No shadow token type — document in prose |

## What cannot be mapped

| CSS concept | Why | Workaround |
|-------------|-----|------------|
| Box shadows (`--sndq-shadow-*`) | No shadow token type in DESIGN.md | Document in Elevation & Depth prose section |
| Dark mode variables (`.dark { ... }`) | No theme variant support | Keep in CSS; document light-mode values in DESIGN.md |
| Component CSS classes (`.sndq-btn`, etc.) | DESIGN.md component tokens only cover 8 properties | Define what can be expressed (colors, radius, padding, height); document the rest in Components prose |
| Animation keyframes | No animation token type | Document in a custom `## Animations` section (DESIGN.md preserves unknown sections) |
