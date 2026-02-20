# Website Redesign: Tailwind CSS + DaisyUI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the Open Props CSS framework with Tailwind CSS + DaisyUI to produce a modern, visually compelling landing page inspired by the Whitepace design mockups.

**Architecture:** The ERB template (`templates/website/default.html.erb`) will be rewritten with Tailwind utility classes and DaisyUI components. The Tailwind CLI will compile a production CSS file during website generation. Hand-rolled carousel and accordion JS will be replaced by DaisyUI's CSS-only components, keeping only the annotation tooltip JS (which is unique to jojo). The existing test suite will be updated to validate the new HTML structure.

**Tech Stack:** Tailwind CSS 4 (CLI), DaisyUI 5, ERB templates, vanilla JS (annotations only)

---

## Prerequisites

- `tailwindcss` CLI is installed and available on PATH
- Ruby 3.4.5, Bundler, Minitest
- Reference design: `tmp/whitepace_desgin/` (design tokens, landing page mockups)
- `rodney` CLI installed for dev-time visual testing

## Design Tokens (from Whitepace mockups)

| Token | Value | Usage |
|-------|-------|-------|
| Primary Dark | `#034873` | Header bg, dark text |
| Primary Light | `#4F9CF9` | CTA buttons, links, accents |
| Secondary Yellow | `#FFE492` | Highlights, badges |
| Secondary Light Blue | `#A7CEFC` | Alternating section bg |
| White | `#FFFFFF` | Main background |
| Dark | `#212529` | Body text, dark sections |
| Font | Inter (Google Fonts) | All text |

---

## Task 1: Set Up Tailwind CSS Infrastructure

**Files:**
- Create: `templates/website/tailwind/input.css`
- Create: `templates/website/tailwind/tailwind.config.js`
- Modify: `lib/jojo/commands/website/generator.rb:220-238` (copy_template_assets)

**Step 1: Create the Tailwind input CSS file**

Create `templates/website/tailwind/input.css`:

```css
@import "tailwindcss";
@plugin "daisyui";

@theme {
  --color-primary-dark: #034873;
  --color-primary-light: #4F9CF9;
  --color-secondary-yellow: #FFE492;
  --color-secondary-blue: #A7CEFC;
  --color-dark: #212529;
  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
}
```

**Step 2: Create the Tailwind config file**

Create `templates/website/tailwind/tailwind.config.js`:

```js
module.exports = {
  content: ["../default.html.erb"],
  plugins: [require("daisyui")],
  daisyui: {
    themes: [
      {
        jojo: {
          "primary": "#4F9CF9",
          "primary-content": "#ffffff",
          "secondary": "#034873",
          "secondary-content": "#ffffff",
          "accent": "#FFE492",
          "accent-content": "#212529",
          "neutral": "#212529",
          "neutral-content": "#ffffff",
          "base-100": "#ffffff",
          "base-200": "#f8fafc",
          "base-300": "#A7CEFC",
          "info": "#A7CEFC",
          "success": "#22c55e",
          "warning": "#FFE492",
          "error": "#ef4444",
        },
      },
    ],
  },
};
```

Note: Tailwind 4 may handle config differently (CSS-based config via `@theme`). Verify the exact Tailwind 4 configuration approach by running `tailwindcss --help` to check the version, then consult the appropriate docs. The above files show the intent — adapt syntax to match the installed version.

**Step 3: Verify Tailwind CLI works with a test build**

Run:
```bash
cd templates/website && tailwindcss -i tailwind/input.css -o styles-tw.css --minify 2>&1 | head -20
```
Expected: A compiled CSS file is produced at `templates/website/styles-tw.css`. Check output for errors. If the Tailwind 4 CLI needs different flags or config approach, adapt accordingly.

Clean up the test file:
```bash
rm templates/website/styles-tw.css
```

**Step 4: Add Tailwind build step to generator**

In `lib/jojo/commands/website/generator.rb`, add a new method `build_tailwind_css` and call it from `copy_template_assets`. The build step should:

1. Run `tailwindcss` CLI to compile the input CSS, scanning the ERB template for classes
2. Output the compiled CSS directly to `{application.website_path}/styles.css`
3. Raise a clear error if `tailwindcss` is not found on PATH

