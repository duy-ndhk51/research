# Dialog Component Architecture — Base UI

> **Source**: [Base UI Dialog](https://github.com/mui/base-ui) (`packages/react/src/dialog/`)
> **Pattern type**: Compound component with modal/non-modal focus management
> **Complexity tier**: High — composition, nested coordination, detached triggers, imperative handles

---

## TL;DR

The Base UI Dialog is the **foundational overlay primitive** in the library. Drawer, AlertDialog, and other modal components compose it rather than duplicating its behavior. It implements compound components with a store-based architecture, supports three modality modes (`true`, `false`, `'trap-focus'`), handles N-level nested dialog coordination via a floating-tree parent node system, and provides detached trigger support through an imperative handle API. The dialog owns focus management, scroll locking, dismiss behavior (Escape + outside press), transition lifecycle, and accessible labelling — all as a headless, unstyled primitive.

---

## Key Concepts

| Concept | One-liner |
|---------|-----------|
| Compound component | Namespace API: `Dialog.Root`, `Dialog.Popup`, `Dialog.Trigger`, etc. |
| Store-based state | `DialogStore` extends `ReactStore` with pub/sub selectors for granular updates |
| 3 modality modes | `true` (trap focus + scroll lock), `'trap-focus'` (trap focus, no scroll lock), `false` (no trap, no lock) |
| Nested dialog tree | Floating UI parent node IDs + `nestedOpenDialogCount` propagation |
| Detached triggers | `Dialog.createHandle()` enables triggers outside `Dialog.Root` |
| Payload generics | `Dialog.Root<Payload>` + render props for type-safe trigger-to-content data flow |
| Transition lifecycle | `mounted`, `transitionStatus`, `onOpenChangeComplete` driven by CSS animations |
| Data attributes | `data-open`, `data-closed`, `data-starting-style`, `data-ending-style`, `data-nested-dialog-open` |
| Portal + InternalBackdrop | Modal dialogs render an invisible `role="presentation"` layer for dismiss hit-testing |
| IsDrawerContext | Boolean context bridge allowing Drawer to reuse dialog internals without coupling |

---

## Deep Dive

### 1. Component tree and file structure

```
dialog/
├── root/                  # DialogRoot + DialogRootContext + useDialogRoot
├── store/                 # DialogStore (state machine) + DialogHandle (imperative API)
├── popup/                 # Focus-managed surface, ARIA labelling, nested CSS var
├── trigger/               # Click-to-open, ARIA, payload forwarding
├── backdrop/              # Overlay with nested-aware conditional rendering
├── viewport/              # Scroll/position wrapper for inside-scroll pattern
├── portal/                # FloatingPortal + InternalBackdrop + keepMounted
├── close/                 # Close button with reason-aware event details
├── title/                 # <h2> syncing aria-labelledby
├── description/           # <p> syncing aria-describedby
├── index.ts               # Barrel: namespace export + type re-exports
└── index.parts.ts         # Maps internal names to short compound names
```

Each part folder contains:
- `ComponentName.tsx` — the component implementation
- `ComponentNameDataAttributes.ts` — data attribute enums (where applicable)
- `ComponentNameCssVars.ts` — CSS variable enums (where applicable)
- `ComponentName.test.tsx` — co-located tests

**Typical render tree:**

```
Dialog.Root                  ← context setup, no DOM node
  Dialog.Trigger             ← button with aria-haspopup="dialog"
  Dialog.Portal              ← FloatingPortal + InternalBackdrop (modal only)
    Dialog.Backdrop          ← role="presentation" overlay (root-level only)
    Dialog.Viewport          ← optional scroll/position wrapper
      Dialog.Popup           ← focus-managed surface, role="dialog"
        Dialog.Title         ← aria-labelledby source
        Dialog.Description   ← aria-describedby source
        Dialog.Close         ← close button
```

### 2. Store-based state management

Unlike flat context approaches, Base UI uses a **`DialogStore`** that extends `ReactStore` — a lightweight observable store with selectors:

```tsx
// DialogStore extends ReactStore with dialog-specific state
interface DialogStoreState<Payload> extends PopupStoreState<Payload> {
  modal: boolean | 'trap-focus';
  disablePointerDismissal: boolean;
  openMethod: InteractionType | undefined;
  nested: boolean;
  nestedOpenDialogCount: number;
  nestedOpenDrawerCount: number;
  titleElementId: string | undefined;
  descriptionElementId: string | undefined;
  viewportElement: HTMLElement | null;
  role: 'dialog' | 'alertdialog';
}
```

Parts subscribe to specific slices via `store.useState('fieldName')`, avoiding re-renders when unrelated fields change. The store also holds a `context` object for refs and callbacks that should not trigger updates:

```tsx
// Store context (non-reactive references)
interface DialogStoreContext {
  popupRef: React.RefObject<HTMLElement>;
  backdropRef: React.RefObject<HTMLElement>;
  internalBackdropRef: React.RefObject<HTMLElement>;
  outsidePressEnabledRef: React.RefObject<boolean>;
  onNestedDialogOpen?: (dialogCount: number, drawerCount: number) => void;
  onNestedDialogClose?: () => void;
  triggerElements: Map<string, HTMLElement>;
  onOpenChange?: (open: boolean, details: ChangeEventDetails) => void;
}
```

**Why stores over context:**
- Granular subscriptions: `store.useState('open')` only re-renders when `open` changes
- Shared between detached components: `DialogHandle` shares the same store instance
- Imperative access: `store.select('open')` reads without subscribing
- Batch updates: multiple `store.set()` calls before React commits

### 3. Three modality modes

The `modal` prop accepts three values with distinct behavior:

| Mode | Focus trap | Scroll lock | Outside press | Use case |
|------|-----------|-------------|---------------|----------|
| `true` (default) | Yes | Yes | Dismisses | Standard modal dialog |
| `'trap-focus'` | Yes | No | Dismisses | Dialog over scrollable content (e.g. cookie consent) |
| `false` | No | No | Dismisses | Non-modal dialog (sidebar, panel) |

Implementation in `DialogInteractions`:

```tsx
// Scroll lock only when modal === true (not 'trap-focus')
useScrollLock(open && modal === true, popupElement);

// Focus trap when modal !== false (both true and 'trap-focus')
<FloatingFocusManager modal={modal !== false} /* ... */ />
```

The `'trap-focus'` mode solves a real problem: dialogs that must trap keyboard navigation (for accessibility) but should not lock page scrolling (e.g. a fixed banner or sheet that coexists with scrollable content).

### 4. Dismiss behavior pipeline

Dialog dismissal flows through Floating UI's `useDismiss` hook with dialog-specific guards:

```
User action (Escape / outside click)
  → useDismiss interceptor
    → isTopmost check (only innermost nested dialog responds)
      → outsidePress guard (modal backdrop vs document)
        → store.setOpen(false, eventDetails)
          → onOpenChange callback with reason + cancel()
            → if not canceled: state update + transition lifecycle
```

**Key behaviors:**

- **Topmost only**: `isTopmost = ownNestedOpenDialogs === 0` — Escape and outside press only affect the innermost dialog in a nested stack
- **Right-click immunity**: Backdrop right-clicks do not dismiss (context menu should open normally)
- **Intentional click**: Outside dismiss requires a full click (mousedown + mouseup), not just mousedown alone
- **Shadow DOM awareness**: Outside press detection works correctly when dialogs are portaled into shadow roots
- **Stacked non-nested**: Multiple independent modal dialogs coexist — clicking one does not dismiss others

### 5. Nested dialog coordination

Nesting is detected automatically via Floating UI's tree system:

```tsx
// In usePopupStore:
const parentNodeId = useFloatingParentNodeId();
const nested = parentNodeId != null;
```

When a nested dialog opens, it communicates with its parent through context callbacks:

```
Parent Dialog
  └── DialogStore.context.onNestedDialogOpen(count, drawerCount)
  └── DialogStore.context.onNestedDialogClose()
        ↑
        │ (called by child's DialogInteractions effect)
        │
Child Dialog (reads parent context)
  └── notifies parent on open/close
  └── reports own nested count upward (propagation chain)
```

**N-level propagation**: Each dialog reports `ownNestedCount + 1` to its parent, so the root dialog knows the total depth. This drives:
- CSS variable `--nested-dialogs` on parent popup
- Data attribute `data-nested-dialog-open` for styling
- Dismiss behavior (only topmost responds to Escape)
- Backdrop suppression (nested dialogs skip backdrop by default)

**Backdrop behavior**: `DialogBackdrop` renders only when `!nested || forceRender`:

```tsx
const enabled = forceRender || !nested;
```

This prevents duplicate overlays stacking when dialogs nest. The `forceRender` prop overrides for edge cases.

### 6. Detached triggers and imperative handles

For triggers that live outside `Dialog.Root` (e.g. in a sidebar, toolbar, or different component tree):

```tsx
// Create a handle (external store reference)
const handle = Dialog.createHandle();

// Trigger outside Dialog.Root
<Dialog.Trigger handle={handle}>Open from anywhere</Dialog.Trigger>

// Dialog.Root receives the handle
<Dialog.Root handle={handle}>
  <Dialog.Portal>...</Dialog.Portal>
</Dialog.Root>
```

**`DialogHandle` API:**

| Method | Purpose |
|--------|---------|
| `handle.open(triggerId?)` | Open dialog, optionally associating a trigger for focus return |
| `handle.openWithPayload(payload)` | Open and set typed payload |
| `handle.close()` | Close the dialog |
| `handle.isOpen` | Reactive selector for open state |

Multiple detached triggers can share the same handle. Each trigger registers itself in the store's `triggerElements` map with its `id`, enabling correct `aria-controls` wiring and focus return to the specific trigger that opened the dialog.

### 7. Payload and render props

Dialog supports typed payloads flowing from trigger to content:

```tsx
<Dialog.Root<{ item: Item }> handle={handle}>
  {({ payload }) => (
    <Dialog.Portal>
      <Dialog.Popup>
        <h2>{payload?.item.name}</h2>
      </Dialog.Popup>
    </Dialog.Portal>
  )}
</Dialog.Root>

// Trigger with typed payload
<Dialog.Trigger handle={handle} payload={{ item: selectedItem }}>
  Edit
</Dialog.Trigger>
```

The generic `<Payload>` flows through `DialogRoot`, `DialogTrigger`, and `DialogHandle` — TypeScript enforces that payloads match across trigger and root.

### 8. Focus management

Focus is managed by `FloatingFocusManager` (from floating-ui-react) with dialog-specific configuration:

```tsx
<FloatingFocusManager
  openInteractionType={openMethod}    // keyboard vs mouse vs touch
  disabled={!mounted}
  closeOnFocusOut={!disablePointerDismissal}
  initialFocus={resolvedInitialFocus}
  finalFocus={finalFocus}
  modal={modal !== false}
  restoreFocus="popup"
>
```

**Initial focus resolution:**

| Scenario | Behavior |
|----------|----------|
| Default (keyboard open) | First tabbable element inside popup |
| Default (touch open) | Popup element itself (avoids mobile keyboard) |
| `initialFocus={ref}` | Specific element |
| `initialFocus={(type) => ...}` | Function receives `InteractionType`, returns element/ref/boolean |
| `initialFocus={false}` | No auto-focus |

**Final focus (return focus):**

| Scenario | Behavior |
|----------|----------|
| Default | Returns to trigger that opened the dialog |
| `finalFocus={ref}` | Specific element |
| `finalFocus={(type) => ...}` | Function receives close type (`'escape-key'`, `'outside-press'`, etc.) |
| Detached trigger unmounted | Falls back to next focusable ancestor |

**Composite widget protection**: The popup's `onKeyDown` calls `stopPropagation()` for composite keys (arrows, Home, End) to prevent them from bubbling to parent composite widgets when a dialog contains one.

### 9. Transition lifecycle

The dialog uses a CSS-animation-driven transition system:

```
open=true → transitionStatus='starting' → (animation frame) → transitionStatus='open'
                                                                    ↓
                                                          onOpenChangeComplete(true)

open=false → transitionStatus='closing' → (CSS animation ends) → mounted=false
                                                                     ↓
                                                           onOpenChangeComplete(false)
```

**Data attributes through the lifecycle:**

| Phase | Attributes present |
|-------|--------------------|
| Opening (first frame) | `data-open`, `data-starting-style` |
| Open (steady state) | `data-open` |
| Closing | `data-closed`, `data-ending-style` |
| Unmounted | Element removed from DOM |

The `actionsRef` imperative API provides `unmount()` for bypassing animation-driven teardown when external animation libraries manage exit transitions:

```tsx
const actionsRef = useRef(null);
// Later: actionsRef.current.unmount() — immediately removes DOM
```

### 10. Portal and InternalBackdrop

`Dialog.Portal` renders content via `FloatingPortal` with an additional mechanism for modal dialogs:

When `modal === true`, Portal renders an **`InternalBackdrop`** — a full-viewport `role="presentation"` div that:
- Provides a hit-test target for `useDismiss` outside-press detection
- Uses `inert` attribute when the dialog is not open (but `keepMounted`)
- Is separate from the user-facing `Dialog.Backdrop` (which is styled)

This separation allows the dismiss system to work correctly even when:
- The user doesn't render a `Dialog.Backdrop`
- Multiple portaled modals are stacked
- The dialog is inside a Shadow DOM

### 11. ARIA and accessibility

| Feature | Implementation |
|---------|----------------|
| Dialog role | `role="dialog"` (default) or `role="alertdialog"` on Popup |
| Labelling | `aria-labelledby` from `Dialog.Title` id sync |
| Description | `aria-describedby` from `Dialog.Description` id sync |
| Trigger | `aria-haspopup="dialog"`, `aria-expanded`, `aria-controls` |
| Focus trap | `FloatingFocusManager` with modal/trap-focus modes |
| Inert siblings | Managed by floating-ui-react's `markOthers` (aria-hidden on siblings) |
| Scroll lock | `useScrollLock` on document when `modal === true` |
| Escape | `useDismiss` with topmost-only gate |
| Touch screens | Include `Dialog.Close` when modal — screen readers need explicit close affordance |

### 12. Barrel export and namespace pattern

Two files provide the public API:

**`index.parts.ts`** — compound component namespace:

```tsx
export { DialogBackdrop as Backdrop } from './backdrop/DialogBackdrop';
export { DialogClose as Close } from './close/DialogClose';
export { DialogDescription as Description } from './description/DialogDescription';
export { DialogPopup as Popup } from './popup/DialogPopup';
export { DialogPortal as Portal } from './portal/DialogPortal';
export { DialogRoot as Root } from './root/DialogRoot';
export { DialogViewport as Viewport } from './viewport/DialogViewport';
export { DialogTitle as Title } from './title/DialogTitle';
export { DialogTrigger as Trigger } from './trigger/DialogTrigger';
export { createDialogHandle as createHandle, DialogHandle as Handle } from './store/DialogHandle';
```

**`index.ts`** — namespace + type exports:

```tsx
export * as Dialog from './index.parts';

export type * from './root/DialogRoot';
export type * from './trigger/DialogTrigger';
export type * from './popup/DialogPopup';
// ... all parts
```

Consumer usage:

```tsx
import { Dialog } from '@base-ui/react/dialog';

<Dialog.Root>
  <Dialog.Trigger>Open</Dialog.Trigger>
  <Dialog.Portal>
    <Dialog.Backdrop />
    <Dialog.Popup>
      <Dialog.Title>Confirm</Dialog.Title>
      <Dialog.Description>Are you sure?</Dialog.Description>
      <Dialog.Close>OK</Dialog.Close>
    </Dialog.Popup>
  </Dialog.Portal>
</Dialog.Root>
```

---

## Architecture Patterns Worth Extracting

### Pattern: Store with selective subscriptions

```tsx
// Subscribe to single field — re-render only when 'open' changes
const open = store.useState('open');

// Read without subscribing (imperative)
const currentOpen = store.select('open');

// Sync component state into store (bidirectional)
store.useSyncedValueWithCleanup('titleElementId', id);
```

### Pattern: Context with required/optional consumption

```tsx
export function useDialogRootContext(): DialogRootContext;            // throws if missing
export function useDialogRootContext(optional: true): DialogRootContext | undefined;
```

### Pattern: Cancelable change events

```tsx
onOpenChange={(open, details) => {
  // details.reason: 'trigger-press' | 'close-press' | 'escape-key' | 'outside-press'
  // details.cancel(): prevents the state change
  // details.preventUnmountOnClose(): keeps DOM mounted during external animation
  if (hasUnsavedChanges && !open) {
    details.cancel();
    showConfirmation();
  }
}}
```

### Pattern: IsDrawerContext bridge

```tsx
// DialogRoot resets to false (default dialog behavior)
<IsDrawerContext.Provider value={false}>
  <DialogInteractions ... />
</IsDrawerContext.Provider>

// DrawerRoot overrides to true (drawer-specific branches)
<IsDrawerContext.Provider value={true}>
  <Dialog.Root ...>...</Dialog.Root>
</IsDrawerContext.Provider>
```

This allows dialog internals to branch on `isDrawer` where behavior must differ (e.g. nested counting, backdrop rendering) without the dialog code importing drawer-specific logic.

---

## Trade-offs & When to Use

| Approach | Pros | Cons |
|----------|------|------|
| Store-based state | Granular subscriptions, shared across detached triggers, imperative access | More complex than simple context, learning curve |
| Floating UI integration | Battle-tested dismiss/focus/positioning primitives | Dependency on floating-ui-react internals |
| 3 modality modes | Covers all real-world use cases without boolean props proliferating | `'trap-focus'` string mode less discoverable |
| Detached triggers + handles | Flexible architecture patterns (toolbar triggers, menu triggers) | API surface larger than simple dialog |
| Payload generics | Type-safe data flow from trigger to content | Generics add complexity for simple use cases |
| CSS animation lifecycle | No JS animation library dependency, performant | Requires CSS `@starting-style` / animation support |
| Nested auto-detection | N-level nesting without API changes | Implicit behavior can surprise developers |

**When to use this architecture:**

- Building a design system where Dialog is the base for multiple overlay types (drawer, alert, sheet)
- Need N-level nested overlay support with correct dismiss behavior
- Require detached triggers (toolbar, sidebar, command palette opening dialogs)
- Type-safe payload passing between trigger context and dialog content
- Headless/unstyled approach with CSS-only customization via data attributes

**When this is overkill:**

- Simple confirmation dialogs with no nesting or detached triggers
- Apps that only need one modal at a time
- Projects already using Radix Dialog with sufficient features

---

## References

- [Base UI Dialog docs](https://base-ui.com/react/components/dialog)
- [Base UI source — dialog](https://github.com/mui/base-ui/tree/master/packages/react/src/dialog)
- [WAI-ARIA Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- [Floating UI React](https://floating-ui.com/docs/react)

---

## My Notes

- The store-based architecture is the defining difference from Radix and Headless UI. It enables detached triggers (a trigger in a sidebar controlling a dialog in a different subtree) because the store is not bound to React's context tree — it can be shared via a handle object.
- The `'trap-focus'` mode is a pragmatic solution to a real accessibility dilemma. WCAG requires keyboard focus to be trapped in modals, but sometimes you want the page to remain scrollable (e.g. a cookie banner). Other libraries force you to choose between "modal" (trapped + locked) and "non-modal" (neither) with no middle ground.
- The `IsDrawerContext` pattern is an elegant inversion-of-control mechanism. Rather than dialog importing drawer logic, the drawer wraps dialog and flips a boolean context that dialog can optionally read. This keeps the dependency graph clean: drawer depends on dialog, never the reverse.
- Nested dialog counting propagating up via `onNestedDialogOpen` is similar to how the drawer implements nested coordination. The shared infrastructure in `DialogInteractions` means both Dialog and Drawer get correct stacking behavior without duplicating the logic.
- The `InternalBackdrop` + user `Backdrop` split is a subtle but important design decision. It separates the dismiss hit-test target (internal, always present for modals) from the visual overlay (optional, styleable). This means dismiss behavior works correctly even if the user omits `Dialog.Backdrop`.
