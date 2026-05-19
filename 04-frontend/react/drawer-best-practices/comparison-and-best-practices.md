# Drawer Implementation Comparison and Best Practices

> **Comparing**: [Base UI Drawer](./base-ui-drawer-architecture.md) vs [Vaul](./vaul-drawer-architecture.md)
> **Focus**: Nested drawer implementation, extensibility, and maintainability

---

## TL;DR

Both Base UI and Vaul validate the fundamental pattern: **a drawer is a dialog with gesture physics layered on top**. They diverge on decomposition (granular compound components vs single-file), context strategy (3-tier layered vs flat blob), and nested drawer coordination (implicit N-level propagation vs explicit single-level `NestedRoot`). This document compares both approaches dimension by dimension, then synthesizes best practices for building a production drawer — with particular depth on nested drawer implementation.

---

## Architecture Comparison

### Overall structure

| Dimension | Base UI | Vaul |
|-----------|---------|------|
| Base primitive | Own Dialog implementation (internal) | `@radix-ui/react-dialog` (external dep) |
| File structure | 1 folder per part, ~35 files | Single `index.tsx` + hook files, ~12 files |
| Component count | 15 parts (Root, Popup, Viewport, Backdrop, Content, Indent, IndentBackground, SwipeArea, Provider, Trigger, Close, Portal, Title, Description, Handle) | 10 parts (Root, NestedRoot, Content, Overlay, Handle, Portal, Trigger, Close, Title, Description) |
| Lines of core logic | ~1375 (DrawerViewport) + ~485 (DrawerPopup) + ~485 (DrawerRoot) | ~1150 (index.tsx) + ~290 (use-snap-points) |
| Bundle approach | Tree-shakeable per part | Single module |

### Context design

| Aspect | Base UI | Vaul |
|--------|---------|------|
| Layers | 3: Root → Viewport → Provider | 1: flat DrawerContext |
| Update isolation | Each layer only triggers re-renders for its consumers | All consumers re-render on any context change |
| High-frequency data | Pub/sub stores (bypass React) | Refs (bypass React state, but context consumers still receive the values) |
| Default value | `undefined` (required consumption throws) | Full noop object (throw guard is dead code) |
| Optional consumption | `useContext(true)` returns `undefined`, TypeScript narrows | Not supported — context always provides defaults |

### Styling API

| Aspect | Base UI | Vaul |
|--------|---------|------|
| CSS variables | Enum-typed per part (`DrawerPopupCssVars`, `DrawerBackdropCssVars`) | Inline strings (`--snap-point-height`, `--initial-transform`) |
| Data attributes | Enum-typed per part with mapping objects | Inline `data-vaul-*` strings |
| Style delivery | Headless — no shipped CSS | Shipped `style.css` with defaults |
| Performance | `CSS.registerProperty` with `inherits: false` | No CSS property registration |
| State → attribute | Centralized `stateAttributesMapping` functions | Inline ternaries in JSX |

### Type system

| Aspect | Base UI | Vaul |
|--------|---------|------|
| Pattern | `export namespace DrawerPopup { Props, State }` per part | Inline interfaces in `index.tsx` |
| Base props | `BaseUIComponentProps<'div', State>` | `React.ComponentPropsWithoutRef<typeof RadixPrimitive>` |
| Event details | Typed `ChangeEventDetails` with `reason`, `isCanceled`, `preventUnmountOnClose` | Simple `(open: boolean) => void` callback |
| Generics | `DrawerRoot.Props<Payload>` for render prop payloads | No generics |

### Performance

| Technique | Base UI | Vaul |
|-----------|---------|------|
| Drag updates | `element.style.setProperty()` via pub/sub store listeners | `set()` helper with WeakMap cache |
| CSS var inheritance | `CSS.registerProperty` with `inherits: false` | Not used |
| Height measurement | `ResizeObserver` | `getBoundingClientRect` on demand |
| Layout effect | `useIsoLayoutEffect` (SSR-safe) | Standard `React.useEffect` |
| Callback stability | `useStableCallback` (stable ref wrapper) | `React.useCallback` |
| Window resize | `ResizeObserver` on viewport element | `window.addEventListener('resize')` |

---

## Nested Drawer Deep Dive

### How each library handles nesting

#### Vaul: Explicit `NestedRoot`

