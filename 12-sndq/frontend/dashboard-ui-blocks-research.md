# Dashboard UI Blocks & Component Libraries Research

Research on component libraries, block collections, and dashboard-building tools for the SNDQ frontend (`sndq-fe`).

**Created**: 2026-03-27
**Tags**: `sndq`, `frontend`, `design-system`, `dashboard`, `ui-components`

---

## TL;DR

The `@sndq/ui` design system already uses the Shadcn pattern (Radix + CVA + Tailwind Merge), making copy-paste block libraries the best fit. The top 3 recommendations are:

1. **Shadcn Blocks** — zero additional dependencies, same ecosystem
2. **Origin UI** — 473+ components, same stack, rich patterns
3. **Tremor Blocks** — 300+ dashboard-specific blocks, chart-focused

For specialized needs: **Nivo** for advanced charts, **React Grid Layout** for drag-drop dashboards, **AG Grid Community** for Excel-like data grids.

---

## Current SNDQ Frontend Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Next.js (App Router) | 15.5.9 |
| UI Library | React | 19.2.0 |
| Styling | Tailwind CSS | v4 |
| TypeScript | TypeScript | ^5 |
| UI Primitives | Radix UI | Multiple packages |
| Design System | Briicks (custom on Shadcn) | Internal |
| Charts | Recharts | ^2.13.3 |
| Tables | TanStack Table | ^8.21.2 |
| Virtualization | TanStack Virtual | ^3.13.4 |
| State | TanStack Query + Zustand | v5 / v5 |
| Forms | React Hook Form + Zod | v7 / v3 |
| Animation | Motion (Framer) | ^12.23.26 |
| Rich Text | Tiptap | ^2.11.5 |
| Icons | Lucide React | ^0.477.0 |
| i18n | next-intl | ^3.26.5 |

### Design System Architecture

```
Component Priority Order:
1. Briicks (@/components/briicks) — InputV2, Button, Heading, Paragraph, Caption
2. Common composites (@/components/common-*) — CommonSheet, CommonTable, CommonDrawer
3. Custom (@/components) — Feature-specific components
4. UI (@/components/ui) — Base shadcn components (last resort)
```

### Color System (Briicks)

Custom token-based palette replacing Shadcn defaults:
- `brand-[25-900]` — Primary brand colors
- `neutral-[0-900]` — Gray scale
- `success-[25-900]` — Success states
- `warning-[25-900]` — Warning states
- `error-[25-900]` — Error states

---

## Category 1: Dashboard Block Libraries

### 1.1 Shadcn Blocks (Official)

| Attribute | Details |
|-----------|---------|
| URL | https://ui.shadcn.com/blocks |
| License | MIT |
| Price | Free |
| Stack | Radix UI + Tailwind CSS |
| Install | `npx shadcn add dashboard-01` |
| Compatibility | Exact match with SNDQ stack |

#### Overview

Official building blocks from the Shadcn team. These are complete, production-ready page sections that combine multiple Shadcn components into functional layouts.

#### Available Block Types

- **Dashboard** — Full dashboard layout with sidebar, charts, data tables, KPI cards
- **Authentication** — Login, register, forgot password, two-factor pages
- **Sidebar** — Collapsible navigation with nested menu items, search, footer
- **Settings** — Profile, appearance, notifications, display preferences
- **Music App** — Media player layout with playlists, albums, artists
- **Mail App** — Email client layout with inbox, compose, folders
- **Chat** — Messaging interface with conversations, input, attachments
- **Calendar** — Event management with day/week/month views
- **Tasks** — Task management with filters, columns, status badges

#### Key Features

- Components install directly via CLI (`npx shadcn add <block-name>`)
- Uses `@tanstack/react-table` for data tables (already in SNDQ stack)
- Charts built on Recharts (already in SNDQ stack)
- Responsive by default (sidebar collapses to mobile drawer)
- Dark mode support via `next-themes` (already in SNDQ stack)

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★★★ | Identical stack |
| Integration Effort | ★★★★★ | Copy-paste, adapt Briicks colors |
| Dashboard Relevance | ★★★★☆ | Good starting point, needs customization for property management |
| Component Coverage | ★★★☆☆ | Limited number of blocks (quality > quantity) |
| Maintenance Burden | ★★★★★ | Zero dependencies added |

#### Example: Dashboard Block Structure

```
dashboard-01/
├── app/dashboard/
│   └── page.tsx
├── components/
│   ├── app-sidebar.tsx        # Navigation sidebar
│   ├── chart-area-interactive.tsx  # Recharts area chart
│   ├── data-table.tsx         # TanStack Table
│   ├── nav-main.tsx           # Main navigation items
│   ├── section-cards.tsx      # KPI metric cards
│   └── site-header.tsx        # Top header bar
```

#### Adaptation Strategy for SNDQ

1. Install block: `npx shadcn add dashboard-01`
2. Replace color tokens: `bg-primary` → `bg-brand-500`, `text-muted-foreground` → `text-neutral-500`
3. Replace text elements: `<h2>` → `<Heading size="medium">`, `<p>` → `<Paragraph>`
4. Replace base components: `<Input>` → `<InputV2>`, `<Button>` → Briicks `<Button>`
5. Move reusable patterns to `@sndq/ui`

