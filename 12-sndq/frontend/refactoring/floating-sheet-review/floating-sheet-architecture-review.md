# FloatingSheet Architecture Review

> **Component**: `sndq-fe/src/components/floating-sheet/`
> **Evaluated against**: [Drawer Best Practices Knowledge Base](../../../04-frontend/react/drawer-best-practices/README.md)
> **Reference docs**:
> - [Base UI Drawer Architecture](../../../04-frontend/react/drawer-best-practices/base-ui-drawer-architecture.md)
> - [Vaul Drawer Architecture](../../../04-frontend/react/drawer-best-practices/vaul-drawer-architecture.md)
> - [Comparison and Best Practices](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md)
>
> **Date**: 2026-05-17 (updated from 2026-05-16 initial review)

---

## TL;DR

FloatingSheet is a pragmatically well-built compound component with strong layout logic, clean context tiering, and very high adoption (~110 consumers). The `calculateLayout` pure function with its phased collapse algorithm is genuinely well-engineered and thoroughly tested. However, FloatingSheet is a **horizontal stacking panel**, not a gesture-driven bottom drawer — many drawer-specific patterns (snap points, drag physics, swipe pub/sub stores, `CSS.registerProperty`) are not applicable. The patterns that **do** apply regardless of orientation — Dialog composition for accessibility, data attributes as a styling contract, and test coverage — represent the highest-impact improvement areas. Both Base UI and Vaul validate that composing a Dialog primitive is the foundational best practice; FloatingSheet's biggest gap is building modal behavior from scratch.

---

## Where FloatingSheet Fits

FloatingSheet is neither a Base UI-style design system primitive nor a Vaul-style gesture drawer. It is a **custom side-panel with horizontal layer stacking** — a fundamentally different UX pattern from a bottom/edge sheet with swipe physics.

