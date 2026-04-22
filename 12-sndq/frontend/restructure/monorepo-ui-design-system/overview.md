# Monorepo Overview

A pnpm workspace monorepo for shared UI components, app development, and centralized tooling.

## Folder Structure

```
sndq/
├── sndq-fe/              # Main frontend application (kept at root)
├── apps/
│   ├── docs/             # Standalone docs site — standardized components only
│   └── prototype/        # UI prototype/component playground (sndq-ui-v2)
│
├── packages/
│   ├── ui-v2/            # Shared UI component library (@sndq/ui-v2)
│   ├── ui-v2-docs/       # Showcase infrastructure + demo sections (@sndq/ui-v2-docs)
│   ├── config/           # Shared configs: ESLint, Prettier, Tailwind tokens
│   └── tsconfig/         # Shared TypeScript base configs
│
├── package.json
├── pnpm-workspace.yaml   # Workspace definition
├── lerna.json
└── README.md
```

## Package Responsibilities

### sndq-fe

Main production frontend application (kept at root to avoid conflicts with other developers).

### apps/docs

Standalone documentation site for standardized components. Consumes `@sndq/ui-v2-docs` tabs as-is.

### apps/prototype

Experimental playground for testing and previewing UI components. Extends `@sndq/ui-v2-docs` with prototype content.

### packages/ui-v2

Reusable components (primitives) and blocks (compositions). Zero business logic.

### packages/ui-v2-docs

Showcase infrastructure (layout shells, tab components, demo sections, search) consumed by both `apps/docs/` and `apps/prototype/`.

### packages/config

Centralized tooling and design system configs:

- ESLint
- Prettier
- Tailwind CSS
- Design Tokens

### packages/tsconfig

Reusable TypeScript presets for:

- Base apps
- Next.js apps
- Libraries

## Dependency Flow

```
sndq-fe ────────────────▶ @sndq/ui-v2
apps/prototype ─────────▶ @sndq/ui-v2 + @sndq/ui-v2-docs
apps/docs ──────────────▶ @sndq/ui-v2-docs

@sndq/ui-v2-docs ───────▶ @sndq/ui-v2
@sndq/ui-v2 ────────────▶ @sndq/config
all apps + packages ────▶ @sndq/config + @sndq/tsconfig
```

## Related Documents

- [ticket.md](./ticket.md) — Linear ticket summary
- [README.md](./README.md) — full architecture specification (target structure, config contents, component classification)
- [migration-plan.md](./migration-plan.md) — five-phase gradual migration plan
