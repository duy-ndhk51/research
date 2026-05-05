# Layout shell reference (SNDQ UI v2)

Reference for implementing and documenting **`Container`** and **`Section`** in `@sndq/ui-v2`, aligned with Phase 3 Batch 1 sub-batch **1B**. Execution steps live in [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md).

**Created**: 2026-05-04  
**Status**: Reference (implementation follows execution doc)

---

## 1. What this is (and is not)

- **In scope (v1)**: Two **CVA**-driven components — **`Container`** (max width + horizontal inset) and **`Section`** (vertical rhythm for page bands). They use **`class-variance-authority`** + `cn()` on the root, the same composition pattern as [typography-system-reference.md](./typography-system-reference.md).
- **Not in scope (Batch 1)**: **`Box`**, **`Flex`**, **`Grid`**, margin props on arbitrary components, or **`@radix-ui/themes`** layout APIs / CSS / `Theme` spacing. This is **SNDQ-owned** API and tokens only — inspired by common layout *ideas*, not a fork of Radix Themes.
- **Inside a section**: Use Tailwind (or domain components) for flex, grid, gaps, and card padding. These primitives only standardize **page column width** and **macro vertical rhythm**.

---

## 2. Component model

| Component | Default element | Role |
|-----------|-----------------|------|
| **`Container`** | `div` | Centers content, applies **max-width** and **horizontal** padding from the token scale. |
| **`Section`** | `section` | Wraps a major content band; applies **vertical** padding (and optional top/bottom separation via tokens) from the token scale. Prefer `<section>` for document outline unless a specific screen requires a different polymorphic `as`. |

Both expose a **`size`** prop (or equivalent agreed enum) mapping to **discrete presets** — no responsive object props in Batch 1 v1 (e.g. no `p={{ sm: '4', lg: '6' }}`).

---

## 3. Token layering

| Layer | Location | Role |
|-------|----------|------|
| **Canonical layout semantics** | Monorepo `packages/config/tailwind/semantic-tokens.css` | **Add** variables used by `Container` / `Section` `cva` recipes (examples below). Extend the file in the same commits that first reference each variable (Commits 5–8 in the execution doc). |
| **Primitive scale** | Existing `packages/config/tailwind/tokens.css` (`@theme inline`, spacing ramps if any) | Base spacing; semantic layout tokens may reference these where appropriate. |
| **Short utilities** | Optional `@theme` entries in `tokens.css` | Add **only** when a variant needs a shorter class in the **same** commit as that variant. |

**Rule**: `cva` variant strings must use **`var(--sndq-…)`** (or agreed `@theme` aliases that point at those vars). Do not duplicate raw pixel ladders inside component files.

### Suggested token names (implementer adjusts to match design)

**Container** (examples — align with Figma “page width” presets):

- `--sndq-container-max-sm` — narrower reading / modal column
- `--sndq-container-max-md` — default app content
- `--sndq-container-max-lg` — wide dashboards
- `--sndq-container-gutter` — horizontal padding left/right (or per-`size` gutters if design requires)

**Section** (examples — align with Figma “section spacing”):

- `--sndq-section-py-sm` / `--sndq-section-py-md` / `--sndq-section-py-lg` — vertical padding for the band

Exact numeric values and how many `size` steps exist are **design decisions**; keep the set **small** (typically three sizes per component).

---

## 4. `cva` and `cn()`

- Define **`containerVariants`** / **`sectionVariants`** with a **`size`** key (and optional future keys documented when added).
- Export **`ContainerProps`** / **`SectionProps`** including `size`, `className`, `children`, and polymorphic `as` only if the team agrees (default: fixed `div` / `section`).
- Root: **`cn(containerVariants({ size }), className)`** so consumer overrides merge predictably (same as typography §4).

---

## 5. Documentation (Foundations)

- MDX lives under **`apps/docs/content/docs/foundations/container.mdx`** and **`section.mdx`** (not under Primitives), with **`foundations/meta.json`** updated so the sidebar lists them.
- Each page should state: **when to use**, **allowed `size` values**, **token mapping**, and **anti-patterns** (e.g. do not nest five `Section`s for card padding — use Tailwind on the card).

---

## 6. Package exports

- **`Container`** and **`Section`** ship from **`@sndq/ui-v2/components`** (same barrel as other ui-v2 components). Only **docs URLs** use the Foundations path.

---

## 7. Briicks bridge (Phase 4)

Batch 1 adds **`@deprecated`** on legacy barrels **only if** matching exports exist when you inspect `sndq-fe` before the deprecation commit. There is **no default** briicks `Container` / `Section` mapping in the execution table.

---

## 8. Related documents

- [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md) — commit order, sub-batches 1A–1D, verification.
- [typography-system-reference.md](./typography-system-reference.md) — parallel CVA + token pattern for `Text` / `Heading`.
- [migration-plan.md](./migration-plan.md) — phases, API matrix, deprecation strategy.
