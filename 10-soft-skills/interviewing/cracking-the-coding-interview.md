# Cracking the Coding Interview — 189 Programming Questions & Solutions

> **Author**: Gayle Laakmann McDowell  
> **Year**: 2015 (6th Edition)  
> **Pages**: 708  
> **Publisher**: CareerCup, LLC  
> **Source PDF**: [gayle-laakmann-mcdowell-cracking-the-coding-interview-189-programming-questions-and-solutions-careercup-2015.pdf](../../sources/books/gayle-laakmann-mcdowell-cracking-the-coding-interview-189-programming-questions-and-solutions-careercup-2015.pdf)

---

## TL;DR

The definitive guide for software engineering interview preparation at top tech companies. Covers the full interview lifecycle — from resume writing through offer negotiation — with the core focus on **189 data structure and algorithm problems** with detailed solutions. The book teaches not just *what* to solve, but *how* to approach problems systematically. Key insight: interviews test **problem-solving process**, not memorization.

---

## Book Structure

| Section | Chapters | Focus |
|---------|----------|-------|
| I–VIII | Introductory | Interview process, company-specific guides, Big O, problem-solving methodology |
| IX | Ch 1–4 | **Data Structures**: Arrays, Linked Lists, Stacks/Queues, Trees/Graphs |
| IX | Ch 5–11 | **Concepts & Algorithms**: Bit Manipulation, Math, OOP, Recursion/DP, System Design, Sorting, Testing |
| IX | Ch 12–15 | **Knowledge Based**: C/C++, Java, Databases, Threads/Locks |
| IX | Ch 16–17 | **Additional Problems**: Moderate (26 problems) + Hard (26 problems) |
| X | Solutions | Complete solutions for all 189 problems |
| XI | Advanced Topics | AVL Trees, Red-Black Trees, Dijkstra's, MapReduce, Rabin-Karp |
| XII–XIII | Library & Hints | Code library + progressive hints for all problems |

---

## Key Concepts

### 1. The Interview Process

Interviewers evaluate five dimensions:

| Dimension | What They Look For |
|-----------|-------------------|
| **Analytical skills** | Problem decomposition, optimal solution design, tradeoff analysis |
| **Coding skills** | Clean code, error handling, good style |
| **CS fundamentals** | Data structures, algorithms, Big O |
| **Experience** | Technical decisions, interesting projects, initiative |
| **Culture fit / Communication** | Values alignment, clear articulation of thought process |

Key realities:
- **False negatives are acceptable** to companies — they'd rather miss good people than hire bad ones
- **Performance is relative** — you're compared against other candidates on the same question
- **No company-specific question lists** — interviewers choose their own questions
- Questions at Google, Amazon, Facebook, etc. are largely interchangeable

### 2. Behind the Scenes — Company Interview Processes

| Company | Format | Unique Aspect |
|---------|--------|---------------|
| **Microsoft** | 4-5 interviews; meet interviewers in their offices | Reaching the "as app" (hiring manager) = strong positive signal |
| **Amazon** | Phone screen + 4-5 on-site; whiteboard coding | **Bar Raiser** interviewer from different team with veto power |
| **Google** | Phone screen + 4-6 on-site; lunch is non-technical | **Hiring Committee** (not interviewers) makes the decision; needs "enthusiastic endorser" |
| **Apple** | Recruiter screen + 6-8 on-site; two-on-one common | Reaching director/VP interview = very good sign; passion for Apple products matters |
| **Facebook** | 1-2 phone screens + on-site with defined roles | **Jedi** (behavioral), **Ninja** (coding), **Pirate** (design); hired for company, not team; 6-week bootcamp |
| **Palantir** | Phone screens + HackerRank + 2-3 on-site | May cover system design more heavily |

### 3. Big O — Complexity Analysis

The foundation for analyzing algorithms. Industry uses Big O to mean the **tight bound** (closest to academic Theta).

#### Core Rules

| Rule | Example | Result |
|------|---------|--------|
| Drop constants | O(2N) | O(N) |
| Drop non-dominant terms | O(N² + N) | O(N²) |
| Add for sequential steps | do A then do B | O(A + B) |
| Multiply for nested steps | do B for each A | O(A × B) |
| Different inputs = different variables | two arrays a, b | O(ab), **not** O(N²) |

