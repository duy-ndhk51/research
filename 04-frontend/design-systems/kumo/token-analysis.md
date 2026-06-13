# Kumo (Cloudflare) — Token Analysis

## TL;DR

Kumo uses a TypeScript-first, build-time-generated token system built on Tailwind CSS v4. A single `config.ts` file is the source of truth for all semantic tokens, generating CSS with both `light-dark()` and explicit selector fallbacks. Custom lint rules enforce token usage at commit time.

## Key Facts

| Aspect | Detail |
|--------|--------|
| Tech Stack | React, TypeScript, Tailwind CSS v4, Base UI |
| Token Count | ~55 semantic tokens (text, color, typography) |
| Format | CSS `@theme` + `@layer base` (generated from TS) |
| Dark Mode | `data-mode` attribute + CSS `light-dark()` dual delivery |
| Customization API | `data-theme` attribute for brand variants |
| Source of Truth | `packages/kumo/scripts/theme-generator/config.ts` |

## Architecture

### File Map

```
packages/kumo/
  scripts/theme-generator/
    config.ts           # Token definitions (single source)
    types.ts            # ThemeConfig, TokenDefinition types
    generate-css.ts     # Core generator
    index.ts            # CLI entry
    migrate.ts          # Token rename codemod
  src/styles/
    theme-kumo.css      # GENERATED — base theme
    theme-fedramp.css   # GENERATED — override-only
    kumo-binding.css    # Hand-maintained (primitives, animations, utilities)
    kumo.css            # Main entry (imports everything)
```

### Generation Flow

```
config.ts (ThemeConfig)
    | pnpm codegen:themes
generate-css.ts
    |
theme-kumo.css     (@theme + @layer base)
theme-fedramp.css  (overrides only)
    |
lint rules (auto-allowlist from generated CSS)
Figma plugin (sync-tokens-to-figma.ts)
docs site (virtual:kumo-colors module)
```

## Token Hierarchy

### Layer 1: Primitives (Hand-maintained)

In `kumo-binding.css`, not generated:
- `--color-red-650`, `--color-kumo-neutral-925` (oklch values)
- Tailwind default palette vars referenced by semantic tokens

### Layer 2: Semantic (Generated)

Three categories in `config.ts`:
- **Text** (17 tokens): `--text-color-kumo-default`, `-inverse`, `-strong`, `-subtle`, `-brand`, `-danger`, etc.
- **Color** (37 tokens): `--color-kumo-base`, `-elevated`, `-recessed`, `-tint`, `-brand`, `-focus`, `-fill`, status tints, badge backgrounds
- **Typography** (8 entries): `--text-xs` through `--text-lg` with line heights

Each token defined as:
```typescript
{
  newName: string,
  theme: {
    kumo: { light: string, dark: string },
    fedramp?: { light: string, dark: string },
  },
  description?: string,
}
```

### Layer 3: No Component Tokens

Components consume semantic tokens directly via Tailwind utilities (`bg-kumo-base`, `text-kumo-default`). No intermediate component-level token layer.

## Dark Mode

Dual delivery pattern:

```css
/* In @theme — for Tailwind utility generation */
@theme {
  --color-kumo-base: light-dark(#fff, oklch(17% 0 0));
}

/* In @layer base — runtime fallback for DOM mutation edge cases */
@layer base {
  :root, [data-theme="kumo"] {
    --color-kumo-base: #fff;
  }
  [data-mode="dark"] {
    --color-kumo-base: oklch(17% 0 0);
  }
}
```

Switching: set `data-mode="light"` or `data-mode="dark"` on a parent element. Enforced: `dark:` variant is lint-blocked.

## Generation / Authoring

- **Edit `config.ts`, run `pnpm codegen:themes`** — never hand-edit generated CSS
- Generator emits both `light-dark()` format and explicit mode-scoped overrides
- Override themes (fedramp) only include tokens where `theme.fedramp` exists in config
- Migration support: `newName` field + `migrate.ts` renames classes across codebase
- Part of broader chain: `codegen = codegen:primitives + codegen:themes + codegen:registry`

## Component Integration

Components use `cn()` (clsx + tailwind-merge) with semantic utility classes:

```typescript
"bg-kumo-brand !text-white hover:bg-kumo-brand-hover"
"bg-kumo-base !text-kumo-default ring ring-kumo-hairline"
```

Variant maps exported for registry/Figma: `KUMO_BUTTON_VARIANTS`, `KUMO_BADGE_VARIANTS`.

Surface hierarchy convention: `bg-kumo-canvas` < `bg-kumo-elevated` < `bg-kumo-recessed` < `bg-kumo-base`.

## Customization Surface

- **Brand themes:** `data-theme="fedramp"` activates override CSS
- **Mode:** `data-mode="dark"` toggles all tokens
- **No per-component override API** — customization is at the token level
- **Adding tokens:** Edit config, run codegen, lint auto-updates allowlist

## Key Patterns

1. **Single config feeds everything** — CSS, lint, Figma, docs all derive from `config.ts`
2. **Lint enforcement** — raw palette colors blocked at commit (`no-primitive-colors.js`, `no-tailwind-dark-variant.js`)
3. **Dual delivery** — `light-dark()` for Tailwind + `@layer base` for runtime stability
4. **Override-only themes** — fedramp file overrides 3 of 55 tokens (minimal diff)
5. **Migration via `newName`** — token renames are safe, automated codemod across codebase
6. **Unidirectional Figma sync** — code to Figma, never the reverse

## Cross-References

- [Kumo AI-Friendly Pattern](./ai-friendly-pattern.md) — existing note on Kumo patterns
- [Comparison Overview](../token-architecture/comparison-overview.md)
- [Dark Mode Strategies](../token-architecture/dark-mode-strategies.md) — Kumo as Pattern 1
- [Generation Pipelines](../token-architecture/generation-pipelines.md) — Kumo as best practice model
- [Multi-Theme Patterns](../token-architecture/multi-theme-patterns.md) — override-only approach
