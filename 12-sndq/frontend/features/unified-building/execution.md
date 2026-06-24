# Unified Building Execution — A/B Opt-In & Shell Layout

Step-by-step execution guide for the unified building feature. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-22
**Status**: In progress — Commit 7 done
**Architecture**: [overview.md](./overview.md)
**Branch**: `feature/unified-building`

> **IMPORTANT**: Do NOT automatically commit after each step. Implement each commit's changes, then stop and wait for manual review and testing. Only commit after explicit approval.
>
> **STATUS TRACKING**: After completing each commit's implementation, automatically update this file:
> 1. Check off the completed items in that commit's **Status** checklist
> 2. Record the date and any notes in the **Execution Log** table at the bottom
> 3. Update the top-level **Status** field (e.g., "In progress — Commit 3 done")
> This keeps the plan as the single source of truth for progress.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Foundation Types & Hooks](#3-pr-1--foundation-types--hooks)
4. [PR 2 — Opt-In Dialog & Sidebar Integration](#4-pr-2--opt-in-dialog--sidebar-integration)
5. [PR 3 — Routes & Building Shell Layout](#5-pr-3--routes--building-shell-layout)
6. [Final Verification](#6-final-verification)
7. [Team Communication](#7-team-communication)
8. [What's Next](#8-whats-next)
9. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Gate the new unified building experience behind `NEXT_PUBLIC_APP_ENV` (non-production only) and per-user opt-in, add the building shell layout with sidebar navigation, and wire everything into the main sidebar and personal settings — without implementing any section content.

**Structure**: 7 commits across 3 PRs.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Types, localStorage hooks, feature gate hook (using `NEXT_PUBLIC_APP_ENV`), nav constants, route paths | Low | 1–2 |
| **PR 2** | Opt-in dialog, sidebar "Buildings" tab, personal settings toggle | Medium | 3–5 |
| **PR 3** | Route structure, buildings list placeholder, building shell layout | Medium | 6–7 |

**Why 3 PRs**: PR 1 is pure types and hooks with zero UI changes — nothing consumes them yet, so it is safe to merge independently. PR 2 introduces the first user-visible behavior (dialog + sidebar), keeping it isolated from the routing work. PR 3 adds the new route group and shell layout, which depends on PR 1's hooks and constants but is independently verifiable.

### Prerequisites

- `sndq-fe` dev server runs without errors (`pnpm dev`)
- `@sndq/ui-v2` workspace package is resolved (`"@sndq/ui-v2": "workspace:*"` in `package.json`)
- `@radix-ui/react-dialog` is already installed (used by `@/components/ui/dialog`)
- `@radix-ui/react-switch` is already installed (used by `@/components/ui/switch`)

### Known constraints

- Environment gate uses `IS_PRODUCTION_ENV` from `@/constants/appEnv` — feature enabled when `!IS_PRODUCTION_ENV`; no new env var or `.env.example` change
- BE does not support `syndicNavigationEnabled` yet — all persistence is via localStorage with a TanStack Query abstraction layer for easy migration later
- The `@sndq/ui-v2` package does not export a Dialog component — use `@/components/ui/dialog` (shadcn) for the opt-in dialog
- The icon name `'building'` already exists in the sidebar icon map (used by Patrimony item) — reuse it for the new "Buildings" tab
- The feature must only be visible to syndic workspaces (`useWorkspaceType().isSyndic`) — owner and third-party workspaces are unaffected
- No section content is implemented in this ticket — all sections render placeholders

---

## 2. Before You Start

### Quality gate before each implementation commit

Use this gate for every implementation commit. If an item is intentionally skipped, record it under that commit's **Deviations from the gate** section.

- [ ] Public API / behavior is stable for this commit scope
- [ ] Public props, types, functions, or commands have minimal useful documentation where applicable
- [ ] Existing project helpers and patterns are reused instead of introducing one-off abstractions
- [ ] Tests or documented manual checks cover the main behavior and likely regressions
- [ ] No unrelated files, app-specific imports, or ownership-boundary leaks are introduced
- [ ] Security-sensitive values, credentials, generated secrets, and local env files are not committed
- [ ] Build, lint, type-check, and any targeted verification commands are known before editing
- [ ] Any skipped verification is recorded as a deviation with a follow-up owner or trigger

### Documentation and comment policy

- Keep code comments minimal and focused on intent, invariants, or non-obvious behavior.
- Put usage examples, migration notes, variant tables, setup steps, and operational runbooks in docs, not inline code comments.
- Add deprecation notices only on the public export or entry point that consumers actually use.
- If docs and code disagree, update the docs in the same commit or record the gap as a deviation.

### Inspect source tree before implementation

Before the first implementation commit, inspect the actual repository state and record any differences from this plan.

- [ ] Confirm `src/common/types/` folder exists and is the right place for shared types
- [ ] Confirm `src/hooks/` is used for shared hooks (e.g., `useUserProfile.ts`, `useWorkspaceType.ts` already live there)
- [ ] Confirm `src/modules/` is the target for feature modules (e.g., `personal-settings/`, `patrimony/`)
- [ ] Confirm `src/app/(dashboard)/` is the route group for authenticated pages
- [ ] Confirm `src/components/layout/main-layout/side-bar/Sidebar.tsx` has the items array at ~line 32
- [ ] Confirm `src/modules/personal-settings/InfoSidebar.tsx` is the right file for the settings toggle
- [ ] Confirm `src/common/constants/system.ts` exports `routerPaths` with existing route definitions
- [ ] Confirm `@/components/ui/dialog` exports `Dialog`, `DialogContent`, `DialogHeader`, `DialogFooter`, `DialogTitle`, `DialogDescription`
- [ ] Confirm `@/components/ui/switch` exports `Switch`
- [ ] Confirm `useWorkspaceType()` returns `{ isSyndic, isSteward, isOwner, isThirdParty }`
- [ ] Confirm `useAuth()` returns `{ user }` with `user.id` available
- [ ] Confirm `NEXT_PUBLIC_APP_ENV` is referenced in deployment config (no `.env.example` change needed)
- [ ] Confirm `pnpm dev`, `pnpm lint`, `pnpm tsc` commands work
- [ ] Confirm current lint or type-check failures that predate this feature

### Capture baselines

Run these from `sndq-fe/` and save the output. Diff against these after risky commits.

```bash
cd sndq-fe
pnpm tsc --noEmit 2>&1 | tail -5 | tee /tmp/unified-building-tsc-before.txt
pnpm lint 2>&1 | tail -5 | tee /tmp/unified-building-lint-before.txt
```

### Create branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/unified-building
```

---

## 3. PR 1 — Foundation Types & Hooks

Pure types and hooks with zero UI changes. Creates the user settings types mirroring the BE DTO, the localStorage-backed TanStack Query hooks (fake server layer), the composite feature gate hook, and navigation constants. Safe to merge independently because nothing consumes these yet.

---

### Commit 1: User settings types and localStorage-backed hooks

**What**: Create the `UserSettings` types mirroring the BE `UserSettingsResponseDto` and `SyndicNavigationConfig`, then build TanStack Query hooks that read/write localStorage as a fake server layer.

**Files to create**:

- `src/common/types/user-settings.ts` — types mirroring `UserSettingsResponseDto`, `SyndicNavigationConfig`, `BuildingNavigationKey`, `FinancialNavigationKey` from the BE

```typescript
export type BuildingNavigationKey =
  | 'UNITS' | 'OWNERS' | 'METERS' | 'DISTRIBUTIONKEYS'
  | 'MEETINGS' | 'BROADCASTS' | 'DOCUMENTS' | 'FACILITIES'
  | 'TASKS' | 'REQUESTS' | 'NOTES' | 'QUOTES';

export type FinancialNavigationKey =
  | 'BOOKKEEPING' | 'CHARTOFACCOUNTS' | 'DAYBOOKS' | 'BANKACCOUNTS'
  | 'INVOICES' | 'FEEINVOICES' | 'PAYMENTINITIATIONS'
  | 'PROVISIONSANDCOSTS' | 'SUPPLIERS' | 'FISCALYEAR' | 'OPENINGDATA';

export interface SyndicNavigationConfig {
  sidebar?: {
    building?: BuildingNavigationKey[];
    financial?: FinancialNavigationKey[];
  };
}

export interface UserSettings {
  id: string;
  userId: string;
  syndicNavigationConfig?: SyndicNavigationConfig | null;
  syndicNavigationEnabled?: boolean | null;
  createdAt: string;
  updatedAt: string;
}
```

- `src/hooks/useUserSettings.ts` — query key factory, `useUserSettings()` via `useQuery`, `useUpdateSyndicNavigation()` via `useMutation`, both backed by `localStorage('sndq:user-settings')`

```typescript
export const userSettingsKeys = {
  all: () => ['userSettings'] as const,
  detail: () => [...userSettingsKeys.all(), 'me'] as const,
};

// useUserSettings() — reads from localStorage for authenticated user (via useAuth), returns UserSettings | null
// useUpdateSyndicNavigation() — writes syndicNavigationEnabled to localStorage, invalidates query
```

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Types match the BE `UserSettingsResponseDto` and `SyndicNavigationConfig` exactly
- [x] Hook follows the project's query key factory pattern (see `usePurchaseInvoices.ts`)
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Type mismatch with future BE response | LOW | Types mirror the existing BE DTO; when BE ships, verify field names match |
| localStorage not available in SSR | LOW | Hooks are client-side only (`'use client'` components); `queryFn` guards with `typeof window !== 'undefined'` |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec eslint src/common/types/user-settings.ts src/hooks/useUserSettings.ts
```

**If it fails**:

- **"Cannot find module '@tanstack/react-query'"**: Verify import path; `@tanstack/react-query` is already in `package.json` dependencies
- **"Type 'string' is not assignable to type 'Date'"**: Use `string` for `createdAt`/`updatedAt` since localStorage serializes dates as strings; the BE migration will handle `Date` parsing

**Deviations from the gate**:

- **No runtime test** — hooks are not consumed yet; runtime behavior will be tested in commits 3–5

**Commit message**: `feat: add user settings types and localStorage-backed hooks`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [x] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 2: Feature gate hook and navigation constants

**What**: Create the composite `useUnifiedBuildingFeature()` hook that composes the environment gate (`!IS_PRODUCTION_ENV`), workspace type check, and user opt-in state into a single boolean. Also create the navigation constants ported from the prototype and add route paths to `routerPaths`.

**Files to create**:

- `src/constants/appEnv.ts` — shared env gate constant:

```typescript
export const IS_PRODUCTION_ENV =
  process.env.NEXT_PUBLIC_APP_ENV === 'production';
```

- `src/modules/unified-building/hooks/useUnifiedBuildingFeature.ts`

```typescript
import { IS_PRODUCTION_ENV } from '@/constants/appEnv';

interface UnifiedBuildingFeature {
  isEligible: boolean;         // !IS_PRODUCTION_ENV && isSyndic
  isEnabled: boolean;          // eligible + syndicNavigationEnabled === true
  shouldShowOptIn: boolean;    // eligible + not yet interacted + not yet decided
  syndicNavigationEnabled: boolean | null | undefined;
  updateSyndicNavigation: (enabled: boolean) => void;
}
```

UI call sites gate experiment UI via `useUnifiedBuildingFeature().isExperimentAvailable` (non-production + syndic) — do not duplicate `!IS_PRODUCTION_ENV && isSyndic` at call sites.

- `src/modules/unified-building/constants/navigation.ts` — `ALL_SECTIONS`, `OVERVIEW_ITEM`, `DEFAULT_PINNED`, ported from prototype `building-shell.tsx` lines 180–214. Uses lucide-react icons instead of hard-coded icon components.

**Files to edit**:

- `src/common/constants/system.ts` — add to `routerPaths`:

```typescript
buildings: {
  root: '/buildings',
  detail: (buildingId: string) => `/buildings/${buildingId}`,
  section: (buildingId: string, section: string) => `/buildings/${buildingId}/${section}`,
},
```

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] `useUnifiedBuildingFeature` returns sensible defaults on production (`NEXT_PUBLIC_APP_ENV='production'`)
- [x] Navigation constants match the prototype's section IDs and grouping
- [x] Route paths follow existing `routerPaths` patterns
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `IS_PRODUCTION_ENV` in `src/constants/appEnv.ts` inlined at build time | LOW | Next.js inlines `NEXT_PUBLIC_*`; import the constant where needed instead of duplicating the check |
| Navigation constant IDs drift from prototype | LOW | Compare against `ALL_SECTIONS` in `building-shell.tsx` line 180 |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec eslint src/modules/unified-building/ src/common/constants/system.ts
```

**If it fails**:

- **"Cannot find module 'lucide-react'"**: Already in `package.json` — verify import path
- **"Property 'buildings' does not exist on type..."**: Verify the `routerPaths` object structure allows adding a new top-level key

**Deviations from the gate**:

- **No runtime test** — hook and constants are not consumed yet; tested in PR 2

**Commit message**: `feat: add feature gate hook and navigation constants`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [x] Manual verification complete, if applicable
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI to pass before continuing.

```bash
git push -u origin feature/unified-building
# Create PR targeting develop
# Wait for CI to complete successfully
```

**This validates**: Types compile, hooks follow project patterns, navigation constants are well-typed, route paths integrate cleanly into `routerPaths`.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] No existing behavior changed — hooks and constants are not consumed yet
- [ ] Rollback: revert the 2 commits; no runtime impact

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. PR 2 — Opt-In Dialog & Sidebar Integration

User-facing changes: the one-time opt-in dialog, the conditional "Buildings" sidebar tab, and the personal settings toggle. This is the PR that introduces new behavior visible to syndic users on staging.

---

### Commit 3: Opt-in dialog component

**What**: Create the `UnifiedBuildingOptInDialog` component using `@/components/ui/dialog` (shadcn). The dialog shows once for syndic users on non-production environments when they haven't interacted yet. Mount it in `MainLayout`.

**Files to create**:

- `src/modules/unified-building/components/UnifiedBuildingOptInDialog.tsx`

Uses `Dialog`, `DialogContent`, `DialogHeader`, `DialogTitle`, `DialogDescription`, `DialogFooter` from `@/components/ui/dialog`. UI reference: `OptInAffordance.tsx` from the prototype — branded card with sparkles icon, title, description, "Try it" (primary) and "Maybe later" (secondary) buttons.

Key behavior:
- Reads `useUnifiedBuildingFeature().shouldShowOptIn` to determine visibility
- On "Try it": calls `updateSyndicNavigation(true)` + sets `localStorage('sndq:unified-building-opt-in-interacted', 'true')`
- On "Maybe later": only sets the localStorage interacted key
- Uses `Dialog` controlled mode (`open` / `onOpenChange`)

**Files to edit**:

- `src/components/layout/main-layout/MainLayout.tsx` — import and render `<UnifiedBuildingOptInDialog />` inside the authenticated layout, after the `<Sidebar />` and `<TopLayout />` block. The dialog is self-gating (checks env gate internally), so no conditional wrapper needed in `MainLayout`.

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Dialog does not render on production env (verify in DevTools)
- [x] Dialog does not render for non-syndic workspaces
- [x] Dialog does not re-appear after interaction (verify localStorage key)
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Dialog renders on every page load instead of once | MEDIUM | Verify `shouldShowOptIn` correctly reads the localStorage interacted key |
| Dialog z-index conflicts with TopLoader or other modals | LOW | shadcn Dialog uses `z-50`; verify no overlap with `NextTopLoader` |
| MainLayout import increases bundle for non-syndic users | LOW | Dialog component is small; consider `next/dynamic` if bundle impact is measurable |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec eslint src/modules/unified-building/components/UnifiedBuildingOptInDialog.tsx src/components/layout/main-layout/MainLayout.tsx
```

Manual:
1. Ensure `NEXT_PUBLIC_APP_ENV` is not `'production'` (staging or local dev)
2. Log in as syndic workspace
3. Verify dialog appears
4. Click "Maybe later" — dialog closes, does not reappear on refresh
5. Clear `sndq:unified-building-opt-in-interacted` from localStorage
6. Refresh — dialog appears again
7. Click "Try it" — dialog closes, `sndq:user-settings` in localStorage has `syndicNavigationEnabled: true`

**If it fails**:

- **"Dialog doesn't appear"**: Check that `shouldShowOptIn` is `true` — verify `NEXT_PUBLIC_APP_ENV` is not `'production'`, workspace is syndic, and localStorage interacted key is absent
- **"Dialog appears for non-syndic workspace"**: Verify `useWorkspaceType().isSyndic` is correctly checked in `useUnifiedBuildingFeature`
- **"Cannot find module '@/components/ui/dialog'"**: Verify the dialog file exports match the import names

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add unified building opt-in dialog`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [x] Manual verification complete
- [ ] Committed

---

### Commit 4: Sidebar "Buildings" tab

**What**: Conditionally prepend a "Buildings" item as the first sidebar entry when the user has opted in. Uses `useUnifiedBuildingFeature().isEnabled` to gate visibility.

**Files to edit**:

- `src/components/layout/main-layout/side-bar/Sidebar.tsx`
  - Import `useUnifiedBuildingFeature` from `@/modules/unified-building/hooks/useUnifiedBuildingFeature`
  - Call the hook inside the component
  - Conditionally prepend a `SidebarItemType` with `{ href: routerPaths.buildings.root, icon: 'building', label: t('properties.building') }` to the `items` array when `isEnabled` is `true`

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] "Buildings" tab only appears when all 3 gates pass (flag + syndic + opted in)
- [x] Existing sidebar items are unchanged when feature is off
- [x] Navigation to `/buildings` works (even if page doesn't exist yet — will 404 until PR 3)
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Hook call in Sidebar causes extra re-renders | LOW | `useUnifiedBuildingFeature` reads from TanStack Query cache — minimal overhead |
| `'building'` icon name doesn't exist | LOW | Already used by the existing Patrimony item at line 40 of `Sidebar.tsx` |
| Sidebar items array mutation | LOW | Use spread operator to prepend, not `unshift` |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec eslint src/components/layout/main-layout/side-bar/Sidebar.tsx
```

Manual:
1. Staging env + syndic + opted in: "Buildings" appears as first sidebar item
2. Production env: no "Buildings" tab, existing sidebar unchanged
3. Staging env + non-syndic: no "Buildings" tab
4. Staging env + syndic + not opted in: no "Buildings" tab
5. Click "Buildings" tab: navigates to `/buildings`

**If it fails**:

- **"Buildings tab appears for non-syndic"**: Verify `isEnabled` checks all 3 gates
- **"Sidebar crashes"**: Verify hook is called unconditionally (not inside a conditional block) — React hooks rules

**Deviations from the gate**:

- **Navigation target may 404** — `/buildings` route is created in PR 3; during PR 2 review, clicking the tab will show a 404 page. This is acceptable for isolated PR testing.

**Commit message**: `feat: add conditional Buildings tab to sidebar`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

### Commit 5: Personal settings toggle

**What**: Add a "Feature Preview" section to `InfoSidebar.tsx` with a `Switch` toggle for the unified building experience. Only visible on non-production environments and syndic workspaces.

**Files to edit**:

- `src/modules/unified-building/hooks/useUnifiedBuildingFeature.ts`
  - Export `isExperimentAvailable` and `syndicNavigationEnabled` from the hook return (already computed internally)
- `src/modules/personal-settings/InfoSidebar.tsx`
  - Import `Switch` from `@/components/briicks/selectors/switch`
  - Import `useUnifiedBuildingFeature` from `@/modules/unified-building/hooks/useUnifiedBuildingFeature`
  - Import `Caption`, `Paragraph` from `@/components/briicks/text`
  - Add a new section between "Account security" and the footer, gated by `isExperimentAvailable`:

```tsx
{isExperimentAvailable && (
  <div className="gap-1 border-t border-gray-200 p-2">
    <div className="flex w-full items-center justify-between px-2 py-1">
      <Heading size="medium">Feature Preview</Heading>
    </div>
    <div className="flex items-center justify-between px-2 py-2">
      <div>
        <Paragraph variant="label">Buildings view</Paragraph>
        <Caption>Try the unified building layout with everything in one place.</Caption>
      </div>
      <Switch
        checked={syndicNavigationEnabled === true}
        onCheckedChange={(checked) => setBuildingsFlowEnabled(checked)}
      />
    </div>
  </div>
)}
```

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Toggle section only appears on non-production env + syndic workspace
- [x] Toggle ON sets `syndicNavigationEnabled: true` and "Buildings" tab appears
- [x] Toggle OFF sets `syndicNavigationEnabled: false` and "Buildings" tab disappears
- [x] Existing sections in InfoSidebar are unchanged
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Translation keys don't exist yet | MEDIUM | Add temporary English-only keys or use hardcoded strings with a follow-up to add proper i18n |
| Switch state doesn't sync with sidebar | LOW | Both read from the same TanStack Query cache via `useUserSettings` — invalidation triggers re-render |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec eslint src/modules/unified-building/hooks/useUnifiedBuildingFeature.ts src/modules/personal-settings/InfoSidebar.tsx
```

Manual:
1. Staging env + syndic: "Feature Preview" section visible in personal settings
2. Toggle ON: "Buildings" tab appears in sidebar
3. Toggle OFF: "Buildings" tab disappears from sidebar
4. Production env: "Feature Preview" section not visible
5. Non-syndic workspace: "Feature Preview" section not visible

**If it fails**:

- **"Switch doesn't toggle"**: Verify `onCheckedChange` calls `updateSyndicNavigation` and that the mutation invalidates the query
- **"Missing translation key"**: If using `t('settings.feature_preview')`, add the key to `messages/en/settings.json` or use a hardcoded string temporarily

**Deviations from the gate**:

- **Translation keys hardcoded** — English-only copy; follow-up to add en/fr/nl/de i18n keys
- **Briicks Switch** — uses `@/components/briicks/selectors/switch` (not shadcn `@/components/ui/switch`) to match personal-settings patterns
- **Hook API** — `isExperimentAvailable`, `setBuildingsFlowEnabled` replace doc's inline env gate and `updateSyndicNavigation`

**Commit message**: `feat: add unified building toggle to personal settings`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### PR 2 Checkpoint

Push PR 2 and wait for CI to pass before continuing.

```bash
git push origin feature/unified-building
# Create PR targeting develop (or update existing PR)
# Wait for CI to complete successfully
```

**This validates**: Dialog renders and tracks interaction correctly. Sidebar tab appears/disappears based on opt-in state. Personal settings toggle syncs with sidebar via TanStack Query cache.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Dialog: appears once for syndic, tracks interaction, "Try it" enables, "Maybe later" dismisses
- [ ] Sidebar: "Buildings" tab appears/disappears correctly
- [ ] Settings: toggle syncs with sidebar
- [ ] Production env: zero visible changes
- [ ] Rollback instructions are clear

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 5. PR 3 — Routes & Building Shell Layout

New route group and the building shell layout with sidebar navigation. Depends on PR 1's navigation constants and hooks.

---

### Commit 6: Route structure and buildings list placeholder

**What**: Create the route file structure under `src/app/(dashboard)/buildings/` with placeholder pages. The buildings list page shows a simple placeholder. The `[buildingId]` page redirects to the overview section.

**Files to create**:

- `src/app/(dashboard)/buildings/page.tsx` — placeholder buildings list page with `useTranslations('buildings')` for title and under-construction message. Uses `'use client'` and briicks `Heading` / `Paragraph`.

- `src/app/(dashboard)/buildings/[buildingId]/page.tsx` — redirect to overview section:

```typescript
'use client';
import { useParams, useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { routerPaths } from '@/common/constants/system';

export default function BuildingDetailPage() {
  const params = useParams<{ buildingId: string }>();
  const router = useRouter();
  useEffect(() => {
    if (params.buildingId) {
      router.replace(routerPaths.buildings.section(params.buildingId, 'overview'));
    }
  }, [params.buildingId, router]);
  return null;
}
```

- `src/app/(dashboard)/buildings/[buildingId]/[...section]/page.tsx` — placeholder section page that reads the section slug from params, resolves label via `OVERVIEW_ITEM` / `ALL_SECTIONS`, and displays under-construction message via `buildings.section_under_construction`.

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Navigating to `/buildings` renders the placeholder list
- [x] Navigating to `/buildings/[id]` redirects to `/buildings/[id]/overview`
- [x] Navigating to `/buildings/[id]/units` renders the section placeholder
- [x] No existing routes are affected
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Route group conflict with existing `(dashboard)` routes | LOW | New `/buildings` path doesn't overlap with `/patrimony/buildings` |
| Catch-all `[...section]` interferes with `[buildingId]` | LOW | Next.js resolves `[buildingId]/page.tsx` before `[buildingId]/[...section]/page.tsx` |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec eslint src/app/\(dashboard\)/buildings/
```

Manual:
1. Navigate to `/buildings` — placeholder list renders
2. Navigate to `/buildings/test-id` — redirects to `/buildings/test-id/overview`
3. Navigate to `/buildings/test-id/units` — section placeholder renders with "units" label
4. Navigate to `/patrimony/buildings` — existing page still works

**If it fails**:

- **"404 on /buildings"**: Verify the file is at `src/app/(dashboard)/buildings/page.tsx` (inside the `(dashboard)` route group)
- **"Redirect loop"**: Verify the `[buildingId]/page.tsx` redirect checks `params.buildingId` before redirecting

**Deviations from the gate**:

- **No access control on routes** — any authenticated user can navigate to `/buildings` via URL. The sidebar tab is gated, but the route itself is not. Acceptable for staging A/B testing; add route-level guards in a follow-up if needed.
- **i18n via `buildings` namespace** — list and section placeholders use `messages/{locale}/buildings.json` keys (`list_title`, `list_under_construction`, `section_under_construction`) instead of hardcoded English

**Commit message**: `feat: add buildings route structure with placeholder pages`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### Commit 7: Building shell layout and sidebar component

**What**: Create the `BuildingShellSidebar` component (left nav with building/financial groups and "More" popover) and the shell layout that composes it with the content area. Based on the prototype's `building-shell.tsx` lines 348–474.

**Files to create**:

- `src/modules/unified-building/components/BuildingShellSidebar.tsx`

Left sidebar component (240px wide) with:
- "All buildings" back link (to `/buildings`)
- Building name header with icon and fiscal year badge
- Nav groups (Building / Financial) with icons from `ALL_SECTIONS` constant
- Active state highlighting based on current section from URL params
- "More" popover (using `@sndq/ui-v2` `Popover`, `PopoverTrigger`, `PopoverContent`) for unpinned items
- "Customize sidebar" button in the popover footer (placeholder, no action yet)

Uses:
- `@sndq/ui-v2/components` — `Text`, `Heading`, `Button`, `Badge`, `Popover`, `PopoverTrigger`, `PopoverContent`
- `lucide-react` — `ArrowLeft`, `Building2`, `MoreHorizontal`, `SlidersHorizontal`, and section-specific icons
- `@sndq/ui-v2/cn` — `cn()` for class merging
- Navigation constants from `@/modules/unified-building/constants/navigation`

Props:
```typescript
interface BuildingShellSidebarProps {
  buildingId: string;
  buildingName: string;
  fiscalYear: string;
  fiscalYearStatus: 'open' | 'closed';
  currentSection: string;
}
```

- `src/app/(dashboard)/buildings/[buildingId]/layout.tsx` — shell layout that renders `BuildingShellSidebar` + `{children}`:

```tsx
'use client';
export default function BuildingShellLayout({ children, params }) {
  // Read buildingId from params
  // For now, use placeholder building data (name, fiscal year)
  // Later: fetch real building data from API
  return (
    <div className="flex h-full">
      <BuildingShellSidebar
        buildingId={buildingId}
        buildingName="Building Name"
        fiscalYear="2024"
        fiscalYearStatus="open"
        currentSection={currentSection}
      />
      <main className="flex-1 overflow-y-auto">{children}</main>
    </div>
  );
}
```

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Shell sidebar renders all nav groups from `ALL_SECTIONS`
- [x] Active section is highlighted based on URL
- [x] "More" popover opens and shows unpinned items
- [x] Back link navigates to `/buildings`
- [x] Shell layout composes sidebar + content area correctly
- [x] No unrelated imports or ownership-boundary leaks
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `@sndq/ui-v2` Popover API differs from prototype's `@sndq/ui-v2/components/popover` | MEDIUM | Verify Popover exports `Popover`, `PopoverTrigger`, `PopoverContent` with `side` and `align` props |
| Building data is hardcoded (no API yet) | LOW | Acceptable for shell-only scope; replace with real data in future tickets |
| Shell layout doesn't fill available height | LOW | Use `h-full` on the flex container; verify with browser DevTools |
| Section param reading from catch-all route | LOW | `useParams()` returns `{ section: string[] }`; read `section[0]` for the current section ID |

**Verification**:

```bash
pnpm tsc --noEmit
pnpm exec eslint src/modules/unified-building/components/BuildingShellSidebar.tsx src/app/\(dashboard\)/buildings/\[buildingId\]/layout.tsx
```

Manual:
1. Navigate to `/buildings/test-id/overview` — shell renders with sidebar and placeholder content
2. Sidebar shows "Building Name" header with fiscal year badge
3. Click "Units" in sidebar — navigates to `/buildings/test-id/units`, section highlights
4. Click "Bookkeeping" under Financial — navigates correctly
5. Click "More" — popover opens showing unpinned items
6. Click "All buildings" back link — navigates to `/buildings`
7. Resize window — sidebar stays 240px, content area fills remaining space

**If it fails**:

- **"Popover doesn't open"**: Verify `@sndq/ui-v2` Popover is correctly imported and `open`/`onOpenChange` state is managed
- **"Section not highlighted"**: Verify `currentSection` matches the URL segment; check `useParams()` returns the correct shape for catch-all routes
- **"Layout doesn't fill height"**: Add `h-full` to the shell container and verify parent layout (`DashboardLayout > MainLayout`) doesn't constrain height

**Deviations from the gate**:

- **Building data is hardcoded** — building name, fiscal year, and status are placeholder strings. Real data fetching will be implemented when building detail sections are built.
- **Customize sidebar is a no-op** — the "Customize sidebar" button in the More popover doesn't open anything yet. Drag-and-drop reorder and pin/unpin persistence are out of scope.
- **Shell chrome i18n** — back link, group labels, More/customize, fiscal year status use `buildings` namespace; section labels remain English from `navigation.ts`
- **Static `DEFAULT_PINNED`** — no localStorage pin/order persistence this commit

**Commit message**: `feat: add building shell layout with sidebar navigation`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete
- [ ] Committed

---

### PR 3 Checkpoint

Push PR 3 and wait for CI to pass.

```bash
git push origin feature/unified-building
# Create PR targeting develop (or update existing PR)
# Wait for CI to complete successfully
```

**This validates**: Full feature works end-to-end — opt-in dialog, sidebar tab, navigation to buildings list, building shell with sidebar nav, section navigation.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] Route structure works: `/buildings`, `/buildings/[id]` (redirects), `/buildings/[id]/[section]`
- [ ] Shell sidebar shows building/financial groups with icons
- [ ] Active section highlights correctly
- [ ] More popover works
- [ ] No regressions on existing routes
- [ ] Rollback instructions are clear

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 6. Final Verification

After all 7 commits, run the full suite from `sndq-fe/`:

```bash
pnpm tsc --noEmit
pnpm lint
pnpm build
```

Compare against baselines:

```bash
diff /tmp/unified-building-tsc-before.txt <(pnpm tsc --noEmit 2>&1 | tail -5)
diff /tmp/unified-building-lint-before.txt <(pnpm lint 2>&1 | tail -5)
```

**Manual verification**:

- [ ] Production env (`NEXT_PUBLIC_APP_ENV='production'`): zero visible changes — no dialog, no "Buildings" tab, no new routes
- [ ] Staging env + non-syndic: zero visible changes
- [ ] Staging env + syndic + first visit: dialog appears
- [ ] Dialog "Try it": opt-in stored, "Buildings" tab appears in sidebar
- [ ] Dialog "Maybe later": dialog dismissed, won't reappear
- [ ] Sidebar "Buildings" tab navigates to `/buildings`
- [ ] Buildings list page renders placeholder
- [ ] Click building navigates to `/buildings/[id]/overview`
- [ ] Shell sidebar shows building + financial nav groups with correct icons
- [ ] Active section highlighted, nav links work
- [ ] "More" popover shows unpinned items
- [ ] Personal settings toggle: ON/OFF syncs with sidebar
- [ ] Page refresh preserves opt-in state
- [ ] Existing patrimony, financial, and other routes are unaffected
- [ ] No console errors or warnings related to new components

**Expected result**: The unified building infrastructure is fully wired — environment-gated (non-production only), opt-in gated, with a working shell layout. All section content areas show placeholders. The feature is invisible on production or when the user hasn't opted in.

**Final status**:

- [ ] All 7 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes
- [ ] Tests pass or missing coverage is documented
- [ ] Manual verification complete
- [ ] All PRs created and merged, or ready for merge

---

## 7. Team Communication

Send to the team before merging PR 2 (the first PR with user-visible changes):

> **Heads up: Unified building A/B opt-in for syndic workspaces (staging only)**
>
> PR [link] adds a feature-flagged, per-user opt-in for the new unified building experience. On non-production environments (`NEXT_PUBLIC_APP_ENV !== 'production'`), syndic users see a one-time dialog. Opting in adds a "Buildings" tab to the sidebar and opens a new building shell layout.
>
> After pulling:
>
> 1. Run `pnpm install` (no new dependencies expected)
> 2. Ensure `NEXT_PUBLIC_APP_ENV` is not set to `'production'` in `.env` (default local dev is fine)
> 3. Restart dev server
>
> Files that changed and may conflict:
> - `src/components/layout/main-layout/MainLayout.tsx` (dialog mount)
> - `src/components/layout/main-layout/side-bar/Sidebar.tsx` (conditional "Buildings" item)
> - `src/modules/personal-settings/InfoSidebar.tsx` (feature preview toggle)
> - `src/common/constants/system.ts` (route paths)
>
> Known follow-ups:
> - Section content (units, owners, financial, etc.) will be implemented in future tickets
> - BE `syndicNavigationEnabled` API will replace localStorage when ready
> - Translation keys for "Feature Preview" section may need i18n review
> - Route-level access control (redirect non-syndic users from `/buildings`) is not yet implemented

---

## 8. What's Next

After the unified building shell is merged, the next phases are:

1. **Section content implementation** — build out each section (Overview, Units, Owners, Meters, etc.) one by one, starting with the most-used sections
2. **Real BE integration** — replace localStorage hooks with actual API calls when the backend implements `syndicNavigationEnabled`
3. **Building list page** — replace the placeholder with a real buildings list fetched from the API
4. **Sidebar customization** — implement drag-and-drop reorder and pin/unpin persistence (matching the prototype's customize dialog)

### Lessons to carry forward

- Use TanStack Query as an abstraction layer even for localStorage — it makes the migration to real API seamless (swap `queryFn`/`mutationFn` only)
- Environment gate (`!IS_PRODUCTION_ENV` from `@/constants/appEnv`) + workspace-type + per-user opt-in provides 3 layers of gating for safe A/B testing
- Building the shell layout before section content allows parallel development — multiple developers can work on different sections once the shell is merged

### Known lessons from prior phases

- From chart-of-accounts-drawer: optional context pattern (`returns null outside provider`) works well for progressive feature adoption
- From lock-total-amount: prop-driven initialization is more deterministic than effect-based initialization

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| 2026-06-22 | 1 | Types + localStorage hooks implemented; env gate deferred to Commit 2 |
| 2026-06-22 | 2 | Feature gate hook, navigation constants, routerPaths.buildings |
| 2026-06-22 | 3 | Opt-in dialog mounted in MainLayout |
| 2026-06-22 | 4 | Conditional Buildings tab prepended in Sidebar when `isEnabled` |
| 2026-06-22 | 5 | Hook exports `isExperimentAvailable`; Feature Preview toggle in InfoSidebar |
| 2026-06-22 | 6 | `/buildings` route tree with list, redirect, section placeholders + i18n |
| 2026-06-22 | 7 | BuildingShellSidebar + [buildingId]/layout; shell i18n |
