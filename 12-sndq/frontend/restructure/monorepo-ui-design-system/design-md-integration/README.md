# DESIGN.md Integration Planning

Planning document for integrating [DESIGN.md](https://github.com/google-labs-code/design.md) into the SNDQ monorepo UI migration. Determines WHAT to do and WHEN in the 5-phase migration, without prescribing exact commits.

**Created**: 2026-04-29
**Status**: In progress — Commit 19 in [phase-3-batch-1-execution.md](../phase-3-batch-1-execution.md#commit-19-add-designmd-specification-and-cli-toolchain)
**General research**: [04-frontend/design-systems/design-md-evaluation/](../../../../04-frontend/design-systems/design-md-evaluation/README.md) — full features, benefits/tradeoffs, alternatives, metrics
**Migration plan**: [migration-plan.md](../migration-plan.md) — 5-phase migration this document maps into
**Architecture**: [README.md](../README.md) — target monorepo structure

---

## What is DESIGN.md?

A Google-authored format specification that encodes a design system as machine-readable YAML tokens + human-readable markdown prose in a single file. It ships with a CLI (lint, diff, export to Tailwind/DTCG) and is purpose-built for AI coding agents.

For full details, see the [general research](../../../../04-frontend/design-systems/design-md-evaluation/README.md).

## Why consider it for SNDQ?

The SNDQ migration plan already involves:
- Extracting design tokens from `globals.css` into `@sndq/config/tailwind/` (Phase 1b/2)
- Standardizing components in batches with quality gates (Phase 3)
- Maintaining token consistency across `sndq-fe`, `apps/ui-v2-dev`, and `apps/docs` (all phases)

DESIGN.md could serve as a **specification layer above the CSS tokens** — the authoritative source that describes not just the values but the rationale, validates token integrity, and generates exports.

## What DESIGN.md does NOT replace

- `@sndq/config/tailwind/tokens.css` — Still needed as the CSS runtime artifact
- `@sndq/config/tailwind/components.css` — DESIGN.md component tokens only cover 8 properties; component CSS classes remain
- `:root` / `.dark` theme switching — DESIGN.md has no theme variant support
- Tailwind JIT compilation — DESIGN.md is build-time/design-time only

---

## Document Index

| Document | Description |
|----------|-------------|
| [Phase-by-Phase Analysis](./phase-analysis.md) | DESIGN.md relevance per migration phase (1a → 5) |
| [Recommended Timing](./timing.md) | Two-step introduction strategy and rationale |
| [Token Mapping Strategy](./token-mapping.md) | CSS custom properties → DESIGN.md YAML mapping |
| [Component Token Workflow](./component-workflow.md) | Per-batch standardization integration |
| [CI Integration Points](./ci-integration.md) | Lint, diff regression, export drift detection |
| [Effort & Dependencies](./effort-and-dependencies.md) | Estimates, prerequisites, resolved questions |

---

## Related Documents

- [General DESIGN.md Research](../../../../04-frontend/design-systems/design-md-evaluation/README.md) — features, benefits/tradeoffs, alternatives, metrics
- [Migration Plan](../migration-plan.md) — 5-phase migration this document maps into
- [Architecture](../README.md) — target monorepo structure
- [Component Lifting Process](../component-lifting-process.md) — 4-tier promotion model
- [Phase 2 Execution](../phase-2-execution.md) — step-by-step for token extraction phase
- [Phase 3, Batch 1 Execution — Commit 19](../phase-3-batch-1-execution.md#commit-19-add-designmd-specification-and-cli-toolchain) — step-by-step for DESIGN.md creation
