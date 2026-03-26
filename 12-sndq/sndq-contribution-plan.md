# SNDQ Contribution Plan — 4 Pillars

A structured plan for growing impact within the SNDQ project across frontend optimization, dashboard design, UI system standardization, and backend ownership.

**Created**: 2026-03-27

---

## Overview

| # | Pillar | Current State | Impact |
|---|--------|---------------|--------|
| 1 | **Frontend Size Optimization** | 139 direct deps, no bundle analyzer, no `optimizePackageImports`, Sentry source maps increase build time | Very High — improves DX for entire team |
| 2 | **Dashboard Concept Learning** | `recharts`, `zustand`, TanStack Table/Virtual, AI SDK already in stack | Medium-High — enables feature proposals |
| 3 | **UI System Standardization** | Design system split across 3 sources, token drift, Storybook only covers `@sndq/ui` | Very High — addresses clear pain point |
| 4 | **Backend Feature Ownership** | 88 modules, 235 entities, 413 migrations, NestJS + TypeORM + BullMQ | High — full-stack ownership unlocks career growth |

### Priority Order

Run **Pillar 1 + 4 in parallel** first:

- **Pillar 1** — Quick wins, visible impact, builds trust with the team
- **Pillar 4** — Needs accumulation time, start early to benefit later
- **Pillar 3** — Requires PM buy-in and team consensus, begin with audit
- **Pillar 2** — Benefits from understanding both FE + BE, schedule after others

### Weekly Time Allocation

- 40% → Pillar 1 or 3 (visible deliverables)
- 40% → Pillar 4 (backend learning)
- 20% → Pillar 2 (research, gradual)

---

## Pillar 1: Frontend Size Optimization

### Codebase Snapshot

| Metric | Value |
|--------|-------|
| Framework | Next.js `15.5.9`, React `19.2.0` |
| TypeScript | `^5`, strict mode, `moduleResolution: "bundler"` |
| Styling | Tailwind CSS v4, PostCSS |
| Direct dependencies | 139 (115 prod + 24 dev) |
| Bundle analyzer | None installed |
| Dev server | `next dev --turbopack` |
| Prod build | `next build` (no turbopack) |
| `optimizePackageImports` | Not configured |
| Sentry | `widenClientFileUpload: true` (increases build time) |
| ESLint during build | Skipped (`ignoreDuringBuilds: true`) |

### Phase 1.1 — Audit & Measure (Week 1–2)

**Goal**: Establish baseline metrics before any optimization.

#### Actions

1. **Install `@next/bundle-analyzer`**
   - Currently no bundle analysis tooling exists in the project
   - Add `ANALYZE=true` script to `package.json`
   - Generate treemap report for client and server bundles

2. **Run `ANALYZE=true next build`** to create treemap report

3. **Record baseline metrics:**
   - Total build time
   - Total bundle size (first load JS per route)
   - Largest chunks and top dependencies by size
   - Route-level JS breakdown

4. **TypeScript compile diagnostics:**
   - Run `tsc --diagnostics` to measure compile time
   - Identify slow type resolutions or deeply nested generics

5. **Identify quick wins from config:**

```typescript
// next.config.ts — add optimizePackageImports
experimental: {
  optimizePackageImports: [
    'recharts',
    '@radix-ui/react-icons',
    'lucide-react',
    '@tiptap/core',
    '@tiptap/react',
    'dnd-kit',
    'motion',
  ],
}
```

#### Deliverable
- Bundle analysis report with screenshots
- Build time baseline document
- List of optimization candidates ranked by impact

### Phase 1.2 — Dependency Cleanup (Week 2–3)

**Goal**: Reduce bundle size by removing/replacing heavy or redundant dependencies.

#### Actions

1. **Audit all 139 dependencies** — identify:
   - Duplicate functionality (e.g., `clsx` + `tailwind-merge` overlap)
   - Heavy deps with low usage (TipTap editor set, AI SDK, Firebase)
   - Deprecated or unmaintained packages
   - Packages that can be replaced with lighter alternatives

