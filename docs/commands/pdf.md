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
| `applications/<slug>/resume.pdf` | Resume as PDF |
| `applications/<slug>/cover_letter.pdf` | Cover letter as PDF |

## Pandoc requirement

PDF generation requires [Pandoc](https://pandoc.org/):

```bash
# macOS
brew install pandoc

# Ubuntu/Debian
sudo apt-get install pandoc

# Verify installation
pandoc --version
```

{: .note }
If Pandoc is not installed, `jojo pdf` will warn and exit gracefully. When run as part of `jojo generate`, PDF generation is skipped with a warning but all other steps complete normally.
