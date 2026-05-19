# Vaul Drawer Architecture

> **Source**: [Vaul](https://github.com/emilkowalski/vaul) (`src/`)
> **Pattern type**: Dialog wrapper with imperative gesture layer
> **Complexity tier**: Medium — single-file core, feature hooks extracted, Radix Dialog dependency

---

## TL;DR

Vaul is a drawer component built on top of `@radix-ui/react-dialog`. It layers pointer/touch gesture handling, snap point logic, iOS scroll workarounds, and optional background scaling on top of Radix's modal primitives. All components and logic live in a single `index.tsx` (~1150 lines) with feature-specific hooks extracted to separate files. Nested drawers use an explicit `Drawer.NestedRoot` component that wires parent-child communication through three context callbacks. Style updates during drag bypass React entirely via imperative `element.style` mutations cached with a WeakMap.

---

## Key Concepts

| Concept | One-liner |
|---------|-----------|
| Radix Dialog composition | Wraps `@radix-ui/react-dialog` for modal/focus/dismiss behavior |
| Single-file components | Root, Content, Overlay, Handle, NestedRoot, Portal all in `index.tsx` |
| Flat context | One `DrawerContext` with all refs, handlers, snap state, nested callbacks |
| Explicit nesting | `Drawer.NestedRoot` wires parent callbacks — not implicit detection |
| Imperative DOM | `set()`/`reset()` with WeakMap-cached original styles for drag transforms |
| Feature hooks | `useSnapPoints`, `usePreventScroll`, `usePositionFixed`, `useScaleBackground` |
| Shipped CSS | `style.css` with `data-vaul-*` selectors, `--initial-transform`, `--snap-point-height` |

---

## Deep Dive

### 1. File structure

Vaul is compact — 12 source files, no subdirectories:

```
src/
├── index.tsx                # Root, Content, Overlay, Handle, NestedRoot, Portal (~1150 lines)
├── context.ts               # DrawerContext + useDrawerContext
├── types.ts                 # DrawerDirection, SnapPoint, AnyFunction
├── constants.ts             # Timing, thresholds, NESTED_DISPLACEMENT
├── helpers.ts               # set/reset (WeakMap), getTranslate, dampenValue, isVertical
├── browser.ts               # isIOS, isSafari, isMobileFirefox
├── use-controllable-state.ts # Radix-style controlled/uncontrolled state (fork)
├── use-composed-refs.ts     # composeRefs / useComposedRefs (Radix fork)
├── use-snap-points.ts       # Snap point geometry, drag, release, overlay fade
├── use-prevent-scroll.ts    # Body scroll prevention (React Spectrum fork)
├── use-position-fixed.ts    # iOS Safari body fixed positioning
├── use-scale-background.ts  # Scale [data-vaul-drawer-wrapper] element
└── style.css                # Attribute-driven animations, handle chrome
```

All components are defined in `index.tsx`. Hooks are extracted when they have substantial standalone logic (snap points, scroll prevention, iOS positioning, background scaling).

### 2. Radix Dialog composition

Vaul depends on `@radix-ui/react-dialog` and wraps its primitives:

```tsx
// Root renders Radix Dialog with DrawerContext wrapping
return (
  <DialogPrimitive.Root
    defaultOpen={defaultOpen}
    onOpenChange={(open) => {
      if (!dismissible && !open) return;
      if (open) setHasBeenOpened(true);
      else closeDrawer(true);
      setIsOpen(open);
    }}
    open={isOpen}
    modal={modal}
  >
    <DrawerContext.Provider value={contextValue}>
      {children}
    </DrawerContext.Provider>
  </DialogPrimitive.Root>
);
```

Note the provider order: Radix `DialogPrimitive.Root` is the outer wrapper, `DrawerContext.Provider` is inside. This is the inverse of Base UI's approach (where drawer context wraps dialog). The practical effect is the same: drawer-specific state is available to all child parts.

**Parts mapping:**

| Vaul component | Radix primitive | Customization |
|----------------|-----------------|---------------|
| `Drawer.Root` | `DialogPrimitive.Root` | Gesture handlers, snap points, nested callbacks |
| `Drawer.Content` | `DialogPrimitive.Content` | Pointer events for drag, CSS vars, `useScaleBackground` |
| `Drawer.Overlay` | `DialogPrimitive.Overlay` | Composed ref, snap-point data attributes |
| `Drawer.Portal` | `DialogPrimitive.Portal` | Container from context |
| `Drawer.Trigger` | `DialogPrimitive.Trigger` | Direct re-export, no wrapper |
| `Drawer.Close` | `DialogPrimitive.Close` | Direct re-export, no wrapper |
| `Drawer.Title` | `DialogPrimitive.Title` | Direct re-export, no wrapper |
| `Drawer.Description` | `DialogPrimitive.Description` | Direct re-export, no wrapper |
| `Drawer.Handle` | Custom `<div>` | Tap-to-cycle snap points, drag forwarding |
| `Drawer.NestedRoot` | `Root` (self) | Wires parent context callbacks |

### 3. Single flat context

Vaul uses one context for everything:

```tsx
interface DrawerContextValue {
  drawerRef: React.RefObject<HTMLDivElement>;
  overlayRef: React.RefObject<HTMLDivElement>;
  onPress: (event: React.PointerEvent<HTMLDivElement>) => void;
  onRelease: (event: React.PointerEvent<HTMLDivElement> | null) => void;
  onDrag: (event: React.PointerEvent<HTMLDivElement>) => void;
  onNestedDrag: (event: React.PointerEvent<HTMLDivElement>, percentageDragged: number) => void;
  onNestedOpenChange: (o: boolean) => void;
  onNestedRelease: (event: React.PointerEvent<HTMLDivElement>, open: boolean) => void;
  dismissible: boolean;
  isOpen: boolean;
  isDragging: boolean;
  keyboardIsOpen: React.MutableRefObject<boolean>;
  snapPointsOffset: number[] | null;
  snapPoints?: (number | string)[] | null;
  activeSnapPointIndex?: number | null;
  modal: boolean;
  shouldFade: boolean;
  activeSnapPoint?: number | string | null;
  setActiveSnapPoint: (o: number | string | null) => void;
  closeDrawer: () => void;
  direction: DrawerDirection;
  shouldScaleBackground: boolean;
  noBodyStyles: boolean;
  handleOnly?: boolean;
  container?: HTMLElement | null;
  autoFocus?: boolean;
  shouldAnimate?: React.RefObject<boolean>;
  // ... more fields
}
```

The default context is a full noop object (all handlers are `() => {}`, refs are `{ current: null }`). The `useDrawerContext` hook throws if context is missing, but since a default is always provided, the throw never fires in practice.

**Trade-off**: Flat context is simpler to understand but means every context consumer re-renders when any field changes, regardless of which fields it reads. Vaul mitigates this by keeping most high-frequency state in refs rather than context values.

### 4. Gesture handling

Gesture handling lives in `Root` and is forwarded to `Content` via context:

**Press** (`onPress`):
- Records pointer start position and time
- Sets `isDragging` state
- Calls `setPointerCapture` on target for smooth out-of-bounds dragging
- iOS-specific: adds `touchend` listener to clear drag allowance

**Drag** (`onDrag`):
- `shouldDrag` gate checks: `data-vaul-no-drag`, `SELECT` elements, text selection, 500ms cooldown after open, scrollable ancestor not at top, scroll lock timeout
- Sets `transition: none` on drawer element during drag
- Adds `vaul-dragging` CSS class
- Snap path delegates to `useSnapPoints.onDrag`
- Without snap points: rubber-band damping when dragging in the "open" direction via `dampenValue`
- Calculates `percentageDragged` for overlay opacity and nested parent coordination

**Release** (`onRelease`):
- Calculates velocity from distance/time
- Fast release (`velocity > VELOCITY_THRESHOLD`): close immediately
- Slow release: check if displacement exceeds `CLOSE_THRESHOLD` (25% of visible dimension)
- Snap path delegates to `useSnapPoints.onRelease`
- `justReleased` flag briefly true after fast flick to prevent input focus

### 5. Imperative DOM updates with WeakMap cache

Vaul's `set`/`reset` helpers write styles imperatively and cache originals:

```tsx
const cache = new WeakMap();

export function set(
  el: Element | HTMLElement | null | undefined,
  styles: Style,
  ignoreCache = false,
) {
  if (!el || !(el instanceof HTMLElement)) return;
  let originalStyles: Style = {};

  Object.entries(styles).forEach(([key, value]) => {
    if (key.startsWith('--')) {
      el.style.setProperty(key, value);
      return;
    }
    originalStyles[key] = (el.style as any)[key];
    (el.style as any)[key] = value;
  });

  if (ignoreCache) return;
  cache.set(el, originalStyles);
}

export function reset(el: Element | HTMLElement | null, prop?: string) {
  if (!el || !(el instanceof HTMLElement)) return;
  let originalStyles = cache.get(el);
  if (!originalStyles) return;

  if (prop) {
    (el.style as any)[prop] = originalStyles[prop];
  } else {
    Object.entries(originalStyles).forEach(([key, value]) => {
      (el.style as any)[key] = value;
    });
  }
}
```

This pattern enables:
- Direct style mutation during drag (bypasses React reconciliation)
- Clean restoration of original styles on reset
- CSS custom properties handled via `setProperty` (the `--` prefix check)
- WeakMap ensures no memory leaks when elements are garbage collected

### 6. Snap points (`useSnapPoints`)

The snap point hook manages:

**Resolution**: Snap point values can be fractions (0-1) of container size or pixel strings (e.g., `"300px"`). Resolved to absolute translate offsets via `snapPointsOffset` memo.

**Controlled/uncontrolled**: Uses `useControllableState` (Radix fork) for `activeSnapPoint`.

**Drag**: Clamps movement so user cannot drag past the largest snap point.

**Release**: Three-tier logic:
1. High velocity (`> 2`) without `snapToSequentialPoint`: jump to first or last snap
2. Medium velocity (`> VELOCITY_THRESHOLD`) within 40% of dimension: move one snap in drag direction
3. Low velocity: snap to closest point by distance

**Overlay fade**: `fadeFromIndex` determines at which snap point the overlay starts fading. `getPercentageDragged` returns a 0-1 value for overlay opacity interpolation during drag.

```tsx
// Snap to a specific dimension — imperative transform + overlay opacity
const snapToPoint = React.useCallback((dimension: number) => {
  set(drawerRef.current, {
    transition: `transform ${TRANSITIONS.DURATION}s cubic-bezier(...)`,
    transform: isVertical(direction)
      ? `translate3d(0, ${dimension}px, 0)`
      : `translate3d(${dimension}px, 0, 0)`,
  });

  // Overlay opacity based on fadeFromIndex
  if (newSnapPointIndex < fadeFromIndex) {
    set(overlayRef.current, { opacity: '0', transition: '...' });
  } else {
    set(overlayRef.current, { opacity: '1', transition: '...' });
  }

  setActiveSnapPoint(snapPoints?.[Math.max(newSnapPointIndex, 0)]);
}, [/* deps */]);
```

### 7. Nested drawer coordination

Vaul uses an explicit `NestedRoot` component for nesting:

```tsx
export function NestedRoot({ onDrag, onOpenChange, open, ...rest }: DialogProps) {
  const { onNestedDrag, onNestedOpenChange, onNestedRelease } = useDrawerContext();

  if (!onNestedDrag) {
    throw new Error('Drawer.NestedRoot must be placed in another drawer');
  }

  return (
    <Root
      nested
      open={open}
      onClose={() => onNestedOpenChange(false)}
      onDrag={(e, p) => {
        onNestedDrag(e, p);
        onDrag?.(e, p);
      }}
      onOpenChange={(o) => {
        if (o) onNestedOpenChange(o);
        onOpenChange?.(o);
      }}
      onRelease={onNestedRelease}
      {...rest}
    />
  );
}
```

The parent defines three handlers in its `Root`:

**`onNestedOpenChange(open)`**: When nested opens, parent drawer scales down and shifts by `NESTED_DISPLACEMENT` (16px). When nested closes, after a 500ms timeout, parent removes the scale and restores pure translate to preserve swipe offset.

```tsx
function onNestedOpenChange(o: boolean) {
  const scale = o
    ? (window.innerWidth - NESTED_DISPLACEMENT) / window.innerWidth
    : 1;
  const initialTranslate = o ? -NESTED_DISPLACEMENT : 0;

  set(drawerRef.current, {
    transition: `transform ${TRANSITIONS.DURATION}s cubic-bezier(...)`,
    transform: isVertical(direction)
      ? `scale(${scale}) translate3d(0, ${initialTranslate}px, 0)`
      : `scale(${scale}) translate3d(${initialTranslate}px, 0, 0)`,
  });

  if (!o && drawerRef.current) {
    nestedOpenChangeTimer.current = setTimeout(() => {
      const translateValue = getTranslate(drawerRef.current, direction);
      set(drawerRef.current, {
        transition: 'none',
        transform: `translate3d(0, ${translateValue}px, 0)`,
      });
    }, 500);
  }
}
```

**`onNestedDrag(event, percentageDragged)`**: While child drags, parent interpolates between nested-open scale/translate and full-size, creating a "connected stack" visual.

```tsx
function onNestedDrag(_event, percentageDragged) {
  if (percentageDragged < 0) return;
  const initialScale = (window.innerWidth - NESTED_DISPLACEMENT) / window.innerWidth;
  const newScale = initialScale + percentageDragged * (1 - initialScale);
  const newTranslate = -NESTED_DISPLACEMENT + percentageDragged * NESTED_DISPLACEMENT;

  set(drawerRef.current, {
    transform: `scale(${newScale}) translate3d(0, ${newTranslate}px, 0)`,
    transition: 'none',
  });
}
```

**`onNestedRelease(event, open)`**: If nested stays open after release, parent re-applies nested scale with transition. If nested closes, the path goes through `onNestedOpenChange(false)`.

**Limitations**:
- Only one level of explicit nesting is designed for — `NestedRoot` reads its immediate parent's context, but there is no propagation chain for deeper nesting
- No height reporting — parent does not know nested drawer's height
- No swipe progress propagation — parent interpolates based on `percentageDragged` during drag, but there is no continuous store for other consumers
- The `nested` boolean flag on `Root` skips `usePositionFixed` cleanup and open-state restoration for iOS compatibility

### 8. iOS/Safari workarounds

**`usePositionFixed`**: On iOS Safari, applies `position: fixed` to `<body>` while the drawer is open (non-nested only). Preserves scroll position by setting `top: -scrollY`. Cleans up only when no other `[data-vaul-drawer]` elements exist.

**`usePreventScroll`**: Fork of React Spectrum's scroll prevention. Handles:
- iOS Safari focus-scroll: when keyboard opens, prevents the page from scrolling behind the drawer
- Input repositioning: when `repositionInputs` is enabled and snap points are used, repositions inputs instead of scrolling them into view
- `visualViewport` resize listener for keyboard detection

### 9. Background scaling (`useScaleBackground`)

Optional visual effect that scales the page content when a drawer opens:

```tsx
export function useScaleBackground() {
  const { isOpen, shouldScaleBackground, direction } = useDrawerContext();

  React.useEffect(() => {
    if (isOpen && shouldScaleBackground) {
      const wrapper = document.querySelector('[data-vaul-drawer-wrapper]');
      if (!wrapper) return;

      // Scale wrapper down, add border radius, set body background to black
      assignStyle(wrapper, {
        transform: `scale(${getScale()}) translate3d(0, calc(env(safe-area-inset-top) + 14px), 0)`,
        borderRadius: `${BORDER_RADIUS}px`,
        overflow: 'hidden',
      });

      return () => { /* restore styles */ };
    }
  }, [isOpen, shouldScaleBackground]);
}
```

Consumer marks the wrapper: `<div data-vaul-drawer-wrapper>`. The scale factor is `(window.innerWidth - 26) / window.innerWidth`.

### 10. CSS and data attributes

Vaul ships a `style.css` with attribute-driven selectors:

**CSS custom properties:**
- `--initial-transform`: Default `100%`, used in enter/exit keyframes
- `--snap-point-height`: Set inline on Content when snap points are active

**Data attributes:**
- `data-vaul-drawer` — on content element
- `data-vaul-drawer-direction` — `top`, `bottom`, `left`, `right`
- `data-vaul-overlay` — on overlay
- `data-vaul-snap-points` — `true`/`false`
- `data-vaul-snap-points-overlay` — controls overlay fade
- `data-vaul-delayed-snap-points` — applied after rAF for initial transition
- `data-vaul-animate` — controls whether CSS transitions apply
- `data-vaul-handle` — on drag handle
- `data-vaul-custom-container` — `true` when using custom container
- `data-vaul-drawer-wrapper` — consumer-applied, targets background scaling
- `data-vaul-no-drag` — consumer-applied, prevents drag on specific elements

**Key CSS rules:**
- `touch-action: none` on drawer content
- `will-change: transform` for GPU compositing
- `::after` pseudo-element extends drag area beyond safe-area

### 11. Public API

```tsx
export const Drawer = {
  Root,
  NestedRoot,
  Content,
  Overlay,
  Trigger: DialogPrimitive.Trigger,
  Portal,
  Handle,
  Close: DialogPrimitive.Close,
  Title: DialogPrimitive.Title,
  Description: DialogPrimitive.Description,
};
```

**Root props** (key subset):

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `open` | `boolean` | - | Controlled open state |
| `defaultOpen` | `boolean` | `false` | Uncontrolled initial state |
| `onOpenChange` | `(open: boolean) => void` | - | Open state callback |
| `snapPoints` | `(number \| string)[]` | - | Snap positions (fractions or px) |
| `activeSnapPoint` | `number \| string \| null` | - | Controlled active snap |
| `fadeFromIndex` | `number` | last | Overlay fade threshold |
| `direction` | `DrawerDirection` | `'bottom'` | Swipe direction |
| `modal` | `boolean` | `true` | Modal behavior |
| `dismissible` | `boolean` | `true` | Allow close via interaction |
| `handleOnly` | `boolean` | `false` | Restrict drag to Handle |
| `shouldScaleBackground` | `boolean` | `false` | Scale wrapper on open |
| `nested` | `boolean` | `false` | Internal: is this a nested drawer |
| `closeThreshold` | `number` | `0.25` | Fraction of height to trigger close |
| `scrollLockTimeout` | `number` | `500` | ms to disable drag after scroll |
| `fixed` | `boolean` | `false` | Prevent upward shift for keyboard |
| `noBodyStyles` | `boolean` | `false` | Skip body style modifications |

---

## Trade-offs & When to Use

| Approach | Pros | Cons |
|----------|------|------|
| Radix Dialog dependency | Proven focus/dismiss/modal behavior, ecosystem compatibility | Locked to Radix API surface and update cadence |
| Single-file components | Easy to navigate, quick to understand | Harder to tree-shake, large single file |
| Flat context | Simple mental model, one provider | All consumers re-render on any change |
| Explicit NestedRoot | Clear API — nesting is intentional | Limited to 1 level, no propagation chain |
| WeakMap style cache | Clean restore, no leak risk | Only caches last set of styles per element |
| Shipped CSS | Works out of the box, consistent defaults | Consumers must override or suppress defaults |
| Imperative transforms | 60fps drag, no React reconciliation | Harder to debug, split between React and DOM |

**When to use Vaul's architecture:**

- Building on top of Radix UI and want ecosystem compatibility
- Simple drawer use cases with optional single-level nesting
- Quick integration — shipped CSS provides working defaults
- Mobile-first with iOS workarounds baked in

**When it falls short:**

- Deep nesting (3+ levels) — no propagation chain
- Headless/unstyled library approach — shipped CSS creates coupling
- Large design systems needing per-part tree-shaking
- Need for app-level drawer coordination (no Provider equivalent)

---

## References

- [Vaul GitHub](https://github.com/emilkowalski/vaul)
- [Vaul docs](https://vaul.emilkowal.ski/)
- [Radix UI Dialog](https://www.radix-ui.com/primitives/docs/components/dialog)

---

## My Notes

- Vaul's strength is pragmatism. The single-file approach with Radix dependency means you get a working drawer fast. The trade-off is scalability — the flat context, lack of a propagation chain for nesting, and single-file structure become limiting at design-system scale.
- The `NestedRoot` pattern is elegant for the common case (one nested drawer) but does not generalize. If you need drawers-in-drawers-in-drawers, you need Base UI's implicit detection via `useDrawerRootContext(true)`.
- The WeakMap style cache in `set`/`reset` is a practical alternative to Base UI's pub/sub stores. It is simpler but less flexible — you can only restore to the state at the time of `set`, whereas a pub/sub store can drive arbitrary consumers.
- The 500ms timeout in `onNestedOpenChange` for removing scale after nested close is a brittle pattern — it assumes the CSS transition duration. Base UI avoids this by using transition lifecycle callbacks.
- `usePreventScroll` and `usePositionFixed` represent significant iOS-specific complexity. Any drawer implementation targeting mobile must solve these problems. Vaul's approach (fork React Spectrum) is pragmatic; Base UI handles it differently via its dialog viewport.
