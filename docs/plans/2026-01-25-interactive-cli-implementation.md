# Interactive CLI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an interactive TUI mode (`jojo` or `jojo i`) with a dashboard showing workflow state, staleness detection, and guided generation.

**Architecture:** A new `Interactive` class drives a main loop rendering a `Dashboard` and handling key events. A `Workflow` module defines the dependency graph and computes status for each artifact. Modal dialogs handle confirmations, inputs, and errors. State persistence via `.jojo_state` file.

**Tech Stack:** Ruby 3.4, Thor CLI, TTY toolkit (tty-box, tty-cursor, tty-reader, tty-screen), Minitest

---

## Phase 1: Dependencies & Foundation

### Task 1: Add TTY Gem Dependencies

**Files:**
- Modify: `Gemfile`

**Step 1: Add new gems to Gemfile**

Add after the existing `gem "tty-prompt"` line:

```ruby
gem "tty-box", "~> 0.7"          # Box drawing for TUI
gem "tty-cursor", "~> 0.7"       # Cursor movement
gem "tty-reader", "~> 0.9"       # Key input handling
gem "tty-screen", "~> 0.8"       # Terminal dimensions
```

**Step 2: Install dependencies**

Run: `bundle install`
Expected: All gems install successfully

**Step 3: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "$(cat <<'EOF'
feat(deps): add TTY gems for interactive CLI

Add tty-box, tty-cursor, tty-reader, tty-screen for TUI dashboard
EOF
)"
```

---

### Task 2: Add .jojo_state to .gitignore

**Files:**
- Modify: `.gitignore`

**Step 1: Add state file to gitignore**

Add to `.gitignore`:

```
.jojo_state
```

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore .jojo_state persistence file"
```

---

## Phase 2: Workflow Module

### Task 3: Create Workflow Constants

**Files:**
- Create: `lib/jojo/workflow.rb`
- Create: `test/unit/workflow_test.rb`

**Step 1: Write the failing test for STEPS constant**

```ruby
# test/unit/workflow_test.rb
require_relative "../test_helper"

describe Jojo::Workflow do
  describe "STEPS" do
    it "defines all workflow steps in order" do
      steps = Jojo::Workflow::STEPS

      _(steps).must_be_kind_of Array
      _(steps.length).must_equal 9
      _(steps.first[:key]).must_equal :job_description
      _(steps.last[:key]).must_equal :pdf
    end

    it "includes required fields for each step" do
      Jojo::Workflow::STEPS.each do |step|
        _(step).must_include :key
        _(step).must_include :label
        _(step).must_include :dependencies
        _(step).must_include :command
        _(step).must_include :paid
        _(step).must_include :output_file
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: FAIL with "uninitialized constant Jojo::Workflow"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/workflow.rb
module Jojo
  module Workflow
    STEPS = [
      {
        key: :job_description,
        label: "Job Description",
        dependencies: [],
        command: :new,
        paid: false,
        output_file: "job_description.md"
      },
      {
        key: :research,
        label: "Research",
        dependencies: [:job_description],
        command: :research,
        paid: true,
        output_file: "research.md"
      },
      {
        key: :resume,
        label: "Resume",
        dependencies: [:job_description, :research],
        command: :resume,
        paid: true,
        output_file: "resume.md"
      },
      {
        key: :cover_letter,
        label: "Cover Letter",
        dependencies: [:resume],
        command: :cover_letter,
        paid: true,
        output_file: "cover_letter.md"
      },
      {
        key: :annotations,
        label: "Annotations",
        dependencies: [:job_description],
        command: :annotate,
        paid: true,
        output_file: "job_description_annotations.json"
      },
      {
        key: :faq,
        label: "FAQ",
        dependencies: [:job_description, :resume],
        command: :faq,
        paid: true,
        output_file: "faq.json"
      },
      {
        key: :branding,
        label: "Branding Statement",
        dependencies: [:job_description, :resume, :research],
        command: :branding,
        paid: true,
        output_file: "branding.md"
      },
      {
        key: :website,
        label: "Website",
        dependencies: [:resume, :annotations, :faq],
        command: :website,
        paid: false,
        output_file: "website/index.html"
      },
      {
        key: :pdf,
        label: "PDF",
        dependencies: [:resume, :cover_letter],
        command: :pdf,
        paid: false,
        output_file: "resume.pdf"
      }
    ].freeze
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/workflow.rb test/unit/workflow_test.rb
git commit -m "$(cat <<'EOF'
feat(workflow): add STEPS constant with dependency graph

Define all 9 workflow steps with dependencies, commands, and paid flags
EOF
)"
```

---

### Task 4: Implement file_path helper

**Files:**
- Modify: `lib/jojo/workflow.rb`
- Modify: `test/unit/workflow_test.rb`

**Step 1: Write the failing test**

```ruby
describe ".file_path" do
  before do
    @employer = Minitest::Mock.new
    @employer.expect :base_path, "/tmp/test-employer"
  end

  it "returns full path for a step" do
    path = Jojo::Workflow.file_path(:resume, @employer)
    _(path).must_equal "/tmp/test-employer/resume.md"
  end

  it "handles nested paths like website" do
    path = Jojo::Workflow.file_path(:website, @employer)
    _(path).must_equal "/tmp/test-employer/website/index.html"
  end

  it "raises for unknown step" do
    _ { Jojo::Workflow.file_path(:unknown, @employer) }.must_raise ArgumentError
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: FAIL with "undefined method `file_path'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/workflow.rb` inside the module:

```ruby
def self.file_path(step_key, employer)
  step = STEPS.find { |s| s[:key] == step_key }
  raise ArgumentError, "Unknown step: #{step_key}" unless step

  File.join(employer.base_path, step[:output_file])
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/workflow.rb test/unit/workflow_test.rb
git commit -m "feat(workflow): add file_path helper method"
```

---

### Task 5: Implement status computation

**Files:**
- Modify: `lib/jojo/workflow.rb`
- Modify: `test/unit/workflow_test.rb`

**Step 1: Write the failing test**

