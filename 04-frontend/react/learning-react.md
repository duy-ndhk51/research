# Learning React — Modern Patterns for Developing React Apps

> **Authors**: Alex Banks & Eve Porcello  
> **Year**: 2020 (2nd Edition)  
> **Pages**: 310  
> **Publisher**: O'Reilly Media  
> **Source PDF**: [learning-react-modern-patterns-for-developing-react-apps-alex-banks-eve-porcello-oreilly-media-2020.pdf](../../sources/books/learning-react-modern-patterns-for-developing-react-apps-alex-banks-eve-porcello-oreilly-media-2020.pdf)

---

## TL;DR

A beginner-to-intermediate guide that teaches React from first principles, starting with modern JavaScript (ES6+) and functional programming foundations, then building through React components, Hooks, state management, data fetching, Suspense, testing, routing, and server-side rendering. The book uses a **Color Organizer** app as a running project to demonstrate concepts progressively. Strong emphasis on **functional programming patterns** and **Hooks** as the modern React paradigm.

---

## Book Structure

| Chapter | Topic | Focus |
|---------|-------|-------|
| 1 | Welcome to React | Setup, tooling, React DevTools |
| 2 | JavaScript for React | ES6+ syntax: const/let, arrow functions, destructuring, spread, async/await, modules |
| 3 | Functional Programming with JS | Immutability, pure functions, higher-order functions, composition, recursion |
| 4 | How React Works | React elements, ReactDOM, createElement, component tree |
| 5 | React with JSX | JSX syntax, Babel, webpack, Create React App |
| 6 | React State Management | useState, refs, controlled components, custom hooks, Context |
| 7 | Enhancing Components with Hooks | useEffect, useReducer, useMemo, useCallback, performance |
| 8 | Incorporating Data | fetch, localStorage, render props, virtualized lists, GraphQL |
| 9 | Suspense | Error Boundaries, code splitting, lazy loading, Fiber architecture |
| 10 | React Testing | ESLint, Prettier, PropTypes, Flow, TypeScript, Jest, React Testing Library |
| 11 | React Router | Routes, nesting, redirects, routing parameters, useNavigate |
| 12 | React and the Server | Isomorphic/universal JS, SSR with Express, Next.js, Gatsby |

---

## Key Concepts

### 1. JavaScript Foundations for React (Ch 2)

Essential modern JS syntax used throughout React codebases:

| Feature | Purpose in React |
|---------|-----------------|
| `const` / `let` | Block-scoped variables; `const` for values that won't be reassigned |
| Arrow functions | Concise syntax; lexical `this` binding (no own `this` context) |
| Destructuring | Extract props: `function Color({ title, color, rating })` |
| Spread operator | Clone objects/arrays immutably; pass props: `<Color {...color} />` |
| Template literals | String interpolation: `` `Hello ${name}` `` |
| ES modules | `import` / `export` for code organization |
| Promises / async-await | Async data fetching with fetch API |
| Classes | Historical React (class components); still used for Error Boundaries |

**Arrow functions and `this`**: Arrow functions don't have their own `this` — they inherit from the enclosing scope. This is crucial in React event handlers and callbacks:

```javascript
// ❌ Regular function loses `this` in setTimeout
print: function(delay) {
  setTimeout(function() {
    console.log(this.items); // `this` is Window, not the object
  }, delay);
}

// ✅ Arrow function preserves `this`
print: function(delay) {
  setTimeout(() => {
    console.log(this.items); // `this` is the enclosing object
  }, delay);
}
```

### 2. Functional Programming Foundations (Ch 3)

React is built on functional programming principles. Core concepts:

| Concept | Description | React Application |
|---------|-------------|-------------------|
| **Immutability** | Never mutate data; create new copies | State updates: `setColors([...colors, newColor])` |
| **Pure Functions** | Same input → same output, no side effects | Components as pure functions of props |
| **Higher-Order Functions** | Functions that take/return other functions | HOCs, `Array.map`, `Array.filter`, `Array.reduce` |
| **Composition** | Combine small functions into larger ones | Component composition, custom hooks |
| **Declarative** | Describe *what* to do, not *how* | JSX describes UI; React handles DOM updates |

**Key data transformations with `Array` methods**:

```javascript
// filter — select items
const activeUsers = users.filter(u => u.active);

// map — transform items
const names = users.map(u => u.name);

// reduce — accumulate into single value
const total = items.reduce((sum, item) => sum + item.price, 0);
```

### 3. How React Works (Ch 4)

**React elements** are plain JavaScript objects describing what should appear on screen:

```javascript
React.createElement("h1", { id: "title" }, "Hello World");
// Produces: { type: "h1", props: { id: "title", children: "Hello World" } }
```

