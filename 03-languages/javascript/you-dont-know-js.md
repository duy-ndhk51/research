# You Don't Know JS (1st Edition)

> **Author:** Kyle Simpson (@getify)
> **Year:** 2014–2015 | **Books:** 6 volumes | **Code Examples:** JavaScript (ES5/ES6)
> **Source PDF:** [../../sources/books/kyle-simpson-you-dont-know-js.pdf](../../sources/books/kyle-simpson-you-dont-know-js.pdf)
> **Note:** PDF is image-based; notes written from comprehensive knowledge of the book series.
> **Free online:** [github.com/getify/You-Dont-Know-JS](https://github.com/getify/You-Dont-Know-JS)

## TL;DR

A 6-book series that dives deep into JavaScript's core mechanisms that most developers use daily but don't truly understand. It covers scope, closures, `this`, prototypes, types, coercion, async patterns, performance, and ES6+ features. The central thesis: **you can't effectively use what you don't understand** — instead of avoiding the "hard parts" of JS, learn them deeply.

---

## Book 1: Up & Going

An introduction to programming and JavaScript fundamentals for beginners.

### Core Concepts

- **Values & Types:** JavaScript has typed values, not typed variables. Types: `string`, `number`, `boolean`, `null`, `undefined`, `object`, `symbol` (ES6).
- **Coercion:** Converting between types. *Explicit* (you clearly do it) vs *implicit* (JS does it for you). Not a footgun if you understand the rules.
- **Variables:** `var` is function-scoped. Block scoping introduced with `let` and `const` in ES6.
- **Conditionals & Loops:** `if`, `switch`, `while`, `do..while`, `for` — standard control flow.
- **Functions:** Functions are values. They can be assigned, passed, and returned. Key to understanding closures.
- **Scope:** Where the engine looks for variables. Nested scope creates a chain. This is the foundation for everything that follows.

### Key Takeaway

JavaScript has deep, nuanced mechanics. Avoiding the "weird parts" is not the answer — learning them is.

---

## Book 2: Scope & Closures

The deepest dive into how JavaScript's scoping system actually works.

### Chapter 1: What is Scope?

Compilation involves three actors:
1. **Engine:** Runs the program
2. **Compiler:** Parses and code-generates
3. **Scope:** Maintains the look-up list of declared variables

Two types of variable lookups:
- **LHS (Left-Hand Side):** Target of assignment — "who's the target?"
- **RHS (Right-Hand Side):** Source of value — "who's the source?"

```javascript
var a = 2;    // LHS lookup for `a`
console.log(a); // RHS lookup for `a`
```

### Chapter 2: Lexical Scope

- Scope is defined at **author-time** (where you write functions/blocks), not at runtime.
- Nested functions can access outer scope variables (scope chain).
- `eval()` and `with` can cheat lexical scope — but destroy engine optimizations. **Never use them.**

### Chapter 3: Function vs Block Scope

- **Function scope:** Every function creates a new scope.
- **IIFE (Immediately Invoked Function Expression):** Creates scope without polluting outer scope.
- **Block scope:** `let` and `const` (ES6) attach to `{}` blocks, not functions.
- `try/catch` — the `catch` clause is block-scoped (even pre-ES6).

```javascript
// IIFE pattern
(function() {
    var hidden = "can't see me outside";
})();

// Block scope with let
{
    let blockScoped = true;
}
// blockScoped is NOT accessible here
```

### Chapter 4: Hoisting

- Variable and function **declarations** are processed during compilation, before execution.
- Function declarations are hoisted entirely (including body). Variable declarations (`var`) are hoisted but assigned `undefined`.
- `let`/`const` are hoisted but NOT initialized — accessing them before declaration throws `ReferenceError` (Temporal Dead Zone).
- Functions are hoisted first, then variables.

```javascript
foo();  // works! function declaration is fully hoisted
function foo() { console.log("hoisted"); }

bar();  // TypeError: bar is not a function
var bar = function() { console.log("not hoisted"); };
```

### Chapter 5: Scope Closures

> "Closure is when a function is able to remember and access its lexical scope even when that function is executing outside its lexical scope."

```javascript
function makeCounter() {
    var count = 0;
    return function() {
        return ++count;
    };
}
var counter = makeCounter();
counter(); // 1
counter(); // 2 — closure remembers `count`
```

**The classic loop problem:**

```javascript
// BUG: prints 6 five times
for (var i = 1; i <= 5; i++) {
    setTimeout(function() { console.log(i); }, i * 1000);
}

// FIX 1: IIFE creates new scope per iteration
for (var i = 1; i <= 5; i++) {
    (function(j) {
        setTimeout(function() { console.log(j); }, j * 1000);
    })(i);
}

// FIX 2: let creates block scope per iteration
for (let i = 1; i <= 5; i++) {
    setTimeout(function() { console.log(i); }, i * 1000);
}
```

**Module Pattern** — the most important practical application of closure:

```javascript
function CoolModule() {
    var something = "cool";
    var another = [1, 2, 3];

    function doSomething() { console.log(something); }
    function doAnother() { console.log(another.join(" ! ")); }

    return {
        doSomething: doSomething,
        doAnother: doAnother
    };
}

var foo = CoolModule();
foo.doSomething(); // cool
```

Requirements for a module: (1) outer enclosing function invoked at least once, (2) returns at least one inner function that has closure over private scope.

---

## Book 3: this & Object Prototypes

The most misunderstood features of JavaScript.

### Chapter 1-2: `this` Binding Rules

`this` is NOT the function itself. `this` is NOT the function's lexical scope. `this` is a runtime binding determined by the **call-site** — how the function is called.

**4 Rules (in order of precedence):**

| Priority | Rule | Example | `this` =  |
|----------|------|---------|-----------|
| 4 (highest) | **`new` binding** | `var bar = new Foo()` | newly created object |
| 3 | **Explicit binding** | `foo.call(obj)` / `foo.apply(obj)` / `foo.bind(obj)` | `obj` |
| 2 | **Implicit binding** | `obj.foo()` | `obj` (owning object) |
| 1 (lowest) | **Default binding** | `foo()` (standalone call) | `global` (or `undefined` in strict mode) |

**Common pitfalls:**

```javascript
// Implicit binding LOST
var obj = {
    a: 2,
    foo: function() { console.log(this.a); }
};
var bar = obj.foo;  // function reference only!
bar();  // undefined — default binding, not implicit

// Fix with bind
var bar = obj.foo.bind(obj);
bar();  // 2
```

**Arrow functions** (ES6): Don't have their own `this`. They inherit `this` from the enclosing lexical scope.

```javascript
function foo() {
    return () => {
        console.log(this.a);  // `this` captured from foo's scope
    };
}
var obj = { a: 2 };
var bar = foo.call(obj);
bar(); // 2 — arrow function uses foo's `this`
```

### Chapter 3: Objects

- Objects can be created with literal syntax `{}` or constructed `new Object()`.
- 6 primary types: `string`, `number`, `boolean`, `null`, `undefined`, `object`
- Built-in object sub-types: `String`, `Number`, `Boolean`, `Object`, `Function`, `Array`, `Date`, `RegExp`, `Error`
- Property access: `obj.prop` (identifier) or `obj["prop"]` (expression)
- Property descriptors: `writable`, `enumerable`, `configurable`
- Immutability: `Object.preventExtensions()`, `Object.seal()`, `Object.freeze()`
- Getters and Setters: `get` and `set` keywords define computed properties

### Chapter 4-5: Prototypes & Behavior Delegation

Every object has an internal `[[Prototype]]` link. When a property is not found on the object, the engine follows the prototype chain.

```javascript
var anotherObject = { a: 2 };
var myObject = Object.create(anotherObject);
myObject.a; // 2 — found via prototype chain
```

**`__proto__` vs `.prototype`:**
- `__proto__` is the actual link on an instance to its prototype
- `.prototype` is a property on functions used when `new` creates objects

**Behavior Delegation (OLOO — Objects Linked to Other Objects):**

Kyle advocates OLOO over classical OOP patterns:

```javascript
// OLOO pattern (preferred by Kyle)
var Task = {
    setID: function(ID) { this.id = ID; },
    outputID: function() { console.log(this.id); }
};

var XYZ = Object.create(Task);
XYZ.prepareTask = function(ID, Label) {
    this.setID(ID);
    this.label = Label;
};

// vs traditional "class" pattern
function Task(ID) { this.id = ID; }
Task.prototype.outputID = function() { console.log(this.id); };
```

**Key insight:** JavaScript doesn't have "classes" — it has objects that delegate behavior to other objects through the prototype chain. `new`, `class`, `.prototype` are just syntax that obscures this delegation mechanism.

---

## Book 4: Types & Grammar

### Chapter 1-2: Types and Values

**Built-in types:** `undefined`, `null`, `boolean`, `number`, `string`, `object`, `symbol` (ES6)

```javascript
typeof undefined === "undefined"  // true
typeof true === "boolean"          // true
typeof 42 === "number"             // true
typeof "42" === "string"           // true
typeof { life: 42 } === "object"  // true
typeof null === "object"           // BUG! (historical, will never be fixed)
typeof function a(){} === "function" // true (sub-type of object)
typeof [1,2,3] === "object"       // true (arrays are objects)
```

**Special values:**
- `undefined` vs `void 0`: `void` operator always returns `undefined`
- `NaN`: "Not a Number" — but `typeof NaN === "number"`. Use `Number.isNaN()` (ES6), NOT `isNaN()` which coerces.
- `-0`: Exists for direction tracking. `0 === -0` is `true` but `Object.is(0, -0)` is `false`.
- `Infinity` / `-Infinity`: Result of division by zero or overflow.

**Value vs Reference:**
- Primitives are always copied by **value**
- Objects (including arrays, functions) are always passed by **reference**
- There is no way to hold a "reference to a reference" in JS

### Chapter 3: Natives (Built-in Constructors)

- `String()`, `Number()`, `Boolean()` — avoid using as constructors (`new`). Use for coercion only.
- `Array()`, `Object()`, `Function()`, `RegExp()` — prefer literal syntax.
- `Date()`, `Error()` — no literal form, must use constructor.
- Primitives are auto-boxed to their object wrappers when you access methods.

### Chapter 4: Coercion

**The most feared and misunderstood feature of JavaScript.**

Two types:
- **Explicit coercion:** Clearly converting between types
- **Implicit coercion:** Conversion happens as a side effect of an operation

**ToString rules:**
- `null` → `"null"`, `undefined` → `"undefined"`, `true` → `"true"`
- Numbers: standard string form. Very large/small use exponent.
- Objects: calls `toString()`, which calls `[[ToPrimitive]]`

**ToNumber rules:**
- `true` → `1`, `false` → `0`, `undefined` → `NaN`, `null` → `0`
- Strings: numeric parsing (`"" → 0`, `"42" → 42`, `"abc" → NaN`)
- Objects: `valueOf()` first, then `toString()`, then `ToPrimitive`

**ToBoolean — Falsy values (complete list):**
- `undefined`, `null`, `false`, `+0`, `-0`, `NaN`, `""` (empty string)
- **Everything else is truthy** (including `"0"`, `"false"`, `[]`, `{}`, `function(){}`)

**Explicit coercion examples:**

```javascript
String(42);          // "42"
(42).toString();     // "42"
Number("42");        // 42
+"42";               // 42 (unary + operator)
Boolean("0");        // true (non-empty string)
!![];                // true (object is truthy)
```

**Implicit coercion examples:**

```javascript
"42" + 0;   // "420" — string wins, number coerced to string
42 + "";    // "42"  — same rule
"42" - 0;   // 42   — minus always numeric
[1,2] + [3,4]; // "1,23,4" — arrays toString then concatenate
```

**`==` vs `===`:**
- `==` allows coercion; `===` does not
- They are NOT "loose equality" vs "strict equality" — they are "equality with coercion" vs "equality without coercion"
- Kyle's rule: if either side could be `true/false`, `0/""`, or `[]`, use `===`. Otherwise `==` is fine and more readable.

### Chapter 5: Grammar

- **Statement completion values:** Every statement has a completion value (used by `eval`).
- **Operator precedence:** `&&` binds tighter than `||`. Both are short-circuit operators.
- `&&` and `||` don't return `true/false` — they return one of the operand values.
- **ASI (Automatic Semicolon Insertion):** JS inserts semicolons automatically in some cases. Use semicolons explicitly to avoid surprises.
- **Error types:** Early errors (at compile time, e.g., duplicate params in strict mode) vs runtime errors.
- **TDZ (Temporal Dead Zone):** `let`/`const` exists from block start but is unusable until declaration.

```javascript
// && and || return operand values, not booleans
var a = 42;
var b = "abc";
var c = null;

a || b;   // 42 (first truthy)
a && b;   // "abc" (last truthy, or first falsy)
a || c;   // 42
c || b;   // "abc"
c && b;   // null (first falsy)
```

---

## Book 5: Async & Performance

### Chapter 1: Asynchrony — Now & Later

- JS is **single-threaded** with an **event loop**.
- The event loop: a queue of "events" (callback functions) processed one at a time.
- `setTimeout(fn, 0)` doesn't execute immediately — it adds to the queue for the next available tick.
- Concurrency: multiple "processes" interleaving (not parallel execution).
- Cooperation: break long-running processes into smaller chunks using `setTimeout` to avoid blocking.

### Chapter 2: Callbacks

Callbacks are the fundamental async pattern but suffer from:

1. **Inversion of Control:** You hand your callback to a third-party and *trust* they'll call it correctly (once, not too early/late, with proper args).
2. **Callback Hell (Pyramid of Doom):** Not just about indentation — it's about the sequential reasoning difficulty.

```javascript
// Callback hell — hard to reason about
listen("click", function handler(evt) {
    setTimeout(function request() {
        ajax("http://url", function response(text) {
            if (text === "hello") {
                handler();
            } else if (text === "world") {
                request();
            }
        });
    }, 500);
});
```

### Chapter 3: Promises

Promises solve the inversion of control problem. Instead of passing a callback to be called later, you receive a *promise* — a future value you can reason about.

**States:** `pending` → `fulfilled` (resolved) OR `rejected`. Once settled, immutable.

```javascript
// Creating a promise
var p = new Promise(function(resolve, reject) {
    // do async work...
    if (success) resolve(value);
    else reject(reason);
});

// Consuming a promise
p.then(
    function fulfilled(val) { /* success */ },
    function rejected(err) { /* failure */ }
);
```

**Promise chaining:**

```javascript
request("http://url1")
    .then(function(response1) {
        return request("http://url2");
    })
    .then(function(response2) {
        console.log(response2);
    })
    .catch(function(err) {
        console.error(err);
    });
```

**Key patterns:**
- `Promise.all([p1, p2])` — resolves when ALL resolve (gate)
- `Promise.race([p1, p2])` — resolves when FIRST resolves (latch)
- Always end chains with `.catch()`

**Promise Trust:**
- Called only once (resolve or reject)
- Always async (even if immediately resolved)
- Errors become rejections
- Values are passed through

### Chapter 4: Generators

Generators can **pause and resume** execution, enabling synchronous-looking async code.

```javascript
function *main() {
    var x = 1 + (yield "hello");  // pause here, yield "hello"
    console.log(x);
}

var it = main();
it.next();      // { value: "hello", done: false }
it.next(42);    // x = 1 + 42 = 43, logs 43, { value: undefined, done: true }
```

**Generators + Promises = async/await precursor:**

```javascript
function *main() {
    try {
        var text = yield request("http://url");
        console.log(text);
    } catch (err) {
        console.error(err);
    }
}

// A runner utility drives the generator
run(main);
```

This pattern directly inspired ES2017's `async/await` syntax.

### Chapter 5: Performance

- **Web Workers:** True parallel threading for CPU-intensive tasks. Communicate via message passing. No shared DOM access.
- **SIMD (Single Instruction Multiple Data):** Proposed for math-heavy operations.
- **asm.js:** Subset of JS for C/C++ transpilation with near-native performance.
- **Benchmark.js:** Use proper statistical benchmarking, not naive `Date.now()` timing.
- **Tail Call Optimization (TCO):** ES6 spec allows proper tail calls without stack growth. (Limited browser support.)

---

## Book 6: ES6 & Beyond

### Key ES6 Features

| Feature | Description |
|---------|-------------|
| **`let` / `const`** | Block scoping. `const` = immutable binding (not value). |
| **Arrow functions** | Lexical `this`, concise syntax. Don't use for methods or constructors. |
| **Default parameters** | `function foo(x = 10) {}` — evaluated at call time, not definition. |
| **Destructuring** | `var { a, b } = obj;` / `var [x, y] = arr;` — pattern matching for assignment. |
| **Template literals** | `` `Hello ${name}` `` — string interpolation with backticks. |
| **Spread / Rest** | `...arr` (spread into args/elements) / `function(...args)` (gather into array). |
| **Computed property names** | `{ [expr]: value }` — dynamic keys in object literals. |
| **`for..of`** | Iterates over iterables (arrays, strings, Maps, Sets). Not for plain objects. |
| **Symbols** | `Symbol("desc")` — unique, immutable identifiers. Used for meta-programming. |
| **Iterators** | Protocol: object with `next()` returning `{ value, done }`. |
| **Generators** | `function*` — pausable functions that produce iterators. |
| **Promises** | Native async primitive (see Book 5). |
| **Classes** | Syntactic sugar over prototypes. `class`, `extends`, `super`, `static`. |
| **Modules** | `import` / `export` — file-based, static, singleton modules. |
| **Maps / Sets** | `Map` (any-type keys), `Set` (unique values), `WeakMap`, `WeakSet`. |
| **Proxies** | `new Proxy(target, handler)` — intercept/customize fundamental operations. |
| **`Object.assign()`** | Shallow copy/merge objects. |
| **`Array.from()`** | Create array from iterable or array-like. |
| **`String` methods** | `.includes()`, `.startsWith()`, `.endsWith()`, `.repeat()`. |
| **`Number` methods** | `Number.isNaN()`, `Number.isFinite()`, `Number.isInteger()`. |

### Destructuring Deep Dive

```javascript
// Object destructuring with rename and defaults
var { a: X = 10, b: Y = 20 } = { a: 1 };
// X = 1, Y = 20

// Nested destructuring
var { a: { b: c } } = { a: { b: 42 } };
// c = 42

// Array destructuring with skip
var [, b, , d] = [1, 2, 3, 4];
// b = 2, d = 4

// Swap without temp variable
[x, y] = [y, x];

// Parameter destructuring
function foo({ x, y = 10 } = {}) {
    console.log(x, y);
}
```

### ES6 Classes

```javascript
class Widget {
    constructor(width, height) {
        this.width = width;
        this.height = height;
    }
    render() {
        // base render
    }
    static create(w, h) {
        return new Widget(w, h);
    }
}

class Button extends Widget {
    constructor(width, height, label) {
        super(width, height);
        this.label = label;
    }
    render() {
        super.render();
        // button-specific render
    }
}
```

**Kyle's caveat:** `class` is syntactic sugar. The underlying mechanism is still prototype delegation. Be aware of the mismatch between "class" mental model and JS's actual behavior.

### ES6 Modules

```javascript
// Named exports
export function foo() { }
export var bar = 42;

// Default export
export default function baz() { }

// Import
import baz from "module";          // default import
import { foo, bar } from "module"; // named imports
import * as mod from "module";     // namespace import
```

Modules are: file-based, static (resolved at compile time), singletons (cached after first import), strict mode by default.

### Beyond ES6 (ES2016+)

- `async/await` (ES2017) — syntactic sugar over generators + promises
- `Array.prototype.includes()` (ES2016)
- Exponentiation operator `**` (ES2016)
- `Object.entries()` / `Object.values()` (ES2017)
- Shared Memory and Atomics (ES2017)
- Rest/Spread for objects (ES2018)
- `Promise.finally()` (ES2018)
- Optional chaining `?.` and nullish coalescing `??` (ES2020)

---

## Key Themes Across All 6 Books

| Theme | Explanation |
|-------|-------------|
| **Don't avoid the hard parts** | Understanding the mechanics makes you a better developer |
| **Lexical scope is king** | Most of JS's behavior traces back to how scope works |
| **`this` is about call-site** | Not about where a function is defined, but how it's called |
| **JS has no classes** | It has objects with prototype delegation (OLOO) |
| **Coercion is not evil** | It's a feature — learn the rules instead of avoiding it with `===` everywhere |
| **Async is about managing flow** | Callbacks → Promises → Generators → async/await — each layer solves the previous pattern's problems |
| **ES6 is syntax, not new semantics** | Most ES6 features are cleaner syntax for existing mechanisms |

---

## Cross-References

| Topic in This Book | Related Notes | Section |
|--------------------|---------------|---------|
| Closures & Module Pattern | [Clean Code — Ch.10 Classes](../../../01-fundamentals/clean-code/clean-code.md#chapter-10-classes) | Encapsulation, SRP — modules achieve similar goals |
| Callback hell, Async patterns | [Clean Code — Ch.3 Functions](../../../01-fundamentals/clean-code/clean-code.md#chapter-3-functions) | Small functions, do one thing, no side effects |
| Code readability (coercion, naming) | [Clean Code — Ch.2 Meaningful Names](../../../01-fundamentals/clean-code/clean-code.md#chapter-2-meaningful-names) | Intention-revealing names, avoid mental mapping |

---

## References

- **2nd Edition:** "You Don't Know JS Yet" (YDKJSY) — Kyle Simpson (2020, in progress)
- **Related:** "JavaScript: The Good Parts" — Douglas Crockford
- **Related:** "Eloquent JavaScript" — Marijn Haverbeke
- **Related:** "JavaScript: The Definitive Guide" — David Flanagan
- **Spec:** [ECMAScript Language Specification](https://tc39.es/ecma262/)

## My Notes

- The scope/closures book alone is worth the entire series — it fundamentally changes how you think about JS
- The `this` binding rules table (4 rules in priority order) is the single most useful reference for debugging `this` issues
- Kyle's stance against `===` dogma is controversial but well-argued — understanding coercion rules is genuinely valuable
- The OLOO pattern is intellectually compelling but rarely used in practice due to ecosystem conventions (React classes, TS classes)
- The async progression (callbacks → promises → generators → async/await) is an excellent teaching sequence for any language's concurrency model
- The TDZ (Temporal Dead Zone) explanation for `let`/`const` is the clearest I've seen anywhere
