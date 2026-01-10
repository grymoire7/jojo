# Landing Page HTML Changes for ERB Migration

This document details all HTML structural changes made during landing page improvements (Phases 1-8) that need to be preserved when updating the ERB template.

## Head Section Changes

### Added CDN Links
```html
<link rel="stylesheet" href="https://unpkg.com/open-props">
<link rel="stylesheet" href="styles.css">
```

**Notes:**
- Open Props `normalize.min.css` was intentionally NOT included (caused heading size issues)
- Changed from inline `<style>` tag to external `styles.css` reference

### Removed
- Inline `<style>` tag (~1100 lines of CSS)

## Body Section Changes

### Added SVG Sprite Sheet
Inlined SVG sprite sheet at top of `<body>` (after opening tag, before content):

```html
<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
  <defs>
    <symbol id="icon-github" viewBox="0 0 512 512">...</symbol>
    <symbol id="icon-linkedin" viewBox="0 0 448 512">...</symbol>
    <symbol id="icon-calendar" viewBox="0 0 448 512">...</symbol>
    <symbol id="icon-external-link" viewBox="0 0 512 512">...</symbol>
    <symbol id="icon-download" viewBox="0 0 448 512">...</symbol>
    <symbol id="icon-book" viewBox="0 0 512 512">...</symbol>
  </defs>
</svg>
```

Icons extracted from FontAwesome 7.1.0 free icons.

### Project Cards Structure (Phase 5)

Each project card now includes:

1. **Project images** with lazy loading:
```html
<img src="<%= project[:image_url] %>" alt="..." class="project-image" loading="lazy">
```

2. **Technology tags**:
```html
<div class="project-tech">
  <span class="tech-tag">JavaScript</span>
  <span class="tech-tag">HTML</span>
  <!-- etc -->
</div>
```

3. **Three-button action system** with SVG icons:
```html
<div class="project-actions">
  <a href="<%= project[:blog_post_url] %>" class="btn btn-primary">
    <svg class="icon"><use href="icons.svg#icon-book"></use></svg>
    Technical Deep Dive
  </a>
  <a href="<%= project[:live_url] %>" class="btn btn-secondary">
    <svg class="icon"><use href="icons.svg#icon-external-link"></use></svg>
    Live Demo
  </a>
  <a href="<%= project[:github_url] %>" class="btn btn-tertiary">
    <svg class="icon"><use href="icons.svg#icon-github"></use></svg>
    Source Code
  </a>
</div>
```

4. **Project footer** with date and context:
```html
<div class="project-footer">
  <span class="project-date"><%= project[:year] %></span>
  <span class="project-context"><%= project[:context] %></span>
</div>
```

### Footer Changes (Phase 6)

Footer links now include download icons:

```html
<div class="footer-links">
  <a href="<%= base_url %>/resume/<%= company_slug %>">
    <svg class="icon"><use href="icons.svg#icon-download"></use></svg>
    View Resume
  </a>
  <a href="<%= base_url %>/cover-letter/<%= company_slug %>">
    <svg class="icon"><use href="icons.svg#icon-download"></use></svg>
    View Cover Letter
  </a>
</div>
```

### Script Tag Update

Changed from inline `<script>` to external reference before closing `</body>`:

```html
<script src="script.js"></script>
```

**Removed:**
- Inline `<script>` tag (~400 lines of JavaScript)

## Files to Copy During Migration (Phase 10)

When updating the ERB template, also copy these asset files:

1. `employers/cybercoders/website/styles.css` → `templates/website/styles.css`
2. `employers/cybercoders/website/script.js` → `templates/website/script.js`
3. `employers/cybercoders/website/icons.svg` → `templates/website/icons.svg` (if kept as separate file instead of inline)

## ARIA Attributes (Already Present)

Verify these ARIA attributes are preserved in ERB:

**Carousel:**
- `role="region"` on carousel container
- `aria-label` on carousel navigation buttons
- `role="tabpanel"` on carousel slides
- `aria-hidden` on inactive slides

**FAQ:**
- `aria-expanded` on question buttons
- `aria-controls` linking questions to answers
- `aria-hidden="true"` on decorative chevrons

**Annotations:**
- `tabindex="0"` on annotated spans
- `data-tier` attributes for highlight intensity

## Image Lazy Loading

All project images must have `loading="lazy"` attribute:
```html
<img src="..." alt="..." class="project-image" loading="lazy">
```

## Important Notes

1. **Open Props normalize NOT included** - Do not add `normalize.min.css` CDN link
2. **Heading sizes manually set** - Custom `--font-size-*` tokens used to prevent wrapping
3. **SVG sprite inlined** - Not loaded as external file for better performance
4. **Icon sizing** - Icons use `.icon` class with size variants (`.icon-sm`, `.icon-lg`)
5. **Responsive images** - All use `loading="lazy"` for performance

## ERB Template Patterns to Preserve

When migrating, ensure these ERB patterns are maintained:

```erb
<% projects.each do |project| %>
  <!-- Project card HTML -->
  <% if project[:blog_post_url] %>
    <!-- Show blog button -->
  <% end %>
  <% if project[:live_url] %>
    <!-- Show live demo button -->
  <% end %>
  <% if project[:github_url] %>
    <!-- Show GitHub button -->
  <% end %>
<% end %>
```

## WebsiteGenerator Updates

The generator (Phase 10, Task 10.4) needs to:
1. Copy `styles.css` to output directory
2. Copy `script.js` to output directory
3. Copy `icons.svg` to output directory (if used as separate file)
4. Ensure all three files are referenced correctly in generated HTML
