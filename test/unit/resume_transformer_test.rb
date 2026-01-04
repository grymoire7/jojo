# test/unit/resume_transformer_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_transformer"

describe Jojo::ResumeTransformer do
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
    @transformer = Jojo::ResumeTransformer.new(
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
end
