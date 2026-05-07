# Layout shell reference (SNDQ UI v2)

Reference for implementing and documenting **`Container`**, **`Section`**, **`Flex`**, and **`Grid`** in `@sndq/ui-v2`, aligned with Phase 3 Batch 1 sub-batch **1B**. Execution steps live in [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md).

**Created**: 2026-05-04  
**Updated**: 2026-05-06 — added `Flex` and `Grid`, the strict semantic-vs-numeric prop typing rule, and the canonical `className` override-wins guarantee.  
**Status**: Reference (implementation follows execution doc)

---

## 1. What this is (and is not)

- **In scope (v1)**: Four **CVA**-driven components — **`Container`** (max width + horizontal inset), **`Section`** (vertical rhythm for page bands), **`Flex`** (1-axis layout with token-backed gap), and **`Grid`** (2-axis layout with token-backed gap). They use **`class-variance-authority`** + `cn()` on the root, the same composition pattern as [typography-system-reference.md](./typography-system-reference.md).
- **Not in scope (Batch 1)**: **`Box`**, `padding` / `margin` / `width` / `height` props on `Flex` / `Grid`, responsive prop objects, and **`@radix-ui/themes`** layout APIs / CSS / `Theme` spacing. This is **SNDQ-owned** API and tokens only — inspired by common layout *ideas*, not a fork of Radix Themes.
- **Inside a section**: Use `Flex` / `Grid` for inner structure with `gap`. Use Tailwind utilities (or domain components) for spacing exceptions, responsive overrides, or any layout the v1 prop surface doesn't cover. `Container` / `Section` only standardize **page column width** and **macro vertical rhythm**.

---

## 2. Component model

| Component | Default element | Role |
|-----------|-----------------|------|
| **`Container`** | `div` | Centers content, applies **max-width** and **horizontal** padding from the token scale. |
| **`Section`** | `section` | Wraps a major content band; applies **vertical** padding (and optional top/bottom separation via tokens) from the token scale. Prefer `<section>` for document outline unless a specific screen requires a different polymorphic `as`. |
| **`Flex`** | `div` | One-axis layout: `direction`, `align`, `justify`, `wrap`, plus token-backed `gap` / `gapX` / `gapY`. |
| **`Grid`** | `div` | Two-axis layout: numeric `columns`, `align`, `justify`, `flow`, plus token-backed `gap` / `gapX` / `gapY`. `rows` and `areas` deferred. |

`Container` / `Section` expose a **`size`** prop (semantic enum) mapping to **discrete presets**. `Flex` / `Grid` expose layout enums plus **numeric** `gap*` (and numeric `columns` on `Grid`). **No responsive object props in Batch 1 v1** (e.g. no `gap={{ sm: '2', lg: '4' }}` and no `p={{ sm: '4', lg: '6' }}`).

---

## 3. Token layering

| Layer | Location | Role |
|-------|----------|------|
| **Canonical layout semantics** | Monorepo `packages/config/tailwind/semantic-tokens.css` | **Add** variables used by `Container` / `Section` / `Flex` / `Grid` `cva` recipes (examples below). Extend the file in the same commits that first reference each variable (Commits 5–12 in the execution doc). |
| **Numeric spacing scale** | `packages/config/tailwind/semantic-tokens.css` (`--sndq-space-1` … `--sndq-space-N`) | **Single source** for `gap*` (and any future numeric spacing prop). All `Flex` / `Grid` `gap` recipes resolve through this scale. |
| **Primitive scale** | Existing `packages/config/tailwind/tokens.css` (`@theme inline`, spacing ramps if any) | Base spacing; semantic layout tokens may reference these where appropriate. |
| **Short utilities** | Optional `@theme` entries in `tokens.css` | Add **only** when a variant needs a shorter class in the **same** commit as that variant. |

**Rule**: `cva` variant strings must use **`var(--sndq-…)`** (or agreed `@theme` aliases that point at those vars). Do not duplicate raw pixel ladders inside component files. Numeric `gap*` values must resolve to `--sndq-space-*` only — no arbitrary px literals.

