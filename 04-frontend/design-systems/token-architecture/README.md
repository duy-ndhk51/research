# Design System Token Architecture

## TL;DR

Design tokens are the atomic decisions (colors, spacing, typography, shadows) that define a design system's visual language. After studying 8 production systems — Ant Design, Mantine, Kumo, React Spectrum, HeroUI, Radix Primitives, material-react-table, mantine-react-table — the dominant patterns are:

1. **Layered hierarchy**: primitives, semantic, component
2. **Single source of truth** with codegen to multiple formats
3. **CSS custom properties** as the runtime delivery mechanism
4. **Mode switching** via attributes/classes, not media queries alone

## Status

| Field | Value |
|-------|-------|
| Created | 2026-06-08 |
| Source | 8 production design systems in workspace |
| Purpose | Guide SNDQ token architecture decisions |
| Last reviewed | 2026-06-08 |

## Research Documents

| Document | Focus |
|----------|-------|
| [Comparison Overview](./comparison-overview.md) | Side-by-side architecture comparison |
| [Naming & Hierarchy](./naming-hierarchy.md) | Token naming conventions and layering |
| [Dark Mode Strategies](./dark-mode-strategies.md) | Color scheme switching patterns |
| [Generation Pipelines](./generation-pipelines.md) | Manual vs codegen vs hybrid |
| [Component Tokens](./component-tokens.md) | How component-level tokens relate to globals |
| [Multi-Theme Patterns](./multi-theme-patterns.md) | Supporting multiple brands |
| [SNDQ Recommendations](./sndq-recommendations.md) | Actionable plan for @sndq/config |

## Systems Studied

| System | Analysis | Approach | Token Format | Dark Mode |
|--------|----------|----------|--------------|-----------|
| Ant Design | [Full analysis](../ant-design/token-analysis.md) | CSS-in-JS, 4-layer hierarchy | JS objects, runtime CSS | Algorithm swap |
| Mantine | [Full analysis](../mantine/token-analysis.md) | JS theme, CSS vars resolver | `--mantine-*` vars | Color-scheme attribute |
| Kumo | [Full analysis](../kumo/token-analysis.md) | TS config, build-time codegen | `@theme` + `light-dark()` | `data-mode` attribute |
| React Spectrum | [Full analysis](../react-spectrum/token-analysis.md) | CSS files (S1) / JSON macros (S2) | `--spectrum-*` vars / compiled | Class swap (S1) / `color-scheme` (S2) |
| HeroUI | [Full analysis](../heroui/token-analysis.md) | Layered CSS + Tailwind v4 | `@theme inline` + BEM vars | `.dark` / `data-theme` |
| Radix Primitives | [Full analysis](../radix-primitives/token-analysis.md) | Headless (no tokens) | N/A | Consumer responsibility |
| material-react-table | [Full analysis](../material-react-table/token-analysis.md) | MUI delegation + bridge | `mrtTheme` (7 colors) | MUI palette mode |
| mantine-react-table | [Full analysis](../mantine-react-table/token-analysis.md) | Mantine delegation + bridge | `--mrt-*` CSS vars | Mantine color scheme |
| SNDQ (current) | [Recommendations](./sndq-recommendations.md) | DESIGN.md, build-time codegen | `@theme inline` + semantic vars | Not yet (planned) |

## Cross-References

- [DESIGN.md Evaluation](../design-md-evaluation/README.md)
- [Kumo AI-Friendly Pattern](../kumo/ai-friendly-pattern.md)
- [SNDQ Table Architecture](../../12-sndq/frontend/features/design-system/table/architecture.md)

## References

- W3C Design Tokens Community Group: https://design-tokens.github.io/community-group/format/
- Nathan Curtis, "Naming Tokens in Design Systems": https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676
- Ant Design Theme docs: https://ant.design/docs/react/customize-theme
- Mantine Theming: https://mantine.dev/theming/theme-object/
- Spectrum Design Tokens: https://spectrum.adobe.com/page/design-tokens/
