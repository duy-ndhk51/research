# Test Templates — `@sndq/ui-v2` (Primitives & Blocks)

This file is a **template pack**. Copy/paste the relevant template per component/block and replace placeholders.

**Scope**:

- `packages/ui-v2/src/components/{component}/` (Tier 1 primitives — per-component folders)
- `packages/ui-v2/src/blocks/{block}/` (Tier 2 blocks — same folder pattern)

**Tooling**:

- **Unit / component tests**: Vitest (or Jest) + Testing Library
- **Browser / visual regression**: Playwright

**Primary design constraints** (startup-friendly):

- **Maintenance**: Keep tests stable when styles/tokens evolve.
- **Extensibility**: Lock down public contracts so refactors are safe.
- **Complexity**: Spend more tests on “behavioral risk” than on pure styling.

---

## 1) The testing pyramid (recommended)

### 1.1 Contract tests (default for primitives)

**What these protect**

- Public API: `props -> element/attributes/roles`
- Composition mechanics: `as`, `asChild`, ref forwarding (smoke-level)
- Minimal styling contract: only the **few classes/tokens** that are truly part of the component’s public promise

**What they avoid**

- Full DOM/class snapshots
- Exhaustive permutations of variants

**Sizing rule (additive)**

- `1` element/baseline test (default rendered tag)
- `+ 1` per variant prop you assert (one assertion per prop, not per value)
- `+` composition tests for each of `as`, `asChild`, `ref` — only when the component supports them

If you find yourself adding a variant assertion *per value* of a variant prop, you’re testing a matrix — collapse it.

**Worked count**: a `Text` primitive with `weight` / `variant` / `truncate` asserted, plus `as` + `asChild` + `ref`, lands at `1 + 3 + 3 = 7` tests. See §9.

### 1.2 Interaction tests (for complex primitives)

Use for components where regressions are costly and subtle:

- overlays (`Dialog`, `Sheet`, `Popover`, `DropdownMenu`)
- navigation (`Tabs`, `SegmentedControl`)
- selectors (`Select`, combobox-like primitives)

**Target**: 1 happy path + 1 edge case.

### 1.3 Visual regression (the design-system safety net)

**What it catches better than unit tests**

- spacing/typography regressions
- token changes causing subtle layout shifts
- hover/focus ring regressions

**What it should NOT be**

- “snapshot everything”: keep the set **small and curated**

**Target**: core primitives + a few flagship blocks/patterns.

---

## 2) Decision matrix (pick the smallest effective test set)

### 2.1 How to choose

Pick the **highest row you qualify for**.

- **No tests** [Tier 0]:
  - component is internal, unstable, or likely to be removed soon
  - component is a thin re-export without local logic
- **Contract tests only** [Tier 1, default]:
  - primitive or simple composite
  - no complex keyboard/focus behavior
- **Contract + interaction tests** [Tier 1, interactive]:
  - keyboard/focus is part of the contract
  - portals/overlays or controlled/uncontrolled state can break
- **Visual regression (in addition to above)** [Tier 1 core / Tier 2 flagship]:
  - component is core to the design system
  - changes are likely to be mostly visual (tokens, spacing, typography)

### 2.2 What not to test (to keep maintenance low)

- **Avoid large snapshots** of full markup or full class strings.
- **Avoid variant matrices** (every `variant x size x state` combo).
- **Avoid testing `cva`/Radix internals**. Test your wrapper contract only.

---

## 3) Template A — Primitive contract tests (Tier 1)

> Use for primitives like `Text`, `Badge`, `Separator`, simple layout primitives, etc.

### File conventions

- **Component**: `packages/ui-v2/src/components/{component-name}/{ComponentName}.tsx`
- **Test**: `packages/ui-v2/src/components/{component-name}/{ComponentName}.test.tsx`
- **Barrel**: `packages/ui-v2/src/components/{component-name}/index.ts`

### Checklist (copy/paste)

