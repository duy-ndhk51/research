# Templates (Reusable Packs)

This folder contains **copy/paste-ready templates** used during the `@sndq/ui-v2` migration and long-term design-system maintenance.

## Contents

- **Docs (Fumadocs)**: [`docs-rules.md`](./docs-rules.md) — living rules and process for component/block MDX.
- **Docs (Fumadocs)**: [`docs-templates.md`](./docs-templates.md) — copy/paste MDX + Story playground templates.
- **Tests**: [`tests/ui-v2-test-templates.md`](./tests/ui-v2-test-templates.md) — low-maintenance testing strategy + templates for primitives and blocks in `packages/ui-v2/`.

## How to use

- Start from a template and **keep diffs small** (only fill placeholders and delete unused sections).
- Prefer **policy + examples** over large checklists.
- If you introduce a new recurring pattern, update the relevant template so future batches reuse it.

## Component folder structure

Every component in `packages/ui-v2/src/components/` follows a **per-component folder** pattern (inspired by Cloudflare Kumo's [`delete-resource` block](https://github.com/cloudflare/kumo)):

```
components/
  index.ts                          # top barrel, re-exports all component folders
  {component-name}/                 # kebab-case folder
    {ComponentName}.tsx             # PascalCase component file
    {ComponentName}.test.tsx        # co-located test
    index.ts                        # export { ComponentName, type ComponentNameProps } from './ComponentName'
```

**Rules:**

- **Folder**: kebab-case (e.g., `date-picker/`, `combo-button/`)
- **Component file**: PascalCase (e.g., `DatePicker.tsx`)
- **Barrel**: every folder has an `index.ts` that re-exports the public API (component, variants, types)
- **Tests**: co-located inside the component folder
- **Groups**: related components share a parent folder with shared utilities at the group level (e.g., `typography/text/`, `typography/heading/`, `typography/typography-shared.ts`)
- **Top barrel**: `components/index.ts` re-exports from folder indexes (`export * from './container'`)

Our variant uses PascalCase files inside kebab-case folders, matching the existing component file naming convention.

## Rules

### Always use `@theme` utility aliases in CVA recipes

CVA variant strings must use **short `@theme`-backed utilities**, never raw `var()` arbitrary values.

When a component needs a new semantic token from `semantic-tokens.css`, you must also add a corresponding `@theme` alias in `tokens.css` (in the same commit) so the CVA recipe can reference the short utility.

```css
/* Bad — raw var() in CVA */
'max-w-[var(--sndq-container-max-sm)]'
'px-[var(--sndq-container-gutter)]'

/* Good — short @theme utility */
'max-w-sndq-container-sm'
'px-sndq-container-gutter'
```

**Namespace reference** (Tailwind v4 `@theme inline`):

| CSS variable prefix | Produces utilities | Example |
|---|---|---|
| `--color-*` | `text-*`, `bg-*`, `border-*` | `--color-sndq-text-primary` → `text-sndq-text-primary` |
| `--text-*` | `text-*` (font-size) | `--text-sndq-sm` → `text-sndq-sm` |
| `--font-*` | `font-*` | `--font-sndq-heading` → `font-sndq-heading` |
| `--spacing-*` | `p-*`, `m-*`, `gap-*`, `w-*`, `h-*` | `--spacing-sndq-container-gutter` → `px-sndq-container-gutter` |
| `--max-width-*` | `max-w-*` | `--max-width-sndq-container-sm` → `max-w-sndq-container-sm` |
| `--radius-*` | `rounded-*` | `--radius-sndq-lg` → `rounded-sndq-lg` |
| `--shadow-*` | `shadow-*` | `--shadow-sndq-md` → `shadow-sndq-md` |

