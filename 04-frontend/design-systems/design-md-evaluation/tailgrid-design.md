# TailGrids v3 — Style Reference
> Crisp Open Canvas: A clean, airy light-mode interface built for scale — precise structure, confident typography, and a bold blue accent that guides without overwhelming.

**Theme:** light (dark mode supported via Figma variables)

TailGrids v3 embodies a production-grade design system philosophy: structured clarity over decorative flair. The interface rests on a near-white canvas (`#FFFFFF` / `#F9FAFB`) with a tightly organized neutral palette drawn directly from Tailwind CSS's gray scale. Typography is set in Inter across all UI layers, with well-defined size and weight steps that scale from captions to display headings. The system's single dominant accent — a confident indigo-blue (`#3758F9`) — drives primary actions, active states, and focus indicators, while semantic colors (green for success, red for error, amber for warning, sky for info) provide role-specific signaling. The overall density is comfortable yet efficient, leveraging an 8px base unit and consistent 8px border radius to give components a modern, approachable roundness without sacrificing precision.

## Tokens — Colors

### Brand / Primary

| Name | Value | Token | Role |
|------|-------|-------|------|
| Primary | `#3758F9` | `--color-primary` | Primary brand color. Used for main CTAs, active link states, focus rings, and interactive highlights. |
| Primary Dark | `#1B44C8` | `--color-primary-dark` | Hover/pressed state for primary interactive elements. |
| Primary Light | `#EEF2FF` | `--color-primary-light` | Tinted backgrounds for primary context — highlight rows, selected states, badge fills. |

### Neutral / Gray

| Name | Value | Token | Role |
|------|-------|-------|------|
| White | `#FFFFFF` | `--color-white` | Primary page and card background. The base canvas of the design system. |
| Gray 50 | `#F9FAFB` | `--color-gray-50` | Alternate page background and subtle section fills. Slightly off-white to create structure. |
| Gray 100 | `#F3F4F6` | `--color-gray-100` | Input backgrounds, table zebra rows, sidebar fill, and secondary surface layer. |
| Gray 200 | `#E5E7EB` | `--color-gray-200` | Border color for dividers, card outlines, and input field borders. |
| Gray 300 | `#D1D5DB` | `--color-gray-300` | Stronger borders, disabled element outlines, and separator lines. |
| Gray 400 | `#9CA3AF` | `--color-gray-400` | Placeholder text, icon default state, and de-emphasized labels. |
| Gray 500 | `#6B7280` | `--color-gray-500` | Secondary body text, captions, metadata, and helper text. |
| Gray 600 | `#4B5563` | `--color-gray-600` | Mid-weight descriptive text and subheadings. |
| Gray 700 | `#374151` | `--color-gray-700` | Secondary heading text and prominent descriptive content. |
| Gray 800 | `#1F2937` | `--color-gray-800` | Primary body text and heading text. |
| Gray 900 | `#111827` | `--color-gray-900` | Highest-contrast text, page titles, and critical labels. |
| Black | `#090E34` | `--color-black` | Deep headline color with a slight navy cast for brand warmth. Used for hero headings and display text. |

### Semantic — Status Colors

| Name | Value | Token | Role |
|------|-------|-------|------|
| Success | `#22C55E` | `--color-success` | Positive feedback, completion states, success alerts, and "done" iconography. |
| Success Dark | `#16A34A` | `--color-success-dark` | Text and icon color within success alerts or high-contrast success indicators. |
| Success Light | `#F0FDF4` | `--color-success-light` | Background fill for success banners, inline alert backgrounds, and success badge fills. |
| Warning | `#F59E0B` | `--color-warning` | Cautionary alerts, pending states, and informational warnings requiring user attention. |
| Warning Dark | `#D97706` | `--color-warning-dark` | Text and icon color within warning components for readable contrast on light fills. |
| Warning Light | `#FFFBEB` | `--color-warning-light` | Background fill for warning banners and alert containers. |
| Danger | `#EF4444` | `--color-danger` | Destructive actions, error states, validation failures, and critical alerts. |
| Danger Dark | `#DC2626` | `--color-danger-dark` | Text and icon color within error components for high-contrast readability. |
| Danger Light | `#FEF2F2` | `--color-danger-light` | Background fill for error banners, inline error containers. |
| Info | `#0EA5E9` | `--color-info` | Informational callouts, tips, and non-critical system notifications. |
| Info Dark | `#0284C7` | `--color-info-dark` | Text and icon color for info components. |
| Info Light | `#F0F9FF` | `--color-info-light` | Background fill for info banners and notification containers. |

