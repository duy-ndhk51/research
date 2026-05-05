# Progress tracker — Portfolio 2026

Check off steps in order within each phase. After completing a phase, run the linked manual test file and note the completion date in the **Manual test run** line for that phase.

**Agent hint:** Keep [current-focus.md](./current-focus.md) in sync with the next 1–3 unchecked items when ending a session.

**Phase A status:** **Deferred** — deploy is on hold until the Vercel account (or another host) is available. Work continues with **Phase B — Content and IA**; resume Phase A when hosting is unblocked. See [decisions.md](./decisions.md).

---

## Phase A — Go live

**Goal:** Production URL, env vars, smoke routes, accurate public `site.config.ts` (no starter social/domain placeholders in user-facing surfaces).

**While deferred:** Until deploy is unblocked, optional local smoke only (`pnpm dev`, `pnpm build`) if you want a sanity check; production URL and prod env steps stay unchecked.

- [ ] Pick host (e.g. Vercel) and connect the Git repo or deploy from CLI
- [ ] Set production env: Notion token and any vars required by the app README
- [ ] Run production build smoke: home loads, no 500 on cold start
- [ ] Update `site.config.ts`: domain, author, description, social handles to real values
- [ ] Verify OG or social preview on one blog post (debugger or “view source”)
- [ ] Fill **Production URL** in [snapshot.md](./snapshot.md)

**Commit hints (examples, ≤50 chars):** `chore: add vercel env for notion`, `fix: align site config with live domain`

**Manual test run:** [manual-tests/phase-a-deploy-and-smoke.md](./manual-tests/phase-a-deploy-and-smoke.md) — completed: _date: ___ / notes: ___

---

## Phase B — Content and IA

**Goal:** Reliable Notion publishing workflow; navigation matches intent (`navigationStyle` default vs `custom` + `navigationLinks` in `site.config.ts`).

- [x] Document which Notion pages are public vs draft (workflow for yourself) — see [notion-publishing-workflow.md](./notion-publishing-workflow.md); fill the tables for your workspace
- [ ] Confirm blog index lists expected posts only — run `/blogs` locally and complete the verification table in [notion-publishing-workflow.md](./notion-publishing-workflow.md)
- [x] Decide default vs custom navigation; implement in `site.config.ts` if custom — **default** retained; see [decisions.md](./decisions.md)
- [x] Add or trim footer/header links for legal or contact if needed — **none** for MVP; optional trim: remove debug `test` button in portfolio `Footer.tsx` before launch; see [decisions.md](./decisions.md)

**Commit hints:** `feat: add custom notion nav links`, `docs: notion publish checklist`

**Manual test run:** [manual-tests/phase-b-notion-content.md](./manual-tests/phase-b-notion-content.md) — completed: _date: ___ / notes: ___

---

## Phase C — UX baseline

**Goal:** Readable typography, spacing, keyboard and mobile usability, consistent dark/light theme across home and blog.

- [ ] Pass readability on long post (line length, headings hierarchy)
- [ ] Keyboard focus order and visible focus styles on interactive elements
- [ ] Mobile viewport (narrow) — home and blog post without horizontal scroll breakage
- [ ] Theme toggle or system theme: verify `use-dark-mode` (or equivalent) on home + blog

**Commit hints:** `fix: improve focus styles on blog`, `style: tune notion prose spacing`

**Manual test run:** [manual-tests/phase-c-ux-a11y-theme.md](./manual-tests/phase-c-ux-a11y-theme.md) — completed: _date: ___ / notes: ___

---

## Phase D — Motion and reference parity

**Goal:** Deliberate motion using `motion` package; respect `prefers-reduced-motion`; optional dock/hover patterns (`components/ui/Dock.tsx` if used).

- [ ] Inventory which surfaces get motion (home, blog list, page transitions)
- [ ] Implement reduced-motion branch or CSS media query for non-essential animation
- [ ] Add stagger or enter animation for blog list (if desired)
- [ ] Optional: scroll-linked or hero motion on home — keep performance budget in mind

**Commit hints:** `feat: add blog list stagger animation`, `fix: respect reduced motion`

**Manual test run:** [manual-tests/phase-d-motion.md](./manual-tests/phase-d-motion.md) — completed: _date: ___ / notes: ___

---

## Cross-references

| Topic | Related notes |
|-------|----------------|
| MVP scope | [mvp-roadmap.md](./mvp-roadmap.md) |
| Stack baseline | [snapshot.md](./snapshot.md) |
| ADRs | [decisions.md](./decisions.md) |
