# Drawer Component Architecture — Best Practices

> **Source**: [Base UI Drawer](https://github.com/mui/base-ui) (`packages/react/src/drawer/`)
> **Pattern type**: Compound component with gesture physics
> **Complexity tier**: High — composition, nested coordination, performance-critical animations

---

## TL;DR

A well-architected drawer is a **specialization of a dialog**, not a standalone component. The Base UI implementation demonstrates how to build complex interactive components by **composing** an existing primitive (Dialog) rather than forking it, using a **3-tier context architecture** for state distribution, **lightweight pub/sub stores** for high-frequency animation data, and **CSS custom properties** as the public styling API. These patterns generalize to any compound component that combines modal behavior with gesture-driven physics.

---

## Key Concepts

| Concept | One-liner |
|---------|-----------|
| Composition over inheritance | Drawer wraps Dialog.Root — one store, one interaction stack |
| Compound component | Namespace API: `Drawer.Root`, `Drawer.Popup`, `Drawer.Viewport`, etc. |
| 3-tier context | Root (drawer state) → Viewport (swipe state) → Provider (app coordination) |
| Pub/sub store | `getSnapshot/subscribe/set` pattern for high-frequency data without re-renders |
| CSS custom properties | `--drawer-swipe-movement-y` etc. as the consumer styling contract |
| `CSS.registerProperty` | `inherits: false` to cut deep-subtree style recalc |
| Data attributes | `data-swiping`, `data-expanded`, etc. derived from state via mapping objects |
| Alias pattern | Thin parts like `Close`, `Title` cast Dialog parts to Drawer types |

---

## Deep Dive

### 1. Component tree and file structure

```
drawer/
├── root/                  # DrawerRoot + context + snap point hook
├── viewport/              # Swipe physics, touch-scroll negotiation
├── popup/                 # Focus-managed surface, CSS vars, height measurement
├── backdrop/              # Overlay with swipe progress
├── content/               # Marker div for swipe hit-testing
├── provider/              # Optional app-level drawer coordination
├── indent/                # App shell wrapper reacting to drawer open state
├── indent-background/     # Sibling layer for indent effects
├── swipe-area/            # Invisible edge strip for swipe-to-open
├── trigger/               # Alias → DialogTrigger
├── close/                 # Alias → DialogClose
├── portal/                # Alias → DialogPortal
├── title/                 # Alias → DialogTitle
├── description/           # Alias → DialogDescription
├── index.ts               # Barrel: namespace export + type re-exports
└── index.parts.ts         # Maps internal names to short compound names
```

Each part gets its own folder with:
- `ComponentName.tsx` — the component
- `ComponentNameDataAttributes.ts` — data attribute enum (if applicable)
- `ComponentNameCssVars.ts` — CSS variable enum (if applicable)
- `ComponentName.test.tsx` — tests co-located with source

**Typical render tree:**

```
Drawer.Root                  ← context setup, wraps Dialog.Root
  Drawer.Trigger             ← aliased DialogTrigger
  Drawer.Portal              ← aliased DialogPortal
    Drawer.Backdrop          ← overlay, swipe progress CSS vars
    Drawer.Viewport          ← swipe physics + scroll locking
      Drawer.Popup           ← focus-managed surface, height measurement
        Drawer.Title         ← aliased DialogTitle
        Drawer.Description   ← aliased DialogDescription
        Drawer.Content       ← marker div
        Drawer.Close         ← aliased DialogClose
```

### 2. Composition over inheritance

The central architectural decision: **DrawerRoot wraps Dialog.Root** instead of duplicating modal/focus/dismiss logic.

```tsx
// DrawerRoot.tsx — the key pattern
return (
  <DrawerRootContext.Provider value={contextValue}>
    <IsDrawerContext.Provider value>
      <Dialog.Root
        open={openProp}
        defaultOpen={defaultOpen}
        onOpenChange={handleOpenChange}
        modal={modal}
        // ... other dialog props forwarded directly
      >
        {children}
      </Dialog.Root>
    </IsDrawerContext.Provider>
  </DrawerRootContext.Provider>
);
```

**How it works:**

1. `DrawerRoot` sets up drawer-specific context (swipe direction, snap points, nested coordination)
2. `IsDrawerContext.Provider value` (boolean `true`) marks the subtree as a drawer
3. `Dialog.Root` handles the shared modal concern: open/close state, focus trapping, outside-press dismissal, scroll lock, transition lifecycle
4. Dialog internals can branch on `isDrawer` where behavior must differ without tight coupling

**Decision framework — when to alias vs create new:**

| Strategy | When to use | Drawer examples |
|----------|------------|-----------------|
| **Type alias** | Part has identical behavior to the base | `Close`, `Trigger`, `Title`, `Description`, `Portal` |
| **Wrap base part** | Part needs the base behavior plus extras | `Viewport` wraps `DialogViewport` + adds swipe |
| **New component** | No base equivalent exists | `Content`, `Indent`, `SwipeArea`, `Provider` |

The alias pattern is a type cast:

```tsx
// DrawerClose.tsx — complete file, 32 lines total
export const DrawerClose = DialogClose as DrawerClose;

export interface DrawerCloseProps
  extends NativeButtonProps, BaseUIComponentProps<'button', DrawerCloseState> {}

export interface DrawerCloseState {
  disabled: boolean;
}

export interface DrawerClose {
  (componentProps: DrawerCloseProps): React.JSX.Element;
}

export namespace DrawerClose {
  export type Props = DrawerCloseProps;
  export type State = DrawerCloseState;
}
```

This keeps the Drawer public API self-contained (consumers import `Drawer.Close`, not `Dialog.Close`) while the runtime is zero-overhead.

### 3. Context architecture (3-tier)

The drawer uses three context layers, each with a distinct scope and update frequency:

```
┌───────────────────────────────────────────────────────┐
│ DrawerProviderContext (optional, app-level)            │
│  • active: boolean (any drawer open?)                 │
│  • visualStateStore (swipeProgress, frontmostHeight)  │
│  • setDrawerOpen / removeDrawer                       │
├───────────────────────────────────────────────────────┤
│ DrawerRootContext (per drawer instance)                │
│  • swipeDirection, snapPoints, activeSnapPoint        │
│  • popupHeight, frontmostHeight                       │
│  • hasNestedDrawer, nestedSwiping                     │
│  • nestedSwipeProgressStore (pub/sub)                 │
│  • onNested*Change callbacks (parent notifications)   │
│  • notifyParent* callbacks (child-to-parent)          │
├───────────────────────────────────────────────────────┤
│ DrawerViewportContext (per viewport)                   │
│  • swiping: boolean                                   │
│  • getDragStyles(): CSSProperties                     │
│  • swipeStrength: number | null                       │
│  • setSwipeDismissed(dismissed)                       │
└───────────────────────────────────────────────────────┘
```

**Context hook pattern — overloaded `optional` parameter:**

```tsx
export function useDrawerRootContext(optional?: false): DrawerRootContext;
export function useDrawerRootContext(optional: true): DrawerRootContext | undefined;
export function useDrawerRootContext(optional?: boolean) {
  const context = React.useContext(DrawerRootContext);
  if (optional === false && context === undefined) {
    throw new Error(
      'Base UI: DrawerRootContext is missing. ' +
      'Drawer parts must be placed within <Drawer.Root>.'
    );
  }
  return context;
}
```

This gives you:
- **Required consumption** (default): throws if context is missing, return type is non-optional
- **Optional consumption**: returns `undefined` when outside a provider, TypeScript narrows correctly

Use required for child parts that must be inside a provider. Use optional for:
- `DrawerRoot` checking for a parent drawer (nesting detection)
- `DrawerPopup` checking for `DrawerViewportContext` (dev warning if missing)
- Any part checking for `DrawerProviderContext` (optional app-level coordination)

### 4. State management patterns

**4a. Controlled/uncontrolled via `useControlled`**

Both `open` and `snapPoint` support controlled and uncontrolled modes:

```tsx
const [activeSnapPoint, setActiveSnapPointUnwrapped] = useControlled({
  controlled: snapPointProp,
  default: resolvedDefaultSnapPoint,
  name: 'Drawer',
  state: 'snapPoint',
});
```

The wrapper `setActiveSnapPoint` fires `onSnapPointChange` first and respects cancellation via `isCanceled` before calling the unwrapped setter.

**4b. Stable callbacks via `useStableCallback`**

Callbacks passed through context or used in effects are wrapped to avoid stale closures:

```tsx
const onPopupHeightChange = useStableCallback((height: number) => {
  setPopupHeight(height);
  if (!isNestedDrawerOpenRef.current && height > 0) {
    setFrontmostHeight(height);
  }
});
```

Rule of thumb:
- Use `useStableCallback` for callbacks called from effects or event handlers
- Use `React.useCallback` only for callbacks called during render (memoization for child props)

**4c. Lightweight pub/sub store for high-frequency data**

Swipe progress changes 60+ times per second. Using React state would cause expensive re-renders. Instead, a manual store syncs directly to DOM:

```tsx
function createNestedSwipeProgressStore(): NestedSwipeProgressStore {
  let progress = 0;
  const listeners = new Set<() => void>();

  return {
    getSnapshot: () => progress,
    set(nextProgress) {
      const resolved = Number.isFinite(nextProgress) ? nextProgress : 0;
      if (resolved === progress) return;
      progress = resolved;
      listeners.forEach((listener) => listener());
    },
    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
  };
}
```

Consumers subscribe in layout effects and write directly to DOM:

```tsx
useIsoLayoutEffect(() => {
  const syncNestedSwipeProgress = () => {
    const progress = nestedSwipeProgressStore.getSnapshot();
    popupElement.style.setProperty('--drawer-swipe-progress', `${progress}`);
  };
  syncNestedSwipeProgress();
  return nestedSwipeProgressStore.subscribe(syncNestedSwipeProgress);
}, [nestedSwipeProgressStore]);
```

**When to use which:**

| Data type | Mechanism | Example |
|-----------|-----------|---------|
| Discrete state (open/closed, snap point) | React state + context | `open`, `activeSnapPoint` |
| Continuous animation values (60fps) | Pub/sub store → DOM | `swipeProgress`, `frontmostHeight` |
| Cross-instance coordination | Provider context + Map | `openById` in `DrawerProvider` |

### 5. CSS variable strategy

**5a. Enum-based variable definitions**

Each set of CSS variables gets its own enum file for type safety:

```tsx
export enum DrawerPopupCssVars {
  nestedDrawers = '--nested-drawers',
  height = '--drawer-height',
  frontmostHeight = '--drawer-frontmost-height',
  swipeMovementX = '--drawer-swipe-movement-x',
  swipeMovementY = '--drawer-swipe-movement-y',
  snapPointOffset = '--drawer-snap-point-offset',
  swipeStrength = '--drawer-swipe-strength',
}

export enum DrawerBackdropCssVars {
  swipeProgress = '--drawer-swipe-progress',
}
```

Using enums means:
- TypeScript catches typos at compile time
- IDE autocomplete discovers all available variables
- Refactoring (renaming a variable) is a single change

**5b. Performance: `CSS.registerProperty` with `inherits: false`**

Registered once at module level (not per instance):

```tsx
let drawerSwipeVarsRegistered = false;

function removeCSSVariableInheritance() {
  if (drawerSwipeVarsRegistered) return;

  if (typeof CSS !== 'undefined' && 'registerProperty' in CSS) {
    [
      DrawerPopupCssVars.swipeMovementX,
      DrawerPopupCssVars.swipeMovementY,
      DrawerPopupCssVars.snapPointOffset,
    ].forEach((name) => {
      try {
        CSS.registerProperty({
          name,
          syntax: '<length>',
          inherits: false,
          initialValue: '0px',
        });
      } catch { /* already registered */ }
    });
  }

  drawerSwipeVarsRegistered = true;
}
```

Why this matters: when a CSS custom property changes on a parent element, browsers normally invalidate styles for the **entire subtree**. With `inherits: false`, the variable update only affects the element it is set on. For swipe animations updating at 60fps on potentially deep DOM trees, this is a significant performance win.

Reference: [Motion.dev — Web Animation Performance](https://motion.dev/blog/web-animation-performance-tier-list)

**5c. Direct DOM mutation for high-frequency updates**

Instead of React state (which triggers reconciliation), swipe values are written directly:

```tsx
popupElement.style.setProperty(DrawerPopupCssVars.swipeMovementY, `${movementY}px`);
backdropElement.style.setProperty(DrawerBackdropCssVars.swipeProgress, `${progress}`);
```

Initial/default values are set via React's `style` prop (runs once at mount):

```tsx
style: {
  [DrawerBackdropCssVars.swipeProgress]: '0',
  [DrawerPopupCssVars.swipeStrength]: '1',
}
```

### 6. Data attributes and state mapping

State-to-attribute derivation is centralized in mapping objects:

```tsx
const stateAttributesMapping: StateAttributesMapping<DrawerPopupState> = {
  ...baseMapping,            // data-open, data-closed (from shared popup mapping)
  ...transitionStatusMapping, // data-starting-style, data-ending-style
  expanded(value) {
    return value ? { [DrawerPopupDataAttributes.expanded]: '' } : null;
  },
  nestedDrawerOpen(value) {
    return value ? { [DrawerPopupDataAttributes.nestedDrawerOpen]: '' } : null;
  },
  swiping(value) {
    return value ? { [DrawerPopupDataAttributes.swiping]: '' } : null;
  },
  swipeDirection(value) {
    return value ? { [DrawerPopupDataAttributes.swipeDirection]: value } : null;
  },
};
```

**Pattern rules:**
- Boolean attributes: return `{ 'data-xxx': '' }` when true, `null` when false
- Enum attributes: return `{ 'data-xxx': value }` when truthy, `null` otherwise
- Compose with spread: `...baseMapping` reuses shared open/closed attributes
- Attribute names live in their own enum file (`DrawerPopupDataAttributes`)

This lets consumers style entirely with CSS:

```css
[data-swiping] { cursor: grabbing; }
[data-expanded] { border-radius: 0; }
[data-swipe-direction="down"] { /* ... */ }
```

### 7. Type patterns

**7a. Namespace pattern for public types**

Each component exports a namespace that groups its types:

```tsx
export namespace DrawerPopup {
  export type Props = DrawerPopupProps;
  export type State = DrawerPopupState;
}
```

Consumers reference types as `DrawerPopup.Props`, `DrawerPopup.State` — mirrors the `Drawer.Popup` component namespace.

**7b. Base component props**

All parts extend `BaseUIComponentProps<ElementTag, State>`:

```tsx
export interface DrawerPopupProps
  extends BaseUIComponentProps<'div', DrawerPopupState> {
  initialFocus?: /* ... */;
  finalFocus?: /* ... */;
}
```

This provides consistent `render`, `className` (can be a function of state), and ref forwarding across all parts.

**7c. Cancelable event details**

Change events carry typed details with cancellation support:

```tsx
export type DrawerRootChangeEventDetails =
  BaseUIChangeEventDetails<DrawerRoot.ChangeEventReason> & {
    preventUnmountOnClose(): void;
  };

// Usage in handler:
onOpenChange?.(nextOpen, eventDetails);
if (eventDetails.isCanceled) return;
```

Reasons are typed constants (`REASONS.swipe`, `REASONS.escapeKey`, etc.) so consumers can discriminate:

```tsx
onOpenChange={(open, details) => {
  if (details.reason === 'swipe') {
    // handle swipe-specific logic
  }
}}
```

### 8. Performance patterns summary

| Technique | What it solves | Where used |
|-----------|---------------|------------|
| `CSS.registerProperty` with `inherits: false` | Subtree style recalc on variable change | `DrawerPopup` (module-level, once) |
| `element.style.setProperty()` | Bypass React reconciliation for 60fps updates | Swipe movement, backdrop progress, indent sync |
| `ResizeObserver` | Responsive popup height without polling | `DrawerPopup` height measurement |
| `useIsoLayoutEffect` | Synchronous DOM reads/writes (no flicker) | Height measurement, visual state sync |
| Pub/sub store | High-frequency data without React re-renders | `nestedSwipeProgressStore`, `visualStateStore` |
| Module-level flag | Register CSS properties only once across instances | `drawerSwipeVarsRegistered` |
| `useStableCallback` | Avoid stale closures in effects without re-subscribing | All context callbacks |

### 9. Nested component coordination

Drawers can nest (a drawer opens another drawer). Coordination flows in both directions:

```
Parent DrawerRoot
  ├── notifyParentFrontmostHeight ← from child
  ├── notifyParentSwipingChange ← from child
  ├── notifyParentSwipeProgressChange ← from child
  ├── notifyParentHasNestedDrawer ← from child
  │
  └── Child DrawerRoot (reads parent context)
        ├── onNestedFrontmostHeightChange → to parent
        ├── onNestedSwipingChange → to parent
        ├── onNestedSwipeProgressChange → to parent
        └── onNestedDrawerPresenceChange → to parent
```

**How it works:**

1. Child `DrawerRoot` reads parent context via `useDrawerRootContext(true)` (optional — returns `undefined` at top level)
2. If parent exists, child extracts `notifyParent*` callbacks
3. `DrawerPopup` in the child calls `notifyParentFrontmostHeight(frontmostHeight)` on mount and cleanup
4. Parent receives notifications via its `onNested*Change` handlers, updates its own state
5. Parent popup adjusts its visual presentation (e.g., shrinks when a nested drawer opens)

The `DrawerProviderReporter` is a renderless component injected into every `DrawerRoot`'s children. It bridges individual drawer instances with the optional `DrawerProvider`:

```tsx
function DrawerProviderReporter() {
  const drawerId = useId();
  const providerContext = useDrawerProviderContext(true);
  const { store } = useDialogRootContext(false);

  const open = store.useState('open');

  React.useEffect(() => {
    if (drawerId == null) return;
    providerContext?.setDrawerOpen(drawerId, open);
  }, [drawerId, open, providerContext]);

  React.useEffect(() => {
    if (!providerContext || drawerId == null) return undefined;
    return () => providerContext.removeDrawer(drawerId);
  }, [drawerId, providerContext]);

  return null;
}
```

### 10. Barrel export pattern

Two-file barrel structure enables both namespace and direct imports:

**`index.parts.ts`** — maps internal names to short compound names:

```tsx
export { DrawerBackdrop as Backdrop } from './backdrop/DrawerBackdrop';
export { DrawerClose as Close } from './close/DrawerClose';
export { DrawerPopup as Popup } from './popup/DrawerPopup';
export { DrawerRoot as Root } from './root/DrawerRoot';
export { DrawerViewport as Viewport } from './viewport/DrawerViewport';
// ... all parts
export {
  createDialogHandle as createHandle,
  DialogHandle as Handle,
} from '../dialog/store/DialogHandle';
```

**`index.ts`** — namespace re-export + type re-exports:

```tsx
export * as Drawer from './index.parts';

export type * from './root/DrawerRoot';
export type * from './popup/DrawerPopup';
export type * from './viewport/DrawerViewport';
// ... all parts
```

This enables:

```tsx
import { Drawer } from '@base-ui/react/drawer';

<Drawer.Root>
  <Drawer.Trigger>Open</Drawer.Trigger>
  <Drawer.Portal>
    <Drawer.Backdrop />
    <Drawer.Viewport>
      <Drawer.Popup>
        <Drawer.Content>...</Drawer.Content>
      </Drawer.Popup>
    </Drawer.Viewport>
  </Drawer.Portal>
</Drawer.Root>
```

---

## Extensibility checklist

When building a new compound component, apply these patterns:

### Architecture

- [ ] **Identify the base primitive** — can this compose an existing component (Dialog, Popover, etc.) rather than building from scratch?
- [ ] **Use `IsXContext` bridge** — if composing, add a boolean context so the base can branch without coupling
- [ ] **Decide alias vs wrap vs new** for each sub-part
- [ ] **One folder per part** — component, data attributes, CSS vars, tests co-located

### Context design

- [ ] **Define context tiers** — what state belongs at root, what at a mid-level (e.g. viewport), what at app level?
- [ ] **Use overloaded optional hooks** — `useContext(optional?: boolean)` with throw-on-missing for required consumption
- [ ] **Pass parent callbacks through context** for nested coordination
- [ ] **Wrap all context callbacks in `useStableCallback`** to prevent stale closures

### State management

- [ ] **Support controlled/uncontrolled** via `useControlled` for all user-facing state
- [ ] **Use pub/sub stores** for continuous values updated at animation frame rate
- [ ] **Use React state** for discrete values that should trigger re-render
- [ ] **Cancelable events** — fire `onChange` before committing, check `isCanceled`

### Styling API

- [ ] **Define CSS vars in enum files** — one enum per component part
- [ ] **Register high-frequency CSS vars** with `inherits: false` (once, at module level)
- [ ] **Apply initial values via React `style` prop**, update at runtime via `element.style.setProperty()`
- [ ] **Define data attributes in enum files** — derive from component state via mapping objects
- [ ] **Compose state attribute mappings** — spread shared mappings, add component-specific ones

### Types

- [ ] **Export namespace** per component part: `Props`, `State`, `Actions`, event detail types
- [ ] **Extend `BaseUIComponentProps<tag, State>`** for consistent render/className typing
- [ ] **Type event reasons** as discriminated union constants

### Performance

- [ ] **Bypass React for 60fps updates** — direct DOM style mutations via `setProperty`
- [ ] **Use `ResizeObserver`** for size-dependent behavior instead of polling or window resize
- [ ] **Use `useIsoLayoutEffect`** for synchronous DOM measurements
- [ ] **Module-level flags** for one-time setup (CSS property registration, etc.)

---

## Trade-offs & When to Use

| Approach | Pros | Cons |
|----------|------|------|
| Compose existing primitive | No duplication, shared bug fixes, smaller bundle | Coupled to base API surface, `IsXContext` branch complexity |
| Pub/sub store for animation | 60fps without React re-renders | Manual DOM sync, harder to debug, must handle cleanup |
| `CSS.registerProperty` | Eliminates inherited style recalc | No Safari `inherit` opt-back-in (acceptable for non-inherited vars) |
| 3-tier context | Clear separation of concerns, optional layers | More providers in tree, context lookup overhead |
| Type aliases for sub-parts | Zero runtime cost, consistent consumer API | Must manually keep type surface in sync with base |
| Data attributes for styling | CSS-only styling, no JS coupling | Verbose selectors, attribute churn during transitions |

**When to use this architecture:**

- Component is a specialization of an existing primitive (drawer = dialog + swipe)
- Gesture-driven interactions require high-frequency style updates
- Nesting is a use case (drawers inside drawers, popovers inside dialogs)
- Consumers need a headless/unstyled approach with CSS-only customization

**When this is overkill:**

- Simple, non-modal components with no gesture physics
- Components that don't nest or compose with other overlays
- When the base primitive doesn't exist yet (build the primitive first)

---

## References

- [Base UI Drawer docs](https://base-ui.com/react/components/drawer)
- [Base UI source — drawer](https://github.com/mui/base-ui/tree/master/packages/react/src/drawer)
- [CSS custom property performance — Motion.dev](https://motion.dev/blog/web-animation-performance-tier-list)
- [patterns.dev — Compound Component Pattern](https://www.patterns.dev/react/compound-pattern)

---

## My Notes

- The decision to compose Dialog rather than fork it is the single most impactful architectural choice. It means Drawer inherits all Dialog improvements (focus trap, scroll lock, transition lifecycle, accessibility) for free. Any new component should start with "what existing primitive can I wrap?"
- The pub/sub store pattern (`getSnapshot/subscribe/set`) is React-agnostic and could be extracted as a utility. It is essentially a minimal version of `useSyncExternalStore` without the React binding — listeners sync directly to DOM.
- The `CSS.registerProperty` optimization is underused in the ecosystem. Most component libraries eat the inherited-style-recalc cost. Registering high-frequency CSS variables with `inherits: false` is nearly free and has measurable impact on complex subtrees.
- The optional `DrawerProvider` is a good example of "progressive complexity" — simple use cases don't need it, but app-shell integrations (indent effects, any-drawer-open state) get a clean API without polluting the core drawer.
- Nested drawer coordination via context callbacks is verbose but explicit. Each direction of communication (child-to-parent, parent-to-child) has named callbacks. This is preferable to event buses or global stores because the relationship is structurally enforced by the React tree.
