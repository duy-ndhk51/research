# Dive Into Refactoring

> **Author:** Alexander Shvets (Refactoring.Guru)
> **Year:** 2019 | **Pages:** 336 | **Code Examples:** Java
> **Source PDF:** [../../sources/books/alexander-shvets-dive-into-refactoring-2019.pdf](../../sources/books/alexander-shvets-dive-into-refactoring-2019.pdf)

## TL;DR

A comprehensive guide to code refactoring organized into two parts: **Code Smells** (signs that refactoring is needed) and **Refactoring Techniques** (how to fix them). The book catalogs 22 code smells across 5 categories and 66 refactoring techniques across 6 categories. The core message: refactoring is a controllable process of improving code without creating new functionality — transforming messy code into clean code and simple design.

## Key Concepts

### What is Refactoring?

Refactoring is a controllable process of improving code **without creating new functionality**. It transforms a mess into clean code and simple design. Clean code is code that is easy to read, write, and maintain.

### Why Refactor?

- Lack of regular refactoring can lead to complete paralysis of a project
- It's necessary to get rid of code smells while they're still small
- Long methods, large classes, and duplicated code accumulate over time
- Each refactoring should be properly motivated and applied with caution

---

## Part 1: Code Smells (22 Smells in 5 Categories)

### Category 1: Bloaters

Code, methods, and classes that have grown to gargantuan proportions.

| Smell | Signs | Key Treatment |
|-------|-------|---------------|
| **Long Method** | Method > 10 lines; need to comment sections | Extract Method, Replace Temp with Query |
| **Large Class** | Too many fields/methods/lines | Extract Class, Extract Subclass, Extract Interface |
| **Primitive Obsession** | Using primitives instead of small objects; constants for coding info | Replace Data Value with Object, Replace Type Code with Class |
| **Long Parameter List** | More than 3-4 parameters | Introduce Parameter Object, Preserve Whole Object |
| **Data Clumps** | Identical groups of variables in multiple places | Extract Class, Introduce Parameter Object |

**Key insight:** Bloaters don't crop up right away — they accumulate over time as the program evolves, especially when nobody makes an effort to eradicate them.

### Category 2: Object-Orientation Abusers

Incomplete or incorrect application of OOP principles.

| Smell | Signs | Key Treatment |
|-------|-------|---------------|
| **Switch Statements** | Complex switch/if chains | Replace Conditional with Polymorphism |
| **Temporary Field** | Fields only used under certain circumstances | Extract Class, Introduce Null Object |
| **Refused Bequest** | Subclass uses only some inherited methods | Replace Inheritance with Delegation, Extract Superclass |
| **Alternative Classes with Different Interfaces** | Two classes do the same thing, different method names | Rename Methods, Extract Superclass |

**Key insight:** When you see `switch`, think polymorphism. Factory patterns are a valid exception.

### Category 3: Change Preventers

Changing something in one place requires many changes elsewhere.

| Smell | Signs | Key Treatment |
|-------|-------|---------------|
| **Divergent Change** | One class needs many unrelated changes | Extract Class |
| **Shotgun Surgery** | One change requires editing many classes | Move Method, Move Field, Inline Class |
| **Parallel Inheritance Hierarchies** | Creating a subclass forces creating another subclass | Move Method, Move Field |

**Key insight:** Divergent Change and Shotgun Surgery are opposites:
- **Divergent Change** = many changes to ONE class
- **Shotgun Surgery** = ONE change to many classes

### Category 4: Dispensables

Something pointless whose absence would make code cleaner.

| Smell | Signs | Key Treatment |
|-------|-------|---------------|
| **Comments** | Method filled with explanatory comments | Extract Method, Rename Method |
| **Duplicate Code** | Two fragments look almost identical | Extract Method, Pull Up Method, Extract Superclass |
| **Lazy Class** | Class doesn't do enough to justify its existence | Inline Class, Collapse Hierarchy |
| **Data Class** | Class with only fields + getters/setters | Encapsulate Field, Move Method |
| **Dead Code** | Unused variables, parameters, fields, methods, classes | Delete it |
| **Speculative Generality** | Unused code created "just in case" | Collapse Hierarchy, Inline Class, Remove Parameter |

**Key insight:** "The best comment is a good name for a method or class." Comments are like deodorant masking the smell of bad code.

### Category 5: Couplers

Excessive coupling between classes.

| Smell | Signs | Key Treatment |
|-------|-------|---------------|
| **Feature Envy** | Method uses another object's data more than its own | Move Method, Extract Method |
| **Inappropriate Intimacy** | Class uses internal fields/methods of another class | Move Method, Move Field, Hide Delegate |
| **Message Chains** | `a.b().c().d()` chain calls | Hide Delegate, Extract Method |
| **Middle Man** | Class only delegates to another class | Remove Middle Man |