---

### 1.2 Origin UI

| Attribute | Details |
|-----------|---------|
| URL | https://originui.com |
| GitHub | https://github.com/origin-space/originui |
| License | MIT |
| Price | Free |
| Stack | Tailwind CSS v4 + Radix UI + React |
| Components | 473+ |
| TypeScript | 93.7% of codebase |

#### Overview

An extensive open-source collection of copy-and-paste components designed for application UIs. Think of it as Shadcn Blocks on steroids — more components, more patterns, more variety.

#### Component Categories (473+ total)

| Category | Description |
|----------|-------------|
| Accordion | Expandable content sections |
| Alert / Alert Dialog | Notification banners, confirmation dialogs |
| Autocomplete | Search with suggestions |
| Avatar | User profile images with fallbacks |
| Badge | Status indicators, labels |
| Breadcrumb | Navigation trail |
| Button | All variants, icon buttons, button groups |
| Calendar | Date picking and range selection |
| Card | Content containers, KPI cards, pricing cards |
| Checkbox / Checkbox Group | Single and multi-select |
| Collapsible | Expandable panels |
| Combobox | Searchable dropdown |
| Command | Command palette (⌘K) |
| Date Picker | Single date, range, with time |
| Dialog / Drawer | Modal and slide-over panels |
| Empty | Empty state illustrations |
| Field / Fieldset | Form field wrappers |
| Form | Complete form patterns |
| Input / Input Group / Input OTP | Text inputs, grouped inputs, OTP verification |
| Kbd | Keyboard shortcut badges |
| Label | Form labels |
| Menu | Dropdown and context menus |
| Notification | Toast and banner notifications |
| Pagination | Page navigation |
| Popover | Floating content panels |
| Progress | Progress bars and indicators |
| Radio Group | Option selection |
| Select | Dropdown selection |
| Separator | Content dividers |
| Sidebar | Application navigation |
| Skeleton | Loading placeholders |
| Slider | Range input |
| Switch | Toggle controls |
| Table | Data display tables |
| Tabs | Tabbed navigation |
| Textarea | Multi-line text input |
| Timeline | Chronological events |
| Toggle / Toggle Group | Binary switches |
| Tooltip | Contextual help |
| Tree View | Hierarchical navigation |

#### Key Differentiators

1. **Dark mode** built-in for every component
2. **Accessibility** — Radix UI primitives + React Aria for keyboard navigation and screen readers
3. **Copy-paste philosophy** — no npm dependency, full code ownership
4. **Consistent design language** — all 473+ components share the same visual DNA
5. **Regular updates** — actively maintained with new component patterns added frequently

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★★★ | Tailwind v4 + Radix = exact match |
| Integration Effort | ★★★★☆ | Copy-paste, needs Briicks color mapping |
| Dashboard Relevance | ★★★★☆ | Strong application UI patterns |
| Component Coverage | ★★★★★ | 473+ components covers virtually everything |
| Maintenance Burden | ★★★★★ | No dependencies, your code |

#### High-Value Patterns for SNDQ

- **Tree View** — Property hierarchy (building → floor → unit)
- **Timeline** — Rental contract history, payment timeline
- **Command** — Quick navigation (⌘K) for large property portfolios
- **Empty States** — Professional empty states for new workspaces
- **Table patterns** — Advanced filtering, column management, bulk actions
- **Form patterns** — Multi-step forms, inline editing, field validation states

---

### 1.3 Tremor Blocks

| Attribute | Details |
|-----------|---------|
| URL | https://blocks.tremor.so |
| GitHub | https://github.com/tremorlabs/tremor-blocks |
| Core Library | https://tremor.so |
| License | Apache 2.0 |
| Price | Free (blocks) / Templates (paid) |
| Stack | React + Tailwind CSS + Radix UI + Recharts |
| Blocks | 300+ |
| Templates | 6 |

#### Overview

Tremor is purpose-built for dashboards and data visualization. The core library provides 35+ chart and data display components, while Tremor Blocks offers 300+ production-ready compositions combining these components.

#### Core Components (tremor library)

**Charts:**
- AreaChart, BarChart, LineChart, DonutChart
- SparkChart, SparkAreaChart, SparkBarChart
- Funnel Chart
- Combo charts (bar + line)

**Data Display:**
- Tracker — Timeline heatmap (like GitHub contribution grid)
- BarList — Horizontal bar comparisons
- CategoryBar — Segmented progress bar
- ProgressBar, ProgressCircle — Loading/completion indicators
- DataBar — Inline micro-visualization within table cells
- DeltaBadge — Change indicators (+12%, -5%)

**Inputs & Navigation:**
- DatePicker, DateRangePicker
- MultiSelect, SearchSelect
- Tab navigation
- FilterBar with multiple filter types