2. **Dynamic imports for heavy modules:**

| Module | Strategy | Why |
|--------|----------|-----|
| `react-pdf` | `next/dynamic` with SSR disabled | Only loaded when user views a PDF |
| `@tiptap/*` | Lazy load rich text editor | Large bundle, not on every page |
| `recharts` | Lazy load chart components | Only needed in dashboard views |
| `@stripe/stripe-js` | Lazy load on payment pages | Not needed until checkout |
| `firebase` | Dynamic import on auth pages | Heavy SDK |

3. **Fix version skew:** `eslint-config-next` at `15.5.4` vs `next` at `15.5.9`

4. **Check for tree-shaking issues:**
   - Barrel file imports (`index.ts` re-exports) that prevent tree-shaking
   - Named imports vs namespace imports for large libraries

#### Deliverable
- Dependency audit spreadsheet (name, size, usage, recommendation)
- PR with dynamic import conversions
- Before/after bundle comparison

### Phase 1.3 — Build Pipeline Optimization (Week 3–4)

**Goal**: Reduce build time and improve CI/CD performance.

#### Actions

1. **Sentry config review:**
   - `widenClientFileUpload: true` scans more files for source maps → slower builds
   - Evaluate if it can be restricted or moved to a post-build step
   - Consider using `hideSourceMaps: true` for production

2. **Code splitting strategy:**
   - Analyze route-level splitting for large modules (`financial/`, `accounts/`, `patrimony/`)
   - Use `next/dynamic` for module-level code splitting
   - Evaluate parallel routes or intercepting routes for heavy pages

3. **Image optimization:**
   - Migrate from deprecated `images.domains` to `images.remotePatterns` (Next.js 15 recommendation)
   - Audit unoptimized images and placeholder strategies

4. **Evaluate Turbopack for production:**
   - Next.js 15.5 has improved turbopack stability
   - Benchmark `next build --turbopack` vs standard build
   - Document any incompatibilities

5. **CI build caching:**
   - Ensure `node_modules/.cache` and `.next/cache` are cached between builds
   - Consider pnpm store caching for faster installs

#### Deliverable
- Build pipeline optimization PR
- Before/after build time comparison (with CI logs)
- Documentation for build performance monitoring setup

---

## Pillar 2: Dashboard Concept Learning

### Existing Stack for Dashboards

| Tool | Role in SNDQ |
|------|-------------|
| `recharts` | Charting library |
| `zustand` | Client state management |
| TanStack Table | Data tables with sorting, filtering, pagination |
| TanStack Virtual | Virtual scrolling for large lists |
| TanStack Query | Server state management, caching |
| Socket.io | Real-time updates |
| Dexie | Offline data with IndexedDB |
| AI SDK (`ai`, `@ai-sdk/react`) | AI-powered features |

### Phase 2.1 — Study Existing Dashboard Patterns (Week 1–2)

**Goal**: Map all dashboard-related code and understand data flow.

#### Actions

1. **Map dashboard components in codebase:**
   - `src/modules/financial/` — financial dashboard, auto-matching metrics
   - `src/modules/accounts/` — account overview, payment reconciliation
   - `src/hooks/` — data fetching patterns (TanStack Query)
   - `recharts` usage across all modules

2. **Trace the data flow pipeline:**

```
API Resource (src/common/api/resources/)
  → Service Layer (src/services/)
    → React Query Hook (src/hooks/)
      → Component (src/modules/**/components/)
```

3. **Study real-time update patterns:**
   - Socket.io client integration
   - TanStack Query invalidation strategies
   - Optimistic updates

4. **Analyze existing metric components:**
   - `AutoReconcileMetricCell` pattern
   - How KPIs are calculated and displayed
   - Refresh and polling strategies

### Phase 2.2 — Research Best Practices (Week 2–4)

**Goal**: Build knowledge of dashboard design principles.

#### Key Concepts to Master

