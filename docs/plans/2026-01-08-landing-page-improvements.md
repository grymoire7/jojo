# Landing Page Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Status:** ✅ COMPLETED

**Completed:** 2026-01-11

**Goal:** Modernize Jojo landing pages with Open Props design system, fix carousel overflow bug, redesign project cards with modern aesthetic, and replace FontAwesome with SVG sprite sheet.

**Architecture:** Multi-file structure (HTML, CSS, JS, SVG) using Open Props via CDN for consistent design tokens. Iterate on generated HTML first (`employers/cybercoders/website/`) then migrate improvements back to ERB template.

**Tech Stack:** Open Props (CSS design system), Vanilla JavaScript, SVG sprites, ERB templates

**Design Document:** `docs/plans/2026-01-08-landing-page-improvements-design.md`

---

## Phase 1: Setup & File Extraction

### Task 1.1: Create Working Copy

**Files:**
- Read: `employers/cybercoders/website/index.html`
- Backup: `employers/cybercoders/website/index.html.backup`

**Step 1: Create backup of current working file**

```bash
cp employers/cybercoders/website/index.html employers/cybercoders/website/index.html.backup
```

**Step 2: Verify backup exists**

Run: `ls -lh employers/cybercoders/website/index.html*`
Expected: Two files listed (original and backup)

**Step 3: Commit backup**

```bash
git add employers/cybercoders/website/index.html.backup
git commit -m "chore: backup current landing page before improvements"
```

---

### Task 1.2: Extract Inline CSS to External File

**Files:**
- Read: `employers/cybercoders/website/index.html`
- Create: `employers/cybercoders/website/styles.css`
- Modify: `employers/cybercoders/website/index.html` (remove inline styles)

**Step 1: Read current HTML file**

Read the entire `employers/cybercoders/website/index.html` file to locate the `<style>` tag with inline CSS.

**Step 2: Extract CSS from style tag**

Copy all content between `<style>` and `</style>` tags (approximately lines 5-1100).

**Step 3: Create styles.css**

Create `employers/cybercoders/website/styles.css` with the extracted CSS content.

**Step 4: Update HTML to reference external CSS**

In `employers/cybercoders/website/index.html`, replace the entire `<style>...</style>` block with:

```html
<link rel="stylesheet" href="styles.css">
```

**Step 5: Test in browser**

Open `employers/cybercoders/website/index.html` in a browser.
Expected: Page should look identical to before (all styles still applied).

**Step 6: Commit CSS extraction**

```bash
git add employers/cybercoders/website/styles.css employers/cybercoders/website/index.html
git commit -m "refactor: extract inline CSS to external file

Move ~1100 lines of inline CSS to styles.css for better
maintainability and LLM context usage."
```

---

### Task 1.3: Extract Inline JavaScript to External File

**Files:**
- Read: `employers/cybercoders/website/index.html`
- Create: `employers/cybercoders/website/script.js`
- Modify: `employers/cybercoders/website/index.html` (remove inline scripts)

**Step 1: Read current HTML file**

Read `employers/cybercoders/website/index.html` to locate the `<script>` tag with inline JavaScript (approximately lines 1118-1386).

**Step 2: Extract JavaScript from script tag**

Copy all content between `<script>` and `</script>` tags. This includes:
- Tooltip system (lines ~1009-1115)
- Carousel logic (lines ~1118-1287)
- FAQ accordion (lines ~1291-1386)

**Step 3: Create script.js**

Create `employers/cybercoders/website/script.js` with the extracted JavaScript content.

**Step 4: Update HTML to reference external JS**

In `employers/cybercoders/website/index.html`, replace the entire `<script>...</script>` block with:

```html
<script src="script.js"></script>
```

Place this just before the closing `</body>` tag.

**Step 5: Test in browser**

Open `employers/cybercoders/website/index.html` in a browser and test:
- Carousel navigation (arrows, dots, swipe)
- FAQ accordion (open/close)
- Job description tooltips (hover annotations)

Expected: All JavaScript functionality works identically.

**Step 6: Commit JavaScript extraction**

```bash
git add employers/cybercoders/website/script.js employers/cybercoders/website/index.html
git commit -m "refactor: extract inline JavaScript to external file

Move ~300 lines of inline JS (carousel, FAQ, tooltips) to
script.js for better development experience."
```

---

## Phase 2: SVG Sprite Sheet Creation

### Task 2.1: Create SVG Sprite Sheet

**Files:**
- Read: `tmp/fontawesome-free-7.1.0-web/svgs/brands/github.svg`
- Read: `tmp/fontawesome-free-7.1.0-web/svgs/brands/linkedin.svg`
- Read: `tmp/fontawesome-free-7.1.0-web/svgs/solid/calendar.svg`
- Read: `tmp/fontawesome-free-7.1.0-web/svgs/solid/arrow-up-right-from-square.svg`
- Read: `tmp/fontawesome-free-7.1.0-web/svgs/solid/download.svg`
- Read: `tmp/fontawesome-free-7.1.0-web/svgs/solid/book-open.svg`
- Create: `employers/cybercoders/website/icons.svg`

**Step 1: Read FontAwesome SVG files**

Read the 6 icon SVG files listed above to extract their path data and viewBox attributes.

**Step 2: Create sprite sheet structure**

Create `employers/cybercoders/website/icons.svg` with the following structure:

```xml
<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
  <defs>
    <!-- Icons will be defined as symbols here -->
  </defs>
</svg>
```

**Step 3: Add GitHub icon symbol**

Inside `<defs>`, add the GitHub icon:

```xml
<symbol id="icon-github" viewBox="0 0 496 512">
  <!-- Paste path data from github.svg -->
</symbol>
```

**Step 4: Add remaining icon symbols**

Add symbols for:
- `icon-linkedin` (from linkedin.svg)
- `icon-calendar` (from calendar.svg)
- `icon-external-link` (from arrow-up-right-from-square.svg)
- `icon-download` (from download.svg)
- `icon-book` (from book-open.svg)

**Step 5: Verify SVG structure**

Ensure the file is valid XML with all symbols properly nested inside `<defs>`.

**Step 6: Commit sprite sheet**

```bash
git add employers/cybercoders/website/icons.svg
git commit -m "feat: add SVG sprite sheet with 6 icons

Create sprite sheet from FontAwesome free icons:
- GitHub, LinkedIn (brands)
- Calendar, external link, download, book (solid)

Replaces FontAwesome CDN dependency."
```

---

### Task 2.2: Add Icon CSS Utilities

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Add icon base styles**

At the end of `styles.css`, add:

