# DESIGN.md — Benefits & Tradeoffs

Structured analysis of adopting DESIGN.md as a design system specification format. Each item includes evidence and, for tradeoffs, a mitigation strategy.

For the full feature set, see [features-overview.md](./features-overview.md).

---

## Table of Contents

1. [Benefits](#1-benefits)
2. [Tradeoffs](#2-tradeoffs)
3. [Net Assessment](#3-net-assessment)

---

## 1. Benefits

### 1.1 Single Source of Truth (Machine + Human)

| Aspect | Detail |
|--------|--------|
| **What** | One file contains both exact token values (YAML) and design rationale (prose) |
| **Why it matters** | Eliminates drift between documentation and implementation. No separate "design spec" PDF that goes stale. |
| **Evidence** | SNDQ currently has ~160 lines of duplicated CSS tokens between `sndq-fe/globals.css` and `sndq-ui-v2/globals.css`. DESIGN.md centralizes these in a single artifact that can generate both. |

### 1.2 AI Agent Awareness

| Aspect | Detail |
|--------|--------|
| **What** | DESIGN.md is the first design system format explicitly designed for AI coding agents |
| **Why it matters** | Agents reading the file produce UI that matches the design system without manual guidance. The `spec` command injects format context into agent prompts. |
| **Evidence** | The format was created by Google specifically for this use case. Prose sections give agents contextual understanding (brand personality, hierarchy intent) that pure token files cannot provide. |

### 1.3 Automated WCAG Validation

| Aspect | Detail |
|--------|--------|
| **What** | The `contrast-ratio` linting rule checks every component `backgroundColor`/`textColor` pair against WCAG AA (4.5:1 minimum) |
| **Why it matters** | Catches accessibility violations at design-time, before any code is written. Runs automatically in CI. |
| **Evidence** | The linter produces structured JSON findings with exact contrast ratios, making compliance auditable. |

### 1.4 Orphaned Token Detection

| Aspect | Detail |
|--------|--------|
| **What** | The `orphaned-tokens` rule flags color tokens that are defined but never referenced by any component |
| **Why it matters** | Keeps the token set lean. Dead tokens accumulate over time and create confusion about which values are actually in use. |
| **Evidence** | Common problem in mature design systems — tokens added for a feature that later changed, but the token definition remains. |

### 1.5 Tailwind Export Pipeline

| Aspect | Detail |
|--------|--------|
| **What** | `export --format tailwind` generates a Tailwind theme configuration directly from DESIGN.md tokens |
| **Why it matters** | Reduces manual token extraction. Write tokens once in DESIGN.md, generate CSS/Tailwind config automatically. |
| **Evidence** | The repo includes working examples with exported `tailwind.config.js` files (atmospheric-glass, paws-and-paths, totality-festival). |

### 1.6 Version Diffing for Design Regressions

| Aspect | Detail |
|--------|--------|
| **What** | The `diff` command compares two DESIGN.md files and reports token-level additions, removals, and modifications |
| **Why it matters** | Design system changes become reviewable in PRs. Detects unintended regressions (e.g., a color accidentally changed) before merge. |
| **Evidence** | Exit code 1 when regressions are detected (more errors/warnings in the "after" file), enabling automated CI gating. |

### 1.7 W3C DTCG Interoperability

| Aspect | Detail |
|--------|--------|
| **What** | `export --format dtcg` generates W3C Design Tokens Format `tokens.json` |
| **Why it matters** | Future-proofs tokens for interop with Figma Variables, Style Dictionary, Token Studio, and any tool adopting the W3C standard. |
| **Evidence** | DTCG is the emerging industry standard backed by W3C. Exporting to it means DESIGN.md tokens are not locked into one ecosystem. |

### 1.8 Declarative Component Contracts

| Aspect | Detail |
|--------|--------|
| **What** | Component tokens define exact visual properties (background, text color, radius, padding, height) per component and variant |
| **Why it matters** | Each component's visual spec is machine-verifiable. The `broken-ref` rule catches when a component references a deleted or renamed token. |
| **Evidence** | Component tokens support 8 properties and a flat variant convention (e.g., `button-primary`, `button-primary-hover`). Changes to referenced tokens propagate through the reference system. |

---

## 2. Tradeoffs

### 2.1 Alpha Status — Spec Is Actively Evolving

| Aspect | Detail |
|--------|--------|
| **Severity** | Medium |
| **Risk** | Breaking changes to the token schema, section order, or CLI API between versions |
| **Mitigation** | Pin `@google/design.md` to a specific version. Monitor the changelog. Wrap CLI calls in scripts that can be updated in one place. |
| **Timeline** | The spec is labeled "alpha" — expect stabilization within 6-12 months based on typical Google OSS cadence. |

### 2.2 Limited Component Properties (8 Only)

| Aspect | Detail |
|--------|--------|
| **Severity** | Medium |
| **Risk** | Cannot express `borderColor`, `borderWidth`, `gap`, `opacity`, `backdropFilter`, `boxShadow` as component tokens. Components needing these properties fall outside the token system. |
| **Mitigation** | Use prose sections for properties not covered by tokens. The spec accepts unknown component properties with a warning, so you can add custom properties at the cost of a lint warning. Submit feature requests to the repo for commonly needed properties. |
| **Example** | SNDQ's `.sndq-control` class uses `border`, `box-shadow`, and `gap` — these cannot be fully captured in component tokens today. |

### 2.3 No Dark Mode / Theme Variant Support in Tokens

| Aspect | Detail |
|--------|--------|
| **Severity** | Medium |
| **Risk** | The YAML schema has no concept of theme modes. A single DESIGN.md can only describe one visual state. |
| **Mitigation** | Option A: Maintain separate DESIGN.md files per theme (e.g., `DESIGN.md`, `DESIGN-dark.md`). Option B: Handle mode switching in CSS (`:root` / `.dark` vars) and keep DESIGN.md as the light-mode canonical source. Option C: Wait for the spec to add theme support. |
| **Example** | SNDQ uses `:root` and `.dark` CSS custom properties — this pattern would continue alongside DESIGN.md. |

### 2.4 Additional Artifact to Maintain

| Aspect | Detail |
|--------|--------|
| **Severity** | Low |
| **Risk** | DESIGN.md can drift from actual CSS if not kept in sync. Developers might update `tokens.css` without updating DESIGN.md, or vice versa. |
| **Mitigation** | CI lint enforces structural validity. Periodically run `export --format tailwind` and diff against actual config to detect drift. Consider making DESIGN.md the authoritative source and generating CSS from it (removes the drift problem entirely). |

### 2.5 YAML Front Matter Verbosity for Large Token Sets

| Aspect | Detail |
|--------|--------|
| **Severity** | Low |
| **Risk** | Design systems with many color scales (e.g., SNDQ has `brand-25` through `brand-900`, plus `neutral`, `success`, `warning`, `error` scales) produce long YAML blocks. |
| **Mitigation** | YAML supports this naturally — it is just verbose. Token naming conventions keep it organized. The lint `token-summary` rule provides a count overview. |
| **Example** | The atmospheric-glass example has 50+ color tokens in its YAML front matter — it works but is ~140 lines of YAML before the prose starts. |

### 2.6 No Figma Plugin (Yet)

| Aspect | Detail |
|--------|--------|
| **Severity** | Medium (for teams with heavy Figma workflows) |
| **Risk** | No direct sync between Figma designs and DESIGN.md. Changes in Figma must be manually reflected in the file. |
| **Mitigation** | Use the DTCG export as an intermediate format. Figma can import/export DTCG tokens via Token Studio or Variables. The round-trip is: DESIGN.md → `export --format dtcg` → tokens.json → Figma import. |
| **Note** | If the team does not use Figma heavily (or designers work directly in code), this tradeoff has low severity. |

### 2.7 No Runtime Integration

| Aspect | Detail |
|--------|--------|
| **Severity** | Low |
| **Risk** | DESIGN.md is a build/design-time artifact. It does not replace CSS-in-JS solutions, runtime theme providers, or Tailwind's JIT compiler. |
| **Mitigation** | This is by design — DESIGN.md generates artifacts (Tailwind config, DTCG tokens) that feed into runtime systems. It is a source-of-truth layer, not a runtime engine. |

---

## 3. Net Assessment

### Strongest value propositions

1. **Agent-optimized format** — No other design system specification is purpose-built for AI coding agents. As agent-assisted development grows, this becomes increasingly valuable.
2. **Automated quality gates** — WCAG contrast, broken references, orphaned tokens, and regression diffing provide guardrails that pure CSS token files lack.
3. **Interoperability via exports** — Tailwind and DTCG exports mean tokens written once in DESIGN.md can feed multiple consumers without manual translation.

### Biggest risks

1. **Alpha instability** — Production teams must accept the risk of format changes, mitigated by version pinning.
2. **Component token limitations** — 8 properties cover the basics but miss border, shadow, and layout properties that many design systems need.
3. **Dark mode gap** — Teams with multi-theme requirements need a workaround until the spec adds native support.

### Decision framework

| If your project... | Recommendation |
|---------------------|----------------|
| Uses AI agents for UI development | **Strong adopt** — this is the primary use case |
| Has a Tailwind-based design system | **Adopt** — the export pipeline directly reduces manual work |
| Needs multi-theme (light/dark) support | **Defer** until theme variants are in the spec, or accept the workaround |
| Has heavy Figma ↔ code sync workflows | **Evaluate carefully** — the DTCG roundtrip adds friction vs native Figma tooling |
| Needs runtime theme switching | **Complement, don't replace** — use alongside existing CSS/Tailwind infrastructure |
