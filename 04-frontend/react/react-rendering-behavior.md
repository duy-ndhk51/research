# A (Mostly) Complete Guide to React Rendering Behavior

> **Author**: Mark Erikson (Redux maintainer)  
> **Published**: May 17, 2020 (Updated October 2022 for React 18)  
> **Source**: [blog.isquaredsoftware.com](https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/)  
> **Type**: Article

---

## TL;DR

React re-renders **all child components by default** when a parent renders — regardless of whether props changed. This is by design, not a bug. Understanding this default cascade behavior, plus when and how to optimize it with `React.memo()`, `useMemo`, `useCallback`, Context, and React-Redux, is essential for building performant React apps. The upcoming "React Forget" compiler may eventually auto-memoize everything.

---

## 1. What Is "Rendering"?

**Rendering** = React calling your component function (or class `render()`) to get a description of the desired UI based on current props and state.

### Two Phases

| Phase | What Happens | Timing |
|-------|-------------|--------|
| **Render Phase** | Call components, calculate changes (diffing/reconciliation) | Can be paused (React 18 concurrent) |
| **Commit Phase** | Apply changes to DOM, run `componentDidMount/Update`, `useLayoutEffect` | Always synchronous |

After commit, React runs `useEffect` callbacks asynchronously (the "Passive Effects" phase).

**Key insight**: "Rendering" ≠ "updating the DOM". A component can render and produce the same output — no DOM changes needed.

### JSX → Elements → Reconciliation

```jsx
// JSX
<MyComponent a={42} b="test">Text</MyComponent>

// Becomes React.createElement call → plain JS object:
{ type: MyComponent, props: { a: 42, b: "test" }, children: ["Text"] }
```

React collects the full tree of these objects ("virtual DOM"), diffs against the previous tree, and applies only the necessary DOM mutations.

---

## 2. How React Handles Renders

### Queuing Renders

| Mechanism | Component Type |
|-----------|---------------|
| `useState` setter | Function |
| `useReducer` dispatch | Function |
| `this.setState()` | Class |
| `this.forceUpdate()` | Class |
| `ReactDOM.render()` (re-call) | Root |
| `useSyncExternalStore` | Function |

Force-render trick for function components:

```js
const [, forceRender] = useReducer((c) => c + 1, 0);
```

### The Default Cascade Rule

> **When a parent component renders, React will recursively render ALL child components inside of it.**

- React does **NOT** check if props changed — children render unconditionally
- `setState()` in the root `<App>` → every component in the tree renders
- This is by design: React "acts like it redraws the entire app on every update"
- Rendering is not bad — it's how React knows if DOM changes are needed

### Rules of Pure Rendering

Render logic **must NOT**:
- Mutate existing variables/objects
- Create random values (`Math.random()`, `Date.now()`)
- Make network requests
- Queue state updates

Render logic **may**:
- Mutate objects created during that render
- Throw errors
- Lazy-initialize cached data

### Fibers — React's Internal Data Structure

Each component instance is tracked by a **fiber** object containing:
- `type` — component function/class
- `pendingProps`, `memoizedProps` — input data
- `memoizedState` — current state
- `updateQueue` — pending state updates
- `child`, `sibling`, `index` — tree pointers
- `dependencies` — contexts consumed

Props and state you access in components are actually stored on fiber objects. Hooks are stored as a linked list attached to the fiber.

### Component Types and Reconciliation

React reuses existing component instances if the **same type** appears at the **same position** in the tree (compared with `===`).

If the type changes (e.g., `<ComponentA>` → `<ComponentB>`), React **destroys the entire subtree** and recreates from scratch.

**Critical rule**: Never define components inside other components:

```jsx
// ❌ BAD — new reference every render → destroys/recreates child tree
function Parent() {
  function Child() { return <div>Hi</div>; }
  return <Child />;
}

// ✅ GOOD — stable reference
function Child() { return <div>Hi</div>; }
function Parent() { return <Child />; }
```

### Keys and Reconciliation

`key` is not a real prop — it's an instruction to React for identity tracking.

- **Lists**: Always use stable unique IDs (`todo.id`), not array indices
  - Array indices cause wrong component reuse when items are added/removed/reordered