```css
/* Icon Utilities */
.icon {
  width: 1.25rem;
  height: 1.25rem;
  display: inline-block;
  vertical-align: middle;
  fill: currentColor;
}

.icon-sm {
  width: 1rem;
  height: 1rem;
}

.icon-lg {
  width: 1.5rem;
  height: 1.5rem;
}
```

**Step 2: Test icon rendering**

Temporarily add a test icon to `index.html`:

```html
<svg class="icon"><use href="icons.svg#icon-github"></use></svg>
```

Open in browser and verify icon renders correctly.

**Step 3: Remove test icon**

Remove the temporary test icon from HTML.

**Step 4: Commit icon CSS**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: add icon utility classes

Add base .icon class with size variants for SVG sprite usage."
```

---

## Phase 3: Open Props Integration

### Task 3.1: Add Open Props CDN Link

**Files:**
- Modify: `employers/cybercoders/website/index.html`

**Step 1: Add Open Props stylesheet link**

In the `<head>` section of `index.html`, add this line before the `styles.css` link:

```html
<link rel="stylesheet" href="https://unpkg.com/open-props">
<link rel="stylesheet" href="https://unpkg.com/open-props/normalize.min.css">
```

**Step 2: Test page loads**

Open `index.html` in browser.
Expected: Page loads with Open Props imported (may see some style changes from normalize.css).

**Step 3: Commit Open Props integration**

```bash
git add employers/cybercoders/website/index.html
git commit -m "feat: integrate Open Props design system

Add Open Props CDN links for design tokens and normalize CSS."
```

---

### Task 3.2: Migrate Global Styles to Open Props

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update root custom properties**

Replace the existing `:root` variables section with:

```css
:root {
  /* Keep only custom properties not provided by Open Props */
  --content-max-width: 800px;

  /* Semantic color mapping using Open Props */
  --primary-color: var(--blue-6);
  --primary-hover: var(--blue-7);
  --text-color: var(--gray-9);
  --text-light: var(--gray-7);
  --background: var(--gray-0);
  --background-alt: var(--gray-1);
  --border-color: var(--gray-3);
  --header-background: var(--gray-9);
}
```

**Step 2: Update body styles**

Update body element styles:

```css
body {
  font-family: var(--font-sans);
  line-height: var(--font-lineheight-3);
  color: var(--text-color);
  background: var(--background);
  margin: 0;
  padding: var(--size-6) var(--size-4);
  max-width: var(--content-max-width);
  margin: 0 auto;
}
```

**Step 3: Update heading styles**

```css
h1, h2, h3 {
  font-weight: var(--font-weight-7);
  line-height: var(--font-lineheight-2);
  color: var(--text-color);
}

h1 {
  font-size: var(--font-size-7);
  margin-bottom: var(--size-5);
}

h2 {
  font-size: var(--font-size-5);
  margin-bottom: var(--size-4);
  margin-top: var(--size-8);
}

h3 {
  font-size: var(--font-size-3);
  margin-bottom: var(--size-3);
}
```

**Step 4: Update link styles**

```css
a {
  color: var(--primary-color);
  text-decoration: none;
  transition: color var(--ease-3) var(--duration-2);
}

a:hover {
  color: var(--primary-hover);
  text-decoration: underline;
}
```

**Step 5: Test in browser**

Open page and verify:
- Typography looks similar to before
- Colors are consistent
- Spacing feels right

Expected: Page should look very similar, possibly slightly improved.

**Step 6: Commit global styles migration**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "refactor: migrate global styles to Open Props

Update body, headings, and links to use Open Props tokens
for typography, spacing, and colors."
```

---

### Task 3.3: Migrate Header Styles to Open Props

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update header container styles**

Find the `.header` or `header` class and update:

```css
.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: var(--header-background);
  box-shadow: var(--shadow-2);
  z-index: 1000;
  padding: var(--size-4) var(--size-6);
}

.header-content {
  max-width: var(--content-max-width);
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--size-6);
}
```

**Step 2: Update header navigation styles**

```css
.header nav {
  display: flex;
  gap: var(--size-6);
  align-items: center;
}

.header nav a {
  color: var(--gray-0);
  font-size: var(--font-size-1);
  opacity: 0.9;
  transition: opacity var(--ease-3) var(--duration-2);
}

.header nav a:hover {
  opacity: 1;
  text-decoration: none;
}
```

**Step 3: Update CTA button in header**

```css
.header-cta {
  padding: var(--size-2) var(--size-4);
  background: var(--primary-color);
  color: var(--gray-0);
  border-radius: var(--radius-2);
  font-weight: var(--font-weight-6);
  transition: all var(--ease-3) var(--duration-2);
}

.header-cta:hover {
  background: var(--primary-hover);
  box-shadow: var(--shadow-3);
  text-decoration: none;
}
```

**Step 4: Test header in browser**

Open page and verify:
- Fixed header looks good
- Navigation links work
- CTA button has proper styling and hover

**Step 5: Commit header migration**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "refactor: migrate header styles to Open Props

Update fixed header, navigation, and CTA button with
Open Props spacing, colors, and shadows."
```

---

### Task 3.4: Migrate Section Styles to Open Props

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update section container styles**

Find section-related styles and update:

```css
.section {
  padding: var(--size-8) 0;
  border-bottom: var(--border-size-1) solid var(--border-color);
}

.section:last-child {
  border-bottom: none;
}

.section-alt {
  background: var(--background-alt);
  padding: var(--size-8) var(--size-6);
  margin-left: calc(var(--size-6) * -1);
  margin-right: calc(var(--size-6) * -1);
  border-radius: var(--radius-3);
}
```

**Step 2: Update masthead styles**

```css
.masthead {
  text-align: center;
  padding: var(--size-10) 0 var(--size-8);
  margin-top: var(--size-10); /* Account for fixed header */
}

.masthead h1 {
  font-size: var(--font-size-8);
  margin-bottom: var(--size-3);
  font-weight: var(--font-weight-8);
}

.masthead .profile-image {
  width: var(--size-14);
  height: var(--size-14);
  border-radius: var(--radius-round);
  margin-bottom: var(--size-5);
  box-shadow: var(--shadow-3);
}
```

**Step 3: Update branding statement styles**

```css
.branding-statement {
  font-size: var(--font-size-3);
  line-height: var(--font-lineheight-4);
  color: var(--text-light);
  margin-bottom: var(--size-8);
}

.branding-statement p {
  margin-bottom: var(--size-4);
}
```

**Step 4: Test sections in browser**

Open page and verify all sections have proper spacing and styling.

**Step 5: Commit section migration**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "refactor: migrate section styles to Open Props

Update section containers, masthead, and branding statement
with Open Props spacing and typography tokens."
```