- [ ] **Element contract**: default element and `as` behavior (if supported)
- [ ] **Composition contract**: `asChild` merges `className`/props onto child (if supported)
- [ ] **Minimal styling contract**: assert a class **only** when the variant prop being tested has no other observable effect (no DOM/role/attr change). Max **one assertion per variant prop under test**. Never assert layout/utility classes (`flex`, `gap-2`, `p-4`) — those are incidental.
- [ ] **Ref forwarding**: smoke test that `ref` resolves to the rendered DOM node.
- [ ] **A11y sanity**: prefer `getByRole` / `getByLabelText` over `testid`

### Test skeleton (adapt to Vitest or Jest)

```tsx
import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import * as React from 'react';
import { {ComponentName} } from './{ComponentName}';

describe('{ComponentName}', () => {
  it('renders with default element', () => {
    render(<{ComponentName}>Hello</{ComponentName}>);
    // Prefer a semantic query if possible; otherwise fall back to text.
    expect(screen.getByText('Hello').tagName.toLowerCase()).toBe('{defaultTag}');
  });

  it('respects `as` when provided', () => {
    render(
      <{ComponentName} as="{tag}">
        Hello
      </{ComponentName}>,
    );
    expect(screen.getByText('Hello').tagName.toLowerCase()).toBe('{tag}');
  });

  it('applies the {variantProp} contract when {variantProp} is "{value}"', () => {
    render(<{ComponentName} {variantProp}="{value}">Hello</{ComponentName}>);
    expect(screen.getByText('Hello')).toHaveClass('{stableContractClass}');
  });

  it('forwards ref to the DOM element', () => {
    const ref = React.createRef<HTMLElement>();
    render(<{ComponentName} ref={ref}>Hello</{ComponentName}>);
    expect(ref.current).toBe(screen.getByText('Hello'));
  });
});
```

### Anti-patterns

```tsx
// Don't: assert layout utilities (incidental, not a contract)
expect(el).toHaveClass('flex', 'items-center', 'gap-2');

// Don't: assert full class strings (snapshot in disguise)
expect(el.className).toBe('text-sndq-sm font-normal text-sndq-text-primary');

// Don't: variant matrix (one test per value of a variant prop)
['xs', 'sm', 'md', 'lg', 'xl', '2xl', '3xl'].forEach((size) => {
  it(`renders size ${size}`, () => {
    /* ... */
  });
});

// Do: one assertion tied to the variant prop under test
render(<Text weight="medium">x</Text>);
expect(screen.getByText('x')).toHaveClass('font-medium');
```

---

## 4) Template B — Composition contract tests (`asChild`)

> Use only when the component supports `asChild` or slotting.

### Why this test exists

`asChild` is an **extensibility escape hatch** that consumers rely on. It’s also easy to break during refactors (order of `className` merging, prop spreading, ref forwarding). One contract test guarantees the merge behavior survives internal changes.

### Test skeleton

```tsx
import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import * as React from 'react';
import { {ComponentName} } from './{ComponentName}';

describe('{ComponentName} asChild', () => {
  it('merges props/className onto the child element', () => {
    render(
      <{ComponentName} asChild className="fromWrapper" data-testid="target">
        <a href="/x" className="fromChild">
          Link
        </a>
      </{ComponentName}>,
    );

    const el = screen.getByTestId('target');
    expect(el.tagName.toLowerCase()).toBe('a');
    expect(el).toHaveAttribute('href', '/x');
    expect(el).toHaveClass('fromChild');
    expect(el).toHaveClass('fromWrapper');
  });
});
```

---

## 5) Template C — Interactive primitive tests

Interactive primitives split into two flavors. Pick by **where the open content lives in the DOM**, not by which component it is.

### 5.1 Template C1 — In-tree interactive (jsdom-friendly)

> Scope: `Tabs`, `SegmentedControl`, `RadioGroup`, `Checkbox`, controlled inputs — components where focus stays in the document tree.
>
> jsdom + Testing Library is reliable here. No portal, no scroll lock, no animation timing issues.

**Contract to test (copy/paste and fill)**

- [ ] **Open/close**: opens on click, closes on Escape (if applicable)
- [ ] **Keyboard**: Enter/Space on trigger, arrow keys if applicable
- [ ] **Focus**: focus stays reasonable across interactions
- [ ] **ARIA state**: `aria-expanded` / `aria-selected` / `role=...` as applicable

