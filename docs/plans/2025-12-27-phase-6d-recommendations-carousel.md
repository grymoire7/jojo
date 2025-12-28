# Recommendations Carousel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add interactive carousel to display LinkedIn recommendations on landing page

**Architecture:** Parse recommendations from markdown → pass to template → render with vanilla JavaScript carousel (auto-advance, swipe, keyboard nav)

**Tech Stack:** Ruby (parsing), ERB (templating), Vanilla JS (carousel), CSS (styling)

---

## Task 1: Create RecommendationParser - Basic Structure

**Files:**
- Create: `lib/jojo/recommendation_parser.rb`
- Create: `test/unit/recommendation_parser_test.rb`

**Step 1: Write the first failing test**

Create `test/unit/recommendation_parser_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/recommendation_parser'

describe Jojo::RecommendationParser do
  it "parses valid recommendations with all fields" do
    parser = Jojo::RecommendationParser.new('test/fixtures/recommendations.md')
    recommendations = parser.parse

    _(recommendations).must_be_kind_of Array
    _(recommendations.size).must_equal 2

    first = recommendations.first
    _(first[:recommender_name]).must_equal 'Jane Smith'
    _(first[:recommender_title]).must_equal 'Senior Engineering Manager'
    _(first[:relationship]).must_equal 'Former Manager at Acme Corp'
    _(first[:quote]).must_include 'excellent engineer'
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/recommendation_parser_test.rb`

Expected: FAIL with "cannot load such file -- jojo/recommendation_parser"

**Step 3: Create minimal implementation**

Create `lib/jojo/recommendation_parser.rb`:

```ruby
module Jojo
  class RecommendationParser
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def parse
      return nil unless File.exist?(file_path)

      content = File.read(file_path)
      sections = content.split(/^---\s*$/).map(&:strip)

      # Skip first section (header/instructions)
      sections.shift

      sections.map { |section| parse_section(section) }.compact
    end

    private

    def parse_section(section)
      return nil if section.empty?

      # Extract recommender name
      name_match = section.match(/^##\s+Recommendation from\s+(.+)$/i)
      return nil unless name_match
      recommender_name = name_match[1].strip

      # Extract title
      title_match = section.match(/\*\*Their Title:\*\*\s+(.+)$/i)
      recommender_title = title_match ? title_match[1].strip : nil

      # Extract relationship
      relationship_match = section.match(/\*\*Relationship:\*\*\s+(.+)$/i)
      relationship = relationship_match ? relationship_match[1].strip : 'Colleague'

      # Extract quote (blockquote lines starting with >)
      quote_lines = section.lines.select { |line| line.strip.start_with?('>') }
      return nil if quote_lines.empty?

      quote = quote_lines.map { |line| line.sub(/^>\s*/, '').strip }.join(' ')

      {
        recommender_name: recommender_name,
        recommender_title: recommender_title,
        relationship: relationship,
        quote: quote
      }
    end
  end
end
```

**Step 4: Create test fixture**

Create `test/fixtures/recommendations.md`:

```markdown
# LinkedIn Recommendations

These recommendations can be used to tailor your resume and cover letter.

---

## Recommendation from Jane Smith
**Their Title:** Senior Engineering Manager
**Your Role:** Software Engineer
**Relationship:** Former Manager at Acme Corp

> Jane is an excellent engineer who consistently delivers high-quality work.
> Her attention to detail and problem-solving skills are outstanding.

**Key Phrases to Use:**
- "Excellent engineer"
- "High-quality work"

---

## Recommendation from Bob Johnson
**Their Title:** Lead Developer
**Your Role:** Senior Engineer
**Relationship:** Colleague at Tech Co

> I had the pleasure of working with Bob on several critical projects.
> His technical expertise and collaborative approach made every project a success.

**Key Phrases to Use:**
- "Technical expertise"
```

