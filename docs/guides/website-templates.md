---
title: Website Templates
parent: Guides
nav_order: 3
---

# Website Templates

Jojo generates a self-contained HTML landing page for each job application. You can customize the design using templates.

## Default template

The default template is a clean, professional single-page design with these sections:

- **Masthead** — Your name, branding statement, and call-to-action button
- **Portfolio** — Relevant projects with descriptions and links
- **Recommendations carousel** — LinkedIn recommendations
- **Annotated job description** — Interactive view showing how your experience matches requirements
- **FAQ accordion** — Role-specific questions and answers
- **Call-to-action** — Footer encouraging employers to reach out

## Using custom templates

Select a template with the `-t` flag:

```bash
# Use a custom template for website generation
./bin/jojo website -s acme-corp-senior-dev -t modern

# Also works with generate
./bin/jojo generate -s acme-corp-senior-dev -t modern
```

## Creating custom templates

Templates are ERB files located in `templates/website/`.

1. Copy the default template:

   ```bash
   cp templates/website/index.html.erb templates/website/modern.html.erb
   ```

2. Edit with your custom HTML and CSS:

   ```bash
   nvim templates/website/modern.html.erb
   ```

3. Use the template:

   ```bash
   ./bin/jojo website -s acme-corp-senior-dev -t modern
   ```

## Overriding the default template

To customize the default website template without creating a named variant, copy it to `inputs/templates/website/`:

```bash
mkdir -p inputs/templates/website
cp templates/website/index.html.erb inputs/templates/website/index.html.erb
nvim inputs/templates/website/index.html.erb
```

Jojo will use your override automatically — no `-t` flag needed. You can also override static assets the same way:

```bash
cp templates/website/script.js inputs/templates/website/script.js
cp templates/website/icons.svg inputs/templates/website/icons.svg
```

## Template variables

These variables are available in ERB templates:

| Variable | Type | Description |
|----------|------|-------------|
| `seeker_name` | String | Your name from `config.yml` |
| `company_name` | String | Company from job details |
| `job_title` | String | Job title from job details |
| `branding_statement` | String | AI-generated branding (HTML) |
| `cta_text` | String | Call-to-action text from config |
| `cta_link` | String | Call-to-action link from config |
| `branding_image` | String | Path to branding image (if exists) |
| `projects` | Array | Selected projects for the role |
| `recommendations` | Array | Recommendations from `inputs/recommendations.md` |
| `faqs` | Array | FAQ objects from `faq.json` |
| `annotated_job_description` | String | Annotated job description HTML |

## ERB syntax basics

ERB (Embedded Ruby) lets you embed Ruby code in HTML:

```erb
<!-- Output a value -->
<h1><%= seeker_name %></h1>

<!-- Conditional content -->
<% if branding_image %>
  <img src="<%= branding_image %>" alt="Branding">
<% end %>

<!-- Iterate over arrays -->
<% projects.each do |project| %>
  <div class="project">
    <h3><%= project.name %></h3>
    <p><%= project.description %></p>
  </div>
<% end %>
```

## Design guidelines

- **Self-contained** — The default template uses Tailwind CSS and DaisyUI (built automatically). Custom named templates (e.g., `-t modern`) can use inline CSS or link to assets you copy alongside them.
- **Responsive** — Consider mobile viewing since employers may open your link on any device.
- **Professional** — Match the tone to your `voice_and_tone` setting in `config.yml`.