```ruby
describe ".status" do
  before do
    @temp_dir = Dir.mktmpdir
    @employer = Minitest::Mock.new
    @employer.expect :base_path, @temp_dir
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  it "returns :blocked when dependencies missing" do
    # No files exist
    status = Jojo::Workflow.status(:resume, @employer)
    _(status).must_equal :blocked
  end

  it "returns :ready when dependencies exist but output missing" do
    # Create dependencies for resume: job_description and research
    FileUtils.touch(File.join(@temp_dir, "job_description.md"))
    FileUtils.touch(File.join(@temp_dir, "research.md"))

    @employer.expect :base_path, @temp_dir
    @employer.expect :base_path, @temp_dir
    @employer.expect :base_path, @temp_dir

    status = Jojo::Workflow.status(:resume, @employer)
    _(status).must_equal :ready
  end

  it "returns :generated when output exists and up-to-date" do
    # Create dependencies older than output
    FileUtils.touch(File.join(@temp_dir, "job_description.md"))
    FileUtils.touch(File.join(@temp_dir, "research.md"))
    sleep 0.01
    FileUtils.touch(File.join(@temp_dir, "resume.md"))

    @employer.expect :base_path, @temp_dir
    @employer.expect :base_path, @temp_dir
    @employer.expect :base_path, @temp_dir

    status = Jojo::Workflow.status(:resume, @employer)
    _(status).must_equal :generated
  end

  it "returns :stale when dependency is newer than output" do
    # Create output first
    FileUtils.touch(File.join(@temp_dir, "resume.md"))
    sleep 0.01
    # Then create newer dependencies
    FileUtils.touch(File.join(@temp_dir, "job_description.md"))
    FileUtils.touch(File.join(@temp_dir, "research.md"))

    @employer.expect :base_path, @temp_dir
    @employer.expect :base_path, @temp_dir
    @employer.expect :base_path, @temp_dir

    status = Jojo::Workflow.status(:resume, @employer)
    _(status).must_equal :stale
  end

  it "returns :ready for job_description (no dependencies)" do
    status = Jojo::Workflow.status(:job_description, @employer)
    _(status).must_equal :ready
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: FAIL with "undefined method `status'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/workflow.rb`:

```ruby
def self.status(step_key, employer)
  step = STEPS.find { |s| s[:key] == step_key }
  raise ArgumentError, "Unknown step: #{step_key}" unless step

  output_path = file_path(step_key, employer)
  output_exists = File.exist?(output_path)

  # Check if all dependencies are met
  deps_met = step[:dependencies].all? do |dep_key|
    File.exist?(file_path(dep_key, employer))
  end

  return :blocked unless deps_met
  return :ready unless output_exists

  # Check for staleness
  output_mtime = File.mtime(output_path)
  stale = step[:dependencies].any? do |dep_key|
    dep_path = file_path(dep_key, employer)
    File.exist?(dep_path) && File.mtime(dep_path) > output_mtime
  end

  stale ? :stale : :generated
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/workflow.rb test/unit/workflow_test.rb
git commit -m "$(cat <<'EOF'
feat(workflow): add status computation with staleness detection

Returns :blocked, :ready, :stale, or :generated based on file mtimes
EOF
)"
```

---

### Task 6: Implement all_statuses helper

**Files:**
- Modify: `lib/jojo/workflow.rb`
- Modify: `test/unit/workflow_test.rb`

**Step 1: Write the failing test**

```ruby
describe ".all_statuses" do
  before do
    @temp_dir = Dir.mktmpdir
    @employer = Minitest::Mock.new
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  it "returns status for all steps" do
    # Mock base_path for each status call (9 steps, each may call multiple times)
    27.times { @employer.expect :base_path, @temp_dir }

    statuses = Jojo::Workflow.all_statuses(@employer)

    _(statuses).must_be_kind_of Hash
    _(statuses.keys.length).must_equal 9
    _(statuses[:job_description]).must_equal :ready
    _(statuses[:resume]).must_equal :blocked
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: FAIL with "undefined method `all_statuses'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/workflow.rb`:

```ruby
def self.all_statuses(employer)
  STEPS.each_with_object({}) do |step, hash|
    hash[step[:key]] = status(step[:key], employer)
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/workflow.rb test/unit/workflow_test.rb
git commit -m "feat(workflow): add all_statuses helper"
```

---

### Task 7: Implement missing_dependencies helper

**Files:**
- Modify: `lib/jojo/workflow.rb`
- Modify: `test/unit/workflow_test.rb`

**Step 1: Write the failing test**

```ruby
describe ".missing_dependencies" do
  before do
    @temp_dir = Dir.mktmpdir
    @employer = Minitest::Mock.new
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  it "returns list of missing dependency labels" do
    5.times { @employer.expect :base_path, @temp_dir }

    missing = Jojo::Workflow.missing_dependencies(:resume, @employer)

    _(missing).must_include "Job Description"
    _(missing).must_include "Research"
  end

  it "returns empty array when all deps met" do
    FileUtils.touch(File.join(@temp_dir, "job_description.md"))
    FileUtils.touch(File.join(@temp_dir, "research.md"))

    5.times { @employer.expect :base_path, @temp_dir }

    missing = Jojo::Workflow.missing_dependencies(:resume, @employer)
    _(missing).must_be_empty
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: FAIL with "undefined method `missing_dependencies'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/workflow.rb`:

```ruby
def self.missing_dependencies(step_key, employer)
  step = STEPS.find { |s| s[:key] == step_key }
  raise ArgumentError, "Unknown step: #{step_key}" unless step

  step[:dependencies].reject do |dep_key|
    File.exist?(file_path(dep_key, employer))
  end.map do |dep_key|
    STEPS.find { |s| s[:key] == dep_key }[:label]
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/workflow.rb test/unit/workflow_test.rb
git commit -m "feat(workflow): add missing_dependencies helper"
```

---

### Task 8: Implement progress calculation

**Files:**
- Modify: `lib/jojo/workflow.rb`
- Modify: `test/unit/workflow_test.rb`

**Step 1: Write the failing test**

```ruby
describe ".progress" do
  before do
    @temp_dir = Dir.mktmpdir
    @employer = Minitest::Mock.new
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  it "returns 0 when nothing generated" do
    27.times { @employer.expect :base_path, @temp_dir }

    progress = Jojo::Workflow.progress(@employer)
    _(progress).must_equal 0
  end

  it "returns percentage of generated (non-stale) items" do
    # Create job_description (1 of 9 = ~11%)
    FileUtils.touch(File.join(@temp_dir, "job_description.md"))

    27.times { @employer.expect :base_path, @temp_dir }

    progress = Jojo::Workflow.progress(@employer)
    _(progress).must_equal 11  # 1/9 rounded
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: FAIL with "undefined method `progress'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/workflow.rb`:

```ruby
def self.progress(employer)
  statuses = all_statuses(employer)
  generated_count = statuses.values.count(:generated)
  total = STEPS.length

  ((generated_count.to_f / total) * 100).round
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/workflow.rb test/unit/workflow_test.rb
git commit -m "feat(workflow): add progress calculation"
```

---

### Task 9: Add require to main jojo.rb

**Files:**
- Modify: `lib/jojo.rb`

**Step 1: Add require for workflow module**

Find the requires section in `lib/jojo.rb` and add:

```ruby
require_relative "jojo/workflow"
```

**Step 2: Run all workflow tests to verify integration**

Run: `bundle exec ruby -Ilib:test test/unit/workflow_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/jojo.rb
git commit -m "chore: require workflow module in main jojo.rb"
```

---

## Phase 3: State Persistence

### Task 10: Create StatePersistence module

