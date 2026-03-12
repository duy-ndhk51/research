# Toolbar Compound Component

## Objective

Extract raw toolbar markup (repeated divs, inline Tailwind classes) into a reusable compound component following shadcn/ui philosophy.

**Before**: A single `<div>` with hardcoded classes, repeated separator markup, and duplicated input styles ([Examples.tsx](./Examples.tsx)).

**After**: A composable compound component API with semantic naming and built-in consistency ([Toolbar.tsx](./Toolbar.tsx)).

## Stack

React 19, Next.js 15, Tailwind v4, shadcn/ui pattern

## Components

| Component | Role |
|---|---|
| `Toolbar` | Root container, optional `sticky` prop |
| `ToolbarGroup` | Wraps filter controls (e.g. SegmentedTabs), prevents shrinking |
| `ToolbarSeparator` | Vertical divider with `role="separator"` and `aria-orientation` |
| `ToolbarSearch` | Pre-styled search input, wrapped in `React.memo` |
| `ToolbarSpacer` | Flex spacer that pushes subsequent items to the right |
| `ToolbarActions` | Groups action buttons on the right side |

## Before vs After

```tsx
// ❌ Before — raw markup, repeated everywhere
<div className="bg-neutral-25 sticky top-0 z-10 flex items-center gap-2 px-4 pt-3 pb-3">
  <SegmentedTabs .../>
  <div className="h-4 w-px bg-neutral-200" />   {/* repeated 3x */}
  <SegmentedTabs .../>
  <div className="h-4 w-px bg-neutral-200" />
  <input className="focus:ring-brand-300 bg-neutral-0 max-w-64 ..." />
  <div className="flex-1" />
  <Button>Action</Button>
</div>

// ✅ After — semantic, composable
<Toolbar sticky>
  <ToolbarGroup><SegmentedTabs .../></ToolbarGroup>
  <ToolbarSeparator />
  <ToolbarGroup><SegmentedTabs .../></ToolbarGroup>
  <ToolbarSeparator />
  <ToolbarSearch placeholder="Search..." />
  <ToolbarSpacer />
  <ToolbarActions><Button>Action</Button></ToolbarActions>
</Toolbar>
```

## Review Decisions

| Review point | Action | Rationale |
|---|---|---|
| `cn()` in component file | Skip | Already in `@/lib/utils`, inlined here for playground isolation |
| `React.memo` | Applied to `ToolbarSearch` | Input element benefits from memo; layout wrappers don't |
| Debounce/clear/icon on search | Skip | Conflicts with "keep it simple" + shadcn philosophy |
| Dot notation export | Skip | shadcn uses named exports; dot notation is Chakra/Ant pattern |
| `role="toolbar"` on root | **Removed** | No roving tabindex implementation → don't promise a11y behavior to screen readers |
| `forwardRef` | Skip | React 19 passes `ref` as normal prop via `...props` |

## Benefits

- **DRY** — Separator, spacer, search styles defined once, used everywhere
- **Readable** — `<ToolbarSeparator />` vs `<div className="h-4 w-px bg-neutral-200" />`
- **Consistent** — Design changes propagate from one source
- **Accessible** — `role="separator"`, `aria-orientation`, `data-slot` attributes built-in
- **Composable** — Mix and match sub-components freely; override via `className` prop

## Known Limitations

- No responsive/overflow handling (no collapse-to-menu on small screens)
- `sticky` prop is basic — hardcoded `z-10`, no custom `top` value support
- Loose compound pattern (no React Context enforcing parent-child relationship)
- `ToolbarSearch` has no built-in `aria-label` — consumers must provide one

## Key Takeaways

1. Compound component pattern trades complexity for consistency — worth it when a pattern repeats 3+ times
2. `role` attributes without matching keyboard behavior is **worse** than no role — it lies to assistive technology
3. shadcn philosophy: keep it simple, composable, copy-paste friendly — resist the urge to over-abstract
4. Always provide context headers on isolated code snippets to prevent false-positive reviews