**Layout:**
- Card — Metric cards, chart cards, list cards
- Divider — Section separators
- Callout — Alert/info banners

#### Available Templates

| Template | Description | Tech |
|----------|-------------|------|
| **Planner** | Full dashboard with sidebar, charts, tables | Next.js 15, React 19, TypeScript |
| **Solar** | SaaS marketing website | Next.js 15, Tailwind v4, React 19 |
| **Overview** | Dashboard overview with advanced visualizations | Next.js, Recharts |
| **Admin Dashboard** | Analytical interface for data management | Next.js, TypeScript |
| **SaaS Template** | Data application with CRUD operations | Next.js, Recharts |
| **Data Exploration** | Interactive data exploration interface | Next.js, Recharts |

#### Block Categories

| Category | Examples |
|----------|---------|
| KPI Cards | Single metric, comparison, with trend chart, with delta |
| Chart Compositions | Area + controls, bar + legend, donut + table |
| Tables | Sortable, filterable, with inline actions, with charts |
| Account Management | User profile, team settings, billing |
| Pricing | Pricing cards, feature comparison tables |
| Onboarding | Step wizards, progress indicators |
| Feature Sections | Hero cards, feature grids |
| Billing & Usage | Usage meters, plan comparison, invoice tables |

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★★☆ | Same foundation (Radix + Tailwind + Recharts), but has its own component API |
| Integration Effort | ★★★☆☆ | Can copy HTML/Tailwind, but Tremor components need adaptation |
| Dashboard Relevance | ★★★★★ | Purpose-built for dashboards — perfect for property management KPIs |
| Component Coverage | ★★★★★ | 300+ blocks specifically for data-heavy UIs |
| Maintenance Burden | ★★★★☆ | Copy layout patterns, not install `@tremor/react` as dependency |

#### High-Value Patterns for SNDQ

- **KPI Cards** — Occupancy rate, revenue per building, maintenance cost trends
- **Tracker** — Payment status timeline (paid/pending/overdue across months)
- **BarList** — Top buildings by revenue, tenant demographics
- **DeltaBadge** — Month-over-month revenue change, vacancy rate trends
- **Chart Compositions** — Financial reports with area charts + filter controls
- **Billing Blocks** — Invoice management, payment plan comparison
- **Usage Meters** — Storage usage, API quotas for multi-tenant workspaces

#### Integration Strategy

Rather than installing `@tremor/react` as a dependency, extract the pattern:

```tsx
// DON'T: Add tremor as dependency
import { AreaChart, Card } from '@tremor/react';

// DO: Copy the Tailwind structure and use existing SNDQ components
// Tremor KPI card pattern → adapted with Briicks components
import { Heading, Paragraph, Caption } from '@/components/briicks';

function KpiCard({ title, value, delta, trend }: KpiCardProps) {
  return (
    <div className="rounded-md border bg-neutral-0 p-6">
      <Caption className="text-neutral-500">{title}</Caption>
      <Heading size="large" className="mt-1">{value}</Heading>
      <div className="mt-2 flex items-center gap-2">
        <span className={delta >= 0 ? 'text-success-500' : 'text-error-500'}>
          {delta >= 0 ? '+' : ''}{delta}%
        </span>
        <Caption className="text-neutral-400">vs last month</Caption>
      </div>
    </div>
  );
}
```

---

### 1.4 Shadcnblocks.com (Third-Party)

| Attribute | Details |
|-----------|---------|
| URL | https://www.shadcnblocks.com |
| License | Commercial |
| Price | Free tier + Pro $149 / Premium $299 |
| Blocks | 1,423 total |
| Components | 1,189 variants |
| Templates | 13 (Premium) |

#### Overview

A third-party marketplace of Shadcn-compatible blocks. The largest collection available, covering virtually every UI pattern.

#### Block Categories

| Category | Count | Relevance to SNDQ |
|----------|-------|-------------------|
| Hero | 182 | Low (marketing) |
| Feature | 274 | Medium (feature pages) |
| Dashboard | 15+ | High |
| Pricing | 37 | Medium |
| Gallery | 48 | Low |
| Testimonial | Many | Low |
| CTA | Many | Low |
| Footer/Header | Many | Medium |
| Login/Signup | Many | Medium |
| Stats | Many | High |

#### Pricing Breakdown

| Plan | Price | Includes |
|------|-------|----------|
| Free | $0 | Limited blocks, basic components |
| Pro | $149 (lifetime) | 1,189+ component variants, 1,273+ Pro blocks |
| Premium | $299 (lifetime) | + 13 templates, Figma Kit, Admin Kit |
| Premium Team | $599 (lifetime) | + 10 user seats, org dashboard |

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★★★ | Built for Shadcn ecosystem |
| Integration Effort | ★★★★☆ | Copy-paste with Briicks color adaptation |
| Dashboard Relevance | ★★★☆☆ | Dashboard is a small portion of the total blocks |
| Component Coverage | ★★★★★ | 1,423 blocks — the largest collection |
| Maintenance Burden | ★★★★★ | Copy-paste, no dependencies |
| Cost | ★★★☆☆ | Free tier limited; Pro is $149 one-time |