#### Important Runtimes

| Pattern | Runtime | Example |
|---------|---------|---------|
| Constant | O(1) | Hash table lookup |
| Logarithmic | O(log N) | Binary search; problem space halved each step |
| Linear | O(N) | Single pass through array |
| Linearithmic | O(N log N) | Merge sort, quick sort (average) |
| Quadratic | O(N²) | Nested loops over same input |
| Exponential | O(2^N) | Recursive function with 2 branches, depth N |
| Factorial | O(N!) | Generating all permutations |

#### Space Complexity
- Recursive calls consume O(depth) stack space
- Even O(2^N) total nodes in a recursion tree may only need O(N) space (only one branch active at a time)

#### Amortized Time
- ArrayList insertion: O(1) amortized — occasional O(N) resize, but sum of all copies ≈ 2N for N insertions

### 4. Problem-Solving Methodology — The 7-Step Flowchart

This is the core methodology the book advocates for every interview problem:

```
1. LISTEN → 2. EXAMPLE → 3. BRUTE FORCE → 4. OPTIMIZE → 5. WALK THROUGH → 6. IMPLEMENT → 7. TEST
```

#### Step 1: Listen Carefully
- Record **all** unique information — sorted? repeated? server-based?
- Information given is almost always relevant to the optimal solution

#### Step 2: Draw an Example
- Must be **specific** (use real numbers), **sufficiently large**, and **not a special case**
- Bad: tiny perfect binary tree. Good: 7-node unbalanced BST with real values

#### Step 3: State a Brute Force
- Always state it even if obvious — shows baseline understanding
- Explicitly state time and space complexity

#### Step 4: Optimize
Seven optimization strategies:
1. **Look for unused information** — did you use all the clues?
2. **Fresh example** — different data may reveal patterns
3. **Solve it "incorrectly"** — understand why it fails, then fix
4. **Time vs. space tradeoff** — hash tables are king here
5. **Precompute** — sort or build lookup structures upfront
6. **Hash table** — should be top of mind for nearly every problem
7. **Best Conceivable Runtime (BCR)** — can't do better than this, so stop optimizing past it

#### Step 5: Walk Through
- Solidify understanding of the algorithm before writing any code
- Know every variable and when it changes

#### Step 6: Implement — Write Beautiful Code
- **Modularize** from the beginning
- **Error checks** (at least as TODOs)
- **Good variable names** (abbreviate after first use)
- Use **classes/structs** where appropriate

#### Step 7: Test Systematically
1. Conceptual walkthrough (code review style)
2. Check weird-looking code (off-by-one, unusual indices)
3. Hot spots (base cases, null nodes, integer division)
4. Small test cases (3-4 elements, not the big example)
5. Edge cases (null, empty, single element, duplicates)

### 5. BUD Optimization Framework

The most powerful optimization technique:

| Letter | Stands For | Description |
|--------|-----------|-------------|
| **B** | Bottlenecks | The slowest part of your algorithm — optimize this first |
| **U** | Unnecessary Work | Computations that can be eliminated (e.g., break early, compute directly) |
| **D** | Duplicated Work | Same computation done multiple times — cache it (hash table, precomputation) |

**Example**: Finding pairs with difference k in an array
- Brute force: O(N²) — check all pairs
- After BUD: Repeated search is the bottleneck → use hash table → O(N)

### 6. Additional Optimization Techniques

#### DIY (Do It Yourself)
Solve the problem **intuitively by hand** on a real example, then reverse-engineer your approach into an algorithm. Your brain naturally optimizes — use that.

#### Simplify and Generalize
Simplify a constraint (e.g., characters instead of words), solve the simpler version, then adapt for the original.

#### Base Case and Build
Solve for n=1, then n=2, then n=3 — look for the pattern to build a recursive solution.

#### Data Structure Brainstorm
Systematically try different data structures — what would a hash table enable? A tree? A heap? A trie?

---

## Data Structures — Must-Know Topics

### Arrays and Strings (Chapter 1)

