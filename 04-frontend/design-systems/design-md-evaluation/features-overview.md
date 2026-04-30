# DESIGN.md — Features Overview

Full feature map of the DESIGN.md format specification and CLI toolchain. This document is framework-agnostic and applies to any project considering DESIGN.md adoption.

**Source**: [DESIGN.md spec](https://github.com/nichochar/design.md/blob/main/docs/spec.md) | [CLI README](https://github.com/nichochar/design.md)

---

## Table of Contents

1. [Dual-Layer Architecture](#1-dual-layer-architecture)
2. [Token Specification System](#2-token-specification-system)
3. [Canonical Sections](#3-canonical-sections)
4. [Component Tokens](#4-component-tokens)
5. [CLI Toolchain](#5-cli-toolchain)
6. [Linting Rules](#6-linting-rules)
7. [Programmatic API](#7-programmatic-api)
8. [Interoperability](#8-interoperability)
9. [Consumer Behavior for Unknown Content](#9-consumer-behavior-for-unknown-content)

---

## 1. Dual-Layer Architecture

A DESIGN.md file contains two complementary layers in a single file:

| Layer | Format | Purpose | Audience |
|-------|--------|---------|----------|
| **YAML front matter** | Structured key-value tokens between `---` fences | Normative values — exact colors, sizes, weights | Machines, build tools, agents |
| **Markdown body** | Prose organized into `##` sections | Design rationale — brand personality, guidelines, guardrails | Humans, agents (for context) |

The tokens are the source of truth for values. The prose tells agents and developers *why* those values exist and how to apply them contextually.

```md
---
name: My Design System
colors:
  primary: "#1A1C1E"
  tertiary: "#B8422E"
typography:
  h1:
    fontFamily: Public Sans
    fontSize: 3rem
---

## Overview

Architectural Minimalism meets Journalistic Gravitas. The UI evokes
a premium matte finish.

## Colors

- **Primary (#1A1C1E):** Deep ink for headlines and core text.
- **Tertiary (#B8422E):** "Boston Clay" — the sole driver for interaction.
```

---

## 2. Token Specification System

### Schema

```yaml
version: <string>          # optional, current: "alpha"
name: <string>
description: <string>      # optional
colors:
  <token-name>: <Color>
typography:
  <token-name>: <Typography>
rounded:
  <scale-level>: <Dimension>
spacing:
  <scale-level>: <Dimension | number>
components:
  <component-name>:
    <token-name>: <string | token reference>
```

### Token Types

| Type | Format | Example |
|------|--------|---------|
| **Color** | `#` + hex (sRGB) | `"#1A1C1E"` |
| **Dimension** | number + unit (`px`, `em`, `rem`) | `48px`, `-0.02em` |
| **Token Reference** | `{path.to.token}` | `{colors.primary}` |
| **Typography** | Object with font properties | See below |

### Typography Properties

| Property | Type | Description |
|----------|------|-------------|
| `fontFamily` | string | Font family name |
| `fontSize` | Dimension | Size with unit |
| `fontWeight` | number | Numeric weight (400, 700, etc.) |
| `lineHeight` | Dimension or number | With unit or unitless multiplier (recommended) |
| `letterSpacing` | Dimension | Tracking |
| `fontFeature` | string | Maps to CSS `font-feature-settings` |
| `fontVariation` | string | Maps to CSS `font-variation-settings` |

### Token References

References use curly braces and dot-notation to point to other values in the YAML tree:

```yaml
components:
  button-primary:
    backgroundColor: "{colors.tertiary}"    # resolves to #B8422E
    textColor: "{colors.on-tertiary}"
    rounded: "{rounded.sm}"
    typography: "{typography.label-caps}"    # composite reference (allowed in components)
```

Primitive token groups (`colors`, `typography`, `spacing`, `rounded`) can only reference other primitive values. The `components` section can reference both primitive and composite values (e.g., an entire typography object).

### Recommended Token Names (Non-Normative)

The spec suggests commonly used names for consistency across design systems:

- **Colors**: `primary`, `secondary`, `tertiary`, `neutral`, `surface`, `on-surface`, `error`
- **Typography**: `headline-display`, `headline-lg`, `headline-md`, `body-lg`, `body-md`, `body-sm`, `label-lg`, `label-md`, `label-sm`
- **Rounded**: `none`, `sm`, `md`, `lg`, `xl`, `full`

---

## 3. Canonical Sections

Sections use `##` headings. They can be omitted, but those present must follow this order:

| # | Section | Aliases | Purpose |
|---|---------|---------|---------|
| 1 | **Overview** | Brand & Style | Brand personality, target audience, emotional response |
| 2 | **Colors** | — | Color palettes with semantic roles |
| 3 | **Typography** | — | Typography levels (9-15 typical), font strategy |
| 4 | **Layout** | Layout & Spacing | Grid model, spacing scale, containment principles |
| 5 | **Elevation & Depth** | Elevation | Visual hierarchy (shadows, tonal layers, borders) |
| 6 | **Shapes** | — | Corner radius philosophy, shape language |
| 7 | **Components** | — | Component atoms: buttons, chips, lists, inputs, checkboxes, etc. |
| 8 | **Do's and Don'ts** | — | Practical guardrails and common pitfalls |

Each section pairs its token group with prose rationale. For example, the Colors section defines color palettes in prose and the `colors:` YAML block provides the exact hex values.

---

## 4. Component Tokens

Components map a name to a group of sub-token properties, defining the visual contract for each UI element.

### Valid Properties

| Property | Type | Maps to CSS |
|----------|------|-------------|
| `backgroundColor` | Color | `background-color` |
| `textColor` | Color | `color` |
| `typography` | Typography | Font shorthand |
| `rounded` | Dimension | `border-radius` |
| `padding` | Dimension | `padding` |
| `size` | Dimension | `width` + `height` |
| `height` | Dimension | `height` |
| `width` | Dimension | `width` |

### Variant Convention

Variants (hover, active, pressed, disabled) are expressed as separate component entries with a related key name. This keeps the schema flat and avoids nested state objects:

```yaml
components:
  button-primary:
    backgroundColor: "{colors.primary-60}"
    textColor: "{colors.primary-20}"
    rounded: "{rounded.md}"
    padding: 12px
  button-primary-hover:
    backgroundColor: "{colors.primary-70}"
  button-ghost:
    backgroundColor: rgba(255, 255, 255, 0.05)
    textColor: "{colors.primary}"
    rounded: "{rounded.xl}"
```

Agents consider all variants when generating component implementations, applying them to appropriate CSS pseudo-classes or state handlers.

---

## 5. CLI Toolchain

Install: `npm install @google/design.md` or use directly via `npx`.

### Commands

| Command | Purpose | Input | Output | Exit code |
|---------|---------|-------|--------|-----------|
| `lint` | Validate structure, tokens, contrast | DESIGN.md file (or stdin) | JSON findings | `1` if errors |
| `diff` | Compare two versions, detect regressions | Two DESIGN.md files | JSON token changes | `1` if regressions |
| `export` | Convert tokens to other formats | DESIGN.md + `--format` | Tailwind JSON or DTCG JSON | — |
| `spec` | Output the format specification | — | Markdown or JSON | — |

### `lint`

```bash
npx @google/design.md lint DESIGN.md
npx @google/design.md lint --format json DESIGN.md
cat DESIGN.md | npx @google/design.md lint -
```

Output example:

```json
{
  "findings": [
    {
      "severity": "warning",
      "path": "components.button-primary",
      "message": "textColor (#ffffff) on backgroundColor (#1A1C1E) has contrast ratio 15.42:1 — passes WCAG AA."
    }
  ],
  "summary": { "errors": 0, "warnings": 1, "info": 1 }
}
```

### `diff`

```bash
npx @google/design.md diff DESIGN.md DESIGN-v2.md
```

Output example:

```json
{
  "tokens": {
    "colors": { "added": ["accent"], "removed": [], "modified": ["tertiary"] },
    "typography": { "added": [], "removed": [], "modified": [] }
  },
  "regression": false
}
```

Exit code `1` if regressions are detected (more errors/warnings in the "after" file).

### `export`

```bash
# Tailwind theme config
npx @google/design.md export --format tailwind DESIGN.md > tailwind.theme.json

# W3C Design Tokens (DTCG)
npx @google/design.md export --format dtcg DESIGN.md > tokens.json
```

### `spec`

```bash
npx @google/design.md spec                  # Full spec as markdown
npx @google/design.md spec --rules          # Spec + linting rules table
npx @google/design.md spec --rules-only --format json  # Rules only as JSON
```

The `spec` command is designed for injecting format context into AI agent prompts, giving them the full specification to follow.

---

## 6. Linting Rules

Seven built-in rules run against a parsed DESIGN.md:

| Rule | Severity | What it checks |
|------|----------|----------------|
| `broken-ref` | **error** | Token references (`{colors.primary}`) that don't resolve to any defined token |
| `missing-primary` | warning | Colors are defined but no `primary` color exists — agents will auto-generate one |
| `contrast-ratio` | warning | Component `backgroundColor`/`textColor` pairs below WCAG AA minimum (4.5:1) |
| `orphaned-tokens` | warning | Color tokens defined but never referenced by any component |
| `missing-typography` | warning | Colors defined but no typography tokens — agents will use default fonts |
| `section-order` | warning | Sections appear out of the canonical order defined by the spec |
| `token-summary` | info | Summary of how many tokens are defined in each section |
| `missing-sections` | info | Optional sections (spacing, rounded) absent when other tokens exist |

### CI Integration Pattern

```bash
# In a CI pipeline — fail on errors, warn on warnings
npx @google/design.md lint DESIGN.md
if [ $? -ne 0 ]; then
  echo "DESIGN.md has validation errors"
  exit 1
fi
```

### PR Review Pattern

```bash
# Compare the PR's DESIGN.md against the base branch version
npx @google/design.md diff main:DESIGN.md HEAD:DESIGN.md
# Exit code 1 if the PR introduces regressions (new errors/warnings)
```

---

## 7. Programmatic API

The linter is available as a TypeScript/JavaScript library:

```typescript
import { lint } from '@google/design.md/linter';

const report = lint(markdownString);

report.findings;       // Finding[] — individual lint results
report.summary;        // { errors: number, warnings: number, info: number }
report.designSystem;   // Parsed DesignSystemState — the full token tree
```

This enables:
- Custom build scripts that read tokens programmatically
- Integration into existing linting pipelines (e.g., alongside ESLint)
- Custom validation rules beyond the 7 built-in ones
- Token extraction for code generation

---

## 8. Interoperability

### W3C Design Token Format (DTCG)

DESIGN.md tokens are inspired by the [W3C Design Token Format Module](https://tr.designtokens.org/format/). The `export --format dtcg` command converts to the standard `tokens.json` format, enabling round-trip interop with:

- **Figma Variables** — Figma can import/export DTCG tokens via plugins
- **Style Dictionary** — Amazon's multi-platform token transformation tool natively reads DTCG
- **Token Studio** — Figma plugin that reads/writes DTCG tokens

### Tailwind CSS

The `export --format tailwind` command generates a Tailwind theme configuration object from DESIGN.md tokens. This can be used directly in `tailwind.config.js` or as a basis for CSS custom property generation.

### Conversion Flow

```
DESIGN.md
  ├── export --format tailwind → tailwind.theme.json → tailwind.config.js
  ├── export --format dtcg     → tokens.json → Style Dictionary → any platform
  └── programmatic API          → custom scripts → any format
```

---

## 9. Consumer Behavior for Unknown Content

The spec defines graceful handling for content beyond the formal schema:

| Scenario | Behavior | Example |
|----------|----------|---------|
| Unknown section heading | Preserve; do not error | `## Iconography` |
| Unknown color token name | Accept if value is valid hex | `surface-container-high: '#ede7dd'` |
| Unknown typography token name | Accept as valid typography | `telemetry-data` |
| Unknown spacing value | Accept; store as string if not valid dimension | `grid-columns: '5'` |
| Unknown component property | Accept with warning | `borderColor` |
| Duplicate section heading | **Error**; reject the file | Two `## Colors` headings |

This tolerance model means DESIGN.md can accommodate domain-specific extensions (e.g., custom sections for animation tokens or icon guidelines) without breaking tooling.

---

## References

- [DESIGN.md README](https://github.com/nichochar/design.md/blob/main/README.md) — CLI reference, installation, examples
- [DESIGN.md Spec](https://github.com/nichochar/design.md/blob/main/docs/spec.md) — Full format specification
- [W3C Design Tokens Format Module](https://tr.designtokens.org/format/) — The standard DESIGN.md's references are inspired by
- [Example: Atmospheric Glass](https://github.com/nichochar/design.md/blob/main/examples/atmospheric-glass/DESIGN.md) — Glassmorphism dark theme with 50+ color tokens
- [Example: Paws and Paths](https://github.com/nichochar/design.md/blob/main/examples/paws-and-paths/DESIGN.md) — Warm, approachable pet-care design
- [Example: Totality Festival](https://github.com/nichochar/design.md/blob/main/examples/totality-festival/DESIGN.md) — Bold event branding
