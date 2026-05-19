# Dialog Implementation Comparison and Best Practices

> **Comparing**: [Base UI Dialog](./base-ui-dialog-architecture.md) vs Radix Dialog vs Headless UI Dialog
> **Focus**: Architecture patterns, accessibility, focus management, and extensibility

---

## TL;DR

All three libraries validate the same core principle: **a dialog is a state machine coordinating focus, dismissal, and visibility**. They diverge on decomposition granularity (1 part per file vs single component), state strategy (observable store vs flat context vs reducer), and extensibility (detached triggers + handles vs controlled-only). This document compares approaches dimension by dimension, then synthesizes best practices for building production-quality dialogs.

---

## Architecture Comparison

### Overall structure

| Dimension | Base UI | Radix UI | Headless UI |
|-----------|---------|----------|-------------|
| File structure | 1 folder per part (~12 folders) | 1 folder per part (~8 files) | Single `dialog.tsx` + hooks |
| Component count | 10 parts + Handle | 7 parts (Root, Trigger, Portal, Overlay, Content, Title, Description, Close) | 3 parts (Dialog, Panel, Title) + Description |
| State management | `ReactStore` (observable, selective subscriptions) | React context (single provider) | Reducer + context |
| Modal behavior | `true` / `'trap-focus'` / `false` (3 modes) | `true` / `false` (2 modes) | Always modal |
| Bundle approach | Tree-shakeable per part | Tree-shakeable per part | Single module per component |
| Dependency | floating-ui-react (internal) | @radix-ui/react-* internal packages | None (self-contained) |

### Context and state design

| Aspect | Base UI | Radix UI | Headless UI |
|--------|---------|----------|-------------|
| State container | `DialogStore` (pub/sub, selectors) | Context with `useControllableState` | `useReducer` |
| Update granularity | Per-field subscription | Full context re-render | Full context re-render |
| Shared state | Store shared via handle (cross-tree) | Context tree only | Context tree only |
| Nested detection | `FloatingParentNodeId` (automatic) | Manual composition (user responsibility) | Not supported |
| Controlled/uncontrolled | `useControlledProp` + store sync | `useControllableState` (Radix util) | Props only (controlled encouraged) |

### Focus management

| Aspect | Base UI | Radix UI | Headless UI |
|--------|---------|----------|-------------|
| Focus trap | `FloatingFocusManager` | `FocusTrap` (custom implementation) | `FocusTrap` component |
| Initial focus | Prop: ref, function, or boolean | `onOpenAutoFocus` event on Content | `initialFocus` ref or `autoFocus` data attr |
| Return focus | `finalFocus` prop (ref/function) | `onCloseAutoFocus` event on Content | Automatic to trigger |
| Touch handling | Focuses popup (avoids keyboard) | No special handling documented | Disabled autofocus on touch devices |
| Interaction-aware | `openMethod` (keyboard/mouse/touch) → different initial focus | No | No |
| Composite widgets | `stopPropagation` for composite keys | Not documented | Not documented |

### Dismiss behavior

| Aspect | Base UI | Radix UI | Headless UI |
|--------|---------|----------|-------------|
| Escape key | Yes, topmost-only in nested stacks | Yes | Yes |
| Outside click | Full click (down + up), not mousedown alone | `onInteractOutside` event | Click outside detection |
| Pointer dismissal disable | `disablePointerDismissal` prop | `onInteractOutside` + `preventDefault()` | Not configurable |
| Right-click on backdrop | Does not dismiss | Configurable via event | Dismisses (default) |
| Cancelable | `details.cancel()` in `onOpenChange` | `event.preventDefault()` in events | Not cancelable |
| Reason reporting | `details.reason` (typed constant) | Not provided | Not provided |
| Stacked modals | Independent — clicking one doesn't dismiss others | Not documented | Not supported |

### Transition/animation support

| Aspect | Base UI | Radix UI | Headless UI |
|--------|---------|----------|-------------|
| Animation model | CSS animations via data attributes | CSS animations via `data-state` | CSS transitions via `Transition` component |
| Open attribute | `data-open`, `data-starting-style` | `data-state="open"` | `data-open` |
| Close attribute | `data-closed`, `data-ending-style` | `data-state="closed"` | `data-closed` |
| Lifecycle callback | `onOpenChangeComplete` (open/close) | `onAnimationEnd` (manual) | `afterLeave` / `afterEnter` |
| Keep mounted | `Portal keepMounted` | `forceMount` on Portal/Content/Overlay | Not built-in |
| External animation | `actionsRef.unmount()` bypasses CSS lifecycle | Manual with `forceMount` | `Transition` component |

