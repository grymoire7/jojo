# Phase 6b Portfolio Highlights Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add project/achievement highlights to landing pages, resumes, and cover letters using skill-based matching from a YAML data source.

**Architecture:** Template-based project data (`projects.yml`) with skill-based selection algorithm. Projects are scored by matching their skills against job description requirements. Selected projects are passed to generators for AI adaptation or template rendering.

**Tech Stack:** Ruby 3.4.5, YAML parsing, FileUtils for image handling, existing Employer/Generator patterns

**Design Reference:** `docs/plans/2025-12-27-projects-yaml-design.md`

---

## Task 1: ProjectLoader - YAML Loading and Validation

**Files:**
- Create: `lib/jojo/project_loader.rb`
- Create: `test/unit/project_loader_test.rb`
- Create: `test/fixtures/valid_projects.yml`
- Create: `test/fixtures/invalid_projects.yml`
- Create: `test/fixtures/minimal_projects.yml`

**Step 1: Write failing test for basic YAML loading**

Create `test/unit/project_loader_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/project_loader'

describe Jojo::ProjectLoader do
  it "loads valid projects YAML" do
    loader = Jojo::ProjectLoader.new('test/fixtures/valid_projects.yml')
    projects = loader.load

    _(projects).must_be_kind_of Array
    _(projects.size).must_equal 2
    _(projects.first[:title]).must_equal 'Project Alpha'
  end
end
```

Create `test/fixtures/valid_projects.yml`:

```yaml
- title: "Project Alpha"
  description: "Led a team to build a scalable web application."
  year: 2024
  context: "at Example Corp"
  role: "Tech Lead"
  skills:
    - Ruby on Rails
    - PostgreSQL
    - web development

- title: "Employee of the Year"
  description: "Recognized for outstanding leadership."
  year: 2023
  context: "at Previous Corp"
  skills:
    - leadership
    - teamwork
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/project_loader_test.rb
```

Expected: FAIL with "cannot load such file -- jojo/project_loader"

**Step 3: Implement minimal ProjectLoader**

Create `lib/jojo/project_loader.rb`:

```ruby
require 'yaml'

module Jojo
  class ProjectLoader
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      return [] unless File.exist?(file_path)

      projects = YAML.load_file(file_path)
      projects.map { |p| symbolize_keys(p) }
    end

    private

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/project_loader_test.rb
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/project_loader.rb test/unit/project_loader_test.rb test/fixtures/valid_projects.yml
git commit -m "feat: add basic ProjectLoader for YAML parsing"
```

---

## Task 2: ProjectLoader - Validation

**Files:**
- Modify: `lib/jojo/project_loader.rb`
- Modify: `test/unit/project_loader_test.rb`

**Step 1: Write failing test for required fields validation**

Add to `test/unit/project_loader_test.rb`:

```ruby
it "validates required fields" do
  loader = Jojo::ProjectLoader.new('test/fixtures/invalid_projects.yml')

  error = _ { loader.load }.must_raise Jojo::ProjectLoader::ValidationError
  _(error.message).must_include "missing 'title'"
end

it "validates skills is an array" do
  loader = Jojo::ProjectLoader.new('test/fixtures/invalid_skills_projects.yml')

  error = _ { loader.load }.must_raise Jojo::ProjectLoader::ValidationError
  _(error.message).must_include "'skills' must be an array"
end

it "returns empty array when file missing" do
  loader = Jojo::ProjectLoader.new('test/fixtures/nonexistent.yml')
  projects = loader.load

  _(projects).must_equal []
end
```

Create `test/fixtures/invalid_projects.yml`:

```yaml
- description: "Missing title field"
  skills:
    - Ruby
```

Create `test/fixtures/invalid_skills_projects.yml`:

```yaml
- title: "Bad Project"
  description: "Skills is not an array"
  skills: "Ruby, PostgreSQL"
```

**Step 2: Run tests to verify they fail**

```bash
ruby -Ilib:test test/unit/project_loader_test.rb
```

Expected: FAIL - no ValidationError class

**Step 3: Implement validation**

Update `lib/jojo/project_loader.rb`:

```ruby
require 'yaml'

module Jojo
  class ProjectLoader
    class ValidationError < StandardError; end

    REQUIRED_FIELDS = %w[title description skills]

    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def load
      return [] unless File.exist?(file_path)

      projects = YAML.load_file(file_path)
      validate_projects!(projects)
      projects.map { |p| symbolize_keys(p) }
    end

    private

    def validate_projects!(projects)
      errors = []

      projects.each_with_index do |project, index|
        REQUIRED_FIELDS.each do |field|
          unless project[field]
            errors << "Project #{index + 1}: missing '#{field}'"
          end
        end

        if project['skills'] && !project['skills'].is_a?(Array)
          errors << "Project #{index + 1}: 'skills' must be an array"
        end
      end

      raise ValidationError, errors.join('; ') unless errors.empty?
    end

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
```