```ruby
def build_tailwind_css
  template_dir = File.join("templates", "website")
  input_css = File.join(template_dir, "tailwind", "input.css")
  output_css = File.join(application.website_path, "styles.css")

  unless system("which tailwindcss > /dev/null 2>&1")
    raise "tailwindcss CLI not found. Install it: https://tailwindcss.com/docs/installation"
  end

  cmd = "tailwindcss -i #{input_css} -o #{output_css} --minify"
  log "Building Tailwind CSS: #{cmd}"

  unless system(cmd)
    raise "Tailwind CSS build failed. Check your template for syntax errors."
  end
end
```

Update `copy_template_assets` to call `build_tailwind_css` instead of copying `styles.css`, and remove `styles.css` from the static assets list. Keep copying `script.js` and `icons.svg`.

**Step 5: Write a test for the Tailwind build step**

In `test/unit/commands/website/generator_test.rb`, add a test that verifies:
- The generator calls the tailwind build (mock `system` or check the output CSS file exists)
- The output CSS file is present in the website directory after generation

**Step 6: Run tests**

Run: `./bin/test`
Expected: All existing tests pass (the old `styles.css` copy test may need updating).

**Step 7: Commit**

```bash
git add templates/website/tailwind/ lib/jojo/commands/website/generator.rb test/
git commit -m "feat(website): add Tailwind CSS build infrastructure

Replace static Open Props CSS with Tailwind CLI build step.
Generator now compiles Tailwind CSS during website generation."
```

---

## Task 2: Install DaisyUI and Verify Theme

**Files:**
- Modify: `templates/website/tailwind/input.css` (if DaisyUI plugin needs adjustment)

**Step 1: Verify DaisyUI is available to the Tailwind CLI**

DaisyUI 5 can be used as a Tailwind 4 plugin via `@plugin "daisyui"` in the CSS. Verify this works:

```bash
cd templates/website && tailwindcss -i tailwind/input.css -o /tmp/test-daisyui.css 2>&1 | head -20
```

If DaisyUI is not found, install it. Check if there's already a `node_modules` or if we need a different approach for the standalone CLI. The standalone Tailwind CLI doesn't support JS plugins — if that's the case, we'll need to use `npx tailwindcss` with a local `package.json` instead.

**Step 2: Resolve DaisyUI installation approach**

If using the standalone CLI and DaisyUI doesn't work:
- Create `templates/website/package.json` with `tailwindcss` and `daisyui` as dependencies
- Run `npm install` in `templates/website/`
- Update the build command in `generator.rb` to use `npx tailwindcss` from that directory
- Add `templates/website/node_modules/` to `.gitignore`

If DaisyUI 5 works with `@plugin "daisyui"` (Tailwind 4 CSS-first config), no extra setup needed.

**Step 3: Create a minimal test template to verify DaisyUI classes compile**

Create a temporary test HTML file, add some DaisyUI classes (`btn btn-primary`, `card`, `collapse`), build, and verify the output CSS contains the component styles.

**Step 4: Clean up test artifacts and commit**

```bash
git add templates/website/tailwind/ .gitignore
git commit -m "feat(website): configure DaisyUI theme with jojo design tokens"
```

---

## Task 3: Rewrite ERB Template — Header and Hero

**Files:**
- Modify: `templates/website/default.html.erb:1-68`

**Step 1: Write a test for the new header structure**

In `test/unit/commands/website/generator_test.rb`, add/update tests:
- Header contains the seeker name
- Header contains navigation links
- Header contains CTA button when configured
- Hero section has the company name and job title

**Step 2: Run test to verify it fails**

Run: `bundle exec rake test:unit`
Expected: FAIL — new HTML structure assertions don't match old template.

**Step 3: Rewrite the head and header sections**

Replace the `<head>` section to:
- Load Inter font from Google Fonts
- Reference `styles.css` (compiled Tailwind output, no more Open Props CDN)
- Set `data-theme="jojo"` on `<html>` for DaisyUI theming