**Files:**
- Create: `lib/jojo/state_persistence.rb`
- Create: `test/unit/state_persistence_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/state_persistence_test.rb
require_relative "../test_helper"

describe Jojo::StatePersistence do
  before do
    @temp_dir = Dir.mktmpdir
    @state_file = File.join(@temp_dir, ".jojo_state")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe ".save_slug" do
    it "saves slug to .jojo_state file" do
      Jojo::StatePersistence.save_slug("acme-corp-dev")

      _(File.exist?(@state_file)).must_equal true
      _(File.read(@state_file).strip).must_equal "acme-corp-dev"
    end
  end

  describe ".load_slug" do
    it "returns nil when no state file exists" do
      slug = Jojo::StatePersistence.load_slug
      _(slug).must_be_nil
    end

    it "returns saved slug when state file exists" do
      File.write(@state_file, "acme-corp-dev")

      slug = Jojo::StatePersistence.load_slug
      _(slug).must_equal "acme-corp-dev"
    end

    it "strips whitespace from saved slug" do
      File.write(@state_file, "  acme-corp-dev  \n")

      slug = Jojo::StatePersistence.load_slug
      _(slug).must_equal "acme-corp-dev"
    end
  end

  describe ".clear" do
    it "removes the state file" do
      File.write(@state_file, "acme-corp-dev")

      Jojo::StatePersistence.clear

      _(File.exist?(@state_file)).must_equal false
    end

    it "does nothing if no state file exists" do
      Jojo::StatePersistence.clear  # Should not raise
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/state_persistence_test.rb`
Expected: FAIL with "uninitialized constant Jojo::StatePersistence"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/state_persistence.rb
module Jojo
  module StatePersistence
    STATE_FILE = ".jojo_state"

    def self.save_slug(slug)
      File.write(STATE_FILE, slug)
    end

    def self.load_slug
      return nil unless File.exist?(STATE_FILE)
      File.read(STATE_FILE).strip
    end

    def self.clear
      File.delete(STATE_FILE) if File.exist?(STATE_FILE)
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/state_persistence_test.rb`
Expected: PASS

**Step 5: Add require to jojo.rb**

Add to `lib/jojo.rb`:

```ruby
require_relative "jojo/state_persistence"
```

**Step 6: Commit**

```bash
git add lib/jojo/state_persistence.rb test/unit/state_persistence_test.rb lib/jojo.rb
git commit -m "$(cat <<'EOF'
feat(state): add StatePersistence module

Save/load last active application slug to .jojo_state
EOF
)"
```

---

## Phase 4: UI Components

### Task 11: Create Dashboard renderer - status icons

**Files:**
- Create: `lib/jojo/ui/dashboard.rb`
- Create: `test/unit/ui/dashboard_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/ui/dashboard_test.rb
require_relative "../../test_helper"

describe Jojo::UI::Dashboard do
  describe ".status_icon" do
    it "returns checkmark for generated" do
      _(Jojo::UI::Dashboard.status_icon(:generated)).must_equal "✅"
    end

    it "returns bread for stale" do
      _(Jojo::UI::Dashboard.status_icon(:stale)).must_equal "🍞"
    end

    it "returns circle for ready" do
      _(Jojo::UI::Dashboard.status_icon(:ready)).must_equal "⭕"
    end

    it "returns lock for blocked" do
      _(Jojo::UI::Dashboard.status_icon(:blocked)).must_equal "🔒"
    end
  end

  describe ".paid_icon" do
    it "returns money bag for paid commands" do
      _(Jojo::UI::Dashboard.paid_icon(true)).must_equal "💰"
    end

    it "returns empty string for free commands" do
      _(Jojo::UI::Dashboard.paid_icon(false)).must_equal "  "
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: FAIL with "uninitialized constant Jojo::UI"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/ui/dashboard.rb
module Jojo
  module UI
    class Dashboard
      STATUS_ICONS = {
        generated: "✅",
        stale: "🍞",
        ready: "⭕",
        blocked: "🔒"
      }.freeze

      def self.status_icon(status)
        STATUS_ICONS[status] || "?"
      end

      def self.paid_icon(is_paid)
        is_paid ? "💰" : "  "
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/ui/dashboard.rb test/unit/ui/dashboard_test.rb
git commit -m "feat(ui): add Dashboard status and paid icons"
```

---

### Task 12: Create Dashboard renderer - progress bar

**Files:**
- Modify: `lib/jojo/ui/dashboard.rb`
- Modify: `test/unit/ui/dashboard_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe ".progress_bar" do
  it "renders empty bar for 0%" do
    bar = Jojo::UI::Dashboard.progress_bar(0, width: 10)
    _(bar).must_equal "░░░░░░░░░░"
  end

  it "renders full bar for 100%" do
    bar = Jojo::UI::Dashboard.progress_bar(100, width: 10)
    _(bar).must_equal "██████████"
  end

  it "renders partial bar for 50%" do
    bar = Jojo::UI::Dashboard.progress_bar(50, width: 10)
    _(bar).must_equal "█████░░░░░"
  end

  it "renders partial bar for 70%" do
    bar = Jojo::UI::Dashboard.progress_bar(70, width: 10)
    _(bar).must_equal "███████░░░"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: FAIL with "undefined method `progress_bar'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/ui/dashboard.rb`:

```ruby
FILLED_CHAR = "█"
EMPTY_CHAR = "░"

def self.progress_bar(percent, width: 10)
  filled = (percent / 100.0 * width).round
  empty = width - filled

  FILLED_CHAR * filled + EMPTY_CHAR * empty
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/ui/dashboard.rb test/unit/ui/dashboard_test.rb
git commit -m "feat(ui): add Dashboard progress_bar renderer"
```

---

### Task 13: Create Dashboard renderer - workflow line

**Files:**
- Modify: `lib/jojo/ui/dashboard.rb`
- Modify: `test/unit/ui/dashboard_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe ".workflow_line" do
  it "renders a workflow line with number, label, paid icon, and status" do
    step = { key: :resume, label: "Resume", paid: true }
    line = Jojo::UI::Dashboard.workflow_line(3, step, :generated, width: 50)

    _(line).must_include "3."
    _(line).must_include "Resume"
    _(line).must_include "💰"
    _(line).must_include "✅"
  end

  it "pads label to align columns" do
    step = { key: :faq, label: "FAQ", paid: true }
    line = Jojo::UI::Dashboard.workflow_line(6, step, :ready, width: 50)

    # Label should be padded
    _(line).must_match(/FAQ\s+💰/)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: FAIL with "undefined method `workflow_line'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/ui/dashboard.rb`:

```ruby
def self.workflow_line(number, step, status, width: 54)
  label = step[:label]
  paid = paid_icon(step[:paid])
  status_str = status_icon(status)
  status_label = status.to_s.capitalize

  # Format: "  N. Label                    💰   ✅ Generated"
  label_width = 28
  padded_label = label.ljust(label_width)

  "  #{number}. #{padded_label}#{paid}   #{status_str} #{status_label}"
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/ui/dashboard.rb test/unit/ui/dashboard_test.rb
git commit -m "feat(ui): add Dashboard workflow_line renderer"
```

---

### Task 14: Create Dashboard full render method

