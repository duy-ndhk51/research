# AI-Friendly Component Library Patterns (from Cloudflare Kumo)

Extracted principles from Cloudflare's `@cloudflare/kumo` design system that make it exceptionally effective when used by LLM/AI coding agents. Each principle includes why it works, how Kumo implements it, and how to apply it to `@sndq/ui-v2`.

**Created**: 2026-05-10
**Source**: Full analysis of Kumo's `.opencode/agents/kumo.md`, `AGENTS.md` (root + package + component-level), `ai/USAGE.md`, `ai/component-registry.json`, and component source patterns.
**Purpose**: Guide `@sndq/ui-v2` development toward agent-friendly architecture.

---

## The Core Insight

Kumo treats **AI agents as first-class consumers** of the design system, alongside human developers and Figma. This means the library ships not just components but a parallel **machine-readable interface** that agents can query before writing code. The result: agents produce correct component usage on the first attempt instead of guessing from source.

---

## The 10 Principles

### 1. Machine-Readable Component Registry

**What Kumo does**: Auto-generates `ai/component-registry.json` at build time containing structured props, variant values, descriptions, styling classes, and code examples for every component. Agents query it with `jq` or the CLI (`pnpm doc Button`) before writing any code.

**Why it works for LLMs**: LLMs excel when given structured, complete context upfront. A JSON registry eliminates the need to read and parse multiple source files, reducing token usage and hallucination risk. The agent gets the full API surface in one query.

**Kumo implementation**:
```
docs demos → demo-metadata.json → ts-json-schema-generator → enrichment → component-registry.json
```

**SNDQ current state**: No equivalent. Agents must read source files to understand component APIs.

**Recommendation**: Introduce a lightweight registry script in Phase 3 that extracts component metadata (props, variants, defaults, examples) into a single JSON file at `packages/ui-v2/ai/registry.json`. Start simple — even a manually maintained JSON file provides value.

---

### 2. Explicit Variant Constants as Runtime Objects

**What Kumo does**: Every component exports `KUMO_{NAME}_VARIANTS` and `KUMO_{NAME}_DEFAULT_VARIANTS` as runtime objects with classes and descriptions per option:

```typescript
export const KUMO_BUTTON_VARIANTS = {
  variant: {
    primary: { classes: "bg-kumo-brand ...", description: "Primary action" },
    secondary: { classes: "bg-kumo-elevated ...", description: "Secondary action" },
  },
  size: { sm: { classes: "h-7 px-2 text-xs", description: "Compact" }, ... }
} as const;

export const KUMO_BUTTON_DEFAULT_VARIANTS = {
  variant: "secondary",
  size: "base",
  shape: "base"
} as const;
```

**Why it works for LLMs**: Agents can programmatically enumerate all valid variant combinations without parsing TypeScript types. The `description` field provides semantic context that helps agents choose the right variant. This feeds the registry codegen pipeline — the same data serves humans (docs), agents (registry), and tooling (Figma plugin, lint rules).

**SNDQ current state**: Uses CVA variants which capture class mappings but lack descriptions and aren't structured for machine extraction.

**Recommendation**: Alongside CVA, export a `SNDQ_{NAME}_VARIANTS` constant with descriptions. This can coexist with CVA — the constant documents intent while CVA handles runtime class generation. Even without a codegen pipeline, the constant serves as inline documentation agents can read.

---

### 3. Finite, Named Semantic Token Vocabulary

**What Kumo does**: Only semantic tokens are allowed (`bg-kumo-base`, `text-kumo-default`, `border-kumo-line`). Raw Tailwind colors (`bg-blue-500`) fail lint. Dark mode is automatic via `light-dark()` in CSS custom properties — no `dark:` prefix exists.

**Why it works for LLMs**: A closed vocabulary is the single most important property for reliable LLM output. When the set of valid class names is small and named, agents can memorize it and always produce correct styles. Open-ended systems (arbitrary Tailwind colors) create infinite possibility spaces where LLMs hallucinate.

**Kumo's token hierarchy**:
| Layer | Examples |
|-------|----------|
| Surface | `bg-kumo-canvas`, `bg-kumo-base`, `bg-kumo-elevated`, `bg-kumo-recessed` |
| Brand | `bg-kumo-brand`, `bg-kumo-brand-hover` |
| Status | `bg-kumo-info`, `bg-kumo-success`, `bg-kumo-warning`, `bg-kumo-danger` |
| Text | `text-kumo-default`, `text-kumo-strong`, `text-kumo-subtle`, `text-kumo-inactive` |
| Border | `border-kumo-hairline`, `border-kumo-line` |

**SNDQ current state**: `--sndq-*` semantic tokens exist (`--sndq-action`, `--sndq-surface`, `--sndq-text`, etc.) but are consumed via CSS custom properties and arbitrary Tailwind values. No lint enforcement prevents using raw colors.

**Recommendation**: Map semantic tokens to `@theme` aliases so they become first-class Tailwind utilities (e.g. `bg-sndq-surface` instead of `bg-[var(--sndq-surface)]`). Add an ESLint/oxlint rule that blocks raw Tailwind colors in `packages/ui-v2/`. The closed vocabulary is the foundation everything else builds on.

