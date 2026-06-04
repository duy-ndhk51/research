# DESIGN.md Integration: Lessons from Vibe Coding

**Date:** 2026-06-03  
**Context:** Prototyped the purchase invoice page in `apps/prototype` using AI-assisted coding with `@sndq/ui-v2` and `DESIGN.md` as guidance.

---

## Problem Statement

After the vibe coding session, two systematic anti-patterns emerged:

1. **Arbitrary CSS vars instead of Tailwind utilities** — `bg-[var(--sndq-surface)]` instead of `bg-sndq-surface`
2. **Hand-built HTML instead of ui-v2 components** — raw `<input>` instead of `InputGroup` + `InputGroupInput`

These happened despite having `DESIGN.md`, `AGENTS.md`, and docs app documentation.

---

## Root Cause Analysis

### The documentation gap is about AUDIENCE

| Doc | Audience | Answers |
|-----|----------|---------|
| `DESIGN.md` | Authors (token designers) | "What values do tokens have?" |
| `packages/ui-v2/AGENTS.md` | Contributors (component builders) | "How do I graduate a component?" |
| `apps/docs/AGENTS.md` | Docs authors | "How do I write MDX pages?" |
| **MISSING** | Consumers (app developers + AI agents) | "How do I USE the design system?" |

The AI agent knew WHAT tokens existed but not HOW to consume them in Tailwind. It knew DESIGN.md rules but not the component catalog's import paths.

### Specific gaps

1. **Tailwind v4 `@theme inline` mapping is implicit** — `tokens.css` defines `--color-sndq-surface` inside `@theme inline {}`, which Tailwind v4 auto-generates as `bg-sndq-surface`. But nothing in the docs says "this generates utility classes; don't use arbitrary values."

2. **No component decision matrix** — AGENTS.md lists the barrel exports but doesn't say "when you need a search field, compose InputGroup + InputGroupAddon + InputGroupInput." The agent has to read the source to discover composition patterns.

3. **DESIGN.md is machine-readable spec, not usage guide** — It documents values and constraints (max weight 500, Lucide only, etc.) but not code patterns (how to apply them in className strings).

---

## Solution: Consumer-Focused Cursor Rule

Created `apps/prototype/.cursor/rules/ui-v2-usage.mdc` containing:

1. **Token → utility mapping table** with explicit correct/wrong examples
2. **Component decision matrix** — "need X → use component Y from import Z"
3. **Composition patterns** — e.g., search field with InputGroup
4. **"Not available" list** — what to build locally vs what exists in ui-v2
5. **CSS class reference** — `.sndq-control`, `.sndq-btn`, `.sndq-input-wrap`

---

## Key Insight: Three Layers of Design System Documentation

For a design system to be effectively consumed by both humans and AI agents:

```
Layer 1: SPECIFICATION (DESIGN.md)
├── Token values (colors, spacing, radius, typography)
├── Visual constraints (max weight, icon rules)
├── Component token slots (bg, text, radius per variant)
└── Do's and Don'ts (semantic tokens only, no raw hex)

Layer 2: IMPLEMENTATION (AGENTS.md + component source)
├── Package structure and conventions
├── Graduation workflow
├── CVA variant patterns
└── Testing and docs requirements

Layer 3: CONSUMPTION (cursor rule / usage guide)  ← THIS WAS MISSING
├── Tailwind utility class mapping
├── Component import paths and when to use each
├── Composition patterns (search field, form with validation, etc.)
├── What exists vs what to build locally
└── Code examples for common UI patterns
```

**DESIGN.md alone is necessary but not sufficient.** Without Layer 3, an AI agent (or junior dev) will:
- Read the token names and reproduce them with arbitrary CSS vars
- Know the visual spec but hand-build elements that already exist as components
- Follow the constraints (correct colors, correct weights) but use the wrong implementation approach

---

## Application to `sndq-fe` Main Project

When the design system is ready for broader adoption in `sndq-fe`:

### 1. Create a consumption rule in sndq-fe

```
sndq-fe/.cursor/rules/ui-v2-consumption.mdc
```

Same structure as the prototype rule but tailored to sndq-fe's specific patterns:
- How `@sndq/ui-v2` components replace briicks equivalents
- Migration patterns (e.g., briicks `Button` → ui-v2 `Button`)
- Which briicks components still have no ui-v2 equivalent

### 2. Keep DESIGN.md as token spec only

Don't bloat DESIGN.md with usage patterns. It should remain the machine-readable source of truth for `pnpm run design:sync`. Usage docs belong in cursor rules or the docs app.

### 3. Component catalog in docs app

The `apps/docs` Fumadocs site should eventually have per-component pages showing:
- Live playground (Fumadocs Story)
- Import path
- Props table
- Composition examples (InputGroup patterns, Form patterns)
- "When to use" guidance

This replaces part of the cursor rule with proper documentation. But the cursor rule is still valuable because it's concise and always-present in agent context.

### 4. Auto-generate the consumption rule

Consider adding a script that reads `packages/ui-v2/src/components/index.ts` barrel and generates the "available components" section of the cursor rule automatically. This keeps it in sync as components are graduated.

---

## Metrics

| Metric | Before (no consumption guide) | After (with cursor rule) |
|--------|-------------------------------|--------------------------|
| Arbitrary `[var(...)]` usage | ~40 instances | Should be 0 |
| Hand-built inputs | 1 (search field) | Should use InputGroup |
| Time debugging style issues | Unknown | Prevented at generation |

---

## Action Items for Main Project

- [ ] Graduate more components to `@sndq/ui-v2` (Table, Sheet, Tabs, Select at minimum)
- [ ] Create `sndq-fe/.cursor/rules/ui-v2-consumption.mdc` when migration starts
- [ ] Add composition examples to docs app (InputGroup, Field, Form patterns)
- [ ] Consider codegen for the "available components" list in cursor rules
- [ ] Document the Tailwind v4 `@theme inline` → utility class relationship somewhere permanent (AGENTS.md or docs app)