Using the [decision matrix](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md#decision-matrix-which-approach-to-follow) from the research:

| Scenario from matrix | Recommended | FloatingSheet alignment |
|---|---|---|
| Simple app drawer, single level nesting | Vaul pattern | **Partial** — simpler nesting model like Vaul, but no Dialog composition |
| Design system component | Base UI pattern | **Partial** — 3-tier context and compound API like Base UI, but not tree-shakeable or per-part tested |
| Radix-based app | Vaul pattern | **Applicable** — project uses Radix, but FloatingSheet does not compose it |
| App-shell coordination | Base UI pattern | **No** — no Provider for "any sheet open?" coordination |
| Performance-critical (deep DOM) | Base UI pattern | **No** — no `CSS.registerProperty`, but not needed (no 60fps drag) |
| Quick prototype | Vaul pattern | **N/A** — FloatingSheet is production code, not a prototype |
| Headless/unstyled library | Base UI pattern | **No** — Tailwind hardcoded, not headless |

**Pattern alignment summary:**

| Aligns with Base UI | Aligns with Vaul | Diverges from both |
|---|---|---|
| 3-tier context architecture | Flat-ish file structure (single folder) | No Dialog primitive composition |
| ResizeObserver for measurement | Simpler nesting (no N-level propagation) | No gesture physics (horizontal stacking instead) |
| Compound component API | Controlled-only `open` prop | Horizontal right-side panel, not edge sheet |
| `data-slot` attributes on all parts | Callback refs to avoid stale closures | Global mutable dismiss stack (neither library does this) |

---

## Codebase Metrics

| Metric | Value |
|---|---|
| Total files | 13 |
| Total lines of code | ~750 (excluding tests) |
| Test lines | ~345 (`calculateLayout.test.ts`) |
| Test coverage | 1/8 modules tested (~12.5% module coverage) |
| Adoption | **110+ consumer files** across the codebase |
| Sub-sheet usage | **30+ files** use `FloatingSheetSubSheet` |
| Size variants | 4 (`sm`, `md`, `lg`, `xl`) |
| Contexts | 3 (`StackContext`, `InSubSheetContext`, `ParentSheetContext`) |
| Animation library | `motion/react` (Framer Motion) |
| Portal strategy | `createPortal(…, document.body)` for root; sub-sheets portal into the panel element |

---

## File Structure

```
floating-sheet/
├── FloatingSheet.tsx              # Root: portal, backdrop, slide animation
├── FloatingSheetStackContext.tsx   # 3 contexts + stack provider
├── FloatingSheetContent.tsx       # Fixed-width content column, root registration
├── FloatingSheetHeader.tsx        # Title, subtitle, close button, actions
├── FloatingSheetBody.tsx          # Scrollable content area
├── FloatingSheetFooter.tsx        # Fixed footer bar
├── FloatingSheetSubSheet.tsx      # Stacking sub-sheet layer
├── FloatingSheetSkeleton.tsx      # Loading skeleton variants
├── useEscapeDismiss.ts            # Global Escape/dismiss stack
├── calculateLayout.ts            # Pure layout algorithm (collapse phases)
├── calculateLayout.test.ts       # 14 test cases for layout
├── constants.ts                   # Widths, z-index, transition config
└── index.ts                       # Barrel exports
```

**Versus the recommended structure** (Base UI pattern — one folder per part):

```
floating-sheet/
├── root/
│   ├── FloatingSheet.tsx
│   └── FloatingSheet.test.tsx
├── content/
│   ├── FloatingSheetContent.tsx
│   ├── FloatingSheetContentCssVars.ts
│   └── FloatingSheetContent.test.tsx
├── header/
│   └── FloatingSheetHeader.tsx
├── body/
│   └── FloatingSheetBody.tsx
├── footer/
│   └── FloatingSheetFooter.tsx
├── sub-sheet/
│   ├── FloatingSheetSubSheet.tsx
│   └── FloatingSheetSubSheet.test.tsx
├── stack-context/
│   ├── FloatingSheetStackContext.tsx
│   └── FloatingSheetStackContext.test.tsx
├── layout/
│   ├── calculateLayout.ts
│   └── calculateLayout.test.ts
├── skeleton/
│   └── FloatingSheetSkeleton.tsx
├── constants.ts
├── index.ts
└── index.parts.ts
```

Note: Vaul uses a flat single-folder structure (~12 files) similar to FloatingSheet. The per-part folder pattern is a design system concern — for an application component with 13 files, the flat structure is defensible as long as test coverage improves.

---

## Complexity Analysis

**Overall complexity: Medium-High** — appropriate for what it does, but some areas carry unnecessary weight.

| Dimension | Assessment |
|---|---|
| Component count | 13 files — reasonable for a compound component with stacking, layout, animation, and dismiss logic |
| Context layers | 3 contexts (`StackContext`, `InSubSheetContext`, `ParentSheetContext`) — mirrors the 3-tier pattern from Base UI |
| Layout algorithm | `calculateLayout` is the most complex pure function (~65 lines). Well-isolated and independently testable |
| Escape/dismiss | Global mutable singleton (`openSheetStack` array) — functional but fragile |
| Animation | Delegated to `motion/react` — avoids custom physics. No high-frequency 60fps manual DOM writes needed |

The cyclomatic complexity lives almost entirely in two places: `calculateLayout` (the phased collapse algorithm) and `FloatingSheetStackProvider.register` (mutual-exclusion + re-registration guards). Everything else is structurally simple.

---

## Extensibility Assessment

Evaluated against the extensibility checklists from both the [Base UI architecture](../../../04-frontend/react/drawer-best-practices/base-ui-drawer-architecture.md#extensibility-checklist) and the [comparison best practices](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md#best-practices-for-building-a-drawer):

### Architecture

| Checklist Item | Status | Notes |
|---|---|---|
| Identify base primitive | **Partial** | Does NOT compose Dialog or any existing primitive. Builds modal behavior from scratch (portal + backdrop + escape). Both Base UI and Vaul compose Dialog — this is the strongest consensus from the research |
| Compound component API | **Yes** | `FloatingSheet` > `FloatingSheetContent` > `FloatingSheetHeader/Body/Footer` + `FloatingSheetSubSheet` |
| One folder per part | **No** | All 13 files flat in one directory. Comparable to Vaul's structure, but lacks co-located tests |
| Alias vs wrap vs new | **N/A** | No base primitive to alias. Every part is custom |
| `data-slot` attributes | **Yes** | Every part has `data-slot="floating-sheet-*"` — good for external styling and testing |

### Styling API

| Checklist Item | Status | Notes |
|---|---|---|
| CSS variable strategy | **No** | Widths are hardcoded Tailwind classes in `constants.ts`. Neither Base UI's enum-typed CSS vars nor Vaul's inline `--snap-point-height` approach |
| Data attributes for state | **Partial** | Only `data-stacked` on sub-sheets. Both Base UI (`data-swiping`, `data-expanded`) and Vaul (`data-vaul-*`) use richer attribute sets |
| Enum-based CSS vars | **No** | No CSS variable enums. Not critical since FloatingSheet has no 60fps drag updates |

### State Management

| Checklist Item | Status | Notes |
|---|---|---|
| Controlled/uncontrolled | **Controlled only** | `open` is a required prop. No `defaultOpen` or `useControlled`. Vaul supports both; Base UI supports both. Controlled-only is simpler and sufficient for this use case |
| Cancelable events | **No** | `onClose` is fire-and-forget. Base UI has `isCanceled` + typed `reason`; Vaul has simple `(open: boolean) => void`. FloatingSheet would benefit from at least a `reason` discriminator |
| Pub/sub store | **Not needed** | `motion/react` handles animation interpolation outside React. No 60fps manual DOM writes. This is one area where the drawer patterns genuinely do not apply |

### Types

| Checklist Item | Status | Notes |
|---|---|---|
| Namespace exports | **No** | Types exported flat (`FloatingSheetProps`). Base UI uses `DrawerPopup.Props`; Vaul uses inline interfaces. Namespace pattern is a design system concern |
| Base component props | **No** | No `BaseUIComponentProps<tag, State>` pattern. Base UI uses this; Vaul extends `ComponentPropsWithoutRef<typeof RadixPrimitive>` |
| Typed event reasons | **No** | No discrimination between escape, backdrop click, programmatic close |

---

## Component Design — Strengths

### 1. Clean separation of layout logic

`calculateLayout` is a pure function with zero side effects, making it independently testable. The phased collapse algorithm handles priority ordering elegantly:

```
Phase A — collapse "other" intermediates (oldest first)
Phase B — collapse latest's parent
Phase C — collapse root (last resort)
```

14 test cases cover all phases including edge cases (empty input, single layer, 5-layer deep stacks, mixed widths, margin handling). This is a pattern neither Base UI nor Vaul needs (they do not have horizontal layer stacking), and it is well-executed.

### 2. Well-tiered context architecture

The three contexts mirror the research's 3-tier recommendation (Base UI pattern):

| Context | Scope | Base UI equivalent | Vaul equivalent |
|---|---|---|---|
| `StackContext` | Root coordination (register/unregister, layout, panel width) | `DrawerRootContext` | `DrawerContext` (flat, all-in-one) |
| `InSubSheetContext` | Structural marker (boolean: am I inside a sub-sheet?) | `IsDrawerContext` | `nested` prop on Root |
| `ParentSheetContext` | Nesting coordination (parent ID for mutual exclusion) | `notifyParent*` callbacks | `onNested*` callbacks via `NestedRoot` |

FloatingSheet's context design is closer to Base UI's layered approach than Vaul's flat context. This gives better update isolation — `InSubSheetContext` consumers do not re-render when `StackContext` changes.

### 3. Mutual exclusion via registration

Sibling sub-sheets sharing the same `parentId` auto-close each other, enforced at registration time with `queueMicrotask`. This prevents the "two sub-sheets open at the same level" bug elegantly:

```tsx
if (!isRoot && isFirstRegistration) {
  const prior = activeChildRef.current.get(parentId);
  if (prior && prior !== id) {
    const priorClose = closeFnsRef.current.get(prior);
    if (priorClose) queueMicrotask(priorClose);
  }
  activeChildRef.current.set(parentId, id);
}
```

Neither Base UI nor Vaul have this pattern because their drawers overlap (each new drawer fully covers the previous), whereas FloatingSheet's layers sit side-by-side and must manage horizontal space.

### 4. ResizeObserver for width measurement

Both `FloatingSheetContent` and `FloatingSheetSubSheet` use `ResizeObserver` to measure natural width. This matches Base UI's approach (`ResizeObserver` for height measurement). Vaul uses `getBoundingClientRect` on demand instead. The observer pattern is superior for responding to content changes without explicit triggers.

### 5. Portal strategy for sub-sheets

Sub-sheets portal into the panel element (not `document.body`), so all layers share the panel as their containing block. This prevents `overflow: hidden` on parent layers from clipping nested sub-sheets.

---

## Component Design — Weaknesses

### 1. No composition with Dialog primitive

The biggest architectural gap — and the strongest consensus from the research. **Both Base UI and Vaul compose an existing Dialog primitive** rather than building modal behavior from scratch. This is described in [Best Practice #1](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md#1-always-compose-a-dialog-primitive): "do not build modal behavior from scratch."

FloatingSheet manually implements:
- Portal rendering
- Escape key handling (entire `useEscapeDismiss.ts`)
- Backdrop click dismiss
- `aria-modal` and `role="dialog"`

But does **not** implement:
- **Focus trapping** (users can Tab out of the sheet into background content)
- **Return focus on close** (focus doesn't return to the trigger)
- **Scroll lock** on the body
- **`aria-labelledby` / `aria-describedby`** linkage

Radix `Dialog.Root` is already in the project's dependency tree. Following Vaul's approach (wrap Radix Dialog + add custom behavior on top) would be the path of least resistance.

### 2. Global mutable state for dismiss stack

`useEscapeDismiss.ts` uses a module-level mutable singleton:

```tsx
const openSheetStack: StackEntry[] = [];
```

This is superficially similar to how Vaul lets the topmost drawer handle Escape — but Vaul gets this behavior **for free** from Radix Dialog's built-in layered dismiss system. FloatingSheet re-implements it manually with the associated problems:
- **Testing isolation**: tests share global state, requiring manual cleanup
- **Concurrent React**: React 18+ can render multiple instances concurrently — a shared array has no concurrency safety
- **No crash recovery**: if a component unmounts without its cleanup effect running (error boundary, Suspense), the stack gets corrupted
- **Cross-tree leakage**: multiple `FloatingSheet` roots share one dismiss stack, which is correct for layering but couples unrelated component trees

Composing a Dialog primitive would eliminate this entire file.

### 3. Wheel event suppression is problematic

```tsx
const stopWheel = (e: WheelEvent) => {
  e.stopPropagation();
};
el.addEventListener('wheel', stopWheel, { passive: true });
```

`stopPropagation` on wheel events prevents background scroll containers from receiving the event, but:
- `passive: true` means the browser will scroll regardless — `stopPropagation` only prevents parent JS handlers, not scroll behavior
- The intent (preventing background scroll) should be handled by proper scroll lock (which Dialog primitives provide, and Vaul further supplements with `usePreventScroll`)
- This can break parent components that listen for wheel events for other purposes

### 4. Duplicated ResizeObserver logic

Both `FloatingSheetContent` and `FloatingSheetSubSheet` contain nearly identical ResizeObserver measurement logic:

```tsx
// Appears in both files:
const measure = () => {
  const w = el.offsetWidth;
  if (w > 0) setNaturalWidth(w);
};
measure();
const ro = new ResizeObserver(measure);
ro.observe(el);
return () => ro.disconnect();
```

Should be extracted into a shared `useMeasuredWidth` hook.

### 5. Parallel mutable refs in provider

`FloatingSheetStackProvider` maintains three parallel mutable refs tracking related state:

```tsx
const closeFnsRef = useRef<Map<string, () => void>>(new Map());
const activeChildRef = useRef<Map<string, string>>(new Map());
const registeredIdsRef = useRef<Set<string>>(new Set());
```

A single "registry" object would be easier to reason about and keep in sync.

---

## Insights from Vaul Analysis

The [Vaul architecture analysis](../../../04-frontend/react/drawer-best-practices/vaul-drawer-architecture.md) reveals several patterns relevant to FloatingSheet:

### Dismiss handling validates Dialog composition

FloatingSheet's `useEscapeDismiss` manually builds a LIFO stack for layered Escape key handling. Vaul achieves the same behavior with zero custom code because Radix Dialog's portal-based focus management naturally handles layered dismiss. This is the strongest argument for composing Dialog: the 77-line `useEscapeDismiss.ts` would become unnecessary.

### Callback ref pattern is shared

FloatingSheet's `onCloseRef.current = onClose` pattern in `useEffect` mirrors Vaul's approach of storing callbacks in refs to avoid stale closures. Neither uses Base UI's `useStableCallback` wrapper. The ref approach is simpler but requires discipline — every call site must read from `.current` rather than the stale closure value. For FloatingSheet's complexity level, the ref approach is appropriate.

### Controlled-only is the right choice

The comparison confirms that FloatingSheet's controlled-only `open` prop is defensible. Vaul supports both controlled and uncontrolled via `useControllableState`, and Base UI does the same via `useControlled`. However, in a business application where sheet state is always driven by parent components (route parameters, selection state, form submission flows), controlled-only eliminates a category of state synchronization bugs.

### WeakMap style cache is not needed (yet)

Vaul's `set`/`reset` helpers with WeakMap-cached original styles enable clean imperative style mutation and restoration. FloatingSheet delegates all animation to `motion/react`, which manages its own style lifecycle. If FloatingSheet ever needs imperative style control (e.g., for performance-critical transitions), the WeakMap pattern from Vaul would be the reference implementation.

### iOS workarounds are low priority

Vaul dedicates significant complexity to iOS Safari: `usePositionFixed` (body positioning), `usePreventScroll` (keyboard-triggered scroll), and safe area handling. FloatingSheet is a desktop-focused right-side panel with no mobile swipe interaction. Per [Best Practice #7](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md#7-solve-iossafari-scroll-issues), these workarounds are critical for bottom drawers but lower priority for a horizontal panel used primarily on desktop viewports.

---

## Nested Coordination Checklist Evaluation

Evaluated against the [nested drawer implementation checklist](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md#nested-drawer-implementation-checklist) from the comparison document.

**Important context**: FloatingSheet's "nesting" is **horizontal layer stacking** (sub-sheets sit side-by-side, sharing horizontal space), not **overlapping drawer stacking** (nested drawer covers parent with scale/translate effects). Many checklist items apply differently or not at all.

### Parent responsibilities

| Checklist Item | Status | Notes |
|---|---|---|
| Detect nested open and adjust visual | **Different model** | Provider detects registration (not open/close). Visual adjustment is horizontal repositioning via `calculateLayout`, not scale/translate |
| Interpolate transform during child drag | **N/A** | No drag gesture. Layers are statically positioned |
| Restore transform on nested close | **N/A** | Panel width animates via `motion/react` when layers change |
| Track `hasNestedDrawer` | **Yes (implicit)** | The `entries` Map and `subRegistrationOrder` track which sub-sheets exist |
| Track `nestedSwiping` to suppress parent | **N/A** | No swipe interaction |
| Transition timing via lifecycle callbacks | **Yes** | Uses `motion/react` `AnimatePresence.onExitComplete` rather than hardcoded timeouts (avoids Vaul's 500ms timeout pattern) |

### Child responsibilities

| Checklist Item | Status | Notes |
|---|---|---|
| Report open/close to parent | **Yes** | Via `register`/`unregister` calls in effects |
| Report drag progress | **N/A** | No drag gesture |
| Report release result | **N/A** | No drag gesture |
| Report measured height/width | **Yes** | Width reported via `register(id, naturalWidth, opts)`. Both content and sub-sheets measure via `ResizeObserver` |
| Skip body workarounds when nested | **N/A** | No body style modifications |
| Forward swipe progress | **N/A** | No swipe interaction |

### Architecture requirements

| Checklist Item | Status | Notes |
|---|---|---|
| Stable parent callbacks | **Partial** | `register`/`unregister` wrapped in `useCallback`. `onClose` refs used in sub-sheets. No `useStableCallback` wrapper |
| Optional context for parent detection | **Yes** | `InSubSheetContext` (boolean marker) + `ParentSheetContext` (parent ID). `useFloatingSheetStack()` returns `null` outside provider |
| N-level signal relay | **Not needed** | Horizontal stacking does not require parent-to-grandparent signal propagation — the provider manages all layers equally |
| App-level coordination | **No** | No equivalent to Base UI's `DrawerProvider` for "is any sheet open?" queries |
| Z-ordering | **Yes** | `calculateLayout` assigns `baseZIndex + i * 10` per layer. Sub-sheets portal into the panel, so DOM order matches z-index |

### Testing considerations

| Checklist Item | Status | Notes |
|---|---|---|
| Standalone sheet (no sub-sheets) | **Not tested** | No tests for `FloatingSheet` root component |
| Single-level nesting | **Not tested** | No tests for sub-sheet registration/unregistration |
| Nested close stability | **Not tested** | No tests for panel width re-calculation after sub-sheet close |
| Nested drag interpolation | **N/A** | No drag gesture |
| Dialog-inside-sheet not misclassified | **Not tested** | `InSubSheetContext` marker could theoretically confuse nested Dialogs, though unlikely in practice |
| Transition cleanup | **Not tested** | `AnimatePresence` handles this via `motion/react`, but no explicit verification |

**Summary**: FloatingSheet implements the relevant subset of the nested coordination checklist. Items related to drag/swipe (6 of 18) are N/A due to the horizontal stacking model. The main gap is **test coverage** — most architecture requirements are met but unverified.

---

## Maintainability Assessment

| Factor | Rating | Detail |
|---|---|---|
| File organization | 6/10 | Flat directory. 13 files in one folder — comparable to Vaul's structure but lacks co-located tests |
| Test coverage | 4/10 | Only `calculateLayout` tested. Zero tests for: registration, escape dismiss, mutual exclusion, portal behavior |
| Documentation | 8/10 | Every component and the layout function has JSDoc. Phase comments in `calculateLayout` are particularly well-written |
| Dependency surface | 7/10 | Only `motion/react`, `react-dom`, and internal utils. Clean |
| Type safety | 7/10 | Props interfaces well-typed. Missing: discriminated event reasons, state types, cancelable event details |
| Stable callbacks | 6/10 | `onClose` refs used in dismiss hook and sub-sheet (good). But provider `register` captures refs via closure — potential stale reads |

---

## Accessibility Audit

| Feature | Status | Notes |
|---|---|---|
| `role="dialog"` | **Yes** | Set on the panel |
| `aria-modal="true"` | **Yes** | Set on the panel |
| `aria-hidden` on backdrop | **Yes** | Backdrop has `aria-hidden` |
| `aria-label` on close button | **Yes** | Uses `t('general.close')` |
| Focus trapping | **Missing** | Users can Tab into background content. Both Base UI (via Dialog) and Vaul (via Radix Dialog) get this for free |
| Return focus on close | **Missing** | Focus doesn't return to trigger element. Dialog primitives handle this automatically |
| `aria-labelledby` | **Missing** | Title not linked to dialog via `id` |
| `aria-describedby` | **Missing** | No description linkage |
| Scroll lock | **Missing** | Background page remains scrollable. Vaul adds `usePreventScroll` on top of Radix's handling |
| Reduced motion | **Missing** | No `prefers-reduced-motion` support |

---

## Recommendations

Calibrated against the [8 best practices](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md#best-practices-for-building-a-drawer) from the research, with applicability notes for FloatingSheet's horizontal stacking model.

### High Priority (Correctness / A11y)

**1. Compose a Dialog primitive** (Best Practice #1)

Both Base UI and Vaul validate this as the foundational pattern: "do not build modal behavior from scratch." Radix `Dialog.Root` is already in the dependency tree. Wrapping it (Vaul-style) would provide focus trapping, scroll lock, return focus, layered dismiss, and `aria-*` linkage — eliminating `useEscapeDismiss.ts` entirely and fixing the 5 missing accessibility features.

**2. Add scroll lock** (Best Practice #7, partial)

Background content remains scrollable when the sheet is open. A Dialog primitive handles this. If composing Dialog is deferred, a standalone scroll lock (e.g., `react-remove-scroll` or a minimal `usePreventScroll`) is the fallback. Note: iOS-specific workarounds (`usePositionFixed`, `usePreventScroll` for keyboard) are lower priority since FloatingSheet is a desktop-focused panel.

**3. Fix wheel event handler**

`stopPropagation` with `passive: true` doesn't achieve scroll isolation. Replace with proper scroll lock (from Dialog composition) or remove entirely.

### Medium Priority (Architecture)

**4. Extract duplicated ResizeObserver** into a shared `useMeasuredWidth(ref, enabled)` hook used by both `FloatingSheetContent` and `FloatingSheetSubSheet`.

**5. Replace global `openSheetStack`** with a context-scoped dismiss registry inside `FloatingSheetStackProvider`. If Dialog composition (rec #1) is adopted, this becomes unnecessary — Dialog handles layered dismiss natively.

**6. Add `reason` to `onClose`** so consumers can discriminate escape vs. backdrop vs. programmatic close. Base UI has full `ChangeEventDetails` with `isCanceled` and typed reasons; Vaul has simple `(open: boolean) => void`. A middle ground for FloatingSheet:

```tsx
type CloseReason = 'escape' | 'backdrop' | 'programmatic';
onClose?: (reason: CloseReason) => void;
```

**7. Add `aria-labelledby`** by connecting the `FloatingSheetHeader` title to the dialog element via a shared `id`. If Dialog composition is adopted, this wiring comes from `Dialog.Title`.

**8. Expand data attributes** (Best Practice #8) — both Base UI and Vaul use data attributes as the primary styling contract. FloatingSheet only has `data-slot` and `data-stacked`. Add state-driven attributes for consumer CSS:

```css
[data-slot="floating-sheet"][data-state="open"] { /* ... */ }
[data-slot="floating-sheet-subsheet"][data-stacked] { /* ... */ }
[data-slot="floating-sheet-content"][data-peek-folded] { /* ... */ }
```

### Lower Priority (Scalability)

**9. Add tests for the stack provider** — registration, mutual exclusion, unregistration order, edge cases (double-register, register-unregister-register). The nested coordination checklist evaluation shows 5 of 6 applicable test scenarios are untested.

**10. Consider CSS custom properties** for widths instead of hardcoded Tailwind classes, enabling runtime customization:

```tsx
enum FloatingSheetCssVars {
  width = '--floating-sheet-width',
  peekWidth = '--floating-sheet-peek-width',
}
```

Note: `CSS.registerProperty` with `inherits: false` (Best Practice #5) is not needed since FloatingSheet has no 60fps drag updates.

**11. Add `prefers-reduced-motion` support** — skip slide animation when the user has reduced motion preference.

**12. Consolidate parallel refs** in the provider into a single registry Map:

```tsx
interface RegistryEntry {
  closeFn?: () => void;
  activeChild?: string;
}
const registryRef = useRef<Map<string, RegistryEntry>>(new Map());
```

---

## Three-Way Comparison: Base UI vs. Vaul vs. FloatingSheet

| Aspect | Base UI Drawer | Vaul | FloatingSheet |
|---|---|---|---|
| UX pattern | Bottom/edge sheet with swipe | Bottom/edge sheet with swipe | Right-side panel with horizontal stacking |
| Base primitive | Own Dialog (internal) | Radix Dialog (external dep) | **None** — builds from scratch |
| Context design | 3-tier (Provider → Root → Viewport) | Flat (single `DrawerContext`) | 3-tier (StackContext, InSubSheet, ParentSheet) |
| Focus management | Inherited from Dialog | Inherited from Radix Dialog | **Missing** |
| Scroll lock | Inherited from Dialog | Radix Dialog + `usePreventScroll` | **Missing** |
| Animation strategy | Pub/sub store + direct DOM | WeakMap cache + `element.style` | `motion/react` (delegated) |
| CSS vars | Enum-typed, `CSS.registerProperty` | Inline strings (`--snap-point-height`) | **None** — Tailwind classes |
| Data attributes | Full state mapping objects (`data-swiping`, `data-expanded`) | `data-vaul-*` attribute set | Only `data-slot` and `data-stacked` |
| Nesting model | Implicit N-level (context detection + callback chain) | Explicit 1-level (`NestedRoot` component) | Registration-based horizontal stacking |
| Nesting coordination | `notifyParent*` callback chain | `onNested*` callbacks via context | `register`/`unregister` + mutual exclusion |
| Type namespaces | `DrawerPopup.Props`, `DrawerPopup.State` | Inline interfaces | Flat exports (`FloatingSheetProps`) |
| Event details | `isCanceled`, typed `reason`, `preventUnmountOnClose` | Simple `(open: boolean) => void` | Fire-and-forget `onClose` |
| File structure | 1 folder per part (~35 files) | Single folder (~12 files) | Single folder (13 files) |
| Test co-location | Tests per part | Minimal tests | Only `calculateLayout` tested |
| Unique strength | N-level nesting, performance optimization | iOS workarounds, shipped CSS, quick setup | Horizontal collapse algorithm, width-aware stacking |

---

## Best Practice Applicability Matrix

Not all drawer best practices apply to a horizontal stacking panel. This matrix clarifies which patterns from the [comparison document](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md#best-practices-for-building-a-drawer) are relevant:

| # | Best Practice | Applies to FloatingSheet? | Status |
|---|---|---|---|
| 1 | Always compose a dialog primitive | **Yes** — modal behavior is universal | **Not met** |
| 2 | Separate gesture logic from presentation | **N/A** — no gesture physics | N/A |
| 3 | Design context for your nesting depth | **Yes** — horizontal stacking is a form of nesting | **Met** (3-tier context) |
| 4 | Bypass React for high-frequency DOM updates | **N/A** — no 60fps drag | N/A (`motion/react` handles it) |
| 5 | Register CSS custom properties for performance | **N/A** — no high-frequency CSS var updates | N/A |
| 6 | Handle snap point release with velocity | **N/A** — no snap points | N/A |
| 7 | Solve iOS/Safari scroll issues | **Low priority** — desktop-focused panel | Partially missing (scroll lock) |
| 8 | Use data attributes as the styling contract | **Yes** — useful for any stateful component | **Partially met** (`data-slot` only) |

Of the 8 best practices, **3 fully apply** (#1, #3, #8), **1 partially applies** (#7), and **4 are N/A** (#2, #4, #5, #6). FloatingSheet meets 1 of the 3 applicable practices fully, partially meets 1, and does not meet 1.

---

## Verdict

FloatingSheet is a **horizontal stacking panel**, not a gesture-driven drawer. This fundamental difference means 4 of 8 drawer best practices (gesture separation, 60fps DOM bypass, CSS property registration, snap point physics) do not apply. The comparison should not penalize FloatingSheet for lacking swipe features it was never designed to have.

**What FloatingSheet does well** (regardless of orientation):
- The `calculateLayout` pure function with phased collapse is a genuinely novel solution to the horizontal stacking problem — neither Base UI nor Vaul has an equivalent
- The 3-tier context architecture (Base UI pattern) provides clean separation and good update isolation
- Mutual exclusion via registration elegantly solves the "sibling sub-sheets at the same level" problem
- ResizeObserver-based width measurement follows production best practices
- 110+ consumers and 30+ sub-sheet usages prove the API design works at scale

**What must improve** (universal patterns that apply regardless of orientation):
- **Dialog composition** (Best Practice #1) — the strongest consensus from the research. Both Base UI and Vaul compose Dialog. This single change would fix focus trapping, scroll lock, return focus, layered dismiss, and `aria-*` linkage. It would eliminate `useEscapeDismiss.ts` and the global mutable dismiss stack
- **Data attributes** (Best Practice #8) — expand beyond `data-slot` and `data-stacked` to expose sheet state for CSS-only styling
- **Test coverage** — only 1 of 8 modules tested. The nested coordination checklist reveals 5 of 6 applicable test scenarios are unverified

**What is acceptable as-is:**
- Controlled-only `open` prop (validated by the business application context)
- Flat file structure (matches Vaul's approach, appropriate for application-level code)
- `motion/react` for animations (no need for pub/sub stores or direct DOM mutation)
- No iOS-specific workarounds (desktop-focused panel)
- Callback refs instead of `useStableCallback` (simpler, sufficient at this complexity level)

---

## References

- [Drawer Best Practices Knowledge Base](../../../04-frontend/react/drawer-best-practices/README.md)
- [Base UI Drawer Architecture](../../../04-frontend/react/drawer-best-practices/base-ui-drawer-architecture.md)
- [Vaul Drawer Architecture](../../../04-frontend/react/drawer-best-practices/vaul-drawer-architecture.md)
- [Comparison and Best Practices](../../../04-frontend/react/drawer-best-practices/comparison-and-best-practices.md)