### Extended Accent Palette

| Name | Value | Token | Role |
|------|-------|-------|------|
| Indigo 500 | `#6366F1` | `--color-indigo` | Secondary accent for badges, tags, and decorative highlights alongside the primary blue. |
| Purple 500 | `#A855F7` | `--color-purple` | Used in gradient accents and select category indicators in dashboard contexts. |
| Pink 500 | `#EC4899` | `--color-pink` | Decorative highlight in marketing contexts and AI/creative product sections. |
| Teal 500 | `#14B8A6` | `--color-teal` | Data visualization accent and secondary status color in dashboard and analytics blocks. |

## Tokens — Typography

### Inter — Primary UI typeface for all content: headings, body text, labels, and interactive elements. Clean geometric letterforms with exceptional screen legibility across all weights. · `--font-sans`
- **Substitute:** System UI, -apple-system, sans-serif
- **Weights:** 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
- **Sizes:** 12px, 13px, 14px, 15px, 16px, 18px, 20px, 24px, 30px, 36px, 48px, 60px, 72px
- **Line height:** 1.20, 1.25, 1.33, 1.40, 1.50, 1.60, 1.75
- **Letter spacing:** -0.02em (display), -0.01em (headings), 0em (body), 0.01em (captions), 0.05em (overlines/labels)
- **OpenType features:** `"cv01", "cv03", "cv04"`
- **Role:** Primary UI typeface for all content. Used across headings, body copy, labels, navigation, and interactive elements.

### JetBrains Mono — Monospaced typeface for code blocks, technical tokens, and data values where character alignment and technical clarity are required. · `--font-mono`
- **Substitute:** Fira Code, IBM Plex Mono, Consolas
- **Weights:** 400, 500
- **Sizes:** 12px, 13px, 14px
- **Line height:** 1.40, 1.60
- **Letter spacing:** 0em
- **Role:** Code snippets, technical documentation, inline code, and any data display requiring monospaced alignment.

### Type Scale

| Role | Size | Weight | Line Height | Letter Spacing | Token |
|------|------|--------|-------------|----------------|-------|
| label / overline | 12px | 500–600 | 1.40 | 0.05em | `--text-label` |
| caption | 12px | 400 | 1.50 | 0.01em | `--text-caption` |
| body-sm | 13px | 400 | 1.60 | 0em | `--text-body-sm` |
| body | 14px | 400 | 1.60 | 0em | `--text-body` |
| body-lg | 16px | 400 | 1.60 | 0em | `--text-body-lg` |
| lead | 18px | 400–500 | 1.75 | 0em | `--text-lead` |
| heading-sm | 20px | 600 | 1.40 | -0.01em | `--text-heading-sm` |
| heading | 24px | 600–700 | 1.33 | -0.01em | `--text-heading` |
| heading-lg | 30px | 700 | 1.25 | -0.02em | `--text-heading-lg` |
| heading-xl | 36px | 700 | 1.25 | -0.02em | `--text-heading-xl` |
| display | 48px | 700 | 1.20 | -0.02em | `--text-display` |
| display-lg | 60px | 700 | 1.20 | -0.02em | `--text-display-lg` |
| display-xl | 72px | 700–800 | 1.20 | -0.02em | `--text-display-xl` |

## Tokens — Spacing & Shapes

**Base unit:** 4px (Tailwind spacing scale — `1 unit = 0.25rem`)

**Density:** comfortable (standard Tailwind defaults)

### Spacing Scale

