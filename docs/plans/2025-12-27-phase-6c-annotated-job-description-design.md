# Phase 6c: Annotated Job Description Design

**Date**: 2025-12-27
**Status**: Design Complete, Ready for Implementation

## Overview

Add AI-powered annotations to the job description on landing pages, showing hiring managers exactly how the candidate's experience matches specific requirements. Uses fine-grained phrase matching with tiered highlighting (strong/moderate/mention) and interactive tooltips.

## Design Goals

1. **Make qualifications immediately scannable** - Hiring managers see matches at a glance
2. **Provide specific evidence** - Each annotation shows concrete experience, not vague claims
3. **Professional presentation** - Confident tone, clean visual design
4. **Graceful degradation** - Works without JavaScript, omits section if annotations unavailable
5. **Mobile-friendly** - Touch interactions work as smoothly as desktop hover

## Architecture

### Components

**1. AnnotationGenerator** (`lib/jojo/generators/annotation_generator.rb`)
- Reads job description and resume/research
- Calls AI with annotation prompt (reasoning model)
- Returns structured annotation data (JSON)
- Saves to `employers/{slug}/job_description_annotations.json`

**2. Annotation Prompt** (`lib/jojo/prompts/annotation_prompt.rb`)
- Instructions for identifying matchable requirements
- Tiered matching criteria (strong/moderate/mention)
- Output format: JSON array of `{text, match, tier}`
- Emphasis on exact phrase extraction from job description

**3. WebsiteGenerator Updates** (`lib/jojo/generators/website_generator.rb`)
- Loads annotations.json (returns nil if missing)
- Converts job description markdown to HTML
- Wraps all occurrences of annotated phrases with `<span>` tags
- Passes annotated HTML to template

**4. Template Integration** (`templates/website/default.html.erb`)
- New section: "Compare Me to the Job Description"
- Renders annotated job description HTML
- Inline JavaScript for tooltip interactions
- CSS for tier-based highlight styling

### Data Flow

```
generate command
  → AnnotationGenerator.generate
  → AI returns: [{text: "5+ years Python", match: "...", tier: "strong"}, ...]
  → Save annotations.json
  → WebsiteGenerator loads annotations + job description
  → Template renders annotated HTML with data attributes
  → Browser JS adds hover/tap interactions
```

### File Outputs

- `employers/{slug}/job_description_annotations.json` - AI-generated annotation data
- `employers/{slug}/website/index.html` - Includes annotated job description section

## Annotation Matching

### Text Matching Algorithm

1. Parse job description into paragraphs (split on `\n\n`)
2. For each annotation, search for exact text match across all paragraphs
3. Wrap **all occurrences** of matched text with `<span class="annotated" data-match="..." data-tier="...">text</span>`
4. Failed matches: Log warning, continue with remaining annotations

### Example Transformation

```
Input: "We need 5+ years of Python experience"
Annotation: {text: "5+ years of Python", match: "...", tier: "strong"}
Output: "We need <span class="annotated" data-match="..." data-tier="strong">5+ years of Python</span> experience"
```

### Error Handling

- **No exact match found**: Log warning, skip annotation
- **Empty annotations.json**: Omit section entirely
- **Missing annotations file**: Omit section entirely
- **Malformed JSON**: Log error, omit section entirely

**Rationale**: Unannotated job description adds no value. Better to omit section than show plain text.

### Graceful Degradation

