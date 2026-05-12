# Docs Rules — Components & Blocks (Fumadocs)

This file is the **living rules + process** for how we document the design system.

It is written to be used by humans and by an AI coding agent when generating or updating docs.

---

## 1. Goals and audience

- **Audience**: SNDQ engineers shipping product UI.
- **Primary job**: “How do I use this safely and consistently in SNDQ code?”
- **Secondary job**: “What are the guarantees and constraints of this component/block?”
- **Non-goals**:
  - Marketing copy
  - Visual design theory (keep that in Foundations)
  - Re-documenting upstream libraries (Radix, etc.) unless we diverge

---

## 2. Documentation taxonomy (what gets a page)

### 2.1 Tier 1 — Components (primitives)

A Tier 1 doc page is required when:

- the component is exported from `@sndq/ui-v2/components`, and
- it is intended for reuse across apps/modules.

### 2.2 Tier 2 — Blocks (compositions)

A Tier 2 doc page is required when:

- the block is exported from `@sndq/ui-v2/blocks`, and
- it composes multiple primitives into an opinionated UI building block.

### 2.3 Tier 3 — Business components

No docs pages in the design-system docs for Tier 3. Business components live in app code and should be documented near the module if needed.

---

## 3. File location, naming, and routing

### 3.1 Naming rules

- **kebab-case** file names: `button.mdx`, `page-header.mdx`
- **Title case** for `title` frontmatter: `Page Header`
- **Slug** must match file name (Fumadocs routing)

### 3.2 Suggested structure

Keep a predictable IA so search and sidebar remain usable:

- `primitives/layout/{component}.mdx` — Container, Section, Flex, Grid
- `primitives/typography/{component}.mdx` — Text, Heading
- `primitives/{component}.mdx` — Button, Input, Select, etc.
- `blocks/{block}.mdx`
- `foundations/{topic}.mdx` — identity, tokens, design principles (not components)

If a component exists in multiple “bases” (e.g. variants or implementations), prefer **one page** with an explicit “Implementation” section unless there is a strong reason to split pages.

---

## 4. Frontmatter standard (required fields)

Every component/block page MUST include:

- `title`
- `description` (one sentence)
- `package: "@sndq/ui-v2"`
- `tier: component | block`
- `status: draft | stable | deprecated`
- `since` (date or version)

Optional but recommended:

- `source.figma` (URL if available)
- `source.code` (repo path)
- `links.spec` (internal spec URL)
- `links.a11y` (a11y notes URL)

Rule: **Do not add fields unless we will actually use them** (search filters, badges, or future automation).

---

## 5. Page content standard (required sections)

Use the templates in [`docs-templates.md`](./docs-templates.md).

### 5.1 Component pages must include

- **Preview**: a rendered visual demo near the top (not just a code fence — the reader must see the component rendered with styled placeholder content)
- **Visual demos per section**: each major props section (variants, sizes, gaps, alignment, etc.) must include an **inline rendered demo** showing the actual component. Code fences alone are not sufficient. Use the `not-prose` wrapper pattern (see docs-templates.md Template A for the snippet).
- **Overview**: what it is, when to use / not use
- **Installation**: how to import in SNDQ (not npm install)
- **Usage**: minimal example with correct imports
- **Props**: at least the non-obvious props; do not document trivial `className` repeatedly unless it has special meaning
- **Styling**: tokens and/or CSS variables + className contract
- **Accessibility**: keyboard + SR notes, or explicitly “inherits X behavior from Y”
- **Examples**: 2–6 examples showing real use cases, each with a rendered visual demo above the code fence
- **Playground**: Fumadocs Story playground with curated controls (required for Tier 1 primitives)
- **RTL**: only if supported; otherwise explicitly say “Not supported”
- **Related**: cross-links reduce duplicate docs

### 5.2 Block pages must include

- **Preview**
- **Overview**
- **Composition and dependencies**: which primitives it builds from
- **Usage**
- **Props**
- **Customization**: what is safe/expected to override
- **Examples**: include empty/loading where relevant
- **Accessibility**: only what differs from primitives; link out otherwise
- **Related**

---

## 6. Writing rules (tone, clarity, and correctness)

