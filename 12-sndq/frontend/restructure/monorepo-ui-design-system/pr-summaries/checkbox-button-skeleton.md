# Checkbox, Button Icon & Skeleton — PR Summary

**Components:** `Checkbox` (new) · `Button` (update) · `Skeleton` (new) · **Tier:** 1 (Primitive)

---

## 1. Checkbox

### Design decisions

- **Radix foundation** — thin wrapper over `@radix-ui/react-checkbox`. Single `Checkbox` component; no compound parts exposed.
- **SNDQ token classes** — `.sndq-checkbox` applies sizing (`--sndq-selector`), radius (`--sndq-r-xs`), border, background, shadow, focus ring, and transitions. State styling driven by `data-state` attributes (`unchecked`, `checked`, `indeterminate`).
- **Icon usage** — `Icon` component with `size="xs"` and `text-sndq-action-fg`: `Check` for checked, `Minus` for indeterminate.
- **Indeterminate pattern** — uses Radix's native `checked="indeterminate"` directly (no custom prop).
- **Disabled states** — separate disabled styles for unchecked (`surface-muted`) vs checked/indeterminate (`border-strong` bg).
- **Slot attribute** — `data-slot="checkbox"` for consistent selector targeting.

### Documentation

MDX page at `apps/docs/content/docs/primitives/forms/checkbox.mdx`:

| Section | Content |
|---------|---------|
| Hero | Story playground + inline state demos (unchecked, checked, indeterminate, disabled) |
| Overview | Purpose, import, when to use / when not to use |
| States | All four visual states with code |
| Composition | Pairing with `Field` and `Label` for accessible form fields |
| Styling | Override-wins via CSS cascade, className contract |
| API | Props table (checked, disabled, onCheckedChange, className) + Radix pass-through |
| Token reference | 8 tokens (selector size, radius, action colors, shadow, ring) |
| Related | Links to Field, Input |

### Test coverage

**`Checkbox.test.tsx`** — 12 tests (8 unit + 4 interaction):
- Renders `<button>` with `data-slot="checkbox"` and `role="checkbox"`
- Applies `sndq-checkbox` base class
- className override-wins via cascade
- Forwards ref to button element
- Unchecked by default (`aria-checked="false"`)
- Spreads additional HTML attributes
- Checked state renders Check icon
- `checked="indeterminate"` renders Minus icon instead of Check
- Click toggles: fires `onCheckedChange(true)`
- Click checked: fires `onCheckedChange(false)`
- Keyboard Space toggles the checkbox
- Disabled prevents click interaction

**`Checkbox.integration.test.tsx`** — 1 integration test:
- Composition with Label: clicking label toggles checkbox

### Token/CSS changes

- **`semantic-tokens.css`** — new `--sndq-selector: 1.125rem` (18px) for checkbox/radio sizing
- **`tokens.css`** — new `--spacing-sndq-selector` utility mapping
- **`components.css`** — new `.sndq-checkbox` block with states for focus-visible, hover, checked, indeterminate, disabled

---

## 2. Button — Icon & Shape Props Update

### Design decisions

- **New props** — `icon` (`IconName | LucideIcon`), `iconPosition` (`'start' | 'end'`, default `'start'`), and `shape` (`'base' | 'square' | 'circle'`, default `'base'`).
- **Explicit shape prop** — `shape="square"` or `shape="circle"` applies `aspect-ratio: 1` via `.sndq-btn-square` / `.sndq-btn-circle` for icon-only sizing that works correctly at all size tiers (sm, md, lg). Replaces the previous `isIconOnly` auto-detection and `sndq-btn-icon` class.
- **`isCompact` removed** — the `isCompact` variable (`shape === "square" || shape === "circle"`) and its conditional branch in `resolveText` that suppressed children during loading were removed. Shape buttons should use the `icon` prop exclusively; text suppression during loading is the caller's concern.
- **Size-derived icon size** — `sm` buttons use `xs` icons; all other sizes use `sm` icons.
- **Loading integration** — spinner replaces the icon when `loading` is true; `resolveIcon` and `resolveText` helpers centralize the logic.
- **Icon map expansion** — 65+ icons in `icon-map.ts` (original 32 + 34 new entries). New entries cover: actions (trash, copy, download, upload, share, send, archive, bookmark, flag, star, link, refreshCw, externalLink, helpCircle, bell, fileText, clock, printer), navigation (arrowLeft, chevronUp), text formatting (bold, italic, underline, alignLeft/Center/Right, undo, redo), and layout (layoutList, layoutGrid, table, minus, moreVertical).
- **Icon-only button migration** — all `shape="square"` Buttons in `apps/ui-v2-dev/` migrated from icon children to the `icon` prop. Uses `IconName` strings where mapped, `LucideIcon` component types for unmapped icons (e.g. `Chrome`, `Github`).

