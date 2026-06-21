# Table — PR Summary

**Component:** `Table` (compound) · **Tier:** 1 (Primitive)

## Design decisions

- **Foundation** — Fully custom HTML table primitives (no third-party dependency). 10 sub-components: `Table`, `TableHeader`, `TableBody`, `TableFooter`, `TableRow`, `TableHead`, `TableCell`, `TableCaption`, `TableGroupHeader`, `TableSummaryRow`, `TableEmptyRow`.
- **Density context** — `TableDensityContext` provides `'compact' | 'default'` to `TableHead` and `TableCell` via `useTableDensity()` hook. Module-level `densityClasses` lookup eliminates inline conditionals.
- **Token classes** — `.sndq-table-wrap` (border container with radius) and `.sndq-table` (table element base styles) defined in `components.css`. Sub-component styling uses Tailwind utilities with SNDQ semantic tokens.
- **Internal dependencies** — Composes `Button` (ghost/square), `Badge` (neutral/sm), `Text` (sm/medium), and `Icon` from sibling `@sndq/ui-v2` components.
- **Ref forwarding** — All sub-components use the modern function component pattern with `ref` as a prop via `React.ComponentPropsWithRef` (no `forwardRef` wrapper).
- **className override-wins** — All components accept `className` merged via `cn()` after defaults.
- **Spacing tokens** — All padding/gap values use SNDQ spacing scale tokens (`sndq-space-2` through `sndq-space-4`) instead of raw Tailwind utilities. One-off decorative value (`py-12` on empty state) kept as-is.
- **TableGroupHeader colSpan** — Optional `colSpan?: number` prop (default `999`) replaces the hardcoded magic number, letting consumers be explicit when needed. Mirrors the pattern used by `TableEmptyRow`.

## Documentation

MDX page at `apps/docs/content/docs/primitives/table.mdx`:

| Section | Content |
|---------|---------|
| Hero | Story playground with density control + inline demo |
| Overview | Purpose, import snippet, when to use / when not to use |
| Composition | ASCII component tree |
| Usage | Basic invoice table example |
| Density | Default vs compact side-by-side demos with padding table |
| Grouping | TableGroupHeader with expand/collapse, count badge |
| Empty state | TableEmptyRow spanning full width |
| API | Props tables for Table, TableHead, TableCell, TableGroupHeader, TableEmptyRow |
| Styling | Component class table, className contract, token reference |
| Related | Links to future DataTable, Badge, Button |

## Test coverage

**`Table.test.tsx`** — 8 unit tests:
- Renders with wrapper div and table element (sndq-table class)
- Forwards ref to the table element
- Default density applies default padding to TableCell
- Compact density applies compact padding to TableCell
- TableHead inherits density from context
- TableGroupHeader renders expand/collapse button
- TableGroupHeader shows Badge when count provided
- TableEmptyRow renders children centered in full-width cell

## Token/CSS changes

Added to `packages/config/tailwind/semantic-tokens.css`:

- **`--sndq-text-2xs`** — `0.625rem` (10px) for table headers and micro labels

Added to `packages/config/tailwind/tokens.css`:

- **`--text-sndq-2xs`** — maps to `var(--sndq-text-2xs)` (utility: `text-sndq-2xs`)

Added to `packages/config/tailwind/components.css`:

- **`.sndq-table-wrap`** — `position: relative`, `width: 100%`, `overflow: hidden`, `border-radius: var(--sndq-r-lg)`, `border: 1px solid var(--sndq-border)`
- **`.sndq-table`** — `width: 100%`, `caption-side: bottom`, `border-collapse: collapse`, `background: var(--sndq-surface)`, `font-size: var(--sndq-text-sm)`

## Review checklist

- [ ] Token classes match `components.css` definitions
- [ ] Icon component used consistently (no raw Lucide imports in JSX)
- [ ] Density context correctly propagated to TableHead and TableCell
- [ ] MDX live demos are `'use client'` and import from the barrel `index.ts`
- [ ] Unit tests are synchronous (no userEvent)
- [ ] Shared token changes do not break existing consumers
- [ ] `TableGroupHeader` Button uses `shape="square"` (not deprecated `size="icon"`)
