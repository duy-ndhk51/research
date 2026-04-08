# [Setup] Create Test Factory + zodResolver Smoke Test

**Type**: Task · `sndq-fe` · Zod v3 → v4 Migration Infrastructure
**Prerequisite**: `zod@3.25.76` installed (ships v3 + v4 engines)

---

## Objective

Create reusable test infrastructure for the Zod v3 → v4 migration:

1. **`schema-test-factory.ts`** — a `describeSchema()` factory that generates 3-4 snapshot tests per schema from fixtures
2. **`zod-resolver-compat.test.ts`** — regression guard for `zodResolver` + Zod compatibility

These 2 files are created **once**, then reused for every schema file during migration.

---

## Why

The most dangerous Zod v4 breaking change is **`.default()` short-circuiting** — it silently produces different parsed data with no TypeScript or runtime error. Schema snapshot tests are the only way to catch this.

| Risk | What Happens | Detection |
|------|-------------|-----------|
| `.default()` short-circuits parsing | Fields get default values when they shouldn't — wrong data saved silently | Schema snapshot diff |
| `.transform()` output changes | Computed values differ after migration | Schema snapshot diff |
| `zodResolver` breaks with v4 | All 100+ forms fail validation at once | Smoke test |

Upgraded to `@hookform/resolvers@5.2.2` with native Zod v4 `zodResolver` support (requires RHF >=7.55.0). Type errors from input/output inference resolved via centralized wrapper (`src/lib/form/zod-resolver.ts`). The smoke test is a **regression guard**, not a blocker.

---

## Deliverable A: `schema-test-factory.ts`

### Design

A factory function that generates a standard snapshot test suite for any Zod schema. Per-file boilerplate reduced to: imports + fixtures + one function call.



---

## Deliverable B: `zod-resolver-compat.test.ts`

### Context

Upgraded to `@hookform/resolvers@5.2.2` with native Zod v4 `zodResolver` support. Original v4.1.3 used `@standard-schema/utils`; v5.2.2 has direct Zod v4 integration. This test is a **regression guard**, not a blocker.

After full migration: change `import { z } from 'zod'` → `'zod/v4'`. If all 5 tests pass → confirmed safe.

---

## Deliverable C: 13 Schema Snapshot Tests (Just-in-Time)

### Approach

Instead of writing all 13 tests upfront, each test is written **immediately before migrating** that specific file. Benefits:

- Focus on 1 schema at a time (no context switching)
- No stale snapshots (test written right before migration)
- Each migrated file is a shippable unit
- Fixtures informed by reading the schema first

---

## Dangerous Patterns to Watch

| Pattern | Found In | Why Dangerous |
|---------|----------|---------------|
| `.optional().default([]).superRefine().transform()` | #11 (contact — emails, phones) | `.default()` short-circuit skips `.superRefine()` + `.transform()` in v4 |
| `.boolean().default(true/false)` in `z.object()` | #13 (lease — 8+ boolean defaults) | v4 may inject keys where v3 didn't when parent is optional |
| `z.array(subSchema).default([])` | #13 (lease — payers, extraCosts) | Array defaults may interact differently with parent object defaults |
| `createBuildingFormSchema(type)` | #5 (building) | Dynamic factory — needs testing with multiple workspace types |
| `nativeEnum` with `.Enum` / `.Values` | #4, #13, #9 | Runtime crash in v4 — needs systematic replacement |

---

## Notes

- `.snap` files must be committed to git — they are the v3 behavioral baseline
- Existing test fixtures (e.g., `purchase-invoice-v2/schema.test.ts`) can be reused to save fixture authoring time
- Schema snapshot tests run `safeParse()` only — no DOM, no API. Expected runtime: <2s for all 13 files
- AI agents can help generate fixture objects but review cross-field `superRefine` rules carefully
