# Commands

## Overview

| Command               | Description                                                      | Required Options             |
| --------------------- | ---------------------------------------------------------------- | ---------------------------- |
| `jojo setup`          | Create configuration file                                        | None                         |
| `jojo new`            | Create application workspace and process job description            | `-s`, `-j`                   |
| `jojo generate`       | Generate all materials (research, resume, cover letter, website) | `-s` or `JOJO_APPLICATION_SLUG` |
| `jojo research`       | Generate company/role research only                              | `-s` or `JOJO_APPLICATION_SLUG` |
| `jojo resume`         | Generate tailored resume only                                    | `-s` or `JOJO_APPLICATION_SLUG` |
| `jojo cover_letter`   | Generate cover letter only                                       | `-s` or `JOJO_APPLICATION_SLUG` |
| `jojo annotate`       | Generate annotated job description                               | `-s` or `JOJO_APPLICATION_SLUG` |
| `jojo website`        | Generate website only                                            | `-s` or `JOJO_APPLICATION_SLUG` |
| `jojo pdf`            | Generate PDF versions of resume and cover letter                 | `-s` or `JOJO_APPLICATION_SLUG` |
| `jojo version`        | Show version                                                     | None                         |
| `jojo help [COMMAND]` | Show help                                                        | None                         |


## Inputs/Outputs

| Command             | Inputs                                   | Outputs                                             |
| ------------------- | ---------------------------------------- | --------------------------------------------------- |
| `jojo setup`        | None (interactive)                       | `.env`                                              |
|                     |                                          | `config.yml`                                        |
|                     |                                          | `inputs/resume_data.yml`                            |
|                     |                                          | `inputs/templates/default_resume.md.erb`            |
| `jojo new`          | `inputs/resume_data.yml`                 | `applications/<slug>/job_description_raw.md`           |
|                     | job source (file or URL via `-j`)        | `applications/<slug>/job_description.md`               |
|                     |                                          | `applications/<slug>/job_details.yml`                  |
|                     |                                          | `applications/<slug>/website/`                         |
| `jojo generate`     | `applications/<slug>/job_description.md`    | `applications/<slug>/research.md`                      |
|                     | `applications/<slug>/job_details.yml`       | `applications/<slug>/resume.md`                        |
|                     | `inputs/resume_data.yml`                 | `applications/<slug>/cover_letter.md`                  |
|                     | `templates/*`                            | `applications/<slug>/job_description_annotations.json` |
|                     |                                          | `applications/<slug>/faq.json`                         |
|                     |                                          | `applications/<slug>/website/index.html`               |
|                     |                                          | `*.pdf` (if Pandoc installed)                       |
|                     |                                          | `status.log`                                        |
| `jojo research`     | `applications/<slug>/job_description.md`    | `applications/<slug>/research.md`                      |
|                     | `applications/<slug>/job_details.yml`       | `status.log`                                        |
| `jojo resume`       | `applications/<slug>/job_description.md`    | `applications/<slug>/resume.md`                        |
|                     | `applications/<slug>/job_details.yml`       | `status.log`                                        |
|                     | `inputs/resume_data.yml`                 |                                                     |
| `jojo cover_letter` | `applications/<slug>/job_description.md`    | `applications/<slug>/cover_letter.md`                  |
|                     | `applications/<slug>/job_details.yml`       | `status.log`                                        |
|                     | `applications/<slug>/resume.md`             |                                                     |
|                     | `inputs/resume_data.yml`                 |                                                     |
| `jojo annotate`     | `applications/<slug>/job_description.md`    | `applications/<slug>/job_description_annotations.json` |
|                     | `applications/<slug>/job_details.yml`       |                                                     |
| `jojo branding`     | `applications/<slug>/job_description.md`    | `applications/<slug>/branding_statement.json`          |
|                     | `applications/<slug>/job_details.yml`       |                                                     |
|                     | `applications/<slug>/resume.md`             |                                                     |
|                     | optional: `research.md`                  |                                                     |
| `jojo website`      | `applications/<slug>/job_description.md`    | `applications/<slug>/website/index.html`               |
|                     | `applications/<slug>/job_details.yml`       | `status.log`                                        |
|                     | `applications/<slug>/resume.md`             |                                                     |
|                     | optional: `research.md`                  |                                                     |
|                     | `faq.json`                               |                                                     |
|                     | `job_description_annotations.json`       |                                                     |
|                     | `templates/*`                            |                                                     |
| `jojo pdf`          | `applications/<slug>/resume.md`             | `applications/<slug>/resume.pdf`                       |
|                     | `applications/<slug>/cover_letter.md`       | `applications/<slug>/cover_letter.pdf`                 |
| `jojo version`      | None                                     | None (version to stdout)                            |
| `jojo help [CMD]`   | None                                     | None (help to stdout)                               |