**Step 4: Run tests to verify they pass**

```bash
ruby -Ilib:test test/unit/project_loader_test.rb
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/project_loader.rb test/unit/project_loader_test.rb test/fixtures/invalid_projects.yml test/fixtures/invalid_skills_projects.yml
git commit -m "feat: add validation to ProjectLoader"
```

---

## Task 3: ProjectLoader - Minimal Projects Support

**Files:**
- Modify: `test/unit/project_loader_test.rb`

**Step 1: Write test for minimal projects (only required fields)**

Add to `test/unit/project_loader_test.rb`:

```ruby
it "loads minimal projects with only required fields" do
  loader = Jojo::ProjectLoader.new('test/fixtures/minimal_projects.yml')
  projects = loader.load

  _(projects.size).must_equal 1
  _(projects.first[:title]).must_equal 'Minimal Project'
  _(projects.first[:year]).must_be_nil
  _(projects.first[:context]).must_be_nil
end
```

Create `test/fixtures/minimal_projects.yml`:

```yaml
- title: "Minimal Project"
  description: "Only has required fields."
  skills:
    - Ruby
```

**Step 2: Run test to verify it passes (no code change needed)**

```bash
ruby -Ilib:test test/unit/project_loader_test.rb
```

Expected: PASS (validation already handles optional fields)

**Step 3: Commit**

```bash
git add test/unit/project_loader_test.rb test/fixtures/minimal_projects.yml
git commit -m "test: add coverage for minimal projects"
```

---

## Task 4: ProjectSelector - Basic Selection

**Files:**
- Create: `lib/jojo/project_selector.rb`
- Create: `test/unit/project_selector_test.rb`
- Create: `test/fixtures/sample_job_details.yml`

**Step 1: Write failing test for basic skill matching**

Create `test/unit/project_selector_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/project_selector'
require_relative '../../lib/jojo/employer'

describe Jojo::ProjectSelector do
  before do
    @employer = Jojo::Employer.new('Test Corp')
    @employer.create_directory!

    # Create job_details.yml fixture
    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
      desired_skills:
        - leadership
    YAML

    @projects = [
      {
        title: 'Project Alpha',
        description: 'Web app project',
        skills: ['Ruby on Rails', 'PostgreSQL', 'web development']
      },
      {
        title: 'Project Beta',
        description: 'Unrelated project',
        skills: ['Python', 'MongoDB']
      },
      {
        title: 'Leadership Award',
        description: 'Employee award',
        skills: ['leadership', 'teamwork']
      }
    ]
  end

  after do
    FileUtils.rm_rf('employers/test-corp')
  end

  it "selects projects based on skill matching" do
    selector = Jojo::ProjectSelector.new(@employer, @projects)
    selected = selector.select_for_landing_page(limit: 3)

    _(selected.size).must_equal 3
    _(selected.first[:title]).must_equal 'Project Alpha'
    _(selected.first[:score]).must_be :>, 0
  end
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/project_selector_test.rb
```

Expected: FAIL with "cannot load such file -- jojo/project_selector"

**Step 3: Implement basic ProjectSelector**

Create `lib/jojo/project_selector.rb`:

```ruby
require 'yaml'

module Jojo
  class ProjectSelector
    attr_reader :employer, :projects

    def initialize(employer, projects)
      @employer = employer
      @projects = projects
    end

    def select_for_landing_page(limit: 5)
      select_projects(limit: limit)
    end

    def select_for_resume(limit: 3)
      select_projects(limit: limit)
    end

    def select_for_cover_letter(limit: 2)
      select_projects(limit: limit)
    end

    private

    def select_projects(limit:)
      scored = projects.map do |project|
        project.merge(score: calculate_score(project))
      end

      scored.sort_by { |p| -p[:score] }.take(limit)
    end

    def calculate_score(project)
      score = 0
      project_skills = project[:skills] || []

      project_skills.each do |skill|
        score += 10 if required_skills.include?(skill)
        score += 5 if desired_skills.include?(skill)
      end

      score
    end

    def job_details
      @job_details ||= begin
        return {} unless File.exist?(employer.job_details_path)
        YAML.load_file(employer.job_details_path)
      end
    end

    def required_skills
      job_details['required_skills'] || []
    end

    def desired_skills
      job_details['desired_skills'] || []
    end
  end
end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/project_selector_test.rb
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/project_selector.rb test/unit/project_selector_test.rb
git commit -m "feat: add ProjectSelector with skill-based matching"
```