#### Verdict

Good as a supplementary reference library. The free tier provides enough dashboard patterns to be useful. Consider Pro only if the team needs marketing/landing page blocks frequently.

---

### 1.5 Shadboard (Open-Source Dashboard Template)

| Attribute | Details |
|-----------|---------|
| URL | https://github.com/Qualiora/shadboard |
| License | MIT |
| Price | Free |
| Stack | Next.js 15, React 19, Tailwind CSS 4, Shadcn/ui |
| Stars | 615+ |
| TypeScript | 95% |

#### Overview

A full-featured, open-source admin dashboard template. Unlike block libraries (which give you pieces), Shadboard gives you a complete, working dashboard application.

#### Built-In Features

**Applications:**
- Email client
- Chat interface
- Calendar
- Kanban board

**Pages:**
- Pricing, Payment, Settings (General, Security, Plan & Billing, Notifications)
- Authentication (Sign In, Register, Forgot Password, Verify Email)
- Error pages (404, 401, Maintenance)

**Technical:**
- Authentication with NextAuth.js
- Internationalization (i18n)
- Dynamic theme customizer
- Responsive across all devices
- Recharts for charts
- TanStack Table for data tables
- React Hook Form + Zod validation
- Lucide and React Icons

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★★★ | Identical stack to SNDQ |
| Integration Effort | ★★★☆☆ | Full template — extract patterns, don't copy wholesale |
| Dashboard Relevance | ★★★★★ | Complete dashboard implementation |
| Learning Value | ★★★★★ | Reference architecture for dashboard patterns |
| Maintenance Burden | ★★★★★ | MIT, study and extract |

#### Best Use

Don't use Shadboard as a starting point (SNDQ already has its own architecture). Instead, use it as a **reference implementation** for:
- How to structure sidebar navigation with nested routes
- How to build a theme customizer
- How to implement kanban boards
- How to structure settings pages
- Email/Chat UI patterns if needed in the future

---

## Category 2: Chart & Data Visualization

### 2.1 Shadcn Charts (Official)

| Attribute | Details |
|-----------|---------|
| URL | https://ui.shadcn.com/charts |
| Stack | Recharts (wrapper) |
| Price | Free |
| Dependency | None new (uses existing Recharts) |

#### Overview

Official Shadcn chart components — essentially beautiful, themed wrappers around Recharts that integrate with the Shadcn design token system.

#### Chart Types

| Type | Description |
|------|-------------|
| Area Chart | Filled line charts, stacked areas |
| Bar Chart | Vertical/horizontal, stacked, grouped |
| Line Chart | Single/multi-line with dots |
| Pie Chart | Standard and donut |
| Radar Chart | Multi-axis comparison |
| Radial Chart | Circular progress |
| Tooltip | Themed chart tooltips |

#### Key Features

- Automatic dark mode support via CSS variables
- Themed to match Shadcn design tokens (easy to map to Briicks)
- Built on Recharts (already in SNDQ dependencies)
- Accessible with proper ARIA labels
- Responsive containers

#### SNDQ Integration

Since SNDQ already uses Recharts (`^2.13.3`), Shadcn Charts adds zero bundle size. The value is in the **design patterns and theming approach**, not new functionality.

```
Integration cost: Near zero
Bundle impact: Zero
Value: Design consistency + ready-made chart patterns
```

---

### 2.2 Nivo

| Attribute | Details |
|-----------|---------|
| URL | https://nivo.rocks |
| GitHub | https://github.com/plouc/nivo |
| License | MIT |
| Price | Free |
| Stack | React + D3.js |
| Rendering | SVG, Canvas, HTML, HTTP API |
| Stars | 13k+ |

#### Overview

A rich set of data visualization components built on D3.js. Where Recharts excels at common chart types, Nivo shines with specialized visualizations that Recharts cannot produce.

#### Unique Chart Types (not available in Recharts)

| Chart Type | Use Case for SNDQ |
|-----------|-------------------|
| **HeatMap** | Occupancy rates across buildings × months, rent collection patterns |
| **TreeMap** | Portfolio breakdown by building size/revenue, expense categories |
| **Sankey** | Cash flow visualization (income sources → expense categories) |
| **Chord** | Tenant-building relationships, vendor-building connections |
| **Waffle** | Percentage-based metrics (occupancy, payment completion) |
| **Bump** | Building rankings over time (by revenue, occupancy) |
| **Calendar** | Lease expiration calendar, maintenance schedule heatmap |
| **Network** | Property ownership structure, company relationships |
| **Swarm Plot** | Rent distribution analysis, payment timing patterns |
| **Circle Packing** | Hierarchical portfolio visualization |
| **GeoMap** | Property locations on a map |
| **Parallel Coordinates** | Multi-dimensional property comparison |

#### Rendering Modes