| Concept | Why It Matters | Application to SNDQ |
|---------|---------------|---------------------|
| Dashboard Information Architecture | Hierarchy of information, progressive disclosure | Financial overview → drill-down to details |
| Data Visualization Selection | Choosing the right chart type for the data | Revenue trends (line), distributions (bar), compositions (pie) |
| Real-time Data Patterns | WebSocket + polling + stale-while-revalidate | Socket.io integration already exists |
| Responsive Dashboard Layout | Grid systems, responsive breakpoints, collapsible panels | Tailwind v4 responsive utilities |
| Dashboard Performance | Virtual scrolling, lazy loading, memoization | TanStack Virtual already in stack |
| KPI Design | Metric cards, sparklines, trend indicators, thresholds | Extend `AutoReconcileMetricCell` pattern |
| Filter & Drill-down | Cross-filtering, date range pickers, dimension selectors | Existing filter components in Briicks |

#### Reading List

| Resource | Focus Area |
|----------|-----------|
| "The Big Book of Dashboards" — Steve Wexler | Dashboard layout patterns, chart selection |
| "Storytelling with Data" — Cole Nussbaumer Knaflic | Data visualization principles |
| Recharts documentation | Library-specific patterns, custom components |
| TanStack Table docs | Server-side pagination, column customization |
| D3.js fundamentals (conceptual) | Understanding data-driven visualization |

### Phase 2.3 — Feature Proposals (Week 4–6)

**Goal**: Propose dashboard features aligned with SNDQ's domain (Belgian property management).

#### Proposed Dashboard Features

1. **Property Portfolio Dashboard**
   - Overview of all buildings: occupancy rate, revenue trends, maintenance costs
   - Map view with property pins (hot zones)
   - Drill-down: building → unit → tenant → lease details

2. **Financial Health Dashboard**
   - Cash flow waterfall chart (income vs expenses over time)
   - Outstanding payments heatmap (aging buckets: 30/60/90 days)
   - Auto-matching success rate and session history (builds on current `AutoMatchHistory` component)
   - Budget vs actuals comparison

3. **Tenant Screening Analytics**
   - Application funnel: received → reviewed → approved → signed
   - Conversion rates per listing
   - Average time-to-lease
   - Source tracking (where applications come from)

4. **Maintenance & Facility Dashboard**
   - Work order status pipeline (open → in-progress → resolved)
   - Cost per building/unit trending
   - Supplier performance (response time, cost, rating)
   - Seasonal maintenance forecasting

#### Deliverable
- Research document with wireframes (Mermaid diagrams)
- Feature proposal document for PM review
- Prototype implementation in `sndq-prototype/lab/`

---

## Pillar 3: UI System Design Standardization

### Current State Analysis

The design system is currently **split across three sources**, creating confusion about the "source of truth":

| Source | Location | Scale | Role |
|--------|----------|-------|------|
| `@sndq/ui` | `packages/ui/` (git submodule) | ~20+ component groups, icons | Cross-app primitive layer |
| Briicks | `src/components/briicks/` | ~55 `.tsx` files, 22 categories | App-local design system (preferred per rules) |
| shadcn/ui | `src/components/ui/` | ~35 primitives | Base Radix wrappers |

**Key Issues Found:**

1. **Token drift** — `globals.css` and `packages/ui/src/styles/index.css` define different warning/error color ramps. Storybook adds a third brand palette (STRUQTA purple vs SNDQ blue).

2. **Storybook coverage gap** — Only 24 stories for `@sndq/ui`. Briicks and `common-*` composites have zero Storybook coverage, despite being the preferred components.

3. **Component versioning** — Rules say to prefer `InputV2`, `ButtonV2`, etc., implying multiple generations coexist without clear deprecation enforcement.

4. **Import confusion** — Developers must remember the resolution order (Briicks → custom → `ui`) without linting enforcement.

### Phase 3.1 — Component Inventory Audit (Week 1–2)

