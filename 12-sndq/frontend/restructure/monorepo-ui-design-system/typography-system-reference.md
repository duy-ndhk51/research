# Typography system reference (SNDQ UI v2)

Reference for implementing and documenting **`Heading`** and **`Text`** in `@sndq/ui-v2`, aligned with Phase 3 Batch 1. Execution steps live in [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md).

**Created**: 2026-05-04  
**Status**: Reference (implementation follows execution doc)

---

## 1. Component model

- **`Heading`**: document titles and section headings. Prefer explicit levels (`as` / default `h1`–`h6` patterns) for accessibility and SEO.
- **`Text`**: body copy, captions, labels, and inline emphasis. Use a **variant** (or size) axis for visual scale, not multiple one-off components, unless design explicitly requires a separate primitive.

This follows a **Radix-style split** (semantic clarity) with **CVA-style variant maps** (consistent visual control), similar in spirit to Radix Themes `Heading` / `Text` and Cloudflare Kumo’s disciplined variant approach.

---

## 2. Token layering

| Layer | Location | Role |
|-------|----------|------|
| **Canonical semantic tokens** | SNDQ monorepo `packages/config/tailwind/semantic-tokens.css` (`:root`, `--sndq-text`, `--sndq-text-secondary`, `--sndq-text-xs` … `--sndq-text-7xl`, font families) | Single source of truth for colors and type scale used by UI v2. |
| **Primitive palette** | SNDQ monorepo `packages/config/tailwind/tokens.css` (`@theme inline`, Briicks color ramps, etc.) | Base colors; semantic tokens reference these where appropriate. |
| **Tailwind utilities (short classes)** | Extend `@theme` in `tokens.css` (or a small imported file that stays part of the same Tailwind pipeline) | Optional **aliases** such as `--color-sndq-text-secondary: var(--sndq-text-secondary)` so consumers can write `text-sndq-text-secondary` (or a shorter agreed name) instead of only arbitrary values. |

**Rule**: variant definitions in components should **read values from `semantic-tokens.css`** (via `var(--sndq-…)` in class strings or via `@theme` aliases that point at those vars). Do not introduce duplicate hex or ad-hoc font sizes in component files.

---

## 3. Gradual `@theme` aliases

Add **`@theme` entries only when a typography variant (or docs) actually needs them** in the same PR commit that introduces that variant. Do not map the entire semantic palette in one shot.

- **Until an alias exists**, using arbitrary utilities such as `text-[var(--sndq-text-secondary)]` or `text-[length:var(--sndq-text-sm)]` is acceptable in `cva` recipes.
- **When an alias is added**, prefer migrating that variant line to the shorter utility for readability and editor hints.

**Naming**: avoid redundant words in the utility tail where possible (for example map `--sndq-text-secondary` to a theme key that yields `text-sndq-secondary` rather than `text-sndq-text-secondary`), as long as the team documents the mapping once in this file or in `apps/docs` Foundations.

---

## 4. `cn()` and overrides

- **`@sndq/ui-v2` must not import** from `sndq-fe/packages/ui` (submodule). Add **`packages/ui-v2/src/lib/utils.ts`** in the SNDQ monorepo with the same implementation as `sndq-fe/packages/ui/src/lib/utils.ts` (`clsx` + `tailwind-merge`).
- Components compose styles as **`cn(variantClasses, className)`** on the root element so **consumer `className` overrides win** on Tailwind conflicts. This is the canonical override-wins ordering — see [layout-system-reference.md §3-ter](./layout-system-reference.md#3-ter-classname-override-wins-guarantee) for the system-wide rule, the `gap-2` vs `gap-8` example, and the test gate that enforces it.

---

## 5. Briicks bridge (Phase 4 migration)

Legacy typography lives under **`sndq-fe/src/components/briicks/text/`** (`Heading`, `Paragraph`, `Caption` — see current implementation). Batch 1 only adds **`@deprecated`** on barrel exports once `Heading` and `Text` exist in `@sndq/ui-v2/components`.

| briicks (legacy) | ui-v2 target | Phase 4 note |
|------------------|-------------|--------------|
| `Heading` | `Heading` | Map `size` / semantics to ui-v2 `Heading` props. |
| `Paragraph` | `Text` | Map paragraph variants to `Text` variants. |
| `Caption` | `Text` | Map caption styles to `Text` variants (e.g. caption / small). |

APIs are **not** drop-in compatible; call sites change in Phase 4 per [migration-plan.md §10](./migration-plan.md#10-api-compatibility-matrix).

---

## 6. Related documents

- [phase-3-batch-1-execution.md](./phase-3-batch-1-execution.md) — commit order, verification, deprecations.
- [layout-system-reference.md](./layout-system-reference.md) — CVA `Container` / `Section` / `Flex` / `Grid` (Batch 1 sub-batch 1B). Hosts two system-wide rules that also apply to `Text` / `Heading`: (1) **strict semantic-vs-numeric prop typing** (each prop is either semantic OR numeric, never both), and (2) **`className` override-wins** (`cn(variantClasses, className)`).
- [migration-plan.md](./migration-plan.md) — phases, API matrix, deprecation strategy.