Replace the header with a DaisyUI navbar:
```erb
<div class="navbar bg-secondary text-secondary-content sticky top-0 z-50 shadow-lg">
  <div class="navbar-start">
    <a class="text-xl font-bold" href="#"><%= seeker_name %></a>
  </div>
  <div class="navbar-center hidden lg:flex">
    <ul class="menu menu-horizontal px-1 gap-2">
      <%# nav links for each section %>
    </ul>
  </div>
  <div class="navbar-end">
    <%# CTA button %>
  </div>
</div>
```

Replace the masthead with a bold hero section inspired by the Whitepace mockups:
```erb
<div class="hero min-h-[60vh] bg-base-100">
  <div class="hero-content text-center flex-col">
    <h1 class="text-5xl font-bold text-secondary">
      Am I a good match for <%= company_name %>?
    </h1>
    <p class="text-xl text-gray-600 max-w-2xl">
      <%# subtitle with job title %>
    </p>
    <%# CTA button and branding image %>
  </div>
</div>
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec rake test:unit`
Expected: PASS (updated assertions match new structure).

**Step 5: Commit**

```bash
git add templates/website/default.html.erb test/
git commit -m "feat(website): rewrite header and hero with Tailwind/DaisyUI

Navbar with sticky positioning, bold hero section inspired by
Whitepace design. Loads Inter font, uses DaisyUI theme."
```

---

## Task 4: Rewrite ERB Template — Branding and Job Description Sections

**Files:**
- Modify: `templates/website/default.html.erb:70-89`

**Step 1: Write tests for new branding and job description structure**

Verify:
- Branding section renders paragraph content
- Job description section shows annotated content
- Annotation legend is present with tier labels

**Step 2: Run test to verify it fails**

Run: `bundle exec rake test:unit`
Expected: FAIL

**Step 3: Rewrite branding section**

Use alternating section backgrounds (white / light blue) matching the Whitepace rhythm:

```erb
<section id="branding" class="bg-base-100 py-16 px-4">
  <div class="max-w-3xl mx-auto">
    <div class="text-lg leading-relaxed text-gray-600 space-y-4">
      <%= branding_statement.split("\n\n").map { |para| "<p>#{para}</p>" }.join("\n") %>
    </div>
  </div>
</section>
```

**Step 4: Rewrite job description section**

Use the light-blue alternating background:

```erb
<section id="job-description" class="bg-base-300/30 py-16 px-4">
  <div class="max-w-3xl mx-auto">
    <h2 class="text-3xl font-bold text-secondary mb-8 text-center">
      Compare Me to the Job Description
    </h2>
    <div class="card bg-base-100 shadow-md">
      <div class="card-body prose max-w-none">
        <%= annotated_job_description %>
      </div>
    </div>
    <%# Legend below the card %>
  </div>
</section>
```

Keep the annotation `data-tier` attributes and CSS classes — the annotation tooltip JS still needs these. Add Tailwind classes for the annotation highlight colors in the `input.css` as custom utilities:

```css
@layer components {
  .annotated[data-tier="strong"] {
    @apply bg-primary/25 rounded-sm cursor-help;
  }
  .annotated[data-tier="moderate"] {
    @apply bg-primary/15 rounded-sm cursor-help;
  }
  .annotated[data-tier="mention"] {
    @apply bg-primary/[0.08] rounded-sm cursor-help;
  }
  .annotated:hover {
    @apply bg-primary/35;
  }
}
```

**Step 5: Run tests**

Run: `bundle exec rake test:unit`
Expected: PASS

**Step 6: Commit**

```bash
git add templates/website/default.html.erb templates/website/tailwind/input.css test/
git commit -m "feat(website): rewrite branding and job description sections

Alternating white/light-blue section backgrounds. Annotation
highlights use Tailwind custom components."
```

---

## Task 5: Rewrite ERB Template — Recommendations Section (DaisyUI Carousel)

**Files:**
- Modify: `templates/website/default.html.erb:91-127`
- Modify: `templates/website/script.js` (remove carousel JS)

**Step 1: Write tests for new recommendations structure**

Verify:
- Recommendation quotes are rendered
- Attribution (name, title, relationship) is present
- Navigation controls exist for multiple recommendations

