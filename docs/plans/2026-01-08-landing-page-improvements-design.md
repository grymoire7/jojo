# Landing Page Improvements - Design Document

**Date:** 2026-01-08
**Status:** Design Phase
**Goal:** Modernize Jojo landing pages with Open Props, fix carousel bugs, redesign project cards, and implement SVG icon system

## Overview

This design document outlines improvements to the Jojo landing page generation system. The focus is on visual polish and maintainability while preserving existing functionality. We're migrating from inline styles to a modern design system (Open Props), fixing critical layout bugs, and creating a more professional aesthetic that maximizes candidates' chances of landing interviews.

## Design Priorities

1. **Visual Polish** - Professional, modern look to maximize interview chances
2. **Mobile Responsiveness** - Great experience on all devices
3. **Maintainability** - Clean, understandable code using Open Props consistently
4. **Performance** - Fast load times, optimized assets
5. **Accessibility** - Screen readers, keyboard navigation, WCAG compliance

## Current State

### Architecture
- **Template:** `templates/website/default.html.erb` (1,389 lines)
- **Output:** Single HTML file with inline CSS (~1,100 lines) and JavaScript (~300 lines)
- **Styling:** Custom CSS variables with system font stack
- **Icons:** FontAwesome via CDN
- **Sections:** Header, Masthead, Branding Statement, Annotated Job Description, Recommendations Carousel, FAQ Accordion, Projects, Footer

### Problems
1. **Carousel layout bug** - Quotes overflow horizontally, only ~1.2 recommendations reachable
2. **Maintainability** - 58KB single HTML file is hard to edit and uses excessive LLM context
3. **Inconsistent design system** - Custom CSS variables without systematic scale
4. **Project cards** - Generic styling doesn't match modern portfolio aesthetics
5. **Icon dependency** - FontAwesome adds 75-100KB and requires external CDN

## Proposed Solution

### 1. Architecture Changes

**Multi-File Structure**
```
employers/cybercoders/website/
├── index.html          # Clean HTML structure, no inline CSS/JS
├── styles.css          # All custom styles using Open Props
├── script.js           # Carousel, FAQ, tooltips
└── icons.svg           # SVG sprite sheet
```

**Benefits:**
- Better caching and reuse across multiple employer landing pages
- Easier maintenance and debugging
- Reduced LLM context usage
- Better development experience with proper syntax highlighting
- Separation of concerns

**Open Props via CDN:**
```html
<link rel="stylesheet" href="https://unpkg.com/open-props">
```
- ~8KB gzipped
- Comprehensive design system
- Well-documented
- Version pinning for stability

### 2. SVG Sprite Sheet System

**Icon Inventory:**
- GitHub (project source code)
- LinkedIn (professional profile)
- Calendar (dates/timeline)
- External link (live demos)
- Download (resume/cover letter)
- Book/blog (blog posts)

**Implementation:**

`icons.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
  <symbol id="icon-github" viewBox="0 0 496 512">
    <!-- FontAwesome path data -->
  </symbol>
  <symbol id="icon-linkedin" viewBox="0 0 448 512">
    <!-- FontAwesome path data -->
  </symbol>
  <!-- ... other icons ... -->
</svg>
```

**Usage Pattern:**
```html
<a href="https://github.com/user/repo">
  <svg class="icon"><use href="icons.svg#icon-github"></use></svg>
  Source Code
</a>
```

**Styling:**
```css
.icon {
  width: var(--size-4);
  height: var(--size-4);
  display: inline-block;
  vertical-align: middle;
  fill: currentColor;  /* Inherits text color */
}
```

**Benefits:**
- No external dependencies
- Icons inherit text color automatically
- Defined once, used many times
- Full styling control
- Zero network requests after initial page load

### 3. Recommendations Carousel Fix

**Root Cause:**
The `.carousel-slide` and `.recommendation-card` lack proper width constraints, allowing text content to determine width instead of the container controlling it.

**Fix:**
```css
.carousel-track {
  display: flex;
  transition: transform var(--ease-3) var(--duration-3);
}

.carousel-slide {
  min-width: 100%;      /* Critical: force full width */
  flex-shrink: 0;       /* Prevent flex compression */
}

.recommendation-card {
  max-width: 100%;      /* Constrain card width */
  overflow-wrap: break-word;
  word-wrap: break-word;
  hyphens: auto;
}
```