---

## Phase 4: Carousel Fix & Redesign

### Task 4.1: Fix Carousel Width Constraints

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update carousel container styles**

Find `.carousel-container` or `.recommendations` section and update:

```css
.carousel-container {
  position: relative;
  overflow: hidden;
  width: 100%;
  max-width: 100%;
}
```

**Step 2: Update carousel track styles**

```css
.carousel-track {
  display: flex;
  transition: transform var(--ease-3) var(--duration-3);
  width: 100%;
}
```

**Step 3: Fix carousel slide width constraints (CRITICAL)**

```css
.carousel-slide {
  min-width: 100%;  /* Force full width */
  max-width: 100%;  /* Constrain maximum */
  flex-shrink: 0;   /* Prevent flex compression */
  box-sizing: border-box;
}
```

**Step 4: Fix recommendation card text wrapping**

```css
.recommendation-card {
  max-width: 100%;
  width: 100%;
  box-sizing: border-box;
  overflow-wrap: break-word;
  word-wrap: break-word;
  hyphens: auto;
}
```

**Step 5: Test carousel with long quotes**

Open page in browser and test:
1. Navigate through all recommendations
2. Verify each quote is fully readable
3. Check no horizontal overflow
4. Test arrow keys, dots, swipe

Expected: All recommendations accessible, no overflow.

**Step 6: Commit carousel width fix**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "fix: carousel overflow bug with width constraints

Add min-width: 100% and flex-shrink: 0 to carousel slides
to prevent quotes from overflowing horizontally.

Fixes issue where only ~1.2 recommendations were reachable."
```

---

### Task 4.2: Redesign Recommendation Cards with Open Props

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update recommendation card container**

```css
.recommendation-card {
  background: var(--gray-0);
  border: var(--border-size-1) solid var(--gray-3);
  border-radius: var(--radius-3);
  padding: var(--size-6);
  box-shadow: var(--shadow-2);
  transition: box-shadow var(--ease-3) var(--duration-2);
  max-width: 100%;
  width: 100%;
  box-sizing: border-box;
  overflow-wrap: break-word;
  word-wrap: break-word;
  hyphens: auto;
}

.recommendation-card:hover {
  box-shadow: var(--shadow-4);
}
```

**Step 2: Update quote text styles**

```css
.recommendation-quote {
  font-size: var(--font-size-3);
  line-height: var(--font-lineheight-4);
  color: var(--gray-8);
  margin-bottom: var(--size-5);
}
```

**Step 3: Update attribution styles**

```css
.recommendation-attribution {
  font-size: var(--font-size-1);
  color: var(--gray-7);
  font-style: italic;
  display: block;
  margin-top: var(--size-4);
}

.recommendation-name {
  font-weight: var(--font-weight-7);
  color: var(--gray-9);
  font-style: normal;
}
```

**Step 4: Remove decorative quotation mark pseudo-element**

Find and remove or comment out any `.recommendation-card::before` or similar pseudo-element with quotation mark content.

**Step 5: Update carousel arrows**

```css
.carousel-arrow {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: var(--size-9);
  height: var(--size-9);
  border-radius: var(--radius-round);
  background: var(--gray-0);
  border: var(--border-size-2) solid var(--gray-4);
  color: var(--gray-7);
  font-size: var(--font-size-5);
  cursor: pointer;
  transition: all var(--ease-3) var(--duration-2);
  z-index: 10;
  touch-action: manipulation;
}

.carousel-arrow:hover {
  background: var(--primary-color);
  color: var(--gray-0);
  border-color: var(--primary-color);
  box-shadow: var(--shadow-3);
}

.carousel-arrow.prev {
  left: var(--size-3);
}

.carousel-arrow.next {
  right: var(--size-3);
}
```

**Step 6: Update carousel dots**

```css
.carousel-dots {
  display: flex;
  justify-content: center;
  gap: var(--size-2);
  margin-top: var(--size-5);
}

.carousel-dot {
  width: var(--size-2);
  height: var(--size-2);
  border-radius: var(--radius-round);
  background: var(--gray-4);
  border: none;
  cursor: pointer;
  transition: all var(--ease-3) var(--duration-2);
  padding: 0;
}

.carousel-dot.active {
  background: var(--primary-color);
  width: var(--size-5);
}

.carousel-dot:hover {
  background: var(--gray-6);
}

.carousel-dot.active:hover {
  background: var(--primary-hover);
}
```

**Step 7: Test carousel redesign**

Open page and verify:
- Cards have clean, modern look
- Hover states work
- Arrows and dots styled properly
- All functionality still works

**Step 8: Commit carousel redesign**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "refactor: redesign recommendation carousel with Open Props

Update cards, arrows, and dots with modern styling:
- Clean card design with subtle shadows
- Improved typography hierarchy
- Better hover states
- Open Props tokens throughout"
```

---

## Phase 5: Project Cards Redesign

### Task 5.1: Update Project Card HTML Structure

**Files:**
- Modify: `employers/cybercoders/website/index.html`

**Step 1: Read current projects section**

Find the projects section in `index.html` (around line 961-990).

**Step 2: Update project card structure**

Replace the existing project card HTML with the new structure. For each project, use:

```html
<div class="project-card">
  <div class="project-header">
    <img src="<%= project[:image_url] %>" alt="" class="project-icon">
    <h3 class="project-title"><%= project[:name] %></h3>
  </div>

  <p class="project-headline"><%= project[:description] %></p>

  <div class="project-tech">
    <!-- Add tech tags if available in project data -->
    <span class="tech-tag">JavaScript</span>
    <span class="tech-tag">HTML</span>
    <span class="tech-tag">CSS</span>
  </div>

  <div class="project-actions">
    <% if project[:blog_post_url] %>
    <a href="<%= project[:blog_post_url] %>" class="btn btn-primary">
      <svg class="icon"><use href="icons.svg#icon-book"></use></svg>
      Technical Deep Dive
    </a>
    <% end %>
    <% if project[:live_url] %>
    <a href="<%= project[:live_url] %>" class="btn btn-secondary">
      <svg class="icon"><use href="icons.svg#icon-external-link"></use></svg>
      Live Demo
    </a>
    <% end %>
    <% if project[:github_url] %>
    <a href="<%= project[:github_url] %>" class="btn btn-tertiary">
      <svg class="icon"><use href="icons.svg#icon-github"></use></svg>
      Source Code
    </a>
    <% end %>
  </div>

  <div class="project-footer">
    <span class="project-date"><%= project[:year] %></span>
    <span class="project-context"><%= project[:context] %></span>
  </div>
</div>
```