**Goal**: Create a complete map of all shared components across the three sources.

#### Actions

1. **Build component inventory:**
   - List every component from `@sndq/ui` barrel export (`packages/ui/src/index.ts`)
   - List every Briicks component from `src/components/briicks/index.ts`
   - List every shadcn primitive from `src/components/ui/`
   - Mark overlaps (e.g., both `@sndq/ui` and Briicks export a `Badge`)

2. **Token audit:**
   - Compare CSS variables in `src/app/globals.css` vs `packages/ui/src/styles/index.css`
   - Document conflicts in warning/error/success color ramps
   - Map where each token is actually consumed

3. **Import usage analysis:**
   - Grep all imports of `@sndq/ui`, `briicks/`, and `components/ui/` across `src/modules/`
   - Count usage frequency per source
   - Identify modules that mix sources inconsistently

#### Deliverable
- Component inventory spreadsheet with columns: Name, Source, Has Story, Has Tests, Usage Count, Overlap Status
- Token conflict report with side-by-side hex comparisons
- Import analysis heatmap by module

### Phase 3.2 — Standardization Strategy Proposal (Week 2–4)

**Goal**: Define a clear tiered architecture and get PM/team buy-in.

#### Proposed Tier System

```
┌─────────────────────────────────────────────┐
│  Tier 3: Feature Components                 │
│  src/components/common-*                    │
│  (CommonSheet, CommonTable, CommonDrawer)   │
│  Feature-level shared compositions          │
├─────────────────────────────────────────────┤
│  Tier 2: Business Compositions              │
│  src/components/briicks/                    │
│  (MetricCard, FilterBar, DataTable,         │
│   SearchableSelect, NavigationTabs)         │
│  Domain-aware but reusable across modules   │
├─────────────────────────────────────────────┤
│  Tier 1: Design System Primitives           │
│  @sndq/ui (packages/ui/)                   │
│  (Button, Input, Select, Dialog, Badge,     │
│   Checkbox, Form, Tooltip, Skeleton, Icons) │
│  Brand-agnostic, cross-app reusable         │
└─────────────────────────────────────────────┘
```

#### Decision: What goes where?

```
Need a new component?
  └─ Is it a brand-agnostic primitive (button, input, dialog)?
       └─ YES → Create in @sndq/ui + write a story
       └─ NO → Is it used by 2+ modules?
            └─ YES → Create in Briicks (src/components/briicks/)
            └─ NO → Keep it in the module's own components/ folder
```

#### Migration Strategy for `src/components/ui/`

The shadcn/ui layer (`src/components/ui/`) should be gradually absorbed:
- Components already in `@sndq/ui` → Replace imports, delete from `ui/`
- Components not in `@sndq/ui` → Promote to `@sndq/ui` if generic, or to Briicks if business-specific
- Target: zero remaining files in `src/components/ui/` (long-term)

#### Token Consolidation

- Single source of truth: `@sndq/ui` defines base tokens
- App `globals.css` only adds brand-specific overrides
- Storybook uses the exact same token set (no STRUQTA divergence unless multi-brand is intentional)

### Phase 3.3 — Implementation & Enforcement (Week 4–6)

**Goal**: Make the standards enforceable and self-documenting.

#### Actions

1. **Write a UI Contribution Guide:**
   - Component creation checklist (where to put it, naming, props interface, story)
   - Token usage rules (which CSS variables to use)
   - Import resolution order with examples
   - PR review checklist for UI changes

2. **ESLint rules for enforcement:**
   - Warn on raw `<p>`, `<h1>`, `<span>` usage (prefer `Heading`, `Paragraph`, `Caption` from Briicks)
   - Warn on importing from `src/components/ui/` when a Briicks equivalent exists
   - Enforce consistent import paths

3. **Expand Storybook coverage:**
   - Add stories for all Briicks components (currently 0 stories)
   - Add stories for `common-*` composites
   - Target: every shared component has at least one story