| Mode | Best For |
|------|----------|
| SVG | Small to medium datasets, interactivity, accessibility |
| Canvas | Large datasets (1000+ points), performance |
| HTML | TreeMap with text content, table-like layouts |
| HTTP API | Server-side rendering, image generation |

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★☆☆ | D3-based, different from Recharts approach |
| Integration Effort | ★★★☆☆ | New dependency, different API patterns |
| Dashboard Relevance | ★★★★★ | Unlocks advanced visualizations impossible with Recharts |
| Component Coverage | ★★★★★ | 25+ chart types |
| Bundle Impact | ★★☆☆☆ | D3 dependency adds weight; use modular imports |

#### Recommendation

**Don't replace Recharts with Nivo.** Instead, use Nivo as a supplement for specific advanced visualizations:

```
Recharts → Standard charts (bar, line, area, pie) — already in use
Nivo → Advanced charts (heatmap, treemap, sankey, calendar) — add when needed
```

Install individual packages to minimize bundle impact:
```bash
pnpm add @nivo/heatmap    # Only when needed
pnpm add @nivo/treemap    # Only when needed
pnpm add @nivo/sankey     # Only when needed
```

---

## Category 3: Data Grid / Table

### 3.1 TanStack Table (Current)

Already in SNDQ stack at `@tanstack/react-table@^8.21.2`. Best-in-class for headless table logic with full control over rendering.

**Strengths for SNDQ:**
- Complete control over styling (Briicks design system)
- Server-side sorting, filtering, pagination
- Column pinning, grouping, virtualization (via TanStack Virtual)
- Tree data for hierarchical views

**No change recommended** — TanStack Table is the right choice for SNDQ's custom design system approach.

---

### 3.2 AG Grid Community Edition

| Attribute | Details |
|-----------|---------|
| URL | https://www.ag-grid.com |
| License | MIT (Community) / Commercial (Enterprise) |
| Price | Free (Community) / $999+ (Enterprise) |
| Weekly Downloads | 1.9M+ |

#### Community Edition Free Features

| Feature | Available |
|---------|-----------|
| Sorting | ✅ |
| Filtering | ✅ |
| Pagination | ✅ |
| Column Virtualization | ✅ |
| Row Virtualization | ✅ |
| Cell Rendering (custom) | ✅ |
| Themes + CSS Customization | ✅ |
| CSV Export | ✅ |
| Quick Filter / External Filter | ✅ |
| Row Selection | ✅ |
| Row Numbers | ✅ |
| Drag and Drop | ✅ |
| Batch Editing | ✅ |
| Undo/Redo | ✅ |
| Column Menu | ✅ |
| Context Menu | ✅ |
| Clipboard | ✅ |
| ARIA + Keyboard Nav | ✅ |
| Localization | ✅ |

#### Enterprise-Only Features (NOT free)

| Feature | License |
|---------|---------|
| Server-Side Row Model | Enterprise |
| Excel Export | Enterprise |
| Pivot Tables | Enterprise |
| Range Selection | Enterprise |
| Integrated Charts | Enterprise |
| Row Grouping | Enterprise |
| Master/Detail | Enterprise |

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★☆☆ | Brings its own rendering engine, doesn't use Tailwind |
| Integration Effort | ★★☆☆☆ | Significant — own styling system, breaks Briicks consistency |
| Feature Power | ★★★★★ | Most feature-rich grid available |
| Bundle Impact | ★★☆☆☆ | Heavy — 200KB+ for community edition |
| Design Consistency | ★★☆☆☆ | Difficult to match Briicks tokens |

#### Recommendation

**Keep TanStack Table as the primary table solution.** AG Grid is overkill for most SNDQ needs and would break design system consistency.

Consider AG Grid **only** if a specific feature requires Excel-like functionality:
- Chart of Accounts with complex inline editing
- Large financial reports with pivot-like grouping
- Bulk data entry (100+ rows) with clipboard paste

In those cases, isolate AG Grid to specific modules and apply custom theming.

---

## Category 4: Dashboard Layout

### 4.1 React Resizable Panels (Current)

Already in SNDQ stack at `react-resizable-panels@^3.0.5`. Good for split-pane layouts (e.g., email client: list | detail).

---

### 4.2 React Grid Layout

| Attribute | Details |
|-----------|---------|
| URL | https://github.com/react-grid-layout/react-grid-layout |
| License | MIT |
| Price | Free |
| Version | 2.2.3 (March 2026) |
| Stars | 22,143+ |
| Weekly Downloads | 1.9M+ |

#### Overview

A draggable and resizable grid layout system — think Grafana, Kibana, or Windows 11 widgets. Enables users to customize their own dashboard layout by dragging and resizing widget cards.

#### Key Features (v2 — 2026)

| Feature | Description |
|---------|-------------|
| Drag & Drop | Move widgets anywhere on the grid |
| Resize | Drag corners/edges to resize widgets |
| Responsive | Breakpoints for different screen sizes |
| Auto-Packing | Widgets automatically fill gaps |
| Static Widgets | Pin certain widgets in place |
| Lock/Unlock Mode | Toggle between edit and view modes |
| State Persistence | Save layout to localStorage or server |
| TypeScript | First-class types (v2) |
| React Hooks API | `useContainerWidth`, `useGridLayout`, `useResponsiveLayout` |
| Composable Config | `gridConfig`, `dragConfig`, `resizeConfig`, `positionStrategy`, `compactor` |
| Tree-Shakeable | ESM + CJS builds, smaller bundle |

