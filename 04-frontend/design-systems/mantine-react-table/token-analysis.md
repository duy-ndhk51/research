# mantine-react-table — Token Analysis

## TL;DR

mantine-react-table is a full UI implementation of TanStack Table on Mantine. It delegates theming entirely to Mantine's theme system and bridges to table-specific concerns via `--mrt-*` CSS variables defined in CSS modules. Ships bundled `styles.css`; customization is through `mantine*Props` passthrough and Mantine theme wrapping.

## Key Facts

| Aspect | Detail |
|--------|--------|
| Tech Stack | React, Mantine v7, CSS Modules, TanStack Table v8 |
| Token Count | ~15 table-specific CSS vars (`--mrt-*`) |
| Format | CSS custom properties bridged from `--mantine-*` |
| Dark Mode | Delegates to Mantine `useMantineColorScheme()` |
| Customization API | `mantine*Props` passthrough + Mantine theme wrapping |
| Source of Truth | Mantine Theme (primary), `--mrt-*` vars in CSS modules (secondary) |

## Architecture

### Token Flow

```
MantineProvider theme
    |
useMantineTheme() / useMantineColorScheme()
    |
CSS Modules with var(--mantine-*) and var(--mrt-*)
    |
Mantine components (Table, Paper, TextInput, etc.)
```

### MRT CSS Variables

Defined in `MRT_TablePaper.module.css`:
```css
:root {
  --mrt-base-background-color: var(--mantine-color-body);
  --mrt-striped-row-background-color: var(--mantine-color-default-hover);
  --mrt-selected-row-background-color: alpha(var(--mantine-primary-color-light), 0.8);
  --mrt-dragging-hovered-border-color: var(--mantine-primary-color-filled);
  --mrt-resize-column-border-color: var(--mantine-primary-color-filled);
  --mrt-pinned-column-border-color: var(--mantine-color-default-border);
  --mrt-pinned-row-border-color: var(--mantine-color-default-border);
}
```

### Runtime Bridge

`MRT_Table.tsx` dynamically computes striped row colors using Mantine's `darken`/`lighten` utilities based on color scheme:
```typescript
const baseBackgroundColor = /* from --mrt-base-background-color */;
const stripeColor = colorScheme === 'dark'
  ? lighten(baseBackgroundColor, 0.04)
  : darken(baseBackgroundColor, 0.02);
```

## Token Hierarchy

### Layer 1: Mantine Theme (Global)

Full Mantine system: colors, spacing, radius, shadows, font sizes. Automatically inherited by all Mantine components used inside the table.

### Layer 2: MRT Bridge (Table-Specific)

CSS variables in `.module.css` that map Mantine tokens to table semantics:
- `--mrt-base-background-color` — overall table background
- `--mrt-striped-row-background-color` — alternating row bg
- `--mrt-selected-row-background-color` — row selection highlight
- `--mrt-dragging-hovered-border-color` — drag-and-drop feedback
- `--mrt-resize-column-border-color` — resize handle color
- `--mrt-pinned-*-border-color` — sticky column/row borders

### Layer 3: No Explicit Component Sub-Tokens

Individual table parts are Mantine components accepting standard Mantine props.

## Dark Mode

Fully delegated to Mantine:
- `useMantineColorScheme()` determines light/dark
- `--mantine-*` vars switch automatically per scheme
- `--mrt-*` vars reference `--mantine-*`, so they switch too
- Striped row computation adjusts direction (lighten in dark, darken in light)

## Generation / Authoring

- **No generation pipeline** — CSS vars hand-authored in CSS modules
- Bundled as `styles.css` (compiled from CSS modules)
- Consumers must `import 'mantine-react-table/styles.css'`
- Helper utilities in `style.utils.ts`: `getPrimaryColor(theme)`, `getPrimaryShade(theme)`

## Component Integration

Table sub-components use Mantine primitives (`Table`, `Paper`, `TextInput`, `Menu`) with CSS module classes:
```typescript
<Paper className={clsx(classes.root, className)} {...mantinePaperProps}>
  <Table className={classes.table} __vars={{
    '--header-height': `${headerHeight}px`,
    '--col-size': `${columnSize}px`,
  }} {...mantineTableProps}>
```

Layout dimensions use `__vars` (Mantine's CSS var injection pattern).

## Customization Surface

```typescript
// Mantine theme wrapping
<MantineProvider theme={{ primaryColor: 'red', colors: { red: [...] } }}>
  <MantineReactTable ... />
</MantineProvider>

// Per-part Mantine props
mantineTableBodyCellProps: ({ cell }) => ({
  style: { fontWeight: 'bold' },
})

// Override MRT CSS vars
mantinePaperProps: {
  __vars: { '--mrt-base-background-color': '#f0f0f0' },
}

// Sub-component replacement
renderTopToolbar: ({ table }) => <CustomToolbar />
```

## Key Patterns

1. **DS delegation** — does not reinvent tokens, fully wraps Mantine
2. **CSS var bridge** — `--mrt-*` vars map to `--mantine-*` for table-specific semantics
3. **Bundled CSS** — ships `styles.css` (unlike material-react-table which uses no CSS)
4. **`mantine*Props` passthrough** — every sub-component accepts full Mantine component props
5. **`__vars` for layout** — column/header sizes as scoped CSS vars (Mantine pattern)
6. **Scheme-aware computation** — striped rows compute differently per color scheme

## Cross-References

- [Comparison Overview](../token-architecture/comparison-overview.md)
- [Mantine Token Analysis](../mantine/token-analysis.md) — parent DS token system
- [material-react-table](../material-react-table/token-analysis.md) — same author, MUI equivalent
- [Component Tokens](../token-architecture/component-tokens.md) — CSS var bridge as lightweight component tokens
