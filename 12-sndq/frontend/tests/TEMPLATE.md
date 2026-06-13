# {Feature Name}

**Status**: Not started | In progress | Done
**Priority**: HIGH | MEDIUM | LOW ({1-line reason})
**Test tier**: Pure logic | Hook | Component integration
**Target file**: `src/modules/{module}/__tests__/integration/{feature}.test.tsx`
**Component(s) under test**: `{Component}` from `{path}`

## Purpose

{1-2 sentences: what invariant does this file guard?}

## Risk

{What breaks if these tests don't exist?}

## Bugs Guarded

- {describe group} > {test name} guards **B{N}** ({bug name}) -- {one-line explanation of the defended invariant}

## Scenarios

| Describe Group | Test Name | Key Assertion |
|----------------|-----------|---------------|
| {sub-feature} | {short name} | {one-line assertion summary} |

## Related Specs

- {Feature}: [{file}](./{file}) — {which tests}

## Mocking Strategy

```typescript
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));

// Add component-specific mocks below (API hooks, external services, etc.)
```

## Shared Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '../utils';

beforeEach(() => {
  vi.clearAllMocks();
});
```

---

## {Descriptive title}

**Preconditions**: {what state must be true before the test runs}

### Steps

1. {action}
2. {action}

### Expected Outcome

- {expect statement in plain English}
- {expect statement in plain English}

### Example Code

```typescript
describe('{Feature Name}', () => {
  describe('{sub-feature group}', () => {
    it('{descriptive title}', async () => {
      const user = userEvent.setup();

      // Arrange
      renderWithProviders(<Component />, {
        contextOverrides: { /* ... */ },
        formDefaults: { /* ... */ },
      });

      // Act
      await user.click(screen.getByRole('button', { name: /action/i }));

      // Assert
      expect(screen.getByText(/expected/i)).toBeInTheDocument();
    });
  });
});
```

---

<!--
Repeat the H2 section above for each test case.

TEMPLATE RULES:
- Priority is mandatory -- helps triage implementation order
- Test tier is mandatory -- Pure logic | Hook | Component integration
- Scenarios table is mandatory -- provides a scannable overview
- Mocking Strategy is mandatory -- documents shared vi.mock() calls
- Shared Setup is mandatory -- extracts repeated factories/constants
- Related Specs is mandatory -- cross-references dependent features
- Title is plain feature name (not ID-prefixed)
- Each test gets a full H2 section with Preconditions / Steps / Expected Outcome / Example Code
- Use AAA (Arrange-Act-Assert) in example code
- Keep Preconditions to one line when possible
- Steps should be user-facing actions, not implementation details
- Expected Outcome should map 1:1 to expect() calls in example code
- NO sequential IDs (IT-XXX) -- the describe/it tree is the identifier
- Tag only regression tests with [B{N}] in the it() name
- NEVER use `as any` -- use `Partial<T>`, typed factories, or narrow mock types instead
- Limit type casts to verified narrowing (e.g. `as FormDataType`)

USAGE:
1. Copy this template into your feature folder: tests/{feature-name}/integration/{spec}.md
2. Replace all {placeholders} with concrete values
3. Add one H2 section per test scenario
4. Keep the Scenarios table in sync with the H2 sections below
-->
