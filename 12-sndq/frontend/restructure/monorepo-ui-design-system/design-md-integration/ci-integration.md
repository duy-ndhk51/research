# CI Integration Points

---

## Phase 2: Basic validation

Add to the monorepo CI pipeline after DESIGN.md is created:

```yaml
# .github/workflows/design-system.yml (or add to existing CI)
- name: Lint DESIGN.md
  run: npx @google/design.md lint DESIGN.md
```

This catches:
- Broken token references when tokens are renamed/removed
- Missing primary color
- Structural issues (duplicate sections, wrong section order)

---

## Phase 3: Regression gating

Add diff-based regression detection to PRs that touch `DESIGN.md`:

```yaml
- name: Check DESIGN.md regressions
  if: contains(github.event.pull_request.changed_files, 'DESIGN.md')
  run: |
    git show origin/dev:DESIGN.md > /tmp/DESIGN-base.md
    npx @google/design.md diff /tmp/DESIGN-base.md DESIGN.md
```

Exit code 1 blocks the PR if the change introduces new errors or warnings (regressions).

---

## Optional: Export drift detection

Monthly or per-release, verify DESIGN.md tokens match the actual `tokens.css`:

```bash
npx @google/design.md export --format tailwind DESIGN.md > /tmp/generated-theme.json
# Custom script to compare generated theme against @sndq/config/tailwind/tokens.css
```