---

## Task 5: ProjectSelector - Recency Bonus

**Files:**
- Modify: `lib/jojo/project_selector.rb`
- Modify: `test/unit/project_selector_test.rb`

**Step 1: Write failing test for recency bonus**

Add to `test/unit/project_selector_test.rb`:

```ruby
it "applies recency bonus to recent projects" do
  current_year = Time.now.year
  projects = [
    {
      title: 'Old Project',
      description: 'From 5 years ago',
      skills: ['Ruby on Rails'],
      year: current_year - 5
    },
    {
      title: 'Recent Project',
      description: 'From last year',
      skills: ['Ruby on Rails'],
      year: current_year - 1
    }
  ]

  selector = Jojo::ProjectSelector.new(@employer, projects)
  selected = selector.select_for_landing_page(limit: 2)

  _(selected.first[:title]).must_equal 'Recent Project'
  _(selected.first[:score]).must_be :>, selected.last[:score]
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/project_selector_test.rb
```

Expected: FAIL - scores are equal, no recency bonus

**Step 3: Implement recency bonus**

Update `lib/jojo/project_selector.rb` `calculate_score` method:

```ruby
def calculate_score(project)
  score = 0
  project_skills = project[:skills] || []

  project_skills.each do |skill|
    score += 10 if required_skills.include?(skill)
    score += 5 if desired_skills.include?(skill)
  end

  # Recency bonus
  if project[:year]
    current_year = Time.now.year
    score += 5 if project[:year] >= (current_year - 2)
  end

  score
end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/project_selector_test.rb
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/project_selector.rb test/unit/project_selector_test.rb
git commit -m "feat: add recency bonus to project scoring"
```

---

## Task 6: ProjectSelector - Empty Results Handling

**Files:**
- Modify: `test/unit/project_selector_test.rb`

**Step 1: Write test for no matching projects**

Add to `test/unit/project_selector_test.rb`:

```ruby
it "returns empty array when no projects match" do
  projects = [
    {
      title: 'Unrelated Project',
      description: 'No matching skills',
      skills: ['Python', 'Java']
    }
  ]

  selector = Jojo::ProjectSelector.new(@employer, projects)
  selected = selector.select_for_landing_page(limit: 3)

  _(selected).must_be_kind_of Array
  _(selected).must_be_empty
end
```

**Step 2: Run test to verify behavior**

```bash
ruby -Ilib:test test/unit/project_selector_test.rb
```

Expected: Currently returns projects with score 0. We want empty array.

**Step 3: Update selector to filter zero scores**

Update `lib/jojo/project_selector.rb` `select_projects` method:

```ruby
def select_projects(limit:)
  scored = projects.map do |project|
    project.merge(score: calculate_score(project))
  end

  # Filter out zero-score projects
  scored = scored.select { |p| p[:score] > 0 }

  scored.sort_by { |p| -p[:score] }.take(limit)
end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/project_selector_test.rb
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/project_selector.rb test/unit/project_selector_test.rb
git commit -m "feat: filter zero-score projects from selection"
```

---

## Task 7: WebsiteGenerator - Integrate ProjectLoader and ProjectSelector

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb`
- Create: `test/unit/website_generator_projects_test.rb`

**Step 1: Write failing test for project integration**

Create `test/unit/website_generator_projects_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/generators/website_generator'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/config'

describe 'WebsiteGenerator with Projects' do
  before do
    @employer = Jojo::Employer.new('Test Corp')
    @employer.create_directory!
    @config = Jojo::Config.new('test/fixtures/valid_config.yml')

    # Create job_details.yml
    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
    YAML

    # Create projects.yml
    File.write('inputs/projects.yml', <<~YAML)
      - title: "Matching Project"
        description: "This project matches job requirements"
        skills:
          - Ruby on Rails
          - PostgreSQL
      - title: "Non-matching Project"
        description: "This does not match"
        skills:
          - Python
    YAML
  end

  after do
    FileUtils.rm_rf('employers/test-corp')
    FileUtils.rm_f('inputs/projects.yml')
  end

  it "loads and selects relevant projects" do
    generator = Jojo::WebsiteGenerator.new(@employer, @config)

    # Access private method for testing
    projects = generator.send(:load_projects)

    _(projects).wont_be_empty
    _(projects.first[:title]).must_equal 'Matching Project'
    _(projects.first[:score]).must_be :>, 0
  end
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/website_generator_projects_test.rb
```

Expected: FAIL - no load_projects method

**Step 3: Integrate ProjectLoader and ProjectSelector into WebsiteGenerator**

First, check the current WebsiteGenerator structure:

```bash
head -30 lib/jojo/generators/website_generator.rb
```

Then update `lib/jojo/generators/website_generator.rb` to add project loading:

Add requires at top:
```ruby
require_relative '../project_loader'
require_relative '../project_selector'
```

Add private method:
```ruby
private