**Step 3: Note for later**

Since we're working with generated HTML (not ERB), manually replace ERB tags with actual values from the current HTML. Document the ERB structure for later migration.

**Step 4: Add SVG sprite reference if not present**

Ensure `icons.svg` is loaded at the top of the `<body>`:

```html
<body>
  <object data="icons.svg" type="image/svg+xml" style="display: none;"></object>
  <!-- or -->
  <!-- Include contents of icons.svg inline here -->
```

**Step 5: Test HTML structure**

Open page in browser. Cards may look broken (we'll fix with CSS next).

**Step 6: Commit HTML structure update**

```bash
git add employers/cybercoders/website/index.html
git commit -m "refactor: update project card HTML structure

Add new card layout with:
- Header (icon + title)
- Headline and description
- Technology tags
- Action buttons with SVG icons
- Footer metadata"
```

---

### Task 5.2: Style Project Cards with Open Props

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update project list container**

```css
.projects {
  padding: var(--size-8) 0;
}

.project-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 350px), 1fr));
  gap: var(--size-6);
}
```

**Step 2: Style project card container**

```css
.project-card {
  background: var(--gray-0);
  border: var(--border-size-1) solid var(--gray-3);
  border-radius: var(--radius-3);
  padding: var(--size-6);
  box-shadow: var(--shadow-2);
  transition: box-shadow var(--ease-3) var(--duration-2);
  display: flex;
  flex-direction: column;
  gap: var(--size-4);
}

.project-card:hover {
  box-shadow: var(--shadow-4);
}
```

**Step 3: Style project header**

```css
.project-header {
  display: flex;
  align-items: center;
  gap: var(--size-3);
}

.project-icon {
  width: var(--size-8);
  height: var(--size-8);
  border-radius: var(--radius-2);
  object-fit: cover;
}

.project-title {
  font-size: var(--font-size-5);
  font-weight: var(--font-weight-7);
  color: var(--gray-9);
  margin: 0;
}
```

**Step 4: Style project content**

```css
.project-headline {
  font-size: var(--font-size-3);
  font-weight: var(--font-weight-6);
  color: var(--gray-8);
  margin: 0;
  line-height: var(--font-lineheight-3);
}

.project-description {
  font-size: var(--font-size-2);
  line-height: var(--font-lineheight-3);
  color: var(--gray-7);
  margin: 0;
}
```

**Step 5: Style technology tags**

```css
.project-tech {
  display: flex;
  flex-wrap: wrap;
  gap: var(--size-2);
}

.tech-tag {
  padding: var(--size-1) var(--size-3);
  background: var(--gray-2);
  color: var(--gray-7);
  border-radius: var(--radius-2);
  font-size: var(--font-size-0);
  font-weight: var(--font-weight-6);
}
```

**Step 6: Commit project card styles**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: add project card base styles

Add grid layout, card container, header, content, and
tech tag styling using Open Props tokens."
```

---

### Task 5.3: Style Project Action Buttons

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Style action button container**

```css
.project-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--size-3);
  margin-top: auto; /* Push to bottom of card */
}
```

**Step 2: Add base button styles**

```css
.btn {
  display: inline-flex;
  align-items: center;
  gap: var(--size-2);
  padding: var(--size-2) var(--size-4);
  border-radius: var(--radius-2);
  font-size: var(--font-size-1);
  font-weight: var(--font-weight-6);
  text-decoration: none;
  border: none;
  cursor: pointer;
  transition: all var(--ease-3) var(--duration-2);
}

.btn .icon {
  width: var(--size-4);
  height: var(--size-4);
}
```

**Step 3: Add primary button variant (blue)**

```css
.btn-primary {
  background: var(--blue-6);
  color: var(--gray-0);
}

.btn-primary:hover {
  background: var(--blue-7);
  box-shadow: var(--shadow-3);
  text-decoration: none;
}
```

**Step 4: Add secondary button variant (orange)**

```css
.btn-secondary {
  background: var(--orange-5);
  color: var(--gray-0);
}

.btn-secondary:hover {
  background: var(--orange-6);
  box-shadow: var(--shadow-3);
  text-decoration: none;
}
```

**Step 5: Add tertiary button variant (outline)**

```css
.btn-tertiary {
  background: var(--gray-0);
  color: var(--gray-8);
  border: var(--border-size-2) solid var(--gray-4);
}

.btn-tertiary:hover {
  background: var(--gray-1);
  border-color: var(--gray-5);
  box-shadow: var(--shadow-2);
  text-decoration: none;
}
```

**Step 6: Test button styles**

Open page and verify:
- Three button styles are distinct
- Icons appear correctly
- Hover states work
- Buttons have good visual hierarchy

**Step 7: Commit button styles**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: add project action button styles

Add three button variants (primary, secondary, tertiary)
with icons, hover states, and Open Props tokens."
```

---

### Task 5.4: Style Project Footer

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Add project footer styles**

```css
.project-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: var(--font-size-0);
  color: var(--gray-6);
  padding-top: var(--size-3);
  border-top: var(--border-size-1) solid var(--gray-2);
  margin-top: var(--size-2);
}

.project-date {
  display: flex;
  align-items: center;
  gap: var(--size-2);
}

.project-context {
  font-style: italic;
}
```

**Step 2: Test complete project card**

Open page and verify entire project card design:
- Header with icon and title
- Headline and description
- Tech tags
- Action buttons
- Footer metadata
- Card hover state

Expected: Modern, professional card design matching the Stormoji aesthetic.

**Step 3: Commit footer styles**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: add project footer styles

Add footer with date and context metadata, separated
by border with subtle styling."
```

---

## Phase 6: Remaining Sections Migration

### Task 6.1: Migrate Job Description Annotation Styles

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update job description container**

```css
.job-description-comparison {
  padding: var(--size-8) 0;
}

.job-description-content {
  background: var(--gray-0);
  border: var(--border-size-1) solid var(--gray-3);
  border-radius: var(--radius-3);
  padding: var(--size-6);
  line-height: var(--font-lineheight-4);
}
```

**Step 2: Update annotation highlight styles**

```css
.annotated {
  cursor: help;
  border-radius: var(--radius-1);
  transition: background-color var(--ease-3) var(--duration-1);
  position: relative;
}

.annotated[data-tier="strong"] {
  background: color-mix(in srgb, var(--blue-6) 25%, transparent);
}

.annotated[data-tier="moderate"] {
  background: color-mix(in srgb, var(--blue-6) 15%, transparent);
}

.annotated[data-tier="mention"] {
  background: color-mix(in srgb, var(--blue-6) 8%, transparent);
}