- If annotations fail, landing page still works (section simply doesn't appear)
- If JavaScript disabled, annotations visible as styled text, tooltips not interactive
- Tooltip content readable via data attributes for accessibility tools

## AI Prompt Design

### Prompt Structure

```ruby
def self.generate_annotations_prompt(job_description:, resume:, research: nil)
  # Context: Job description + resume + research
  # Task: Identify specific requirements and match to candidate experience
  # Output: JSON array with exact text spans
```

### Prompt Instructions

- Extract specific, matchable phrases from job description (not full sentences)
- Focus on: technical skills, years of experience, specific tools/frameworks, domain knowledge, achievements
- For each phrase, provide concrete evidence from resume/research
- Classify each match as strong/moderate/mention:
  - **Strong**: Direct experience with specific numbers/outcomes
  - **Moderate**: Related experience or transferable skills
  - **Mention**: Tangential connection or potential to learn
- Target: 5-8 strong, 3-5 moderate, 0-3 mention (quality over quantity)
- Extract text EXACTLY as it appears in job description (critical for matching)

### Example Output

```json
[
  {
    "text": "5+ years of Python",
    "match": "Built Python applications for 7 years at Acme Corp and Beta Inc",
    "tier": "strong"
  },
  {
    "text": "distributed systems",
    "match": "Designed fault-tolerant message queue handling 10K msgs/sec",
    "tier": "strong"
  },
  {
    "text": "team leadership",
    "match": "Led team of 3 engineers on authentication project",
    "tier": "moderate"
  },
  {
    "text": "GraphQL",
    "match": "Familiar with GraphQL concepts, built REST APIs with similar patterns",
    "tier": "mention"
  }
]
```

### Model Selection

Use **reasoning model** (Sonnet) for better analytical matching, not text generation model (Haiku).

## JavaScript Interaction Layer

### Tooltip Behavior

- **Desktop**: Show on mouseenter, hide on mouseleave
- **Mobile**: Show on first tap, hide on tap outside or on another annotation
- **Positioning**: Above or below annotation based on viewport space
- **Keyboard accessible**: Tab to annotation, Enter to show, Esc to close

### Implementation Approach

1. **Single tooltip element** - Reused for all annotations, repositioned dynamically
2. **Event listeners** on all `.annotated` spans
3. **Viewport-aware positioning** - Flip tooltip if it would overflow screen
4. **Touch detection** - Use `matchMedia('(hover: none)')` to detect mobile
5. **Close on outside click** - Click listener on document body
6. **Keyboard navigation** - Focus management for accessibility

### CSS for Tier-Based Highlighting

```css
.annotated {
  background-color: rgba(37, 99, 235, 0.15); /* Base blue */
  cursor: pointer;
  border-radius: 2px;
  padding: 1px 2px;
  transition: background-color 0.2s;
}

.annotated[data-tier="strong"] {
  background-color: rgba(37, 99, 235, 0.25); /* Darker/more opaque */
}

.annotated[data-tier="moderate"] {
  background-color: rgba(37, 99, 235, 0.15); /* Medium */
}

.annotated[data-tier="mention"] {
  background-color: rgba(37, 99, 235, 0.08); /* Subtle */
}

.annotated:hover {
  background-color: rgba(37, 99, 235, 0.3); /* All tiers darken on hover */
}
```

### Tooltip Styling

- White background with subtle shadow
- Max width 300px
- Small arrow pointing to annotation
- Smooth fade-in animation (150ms)
- Z-index above all other content
- Responsive positioning (flip if near viewport edge)

## Template Integration

### Section Placement

Flow: Masthead → Branding → **Annotated Job Description** → Projects → CTA → Footer

This creates a narrative: "Why I'm great" → "Here's proof" → "Here's my work" → "Let's talk"

### HTML Structure

```erb
<!-- Annotated Job Description -->
<% if annotated_job_description %>
<section class="job-description-comparison">
  <h2>Compare Me to the Job Description</h2>
  <div class="job-description-content">
    <%= annotated_job_description %>
  </div>
  <p class="annotation-legend">
    <span class="legend-item"><span class="sample strong"></span> Strong match</span>
    <span class="legend-item"><span class="sample moderate"></span> Moderate match</span>
    <span class="legend-item"><span class="sample mention"></span> Worth a mention</span>
    <span class="legend-hint">Hover or tap highlighted text to see details</span>
  </p>
</section>

<!-- Tooltip container -->
<div id="annotation-tooltip" class="annotation-tooltip hidden">
  <div class="tooltip-content"></div>
  <div class="tooltip-arrow"></div>
</div>
<% end %>
```

### WebsiteGenerator Changes

Add `annotate_job_description` method that:
1. Loads `job_description_annotations.json` (returns nil if missing)
2. Reads `job_description.md`
3. Converts markdown to HTML paragraphs
4. Wraps all occurrences of annotated phrases with `<span>` tags
5. Returns annotated HTML string (or nil if annotations unavailable)

Pass `annotated_job_description` to template vars (nil if annotations missing).

Template only renders section if `annotated_job_description` is present.

### Benefits

- Clean separation: annotation generation happens separately from website generation
- Annotations can be regenerated without rebuilding entire website
- If annotations.json missing, section simply doesn't appear (no error)
- Existing websites continue working without annotations

## Testing Strategy

### Unit Tests

**`test/unit/annotation_generator_test.rb`**
- Test annotation generation with mocked AI responses
- Test tier classification (strong/moderate/mention)
- Test exact text extraction from job description
- Test graceful handling when no matches found
- Test JSON output format validation

**`test/unit/annotation_prompt_test.rb`**
- Test prompt includes all required context
- Test prompt emphasizes exact text matching
- Test graceful degradation without research

**`test/unit/website_generator_test.rb` (updates)**
- Test annotation loading and HTML injection
- Test duplicate text matching (all occurrences annotated)
- Test handling of missing annotations.json (section omitted)
- Test malformed JSON (logs error, omits section)
- Test annotations with special HTML characters (proper escaping)

### Integration Tests

**`test/integration/annotated_job_description_test.rb`**
- Test full workflow: generate → annotate → website
- Test annotations appear in correct HTML structure
- Test legend renders with correct tier labels
- Verify JavaScript and CSS present in output HTML

### Manual Testing Checklist

- [ ] Tooltip positioning on desktop (viewport edge cases)
- [ ] Touch interactions on mobile (tap to show/hide)
- [ ] Keyboard navigation (tab, enter, escape)
- [ ] Multiple occurrences of same phrase all annotated
- [ ] Long tooltips don't overflow or break layout
- [ ] Works with JavaScript disabled (graceful degradation)

## Implementation Notes

### HTML Escaping

When injecting annotation match text into data attributes, ensure proper HTML escaping to prevent XSS and attribute breaking.

### Markdown to HTML Conversion

Use simple paragraph-based conversion (split on `\n\n`, wrap in `<p>` tags). Preserve basic markdown formatting:
- **Bold** (`**text**` → `<strong>text</strong>`)
- *Italic* (`*text*` → `<em>text</em>`)
- Links (`[text](url)` → `<a href="url">text</a>`)

Keep it simple - job descriptions rarely need complex markdown.

### Performance Considerations

- Single tooltip element prevents DOM bloat with many annotations
- CSS transitions for smooth interactions
- Event delegation could be used if annotation count is very high (likely unnecessary)

### Accessibility

- Ensure annotated spans are keyboard-focusable (`tabindex="0"`)
- Tooltip shows on Enter key, hides on Escape
- Screen readers can access tooltip content via data attributes
- High contrast between highlight tiers for readability

## Future Enhancements (Post-Phase 6c)

- Analytics: Track which annotations get the most engagement
- Custom tier thresholds: Let users configure what counts as "strong" vs "moderate"
- Annotation editing: Manual override of AI-generated annotations
- Alternative highlight styles: User preference for colors/styles
- Annotation export: Share annotation data with other tools

## Success Criteria

- [ ] Annotations generate successfully from job description + resume
- [ ] All occurrences of annotated text are highlighted
- [ ] Tooltips work on hover (desktop) and tap (mobile)
- [ ] Three visual tiers clearly distinguishable
- [ ] Section omitted gracefully when annotations unavailable
- [ ] Tests pass with comprehensive coverage
- [ ] Landing page feels polished and professional