**Files:**
- Modify: `lib/jojo/ui/dashboard.rb`
- Modify: `test/unit/ui/dashboard_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe ".render" do
  before do
    @temp_dir = Dir.mktmpdir
    @employer = Minitest::Mock.new
    @employer.expect :slug, "acme-corp-dev"
    @employer.expect :company_name, "Acme Corp"

    # Mock base_path calls for all_statuses (many calls due to status checks)
    50.times { @employer.expect :base_path, @temp_dir }
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  it "renders complete dashboard with header and workflow" do
    output = Jojo::UI::Dashboard.render(@employer)

    _(output).must_include "Jojo"
    _(output).must_include "acme-corp-dev"
    _(output).must_include "Acme Corp"
    _(output).must_include "1."
    _(output).must_include "Job Description"
    _(output).must_include "[q] Quit"
  end

  it "includes status legend" do
    output = Jojo::UI::Dashboard.render(@employer)

    _(output).must_include "✅Generated"
    _(output).must_include "🍞Stale"
    _(output).must_include "⭕Ready"
    _(output).must_include "🔒Blocked"
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: FAIL with "undefined method `render'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/ui/dashboard.rb`:

```ruby
def self.render(employer)
  require "tty-box"

  statuses = Jojo::Workflow.all_statuses(employer)
  width = 56

  lines = []

  # Header
  lines << "  Active: #{employer.slug}"
  lines << "  Company: #{employer.company_name}"
  lines << ""
  lines << "  Workflow" + " " * 29 + "Status"
  lines << "  " + "─" * 50

  # Workflow items
  Jojo::Workflow::STEPS.each_with_index do |step, idx|
    status = statuses[step[:key]]
    lines << workflow_line(idx + 1, step, status, width: width)
  end

  lines << ""
  lines << "  Status:  ✅Generated  🍞Stale  ⭕Ready  🔒Blocked"
  lines << ""
  lines << "  [1-9] Generate item    [a] All ready    [q] Quit"
  lines << "  [o] Open folder    [s] Switch application"

  TTY::Box.frame(
    lines.join("\n"),
    title: { top_left: " Jojo " },
    padding: [0, 1],
    border: :thick
  )
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dashboard_test.rb`
Expected: PASS

**Step 5: Add require to jojo.rb**

Add to `lib/jojo.rb`:

```ruby
require_relative "jojo/ui/dashboard"
```

**Step 6: Commit**

```bash
git add lib/jojo/ui/dashboard.rb test/unit/ui/dashboard_test.rb lib/jojo.rb
git commit -m "$(cat <<'EOF'
feat(ui): add Dashboard full render method

Renders complete TUI dashboard with TTY::Box frame
EOF
)"
```

---

### Task 15: Create Dialogs module - confirmation dialog

**Files:**
- Create: `lib/jojo/ui/dialogs.rb`
- Create: `test/unit/ui/dialogs_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/ui/dialogs_test.rb
require_relative "../../test_helper"

describe Jojo::UI::Dialogs do
  describe ".blocked_dialog" do
    it "renders dialog showing missing prerequisites" do
      output = Jojo::UI::Dialogs.blocked_dialog("Cover Letter", ["Resume"])

      _(output).must_include "Cover Letter"
      _(output).must_include "Cannot generate yet"
      _(output).must_include "Resume"
      _(output).must_include "[Esc] Back"
    end
  end

  describe ".ready_dialog" do
    it "renders dialog for ready item with inputs and output" do
      inputs = [
        { name: "resume.md", age: "2 hours ago" },
        { name: "job_description.md", age: nil }
      ]

      output = Jojo::UI::Dialogs.ready_dialog("Cover Letter", inputs, "cover_letter.md", paid: true)

      _(output).must_include "Cover Letter"
      _(output).must_include "Generate"
      _(output).must_include "💰"
      _(output).must_include "resume.md"
      _(output).must_include "2 hours ago"
      _(output).must_include "cover_letter.md"
      _(output).must_include "[Enter] Generate"
    end
  end

  describe ".generated_dialog" do
    it "renders dialog for already generated item" do
      output = Jojo::UI::Dialogs.generated_dialog("Cover Letter", "1 hour ago", paid: true)

      _(output).must_include "cover_letter.md already exists"
      _(output).must_include "1 hour ago"
      _(output).must_include "[r] Regenerate"
      _(output).must_include "💰"
      _(output).must_include "[v] View"
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dialogs_test.rb`
Expected: FAIL with "uninitialized constant Jojo::UI::Dialogs"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/ui/dialogs.rb
require "tty-box"

module Jojo
  module UI
    class Dialogs
      def self.blocked_dialog(label, missing_deps)
        lines = []
        lines << "  Cannot generate yet. Missing prerequisites:"
        lines << ""
        missing_deps.each do |dep|
          lines << "    • #{dep} (not generated)"
        end
        lines << ""
        lines << "  [Esc] Back"

        TTY::Box.frame(
          lines.join("\n"),
          title: { top_left: " #{label} " },
          padding: [0, 1],
          border: :thick
        )
      end

      def self.ready_dialog(label, inputs, output_file, paid: false)
        paid_str = paid ? " 💰" : ""

        lines = []
        lines << "  Generate #{label.downcase}?#{paid_str}"
        lines << ""
        lines << "  Inputs:"
        inputs.each do |input|
          age_str = input[:age] ? " (#{input[:age]})" : ""
          lines << "    • #{input[:name]}#{age_str}"
        end
        lines << ""
        lines << "  Output:"
        lines << "    • #{output_file}"
        lines << ""
        lines << "  [Enter] Generate    [Esc] Back"

        TTY::Box.frame(
          lines.join("\n"),
          title: { top_left: " #{label} " },
          padding: [0, 1],
          border: :thick
        )
      end

      def self.generated_dialog(label, age, paid: false)
        paid_str = paid ? " 💰" : ""
        output_file = label.downcase.gsub(" ", "_") + ".md"

        lines = []
        lines << "  #{output_file} already exists (generated #{age})"
        lines << ""
        lines << "  [r] Regenerate#{paid_str}    [v] View    [Esc] Back"

        TTY::Box.frame(
          lines.join("\n"),
          title: { top_left: " #{label} " },
          padding: [0, 1],
          border: :thick
        )
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dialogs_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/ui/dialogs.rb test/unit/ui/dialogs_test.rb
git commit -m "$(cat <<'EOF'
feat(ui): add Dialogs for blocked, ready, and generated states
EOF
)"
```

---

### Task 16: Add error and input dialogs

**Files:**
- Modify: `lib/jojo/ui/dialogs.rb`
- Modify: `test/unit/ui/dialogs_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe ".error_dialog" do
  it "renders error dialog with message" do
    output = Jojo::UI::Dialogs.error_dialog("Cover Letter", "API Error: Rate limit exceeded")

    _(output).must_include "Error"
    _(output).must_include "Cover letter generation failed"
    _(output).must_include "Rate limit exceeded"
    _(output).must_include "[r] Retry"
    _(output).must_include "[Esc] Back"
  end
end