| Name | Value | Tailwind Class | Token |
|------|-------|---------------|-------|
| 1 | 4px | `p-1` | `--spacing-1` |
| 2 | 8px | `p-2` | `--spacing-2` |
| 3 | 12px | `p-3` | `--spacing-3` |
| 4 | 16px | `p-4` | `--spacing-4` |
| 5 | 20px | `p-5` | `--spacing-5` |
| 6 | 24px | `p-6` | `--spacing-6` |
| 7 | 28px | `p-7` | `--spacing-7` |
| 8 | 32px | `p-8` | `--spacing-8` |
| 10 | 40px | `p-10` | `--spacing-10` |
| 12 | 48px | `p-12` | `--spacing-12` |
| 14 | 56px | `p-14` | `--spacing-14` |
| 16 | 64px | `p-16` | `--spacing-16` |
| 20 | 80px | `p-20` | `--spacing-20` |
| 24 | 96px | `p-24` | `--spacing-24` |
| 32 | 128px | `p-32` | `--spacing-32` |

### Border Radius

| Element | Value | Token |
|---------|-------|-------|
| none | 0px | `--radius-none` |
| sm | 4px | `--radius-sm` |
| default | 8px | `--radius-md` |
| lg | 12px | `--radius-lg` |
| xl | 16px | `--radius-xl` |
| 2xl | 24px | `--radius-2xl` |
| full / pill | 9999px | `--radius-full` |

### Shadows

| Name | Value | Token |
|------|-------|-------|
| xs | `0px 1px 2px 0px rgba(9, 14, 52, 0.06)` | `--shadow-xs` |
| sm | `0px 1px 3px 0px rgba(9, 14, 52, 0.10), 0px 1px 2px 0px rgba(9, 14, 52, 0.06)` | `--shadow-sm` |
| md | `0px 4px 6px -1px rgba(9, 14, 52, 0.10), 0px 2px 4px -1px rgba(9, 14, 52, 0.06)` | `--shadow-md` |
| lg | `0px 10px 15px -3px rgba(9, 14, 52, 0.10), 0px 4px 6px -2px rgba(9, 14, 52, 0.05)` | `--shadow-lg` |
| xl | `0px 20px 25px -5px rgba(9, 14, 52, 0.10), 0px 10px 10px -5px rgba(9, 14, 52, 0.04)` | `--shadow-xl` |
| 2xl | `0px 25px 50px -12px rgba(9, 14, 52, 0.25)` | `--shadow-2xl` |
| inner | `inset 0px 2px 4px 0px rgba(9, 14, 52, 0.06)` | `--shadow-inner` |

### Layout

- **Container max-width:** 1280px (xl breakpoint)
- **Section vertical gap:** 80px–96px
- **Card padding:** 24px (default), 16px (compact)
- **Element gap (within component):** 8px–12px
- **Grid columns:** 12-column, 16px gutter (desktop); 4-column, 16px gutter (mobile)
- **Breakpoints:** sm 640px, md 768px, lg 1024px, xl 1280px, 2xl 1536px

## Components

### Primary Button
**Role:** Main call-to-action element

Filled button with `#3758F9` (Primary) background, white text, 8px border-radius, `10px 24px` padding. Font weight 500, size 14–16px. On hover, transitions to `#1B44C8` (Primary Dark). Used exclusively for the single most important action per view.

### Secondary Button
**Role:** Supporting actions alongside a primary CTA

Outlined button with transparent background, `#3758F9` border (1.5px), `#3758F9` text, 8px border-radius, `10px 24px` padding. On hover, fills with `#EEF2FF` (Primary Light). Used for secondary actions that complement but don't compete with the primary button.

### Ghost Button
**Role:** Tertiary actions, in-line interactive triggers

Transparent background and border, `#374151` (Gray 700) text, 8px border-radius, `10px 16px` padding. On hover, background becomes `#F3F4F6` (Gray 100). Used for less prominent actions, toggles, and cancel/dismiss patterns.

### Danger Button
**Role:** Destructive or irreversible actions

Filled button with `#EF4444` (Danger) background, white text, 8px border-radius, `10px 24px` padding. On hover, transitions to `#DC2626` (Danger Dark). Exclusively for delete, remove, or destructive operations.

### Default Card
**Role:** Content container for general UI blocks