### Documentation

Updated `apps/docs/content/docs/primitives/button.mdx`:

| Section | Content |
|---------|---------|
| Shape (new) | `shape` prop docs with CSS class table for `square` and `circle` |
| Icon buttons (updated) | Demos using `shape="square"` / `shape="circle"` for icon-only, icon+text, trailing icon, variant/size combos |
| API (updated) | `icon`, `iconPosition`, and `shape` props added; `size` no longer includes `'icon'` |

### Test coverage

**`Button.test.tsx`** — 7 new unit tests added:
- Renders an icon element when `icon` prop is provided
- Applies `sndq-btn-square` when `shape="square"`
- Applies `sndq-btn-circle` when `shape="circle"`
- Does not apply shape class when shape is base
- Places icon after text when `iconPosition="end"`
- Replaces icon with spinner when loading
- Renders smaller icon (`size-sndq-icon-xs`) for `size="sm"`

### Token/CSS changes

- **`components.css`** — replaced `.sndq-btn-icon` / `.sndq-btn-sm.sndq-btn-icon` with `.sndq-btn-square` and `.sndq-btn-circle` using `aspect-ratio: 1`.

---

## 3. Skeleton

### Design decisions

- **Fully custom** — pure `<div>` with no Radix or third-party dependency. No internal state.
- **Shape via className** — no dedicated size/shape props; width, height, and border-radius are controlled entirely by Tailwind utilities in `className`.
- **Shimmer animation** — `::after` pseudo-element with a translating gradient (`from-transparent via-sndq-surface-subtle to-transparent`). Registered as `animate-skeleton-shimmer` (1.5s ease-in-out infinite translateX).
- **Base classes** — `bg-sndq-surface-muted`, `rounded-md`, `overflow-hidden`, `relative`.
- **Slot attribute** — `data-slot="skeleton"` for consistent selector targeting.

### Documentation

MDX page at `apps/docs/content/docs/primitives/skeleton.mdx`:

| Section | Content |
|---------|---------|
| Hero | Composed card skeleton demo (text lines + avatar) |
| Overview | Purpose, import, when to use / when not to use |
| Usage | Basic loading card example |
| Shapes | 4 subsections: text lines, circle (avatar), rectangle (image/card), composed card |
| Override-wins | className examples (rounded-full, rounded-none, custom bg) |
| API | Single `className` prop + native `<div>` attributes |
| Token reference | 3 tokens (surface-muted, surface-subtle, skeleton-shimmer animation) |
| Related | Links to Badge, Button |

### Test coverage

**`Skeleton.test.tsx`** — 5 unit tests:
- Renders `<div>` with `data-slot="skeleton"`
- Applies base shimmer classes (`bg-sndq-surface-muted`, `overflow-hidden`)
- className override-wins via `cn()`
- Forwards ref to DOM element
- Spreads additional HTML attributes

No integration tests (no interactive behavior).

### Token/CSS changes

- **`animations.css`** — new `--animate-skeleton-shimmer` custom property and `@keyframes sndq-skeleton-shimmer` (translateX -100% to 100%)

---

## Review checklist

- [ ] Token classes match `components.css` definitions
- [ ] Icon component used consistently (no raw Lucide imports in JSX)
- [ ] `.sndq-checkbox` states cover all `data-state` + `:disabled` combos
- [ ] Button `shape` prop applies `sndq-btn-square` / `sndq-btn-circle` correctly
- [ ] Icon size derivation (`sm` button -> `xs` icon) is consistent
- [ ] Shared token changes (`semantic-tokens.css`, `tokens.css`) do not break existing consumers
- [ ] Skeleton shimmer animation registered in `animations.css` and does not conflict with existing keyframes