**Redesign with Open Props:**
```css
.recommendation-card {
  background: var(--gray-0);
  border: var(--border-size-1) solid var(--gray-3);
  border-radius: var(--radius-3);
  padding: var(--size-6);
  box-shadow: var(--shadow-2);
  transition: box-shadow var(--ease-3) var(--duration-2);
}

.recommendation-card:hover {
  box-shadow: var(--shadow-4);
}

.recommendation-quote {
  font-size: var(--font-size-3);
  line-height: var(--font-lineheight-3);
  color: var(--gray-8);
  margin-bottom: var(--size-4);
}

.recommendation-attribution {
  font-size: var(--font-size-1);
  color: var(--gray-7);
  font-style: italic;
}

.recommendation-name {
  font-weight: var(--font-weight-7);
  color: var(--gray-9);
}
```

**Visual Enhancements:**
- Remove decorative quotation mark pseudo-element (cleaner)
- Open Props shadows for subtle depth
- Hover state with enhanced shadow
- Better typography hierarchy

**Keep Existing JavaScript:**
- Auto-advance (6 seconds)
- Manual navigation (buttons, dots)
- Keyboard support (arrow keys)
- Touch/swipe support
- Accessibility features (ARIA, reduced-motion)

### 4. Project Cards Redesign

**Design Inspiration:**
Based on the Stormoji project card aesthetic with:
- Prominent project identity (icon/logo + title)
- Clear visual hierarchy
- Technology tags as subtle pills
- Distinct, colorful action buttons with icons
- Metadata footer
- Generous spacing

**HTML Structure:**
```html
<div class="project-card">
  <div class="project-header">
    <img src="images/project-logo.png" alt="" class="project-icon">
    <h3 class="project-title">Project Name</h3>
  </div>

  <p class="project-headline">Brief compelling headline</p>
  <p class="project-description">Longer description...</p>

  <div class="project-tech">
    <span class="tech-tag">JavaScript</span>
    <span class="tech-tag">HTML</span>
    <span class="tech-tag">CSS</span>
  </div>

  <div class="project-actions">
    <a href="#" class="btn btn-primary">
      <svg class="icon"><use href="icons.svg#icon-book"></use></svg>
      Technical Deep Dive
    </a>
    <a href="#" class="btn btn-secondary">
      <svg class="icon"><use href="icons.svg#icon-external"></use></svg>
      Live Demo
    </a>
    <a href="#" class="btn btn-tertiary">
      <svg class="icon"><use href="icons.svg#icon-github"></use></svg>
      Source Code
    </a>
  </div>

  <div class="project-footer">
    <span class="project-date">October 2025</span>
    <span class="project-context">Static site</span>
  </div>
</div>
```

**Styling with Open Props:**
```css
.project-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 350px), 1fr));
  gap: var(--size-6);
}

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

.project-header {
  display: flex;
  align-items: center;
  gap: var(--size-3);
}

.project-icon {
  width: var(--size-8);
  height: var(--size-8);
  border-radius: var(--radius-2);
}

.project-title {
  font-size: var(--font-size-5);
  font-weight: var(--font-weight-7);
  color: var(--gray-9);
  margin: 0;
}

.project-headline {
  font-size: var(--font-size-3);
  font-weight: var(--font-weight-6);
  color: var(--gray-8);
  margin: 0;
}

.project-description {
  font-size: var(--font-size-2);
  line-height: var(--font-lineheight-3);
  color: var(--gray-7);
  margin: 0;
}

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
}

.project-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--size-3);
  margin-top: auto; /* Push to bottom */
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: var(--size-2);
  padding: var(--size-2) var(--size-4);
  border-radius: var(--radius-2);
  font-size: var(--font-size-1);
  font-weight: var(--font-weight-6);
  text-decoration: none;
  transition: all var(--ease-3) var(--duration-2);
}

.btn-primary {
  background: var(--blue-6);
  color: var(--gray-0);
}

.btn-primary:hover {
  background: var(--blue-7);
  box-shadow: var(--shadow-3);
}

.btn-secondary {
  background: var(--orange-5);
  color: var(--gray-0);
}

.btn-secondary:hover {
  background: var(--orange-6);
  box-shadow: var(--shadow-3);
}

.btn-tertiary {
  background: var(--gray-0);
  color: var(--gray-8);
  border: var(--border-size-1) solid var(--gray-4);
}

.btn-tertiary:hover {
  background: var(--gray-1);
  border-color: var(--gray-5);
}

.project-footer {
  display: flex;
  justify-content: space-between;
  font-size: var(--font-size-0);
  color: var(--gray-6);
  padding-top: var(--size-3);
  border-top: var(--border-size-1) solid var(--gray-2);
}
```