def load_projects
  return [] unless File.exist?('inputs/projects.yml')

  loader = ProjectLoader.new('inputs/projects.yml')
  all_projects = loader.load

  selector = ProjectSelector.new(employer, all_projects)
  selector.select_for_landing_page(limit: 5)
rescue ProjectLoader::ValidationError => e
  logger&.warn "Projects validation failed: #{e.message}"
  []
end
```

**Step 4: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/website_generator_projects_test.rb
```

Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/generators/website_generator.rb test/unit/website_generator_projects_test.rb
git commit -m "feat: integrate project loading into WebsiteGenerator"
```

---

## Task 8: WebsiteGenerator - Pass Projects to Template

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb`
- Modify: `test/unit/website_generator_projects_test.rb`

**Step 1: Write test for projects in template variables**

Add to `test/unit/website_generator_projects_test.rb`:

```ruby
it "includes projects in template variables" do
  # Create minimal job description for full generation
  File.write(@employer.job_description_path, "Test job description")

  # Mock AI client to avoid real API calls
  mock_ai = Minitest::Mock.new
  mock_ai.expect :generate_text, "Test branding statement", [String]

  generator = Jojo::WebsiteGenerator.new(@employer, @config, ai_client: mock_ai)
  generator.generate(template: 'default')

  # Read generated HTML
  html = File.read(@employer.index_html_path)

  # Should mention the matching project
  _(html).must_include 'Matching Project'

  mock_ai.verify
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/website_generator_projects_test.rb
```

Expected: FAIL - template doesn't include projects yet

**Step 3: Update WebsiteGenerator generate method**

Update the `generate` method in `lib/jojo/generators/website_generator.rb` to include projects in template_vars:

```ruby
def generate(template: 'default')
  # ... existing code ...

  projects = load_projects

  template_vars = {
    # ... existing vars ...
    projects: projects
  }

  # ... rest of method ...
end
```

**Step 4: Update default template to display projects**

Read current template:
```bash
cat templates/website/default.html.erb | head -100
```

Then modify `templates/website/default.html.erb` to add projects section (add before footer):

```erb
    <% if projects && !projects.empty? %>
    <section class="projects">
      <h2>Relevant Work</h2>
      <div class="project-list">
        <% projects.each do |project| %>
        <div class="project-card">
          <h3><%= project[:title] %></h3>
          <p><%= project[:description] %></p>
          <% if project[:context] || project[:year] %>
          <p class="project-meta">
            <% if project[:year] %><span><%= project[:year] %></span><% end %>
            <% if project[:context] %><span><%= project[:context] %></span><% end %>
          </p>
          <% end %>
          <% if project[:blog_post_url] || project[:github_url] || project[:live_url] %>
          <div class="project-links">
            <% if project[:blog_post_url] %><a href="<%= project[:blog_post_url] %>">Blog Post</a><% end %>
            <% if project[:github_url] %><a href="<%= project[:github_url] %>">GitHub</a><% end %>
            <% if project[:live_url] %><a href="<%= project[:live_url] %>">Live Demo</a><% end %>
          </div>
          <% end %>
        </div>
        <% end %>
      </div>
    </section>
    <% end %>
```

Add CSS for projects section (in `<style>` tag):

```css
.projects {
  margin: 40px 0;
}

.project-list {
  display: grid;
  gap: 20px;
}

.project-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  background: white;
}

.project-card h3 {
  margin-top: 0;
  color: #2c3e50;
}

.project-meta {
  font-size: 0.9em;
  color: #666;
  margin: 10px 0;
}

.project-meta span {
  margin-right: 15px;
}

.project-links {
  margin-top: 15px;
}

.project-links a {
  display: inline-block;
  margin-right: 15px;
  color: #3498db;
  text-decoration: none;
}

.project-links a:hover {
  text-decoration: underline;
}
```

**Step 5: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/website_generator_projects_test.rb
```

Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/generators/website_generator.rb templates/website/default.html.erb test/unit/website_generator_projects_test.rb
git commit -m "feat: add projects section to default website template"
```

---

## Task 9: Image Handling - Copy Local Images

**Files:**
- Modify: `lib/jojo/generators/website_generator.rb`
- Modify: `test/unit/website_generator_projects_test.rb`
- Create: `test/fixtures/test_project_image.png`

**Step 1: Write test for image copying**