White background (`#FFFFFF`), 8px border-radius, `1px solid #E5E7EB` (Gray 200) border, and `--shadow-sm` outer shadow. Padding of 24px all sides. The foundational surface unit for content grouping.

### Elevated Card
**Role:** Featured or promoted content container

White background, 12px border-radius, `--shadow-md` elevation, no explicit border. Padding 24px–32px. Used for pricing cards, feature highlights, and prominent content sections.

### Flat / Subtle Card
**Role:** Low-prominence content groupings

`#F9FAFB` (Gray 50) background, 8px border-radius, `1px solid #E5E7EB` border, no shadow. Padding 16px–24px. Used for secondary content panels, info boxes, and nested containers.

### Input Field
**Role:** Text entry and form fields

White background, `#374151` text (Gray 700), `#D1D5DB` border (Gray 300), 8px border-radius, `10px 14px` padding. Placeholder text in Gray 400. On focus, border switches to `#3758F9` (Primary) with a `0px 0px 0px 3px rgba(55, 88, 249, 0.12)` focus ring. Error state uses Danger border color.

### Select / Dropdown
**Role:** Choice selection from a defined list

Visually identical to Input Field. Chevron icon in Gray 400. Dropdown panel uses white background, `--shadow-lg`, 8px border-radius. Selected option highlights with Primary Light background.

### Checkbox
**Role:** Boolean selection within forms

16px × 16px control. Unchecked: White fill, `1.5px solid #D1D5DB` border, 4px border-radius. Checked: `#3758F9` fill, white checkmark icon. Focus state has a Primary-colored focus ring. Indeterminate state uses a dash mark.

### Radio Button
**Role:** Single-choice selection within a group

20px × 20px control. Unchecked: White fill, `1.5px solid #D1D5DB` border, `50%` border-radius. Selected: White fill, `#3758F9` outer border (1.5px), `#3758F9` inner filled circle (10px). Focus state has a Primary-colored focus ring.

### Toggle / Switch
**Role:** Binary enable/disable control

40px × 22px track. Off state: `#D1D5DB` (Gray 300) track, white thumb. On state: `#3758F9` track, white thumb. Smooth sliding transition on toggle. Focus ring appears around the track.

### Badge / Tag
**Role:** Categorical label, status indicator, or count chip

Pill-shaped (`9999px` radius), `4px 10px` padding, 12px font size, weight 500. Available in color variants: Primary (blue fill + white text), Gray, Success, Warning, Danger, Info. Also available as an outlined variant using the respective color for border and text on a light tint background.

### Alert / Notification Banner
**Role:** System messages and contextual feedback

Full-width or inline container with rounded-md (8px) corners. Left accent border (4px) in the semantic color. Light semantic-color background (`*-light` tokens). Icon + heading + body text layout. Dismiss button (×) on right. Available in: Success, Warning, Danger, Info variants.

### Tooltip
**Role:** Contextual helper text on hover

Dark background (`#1F2937`, Gray 800), white text, 4px border-radius, 12px font size, `6px 10px` padding. 8px offset from trigger. Appears on hover/focus with a brief fade-in transition.

### Avatar
**Role:** User identity representation

Available in sizes: 24px, 32px, 40px, 48px, 56px, 64px, 80px, 96px. Circular (50% radius). Image variant shows user photo. Fallback shows initials on a semantic color background. Border variant uses 2px white ring with `--shadow-sm` for stack groups.

### Breadcrumb
**Role:** Hierarchical navigation trail

Horizontal list of links separated by `/` or `›` dividers. Link text in Gray 500, current page in Gray 800. 14px font size, weight 400 (links) / 500 (current). Spacing of 8px between items.

### Pagination
**Role:** Multi-page navigation control

Row of page number buttons. Default state: Gray 100 background, Gray 700 text, 8px radius. Active state: Primary background, white text. Prev/Next buttons: Ghost style with arrow icons. Ellipsis (`…`) for collapsed ranges.

### Table
**Role:** Structured data presentation

Full-width, white background. Header row: Gray 50 background, Gray 500 text, 12px all-caps font, weight 600. Body rows: white background, 1px Gray 200 bottom border, Gray 800 primary text, Gray 500 secondary text. Hover state: Gray 50 row background. Zebra striping optional via Gray 50 alternating rows.