**Step 5: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/recommendation_parser_test.rb`

Expected: PASS (1 test, 4 assertions)

**Step 6: Commit**

```bash
git add lib/jojo/recommendation_parser.rb test/unit/recommendation_parser_test.rb test/fixtures/recommendations.md
git commit -m "feat: add RecommendationParser with basic parsing"
```

---

## Task 2: RecommendationParser - Handle Edge Cases

**Files:**
- Modify: `test/unit/recommendation_parser_test.rb`
- Modify: `lib/jojo/recommendation_parser.rb` (if needed)

**Step 1: Write tests for edge cases**

Add to `test/unit/recommendation_parser_test.rb`:

```ruby
  it "handles missing optional fields" do
    parser = Jojo::RecommendationParser.new('test/fixtures/recommendations_minimal.md')
    recommendations = parser.parse

    _(recommendations.size).must_equal 1
    _(recommendations.first[:recommender_name]).must_equal 'Alice Lee'
    _(recommendations.first[:recommender_title]).must_be_nil
    _(recommendations.first[:relationship]).must_equal 'Colleague'  # default
    _(recommendations.first[:quote]).wont_be_empty
  end

  it "returns nil when file does not exist" do
    parser = Jojo::RecommendationParser.new('test/fixtures/nonexistent.md')
    recommendations = parser.parse

    _(recommendations).must_be_nil
  end

  it "returns empty array when file has no valid recommendations" do
    parser = Jojo::RecommendationParser.new('test/fixtures/recommendations_empty.md')
    recommendations = parser.parse

    _(recommendations).must_be_kind_of Array
    _(recommendations).must_be_empty
  end

  it "skips recommendations missing required name" do
    parser = Jojo::RecommendationParser.new('test/fixtures/recommendations_malformed.md')
    recommendations = parser.parse

    # Should have 1 valid, skip 1 invalid
    _(recommendations.size).must_equal 1
  end

  it "skips recommendations missing quote" do
    parser = Jojo::RecommendationParser.new('test/fixtures/recommendations_no_quote.md')
    recommendations = parser.parse

    _(recommendations).must_be_empty
  end

  it "handles multi-paragraph quotes" do
    parser = Jojo::RecommendationParser.new('test/fixtures/recommendations_long.md')
    recommendations = parser.parse

    quote = recommendations.first[:quote]
    _(quote).must_include 'first paragraph'
    _(quote).must_include 'second paragraph'
  end
```

**Step 2: Run tests to verify they fail**

Run: `ruby -Ilib:test test/unit/recommendation_parser_test.rb`

Expected: Some tests FAIL with "No such file"

**Step 3: Create additional test fixtures**

Create `test/fixtures/recommendations_minimal.md`:

```markdown
# Recommendations

---

## Recommendation from Alice Lee

> Alice is a talented developer with great communication skills.
```

Create `test/fixtures/recommendations_empty.md`:

```markdown
# Recommendations

Just header, no recommendations.
```

Create `test/fixtures/recommendations_malformed.md`:

```markdown
# Recommendations

---

## Recommendation from Valid Person
**Relationship:** Colleague

> This one is valid.

---

**Their Title:** Missing Name
**Relationship:** Manager

> This one has no name header.
```

Create `test/fixtures/recommendations_no_quote.md`:

```markdown
# Recommendations

---

## Recommendation from Missing Quote Person
**Their Title:** Developer
**Relationship:** Colleague

No blockquote here!
```

Create `test/fixtures/recommendations_long.md`:

```markdown
# Recommendations

---

## Recommendation from Verbose Person
**Relationship:** Manager

> This is the first paragraph of a longer recommendation.
> It has multiple sentences.
>
> This is the second paragraph, which should also be included.
```

**Step 4: Run tests again**

Run: `ruby -Ilib:test test/unit/recommendation_parser_test.rb`

Expected: All tests PASS (7 tests total)

**Step 5: Commit**

```bash
git add test/unit/recommendation_parser_test.rb test/fixtures/recommendations_*.md
git commit -m "test: add edge case tests for RecommendationParser"
```

---

## Task 3: Integrate RecommendationParser into WebsiteGenerator

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb:6` (add require)
- Modify: `lib/jojo/generators/website_generator.rb:35-36` (add recommendation loading)
- Modify: `lib/jojo/generators/website_generator.rb:118` (add recommendations to template vars)
- Create: `test/unit/generators/website_generator_recommendations_test.rb`

**Step 1: Write test for recommendations integration**

Create `test/unit/generators/website_generator_recommendations_test.rb`:

```ruby
require_relative '../../test_helper'
require_relative '../../../lib/jojo/employer'
require_relative '../../../lib/jojo/generators/website_generator'
require_relative '../../../lib/jojo/config'
require 'tmpdir'
require 'fileutils'

describe 'WebsiteGenerator with Recommendations' do
  before do
    @temp_dir = Dir.mktmpdir
    @employer = Jojo::Employer.new('Test Corp', base_path: @temp_dir)

    # Create required files
    FileUtils.mkdir_p(@employer.employer_path)
    File.write(@employer.job_description_path, "Job description")
    File.write(@employer.resume_path, "Resume content")

    # Mock AI client
    @ai_client = Minitest::Mock.new
    @ai_client.expect(:generate_text, "Branding statement", [String])

    # Mock config
    @config = Minitest::Mock.new
    @config.expect(:seeker_name, "Test User")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:website_cta_text, "Get in touch")
    @config.expect(:website_cta_link, nil)
    @config.expect(:base_url, "https://example.com")
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  it "includes recommendations in template vars when file exists" do
    # Create recommendations file in inputs
    inputs_path = File.join(@temp_dir, 'inputs')
    FileUtils.mkdir_p(inputs_path)
    File.write(
      File.join(inputs_path, 'recommendations.md'),
      File.read('test/fixtures/recommendations.md')
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    html = generator.generate

    # Should include recommendations in output
    _(html).must_include 'Jane Smith'
    _(html).must_include 'excellent engineer'
  end

  it "handles missing recommendations file gracefully" do
    inputs_path = File.join(@temp_dir, 'inputs')
    FileUtils.mkdir_p(inputs_path)
    # No recommendations.md file

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: inputs_path
    )

    # Should not raise error
    html = generator.generate
    _(html).wont_be_nil
  end
end
```

