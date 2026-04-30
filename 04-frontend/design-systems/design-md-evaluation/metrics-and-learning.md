# DESIGN.md — Metrics & Learning Resources

What to measure when evaluating DESIGN.md, resources for deepening understanding, and hands-on experiments to validate the tool before making an adoption decision.

---

## Table of Contents

1. [Evaluation Metrics](#1-evaluation-metrics)
2. [Learning Resources](#2-learning-resources)
3. [Hands-On Experiments](#3-hands-on-experiments)
4. [Ongoing Metrics (Post-Adoption)](#4-ongoing-metrics-post-adoption)

---

## 1. Evaluation Metrics

Metrics to gather **before** making an adopt/defer/reject decision. Run these during the hands-on experiments.

| Metric | How to measure | Target | Why it matters |
|--------|---------------|--------|----------------|
| **Token coverage** | Count CSS variables in your `tokens.css` vs tokens defined in DESIGN.md | 100% parity | Validates that DESIGN.md can express your full token set |
| **Export accuracy** | `export --format tailwind` output diffed against current Tailwind config / CSS | No meaningful diff in values | Proves the export pipeline produces usable output |
| **Lint validity** | `lint` on your DESIGN.md — count errors and warnings | 0 errors, ≤ 5 warnings on first pass | Shows the file is structurally correct and tokens are well-formed |
| **WCAG compliance** | Count `contrast-ratio` warnings from `lint` | 0 failing component pairs | Validates accessibility of component token definitions |
| **Broken references** | Count `broken-ref` errors from `lint` | 0 | All component token references resolve correctly |
| **Agent output quality** | Give an agent your DESIGN.md + a component brief, evaluate the generated UI | Matches design intent without manual correction | The primary value proposition — does it actually help agents? |
| **Authoring time** | Time to write DESIGN.md for your existing token set | < 2 hours for initial creation | Validates the authoring experience is not burdensome |
| **Property coverage gap** | List component CSS properties that cannot be expressed as DESIGN.md component tokens | Identify which properties are missing | Quantifies the severity of the 8-property limitation |

---

## 2. Learning Resources

### Primary Sources

| Resource | Type | What you learn |
|----------|------|----------------|
| [DESIGN.md README](https://github.com/nichochar/design.md/blob/main/README.md) | Documentation | CLI commands, installation, linting rules, programmatic API |
| [DESIGN.md Spec (docs/spec.md)](https://github.com/nichochar/design.md/blob/main/docs/spec.md) | Specification | Token schema, section order, component properties, consumer behavior |
| `npx @google/design.md spec` | CLI output | The full spec formatted for agent prompt injection |
| `npx @google/design.md spec --rules` | CLI output | Spec + all linting rules in one document |

### Example DESIGN.md Files

| Example | Style | Token count | Notable features |
|---------|-------|-------------|------------------|
| [Atmospheric Glass](https://github.com/nichochar/design.md/blob/main/examples/atmospheric-glass/DESIGN.md) | Dark glassmorphism | 50+ colors, 6 typography, 6 rounded, 5 spacing, 10 components | Large color palette, `rgba()` in component tokens, composite `typography` references |
| [Paws and Paths](https://github.com/nichochar/design.md/blob/main/examples/paws-and-paths/DESIGN.md) | Warm, approachable | Smaller token set | Minimal, focused design system |
| [Totality Festival](https://github.com/nichochar/design.md/blob/main/examples/totality-festival/DESIGN.md) | Bold event branding | Medium token set | Strong brand personality in prose |

Each example also includes an exported `tailwind.config.js` and `design_tokens.json` (DTCG), demonstrating the full export pipeline.

### Background Reading

| Resource | Type | Relevance |
|----------|------|-----------|
| [W3C Design Tokens Format Module](https://tr.designtokens.org/format/) | W3C Community Draft | The standard DESIGN.md's token references are inspired by. Essential for understanding DTCG interop. |
| [Style Dictionary v4 Documentation](https://amzn.github.io/style-dictionary/) | Documentation | The leading multi-platform token transformation tool. Relevant if considering the DESIGN.md → DTCG → Style Dictionary pipeline. |
| [Tailwind CSS Theme Configuration](https://tailwindcss.com/docs/theme) | Documentation | Understand what the `export --format tailwind` output maps to. |
| [WCAG 2.1 Contrast Requirements](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html) | W3C Guideline | Context for the `contrast-ratio` linting rule (4.5:1 AA minimum). |

### Source Code Exploration

The CLI implementation reveals how each feature works internally:

| Path (in the design.md repo) | What it contains |
|-------------------------------|------------------|
| `packages/cli/src/linter/linter/rules/` | All 7 linting rule implementations |
| `packages/cli/src/linter/tailwind/handler.ts` | Tailwind export logic |
| `packages/cli/src/linter/dtcg/handler.ts` | DTCG export logic |
| `packages/cli/src/linter/parser/handler.ts` | YAML + Markdown parser |
| `packages/cli/src/linter/model/spec.ts` | Token type definitions and schema |
| `packages/cli/src/commands/` | CLI command implementations (lint, diff, export, spec) |

---

## 3. Hands-On Experiments

Four experiments to validate DESIGN.md before making an adoption decision. Each builds on the previous one.

### Experiment 1: Write a Minimal DESIGN.md

**Goal**: Validate that your existing token set can be expressed in the format.

**Steps**:
1. Pick 10-15 representative tokens from your CSS (a few colors, 2-3 typography levels, spacing scale, a couple of radius values)
2. Write them as YAML front matter in a new `DESIGN.md` file
3. Add brief prose for the Overview and Colors sections
4. Run `npx @google/design.md lint DESIGN.md`
5. Fix any errors, note any warnings

**Record**:
- Time to author (minutes)
- Lint findings (errors, warnings, info)
- Any tokens you could not express in the schema

### Experiment 2: Test the Diff Pipeline

**Goal**: Validate regression detection for design system changes.

**Steps**:
1. Copy your DESIGN.md to `DESIGN-v2.md`
2. In v2, change a color value, add a new token, remove an existing one
3. Run `npx @google/design.md diff DESIGN.md DESIGN-v2.md`
4. Examine the JSON output — does it accurately report the changes?
5. Introduce a `broken-ref` in v2 (reference a deleted token) and re-run diff

**Record**:
- Diff output accuracy (all changes detected?)
- Regression detection (exit code 1 when broken ref introduced?)

### Experiment 3: Test Agent Output Quality

**Goal**: Validate that DESIGN.md actually improves agent-generated UI.

**Steps**:
1. Pick a component your project needs (e.g., a card, a form, a dashboard widget)
2. Write a brief: "Build a [component] using the design system in DESIGN.md"
3. Give the DESIGN.md file + the brief to an AI agent
4. Evaluate the output: Does it use the correct colors? Typography? Spacing? Component tokens?
5. Repeat without DESIGN.md (just a text description) and compare quality

**Record**:
- Output accuracy with DESIGN.md (1-5 scale)
- Output accuracy without DESIGN.md (1-5 scale)
- Specific improvements or regressions

### Experiment 4: Export Roundtrip Test

**Goal**: Validate the Tailwind export pipeline against your actual configuration.

**Steps**:
1. Write a DESIGN.md that covers your full token set (expand from Experiment 1)
2. Run `npx @google/design.md export --format tailwind DESIGN.md > generated-theme.json`
3. Compare `generated-theme.json` against your current Tailwind config / `tokens.css`
4. Note any values that differ, are missing, or are incorrectly mapped
5. Also run `npx @google/design.md export --format dtcg DESIGN.md > tokens.json` and inspect

**Record**:
- Token count: generated vs actual
- Value accuracy (exact matches, close matches, mismatches)
- Properties that the export could not handle

---

## 4. Ongoing Metrics (Post-Adoption)

If DESIGN.md is adopted, track these metrics over time to measure the health of the design system specification.

| Metric | Frequency | Tool | Target |
|--------|-----------|------|--------|
| **Lint errors** | Every PR (CI) | `npx @google/design.md lint` | 0 errors |
| **Lint warnings** | Weekly review | `npx @google/design.md lint` | Trending downward |
| **Regression count** | Every PR touching DESIGN.md | `npx @google/design.md diff` | 0 regressions |
| **Orphaned tokens** | Monthly cleanup | `orphaned-tokens` lint rule | 0 |
| **WCAG violations** | Every PR (CI) | `contrast-ratio` lint rule | 0 |
| **Component token coverage** | Per standardization batch | Manual count: components with tokens / total graduated components | 100% for graduated |
| **Token-CSS drift** | Monthly | Export → diff against `tokens.css` | 0 meaningful diffs |
| **Agent adoption** | Quarterly | Survey: are agents using DESIGN.md effectively? | Positive trend |
