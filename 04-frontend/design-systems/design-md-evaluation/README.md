# DESIGN.md — Format Specification for Design Systems

## TL;DR

DESIGN.md is a Google-authored, open-format specification that encodes a visual identity as machine-readable YAML tokens + human-readable markdown prose in a single file. It ships with a CLI toolchain (lint, diff, export) and is the first design system format explicitly optimized for AI coding agents.

## Status

| Field | Value |
|-------|-------|
| **Decision** | Evaluating |
| **Version** | alpha (spec, token schema, and CLI under active development) |
| **Source** | [github.com/nichochar/design.md](https://github.com/nichochar/design.md) |
| **Package** | `@google/design.md` (npm) |
| **Last reviewed** | 2026-04-29 |

## What is DESIGN.md?

A DESIGN.md file combines two layers:

1. **YAML front matter** — Machine-readable design tokens (colors, typography, spacing, border-radius, component tokens) delimited by `---` fences. These are the normative values.
2. **Markdown body** — Human-readable design rationale organized into canonical sections (Overview, Colors, Typography, Layout, Elevation, Shapes, Components, Do's and Don'ts). The prose explains *why* the tokens exist and how to apply them.

An agent reading a DESIGN.md file can produce a UI that matches the design system without further instruction. A human reading the same file understands the brand personality, decision rationale, and guardrails.

The format also ships with a CLI:

- `lint` — Validate structure, catch broken token references, check WCAG contrast ratios
- `diff` — Compare two versions, detect token-level regressions
- `export` — Convert tokens to Tailwind theme config or W3C DTCG `tokens.json`
- `spec` — Output the format spec (useful for injecting into agent prompts)

## Research Documents

| Document | Description |
|----------|-------------|
| [features-overview.md](./features-overview.md) | Full feature map — token schema, CLI tooling, linting rules, programmatic API, interoperability |
| [benefits-tradeoffs.md](./benefits-tradeoffs.md) | Structured analysis of benefits and tradeoffs with evidence and mitigations |
| [alternatives-comparison.md](./alternatives-comparison.md) | Short comparison vs W3C DTCG, Style Dictionary, Figma Variables, Tailwind config |
| [metrics-and-learning.md](./metrics-and-learning.md) | Metrics to track, learning resources, suggested hands-on experiments |

## SNDQ Application

For how DESIGN.md maps to the SNDQ monorepo UI migration (5-phase plan), see:

- [design-md-integration.md](../../../12-sndq/frontend/restructure/monorepo-ui-design-system/design-md-integration.md) — Phase-by-phase analysis, token mapping strategy, component token workflow, CI integration points

## Quick Verdict

> *To be filled after completing hands-on experiments from [metrics-and-learning.md](./metrics-and-learning.md).*

**Adopt / Defer / Reject**: _pending_

**Reasoning**: _pending_

**Key factors**:
- [ ] Token coverage matches current CSS variable set
- [ ] Export accuracy verified against existing Tailwind config
- [ ] Agent output quality tested with real component briefs
- [ ] Alpha-stage risk assessed for production adoption timeline