describe ".input_dialog" do
  it "renders input dialog with prompt" do
    output = Jojo::UI::Dialogs.input_dialog("New Application", "Slug (e.g., acme-corp-senior-dev):")

    _(output).must_include "New Application"
    _(output).must_include "Slug"
    _(output).must_include "> "
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dialogs_test.rb`
Expected: FAIL with "undefined method `error_dialog'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/ui/dialogs.rb`:

```ruby
def self.error_dialog(label, error_message)
  lines = []
  lines << ""
  lines << "  #{label} generation failed:"
  lines << ""
  lines << "  #{error_message}"
  lines << ""
  lines << "  [r] Retry    [v] View full error    [Esc] Back"

  TTY::Box.frame(
    lines.join("\n"),
    title: { top_left: " Error " },
    padding: [0, 1],
    border: :thick
  )
end

def self.input_dialog(title, prompt)
  lines = []
  lines << ""
  lines << "  #{prompt}"
  lines << "  > "
  lines << ""

  TTY::Box.frame(
    lines.join("\n"),
    title: { top_left: " #{title} " },
    padding: [0, 1],
    border: :thick
  )
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/ui/dialogs_test.rb`
Expected: PASS

**Step 5: Add require to jojo.rb**

Add to `lib/jojo.rb`:

```ruby
require_relative "jojo/ui/dialogs"
```

**Step 6: Commit**

```bash
git add lib/jojo/ui/dialogs.rb test/unit/ui/dialogs_test.rb lib/jojo.rb
git commit -m "feat(ui): add error and input dialogs"
```

---

## Phase 5: Interactive Loop

### Task 17: Create Interactive class skeleton

**Files:**
- Create: `lib/jojo/interactive.rb`
- Create: `test/unit/interactive_test.rb`

**Step 1: Write the failing test**

```ruby
# test/unit/interactive_test.rb
require_relative "../test_helper"

describe Jojo::Interactive do
  describe "#initialize" do
    it "accepts optional slug parameter" do
      interactive = Jojo::Interactive.new(slug: "test-slug")
      _(interactive.slug).must_equal "test-slug"
    end

    it "loads slug from state persistence when not provided" do
      # This tests integration with StatePersistence
      original_dir = Dir.pwd
      temp_dir = Dir.mktmpdir
      Dir.chdir(temp_dir)

      File.write(".jojo_state", "saved-slug")
      interactive = Jojo::Interactive.new

      _(interactive.slug).must_equal "saved-slug"

      Dir.chdir(original_dir)
      FileUtils.rm_rf(temp_dir)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: FAIL with "uninitialized constant Jojo::Interactive"

**Step 3: Write minimal implementation**

```ruby
# lib/jojo/interactive.rb
require "tty-reader"
require "tty-cursor"
require "tty-screen"

module Jojo
  class Interactive
    attr_reader :slug

    def initialize(slug: nil)
      @slug = slug || StatePersistence.load_slug
      @reader = TTY::Reader.new
      @cursor = TTY::Cursor
      @running = false
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/interactive.rb test/unit/interactive_test.rb
git commit -m "feat(interactive): add Interactive class skeleton"
```

---

### Task 18: Add employer resolution

**Files:**
- Modify: `lib/jojo/interactive.rb`
- Modify: `test/unit/interactive_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe "#employer" do
  it "returns nil when no slug set" do
    interactive = Jojo::Interactive.new
    _(interactive.employer).must_be_nil
  end

  it "returns Employer instance when slug is set" do
    temp_dir = Dir.mktmpdir
    employers_dir = File.join(temp_dir, "employers", "test-slug")
    FileUtils.mkdir_p(employers_dir)

    original_dir = Dir.pwd
    Dir.chdir(temp_dir)

    interactive = Jojo::Interactive.new(slug: "test-slug")
    employer = interactive.employer

    _(employer).must_be_kind_of Jojo::Employer
    _(employer.slug).must_equal "test-slug"

    Dir.chdir(original_dir)
    FileUtils.rm_rf(temp_dir)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: FAIL with "undefined method `employer'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/interactive.rb`:

```ruby
def employer
  return nil unless @slug
  @employer ||= Employer.new(@slug)
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/interactive.rb test/unit/interactive_test.rb
git commit -m "feat(interactive): add employer resolution"
```

---

### Task 19: Add list_applications helper

**Files:**
- Modify: `lib/jojo/interactive.rb`
- Modify: `test/unit/interactive_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe "#list_applications" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    FileUtils.mkdir_p(@employers_dir)
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  it "returns empty array when no employers exist" do
    interactive = Jojo::Interactive.new
    _(interactive.list_applications).must_equal []
  end

  it "returns list of employer slugs" do
    FileUtils.mkdir_p(File.join(@employers_dir, "acme-corp"))
    FileUtils.mkdir_p(File.join(@employers_dir, "globex-inc"))

    interactive = Jojo::Interactive.new
    apps = interactive.list_applications

    _(apps).must_include "acme-corp"
    _(apps).must_include "globex-inc"
  end

  it "excludes non-directories" do
    FileUtils.mkdir_p(File.join(@employers_dir, "acme-corp"))
    File.write(File.join(@employers_dir, "some-file.txt"), "test")

    interactive = Jojo::Interactive.new
    apps = interactive.list_applications

    _(apps).must_equal ["acme-corp"]
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: FAIL with "undefined method `list_applications'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/interactive.rb`:

```ruby
def list_applications
  employers_path = File.join(Dir.pwd, "employers")
  return [] unless Dir.exist?(employers_path)

  Dir.children(employers_path)
    .select { |f| File.directory?(File.join(employers_path, f)) }
    .sort
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/interactive.rb test/unit/interactive_test.rb
git commit -m "feat(interactive): add list_applications helper"
```

---

### Task 20: Add switch_application method

**Files:**
- Modify: `lib/jojo/interactive.rb`
- Modify: `test/unit/interactive_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe "#switch_application" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    FileUtils.mkdir_p(File.join(@employers_dir, "new-app"))
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  it "updates slug and saves to state" do
    interactive = Jojo::Interactive.new(slug: "old-app")
    interactive.switch_application("new-app")

    _(interactive.slug).must_equal "new-app"
    _(Jojo::StatePersistence.load_slug).must_equal "new-app"
  end

  it "clears cached employer" do
    interactive = Jojo::Interactive.new(slug: "new-app")
    _old_employer = interactive.employer  # Cache it

    interactive.switch_application("new-app")
    # employer should be re-instantiated on next access
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: FAIL with "undefined method `switch_application'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/interactive.rb`:

```ruby
def switch_application(new_slug)
  @slug = new_slug
  @employer = nil  # Clear cached employer
  StatePersistence.save_slug(new_slug)
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/interactive.rb test/unit/interactive_test.rb
git commit -m "feat(interactive): add switch_application method"
```

---

### Task 21: Add run method with main loop structure

**Files:**
- Modify: `lib/jojo/interactive.rb`
- Modify: `test/unit/interactive_test.rb`

**Step 1: Write the failing test**

Add to test file:

```ruby
describe "#handle_key" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    FileUtils.mkdir_p(File.join(@employers_dir, "test-app"))
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  it "returns :quit for 'q' key" do
    interactive = Jojo::Interactive.new(slug: "test-app")
    result = interactive.handle_key("q")
    _(result).must_equal :quit
  end

  it "returns :switch for 's' key" do
    interactive = Jojo::Interactive.new(slug: "test-app")
    result = interactive.handle_key("s")
    _(result).must_equal :switch
  end

  it "returns :open for 'o' key" do
    interactive = Jojo::Interactive.new(slug: "test-app")
    result = interactive.handle_key("o")
    _(result).must_equal :open
  end

  it "returns :all for 'a' key" do
    interactive = Jojo::Interactive.new(slug: "test-app")
    result = interactive.handle_key("a")
    _(result).must_equal :all
  end

  it "returns step index for number keys 1-9" do
    interactive = Jojo::Interactive.new(slug: "test-app")
    _(interactive.handle_key("1")).must_equal 0
    _(interactive.handle_key("5")).must_equal 4
    _(interactive.handle_key("9")).must_equal 8
  end

  it "returns nil for unrecognized keys" do
    interactive = Jojo::Interactive.new(slug: "test-app")
    _(interactive.handle_key("x")).must_be_nil
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: FAIL with "undefined method `handle_key'"

**Step 3: Write minimal implementation**

Add to `lib/jojo/interactive.rb`:

```ruby
def handle_key(key)
  case key
  when "q", "Q"
    :quit
  when "s", "S"
    :switch
  when "o", "O"
    :open
  when "a", "A"
    :all
  when "n", "N"
    :new
  when "1".."9"
    key.to_i - 1  # Convert to 0-indexed
  else
    nil
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/jojo/interactive.rb test/unit/interactive_test.rb
git commit -m "feat(interactive): add handle_key method"
```

---

### Task 22: Add clear_screen and render helpers

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add helper methods**

Add to `lib/jojo/interactive.rb`:

```ruby
def clear_screen
  print @cursor.clear_screen
  print @cursor.move_to(0, 0)
end

def render_dashboard
  clear_screen
  puts UI::Dashboard.render(employer)
end

def render_welcome
  clear_screen
  lines = []
  lines << ""
  lines << "  Welcome! No applications yet."
  lines << ""
  lines << "  To get started, create your first application:"
  lines << ""
  lines << "  [n] New application    [q] Quit"

  puts TTY::Box.frame(
    lines.join("\n"),
    title: { top_left: " Jojo " },
    padding: [0, 1],
    border: :thick
  )
end
```

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add screen rendering helpers"
```

---

### Task 23: Add run method implementation

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add the run method**

Add to `lib/jojo/interactive.rb`:

```ruby
def run
  @running = true

  # Initial render
  if employer && File.exist?(employer.base_path)
    render_dashboard
  else
    render_welcome
  end

  while @running
    key = @reader.read_keypress

    action = handle_key(key)
    case action
    when :quit
      @running = false
      clear_screen
      puts "Goodbye!"
    when :switch
      handle_switch
    when :open
      handle_open
    when :all
      handle_generate_all
    when :new
      handle_new_application
    when Integer
      handle_step_selection(action) if employer
    end
  end
rescue TTY::Reader::InputInterrupt
  # Ctrl+C pressed
  @running = false
  clear_screen
  puts "Interrupted. Goodbye!"
end
```

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add main run loop"
```

---

### Task 24: Add step selection handler

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add handle_step_selection method**

Add to `lib/jojo/interactive.rb`:

```ruby
def handle_step_selection(step_index)
  return unless step_index >= 0 && step_index < Workflow::STEPS.length

  step = Workflow::STEPS[step_index]
  status = Workflow.status(step[:key], employer)

  case status
  when :blocked
    show_blocked_dialog(step)
  when :ready, :stale
    show_ready_dialog(step, status)
  when :generated
    show_generated_dialog(step)
  end
end

private

def show_blocked_dialog(step)
  missing = Workflow.missing_dependencies(step[:key], employer)

  clear_screen
  puts UI::Dialogs.blocked_dialog(step[:label], missing)

  # Wait for Escape
  loop do
    key = @reader.read_keypress
    break if key == "\e" || key == "\u001B"
  end

  render_dashboard
end

def show_ready_dialog(step, status)
  inputs = step[:dependencies].map do |dep_key|
    dep_step = Workflow::STEPS.find { |s| s[:key] == dep_key }
    path = Workflow.file_path(dep_key, employer)
    age = File.exist?(path) ? time_ago(File.mtime(path)) : nil
    { name: dep_step[:output_file], age: age }
  end

  clear_screen
  puts UI::Dialogs.ready_dialog(step[:label], inputs, step[:output_file], paid: step[:paid])

  loop do
    key = @reader.read_keypress
    case key
    when "\r", "\n"  # Enter
      execute_step(step)
      break
    when "\e", "\u001B"  # Escape
      break
    end
  end

  render_dashboard
end

def show_generated_dialog(step)
  path = Workflow.file_path(step[:key], employer)
  age = time_ago(File.mtime(path))

  clear_screen
  puts UI::Dialogs.generated_dialog(step[:label], age, paid: step[:paid])

  loop do
    key = @reader.read_keypress
    case key
    when "r", "R"
      execute_step(step)
      break
    when "v", "V"
      view_file(path)
      break
    when "\e", "\u001B"
      break
    end
  end

  render_dashboard
end

def time_ago(time)
  seconds = Time.now - time
  case seconds
  when 0..59
    "just now"
  when 60..3599
    "#{(seconds / 60).to_i} minutes ago"
  when 3600..86399
    "#{(seconds / 3600).to_i} hours ago"
  else
    "#{(seconds / 86400).to_i} days ago"
  end
end

def view_file(path)
  editor = ENV["EDITOR"] || "less"
  system(editor, path)
end
```

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add step selection handlers with dialogs"
```

---

### Task 25: Add execute_step method

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add execute_step method**

Add to `lib/jojo/interactive.rb`:

```ruby
def execute_step(step)
  clear_screen

  # Show generating indicator
  puts "Generating #{step[:label].downcase}..."
  puts "Press Ctrl+C to cancel"
  puts

  begin
    # Build the Thor CLI instance and invoke the command
    cli = CLI.new
    cli.options = { slug: @slug, overwrite: true, quiet: false }

    case step[:command]
    when :new
      puts "Use 'jojo new' command to create a new application"
    when :research
      cli.invoke(:research, [], slug: @slug, overwrite: true)
    when :resume
      cli.invoke(:resume, [], slug: @slug, overwrite: true)
    when :cover_letter
      cli.invoke(:cover_letter, [], slug: @slug, overwrite: true)
    when :annotate
      cli.invoke(:annotate, [], slug: @slug, overwrite: true)
    when :faq
      cli.invoke(:faq, [], slug: @slug, overwrite: true)
    when :branding
      cli.invoke(:branding, [], slug: @slug, overwrite: true)
    when :website
      cli.invoke(:website, [], slug: @slug, overwrite: true)
    when :pdf
      cli.invoke(:pdf, [], slug: @slug, overwrite: true)
    end

    puts
    puts "Done! Press any key to continue..."
    @reader.read_keypress
  rescue => e
    show_error_dialog(step, e.message)
  end