### Accessibility

| Aspect | Base UI | Radix UI | Headless UI |
|--------|---------|----------|-------------|
| Dialog role | `role="dialog"` or `"alertdialog"` (prop) | `role="dialog"` (Content) or AlertDialog variant | `role="dialog"` (always) |
| Label source | `Dialog.Title` → `aria-labelledby` (auto-synced) | `Dialog.Title` → `aria-labelledby` | `Dialog.Title` → `aria-labelledby` |
| Description | `Dialog.Description` → `aria-describedby` | `Dialog.Description` → `aria-describedby` | `Description` → `aria-describedby` |
| Trigger ARIA | `aria-haspopup="dialog"`, `aria-expanded`, `aria-controls` | `aria-haspopup="dialog"`, `aria-expanded`, `aria-controls` | No dedicated trigger part |
| Inert siblings | `FloatingFocusManager` marks others with `aria-hidden` | Custom `aria-hidden` management | `inert` attribute on siblings |
| Scroll lock | `useScrollLock` (modal only) | Scroll lock utility | Body scroll lock |

---

## Focus Management Deep Dive

### The problem space

Focus management is the most complex aspect of dialog implementation. The dialog must:

1. **Trap focus** — Tab and Shift+Tab cycle within the dialog (modal only)
2. **Set initial focus** — Move focus into the dialog on open, to an appropriate target
3. **Return focus** — Move focus back to the trigger on close
4. **Handle edge cases** — Touch devices, interaction types, removed elements, detached triggers

### How each library handles initial focus

#### Base UI: Interaction-type-aware + function API

```tsx
// Function receives the interaction type that opened the dialog
<Dialog.Popup
  initialFocus={(interactionType) => {
    if (interactionType === 'touch') return popupRef;  // avoid keyboard
    if (interactionType === 'keyboard') return inputRef; // focus input
    return undefined; // default behavior for mouse
  }}
/>
```

Base UI distinguishes how the dialog was opened:
- **Keyboard** (Enter/Space on trigger): focuses first tabbable element
- **Mouse**: focuses first tabbable element
- **Touch**: focuses popup element itself (prevents mobile keyboard from appearing)

This is critical for mobile: if a dialog contains an input and opens via touch, auto-focusing the input opens the keyboard immediately, which disrupts animations and surprises users.

#### Radix UI: Event-based interception

```tsx
<Dialog.Content
  onOpenAutoFocus={(event) => {
    event.preventDefault(); // prevent default focus
    inputRef.current?.focus(); // manual focus
  }}
/>
```

Radix fires an `onOpenAutoFocus` event that can be prevented. The consumer must handle focus manually if they prevent it. No interaction-type awareness.

#### Headless UI: Ref-based with touch awareness

```tsx
<Dialog initialFocus={inputRef}>
  ...
</Dialog>
```

Headless UI accepts an `initialFocus` ref. It disables autofocus on touch devices entirely (documented design decision to prevent keyboard auto-opening).

### Focus return patterns

| Scenario | Base UI | Radix UI | Headless UI |
|----------|---------|----------|-------------|
| Normal close | Returns to trigger | Returns to trigger | Returns to trigger |
| Trigger unmounted | Falls back to focusable ancestor | Not documented | Not documented |
| Detached trigger | Returns to specific trigger (via `triggerElements` map) | N/A (no detached triggers) | N/A |
| Close reason matters | `finalFocus={(closeType) => ...}` | `onCloseAutoFocus` event | Not configurable |
| Focus something else | `finalFocus={ref}` or `finalFocus={false}` | `onCloseAutoFocus` + `preventDefault()` | Not configurable |

### Focus trap with composite widgets

When a dialog contains composite widgets (listbox, grid, toolbar), arrow keys should navigate within the widget without propagating to the dialog's own key handlers.

Base UI handles this explicitly:

```tsx
// DialogPopup.tsx — stops composite keys from bubbling
const COMPOSITE_KEYS = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Home', 'End'];

onKeyDown={(event) => {
  if (COMPOSITE_KEYS.includes(event.key)) {
    event.stopPropagation();
  }
}}
```

Radix and Headless UI do not document explicit handling for this scenario.

---

## Nested Dialog Deep Dive

### Why nesting matters

