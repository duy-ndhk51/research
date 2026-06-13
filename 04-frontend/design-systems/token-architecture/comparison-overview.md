# Comparison Overview

## TL;DR

Production design systems converge on CSS custom properties as the runtime format but diverge significantly on authoring format, generation pipeline, and customization API. The most maintainable systems use a single source of truth with automated derivation.

## Key Concepts

### Architecture Spectrum

| | Ant Design | Mantine | Kumo | React Spectrum | HeroUI | SNDQ |
|---|---|---|---|---|---|---|
| **Authoring** | JS seed objects | JS theme object | TS config | CSS / JSON | CSS vars | DESIGN.md YAML |
| **Runtime** | CSS-in-JS injection | `<style>` tag | Static CSS | CSS modules | Static CSS | Static CSS |
| **Customization** | `ConfigProvider` props | `MantineProvider` theme | `data-theme` attr | Theme object | CSS var override | CSS var override |
| **Token count** | ~500+ (derived) | ~200 base | ~55 semantic | ~1000+ | ~80 semantic | ~100 semantic |
| **Codegen** | Algorithmic at runtime | Resolver at runtime | Build-time script | Build-time (S2) | None | Build-time script |

### Delivery Mechanisms

| Mechanism | Used By | Pros | Cons |
|-----------|---------|------|------|
| CSS-in-JS runtime | Ant Design | Full JS control, dynamic themes | Bundle size, FOUC, SSR complexity |
| JS to CSS var resolver | Mantine | Typed + cacheable, diff injection | Runtime cost, JS dependency |
| Build-time generated CSS | Kumo, SNDQ, Spectrum S2 | Zero runtime, cache-friendly | Rebuild for changes |
| Static CSS files | HeroUI, Spectrum S1 | Simple, fast, no tooling deps | Manual maintenance |
| Compile-time macros | Spectrum S2 | Tree-shaking, zero runtime | Complex toolchain |

### Customization Depth

| Level | Example | Who Supports |
|-------|---------|--------------|
| Global seed override | Change `colorPrimary` cascades everywhere | Ant Design, Mantine |
| Token-level override | Override `--color-brand` | All CSS-var systems |
| Component-level tokens | Button-specific `primaryShadow` | Ant Design, Mantine, MRT |
| Algorithm swap | `darkAlgorithm` | Ant Design |
| Theme file replacement | Swap `theme-default` to `theme-fedramp` | Kumo, Spectrum S1 |
| Full CSS layer override | `@layer` priority | HeroUI, SNDQ |

## Deep Dive

### What Makes Each System Unique

**Ant Design** — Most sophisticated derivation. ~12 seed values generate 500+ tokens via algorithms. Dark mode is literally a different math function, not different values. Enables composable `[default, dark, compact]` algorithm stacking.

**Mantine** — Best developer ergonomics. `createTheme()` identity function + deep merge means zero learning curve. `rem()` utility auto-scales everything via `--mantine-scale`. Static CSS pre-generated for defaults, runtime only injects diffs.

**Kumo** — Best enforcement. Custom lint rules literally block raw colors at commit time. Dual delivery (light-dark() in @theme + explicit @layer base fallbacks) handles edge cases. FedRAMP theme overrides only tokens that differ.

**React Spectrum S2** — Most zero-runtime. Tokens consumed at compile time via style macros; final CSS has no var() lookups for most values. Best for performance-critical deployments.

**HeroUI** — Best component-local isolation. Three-tier: semantic vars, Tailwind theme, per-component CSS vars (e.g. `--button-bg`). Variants only swap local vars, making reasoning about overrides trivial.

**SNDQ (current)** — Closest to Kumo/HeroUI model. DESIGN.md YAML to Tailwind v4 `@theme inline`. Missing: dark mode in the shared layer, multi-theme support, component-level token contracts.

## Cross-References

- [Naming & Hierarchy](./naming-hierarchy.md) — how naming conventions differ
- [Generation Pipelines](./generation-pipelines.md) — authoring and codegen details
- [SNDQ Recommendations](./sndq-recommendations.md) — where SNDQ should go next

## References

- Ant Design Theme docs: https://ant.design/docs/react/customize-theme
- Mantine Theming: https://mantine.dev/theming/theme-object/
- Spectrum Tokens: https://spectrum.adobe.com/page/design-tokens/