end

def show_error_dialog(step, error_message)
  clear_screen
  puts UI::Dialogs.error_dialog(step[:label], error_message)

  loop do
    key = @reader.read_keypress
    case key
    when "r", "R"
      execute_step(step)
      return
    when "\e", "\u001B"
      return
    end
  end
end
```

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add execute_step method with CLI invocation"
```

---

### Task 26: Add handle_switch method

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add handle_switch method**

Add to `lib/jojo/interactive.rb`:

```ruby
def handle_switch
  apps = list_applications
  return render_welcome if apps.empty?

  clear_screen

  lines = []
  lines << ""
  lines << "  Recent applications:"
  lines << ""

  apps.each_with_index do |app_slug, idx|
    next if idx >= 9  # Only show first 9

    # Get progress for this app
    app_employer = Employer.new(app_slug)
    if File.exist?(app_employer.base_path)
      progress = Workflow.progress(app_employer)
      progress_bar = UI::Dashboard.progress_bar(progress, width: 10)
      progress_str = progress == 100 ? "Done" : "#{progress}%"
      company = app_employer.company_name

      lines << "  #{idx + 1}. #{app_slug.ljust(25)} #{progress_bar}  #{progress_str}"
      lines << "     #{company}"
      lines << ""
    else
      lines << "  #{idx + 1}. #{app_slug}"
      lines << ""
    end
  end

  lines << "  [1-#{[apps.length, 9].min}] Select    [n] New application    [Esc] Back"

  puts TTY::Box.frame(
    lines.join("\n"),
    title: { top_left: " Switch Application " },
    padding: [0, 1],
    border: :thick
  )

  loop do
    key = @reader.read_keypress
    case key
    when "1".."9"
      idx = key.to_i - 1
      if idx < apps.length
        switch_application(apps[idx])
        render_dashboard
        return
      end
    when "n", "N"
      handle_new_application
      return
    when "\e", "\u001B"
      if employer
        render_dashboard
      else
        render_welcome
      end
      return
    end
  end
end
```

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add application switcher"
```

---

### Task 27: Add handle_new_application method

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add handle_new_application method**

Add to `lib/jojo/interactive.rb`:

```ruby
def handle_new_application
  clear_screen

  # Prompt for slug
  puts TTY::Box.frame(
    "\n  Slug (e.g., acme-corp-senior-dev):\n  > \n",
    title: { top_left: " New Application " },
    padding: [0, 1],
    border: :thick
  )

  # Move cursor into the input area
  print @cursor.up(3)
  print @cursor.forward(5)

  slug = @reader.read_line.strip
  return render_dashboard if slug.empty?

  clear_screen

  # Prompt for job source
  puts TTY::Box.frame(
    "\n  Job description source:\n\n  [u] URL    [f] File path    [p] Paste text    [Esc] Cancel\n",
    title: { top_left: " New Application " },
    padding: [0, 1],
    border: :thick
  )

  job_source = nil
  loop do
    key = @reader.read_keypress
    case key
    when "u", "U"
      job_source = prompt_for_input("Enter URL:")
      break if job_source
    when "f", "F"
      job_source = prompt_for_input("Enter file path:")
      break if job_source
    when "p", "P"
      job_source = prompt_for_paste
      break if job_source
    when "\e", "\u001B"
      render_dashboard if employer
      return
    end
  end

  return unless job_source

  # Create the application
  begin
    clear_screen
    puts "Creating application #{slug}..."
    puts

    cli = CLI.new
    cli.invoke(:new, [], slug: slug, job: job_source)

    switch_application(slug)
    puts
    puts "Application created! Press any key to continue..."
    @reader.read_keypress
    render_dashboard
  rescue => e
    puts "Error: #{e.message}"
    puts "Press any key to continue..."
    @reader.read_keypress
    render_welcome
  end
end

def prompt_for_input(prompt)
  clear_screen
  puts TTY::Box.frame(
    "\n  #{prompt}\n  > \n",
    title: { top_left: " New Application " },
    padding: [0, 1],
    border: :thick
  )

  print @cursor.up(3)
  print @cursor.forward(5)

  input = @reader.read_line.strip
  input.empty? ? nil : input
end

def prompt_for_paste
  clear_screen
  puts "Paste job description (end with Ctrl+D on empty line):"
  puts

  lines = []
  while (line = $stdin.gets)
    lines << line
  end

  text = lines.join
  text.empty? ? nil : text
rescue Interrupt
  nil
end
```

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add new application flow"
```

---

### Task 28: Add handle_open and handle_generate_all methods

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add remaining handler methods**

Add to `lib/jojo/interactive.rb`:

```ruby
def handle_open
  return unless employer

  path = employer.base_path
  if RUBY_PLATFORM.include?("darwin")
    system("open", path)
  elsif RUBY_PLATFORM.include?("linux")
    system("xdg-open", path)
  else
    puts "Cannot open folder on this platform"
    sleep 1
  end
end

def handle_generate_all
  return unless employer

  statuses = Workflow.all_statuses(employer)
  ready_steps = Workflow::STEPS.select { |s| [:ready, :stale].include?(statuses[s[:key]]) }

  return if ready_steps.empty?

  clear_screen
  puts "Generating all ready items..."
  puts

  ready_steps.each do |step|
    puts "→ #{step[:label]}..."
    execute_step_quietly(step)
  end

  puts
  puts "Done! Press any key to continue..."
  @reader.read_keypress
  render_dashboard
end

def execute_step_quietly(step)
  cli = CLI.new
  cli.options = { slug: @slug, overwrite: true, quiet: true }

  case step[:command]
  when :research
    cli.invoke(:research, [], slug: @slug, overwrite: true, quiet: true)
  when :resume
    cli.invoke(:resume, [], slug: @slug, overwrite: true, quiet: true)
  when :cover_letter
    cli.invoke(:cover_letter, [], slug: @slug, overwrite: true, quiet: true)
  when :annotate
    cli.invoke(:annotate, [], slug: @slug, overwrite: true, quiet: true)
  when :faq
    cli.invoke(:faq, [], slug: @slug, overwrite: true, quiet: true)
  when :branding
    cli.invoke(:branding, [], slug: @slug, overwrite: true, quiet: true)
  when :website
    cli.invoke(:website, [], slug: @slug, overwrite: true, quiet: true)
  when :pdf
    cli.invoke(:pdf, [], slug: @slug, overwrite: true, quiet: true)
  end
rescue => e
  puts "  Error: #{e.message}"
end
```

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add open folder and generate all handlers"
```

---

### Task 29: Add require and integration

**Files:**
- Modify: `lib/jojo.rb`

**Step 1: Add require for interactive module**

Add to `lib/jojo.rb`:

```ruby
require_relative "jojo/interactive"
```

**Step 2: Run tests to verify no regressions**

Run: `bundle exec ruby -Ilib:test test/unit/interactive_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/jojo.rb
git commit -m "chore: require interactive module in main jojo.rb"
```

---

## Phase 6: CLI Integration

### Task 30: Add interactive command to CLI

**Files:**
- Modify: `lib/jojo/cli.rb`

**Step 1: Add the interactive command**

Add to `lib/jojo/cli.rb` (after existing commands):

```ruby
desc "interactive", "Launch interactive dashboard mode"
method_option :slug, type: :string, aliases: "-s", desc: "Application slug to start with"
map "i" => :interactive
def interactive
  slug = options[:slug] || ENV["JOJO_EMPLOYER_SLUG"]
  Jojo::Interactive.new(slug: slug).run