**Step 2: Run test to verify it fails**

Run: `bundle exec rake test:unit`
Expected: FAIL

**Step 3: Rewrite recommendations with DaisyUI carousel**

DaisyUI 5 provides a CSS-based carousel. However, for auto-advance and the existing UX (dots, arrows, ARIA), we may want to keep a simplified JS carousel. Evaluate DaisyUI's carousel component and decide:

**Option A: DaisyUI CSS carousel** (simpler, fewer features):
```erb
<div class="carousel w-full">
  <% recommendations.each_with_index do |rec, index| %>
  <div id="rec-<%= index %>" class="carousel-item w-full">
    <div class="card bg-base-100 shadow-md w-full">
      <div class="card-body">
        <blockquote class="text-lg italic text-gray-700">
          "<%= rec[:quote] %>"
        </blockquote>
        <p class="text-sm text-gray-500 mt-4">
          <strong><%= rec[:name] %></strong><%= ", #{rec[:title]}" if rec[:title] %>
          <br><%= rec[:relationship] %>
        </p>
      </div>
    </div>
  </div>
  <% end %>
</div>
```

**Option B: Keep custom JS carousel** (richer UX — auto-advance, keyboard nav, swipe):
Keep the existing carousel JS but update the HTML to use Tailwind classes. This preserves the current accessibility features (ARIA live region, keyboard nav, reduced motion support).

Choose the option that best fits the design goals. If keeping custom JS, update the HTML class names in the carousel JS to match the new template.

**Step 4: Remove or simplify carousel JS**

If using DaisyUI carousel: remove the carousel IIFE from the inline `<script>` in the ERB template and from `script.js`.

If keeping custom JS: update class selectors in `script.js` to match new template structure.

**Step 5: Style the section with alternating background**

```erb
<section id="recommendations" class="bg-base-100 py-16 px-4">
  <div class="max-w-3xl mx-auto">
    <h2 class="text-3xl font-bold text-secondary mb-8 text-center">
      What Others Say
    </h2>
    <%# carousel content %>
  </div>
</section>
```

**Step 6: Run tests**

Run: `bundle exec rake test:unit`
Expected: PASS

**Step 7: Commit**

```bash
git add templates/website/default.html.erb templates/website/script.js test/
git commit -m "feat(website): rewrite recommendations section with Tailwind

Modernized carousel with DaisyUI card components and
alternating section rhythm."
```

---

## Task 6: Rewrite ERB Template — FAQ Section (DaisyUI Accordion)

**Files:**
- Modify: `templates/website/default.html.erb:129-147`
- Modify: `templates/website/script.js` (remove FAQ JS)

**Step 1: Write tests for new FAQ structure**

Verify:
- FAQ questions are rendered
- FAQ answers are rendered
- Accordion structure uses proper ARIA attributes

**Step 2: Run test to verify it fails**

Run: `bundle exec rake test:unit`
Expected: FAIL

**Step 3: Replace FAQ with DaisyUI accordion (collapse component)**

DaisyUI's `collapse` component handles expand/collapse with pure CSS — no JS needed:

```erb
<section id="faq" class="bg-base-300/30 py-16 px-4">
  <div class="max-w-3xl mx-auto">
    <h2 class="text-3xl font-bold text-secondary mb-8 text-center">
      Your Questions, Answered
    </h2>
    <div class="space-y-3">
      <% faqs.each_with_index do |faq, index| %>
      <div class="collapse collapse-arrow bg-base-100 shadow-sm border border-base-300">
        <input type="radio" name="faq-accordion" <%= 'checked="checked"' if index == 0 %> />
        <div class="collapse-title font-semibold text-secondary">
          <%= faq[:question] %>
        </div>
        <div class="collapse-content text-gray-600">
          <p><%= faq[:answer] %></p>
        </div>
      </div>
      <% end %>
    </div>
  </div>
</section>
```

This replaces ~90 lines of custom accordion JS with zero JS.

**Step 4: Remove FAQ JavaScript**

Remove the FAQ accordion IIFE from the inline `<script>` block in the ERB template. Also remove the FAQ section from `script.js`.

**Step 5: Run tests**