Real applications frequently nest dialogs: a settings dialog opens a confirmation dialog, a form dialog opens a file picker dialog. Correct nesting requires:

1. Only the topmost dialog responds to Escape
2. Outside-click dismisses the topmost dialog, not all of them
3. Focus returns correctly through the chain
4. Backdrops don't visually stack (multiple darkening layers)
5. Accessibility tree remains correct (aria-hidden management)

### Base UI: Automatic N-level nesting

```
Dialog A (root)
  └── Floating tree node (parent)
        └── Dialog B (nested — detected via FloatingParentNodeId)
              └── nestedOpenDialogCount=0 → isTopmost=true (handles Escape)
              └── reports to Dialog A: nestedOpenDialogCount=1
                    └── Dialog A: isTopmost=false (ignores Escape)
```

**Detection**: `usePopupStore` checks `useFloatingParentNodeId()` — if non-null, the dialog is nested.

**Dismiss gating**: `isTopmost = ownNestedOpenDialogs === 0`

**Backdrop**: Nested dialogs suppress their backdrop by default (`!nested || forceRender`).

**CSS coordination**: Parent popup receives `--nested-dialogs: N` CSS variable and `data-nested-dialog-open` attribute for styling (e.g. scale down, dim).

**Propagation**: Each dialog reports its own nested count + 1 to its parent, enabling the root to know total depth.

### Radix UI: Manual composition

Radix has no built-in nested dialog detection. Nesting is achieved by placing a second `Dialog.Root` inside a first `Dialog.Content`:

```tsx
<Dialog.Root>
  <Dialog.Content>
    {/* Nested dialog — manual composition */}
    <Dialog.Root>
      <Dialog.Trigger>Open nested</Dialog.Trigger>
      <Dialog.Content>...</Dialog.Content>
    </Dialog.Root>
  </Dialog.Content>
</Dialog.Root>
```

Escape and focus behavior depend on Radix's internal context tree traversal. No CSS variables or data attributes are provided for the parent to react to nested state.

### Headless UI: Multi-dialog support (v2.1+)

Headless UI v2.1 added multi-dialog support where opening a second Dialog automatically inerts the first:

```tsx
// Two independent dialogs — Headless UI manages stacking
<Dialog open={showFirst}>...</Dialog>
<Dialog open={showSecond}>...</Dialog>
```

This is not nested composition but rather a stacking model: the newer dialog inerts the older one. Escape closes the topmost. However, there is no parent-child coordination or styling hooks.

### Comparison

| Feature | Base UI | Radix UI | Headless UI |
|---------|---------|----------|-------------|
| Nesting model | Automatic detection via floating tree | Manual composition | Stacking (not true nesting) |
| Depth support | N-level with propagation | Works but no coordination API | 2+ independent dialogs |
| Dismiss isolation | Topmost-only (automatic) | Context-based (automatic) | Topmost-only (stacking) |
| Parent styling hooks | `--nested-dialogs`, `data-nested-dialog-open` | None | None |
| Backdrop management | Auto-suppressed for nested | Manual | N/A |
| Drawer integration | `nestedOpenDrawerCount` separate tracking | N/A | N/A |

---

## Best Practices for Building a Dialog

### 1. Design the state container for your extensibility needs

**If you need detached triggers or cross-tree sharing:**
- Use a store/observable pattern (Base UI approach)
- Store instance can be shared via handle objects outside React's context tree
- Enables toolbar triggers, command palette triggers, menu triggers

**If dialogs are always colocated with their triggers:**
- Context + controlled/uncontrolled is sufficient (Radix/Headless UI approach)
- Simpler mental model, fewer concepts

**Decision**: ask "will triggers ever live outside the dialog's React subtree?" If yes, you need a shareable store.

### 2. Support three modality modes

The binary `modal: true | false` is insufficient for real applications:

| Mode | Focus trap | Scroll lock | Example use case |
|------|-----------|-------------|------------------|
| `true` | Yes | Yes | Confirmation dialog, destructive action |
| `'trap-focus'` | Yes | No | Cookie banner, fixed announcement, slide-over |
| `false` | No | No | Non-modal panel, inspector, sidebar |

Trap-focus-without-scroll-lock solves the common "I need keyboard accessibility but the page should remain scrollable" problem. Without this middle ground, developers either sacrifice accessibility (non-modal) or scroll (modal).

### 3. Make initial focus interaction-aware