**Key insight:** Feature Envy rule of thumb: "If things change at the same time, keep them in the same place."

---

## Part 2: Refactoring Techniques (66 Techniques in 6 Categories)

### 1. Composing Methods

Streamline methods, remove duplication, pave the way for improvements.

| Technique | Problem → Solution |
|-----------|-------------------|
| **Extract Method** | Code fragment can be grouped → Move to separate method |
| **Inline Method** | Method body is more obvious than the method → Replace calls with content |
| **Extract Variable** | Hard-to-understand expression → Place parts in self-explanatory variables |
| **Inline Temp** | Temp assigned result of simple expression → Replace with expression |
| **Replace Temp with Query** | Local variable stores expression result → Move to separate method |
| **Split Temporary Variable** | Variable used for multiple purposes → Use different variables |
| **Remove Assignments to Parameters** | Parameter modified inside method → Use local variable instead |
| **Replace Method with Method Object** | Long method with intertwined local variables → Transform to class |
| **Substitute Algorithm** | Want to replace algorithm → Replace method body |

**Most important:** Extract Method is the foundation of many other refactoring approaches.

### 2. Moving Features between Objects

Safely move functionality between classes.

| Technique | Problem → Solution |
|-----------|-------------------|
| **Move Method** | Method used more in another class → Move it there |
| **Move Field** | Field used more in another class → Move it there |
| **Extract Class** | One class doing work of two → Split into two classes |
| **Inline Class** | Class does almost nothing → Move features to another class |
| **Hide Delegate** | Client calls `a.b().method()` → Create delegating method in A |
| **Remove Middle Man** | Too many delegating methods → Force client to call directly |
| **Introduce Foreign Method** | Need method in utility class you can't modify → Add to client class |
| **Introduce Local Extension** | Need multiple methods in unmodifiable class → Create wrapper/subclass |

**Rule of thumb for Move Field:** Put a field in the same place as the methods that use it.

### 3. Organizing Data

Handle data better, replace primitives with rich class functionality.

| Technique | Problem → Solution |
|-----------|-------------------|
| **Self Encapsulate Field** | Direct access to private field → Create getter/setter |
| **Replace Data Value with Object** | Field has its own behavior → Create class for it |
| **Change Value to Reference** | Many identical instances → Convert to single reference object |
| **Change Reference to Value** | Small, infrequently changed reference → Turn into value object |
| **Replace Array with Object** | Array contains different types → Replace with object with named fields |
| **Duplicate Observed Data** | Domain data in GUI class → Separate into domain class |
| **Change Unidirectional to Bidirectional** | Need both-way access → Add reverse association |
| **Change Bidirectional to Unidirectional** | One class doesn't use the other → Remove unused association |
| **Replace Magic Number with Constant** | Number with meaning → Replace with named constant |
| **Encapsulate Field** | Public field → Make private, add getter/setter |
| **Encapsulate Collection** | Simple getter/setter for collection → Return read-only, add/remove methods |
| **Replace Type Code with Class** | Type code not affecting behavior → Create class |
| **Replace Type Code with Subclasses** | Type code affects behavior → Create subclasses |
| **Replace Type Code with State/Strategy** | Type code affects behavior but can't subclass → Use State/Strategy pattern |
| **Replace Subclass with Fields** | Subclasses differ only in constant-returning methods → Replace with fields |

### 4. Simplifying Conditional Expressions

Combat increasingly complicated conditional logic.

| Technique | Problem → Solution |
|-----------|-------------------|
| **Decompose Conditional** | Complex if/else/switch → Extract condition, then, else into methods |
| **Consolidate Conditional Expression** | Multiple conditions lead to same result → Combine into single expression |
| **Consolidate Duplicate Conditional Fragments** | Identical code in all branches → Move outside conditional |
| **Remove Control Flag** | Boolean variable as control flag → Use break/continue/return |
| **Replace Nested Conditional with Guard Clauses** | Deeply nested conditionals → Flat list with early returns |
| **Replace Conditional with Polymorphism** | Conditional varies by type → Create subclasses with shared method |
| **Introduce Null Object** | Many null checks → Return null object with default behavior |
| **Introduce Assertion** | Code assumes certain conditions → Add explicit assertion checks |

**Key pattern:** Guard Clauses turn the "arrow of doom" (deeply nested ifs) into a flat, readable list.

### 5. Simplifying Method Calls

Make method calls simpler and easier to understand.

