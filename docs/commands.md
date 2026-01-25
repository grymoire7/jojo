# Commands

## Overview

| Command               | Description                                                      | Required Options             |
| --------------------- | ---------------------------------------------------------------- | ---------------------------- |
| `jojo setup`          | Create configuration file                                        | None                         |
| `jojo new`            | Create employer workspace and process job description            | `-s`, `-j`                   |
| `jojo generate`       | Generate all materials (research, resume, cover letter, website) | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo research`       | Generate company/role research only                              | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo resume`         | Generate tailored resume only                                    | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo cover_letter`   | Generate cover letter only                                       | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo annotate`       | Generate annotated job description                               | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo website`        | Generate website only                                            | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo pdf`            | Generate PDF versions of resume and cover letter                 | `-s` or `JOJO_EMPLOYER_SLUG` |
| `jojo test`           | Run test suite                                                   | None                         |
| `jojo version`        | Show version                                                     | None                         |
| `jojo help [COMMAND]` | Show help                                                        | None                         |


## Inputs/Outputs

| Command             | Inputs                                   | Outputs                                             |
| ------------------- | ---------------------------------------- | --------------------------------------------------- |
| `jojo setup`        | None (interactive)                       | `.env`                                              |
|                     |                                          | `config.yml`                                        |
|                     |                                          | `inputs/resume_data.yml`                            |
|                     |                                          | `inputs/templates/default_resume.md.erb`            |
| `jojo new`          | `inputs/resume_data.yml`                 | `employers/<slug>/job_description_raw.md`           |
|                     | job source (file or URL via `-j`)        | `employers/<slug>/job_description.md`               |
|                     |                                          | `employers/<slug>/job_details.yml`                  |
|                     |                                          | `employers/<slug>/website/`                         |
| `jojo generate`     | `employers/<slug>/job_description.md`    | `employers/<slug>/research.md`                      |
|                     | `employers/<slug>/job_details.yml`       | `employers/<slug>/resume.md`                        |
|                     | `inputs/resume_data.yml`                 | `employers/<slug>/cover_letter.md`                  |
|                     | `templates/*`                            | `employers/<slug>/job_description_annotations.json` |
|                     |                                          | `employers/<slug>/faq.json`                         |
|                     |                                          | `employers/<slug>/website/index.html`               |
|                     |                                          | `*.pdf` (if Pandoc installed)                       |
|                     |                                          | `status.log`                                        |
| `jojo research`     | `employers/<slug>/job_description.md`    | `employers/<slug>/research.md`                      |
|                     | `employers/<slug>/job_details.yml`       | `status.log`                                        |
| `jojo resume`       | `employers/<slug>/job_description.md`    | `employers/<slug>/resume.md`                        |
|                     | `employers/<slug>/job_details.yml`       | `status.log`                                        |
|                     | `inputs/resume_data.yml`                 |                                                     |
| `jojo cover_letter` | `employers/<slug>/job_description.md`    | `employers/<slug>/cover_letter.md`                  |
|                     | `employers/<slug>/job_details.yml`       | `status.log`                                        |
|                     | `employers/<slug>/resume.md`             |                                                     |
|                     | `inputs/resume_data.yml`                 |                                                     |
| `jojo annotate`     | `employers/<slug>/job_description.md`    | `employers/<slug>/job_description_annotations.json` |
|                     | `employers/<slug>/job_details.yml`       |                                                     |
| `jojo branding`     | `employers/<slug>/job_description.md`    | `employers/<slug>/branding_statement.json`          |
|                     | `employers/<slug>/job_details.yml`       |                                                     |
|                     | `employers/<slug>/resume.md`             |                                                     |
|                     | optional: `research.md`                  |                                                     |
| `jojo website`      | `employers/<slug>/job_description.md`    | `employers/<slug>/website/index.html`               |
|                     | `employers/<slug>/job_details.yml`       | `status.log`                                        |
|                     | `employers/<slug>/resume.md`             |                                                     |
|                     | optional: `research.md`                  |                                                     |
|                     | `faq.json`                               |                                                     |
|                     | `job_description_annotations.json`       |                                                     |
|                     | `templates/*`                            |                                                     |
| `jojo pdf`          | `employers/<slug>/resume.md`             | `employers/<slug>/resume.pdf`                       |
|                     | `employers/<slug>/cover_letter.md`       | `employers/<slug>/cover_letter.pdf`                 |
| `jojo test`         | None (test fixtures in `test/fixtures/`) | None (results to stdout)                            |
| `jojo version`      | None                                     | None (version to stdout)                            |
| `jojo help [CMD]`   | None                                     | None (help to stdout)                               |



