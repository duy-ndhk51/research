# material-react-table — Token Analysis

## TL;DR

material-react-table is a full UI implementation of TanStack Table on MUI. It delegates theming entirely to MUI's `Theme` system and adds a small `mrtTheme` bridge layer (7 semantic colors derived from MUI palette) for table-specific concerns. No bundled CSS — styling is entirely Emotion/`sx` at runtime.

## Key Facts

| Aspect | Detail |
|--------|--------|
| Tech Stack | React, MUI v6, Emotion, TanStack Table v8 |
| Token Count | 7 table-specific colors (`MRT_Theme`) |
| Format | JS object derived from MUI `Theme` at runtime |
| Dark Mode | Delegates to MUI `palette.mode` |
| Customization API | `mrtTheme` callback + `mui*Props` passthrough |
| Source of Truth | MUI Theme (primary), `getMRTTheme()` (secondary) |

## Architecture

### Token Flow

```
MUI createTheme()
    |
useTheme() in useMRT_TableOptions
    |
getMRTTheme(mrtTheme, muiTheme) -> MRT_Theme (7 colors)
    |
getCommonMRTCellStyles(), getCommonToolbarStyles()
    |
Component sx props
```

### MRT_Theme Interface

```typescript
interface MRT_Theme {
  baseBackgroundColor: string;
  cellNavigationOutlineColor: string;
  draggingBorderColor: string;
  matchHighlightColor: string;
  menuBackgroundColor: string;
  pinnedRowBackgroundColor: string;
  selectedRowBackgroundColor: string;
}
```

### Default Derivation

```typescript
const getMRTTheme = (mrtTheme, muiTheme) => {
  const baseBackgroundColor =
    mrtTheme?.baseBackgroundColor ??
    (muiTheme.palette.mode === 'dark'
      ? lighten(muiTheme.palette.background.default, 0.05)
      : muiTheme.palette.background.default);
  return {
    baseBackgroundColor,
    cellNavigationOutlineColor: muiTheme.palette.primary.main,
    draggingBorderColor: muiTheme.palette.primary.main,
    matchHighlightColor: /* from warning palette */,
    menuBackgroundColor: lighten(baseBackgroundColor, 0.07),
    pinnedRowBackgroundColor: alpha(muiTheme.palette.primary.main, 0.1),
    selectedRowBackgroundColor: alpha(muiTheme.palette.primary.main, 0.2),
    ...mrtThemeOverrides,
  };
};
```

## Token Hierarchy

### Layer 1: MUI Theme (Global)

MUI's full theme system: palette, typography, spacing, breakpoints, component overrides. material-react-table inherits all of this automatically.

### Layer 2: MRT Bridge (Table-Specific)

7 colors that map MUI palette to table-specific semantics. Auto-derived but overridable.

### Layer 3: No Component Sub-Tokens

Individual table parts (cells, headers, toolbars) use MUI components directly and accept `sx` props.

## Dark Mode

Fully delegated to MUI:
- `palette.mode: 'dark'` in `createTheme()` switches MUI primitives
- `getMRTTheme()` reads `palette.mode` to derive appropriate base backgrounds
- No separate dark mode mechanism in the table itself

## Generation / Authoring

- **No generation pipeline** — all at runtime via MUI's theme system
- `getMRTTheme()` derives defaults on every render (memoized via `useMemo`)
- User overrides via `mrtTheme` option (static object or `(muiTheme) => Partial<MRT_Theme>`)
- No CSS files shipped (`sideEffects: false`)

## Component Integration

Components use MUI primitives (`TableCell`, `Paper`, `TextField`) with shared style utils:
- `getCommonMRTCellStyles()` — cell backgrounds, pinning, borders
- `getCommonPinnedCellStyles()` — sticky column styles
- `getCommonToolbarStyles()` — toolbar layout

All reference `table.options.mrtTheme` + MUI theme + column sizing CSS vars.

## Customization Surface

```typescript
// Table-specific theme
mrtTheme: (muiTheme) => ({
  baseBackgroundColor: '#f5f5f5',
  draggingBorderColor: muiTheme.palette.secondary.main,
})

// Per-part MUI props
muiTableBodyCellProps: ({ cell }) => ({
  sx: { backgroundColor: 'lightblue' },
})

// Global MUI theme
<ThemeProvider theme={createTheme({ palette: { primary: { main: '#e63946' } } })}>

// Sub-component replacement
renderTopToolbar: ({ table }) => <CustomToolbar table={table} />
```

## Key Patterns

1. **DS delegation** — does not reinvent token system, wraps MUI completely
2. **Bridge layer** — small typed interface (7 colors) for table-specific semantics
3. **Auto-derivation from palette** — user changes MUI theme, table adapts automatically
4. **`*Props` passthrough** — every sub-component accepts full MUI component props
5. **`parseFromValuesOrFunc`** — unified pattern for static or context-dependent prop values
6. **No bundled CSS** — zero stylesheet cost; all Emotion-injected

## Cross-References

- [Comparison Overview](../token-architecture/comparison-overview.md)
- [Component Tokens](../token-architecture/component-tokens.md) — MRT bridge as lightweight component tokens
- [mantine-react-table](../mantine-react-table/token-analysis.md) — same author, Mantine equivalent