**Key Design Decisions:**
- **Three-tier button hierarchy** - Primary (blue), Secondary (orange), Tertiary (outline)
- **Flexible grid** - Auto-fits cards based on available space (min 350px)
- **Visual hierarchy** - Icon + title → headline → description → tech tags → actions → metadata
- **Spacing** - Open Props size scale for consistent rhythm
- **Hover states** - Subtle shadow elevation

### 5. Open Props Migration Strategy

**Core Design Token Mapping:**

**Typography:**
```css
/* Before */
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto'...;
line-height: 1.6;

/* After */
font-family: var(--font-sans);
line-height: var(--font-lineheight-3);
```

**Spacing:**
```css
/* Before */
padding: 2rem 1rem;
margin-bottom: 1.5rem;
gap: 20px;

/* After */
padding: var(--size-6) var(--size-4);
margin-bottom: var(--size-5);
gap: var(--size-5);
```

**Colors:**
```css
/* Before */
--primary-color: #2563eb;
--text-color: #1f2937;
--background-alt: #f9fafb;
--border-color: #e5e7eb;

/* After */
--primary-color: var(--blue-6);
--text-color: var(--gray-9);
--background-alt: var(--gray-1);
--border-color: var(--gray-3);
```

**Shadows & Effects:**
```css
/* Before */
box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);

/* After */
box-shadow: var(--shadow-2);
box-shadow: var(--shadow-3);
```

**Border Radius:**
```css
/* Before */
border-radius: 6px;
border-radius: 8px;

/* After */
border-radius: var(--radius-2);
border-radius: var(--radius-3);
```

**Transitions:**
```css
/* Before */
transition: all 0.2s;
transition: transform 300ms ease-in-out;

/* After */
transition: all var(--ease-3) var(--duration-2);
transition: transform var(--ease-3) var(--duration-3);
```

**Migration Order:**

1. Setup - Add Open Props CDN link
2. Global styles - Body, typography, links
3. Header/navigation - Fixed header and nav links
4. Content sections - Masthead, branding, job description
5. Interactive components - Carousel, FAQ, tooltips
6. Project cards - Apply new design
7. Footer - Links and metadata
8. Responsive breakpoints - Update media queries
9. Dark mode prep - Structure CSS for future support (optional)

**File Organization:**

```css
/* styles.css structure */

/* 1. Open Props Import */
@import "https://unpkg.com/open-props";

/* 2. Custom Properties (minimal overrides) */
:root {
  --content-max-width: 800px;
}

/* 3. Base Styles */
body { ... }
h1, h2, h3 { ... }
a { ... }

/* 4. Layout Components */
.header { ... }
.masthead { ... }
.section { ... }

/* 5. Interactive Components */
.carousel { ... }
.faq { ... }
.tooltip { ... }

/* 6. Project Cards */
.project-card { ... }

/* 7. Utilities */
.icon { ... }
.btn { ... }

/* 8. Responsive */
@media (max-width: 640px) { ... }
```

### 6. Responsive Design & Mobile Optimization

**Breakpoint Strategy:**

Mobile-first approach using Open Props:

```css
/* Mobile-first base styles */
.project-list {
  grid-template-columns: 1fr;
  gap: var(--size-5);
}

/* Tablet and up */
@media (min-width: 768px) {
  .project-list {
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: var(--size-6);
  }
}
```

**Mobile-Specific Adjustments:**

**Header/Navigation:**
```css
.header {
  padding: var(--size-3) var(--size-4);
  height: auto;
}

.nav {
  flex-direction: column;
  gap: var(--size-2);
}

@media (min-width: 768px) {
  .header {
    padding: var(--size-4) var(--size-6);
  }

  .nav {
    flex-direction: row;
    gap: var(--size-6);
  }
}
```

**Typography Scaling:**
```css
.masthead h1 {
  font-size: var(--font-size-6);
}

@media (min-width: 768px) {
  .masthead h1 {
    font-size: var(--font-size-8);
  }
}
```

**Carousel Touch Optimization:**
```css
.carousel-arrow {
  width: var(--size-9);
  height: var(--size-9);
  touch-action: manipulation;
}

@media (max-width: 480px) {
  .carousel-arrow {
    display: none; /* Swipe + dots only */
  }
}
```

**Project Card Stacking:**
```css
.project-actions {
  flex-direction: column;
}

.btn {
  width: 100%;
  justify-content: center;
}

@media (min-width: 480px) {
  .project-actions {
    flex-direction: row;
    flex-wrap: wrap;
  }

  .btn {
    width: auto;
  }
}
```