```tsx
import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import * as React from 'react';
import { {ComponentName} } from './{ComponentName}';

describe('{ComponentName} interactions', () => {
  it('responds to keyboard interaction', async () => {
    const user = userEvent.setup();
    render(<{ComponentName} />);

    const trigger = screen.getByRole('{triggerRole}', { name: /{triggerLabel}/i });
    await user.click(trigger);
    expect(screen.getByRole('{openRole}')).toBeInTheDocument();
  });
});
```

### 5.2 Template C2 — Portal / overlay interactive (Playwright by default)

> Scope: `Dialog`, `Popover`, `Sheet`, `DropdownMenu`, `Tooltip`, `Toast` — anything that portals out of the component tree.
>
> **Default to Playwright.** jsdom mishandles portals, focus return, scroll lock, and animation timing. Testing Library is acceptable only if the author verifies **10× consecutive non-flaky local runs** and notes it in the PR.

**Contract to test**

- [ ] Trigger opens overlay; overlay has `role="dialog" | "menu" | "listbox"`
- [ ] Escape closes; click-outside closes (where applicable)
- [ ] Focus enters overlay on open; **returns to trigger on close**
- [ ] `aria-expanded` reflects state (where applicable)

```ts
import { expect, test } from '@playwright/test';

test('{ComponentName} opens, traps focus, returns focus on Escape', async ({ page }) => {
  await page.goto('/__sandbox__/{component-slug}');
  const trigger = page.getByRole('button', { name: /{triggerLabel}/i });

  await trigger.click();
  await expect(page.getByRole('{openRole}')).toBeVisible();

  await page.keyboard.press('Escape');
  await expect(page.getByRole('{openRole}')).toBeHidden();
  await expect(trigger).toBeFocused();
});
```

---

## 6) Template D — Block testing policy (Tier 2)

Blocks are compositions and tend to evolve with product needs.

**Default**: blocks get **visual regression only** (Template E).

**Add a unit/integration test only if it would catch a bug a contract test on the underlying primitives wouldn’t.**

### Examples — DO test

- Wizard / multi-step form: branching navigation, step gating
- Drag-and-drop list: reorder logic, drop-target validation
- Filter bar: query composition from multiple inputs
- Anything with a state machine or derived state

### Examples — DON'T test

- Block that wraps `<Button>` and forwards `onClick` (already covered by `Button` contract)
- Block that just renders children (already covered by composition contract)
- Pure layout blocks (covered by visual regression)

### Provider/context invariant

Tier 1 primitives **must not require a context provider** to render. If yours does, fix the component, don’t add test infra. Tier 2 blocks may need providers — extract a `renderWithProviders` helper rather than wiring providers per file.

### "Logic exists" block test skeleton

```tsx
import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import * as React from 'react';
import { {BlockName} } from './{BlockName}';

describe('{BlockName}', () => {
  it('fires the primary action', async () => {
    const user = userEvent.setup();
    const onAction = vi.fn();
    render(<{BlockName} onAction={onAction} />);
    await user.click(screen.getByRole('button', { name: /{actionLabel}/i }));
    expect(onAction).toHaveBeenCalledTimes(1);
  });
});
```

---

## 7) Template E — Visual regression spec (Playwright)

### What to screenshot

Keep it intentionally small:

- **Core primitives**: a short, curated list (10–20 max)
- **A few flagship blocks**: only those reused widely

### Keep screenshots stable (maintenance rules)

- Use **deterministic data** (no random IDs, no “today’s date”, no live network).
- Freeze time if the UI renders relative timestamps.
- Fix viewport sizes.
- Avoid animations in screenshot mode.

### Tooling and workflow

- **API**: use `@playwright/test`’s `expect(locator).toHaveScreenshot('name.png')`.
- **Update baselines**: `pnpm test:visual --update-snapshots` (run locally and commit the diff intentionally — never auto-update in CI).
- **Storage**: baselines live next to the spec under `__screenshots__/{spec}/{platform}/`. Pin `playwright.config.ts` `snapshotPathTemplate` so screenshots are stable across machines.
- **Determinism setup** (in `beforeEach` or a fixture):
  - `await page.emulateMedia({ reducedMotion: 'reduce' })`
  - Freeze `Date` if relative timestamps render
  - Set viewport explicitly (don’t rely on default)
