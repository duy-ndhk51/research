# Drawer Best Practices — Knowledge Base

A structured analysis of production drawer implementations, comparing architectural patterns for extensibility, maintainability, and reduced complexity.

## Documents

| Document | Source | Focus |
|----------|--------|-------|
| [Base UI Drawer Architecture](./base-ui-drawer-architecture.md) | Base UI (`@base-ui/react`) | Compound component pattern, 3-tier context, pub/sub stores, CSS variable optimization, N-level nested coordination |
| [Vaul Drawer Architecture](./vaul-drawer-architecture.md) | Vaul (`vaul`) | Radix Dialog composition, flat context, explicit NestedRoot, imperative DOM with WeakMap, iOS workarounds |
| [Comparison and Best Practices](./comparison-and-best-practices.md) | Both | Side-by-side architecture comparison, nested drawer deep dive, implementation checklist, decision matrix |

## Key takeaway

A drawer is a **dialog with gesture physics**. Both libraries compose an existing dialog primitive (own vs Radix) rather than building modal behavior from scratch. The critical architectural decisions are:

1. **Context granularity** — flat (simple, more re-renders) vs layered (complex, better isolation)
2. **Nesting model** — explicit component (1 level, clear API) vs implicit detection (N levels, more wiring)
3. **Update strategy** — direct DOM mutation for 60fps drag, React state for discrete changes
4. **Styling contract** — CSS variables + data attributes as the public API surface

Start with the [Comparison and Best Practices](./comparison-and-best-practices.md) for actionable guidelines, or read the individual architecture documents for deep implementation reference.
