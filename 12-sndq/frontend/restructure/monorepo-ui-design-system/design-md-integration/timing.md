# Recommended Timing

Based on the [phase analysis](./phase-analysis.md), the recommended approach is a **two-step introduction**.

---

## Step 1: Create DESIGN.md ~~during Phase 2~~ → executed as Commit 19 in Phase 3, Batch 1

> **Update (2026-05-15)**: Step 1 is being executed as **Commit 19** in [phase-3-batch-1-execution.md](../phase-3-batch-1-execution.md#commit-19-add-designmd-specification-and-cli-toolchain), not as a separate Phase 2 step. This is because (a) the token set is already stable (Briicks primitives + UI-V2 semantic tokens are all in `tokens.css` / `semantic-tokens.css`), (b) three graduated interactive components (Button, Badge, Input) already exist in `packages/ui-v2/`, and (c) writing DESIGN.md now includes both tokens AND the first component token entries — combining the originally separate Step 1 and Step 2 for the Batch 1 components.

**When**: After tokens are extracted to `@sndq/config/tailwind/tokens.css` and UI-V2 semantic tokens are added.

**What**: Write a DESIGN.md with:
- YAML front matter: all primitive tokens (Briicks colors, type scale, spacing, radius) + UI-V2 semantic tokens
- Markdown prose: Overview (SNDQ brand/product personality), Colors (palette rationale), Typography (font strategy), Layout (spacing philosophy), Shapes (radius philosophy)
- ~~No component tokens yet~~ Component tokens for Button, Badge, Input included (Batch 1 components are already graduated)

**Why this timing**:
- The token set is freshly extracted and organized — writing DESIGN.md now documents the canonical form while it's fresh
- The export roundtrip (`export --format tailwind` vs `tokens.css`) validates the extraction accuracy
- The `lint` command catches any broken references or missing tokens immediately
- The prose sections capture design rationale that would otherwise exist only in developers' heads

**Effort**: ~2-3 hours (see [Effort & Dependencies](./effort-and-dependencies.md))

---

## Step 2: Add component tokens during Phase 3 (per batch)

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

---

## Why NOT earlier (Phase 1a/1b)?

- Phase 1a has no design tokens at all
- Phase 1b only extracts a subset of Briicks primitives — the full token set doesn't exist until Phase 2 when UI-V2 semantic tokens join. Writing DESIGN.md against a partial token set creates maintenance burden

## Why NOT later (Phase 4/5)?

- Phase 3 is the window where component contracts are being defined — exactly when DESIGN.md component tokens are most useful
- Waiting until Phase 4/5 loses the "document while it's fresh" benefit and the CI validation during the highest-risk phase