**ReactDOM** renders these element descriptions into actual DOM nodes. React uses a **virtual DOM** — a lightweight copy of the DOM tree — to efficiently calculate the minimum set of changes needed.

**Components** are functions that return React elements. They accept `props` (input data) and can be composed into a tree:

```jsx
function IngredientsList({ items }) {
  return (
    <ul>
      {items.map((item, i) => <li key={i}>{item}</li>)}
    </ul>
  );
}
```

**Key rule**: When rendering lists, each item needs a unique `key` prop so React can efficiently track changes.

### 4. React State Management (Ch 6)

#### useState Hook

```jsx
const [color, setColor] = useState("#000000");
```

- Returns `[currentValue, setterFunction]`
- Calling the setter triggers a **re-render**
- State is local to the component instance

#### State in Component Trees

Data flows **down** via props; interactions flow **up** via callback functions:

```
App (owns state)
├── passes colors[] down as props
├── passes onRemoveColor callback down
└── ColorList
    └── Color
        └── calls onRemove(id) → bubbles up to App → App updates state
```

**Pattern**: `f => f` as default for optional callback props — a no-op function that prevents errors when the callback isn't provided:

```jsx
function Color({ onRemove = f => f, onRate = f => f }) { ... }
```

#### Controlled vs Uncontrolled Components

| Type | How Values Are Managed | When to Use |
|------|----------------------|-------------|
| **Uncontrolled** | DOM manages values; accessed via `useRef` | Quick forms, integrating with non-React code |
| **Controlled** | React state manages values via `useState` + `onChange` | Forms needing validation, dynamic behavior |

```jsx
// Controlled component
<input
  value={title}
  onChange={e => setTitle(e.target.value)}
  type="text"
/>
```

#### Custom Hooks

Abstract reusable stateful logic into `use*` functions:

```jsx
export const useInput = (initialValue) => {
  const [value, setValue] = useState(initialValue);
  return [
    { value, onChange: e => setValue(e.target.value) },
    () => setValue(initialValue)
  ];
};

// Usage
const [titleProps, resetTitle] = useInput("");
<input {...titleProps} type="text" />
```

#### React Context

Avoid "prop drilling" by sharing state across the component tree:

```jsx
const ColorContext = createContext();

function ColorProvider({ children }) {
  const [colors, setColors] = useState(colorData);
  return (
    <ColorContext.Provider value={{ colors, setColors }}>
      {children}
    </ColorContext.Provider>
  );
}

// Any descendant component
function ColorList() {
  const { colors } = useContext(ColorContext);
  return colors.map(c => <Color key={c.id} {...c} />);
}
```

### 5. Enhancing Components with Hooks (Ch 7)

#### useEffect — Side Effects

```jsx
useEffect(() => {
  // runs after render
  document.title = `${count} clicks`;

  return () => {
    // cleanup (runs before next effect or unmount)
  };
}, [count]); // dependency array — only re-run when count changes
```

| Dependency Array | Behavior |
|-----------------|----------|
| Not provided | Runs after **every** render |
| `[]` (empty) | Runs **once** after initial render (like componentDidMount) |
| `[dep1, dep2]` | Runs when any dependency changes |

**useLayoutEffect**: Same as `useEffect` but fires synchronously **after DOM mutations, before the browser paints**. Use for DOM measurements or visual updates that must happen before the user sees.

#### useReducer — Complex State

```jsx
function reducer(state, action) {
  switch (action.type) {
    case "ADD_COLOR":
      return { ...state, colors: [...state.colors, action.payload] };
    case "REMOVE_COLOR":
      return { ...state, colors: state.filter(c => c.id !== action.payload) };
    default:
      return state;
  }
}

const [state, dispatch] = useReducer(reducer, initialState);
dispatch({ type: "ADD_COLOR", payload: newColor });
```

Best for state with **multiple sub-values** or when the **next state depends on the previous**.

#### Performance Optimization

| Hook | Purpose |
|------|---------|
| `useMemo(fn, deps)` | Memoize expensive **computed values** — only recalculates when deps change |
| `useCallback(fn, deps)` | Memoize **function references** — prevents unnecessary child re-renders |
| `React.memo(Component)` | Skip re-rendering if props haven't changed (shallow comparison) |

```jsx
const sortedColors = useMemo(
  () => colors.sort((a, b) => a.title.localeCompare(b.title)),
  [colors]
);
```

### 6. Incorporating Data (Ch 8)

#### Fetching Data Pattern