**Spacing Adjustments:**
```css
/* Mobile: tighter spacing */
.section {
  padding: var(--size-6) var(--size-4);
}

.project-card {
  padding: var(--size-5);
  gap: var(--size-3);
}

/* Desktop: more generous spacing */
@media (min-width: 768px) {
  .section {
    padding: var(--size-8) var(--size-6);
  }

  .project-card {
    padding: var(--size-6);
    gap: var(--size-4);
  }
}
```

**Performance Considerations:**
- Lazy load project images: `<img loading="lazy">`
- Responsive images: Consider srcset for different screen sizes
- Reduce animations on `prefers-reduced-motion`
- Keep JavaScript lightweight

## Implementation Plan

### Phase 1: Setup & File Extraction
1. Copy `employers/cybercoders/website/index.html` to working version
2. Extract inline CSS to `styles.css`
3. Extract inline JavaScript to `script.js`
4. Create `icons.svg` sprite sheet from FontAwesome SVGs (from `tmp/fontawesome-free-7.1.0-web/svgs/`)
5. Update HTML to reference external files
6. Test that everything still works after extraction

### Phase 2: Open Props Migration
1. Add Open Props CDN link to HTML head
2. Replace CSS custom properties with Open Props tokens
3. Update all spacing, typography, colors, shadows
4. Test each section as you migrate (incremental validation)

### Phase 3: Carousel Fix
1. Apply width constraints to `.carousel-slide` and `.recommendation-card`
2. Test with various quote lengths (short, medium, long, very long)
3. Verify swipe/keyboard navigation still works
4. Check mobile responsiveness

### Phase 4: Project Cards Redesign
1. Update HTML structure for new card layout
2. Apply new styling with Open Props
3. Add SVG icons to action buttons
4. Test grid layout at various viewport widths

### Phase 5: Icon Integration
1. Create sprite sheet with all needed icons
2. Update all icon references to use `<use>` pattern
3. Test icon rendering and color inheritance

### Phase 6: Testing
- [ ] Desktop (Chrome, Firefox, Safari)
- [ ] Mobile (iOS Safari, Android Chrome)
- [ ] Tablet (iPad, Android tablet)
- [ ] Keyboard navigation (tab, arrows, enter, escape)
- [ ] Screen reader (VoiceOver or NVDA spot check)
- [ ] Reduced motion preference
- [ ] Various content lengths (long quotes, many projects)
- [ ] Print styles (if applicable)

### Phase 7: ERB Template Migration
1. Document all HTML structure changes
2. Update `templates/website/default.html.erb` with new structure
3. Move `styles.css` to `templates/website/styles.css`
4. Move `script.js` to `templates/website/script.js`
5. Move `icons.svg` to `templates/website/icons.svg`
6. Update `WebsiteGenerator` to copy new assets to output directory
7. Test generation with multiple employer examples
8. Verify all ERB variables still work correctly
9. Compare before/after HTML output for regressions

## Validation Criteria

- ✅ All carousel quotes are fully readable (no horizontal overflow)
- ✅ Project cards match target design aesthetic
- ✅ All Open Props tokens used consistently (no hard-coded values)
- ✅ Icons render correctly in all contexts
- ✅ Mobile experience is smooth and responsive
- ✅ No visual regressions in existing sections
- ✅ Page loads quickly (< 1s on 3G)
- ✅ Accessibility features still work (ARIA, keyboard nav)
- ✅ ERB template generates identical output to hand-crafted version

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Open Props color mapping doesn't match brand | Create custom properties that use Open Props as base but override specific values |
| Carousel fix breaks existing JavaScript | Test thoroughly with various quote lengths; keep existing touch/keyboard logic |
| SVG sprites don't work in all browsers | Use modern `<use href>` syntax (widely supported); fallback not needed for target audience |
| ERB migration introduces bugs | Test with multiple employer examples; compare before/after HTML output |
| Page weight increases with Open Props | Open Props is ~8KB gzipped; much smaller than FontAwesome; use specific version for long-term caching |

## Future Enhancements

These are explicitly out of scope for this phase but could be considered later:

- Dark mode support
- Animation enhancements
- Additional sections (skills, timeline, testimonials video)
- A/B testing framework
- Analytics integration
- Accessibility audit and WCAG 2.1 AA certification
- Performance optimization (critical CSS, code splitting)
- Alternative color schemes for different industries

## Success Metrics

- Visual quality assessment: landing page looks professional and modern
- Carousel bug fixed: all recommendations accessible
- Code quality: CSS uses Open Props consistently, no hard-coded values
- Performance: page loads < 1s on 3G
- Maintainability: separate files, clear organization
- Reusability: assets can be shared across multiple employer landing pages