.annotated:hover {
  background: color-mix(in srgb, var(--blue-6) 35%, transparent);
}
```

**Step 3: Update tooltip styles**

```css
.annotation-tooltip {
  position: absolute;
  max-width: 300px;
  background: var(--gray-0);
  border: var(--border-size-1) solid var(--gray-4);
  border-radius: var(--radius-2);
  padding: var(--size-3);
  box-shadow: var(--shadow-4);
  z-index: 1000;
  font-size: var(--font-size-1);
  line-height: var(--font-lineheight-3);
  color: var(--gray-8);
  opacity: 0;
  transition: opacity var(--ease-3) var(--duration-2);
  pointer-events: none;
}

.annotation-tooltip.show {
  opacity: 1;
}

.annotation-tooltip::before {
  content: '';
  position: absolute;
  width: var(--size-2);
  height: var(--size-2);
  background: var(--gray-0);
  border: var(--border-size-1) solid var(--gray-4);
  transform: rotate(45deg);
}

.annotation-tooltip[data-position="above"]::before {
  bottom: calc(var(--size-1) * -1);
  border-top: none;
  border-left: none;
}

.annotation-tooltip[data-position="below"]::before {
  top: calc(var(--size-1) * -1);
  border-bottom: none;
  border-right: none;
}
```

**Step 4: Update legend styles**

```css
.annotation-legend {
  display: flex;
  flex-wrap: wrap;
  gap: var(--size-4);
  margin-top: var(--size-4);
  font-size: var(--font-size-1);
  color: var(--gray-7);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: var(--size-2);
}

.legend-item .sample {
  display: inline-block;
  width: var(--size-5);
  height: var(--size-3);
  border-radius: var(--radius-1);
}

.legend-item .sample.strong {
  background: color-mix(in srgb, var(--blue-6) 25%, transparent);
}

.legend-item .sample.moderate {
  background: color-mix(in srgb, var(--blue-6) 15%, transparent);
}

.legend-item .sample.mention {
  background: color-mix(in srgb, var(--blue-6) 8%, transparent);
}
```

**Step 5: Test annotations**

Open page and test:
- Hover over annotated spans
- Tooltip appears and positions correctly
- Legend displays properly
- All tiers have distinct colors

**Step 6: Commit annotation styles**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "refactor: migrate job annotation styles to Open Props

Update highlights, tooltips, and legend with Open Props
tokens for consistent colors and spacing."
```

---

### Task 6.2: Migrate FAQ Accordion Styles

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update FAQ container**

```css
.faq {
  padding: var(--size-8) 0;
}

.faq-accordion {
  display: flex;
  flex-direction: column;
  gap: var(--size-3);
}
```

**Step 2: Update FAQ item styles**

```css
.faq-item {
  background: var(--gray-0);
  border: var(--border-size-1) solid var(--gray-3);
  border-radius: var(--radius-2);
  overflow: hidden;
}

.faq-item.active {
  border-left: var(--border-size-3) solid var(--primary-color);
}
```

**Step 3: Update FAQ question button**

```css
.faq-question {
  width: 100%;
  padding: var(--size-4);
  padding-right: var(--size-10);
  background: transparent;
  border: none;
  text-align: left;
  font-size: var(--font-size-2);
  font-weight: var(--font-weight-6);
  color: var(--gray-9);
  cursor: pointer;
  position: relative;
  transition: background var(--ease-3) var(--duration-2);
}

.faq-question:hover {
  background: color-mix(in srgb, var(--gray-9) 2%, transparent);
}

.faq-chevron {
  position: absolute;
  right: var(--size-4);
  top: 50%;
  transform: translateY(-50%);
  font-size: var(--font-size-4);
  color: var(--gray-6);
  transition: transform var(--ease-3) var(--duration-2);
}

.faq-item.active .faq-chevron {
  transform: translateY(-50%) rotate(90deg);
}
```

**Step 4: Update FAQ answer styles**

```css
.faq-answer {
  max-height: 0;
  overflow: hidden;
  transition: max-height var(--ease-3) var(--duration-3);
}

.faq-answer.open {
  max-height: 1000px; /* Large enough for content */
}

.faq-answer p {
  padding: 0 var(--size-4) var(--size-4);
  margin: 0;
  font-size: var(--font-size-2);
  line-height: var(--font-lineheight-4);
  color: var(--gray-7);
}
```

**Step 5: Test FAQ accordion**

Open page and test:
- Click questions to open/close
- Smooth animation
- Chevron rotates
- Active state border appears
- Keyboard navigation works

**Step 6: Commit FAQ styles**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "refactor: migrate FAQ accordion styles to Open Props

Update question buttons, answers, and animations with
Open Props spacing, colors, and transitions."
```

---

### Task 6.3: Migrate Footer Styles

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Update footer container**

```css
.footer {
  padding: var(--size-8) 0 var(--size-6);
  margin-top: var(--size-10);
  border-top: var(--border-size-1) solid var(--border-color);
  text-align: center;
}
```

**Step 2: Update footer links**

```css
.footer-links {
  display: flex;
  justify-content: center;
  gap: var(--size-6);
  flex-wrap: wrap;
}

.footer-links a {
  display: inline-flex;
  align-items: center;
  gap: var(--size-2);
  font-size: var(--font-size-2);
  color: var(--gray-7);
  transition: color var(--ease-3) var(--duration-2);
}

.footer-links a:hover {
  color: var(--primary-color);
}

.footer-links .icon {
  width: var(--size-4);
  height: var(--size-4);
}
```

**Step 3: Add icons to footer links**

In `index.html`, update footer links to include icons:

```html
<a href="resume.pdf">
  <svg class="icon"><use href="icons.svg#icon-download"></use></svg>
  Download Resume
</a>
<a href="cover-letter.pdf">
  <svg class="icon"><use href="icons.svg#icon-download"></use></svg>
  Download Cover Letter
</a>
```

**Step 4: Test footer**

Open page and verify footer styling and icon display.

**Step 5: Commit footer styles**

```bash
git add employers/cybercoders/website/styles.css employers/cybercoders/website/index.html
git commit -m "refactor: migrate footer styles to Open Props

Add icons to footer links and update styling with
Open Props tokens."
```

---

## Phase 7: Responsive Design Polish

### Task 7.1: Add Mobile Breakpoints for Header

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Add mobile header styles**

At the end of styles.css, add:

```css
/* Responsive Styles */