---

### 4. Lint-Enforced Constraints (Fast Failure)

**What Kumo does**: Custom oxlint rules enforce architectural decisions at the code level:
- `no-raw-tailwind-colors` — blocks arbitrary colors
- `no-dark-variant` — blocks `dark:` prefix
- `no-deprecated-props` — reads deprecation data from registry
- `no-cross-package-imports` — prevents boundary violations

**Why it works for LLMs**: Agents operate in a generate-check-fix loop. When constraints fail fast with clear error messages, agents self-correct efficiently. Silent errors or runtime-only failures waste agent iterations. The tighter the constraints, the fewer valid outputs exist, and the more likely the agent's first attempt is correct.

**SNDQ current state**: ESLint enforces code quality but no custom rules enforce design system boundaries or token usage.

**Recommendation**: Start with one high-impact rule: `no-raw-tailwind-colors` scoped to `packages/ui-v2/`. This single rule forces all styling through the semantic token layer. Add `no-cross-package-imports` to prevent `@sndq/ui-v2` from importing app-world code (already documented as a forbidden import in the architecture doc).

---

### 5. Scaffolding CLI (Never Create Manually)

**What Kumo does**: `pnpm new:component` (Plop-based) creates the component file, barrel export, vite config entry, and package.json entry in one command. Markers (`PLOP_INJECT_EXPORT`, `PLOP_INJECT_COMPONENT_ENTRY`) indicate injection points.

**Why it works for LLMs**: Creating a component involves updating 3-4 files in specific locations. Agents frequently forget one (especially barrel re-exports). A CLI collapses this into a single command that's impossible to get wrong.

**SNDQ current state**: Components are created manually. The `package.json` exports field uses wildcard patterns (`"./components/*": "./src/components/*.tsx"`) which reduces but doesn't eliminate the need for barrel updates.

**Recommendation**: Add a simple scaffold script (`pnpm new:component <Name>`) that creates `src/components/{Name}/{Name}.tsx`, `src/components/{Name}/index.ts`, `src/components/{Name}/{Name}.test.tsx`, and updates `src/components/index.ts`. Even a bash script provides value over manual creation.

---

### 6. Layered AGENTS.md Documentation

**What Kumo does**: Places `AGENTS.md` files at multiple levels:
- Root `AGENTS.md` — monorepo overview, conventions, commands, toolchain
- `packages/kumo/AGENTS.md` — build system, testing, anti-patterns, deprecated items
- `packages/kumo/src/components/AGENTS.md` — file patterns, required exports, complexity hotspots

Each level provides context appropriate to the task depth. An agent modifying a component reads the component-level doc; an agent adding a new package reads the root doc.

**Why it works for LLMs**: Context window is finite. Layered docs let agents load only the relevant slice. The alternative (one massive doc) wastes tokens on irrelevant context or gets truncated.

**SNDQ current state**: No `AGENTS.md` in `packages/ui-v2/`. The existing research docs are in a separate repo.

**Recommendation**: Add three files:
1. `packages/ui-v2/AGENTS.md` — package overview, exports, test commands, token usage rules
2. `packages/ui-v2/src/components/AGENTS.md` — component file pattern, required exports, composition rules
3. `packages/ui-v2/src/blocks/AGENTS.md` — block pattern, what qualifies as a block vs primitive

---

### 7. Codegen Pipeline (Registry Always in Sync)

**What Kumo does**: The component registry is a build artifact, not a manually maintained file. Pipeline:
1. Docs demos are extracted into `demo-metadata.json` (JSDoc comments become descriptions)
2. `ts-json-schema-generator` extracts TypeScript types
3. Enrichment adds variants, examples, sub-components, styling metadata
4. Output: `component-registry.json` + `component-registry.md` + `schemas.ts`

**Why it works for LLMs**: Manual documentation drifts. Codegen guarantees the registry matches the source code at all times. Agents never encounter stale API docs.

**SNDQ current state**: No codegen pipeline for component metadata.

