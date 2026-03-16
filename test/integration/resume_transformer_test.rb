require_relative "../test_helper"
require_relative "../../lib/jojo/commands/resume/transformer"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/config"
require "yaml"

class ResumeTransformerTest < JojoTest
  def setup
    super
    @config = Jojo::Config.new(fixture_path("valid_config.yml"))
    @ai_client = Jojo::AIClient.new(@config, verbose: false)
    @config_hash = YAML.load_file(fixture_path("valid_config.yml"))
    @job_context = {
      job_description: "Looking for a Senior Ruby on Rails developer with PostgreSQL and Docker experience. Must have strong backend skills and experience with microservices architecture."
    }
    @transformer = Jojo::Commands::Resume::Transformer.new(
      ai_client: @ai_client,
      config: @config_hash,
      job_context: @job_context
    )
  end

  def test_filter_field_filters_skills_and_returns_valid_json_indices
    MockOpenAI.set_responses([{match: ".*", response: "[0, 6]"}])

    data = {"skills" => ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"]}

    @transformer.send(:filter_field, "skills", data)

    assert_kind_of Array, data["skills"]
    assert_operator data["skills"].length, :>, 0
    assert_operator data["skills"].length, :<=, 8

    data["skills"].each do |skill|
      assert_includes ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"], skill
    end
  end

  def test_reorder_field_maintains_all_items_when_can_remove_is_false
    MockOpenAI.set_responses([{match: ".*", response: "[0, 1, 2]"}])

    data = {
      "experience" => [
        {"company" => "TechCorp", "title" => "Senior Engineer", "description" => "Led Ruby on Rails team"},
        {"company" => "StartupXYZ", "title" => "Developer", "description" => "Built Python APIs"},
        {"company" => "ConsultingCo", "title" => "Junior Dev", "description" => "Frontend JavaScript work"}
      ]
    }

    original_count = data["experience"].length

    @transformer.send(:reorder_field, "experience", data, can_remove: false)

    assert_equal original_count, data["experience"].length
    assert_kind_of Array, data["experience"]
    companies = data["experience"].map { |exp| exp["company"] }.sort
    assert_equal ["ConsultingCo", "StartupXYZ", "TechCorp"], companies
  end

  def test_reorder_field_allows_removal_when_can_remove_is_true
    MockOpenAI.set_responses([{match: ".*", response: "[0, 2, 1, 3, 4]"}])

    data = {"skills" => ["Ruby", "Python", "JavaScript", "Cobol", "Fortran"]}

    @transformer.send(:reorder_field, "skills", data, can_remove: true)

    assert_kind_of Array, data["skills"]
    assert_operator data["skills"].length, :>, 0
    assert_operator data["skills"].length, :<=, 5
  end

  def test_rewrite_field_tailors_summary_to_job_description
    MockOpenAI.set_responses([{match: ".*", response: "Experienced software engineer with broad technical background across multiple domains"}])

    data = {"summary" => "Experienced software engineer with broad technical background across multiple domains"}

    @transformer.send(:rewrite_field, "summary", data)

    assert_kind_of String, data["summary"]
    assert_operator data["summary"].length, :>, 0
  end

  def test_raises_permission_violation_if_ai_removes_from_reorder_only_field
    # Response returns only 3 of 5 items — this triggers a PermissionViolation
    # because can_remove: false requires all items to be returned.
    MockOpenAI.set_responses([{match: ".*", response: "[0, 1, 2]"}])

    transformer = Jojo::Commands::Resume::Transformer.new(
      ai_client: @ai_client,
      config: @config_hash,
      job_context: {
        job_description: "Looking ONLY for Ruby developers. No other languages."
      }
    )

    data = {"languages" => ["English", "Spanish", "French", "German", "Japanese"]}

    error = assert_raises(Jojo::PermissionViolation) do
      transformer.send(:reorder_field, "languages", data, can_remove: false)
    end
    assert_includes error.message, "removed items"
  end
end
