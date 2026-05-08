# Docs Templates — Components & Blocks (Fumadocs)

This file is a **template pack**. Copy/paste one template per new doc page and replace placeholders.

**Scope**:

- **Components**: Tier 1 primitives (e.g. `Button`, `Input`, `Dialog`)
- **Blocks**: Tier 2 compositions (e.g. `PageHeader`, `FormShell`)

**Target runtime**: Fumadocs + MDX (Next.js App Router).

---

## Template A — Component page (Tier 1 primitive)

> **File location (example)**: `apps/docs/content/docs/primitives/{component-slug}.mdx`

```mdx
---
title: {ComponentName}
description: {One sentence: what it is + why it exists.}
package: "@sndq/ui-v2"
tier: component
status: "{draft|stable|deprecated}"
since: "{YYYY-MM-DD|version}"
source:
  figma: "{FIGMA_URL_OR_EMPTY}"
  code: "{REPO_PATH_OR_EMPTY}"
links:
  spec: "{URL_OR_EMPTY}"
  a11y: "{URL_OR_EMPTY}"
---

{/* Prefer in-page previews (simple + explicit). `ComponentPreview` is not a standard component in `apps/docs` today. */}
<div className="border-sndq-border rounded-md border p-4">
  {preview}
</div>

## Overview

{2–5 sentences. What problem does this component solve? When should it be used?}

### When to use

- {Use case 1}
- {Use case 2}

### When not to use

- {Anti-use-case 1}
- {Anti-use-case 2}

## Installation

<CodeTabs>
  <TabsList>
    <TabsTrigger value="app">App usage</TabsTrigger>
    <TabsTrigger value="manual">Manual</TabsTrigger>
  </TabsList>

  <TabsContent value="app">

```tsx
import { {ComponentName} } from "@sndq/ui-v2/components";
```

  </TabsContent>

  <TabsContent value="manual">

```txt
packages/ui-v2/src/components/{ComponentName}.tsx
```

  </TabsContent>
</CodeTabs>

## Usage

```tsx
import { {ComponentName} } from "@sndq/ui-v2/components";
```

```tsx
export function Example() {
  return <{ComponentName} />;
}
```

## Playground (Story-based)

> Optional but recommended for Tier 1 primitives.
>
> This is a usage sandbox with **curated controls**, not exhaustive testing.

import { story } from '@/stories/{component-slug}.story';

<div className="border-sndq-border rounded-md border p-4">
  <story.WithControl />
</div>

## Props

### {ComponentName}

| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `{prop}` | `{type}` | `{default}` | {Notes / invariants / gotchas} |

## Behavior

{Describe key behavior that isn’t obvious from props alone (state model, controlled/uncontrolled, keyboard behavior, etc.).}

## Styling

### Tokens and CSS variables

- **Uses tokens**: `{--token-a}`, `{--token-b}`
- **Theme surface**: `{surface/background/border/text}` (pick the correct ones)

### ClassName contract

{State explicitly where `className` applies (root? content? trigger?) and whether it overrides defaults.}

## Accessibility

### Keyboard support

- **Tab**: {…}
- **Enter/Space**: {…}
- **Arrow keys**: {…}
- **Escape**: {…}

### Screen reader notes

{ARIA attributes, labelling requirements, common pitfalls.}

## Composition

Use the following composition to build `{ComponentName}`:

```text
{ComponentName}
├── {ChildA}
└── {ChildB}
```

## Examples

### Basic

<ComponentPreview name="{component-basic-id}" />

### Variants

{Explain the variation signal (prop, slots, CSS, etc.).}

<ComponentPreview name="{component-variants-id}" />

### With form field

<ComponentPreview name="{component-in-form-id}" />

## Playground

> **Required** for Tier 1 primitives.
>
> - This is a **usage sandbox**, not an a11y harness or exhaustive-attribute test bed.
> - Controls MUST be curated to the **main props only** (`pickProps` from `apps/docs/src/lib/story-pick-props.ts`; see `apps/docs/AGENTS.md`).
> - **One playground per page**.

import { story } from '@/stories/{component-slug}.story';

<div className="border-sndq-border rounded-md border p-4">
  <story.WithControl />
</div>

## Edge cases

- **Case**: {description}
  - **Recommendation**: {what to do}

## RTL

{If supported} Provide a preview and any required configuration notes.

<ComponentPreview name="{component-rtl-id}" direction="rtl" />

## Changelog

- **{YYYY-MM-DD}**: {Change summary.}

## Related

- `{OtherComponent}` — {why related}
- `{BlockName}` — {why related}
```