### Tabs
**Role:** Section switching within a single view

Horizontal tab bar. Default tab: Gray 500 text, 14–16px weight 500. Active tab: Gray 900 text, 2px Primary bottom border. On hover: Gray 700 text. Underline variant (default) and pill variant (active tab: Primary Light background).

### Dropdown Menu
**Role:** Contextual action menu

White background, `--shadow-lg`, 8px border-radius, 1px Gray 200 border. Items: 14px Gray 700 text, `8px 16px` padding, 8px gap between icon and label. Hover state: Gray 50 background. Destructive items use Danger text. Dividers: 1px Gray 100 lines.

### Modal / Dialog
**Role:** Focused task or confirmation overlay

White panel, 12px–16px border-radius, `--shadow-2xl`, centered on a `rgba(17, 24, 39, 0.4)` backdrop. Widths: sm (400px), md (560px), lg (720px). Header: title (heading weight 600) + close button. Footer: right-aligned button group.

### Progress Bar
**Role:** Completion or loading indicator

Track: 8px height, Gray 200 background, 9999px radius. Fill: Primary color, smooth transition. Label above or below. Available in sm (4px), md (8px), lg (12px) heights. Semantic color variants available.

### Skeleton Loader
**Role:** Content placeholder during loading

Gray 200 background with a shimmering animation (`linear-gradient` sweep, 1.5s infinite). Rounded-md corners. Used to mirror the shape of loading content — paragraphs, cards, avatars, etc.

## Do's and Don'ts

### Do
- Use `#FFFFFF` for primary card and content backgrounds; `#F9FAFB` for page-level background fills to create subtle depth.
- Apply `#3758F9` (Primary) exclusively for the single most important action per screen — the CTA must stand alone.
- Use Inter at 14px / weight 400 / line-height 1.60 for all body copy, ensuring readability at normal reading distances.
- Maintain the 8px border-radius standard across buttons, cards, and inputs for a cohesive, rounded-but-precise aesthetic.
- Use Gray 800 (`#1F2937`) or Black (`#090E34`) for primary headings and display text; reserve Gray 500 for supporting text.
- Layer surfaces using White → Gray 50 → Gray 100 to establish visual hierarchy without reaching for shadows.
- Apply semantic status colors (success, warning, danger, info) only for their designated communicative role — never decoratively.
- Use `--shadow-sm` for cards, `--shadow-md` for dropdowns, `--shadow-lg` for modals — increase elevation with shadow weight.
- Respect the 12-column grid with 16px gutters; never place interactive content outside the defined container max-width of 1280px.
- Pair the Primary accent with Primary Light (`#EEF2FF`) for hover/selected states on list items, table rows, and navigation items.

### Don't
- Do not use more than one filled primary button per view; secondary and tertiary actions must use lower-weight button styles.
- Avoid placing gray text on gray backgrounds — always ensure at least 4.5:1 contrast ratio for WCAG AA compliance.
- Do not use the extended accent palette (indigo, purple, pink, teal) for interactive elements; reserve them for data viz and decorative contexts.
- Avoid custom border-radii that deviate from the defined scale — do not use 5px, 10px, or 15px as one-offs.
- Do not use shadows to create depth on flat surface transitions; rely on background color steps (white → gray-50 → gray-100) first.
- Avoid tight letter-spacing (`-0.02em`) on body text; negative tracking is reserved for display and large heading sizes only.
- Do not mix multiple typeface families — Inter is the sole typeface for all UI; JetBrains Mono is exclusively for code/data.
- Avoid full-saturation red for decorative elements; Red/Danger is exclusively a semantic error color.
- Do not create modal stacks deeper than 2 levels; nested modals violate the focused-task intent of the component.
- Avoid disabling buttons without a clear visual disabled state (opacity 40%, not-allowed cursor); never hide unavailable actions entirely.

## Elevation

