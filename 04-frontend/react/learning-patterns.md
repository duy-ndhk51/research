# Learning Patterns

> **Authors**: Lydia Hallie & Addy Osmani  
> **Year**: 2022  
> **Pages**: 436  
> **Website**: [patterns.dev](https://www.patterns.dev)  
> **Source PDF**: [learning-patterns-final-v11.pdf](../../sources/books/learning-patterns-final-v11.pdf)  
> **Note**: PDF is image-based (Internet Archive scan) — notes created from training knowledge of this book.

---

## TL;DR

A modern guide to **JavaScript and React design patterns**, **rendering strategies**, and **performance optimizations** for web applications. Unlike classic design pattern books that focus on OOP languages, this book applies patterns specifically to the **JavaScript ecosystem** with React-centric examples. It bridges the gap between classic Gang of Four patterns and modern frontend architecture, covering everything from Singleton to Islands Architecture.

---

## Book Structure

| Part | Focus | Patterns Covered |
|------|-------|-----------------|
| **Design Patterns** | Classic + modern JS/React component patterns | Singleton, Proxy, Provider, Prototype, Observer, Module, Mixin, Mediator/Middleware, HOC, Render Props, Hooks, Flyweight, Factory, Compound, Command |
| **Rendering Patterns** | How and where to render web content | CSR, SSR, SSG, ISR, Progressive Hydration, Streaming SSR, React Server Components, Selective Hydration, Islands Architecture |
| **Performance Patterns** | Optimizing loading and runtime performance | Bundle Splitting, Tree Shaking, Preload, Prefetch, Dynamic Import, Import On Visibility/Interaction, Route-Based Splitting, PRPL, List Virtualization |

---

## Part 1: Design Patterns

### Singleton Pattern

**Intent**: Ensure a class has only one instance and provide a global point of access to it.

**In JavaScript**:

```javascript
let instance;

class Counter {
  constructor() {
    if (instance) {
      throw new Error("You can only create one instance!");
    }
    instance = this;
    this.count = 0;
  }

  getCount() { return this.count; }
  increment() { return ++this.count; }
  decrement() { return --this.count; }
}

const counter = Object.freeze(new Counter());
export default counter;
```

| Pros | Cons |
|------|------|
| Memory efficient — single instance | Hidden dependencies — hard to track what uses it |
| Global access point | Testing difficulty — state persists across tests |
| Consistent state | Tight coupling — modules depend on global state |

**Key insight**: In JavaScript, plain objects or ES modules already provide singleton-like behavior. `Object.freeze()` prevents modification. True Singletons are often considered an **anti-pattern** in modern JS — prefer dependency injection or React Context instead.

---

### Proxy Pattern

**Intent**: Intercept and control interactions with an object.

**In JavaScript** (using ES6 `Proxy`):

```javascript
const person = { name: "John", age: 42 };

const personProxy = new Proxy(person, {
  get: (obj, prop) => {
    console.log(`Getting ${prop}: ${obj[prop]}`);
    return Reflect.get(obj, prop);
  },
  set: (obj, prop, value) => {
    if (prop === "age" && typeof value !== "number") {
      throw new Error("Age must be a number");
    }
    console.log(`Setting ${prop} to ${value}`);
    return Reflect.set(obj, prop, value);
  }
});
```

| Use Cases | Benefits |
|-----------|----------|
| Validation | Add logic without modifying original object |
| Formatting / sanitizing | Intercept reads and writes transparently |
| Logging / debugging | Track property access |
| Reactive systems (Vue 3) | Power behind Vue's reactivity engine |

**Key insight**: `Reflect` API mirrors `Proxy` handler methods and should be used inside handlers for correct behavior. Overuse of Proxy can impact performance on hot paths.

---

### Provider Pattern

**Intent**: Share global data across multiple components without prop drilling.

**In React** (using Context API):

```jsx
const ThemeContext = React.createContext("light");

function ThemeProvider({ children }) {
  const [theme, setTheme] = useState("light");
  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

function ThemedButton() {
  const { theme, setTheme } = useContext(ThemeContext);
  return <button className={theme}>Toggle</button>;
}
```

| Pros | Cons |
|------|------|
| Eliminates prop drilling | Can cause unnecessary re-renders |
| Clean separation of concerns | Overuse leads to "Provider hell" (deeply nested providers) |
| Works well for truly global state (theme, auth, locale) | Not ideal for frequently changing state |

**Key insight**: Use multiple small contexts instead of one giant context. For high-frequency updates, consider `useMemo` on the value or use external state libraries (Zustand, Jotai).

---

### Prototype Pattern

**Intent**: Share properties among objects of the same type via the prototype chain.

**In JavaScript**:

```javascript
class Dog {
  constructor(name) { this.name = name; }
  bark() { return "Woof!"; }
}

const dog1 = new Dog("Max");
const dog2 = new Dog("Buddy");
// dog1.bark === dog2.bark → true (shared via prototype)
```

**Key insight**: JavaScript is inherently prototype-based. All objects have a `__proto__` linking to a prototype object. Methods defined on a class are stored on `ClassName.prototype`, shared across all instances. This is memory-efficient — methods exist once, not per-instance.

---

### Observer Pattern

**Intent**: When an event occurs, notify all subscribers (observers) that are subscribed to that event.

**In JavaScript**:

```javascript
class EventEmitter {
  constructor() { this.observers = {}; }

  subscribe(event, fn) {
    this.observers[event] = this.observers[event] || [];
    this.observers[event].push(fn);
    return () => this.unsubscribe(event, fn);
  }

  unsubscribe(event, fn) {
    this.observers[event] = this.observers[event]?.filter(sub => sub !== fn);
  }

  notify(event, data) {
    this.observers[event]?.forEach(fn => fn(data));
  }
}
```

| Use Cases | Examples |
|-----------|---------|
| Event handling | DOM events, Node.js EventEmitter |
| Reactive state updates | RxJS Observables |
| Pub/Sub messaging | WebSocket handlers, message queues |
| Data binding | UI frameworks (Angular, Vue) |

**Key insight**: Separating the Observer from the Observable (Subject) enforces the **separation of concerns** principle. In React, the `useEffect` + state pattern is essentially an observer pattern.

---

### Module Pattern

**Intent**: Encapsulate code into reusable, self-contained pieces with explicit public/private boundaries.

**In JavaScript**:

```javascript
// ES Modules (modern)
// math.js
const privateHelper = (x) => x * x;

export function square(x) { return privateHelper(x); }
export function sum(x, y) { return x + y; }
export default function multiply(x, y) { return x * y; }
```

**Key insight**: ES2015 modules are the standard. They provide **static analysis** (enables tree shaking), **strict mode** by default, and **deferred execution**. The older IIFE / Revealing Module Pattern is largely replaced by ES modules.

---

### Mixin Pattern

**Intent**: Add reusable functionality to objects or classes without inheritance.

**In JavaScript**:

```javascript
const canFly = {
  fly() { console.log(`${this.name} is flying!`); }
};

const canSwim = {
  swim() { console.log(`${this.name} is swimming!`); }
};

class Duck {
  constructor(name) { this.name = name; }
}

Object.assign(Duck.prototype, canFly, canSwim);
new Duck("Donald").fly(); // "Donald is flying!"
```

| Pros | Cons |
|------|------|
| Code reuse without deep inheritance | Implicit dependencies — hard to trace origin |
| Compose behaviors flexibly | Name collisions between mixins |
| Avoids "diamond problem" | React deprecated mixins in favor of Hooks/HOCs |

**Key insight**: In React, **Hooks** replaced mixins entirely. Hooks provide the same composability with better explicitness, static analysis, and no namespace collisions.

---

### Mediator / Middleware Pattern

**Intent**: Central object that handles communication between components, preventing direct coupling.

**Examples in practice**:

| Context | Mediator |
|---------|----------|
| Express.js | Middleware chain — `app.use(cors()); app.use(json());` |
| Redux | Store as mediator; middleware like `redux-thunk`, `redux-saga` |
| Chat room | Central server routing messages between users |

**Key insight**: Middleware in Express/Koa follows the **Chain of Responsibility** pattern — each middleware can process, modify, or pass the request to the next handler via `next()`.

---

### HOC Pattern (Higher-Order Components)

**Intent**: Reuse component logic by wrapping a component and injecting additional props or behavior.

**In React**:

```jsx
function withLoader(WrappedComponent, url) {
  return function WithLoaderComponent(props) {
    const [data, setData] = useState(null);

    useEffect(() => {
      fetch(url).then(res => res.json()).then(setData);
    }, []);

    if (!data) return <div>Loading...</div>;
    return <WrappedComponent {...props} data={data} />;
  };
}

const DogImages = ({ data }) => data.map(img => <img src={img} />);
export default withLoader(DogImages, "/api/dogs");
```

| Pros | Cons |
|------|------|
| Reuse logic across components | "Wrapper hell" — deep nesting |
| Separation of concerns | Naming collisions on injected props |
| Composable: `withAuth(withLoader(Component))` | Hard to trace where props come from |
| | Mostly replaced by Hooks |

**Key insight**: HOCs were the primary React reuse pattern before Hooks. Now prefer custom Hooks unless you specifically need to **wrap rendering** (e.g., error boundaries).

---

### Render Props Pattern

**Intent**: Pass a function as a prop that returns a React element, giving the parent control over what to render.

**In React**:

```jsx
function DataFetcher({ url, render }) {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch(url).then(res => res.json()).then(setData);
  }, [url]);

  return render(data);
}

// Usage
<DataFetcher
  url="/api/dogs"
  render={(data) => data ? <DogImages data={data} /> : <Loading />}
/>
```

**Key insight**: Like HOCs, largely **replaced by Hooks**. The `children` prop as a function is a common variant. Still useful in libraries (e.g., React Motion, Downshift) where rendering is truly customizable.

---

### Hooks Pattern

**Intent**: Share stateful logic between components using functions instead of classes, HOCs, or render props.

**In React**:

```jsx
function useWindowSize() {
  const [size, setSize] = useState({
    width: window.innerWidth,
    height: window.innerHeight
  });

  useEffect(() => {
    const handler = () => setSize({
      width: window.innerWidth,
      height: window.innerHeight
    });
    window.addEventListener("resize", handler);
    return () => window.removeEventListener("resize", handler);
  }, []);

  return size;
}

// Usage in any component
function Header() {
  const { width } = useWindowSize();
  return <header>{width > 768 ? <DesktopNav /> : <MobileNav />}</header>;
}
```

| Advantage Over Classes/HOCs/Render Props |
|------------------------------------------|
| No wrapper hell — flat component tree |
| Explicit data flow — easy to trace |
| Composable — combine hooks in custom hooks |
| Better tree shaking — unused hooks are eliminated |
| Simpler testing — test hooks independently |

**Key insight**: Hooks are now the **default pattern** for logic reuse in React. Rules: only call at top level, only call in React functions. Custom hooks (`use*`) encapsulate and compose logic cleanly.

---

### Compound Pattern

**Intent**: Create a set of components that work together to form a complete UI element with shared implicit state.

**In React**:

```jsx
const SelectContext = createContext();

function Select({ children, onChange }) {
  const [selectedOption, setSelectedOption] = useState(null);
  const handleSelect = (option) => {
    setSelectedOption(option);
    onChange?.(option);
  };
  return (
    <SelectContext.Provider value={{ selectedOption, handleSelect }}>
      <div className="select">{children}</div>
    </SelectContext.Provider>
  );
}

function Option({ value, children }) {
  const { selectedOption, handleSelect } = useContext(SelectContext);
  return (
    <div
      className={selectedOption === value ? "selected" : ""}
      onClick={() => handleSelect(value)}
    >{children}</div>
  );
}

Select.Option = Option;

// Usage — flexible, declarative API
<Select onChange={handleChange}>
  <Select.Option value="react">React</Select.Option>
  <Select.Option value="vue">Vue</Select.Option>
  <Select.Option value="angular">Angular</Select.Option>
</Select>
```

**Examples**: Radix UI, Headless UI, Reach UI, Ant Design's `<Menu>`, `<Form>`, `<Select>`

**Key insight**: Compound components provide a **flexible API** — the consumer controls composition and ordering while the parent manages shared state internally via Context.

---

### Container/Presentational Pattern

**Intent**: Separate data-fetching/logic (container) from rendering (presentational).

```
Container Component          Presentational Component
├── Fetches data              ├── Receives data via props
├── Manages state             ├── Stateless (mostly)
├── No styling                ├── Handles styling/UI
└── Passes data down          └── Highly reusable
```

**Key insight**: With Hooks, this separation is less about **component types** and more about **custom hooks vs components**. The hook handles logic; the component handles rendering. The principle remains valid even if the implementation has evolved.

---

### Factory Pattern

**Intent**: Create objects without specifying the exact class, using a factory function.

```javascript
const createUser = ({ firstName, lastName, email }) => ({
  firstName,
  lastName,
  email,
  fullName() { return `${this.firstName} ${this.lastName}`; }
});

const user1 = createUser({ firstName: "John", lastName: "Doe", email: "john@example.com" });
```

**Key insight**: In JavaScript, factory functions are often preferred over classes because they naturally provide **encapsulation** (closures for private state), avoid `new` keyword issues, and work well with composition.

---

### Flyweight Pattern

**Intent**: Conserve memory by sharing common data across many similar objects.

**Use case**: Rendering thousands of items (books, users, rows) where much of the data structure is identical.

**Key insight**: In React, **list virtualization** (react-window, react-virtuoso) is the practical implementation of the Flyweight concept — only render visible items, reuse DOM nodes.

---

## Part 2: Rendering Patterns

### Overview: The Rendering Spectrum

```
Client-Side ◄─────────────────────────────────────────► Server-Side

   CSR        CSR+SSG      SSR       Streaming SSR      Static
   │           │            │            │                │
   SPA     Pre-rendered   Per-request  Chunks sent     Build-time
   slow     fast first    fresh data   progressively    fastest
   FCP      load          slower TTFB  fast FCP         no dynamic
```

---

### Client-Side Rendering (CSR)

**How it works**: Browser downloads a minimal HTML shell + JS bundle → JS runs → renders the full UI.

```
Browser: GET / → receives empty <div id="root"> → downloads bundle.js → React renders
```

| Pros | Cons |
|------|------|
| Rich interactivity | Slow First Contentful Paint (FCP) |
| Simple deployment (CDN) | Large JS bundle = slow TTI |
| Great for authenticated/dashboard apps | Poor SEO (empty HTML for crawlers) |
| No server costs at scale | Requires loading spinners |

**Best for**: Dashboards, admin panels, apps behind auth where SEO doesn't matter.

---

### Server-Side Rendering (SSR)

**How it works**: Server generates full HTML for every request → sends to browser → browser hydrates (attaches event listeners).

```
Browser: GET / → Server runs React → full HTML response → browser hydrates
```

| Pros | Cons |
|------|------|
| Fast FCP — content visible immediately | Server cost per request |
| Good SEO — full HTML for crawlers | Slower TTFB (server must render) |
| Fresh data on every request | Full hydration blocks interactivity |
| Works with dynamic/personalized content | More complex infrastructure |

**Best for**: E-commerce product pages, news sites, social media feeds — content that changes frequently and needs SEO.

---

### Static Site Generation (SSG)

**How it works**: Pages are pre-rendered at **build time** → served as static HTML files from CDN.

| Pros | Cons |
|------|------|
| Fastest TTFB — served from CDN edge | Stale data between builds |
| No server needed at runtime | Build time grows with page count |
| Excellent SEO | Not for highly dynamic content |
| Very cheap to host | Must rebuild to update content |

**Best for**: Blogs, documentation, marketing pages, portfolios — content that rarely changes.

---

### Incremental Static Regeneration (ISR)

**How it works**: Combine SSG with background revalidation. Serve static pages, but regenerate them in the background after a specified time.

```javascript
// Next.js
export async function getStaticProps() {
  const data = await fetchData();
  return {
    props: { data },
    revalidate: 60 // Regenerate page every 60 seconds
  };
}
```

| Pros | Cons |
|------|------|
| Static speed + fresh data | Can serve briefly stale content |
| No full rebuilds | Next.js / framework-specific |
| Scales to millions of pages | Complex cache invalidation |

**Best for**: E-commerce catalogs, blogs with comments, content that updates periodically.

---

### Progressive Hydration

**How it works**: Instead of hydrating the entire page at once, hydrate components **lazily** — only when they're needed (visible, interacted with, or idle).

```
Page loads → above-the-fold hydrates immediately
           → below-the-fold hydrates on scroll/idle
           → modal hydrates on click
```

| Benefit | Description |
|---------|-------------|
| Faster TTI | Less JS to execute upfront |
| Reduced main thread work | Hydration spread over time |
| Better user experience | Visible content interactive sooner |

---

### Streaming Server-Side Rendering

**How it works**: Server sends HTML in **chunks** as it's generated, rather than waiting for the full page.

```
Server: renderToPipeableStream()
  → sends <head> + shell immediately
  → sends main content as it resolves
  → sends deferred content (comments, sidebar) later
```

**React 18** introduced `renderToPipeableStream` for streaming SSR with `<Suspense>` boundaries marking chunk boundaries.

| Pros | Cons |
|------|------|
| Fastest TTFB — first byte sent immediately | More complex server infrastructure |
| Progressive content reveal | Requires Suspense-compatible architecture |
| Combines well with Selective Hydration | Debugging is harder |

---

### React Server Components (RSC)

**How it works**: Components that run **only on the server** — they never ship JavaScript to the client. They can directly access databases, file systems, and backend services.

```
Server Components (*.server.js)     Client Components (*.client.js)
├── Run on server only               ├── Run on client (+ SSR)
├── Zero JS sent to client            ├── JS bundle included
├── Direct DB/API access              ├── Interactivity (state, effects)
├── Can't use useState/useEffect      ├── Can use all React hooks
├── Can import Client Components      ├── Cannot import Server Components
└── Async/await friendly              └── Standard React components
```

| Pros | Cons |
|------|------|
| Smaller client bundles | New mental model to learn |
| Direct backend access | Framework-specific (Next.js App Router) |
| Automatic code splitting | Can't use hooks in server components |
| No client-side waterfalls | Debugging across server/client boundary |

**Key insight**: RSC is not a replacement for SSR — it's **complementary**. SSR renders HTML for fast FCP; RSC keeps rendering logic on the server to reduce client JS.

---

### Selective Hydration

**How it works**: React 18 can hydrate different parts of the page **independently** based on user interaction. If a user clicks a component that hasn't hydrated yet, React **prioritizes** hydrating that component.

Requires: `<Suspense>` boundaries + streaming SSR.

---

### Islands Architecture

**How it works**: The page is mostly **static HTML** with small interactive "islands" that hydrate independently. Each island is a self-contained widget.

```
┌──────────────────────────────────────────┐
│ Static Header HTML (no JS)               │
├──────────────────────────────────────────┤
│ Static Content HTML (no JS)              │
├──────────┬──────────┬────────────────────┤
│ Island:  │ Static   │ Island:            │
│ Search   │ sidebar  │ Comments           │
│ (React)  │ (no JS)  │ (React)            │
├──────────┴──────────┴────────────────────┤
│ Static Footer HTML (no JS)               │
└──────────────────────────────────────────┘
```

**Frameworks**: Astro, Fresh (Deno), Marko, Qwik (similar philosophy)

| Pros | Cons |
|------|------|
| Minimal JS — only islands ship code | Not ideal for highly interactive SPAs |
| Independent hydration per island | Less ecosystem support (still emerging) |
| Great performance by default | Mental model shift from SPA thinking |

---

## Part 3: Performance Patterns

### Bundle Splitting / Code Splitting

**Intent**: Split the application bundle into smaller chunks that load on demand.

```javascript
// Route-based splitting (React + React Router)
const Home = lazy(() => import("./pages/Home"));
const About = lazy(() => import("./pages/About"));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
      </Routes>
    </Suspense>
  );
}
```

---

### Dynamic Import Patterns

| Pattern | When JS Loads | Use Case |
|---------|--------------|----------|
| **Import on Interaction** | User clicks/hovers | Modals, tooltips, chat widgets |
| **Import on Visibility** | Component scrolls into viewport | Below-fold content, infinite scroll |
| **Route-Based Splitting** | User navigates to route | Page-level code splitting |
| **Prefetch** | Browser idle time | Likely next navigation |
| **Preload** | During current page load | Critical resources needed soon |

```javascript
// Import on Interaction
const handleClick = async () => {
  const { Modal } = await import("./Modal");
  // render modal
};

// Import on Visibility (Intersection Observer)
const ref = useRef();
useEffect(() => {
  const observer = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) {
      import("./HeavyComponent").then(setComponent);
    }
  });
  observer.observe(ref.current);
}, []);
```

---

### Tree Shaking

**Intent**: Eliminate dead code — unused exports are removed from the final bundle.

**Requirements**:
- ES module syntax (`import`/`export`, not `require`)
- Side-effect-free modules (mark in `package.json`: `"sideEffects": false`)
- Build tool support (Webpack, Rollup, esbuild, Vite)

```javascript
// ✅ Tree-shakeable — bundler can remove unused exports
import { debounce } from "lodash-es";

// ❌ NOT tree-shakeable — imports entire library
import _ from "lodash";
```

---

### PRPL Pattern

| Letter | Stands For | Action |
|--------|-----------|--------|
| **P** | Push | Push critical resources for the initial route |
| **R** | Render | Render the initial route as quickly as possible |
| **P** | Pre-cache | Pre-cache remaining routes via service worker |
| **L** | Lazy-load | Lazy-load and create remaining routes on demand |

**Key insight**: PRPL is a **mental model** for optimizing loading, not a specific tool. It combines preloading, SSR/SSG, service workers, and code splitting.

---

### List Virtualization

**Intent**: Only render items currently visible in the viewport, not the entire list.

**Libraries**: `react-window`, `react-virtuoso`, `@tanstack/react-virtual`

```
Full list: 10,000 items
Rendered DOM: ~20 items (visible viewport + buffer)
→ Constant DOM size regardless of data size
→ O(1) memory for rendering vs O(n)
```

**When to use**: Any list/table/grid with 100+ items. Especially important for mobile performance.

---

### Resource Hints

```html
<!-- Preload: critical resource needed NOW (current page) -->
<link rel="preload" href="/fonts/Inter.woff2" as="font" crossorigin>

<!-- Prefetch: resource needed SOON (next navigation) -->
<link rel="prefetch" href="/about.js">

<!-- Preconnect: establish early connection to origin -->
<link rel="preconnect" href="https://api.example.com">

<!-- DNS Prefetch: resolve DNS early (fallback for preconnect) -->
<link rel="dns-prefetch" href="https://cdn.example.com">
```

| Hint | Priority | Timing | Use For |
|------|----------|--------|---------|
| `preload` | High | Current page | Fonts, critical CSS, above-fold images |
| `prefetch` | Low | Next navigation | Route bundles, next-page resources |
| `preconnect` | Medium | Before first request | API servers, CDNs |

---

### Compressing JavaScript

| Technique | What It Does |
|-----------|-------------|
| **Minification** | Remove whitespace, shorten variables (Terser, esbuild) |
| **Compression** | Gzip (~60% reduction) or Brotli (~70-80% reduction) |
| **Scope Hoisting** | Concatenate modules to reduce function wrappers |
| **Dead Code Elimination** | Remove unreachable code paths |

**Priority order**: Tree shaking → Code splitting → Minification → Brotli compression

---

## Pattern Selection Guide

### When to Use Which Design Pattern

| Problem | Pattern |
|---------|---------|
| Share global state (theme, auth, locale) | **Provider Pattern** |
| Reuse stateful logic across components | **Hooks Pattern** (custom hooks) |
| Build flexible multi-part UI components | **Compound Pattern** |
| Validate/intercept object access | **Proxy Pattern** |
| Decouple event producers from consumers | **Observer Pattern** |
| Wrap components with extra behavior | **HOC Pattern** (or Hooks) |
| Global single-instance service | **Module Pattern** (avoid Singleton) |
| Create objects with similar structure | **Factory Pattern** |

### When to Use Which Rendering Pattern

| Scenario | Pattern |
|----------|---------|
| Dashboard / app behind auth | **CSR** |
| Blog / docs / marketing pages | **SSG** |
| E-commerce / news / social feed | **SSR** or **ISR** |
| Content site + a few interactive widgets | **Islands Architecture** |
| Large app with mixed static + dynamic | **RSC** + Streaming SSR |
| Existing SSR app with slow TTI | **Progressive / Selective Hydration** |

---

## Common Pitfalls

| Pitfall | Why It Hurts | Fix |
|---------|-------------|-----|
| Using Singleton for shared state in React | State doesn't trigger re-renders | Use Context/Provider or state library |
| Overusing Context for frequent updates | Causes cascading re-renders | Split contexts; use Zustand/Jotai for frequent state |
| HOC wrapper hell | Deep nesting, hard to debug | Migrate to custom Hooks |
| Hydrating everything at once | Slow TTI, blocks main thread | Progressive/Selective Hydration |
| Not code-splitting | Huge initial bundle | Route-based splitting + lazy() |
| Importing full lodash | Tree shaking fails | Use `lodash-es` or individual imports |
| Rendering 10k+ list items | DOM thrashing, memory issues | List virtualization |
| SSR everything | Unnecessary server costs | Use SSG/ISR where possible |

---

## Cross-References

| Topic in This Book | Related Notes | Connection |
|--------------------|---------------|------------|
| JavaScript Module Pattern, Prototype | [You Don't Know JS](../../03-languages/javascript/you-dont-know-js.md) | Deep dive into JS modules, prototypes, closures |
| Clean code in React components | [Clean Code](../../01-fundamentals/clean-code/clean-code.md) | Naming, functions, modularity principles |
| Code smells in pattern misuse | [Dive Into Refactoring](../../01-fundamentals/refactoring/dive-into-refactoring.md) | Refactoring anti-patterns |
| Interview questions about patterns | [Cracking the Coding Interview](../../10-soft-skills/interviewing/cracking-the-coding-interview.md) | OO Design chapter (Ch 7) |

---

## References

- [Source PDF](../../sources/books/learning-patterns-final-v11.pdf)
- [patterns.dev](https://www.patterns.dev) — Free online version with interactive examples
- [Addy Osmani — Learning JavaScript Design Patterns](https://www.patterns.dev/posts/classic-design-patterns/) — Extended companion
- [React Docs — Server Components](https://react.dev/blog/2023/03/22/react-labs-what-we-have-been-working-on-march-2023)
- [web.dev — Rendering on the Web](https://web.dev/rendering-on-the-web/) — Google's rendering guide