```jsx
function GitHubUser({ login }) {
  const [data, setData] = useState();
  const [error, setError] = useState();
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!login) return;
    setLoading(true);
    fetch(`https://api.github.com/users/${login}`)
      .then(res => res.json())
      .then(setData)
      .then(() => setLoading(false))
      .catch(setError);
  }, [login]);

  if (loading) return <h1>Loading...</h1>;
  if (error) return <pre>{JSON.stringify(error)}</pre>;
  if (!data) return null;
  return <UserProfile data={data} />;
}
```

**Three states of any async request**: pending → success | fail. Every data fetch must handle all three.

#### Render Props

Pass a function-as-prop that receives data and returns what to render:

```jsx
<List
  data={peaks}
  renderEmpty={<p>No items</p>}
  renderItem={item => <>{item.name} - {item.elevation}ft</>}
/>
```

#### Virtualized Lists

For large datasets (1000+ items), only render items visible in the viewport using libraries like `react-window` or `react-virtuoso`. Dramatically reduces DOM nodes and improves performance.

#### Waterfall vs Parallel Requests

- **Waterfall**: Requests happen sequentially — each waits for the previous → slow
- **Parallel**: Fire all requests simultaneously with `Promise.all` → fast

```jsx
// ❌ Waterfall
const user = await fetch("/user");
const posts = await fetch("/posts"); // waits for user first

// ✅ Parallel
const [user, posts] = await Promise.all([
  fetch("/user"),
  fetch("/posts")
]);
```

### 7. Suspense & Error Boundaries (Ch 9)

#### Error Boundaries

Class components that catch JavaScript errors in their child component tree:

```jsx
class ErrorBoundary extends React.Component {
  state = { hasError: false };

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) return this.props.fallback;
    return this.props.children;
  }
}
```

**Note**: Error Boundaries only work as **class components** — they cannot be written as function components (as of React 18).

#### Code Splitting with React.lazy

```jsx
const Main = React.lazy(() => import("./Main"));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <Main />
    </Suspense>
  );
}
```

Only loads the `Main` component's code when it's actually rendered. The `Suspense` component shows a fallback UI while loading.

#### Suspense with Data (Experimental)

The pattern of **throwing promises** to communicate async state:

```javascript
function createResource(pending) {
  let error, response;
  pending.then(r => (response = r)).catch(e => (error = e));
  return {
    read() {
      if (error) throw error;
      if (response) return response;
      throw pending;
    }
  };
}
```

- `throw promise` → caught by `<Suspense>`, renders fallback
- `throw error` → caught by `<ErrorBoundary>`, renders error UI
- `return data` → renders the component normally

#### React Fiber

React's reconciliation engine (rewritten in v16.0):

- Splits rendering work into small **units of work** called **fibers**
- Can **pause and resume** rendering — yields to the main thread for high-priority tasks (user input, animations)
- Enables **concurrent rendering**, **Suspense**, and **prioritized updates**
- Separates the **reconciler** (diffing algorithm in React Core) from the **renderer** (ReactDOM, React Native, etc.)

### 8. React Testing (Ch 10)

#### Testing Stack

| Tool | Purpose |
|------|---------|
| **ESLint** | Static code analysis — catches bugs and enforces style |
| **Prettier** | Automatic code formatting |
| **PropTypes** | Runtime type checking for component props |
| **Flow / TypeScript** | Static type checking at build time |
| **Jest** | Test runner + assertion library |
| **React Testing Library** | DOM testing utilities for React components |

#### TypeScript with React

```tsx
type AppProps = {
  item: string;
  cost?: number; // optional
};

function App({ item, cost }: AppProps) {
  const [color, setColor] = useState("purple"); // type inferred as string
  return <h1>{color} {item}</h1>;
}
```

TypeScript infers hook types from initial values — `useState("purple")` automatically types the state as `string`.

#### Testing Pattern (TDD Cycle)

```
1. Write test → 2. Run & watch fail (RED) → 3. Write minimal code to pass (GREEN) → 4. Refactor (GOLD)
```

```javascript
// Jest test
describe("Math functions", () => {
  test("Multiplies by two", () => {
    expect(timesTwo(4)).toBe(8);
  });
});

// React component test
import { render } from "@testing-library/react";

test("renders star component", () => {
  const { getByTestId } = render(<Star />);
  expect(getByTestId("star")).toHaveAttribute("color", "grey");
});
```

#### Key Matchers

| Matcher | Use Case |
|---------|----------|
| `.toBe(value)` | Primitive equality (numbers, strings, booleans) |
| `.toEqual(object)` | Deep equality for objects and arrays |
| `.toBeTruthy()` / `.toBeFalsy()` | Boolean-ish checks |
| `.toHaveLength(n)` | Array/string length |
| `.toHaveAttribute(attr, value)` | DOM element attributes |

### 9. React Router (Ch 11)

```jsx
import { BrowserRouter, Routes, Route, useNavigate, useParams } from "react-router-dom";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="colors" element={<ColorList />}>
          <Route path=":id" element={<ColorDetails />} />
        </Route>
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}
```

| Hook | Purpose |
|------|---------|
| `useNavigate()` | Programmatic navigation: `navigate("/colors")` |
| `useParams()` | Access URL parameters: `const { id } = useParams()` |
| `useLocation()` | Access current URL info |

**Nested routes**: Child `<Route>` elements render inside parent's `<Outlet />`.

### 10. React and the Server (Ch 12)

#### Isomorphic vs Universal

| Term | Meaning |
|------|---------|
| **Universal** | Same code runs in multiple environments (browser + Node.js) |
| **Isomorphic** | App can be rendered on multiple platforms (server + client) |

#### Server-Side Rendering with Express

```javascript
import ReactDOMServer from "react-dom/server";
import { Menu } from "../src/Menu";

