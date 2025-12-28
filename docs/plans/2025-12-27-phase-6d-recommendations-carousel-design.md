# Phase 6d: Recommendations Carousel - Design Document

**Date:** 2025-12-27
**Phase:** 6d - Recommendations Carousel
**Status:** Design Complete, Ready for Implementation

## Overview

Add an interactive carousel to display LinkedIn recommendations on the landing page. The carousel showcases all recommendations from `inputs/recommendations.md` with auto-advance, manual navigation, and mobile swipe support.

## Design Decisions

### Carousel Behavior
- **Auto-advance:** Rotates every 6 seconds automatically
- **Pause on interaction:** Stops when user hovers, clicks, or swipes
- **Resume after interaction:** Restarts auto-advance when user stops interacting
- **Manual controls:** Previous/next arrow buttons and dot indicators

### Content Display
Each recommendation slide shows:
- Full recommendation quote (blockquote style)
- Recommender's name and title
- Relationship to candidate (e.g., "Former Manager at Company X")
- Future enhancement: Optional headshot image

### Recommendation Selection
- Display **all** recommendations from `inputs/recommendations.md`
- No AI filtering or reordering
- The file itself acts as the curation mechanism
- Carousel makes multiple recommendations space-efficient

### Visual Style
- **Card-based design** with subtle border and shadow
- **Navigation dots** below carousel showing count and position
- **Left/right arrow buttons** on sides
- Matches existing template aesthetic (similar to job description section)

### Page Position
Order: Masthead → Branding → Job Description → **Recommendations** → Projects → CTA → Footer

Natural storytelling flow: role requirements → personal pitch → social proof → work examples → call to action

### Mobile Behavior
- **Swipe gestures** for navigation (left/right)
- **Arrow buttons** still visible and functional
- **Auto-advance** pauses on touch, resumes after interaction
- Reuses touch detection patterns from annotation tooltips

## Architecture

### Component Breakdown

1. **RecommendationParser** (`lib/jojo/recommendation_parser.rb`)
   - Parses `inputs/recommendations.md` into structured data
   - Returns array of recommendation hashes
   - Handles missing/optional fields gracefully

2. **WebsiteGenerator** (enhanced)
   - Calls RecommendationParser if recommendations file exists
   - Passes recommendations array to template
   - No impact on existing branding/annotation logic

3. **Template** (`templates/website/default.html.erb`, enhanced)
   - New CSS for carousel card, dots, arrows
   - New HTML section between job description and projects
   - New JavaScript for carousel behavior

### Data Flow

```
inputs/recommendations.md → RecommendationParser → Array of hashes
                                                    ↓
                                               WebsiteGenerator
                                                    ↓
                                            Template variables
                                                    ↓
                                          Rendered HTML carousel
```

### Graceful Degradation

- No recommendations file → section not rendered
- Empty/malformed file → log warning, skip section
- Single recommendation → hide arrows/dots, disable auto-advance
- No AI fallback (these are human testimonials)

## Recommendation Parsing

### File Structure

The `inputs/recommendations.md` file uses markdown with:
- `---` delimiters between recommendations
- Consistent metadata format
- Blockquote for recommendation text

### Parsing Logic

1. Split file content on `---` delimiters
2. For each section, extract metadata using regex:
   - `## Recommendation from [Name]` → recommender name
   - `**Their Title:** [Title]` → recommender title
   - `**Relationship:** [Relationship]` → relationship type
   - `> [Quote text]` → extract blockquote content (may be multi-paragraph)
3. Skip header section (before first `---`)
4. Skip recommendations missing required fields (name or quote)

### Data Structure

```ruby
{
  recommender_name: "Jane Smith",
  recommender_title: "Senior Engineering Manager",
  relationship: "Former Manager at Acme Corp",
  quote: "Full text of the recommendation goes here..."
}
```

### Field Requirements

**Required:**
- `recommender_name`
- `quote`

**Optional:**
- `recommender_title` (defaults to nil)
- `relationship` (defaults to "Colleague")

**Ignored:**
- "Your Role" section (internal use)
- "Key Phrases to Use" section (for AI tailoring)

### Error Handling

- Missing required fields → skip that recommendation
- Empty file → return empty array
- Malformed markdown → log warning, parse what's parsable
- File doesn't exist → return nil (WebsiteGenerator handles)

## Visual Design

### Section Layout

```html
<section class="recommendations">
  <h2>What Others Say</h2>
  <div class="carousel-container">
    <div class="carousel-track">
      <!-- Multiple .carousel-slide elements -->
    </div>
    <button class="carousel-arrow prev" aria-label="Previous">‹</button>
    <button class="carousel-arrow next" aria-label="Next">›</button>
  </div>
  <div class="carousel-dots">
    <!-- Dot indicators -->
  </div>
</section>
```

### Card Design

- Background: `var(--background)` (white)
- Border: 1px solid `var(--border-color)`
- Padding: 2.5rem desktop, 2rem mobile
- Border-radius: 8px (matches other sections)
- Box-shadow: subtle, like project cards
- Large quotation mark (CSS pseudo-element) in light gray
- Quote text: 1.125rem, line-height 1.8
- Attribution: 0.9rem, color `var(--text-light)`

### Navigation Elements

**Arrow Buttons:**
- 40px diameter circles
- Background: white with border
- Hover: `var(--primary-color)` background
- Positioned absolutely, vertically centered
- Smaller or hidden on mobile