- **Flat Surface:** No shadow — background color differentiation (Gray 50 / Gray 100) creates implied layers.
- **Cards / Default Elevation:** `--shadow-sm` — `0px 1px 3px rgba(9, 14, 52, 0.10), 0px 1px 2px rgba(9, 14, 52, 0.06)`
- **Dropdowns / Selects:** `--shadow-md` — `0px 4px 6px -1px rgba(9, 14, 52, 0.10), 0px 2px 4px -1px rgba(9, 14, 52, 0.06)`
- **Popovers / Tooltips:** `--shadow-lg` — `0px 10px 15px -3px rgba(9, 14, 52, 0.10), 0px 4px 6px -2px rgba(9, 14, 52, 0.05)`
- **Modals / Dialogs:** `--shadow-2xl` — `0px 25px 50px -12px rgba(9, 14, 52, 0.25)`
- **Focus Ring (Primary):** `0px 0px 0px 3px rgba(55, 88, 249, 0.20)` — applied on interactive element focus.

## Surfaces

- **White Canvas** (`#FFFFFF`) — Default card and content surface. The primary workspace.
- **Gray 50 Page** (`#F9FAFB`) — Page-level background and alternate section fills. Provides gentle separation from white cards.
- **Gray 100 Recessed** (`#F3F4F6`) — Input backgrounds, table headers, sidebar panels, and inner container fills.
- **Gray 200 Border** (`#E5E7EB`) — Universal border and divider color. Applied to all separating lines and structural outlines.
- **Primary Light** (`#EEF2FF`) — Highlighted state surface for selected rows, active navigation items, and tag backgrounds.

## Imagery

TailGrids v3's visual language centers on clean UI mockups, component previews, and product screenshots embedded in device frames. Illustrations, where used, are flat and geometric — using the primary blue alongside gray and white for a consistently on-brand feel. Icons are line-style, 20×20px or 24×24px, from a unified icon family (Heroicons or custom SVG), rendered in Gray 500 (default) or Primary (active/selected). Marketing imagery uses photography only in contained aspect-ratio boxes (16:9 for hero, 4:3 for feature cards) with no full-bleed decorative photography. Gradient elements are subtle and functional — typically a single-axis fade from Primary to Indigo, used selectively in hero sections and gradient badge fills.

## Layout

TailGrids v3 follows a standard responsive grid layout. Desktop views use a 12-column grid within a 1280px max-width container centered on the page. The page background is Gray 50 (`#F9FAFB`), with white cards creating a lifted, layered feel. The navigation bar is sticky, white with a bottom `--shadow-sm` border. Sidebar navigation (application contexts) is 256px wide, white, with a right-side 1px Gray 200 border. Content sections alternate between white and Gray 50 backgrounds for visual rhythm in marketing layouts. Spacing between major page sections is 80px–96px. Component-level spacing follows the 8px base unit: internal padding is typically 16–24px, element gaps 8–12px.

## Similar Brands

- **Tailwind UI** — Clean white-canvas components with a primary blue accent, Inter typography, and a thorough gray neutral scale for hierarchy.
- **Shadcn/UI** — Neutral-first component library with semantic color tokens and a similar comfortable-density design philosophy.
- **Radix Themes** — Systematic neutral palette, Inter typeface, accessible-first component design with semantic semantic color application.
- **Linear (light mode)** — Precise typographic hierarchy, clear information density, and restrained use of a single primary accent color.
- **Vercel (light)** — Clean white canvas, strong typographic contrast, and structural use of gray scale for surface layering.

---

## CSS Variables Reference

### CSS Custom Properties

