# test/unit/commands/resume/curation_service_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/resume/curation_service"

describe Jojo::Commands::Resume::CurationService do
  before do
    @ai_client = Minitest::Mock.new
    @config = {
      "resume_data" => {
        "permissions" => {
          "skills" => ["remove", "reorder"],
          "summary" => ["rewrite"]
        }
      }
    }
    @job_context = {
      job_description: "Looking for Ruby developer"
    }

    @service = Jojo::Commands::Resume::CurationService.new(
      ai_client: @ai_client,
      config: @config,
      resume_data_path: "test/fixtures/resume_data.yml",
      template_path: "test/fixtures/templates/resume_template.md.erb"
    )
  end

  it "curates resume from data using transformer and template" do
    # Mock transformer calls
    @ai_client.expect(:generate_text, "[0, 1, 2]", [String]) # filter
    @ai_client.expect(:generate_text, "[2, 1, 0]", [String]) # reorder
    @ai_client.expect(:generate_text, "Tailored Ruby developer summary", [String]) # rewrite

    result = @service.generate(@job_context)

    _(result).must_include "# Jane Doe"
    _(result).must_include "Tailored Ruby developer summary"
    _(result).must_include "Skills"

    @ai_client.verify
  end

  it "caches curated data for same job context" do
    cache_file = "test/fixtures/cached_resume_data.yml"
    FileUtils.rm_f(cache_file)

    service_with_cache = Jojo::Commands::Resume::CurationService.new(
      ai_client: @ai_client,
      config: @config,
      resume_data_path: "test/fixtures/resume_data.yml",
      template_path: "test/fixtures/templates/resume_template.md.erb",
      cache_path: cache_file
    )

    # First call - uses AI
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])
    @ai_client.expect(:generate_text, "Summary v1", [String])

    result1 = service_with_cache.generate(@job_context)
    _(result1).must_include "Summary v1"

    # Second call - uses cache (no AI calls)
    result2 = service_with_cache.generate(@job_context)
    _(result2).must_include "Summary v1"

    @ai_client.verify
    FileUtils.rm_f(cache_file)
  end
end
