---
name: firecrawl-parse
description: |
  Convert a PUBLIC or non-confidential local file (PDF, DOCX, XLSX, HTML, …) to markdown by uploading it to Firecrawl's cloud. Use only when the user explicitly asks for Firecrawl parsing of such a file. NEVER for legal documents, client files, case files (expedientes), contracts or personal data: for those use the local `pdf-local` skill or local tools. (Local guard added 2026-10-29 for Óscar's install.)
allowed-tools:
  - Bash(firecrawl *)
  - Bash(npx firecrawl-cli *)
---

# firecrawl parse

Turn a local document into clean markdown on disk. Supports **PDF, DOCX, DOC, ODT, RTF, XLSX, XLS, HTML/HTM**.

## Quick start

Always save to `.firecrawl/` with `-o` — parsed docs can be hundreds of KB and blow up context if streamed to stdout. Add `.firecrawl/` to `.gitignore`.

```bash
mkdir -p .firecrawl

# File → markdown
firecrawl parse ./paper.pdf -o .firecrawl/paper.md

# AI summary
firecrawl parse ./paper.pdf -S -o .firecrawl/paper-summary.md

# Ask a question about the doc
firecrawl parse ./paper.pdf -Q "What are the main conclusions?" \
  -o .firecrawl/paper-qa.md
```

Then read the output incrementally with `head`, `grep`, or `rg`.

Run `firecrawl parse --help` for the full option list.

**Done when:** the markdown, summary, or answer is written under `.firecrawl/` and you have inspected it with bounded reads.

## Tips

- Quote paths with spaces: `firecrawl parse "./My Doc.pdf" -o .firecrawl/mydoc.md`.
- Max upload size: **50 MB** per file.
- Credits: ~1 per PDF page; HTML is 1 flat.
- Check `.firecrawl/` before re-parsing the same file.
- To check your credit balance (recommended for batch processing and similar workflows), use `firecrawl credit-usage` (requires authentication).

## See also

- [firecrawl-scrape](../firecrawl-scrape/SKILL.md) — same idea for URLs
- [firecrawl-build-scrape](https://github.com/firecrawl/skills/tree/main/skills/build/firecrawl-build-scrape) — building document extraction into an app instead of running it here
