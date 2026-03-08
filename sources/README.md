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
| `books/alexander-shvets-dive-Into-refactoring-2019.pdf` | Dive Into Refactoring | Alexander Shvets | 01-fundamentals | [Yes](../01-fundamentals/refactoring/dive-into-refactoring.md) |
| `books/clean-code-a-handbook-of-agile-software-craftmanship.pdf` | Clean Code | Robert C. Martin | 01-fundamentals | [Yes](../01-fundamentals/clean-code/clean-code.md) |
| `books/kyle-simpson-you-dont-know-js.pdf` | You Don't Know JS (1st Ed.) | Kyle Simpson | 03-languages | [Yes](../03-languages/javascript/you-dont-know-js.md) |
| `books/how-to-land-big-tech-jobs.pdf` | How I Landed 10+ Big Tech Interviews Without Applying | Evgeny Shigol | 10-soft-skills | [Yes](../10-soft-skills/interviewing/how-to-land-big-tech-jobs.md) |

### Papers

| File | Title | Author/Org | Year | Domain | Notes Created |
|------|-------|------------|------|--------|---------------|
| _No papers yet_ | | | | | |

### Guides

| File | Title | Source | Domain | Notes Created |
|------|-------|--------|--------|---------------|
| _No guides yet_ | | | | |

## Workflow

1. Drop a PDF into the appropriate subfolder
2. Update this index with the file details
3. Ask AI: "Read `sources/books/xyz.pdf` and create notes"
4. AI reads → summarizes → creates notes in the relevant domain folder (01-11)
5. Notes will link back to the original PDF via relative path