| Data Structure | Key Points |
|---------------|-----------|
| **Hash Table** | O(1) average lookup; array of linked lists + hash function; **most important DS for interviews** |
| **ArrayList** | Dynamic resizing array; O(1) amortized insert; doubles in size when full |
| **StringBuilder** | Avoids O(xn²) string concatenation; uses resizable array internally |

**9 Interview Questions**: Is Unique, Check Permutation, URLify, Palindrome Permutation, One Away, String Compression, Rotate Matrix, Zero Matrix, String Rotation

### Linked Lists (Chapter 2)

| Technique | Description |
|-----------|-------------|
| **Runner (Two Pointer)** | Fast pointer + slow pointer; finds midpoints, detects cycles |
| **Recursive approach** | Natural fit for many linked list problems; costs O(n) stack space |
| **Sentinel/dummy head** | Simplifies edge cases for insertion/deletion |

Key considerations: singly vs doubly linked, update head/tail pointers, null checks, memory management (C/C++)

**8 Interview Questions**: Remove Dups, Return Kth to Last, Delete Middle Node, Partition, Sum Lists, Palindrome, Intersection, Loop Detection

### Stacks and Queues (Chapter 3)

| Structure | Order | Operations | Use Cases |
|-----------|-------|-----------|-----------|
| **Stack** | LIFO | push, pop, peek | Parsing, backtracking, DFS, undo |
| **Queue** | FIFO | add, remove, peek | BFS, scheduling, buffering |

Both can be implemented with linked lists or arrays. Can implement a queue with two stacks.

**6 Interview Questions**: Three in One, Stack Min, Stack of Plates, Queue via Stacks, Sort Stack, Animal Shelter

### Trees and Graphs (Chapter 4)

#### Tree Types

| Type | Property |
|------|----------|
| **Binary Tree** | Each node has ≤ 2 children |
| **Binary Search Tree** | Left ≤ current < right for all nodes |
| **Balanced** | Height difference between subtrees ≤ 1 (AVL, Red-Black) |
| **Complete** | Every level fully filled except possibly last (filled left to right) |
| **Full** | Every node has 0 or 2 children |
| **Perfect** | Full + complete; exactly 2^(h+1) - 1 nodes |

#### Traversals

| Order | Pattern | Common Use |
|-------|---------|-----------|
| **In-order** | Left → Root → Right | BST gives sorted order |
| **Pre-order** | Root → Left → Right | Copying/serializing a tree |
| **Post-order** | Left → Right → Root | Deleting a tree |

#### Graph Representations
- **Adjacency List** (most common): array of lists; space-efficient for sparse graphs
- **Adjacency Matrix**: N×N boolean matrix; O(1) edge lookup but O(N²) space

#### Graph Search

| Algorithm | Data Structure | Use Case |
|-----------|---------------|----------|
| **DFS** | Stack / recursion | Visiting all nodes, topological sort, path finding |
| **BFS** | Queue | Shortest path (unweighted), level-order traversal |
| **Bidirectional** | Two BFS from each end | Shortest path — O(k^(d/2)) vs O(k^d) |

**12 Interview Questions**: Route Between Nodes, Minimal Tree, List of Depths, Check Balanced, Validate BST, Successor, Build Order, First Common Ancestor, BST Sequences, Check Subtree, Random Node, Paths with Sum

---

## Concepts & Algorithms

### Bit Manipulation (Chapter 5)

Essential operations:

| Operation | Code | Purpose |
|-----------|------|---------|
| Get bit i | `(num & (1 << i)) != 0` | Check if bit i is set |
| Set bit i | `num \| (1 << i)` | Set bit i to 1 |
| Clear bit i | `num & ~(1 << i)` | Set bit i to 0 |
| Update bit i | `(num & ~(1 << i)) \| (v << i)` | Set bit i to value v |

Key concepts: two's complement, arithmetic vs logical right shift, XOR tricks

**8 Interview Questions**: Insertion, Binary to String, Flip Bit to Win, Next Number, Debugger, Conversion, Pairwise Swap, Draw Line

### Math and Logic Puzzles (Chapter 6)

