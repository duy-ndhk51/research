# Component Token Workflow

How component tokens integrate with the Phase 3 batch standardization process.

---

## Per-batch workflow (extended)

The existing Phase 3 [per-batch workflow](../migration-plan.md#6-phase-3-standardize--graduate-to-package) gains two additional steps:

```
1. Standardize in apps/ui-v2-dev/               (existing)
2. Graduate to packages/ui-v2/                   (existing)
3. Define component tokens in DESIGN.md          ← NEW
   - Add YAML entries for each component + variants
   - Reference existing color/typography/spacing tokens
4. Validate                                      ← NEW
   - Run: npx @google/design.md lint DESIGN.md
   - Check: 0 errors, 0 contrast warnings for new components
   - Run: npx @google/design.md diff DESIGN-prev.md DESIGN.md
   - Review: token changes match expected batch scope
5. Update agent config (AGENTS.md) if needed     ← NEW
   - Ensure packages/ui-v2/AGENTS.md lists the new components
   - Ensure apps/docs/AGENTS.md and apps/ui-v2-dev/AGENTS.md
     still accurately reference the DESIGN.md specification
6. Deprecate legacy counterparts                 (existing)
7. Verify                                        (existing)
```

> **Agent awareness**: AGENTS.md files in `apps/docs/`, `apps/ui-v2-dev/`, and `packages/ui-v2/` all reference `packages/ui-v2/DESIGN.md` so AI agents working in any of these directories can consult the design system spec. This was introduced in Commit 19 alongside the DESIGN.md file itself.

---

## Batch 1 component tokens (example)

After Batch 1 (Button, Input, Badge, Select, Dialog, Sheet) graduates:

```yaml
components:
  # Button
  button-primary:
    backgroundColor: "{colors.sndq-action}"
    textColor: "{colors.sndq-action-fg}"
    rounded: "{rounded.sndq-md}"
    padding: 12px
    height: "{spacing.control}"
  button-primary-hover:
    backgroundColor: "{colors.sndq-action-hover}"
  button-secondary:
    backgroundColor: "{colors.sndq-surface}"
    textColor: "{colors.sndq-text}"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"
  button-ghost:
    backgroundColor: transparent
    textColor: "{colors.sndq-text}"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"
  button-destructive:
    backgroundColor: "{colors.error-500}"
    textColor: "#FFFFFF"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"

  # Input
  input-default:
    backgroundColor: "{colors.sndq-surface}"
    textColor: "{colors.sndq-text}"
    typography: "{typography.body-md}"
    rounded: "{rounded.sndq-md}"
    height: "{spacing.control}"

  # Badge
  badge-neutral:
    backgroundColor: "{colors.neutral-100}"
    textColor: "{colors.neutral-700}"
    rounded: "{rounded.sndq-full}"
  badge-success:
    backgroundColor: "{colors.success-100}"
    textColor: "{colors.success-700}"
    rounded: "{rounded.sndq-full}"
  badge-error:
    backgroundColor: "{colors.error-100}"
    textColor: "{colors.error-700}"
    rounded: "{rounded.sndq-full}"
```

---

## What component tokens cannot express

Per the [benefits-tradeoffs analysis](../../../../04-frontend/design-systems/design-md-evaluation/benefits-tradeoffs.md#22-limited-component-properties-8-only), DESIGN.md component tokens only support 8 properties. SNDQ components also use:

| Missing property | Used by | Workaround |
|------------------|---------|------------|
| `borderColor` | Input, Select, Card | Document in Components prose |
| `borderWidth` | Input (focus ring) | Document in Components prose |
| `boxShadow` | Card, Dialog, Sheet, DropdownMenu | Document in Elevation prose |
| `gap` | ButtonGroup, ToggleGroup | Document in Layout prose |
| `opacity` | Disabled states | Document in Do's and Don'ts |
| `backdropFilter` | Dialog overlay, Sheet overlay | Document in Elevation prose |