### Suggested token names (implementer adjusts to match design)

**Container** (examples — align with Figma "page width" presets):

- `--sndq-container-max-sm` — narrower reading / modal column
- `--sndq-container-max-md` — default app content
- `--sndq-container-max-lg` — wide dashboards
- `--sndq-container-gutter` — horizontal padding left/right (or per-`size` gutters if design requires)

**Section** (examples — align with Figma "section spacing"):

- `--sndq-section-py-sm` / `--sndq-section-py-md` / `--sndq-section-py-lg` — vertical padding for the band

**Numeric spacing scale (used by `Flex` / `Grid` `gap*`)**:

- `--sndq-space-0` … `--sndq-space-5` (initial range; extend the scale only when a recipe needs a new step)

Exact numeric values and how many steps exist are **design decisions**; keep each set **small** (typically three sizes for Container / Section, ~5–6 steps for the numeric spacing scale).

---

## 3-bis. Prop typing rule (strict; never both)

System-wide rule for **every** ui-v2 component (not just layout): **each prop is either semantic OR numeric — never both**.

| Mode | When to use | Examples in v1 |
|------|-------------|----------------|
| **Semantic** | Low-step, "design decision" props expected to retune rarely (and in large jumps). | `Container.size` / `Section.size` (`sm` / `md` / `lg`); future `radius`, `shadow`, breakpoint axes. |
| **Numeric** | Fine-grained, frequently-tuned props that iterate during build-out. | `Flex.gap` / `Grid.gap` / `gapX` / `gapY`, `Grid.columns`. |

**Forbidden**: a single prop that accepts both modes (e.g. `gap: "md" | "3"`). If you need both expressivity and design-system governance for the same axis, ship two distinct, non-overlapping scales on different props — never collapse them.

**Why**: mixing modes on one prop fragments usage across teams ("team A uses `3`, team B uses `md`"), erodes the "change one place, update everywhere" lever, and makes future migrations harder.

---

## 3-ter. `className` override-wins guarantee

System-wide canonical rule for **every** ui-v2 component.

**Promise**: when a consumer passes a `className` whose Tailwind utility conflicts with one applied by a component variant, the **`className` value wins**.

```tsx
// Variant produces "gap-2"; consumer passes "gap-8"
<Flex gap="2" className="gap-8" />
// Final root className contains gap-8 (variant gap-2 is dropped)
```

**Required composition order** on every primitive root:

```ts
cn(variantClasses, className) // correct — className wins on conflicts
```

**Anti-pattern (forbidden)**:

```ts
cn(className, variantClasses) // wrong — variants override consumer className
```

