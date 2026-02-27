# test/unit/commands/resume/transformer_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/resume/transformer"

class Jojo::Commands::Resume::TransformerTest < JojoTest
  def setup
    super
    @ai_client = Minitest::Mock.new
    @config = {
      "resume_data" => {
        "permissions" => {
          "skills" => ["remove", "reorder"]
        }
      }
    }
    @job_context = {
      job_description: "Looking for Ruby developer with PostgreSQL experience"
    }
    @transformer = Jojo::Commands::Resume::Transformer.new(
      ai_client: @ai_client,
      config: @config,
      job_context: @job_context
    )
  end

  def test_initializes_with_required_parameters
    refute_nil @transformer
  end

  # -- get_field --

  def test_get_field_gets_top_level_field
    data = {"skills" => ["Ruby", "Python"]}
    result = @transformer.send(:get_field, data, "skills")
    assert_equal ["Ruby", "Python"], result
  end

  def test_get_field_gets_nested_field_with_dot_notation
    data = {
      "experience" => [
        {"description" => "Led team"}
      ]
    }
    result = @transformer.send(:get_field, data, "experience.description")
    assert_equal "Led team", result
  end

  def test_get_field_returns_nil_for_missing_field
    data = {"skills" => []}
    result = @transformer.send(:get_field, data, "nonexistent")
    assert_nil result
  end

  # -- set_field --

  def test_set_field_sets_top_level_field
    data = {"skills" => ["Ruby"]}
    @transformer.send(:set_field, data, "skills", ["Python"])
    assert_equal ["Python"], data["skills"]
  end

  def test_set_field_sets_field_on_all_array_items
    data = {
      "experience" => [
        {"description" => "old"},
        {"description" => "old"}
      ]
    }
    @transformer.send(:set_field, data, "experience.description", "new")
    assert_equal "new", data["experience"][0]["description"]
    assert_equal "new", data["experience"][1]["description"]
  end

  def test_set_field_sets_nested_scalar_field
    data = {"contact" => {"email" => "old@example.com"}}
    @transformer.send(:set_field, data, "contact.email", "new@example.com")
    assert_equal "new@example.com", data["contact"]["email"]
  end

  # -- filter_field --

  def test_filter_field_filters_array_items_using_ai
    data = {"skills" => ["Ruby", "Python", "Java", "C++", "Go"]}

    # Mock AI to return indices [0, 1, 4] (keep Ruby, Python, Go)
    @ai_client.expect(:generate_text, "[0, 1, 4]", [String])

    @transformer.send(:filter_field, "skills", data)

    assert_equal ["Ruby", "Python", "Go"], data["skills"]
    @ai_client.verify
  end

  def test_filter_field_filters_each_employers_technologies_independently
    data = {
      "experience" => [
        {"company" => "BenchPrep", "technologies" => ["Ruby", "Rails", "Docker", "OpenAI"]},
        {"company" => "Groupon", "technologies" => ["Python", "AWS", "Terraform"]}
      ]
    }

    # One AI call per employer, each with different technologies
    @ai_client.expect(:generate_text, "[0, 1]", [String])   # BenchPrep: keep Ruby, Rails
    @ai_client.expect(:generate_text, "[0, 2]", [String])   # Groupon: keep Python, Terraform

    @transformer.send(:filter_field, "experience.technologies", data)

    assert_equal ["Ruby", "Rails"], data["experience"][0]["technologies"]
    assert_equal ["Python", "Terraform"], data["experience"][1]["technologies"]
    @ai_client.verify
  end

  def test_filter_field_does_nothing_for_non_array_fields
    data = {"summary" => "Some text"}

    @transformer.send(:filter_field, "summary", data)

    assert_equal "Some text", data["summary"]
  end

  def test_filter_field_does_nothing_for_missing_fields
    data = {"skills" => ["Ruby"]}

    @transformer.send(:filter_field, "nonexistent", data)

    assert_equal ["Ruby"], data["skills"]
  end

  # -- reorder_field --

  def test_reorder_field_reorders_array_items_using_ai
    data = {"skills" => ["Ruby", "Python", "Java"]}

    # Mock AI to return reordered indices [2, 0, 1]
    @ai_client.expect(:generate_text, "[2, 0, 1]", [String])

    @transformer.send(:reorder_field, "skills", data, can_remove: true)

    assert_equal ["Java", "Ruby", "Python"], data["skills"]
    @ai_client.verify
  end

  def test_reorder_field_reorders_each_employers_technologies_independently
    data = {
      "experience" => [
        {"company" => "BenchPrep", "technologies" => ["Ruby", "Rails", "Docker"]},
        {"company" => "Groupon", "technologies" => ["Python", "AWS"]}
      ]
    }

    # One AI call per employer, each with different results
    @ai_client.expect(:generate_text, "[2, 0, 1]", [String])  # BenchPrep: Docker, Ruby, Rails
    @ai_client.expect(:generate_text, "[1, 0]", [String])     # Groupon: AWS, Python

    @transformer.send(:reorder_field, "experience.technologies", data, can_remove: true)

    assert_equal ["Docker", "Ruby", "Rails"], data["experience"][0]["technologies"]
    assert_equal ["AWS", "Python"], data["experience"][1]["technologies"]
    @ai_client.verify
  end

  def test_reorder_field_raises_error_when_llm_removes_items_from_reorder_only_field
    data = {"experience" => ["exp1", "exp2", "exp3"]}

    # Mock AI returns only 2 indices (violating reorder-only)
    @ai_client.expect(:generate_text, "[1, 0]", [String])

    error = assert_raises(Jojo::PermissionViolation) do
      @transformer.send(:reorder_field, "experience", data, can_remove: false)
    end

    assert_includes error.message, "removed items"
    assert_includes error.message, "experience"
  end

  def test_reorder_field_raises_error_when_llm_returns_invalid_indices
    data = {"experience" => ["exp1", "exp2", "exp3"]}

    # Mock AI returns invalid indices
    @ai_client.expect(:generate_text, "[5, 1, 2]", [String])

    error = assert_raises(Jojo::PermissionViolation) do
      @transformer.send(:reorder_field, "experience", data, can_remove: false)
    end

    assert_includes error.message, "invalid indices"
  end

  def test_reorder_field_allows_removal_when_can_remove_is_true
    data = {"skills" => ["Ruby", "Python", "Java"]}

    # Returns only 2 items - should be allowed
    @ai_client.expect(:generate_text, "[0, 2]", [String])

    @transformer.send(:reorder_field, "skills", data, can_remove: true)

    assert_equal ["Ruby", "Java"], data["skills"]
    @ai_client.verify
  end

  # -- rewrite_field --

  def test_rewrite_field_rewrites_each_array_item_individually
    data = {
      "experience" => [
        {"description" => "Led Ruby team at TechCorp building Rails APIs"},
        {"description" => "Built C++ document processing pipelines at Inso"}
      ]
    }

    @ai_client.expect(:generate_text, "Rails-focused Ruby engineer", [String])
    @ai_client.expect(:generate_text, "Document processing with C++", [String])

    @transformer.send(:rewrite_field, "experience.description", data)

    assert_equal "Rails-focused Ruby engineer", data["experience"][0]["description"]
    assert_equal "Document processing with C++", data["experience"][1]["description"]
    @ai_client.verify
  end

  def test_rewrite_field_prompt_prohibits_inventing_technologies_not_in_original
    data = {"summary" => "Ruby on Rails developer with Vue.js experience"}

    captured_prompt = nil
    mock_client = Object.new
    mock_client.define_singleton_method(:generate_text) do |prompt|
      captured_prompt = prompt
      "tailored result"
    end

    transformer = Jojo::Commands::Resume::Transformer.new(
      ai_client: mock_client,
      config: @config,
      job_context: @job_context
    )

    transformer.send(:rewrite_field, "summary", data)

    assert_match(/do not add|never add|only.*original|CRITICAL/i, captured_prompt)
  end

  def test_rewrite_field_rewrites_text_field_using_ai
    data = {"summary" => "Generic software engineer with broad experience"}

    tailored = "Ruby specialist with 10+ years of backend development"
    @ai_client.expect(:generate_text, tailored, [String])

    @transformer.send(:rewrite_field, "summary", data)

    assert_equal tailored, data["summary"]
    @ai_client.verify
  end

  def test_rewrite_field_does_nothing_for_non_string_fields
    data = {"skills" => ["Ruby", "Python"]}

    @transformer.send(:rewrite_field, "skills", data)

    assert_equal ["Ruby", "Python"], data["skills"]
  end

  def test_rewrite_field_does_nothing_for_missing_fields
    data = {"summary" => "text"}

    @transformer.send(:rewrite_field, "nonexistent", data)

    assert_equal "text", data["summary"]
  end

  # -- transform --

  def test_transform_applies_all_transformations_based_on_permissions
    setup_full_transformer

    data = {
      "skills" => ["Ruby", "Python", "Java", "C++"],
      "experience" => ["exp1", "exp2", "exp3"],
      "summary" => "Generic summary"
    }

    # Mock filter call for skills (remove + reorder)
    @ai_client.expect(:generate_text, "[0, 1, 2]", [String])
    # Mock reorder call for filtered skills
    @ai_client.expect(:generate_text, "[2, 0, 1]", [String])
    # Mock reorder call for experience (reorder only)
    @ai_client.expect(:generate_text, "[2, 1, 0]", [String])
    # Mock rewrite call for summary
    @ai_client.expect(:generate_text, "Tailored summary", [String])

    result = @full_transformer.transform(data)

    # Skills filtered and reordered
    assert_equal 3, result["skills"].length
    # Experience reordered (all 3 preserved)
    assert_equal ["exp3", "exp2", "exp1"], result["experience"]
    # Summary rewritten
    assert_equal "Tailored summary", result["summary"]

    @ai_client.verify
  end

  def test_transform_skips_fields_without_permissions
    setup_full_transformer

    data = {
      "skills" => ["Ruby"],
      "name" => "Jane Doe",
      "email" => "jane@example.com"
    }

    # Only skills has permissions
    @ai_client.expect(:generate_text, "[0]", [String])
    @ai_client.expect(:generate_text, "[0]", [String])

    result = @full_transformer.transform(data)

    # Read-only fields preserved exactly
    assert_equal "Jane Doe", result["name"]
    assert_equal "jane@example.com", result["email"]
  end

  private

  def setup_full_transformer
    full_config = {
      "resume_data" => {
        "permissions" => {
          "skills" => ["remove", "reorder"],
          "experience" => ["reorder"],
          "summary" => ["rewrite"]
        }
      }
    }
    @full_transformer = Jojo::Commands::Resume::Transformer.new(
      ai_client: @ai_client,
      config: full_config,
      job_context: @job_context
    )
  end
end
