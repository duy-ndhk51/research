# Token Generation Pipelines

## TL;DR

The most maintainable systems generate tokens from a single source of truth. Three dominant patterns: YAML/Markdown source to CSS/JSON (SNDQ, Kumo), TypeScript config to CSS (Kumo), JS theme object to CSS vars at runtime (Mantine, Ant Design). Build-time generation wins for performance; runtime generation wins for dynamic theming.

## Key Concepts

### Pipeline Architectures

| System | Source | Transform | Output | When |
|--------|--------|-----------|--------|------|
| SNDQ | `DESIGN.md` (YAML) | `export-design-tokens.mjs` | `tokens.css` + `tokens.dtcg.json` | Build (`pnpm design:sync`) |
| Kumo | `config.ts` (TS) | `generate-css.ts` | `theme-kumo.css` + `theme-fedramp.css` | Build (`pnpm codegen:themes`) |
| Mantine | `DEFAULT_THEME` (JS) | `defaultCssVariablesResolver` | `<style>` in DOM | Runtime (+ static pre-gen) |
| Ant Design | Seed + Algorithm | `@ant-design/cssinjs` | Scoped CSS rules | Runtime |
| React Spectrum S2 | `variables.json` (JSON) | `style()` macro (Parcel) | Compiled CSS | Build (bundler plugin) |
| HeroUI | Hand-authored CSS | None | Direct CSS files | None (manual) |

### Source Format Comparison

| Format | Pros | Cons | Used By |
|--------|------|------|---------|
| **YAML in Markdown** | Human-readable, versionable, designer-friendly | Custom parser needed, no IDE autocomplete | SNDQ |
| **TypeScript config** | Type-safe, IDE support, refactorable | Requires TS toolchain | Kumo |
| **JSON (W3C DTCG)** | Interoperable, Figma-friendly, standardized | Verbose, no computed values | SNDQ (output), Spectrum |
| **JS theme object** | Full expressiveness, composable | Not portable to non-JS tools | Mantine, Ant Design |
| **CSS variables** | Universal, no build step | No derivation, manual maintenance | HeroUI |

## Deep Dive

### SNDQ Pipeline (Current)

```
packages/ui-v2/DESIGN.md
    | pnpm design:export:tailwind
scripts/export-design-tokens.mjs (@google/design.md CLI)
    |
packages/config/tailwind/tokens.css       (@theme inline)
packages/config/tailwind/tokens.dtcg.json  (W3C format)
```

**Strengths:**
- Single source (DESIGN.md) readable by designers and devs
- W3C DTCG output for Figma/tool interop
- Tailwind v4 native `@theme inline` output

**Gaps:**
- No dark mode values in DESIGN.md yet
- No computed/derived tokens in the pipeline (color-mix lives separately in semantic-tokens.css)
- Manual aliasing bridge in tokens.css for CSS-only tokens
- No validation step (can generate invalid tokens silently)

### Kumo Pipeline (Best Practice Model)

```
packages/kumo/scripts/theme-generator/config.ts
    | pnpm codegen:themes
packages/kumo/scripts/theme-generator/generate-css.ts
    |
theme-kumo.css     (@theme + @layer base, both light-dark() and explicit selectors)
theme-fedramp.css  (overrides only)
    |
Consumed by lint rules (auto-allowlist)
Consumed by Figma plugin (sync-tokens-to-figma.ts)
Consumed by docs (virtual:kumo-colors module)
```

Key insight: One config feeds CSS, lint, Figma, docs. Adding a token = edit config, run codegen, everything updates.

### Mantine Pipeline (Hybrid Static + Runtime)

```
DEFAULT_THEME (JS object)
    | scripts/codegen/generate-default-css-variables.ts
default-css-variables.css (static, imported at build)
    | MantineCssVariables component
<style> tag in DOM (runtime diffs only when theme changes)
```

Key insight: Pre-generate defaults as static CSS; only inject runtime styles for the delta. Best of both worlds for unchanged defaults.

### Recommended SNDQ Evolution

**Phase 1 — Add dark mode to DESIGN.md:**
```yaml
colors:
  sndq-surface:
    light: "{neutral.50}"
    dark: "{neutral.900}"
```
Update export script to emit both values.

**Phase 2 — Add validation:**
```bash
pnpm design:lint  # Check all tokens have both light/dark, valid references
```

**Phase 3 — Add Figma sync:**
```bash
pnpm design:sync:figma  # Push DTCG tokens to Figma Variables
```

**Phase 4 (optional) — Migrate to TS config:**
If DESIGN.md becomes limiting (computed tokens, conditional logic), migrate to a TypeScript config like Kumo's — still generates CSS, but with full type safety and IDE support.

## Cross-References

- [Comparison Overview](./comparison-overview.md) — how pipelines fit into overall architecture
- [Dark Mode Strategies](./dark-mode-strategies.md) — what the pipeline needs to output for dark mode
- [SNDQ Recommendations](./sndq-recommendations.md) — phased evolution plan

## References

- W3C Design Tokens Community Group: https://design-tokens.github.io/community-group/format/
- Style Dictionary: https://amzn.github.io/style-dictionary/
- Cobalt UI (DTCG tooling): https://cobalt-ui.pages.dev/
