# React Fiber: Reconciliation Algorithm

Source: [Inside Fiber: in-depth overview of the new reconciliation algorithm in React](https://medium.com/react-in-depth/inside-fiber-in-depth-overview-of-the-new-reconciliation-algorithm-in-react-e1c04700ef6e) — Max Koretskyi, 2018

## Overview

React Fiber is the internal reconciliation engine introduced in React 16. It replaced the old stack-based reconciler with a linked-list-based architecture that enables **incremental rendering** — the ability to split rendering work into chunks, pause, resume, and abort it.

## Key Data Structures

### React Elements

- Immutable objects returned from `render()` / JSX
- Describe what should appear on screen (type, props, key, ref)
- Recreated on every render

### Fiber Nodes

- Mutable internal data structures corresponding to each React element
- **Not** recreated on every render — reused and updated
- Represent a **unit of work** to be done
- Connected via linked list: `child`, `sibling`, `return` pointers

Key fields on a fiber node:

| Field | Purpose |
|-------|---------|
| `stateNode` | Reference to component instance, DOM node, or other host |
| `type` | Constructor (class) or tag name (host) |
| `tag` | Numeric type identifier (ClassComponent = 1, HostComponent = 5, etc.) |
| `updateQueue` | Queue of state updates, callbacks, DOM updates |
| `memoizedState` | State used to produce current output on screen |
| `memoizedProps` | Props used during previous render |
| `pendingProps` | New props to be applied |
| `key` | Reconciliation identity for list diffing |
| `alternate` | Pointer to counterpart node in the other tree |
| `effectTag` | Encodes side-effects (Placement, Update, Deletion, etc.) |

## Double Buffering: Current & WorkInProgress Trees

React maintains **two fiber trees** at any time:

1. **Current tree** — reflects what is currently rendered on screen
2. **WorkInProgress tree** — being built during an update, represents the future state

Once the workInProgress tree is fully processed and committed to the DOM, it **becomes** the current tree (pointer swap). This ensures the UI is always updated atomically — no partial results shown to the user.

Each fiber in `current` has an `alternate` pointing to its counterpart in `workInProgress` and vice versa.

## Side-Effects & Effects List

- Any activity beyond computing UI (DOM mutations, lifecycle calls, ref updates) is a **side-effect**
- Each fiber's `effectTag` field encodes what effects it carries
- During traversal, React builds a **linear linked list** of fibers that have effects (`nextEffect` pointers)
- This effects list is a subset of the tree — enables fast iteration during commit without visiting effect-free nodes

Order: children effects are processed before parent effects (bottom-up).

## Two-Phase Algorithm

### Phase 1: Render (Reconciliation)

- **Asynchronous** — can be paused, resumed, or discarded
- Traverses from `HostRoot` downward
- For each fiber: calls `beginWork` (step into) and `completeWork` (step out)
- Produces the workInProgress tree with effect tags
- No visible DOM changes during this phase

Work loop (simplified):

```
while (nextUnitOfWork !== null) {
  nextUnitOfWork = performUnitOfWork(nextUnitOfWork);
}
```

Traversal pattern:
1. `performUnitOfWork` → calls `beginWork` → returns first child (or null)
2. If child exists, continue down
3. If no child, call `completeUnitOfWork` → complete current, check sibling, backtrack to parent

Lifecycle methods called during render phase:
- `getDerivedStateFromProps`
- `shouldComponentUpdate`
- `render`
- ~~`componentWillMount`~~, ~~`componentWillReceiveProps`~~, ~~`componentWillUpdate`~~ (deprecated/UNSAFE — unsafe because this phase can be interrupted and re-run)

### Phase 2: Commit

- **Synchronous** — cannot be interrupted, runs in a single pass
- Iterates the effects list and applies changes to the DOM
- Calls post-mutation lifecycle methods

Three sub-passes:

1. **Pre-mutation**: `getSnapshotBeforeUpdate`, `componentWillUnmount` (for deletions)
2. **Mutation**: DOM insertions, updates, deletions (via `commitMutationEffects`)
3. **Layout**: `componentDidMount`, `componentDidUpdate`, ref callbacks

Between pass 1 and pass 2, React swaps the `finishedWork` tree to become `current` — so `componentWillUnmount` sees the old tree, while `componentDidMount/Update` see the new one.

## Fiber Root

- Created for each root container (`ReactDOM.render(...)`)
- Accessible via `container._reactRootContainer._internalRoot`
- Holds `current` property pointing to the top `HostRoot` fiber
- The `HostRoot` fiber's `stateNode` points back to the FiberRoot

## Why Fiber Matters

| Old (Stack Reconciler) | New (Fiber) |
|------------------------|-------------|
| Recursive, synchronous traversal | Iterative, interruptible traversal via linked list |
| Must complete entire tree in one go | Can pause and yield to browser (time-slicing) |
| No prioritization | Work can be prioritized (expiration times) |
| Blocks main thread for large trees | Enables concurrent rendering |

## Key Takeaways

1. Fiber turns the render phase into **incremental units of work** that can be scheduled
2. The double-buffering (current/workInProgress) pattern guarantees **atomic UI updates**
3. The effects list provides an **O(n) fast path** through only the nodes that changed
4. The commit phase is always synchronous to prevent visual tearing
5. Legacy lifecycle methods prefixed with `UNSAFE_` exist because the render phase can run multiple times — side effects in those methods break the async model
