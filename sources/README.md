# Sources

Original PDF files and documents — organized by type for easy AI retrieval.

## Structure

| Folder | What goes here | Examples |
|--------|---------------|----------|
| [books/](./books/) | Technical books, textbooks | DDIA, Clean Code, CLRS |
| [papers/](./papers/) | Academic papers, whitepapers | Google MapReduce, Amazon Dynamo |
| [guides/](./guides/) | Tutorials, guides, cheat sheets | AWS Well-Architected, K8s cheat sheet |
| [misc/](./misc/) | Anything else | Slides, reports, misc documents |

## Naming Convention

Use `kebab-case` for filenames:
- `designing-data-intensive-applications.pdf`
- `google-mapreduce-2004.pdf`
- `aws-well-architected-framework.pdf`

## Index

### Books

| File | Title | Author | Domain | Notes Created |
|------|-------|--------|--------|---------------|
| `books/alexander-shvets-dive-into-refactoring-2019.pdf` | Dive Into Refactoring | Alexander Shvets | 01-fundamentals | [Yes](../01-fundamentals/refactoring/dive-into-refactoring.md) |
| `books/clean-code-a-handbook-of-agile-software-craftmanship.pdf` | Clean Code | Robert C. Martin | 01-fundamentals | [Yes](../01-fundamentals/clean-code/clean-code.md) |
| `books/kyle-simpson-you-dont-know-js.pdf` | You Don't Know JS (1st Ed.) | Kyle Simpson | 03-languages | [Yes](../03-languages/javascript/you-dont-know-js.md) |
| `books/eric-t-freeman-elisabeth-robson-head-first-javascript-programming-a-brain-friendly-guide-o-reilly-media-2014.pdf` | Head First JavaScript Programming | Eric T. Freeman & Elisabeth Robson | 03-languages | [Yes](../03-languages/javascript/head-first-javascript-programming.md) |
| `books/gayle-laakmann-mcdowell-cracking-the-coding-interview-189-programming-questions-and-solutions-careercup-2015.pdf` | Cracking the Coding Interview (6th Ed.) | Gayle Laakmann McDowell | 10-soft-skills | [Yes](../10-soft-skills/interviewing/cracking-the-coding-interview.md) |
| `books/how-to-land-big-tech-jobs.pdf` | How I Landed 10+ Big Tech Interviews Without Applying | Evgeny Shigol | 10-soft-skills | [Yes](../10-soft-skills/interviewing/how-to-land-big-tech-jobs.md) |
| `books/learning-patterns-final-v11.pdf` | Learning Patterns | Lydia Hallie & Addy Osmani | 04-frontend | [Yes](../04-frontend/react/learning-patterns.md) |
| `books/learning-react-modern-patterns-for-developing-react-apps-alex-banks-eve-porcello-oreilly-media-2020.pdf` | Learning React (2nd Ed.) | Alex Banks & Eve Porcello | 04-frontend | [Yes](../04-frontend/react/learning-react.md) |
| `books/michael-morrison-head-first-javascript-oreilly-media-2008.pdf` | Head First JavaScript | Michael Morrison | 03-languages | No |

### Papers

| File | Title | Author/Org | Year | Domain | Notes Created |
|------|-------|------------|------|--------|---------------|
| _No papers yet_ | | | | | |

### Guides

| File | Title | Source | Domain | Notes Created |
|------|-------|--------|--------|---------------|
| _No guides yet_ | | | | |

## Tools

### `rename-to-kebab-case.sh` — PDF Filename Enforcer

Scans all PDFs under `sources/` and renames any that don't follow the kebab-case convention.

**Kebab-case rule:** filenames must match `[a-z0-9]+(-[a-z0-9]+)*.pdf` — all lowercase, words separated by hyphens, no spaces or special characters.

#### How to use

**1. Dry-run (preview only — no files are changed):**

```bash
./sources/rename-to-kebab-case.sh
```

Example output:

```
=== PDF Kebab-Case Rename Check ===
    Directory: /Users/admin/projects/private/research/sources
    Mode: DRY-RUN (preview only)

  ✗ Michael Morrison - Head First JavaScript-O'Reilly Media (2008).pdf
    → michael-morrison-head-first-javascript-oreilly-media-2008.pdf

  ✓ clean-code-a-handbook-of-agile-software-craftmanship.pdf
---
Total PDFs scanned: 6
Non-compliant: 1
```

**2. Apply (actually rename files):**

```bash
./sources/rename-to-kebab-case.sh --apply
```

**3. Via Cursor/VS Code Command Palette:**

1. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
2. Type **"Tasks: Run Task"**
3. Select one of:
   - **Rename PDFs to kebab-case (dry-run)** — preview only
   - **Rename PDFs to kebab-case (apply)** — rename files

#### What the script does

| Step | Description |
|------|-------------|
| 1 | Finds all `.pdf` files recursively under `sources/` |
| 2 | Checks each filename against the kebab-case pattern |
| 3 | For non-compliant files: lowercases, replaces spaces/underscores with hyphens, strips special characters |
| 4 | Uses two-step rename (file → file.tmp → final) to handle macOS case-insensitive filesystem |
| 5 | Skips if target filename already exists (prevents accidental overwrites) |

> **Important:** After renaming, manually update any markdown references that point to the old filename (check `sources/README.md`, `references/books.md`, and notes files).

---

## Workflow

1. Drop a PDF into the appropriate subfolder
2. Run `./sources/rename-to-kebab-case.sh` to check naming — apply if needed
3. Update this index with the file details
4. Ask AI: "Read `sources/books/xyz.pdf` and create notes"
5. AI reads → summarizes → creates notes in the relevant domain folder (01-11)
6. Notes will link back to the original PDF via relative path
