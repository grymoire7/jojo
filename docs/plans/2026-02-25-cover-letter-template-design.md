# Cover Letter ERB Template Design

**Date:** 2026-02-25
**Status:** Approved

## Problem

The cover letter generator produces only the letter body — no sender header, salutation, closing, or signature. The landing page link is prepended at the top, which is not standard letter format.

## Goal

Use an ERB template to wrap the AI-generated body with proper letter structure: sender info, date, salutation, closing, and move the landing page link to a P.S.

## Design

### Output Structure

```
Tracy Atteberry
tracy@tracyatteberry.com | https://tracyatteberry.com
February, 2026

Dear Hiring Manager,

[AI-generated body]

Sincerely,

Tracy Atteberry

---

*P.S. **Specifically for [Company Name]**: https://tracyatteberry.com/[slug]*
```

### Files Changed

| File | Change |
|------|--------|
| `lib/jojo/commands/cover_letter/cover_letter.md.erb` | **New** — ERB template defining letter structure |
| `lib/jojo/commands/cover_letter/generator.rb` | Replace `add_landing_page_link` with `render_template`; add `resume_data` to inputs hash |
| `lib/jojo/commands/cover_letter/prompt.rb` | No behavioral change (existing "no header/signature" instruction stays) |

### Template Variables

| Variable | Source |
|----------|--------|
| `name` | `inputs[:resume_data]["name"]` |
| `email` | `inputs[:resume_data]["email"]` |
| `website` | `inputs[:resume_data]["website"]` |
| `date` | `Time.now.strftime("%B, %Y")` |
| `body` | AI-generated cover letter body |
| `company_name` | `inputs[:company_name]` |
| `landing_page_url` | `"#{config.base_url}/#{inputs[:company_slug]}"` |

### Data Flow

```
gather_inputs
  → loads resume_data.yml (already done for generic_resume)
  → adds inputs[:resume_data] = raw resume_data hash

call_ai(prompt) → body

render_template(body, inputs)
  → loads cover_letter.md.erb
  → binds template variables
  → returns rendered markdown string

save_cover_letter(rendered)
```

### Landing Page URL Fix

The current `add_landing_page_link` uses `config.base_url + "/resume/" + slug`. The template corrects this to `config.base_url + "/" + slug`.

### Prompt Change

The existing prompt instruction stays:
> "DO NOT include date, address header, or signature block (just the letter body)"

The AI continues to generate only body paragraphs. The template handles all structure.

## Testing

Update existing tests that assert the landing page link appears at the top — it now appears in P.S. at the bottom.

New unit tests for `render_template` verify:
- Sender block (name, email, website) at the top
- Date in `Month, YYYY` format
- `Dear Hiring Manager,` salutation
- AI body injected correctly
- `Sincerely,` closing with name
- Landing page link in P.S. at the bottom
- Corrected URL format (no `/resume/` segment)
