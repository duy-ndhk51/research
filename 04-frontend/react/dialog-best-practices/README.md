# Dialog Best Practices — Knowledge Base

A structured analysis of production dialog implementations, comparing architectural patterns for accessibility, extensibility, and composition with other overlay types.

## Documents

| Document | Source | Focus |
|----------|--------|-------|
| [Base UI Dialog Architecture](./base-ui-dialog-architecture.md) | Base UI (`@base-ui/react`) | Store-based state, 3 modality modes, N-level nesting, detached triggers, imperative handles, transition lifecycle |
| [Comparison and Best Practices](./comparison-and-best-practices.md) | Base UI, Radix UI, Headless UI | Side-by-side architecture comparison, focus management deep dive, nested dialog patterns, decision matrix |

## Key takeaway

A dialog is a **state machine coordinating focus, dismissal, and visibility**. The critical architectural decisions are:

1. **State container** — flat context (simple, full re-renders) vs observable store (complex, granular subscriptions, cross-tree sharing)
2. **Modality spectrum** — binary modal/non-modal vs a third `'trap-focus'` mode that traps keyboard without locking scroll
3. **Focus strategy** — interaction-type-aware initial focus prevents mobile keyboard issues; function API enables per-scenario logic
4. **Dismiss pipeline** — cancelable events with reasons enable close-confirmation without boolean flags or effects
5. **Composition model** — dialog as the base primitive for Drawer/AlertDialog/Sheet via identity context bridges

Start with the [Comparison and Best Practices](./comparison-and-best-practices.md) for actionable guidelines and decision matrix, or read the [Base UI Dialog Architecture](./base-ui-dialog-architecture.md) for deep implementation reference.
