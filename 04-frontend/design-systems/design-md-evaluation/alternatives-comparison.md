# DESIGN.md — Alternatives Comparison

Short comparison of DESIGN.md against established design token formats and tools. The goal is to understand where DESIGN.md fits in the ecosystem, not to provide an exhaustive review of each tool.

For DESIGN.md's full feature set, see [features-overview.md](./features-overview.md).

---

## Comparison Matrix

| Dimension | DESIGN.md | W3C DTCG (tokens.json) | Style Dictionary | Figma Variables | Tailwind Config |
|-----------|-----------|------------------------|------------------|-----------------|-----------------|
| **Format** | Markdown + YAML | JSON | JSON / YAML (+ config) | Figma-native | JS / TS |
| **Machine readable** | Yes (YAML tokens) | Yes (JSON) | Yes (JSON/YAML input) | Yes (API) | Yes (JS object) |
| **Human readable** | Yes (prose sections) | No | No | Partial (descriptions) | No |
| **CLI tooling** | lint, diff, export, spec | N/A (spec only) | Build + transform pipeline | N/A (GUI + API) | N/A (part of Tailwind) |
| **Validation / linting** | 7 built-in rules | N/A | Custom via hooks | N/A | N/A |
| **WCAG contrast check** | Built-in (`contrast-ratio` rule) | No | Via custom transform | No | No |
| **Version diffing** | Built-in (`diff` command) | Manual JSON diff | Manual JSON diff | Via version history | Manual config diff |
| **Tailwind export** | Built-in (`export --format tailwind`) | Via Style Dictionary | Yes (custom format) | Via plugins | Native |
| **DTCG export** | Built-in (`export --format dtcg`) | Native | Native output | Via plugins | No |
| **Figma sync** | Via DTCG roundtrip | Via plugins | Via plugins | Native | Via plugins |
| **Multi-platform output** | Tailwind + DTCG | Via Style Dictionary | iOS, Android, Web, etc. | Via plugins | Web only |
| **Agent optimized** | Yes (primary design goal) | No | No | No | No |
| **Maturity** | Alpha | W3C Community Draft | Mature (v4+) | GA | Stable |
| **Maintainer** | Google | W3C Design Tokens CG | Amazon | Figma | Tailwind Labs |

---

## Tool-by-Tool Analysis

### W3C DTCG (Design Token Community Group)

The [W3C Design Tokens Format Module](https://tr.designtokens.org/format/) defines a standard JSON format (`tokens.json`) for describing design tokens across tools and platforms.

**Relationship to DESIGN.md**: DESIGN.md's token model is inspired by DTCG. The `export --format dtcg` command converts DESIGN.md tokens to a compliant `tokens.json`. They are complementary, not competing — DESIGN.md adds the human-readable layer and agent optimization that DTCG's pure JSON cannot provide.

**When to use DTCG directly**: When you need a tool-agnostic token exchange format between Figma, Style Dictionary, and multiple platform targets (iOS, Android, Web). DTCG is the wire format; DESIGN.md is the authoring format.

### Style Dictionary

[Style Dictionary](https://amzn.github.io/style-dictionary/) (by Amazon) is a build system for design tokens. It reads token files (JSON/YAML/DTCG) and transforms them into platform-specific outputs (CSS custom properties, Swift constants, Kotlin values, Tailwind config, etc.).

**Relationship to DESIGN.md**: Style Dictionary is a transform pipeline, not an authoring format. DESIGN.md can feed into Style Dictionary via its DTCG export. The combination would be: DESIGN.md (authoring) → `export --format dtcg` → `tokens.json` → Style Dictionary → platform outputs.

**When to use Style Dictionary**: When you need to generate tokens for multiple platforms (iOS + Android + Web) from a single source. Overkill for web-only projects with Tailwind.

### Figma Variables

[Figma Variables](https://help.figma.com/hc/en-us/articles/15339657135383) are a native Figma feature for defining design tokens (colors, numbers, strings, booleans) inside Figma files, with support for modes (light/dark) and scoping.

**Relationship to DESIGN.md**: Figma Variables live inside the design tool; DESIGN.md lives in the codebase. There is no direct sync today. The bridge is DTCG: export DESIGN.md tokens to `tokens.json`, import into Figma via Token Studio or the Variables API. The reverse flow (Figma → DESIGN.md) requires manual translation or custom scripting.

**When to use Figma Variables**: When designers are the primary token authors and the team has a strong Figma-first workflow. Not suitable as a code-side source of truth.

### Tailwind Config

Tailwind CSS's `tailwind.config.js` (or `tailwind.config.ts`) defines the theme — colors, spacing, typography, border-radius, shadows, etc. — as a JavaScript object consumed directly by the Tailwind JIT compiler.

**Relationship to DESIGN.md**: DESIGN.md can generate a Tailwind theme config via `export --format tailwind`. However, Tailwind configs are JavaScript and can express arbitrary logic (functions, conditionals, plugin references) that DESIGN.md's static YAML cannot. DESIGN.md covers the declarative subset; Tailwind handles the dynamic runtime.

**When to use Tailwind config directly**: When you only need Web/Tailwind output, the team works code-first, and you don't need agent-readable design rationale or automated WCAG validation.

---

## Key Insight

DESIGN.md occupies a unique position: it is the only format that combines **machine-readable tokens** with **human-readable design rationale** in a single file, specifically optimized for **AI agent consumption**.

```
                    Machine Readable
                          │
         Tailwind ────────┤
         DTCG ────────────┤
         Style Dict ──────┤
         DESIGN.md ───────┤──── + Human Readable + Agent Optimized
                          │
         Figma Vars ──────┤──── + GUI-native
                          │
```

All other tools solve the "token storage and transformation" problem. DESIGN.md additionally solves the "design intent communication" problem — especially for AI agents that need to understand *why* a design decision was made, not just *what* the values are.

---

## When to Combine Tools

DESIGN.md does not replace the entire design token ecosystem. The recommended combination depends on the project:

| Scenario | Recommended stack |
|----------|-------------------|
| Web-only, Tailwind, agent-assisted | DESIGN.md → `export --format tailwind` → Tailwind config |
| Web-only, Tailwind, no agents | Tailwind config directly (DESIGN.md adds overhead without agent benefit) |
| Multi-platform (iOS + Android + Web) | DESIGN.md → `export --format dtcg` → Style Dictionary → platform outputs |
| Figma-heavy team, web output | Figma Variables → Token Studio → DTCG export → optional DESIGN.md for agent context |
| CI-gated design quality | DESIGN.md `lint` + `diff` in pipeline, regardless of other tools |

---

## References

- [W3C Design Tokens Format Module](https://tr.designtokens.org/format/)
- [Style Dictionary v4 Documentation](https://amzn.github.io/style-dictionary/)
- [Figma Variables Documentation](https://help.figma.com/hc/en-us/articles/15339657135383)
- [Tailwind CSS Theme Configuration](https://tailwindcss.com/docs/theme)
- [Token Studio for Figma](https://tokens.studio/)