---

## Template B — Block page (Tier 2 composition)

> **File location (example)**: `apps/docs/content/docs/blocks/{category}/{block-slug}.mdx`

```mdx
---
title: {BlockName}
description: {One sentence: what it composes + what UI problem it solves.}
package: "@sndq/ui-v2"
tier: block
status: "{draft|stable|deprecated}"
since: "{YYYY-MM-DD|version}"
source:
  figma: "{FIGMA_URL_OR_EMPTY}"
  code: "{REPO_PATH_OR_EMPTY}"
---

<ComponentPreview name="{block-demo-id}" />

## Overview

{Explain the layout/composition intent. Clarify what is “opinionated” vs configurable.}

## Composition and dependencies

### Built from

- `{PrimitiveA}`
- `{PrimitiveB}`
- `{PrimitiveC}`

### Slots (if any)

- **Header**: {…}
- **Body**: {…}
- **Footer**: {…}

## Usage

```tsx
import { {BlockName} } from "@sndq/ui-v2/blocks";
```

```tsx
export function Example() {
  return <{BlockName} />;
}
```

## Props and API

| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `{prop}` | `{type}` | `{default}` | {Notes / invariants / gotchas} |

## Customization

### Layout customization

- {What can be changed safely}
- {What should not be changed}

### Styling customization

- {Tokens}
- {ClassName contract}

## Examples

### Basic

<ComponentPreview name="{block-basic-id}" />

### With actions

<ComponentPreview name="{block-actions-id}" />

### Empty / loading states

<ComponentPreview name="{block-empty-id}" />

## Playground (optional)

> Optional for Tier 2 blocks.
>
> Only add a playground if the block has a small, meaningful set of props to tweak.
> Controls MUST be curated to the **main props only**. **One playground per page**.

import { story } from '@/stories/{block-slug}.story';

<div className="border-sndq-border rounded-md border p-4">
  <story.WithControl />
</div>

## Accessibility

{Only what differs from the underlying primitives; link to primitives otherwise.}

## Edge cases

- **Case**: {description}
  - **Recommendation**: {what to do}

## Related

- `{PrimitiveA}`
- `{OtherBlock}`
```

---

## Template C — “Component index” page (category landing)

> Use when a category needs a landing page with guidance beyond the sidebar.

```mdx
---
title: {CategoryName}
description: {What this category covers.}
---

## What belongs here

- {…}

## Recommended defaults

- {…}

## Patterns

- {Pattern 1} → links
- {Pattern 2} → links
```

---

## Template D — Deprecation notice snippet

```mdx
<Callout type="warning">

**Deprecated.** Use `{ReplacementName}` instead.

- **Reason**: {why}
- **Removal**: {date or version}
- **Migration**: {one-liner instructions}

</Callout>
```

---

## Template E — Story-based Playground (Fumadocs)

This template defines the backing story for a docs page `<story.WithControl />` playground.

**Purpose**: quick usage exploration of the **main props**, not exhaustive prop coverage, not a11y testing.

### Files (standard locations)

- `apps/docs/src/stories/{slug}.story.tsx`
- `apps/docs/src/stories/components/{slug}.tsx` (client wrapper)

### Story file

```tsx
import { defineStory } from '@/lib/story';
import { pickProps } from '@/lib/story-pick-props';
import { {ComponentName} } from './components/{slug}';

const VISIBLE_PROPS = [
  // Curate to the “main” props only. Keep this list short.
  // Do NOT add every HTML attribute or a11y-related prop.
  '{propA}',
  '{propB}',
  '{propC}',
] as const;

export const story = defineStory(import.meta.url, {
  Component: {ComponentName},
  args: {
    initial: {
      // Minimal, representative defaults (not a test matrix).
    },
    controls: {
      transform: pickProps(VISIBLE_PROPS),
    },
  },
});
```

### Client wrapper component

```tsx
'use client';

export { {ComponentName}, type {ComponentName}Props } from '@sndq/ui-v2/components';
```

### Playground rules

- **One playground per page**.
- Controls must be **curated** (main props only).
- The playground is for **usage**, not:
  - a11y verification
  - exhaustive prop validation
  - integration testing