```
Drawer.Root (parent)
  └── DrawerContext.Provider
        ├── onNestedDrag
        ├── onNestedOpenChange
        ├── onNestedRelease
        │
        └── Drawer.NestedRoot (child)
              └── Root (with nested=true)
                    ├── onClose → parent.onNestedOpenChange(false)
                    ├── onDrag → parent.onNestedDrag + user.onDrag
                    ├── onOpenChange → parent.onNestedOpenChange(true)
                    └── onRelease → parent.onNestedRelease
```

**Flow when nested drawer opens:**
1. User triggers nested open
2. `NestedRoot.onOpenChange` calls `parent.onNestedOpenChange(true)`
3. Parent scales down by `NESTED_DISPLACEMENT` (16px) with eased transition
4. Parent's transform: `scale(0.97) translate3d(0, -16px, 0)` (for bottom drawer)

**Flow during nested drag:**
1. `Content.onPointerMove` calls `onDrag` on child `Root`
2. Child calculates `percentageDragged` and calls `parent.onNestedDrag(event, percentageDragged)`
3. Parent interpolates between scaled-down state and full-size: `newScale = 0.97 + percentageDragged * 0.03`

**Flow when nested closes:**
1. Nested `onClose` calls `parent.onNestedOpenChange(false)`
2. Parent transitions scale back to `1` and translate back to `0`
3. After 500ms timeout, parent strips the scale and applies pure translate to preserve any existing swipe offset

**Limitations:**
- `NestedRoot` reads only the immediate parent context — no propagation chain
- If you nest `NestedRoot` inside another `NestedRoot`, the middle drawer has no way to relay swipe/open signals from the innermost to the outermost
- Parent does not know nested drawer's measured height — it uses a fixed 16px displacement
- The 500ms timeout for removing scale assumes CSS transition duration, making it brittle
- No app-level coordination — no way to know if "any drawer" is open

#### Base UI: Implicit nesting via context detection

```
DrawerRoot (parent)
  └── DrawerRootContext.Provider
        ├── onNestedFrontmostHeightChange
        ├── onNestedSwipingChange
        ├── onNestedSwipeProgressChange
        ├── onNestedDrawerPresenceChange
        │
        └── DrawerRoot (child — same component, detects parent)
              reads parent via useDrawerRootContext(true)
              extracts notifyParent* callbacks
              │
              └── DrawerPopup
                    ├── notifyParentFrontmostHeight(height) on mount
                    ├── notifyParentHasNestedDrawer(present) on mount/unmount
                    └── DrawerViewport
                          ├── notifyParentSwipingChange(swiping) during drag
                          └── notifyParentSwipeProgressChange(progress) during drag
```

**Flow when nested drawer opens:**
1. Child `DrawerRoot` reads parent context (same component — no `NestedRoot` needed)
2. `DrawerPopup` mounts, reports height via `notifyParentFrontmostHeight(height)`
3. `DrawerPopup` reports presence via `notifyParentHasNestedDrawer(true)`
4. Parent updates `frontmostHeight` and `hasNestedDrawer` state
5. Parent popup adjusts visual presentation based on nested state

**Flow during nested drag:**
1. Child `DrawerViewport` handles swipe physics
2. Reports progress via `notifyParentSwipeProgressChange(progress)` — propagates up the chain
3. Reports swiping state via `notifyParentSwipingChange(swiping)`
4. Parent subscribes to `nestedSwipeProgressStore` and syncs to DOM without re-renders

**Flow when nested closes:**
1. Child `DrawerPopup` cleanup calls `notifyParentHasNestedDrawer(false)` and `notifyParentFrontmostHeight(0)`
2. Parent restores its own height as frontmost
3. Transition lifecycle handled by dialog, not a timeout

**N-level nesting:**
```
Drawer A (root)
  └── reads parent context → undefined (top level)
  └── Drawer B (nested)
        └── reads parent context → Drawer A's context
        └── notifyParent* → Drawer A receives
        └── Drawer C (deeply nested)
              └── reads parent context → Drawer B's context
              └── notifyParent* → Drawer B receives → B relays to A
```

Each `notifyParent*` callback in the middle drawer both updates its own state AND calls the parent's notification:

```tsx
const onNestedSwipeProgressChange = useStableCallback((progress: number) => {
  nestedSwipeProgressStore.set(progress);
  notifyParentSwipeProgressChange?.(progress); // relay up the chain
});
```