- **Primes**: Sieve of Eratosthenes; primality check up to √n
- **Probability**: P(A and B) = P(B|A) × P(A); Bayes' Theorem; independence; mutual exclusivity
- **Approach**: Start talking, develop rules/patterns, worst-case shifting

### Object-Oriented Design (Chapter 7)

**Approach**: Handle ambiguity → Define core objects → Analyze relationships → Investigate actions

Design questions test: class hierarchy design, encapsulation, use of design patterns (Singleton, Factory, Observer, etc.)

### Recursion and Dynamic Programming (Chapter 8)

Three approaches:

| Approach | Description | Space |
|----------|-------------|-------|
| **Pure Recursion** | Direct recursive calls; often exponential time | O(depth) stack |
| **Top-Down (Memoization)** | Recursion + cache results in hash map or array | O(N) cache + O(depth) stack |
| **Bottom-Up DP** | Iterative, build from base cases | O(N) table, sometimes O(1) |

**Space optimization**: Often only need the last few values (e.g., Fibonacci only needs `a` and `b`, not the full memo array)

**14 Interview Questions**: Triple Step, Robot in a Grid, Magic Index, Power Set, Recursive Multiply, Towers of Hanoi, Permutations without/with Dups, Parens, Paint Fill, Coins, Eight Queens, Stack of Boxes, Boolean Evaluation

### System Design and Scalability (Chapter 9)

#### 5-Step Design Process

| Step | Action |
|------|--------|
| **1. Scope** | Clarify requirements, features, constraints — ask questions |
| **2. Assumptions** | State explicitly; estimate data volumes, user counts |
| **3. Major Components** | Draw high-level architecture on whiteboard |
| **4. Key Issues** | Identify bottlenecks, single points of failure |
| **5. Redesign** | Address key issues with specific solutions |

#### Key Concepts

| Concept | Description |
|---------|-------------|
| **Horizontal Scaling** | Add more machines (preferred for web scale) |
| **Vertical Scaling** | Add resources to existing machine (limited) |
| **Load Balancer** | Distribute traffic across server pool |
| **Database Sharding** | Partition data across machines (by key, by feature, directory-based) |
| **Denormalization / NoSQL** | Avoid joins; add redundant data for read performance |
| **Caching** | In-memory key-value store between app and database |
| **Async Processing** | Queues for slow operations; eventual consistency |
| **MapReduce** | Map (emit key-value) → Reduce (aggregate); parallel processing at scale |

#### Networking Metrics
- **Bandwidth**: Max data transfer rate
- **Throughput**: Actual data transfer rate
- **Latency**: Delay from sender to receiver

**8 Interview Questions**: Stock Data, Social Network, Web Crawler, Duplicate URLs, Cache, Sales Rank, Personal Financial Manager, Pastebin

### Sorting and Searching (Chapter 10)

| Algorithm | Time (Average) | Time (Worst) | Space | Stable |
|-----------|---------------|--------------|-------|--------|
| Bubble Sort | O(N²) | O(N²) | O(1) | Yes |
| Selection Sort | O(N²) | O(N²) | O(1) | No |
| Merge Sort | O(N log N) | O(N log N) | O(N) | Yes |
| Quick Sort | O(N log N) | O(N²) | O(log N) | No |
| Radix Sort | O(kN) | O(kN) | O(N + k) | Yes |

**11 Interview Questions**: Sorted Merge, Group Anagrams, Search in Rotated Array, Sorted Search No Size, Sparse Search, Sort Big File, Missing Int, Find Duplicates, Sorted Matrix Search, Rank from Stream, Peaks and Valleys

### Testing (Chapter 11)

Four categories of testing questions:
1. **Real-world object** (e.g., test a pen)
2. **Software** (e.g., test a web browser)
3. **Function** (e.g., test a sorting method)
4. **Troubleshooting** (e.g., app crashes randomly)

---

## Knowledge-Based Topics

### C and C++ (Chapter 12)
- Classes, inheritance, virtual functions, pure virtual (abstract)
- Constructors, destructors, virtual destructors
- Pointers vs references, pointer arithmetic
- Templates, operator overloading
- Default values, memory management (new/delete)

