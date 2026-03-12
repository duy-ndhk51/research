# Playground

Code experiments, proof-of-concepts, and hands-on explorations.

## How to Use

Create a subfolder for each experiment:

```
playground/
├── 2026-03-08-binary-search-tree/
│   ├── README.md       # What you're experimenting with
│   ├── solution.ts     # Your code
│   └── test.ts         # Tests if applicable
```

## Naming Convention

Use `YYYY-MM-DD-topic-slug/` format so experiments are chronologically ordered.

## Snippet Header Template

Every playground file should include a header comment for AI review context:

```typescript
/**
 * @playground <Component Name>
 * @source <original file path or "new">
 * @stack React 19, Next.js 15, Tailwind v4, shadcn/ui
 *
 * Context:
 * - <key context about the real codebase>
 * - <inlined utilities, omitted imports, etc.>
 *
 * Review focus: <what feedback you want>
 * Out of scope: <what reviewers should skip>
 */
```

| Field | Purpose |
|---|---|
| `@playground` | Component/experiment name |
| `@source` | Where this code lives in real codebase (or "new") |
| `@stack` | Tech stack so reviewer knows what's available |
| `Context` | Explain differences from real codebase (inlined utils, missing deps) |
| `Review focus` | What you actually want feedback on |
| `Out of scope` | Prevent false-positive reviews on intentional choices |

See `12-Mar-2026-sndq-toolbar-component/Toolbar.tsx` for a real example.

## Experiments

_No experiments yet. Start your first one!_