**Advantages:**
- Same `DrawerRoot` component at every level — no separate `NestedRoot`
- N-level propagation via callback chaining
- Height-aware — parent knows the exact measured height of the nested drawer
- Continuous swipe progress via pub/sub store (no re-renders)
- Transition lifecycle managed by dialog (no hardcoded timeouts)
- Optional `DrawerProvider` for app-level coordination ("is any drawer open?")

### Comparison summary

| Aspect | Vaul | Base UI |
|--------|------|---------|
| Nesting API | Explicit `Drawer.NestedRoot` | Same `Drawer.Root` with implicit detection |
| Nesting depth | 1 level (designed) | N levels (propagation chain) |
| Parent visual effect | Scale + translate with fixed 16px | Flexible — driven by measured height |
| Drag coordination | `percentageDragged` callback | Pub/sub store + direct DOM sync |
| Height awareness | No — fixed displacement | Yes — `ResizeObserver` measurements |
| Swipe progress | Per-drag callback only | Continuous pub/sub store |
| Transition timing | 500ms hardcoded timeout | Dialog transition lifecycle |
| App-level coordination | None | `DrawerProvider` + `DrawerProviderReporter` |
| Complexity | Low | High |

---

## Best Practices for Building a Drawer

### 1. Always compose a dialog primitive

Both libraries validate this: **do not build modal behavior from scratch**. A drawer needs focus trapping, scroll locking, outside-press dismissal, escape key handling, `aria-*` attributes, and transition lifecycle. Use an existing dialog as the foundation.

**Decision**: Use your own dialog if you control the design system (like Base UI). Use Radix Dialog if you want ecosystem compatibility (like Vaul).

### 2. Separate gesture logic from presentation

Extract swipe/drag physics into dedicated hooks or modules. Keep the visual component (popup/content) focused on rendering and styling.

```
Good:
  DrawerViewport — owns swipe physics, touch-scroll negotiation
  DrawerPopup — owns rendering, CSS vars, height measurement

Bad:
  DrawerContent — owns drag handlers, snap math, AND rendering
```

Vaul puts gesture logic in Root (handlers) + Content (pointer events) + useSnapPoints (snap math). Base UI isolates it entirely in DrawerViewport. The Base UI approach is cleaner for testing and reuse.

### 3. Design context for your nesting depth

**If you only need single-level nesting** (most apps):
- Vaul's flat context + explicit `NestedRoot` is simpler and sufficient
- Three callbacks: `onNestedDrag`, `onNestedOpenChange`, `onNestedRelease`

**If you need N-level nesting or app-level coordination**:
- Base UI's 3-tier context + implicit detection is necessary
- Each drawer reads parent context optionally, extracts `notifyParent*` callbacks
- Middle drawers relay signals upward via callback chaining
- Add a Provider tier for cross-instance coordination

**Regardless of depth, these parent/child signals are required:**

| Signal | Direction | Purpose |
|--------|-----------|---------|
| Open/close state | Child → Parent | Parent adjusts visual (scale, translate) |
| Drag progress | Child → Parent | Parent interpolates during child drag |
| Release result | Child → Parent | Parent knows if child stayed open or closed |
| Presence | Child → Parent | Parent knows when nested unmounts (including transition) |
| Height (optional) | Child → Parent | Parent adjusts displacement based on actual size |
| Swipe progress (optional) | Child → Parent | Continuous store for parent backdrop/indent effects |

### 4. Bypass React for high-frequency DOM updates

Both libraries agree: **do not use React state for values that change at 60fps during drag**.

**Minimum viable approach** (Vaul):
```tsx
// Direct element.style mutation during drag
set(drawerRef.current, {
  transform: `translate3d(0, ${value}px, 0)`,
  transition: 'none',
});
```

**Optimal approach** (Base UI):
```tsx
// Pub/sub store → layout effect → style.setProperty
const store = createStore();
store.subscribe(() => {
  element.style.setProperty('--drawer-swipe-progress', `${store.getSnapshot()}`);
});
```

The pub/sub approach is better for multiple consumers (backdrop, indent, parent drawer) that need the same value without coupling to each other.

### 5. Register CSS custom properties for performance

If your drawer uses CSS variables for transforms/opacity during drag, register them with `inherits: false`:

```tsx
CSS.registerProperty({
  name: '--drawer-swipe-movement-y',
  syntax: '<length>',
  inherits: false,
  initialValue: '0px',
});
```

This prevents the browser from invalidating styles on the entire subtree when the variable changes. Only Base UI does this — Vaul takes the performance hit. For simple drawers it does not matter; for drawers with deep content trees it is significant.