- **CI**: run the visual job on Linux/Chromium only — macOS rendering differs subtly and produces noise. Failed diffs upload to artifacts; reviewer must approve in the PR.

### Suggested "definition of done" for a core component (visual)

- [ ] baseline screenshot exists for the default state
- [ ] at least one “state” screenshot exists (e.g. error/disabled/open)
- [ ] diffs are explainable and tied to a deliberate change (token/component update)

---

## 8) Reviewer checklist

Use during PR review. Each item maps back to the section that enforces it.

**Sizing (§1.1)**

- [ ] Test count fits the additive sizing rule: `1` baseline + `1` per variant prop asserted + composition tests for `as` / `asChild` / `ref`.
- [ ] No variant matrices (one test per value of a variant prop).
- [ ] No full-class-string snapshots, no full-DOM snapshots.

**Contract focus (§3)**

- [ ] Class assertions are tied 1:1 to a variant prop under test.
- [ ] No tests for `cva` output composition or Radix internals.
- [ ] No assertions on layout/utility classes (`flex`, `gap-2`, `p-4`, etc.).
- [ ] `as` and `asChild` (if supported) each have one test.
- [ ] `ref` forwarding has a smoke test.

**Interactive components (§5)**

- [ ] In-tree interactives use Template C1 (jsdom).
- [ ] Portal/overlay interactives use Template C2 (Playwright). If Testing Library is used, the author confirms 10× non-flaky local runs in the PR description.

**Blocks (§6)**

- [ ] Block has unit tests **only** if it has logic a primitive contract test wouldn’t catch.
- [ ] Block does not introduce a context dependency at the primitive layer.

**Visual (§7)**

- [ ] Visual specs are deterministic (frozen time/data, fixed viewport, `reducedMotion: 'reduce'`).
- [ ] Baseline diffs are intentional and explained in the PR description.

---

## 9) Worked example: `Text`

`Text` is the canonical Tier 1 primitive. Use it as a reference when adapting Templates A and B.

- **Source**: `packages/ui-v2/src/components/typography/text/Text.tsx`
- **Tests**: `packages/ui-v2/src/components/typography/text/Text.test.tsx`

### Decisions made

| Concern         | Decision                                                  | Why                                                                                                      |
| --------------- | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Tier            | Contract only                                             | Pure styling primitive, no portals, no keyboard contract                                                 |
| Element         | One `as` test                                             | `as` is part of the public API; one tag value proves the contract (`TextElement` union covers the rest at compile time) |
| Composition     | One `asChild` test                                        | `asChild` is an extensibility guarantee                                                                  |
| Variants        | Assert `weight`, `variant`, `truncate` (one each)         | These have no other observable effect — the class **is** the contract                                    |
| Variants skipped | `size`, `align`                                          | `size` has 7 values (matrix risk); `align` is low-regression-risk text alignment                         |
| Ref             | Forwarding smoke test                                     | `forwardRef` is part of the public API                                                                   |
| Visual          | Optional                                                  | Participates in flagship type-scale visual specs; no per-component baseline                              |

### Test count

`1` element + `1` `as` + `1` `asChild` + `3` variant assertions + `1` ref = **7 tests**.

This matches the §1.1 additive formula. Anything more (e.g. asserting every value of `size`) is a matrix; anything less drops a public-API guarantee.

---

## 10) Contract drift policy

Tests live as long as the component. Apply these rules when contracts evolve:

- **Adding a variant value** (e.g. new `size`): no new test required. Optional if the variant is core to the design.
- **Renaming a variant prop or value**: update the contract test in the **same PR** as the rename. PR is incomplete otherwise.
- **Removing a variant**: delete the test. Don’t keep dead assertions.
- **Adding a prop with side effects** (e.g. `loading` that disables the trigger): add one contract test in the same PR.
- **Internal refactor** (cva → tailwind-variants, swap Radix versions): tests must continue to pass without modification. If they don’t, the contract was wrong, not the refactor.
