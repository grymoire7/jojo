# Projects YAML Design

**Date**: 2025-12-27
**Status**: Approved
**Related Phase**: Phase 6b - Portfolio Highlights

## Overview

This design establishes a YAML-based structure for managing project and achievement highlights that will be used across multiple outputs: landing pages, tailored resumes, and cover letters. The system uses skill-based matching to automatically select and present the most relevant work based on job requirements.

## Goals

1. Single source of truth for project/achievement data
2. Automatic relevance-based selection using job description skills
3. Support for landing pages, resumes, and cover letters
4. Optional visual elements (images) for portfolio presentation
5. Graceful degradation when projects.yml not provided

## Schema Structure

### File Locations

- `templates/projects.yml` - Example template with sample data
- `inputs/projects.yml` - User's actual projects (optional)

### YAML Schema

```yaml
# Projects and achievements highlights
# Used in landing pages, resumes, and cover letters
# AI selects relevant items based on skill matching

- title: "Project Alpha"
  description: "Led a team of 5 developers to build a scalable web application
    that increased customer engagement by 30%."

  # Optional metadata for prioritization and context
  year: 2024                    # or date_range: "2023-2024"
  context: "at Example Corp"    # or "personal project", "open source", "freelance"
  role: "Tech Lead"             # your role in the project

  # Optional URLs (all optional)
  blog_post_url: "https://tracyatteberry.com/posts/project-alpha"
  github_url: "https://github.com/grymoire7/project-alpha"
  live_url: "https://project-alpha.example.com"

  # Optional visual (URL or path relative to inputs/)
  image: "inputs/projects/project-alpha-screenshot.png"
  # OR: image: "https://example.com/screenshot.png"

  # Skills for matching (required)
  skills:
    - Ruby on Rails
    - VueJS
    - PostgreSQL
    - web development
    - customer engagement

- title: "Employee of the Year Award"
  description: "Recognized for outstanding technical leadership and mentoring
    of junior developers."
  year: 2023
  context: "at Previous Corp"
  skills:
    - leadership
    - mentoring
    - teamwork
```

### Field Requirements

**Required fields:**
- `title` - Project or achievement name
- `description` - Full description (AI will adapt for different contexts)
- `skills` - Array of skills for matching

**Optional fields:**
- `year` - Integer year (e.g., 2024) OR `date_range` (e.g., "2023-2024")
- `context` - Employment context (e.g., "at Company X", "personal project")
- `role` - Your role in the project
- `blog_post_url` - Link to blog post about project
- `github_url` - GitHub repository URL
- `live_url` - Live project/demo URL
- `image` - Screenshot/visual (URL or file path relative to inputs/)

### Design Decisions

1. **Unified list**: Projects and achievements in single file, no type distinction
2. **AI adaptation**: Single description field, AI rewrites for each context
3. **Optional metadata**: Year/context for prioritization, but not required
4. **Flexible images**: Support both URLs and local file paths

## Selection Algorithm

### Skill-Based Matching

The system uses a scoring algorithm to rank projects by relevance:

```ruby
# Pseudocode for scoring logic
projects.each do |project|
  score = 0
  project.skills.each do |skill|
    if job_required_skills.include?(skill)
      score += 10  # Strong match
    elsif job_desired_skills.include?(skill)
      score += 5   # Medium match
    elsif skill.similar_to?(any_job_skill)  # fuzzy match
      score += 2   # Weak match
    end
  end

  # Recency bonus
  score += 5 if project.year >= (current_year - 2)

  project.relevance_score = score
end
```

### Selection Rules

**Landing Page (Phase 6b):**
- Select top 3-5 projects by relevance score
- Include images if available
- Rich presentation with links

**Resume:**
- Select top 3 projects by relevance score
- AI converts to bullet points
- Emphasis on metrics and outcomes

**Cover Letter:**
- Select top 1-2 projects by relevance score
- AI weaves into narrative
- Focus on alignment with company needs

## Integration Points

### New Classes

**`lib/jojo/project_loader.rb`**
- Load and parse `inputs/projects.yml`
- Validate schema (required fields, types)
- Return array of project hashes
- Graceful degradation if file missing

**`lib/jojo/project_selector.rb`**
- Accept job_details and projects array
- Calculate relevance scores using skill matching
- Support different selection methods:
  - `select_for_landing_page(limit: 5)`
  - `select_for_resume(limit: 3)`
  - `select_for_cover_letter(limit: 2)`
- Return sorted array with scores

**`lib/jojo/image_handler.rb`** (or within WebsiteGenerator)
- Handle URL images (pass through)
- Handle file path images (copy to `employers/*/website/images/`)
- Graceful degradation for missing images

### Generator Integration

**Website Generator (Phase 6b):**
```ruby
projects = ProjectSelector.new(employer).select_for_landing_page(limit: 5)
template_vars = {
  # ... existing vars ...
  projects: projects
}
# Template renders projects section with images/links
```

**Resume Generator (enhancement):**
```ruby
projects = ProjectSelector.new(employer).select_for_resume(limit: 3)
prompt = ResumePrompt.generate(
  # ... existing context ...
  relevant_projects: projects
)
# AI weaves projects into resume
```

**Cover Letter Generator (enhancement):**
```ruby
projects = ProjectSelector.new(employer).select_for_cover_letter(limit: 2)
prompt = CoverLetterPrompt.generate(
  # ... existing context ...
  highlight_projects: projects
)
# AI references projects in narrative
```

## Data Flow

### Generation Sequence