Different opening methods warrant different focus targets:

```
Keyboard open (Enter/Space) → First tabbable element (user is keyboard-navigating)
Mouse click → First tabbable element (standard desktop pattern)
Touch tap → Dialog container itself (prevent mobile keyboard popup)
```

This prevents the jarring UX of a keyboard sliding up immediately on mobile when a dialog opens via touch, especially if the dialog has an input field.

### 4. Implement cancelable change events with reasons

Expose both the direction of change and the cause:

```tsx
onOpenChange={(open, details) => {
  // details.reason tells you WHY
  // details.cancel() prevents the change
  // details.preventUnmountOnClose() keeps DOM for external animation
}}
```

**Reasons to expose:**
- `trigger-press` — user clicked a trigger
- `close-press` — user clicked a close button
- `escape-key` — user pressed Escape
- `outside-press` — user clicked backdrop or outside

This enables close-confirmation patterns without boolean flags:

```tsx
onOpenChange={(open, details) => {
  if (!open && hasUnsavedChanges) {
    details.cancel();
    setShowConfirmation(true);
  }
}}
```

### 5. Separate dismiss mechanics from visual overlay

The dismiss hit-test target (invisible, always present for modals) should be separate from the visual backdrop (optional, styled):

```
InternalBackdrop (invisible, role="presentation")
  → Always present when modal=true
  → Handles outside-press detection
  → Uses inert when closed (for keepMounted)

Dialog.Backdrop (visible, user-styled)
  → Optional — user may choose not to render
  → Suppressed for nested dialogs
  → Animatable via data attributes
```

This separation ensures dismiss behavior works correctly regardless of whether the user renders a visible backdrop, and prevents nested dialogs from stacking multiple darkening layers.

### 6. Use data attributes as the styling contract

Expose dialog state via data attributes rather than requiring JavaScript:

```css
/* Open/close states */
[data-open] { opacity: 1; }
[data-closed] { opacity: 0; }

/* Transition phases */
[data-starting-style] { transform: translateY(20px); }
[data-ending-style] { transform: translateY(20px); }

/* Nested state — parent reacts to children */
[data-nested-dialog-open] {
  transform: scale(0.95);
  filter: brightness(0.8);
}
```

Benefits over className-based approaches:
- No CSS-in-JS dependency
- Works with any styling solution (CSS Modules, Tailwind, vanilla CSS)
- Attribute selectors have clear boolean semantics
- Compound selectors possible: `[data-open][data-nested-dialog-open]`

### 7. Handle stacked non-nested modal dialogs

Multiple independent modal dialogs can coexist (e.g. a notification dialog and a settings dialog from different parts of the app). Correct behavior:

- Each dialog has its own backdrop
- Clicking one dialog's backdrop does not dismiss another dialog
- Escape closes only the most recently opened dialog
- `aria-hidden` is managed per-dialog (all non-dialog content is hidden)

Base UI solves this by scoping outside-press detection to the specific dialog's internal backdrop and portal container.

### 8. Provide imperative escape hatches

For edge cases that declarative props cannot cover:

```tsx
const actionsRef = useRef(null);

// Later: programmatically control
actionsRef.current.close();   // trigger close with transition
actionsRef.current.unmount(); // immediately remove DOM (bypass animation)
```

This is essential for:
- External animation libraries managing exit transitions
- Programmatic close from effects or async operations
- Testing (immediate teardown without waiting for animations)

### 9. Plan for Drawer/AlertDialog composition from day one

If your dialog will be the base for other overlay types:

- Add an identity context (e.g. `IsDrawerContext`) so dialog internals can branch without importing drawer code
- Keep nested counting generic (dialog count + drawer count separately)
- Make scroll lock conditionally opt-out-able (drawers with snap points may manage their own scroll)
- Expose transition lifecycle hooks that work regardless of whether CSS or JS animations are used

The investment in composition pays off: Drawer inherits all Dialog improvements (focus, dismiss, transitions, accessibility) without duplicating logic.

### 10. Test the dismiss pipeline exhaustively

The dismiss system has the most edge cases. Ensure tests cover:

- [ ] Escape closes topmost nested dialog only
- [ ] Outside click requires full click (down + up on same target)
- [ ] Right-click on backdrop does not dismiss
- [ ] Outside click in Shadow DOM portals works correctly
- [ ] Multiple independent modals don't interfere with each other
- [ ] `disablePointerDismissal` still allows Escape
- [ ] Cancel in `onOpenChange` prevents the close
- [ ] Reopen after cancel (Escape then outside click still works)
- [ ] Nested overlay inside dialog (menu, select) doesn't dismiss dialog
- [ ] Pointer lock / scrub scenarios still allow first outside click

