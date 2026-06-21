# DropdownMenu — PR Summary

**Component:** `DropdownMenu` · **Tier:** 1 (Primitive)

## Design decisions

- **Radix foundation** — thin wrappers over `@radix-ui/react-dropdown-menu`. Root, Trigger, Group, Portal, RadioGroup, and Sub are direct re-exports; styled wrappers for Content, SubContent, Item, CheckboxItem, RadioItem, Separator, Label, SubTrigger.
- **SNDQ token classes** — all styling goes through shared component classes:
  - `sndq-menu` (Content, SubContent) — surface, border, radius, shadow
  - `sndq-item` (Item, CheckboxItem, RadioItem, SubTrigger) — height, padding, hover/focus
  - `sndq-item-destructive` (Item when `destructive`) — error text/hover
  - `sndq-separator` (Separator) — horizontal divider
  - `sndq-menu-label` (Label) — section heading
- **Icon component** — all icons render through the shared `Icon` wrapper with `size="xs"`:
  - `Check` for CheckboxItem indicator
  - `ChevronRight` for SubTrigger (auto-appended, `ml-auto text-sndq-text-tertiary`)
  - `Circle` for RadioItem indicator (`h-2 w-2 fill-current` override)
- **Indicator pattern** — CheckboxItem and RadioItem use Shadcn's absolute-positioned `<span>` wrapper (`absolute left-2.5 flex size-sndq-icon-sm`) with `pointer-events-none`. Items get `relative pl-8` for gutter space. Radix `ItemIndicator` controls visibility.
- **Animations** — directional `translateY`/`translateX` (6px slide) driven by `data-[state]` + `data-[side]` attributes. 150ms custom easing defined in `animations.css`.
- **Content** wraps itself in a Radix Portal internally; `sideOffset` defaults to `4`.

## Documentation

MDX page at `apps/docs/content/docs/primitives/dropdown-menu.mdx`:

| Section | Content |
|---------|---------|
| Hero | Fumadocs Story playground + 2 inline demos (Actions, Account icon-only) |
| Overview | Purpose, import snippet, when to use / when not to use |
| Composition | ASCII component tree |
| Usage | 7 subsections: Basic, Trigger variants, Labels/groups, Sub-menu, Checkbox, Radio, Controlled |
| Styling | CSS class table, className contract, animation description |
| API | Props tables for all 10 sub-components |
| Edge cases | Viewport collision, nested sub-menus, focus management, disabled items |
| Related | Links to Popover, Button |

## Test coverage

Tests split into two co-located files following the `*.test.tsx` / `*.integration.test.tsx` convention:

**`DropdownMenu.test.tsx`** — 11 unit tests (no userEvent, static renders with `defaultOpen`):
- Content: renders when open, ref forwarding, className merge
- Item: destructive class
- CheckboxItem: indicator visible when checked, hidden when unchecked
- RadioGroup: marks selected item
- Separator: `sndq-separator` class
- Label: `sndq-menu-label` class + text content
- Sub: chevron icon renders, className merge on SubTrigger

**`DropdownMenu.integration.test.tsx`** — 7 integration tests (userEvent-driven):
- Trigger: click opens menu, Escape closes menu
- Item: onSelect fires on click, disabled item does not fire onSelect
- CheckboxItem: onCheckedChange fires on click
- RadioGroup: onValueChange fires when clicking different item
- Sub: sub-content opens on pointer enter

## Token/CSS changes

Changes to shared config (`packages/config/tailwind/`):

- **`.sndq-menu` shadow** — unified with Popover by switching to `var(--sndq-shadow-md)`
- **`.sndq-item` fully tokenized** — `gap: var(--sndq-space-3)`, `padding: var(--sndq-space-2) var(--sndq-space-3)`, `min-height: var(--sndq-h-sm)`, `font-weight: var(--font-weight-medium)`

## Review checklist

- [ ] Token classes match `components.css` definitions
- [ ] Icon component used consistently (no raw Lucide imports in JSX)
- [ ] Indicator `<span>` wrapper uses `pointer-events-none` + absolute positioning
- [ ] Animations use `data-[state]` / `data-[side]` selectors (no JS-driven animation)
- [ ] MDX live demos are `'use client'` and import from the barrel `index.ts`
- [ ] Unit tests are synchronous (no userEvent); integration tests use userEvent
- [ ] Shared token changes (`components.css`) do not break Popover or other consumers