Run: `bundle exec rake test:unit`
Expected: PASS

**Step 6: Commit**

```bash
git add templates/website/default.html.erb templates/website/script.js test/
git commit -m "feat(website): replace FAQ accordion with DaisyUI collapse

Zero-JS accordion using DaisyUI collapse-arrow component.
Removes ~90 lines of custom accordion JavaScript."
```

---

## Task 7: Rewrite ERB Template — Projects Section

**Files:**
- Modify: `templates/website/default.html.erb:149-206`

**Step 1: Write tests for new projects structure**

Verify:
- Project names are rendered
- Project descriptions are present
- Skill tags are rendered
- Action buttons (blog, live demo, source) are present

**Step 2: Run test to verify it fails**

Run: `bundle exec rake test:unit`
Expected: FAIL

**Step 3: Rewrite projects section with DaisyUI cards**

```erb
<section id="projects" class="bg-base-100 py-16 px-4">
  <div class="max-w-5xl mx-auto">
    <h2 class="text-3xl font-bold text-secondary mb-8 text-center">
      Relevant Projects
    </h2>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <% projects.each do |project| %>
      <div class="card bg-base-100 shadow-md border border-base-300 hover:shadow-lg transition-shadow">
        <% if project[:image_url] %>
        <figure><img src="<%= project[:image_url] %>" alt="" loading="lazy" class="w-full h-48 object-cover" /></figure>
        <% end %>
        <div class="card-body">
          <h3 class="card-title text-secondary"><%= project[:name] %></h3>
          <p class="text-gray-600"><%= project[:description] %></p>
          <% if project[:skills] && !project[:skills].empty? %>
          <div class="flex flex-wrap gap-2 mt-2">
            <% project[:skills].each do |skill| %>
            <span class="badge badge-outline badge-sm"><%= skill %></span>
            <% end %>
          </div>
          <% end %>
          <div class="card-actions justify-start mt-4">
            <% if project[:blog_post_url] %>
            <a href="<%= project[:blog_post_url] %>" class="btn btn-primary btn-sm">Technical Deep Dive</a>
            <% end %>
            <% if project[:live_url] %>
            <a href="<%= project[:live_url] %>" class="btn btn-accent btn-sm">Live Demo</a>
            <% end %>
            <% if project[:url] %>
            <a href="<%= project[:url] %>" class="btn btn-outline btn-sm">Source Code</a>
            <% end %>
          </div>
          <% if project[:year] || project[:context] %>
          <div class="text-xs text-gray-400 mt-2 pt-2 border-t border-base-300 flex justify-between">
            <% if project[:year] %><span><%= project[:year] %></span><% end %>
            <% if project[:context] %><span class="italic"><%= project[:context] %></span><% end %>
          </div>
          <% end %>
        </div>
      </div>
      <% end %>
    </div>
  </div>
</section>
```

**Step 4: Run tests**

Run: `bundle exec rake test:unit`
Expected: PASS

**Step 5: Commit**

```bash
git add templates/website/default.html.erb test/
git commit -m "feat(website): rewrite projects section with DaisyUI cards

Grid layout with image support, badge skill tags, and
categorized action buttons."
```

---

## Task 8: Rewrite ERB Template — CTA and Footer

**Files:**
- Modify: `templates/website/default.html.erb:208-229`

**Step 1: Write tests for CTA and footer**

Verify:
- CTA section has button with link and text when configured
- CTA section absent when not configured
- Footer has resume and cover letter download links

**Step 2: Run test to verify it fails**

Run: `bundle exec rake test:unit`

**Step 3: Rewrite CTA section**

Inspired by the Whitepace "Try Whitespace today" section — dark blue background, centered white text:

```erb
<% if cta_link && !cta_link.strip.empty? %>
<section class="bg-secondary text-secondary-content py-20 px-4">
  <div class="max-w-2xl mx-auto text-center">
    <h2 class="text-3xl font-bold mb-4">Let's Connect</h2>
    <p class="text-lg opacity-90 mb-8">Interested in learning more? I'd love to chat.</p>
    <a href="<%= cta_link %>" class="btn btn-primary btn-lg"><%= cta_text %></a>
  </div>
</section>
<% end %>
```

