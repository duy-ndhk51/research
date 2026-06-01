# UI-V2-Dev Routing Restructure

Restructure `apps/ui-v2-dev` from a single-page tab-based architecture to Next.js App Router route-based code splitting.

**Created**: 2026-05-20
**Status**: Complete
**Branch**: `feat/SQ-21402`

---

## Problem

The original `apps/ui-v2-dev` rendered everything through a single client component (`ShowcasePage`) that switched between 15+ tabs via `?tab=` query params. All ~1,100 source files contributed to a single JS bundle. As the codebase grew, initial load and hot-reload times degraded linearly.

---

## Outcome

Converted to a route-based architecture with:

- Automatic code splitting per category
- `CategoryBrowserLayout` as the standard sidebar navigation for all browsable pages
- External libraries (Coss UI, Tremor) under `/integrations/` with their own browsing UIs
- Deep-linkable URLs (`/primitives/button`, `/blocks/sndq/building`, `/blocks/forms/contact`)

All routes with browsable categories use the `CategoryBrowserLayout` pattern:

```
route/
├── data/{route}Categories.ts       # CategoryGroup[], CategoryItem[], section loaders
├── components/{Route}Content.tsx    # Lazy-loads component by categoryId
├── layout.tsx                       # CategoryBrowserLayout wrapper
├── page.tsx                         # Redirects to default category
└── [param]/page.tsx                 # Validates param, renders content component
```

---

## Documents

| File | Purpose |
|------|---------|
| [execution.md](./execution.md) | Step-by-step commit log (13/13 complete) |
| [AGENTS.md](./AGENTS.md) | Agent guidance — route structure, constraints, patterns |

---

## URL Mapping

| Old tab/route | Current route |
|---------------|---------------|
| `/?tab=overview` | `/` |
| `/?tab=components` | `/primitives/button` |
| `/?tab=cell` | `/primitives/row` |
| `/?tab=blocks` | `/blocks/ui-v2` |
| `/?tab=sndq-blocks` | `/blocks/sndq/building` |
| `/?tab=composable` | `/blocks/composable/financial` |
| `/?tab=forms` | `/blocks/forms/contact` |
| `/?tab=table` | `/blocks/tables` |
| `/?tab=filter` | `/blocks/filters` |
| `/?tab=metric` | `/blocks/metrics` |
| `/?tab=sheet` | `/blocks/sheets/breakdown` |
| `/?tab=coss` | `/integrations/coss` |
| `/?tab=tremor-blocks` | `/integrations/tremor` |
| `/?tab=identity` | `/foundations/identity` |
| `/?tab=foundation` | `/foundations/tokens` |
| `/particles` | `/integrations/coss` (merged) |