- **Identity reset**: Add `key` to any component to force destroy/recreate when key changes
  - Common pattern: `<DetailForm key={selectedItem.id}>` — resets form state on item change

### Render Batching

| React Version | Batching Behavior |
|---------------|------------------|
| React 17 | Only batches inside React event handlers |
| **React 18** | **Automatic batching** of ALL updates in any single event loop tick |

```js
const onClick = async () => {
  setCounter(0);
  setCounter(1);        // ← Batched together (1 render)

  const data = await fetchSomeData();

  setCounter(2);
  setCounter(3);        // ← Batched together (1 render) — React 18 only!
};
// React 17: 3 renders | React 18: 2 renders
```

Use `flushSync()` in React 18 to opt out of automatic batching and force immediate renders.

### State as a Snapshot (Closures)

```js
function MyComponent() {
  const [counter, setCounter] = useState(0);

  const handleClick = () => {
    setCounter(counter + 1);
    console.log(counter); // ❌ Still 0! (closure captures the snapshot)
  };
}
```

`handleClick` is a **closure** — it can only see variable values from the render pass when it was defined. `setCounter()` queues a future render with a new `counter` value, but this copy of `handleClick` will never see it.

---

## 3. Improving Rendering Performance

Two approaches: (1) do the same work faster, (2) **do less work** by skipping unnecessary renders.

### Optimization APIs

| API | Type | How It Works |
|-----|------|-------------|
| **`React.memo(Component)`** | HOC wrapper | Shallow-compares props; skips render if unchanged |
| **`shouldComponentUpdate()`** | Class lifecycle | Return `false` to skip render |
| **`React.PureComponent`** | Class base | Auto shallow-compare props + state |
| **Same element reference** | Pattern | If child element reference is identical, skip re-render |

All use **shallow equality** (`===` on each field of the object).

**Same element reference** technique:

```jsx
// props.children won't re-render when SomeProvider's state updates
function SomeProvider({ children }) {
  const [counter, setCounter] = useState(0);
  return (
    <div>
      <button onClick={() => setCounter(counter + 1)}>Count: {counter}</button>
      {children}  {/* ← same reference, skips re-render */}
    </div>
  );
}

// useMemo for element references
function Parent() {
  const [counter1, setCounter1] = useState(0);
  const [counter2, setCounter2] = useState(0);

  const memoizedElement = useMemo(() => {
    return <ExpensiveChild />;
  }, [counter1]); // only re-creates if counter1 changes

  return <div>{memoizedElement}</div>;
}
```

### New Props References vs. Memoization

By default, React re-renders children unconditionally → passing new references as props doesn't matter.

**But** if a child is wrapped in `React.memo()`, new references will break the optimization:

```jsx
const MemoizedChild = React.memo(ChildComponent);

function Parent() {
  // ❌ New function + object reference every render → MemoizedChild always re-renders
  const onClick = () => console.log("click");
  const data = { a: 1, b: 2 };

  return <MemoizedChild onClick={onClick} data={data} />;
}
```

**Fix**: Use `useCallback` and `useMemo` to stabilize references:

```jsx
function Parent() {
  const onClick = useCallback(() => console.log("click"), []);
  const data = useMemo(() => ({ a: 1, b: 2 }), []);

  return <MemoizedChild onClick={onClick} data={data} />;
}
```

### Should You Memo Everything?

| Perspective | Argument |
|------------|---------|
| **Dan Abramov** | Memoization has cost (comparing props); many components always receive new props anyway |
| **Mark Erikson** | Widespread `React.memo()` is likely a net perf gain for most apps |
| **React docs** | Only valuable when re-renders are frequent with same props AND rendering is expensive |

**Practical guideline** (from React docs):
> - `memo` is unnecessary if props are always different
> - `useMemo` + `useCallback` are often needed together with `memo`
> - Some teams memoize everything — downside is less readable code, not significant harm

### Immutability Is Required

**React state updates must be immutable.** Two reasons:

1. **Optimization breaks**: `React.memo` / `PureComponent` use `===` — mutation keeps same reference → component thinks nothing changed
2. **Hooks bail out**: `useState` / `useReducer` skip re-render if new value is the same reference

