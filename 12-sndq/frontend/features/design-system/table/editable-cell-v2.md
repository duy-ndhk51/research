# Editable Cell V2 Execution — Form-based Editing with Column-level Meta

Step-by-step execution guide for upgrading the DataTable editable cell system. Each commit should be independently verifiable and revertable.

**Created**: 2026-06-19
**Status**: In progress — Commit 8 done
**Architecture**: [architecture.md](./architecture.md)
**Prior execution**: [execution.md](./execution.md) (Phase 0 complete)
**Branch**: `feature/editable-cell-v2`

> **IMPORTANT**: Do NOT automatically commit after each step. Implement each commit's changes, then stop and wait for manual review and testing. Only commit after explicit approval.
>
> **STATUS TRACKING**: After completing each commit's implementation, automatically update this file:
> 1. Check off the completed items in that commit's **Status** checklist
> 2. Record the date and any notes in the **Execution Log** table at the bottom
> 3. Update the top-level **Status** field (e.g., "In progress — Commit 3 done")

---

## Table of Contents

1. [Overview](#1-overview)
2. [Before You Start](#2-before-you-start)
3. [PR 1 — Editable Cell V2](#3-pr-1--editable-cell-v2)
4. [Final Verification](#4-final-verification)
5. [Team Communication](#5-team-communication)
6. [What's Next](#6-whats-next)
7. [Execution Log](#execution-log)

---

## 1. Overview

**Goal**: Replace the callback-based editor pattern (`CellEditor<TValue>` render function) with a form-based submission model (React Spectrum pattern) and column-level declarative editor config (MRT/tablecn pattern), eliminating per-column boilerplate while adding validation, `isSaving` feedback, and configurable submit-on-blur — all without breaking forward compatibility with future row-level editing.

**Structure**: 8 commits across 1 PR.

| PR | Scope | Risk level | Commits |
|----|-------|------------|---------|
| **PR 1** | Types, hook, editors, EditableCell, Content auto-render, exports, 3 consumer migrations | Medium | 1–8 |

**Why 1 PR**: All changes are tightly coupled — the type definitions, editor factories, EditableCell component, and Content auto-rendering all depend on each other. Splitting into multiple PRs would leave the codebase in a broken intermediate state. Consumer migrations are included because breaking changes are accepted (prototyping mode).

### Prerequisites

- `packages/ui-v2` builds successfully (`pnpm tsc --noEmit` from package root)
- Phase 0 DataTable infrastructure is complete (all 22 commits from `execution.md`)
- Existing `DataTable.EditableCell` works with the current `editor={...}` pattern
- `apps/prototype` dev server runs and editable cells function in `ServerSideDemo`, `DataTableDemo`, and `InvoicesTable`

### Known constraints

- Breaking changes to `DataTableEditableCellProps` and `CellEditor` type are accepted — all 3 consumers will be updated in the same PR
- The `useEditingStore` external store pattern in `DataTable.tsx` must be preserved for performance — it avoids re-rendering the entire table when editing state changes
- TanStack Table's `ColumnMeta` type must be augmented via module declaration merging, which requires the augmentation to live alongside other existing augmentations in the same declaration
- The `locale` system (`useUILocale`) must continue to provide editor button labels (Save/Cancel)

### Research references

The design synthesizes patterns from three libraries:

| Library | Pattern adopted | Source file |
|---------|----------------|-------------|
| React Spectrum S2 | Form-based submission (`<Form>` + `FormData`), `requestSubmit()` on click-outside, `isSaving`, `onCancel` | `react-spectrum/packages/@react-spectrum/s2/src/TableView.tsx` lines 1559–1855 |
| Material React Table | Column-level `editVariant` + `editSelectOptions` on column def, table-level `onEditingRowSave` | `material-react-table/src/types.ts` lines 464–478, 1168–1173 |
| tablecn | Discriminated union `CellOpts` on `ColumnMeta.cell`, switch-based cell rendering | `tablecn/src/types/data-grid.ts` lines 14–51, `data-grid-cell.tsx` lines 48–98 |

---

## 2. Before You Start

### Quality gate before each implementation commit

Use this gate for every implementation commit. If an item is intentionally skipped, record it under that commit's **Deviations from the gate** section.

- [ ] Public API / behavior is stable for this commit scope
- [ ] Public props, types, functions, or commands have minimal useful documentation where applicable
- [ ] Existing project helpers and patterns are reused instead of introducing one-off abstractions
- [ ] Tests or documented manual checks cover the main behavior and likely regressions
- [ ] No unrelated files, app-specific imports, or ownership-boundary leaks are introduced
- [ ] Security-sensitive values, credentials, generated secrets, and local env files are not committed
- [ ] Build, lint, type-check, and any targeted verification commands are known before editing
- [ ] Any skipped verification is recorded as a deviation with a follow-up owner or trigger

### Documentation and comment policy

- Keep code comments minimal and focused on intent, invariants, or non-obvious behavior.
- Put usage examples, migration notes, variant tables, setup steps, and operational runbooks in docs, not inline code comments.
- Add deprecation notices only on the public export or entry point that consumers actually use.
- If docs and code disagree, update the docs in the same commit or record the gap as a deviation.

### Inspect source tree before implementation

Before the first implementation commit, inspect the actual repository state and record any differences from this plan.

- [ ] Confirm `packages/ui-v2/src/components/data-table/editors.tsx` exports `CellEditor`, `EditorContext`, `SelectOption`, `textEditor`, `currencyEditor`, `selectEditor`
- [ ] Confirm `packages/ui-v2/src/components/data-table/DataTableEditableCell.tsx` exports `DataTableEditableCellProps` with `row`, `field`, `value`, `editor`, `onSave` props
- [ ] Confirm `packages/ui-v2/src/components/data-table/DataTable.tsx` exports `useEditingStore` and `EditingCellStore`
- [ ] Confirm `packages/ui-v2/src/components/data-table/DataTableContent.tsx` uses `flexRender(cell.column.columnDef.cell, cell.getContext())` for cell rendering
- [ ] Confirm `packages/ui-v2/src/hooks/useDataTable.ts` has `DataTableOptions` interface with `config?` property
- [ ] Confirm 3 consumer files exist: `apps/prototype/src/modules/demo/ServerSideDemo.tsx`, `DataTableDemo.tsx`, `apps/prototype/src/modules/financial/invoices/InvoicesTable.tsx`
- [ ] Confirm whether dependencies or lockfiles will change (expected: no new dependencies)
- [ ] Confirm current lint, type-check, build status — record any pre-existing failures

### Capture baselines

Run these from the repository root and save the output. Diff against these after risky commits.

```bash
cd packages/ui-v2 && pnpm tsc --noEmit 2>&1 | tee /tmp/editable-v2-tsc-before.txt
cd apps/prototype && pnpm tsc --noEmit 2>&1 | tee /tmp/editable-v2-proto-tsc-before.txt
```

### Create branch

```bash
git checkout main
git pull origin main
git checkout -b feature/editable-cell-v2
```

---

## 3. PR 1 — Editable Cell V2

Rewrites the editable cell system from callback-based editors to form-based submission with column-level declarative config. Includes all consumer migrations. Safe to merge as a single atomic change because breaking changes are accepted in prototyping mode.

---

### Commit 1: Define EditorMeta types and augment ColumnMeta

**What**: Create the `EditorMeta` discriminated union type for declaring editors on column definitions via `meta.editor`, and augment TanStack's `ColumnMeta` to accept it.

**Files to create**: None

**Files to edit**:

- `packages/ui-v2/src/components/data-table/types.ts` — add:

```typescript
export interface SelectOption<T extends string = string> {
  value: T;
  label: string;
}

export type EditorMeta =
  | { variant: 'text'; submitOnBlur?: boolean; validate?: (value: string) => string | null }
  | { variant: 'currency'; step?: string; submitOnBlur?: boolean; validate?: (value: number) => string | null }
  | { variant: 'select'; options: readonly SelectOption[]; submitOnBlur?: boolean }
  | { variant: 'custom'; renderEditing: () => React.ReactNode; submitOnBlur?: boolean }
```

Augment TanStack's `ColumnMeta` via module declaration merging to add `editor?: EditorMeta`. This must coexist with any existing `ColumnMeta` augmentations (e.g., `align`, `sortKey`, `type`).

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Module augmentation conflicts with existing ColumnMeta extensions | LOW | Check that existing `meta.align`, `meta.type`, `meta.sortKey` still type-check correctly |
| SelectOption name collision with existing editors.tsx export | MEDIUM | The existing `SelectOption` in `editors.tsx` will be removed in commit 3; verify no import conflicts during intermediate state |

**Verification**:

```bash
cd packages/ui-v2 && pnpm tsc --noEmit
```

**If it fails**:

- **"Duplicate identifier 'SelectOption'"**: Ensure the `SelectOption` in `types.ts` uses a different export name or remove the one in `editors.tsx` first
- **"Property 'editor' does not exist on type 'ColumnMeta'"**: Verify the module augmentation uses `declare module '@tanstack/react-table'` with the correct `ColumnMeta` interface path

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add EditorMeta types and ColumnMeta augmentation`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 2: Add centralized editing.onSave to useDataTable and DataTable context

**What**: Add `config.editing` to `DataTableOptions` for centralized save callback, and thread it through `DataTableContext` so auto-rendered editors can access it without per-column wiring.

**Files to create**: None

**Files to edit**:

- `packages/ui-v2/src/hooks/useDataTable.ts` — add to `DataTableOptions.config`:

```typescript
config?: {
  // ...existing fields...
  editing?: {
    onSave: (rowId: string, field: string, value: unknown) => void | Promise<void>;
  };
};
```

Add `editing` to the returned `DataTableInstance`:

```typescript
interface DataTableInstance<TData> extends Table<TData> {
  // ...existing extensions...
  editing?: {
    onSave: (rowId: string, field: string, value: unknown) => void | Promise<void>;
  };
}
```

- `packages/ui-v2/src/components/data-table/DataTable.tsx` — expose `editing` config from the table instance via context (already available through `DataTableContext` since it provides the full `DataTableInstance`)

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Adding optional `editing` to DataTableInstance breaks existing consumers | LOW | Property is optional; existing code that doesn't use it is unaffected |
| `config.editing` name conflicts with TanStack internal options | LOW | TanStack uses `enableEditing` at the column level, not `editing` at the config level |

**Verification**:

```bash
cd packages/ui-v2 && pnpm tsc --noEmit
cd apps/prototype && pnpm tsc --noEmit
```

**If it fails**:

- **"Type 'editing' does not exist on type 'DataTableInstance'"**: Ensure the interface extension includes the `editing` field with `?` optional marker

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: add config.editing.onSave to useDataTable`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 3: Rewrite editors.tsx with form-based editors and validate support

**What**: Replace the `CellEditor<TValue>` callback pattern with form-compatible React components. Each editor renders form fields with `name` attributes for `FormData` extraction. Factory functions now return `EditorMeta` config objects instead of render callbacks. Add `validate` option to text and currency editors.

**Files to create**: None

**Files to edit**:

- `packages/ui-v2/src/components/data-table/editors.tsx` — full rewrite:

Remove:
- `EditorContext<TValue>` interface
- `CellEditor<TValue>` type
- `SelectOption` type (moved to `types.ts` in commit 1)
- `TextEditorUI`, `CurrencyEditorUI`, `SelectEditorUI` components
- Old factory functions returning render callbacks

Add:
- `TextEditorField` — renders `<Input name={fieldName} defaultValue={value} />` with auto-focus and select-on-mount. Accepts optional `validate` prop. Handles Enter to submit form, Escape to cancel.
- `CurrencyEditorField` — renders `<Input name={fieldName} type="number" step={step} defaultValue={value} />` with `validate` support.
- `SelectEditorField` — renders a list of button options with a hidden `<input name={fieldName} value={selectedValue} />` for FormData extraction. Selecting an option immediately submits the form.
- `EditorFieldProps` interface: `{ fieldName: string; defaultValue: unknown; onCancel: () => void; validate?: (value: any) => string | null }`.
- `resolveEditorField(meta: EditorMeta, fieldName: string, defaultValue: unknown, onCancel: () => void): React.ReactNode` — maps `EditorMeta.variant` to the corresponding field component.
- Updated factory functions: `textEditor()` returns `EditorMeta` with `{ variant: 'text' }`, `currencyEditor(opts?)` returns `{ variant: 'currency', step: opts?.step }`, `selectEditor(options)` returns `{ variant: 'select', options }`.

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Breaking change: `CellEditor<TValue>` type removed | HIGH | All consumers must be migrated (commits 7–8). Type-check will fail until consumers are updated. |
| `FormData` value extraction returns `string` for number inputs | MEDIUM | `CurrencyEditorField` must parse via `parseFloat()` in the `EditableCell` submit handler or within the editor itself |
| Select editor immediate submit on selection | LOW | Verify the hidden input value updates before `form.requestSubmit()` is called |

**Verification**:

```bash
cd packages/ui-v2 && pnpm tsc --noEmit
```

Note: Consumer apps will fail type-check until commits 7–8. Only verify the library package here.

**If it fails**:

- **"Module has no exported member 'CellEditor'"**: Expected during transition. Consumer migrations in commits 7–8 will resolve this.
- **"Cannot find name 'SelectOption'"**: Ensure `SelectOption` is imported from `./types` or re-exported from `editors.tsx`

**Deviations from the gate**:

- **Consumer type-check broken** — intentionally broken until commits 7–8 migrate consumers. This is acceptable because breaking changes are approved and all changes ship in one PR.

**Commit message**: `feat: rewrite editors to form-based fields with validate`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented — only `DataTableEditableCell.tsx` errors (expected, fixed in Commit 4)
- [x] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 4: Rewrite DataTableEditableCell with form submission, children, isSaving, submitOnBlur

**What**: Replace the `value` + `editor` callback pattern with a form-based `<Popover>` that wraps editor fields in a `<form>`. Click-outside triggers `requestSubmit()` when `submitOnBlur` is true (React Spectrum pattern). Escape cancels. Explicit Save/Cancel buttons always visible. `children` replaces `value` prop. `isSaving` shows loading state on trigger.

**Files to create**: None

**Files to edit**:

- `packages/ui-v2/src/components/data-table/DataTableEditableCell.tsx` — full rewrite:

New props interface:

```typescript
export interface DataTableEditableCellProps {
  row: Row<any>;
  field: string;
  children: React.ReactNode;
  editor?: EditorMeta;
  isSaving?: boolean;
  submitOnBlur?: boolean;
  onSave?: (rowId: string, field: string, value: unknown) => void;
  className?: string;
}
```

Key implementation details:
- Wraps editor field inside `<form ref={formRef}>` element
- `onSubmit` handler: `e.preventDefault()`, extracts value via `new FormData(e.currentTarget).get(field)`, parses number for currency variant, runs `validate` if present, calls `onSave` or falls back to `table.editing?.onSave` from context
- Popover `onInteractOutside`: when `submitOnBlur` is true (default), calls `formRef.current?.requestSubmit()` and prevents popover close (form submit handler closes it). When false, simply closes the popover (cancel behavior).
- Escape key: always cancels (closes without submitting)
- Save/Cancel button row rendered below the editor field
- `isSaving`: when true, shows a spinner/loading indicator on the edit trigger button
- If `editor` prop is not provided, reads from column `meta.editor` via context (for manual `EditableCell` usage that still wants to leverage column-level config)
- Preserves the `useEditingStore` external store pattern for performance

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `requestSubmit()` not supported in older browsers | LOW | All target browsers support it (Chrome 76+, Firefox 75+, Safari 16+). The prototype targets modern browsers only. |
| Popover positioning breaks when form elements resize | LOW | Test with text input expanding and select dropdown opening |
| Race condition: submitOnBlur triggers while select option click is propagating | MEDIUM | Ensure select editor's option click calls `form.requestSubmit()` synchronously before the interact-outside handler fires |
| `children` vs `value` breaks existing consumers | HIGH | All consumers updated in commits 7–8 |

**Verification**:

```bash
cd packages/ui-v2 && pnpm tsc --noEmit
```

Note: Consumer apps will fail type-check until commits 7–8.

**If it fails**:

- **"Property 'value' does not exist"**: This means old consumers haven't been migrated yet — expected until commits 7–8
- **Popover doesn't close after save**: Check that `close()` is called after `onSave` in the form submit handler

**Deviations from the gate**:

- **Consumer type-check broken** — intentionally broken until commits 7–8 migrate consumers

**Commit message**: `feat: rewrite EditableCell with form-based submission`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented — ui-v2 compiles with zero errors, no lint issues
- [x] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 5: Auto-render editors from meta.editor in DataTableContent

**What**: When a column has `meta.editor` defined and uses the default cell renderer (no custom `cell` function), `DataTableContent` automatically wraps the cell value in `<DataTableEditableCell>` with the editor from `meta.editor`. Columns with custom `cell` renderers are unaffected (escape hatch).

**Files to create**: None

**Files to edit**:

- `packages/ui-v2/src/components/data-table/DataTableContent.tsx` — in the `FlatRow` cell rendering loop, add auto-editor logic:

```typescript
// Current:
{flexRender(cell.column.columnDef.cell, cell.getContext())}

// New (pseudocode):
const editorMeta = cell.column.columnDef.meta?.editor;
const hasCustomCell = typeof cell.column.columnDef.cell === 'function';

if (editorMeta && !hasCustomCell) {
  // Auto-wrap: render default value inside EditableCell
  <DataTableEditableCell row={row} field={cell.column.id} editor={editorMeta}>
    {flexRender(cell.column.columnDef.cell, cell.getContext())}
  </DataTableEditableCell>
} else {
  // Existing behavior: render custom cell or default
  {flexRender(cell.column.columnDef.cell, cell.getContext())}
}
```

Also apply the same logic in the grouped rendering path if it renders cells similarly.

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| `hasCustomCell` detection is wrong for `accessorFn` columns | MEDIUM | TanStack generates a default `cell` for accessor columns. Check `cell.column.columnDef.cell !== undefined` instead of `typeof === 'function'` |
| Auto-wrapped cell doesn't pass correct `defaultValue` to editor | LOW | Ensure `cell.getValue()` is used to get the current value for the editor's `defaultValue` |
| Performance: wrapping every cell in EditableCell adds overhead | LOW | Only columns with `meta.editor` are wrapped. Non-editable columns are untouched. |

**Verification**:

```bash
cd packages/ui-v2 && pnpm tsc --noEmit
```

**If it fails**:

- **"Cannot find module './DataTableEditableCell'"**: Ensure the import is added at the top of `DataTableContent.tsx`
- **Cells render double-wrapped**: Check that the condition `!hasCustomCell` correctly identifies default vs custom cell renderers

**Deviations from the gate**:

- **None expected**

**Commit message**: `feat: auto-render editors from meta.editor in Content`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented — DataTableContent.tsx has zero type errors and zero lint issues. Pre-existing `size="icon"` error in Table.tsx is unrelated.
- [x] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 6: Update index.ts and types.ts exports ✅

**What**: Update the barrel exports to reflect the new API surface. Export `EditorMeta` and updated `DataTableEditableCellProps`. Keep factory function exports (`textEditor`, `currencyEditor`, `selectEditor`) which now return `EditorMeta` objects. Remove the old `CellEditor` and `EditorContext` type exports.

**Files to create**: None

**Files to edit**:

- `packages/ui-v2/src/components/data-table/index.ts` — update:
  - Keep: `export { textEditor, currencyEditor, selectEditor } from './editors'`
  - Add: `export { resolveEditorField } from './editors'` (for custom escape hatch usage)
  - Existing `DataTable.EditableCell` assignment remains unchanged

- `packages/ui-v2/src/components/data-table/types.ts` — update:
  - Remove: `export type { EditorContext, CellEditor, SelectOption } from './editors'`
  - Add: `export type { EditorMeta, SelectOption } from './types'` (if not already re-exported)
  - Add: `export type { DataTableEditableCellProps } from './DataTableEditableCell'` (updated type)

**Files to delete**: None

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Removing `CellEditor` export breaks consumers that import it | HIGH | All consumers must be migrated in commits 7–8. Verify no other files import `CellEditor`. |
| Circular import between types.ts and editors.tsx | LOW | `types.ts` defines `EditorMeta` and `SelectOption`; `editors.tsx` imports from `types.ts`. One-directional. |

**Verification**:

```bash
cd packages/ui-v2 && pnpm tsc --noEmit
```

**If it fails**:

- **"Module has no exported member 'CellEditor'"**: Expected — consumers need migration (commits 7–8)
- **Circular dependency**: Ensure `editors.tsx` imports from `./types` but `types.ts` does not import from `./editors`

**Deviations from the gate**:

- **Consumer type-check broken** — resolves in commits 7–8

**Commit message**: `refactor: update editable cell exports for v2 API`

**Status**:

- [ ] Quality gate checklist satisfied
- [ ] Tests green or deviation documented
- [ ] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 7: Migrate ServerSideDemo.tsx to meta.editor ✅

**What**: Convert `ServerSideDemo.tsx` from per-column `DataTable.EditableCell` with `editor={...}` callback pattern to column-level `meta.editor` declarative config with centralized `config.editing.onSave`.

**Files to create**: None

**Files to edit**:

- `apps/prototype/src/modules/demo/ServerSideDemo.tsx`:

Remove:
- `textEditor`, `selectEditor` imports
- Hoisted editor instances (`DATE_EDITOR`, `DESCRIPTION_EDITOR`, `TYPE_EDITOR`)
- Custom `cell` renderers that wrap `DataTable.EditableCell` for editable columns (`invoiceDate`, `description`, `type`, `dateDue`)

Add:
- `meta: { editor: { variant: 'text' } }` on `invoiceDate`, `description`, `dateDue` columns
- `meta: { editor: { variant: 'select', options: [...] } }` on `type` column
- `config: { editing: { onSave: handleFieldSave } }` in `useDataTable` options

For columns that need custom display formatting (e.g., `type` showing a `<Badge>`), keep a custom `cell` renderer but remove the `DataTable.EditableCell` wrapper — the custom renderer becomes the escape hatch, and `meta.editor` still defines the editor variant. The `DataTableContent` will NOT auto-wrap because a custom `cell` is present, so the consumer must use `<DataTable.EditableCell>` manually for those columns.

**Files to delete**: None

**Quality gate checklist**:

- [x] Public API / behavior for this commit is stable
- [x] Documentation or comments are updated where this commit changes behavior
- [x] Verification covers the main behavior and likely regression
- [x] No unrelated or secret-bearing files are included
- [x] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| Columns with custom display (Badge for type) lose edit affordance | MEDIUM | These columns must keep `<DataTable.EditableCell>` in their custom cell renderer, using the new `children` + `editor` props |
| `handleFieldSave` signature mismatch with centralized `onSave` | LOW | Current: `(rowId, field, value)`. New centralized: same signature. Should be compatible. |

**Verification**:

```bash
cd apps/prototype && pnpm tsc --noEmit
```

Manual: Open ServerSideDemo page. Click editable cells. Verify:
- Text cells (date, description, due date) open editor, save on Enter, cancel on Escape
- Type cell (badge) opens select editor, selecting an option saves
- Click outside saves (submitOnBlur default behavior)
- Server mutation fires on save

**If it fails**:

- **"Property 'editor' does not exist"**: Import `DataTable.EditableCell` is using old props. Verify the new `DataTableEditableCellProps` is being used.
- **"Property 'value' does not exist"**: Replace `value={...}` with `children` (JSX children).

**Deviations from the gate**:

- **None expected**

**Commit message**: `refactor: migrate ServerSideDemo to meta.editor`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### Commit 8: Migrate DataTableDemo.tsx and InvoicesTable.tsx to meta.editor

**What**: Convert the remaining two consumer files from the old `editor={...}` callback pattern to the new `meta.editor` + centralized `config.editing.onSave` approach.

**Files to create**: None

**Files to edit**:

- `apps/prototype/src/modules/demo/DataTableDemo.tsx`:
  - Remove `textEditor`, `currencyEditor`, `selectEditor` imports and inline `editor={textEditor()}` / `editor={currencyEditor()}` / `editor={selectEditor(statusOptions)}` usage
  - Add `meta: { editor: { variant: 'text' } }` on supplier column
  - Add `meta: { editor: { variant: 'currency' } }` on amount column
  - Add `meta: { editor: { variant: 'select', options: statusOptions } }` on status column
  - Move per-column `onSave` callbacks to centralized `config.editing.onSave` in `useDataTable`
  - For columns with custom display (e.g., `MoneyCell`, `StatusBadge`), keep custom `cell` with `<DataTable.EditableCell>` using `children` pattern

- `apps/prototype/src/modules/financial/invoices/InvoicesTable.tsx`:
  - Same migration pattern as `ServerSideDemo.tsx` (commit 7)
  - Remove hoisted `DATE_EDITOR`, `DESCRIPTION_EDITOR`, `TYPE_EDITOR`
  - Add `meta.editor` on columns, centralize `handleFieldSave` via `config.editing.onSave`

**Files to delete**: None

**Quality gate checklist**:

- [ ] Public API / behavior for this commit is stable
- [ ] Documentation or comments are updated where this commit changes behavior
- [ ] Verification covers the main behavior and likely regression
- [ ] No unrelated or secret-bearing files are included
- [ ] Rollback path is clear

**Risks**:

| Risk | Severity | What to check |
|------|----------|---------------|
| DataTableDemo uses per-column onSave with different update logic per field | MEDIUM | The centralized `onSave` must handle the generic `(rowId, field, value)` signature. Per-column custom logic moves into the centralized handler via field-name switching. |
| InvoicesTable `PurchaseInvoiceType` enum values in select options | LOW | Ensure the enum values are preserved as string option values in `meta.editor.options` |

**Verification**:

```bash
cd apps/prototype && pnpm tsc --noEmit
cd packages/ui-v2 && pnpm tsc --noEmit
```

Manual: Open DataTableDemo and InvoicesTable pages. Verify all editable cells work:
- Text, currency, select editors open and save
- Click outside saves (submitOnBlur)
- Escape cancels
- Custom display cells (MoneyCell, StatusBadge) still render correctly

**If it fails**:

- **Per-column save logic lost**: Move the field-specific update logic into the centralized `onSave` callback using a switch or if-else on the `field` parameter
- **MoneyCell/StatusBadge not rendering**: Ensure custom `cell` renderers are preserved for display-only columns; `meta.editor` handles the editing, not the display

**Deviations from the gate**:

- **None expected**

**Commit message**: `refactor: migrate DataTableDemo and InvoicesTable to meta.editor`

**Status**:

- [x] Quality gate checklist satisfied
- [x] Tests green or deviation documented
- [x] Build / lint / type-check green or deviation documented — only pre-existing `size="icon"` error in DataTableDemo.tsx (line 355) and Table.tsx, plus unrelated Helpers.ts missing module errors
- [ ] Manual verification complete, if applicable
- [ ] Committed

---

### PR 1 Checkpoint

Push PR 1 and wait for CI or the relevant automated checks to pass before continuing.

```bash
git push -u origin feature/editable-cell-v2
# Create PR targeting main
# Wait for CI to complete successfully
```

**This validates**: The full editable cell V2 API compiles, lints, and all 3 consumers work with the new `meta.editor` + form-based pattern. No runtime regressions in editable cell behavior.

**Manual checkpoint**:

- [ ] PR description matches the commit scope
- [ ] CI passes or failures are explained
- [ ] All 3 consumer files type-check cleanly
- [ ] Editable cells in ServerSideDemo work (text, select, submit-on-blur)
- [ ] Editable cells in DataTableDemo work (text, currency, select)
- [ ] Editable cells in InvoicesTable work (text, select)
- [ ] Auto-rendered editors (columns without custom `cell`) work
- [ ] Escape hatch (columns with custom `cell` + manual `EditableCell`) works
- [ ] Rollback instructions are clear (revert branch)

**Status**:

- [ ] PR created
- [ ] CI passes
- [ ] Reviewed
- [ ] Merged or approved to continue

---

## 4. Final Verification

After all 8 commits, run the full suite:

```bash
cd packages/ui-v2 && pnpm tsc --noEmit 2>&1 | tee /tmp/editable-v2-tsc-final.txt
cd apps/prototype && pnpm tsc --noEmit 2>&1 | tee /tmp/editable-v2-proto-tsc-final.txt
```

Compare against baselines:

```bash
diff /tmp/editable-v2-tsc-before.txt /tmp/editable-v2-tsc-final.txt
diff /tmp/editable-v2-proto-tsc-before.txt /tmp/editable-v2-proto-tsc-final.txt
```

**Manual verification**:

- [ ] ServerSideDemo: click date cell -> editor opens -> type value -> Enter saves -> mutation fires
- [ ] ServerSideDemo: click type cell -> select editor -> pick option -> saves immediately
- [ ] ServerSideDemo: click description cell -> edit -> click outside -> saves (submitOnBlur)
- [ ] ServerSideDemo: click cell -> Escape -> closes without saving
- [ ] DataTableDemo: currency editor works with number parsing
- [ ] DataTableDemo: status select editor with StatusBadge display
- [ ] InvoicesTable: all editable columns functional
- [ ] Columns without `meta.editor` are NOT wrapped in EditableCell
- [ ] Columns with custom `cell` renderer + `meta.editor` use escape hatch correctly
- [ ] No console errors or warnings

**Expected result**: All 3 consumer files use the new `meta.editor` column-level config. Editable cells use form-based submission with `FormData`. Submit-on-blur works by default. The old `CellEditor` callback pattern is fully removed from the codebase.

**Final status**:

- [ ] All 8 commits complete
- [ ] Build passes
- [ ] Lint passes
- [ ] Type-check passes for both `packages/ui-v2` and `apps/prototype`
- [ ] Manual verification complete
- [ ] PR created and ready for merge

---

## 5. Team Communication

Send to the team before merging:

> **Heads up: DataTable.EditableCell API rewrite**
>
> PR [link] rewrites the editable cell system in `packages/ui-v2`. After pulling:
>
> 1. Run `pnpm install` (no new dependencies)
> 2. If you have local branches with `DataTable.EditableCell` usage, you'll need to migrate:
>    - Replace `editor={textEditor()}` with `meta: { editor: { variant: 'text' } }` on column definition
>    - Replace `value={...}` prop with `children`
>    - Move per-column `onSave` to centralized `config: { editing: { onSave: ... } }` in `useDataTable`
>
> Files that changed and may conflict:
> - `packages/ui-v2/src/components/data-table/editors.tsx`
> - `packages/ui-v2/src/components/data-table/DataTableEditableCell.tsx`
> - `packages/ui-v2/src/components/data-table/DataTableContent.tsx`
> - `packages/ui-v2/src/components/data-table/types.ts`
> - `apps/prototype/src/modules/demo/ServerSideDemo.tsx`
> - `apps/prototype/src/modules/demo/DataTableDemo.tsx`
> - `apps/prototype/src/modules/financial/invoices/InvoicesTable.tsx`
>
> Known deviations or follow-ups:
> - Row-level editing (`editDisplayMode: 'row'`) is not yet implemented — the architecture supports it as a future additive change
> - `isSaving` per-cell state management (tracking which cell is currently saving) is left to the consumer

---

## 6. What's Next

After Editable Cell V2 is merged, the following enhancements can be added without breaking changes:

### Row-level editing (additive)

Add `config.editing.displayMode: 'cell' | 'row'` to `DataTableOptions`. Row mode wraps all editable cells in a single `<form>`. `FormData` collects all field values. Add `onRowSave(rowId, values)` callback. Column-level `meta.editor` configs are reused unchanged.

### Additional editor variants (additive)

Add new variants to the `EditorMeta` discriminated union: `date`, `multiSelect`, `combobox`, `textarea`. Each new variant is a new union branch — no breaking changes.

### isSaving state management (additive)

Add `config.editing.isSaving: Set<string>` or similar to track which cells are currently saving. Auto-pass `isSaving` to EditableCell based on `${rowId}:${field}` membership.

### Lessons to carry forward

- Form-based value extraction (`FormData`) is more robust than local state for submit-on-blur because the value is always in the DOM
- Column-level declarative config (`meta.editor`) eliminates 80% of boilerplate for standard editor types
- The escape hatch (custom `cell` + manual `EditableCell`) is essential for non-standard displays (badges, formatted amounts)
- `requestSubmit()` on interact-outside is the cleanest submit-on-blur pattern — it triggers native form validation and the `onSubmit` handler

### Known lessons from prior phases

- Column definitions should not contain controlled state (Ant Design lesson from Phase 0)
- Context-based instance sharing keeps compound components clean (MRT lesson from Phase 0)
- Feature flags (`enable*`) are the right granularity for feature activation (Phase 0)

---

## Execution Log

Record notes, issues, verification results, and deviations here as you go.

| Date | Commit | Notes |
|------|--------|-------|
| | 1 | |
| | 2 | |
| 2026-06-19 | 3 | Full rewrite of editors.tsx. Removed EditorContext/CellEditor callback pattern. Added TextEditorField, CurrencyEditorField, SelectEditorField form-compatible components with `name` attributes. Added resolveEditorField dispatcher. Factory functions now return EditorMeta objects. Removed EditorContext/CellEditor re-export from types.ts. tsc confirms only DataTableEditableCell.tsx error (expected). |
| 2026-06-19 | 4 | Full rewrite of DataTableEditableCell.tsx. Replaced value+editor callback with form-based submission (children, EditorMeta, resolveEditorField). Added isSaving loading state, submitOnBlur via Radix onInteractOutside (default true), Escape always cancels. Save/Cancel buttons for text/currency; select submits immediately. Context fallback for onSave via table.editing?.onSave. tsc zero errors, no lint issues. |
| | 5 | |
| | 6 | |
| | 7 | |
| | 8 | |