1. User runs: `./bin/jojo generate -e "Acme Corp" -j job.txt`

2. `JobDescriptionProcessor` extracts skills → `job_details.yml`
   ```yaml
   required_skills: [...]
   desired_skills: [...]
   ```

3. `ProjectLoader` reads `inputs/projects.yml`
   - Validates schema
   - Returns array of project hashes

4. `ProjectSelector` receives job_details + projects
   - Calculates relevance scores
   - Returns top N sorted by score

5. Generators receive selected projects
   - Copy project images to employer directory (if file paths)
   - Pass data to AI or template

### Directory Structure

```
employers/acme-corp/
  website/
    index.html
    images/               # NEW
      project-alpha-screenshot.png
      achievement-beta-icon.png
```

## Image Handling

### Strategy

```ruby
projects.each do |project|
  next unless project[:image]

  if project[:image].start_with?('http://', 'https://')
    # URL: reference directly in HTML
    project[:image_url] = project[:image]
  else
    # File path: copy to employer website directory
    src = File.join(Dir.pwd, project[:image])
    dest = File.join(employer.website_path, 'images', File.basename(project[:image]))

    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(src, dest) if File.exist?(src)

    project[:image_url] = "images/#{File.basename(project[:image])}"
  end
end
```

### Template Usage

```erb
<% projects.each do |project| %>
  <div class="project-card">
    <% if project[:image_url] %>
      <img src="<%= project[:image_url] %>" alt="<%= project[:title] %>">
    <% end %>
    <h3><%= project[:title] %></h3>
    <p><%= project[:description] %></p>
    <!-- Links to blog_post_url, github_url, live_url if present -->
  </div>
<% end %>
```

## Validation & Error Handling

### YAML Validation

```ruby
class ProjectLoader
  REQUIRED_FIELDS = %w[title description skills]
  OPTIONAL_FIELDS = %w[year date_range context role blog_post_url
                       github_url live_url image]

  def validate_project(project, index)
    errors = []

    # Required fields
    REQUIRED_FIELDS.each do |field|
      errors << "Project #{index}: missing '#{field}'" unless project[field]
    end

    # Skills must be array
    if project['skills'] && !project['skills'].is_a?(Array)
      errors << "Project #{index}: 'skills' must be an array"
    end

    # Year validation
    if project['year'] && !project['year'].is_a?(Integer)
      errors << "Project #{index}: 'year' must be integer (e.g., 2024)"
    end

    errors
  end
end
```

### Error Handling Strategy

| Scenario | Behavior |
|----------|----------|
| Missing `projects.yml` | Log warning, continue without projects (graceful degradation) |
| Invalid YAML syntax | Raise error with helpful message |
| Schema validation failures | Raise error listing all validation issues |
| Missing image files | Log warning, render without image (don't fail) |
| No matching projects | Log info message, continue (empty projects array) |

### Logging

```ruby
logger.info "Loaded #{projects.count} projects from inputs/projects.yml"
logger.info "Selected #{selected.count} projects relevant to #{employer_name}"
logger.debug "Top project: '#{top_project[:title]}' (score: #{top_project[:score]})"
logger.warn "Project image not found: #{image_path}" if missing_image
logger.warn "No projects.yml found, skipping project selection"
```

## Testing Strategy

### Unit Tests

**`test/unit/project_loader_test.rb`:**
- Valid YAML with all fields
- Valid YAML with only required fields
- Missing required field (title/description/skills)
- Invalid skills (not array)
- Invalid year (not integer)
- Malformed YAML syntax
- Missing file (graceful degradation)

**`test/unit/project_selector_test.rb`:**
- Exact skill match
- Fuzzy skill match ("PostgreSQL" ~ "Postgres")
- Recency bonus calculation
- No matching skills (returns empty)
- Limit parameter (top N)
- Different contexts (landing_page vs resume vs cover_letter)

**`test/unit/image_handler_test.rb`** (or in website_generator_test.rb):
- URL image (pass through)
- File path image (copy to website/images/)
- Missing image file (graceful degradation)
- No image field (skip)

### Integration Tests

**`test/integration/projects_workflow_test.rb`:**
- End-to-end: job description → project selection → website with projects
- Integration with existing resume/cover letter generation
- Image copying workflow
- Graceful degradation paths

## Implementation Notes

### Phase 6b Task Updates

The existing Phase 6b tasks should be updated to incorporate this design:

1. **Extend WebsiteGenerator** → Include ProjectLoader and ProjectSelector
2. **Update default template** → Add projects section with image support
3. **Create tests** → Cover ProjectLoader, ProjectSelector, image handling

### Future Enhancements

- **Fuzzy skill matching**: Use text similarity (Levenshtein distance) for skill matching
- **Custom weighting**: Allow user to weight certain skills higher in config
- **Manual overrides**: Support per-employer project selection in employer-specific config
- **Visual templates**: Different project card layouts per website template

## Success Criteria

✅ Schema supports both projects and achievements
✅ Skill-based matching selects relevant items automatically
✅ Works across landing pages, resumes, cover letters
✅ Optional metadata (year, context, role) for richer presentation
✅ Image support (URLs and file paths)
✅ Graceful degradation when projects.yml missing
✅ Clear validation errors for malformed data
✅ Comprehensive test coverage

## Related Documents

- [Phase 6a Website Generation Design](2025-12-26-phase-6a-website-generation-design.md)
- [Implementation Plan](implementation_plan.md) - Phase 6b
- [Overall Design](design.md)
