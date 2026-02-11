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

      _(data["skills"]).must_be_kind_of Array
      _(data["skills"].length).must_be :>, 0
      _(data["skills"].length).must_be :<=, 8

      data["skills"].each do |skill|
        _(["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"]).must_include skill
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

      _(data["experience"].length).must_equal original_count
      _(data["experience"]).must_be_kind_of Array
      companies = data["experience"].map { |exp| exp["company"] }.sort
      _(companies).must_equal ["ConsultingCo", "StartupXYZ", "TechCorp"]
    end
  end

  def test_reorder_field_allows_removal_when_can_remove_is_true
    with_vcr("resume_transformer_reorder_with_removal") do
      data = {"skills" => ["Ruby", "Python", "JavaScript", "Cobol", "Fortran"]}

      @transformer.send(:reorder_field, "skills", data, can_remove: true)

      _(data["skills"]).must_be_kind_of Array
      _(data["skills"].length).must_be :>, 0
      _(data["skills"].length).must_be :<=, 5
    end
  end

  def test_rewrite_field_tailors_summary_to_job_description
    with_vcr("resume_transformer_rewrite_summary") do
      data = {"summary" => "Experienced software engineer with broad technical background across multiple domains"}

      original_summary = data["summary"]

      @transformer.send(:rewrite_field, "summary", data)

      _(data["summary"]).must_be_kind_of String
      _(data["summary"].length).must_be :>, 0
      _(data["summary"]).wont_equal original_summary
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
        _(data["languages"].length).must_equal 5
      rescue Jojo::PermissionViolation => e
        _(e.message).must_include "removed items"
      end
    end
  end
end