end
```

**Step 2: Add default task**

Add near the top of the CLI class, after `class_option` declarations:

```ruby
def self.exit_on_failure?
  true
end

default_task :interactive
```

**Step 3: Commit**

```bash
git add lib/jojo/cli.rb
git commit -m "$(cat <<'EOF'
feat(cli): add interactive command as default task

Running 'jojo' with no args or 'jojo i' launches interactive mode
EOF
)"
```

---

## Phase 7: Integration Testing

### Task 31: Create integration test for interactive mode

**Files:**
- Create: `test/integration/interactive_integration_test.rb`

**Step 1: Write integration test**

```ruby
# test/integration/interactive_integration_test.rb
require_relative "../test_helper"

describe "Interactive Mode Integration" do
  before do
    @temp_dir = Dir.mktmpdir
    @employers_dir = File.join(@temp_dir, "employers")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe "with no applications" do
    it "shows welcome screen" do
      interactive = Jojo::Interactive.new
      _(interactive.employer).must_be_nil
      _(interactive.list_applications).must_be_empty
    end
  end

  describe "with existing application" do
    before do
      @slug = "test-company-dev"
      app_dir = File.join(@employers_dir, @slug)
      FileUtils.mkdir_p(app_dir)
      File.write(File.join(app_dir, "job_description.md"), "Test job")
      File.write(File.join(app_dir, "job_details.yml"), "company_name: Test Company\njob_title: Developer")
    end

    it "loads application state" do
      Jojo::StatePersistence.save_slug(@slug)

      interactive = Jojo::Interactive.new
      _(interactive.slug).must_equal @slug
      _(interactive.employer).wont_be_nil
      _(interactive.employer.company_name).must_equal "Test Company"
    end

    it "computes workflow status correctly" do
      interactive = Jojo::Interactive.new(slug: @slug)
      employer = interactive.employer

      statuses = Jojo::Workflow.all_statuses(employer)

      _(statuses[:job_description]).must_equal :generated
      _(statuses[:research]).must_equal :ready  # dependency met
      _(statuses[:resume]).must_equal :blocked  # needs research
    end
  end

  describe "staleness detection" do
    before do
      @slug = "stale-test"
      app_dir = File.join(@employers_dir, @slug)
      FileUtils.mkdir_p(app_dir)

      # Create job_description first
      File.write(File.join(app_dir, "job_description.md"), "Job")
      sleep 0.01

      # Create research
      File.write(File.join(app_dir, "research.md"), "Research")
      sleep 0.01

      # Create resume
      File.write(File.join(app_dir, "resume.md"), "Resume")
    end

    it "detects when resume is up-to-date" do
      interactive = Jojo::Interactive.new(slug: @slug)
      status = Jojo::Workflow.status(:resume, interactive.employer)
      _(status).must_equal :generated
    end

    it "detects when resume becomes stale" do
      # Touch job_description to make it newer
      sleep 0.01
      app_dir = File.join(@employers_dir, @slug)
      FileUtils.touch(File.join(app_dir, "job_description.md"))

      interactive = Jojo::Interactive.new(slug: @slug)
      status = Jojo::Workflow.status(:resume, interactive.employer)
      _(status).must_equal :stale
    end
  end
end
```

**Step 2: Run integration test**

Run: `bundle exec ruby -Ilib:test test/integration/interactive_integration_test.rb`
Expected: PASS

**Step 3: Commit**

```bash
git add test/integration/interactive_integration_test.rb
git commit -m "test(integration): add interactive mode integration tests"
```

---

## Phase 8: Final Polish

### Task 32: Add spinner for generation

**Files:**
- Modify: `lib/jojo/interactive.rb`

**Step 1: Add spinner animation**

Add constant at top of class:

```ruby
SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"].freeze
```

Update `execute_step` to use spinner (optional enhancement).

**Step 2: Commit**

```bash
git add lib/jojo/interactive.rb
git commit -m "feat(interactive): add spinner frames for generation indicator"
```

---

### Task 33: Run full test suite

**Step 1: Run all unit tests**

Run: `bundle exec rake test:unit`
Expected: All tests pass

**Step 2: Run all integration tests**

Run: `bundle exec rake test:integration`
Expected: All tests pass

**Step 3: Run standard linter**

Run: `bundle exec standardrb --fix`
Expected: No violations or all auto-fixed

**Step 4: Commit any lint fixes**

```bash
git add -A
git commit -m "style: fix standardrb violations"
```

---

### Task 34: Manual testing

**Step 1: Test with no applications**

Run: `bundle exec bin/jojo`
Expected: Welcome screen appears, can create new application

**Step 2: Test with existing application**

Run: `bundle exec bin/jojo -s existing-app-slug`
Expected: Dashboard shows workflow status for that application

**Step 3: Test keyboard navigation**

- Press number keys to select items
- Press 'q' to quit
- Press 's' to switch applications
- Press 'o' to open folder

**Step 4: Test generation flow**

- Select a "ready" item
- Press Enter to generate
- Verify generation completes

---

### Task 35: Final commit and summary

**Step 1: Review all changes**

Run: `git log --oneline -20`

**Step 2: Create final summary commit if needed**

If there are uncommitted changes:

```bash
git add -A
git commit -m "$(cat <<'EOF'
feat(interactive): complete interactive CLI mode implementation

Adds TUI dashboard with:
- Workflow visualization with status icons
- Staleness detection via file mtimes
- Application switching with progress bars
- Modal dialogs for generation confirmation
- State persistence across sessions
EOF
)"
```

---

## Summary

This plan implements the interactive CLI in 35 bite-sized tasks across 8 phases:

1. **Dependencies & Foundation** - Add TTY gems, gitignore state file
2. **Workflow Module** - Dependency graph, status computation, staleness detection
3. **State Persistence** - Save/load last active application
4. **UI Components** - Dashboard rendering, dialogs for all states
5. **Interactive Loop** - Main event loop, key handling, step selection
6. **CLI Integration** - Add `jojo` and `jojo i` entry points
7. **Integration Testing** - End-to-end workflow tests
8. **Final Polish** - Spinner, linting, manual testing

Each task follows TDD: write failing test → implement → verify → commit.