4. **Visual regression with Chromatic:**
   - Chromatic is already set up
   - Configure snapshot tests for new stories
   - Add to CI pipeline

#### Deliverable
- UI Contribution Guide (markdown, linked from AGENTS.md)
- ESLint plugin/rules PR
- Storybook stories PR (Briicks components)
- Updated `12-sndq/README.md` linking to the guide

---

## Pillar 4: Backend Feature Ownership

### Backend Architecture Snapshot

| Metric | Value |
|--------|-------|
| Framework | NestJS |
| ORM | TypeORM |
| Database | PostgreSQL |
| Cache | Redis (ioredis) |
| Queue | BullMQ |
| Auth | JWT (Passport) |
| Modules | 88 `*.module.ts` files |
| Entities | 235 `*.entity.ts` files |
| Migrations | 413 migration files |
| Unit tests | 74 `*.spec.ts` files |
| E2E tests | 28 `*.e2e-spec.ts` files |
| Multi-tenant | `workspaceId` scoping on all queries |

### Phase 4.1 — Foundation (Week 1–3)

**Goal**: Understand the NestJS architecture and core patterns used in SNDQ.

#### Learning Path (ordered)

| Step | Topic | Key Files to Read |
|------|-------|-------------------|
| 1 | Project conventions | `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*` |
| 2 | App bootstrap | `src/main.ts`, `src/app.module.ts` |
| 3 | Base entity patterns | `src/common/entities/base.entity.ts`, `src/common/entities/with-user-tracking.entity.ts` |
| 4 | Exception handling | `src/common/exceptions/`, `src/common/filters/` |
| 5 | Auth flow | `src/modules/auth/`, `guards/global-auth.guard.ts`, `strategies/jwt.strategy.ts` |
| 6 | Transaction pattern | `src/modules/core/services/db.service.ts` |
| 7 | Multi-tenant context | `src/modules/workspaces/` |
| 8 | Validation (DTOs) | Any `dto/*.dto.ts` file — `class-validator` decorators |
| 9 | Queue processing | Any `consumers/*.consumer.ts` — BullMQ patterns |

#### Hands-on Exercises

1. **Run the project locally:**
   ```bash
   pnpm install
   pnpm run start:dev
   ```

2. **Read a simple module end-to-end:**
   - Recommended: `country` or `note` module
   - Trace: Module → Controller → Service → Entity → DTO
   - Understand decorator usage: `@Controller`, `@Injectable`, `@InjectRepository`

3. **Write a unit test** for an existing service:
   - Pick any service with no existing `.spec.ts`
   - Mirror the mocking pattern from the closest existing test
   - Follow AAA pattern (Arrange-Act-Assert)

4. **Run the test suite:**
   ```bash
   pnpm test path/to/your.spec.ts
   ```

### Phase 4.2 — Domain Deep Dive (Week 3–6)

**Goal**: Deep-dive into a vertical slice related to current work.

Since the current branch is `feat/auto-match-session`, the recommended vertical slice is **financial/payments**:

#### Payment Matching Domain

| Module | Key Concepts |
|--------|-------------|
| `payment-matching/` | Auto-matching logic, session entities, Bull consumer for background processing |
| `transaction/` | Core financial entities (receivables/payables), transaction lines, reminders |
| `payments/` | Payment recording, internal transfers |
| `accounting/` | Ledgers, journal entries, accounting years |
| `bank/` | Bank accounts |
| `ponto/` | Open banking integration (Ponto), real-time bank sync |

#### Study Plan for Each Module

```
For each module:
  1. Read *.module.ts — understand imports, providers, exports
  2. Read entities/ — understand the data model and relations
  3. Read dto/ — understand API inputs and validation
  4. Read services/ — understand business logic and DB queries
  5. Read controllers/ — understand API endpoints and auth
  6. Read consumers/ (if any) — understand background job processing
  7. Read *.spec.ts (if any) — understand how it's tested
  8. Draw an entity relationship diagram
```

#### Existing Deep Dives (already in this repo)