Add to `test/unit/website_generator_projects_test.rb`:

```ruby
it "copies local project images to website directory" do
  # Create test image
  FileUtils.mkdir_p('inputs/images')
  File.write('inputs/images/test.png', 'fake image data')

  # Update projects.yml with image
  File.write('inputs/projects.yml', <<~YAML)
    - title: "Project with Image"
      description: "Has a local image"
      skills:
        - Ruby on Rails
      image: "inputs/images/test.png"
  YAML

  File.write(@employer.job_details_path, <<~YAML)
    required_skills:
      - Ruby on Rails
  YAML

  File.write(@employer.job_description_path, "Test job")

  mock_ai = Minitest::Mock.new
  mock_ai.expect :generate_text, "Test branding", [String]

  generator = Jojo::WebsiteGenerator.new(@employer, @config, ai_client: mock_ai)
  generator.generate(template: 'default')

  # Check image was copied
  copied_image = File.join(@employer.website_path, 'images', 'test.png')
  _(File.exist?(copied_image)).must_equal true

  # Check HTML references image correctly
  html = File.read(@employer.index_html_path)
  _(html).must_include 'src="images/test.png"'

  FileUtils.rm_rf('inputs/images')
  mock_ai.verify
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/website_generator_projects_test.rb
```

Expected: FAIL - images not copied

**Step 3: Implement image handling**

Add private method to `lib/jojo/generators/website_generator.rb`:

```ruby
def process_project_images(projects)
  projects.map do |project|
    project = project.dup

    if project[:image]
      if project[:image].start_with?('http://', 'https://')
        # URL: use directly
        project[:image_url] = project[:image]
      else
        # File path: copy to website/images/
        src = File.join(Dir.pwd, project[:image])

        if File.exist?(src)
          dest_dir = File.join(employer.website_path, 'images')
          FileUtils.mkdir_p(dest_dir)

          filename = File.basename(project[:image])
          dest = File.join(dest_dir, filename)
          FileUtils.cp(src, dest)

          project[:image_url] = "images/#{filename}"
        else
          logger&.warn "Project image not found: #{project[:image]}"
        end
      end
    end

    project
  end
end
```

Update `generate` method to call `process_project_images`:

```ruby
def generate(template: 'default')
  # ... existing code ...

  projects = load_projects
  projects = process_project_images(projects)

  template_vars = {
    # ... existing vars ...
    projects: projects
  }

  # ... rest of method ...
end
```

**Step 4: Update template to display images**

Update the project-card section in `templates/website/default.html.erb`:

```erb
<div class="project-card">
  <% if project[:image_url] %>
  <img src="<%= project[:image_url] %>" alt="<%= project[:title] %>" class="project-image">
  <% end %>
  <h3><%= project[:title] %></h3>
  <!-- rest of card ... -->
</div>
```

Add CSS for project images:

```css
.project-image {
  width: 100%;
  max-width: 400px;
  height: auto;
  border-radius: 4px;
  margin-bottom: 15px;
}
```

**Step 5: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/website_generator_projects_test.rb
```

Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/generators/website_generator.rb templates/website/default.html.erb test/unit/website_generator_projects_test.rb
git commit -m "feat: add image handling for project images"
```

---

## Task 10: ResumeGenerator - Integrate Projects

**Files:**
- Modify: `lib/jojo/generators/resume_generator.rb`
- Modify: `lib/jojo/prompts/resume_prompt.rb`
- Create: `test/unit/resume_generator_projects_test.rb`

**Step 1: Write test for project integration in resume**

Create `test/unit/resume_generator_projects_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/generators/resume_generator'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/config'

describe 'ResumeGenerator with Projects' do
  before do
    @employer = Jojo::Employer.new('Test Corp')
    @employer.create_directory!
    @config = Jojo::Config.new('test/fixtures/valid_config.yml')

    File.write(@employer.job_description_path, "Ruby developer needed")
    File.write('inputs/generic_resume.md', "# Generic Resume\n\nExperience...")

    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
    YAML

    File.write('inputs/projects.yml', <<~YAML)
      - title: "Rails App"
        description: "Built a Rails application"
        skills:
          - Ruby on Rails
    YAML
  end

  after do
    FileUtils.rm_rf('employers/test-corp')
    FileUtils.rm_f('inputs/generic_resume.md')
    FileUtils.rm_f('inputs/projects.yml')
  end

  it "includes relevant projects in resume prompt" do
    mock_ai = Minitest::Mock.new

    # Capture the prompt to verify it includes projects
    mock_ai.expect :generate_text do |prompt|
      _(prompt).must_include 'Rails App'
      _(prompt).must_include 'relevant projects'
      "Generated resume with projects"
    end

    generator = Jojo::ResumeGenerator.new(@employer, @config, ai_client: mock_ai)
    generator.generate

    mock_ai.verify
  end
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/resume_generator_projects_test.rb
```