**Step 4: Rewrite footer**

```erb
<footer class="footer footer-center p-6 bg-base-200 text-base-content border-t border-base-300">
  <div>
    <p class="text-sm text-gray-500 mb-2">Application materials for <%= company_name %></p>
    <div class="flex gap-4 justify-center">
      <a href="resume.pdf" class="link link-hover flex items-center gap-1">
        <svg class="w-4 h-4 fill-current"><use href="#icon-download"></use></svg>
        Resume (pdf)
      </a>
      <a href="cover-letter.pdf" class="link link-hover flex items-center gap-1">
        <svg class="w-4 h-4 fill-current"><use href="#icon-download"></use></svg>
        Cover Letter (pdf)
      </a>
    </div>
  </div>
</footer>
```

**Step 5: Run tests**

Run: `bundle exec rake test:unit`
Expected: PASS

**Step 6: Commit**

```bash
git add templates/website/default.html.erb test/
git commit -m "feat(website): rewrite CTA and footer sections

Dark blue CTA section with prominent button. Clean footer
with download links."
```

---

## Task 9: Clean Up — Remove Old CSS and Unused JS

**Files:**
- Delete: `templates/website/styles.css` (replaced by Tailwind build output)
- Modify: `templates/website/script.js` (keep only annotation tooltip JS)
- Modify: `templates/website/default.html.erb` (remove inline carousel/FAQ scripts)
- Modify: `lib/jojo/commands/website/generator.rb` (update asset list)

**Step 1: Delete the old styles.css**

The old 1007-line Open Props CSS file is no longer used. Delete it.

```bash
rm templates/website/styles.css
```

**Step 2: Simplify script.js**

Keep only the annotation tooltip IIFE (~105 lines). Remove the carousel and FAQ IIFEs if they haven't been removed already in Tasks 5 and 6.

**Step 3: Remove inline scripts from ERB template**

The inline `<script>` blocks for carousel and FAQ at the bottom of `default.html.erb` should be removed if not already done. Keep the annotation tooltip inline script (it uses ERB-injected conditions).

If the annotation tooltip script can work without ERB conditionals, move it to `script.js` too and remove all inline scripts.

**Step 4: Update generator asset list**

In `generator.rb`, the `copy_template_assets` method copies `["styles.css", "script.js", "icons.svg"]`. Update this to `["script.js", "icons.svg"]` since CSS is now built by Tailwind.

**Step 5: Run all tests**

Run: `./bin/test`
Expected: ALL PASS (unit, integration, standard)

**Step 6: Commit**

```bash
git add -A
git commit -m "refactor(website): remove old Open Props CSS and unused JS

Delete 1007-line styles.css (replaced by Tailwind build).
Simplify script.js to annotation tooltip only (~105 lines).
Remove inline carousel/FAQ scripts from template."
```

---

## Task 10: Update Integration Tests

**Files:**
- Modify: `test/integration/website_workflow_test.rb`

**Step 1: Review and update integration tests**

The integration test at `test/integration/website_workflow_test.rb` generates a full website. Update assertions to:
- Check that `styles.css` exists in output (now Tailwind-compiled, not copied)
- Update HTML structure assertions to match new Tailwind/DaisyUI class names
- Verify the generated HTML contains `data-theme="jojo"`
- Verify Inter font is loaded

**Step 2: Run integration tests**

Run: `bundle exec rake test:integration`
Expected: PASS

**Step 3: Run full test suite**

Run: `./bin/test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add test/
git commit -m "test(website): update integration tests for Tailwind template

Assertions updated to match new DaisyUI component structure
and Tailwind-compiled CSS output."
```

---

## Task 11: Visual Testing with Rodney (Development Only)

**Files:**
- Create: `bin/visual-test-website` (dev script, not production code)

**Step 1: Create a dev script for visual testing**

Create `bin/visual-test-website`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Visual test script for website output
# Usage: bin/visual-test-website <application-slug>
#
# Requires: rodney CLI (Chrome automation tool)

SLUG="${1:?Usage: bin/visual-test-website <application-slug>}"
WEBSITE_DIR="applications/${SLUG}/website"
INDEX="${WEBSITE_DIR}/index.html"