**Backed by**: `tailwind-merge` inside the shared `cn()` helper. The mirror at `packages/ui-v2/src/lib/utils.ts` must use the same implementation as `sndq-fe/src/lib/utils.ts` (`twMerge(clsx(inputs))`); see [typography-system-reference.md §4](./typography-system-reference.md#4-cn-and-overrides).

**Standardization gate**: every component graduating in Batch 1+ must include at least one test asserting that `<Component variantProp className="conflicting-utility" />` resolves to the consumer value (e.g. `gap-2` vs `gap-8`).

---

## 4. Flex API (v1)

Default element: `div`. CVA variants on the root with `cn(flexVariants(props), className)`.

| Prop | Mode | Allowed values (v1) | Notes |
|------|------|---------------------|-------|
| `direction` | Enum | `"row"` (default) \| `"column"` \| `"row-reverse"` \| `"column-reverse"` | |
| `align` | Enum | `"start"` \| `"center"` \| `"end"` \| `"baseline"` \| `"stretch"` | Maps to `align-items`. |
| `justify` | Enum | `"start"` \| `"center"` \| `"end"` \| `"between"` | Maps to `justify-content`. |
| `wrap` | Enum | `"nowrap"` (default) \| `"wrap"` \| `"wrap-reverse"` | |
| `gap` | **Numeric** | `"0"` \| `"1"` \| `"2"` \| `"3"` \| `"4"` \| `"5"` | Resolves to `--sndq-space-*`. |
| `gapX` | **Numeric** | same scale as `gap` | Overrides `gap` on the column-axis. |
| `gapY` | **Numeric** | same scale as `gap` | Overrides `gap` on the row-axis. |

**Not in v1**: `padding` / `margin` / `width` / `height` props, `inline` flag, polymorphic `as`, responsive prop objects. Compose those with Tailwind utilities at the call site.

---

## 5. Grid API (v1)

Default element: `div`. CVA variants on the root with `cn(gridVariants(props), className)`.

| Prop | Mode | Allowed values (v1) | Notes |
|------|------|---------------------|-------|
| `columns` | **Numeric** | `"1"` \| `"2"` \| `"3"` \| `"4"` \| `"6"` \| `"12"` | Structural enum; covers common column counts. |
| `align` | Enum | `"start"` \| `"center"` \| `"end"` \| `"stretch"` | Maps to `align-items`. |
| `justify` | Enum | `"start"` \| `"center"` \| `"end"` \| `"between"` | Maps to `justify-content`. |
| `flow` | Enum | `"row"` (default) \| `"column"` \| `"dense"` | |
| `gap` | **Numeric** | same scale as `Flex.gap` | Resolves to `--sndq-space-*`. |
| `gapX` | **Numeric** | same scale as `Flex.gap` | |
| `gapY` | **Numeric** | same scale as `Flex.gap` | |

**Not in v1**: `rows`, `areas`, `padding` / `margin` / `width` / `height` props, polymorphic `as`, responsive prop objects.

---

## 6. `cva` and `cn()`

- Define **`containerVariants`** / **`sectionVariants`** with a **`size`** key.
- Define **`flexVariants`** / **`gridVariants`** with the enum + numeric keys above (and any future axes documented when added).
- Export **`ContainerProps`** / **`SectionProps`** / **`FlexProps`** / **`GridProps`** including all variant keys, `className`, `children`, and polymorphic `as` only if the team agrees (default: fixed elements per §2).
- Root: **`cn(<variants>({ ... }), className)`** so consumer overrides merge predictably (see §3-ter for the override-wins guarantee).

---

## 7. Documentation (Foundations)

- MDX lives under **`apps/docs/content/docs/foundations/`**:
  - `container.mdx`
  - `section.mdx`
  - `flex.mdx`
  - `grid.mdx`
- Update **`foundations/meta.json`** so the sidebar lists all four (alongside any other Foundations pages).
- Each page should state: **when to use**, **allowed prop values** (with the semantic-vs-numeric distinction explicit), **token mapping** (e.g. `gap="2"` → `--sndq-space-2`), the **override-wins guarantee** (with the `gap-2` vs `gap-8` example), and **anti-patterns** (e.g. do not nest five `Section`s for card padding — use `Flex`/`Grid` with `gap` on the card).

---

## 8. Package exports

- **`Container`**, **`Section`**, **`Flex`**, **`Grid`** ship from **`@sndq/ui-v2/components`** (same barrel as other ui-v2 components). Only **docs URLs** use the Foundations path.

---

## 9. Briicks bridge (Phase 4)

Batch 1 adds **`@deprecated`** on legacy barrels **only if** matching exports exist when you inspect `sndq-fe` before the deprecation commit. There is **no default** briicks `Container` / `Section` / `Flex` / `Grid` mapping in the execution table.

`Row` / `Frame` / `Group` (existing Tier 1 Layout entries in the prototype) are **not** decided here — revisit during their own graduation whether they remain as higher-level conveniences built on `Flex` / `Grid`, get replaced, or are deprecated.

---

## 10. Related documents

- [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md) — commit order, sub-batches 1A–1D, verification.
- [typography-system-reference.md](./typography-system-reference.md) — parallel CVA + token pattern for `Text` / `Heading`; references the same override-wins rule.
- [migration-plan.md](./migration-plan.md) — phases, API matrix, deprecation strategy.
