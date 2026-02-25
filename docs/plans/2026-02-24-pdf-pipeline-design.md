# PDF Pipeline Redesign: MD → HTML → PDF

**Date:** 2026-02-24
**Status:** Approved

## Problem

The current PDF pipeline uses `pandoc --pdf-engine=pdflatex`, which produces output styled by LaTeX's typography engine. This results in lower visual quality than a CSS-driven approach. There is also no HTML artifact, limiting future options (e.g. serving the resume in a browser on the generated website).

## Goal

Replace the single-step pandoc+pdflatex pipeline with a two-step pipeline:

1. **pandoc** converts markdown → standalone HTML (with embedded CSS)
2. **wkhtmltopdf** converts HTML → PDF

Both `resume.html` and `resume.pdf` (and cover letter equivalents) become permanent build artifacts in the application directory.

## Architecture

```
resume.md          cover_letter.md
  ↓ pandoc           ↓ pandoc
resume.html        cover_letter.html   ← new build artifacts
  ↓ wkhtmltopdf      ↓ wkhtmltopdf
resume.pdf         cover_letter.pdf
```

The HTML files are self-contained (CSS embedded via `--embed-resources --standalone`) so they can be served in a browser or copied anywhere without external dependencies.

## Design Decisions

### Single shared stylesheet

A single `templates/pdf-stylesheet.css` serves both resume and cover letter. Both documents are rendered from markdown to HTML and share the same typographic base. The stylesheet is copied from the `mdresume` project as a starting point and can be tuned independently over time.

### HTML as a first-class artifact

The intermediate HTML is saved to the application directory (`resume.html`, `cover_letter.html`) rather than discarded. This enables future use cases such as in-browser resume viewing on the generated website.

### CSS embedding

The pandoc command uses `--embed-resources --standalone` to inline the CSS into the HTML output. This makes the HTML file portable — it requires no external files to render correctly in a browser or in wkhtmltopdf.

### YAML front-matter cleanup

The current resume template includes LaTeX-specific YAML front-matter (`margin-left`, `margin-right`, `margin-top`, `margin-bottom`, etc.) that targets the old pdflatex engine. These variables are meaningless in the new pipeline and will be removed as part of this work.

## Components Changed

| Component | Change |
|-----------|--------|
| `templates/pdf-stylesheet.css` | New — shared CSS for both document types |
| `lib/jojo/application.rb` | Add `resume_html_path` and `cover_letter_html_path` |
| `lib/jojo/commands/pdf/converter.rb` | Replace `build_pandoc_command` with two-step pipeline (pandoc → HTML, wkhtmltopdf → PDF) for both document types |
| `lib/jojo/commands/pdf/wkhtmltopdf_checker.rb` | New — parallel interface to `PandocChecker` |
| `lib/jojo/commands/pdf/command.rb` | Update output reporting to list HTML files alongside PDFs |
| `templates/default_resume.md.erb` | Remove deprecated LaTeX YAML front-matter |
| `docs/commands/pdf.md` | Add HTML to Outputs table; expand requirements section to cover both tools |
| `docs/getting-started/installation.md` | Add wkhtmltopdf alongside Pandoc in prerequisites |

## Tests

- `test/unit/commands/pdf/converter_test.rb` — update mocks for both pandoc and wkhtmltopdf calls; verify both `.html` and `.pdf` output paths are produced for both document types
- `test/unit/commands/pdf/wkhtmltopdf_checker_test.rb` — new, mirrors `pandoc_checker_test.rb`

## Reference

The two-step pipeline mirrors the approach used in `~/projects/mdresume/.github/workflows/create-pdf.yml`:

```bash
# Step 1: markdown to HTML
pandoc resume.md -f markdown -t html -c resume-stylesheet.css -s -o resume.html

# Step 2: HTML to PDF
wkhtmltopdf --enable-local-file-access resume.html resume.pdf
```

The jojo implementation differs in using `--embed-resources` to produce a self-contained HTML file.