if [ ! -f "$INDEX" ]; then
  echo "Error: ${INDEX} not found. Generate the website first."
  exit 1
fi

SCREENSHOT_DIR="${WEBSITE_DIR}/screenshots"
mkdir -p "$SCREENSHOT_DIR"

echo "Starting Chrome..."
rodney start --show

echo "Opening ${INDEX}..."
rodney open "file://$(pwd)/${INDEX}"
rodney wait idle

echo "Taking desktop screenshot (1440px)..."
rodney screenshot "${SCREENSHOT_DIR}/desktop-1440.png" --full-page --width 1440

echo "Taking tablet screenshot (768px)..."
rodney screenshot "${SCREENSHOT_DIR}/tablet-768.png" --full-page --width 768

echo "Taking mobile screenshot (375px)..."
rodney screenshot "${SCREENSHOT_DIR}/mobile-375.png" --full-page --width 375

echo "Stopping Chrome..."
rodney stop

echo ""
echo "Screenshots saved to ${SCREENSHOT_DIR}/"
ls -la "${SCREENSHOT_DIR}/"
```

**Step 2: Make it executable**

```bash
chmod +x bin/visual-test-website
```

**Step 3: Test it against an existing generated website**

If there's an existing application with a generated website, run:
```bash
bin/visual-test-website <slug>
```

Verify screenshots are produced. Examine them to confirm the new design looks correct.

**Step 4: Add screenshots directory to .gitignore**

```
# Visual test screenshots
applications/*/website/screenshots/
```

**Step 5: Commit**

```bash
git add bin/visual-test-website .gitignore
git commit -m "feat(dev): add visual testing script for website output

Uses rodney to screenshot generated websites at desktop,
tablet, and mobile breakpoints. Development use only."
```

---

## Task 12: Final Validation

**Step 1: Run full test suite**

Run: `./bin/test`
Expected: ALL PASS (unit + integration + standard)

**Step 2: Generate a website and visually verify**

If test fixtures allow, generate a website for an existing application and open it in a browser:

```bash
./bin/jojo website -s <existing-slug> -v
open applications/<slug>/website/index.html
```

**Step 3: Compare against design mockups**

Visually compare the generated site against the Whitepace mockups in `tmp/whitepace_desgin/`:
- Header: dark blue navbar with white text, sticky ✓
- Hero: bold centered heading, CTA button ✓
- Section rhythm: alternating white / light blue backgrounds ✓
- Recommendations: card-based quotes ✓
- FAQ: clean accordion ✓
- Projects: grid cards with images, tags, buttons ✓
- CTA: dark blue section with centered button ✓
- Footer: clean, centered, download links ✓
- Typography: Inter font throughout ✓

**Step 4: Run visual test script**

```bash
bin/visual-test-website <slug>
```

Review screenshots at all three breakpoints.

**Step 5: Final commit (if any adjustments needed)**

```bash
git add -A
git commit -m "feat(website): complete Tailwind CSS + DaisyUI redesign

Modern, responsive landing page with DaisyUI components,
Whitepace-inspired design tokens, and streamlined JavaScript."
```

---

## Summary

| Task | What Changes | Lines Removed (approx) | Lines Added (approx) |
|------|-------------|----------------------|---------------------|
| 1 | Tailwind infrastructure | 0 | ~40 (config + build) |
| 2 | DaisyUI setup | 0 | ~10 |
| 3 | Header + Hero | ~68 | ~50 |
| 4 | Branding + Job Description | ~20 | ~40 |
| 5 | Recommendations | ~130 (incl JS) | ~30 |
| 6 | FAQ | ~95 (incl JS) | ~25 |
| 7 | Projects | ~55 | ~45 |
| 8 | CTA + Footer | ~20 | ~25 |
| 9 | Cleanup (old CSS, JS) | ~1250 | 0 |
| 10 | Integration tests | ~20 | ~25 |
| 11 | Visual test script | 0 | ~35 |
| 12 | Final validation | 0 | 0 |

**Net effect:** ~1650 lines removed, ~325 lines added. The generated website gets a modern, polished design with significantly less custom code.