### Java (Chapter 13)
- Overloading vs overriding
- Collection Framework: ArrayList, Vector, LinkedList, HashMap
- Generics vs C++ templates
- Abstract classes vs interfaces
- `final`, `finally`, `finalize`

### Databases (Chapter 14)
- SQL syntax: JOIN types, GROUP BY, aggregation
- Normalized vs denormalized design
- Small vs large database design considerations

### Threads and Locks (Chapter 15)
- Thread creation (extending Thread vs implementing Runnable)
- `synchronized` keyword, locks, semaphores
- Deadlock conditions and prevention strategies
- Common concurrency patterns

---

## Advanced Topics (Chapter XI)

| Topic | Key Insight |
|-------|-------------|
| **Topological Sort** | Linear ordering of DAG nodes; used in build systems, task scheduling |
| **Dijkstra's Algorithm** | Shortest path in weighted graph (no negative edges); uses priority queue |
| **AVL Trees** | Self-balancing BST; heights of subtrees differ by ≤ 1; O(log N) operations |
| **Red-Black Trees** | Self-balancing BST; less strict balance than AVL; used in Java TreeMap |
| **Hash Table Collision Resolution** | Chaining (linked lists) vs open addressing (linear/quadratic probing) |
| **Rabin-Karp** | String matching using rolling hash; O(N+M) average |
| **MapReduce** | Parallel processing: Map emits (key, value) pairs → Reduce aggregates by key |

#### Powers of 2 Table (Useful for Estimation)

| Power | Value | Approx | Size |
|-------|-------|--------|------|
| 2^10 | 1,024 | 1 thousand | 1 KB |
| 2^20 | 1,048,576 | 1 million | 1 MB |
| 2^30 | ~1 billion | 1 billion | 1 GB |
| 2^32 | ~4.3 billion | | 4 GB |
| 2^40 | ~1.1 trillion | 1 trillion | 1 TB |

---

## Behavioral Interview Preparation

### Interview Preparation Grid

Map each past project to common behavioral themes:

| | Project 1 | Project 2 | Project 3 |
|--|-----------|-----------|-----------|
| **Challenges** | | | |
| **Mistakes/Failures** | | | |
| **What I Enjoyed** | | | |
| **Leadership** | | | |
| **Conflicts** | | | |
| **What I'd Do Differently** | | | |

### Response Structure: S.A.R.

| Component | Description |
|-----------|-------------|
| **Situation** | Brief context — what was happening |
| **Action** | What **you** specifically did (not the team) |
| **Result** | Quantified outcome; what you achieved or learned |

### "Tell Me About Yourself" Structure
1. **Current role** (brief headline)
2. **College** (if relevant / recent)
3. **Post-college career** (chronological progression)
4. **Current role details** (what excites you)
5. **Outside of work** (relevant hobbies/projects — brief)
6. **Why here** (wrap up with interest in this role)

---

## Resume Best Practices

- **One page** for < 10 years experience; 1.5–2 pages for more senior
- **Focus on accomplishments, not responsibilities** — use metrics
- Recruiters spend ~10 seconds scanning — make key items prominent
- **For each role/project**: "Accomplished X, as measured by Y, by doing Z"
- Highlight **languages and technologies** relevant to target role
- Include **2-3 projects** with impressive, quantified results

---

## Offer & Negotiation

### Evaluating an Offer
- **Total compensation**: salary + signing bonus + annual bonus + equity (amortize over 3 years)
- **Cost of living**: Silicon Valley is 30%+ more expensive than Seattle
- **Career development**: learning, promotion path, company name on resume
- **Happiness factors**: product, manager/teammates, culture, hours

### Negotiation Tips
1. **Always negotiate** — recruiters won't revoke offers for negotiating
2. **Have alternatives** — competing offers are the strongest leverage
3. **Be specific** — ask for a concrete number, not just "more"
4. **Overshoot** — they'll meet you in the middle
5. **Think beyond salary** — equity, signing bonus, relocation
6. **Use your best medium** — phone is ideal, email is acceptable

### On the Job
- Set a career timeline before starting — check in annually
- Build strong relationships with teammates and managers
- Interview at least once a year to stay sharp and informed
- Ask for what you want — be your own advocate

