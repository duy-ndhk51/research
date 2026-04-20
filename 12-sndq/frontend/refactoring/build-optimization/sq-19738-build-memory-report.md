# SQ-19738 Build Memory — Progress Report

## Summary

The prerequisite work from **SQ-20642** (RHF v7.72 + resolvers v5.2 + centralized zodResolver wrapper) has been merged. TypeScript compiler metrics dropped **over 50%** across the board:

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Types | 1,691,552 | 811,954 | **-52.0%** |
| Instantiations | 29,150,241 | 12,282,340 | **-57.9%** |
| Memory | 6.46 GB | 2.81 GB | **-56.5%** |
| Check time | 117s | 73s | **-37.7%** |

This means **`tsc --noEmit` no longer needs extra RAM** — it runs comfortably within default Node.js limits.

## Still Required: NODE_OPTIONS for `next build`

Despite the tsc improvement, **`pnpm build` still OOMs** with default heap (~4 GB). The root cause is that `next build` runs everything in a single Node.js process:

- **Webpack compilation** peaks at **4.33 GB heap / 6.96 GB RSS** — this alone exceeds the default limit
- After webpack finishes, type-checking runs at only 1.25 GB (thanks to SQ-20642), but the webpack phase has already crashed before reaching it

The webpack peak is driven by: 174 routes (34 are unused prototype routes), Sentry AST transforms, full dependency graph resolution, and chunk analysis — all in one process.

**Current fix**: `NODE_OPTIONS="--max-old-space-size=8192"` must be set for any build command. CI runners need >= 8 GB RAM.

## Next Optimization Steps

| Priority | Action | Impact |
|----------|--------|--------|
| P0 | Hardcode `NODE_OPTIONS` in build script | Prevents OOM for all devs/CI |
| P1 | Exclude ~34 prototype routes from prod build | -20% routes compiled |
| P1 | Make Sentry transforms CI-only | Reduces local build memory |
| P2 | Lazy-load tiptap, recharts, pdf-lib, firebase | Smaller webpack graph |
| P3 | Evaluate Turbopack for production builds | Potentially eliminates the problem |

## Key Takeaway

SQ-20642 solved the **type-checking memory** problem (tsc: 6.46 GB → 2.81 GB). The remaining OOM is purely a **webpack bundling** problem — a different bottleneck that requires build config optimizations, not type-level fixes.