```js
// ❌ Mutation — component won't re-render
const onClick = () => {
  todos[3].completed = true;
  setTodos(todos);  // Same reference → React bails out
};

// ✅ Immutable update
const onClick = () => {
  const newTodos = todos.map((todo, i) =>
    i === 3 ? { ...todo, completed: true } : todo
  );
  setTodos(newTodos);  // New reference → React re-renders
};
```

**Exception**: `this.setState()` in class components **always** triggers re-render, even with mutation.

---

## 4. Context and Rendering Behavior

### How Context Works

- Provider receives a single `value` prop
- Consumers read via `useContext(MyContext)` or `<MyContext.Consumer>`
- React checks if provider value is a **new reference** → if yes, all consumers must re-render

**Context is NOT state management** — you manage the values yourself (typically via `useState`/`useReducer`).

### The Context Re-Render Problem

```jsx
function Parent() {
  const [a, setA] = useState(0);
  const [b, setB] = useState("text");

  // ❌ New object every render → ALL consumers re-render
  const contextValue = { a, b };

  return (
    <MyContext.Provider value={contextValue}>
      <ChildComponent />
    </MyContext.Provider>
  );
}
```

**No partial subscriptions**: A component consuming `value.a` will also re-render when only `value.b` changes, because the entire `value` object is a new reference.

### Context + Default Cascade = Double Whammy

When `Parent` re-renders:
1. Default cascade: all children re-render anyway (regardless of context)
2. Context update: consumers see new value and must re-render

Most of the time, children re-render because of the cascade, not the context update.

### The Fix: Memo the Provider's Child

```jsx
const MemoizedChild = React.memo(ChildComponent);

function Parent() {
  const [a, setA] = useState(0);
  const contextValue = useMemo(() => ({ a }), [a]);

  return (
    <MyContext.Provider value={contextValue}>
      <MemoizedChild />  {/* ← stops cascade */}
    </MyContext.Provider>
  );
}
```

Or use the `{props.children}` pattern:

```jsx
function ContextWrapper({ children }) {
  const [a, setA] = useState(0);
  return (
    <MyContext.Provider value={{ a, setA }}>
      {children}  {/* ← same reference, no cascade */}
    </MyContext.Provider>
  );
}
// Usage: <ContextWrapper><App /></ContextWrapper>
```

> **Sophie Alpert**: "That React Component Right Under Your Context Provider Should Probably Use `React.memo`"

**Important**: Once a context consumer re-renders, React resumes the default cascade — all components below it render too.

---

## 5. React-Redux vs Context

### How React-Redux Works

- Passes the **store instance** (not state) through context → context value never changes
- Uses **subscriptions** outside React to detect store changes
- Runs `mapState` / `useSelector` on every dispatch → only re-renders if selected data changed

### `connect` vs `useSelector`

| Feature | `connect` (HOC) | `useSelector` (Hook) |
|---------|-----------------|---------------------|
| Acts like `React.memo` | ✅ Yes — wrapper checks combined props | ❌ No — can't prevent parent-caused renders |
| Stops render cascade | ✅ Yes — acts as firewall | ❌ No — cascade passes through |
| Selector runs | On dispatch + parent render | On dispatch + every render |
| Fix for cascade | Built-in | Wrap component in `React.memo()` manually |

**Practical impact**: Apps using only `useSelector` (no `connect`) may see larger render cascades. Add `React.memo()` to key components as needed.

### When to Use Context vs Redux

| Use **Context** when | Use **Redux** when |
|---------------------|-------------------|
| Simple values that rarely change | Large, frequently-updated app state |
| Avoiding prop drilling for a subtree | Complex state update logic |
| Keeping dependencies minimal | Medium/large codebase, many developers |

---

## 6. Future React Improvements

### React Forget (Auto-Memoizing Compiler)

- Rewrites function component bodies to automatically add memoization
- Memoizes **JSX element return values** → leverages "same element reference" optimization
- Could potentially **eliminate unnecessary renders throughout the entire tree**
- As of 2022: 3–4 engineers working full-time; goal is Facebook.com fully working before public release
- `useEvent` RFC was closed because React Forget might make it unnecessary