```css
:root {
  /* Brand Colors */
  --color-primary: #3758F9;
  --color-primary-dark: #1B44C8;
  --color-primary-light: #EEF2FF;

  /* Neutral / Gray */
  --color-white: #FFFFFF;
  --color-gray-50: #F9FAFB;
  --color-gray-100: #F3F4F6;
  --color-gray-200: #E5E7EB;
  --color-gray-300: #D1D5DB;
  --color-gray-400: #9CA3AF;
  --color-gray-500: #6B7280;
  --color-gray-600: #4B5563;
  --color-gray-700: #374151;
  --color-gray-800: #1F2937;
  --color-gray-900: #111827;
  --color-black: #090E34;

  /* Semantic — Success */
  --color-success: #22C55E;
  --color-success-dark: #16A34A;
  --color-success-light: #F0FDF4;

  /* Semantic — Warning */
  --color-warning: #F59E0B;
  --color-warning-dark: #D97706;
  --color-warning-light: #FFFBEB;

  /* Semantic — Danger */
  --color-danger: #EF4444;
  --color-danger-dark: #DC2626;
  --color-danger-light: #FEF2F2;

  /* Semantic — Info */
  --color-info: #0EA5E9;
  --color-info-dark: #0284C7;
  --color-info-light: #F0F9FF;

  /* Extended Accents */
  --color-indigo: #6366F1;
  --color-purple: #A855F7;
  --color-pink: #EC4899;
  --color-teal: #14B8A6;

  /* Typography — Font Families */
  --font-sans: 'Inter', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;

  /* Typography — Scale */
  --text-label: 12px;
  --leading-label: 1.40;
  --tracking-label: 0.05em;

  --text-caption: 12px;
  --leading-caption: 1.50;
  --tracking-caption: 0.01em;

  --text-body-sm: 13px;
  --leading-body-sm: 1.60;

  --text-body: 14px;
  --leading-body: 1.60;
  --tracking-body: 0em;

  --text-body-lg: 16px;
  --leading-body-lg: 1.60;

  --text-lead: 18px;
  --leading-lead: 1.75;

  --text-heading-sm: 20px;
  --leading-heading-sm: 1.40;
  --tracking-heading-sm: -0.01em;

  --text-heading: 24px;
  --leading-heading: 1.33;
  --tracking-heading: -0.01em;

  --text-heading-lg: 30px;
  --leading-heading-lg: 1.25;
  --tracking-heading-lg: -0.02em;

  --text-heading-xl: 36px;
  --leading-heading-xl: 1.25;
  --tracking-heading-xl: -0.02em;

  --text-display: 48px;
  --leading-display: 1.20;
  --tracking-display: -0.02em;

  --text-display-lg: 60px;
  --leading-display-lg: 1.20;
  --tracking-display-lg: -0.02em;

  --text-display-xl: 72px;
  --leading-display-xl: 1.20;
  --tracking-display-xl: -0.02em;

  /* Typography — Weights */
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  /* Spacing (Tailwind 4px base) */
  --spacing-1: 4px;
  --spacing-2: 8px;
  --spacing-3: 12px;
  --spacing-4: 16px;
  --spacing-5: 20px;
  --spacing-6: 24px;
  --spacing-7: 28px;
  --spacing-8: 32px;
  --spacing-10: 40px;
  --spacing-12: 48px;
  --spacing-14: 56px;
  --spacing-16: 64px;
  --spacing-20: 80px;
  --spacing-24: 96px;
  --spacing-32: 128px;

  /* Layout */
  --container-max: 1280px;
  --section-gap: 80px;
  --card-padding: 24px;
  --card-padding-compact: 16px;
  --element-gap: 8px;

  /* Border Radius */
  --radius-none: 0px;
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-2xl: 24px;
  --radius-full: 9999px;

  /* Named Radii */
  --radius-buttons: 8px;
  --radius-inputs: 8px;
  --radius-cards: 8px;
  --radius-badges: 9999px;
  --radius-tags: 4px;
  --radius-modals: 12px;

  /* Shadows */
  --shadow-xs: 0px 1px 2px 0px rgba(9, 14, 52, 0.06);
  --shadow-sm: 0px 1px 3px 0px rgba(9, 14, 52, 0.10), 0px 1px 2px 0px rgba(9, 14, 52, 0.06);
  --shadow-md: 0px 4px 6px -1px rgba(9, 14, 52, 0.10), 0px 2px 4px -1px rgba(9, 14, 52, 0.06);
  --shadow-lg: 0px 10px 15px -3px rgba(9, 14, 52, 0.10), 0px 4px 6px -2px rgba(9, 14, 52, 0.05);
  --shadow-xl: 0px 20px 25px -5px rgba(9, 14, 52, 0.10), 0px 10px 10px -5px rgba(9, 14, 52, 0.04);
  --shadow-2xl: 0px 25px 50px -12px rgba(9, 14, 52, 0.25);
  --shadow-inner: inset 0px 2px 4px 0px rgba(9, 14, 52, 0.06);
  --shadow-focus-primary: 0px 0px 0px 3px rgba(55, 88, 249, 0.20);

  /* Surfaces */
  --surface-canvas: #FFFFFF;
  --surface-page: #F9FAFB;
  --surface-recessed: #F3F4F6;
  --surface-border: #E5E7EB;
  --surface-selected: #EEF2FF;
}
```