- Write in **English**, concise and technical.
- Prefer **bullets** over long paragraphs.
- Always answer:

### 6.1 Code comments vs docs pages (important)

This rule applies to **component implementation files only** (e.g. `packages/ui-v2/src/components/{component}/*.tsx`, `apps/ui-v2-dev/src/components/ui-v2/**`):

- Keep in-code JSDoc **minimal**: API essentials only (prop intent, constraints/invariants, defaults, and `@deprecated` notices).
- Avoid long block comments that duplicate docs content (usage guides, variant tables, design rationale, migration notes).
- The **canonical docs** live in `apps/docs` as MDX pages under `apps/docs/content/docs/`. If a component is exported from `@sndq/ui-v2/components`, it should have an MDX page (Tier 1 primitive) and the code should not try to be the documentation.
  - **What problem does it solve?**
  - **What are the invariants?** (what must always remain true)
  - **What are the foot-guns?** (common misuse)
- Do not include “obvious” narrative comments.
- When you make a claim (“supports keyboard navigation”), back it with:
  - a code example,
  - a listed keybinding contract, or
  - a link to the upstream spec we follow.

---

## 7. Code examples: standards

### 7.1 Imports

- Always show the **exact import path** used in SNDQ:
  - `@sndq/ui-v2/components`
  - `@sndq/ui-v2/blocks`

### 7.2 Examples must be minimal but realistic

- Prefer 10–30 lines examples.
- Use meaningful prop values (avoid `foo`, `bar`).
- If the component relies on composition, show the composition.

### 7.3 No app-specific dependencies in docs examples

Docs examples must not require:

- app-specific contexts (`useWorkspace`, etc.)
- translations (`useTranslations`)
- API calls or data fetching

If demonstrating a realistic state, use inline mock data.

---

## 8. Accessibility rules (minimum bar)

Every component/block page must either:

- document keyboard + SR behavior directly, OR
- explicitly delegate to a dependency (“This matches Radix X, see link”) AND list any **local deviations**.

If the component has any of these, document them explicitly:

- focus trapping / restoring focus
- `aria-*` requirements
- `label` / `id` pairing requirements
- “asChild/render prop” semantics that can break roles

---

## 9. Styling rules (tokens and theming)

### 9.1 Token-first explanation

Prefer documenting styling in terms of:

- CSS variables / design tokens the component consumes
- semantic vs primitive tokens (when relevant)

Avoid saying “just change Tailwind classes” unless the component is explicitly designed for that.

### 9.2 `className` contract must be explicit

For every component/block, state one of:

- **Root override**: `className` applies to the root element and composes as `cn(defaults, className)`
- **Slot override**: `className` exists on multiple subcomponents; document which one affects what
- **No className**: if intentionally omitted, say why and how to style instead

---

## 10. “Composition” section rules

If the component is compositional (multiple exports), the page MUST include the tree diagram:

```text
Component
├── SubcomponentA
└── SubcomponentB
```

Additionally:

- mention any **required ordering**
- mention any **required pairing** (trigger/content, label/control)

---

## 11. Change management rules

### 11.1 When to update docs

Update the doc page in the same PR when:

- exports change (new/removed component, prop rename)
- default behavior changes
- styling contract changes (tokens, className behavior)
- accessibility behavior changes

### 11.2 Changelog section

Only add a “Changelog” entry when the change is user-visible and not obvious from the code diff.

---

## 12. Standard doc “Definition of Done”

A component/block doc is “done” when:

- The page renders with a working preview and inline visual demos for each major props section
- Usage snippet compiles in a typical SNDQ app
- Non-obvious props are documented
- Styling contract is documented
- Accessibility section is present (direct or delegated)
- At least 2 examples exist
- Related links are present

---

## 13. Agent workflow (how you and I maintain this)

When creating docs:

- Start from [`docs-templates.md`](./docs-templates.md)
- Keep content consistent with existing doc patterns (Preview → Install → Usage → Composition → Examples → RTL → API)
- Prefer updating these rules over inventing one-off patterns

When you discover a new recurring docs need (e.g. “Tokens used” list for every component):

- add it here under the relevant section
- update templates to match