| Technique | Problem → Solution |
|-----------|-------------------|
| **Rename Method** | Name doesn't explain what method does → Rename it |
| **Add Parameter** | Method needs more data → Add parameter |
| **Remove Parameter** | Parameter unused → Remove it |
| **Separate Query from Modifier** | Method returns value AND changes state → Split into two methods |
| **Parameterize Method** | Multiple similar methods with different values → Combine with parameter |
| **Replace Parameter with Explicit Methods** | Method split by parameter value → Extract into separate methods |
| **Preserve Whole Object** | Passing multiple values from same object → Pass the object |
| **Replace Parameter with Method Call** | Passing query result as parameter → Call query inside method |
| **Introduce Parameter Object** | Repeating group of parameters → Replace with object |
| **Remove Setting Method** | Field should be set only at creation → Remove setter |
| **Hide Method** | Method unused outside class → Make private/protected |
| **Replace Constructor with Factory Method** | Complex constructor → Create factory method |
| **Replace Error Code with Exception** | Returning error codes → Throw exceptions |
| **Replace Exception with Test** | Exception where simple test would work → Use conditional check |

**CQRS principle:** Separate Query from Modifier implements Command and Query Responsibility Segregation.

### 6. Dealing with Generalization

Move functionality along class inheritance hierarchy.

| Technique | Problem → Solution |
|-----------|-------------------|
| **Pull Up Field** | Same field in subclasses → Move to superclass |
| **Pull Up Method** | Similar methods in subclasses → Move to superclass |
| **Pull Up Constructor Body** | Similar constructors → Create superclass constructor |
| **Push Down Method** | Superclass behavior used by one subclass → Move to subclass |
| **Push Down Field** | Field used in only some subclasses → Move there |
| **Extract Subclass** | Class has features used only in certain cases → Create subclass |
| **Extract Superclass** | Two classes with common fields/methods → Create shared superclass |
| **Extract Interface** | Multiple clients use same part of class interface → Create interface |
| **Collapse Hierarchy** | Subclass ≈ superclass → Merge them |
| **Form Template Method** | Subclasses with similar algorithm steps → Template Method pattern |
| **Replace Inheritance with Delegation** | Subclass uses only some superclass methods → Use composition |
| **Replace Delegation with Inheritance** | Class delegates everything to another → Inherit instead |

**Key principle:** Favor composition over inheritance (Replace Inheritance with Delegation) when the subclass violates Liskov Substitution Principle.

---

## Trade-offs & When to Use

### When to Refactor
- Before adding new features (make existing code cleaner first)
- When you find code smells during code review
- When understanding existing code is difficult
- When duplicate code is discovered

### When NOT to Refactor
- Code works and never needs to change
- It would be faster to rewrite from scratch
- Close to a deadline (note: this creates technical debt)

### Performance Concerns
- More methods with short bodies = negligible performance impact
- Clean, readable code makes it EASIER to find real performance bottlenecks
- Don't optimize prematurely — refactor first, optimize later

---

## Cross-References

| Topic in This Book | Related Notes | Section |
|--------------------|---------------|---------|
| Code Smells (all categories) | [Clean Code — Ch.17 Smells & Heuristics](../clean-code/clean-code.md#chapter-17-smells-and-heuristics) | G1–G36 general heuristics, C1–C5 comments, F1–F4 functions |
| Bloaters (Long Method, Large Class) | [Clean Code — Ch.3 Functions](../clean-code/clean-code.md#chapter-3-functions) | Small functions, do one thing, argument limits |
| Dispensables (Comments smell) | [Clean Code — Ch.4 Comments](../clean-code/clean-code.md#chapter-4-comments) | Good vs bad comments, "comments are a failure" |
| Couplers (Feature Envy, Law of Demeter) | [Clean Code — Ch.6 Objects & Data Structures](../clean-code/clean-code.md#chapter-6-objects-and-data-structures) | Law of Demeter, Data/Object Anti-Symmetry |
| When to Refactor | [Clean Code — Ch.9 Unit Tests](../clean-code/clean-code.md#chapter-9-unit-tests) | TDD Red/Green/Refactor cycle, F.I.R.S.T. principles |
| Simplifying Conditionals (Null Object) | [Clean Code — Ch.7 Error Handling](../clean-code/clean-code.md#chapter-7-error-handling) | Don't return null, Special Case Pattern |

---

## References

- **Book:** "Refactoring: Improving the Design of Existing Code" — Martin Fowler
- **Book:** "Refactoring to Patterns" — Joshua Kerievsky
- **Related:** "Clean Code" — Robert C. Martin ([notes](../clean-code/clean-code.md))
- **Website:** [refactoring.guru](https://refactoring.guru)
- **Related topics:** Design Patterns (the book recommends learning patterns alongside refactoring)

## My Notes

- The relationship map between smells and techniques is extremely useful — each smell points to specific techniques
- The Divergent Change vs Shotgun Surgery distinction is a great mental model for understanding coupling
- "The best comment is a good name" is a strong guideline for writing self-documenting code
- The book's structure (smell → signs → reasons → treatment → payoff → when to ignore) is an excellent template for documenting any technical concept
