# Reading Plan: Research → sndq-fe Contribution

A strategic reading plan that maps research topics to their practical impact on the **sndq-fe** codebase (Next.js 15 / React 19 property management platform).

**Created**: 2026-03-14

---

## Priority Map: Research → sndq-fe Impact

### Tier 1 — Highest Impact (read first)

| Research File | Why it matters for sndq-fe |
|---|---|
| `04-frontend/react/react-rendering-behavior.md` | sndq-fe uses **React 19** + **TanStack Query** — understanding rendering behavior prevents unnecessary re-renders in complex modules like `financial/`, `patrimony/` |
| `04-frontend/react/learning-patterns.md` | Codebase uses many patterns: **compound components** (Briicks), **composition** (CommonSheet, CommonTable), **hooks** — mastering patterns = better contributions |
| `04-frontend/react/learning-react.md` | React foundation must be solid since the project uses React 19 with many advanced features |
| `03-languages/javascript/you-dont-know-js.md` | TypeScript builds on JS — deep understanding of closures, scope, async/await helps debug and write better hooks |

### Tier 2 — High Impact (read within first week)

| Research File | Why it matters for sndq-fe |
|---|---|
| `02-system-design/greatfrontend-fe-system-design.md` | Understanding FE system design enables **architecture-level contributions** — layered architecture (API → Services → Hooks → Components) |
| `02-system-design/greatfrontend-news-feed-facebook.md` | Relevant to **infinite scroll**, **real-time updates** — sndq-fe uses Socket.io + TanStack Query |
| `02-system-design/greatfrontend-pinterest.md` | Relevant to **image-heavy UI**, **virtualization** — sndq-fe uses `@tanstack/react-virtual` |
| `02-system-design/autocomplete-fe-system-design.md` | sndq-fe has search/autocomplete components — debounce, caching, UX patterns |
| `01-fundamentals/clean-code/clean-code.md` | Codebase follows strict coding standards (see AGENTS.md) — clean code gets PRs approved faster |

### Tier 3 — Medium Impact (read when needed)

| Research File | When to read |
|---|---|
| `01-fundamentals/refactoring/dive-into-refactoring.md` | When assigned refactoring tasks or improving existing modules |
| `02-system-design/bytebytego-system-design.md` | When needing to understand backend integration patterns (API design, caching) |
| `02-system-design/system-design-interview-vol1.md` | Background knowledge — not directly applicable but helps with the big picture |

### Tier 4 — Low Impact (skip or leisure)

| Research | Reason |
|---|---|
| `05-backend/` through `11-ai-ml/` | No content yet, and backend knowledge has less direct impact on FE contribution |
| `10-soft-skills/interviewing/*` | Not directly related to contribution |

---

## Reading Strategy

### Phase 1: Foundation Sprint (Day 1–5)

**Goal**: Master React + JS fundamentals for sndq-fe

```
Day 1-2: react-rendering-behavior.md
  → Then open sndq-fe/src/hooks/ and study how TanStack Query hooks work
  → Find patterns: useQuery, useMutation, stale time, cache invalidation

Day 3-4: learning-patterns.md
  → Then open sndq-fe/src/components/briicks/ and identify patterns in use
  → Compare with CommonSheet, CommonTable, CommonDrawer

Day 5: you-dont-know-js.md (focus: closures, async, scope)
  → Apply by reading sndq-fe/src/common/utils/ and services/
```

### Phase 2: Architecture Understanding (Day 6–10)

**Goal**: Understand FE system design to contribute at a higher level

```
Day 6-7: greatfrontend-fe-system-design.md
  → Map RADIO framework to sndq-fe architecture:
    Requirements → docs/sndq-kb/
    Architecture → API → Services → Hooks → Components
    Data Model → src/common/models/
    Interface → src/components/briicks/
    Optimizations → virtualization, caching

Day 8-9: autocomplete-fe-system-design.md + news-feed-facebook.md
  → Find in codebase how these are handled:
    - Debounced search
    - Infinite scroll
    - Real-time updates (Socket.io)

Day 10: clean-code.md
  → Read alongside AGENTS.md and .cursor/rules/ from sndq-fe
```

### Phase 3: Practice Loop (ongoing)

```
For each new task:
  1. Check if research/ has a relevant topic
  2. Read/review that section before coding
  3. Write notes in journal/ after completing the task
```

---

## Research ↔ sndq-fe Codebase Mapping

| Research Concept | Where to apply in sndq-fe |
|---|---|
| **Rendering optimization** | `src/hooks/` — TanStack Query options, `src/modules/` — heavy components |
| **Component patterns** | `src/components/briicks/` — design system, `src/components/common-*/` — composites |
| **State management** | `src/contexts/` — React Context, Zustand stores |
| **Data fetching** | `src/common/api/resources/` → `src/services/` → `src/hooks/` |
| **Form patterns** | React Hook Form + Zod — spread across modules |
| **i18n** | `messages/` folder — next-intl integration |
| **Real-time** | Socket.io integration — broadcasts module |
| **Virtualization** | `@tanstack/react-virtual` — large lists/tables |

---

## Playground Experiments

Continue the pattern from `playground/12-Mar-2026-sndq-toolbar-component/`:

| After reading about... | Create playground experiment for... |
|---|---|
| React rendering | Optimize a real component from sndq-fe |
| Design patterns | Rebuild a Briicks component using a new pattern |
| System design (autocomplete) | Prototype search component following the case study |
| Virtualization (Pinterest) | Test `@tanstack/react-virtual` with large datasets |

---

## Key Principles

1. **Read by impact, not by domain number** — React core first, then system design, then clean code
2. **Always connect back**: After each research section, open sndq-fe codebase and find where to apply
3. **Playground is your weapon**: Prototype before contributing — reduces risk, builds confidence
4. **Journal the loop**: Document what you learned and how it applied to real tasks