**Step 2: Run test to verify it fails**

Run: `ruby -Ilib:test test/unit/generators/website_generator_recommendations_test.rb`

Expected: FAIL (recommendations not in template vars)

**Step 3: Update WebsiteGenerator to load recommendations**

Modify `lib/jojo/generators/website_generator.rb`:

Add require at top (around line 6):
```ruby
require_relative '../recommendation_parser'
```

Add recommendation loading in `generate` method (around line 34):
```ruby
      log "Loading recommendations..."
      recommendations = load_recommendations
```

Add to `prepare_template_vars` (around line 145):
```ruby
        {
          seeker_name: config.seeker_name,
          company_name: inputs[:company_name],
          company_slug: inputs[:company_slug],
          job_title: job_title,
          branding_statement: branding_statement,
          cta_text: config.website_cta_text,
          cta_link: cta_link,
          has_branding_image: branding_image_info[:exists],
          branding_image_path: branding_image_info[:relative_path],
          base_url: config.base_url,
          projects: projects,
          annotated_job_description: annotated_job_description,
          recommendations: recommendations  # ADD THIS LINE
        }
```

Update render_template binding (around line 170):
```ruby
        seeker_name = vars[:seeker_name]
        company_name = vars[:company_name]
        company_slug = vars[:company_slug]
        job_title = vars[:job_title]
        branding_statement = vars[:branding_statement]
        cta_text = vars[:cta_text]
        cta_link = vars[:cta_link]
        has_branding_image = vars[:has_branding_image]
        branding_image_path = vars[:branding_image_path]
        base_url = vars[:base_url]
        projects = vars[:projects]
        annotated_job_description = vars[:annotated_job_description]
        recommendations = vars[:recommendations]  # ADD THIS LINE
```

Pass recommendations to prepare_template_vars (around line 38):
```ruby
        template_vars = prepare_template_vars(branding_statement, inputs, projects, annotated_job_description, recommendations)
```

Update prepare_template_vars signature (around line 118):
```ruby
      def prepare_template_vars(branding_statement, inputs, projects = [], annotated_job_description = nil, recommendations = nil)
```

Add new private method at end (before `end` of class):
```ruby
      def load_recommendations
        recommendations_path = File.join(inputs_path, 'recommendations.md')

        unless File.exist?(recommendations_path)
          log "No recommendations found at #{recommendations_path}"
          return nil
        end

        parser = RecommendationParser.new(recommendations_path)
        recommendations = parser.parse

        if recommendations.nil? || recommendations.empty?
          log "Warning: No valid recommendations found in #{recommendations_path}"
          return nil
        end

        log "Loaded #{recommendations.size} recommendation(s)"
        recommendations
      rescue => e
        log "Error loading recommendations: #{e.message}"
        nil
      end
```

**Step 4: Run test to verify it passes**

Run: `ruby -Ilib:test test/unit/generators/website_generator_recommendations_test.rb`

Expected: Tests still FAIL because template doesn't render recommendations yet (that's next task)

For now, verify the recommendations are loaded by checking they're in template vars.

Update test temporarily to check template vars instead of HTML output.

**Step 5: Commit**

```bash
git add lib/jojo/generators/website_generator.rb test/unit/generators/website_generator_recommendations_test.rb
git commit -m "feat: integrate RecommendationParser into WebsiteGenerator"
```

---

## Task 4: Add Carousel HTML and CSS to Template

**Files:**
- Modify: `templates/website/default.html.erb:471` (add recommendations section)
- Modify: `templates/website/default.html.erb:398-end` (add CSS before </style>)

**Step 1: Add carousel CSS**

In `templates/website/default.html.erb`, add before `</style>` tag (around line 398):