@media (max-width: 768px) {
  .header {
    padding: var(--size-3) var(--size-4);
  }

  .header-content {
    flex-wrap: wrap;
    gap: var(--size-3);
  }

  .header nav {
    flex-direction: column;
    gap: var(--size-2);
    width: 100%;
  }
}
```

**Step 2: Test on mobile viewport**

Resize browser to 375px width and verify header adapts properly.

**Step 3: Commit mobile header**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: add mobile responsive header styles

Header, navigation, and CTA adapt for small screens."
```

---

### Task 7.2: Add Mobile Breakpoints for Typography

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Add mobile typography adjustments**

```css
@media (max-width: 768px) {
  body {
    padding: var(--size-4) var(--size-3);
  }

  .masthead {
    padding: var(--size-8) 0 var(--size-6);
  }

  .masthead h1 {
    font-size: var(--font-size-6);
  }

  h2 {
    font-size: var(--font-size-4);
  }

  h3 {
    font-size: var(--font-size-2);
  }
}
```

**Step 2: Test typography on mobile**

Verify headings scale appropriately on small screens.

**Step 3: Commit mobile typography**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: add mobile typography scaling

Headings and spacing adjust for readability on small screens."
```

---

### Task 7.3: Add Mobile Breakpoints for Carousel

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Add mobile carousel adjustments**

```css
@media (max-width: 480px) {
  .carousel-arrow {
    display: none; /* Hide arrows on very small screens */
  }

  .recommendation-card {
    padding: var(--size-5);
  }

  .recommendation-quote {
    font-size: var(--font-size-2);
  }
}
```

**Step 2: Test carousel on mobile**

Verify:
- Arrows hidden on small screens
- Swipe still works
- Dots visible and functional
- Card padding appropriate

**Step 3: Commit mobile carousel**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: optimize carousel for mobile

Hide arrows on small screens, adjust padding and typography."
```

---

### Task 7.4: Add Mobile Breakpoints for Project Cards

**Files:**
- Modify: `employers/cybercoders/website/styles.css`

**Step 1: Add mobile project card adjustments**

```css
@media (max-width: 768px) {
  .project-list {
    gap: var(--size-5);
  }

  .project-card {
    padding: var(--size-5);
    gap: var(--size-3);
  }
}

@media (max-width: 480px) {
  .project-actions {
    flex-direction: column;
  }

  .btn {
    width: 100%;
    justify-content: center;
  }

  .project-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--size-2);
  }
}
```

**Step 2: Test project cards on mobile**

Verify:
- Cards stack properly in grid
- Buttons stack vertically on narrow screens
- Footer metadata stacks on very small screens
- All content readable

**Step 3: Commit mobile project cards**

```bash
git add employers/cybercoders/website/styles.css
git commit -m "style: optimize project cards for mobile

Stack buttons vertically and adjust spacing for small screens."
```

---

## Phase 8: Performance & Accessibility

### Task 8.1: Add Image Lazy Loading

**Files:**
- Modify: `employers/cybercoders/website/index.html`

**Step 1: Add loading="lazy" to project images**

Find all `<img>` tags in project cards and add the `loading="lazy"` attribute:

```html
<img src="images/project.png" alt="Project name" class="project-icon" loading="lazy">
```

**Step 2: Add loading="lazy" to other images**

Add to profile image, branding image, etc.

**Step 3: Test lazy loading**

Open browser dev tools Network tab and verify images load as you scroll.

**Step 4: Commit lazy loading**

```bash
git add employers/cybercoders/website/index.html
git commit -m "perf: add lazy loading to images

Defer off-screen image loading for better initial page load."
```

---

### Task 8.2: Add Reduced Motion Support

**Files:**
- Modify: `employers/cybercoders/website/styles.css`
- Modify: `employers/cybercoders/website/script.js`

**Step 1: Add reduced motion CSS**

At the end of styles.css:

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }

  .carousel-track {
    transition: none;
  }

  .faq-answer {
    transition: none;
  }
}
```

**Step 2: Update carousel autoplay for reduced motion**

In `script.js`, find the carousel initialization and update:

```javascript
// Check for reduced motion preference
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

if (!prefersReducedMotion) {
  // Only auto-advance if user hasn't requested reduced motion
  autoAdvanceInterval = setInterval(nextSlide, 6000);
}
```

**Step 3: Test reduced motion**

Enable reduced motion in browser settings and verify:
- Transitions are instant
- Carousel doesn't auto-advance
- Interactions still work

**Step 4: Commit reduced motion support**

```bash
git add employers/cybercoders/website/styles.css employers/cybercoders/website/script.js
git commit -m "a11y: add reduced motion support

Respect prefers-reduced-motion preference for animations
and carousel auto-advance."
```

---

### Task 8.3: Verify ARIA Attributes

**Files:**
- Read: `employers/cybercoders/website/index.html`
- Read: `employers/cybercoders/website/script.js`

**Step 1: Check carousel ARIA**

Verify carousel has:
- `role="region"` on container
- `aria-label` on buttons
- `aria-live="polite"` for status updates

**Step 2: Check FAQ ARIA**

Verify accordion has:
- `aria-expanded` on questions
- `aria-controls` linking questions to answers
- Proper keyboard handling (Enter, Space, Escape)

**Step 3: Check annotation tooltips**

Verify annotated spans have appropriate attributes and keyboard support.

**Step 4: Test with keyboard**

Navigate entire page using only:
- Tab (focus next element)
- Shift+Tab (focus previous)
- Enter/Space (activate buttons)
- Arrow keys (carousel)
- Escape (close tooltips/accordion)

Expected: All interactive elements accessible via keyboard.

**Step 5: Document ARIA verification**

Add comment to this task noting ARIA is properly implemented (or fix any issues found).

**Step 6: Commit any ARIA fixes**

Only if changes were needed:

```bash
git add employers/cybercoders/website/index.html employers/cybercoders/website/script.js
git commit -m "a11y: fix ARIA attributes for [component]"
```

---

## Phase 9: Cross-Browser Testing

### Task 9.1: Browser Testing Checklist

**Files:**
- None (testing only)

**Step 1: Test in Chrome**

Open `employers/cybercoders/website/index.html` in Chrome and verify:
- [ ] All styles render correctly
- [ ] Carousel works (arrows, dots, swipe, keyboard)
- [ ] FAQ accordion opens/closes
- [ ] Tooltips appear on hover
- [ ] Project cards display properly
- [ ] All buttons and links work
- [ ] Mobile responsive (Chrome DevTools)

**Step 2: Test in Firefox**

Repeat all checks from Step 1 in Firefox.

**Step 3: Test in Safari**

Repeat all checks from Step 1 in Safari.

**Step 4: Test on actual mobile device**

If possible, test on real iPhone/Android:
- Touch interactions
- Swipe gestures
- Responsive layout
- Performance

**Step 5: Document results**

Note any browser-specific issues in this task or create separate tasks to fix them.

**Step 6: No commit (unless fixes needed)**

---

## Phase 10: ERB Template Migration

### Task 10.1: Document HTML Changes for ERB

**Files:**
- Create: `docs/plans/2026-01-08-landing-page-html-changes.md`

**Step 1: Compare old and new HTML structure**

Open both:
- `employers/cybercoders/website/index.html.backup`
- `employers/cybercoders/website/index.html`

**Step 2: Document structural changes**

Create a document listing all HTML changes:
- New elements added
- Removed elements
- Changed class names
- New attributes (loading="lazy", etc.)
- Icon usage patterns

**Step 3: Document ERB considerations**

Note where ERB variables need to be preserved:
- `<%= project[:name] %>`
- `<% if condition %>`
- Loops and conditionals

**Step 4: Commit documentation**

```bash
git add docs/plans/2026-01-08-landing-page-html-changes.md
git commit -m "docs: document HTML changes for ERB migration

