# Purchase Invoice V3 — Test Planning Notes

**Created**: 2026-05-07  
**Context**: Planning test coverage for `sndq-fe/src/modules/financial/forms/purchase-invoice-v3` now that the form is in a stable phase.

---

## Goal

Increase confidence in **form behaviors and interactions** (cross-component wiring, state transitions, validation, totals, and line editing flows) while keeping tests **maintainable**, **fast**, and **high-signal** for day-to-day refactors.

---

## Recommendation (layered)

Use a test pyramid for best ROI:

- **Unit tests (keep/extend where it pays)**: pure logic with high determinism (reducers, utils, small hooks).
- **Integration tests (add, form-focused)**: verify key behavioral contracts across multiple components/providers with controlled dependencies.
- **E2E tests (thin, critical path)**: minimal “real app” smoke coverage to validate routing + real network wiring + submission path.

Rationale: integration tests typically provide the best balance of **signal**, **speed**, and **refactor safety** for a complex form module, while a small number of E2E tests protects against “it works in isolation but not in the app” failures.

---

## Integration tests for the form — benefits

- **High refactor ROI**: catches regressions when changing context/hooks/section composition without rewriting many unit tests.
- **Fast feedback**: usually much faster and less flaky than browser E2E, so they can run on every PR and locally.
- **Behavioral focus**: validates rules like totals, validation, toggles, and invoice-line interactions in realistic UI composition.
- **Better debug loop**: failures point closer to the broken logic than end-to-end failures.

---

## Integration tests — tradeoffs

- **Scope creep risk**: “integration” can become “mini-e2e” if setups get too heavy.
- **Mock drift**: mocked network/data can diverge from reality; mitigations include a thin E2E layer and/or contract checks for key endpoints.
- **Overlap cost**: duplicating the same scenarios in integration and E2E doubles maintenance unless responsibilities are clearly split.

---

## E2E-only (skip integration) — impact and cost

### What you gain

- **Highest fidelity**: real browser + routing + auth + network stack; best for “can the user complete the flow end-to-end?”
- **Strong release confidence**: especially valuable for financial flows where app wiring matters.

### What it costs

- **Lower day-to-day ROI**: slower execution means less frequent running and slower feedback during refactors.
- **Flakiness & infra tax**: selectors, timing, data setup, and environment issues increase triage time.
- **Harder to scale scenarios**: each additional behavior case is expensive compared to integration tests.

Conclusion: E2E-only can feel “more impactful” when it fails, but often yields **higher total cost** and **slower feedback** unless E2E infrastructure is already exceptionally stable and fast.

---

## Decision heuristics

### Prefer integration tests when…

- The main risk is **intra-form state** and UI behaviors (invoice line editing, totals, toggles, validation, derived state).
- You expect ongoing refactors inside `purchase-invoice-v3` and want **fast regressions detection**.
- You want failures to be **actionable** without heavy environment triage.

### Prefer adding (or prioritizing) E2E tests when…

- The main risk is **app wiring**: routing, auth/session, real API behavior, server validation, navigation outcomes.
- Past incidents were “unit/integration passed but production failed due to backend/app wiring.”

---

## Metrics summary (qualitative)

- **Impact (real-world failures caught)**:
  - Integration: high for module behavior, lower for full-app wiring.
  - E2E: high for wiring, can miss edge cases unless suite is large.
- **Maintainability**:
  - Integration: good if scenarios stay small and behavior-named.
  - E2E: tends to be higher cost due to selectors, timing, data, env.
- **Extensibility**:
  - Integration: cheaper to add one more behavioral contract.
  - E2E: each scenario is heavy.
- **Costs**:
  - Integration: medium authoring cost, low runtime cost.
  - E2E: higher authoring + runtime + triage cost.

---

## Suggested split of responsibilities

- **Integration suite**: cover “business behavior contracts” for the form module (the module should be safe to refactor).
- **E2E suite**: cover “critical user journey smoke” (the app is wired correctly).