---

## All 189 Interview Questions — Quick Reference

### Data Structures (Ch 1–4)

| # | Chapter | Question |
|---|---------|----------|
| 1.1 | Arrays | Is Unique |
| 1.2 | Arrays | Check Permutation |
| 1.3 | Arrays | URLify |
| 1.4 | Arrays | Palindrome Permutation |
| 1.5 | Arrays | One Away |
| 1.6 | Arrays | String Compression |
| 1.7 | Arrays | Rotate Matrix |
| 1.8 | Arrays | Zero Matrix |
| 1.9 | Arrays | String Rotation |
| 2.1 | Linked Lists | Remove Dups |
| 2.2 | Linked Lists | Return Kth to Last |
| 2.3 | Linked Lists | Delete Middle Node |
| 2.4 | Linked Lists | Partition |
| 2.5 | Linked Lists | Sum Lists |
| 2.6 | Linked Lists | Palindrome |
| 2.7 | Linked Lists | Intersection |
| 2.8 | Linked Lists | Loop Detection |
| 3.1 | Stacks/Queues | Three in One |
| 3.2 | Stacks/Queues | Stack Min |
| 3.3 | Stacks/Queues | Stack of Plates |
| 3.4 | Stacks/Queues | Queue via Stacks |
| 3.5 | Stacks/Queues | Sort Stack |
| 3.6 | Stacks/Queues | Animal Shelter |
| 4.1 | Trees/Graphs | Route Between Nodes |
| 4.2 | Trees/Graphs | Minimal Tree |
| 4.3 | Trees/Graphs | List of Depths |
| 4.4 | Trees/Graphs | Check Balanced |
| 4.5 | Trees/Graphs | Validate BST |
| 4.6 | Trees/Graphs | Successor |
| 4.7 | Trees/Graphs | Build Order |
| 4.8 | Trees/Graphs | First Common Ancestor |
| 4.9 | Trees/Graphs | BST Sequences |
| 4.10 | Trees/Graphs | Check Subtree |
| 4.11 | Trees/Graphs | Random Node |
| 4.12 | Trees/Graphs | Paths with Sum |

### Concepts & Algorithms (Ch 5–11)

| # | Chapter | Question |
|---|---------|----------|
| 5.1 | Bit Manipulation | Insertion |
| 5.2 | Bit Manipulation | Binary to String |
| 5.3 | Bit Manipulation | Flip Bit to Win |
| 5.4 | Bit Manipulation | Next Number |
| 5.5 | Bit Manipulation | Debugger |
| 5.6 | Bit Manipulation | Conversion |
| 5.7 | Bit Manipulation | Pairwise Swap |
| 5.8 | Bit Manipulation | Draw Line |
| 6.1–6.10 | Math/Logic | 10 puzzles (e.g., Heavy Pill, Basketball, Dominos, Poison) |
| 7.1–7.12 | OO Design | Deck of Cards, Call Center, Jukebox, Parking Lot, Chat Server, etc. |
| 8.1 | Recursion/DP | Triple Step |
| 8.2 | Recursion/DP | Robot in a Grid |
| 8.3 | Recursion/DP | Magic Index |
| 8.4 | Recursion/DP | Power Set |
| 8.5 | Recursion/DP | Recursive Multiply |
| 8.6 | Recursion/DP | Towers of Hanoi |
| 8.7 | Recursion/DP | Permutations without Dups |
| 8.8 | Recursion/DP | Permutations with Dups |
| 8.9 | Recursion/DP | Parens |
| 8.10 | Recursion/DP | Paint Fill |
| 8.11 | Recursion/DP | Coins |
| 8.12 | Recursion/DP | Eight Queens |
| 8.13 | Recursion/DP | Stack of Boxes |
| 8.14 | Recursion/DP | Boolean Evaluation |
| 9.1–9.8 | System Design | Stock Data, Social Network, Web Crawler, Duplicate URLs, Cache, Sales Rank, etc. |
| 10.1–10.11 | Sorting/Searching | Sorted Merge, Group Anagrams, Rotated Array, Sparse Search, etc. |
| 11.1–11.6 | Testing | Mistake, Random Crashes, Chess Test, No Test Tools, Test a Pen, Test ATM |