### 6. Handle snap point release with velocity

Both libraries use velocity-based release logic. The pattern:

```
if (velocity > HIGH_THRESHOLD) → jump to first or last snap
if (velocity > MEDIUM_THRESHOLD) → move one snap in drag direction
else → snap to closest point by distance
```

Add `snapToSequentialPoint` option to disable velocity-based skipping for cases where the user should only move one step at a time.

### 7. Solve iOS/Safari scroll issues

Any production drawer must handle:
- **Body scroll lock**: Prevent background scrolling when drawer is open
- **iOS `position: fixed`**: Safari requires body fixed positioning to prevent scroll bounce
- **Keyboard resize**: `visualViewport` changes when keyboard opens; drawer must adapt
- **Safe area**: Account for `env(safe-area-inset-*)` in transforms and padding
- **Scroll-then-drag**: Add a cooldown (`scrollLockTimeout`) after scrolling inside the drawer before allowing drag-to-dismiss

### 8. Use data attributes as the styling contract

Both libraries expose drawer state via data attributes for CSS-only styling:

```css
/* State-driven styling without JS */
[data-swiping] { cursor: grabbing; }
[data-expanded] { border-radius: 0; }
[data-vaul-snap-points="true"] { /* snap-specific styles */ }
```

Best practice: define attribute names in enum/constant files (Base UI pattern) rather than inline strings (Vaul pattern). This catches typos at compile time.

---

## Nested Drawer Implementation Checklist

When implementing nested drawers, ensure these behaviors:

### Parent responsibilities
- [ ] Detect when a nested drawer opens and scale/translate to indicate stacking
- [ ] Interpolate transform during child drag to create connected motion
- [ ] Restore transform when nested drawer closes
- [ ] Track `hasNestedDrawer` to prevent height changes while nested is open
- [ ] Track `nestedSwiping` to suppress parent interactions during child swipe
- [ ] Handle transition timing via lifecycle callbacks (not hardcoded timeouts)

### Child responsibilities
- [ ] Report open/close state to parent
- [ ] Report drag progress to parent during swipe
- [ ] Report release result (stayed open vs closed) to parent
- [ ] Report measured height to parent (if height-aware nesting is needed)
- [ ] Skip body/scroll workarounds when `nested=true` (parent handles them)
- [ ] Forward swipe progress for continuous visual effects (backdrop, indent)

### Architecture requirements
- [ ] Parent callbacks must be stable (wrapped in `useStableCallback` or `useCallback`)
- [ ] Use optional context consumption for parent detection (allow standalone use)
- [ ] For N-level nesting: relay signals upward in each callback handler
- [ ] For app-level coordination: add a Provider that tracks open state across all drawers
- [ ] Keep z-ordering simple — nested portals naturally stack via DOM order

### Testing considerations
- [ ] Test standalone drawer (no parent)
- [ ] Test single-level nesting (parent + child)
- [ ] Test nested close does not break parent position/height
- [ ] Test nested drag interpolation on parent
- [ ] Test Dialog inside Drawer is not misclassified as nested drawer
- [ ] Test transition cleanup (no lingering transforms after close)

---

## Decision Matrix: Which Approach to Follow

| Scenario | Recommended | Why |
|----------|-------------|-----|
| Simple app drawer, single level nesting | Vaul pattern | Less complexity, explicit API |
| Design system component | Base UI pattern | Extensible, tree-shakeable, N-level nesting |
| Radix-based app | Vaul pattern | Ecosystem compatibility |
| Need app-shell coordination (indent effects) | Base UI pattern | Provider + visual state store |
| Performance-critical (deep DOM trees) | Base UI pattern | `CSS.registerProperty`, pub/sub stores |
| Quick prototype | Vaul pattern | Working drawer in minutes with shipped CSS |
| Headless/unstyled library | Base UI pattern | No shipped CSS, data attributes + CSS vars |

---

## References

- [Base UI Drawer Architecture](./base-ui-drawer-architecture.md) — full analysis
- [Vaul Drawer Architecture](./vaul-drawer-architecture.md) — full analysis
- [Base UI Drawer docs](https://base-ui.com/react/components/drawer)
- [Vaul docs](https://vaul.emilkowal.ski/)
- [CSS custom property performance — Motion.dev](https://motion.dev/blog/web-animation-performance-tier-list)