- [SNDQ Accounting Module](./backend/sndq-accounting-module.md)
- [SNDQ Payment Request Module](./backend/sndq-payment-request-module.md)

### Phase 4.3 — First Backend Contribution (Week 6–8)

**Goal**: Own one feature end-to-end (frontend + backend).

#### Contribution Checklist

1. **Pick a ticket** related to auto-matching or financial module
2. **Implement the API endpoint:**
   - Controller with proper decorators and DTO validation
   - Service with business logic and transaction management
   - Entity changes (if needed) with proper column naming
3. **Generate migration** (if DB changes):
   ```bash
   pnpm run migration:generate src/migrations/descriptive_snake_case_name
   ```
4. **Write tests:**
   - Unit tests for service methods (mock repositories)
   - E2E test for the endpoint (if complex flow)
5. **Self-review** against:
   - `.cursor/rules/coding-guideline.mdc`
   - Error handling rules (custom exceptions with i18n)
   - TypeORM best practices (soft deletes, workspace scoping)
6. **Lint check:**
   ```bash
   pnpm eslint --fix src/modules/your-module/**/*.ts
   ```

#### Key Patterns to Follow

| Pattern | Example |
|---------|---------|
| Custom exceptions | `throw new BadRequestException(error('error.invalid_data'))` |
| Transaction wrapping | `this.dbService.withTransaction(manager, async (m) => { ... })` |
| Workspace scoping | Always include `workspaceId` in WHERE clauses |
| Soft delete awareness | Automatic in TypeORM queries; manual `deleted_at IS NULL` in raw SQL |
| DTO validation | `class-validator` decorators on all input DTOs |

#### Deliverable
- Backend learning notes (journal entries in this repo)
- First backend PR with unit tests
- Architecture diagram for the module being owned

---

## Timeline

```
Week 1-2:   [P1] Bundle audit + baseline      [P4] Read AGENTS.md, run project, read simple module
Week 2-3:   [P1] Dependency cleanup PR         [P4] Auth flow + transaction patterns
Week 3-4:   [P1] Build pipeline optimization   [P4] Payment matching domain deep dive
                                               [P2] Study existing dashboard patterns
Week 4-5:   [P3] Component inventory audit     [P4] Continue domain study
                                               [P2] Research dashboard best practices
Week 5-6:   [P3] Standardization proposal      [P4] First backend contribution
                                               [P2] Feature proposal drafts
Week 6-8:   [P3] Implementation + enforcement  [P4] Own feature end-to-end
                                               [P2] Prototype in sndq-prototype
```

---

## Success Metrics

| Pillar | Metric | Target |
|--------|--------|--------|
| 1. FE Optimization | Build time reduction | -20% or more |
| 1. FE Optimization | First load JS reduction | -15% or more |
| 2. Dashboard | Feature proposals accepted by PM | At least 1 |
| 2. Dashboard | Prototype created | At least 1 in `sndq-prototype` |
| 3. UI System | Component inventory completed | 100% coverage |
| 3. UI System | Storybook stories for Briicks | +20 new stories |
| 3. UI System | Contribution guide written and adopted | Linked in AGENTS.md |
| 4. Backend | Backend PRs merged | At least 2 |
| 4. Backend | Full-stack feature delivered | At least 1 end-to-end |
| 4. Backend | Unit test coverage contribution | +10 new spec files |

---

## References

- [sndq-fe Reading Plan](./frontend/sndq-fe-reading-plan.md) — earlier reading plan for FE contribution
- [SNDQ Accounting Module Deep Dive](./backend/sndq-accounting-module.md) — backend domain study
- [SNDQ Payment Request Module Deep Dive](./backend/sndq-payment-request-module.md) — backend domain study
- `sndq-fe/AGENTS.md` — frontend codebase conventions
- `sndq-be/AGENTS.md` — backend codebase conventions
- `sndq-be/.cursor/rules/` — coding guidelines, TypeORM rules, testing guidelines
