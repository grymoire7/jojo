---
title: pdf
parent: Commands
nav_order: 12
---

# jojo pdf

Convert resume and cover letter from markdown to PDF.

## Usage

```bash
./bin/jojo pdf -s SLUG
./bin/jojo pdf  # if JOJO_APPLICATION_SLUG is set
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --slug SLUG` | Application slug (or set `JOJO_APPLICATION_SLUG`) |
| `--overwrite` | Overwrite existing PDFs without prompting |

## Inputs

| Input | Description |
|-------|-------------|
| `applications/<slug>/resume.md` | Tailored resume |
| `applications/<slug>/cover_letter.md` | Cover letter |

## Outputs

| File | Description |
|------|-------------|
| `applications/<slug>/resume.html` | Resume as standalone HTML (CSS embedded) |
| `applications/<slug>/resume.pdf` | Resume as PDF |
| `applications/<slug>/cover_letter.html` | Cover letter as standalone HTML (CSS embedded) |
| `applications/<slug>/cover_letter.pdf` | Cover letter as PDF |

## Requirements

PDF generation requires both [Pandoc](https://pandoc.org/) and [wkhtmltopdf](https://wkhtmltopdf.org/).

### Pandoc

```bash
# macOS
brew install pandoc

# Ubuntu/Debian
sudo apt-get install pandoc

# Verify
pandoc --version
```

### wkhtmltopdf

```bash
# macOS
brew install --cask wkhtmltopdf

# Ubuntu/Debian
sudo apt-get install wkhtmltopdf

# Verify
wkhtmltopdf --version
```

{: .note }
If either tool is not installed, `jojo pdf` will warn and exit gracefully. When run as part of `jojo generate`, PDF generation is skipped with a warning but all other steps complete normally.