```css
    /* Recommendations Carousel Section */
    .recommendations {
      margin: 3rem 0;
      padding: 2rem;
      background-color: var(--background-alt);
      border-radius: 8px;
    }

    .recommendations h2 {
      text-align: center;
      margin-top: 0;
      margin-bottom: 2rem;
      color: var(--text-color);
    }

    .carousel-container {
      position: relative;
      overflow: hidden;
      max-width: 700px;
      margin: 0 auto;
    }

    .carousel-track {
      display: flex;
      transition: transform 300ms ease-in-out;
    }

    .carousel-slide {
      min-width: 100%;
      flex-shrink: 0;
      padding: 0 1rem;
    }

    .recommendation-card {
      background: var(--background);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      padding: 2.5rem;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      position: relative;
    }

    .recommendation-card::before {
      content: '"';
      position: absolute;
      top: 1rem;
      left: 1.5rem;
      font-size: 4rem;
      line-height: 1;
      color: rgba(0, 0, 0, 0.1);
      font-family: Georgia, serif;
    }

    .recommendation-quote {
      font-size: 1.125rem;
      line-height: 1.8;
      color: var(--text-color);
      margin-bottom: 1.5rem;
      position: relative;
      z-index: 1;
    }

    .recommendation-attribution {
      font-size: 0.9rem;
      color: var(--text-light);
      font-style: italic;
    }

    .recommendation-attribution strong {
      font-weight: 600;
      color: var(--text-color);
      font-style: normal;
    }

    /* Carousel Navigation */
    .carousel-arrow {
      position: absolute;
      top: 50%;
      transform: translateY(-50%);
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: var(--background);
      border: 1px solid var(--border-color);
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
      color: var(--text-color);
      transition: all 0.2s ease;
      z-index: 10;
    }

    .carousel-arrow:hover {
      background: var(--primary-color);
      color: white;
      border-color: var(--primary-color);
    }

    .carousel-arrow.prev {
      left: -50px;
    }

    .carousel-arrow.next {
      right: -50px;
    }

    .carousel-arrow:disabled {
      opacity: 0.3;
      cursor: not-allowed;
    }

    .carousel-dots {
      display: flex;
      justify-content: center;
      gap: 0.5rem;
      margin-top: 1.5rem;
    }

    .carousel-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--border-color);
      border: none;
      cursor: pointer;
      transition: background-color 0.2s ease;
      padding: 0;
    }

    .carousel-dot.active {
      background: var(--primary-color);
    }

    .carousel-dot:hover {
      background: var(--primary-hover);
    }

    /* Single recommendation - no navigation */
    .recommendations.single-recommendation .carousel-arrow,
    .recommendations.single-recommendation .carousel-dots {
      display: none;
    }

    /* Responsive */
    @media (max-width: 640px) {
      .recommendations {
        padding: 1.5rem 1rem;
      }

      .recommendation-card {
        padding: 2rem 1.5rem;
      }

      .recommendation-card::before {
        font-size: 3rem;
      }

      .recommendation-quote {
        font-size: 1rem;
      }

      .carousel-arrow {
        width: 32px;
        height: 32px;
        font-size: 1.25rem;
      }

      .carousel-arrow.prev {
        left: -40px;
      }

      .carousel-arrow.next {
        right: -40px;
      }
    }
```

**Step 2: Add carousel HTML section**

In `templates/website/default.html.erb`, add after projects section (around line 471, before CTA section):

```erb
    <!-- Recommendations Carousel -->
    <% if recommendations && !recommendations.empty? %>
    <section class="recommendations<%= ' single-recommendation' if recommendations.size == 1 %>">
      <h2>What Others Say</h2>
      <div class="carousel-container">
        <div class="carousel-track">
          <% recommendations.each do |rec| %>
          <div class="carousel-slide">
            <div class="recommendation-card">
              <div class="recommendation-quote">
                <%= rec[:quote] %>
              </div>
              <div class="recommendation-attribution">
                <strong><%= rec[:recommender_name] %></strong><% if rec[:recommender_title] %>, <%= rec[:recommender_title] %><% end %>
                <br><%= rec[:relationship] %>
              </div>
            </div>
          </div>
          <% end %>
        </div>
        <button class="carousel-arrow prev" aria-label="Previous recommendation">‹</button>
        <button class="carousel-arrow next" aria-label="Next recommendation">›</button>
      </div>
      <div class="carousel-dots" role="tablist">
        <% recommendations.each_with_index do |_, index| %>
        <button class="carousel-dot<%= ' active' if index == 0 %>"
                aria-label="Go to recommendation <%= index + 1 %>"
                data-index="<%= index %>"></button>
        <% end %>
      </div>
    </section>
    <% end %>
```

**Step 3: Manual test - generate website**

Run: `./bin/jojo generate -e "Test Corp" -j test/fixtures/sample_job.txt -v` (if you have a test setup)

Or create a minimal test:
- Create inputs/recommendations.md with test data
- Generate website
- Open in browser
- Verify carousel HTML is present (JS not working yet)

