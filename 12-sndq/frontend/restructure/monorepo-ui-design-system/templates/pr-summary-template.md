# PR Summary Template

Copy-paste template for component PR summaries. Fill in each section, delete anything that does not apply.

Save the completed summary to `pr-summaries/{component-name}.md`.

---

## Template

```markdown
# {ComponentName} — PR Summary

**Component:** `{ComponentName}` · **Tier:** {1 (Primitive) | 2 (Block) | 3 (Pattern)}

## Design decisions

- **Foundation** — {e.g. Radix primitive, fully custom, composition of existing primitives}
- **Token classes** — {list SNDQ component classes used and what they apply to}
- **Icon usage** — {Icon component with size/variant, or N/A}
- **Key patterns** — {e.g. indicator approach, asChild support, portal strategy, animation method}
- {Add or remove bullets as needed}

## Documentation

MDX page at `apps/docs/content/docs/primitives/{component-name}.mdx`:

| Section | Content |
|---------|---------|
| Hero | {Story playground, inline demos} |
| Overview | {Purpose, import, when to use / when not to use} |
| Composition | {Component tree if compound component} |
| Usage | {List subsections, e.g. Basic, With icons, Controlled} |
| Styling | {CSS class table, className contract, animation description} |
| API | {Props tables for sub-components} |
| Edge cases | {Viewport, focus, disabled, etc.} |
| Related | {Links to related components} |

## Test coverage

**`{ComponentName}.test.tsx`** — {N} unit tests:
- {list what's covered, grouped by sub-component}

**`{ComponentName}.integration.test.tsx`** — {N} integration tests:
- {list what's covered}

{If only one test file is needed, delete the other. See `templates/tests/ui-v2-test-templates.md` Section 5.3 for the split file convention.}

## Token/CSS changes

{List any additions or modifications to shared config files (`packages/config/tailwind/`). If none, write "No shared token changes."}

## Review checklist

- [ ] Token classes match `components.css` definitions
- [ ] Icon component used consistently (no raw icon library imports in JSX)
- [ ] MDX live demos are `'use client'` and import from the barrel `index.ts`
- [ ] Unit tests are synchronous; integration tests use userEvent
- [ ] Shared token changes do not break existing consumers
- [ ] {Add component-specific checks as needed}
```

---

## Related templates

- [docs-templates.md](docs-templates.md) — MDX page templates (Template A: components, Template B: blocks)
- [docs-rules.md](docs-rules.md) — documentation authoring rules
- [tests/ui-v2-test-templates.md](tests/ui-v2-test-templates.md) — test file templates and conventions