**Dot Indicators:**
- 8px circles, centered below carousel
- Inactive: `var(--border-color)`
- Active: `var(--primary-color)`
- Clickable to jump to specific slide

### Animation

- CSS transform (translateX) for slide transitions
- 300ms ease-in-out timing
- Smooth, not jarring

### Responsive Design

- Desktop: arrows visible, swipe optional
- Mobile: arrows smaller/hidden, swipe primary
- Quote font size scales down on mobile

## JavaScript Behavior

### State Management

```javascript
{
  currentIndex: 0,
  totalSlides: N,
  autoAdvanceInterval: null,
  autoAdvanceDelay: 6000, // 6 seconds
  isTransitioning: false,
  isTouchDevice: matchMedia check
}
```

### Core Functions

1. **goToSlide(index)**
   - Updates currentIndex
   - Applies CSS transform to carousel-track
   - Updates active dot indicator
   - Prevents transitions during transition (debounce)

2. **nextSlide() / prevSlide()**
   - Increments/decrements index with wrapping
   - Calls goToSlide()
   - Pauses auto-advance

3. **startAutoAdvance()**
   - Sets interval to call nextSlide() every 6 seconds

4. **pauseAutoAdvance()**
   - Clears the interval

5. **resumeAutoAdvance()**
   - Restarts interval after user interaction ends

### Event Listeners

**Desktop (mouse):**
- Arrow button clicks → next/prev, pause auto-advance
- Dot clicks → goToSlide(index), pause auto-advance
- Mouse enter carousel → pause auto-advance
- Mouse leave carousel → resume auto-advance

**Mobile (touch):**
- touchstart → record start position, pause auto-advance
- touchmove → track finger movement
- touchend → detect swipe (threshold: 50px), call next/prev, resume auto-advance after delay

**Keyboard:**
- Left/Right arrow keys → prev/next when carousel focused
- Dots focusable with tab, Enter to activate

### Accessibility

- ARIA labels on buttons
- ARIA live region announcing current slide
- Keyboard navigation support
- Reduced motion media query disables auto-advance if user prefers
- All interactive elements focusable

### Edge Cases

- Single recommendation → hide arrows/dots, disable auto-advance
- No recommendations → section not rendered
- Tab visibility API → pause when tab not visible

## Testing Strategy

### Unit Tests

**RecommendationParserTest** (`test/unit/recommendation_parser_test.rb`)
- Parse valid recommendations with all fields
- Parse recommendations with optional fields missing
- Handle malformed markdown gracefully
- Skip recommendations missing required fields
- Handle empty file
- Handle file with only header section
- Extract multi-paragraph quotes correctly
- Handle various markdown formatting variations

**WebsiteGeneratorTest** (enhanced)
- Generate website with recommendations
- Generate website without recommendations file
- Generate website with empty recommendations file
- Verify recommendations section position (after job description, before projects)
- Verify carousel HTML structure
- Verify single recommendation hides navigation

### Integration Tests

**RecommendationsWorkflowTest** (`test/integration/recommendations_workflow_test.rb`)
- Full workflow: parse → generate → verify HTML
- Carousel JavaScript included when recommendations present
- Carousel JavaScript not included when no recommendations
- Multiple recommendations render correctly
- Graceful degradation in generate command

### Test Fixtures

- `test/fixtures/recommendations.md` - sample with varied formatting
- `test/fixtures/recommendations_minimal.md` - minimal valid
- `test/fixtures/recommendations_single.md` - single recommendation
- `test/fixtures/recommendations_malformed.md` - error handling

### Manual Testing

- Visual testing (desktop and mobile browsers)
- Touch swipe on actual mobile device
- Auto-advance timing
- Screen reader accessibility
- Keyboard navigation

### Expected Coverage

- ~10-12 tests for RecommendationParser
- ~5-6 additional tests for WebsiteGenerator
- ~5 integration tests
- **Total: ~20-22 new tests**

## Implementation Tasks

1. Create `lib/jojo/recommendation_parser.rb`
   - Parse markdown structure
   - Extract metadata and quotes
   - Handle errors gracefully

2. Update `lib/jojo/generators/website_generator.rb`
   - Call RecommendationParser if file exists
   - Pass recommendations to template

3. Update `templates/website/default.html.erb`
   - Add recommendations section CSS
   - Add carousel HTML structure
   - Add carousel JavaScript
   - Position between job description and projects

4. Create test files
   - `test/unit/recommendation_parser_test.rb`
   - `test/integration/recommendations_workflow_test.rb`
   - Update `test/unit/website_generator_test.rb`

5. Create test fixtures
   - Various recommendations.md formats

## Success Criteria

- ✅ All recommendations from `inputs/recommendations.md` display in carousel
- ✅ Auto-advance rotates every 6 seconds
- ✅ Hover/click/swipe pauses auto-advance
- ✅ Arrow buttons and dots navigate correctly
- ✅ Mobile swipe gestures work smoothly
- ✅ Single recommendation shows static card (no carousel UI)
- ✅ No recommendations → section not rendered
- ✅ Keyboard navigation functional
- ✅ All tests passing (~20-22 new tests)
- ✅ Responsive design works on mobile and desktop

## Future Enhancements

- Optional headshot images for recommenders
- LinkedIn profile links
- Filter by relationship type (managers vs colleagues)
- AI-generated summary of common themes across recommendations
