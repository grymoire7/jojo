require_relative "../test_helper"
require_relative "../../lib/jojo/commands/resume/transformer"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/config"
require "yaml"

class ResumeTransformerVcrTest < JojoTest
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
    with_vcr("resume_transformer_filter_skills") do
      data = {"skills" => ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"]}

      @transformer.send(:filter_field, "skills", data)

      assert_kind_of Array, data["skills"]
      assert_operator data["skills"].length, :>, 0
      assert_operator data["skills"].length, :<=, 8

      data["skills"].each do |skill|
        assert_includes ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"], skill
      end
    end
  end

  def test_reorder_field_maintains_all_items_when_can_remove_is_false
    with_vcr("resume_transformer_reorder_experience") do
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
  end

  def test_reorder_field_allows_removal_when_can_remove_is_true
    with_vcr("resume_transformer_reorder_with_removal") do
      data = {"skills" => ["Ruby", "Python", "JavaScript", "Cobol", "Fortran"]}

      @transformer.send(:reorder_field, "skills", data, can_remove: true)

      assert_kind_of Array, data["skills"]
      assert_operator data["skills"].length, :>, 0
      assert_operator data["skills"].length, :<=, 5
    end
  end

  def test_rewrite_field_tailors_summary_to_job_description
    with_vcr("resume_transformer_rewrite_summary") do
      data = {"summary" => "Experienced software engineer with broad technical background across multiple domains"}

      original_summary = data["summary"]

      @transformer.send(:rewrite_field, "summary", data)

      assert_kind_of String, data["summary"]
      assert_operator data["summary"].length, :>, 0
      refute_equal original_summary, data["summary"]
    end
  end

  def test_raises_permission_violation_if_ai_removes_from_reorder_only_field
    with_vcr("resume_transformer_permission_violation") do
      transformer = Jojo::Commands::Resume::Transformer.new(
        ai_client: @ai_client,
        config: @config_hash,
        job_context: {
          job_description: "Looking ONLY for Ruby developers. No other languages."
        }
      )

      data = {"languages" => ["English", "Spanish", "French", "German", "Japanese"]}

      begin
        transformer.send(:reorder_field, "languages", data, can_remove: false)
        assert_equal 5, data["languages"].length
      rescue Jojo::PermissionViolation => e
        assert_includes e.message, "removed items"
      end
    end
  end
end
