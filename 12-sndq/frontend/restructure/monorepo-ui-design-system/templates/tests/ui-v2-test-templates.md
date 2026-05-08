# Test Templates — `@sndq/ui-v2` (Primitives & Blocks)

This file is a **template pack**. Copy/paste the relevant template per component/block and replace placeholders.

**Scope**:

- `packages/ui-v2/src/components/**` (Tier 1 primitives)
- `packages/ui-v2/src/blocks/**` (Tier 2 blocks)

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

**Target**: \(2–6\) tests per **core primitive**, \(0–2\) for non-core.

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

- **No tests**:
  - component is internal, unstable, or likely to be removed soon
  - component is a thin re-export without local logic
- **Contract tests only (default)**:
  - primitive or simple composite
  - no complex keyboard/focus behavior
- **Contract + interaction tests**:
  - keyboard/focus is part of the contract
  - portals/overlays or controlled/uncontrolled state can break
- **Visual regression (in addition to above)**:
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

- **Component**: `packages/ui-v2/src/components/{ComponentName}.tsx`
- **Test**: `packages/ui-v2/src/components/{ComponentName}.test.tsx`

### Checklist (copy/paste)

- [ ] **Element contract**: default element and `as` behavior (if supported)
- [ ] **Composition contract**: `asChild` merges `className`/props onto child (if supported)
- [ ] **Minimal styling contract**: assert only 1–3 “meaningful” classes/tokens
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

  it('applies the minimal styling contract', () => {
    render(<{ComponentName} {propForVariant}="{value}">Hello</{ComponentName}>);
    expect(screen.getByText('Hello')).toHaveClass('{stableContractClass}');
  });
});
```

---

## 4) Template B — Composition contract tests (`asChild`)

> Use only when the component supports `asChild` or slotting.

### Why this test exists

`asChild` is an **extensibility escape hatch**. It’s also easy to break during refactors (order of `className` merging, prop spreading, ref forwarding).

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

## 5) Template C — Interactive primitive tests (keyboard + focus + aria)

> Use for components where keyboard/focus is the contract (or where wrappers can break Radix behavior).

### Contract to test (copy/paste and fill)

- [ ] **Open/close**: opens on click, closes on Escape
- [ ] **Keyboard**: Enter/Space on trigger, arrow keys if applicable
- [ ] **Focus**: initial focus is reasonable; focus returns to trigger on close
- [ ] **ARIA state**: `aria-expanded` / `role=dialog|menu|listbox` exists when open

### Minimal skeleton (Testing Library)

```tsx
import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import * as React from 'react';
import { {ComponentName} } from './{ComponentName}';

describe('{ComponentName} interactions', () => {
  it('opens and closes with keyboard', async () => {
    const user = userEvent.setup();
    render(<{ComponentName} />);

    const trigger = screen.getByRole('button', { name: /{triggerLabel}/i });
    await user.click(trigger);
    expect(screen.getByRole('{openRole}')).toBeInTheDocument();

    await user.keyboard('{Escape}');
    expect(screen.queryByRole('{openRole}')).not.toBeInTheDocument();
    expect(trigger).toHaveFocus();
  });
});
```

**When to prefer Playwright instead of Testing Library**

- portals + layering + focus quirks
- animation timing issues (prefer disabling animations in test env)
- anything that was flaky in jsdom

---

## 6) Template D — Block testing policy (Tier 2)

Blocks are compositions and tend to evolve with product needs. Default posture:

- **Prefer visual regression** to protect layout/styling.
- Add a unit/integration test **only** if the block contains meaningful logic:
  - state machines
  - complex branching rendering
  - event handling that is easy to regress

### Minimal “logic exists” block test skeleton

```tsx
import { describe, expect, it } from 'vitest';
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

### Suggested “definition of done” for a core component (visual)

- [ ] baseline screenshot exists for the default state
- [ ] at least one “state” screenshot exists (e.g. error/disabled/open)
- [ ] diffs are explainable and tied to a deliberate change (token/component update)

---

## 8) Template F — Benefits & reasons (copy/paste into PR description)

### Why these tests are low maintenance

- Contract tests assert **public outcomes** (element/role/behavior), not internal implementation.
- Visual tests cover styling regressions without brittle class assertions.
- Minimal test counts prevent “variant explosion”.

### Why this improves extensibility

- `as` / `asChild` / `className` behavior is treated as a **guarantee**, so consumers can safely compose.
- Refactors can change internals without rewriting tests, as long as the contract holds.

### Why this fits Phase 3 batch work

- Every graduating component can follow the same small template, keeping PRs reviewable.
- When a regression happens, add **one targeted regression test** rather than increasing broad coverage.

