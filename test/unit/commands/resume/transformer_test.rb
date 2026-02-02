# test/unit/commands/resume/transformer_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/resume/transformer"

describe Jojo::Commands::Resume::Transformer do
  before do
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

  it "initializes with required parameters" do
    _(@transformer).wont_be_nil
  end

  describe "#get_field" do
    it "gets top-level field" do
      data = {"skills" => ["Ruby", "Python"]}
      result = @transformer.send(:get_field, data, "skills")
      _(result).must_equal ["Ruby", "Python"]
    end

    it "gets nested field with dot notation" do
      data = {
        "experience" => [
          {"description" => "Led team"}
        ]
      }
      result = @transformer.send(:get_field, data, "experience.description")
      _(result).must_equal "Led team"
    end

    it "returns nil for missing field" do
      data = {"skills" => []}
      result = @transformer.send(:get_field, data, "nonexistent")
      _(result).must_be_nil
    end
  end

  describe "#set_field" do
    it "sets top-level field" do
      data = {"skills" => ["Ruby"]}
      @transformer.send(:set_field, data, "skills", ["Python"])
      _(data["skills"]).must_equal ["Python"]
    end

    it "sets field on all array items" do
      data = {
        "experience" => [
          {"description" => "old"},
          {"description" => "old"}
        ]
      }
      @transformer.send(:set_field, data, "experience.description", "new")
      _(data["experience"][0]["description"]).must_equal "new"
      _(data["experience"][1]["description"]).must_equal "new"
    end

    it "sets nested scalar field" do
      data = {"contact" => {"email" => "old@example.com"}}
      @transformer.send(:set_field, data, "contact.email", "new@example.com")
      _(data["contact"]["email"]).must_equal "new@example.com"
    end
  end

  describe "#filter_field" do
    it "filters array items using AI" do
      data = {"skills" => ["Ruby", "Python", "Java", "C++", "Go"]}

      # Mock AI to return indices [0, 1, 4] (keep Ruby, Python, Go)
      @ai_client.expect(:generate_text, "[0, 1, 4]", [String])

      @transformer.send(:filter_field, "skills", data)

      _(data["skills"]).must_equal ["Ruby", "Python", "Go"]
      @ai_client.verify
    end

    it "does nothing for non-array fields" do
      data = {"summary" => "Some text"}

      @transformer.send(:filter_field, "summary", data)

      _(data["summary"]).must_equal "Some text"
    end

    it "does nothing for missing fields" do
      data = {"skills" => ["Ruby"]}

      @transformer.send(:filter_field, "nonexistent", data)

      _(data["skills"]).must_equal ["Ruby"]
    end
  end

  describe "#reorder_field" do
    it "reorders array items using AI" do
      data = {"skills" => ["Ruby", "Python", "Java"]}

      # Mock AI to return reordered indices [2, 0, 1]
      @ai_client.expect(:generate_text, "[2, 0, 1]", [String])

      @transformer.send(:reorder_field, "skills", data, can_remove: true)

      _(data["skills"]).must_equal ["Java", "Ruby", "Python"]
      @ai_client.verify
    end

    it "raises error when LLM removes items from reorder-only field" do
      data = {"experience" => ["exp1", "exp2", "exp3"]}

      # Mock AI returns only 2 indices (violating reorder-only)
      @ai_client.expect(:generate_text, "[1, 0]", [String])

      error = assert_raises(Jojo::PermissionViolation) do
        @transformer.send(:reorder_field, "experience", data, can_remove: false)
      end

      _(error.message).must_include "removed items"
      _(error.message).must_include "experience"
    end

    it "raises error when LLM returns invalid indices" do
      data = {"experience" => ["exp1", "exp2", "exp3"]}

      # Mock AI returns invalid indices
      @ai_client.expect(:generate_text, "[5, 1, 2]", [String])

      error = assert_raises(Jojo::PermissionViolation) do
        @transformer.send(:reorder_field, "experience", data, can_remove: false)
      end

      _(error.message).must_include "invalid indices"
    end

    it "allows removal when can_remove is true" do
      data = {"skills" => ["Ruby", "Python", "Java"]}

      # Returns only 2 items - should be allowed
      @ai_client.expect(:generate_text, "[0, 2]", [String])

      @transformer.send(:reorder_field, "skills", data, can_remove: true)

      _(data["skills"]).must_equal ["Ruby", "Java"]
      @ai_client.verify
    end
  end

  describe "#rewrite_field" do
    it "rewrites text field using AI" do
      data = {"summary" => "Generic software engineer with broad experience"}

      tailored = "Ruby specialist with 10+ years of backend development"
      @ai_client.expect(:generate_text, tailored, [String])

      @transformer.send(:rewrite_field, "summary", data)

      _(data["summary"]).must_equal tailored
      @ai_client.verify
    end

    it "does nothing for non-string fields" do
      data = {"skills" => ["Ruby", "Python"]}

      @transformer.send(:rewrite_field, "skills", data)

      _(data["skills"]).must_equal ["Ruby", "Python"]
    end

    it "does nothing for missing fields" do
      data = {"summary" => "text"}

      @transformer.send(:rewrite_field, "nonexistent", data)

      _(data["summary"]).must_equal "text"
    end
  end

  describe "#transform" do
    before do
      @full_config = {
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
        config: @full_config,
        job_context: @job_context
      )
    end

    it "applies all transformations based on permissions" do
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
      _(result["skills"].length).must_equal 3
      # Experience reordered (all 3 preserved)
      _(result["experience"]).must_equal ["exp3", "exp2", "exp1"]
      # Summary rewritten
      _(result["summary"]).must_equal "Tailored summary"

      @ai_client.verify
    end

    it "skips fields without permissions" do
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
      _(result["name"]).must_equal "Jane Doe"
      _(result["email"]).must_equal "jane@example.com"
    end
  end
end