#### Use Cases for SNDQ

| Use Case | Description |
|----------|-------------|
| **Custom Dashboard** | Let property managers arrange KPI cards, charts, tables |
| **Portfolio Overview** | Drag-and-drop building summary widgets |
| **Financial Dashboard** | Customizable financial report layout |
| **Tenant Portal** | Personalized tenant dashboard |

#### Layout Persistence Pattern

```tsx
// Save layout to user preferences (API)
const handleLayoutChange = (layout: Layout[]) => {
  saveUserDashboardLayout(workspaceId, userId, layout);
};

// Restore layout on mount
const { data: savedLayout } = useQuery({
  queryKey: ['dashboard-layout', workspaceId, userId],
  queryFn: () => fetchUserDashboardLayout(workspaceId, userId),
});
```

#### SNDQ Integration Assessment

| Factor | Rating | Notes |
|--------|--------|-------|
| Stack Compatibility | ★★★★☆ | React library, needs Tailwind styling wrapper |
| Integration Effort | ★★★☆☆ | Moderate — needs layout wrapper component |
| Dashboard Relevance | ★★★★★ | Enables user-customizable dashboards |
| Bundle Impact | ★★★★☆ | Relatively small (~30KB) |
| UX Value | ★★★★★ | "Wow factor" — users love customizable layouts |

#### Recommendation

**Add when building a customizable dashboard feature.** Not needed immediately, but high UX value when property managers want personalized dashboard views.

Priority: Medium — implement after core dashboard is built with static layout.

---

## Category 5: Full Design System References

### 5.1 Catalyst (Tailwind Labs)

| Attribute | Details |
|-----------|---------|
| URL | https://catalyst.tailwindui.com |
| By | Tailwind Labs (official) |
| License | Commercial (Tailwind Plus) |
| Price | Included with Tailwind Plus subscription |
| Stack | React 19 + Tailwind CSS v4.2 + Headless UI v2.1 + TypeScript 5.3 |

#### Overview

The official application UI kit from the Tailwind CSS team. Not a library — it's source code you download and own (similar to Shadcn philosophy but by the Tailwind team).

#### Components

| Component | Notes |
|-----------|-------|
| Button | All variants, icon buttons, loading states |
| Input | Text, email, number, search |
| Select | Native and custom |
| Checkbox, Radio, Switch | Form controls |
| Table | With sorting headers |
| Sidebar Layout | Desktop sidebar + mobile drawer |
| Stacked Layout | Horizontal nav for simpler apps |
| Dialog | Modal with transitions |
| Dropdown | Action menus |
| Alert | Banners and notifications |
| Badge | Status labels |
| Avatar | User profile images |
| Pagination | Page navigation |
| Combobox | Searchable select |
| Listbox | Enhanced select |
| Navbar | Top navigation bar |
| Textarea | Multi-line input |
| Divider | Section separators |

#### Key Characteristics

- **Customizable** — utilities in markup, no CSS variables to override
- **Your code** — downloadable source, not npm package
- **Accessible** — WAI-ARIA compliant, keyboard navigation
- **Dark mode** — complete dark mode support
- **Headless UI v2** — stable, production-ready

#### SNDQ Relevance

| Factor | Rating | Notes |
|--------|--------|-------|
| As a Reference | ★★★★★ | Best-in-class component design from Tailwind team |
| As a Replacement | ★☆☆☆☆ | SNDQ already has Shadcn + Briicks — no need to switch |
| Design Inspiration | ★★★★★ | Study their sidebar, table, and form patterns |
| Stack Match | ★★★☆☆ | Uses Headless UI, not Radix (different primitives) |

#### Recommendation

Use Catalyst as a **design reference**, not a code source. Study their:
- Sidebar layout responsive behavior
- Form validation UX patterns
- Dark mode color decisions
- Accessibility implementation

---

### 5.2 Park UI

| Attribute | Details |
|-----------|---------|
| URL | https://park-ui.com |
| GitHub | Part of Chakra UI organization |
| License | MIT |
| Price | Free |
| Stack | Ark UI + Panda CSS or Tailwind CSS |
| Frameworks | React, Solid, Vue (Svelte planned) |

#### Overview

A component library built on Ark UI (headless, from the Chakra UI team) that supports both Panda CSS and Tailwind CSS. Recently became part of the Chakra UI organization.

#### Key Differentiators

- **Multi-framework** — React, Solid, Vue
- **Tailwind plugin** — `@park-ui/tailwind-plugin` with configurable accent/gray colors
- **CLI** — Individual component installation
- **Components** — Accordion, Avatar, NumberInput, ToggleGroup, Collapsible, TreeView, Clipboard

#### SNDQ Relevance