List all structural changes, new classes, and ERB patterns
to preserve when updating template."
```

---

### Task 10.2: Update ERB Template Structure

**Files:**
- Read: `employers/cybercoders/website/index.html` (reference)
- Modify: `templates/website/default.html.erb`

**Step 1: Backup ERB template**

```bash
cp templates/website/default.html.erb templates/website/default.html.erb.backup
```

**Step 2: Update head section**

Add Open Props CDN links and change inline styles to external:

```erb
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= title %></title>
  <link rel="stylesheet" href="https://unpkg.com/open-props">
  <link rel="stylesheet" href="https://unpkg.com/open-props/normalize.min.css">
  <link rel="stylesheet" href="styles.css">
</head>
```

**Step 3: Update project card HTML in ERB**

Replace existing project card structure with new design, preserving ERB variables:

```erb
<% projects.each do |project| %>
<div class="project-card">
  <div class="project-header">
    <img src="<%= project[:image_url] %>" alt="" class="project-icon" loading="lazy">
    <h3 class="project-title"><%= project[:name] %></h3>
  </div>

  <p class="project-headline"><%= project[:description] %></p>

  <% if project[:technologies] %>
  <div class="project-tech">
    <% project[:technologies].each do |tech| %>
    <span class="tech-tag"><%= tech %></span>
    <% end %>
  </div>
  <% end %>

  <div class="project-actions">
    <% if project[:blog_post_url] %>
    <a href="<%= project[:blog_post_url] %>" class="btn btn-primary">
      <svg class="icon"><use href="icons.svg#icon-book"></use></svg>
      Technical Deep Dive
    </a>
    <% end %>
    <% if project[:live_url] %>
    <a href="<%= project[:live_url] %>" class="btn btn-secondary">
      <svg class="icon"><use href="icons.svg#icon-external-link"></use></svg>
      Live Demo
    </a>
    <% end %>
    <% if project[:github_url] %>
    <a href="<%= project[:github_url] %>" class="btn btn-tertiary">
      <svg class="icon"><use href="icons.svg#icon-github"></use></svg>
      Source Code
    </a>
    <% end %>
  </div>

  <div class="project-footer">
    <span class="project-date"><%= project[:year] %></span>
    <% if project[:context] %>
    <span class="project-context"><%= project[:context] %></span>
    <% end %>
  </div>
</div>
<% end %>
```

**Step 4: Update footer links with icons**

```erb
<footer class="footer">
  <div class="footer-links">
    <a href="resume.pdf">
      <svg class="icon"><use href="icons.svg#icon-download"></use></svg>
      Download Resume
    </a>
    <a href="cover-letter.pdf">
      <svg class="icon"><use href="icons.svg#icon-download"></use></svg>
      Download Cover Letter
    </a>
  </div>
</footer>
```

**Step 5: Update script tag to external**

Replace inline `<script>` with:

```erb
<script src="script.js"></script>
```

**Step 6: Commit ERB structure update**

```bash
git add templates/website/default.html.erb
git commit -m "refactor: update ERB template structure

- Add Open Props CDN links
- External CSS/JS references
- New project card structure with icons
- Footer icons
- Preserve all ERB variables and logic"
```

---

### Task 10.3: Copy Assets to Template Directory

**Files:**
- Copy: `employers/cybercoders/website/styles.css` → `templates/website/styles.css`
- Copy: `employers/cybercoders/website/script.js` → `templates/website/script.js`
- Copy: `employers/cybercoders/website/icons.svg` → `templates/website/icons.svg`

**Step 1: Copy CSS file**

```bash
cp employers/cybercoders/website/styles.css templates/website/styles.css
```

**Step 2: Copy JavaScript file**

```bash
cp employers/cybercoders/website/script.js templates/website/script.js
```

**Step 3: Copy SVG sprite**

```bash
cp employers/cybercoders/website/icons.svg templates/website/icons.svg
```

**Step 4: Verify files copied**

```bash
ls -lh templates/website/
```

Expected: See styles.css, script.js, icons.svg, default.html.erb

**Step 5: Commit template assets**

```bash
git add templates/website/styles.css templates/website/script.js templates/website/icons.svg
git commit -m "feat: add CSS, JS, and SVG assets to template directory

Copy finalized styles, scripts, and icon sprite sheet
for use by WebsiteGenerator."
```

---

### Task 10.4: Update WebsiteGenerator to Copy Assets

**Files:**
- Read: `lib/jojo/generators/website_generator.rb`
- Modify: `lib/jojo/generators/website_generator.rb`

**Step 1: Read WebsiteGenerator**

Read the entire `lib/jojo/generators/website_generator.rb` file to understand the current implementation.

**Step 2: Find the save_website method**

Locate where the HTML is written to disk (likely near the end of the file).

**Step 3: Add method to copy template assets**

Add a new method:

```ruby
def copy_template_assets
  output_dir = File.dirname(output_file)
  template_dir = File.dirname(template_file)

  assets = ['styles.css', 'script.js', 'icons.svg']

  assets.each do |asset|
    source = File.join(template_dir, asset)
    dest = File.join(output_dir, asset)

    if File.exist?(source)
      FileUtils.cp(source, dest)
      logger.info "Copied #{asset} to #{output_dir}"
    else
      logger.warn "Asset not found: #{source}"
    end
  end
end
```

**Step 4: Call copy_template_assets in generate method**

Find the `generate` method and add the call after saving HTML:

```ruby
def generate
  # ... existing code ...
  save_website(html)
  copy_template_assets
  logger.info "Website generated successfully at #{output_file}"
