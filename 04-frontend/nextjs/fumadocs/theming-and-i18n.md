# Fumadocs — Theming and i18n

How Fumadocs UI handles theming, hydration, host-app CSS interop, and locales.

**Sources**: [Fumadocs UI — Theme](https://www.fumadocs.dev/docs/ui/theme), [Fumadocs Core — i18n](https://www.fumadocs.dev/docs/headless/internationalization)

---

## Table of Contents

1. [`RootProvider`](#1-rootprovider)
2. [`fumadocs-ui/style.css`](#2-fumadocs-uistylecss)
3. [Tailwind v4 interop](#3-tailwind-v4-interop)
4. [Hosting Fumadocs in an app with its own design tokens](#4-hosting-fumadocs-in-an-app-with-its-own-design-tokens)
5. [i18n setup](#5-i18n-setup)
6. [`slots` and customization escape hatches](#6-slots-and-customization-escape-hatches)

---

## 1. `RootProvider`

`RootProvider` (from `fumadocs-ui/provider`) wraps the entire app body and supplies:

- **Theme switching** (light / dark / system) — toggles a class on `<html>`
- **Search dialog** (Cmd+K binding, calls `/api/search`)
- **Sidebar / nav state** the layouts share
- **Hydration boundary** for the above

```tsx
// app/layout.tsx
import 'fumadocs-ui/style.css';
import { RootProvider } from 'fumadocs-ui/provider';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
```

**`suppressHydrationWarning` on `<html>` is required** because `RootProvider` mutates `<html class="dark">` on the client based on the saved theme. Without it, React logs a hydration mismatch on first paint.

`RootProvider` is a **client component**; the layout itself stays a server component.

---

## 2. `fumadocs-ui/style.css`

A single CSS bundle that ships:

- Base typography for MDX (headings, lists, tables, code blocks)
- Layout chrome (sidebar, nav, search dialog)
- Theme tokens (Fumadocs-defined CSS variables for color, radius, spacing)
- Light / dark mode rules

Import it **once**, in the root layout. The order matters when other CSS imports exist:

```tsx
// app/layout.tsx
import 'fumadocs-ui/style.css'; // Fumadocs first
import './globals.css';          // then app overrides (host tokens, page-level styles)
```

Importing `fumadocs-ui/style.css` more than once or after late page styles can cause specificity surprises (your `globals.css` rules silently lose to Fumadocs base rules).

---

## 3. Tailwind v4 interop

Fumadocs ships its own CSS variables and base styles, **not** a Tailwind plugin. For Tailwind v4 apps:

- Fumadocs' base styles live in its own `style.css` — they do **not** depend on your Tailwind config
- Your Tailwind utilities work inside MDX content (e.g. `<div className="grid grid-cols-2">`) the same as anywhere
- Your `@theme` tokens (Tailwind v4) are independent of Fumadocs theme tokens

If you want Fumadocs chrome to **match** your app's theme, set Fumadocs CSS variables in your own stylesheet **after** the Fumadocs import, e.g.:

```css
/* app/globals.css, after `import 'fumadocs-ui/style.css'` */
:root {
  --color-fd-primary: var(--my-brand-500);
  --color-fd-background: var(--my-surface);
}
```

(See the Fumadocs theme docs for the canonical variable names — they evolve between versions.)

---

## 4. Hosting Fumadocs in an app with its own design tokens

When the host app (e.g. SNDQ's `apps/docs/` consuming `@sndq/config/tailwind/*`) already defines a token system, two strategies:

### A. Keep Fumadocs chrome on its own tokens (recommended default)

- Don't override Fumadocs CSS variables
- Author MDX with Fumadocs' base typography
- Use **your own components** (rendered inside MDX or referenced from `apps/docs/src/components/`) when you need to **showcase** the host design system — so the showcased components look like the product, while Fumadocs chrome stays consistent with other Fumadocs sites

### B. Theme Fumadocs chrome to match the host

- Map Fumadocs' theme variables to your host tokens (snippet in §3)
- Keep typography overrides minimal — Fumadocs tunes line-height and rhythm carefully
- Risk: Fumadocs may rename / restructure its variables across major versions; you re-map on upgrade

For **internal** docs that document a design system, **A** is usually right: developers see the host components rendered inside neutral chrome, which prevents visual confusion ("is the tab style from Fumadocs or from us?").

---

## 5. i18n setup

Fumadocs supports multi-locale docs via `loader()`'s `i18n` option and parallel content folders.

Minimal sketch:

```ts
// src/lib/source.ts
import { loader } from 'fumadocs-core/source';
import { i18n } from '@/lib/i18n';
import { docs } from '../../.source';

export const source = loader({
  baseUrl: '/',
  i18n,
  source: docs.toFumadocsSource(),
});
```

```ts
// src/lib/i18n.ts
import type { I18nConfig } from 'fumadocs-core/i18n';

export const i18n: I18nConfig = {
  defaultLanguage: 'en',
  languages: ['en', 'fr', 'nl', 'de'],
  // hideLocale: 'default-locale' // optional UX
};
```

Content folders are organized per locale (e.g. `content/docs/en/...`, `content/docs/fr/...`) — see the official docs for the exact convention in the version you install.

### When **not** to enable i18n

- Single-language internal docs → adds routing complexity and a language switcher you do not need
- Translation pipeline isn't ready → empty locales create broken sidebar entries
- Audience is fully English (e.g. engineering team) and the **product** is multilingual — translate the product, not its dev docs

Add i18n when you have a translator workflow in place and a real audience demand. Removing it later is straightforward; adding it on day 1 to "be ready" rarely pays off.

---

## 6. `slots` and customization escape hatches

`fumadocs-ui` layouts accept a `slots` (and similar) prop to **inject custom regions** without forking the layout:

- Custom sidebar header / footer
- Custom nav links beyond the built-in `links` prop
- Custom theme switch UI
- Replace the language switcher

When a layout's built-in props don't cover what you need, `slots` is the first thing to reach for before deciding to compose your own layout from `fumadocs-core` + `fumadocs-ui` primitives.

For deeper customization, you can also:

- Compose your own layout using `fumadocs-core` (page tree, breadcrumbs, search dialog) and skip `fumadocs-ui` layouts entirely
- Replace `RootProvider` with a custom provider that wires only the parts you need
- Override individual `DocsPage` / `DocsBody` styles via `className` props

Trade-off ladder, lightest first: **layout props** → **`slots`** → **custom layout from core primitives** → **headless Fumadocs (no `fumadocs-ui`)**.