**Recommendation**: Defer full codegen to later phases. In the near term, the manual approach (principle #10 — AI Usage Guide) provides most of the value with minimal infrastructure. When the component count exceeds ~20 graduated components, invest in a `codegen:registry` script that extracts props from TypeScript types.

---

### 8. Predictable File Structure

**What Kumo does**: Every component lives at `src/components/{name}/{name}.tsx` with:
- `index.ts` barrel re-export
- Optional `{name}.test.tsx`
- `displayName` set on every `forwardRef` component (enforced)
- One component per folder (compound sub-components in the same file)

**Why it works for LLMs**: Predictability eliminates search. When an agent needs to modify `Button`, it knows the exact path without globbing. Consistent naming means pattern matching works across all components.

**SNDQ current state**: `packages/ui-v2/src/components/` follows this pattern already (`Container.tsx`, `typography/Heading.tsx`, `typography/Text.tsx`). The structure is correct but young.

**Recommendation**: Codify the pattern in `src/components/AGENTS.md` and enforce it via the scaffold script. Specifically: `src/components/{Name}/{Name}.tsx` (not flat files at the components root). The typography grouping (`typography/Heading.tsx`) is fine as a sub-category but each component should still have its own folder once graduated.

---

### 9. Single Canonical Composition Pattern

**What Kumo does**: Every component composes styles as:
```tsx
cn(variantClasses, className)
```
`className` always wins on conflicts (via `tailwind-merge`). No exceptions, no alternative patterns.

**Why it works for LLMs**: One rule is easier to follow than many. When there's exactly one way to compose styles, agents produce correct code without needing to determine which pattern applies to which component.

**SNDQ current state**: Already documented as the "override-wins guarantee" in the typography and layout system references. The implementation in `packages/ui-v2/src/lib/utils.ts` uses `clsx` + `tailwind-merge`.

**Recommendation**: Already aligned. Enforce via code review and test gates (each component must have a test asserting `className` override wins on conflicting utilities).

---

### 10. AI Usage Guide (Separate from Human Docs)

**What Kumo does**: Ships `ai/USAGE.md` — a condensed, table-heavy reference of all components, semantic tokens, controlled state patterns, and common patterns. Designed for LLM consumption (structured, scannable, no prose fluff).

**Why it works for LLMs**: Human docs (Astro site) are verbose, visual, and scattered across pages. LLMs need dense, structured, complete references. A single file with tables beats navigating a docs site.

**SNDQ current state**: No AI-specific reference exists.

**Recommendation**: Create `packages/ui-v2/ai/USAGE.md` containing:
- Component quick reference table (name, category, key props, variants)
- Semantic token reference (full list with purpose)
- Import patterns (barrel vs deep imports)
- Controlled state reference (value prop + change callback per component)
- Common composition patterns (Field wrapper, compound components)

This is the highest ROI action for immediate agent effectiveness.

---

## Priority Matrix

Ordered by impact-to-effort ratio for `@sndq/ui-v2`:

| Priority | Principle | Effort | Impact | When |
|----------|-----------|--------|--------|------|
| **P0** | #10 AI Usage Guide | 2-3 hours | High | Now (Phase 3 ongoing) |
| **P0** | #6 Layered AGENTS.md | 1-2 hours | High | Now |
| **P1** | #3 Semantic token enforcement | 4-6 hours | High | Phase 3 |
| **P1** | #9 Canonical composition (tests) | 2-3 hours | Medium | Phase 3 per-batch |
| **P2** | #8 Predictable file structure | 1 hour | Medium | Phase 3 scaffold |
| **P2** | #5 Scaffolding CLI | 3-4 hours | Medium | Phase 3 |
| **P2** | #2 Variant constants with descriptions | 1 hour/component | Medium | Phase 3 per-batch |
| **P3** | #4 Custom lint rules | 8-12 hours | High (long-term) | Phase 3-4 |
| **P3** | #1 Component registry | 12-16 hours | Very high (long-term) | Post-Phase 3 |
| **P4** | #7 Codegen pipeline | 20+ hours | Very high (long-term) | Post-Phase 4 |

---

## Implementation Checklist

### Immediate (this sprint)

- [ ] Create `packages/ui-v2/AGENTS.md` with package overview, export patterns, token rules
- [ ] Create `packages/ui-v2/src/components/AGENTS.md` with file pattern, composition rules
- [ ] Create `packages/ui-v2/ai/USAGE.md` with component table, token reference, patterns

### Phase 3 (per batch)

- [ ] Each graduated component gets a `className` override-wins test
- [ ] Each graduated component exports variant descriptions (alongside CVA)
- [ ] Map all `--sndq-*` tokens to `@theme` aliases for first-class Tailwind utilities
- [ ] Document the closed token vocabulary in `ai/USAGE.md` as components graduate

### Phase 3 (infrastructure)

- [ ] Add `pnpm new:component` scaffold script (Plop or bash)
- [ ] Add `no-raw-tailwind-colors` ESLint rule scoped to `packages/ui-v2/`
- [ ] Add `no-app-imports` ESLint rule scoped to `packages/ui-v2/`

### Post-Phase 3

- [ ] Build a `codegen:registry` script extracting TypeScript props into `ai/registry.json`
- [ ] Wire registry codegen into the build pipeline
- [ ] Add `no-deprecated-props` rule reading from registry

---

## Key Takeaway

The fundamental pattern is: **constrain the possibility space, then document what remains**.

Kumo works for agents because it (1) makes invalid output fail immediately (lint rules), (2) reduces the valid output space to a small set (semantic tokens), and (3) documents that small set in a machine-optimized format (registry + USAGE.md). Agents don't need to be "smart" about design decisions — they just need to pick from a curated menu.

For `@sndq/ui-v2`, the fastest path to agent-friendliness is: write the AI Usage Guide (principle #10), add AGENTS.md files (principle #6), and enforce semantic tokens via lint (principle #3). These three actions cover 80% of the value with 20% of the effort.