### Tailwind v4

```css
@theme {
  /* Brand Colors */
  --color-primary: #3758F9;
  --color-primary-dark: #1B44C8;
  --color-primary-light: #EEF2FF;

  /* Neutral / Gray */
  --color-white: #FFFFFF;
  --color-gray-50: #F9FAFB;
  --color-gray-100: #F3F4F6;
  --color-gray-200: #E5E7EB;
  --color-gray-300: #D1D5DB;
  --color-gray-400: #9CA3AF;
  --color-gray-500: #6B7280;
  --color-gray-600: #4B5563;
  --color-gray-700: #374151;
  --color-gray-800: #1F2937;
  --color-gray-900: #111827;
  --color-black: #090E34;

  /* Semantic */
  --color-success: #22C55E;
  --color-success-dark: #16A34A;
  --color-success-light: #F0FDF4;
  --color-warning: #F59E0B;
  --color-warning-dark: #D97706;
  --color-warning-light: #FFFBEB;
  --color-danger: #EF4444;
  --color-danger-dark: #DC2626;
  --color-danger-light: #FEF2F2;
  --color-info: #0EA5E9;
  --color-info-dark: #0284C7;
  --color-info-light: #F0F9FF;

  /* Extended Accents */
  --color-indigo: #6366F1;
  --color-purple: #A855F7;
  --color-pink: #EC4899;
  --color-teal: #14B8A6;

  /* Typography */
  --font-sans: 'Inter', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;

  /* Type Scale */
  --text-label: 12px;
  --text-caption: 12px;
  --text-body-sm: 13px;
  --text-body: 14px;
  --text-body-lg: 16px;
  --text-lead: 18px;
  --text-heading-sm: 20px;
  --text-heading: 24px;
  --text-heading-lg: 30px;
  --text-heading-xl: 36px;
  --text-display: 48px;
  --text-display-lg: 60px;
  --text-display-xl: 72px;

  /* Spacing */
  --spacing-1: 4px;
  --spacing-2: 8px;
  --spacing-3: 12px;
  --spacing-4: 16px;
  --spacing-5: 20px;
  --spacing-6: 24px;
  --spacing-7: 28px;
  --spacing-8: 32px;
  --spacing-10: 40px;
  --spacing-12: 48px;
  --spacing-14: 56px;
  --spacing-16: 64px;
  --spacing-20: 80px;
  --spacing-24: 96px;
  --spacing-32: 128px;

  /* Border Radius */
  --radius-none: 0px;
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-2xl: 24px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-xs: 0px 1px 2px 0px rgba(9, 14, 52, 0.06);
  --shadow-sm: 0px 1px 3px 0px rgba(9, 14, 52, 0.10), 0px 1px 2px 0px rgba(9, 14, 52, 0.06);
  --shadow-md: 0px 4px 6px -1px rgba(9, 14, 52, 0.10), 0px 2px 4px -1px rgba(9, 14, 52, 0.06);
  --shadow-lg: 0px 10px 15px -3px rgba(9, 14, 52, 0.10), 0px 4px 6px -2px rgba(9, 14, 52, 0.05);
  --shadow-xl: 0px 20px 25px -5px rgba(9, 14, 52, 0.10), 0px 10px 10px -5px rgba(9, 14, 52, 0.04);
  --shadow-2xl: 0px 25px 50px -12px rgba(9, 14, 52, 0.25);
  --shadow-inner: inset 0px 2px 4px 0px rgba(9, 14, 52, 0.06);
  --shadow-focus-primary: 0px 0px 0px 3px rgba(55, 88, 249, 0.20);
}
```