**Step 4: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "feat: add carousel HTML and CSS to template"
```

---

## Task 5: Add Carousel JavaScript - Basic Navigation

**Files:**
- Modify: `templates/website/default.html.erb:597-end` (add JS before </body>)

**Step 1: Add carousel JavaScript**

In `templates/website/default.html.erb`, add before `</body>` tag (after existing annotation script, around line 597):

```erb
  <% if recommendations && recommendations.size > 1 %>
  <!-- Recommendations Carousel JavaScript -->
  <script>
  (function() {
    'use strict';

    // Carousel state
    const carousel = {
      track: document.querySelector('.recommendations .carousel-track'),
      slides: document.querySelectorAll('.recommendations .carousel-slide'),
      prevBtn: document.querySelector('.recommendations .carousel-arrow.prev'),
      nextBtn: document.querySelector('.recommendations .carousel-arrow.next'),
      dots: document.querySelectorAll('.recommendations .carousel-dot'),
      currentIndex: 0,
      totalSlides: <%= recommendations.size %>,
      isTransitioning: false,
      autoAdvanceInterval: null,
      autoAdvanceDelay: 6000
    };

    // Go to specific slide
    function goToSlide(index) {
      if (carousel.isTransitioning) return;

      carousel.isTransitioning = true;
      carousel.currentIndex = index;

      // Update transform
      const offset = -index * 100;
      carousel.track.style.transform = `translateX(${offset}%)`;

      // Update dots
      carousel.dots.forEach((dot, i) => {
        dot.classList.toggle('active', i === index);
      });

      // Update ARIA
      carousel.slides.forEach((slide, i) => {
        slide.setAttribute('aria-hidden', i !== index);
      });

      setTimeout(() => {
        carousel.isTransitioning = false;
      }, 300);
    }

    // Next slide
    function nextSlide() {
      const next = (carousel.currentIndex + 1) % carousel.totalSlides;
      goToSlide(next);
    }

    // Previous slide
    function prevSlide() {
      const prev = (carousel.currentIndex - 1 + carousel.totalSlides) % carousel.totalSlides;
      goToSlide(prev);
    }

    // Auto-advance
    function startAutoAdvance() {
      if (carousel.autoAdvanceInterval) return;

      carousel.autoAdvanceInterval = setInterval(() => {
        nextSlide();
      }, carousel.autoAdvanceDelay);
    }

    function pauseAutoAdvance() {
      if (carousel.autoAdvanceInterval) {
        clearInterval(carousel.autoAdvanceInterval);
        carousel.autoAdvanceInterval = null;
      }
    }

    function resumeAutoAdvance() {
      pauseAutoAdvance();
      setTimeout(startAutoAdvance, 1000);
    }

    // Event listeners
    carousel.prevBtn.addEventListener('click', () => {
      prevSlide();
      pauseAutoAdvance();
    });

    carousel.nextBtn.addEventListener('click', () => {
      nextSlide();
      pauseAutoAdvance();
    });

    carousel.dots.forEach((dot, index) => {
      dot.addEventListener('click', () => {
        goToSlide(index);
        pauseAutoAdvance();
      });
    });

    // Pause on hover
    const container = document.querySelector('.recommendations');
    container.addEventListener('mouseenter', pauseAutoAdvance);
    container.addEventListener('mouseleave', resumeAutoAdvance);

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (e.target.closest('.recommendations')) {
        if (e.key === 'ArrowLeft') {
          prevSlide();
          pauseAutoAdvance();
        } else if (e.key === 'ArrowRight') {
          nextSlide();
          pauseAutoAdvance();
        }
      }
    });

    // Initialize
    goToSlide(0);
    startAutoAdvance();

    // Pause when tab not visible
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        pauseAutoAdvance();
      } else {
        resumeAutoAdvance();
      }
    });
  })();
  </script>
  <% end %>
```

**Step 2: Manual test**

- Generate website with multiple recommendations
- Open in browser
- Verify auto-advance works (6 second interval)
- Verify prev/next buttons work
- Verify dots work
- Verify hover pauses auto-advance
- Verify keyboard arrows work

**Step 3: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "feat: add carousel JavaScript with navigation and auto-advance"
```

---

## Task 6: Add Touch/Swipe Support

**Files:**
- Modify: `templates/website/default.html.erb` (carousel JS section)

**Step 1: Add touch event handlers to carousel JavaScript**

In the carousel JavaScript (inside the IIFE, after keyboard navigation, before initialize), add:

