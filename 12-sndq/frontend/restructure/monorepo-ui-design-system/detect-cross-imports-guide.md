# detect-cross-imports.sh — Guide

**Script**: [detect-cross-imports.sh](./detect-cross-imports.sh)
**Example output**: [detect-cross-imports-example-output.md](./detect-cross-imports-example-output.md)
**Process**: [component-lifting-process.md](./component-lifting-process.md)

---

## What It Does

Scans the frontend source tree and produces a report of component import boundaries. It answers three questions:

1. Which shared components (`src/components/`) are most used by modules? (candidates for `@sndq/ui-v2`)
2. Which modules import components from other modules? (boundary violations that need lifting)
3. Are there any `TODO(lift)` markers pending action?

This connects directly to the [4-tier promotion model](./component-lifting-process.md#1-promotion-ladder): the script detects when components should move from **Local** to **Shared**, or from **Shared** to **Blocks/Primitives**.

## How to Run

```bash
# From monorepo root (sndq-clone/) — uses default path sndq-fe/src
bash detect-cross-imports.sh

# Or specify a custom src directory
bash detect-cross-imports.sh path/to/src
```

No dependencies required — uses only `grep`, `sed`, `cut`, `sort`, `uniq`.

## When to Run

- **Before sprint planning** — generates the candidate list for lift PRs
- **After major feature work** — new features often introduce cross-boundary imports
- **Monthly at minimum** — catches gradual drift

## Report Sections

### Section 1: Shared Component Usage

Lists every `src/components/` folder that modules import from, ranked by import count.

**What it scans**: All `from '@/components/...'` imports inside `src/modules/`.

**How to read it**: High counts mean the component is already widely shared across modules. These are the top candidates for lifting into `@sndq/ui-v2/blocks` or `@sndq/ui-v2/components`.

### Section 2: Cross-Module Component Imports

Lists every individual import where module A reaches into module B's `components/` folder. Each entry shows:

- **Consumer module** ← **Source module** (which module is importing from which)
- **File path** (the consuming file)
- **Import path** (the `@/modules/...` path being imported)

**What it means**: These are boundary violations — a component in one module is being used by another module. The component should either be moved to `src/components/` (Shared tier) or to `@sndq/ui-v2` (Blocks/Primitives tier).

### Section 2b: Cross-Module Summary

Aggregated view of Section 2, grouped by source module. Shows which modules' components are most "leaked" into other modules.

**How to read it**: The highest-ranked modules are the top priority for lifting — their components are already shared in practice, just not formally.

### Section 3: Pending TODO(lift) Markers

Shows all `// TODO(lift)` comments in the codebase. These are markers added by developers during PR review when a cross-boundary import is introduced.

**Convention**: When a developer adds a cross-module import in a PR, they mark it:

```tsx
// TODO(lift): cross-module import, candidate for blocks
import { DashboardSectionLayout } from '@/modules/financial/components/...';
```

## Color Coding

The terminal output uses color to indicate severity:

| Color | Threshold | Meaning |
|-------|-----------|---------|
| Red | 20+ imports | Heavy usage — high-priority lift candidate |
| Yellow | 10-19 imports | Moderate usage — evaluate for lifting |
| Dim | <10 imports | Low usage — monitor, no action needed yet |

## What to Do With Results

Follow the [sprint cadence](./component-lifting-process.md#5-day-to-day-process):

1. Review the report in a 15-minute standup
2. Pick 2-3 candidates from the top of each section
3. Create focused lift PRs during the sprint
4. Resolve any `TODO(lift)` markers that have been pending for more than one sprint