---

## Decision Matrix: Which Approach to Follow

| Scenario | Recommended | Why |
|----------|-------------|-----|
| Design system with multiple overlay types | Base UI pattern | Drawer/AlertDialog compose Dialog; store enables detached triggers |
| Radix-based app needing standard dialogs | Radix Dialog | Ecosystem compatibility, proven, simpler API surface |
| Tailwind app with basic modals | Headless UI Dialog | Tight Tailwind integration, simple API, built-in transitions |
| Need close-confirmation patterns | Base UI pattern | Cancelable events with reasons; Radix needs `onInteractOutside` |
| Deep nesting (3+ levels) | Base UI pattern | Automatic detection, N-level propagation, parent styling hooks |
| Detached triggers (toolbar/sidebar/menu) | Base UI pattern | Handle API for cross-tree store sharing |
| Quick prototype, one dialog | Headless UI or Radix | Less API surface, faster time to working modal |
| Mobile-first with touch focus care | Base UI pattern | Interaction-type-aware `initialFocus` |
| Non-modal panels/sidebars | Base UI or Radix | `modal={false}` mode available |

---

## Common Mistakes and Anti-patterns

### 1. Using `useEffect` to react to open/close

```tsx
// Anti-pattern
useEffect(() => {
  if (open) fetchData();
}, [open]);

// Correct — use onOpenChange
<Dialog.Root onOpenChange={(open) => { if (open) fetchData(); }} />
```

Effects fire after render, causing an extra render cycle. The change callback fires synchronously with the state transition.

### 2. Putting "outside" UI actually outside the popup

```tsx
// Anti-pattern — floating action bar outside Dialog.Popup
<Dialog.Portal>
  <Dialog.Popup>Content</Dialog.Popup>
  <ActionBar /> {/* Outside popup = outside focus trap = inaccessible */}
</Dialog.Portal>

// Correct — inside popup with pointer-events split
<Dialog.Popup style={{ pointerEvents: 'none' }}>
  <div style={{ pointerEvents: 'auto' }}>Content</div>
  <ActionBar style={{ pointerEvents: 'auto' }} />
</Dialog.Popup>
```

UI that appears "outside" the dialog visually must remain inside `Dialog.Popup` for focus trapping and screen reader access.

### 3. Nesting without backdrop suppression

```tsx
// Anti-pattern — stacking dark overlays
<Dialog.Root> {/* Parent with backdrop */}
  <Dialog.Backdrop /> {/* opacity: 0.5 */}
  <Dialog.Popup>
    <Dialog.Root> {/* Nested */}
      <Dialog.Backdrop /> {/* Another opacity: 0.5 = TOO DARK */}
    </Dialog.Root>
  </Dialog.Popup>
</Dialog.Root>
```

Nested dialogs should suppress their own backdrop (Base UI does this automatically). If you need a nested backdrop for styling, use a lighter opacity or `forceRender` with adjusted styles.

### 4. Manual scroll locking outside the dialog

```tsx
// Anti-pattern — duplicating scroll lock
useEffect(() => {
  if (open) document.body.style.overflow = 'hidden';
  return () => { document.body.style.overflow = ''; };
}, [open]);
```

The dialog component manages scroll lock internally. Manual lock causes conflicts (double-lock, race conditions on unmount, iOS issues).

### 5. Boolean state for close confirmation

```tsx
// Anti-pattern — extra state + effect + timing issues
const [showConfirm, setShowConfirm] = useState(false);

// In parent: prevent close if showConfirm... but how?
// The dialog already closed by the time the effect runs.

// Correct — use cancelable event
onOpenChange={(open, details) => {
  if (!open && isDirty) {
    details.cancel(); // prevents close synchronously
    setShowConfirm(true);
  }
}}
```

---

## References

- [Base UI Dialog Architecture](./base-ui-dialog-architecture.md) — full analysis
- [Base UI Dialog docs](https://base-ui.com/react/components/dialog)
- [Radix UI Dialog](https://radix-ui.com/primitives/docs/components/dialog)
- [Headless UI Dialog](https://headlessui.com/react/dialog)
- [WAI-ARIA Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- [WAI-ARIA AlertDialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/)