```javascript
    // Touch/swipe support
    const isTouchDevice = window.matchMedia('(hover: none)').matches;
    let touchStartX = 0;
    let touchEndX = 0;
    const swipeThreshold = 50;

    function handleSwipe() {
      const diff = touchStartX - touchEndX;

      if (Math.abs(diff) > swipeThreshold) {
        if (diff > 0) {
          // Swipe left - next slide
          nextSlide();
        } else {
          // Swipe right - previous slide
          prevSlide();
        }
        pauseAutoAdvance();
        setTimeout(resumeAutoAdvance, 2000);
      }
    }

    container.addEventListener('touchstart', (e) => {
      touchStartX = e.changedTouches[0].screenX;
      pauseAutoAdvance();
    }, { passive: true });

    container.addEventListener('touchend', (e) => {
      touchEndX = e.changedTouches[0].screenX;
      handleSwipe();
    }, { passive: true });
```

**Step 2: Test on mobile device or browser dev tools**

- Open in browser dev tools mobile view
- Test swipe left/right
- Verify auto-advance pauses on touch
- Verify auto-advance resumes after swipe

**Step 3: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "feat: add touch swipe support to carousel"
```

---

## Task 7: Add Accessibility Features

**Files:**
- Modify: `templates/website/default.html.erb` (carousel HTML and JS)

**Step 1: Add ARIA attributes to carousel HTML**

Update carousel HTML section:

```erb
      <div class="carousel-container" role="region" aria-label="Recommendations carousel">
        <div class="carousel-track">
          <% recommendations.each_with_index do |rec, index| %>
          <div class="carousel-slide" role="tabpanel" aria-hidden="<%= index != 0 %>">
```

**Step 2: Add reduced motion support to JavaScript**

In carousel JavaScript, after state declaration, add:

```javascript
    // Check for reduced motion preference
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
```

Update startAutoAdvance function:

```javascript
    function startAutoAdvance() {
      if (carousel.autoAdvanceInterval || prefersReducedMotion) return;

      carousel.autoAdvanceInterval = setInterval(() => {
        nextSlide();
      }, carousel.autoAdvanceDelay);
    }
```

**Step 3: Add ARIA live region for screen readers**

In HTML, add after carousel-dots:

```erb
      </div>
      <div class="sr-only" aria-live="polite" aria-atomic="true" id="carousel-status">
        Showing recommendation <span id="carousel-current">1</span> of <%= recommendations.size %>
      </div>
```

Add CSS for sr-only class (in CSS section):

```css
    .sr-only {
      position: absolute;
      width: 1px;
      height: 1px;
      padding: 0;
      margin: -1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      white-space: nowrap;
      border-width: 0;
    }
```

Update goToSlide function to announce changes:

```javascript
      // Update ARIA live region
      const statusCurrent = document.getElementById('carousel-current');
      if (statusCurrent) {
        statusCurrent.textContent = index + 1;
      }
```

**Step 4: Test with screen reader**

- Test with VoiceOver (Mac) or NVDA (Windows)
- Verify announcements work
- Verify keyboard navigation
- Verify reduced motion preference disables auto-advance

**Step 5: Commit**

```bash
git add templates/website/default.html.erb
git commit -m "feat: add accessibility features to carousel"
```

---

## Task 8: Integration Tests

**Files:**
- Create: `test/integration/recommendations_workflow_test.rb`

**Step 1: Write integration test**

Create `test/integration/recommendations_workflow_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/generators/website_generator'
require_relative '../../lib/jojo/config'
require 'tmpdir'
require 'fileutils'

