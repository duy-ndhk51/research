# Monorepo Overview

A pnpm workspace monorepo for shared UI components, app development, and centralized tooling.

## Folder Structure

```
sndq/
├── sndq-fe/             # Main frontend application (kept at root)
├── apps/
│   └── prototype/       # UI prototype/component playground (sndq-ui-v2)
│
├── packages/
│   ├── ui/              # Shared UI component library (@sndq/ui)
│   ├── config/          # Shared configs: ESLint, Prettier, Tailwind tokens
│   └── tsconfig/        # Shared TypeScript base configs
│
├── package.json
├── pnpm-workspace.yaml  # Workspace definition
├── lerna.json
└── README.md
```

## Package Responsibilities

### sndq-fe

Main production frontend application (kept at root to avoid conflicts with other developers).

### apps/prototype

Sandbox environment for testing and previewing UI components.

### packages/ui

Reusable components, blocks, and shared UI primitives.

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
sndq-fe ──────────────┐
                      ├──▶ @sndq/ui
apps/prototype ───────┘

@sndq/ui ─────────────▶ @sndq/config

sndq-fe ──────────────▶ @sndq/config
sndq-fe ──────────────▶ @sndq/tsconfig
apps/prototype ───────▶ @sndq/config
apps/prototype ───────▶ @sndq/tsconfig
```

## Related Documents

- [ticket.md](./ticket.md) — Linear ticket summary
- [README.md](./README.md) — full architecture specification (target structure, config contents, component classification, migration phases)