### Knowledge Based (Ch 12–15)

| # | Chapter | Question |
|---|---------|----------|
| 12.1–12.11 | C/C++ | Last K Lines, Reverse String, Hash Table vs STL Map, Virtual Functions, Smart Pointer, Malloc, 2D Alloc, etc. |
| 13.1–13.8 | Java | Private Constructor, Return from Finally, Generics vs Templates, TreeMap/HashMap/LinkedHashMap, Lambda Expressions, etc. |
| 14.1–14.7 | Databases | Multiple Apartments, Open Requests, Close All Requests, Joins, Denormalization, Entity Relationship, Design Grade Database |
| 15.1–15.7 | Threads/Locks | Thread vs Process, Context Switch, Dining Philosophers, Deadlock-Free Class, Call In Order, Synchronized Methods, FizzBuzz |

### Additional Review Problems (Ch 16–17)

| # | Chapter | Question |
|---|---------|----------|
| 16.1–16.26 | Moderate | Number Swapper, Word Frequencies, Intersection, Tic Tac Win, Factorial Zeros, Smallest Difference, English Int, Operations, Living People, Diving Board, XML Encoding, Bisect Squares, Best Line, Master Mind, Sub Sort, Contiguous Sequence, Pattern Matching, Pond Sizes, T9, Ant on Grid, Sum Swap, Langton's Ant, Rand7 from Rand5, Pairs with Sum, LRU Cache, Calculator |
| 17.1–17.26 | Hard | Add Without Plus, Shuffle, Random Set, Count of 2s, Letters and Numbers, Count of 2s, Baby Names, Circus Tower, Kth Multiple, Majority Element, Word Distance, BiNode, Re-Space, Smallest K, Longest Word, The Masseuse, Multi Search, Shortest Supersequence, Missing Two, Continuous Median, Volume of Histogram, Word Transformer, Max Square Matrix, Max Submatrix, Word Rectangle, Sparse Similarity |

---

## Common Pitfalls to Avoid

| Pitfall | Why It Hurts | Fix |
|---------|-------------|-----|
| Jumping straight to code | Miss edge cases, write suboptimal solution | Follow the 7-step flowchart |
| Not talking through your thinking | Interviewer can't evaluate your process | Verbalize every decision |
| Using N for multiple variables | O(a²) ≠ O(ab); ambiguity causes errors | Use distinct, descriptive variable names |
| Ignoring brute force | Miss the starting point for optimization | Always state brute force first |
| Memorizing solutions | Breaks down on variations; interviewer knows | Understand patterns, not specific answers |
| Not testing code | Submitting buggy code | Systematic testing: small cases → edge cases |
| Forgetting space complexity | Only analyzing time | Always state both time AND space |
| Over-engineering in interview | Running out of time | Start simple, optimize as needed |
| Not asking clarifying questions | Solving the wrong problem | Clarify before coding |

---

## Cross-References

| Topic in This Book | Related Notes | Connection |
|--------------------|---------------|------------|
| Landing interviews, resume, recruiter process | [How to Land Big Tech Jobs](./how-to-land-big-tech-jobs.md) | Complements CTCI's "Before the Interview" sections |
| Writing clean interview code | [Clean Code](../../01-fundamentals/clean-code/clean-code.md) | "What Good Coding Looks Like" in Ch VII |
| Refactoring & code smells | [Dive Into Refactoring](../../01-fundamentals/refactoring/dive-into-refactoring.md) | OO Design questions in Ch 7 |

---

## References

- [Source PDF](../../sources/books/gayle-laakmann-mcdowell-cracking-the-coding-interview-189-programming-questions-and-solutions-careercup-2015.pdf)
- [CrackingTheCodingInterview.com](https://www.crackingthecodinginterview.com) — Solutions in other languages, errata, discussion
- [CareerCup.com](https://www.careercup.com) — Interview question database and discussion
- [LeetCode](https://leetcode.com) — Practice platform for algorithm problems
- [levels.fyi](https://levels.fyi) — Compensation data for offer evaluation