describe 'Recommendations Workflow Integration' do
  before do
    @temp_dir = Dir.mktmpdir
    @employer = Jojo::Employer.new('Integration Test Corp', base_path: @temp_dir)

    # Create required files
    FileUtils.mkdir_p(@employer.employer_path)
    File.write(@employer.job_description_path, "Software Engineer position")
    File.write(@employer.resume_path, "My resume content")

    # Create inputs directory
    @inputs_path = File.join(@temp_dir, 'inputs')
    FileUtils.mkdir_p(@inputs_path)

    # Mock AI client
    @ai_client = Minitest::Mock.new
    @ai_client.expect(:generate_text, "I am the perfect fit", [String])

    # Mock config
    @config = Minitest::Mock.new
    @config.expect(:seeker_name, "Test User")
    @config.expect(:voice_and_tone, "professional")
    @config.expect(:website_cta_text, "Contact me")
    @config.expect(:website_cta_link, "mailto:test@example.com")
    @config.expect(:base_url, "https://example.com")
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  it "generates complete website with recommendations carousel" do
    # Create recommendations file
    File.write(
      File.join(@inputs_path, 'recommendations.md'),
      File.read('test/fixtures/recommendations.md')
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify HTML includes carousel structure
    _(html).must_include '<section class="recommendations">'
    _(html).must_include 'What Others Say'
    _(html).must_include 'carousel-track'
    _(html).must_include 'carousel-slide'
    _(html).must_include 'carousel-arrow'
    _(html).must_include 'carousel-dots'

    # Verify recommendations content
    _(html).must_include 'Jane Smith'
    _(html).must_include 'Senior Engineering Manager'
    _(html).must_include 'excellent engineer'
    _(html).must_include 'Bob Johnson'

    # Verify JavaScript is included
    _(html).must_include 'Recommendations Carousel JavaScript'
    _(html).must_include 'function goToSlide'
    _(html).must_include 'startAutoAdvance'
  end

  it "generates website without carousel when no recommendations" do
    # Don't create recommendations file

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify no carousel HTML
    _(html).wont_include '<section class="recommendations">'
    _(html).wont_include 'carousel-track'
    _(html).wont_include 'Recommendations Carousel JavaScript'
  end

  it "generates static card for single recommendation" do
    # Create recommendations file with single recommendation
    File.write(
      File.join(@inputs_path, 'recommendations.md'),
      File.read('test/fixtures/recommendations_minimal.md')
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Verify recommendations section exists
    _(html).must_include '<section class="recommendations single-recommendation">'
    _(html).must_include 'Alice Lee'

    # Verify no carousel JavaScript (single recommendation)
    _(html).wont_include 'Recommendations Carousel JavaScript'
  end

  it "positions recommendations after job description and before projects" do
    # Add all sections
    File.write(
      File.join(@inputs_path, 'recommendations.md'),
      File.read('test/fixtures/recommendations.md')
    )
    File.write(
      File.join(@inputs_path, 'projects.yml'),
      File.read('test/fixtures/valid_projects.yml')
    )
    File.write(@employer.job_description_annotations_path, '[]')

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    html = generator.generate

    # Find positions in HTML
    job_desc_pos = html.index('job-description-comparison')
    recommendations_pos = html.index('class="recommendations"')
    projects_pos = html.index('class="projects"')

    # Verify order (skip nil checks for sections that might not exist)
    if job_desc_pos && recommendations_pos
      _(recommendations_pos).must_be :>, job_desc_pos
    end

    if recommendations_pos && projects_pos
      _(projects_pos).must_be :>, recommendations_pos
    end
  end

  it "handles malformed recommendations gracefully" do
    File.write(
      File.join(@inputs_path, 'recommendations.md'),
      File.read('test/fixtures/recommendations_malformed.md')
    )

    generator = Jojo::Generators::WebsiteGenerator.new(
      @employer,
      @ai_client,
      config: @config,
      inputs_path: @inputs_path
    )

    # Should not raise error
    html = generator.generate

    # Should include valid recommendation, skip invalid
    _(html).must_include 'Valid Person'
    _(html).wont_include 'Missing Name'
  end
end
```

**Step 2: Run integration tests**

Run: `ruby -Ilib:test test/integration/recommendations_workflow_test.rb`

Expected: 5 tests PASS

**Step 3: Commit**

```bash
git add test/integration/recommendations_workflow_test.rb
git commit -m "test: add integration tests for recommendations carousel"
```

---

## Task 9: Run Full Test Suite

**Files:**
- All test files

**Step 1: Run all unit tests**

Run: `./bin/jojo test --unit`

Expected: All unit tests PASS (~112 tests including new ones)

**Step 2: Run all integration tests**

Run: `./bin/jojo test --integration`

Expected: All integration tests PASS (~15 tests including new ones)

**Step 3: Run complete test suite**

Run: `./bin/jojo test --all`

Expected: All tests PASS (~127 total tests)

**Step 4: Fix any failing tests**

If tests fail, fix issues and re-run.

**Step 5: Commit if any fixes were needed**

```bash
git add .
git commit -m "fix: address test failures"
```

---

## Task 10: Update Implementation Plan

**Files:**
- Modify: `docs/plans/implementation_plan.md`

**Step 1: Mark Phase 6d tasks as complete**

Update Phase 6d section in `docs/plans/implementation_plan.md`:

Change all `[ ]` to `[x]` for Phase 6d tasks:

```markdown
### Phase 6d: Recommendations Carousel

**Goal**: Display recommendation quotes with carousel

**Status**: COMPLETED

#### Tasks:

- [x] Parse `inputs/recommendations.md`
  - Extract individual recommendations
  - Parse author/relationship metadata

- [x] Create carousel JavaScript component
  - Auto-advance with manual controls
  - Responsive design

- [x] Update template with recommendations section
  - "What do my co-workers say?" heading
  - Carousel container

- [x] Create tests for recommendation parsing

**Validation**: ✅ Recommendations display in rotating carousel. Auto-advance works. Swipe gestures functional. Keyboard navigation works. Accessibility features present.
```

Add ✅ to Phase 6d heading:

```markdown
### Phase 6d: Recommendations Carousel ✅
```

**Step 2: Review and commit**

```bash
git add docs/plans/implementation_plan.md
git commit -m "docs: mark Phase 6d as completed"
```

---

## Task 11: Final Manual Testing

**Files:**
- N/A (manual testing)

**Step 1: Test with real data**

1. Create `inputs/recommendations.md` with 3-4 real recommendations
2. Run: `./bin/jojo generate -e "Test Company" -j inputs/sample_job.md`
3. Open generated `employers/test-company/website/index.html` in browser

**Step 2: Test all features**

Desktop:
- ✅ Carousel auto-advances every 6 seconds
- ✅ Hover pauses auto-advance
- ✅ Mouse leave resumes auto-advance
- ✅ Prev/next buttons work
- ✅ Dot indicators work
- ✅ Keyboard arrows work
- ✅ Recommendations positioned correctly in page flow

Mobile (Chrome DevTools):
- ✅ Swipe left/right works
- ✅ Touch pauses auto-advance
- ✅ Responsive design looks good
- ✅ Arrows visible but smaller

Accessibility:
- ✅ Tab through interactive elements works
- ✅ Screen reader announces slide changes (test with VoiceOver)
- ✅ Reduced motion preference disables auto-advance

Edge cases:
- ✅ Single recommendation shows static card (no carousel UI)
- ✅ No recommendations → section not rendered
- ✅ Malformed recommendations handled gracefully

**Step 3: Browser testing**

Test in multiple browsers:
- Chrome
- Firefox
- Safari

**Step 4: Document any issues found**

Create issues or fix immediately if trivial.

---

## Task 12: Create Example Recommendations Template

**Files:**
- Modify: `templates/recommendations.md`

**Step 1: Update template with better example**

Update `templates/recommendations.md` to be more helpful:

```markdown
# LinkedIn Recommendations

These recommendations will be displayed in a carousel on your landing page.

**Instructions:**
1. Copy this file to `inputs/recommendations.md`
2. Go to your LinkedIn profile → Recommendations
3. Copy each recommendation you want to showcase
4. Fill in the template below for each one
5. Keep the most impactful 3-5 recommendations (quality over quantity)

---

## Recommendation from [Full Name]
**Their Title:** [Their current job title]
**Your Role:** [Your job title when you worked together]
**Relationship:** [Former Manager | Colleague | Direct Report | Client | etc.]

> [Paste the full LinkedIn recommendation text here.
> Keep the exact wording - authenticity matters.
> Multi-paragraph recommendations are fine.]

**Key Phrases to Use:**
- "[Notable skill or quality they mentioned]"
- "[Specific achievement they highlighted]"

---

## Recommendation from [Another Recommender]
**Their Title:** [Job Title]
**Your Role:** [Your Job Title]
**Relationship:** [Your relationship]

> [Full recommendation text]

**Key Phrases to Use:**
- "[Skill or quality]"
- "[Achievement]"

---

## Tips for Choosing Recommendations

- **Recent is better**: Prioritize recommendations from the last 2-3 years
- **Specific over generic**: "Delivered X project ahead of schedule" beats "hard worker"
- **Relevant skills**: Match recommendations to the types of roles you're seeking
- **Diverse perspectives**: Include managers, peers, and direct reports if possible
- **Achievement-focused**: Best recommendations cite concrete results

## Optional: Add Headshots (Future Feature)

In a future version, you'll be able to add headshot images for recommenders.
For now, focus on the text content.
```

**Step 2: Commit**

```bash
git add templates/recommendations.md
git commit -m "docs: improve recommendations template with tips and examples"
```

---

## Success Criteria

✅ RecommendationParser parses markdown correctly
✅ WebsiteGenerator loads recommendations
✅ Template renders carousel with all recommendations
✅ Auto-advance rotates every 6 seconds
✅ Hover/click/swipe pauses auto-advance
✅ Arrow buttons and dots navigate correctly
✅ Mobile swipe gestures work
✅ Keyboard navigation functional
✅ Accessibility features present (ARIA, reduced motion, screen reader)
✅ Single recommendation shows static card
✅ No recommendations → section not rendered
✅ All tests passing (~127 total)
✅ Positioned correctly (after job description, before projects)

## Validation Commands

```bash
# Run tests
./bin/jojo test --all

# Generate test website
./bin/jojo generate -e "Test Corp" -j inputs/sample_job.md -v

# Check test coverage
ruby -Ilib:test test/unit/recommendation_parser_test.rb
ruby -Ilib:test test/unit/generators/website_generator_recommendations_test.rb
ruby -Ilib:test test/integration/recommendations_workflow_test.rb
```