| Factor | Rating | Notes |
|--------|--------|-------|
| As a Reference | ★★★★☆ | Good patterns, especially TreeView and Clipboard |
| As a Replacement | ★☆☆☆☆ | Different headless layer (Ark UI vs Radix) |
| Specific Value | ★★★☆☆ | TreeView pattern for property hierarchy |

---

### 5.3 Mantine

| Attribute | Details |
|-----------|---------|
| URL | https://mantine.dev |
| License | MIT |
| Price | Free |
| Components | 100+ |
| Approach | Library-first (install as dependency) |

#### Overview

A batteries-included React component library. Strongest for internal tools and admin dashboards where development speed matters more than design customization.

#### Mantine vs Shadcn/Briicks (SNDQ context)

| Feature | Mantine | Shadcn/Briicks (SNDQ) |
|---------|---------|----------------------|
| Data Table | Full-featured (sorting, pagination, resize, selection) | TanStack Table + custom rendering |
| Date Pickers | Comprehensive (DateRangePicker, DateTimePicker) | react-day-picker + custom |
| Charts | @mantine/charts (built-in) | Recharts + custom |
| Forms | Integrated Zod, nested fields | React Hook Form + Zod |
| Notifications | Advanced system | Sonner toast |
| Rich Text | Tiptap-based | Tiptap (already in SNDQ) |
| Setup Time | Minutes (single install) | Hours (component-by-component) |
| Bundle Size | ~200KB | ~50KB (only what you use) |
| Customization | Limited to theme API | Complete control (your code) |
| Design System Fit | Own design language | Adapts to any design system |

#### SNDQ Verdict

**Don't switch to Mantine.** SNDQ already invested in the Shadcn/Briicks pattern which offers:
- Complete design control (Briicks color system)
- Smaller bundle size
- Better for a product with its own design identity

Mantine would be the right choice if starting a new internal tool from scratch, but not for a product with an established design system.

---

## Category 6: Specialized Components

### 6.1 Motion (Already in Stack)

`motion@^12.23.26` — Framer Motion successor. Use for:
- Page transitions
- Widget enter/exit animations
- Drag interactions
- Layout animations (SharedLayout)

### 6.2 DND Kit (Already in Stack)

`@dnd-kit/core@^6.1.0` + `@dnd-kit/sortable@^8.0.0` — Use for:
- Kanban boards
- Sortable lists
- Drag-and-drop file upload

### 6.3 Tiptap (Already in Stack)

Full rich text editor at `@tiptap/react@^2.11.5` — Already well-configured with tables, images, mentions, etc.

---

## Comparison Matrix

### Block Libraries

| Library | Components | Price | Stack Match | Dashboard Focus | Bundle Impact |
|---------|-----------|-------|-------------|----------------|---------------|
| **Shadcn Blocks** | ~10 blocks | Free | ★★★★★ | ★★★★☆ | Zero |
| **Origin UI** | 473+ | Free | ★★★★★ | ★★★★☆ | Zero |
| **Tremor Blocks** | 300+ | Free/Paid | ★★★★☆ | ★★★★★ | Zero (copy) |
| **Shadcnblocks.com** | 1,423 | Free/$149+ | ★★★★★ | ★★★☆☆ | Zero |
| **Shadboard** | Full app | Free | ★★★★★ | ★★★★★ | Zero (reference) |

### Chart Libraries

| Library | Chart Types | Bundle Size | Already in SNDQ | Best For |
|---------|------------|-------------|-----------------|----------|
| **Recharts** | ~10 | ~150KB | ✅ Yes | Standard charts |
| **Shadcn Charts** | ~7 | 0 (wrapper) | Partial | Themed Recharts |
| **Nivo** | 25+ | ~50KB/chart | ❌ No | Advanced viz (heatmap, sankey) |

### Data Grids

| Library | License | Bundle | Design Control | Features |
|---------|---------|--------|----------------|----------|
| **TanStack Table** | MIT | ~15KB | ★★★★★ | Headless |
| **AG Grid Community** | MIT | ~200KB | ★★☆☆☆ | Battery-included |

### Layout

| Library | Type | Already in SNDQ | Best For |
|---------|------|-----------------|----------|
| **react-resizable-panels** | Split panes | ✅ Yes | Two/three panel layouts |
| **React Grid Layout** | Drag grid | ❌ No | Customizable dashboards |

---

## Implementation Roadmap

### Phase 1: Quick Wins (Week 1-2)

1. **Adopt Shadcn Charts theming** for existing Recharts usage
   - Map Shadcn color tokens → Briicks tokens
   - Create chart color palette constant for consistency

2. **Catalog useful patterns from Origin UI**
   - Identify 10-15 patterns most relevant to SNDQ
   - Create a Notion/document mapping: "SNDQ need → Origin UI pattern"

3. **Extract KPI card patterns from Tremor Blocks**
   - Adapt 3-4 KPI card variants for property management metrics
   - Add to `@sndq/ui` as reusable components

### Phase 2: Dashboard Components (Week 3-6)