Expected: FAIL - prompt doesn't include projects

**Step 3: Add project loading to ResumeGenerator**

Update `lib/jojo/generators/resume_generator.rb`:

Add requires at top:
```ruby
require_relative '../project_loader'
require_relative '../project_selector'
```

Add private method:
```ruby
private

def load_projects
  return [] unless File.exist?('inputs/projects.yml')

  loader = ProjectLoader.new('inputs/projects.yml')
  all_projects = loader.load

  selector = ProjectSelector.new(employer, all_projects)
  selector.select_for_resume(limit: 3)
rescue ProjectLoader::ValidationError => e
  logger&.warn "Projects validation failed: #{e.message}"
  []
end
```

Update `generate` method to pass projects to prompt:

```ruby
def generate
  # ... existing code to read job_description, generic_resume, research ...

  projects = load_projects

  prompt = ResumePrompt.generate(
    # ... existing params ...
    relevant_projects: projects
  )

  # ... rest of method ...
end
```

**Step 4: Update ResumePrompt to include projects**

Update `lib/jojo/prompts/resume_prompt.rb`:

```ruby
def self.generate(job_description:, generic_resume:, research: nil, voice_and_tone:, base_url:, relevant_projects: [])
  # ... existing prompt content ...

  prompt = <<~PROMPT
    # ... existing prompt sections ...

    #{projects_section(relevant_projects)}

    # ... rest of prompt ...
  PROMPT
end

private

def self.projects_section(projects)
  return "" if projects.empty?

  <<~SECTION
    ## Relevant Projects and Achievements

    The following projects and achievements are particularly relevant to this role:

    #{projects.map { |p| "- **#{p[:title]}**: #{p[:description]}" }.join("\n")}

    Consider emphasizing these in the tailored resume where appropriate.
  SECTION
end
```

**Step 5: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/resume_generator_projects_test.rb
```

Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/generators/resume_generator.rb lib/jojo/prompts/resume_prompt.rb test/unit/resume_generator_projects_test.rb
git commit -m "feat: integrate projects into resume generation"
```

---

## Task 11: CoverLetterGenerator - Integrate Projects

**Files:**
- Modify: `lib/jojo/generators/cover_letter_generator.rb`
- Modify: `lib/jojo/prompts/cover_letter_prompt.rb`
- Create: `test/unit/cover_letter_generator_projects_test.rb`

**Step 1: Write test for project integration in cover letter**

Create `test/unit/cover_letter_generator_projects_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/generators/cover_letter_generator'
require_relative '../../lib/jojo/employer'
require_relative '../../lib/jojo/config'

describe 'CoverLetterGenerator with Projects' do
  before do
    @employer = Jojo::Employer.new('Test Corp')
    @employer.create_directory!
    @config = Jojo::Config.new('test/fixtures/valid_config.yml')

    File.write(@employer.job_description_path, "Ruby developer needed")
    File.write(@employer.resume_path, "# Resume\n\nTailored resume...")

    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
    YAML

    File.write('inputs/projects.yml', <<~YAML)
      - title: "Rails App"
        description: "Built a Rails application"
        skills:
          - Ruby on Rails
    YAML
  end

  after do
    FileUtils.rm_rf('employers/test-corp')
    FileUtils.rm_f('inputs/projects.yml')
  end

  it "includes relevant projects in cover letter prompt" do
    mock_ai = Minitest::Mock.new

    mock_ai.expect :generate_text do |prompt|
      _(prompt).must_include 'Rails App'
      _(prompt).must_include 'highlight projects'
      "Generated cover letter with projects"
    end

    generator = Jojo::CoverLetterGenerator.new(@employer, @config, ai_client: mock_ai)
    generator.generate

    mock_ai.verify
  end
end
```

**Step 2: Run test to verify it fails**

```bash
ruby -Ilib:test test/unit/cover_letter_generator_projects_test.rb
```

Expected: FAIL - prompt doesn't include projects

**Step 3: Add project loading to CoverLetterGenerator**

Update `lib/jojo/generators/cover_letter_generator.rb`:

Add requires:
```ruby
require_relative '../project_loader'
require_relative '../project_selector'
```

Add private method:
```ruby
private

def load_projects
  return [] unless File.exist?('inputs/projects.yml')

  loader = ProjectLoader.new('inputs/projects.yml')
  all_projects = loader.load

  selector = ProjectSelector.new(employer, all_projects)
  selector.select_for_cover_letter(limit: 2)
rescue ProjectLoader::ValidationError => e
  logger&.warn "Projects validation failed: #{e.message}"
  []
end
```