end
```

**Step 5: Test generation**

Run the generator for an existing employer:

```bash
jojo generate employers/cybercoders
```

Expected: HTML, CSS, JS, and SVG files all copied to `employers/cybercoders/website/`

**Step 6: Verify generated output**

```bash
ls -lh employers/cybercoders/website/
```

Expected: index.html, styles.css, script.js, icons.svg

**Step 7: Open generated page in browser**

Verify it looks correct with all styles and functionality working.

**Step 8: Commit generator update**

```bash
git add lib/jojo/generators/website_generator.rb
git commit -m "feat: copy CSS, JS, and SVG assets during generation

Update WebsiteGenerator to copy styles.css, script.js, and
icons.svg from template directory to output directory."
```

---

### Task 10.5: Test Generation with Multiple Employers

**Files:**
- None (testing only)

**Step 1: Regenerate existing employer site**

```bash
jojo generate employers/cybercoders
```

**Step 2: Open in browser and test thoroughly**

Verify all sections, interactivity, and styling work correctly.

**Step 3: If multiple employer directories exist, test another**

```bash
jojo generate employers/other-company
```

**Step 4: Compare old vs new output**

Use browser to compare:
- `employers/cybercoders/website/index.html.backup` (old)
- `employers/cybercoders/website/index.html` (new)

Document any regressions or unexpected differences.

**Step 5: Fix any issues found**

Create new tasks if bugs are discovered.

**Step 6: No commit (testing only)**

---

## Phase 11: Final Polish & Documentation

### Task 11.1: Update Implementation Plan Status

**Files:**
- Modify: `docs/plans/2026-01-08-landing-page-improvements.md`

**Step 1: Mark implementation plan as completed**

At the top of this file, update the header:

```markdown
# Landing Page Improvements Implementation Plan

**Status:** ✅ COMPLETED

**Completed:** [Today's date]

**Goal:** Modernize Jojo landing pages with Open Props design system, fix carousel overflow bug, redesign project cards with modern aesthetic, and replace FontAwesome with SVG sprite sheet.
```

**Step 2: Commit status update**

```bash
git add docs/plans/2026-01-08-landing-page-improvements.md
git commit -m "docs: mark implementation plan as completed"
```

---

### Task 11.2: Create Summary Commit

**Files:**
- None (git only)

**Step 1: Review all commits**

```bash
git log --oneline --since="today"
```

Review the series of commits made during implementation.

**Step 2: Optionally create summary tag**

```bash
git tag -a landing-page-improvements-v1 -m "Landing page improvements: Open Props migration, carousel fix, project card redesign, SVG icons"
```

**Step 3: Push if using remote**

```bash
git push origin main --tags
```

---

### Task 11.3: Update Design Document with Results

**Files:**
- Modify: `docs/plans/2026-01-08-landing-page-improvements-design.md`

**Step 1: Add Implementation Results section**

At the end of the design document, add:

```markdown
## Implementation Results

**Status:** ✅ Completed on [date]

**Validation Results:**

- ✅ All carousel quotes are fully readable (no horizontal overflow)
- ✅ Project cards match target design aesthetic
- ✅ All Open Props tokens used consistently
- ✅ Icons render correctly in all contexts
- ✅ Mobile experience is smooth and responsive
- ✅ No visual regressions in existing sections
- ✅ Page loads quickly
- ✅ Accessibility features work (ARIA, keyboard nav)
- ✅ ERB template generates correct output

**Key Achievements:**

- Migrated from ~1,100 lines of inline CSS to organized external stylesheet
- Fixed critical carousel overflow bug
- Redesigned project cards with modern aesthetic
- Replaced FontAwesome with 6-icon SVG sprite sheet
- Achieved full Open Props integration
- Improved maintainability and reduced LLM context usage
- Maintained all existing functionality and accessibility features

**Files Changed:**

- `templates/website/default.html.erb` - Updated structure
- `templates/website/styles.css` - New stylesheet with Open Props
- `templates/website/script.js` - Extracted JavaScript
- `templates/website/icons.svg` - New SVG sprite sheet
- `lib/jojo/generators/website_generator.rb` - Asset copying
```

**Step 2: Commit design doc update**

```bash
git add docs/plans/2026-01-08-landing-page-improvements-design.md
git commit -m "docs: add implementation results to design document"
```

---

### Task 11.4: Clean Up Temporary Files

**Files:**
- Remove: `employers/cybercoders/website/index.html.backup`
- Remove: `templates/website/default.html.erb.backup`

**Step 1: Remove backup files**

```bash
git rm employers/cybercoders/website/index.html.backup
git rm templates/website/default.html.erb.backup
```

**Step 2: Commit cleanup**

```bash
git commit -m "chore: remove backup files after successful migration"
```

---

## Validation Checklist

After completing all tasks, verify:

- [ ] Carousel displays all recommendations without horizontal overflow
- [ ] Project cards have modern design with icons, tech tags, and action buttons
- [ ] All styles use Open Props tokens (no hard-coded values in CSS)
- [ ] SVG icons render correctly and inherit colors
- [ ] Page is responsive on mobile, tablet, and desktop
- [ ] All interactive components work (carousel, FAQ, tooltips)
- [ ] Keyboard navigation works throughout the page
- [ ] Page loads quickly (< 2s on 3G)
- [ ] WebsiteGenerator creates all necessary files
- [ ] Multiple employer sites can be generated successfully
- [ ] No visual regressions compared to original design
- [ ] All accessibility features preserved (ARIA, reduced motion, etc.)

---

## Success Criteria

**Primary Goals:**
1. ✅ Carousel bug fixed - all quotes accessible
2. ✅ Open Props fully integrated - consistent design system
3. ✅ Project cards redesigned - modern aesthetic
4. ✅ SVG sprite sheet created - no FontAwesome dependency

**Secondary Goals:**
1. ✅ Improved maintainability - external CSS/JS files
2. ✅ Reduced LLM context usage - organized file structure
3. ✅ Better performance - smaller assets, lazy loading
4. ✅ Preserved accessibility - ARIA, keyboard nav, reduced motion

**Quality Standards:**
1. ✅ All commits follow conventional commit format
2. ✅ Each task has focused, atomic commit
3. ✅ No regressions in existing functionality
4. ✅ Cross-browser compatibility maintained
5. ✅ Documentation updated

---

## Future Enhancements

Out of scope for this plan but could be considered:

- Dark mode support using Open Props dark theme
- Animation enhancements on scroll
- Performance optimization (critical CSS, code splitting)
- A/B testing framework
- Analytics integration
- Additional project card layouts
- Video testimonials section
- Skills visualization
- Timeline component