app.get("/*", (req, res) => {
  const html = ReactDOMServer.renderToString(<Menu recipes={data} />);
  const indexFile = path.resolve("./build/index.html");
  fs.readFile(indexFile, "utf8", (err, data) => {
    res.send(data.replace(
      '<div id="root"></div>',
      `<div id="root">${html}</div>`
    ));
  });
});
```

**Hydration**: On the client, use `ReactDOM.hydrate()` instead of `ReactDOM.render()` — it attaches event listeners to server-rendered HTML without re-creating DOM nodes.

**Order of operations**:
1. Server renders static HTML → user sees content immediately
2. Browser downloads JavaScript bundle
3. React **hydrates** — attaches interactivity to existing HTML
4. App becomes fully interactive

#### Next.js

Framework built on React that provides SSR, SSG, file-based routing, and API routes out of the box. Mentioned as the recommended production-ready approach.

#### Gatsby

Static site generator for React. Pre-renders pages at build time. Uses GraphQL for data sourcing. Best for content-heavy sites (blogs, docs, marketing).

---

## The Color Organizer — Running Project

The book builds a **Color Organizer** app across chapters 6–12, progressively adding features:

| Chapter | Feature Added |
|---------|--------------|
| Ch 6 | Star rating component, state management with useState, add/remove/rate colors, Context API |
| Ch 7 | useEffect for side effects, useReducer for complex state, performance optimization |
| Ch 8 | Fetch data from APIs, localStorage caching, render props, virtualized lists |
| Ch 9 | Error boundaries, code splitting with React.lazy, Suspense for async |
| Ch 10 | Unit tests with Jest, component tests with React Testing Library |
| Ch 11 | Client-side routing with React Router, color detail pages |
| Ch 12 | Server-side rendering the app with Express + Next.js |

---

## Common Pitfalls

| Pitfall | Why It Hurts | Fix |
|---------|-------------|-----|
| Mutating state directly | React won't detect changes → no re-render | Always create new objects/arrays: `[...arr, item]`, `{...obj, key: val}` |
| Missing dependency in useEffect | Stale closures; effect doesn't re-run when it should | Include all values from component scope used inside the effect |
| Not providing `key` on list items | React can't efficiently track which items changed | Use stable, unique IDs (not array index for dynamic lists) |
| Prop drilling through many layers | Verbose, fragile, hard to refactor | Use Context or state management library |
| Fetching data without loading/error states | Blank screen or crashed app | Always handle all three states: pending, success, fail |
| Using useEffect for everything | Unnecessary re-renders, complex logic | Consider useReducer, useMemo, or event handlers instead |
| Forgetting `()` around returned objects in arrow functions | `SyntaxError: Unexpected token` | `const fn = () => ({ key: value })` — wrap in parentheses |
| Using arrow function for object methods | `this` refers to outer scope, not the object | Use regular `function` for object methods that need `this` |

---

## Cross-References

| Topic in This Book | Related Notes | Connection |
|--------------------|---------------|------------|
| Design patterns (Provider, HOC, Hooks, Render Props) | [Learning Patterns](./learning-patterns.md) | Deeper dive into pattern theory and tradeoffs |
| JavaScript fundamentals (scope, closures, `this`) | [You Don't Know JS](../../03-languages/javascript/you-dont-know-js.md) | Thorough JS foundation for Ch 2–3 |
| Clean component code | [Clean Code](../../01-fundamentals/clean-code/clean-code.md) | Naming, function design, modularity |
| Interview questions on React | [Cracking the Coding Interview](../../10-soft-skills/interviewing/cracking-the-coding-interview.md) | OO Design (Ch 7), System Design (Ch 9) |

---

## References

- [Source PDF](../../sources/books/learning-react-modern-patterns-for-developing-react-apps-alex-banks-eve-porcello-oreilly-media-2020.pdf)
- [GitHub Repository](https://github.com/moonhighway/learning-react) — All code examples
- [React Documentation](https://react.dev) — Official docs
- [Create React App](https://create-react-app.dev) — Project scaffolding tool
- [React Router](https://reactrouter.com) — Client-side routing
- [Jest](https://jestjs.io) — Testing framework
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/) — Component testing
