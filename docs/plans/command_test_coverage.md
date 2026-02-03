# Command Test Coverage Improvement Plan

## Goal
Improve test coverage for command classes by adding dependency injection and comprehensive tests covering: guard failures, successful execution, logging, user output, error recovery.

## Pattern Established (Annotate Command)

### 1. Command changes
- Add `initialize` that accepts command-specific dependencies (e.g., `generator:`)
- Pass `**rest` to super for `ai_client:`, `employer:`, and options
```ruby
def initialize(cli, generator: nil, **rest)
  super(cli, **rest)
  @generator = generator
end
```

### 2. Test coverage checklist
For each command, verify tests exist for:
- [ ] Guard failures (employer not found, missing files, etc.)
- [ ] Successful execution (service/generator called correctly)
- [ ] Logging (`log()` called with expected step/tokens/status)
- [ ] User output (`say()` calls with correct messages)
- [ ] Error recovery (exception caught, error displayed, exit 1)
- [ ] Dependency creation when not injected

---

## Phase 1: Implement pattern for 3 more commands

### 1.1 Resume Command
- [ ] Add DI for generator in `lib/jojo/commands/resume/command.rb`
- [ ] Add comprehensive tests in `test/unit/commands/resume/command_test.rb`
- [ ] Verify all tests pass

### 1.2 Research Command
- [ ] Add DI for generator in `lib/jojo/commands/research/command.rb`
- [ ] Add comprehensive tests in `test/unit/commands/research/command_test.rb`
- [ ] Verify all tests pass

### 1.3 Cover Letter Command
- [ ] Add DI for generator in `lib/jojo/commands/cover_letter/command.rb`
- [ ] Add comprehensive tests in `test/unit/commands/cover_letter/command_test.rb`
- [ ] Verify all tests pass

---

## Phase 2: Evaluate helper extraction

After completing Phase 1, assess:
1. How much code is duplicated across the 4 test files?
2. Are the mock expectations consistent enough to generalize?
3. What would the helper API look like?

### Candidate extractions
```ruby
module CommandTestHelper
  def setup_temp_project        # tmpdir + config.yml
  def teardown_temp_project     # cleanup
  def create_employer_fixture(slug, files: {})
  def mock_employer(company_name:, **path_expectations)
end
```

Here's a minimal helper that covers the high-value cases:                                                                                                                                      
                                                                                                                                                                                                 
```ruby
  # test/support/command_test_helper.rb                                                                                                                                                          
  module CommandTestHelper                                                                                                                                                                       
    def setup_temp_project                                                                                                                                                                       
      @tmpdir = Dir.mktmpdir                                                                                                                                                                     
      @original_dir = Dir.pwd                                                                                                                                                                    
      Dir.chdir(@tmpdir)                                                                                                                                                                         
                                                                                                                                                                                                 
      File.write("config.yml", <<~YAML)                                                                                                                                                          
        seeker_name: "Test User"                                                                                                                                                                 
        base_url: "https://example.com"                                                                                                                                                          
        reasoning_ai_service: openai                                                                                                                                                             
        reasoning_ai_model: gpt-4                                                                                                                                                                
        text_generation_ai_service: openai                                                                                                                                                       
        text_generation_ai_model: gpt-4                                                                                                                                                          
      YAML
    end

    def teardown_temp_project                                                                                                                                                                    
      Dir.chdir(@original_dir)                                                                                                                                                                   
      FileUtils.rm_rf(@tmpdir)                                                                                                                                                                   
    end

    def create_employer_fixture(slug, files: {})                                                                                                                                                 
      FileUtils.mkdir_p("employers/#{slug}")                                                                                                                                                     
      files.each { |name, content| File.write("employers/#{slug}/#{name}", content) }                                                                                                            
    end

    def mock_employer(company_name:, annotations_path: nil, status_logger: nil)                                                                                                                  
      mock = Minitest::Mock.new                                                                                                                                                                  
      mock.expect(:artifacts_exist?, true)                                                                                                                                                       
      mock.expect(:company_name, company_name)                                                                                                                                                   
      mock.expect(:job_description_annotations_path, annotations_path) if annotations_path                                                                                                       
      mock.expect(:status_logger, status_logger) if status_logger                                                                                                                                
      mock
    end
  end
```

Usage would simplify the test to:                                                                                                                                                              

```ruby
  before do
    setup_temp_project
    create_employer_fixture("acme-corp", files: {
      "job_description.md" => "5+ years Python",
      "resume.md" => "7 years Python"
    })
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }
```

Decision checkpoint:
- [x] Review duplication across annotate, resume, research, cover_letter tests
- [x] Decide: extract helper now, or continue without it
- [x] Created `test/support/command_test_helper.rb`
- [x] Refactored 4 Phase 1 tests to use helper

---

## Phase 3: Complete remaining commands ✅

### 3.1 Branding Command
- [x] Add DI and tests

### 3.2 Website Command
- [x] Add DI and tests

### 3.3 Faq Command
- [x] Add DI and tests

### 3.4 Pdf Command
- [x] Add DI and tests

### 3.5 Job Description Command
- [x] Add DI and tests (uses `||=` pattern for employer)

### 3.6 New Command
- [x] Add tests (no DI needed - file system operations)

### 3.7 Setup Command
- [x] Add DI and tests (uses service)

---

## Commands without generators (lower priority)
- Version - trivial, no DI needed
- Test - runs other tests, no DI needed
- Interactive - REPL wrapper, complex to test

---

## Progress

| Command | DI Added | Tests Added | Verified |
|---------|----------|-------------|----------|
| Annotate | ✅ | ✅ | ✅ |
| Resume | ✅ | ✅ | ✅ |
| Research | ✅ | ✅ | ✅ |
| Cover Letter | ✅ | ✅ | ✅ |
| --- Phase 2 checkpoint --- | | | |
| Branding | ✅ | ✅ | ✅ |
| Website | ✅ | ✅ | ✅ |
| Faq | ✅ | ✅ | ✅ |
| Pdf | ✅ | ✅ | ✅ |
| Job Description | ✅ | ✅ | ✅ |
| New | N/A | ✅ | ✅ |
| Setup | ✅ | ✅ | ✅ |

## Phase 1 Complete - 376 tests passing (up from 347)
## Phase 3 Complete - 408 tests passing