### Context Selectors (RFC)

- Proposed API to selectively subscribe to parts of a context value
- Andrew Clark implemented a proof of concept (Jan 2021)
- No further movement; may be obsoleted by React Forget
- Polyfill available: `use-context-selector` by Daishi Kato

---

## 7. Edge Cases

### Setting State While Rendering

Function components **may** call `setState()` during render **if done conditionally** (equivalent of `getDerivedStateFromProps`):

```jsx
function Component({ items }) {
  const [prevItems, setPrevItems] = useState(items);
  const [selection, setSelection] = useState(null);

  if (items !== prevItems) {
    setPrevItems(items);
    setSelection(null);  // OK — conditional, won't loop infinitely
  }
}
```

React applies the update immediately and re-renders synchronously before continuing. Infinite loops are broken after 50 attempts.

### StrictMode Double Rendering

React **double-renders** components inside `<StrictMode>` in development. Don't rely on `console.log` to count renders — use React DevTools Profiler or log inside `useEffect`.

### Commit Phase Lifecycles

State updates in `useLayoutEffect` / `componentDidMount` / `componentDidUpdate` trigger synchronous re-renders before browser paint — useful for measure-then-update patterns.

---

## Quick Decision Flowchart

```
Component re-rendering too often?
│
├─ Is the parent causing it?
│   ├─ Yes → Wrap child in React.memo()
│   │         └─ Are props always new references?
│   │             └─ Yes → useCallback / useMemo in parent
│   └─ No → Is it a context update?
│       ├─ Yes → Memo the provider's direct child
│       │         └─ Can you split the context?
│       │             └─ Separate frequently-changing from stable values
│       └─ No → Is it a Redux store update?
│           └─ Using useSelector? → Wrap in React.memo() if needed
│
└─ Is the render itself slow?
    ├─ Profile with React DevTools (production build!)
    ├─ Virtualize long lists
    └─ Code-split heavy components with React.lazy
```

---

## Key Takeaways

1. **React renders recursively by default** — parent renders → all children render
2. **Rendering is not bad** — it's how React determines DOM changes
3. **`React.memo()`** skips render if props unchanged (shallow compare)
4. **New references break memo** — stabilize with `useMemo` / `useCallback`
5. **Context forces ALL consumers to re-render** — no partial subscriptions (yet)
6. **Memo the context provider's child** to prevent cascade + context double-hit
7. **React-Redux uses subscriptions**, not context, for state → more granular updates
8. **`connect` acts like `React.memo()`**; `useSelector` doesn't — add memo manually
9. **Always update state immutably** — mutation breaks optimizations and causes bugs
10. **React 18 batches all state updates** automatically (not just event handlers)
11. **React Forget compiler** may eventually auto-memoize everything

---

## Cross-References

| Topic | Related Notes | Connection |
|-------|---------------|------------|
| React hooks, state management, Context | [Learning React](./learning-react.md) | Ch 6–8 cover hooks and state in depth |
| Design patterns (Provider, HOC, Hooks) | [Learning Patterns](./learning-patterns.md) | Provider, HOC, and Hooks patterns |
| Rendering strategies (CSR, SSR, SSG) | [Learning Patterns](./learning-patterns.md) | Rendering Patterns section |
| Performance (code splitting, virtualization) | [Learning Patterns](./learning-patterns.md) | Performance Patterns section |

---

## References

- [Source Article](https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/)
- [React docs: State as a Snapshot](https://react.dev/learn/state-as-a-snapshot)
- [React docs: Optimizing with memo](https://react.dev/reference/react/memo)
- [The Rules of React — Seb Markbage](https://gist.github.com/sebmarkbage/75f0838967cd003cd7f9ab938eb1799f)
- [Josh Comeau: Why React Re-Renders](https://www.joshwcomeau.com/react/why-react-re-renders/)
- [Alex Sidorenko: Visual Guide to React Rendering](https://alexsidorenko.com/blog/react-render-always-rerenders/)
- [Kent C Dodds: Fix the slow render before you fix the re-render](https://kentcdodds.com/blog/fix-the-slow-render-before-you-fix-the-re-render)