Update `generate` method:
```ruby
def generate
  # ... existing code ...

  projects = load_projects

  prompt = CoverLetterPrompt.generate(
    # ... existing params ...
    highlight_projects: projects
  )

  # ... rest of method ...
end
```

**Step 4: Update CoverLetterPrompt**

Update `lib/jojo/prompts/cover_letter_prompt.rb`:

```ruby
def self.generate(job_description:, research:, resume:, voice_and_tone:, base_url:, highlight_projects: [])
  # ... existing prompt ...

  prompt = <<~PROMPT
    # ... existing sections ...

    #{projects_section(highlight_projects)}

    # ... rest of prompt ...
  PROMPT
end

private

def self.projects_section(projects)
  return "" if projects.empty?

  <<~SECTION
    ## Projects to Highlight

    Consider naturally weaving these relevant projects into the narrative:

    #{projects.map { |p| "- **#{p[:title]}**: #{p[:description]}" }.join("\n")}

    Use these to demonstrate concrete examples of your qualifications.
  SECTION
end
```

**Step 5: Run test to verify it passes**

```bash
ruby -Ilib:test test/unit/cover_letter_generator_projects_test.rb
```

Expected: PASS

**Step 6: Commit**

```bash
git add lib/jojo/generators/cover_letter_generator.rb lib/jojo/prompts/cover_letter_prompt.rb test/unit/cover_letter_generator_projects_test.rb
git commit -m "feat: integrate projects into cover letter generation"
```

---

## Task 12: Integration Test - Full Workflow

**Files:**
- Create: `test/integration/projects_workflow_test.rb`

**Step 1: Write integration test**

Create `test/integration/projects_workflow_test.rb`:

```ruby
require_relative '../test_helper'
require_relative '../../lib/jojo/cli'
require_relative '../../lib/jojo/employer'

describe 'Projects Integration Workflow' do
  before do
    @employer = Jojo::Employer.new('Integration Test Corp')
    @employer.create_directory!

    # Setup all required files
    File.write(@employer.job_description_path, "Looking for Ruby on Rails developer")

    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
      desired_skills:
        - leadership
    YAML

    File.write('inputs/generic_resume.md', "# Generic Resume\n\nExperience with Ruby...")

    File.write('inputs/projects.yml', <<~YAML)
      - title: "E-commerce Platform"
        description: "Built a scalable Rails e-commerce platform"
        year: 2024
        context: "at Previous Corp"
        role: "Lead Developer"
        blog_post_url: "https://example.com/blog/ecommerce"
        github_url: "https://github.com/user/ecommerce"
        skills:
          - Ruby on Rails
          - PostgreSQL
          - web development

      - title: "Team Leadership Award"
        description: "Recognized for exceptional team leadership"
        year: 2023
        skills:
          - leadership
          - teamwork

      - title: "Python Project"
        description: "Unrelated Python work"
        skills:
          - Python
          - Django
    YAML
  end

  after do
    FileUtils.rm_rf('employers/integration-test-corp')
    FileUtils.rm_f('inputs/generic_resume.md')
    FileUtils.rm_f('inputs/projects.yml')
  end

  it "generates website with relevant projects only" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')

    mock_ai = Minitest::Mock.new
    mock_ai.expect :generate_text, "Branding statement", [String]

    generator = Jojo::WebsiteGenerator.new(@employer, config, ai_client: mock_ai)
    generator.generate(template: 'default')

    html = File.read(@employer.index_html_path)

    # Should include matching projects
    _(html).must_include 'E-commerce Platform'
    _(html).must_include 'Team Leadership Award'

    # Should NOT include non-matching project
    _(html).wont_include 'Python Project'

    # Should include project metadata
    _(html).must_include '2024'
    _(html).must_include 'at Previous Corp'

    # Should include links
    _(html).must_include 'https://example.com/blog/ecommerce'
    _(html).must_include 'https://github.com/user/ecommerce'

    mock_ai.verify
  end
end
```

**Step 2: Run test to verify it passes**

```bash
ruby -Ilib:test test/integration/projects_workflow_test.rb
```

Expected: PASS (all components integrated correctly)

**Step 3: Commit**

```bash
git add test/integration/projects_workflow_test.rb
git commit -m "test: add integration test for projects workflow"
```

---

## Task 13: Documentation and Templates

**Files:**
- Modify: `templates/projects.yml`
- Modify: `docs/plans/implementation_plan.md`

**Step 1: Update example projects template**

The template already exists at `templates/projects.yml`. Update it to match the design:

```yaml
# Projects and achievements highlights
# Used in landing pages, resumes, and cover letters
# AI selects relevant items based on skill matching
#
# Copy this file to inputs/projects.yml and customize with your actual projects

- title: "Project Alpha"
  description: "Led a team of 5 developers to build a scalable web application
    that increased customer engagement by 30%."

  # Optional metadata for prioritization and context
  year: 2024                    # or date_range: "2023-2024"
  context: "at Example Corp"    # or "personal project", "open source", "freelance"
  role: "Tech Lead"             # your role in the project

  # Optional URLs
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

- title: "Open Source Contribution"
  description: "Major contributor to popular Ruby gem with 10k+ downloads."
  year: 2024
  context: "personal project"
  github_url: "https://github.com/example/gem"
  skills:
    - Ruby
    - open source
    - community engagement
```

**Step 2: Update implementation plan**

Update Phase 6b section in `docs/plans/implementation_plan.md`:

Change status from PLANNED to IN PROGRESS, and update tasks with checkboxes:

```markdown
### Phase 6b: Portfolio Highlights ✅

**Goal**: Display relevant projects and achievements

**Status**: COMPLETED

**Design Document**: `docs/plans/2025-12-27-projects-yaml-design.md`

#### Tasks:

- [x] Create ProjectLoader for YAML loading and validation
- [x] Create ProjectSelector for skill-based matching
- [x] Integrate projects into WebsiteGenerator
- [x] Update default template with projects section
- [x] Add image handling for project images
- [x] Integrate projects into ResumeGenerator
- [x] Integrate projects into CoverLetterGenerator
- [x] Create comprehensive test coverage
- [x] Update templates/projects.yml example

**Validation**: Landing page includes relevant project highlights selected by skill matching. Resume and cover letter prompts include relevant projects for AI to weave into content. Images are properly handled (copied or linked).
```

**Step 3: Run all tests**

```bash
./bin/jojo test
```

Expected: All tests PASS

**Step 4: Commit**

```bash
git add templates/projects.yml docs/plans/implementation_plan.md
git commit -m "docs: update projects template and mark Phase 6b complete"
```

---

## Task 14: End-to-End Manual Testing

**Files:**
- None (manual testing)

**Step 1: Create test inputs**

```bash
# Create projects.yml
cp templates/projects.yml inputs/projects.yml

# Edit with real or test data
$EDITOR inputs/projects.yml
```

**Step 2: Run full generation**

```bash
./bin/jojo generate -e "Test Company" -j test/fixtures/sample_job.txt
```

**Step 3: Verify outputs**

```bash
# Check that website includes projects
open employers/test-company/website/index.html

# Check that projects section exists
grep -A 20 "Relevant Work" employers/test-company/website/index.html

# Check resume mentions projects (if AI included them)
cat employers/test-company/resume.md

# Check cover letter mentions projects (if AI included them)
cat employers/test-company/cover_letter.md

# Check logs
tail employers/test-company/status_log.md
```

**Step 4: Clean up test data**

```bash
rm -rf employers/test-company
rm inputs/projects.yml
```

**Step 5: Document findings**

If any issues found, create new tasks. Otherwise, proceed to final commit.

**Step 6: Final commit**

```bash
git add -A
git commit -m "feat: complete Phase 6b portfolio highlights implementation"
```

---

## Summary

**What was built:**
- `ProjectLoader` - YAML loading with validation
- `ProjectSelector` - Skill-based matching algorithm
- Integration with WebsiteGenerator (projects section with images)
- Integration with ResumeGenerator (projects in AI prompt)
- Integration with CoverLetterGenerator (projects in AI prompt)
- Comprehensive test coverage (unit + integration)
- Updated templates and documentation

**Testing:**
- Unit tests for ProjectLoader (validation, graceful degradation)
- Unit tests for ProjectSelector (scoring, recency bonus, filtering)
- Integration tests for generators with projects
- Full workflow integration test

**Key features:**
- Skill-based matching with scoring
- Recency bonus for recent projects
- Image handling (local files and URLs)
- Graceful degradation when projects.yml missing
- Validation with clear error messages
- Support for optional metadata (year, context, role, links)

**Files created/modified:**
- 2 new classes (ProjectLoader, ProjectSelector)
- 3 generators modified (Website, Resume, CoverLetter)
- 2 prompts modified (Resume, CoverLetter)
- 1 template modified (default.html.erb)
- 7 test files created
- 5+ fixture files created
- Documentation updated

**Next steps:**
- Phase 6c: Interactive job description annotations
- Phase 6d: Recommendations carousel
- Phase 6e: FAQ accordion
