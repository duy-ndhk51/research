# DESIGN.md Integration Planning

Planning document for integrating [DESIGN.md](https://github.com/nichochar/design.md) into the SNDQ monorepo UI migration. Determines WHAT to do and WHEN in the 5-phase migration, without prescribing exact commits.

**Created**: 2026-04-29
**Status**: Planning
**General research**: [04-frontend/design-systems/design-md-evaluation/](../../../../04-frontend/design-systems/design-md-evaluation/README.md) — full features, benefits/tradeoffs, alternatives, metrics
**Migration plan**: [migration-plan.md](./migration-plan.md) — 5-phase migration this document maps into
**Architecture**: [README.md](./README.md) — target monorepo structure

---

## Table of Contents

1. [Overview](#1-overview)
2. [Phase-by-Phase Analysis](#2-phase-by-phase-analysis)
3. [Recommended Timing](#3-recommended-timing)
4. [Token Mapping Strategy](#4-token-mapping-strategy)
5. [Component Token Workflow](#5-component-token-workflow)
6. [CI Integration Points](#6-ci-integration-points)
7. [Effort Estimates](#7-effort-estimates)
8. [Dependencies](#8-dependencies)
9. [Open Questions](#9-open-questions)

---

## 1. Overview

### What is DESIGN.md?

A Google-authored format specification that encodes a design system as machine-readable YAML tokens + human-readable markdown prose in a single file. It ships with a CLI (lint, diff, export to Tailwind/DTCG) and is purpose-built for AI coding agents.

For full details, see the [general research](../../../../04-frontend/design-systems/design-md-evaluation/README.md).

### Why consider it for SNDQ?

The SNDQ migration plan already involves:
- Extracting design tokens from `globals.css` into `@sndq/config/tailwind/` (Phase 1b/2)
- Standardizing components in batches with quality gates (Phase 3)
- Maintaining token consistency across `sndq-fe`, `apps/prototype`, and `apps/docs` (all phases)

DESIGN.md could serve as a **specification layer above the CSS tokens** — the authoritative source that describes not just the values but the rationale, validates token integrity, and generates exports.

### What DESIGN.md does NOT replace

- `@sndq/config/tailwind/tokens.css` — Still needed as the CSS runtime artifact
- `@sndq/config/tailwind/components.css` — DESIGN.md component tokens only cover 8 properties; component CSS classes remain
- `:root` / `.dark` theme switching — DESIGN.md has no theme variant support
- Tailwind JIT compilation — DESIGN.md is build-time/design-time only

---

## 2. Phase-by-Phase Analysis

### Phase 1a: Structural Foundation

**DESIGN.md relevance**: None.

Phase 1a creates monorepo infrastructure (tsconfig, ESLint, Prettier packages). No design tokens or visual system changes. DESIGN.md has nothing to contribute here.

### Phase 1b / Phase 2: Token Extraction + Prototype Integration

**DESIGN.md relevance**: Medium-High.

This is when tokens are extracted from `globals.css` into `@sndq/config/tailwind/tokens.css`. DESIGN.md could be introduced here as the specification that documents the token set being extracted.

**What DESIGN.md adds at this point**:
- A human-readable document explaining the Briicks color system, type scale, spacing philosophy
- Machine-validated token references (the `broken-ref` lint rule catches errors)
- A Tailwind export that can be compared against the manually extracted `tokens.css` for accuracy
- WCAG contrast checks on any component tokens defined early

**What it does NOT help with**:
- The actual CSS extraction work — `tokens.css` must still be authored manually (or generated from DESIGN.md export, but the export only covers token values, not CSS custom property syntax with `@theme inline`)
- Dark mode / shadcn theme variables — DESIGN.md cannot express `:root` / `.dark` variants
- Component CSS classes (`.sndq-btn`, `.sndq-control`) — these are beyond DESIGN.md's scope

**Risk at this point**: Writing a DESIGN.md before the token set is stabilized means maintaining an additional artifact during a period of active change. Tokens are being reorganized (Briicks primitives → shared tokens, UI-V2 semantic tokens joining). The DESIGN.md would need frequent updates.

### Phase 3: Standardize + Graduate to Package

**DESIGN.md relevance**: High.

This is where DESIGN.md provides the most value. Each standardization batch defines a component's visual contract — exactly what DESIGN.md component tokens express.

**What DESIGN.md adds at this point**:
- **Component tokens as graduation criteria**: Add "component tokens defined in DESIGN.md" to the [Definition of Standardized](./migration-plan.md#6-phase-3-standardize--graduate-to-package) checklist
- **Machine-verifiable contracts**: When a color token is renamed or removed, `broken-ref` immediately flags which components break
- **Batch-level diffing**: After each batch, run `diff` against the previous version to track how the design system evolves
- **WCAG per component**: Every graduated component's `backgroundColor`/`textColor` pair is checked for contrast compliance
- **Agent-assisted standardization**: Agents can read DESIGN.md when implementing or reviewing component standardization work

**Integration with batch workflow**:

```
Per-batch addition to the standardization checklist:
1. Standardize in apps/prototype/  (existing)
2. Graduate to packages/ui-v2/     (existing)
3. Define component tokens in DESIGN.md   ← NEW
4. Run `lint` — 0 errors, 0 contrast warnings
5. Run `diff` against previous version — review changes
6. Deprecate legacy counterparts    (existing)
```

### Phase 4: Module-by-Module Migration

**DESIGN.md relevance**: Low.

Phase 4 is about changing import paths and updating prop usage across `sndq-fe` modules. DESIGN.md doesn't directly help with import migration. However, agents performing the migration can reference DESIGN.md to understand the target component's intended appearance and behavior.

### Phase 5: Cleanup

**DESIGN.md relevance**: Low.

Phase 5 removes legacy directories and the old submodule. DESIGN.md is not involved. Post-cleanup, DESIGN.md becomes the ongoing living document for the finalized design system.

---

## 3. Recommended Timing

Based on the phase analysis, the recommended approach is a **two-step introduction**:

### Step 1: Create DESIGN.md during Phase 2 (tokens only)

**When**: After tokens are extracted to `@sndq/config/tailwind/tokens.css` and UI-V2 semantic tokens are added.

**What**: Write a DESIGN.md with:
- YAML front matter: all primitive tokens (Briicks colors, type scale, spacing, radius) + UI-V2 semantic tokens
- Markdown prose: Overview (SNDQ brand/product personality), Colors (palette rationale), Typography (font strategy), Layout (spacing philosophy), Shapes (radius philosophy)
- No component tokens yet

**Why this timing**:
- The token set is freshly extracted and organized — writing DESIGN.md now documents the canonical form while it's fresh
- The export roundtrip (`export --format tailwind` vs `tokens.css`) validates the extraction accuracy
- The `lint` command catches any broken references or missing tokens immediately
- The prose sections capture design rationale that would otherwise exist only in developers' heads

**Effort**: ~2-3 hours (see [Effort Estimates](#7-effort-estimates))

### Step 2: Add component tokens during Phase 3 (per batch)

**When**: As each batch is standardized and graduated.

**What**: For each batch:
1. Add component token entries to the DESIGN.md `components:` section
2. Define `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `height` per component + variants
3. Run `lint` and `diff`
4. Update prose in the Components section if needed

**Why this timing**:
- Component tokens are meaningless without stable, graduated components
- Defining tokens per batch keeps the work incremental and reviewable
- The `broken-ref` rule provides ongoing validation as the token set evolves

**Effort**: ~30-60 minutes per batch

### Why NOT earlier (Phase 1a/1b)?

- Phase 1a has no design tokens at all
- Phase 1b only extracts a subset of Briicks primitives — the full token set doesn't exist until Phase 2 when UI-V2 semantic tokens join. Writing DESIGN.md against a partial token set creates maintenance burden

### Why NOT later (Phase 4/5)?

- Phase 3 is the window where component contracts are being defined — exactly when DESIGN.md component tokens are most useful
- Waiting until Phase 4/5 loses the "document while it's fresh" benefit and the CI validation during the highest-risk phase

---

## 4. Token Mapping Strategy

How to map SNDQ's current CSS custom properties to DESIGN.md YAML tokens.

### Briicks Primitive Tokens

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

### UI-V2 Semantic Tokens

| CSS variable pattern | DESIGN.md token group | Notes |
|---------------------|----------------------|-------|
| `--sndq-action`, `--sndq-action-hover`, etc. | `colors.sndq-action`, `colors.sndq-action-hover` | Semantic role tokens, reference Briicks primitives |
| `--sndq-surface`, `--sndq-surface-subtle`, etc. | `colors.sndq-surface`, etc. | Surface hierarchy |
| `--sndq-text`, `--sndq-text-secondary`, etc. | `colors.sndq-text`, etc. | Text hierarchy |
| `--sndq-border`, `--sndq-border-strong`, etc. | `colors.sndq-border`, etc. | Border variations |
| `--sndq-h-sm`, `--sndq-h`, `--sndq-h-lg` | `spacing.control-sm`, `spacing.control`, `spacing.control-lg` | Control sizing |
| `--sndq-r-{xs-full}` | `rounded.sndq-{xs-full}` | Component radius scale |
| `--sndq-shadow-{xs-md}` | Cannot express in DESIGN.md | No shadow token type — document in prose |

### What cannot be mapped

| CSS concept | Why | Workaround |
|-------------|-----|------------|
| Box shadows (`--sndq-shadow-*`) | No shadow token type in DESIGN.md | Document in Elevation & Depth prose section |
| Dark mode variables (`.dark { ... }`) | No theme variant support | Keep in CSS; document light-mode values in DESIGN.md |
| Component CSS classes (`.sndq-btn`, etc.) | DESIGN.md component tokens only cover 8 properties | Define what can be expressed (colors, radius, padding, height); document the rest in Components prose |
| Animation keyframes | No animation token type | Document in a custom `## Animations` section (DESIGN.md preserves unknown sections) |

---

## 5. Component Token Workflow

How component tokens integrate with the Phase 3 batch standardization process.

### Per-batch workflow (extended)

The existing Phase 3 [per-batch workflow](./migration-plan.md#6-phase-3-standardize--graduate-to-package) gains two additional steps:

```
1. Standardize in apps/prototype/               (existing)
2. Graduate to packages/ui-v2/                   (existing)
3. Define component tokens in DESIGN.md          ← NEW
   - Add YAML entries for each component + variants
   - Reference existing color/typography/spacing tokens
4. Validate                                      ← NEW
   - Run: npx @google/design.md lint DESIGN.md
   - Check: 0 errors, 0 contrast warnings for new components
   - Run: npx @google/design.md diff DESIGN-prev.md DESIGN.md
   - Review: token changes match expected batch scope
5. Deprecate legacy counterparts                 (existing)
6. Verify                                        (existing)
```

### Batch 1 component tokens (example)

After Batch 1 (Button, Input, Badge, Select, Dialog, Sheet) graduates:

```yaml
components:
  # Button
  button-primary:
    backgroundColor: "{colors.sndq-action}"
    textColor: "{colors.sndq-action-fg}"
    rounded: "{rounded.sndq-md}"
    padding: 12px
    height: "{spacing.control}"
  button-primary-hover:
    backgroundColor: "{colors.sndq-action-hover}"
  button-secondary:
    backgroundColor: "{colors.sndq-surface}"
    textColor: "{colors.sndq-text}"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"
  button-ghost:
    backgroundColor: transparent
    textColor: "{colors.sndq-text}"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"
  button-destructive:
    backgroundColor: "{colors.error-500}"
    textColor: "#FFFFFF"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"

  # Input
  input-default:
    backgroundColor: "{colors.sndq-surface}"
    textColor: "{colors.sndq-text}"
    typography: "{typography.body-md}"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"

  # Badge
  badge-neutral:
    backgroundColor: "{colors.neutral-100}"
    textColor: "{colors.neutral-700}"
    rounded: "{rounded.sndq-full}"
  badge-success:
    backgroundColor: "{colors.success-100}"
    textColor: "{colors.success-700}"
    rounded: "{rounded.sndq-full}"
  badge-error:
    backgroundColor: "{colors.error-100}"
    textColor: "{colors.error-700}"
    rounded: "{rounded.sndq-full}"
```

### What component tokens cannot express

Per the [benefits-tradeoffs analysis](../../../../04-frontend/design-systems/design-md-evaluation/benefits-tradeoffs.md#22-limited-component-properties-8-only), DESIGN.md component tokens only support 8 properties. SNDQ components also use:

| Missing property | Used by | Workaround |
|------------------|---------|------------|
| `borderColor` | Input, Select, Card | Document in Components prose |
| `borderWidth` | Input (focus ring) | Document in Components prose |
| `boxShadow` | Card, Dialog, Sheet, DropdownMenu | Document in Elevation prose |
| `gap` | ButtonGroup, ToggleGroup | Document in Layout prose |
| `opacity` | Disabled states | Document in Do's and Don'ts |
| `backdropFilter` | Dialog overlay, Sheet overlay | Document in Elevation prose |

---

## 6. CI Integration Points

### Phase 2: Basic validation

Add to the monorepo CI pipeline after DESIGN.md is created:

```yaml
# .github/workflows/design-system.yml (or add to existing CI)
- name: Lint DESIGN.md
  run: npx @google/design.md lint DESIGN.md
```

This catches:
- Broken token references when tokens are renamed/removed
- Missing primary color
- Structural issues (duplicate sections, wrong section order)

### Phase 3: Regression gating

Add diff-based regression detection to PRs that touch `DESIGN.md`:

```yaml
- name: Check DESIGN.md regressions
  if: contains(github.event.pull_request.changed_files, 'DESIGN.md')
  run: |
    git show origin/dev:DESIGN.md > /tmp/DESIGN-base.md
    npx @google/design.md diff /tmp/DESIGN-base.md DESIGN.md
```

Exit code 1 blocks the PR if the change introduces new errors or warnings (regressions).

### Optional: Export drift detection

Monthly or per-release, verify DESIGN.md tokens match the actual `tokens.css`:

```bash
npx @google/design.md export --format tailwind DESIGN.md > /tmp/generated-theme.json
# Custom script to compare generated theme against @sndq/config/tailwind/tokens.css
```

---

## 7. Effort Estimates

| Task | Phase | Effort | Dependencies |
|------|-------|--------|--------------|
| Write DESIGN.md (tokens + prose, no components) | Phase 2 | 2-3 hours | Token extraction complete |
| Add to CI (lint) | Phase 2 | 30 min | DESIGN.md exists |
| Batch 1 component tokens (Button, Input, Badge, Select, Dialog, Sheet) | Phase 3 | 45-60 min | Batch 1 graduated |
| Batch 2 component tokens (Card, Tabs, Tooltip, EmptyState, Skeleton) | Phase 3 | 30-45 min | Batch 2 graduated |
| Batch 3 component tokens (remaining) | Phase 3 | 30-45 min | Batch 3 graduated |
| Add diff regression check to CI | Phase 3 | 30 min | DESIGN.md in CI |
| Export drift detection script | Phase 3+ | 1-2 hours | DESIGN.md covers full token set |

**Total incremental effort**: ~6-8 hours spread across Phases 2-3.

---

## 8. Dependencies

### Before creating DESIGN.md (Phase 2)

- [ ] Phase 1a merged (monorepo structure exists)
- [ ] Token extraction to `@sndq/config/tailwind/tokens.css` complete (Briicks primitives)
- [ ] UI-V2 semantic tokens added to `tokens.css`
- [ ] `@google/design.md` added as devDependency in root `package.json`

### Before adding component tokens (Phase 3)

- [ ] DESIGN.md exists with token-only YAML (from Phase 2 step)
- [ ] Batch N components graduated to `packages/ui-v2/`
- [ ] Component prop interfaces stable (no breaking changes expected)

### Before CI integration

- [ ] DESIGN.md committed to the repository
- [ ] `@google/design.md` available in CI environment (via devDependency or npx)

---

## 9. Open Questions

Questions to resolve before or during implementation:

| # | Question | Context | Resolution path |
|---|----------|---------|-----------------|
| 1 | Where does DESIGN.md live in the repo? | Options: monorepo root, `packages/config/`, `packages/ui-v2/` | Recommendation: **monorepo root** (`sndq/DESIGN.md`) — it describes the entire design system, not just one package |
| 2 | Should the Tailwind export replace manual `tokens.css` authoring? | If yes, DESIGN.md becomes the source of truth and `tokens.css` is generated. If no, they coexist and drift is monitored. | Run [Experiment 4](../../../../04-frontend/design-systems/design-md-evaluation/metrics-and-learning.md#experiment-4-export-roundtrip-test) to determine export accuracy. If high accuracy, consider generated `tokens.css`. |
| 3 | How to handle the alpha-stage risk? | The spec may change. Pinning helps but doesn't prevent deprecation. | Pin version, wrap CLI calls in npm scripts, monitor changelog. Accept the risk given the tool is from Google. |
| 4 | Should `@google/design.md` be a root devDep or per-package? | It's used for linting/CI, not runtime | Recommendation: **root devDependency** — it's a development tool, not a package dependency |
| 5 | How to handle dark mode tokens? | DESIGN.md has no theme variant support. SNDQ uses `:root` / `.dark`. | Keep dark mode in CSS. DESIGN.md documents the light-mode canonical values. Add a custom `## Theming` prose section explaining the dark mode strategy. |

---

## Related Documents

- [General DESIGN.md Research](../../../../04-frontend/design-systems/design-md-evaluation/README.md) — features, benefits/tradeoffs, alternatives, metrics
- [Migration Plan](./migration-plan.md) — 5-phase migration this document maps into
- [Architecture](./README.md) — target monorepo structure
- [Component Lifting Process](./component-lifting-process.md) — 4-tier promotion model
- [Phase 2 Execution](./phase-2-execution.md) — step-by-step for the phase where DESIGN.md is introduced