4. **Build dashboard metric components**
   - KPI cards (occupancy rate, revenue, maintenance costs)
   - Delta badges (month-over-month changes)
   - Progress indicators (lease renewals, payment collection)

5. **Create chart compositions**
   - Revenue over time (area chart + filter controls)
   - Expense breakdown (donut chart + legend table)
   - Building comparison (bar chart + selector)

6. **Implement dashboard layout**
   - Static grid layout first (CSS Grid)
   - Consider React Grid Layout for phase 3

### Phase 3: Advanced Features (Week 7+)

7. **Add Nivo for advanced visualizations** (if needed)
   - Occupancy heatmap (buildings × months)
   - Cash flow sankey diagram
   - Lease expiration calendar view

8. **Implement customizable dashboard** (if product roadmap includes it)
   - React Grid Layout for drag-and-drop
   - Layout persistence per user/workspace
   - Widget catalog (users choose which widgets to display)

---

## Decision Framework

Use this flowchart when deciding which library to use:

```
Need a new UI component?
├── Is it a standard component? (button, input, select, dialog)
│   └── YES → Check Briicks → Check Shadcn → Check Origin UI
│
├── Is it a dashboard block? (KPI card, chart composition, stats section)
│   └── YES → Check Tremor Blocks → Check Shadcn Blocks → Build custom
│
├── Is it a chart?
│   ├── Standard chart? (bar, line, area, pie)
│   │   └── YES → Use Recharts (already installed)
│   └── Advanced chart? (heatmap, treemap, sankey)
│       └── YES → Use Nivo (install specific package)
│
├── Is it a data table?
│   └── YES → Use TanStack Table (already installed)
│
├── Is it a layout feature?
│   ├── Split panes? → Use react-resizable-panels (already installed)
│   └── Drag-and-drop grid? → Use React Grid Layout
│
└── Is it a full page template?
    └── YES → Check Shadboard for reference → Build custom
```

---

## References

| Resource | URL | Type |
|----------|-----|------|
| Shadcn Blocks | https://ui.shadcn.com/blocks | Official blocks |
| Shadcn Charts | https://ui.shadcn.com/charts | Chart wrappers |
| Origin UI | https://originui.com | Component library |
| Tremor | https://tremor.so | Dashboard components |
| Tremor Blocks | https://blocks.tremor.so | Dashboard blocks |
| Shadcnblocks.com | https://www.shadcnblocks.com | Block marketplace |
| Shadboard | https://github.com/Qualiora/shadboard | Dashboard template |
| Nivo | https://nivo.rocks | Advanced charts |
| React Grid Layout | https://github.com/react-grid-layout/react-grid-layout | Dashboard grid |
| AG Grid | https://www.ag-grid.com | Data grid |
| Catalyst | https://catalyst.tailwindui.com | Tailwind Labs UI kit |
| Park UI | https://park-ui.com | Ark UI components |
| Mantine | https://mantine.dev | Full component library |

---

## My Notes

### Key Takeaways

1. **SNDQ's Shadcn/Briicks foundation is strong** — don't switch to Mantine or any full library. The copy-paste approach maintains design system control.

2. **Origin UI is the biggest unlocked value** — 473+ free components with the exact same stack. Should be the first reference when building any new component.

3. **Tremor's value is in patterns, not code** — copy the dashboard composition patterns (KPI card + chart + filter layout) rather than installing `@tremor/react`.

4. **Nivo fills a real gap** — Recharts cannot do heatmaps, treemaps, or sankey diagrams. When advanced visualization is needed, Nivo is the answer.

5. **React Grid Layout is a future differentiator** — customizable dashboards are a premium feature that distinguishes modern SaaS platforms. Plan for it but don't rush implementation.

6. **AG Grid is a trap** — tempting features but breaks design consistency. TanStack Table with Briicks styling is the right path for SNDQ.

### Briicks Color Mapping Guide

When adapting any external block/component, use this mapping:

| External Token | Briicks Equivalent |
|----------------|-------------------|
| `bg-primary` | `bg-brand-500` |
| `bg-secondary` | `bg-neutral-100` |
| `text-primary` | `text-brand-500` |
| `text-muted-foreground` | `text-neutral-500` |
| `bg-muted` | `bg-neutral-50` |
| `border` | `border` (pre-configured) |
| `bg-white` | `bg-neutral-0` |
| `bg-destructive` | `bg-error-500` |
| `text-destructive` | `text-error-500` |
| `bg-green-*` / `bg-emerald-*` | `bg-success-*` |
| `bg-yellow-*` / `bg-amber-*` | `bg-warning-*` |
| `rounded-lg` | `rounded-md` |

### What NOT to Do

- ❌ Don't install `@tremor/react` as a dependency — copy patterns instead
- ❌ Don't replace TanStack Table with AG Grid for regular tables
- ❌ Don't switch to Mantine — SNDQ's investment in Shadcn/Briicks is the right path
- ❌ Don't copy blocks without adapting to Briicks design tokens
- ❌ Don't add Nivo for charts that Recharts already handles well
- ❌ Don't add React Grid Layout until a customizable dashboard feature is planned
