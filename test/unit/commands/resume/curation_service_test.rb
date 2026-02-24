# test/unit/commands/resume/curation_service_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/resume/curation_service"

class Jojo::Commands::Resume::CurationServiceTest < JojoTest
  def setup
    super
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
      resume_data_path: fixture_path("resume_data.yml"),
      template_path: fixture_path("templates/resume_template.md.erb")
    )
  end

  def test_curates_resume_from_data_using_transformer_and_template
    # Mock transformer calls
    @ai_client.expect(:generate_text, "[0, 1, 2]", [String]) # filter
    @ai_client.expect(:generate_text, "[2, 1, 0]", [String]) # reorder
    @ai_client.expect(:generate_text, "Tailored Ruby developer summary", [String]) # rewrite

    result = @service.generate(@job_context)

    assert_includes result, "# Jane Doe"
    assert_includes result, "Tailored Ruby developer summary"
    assert_includes result, "Skills"

    @ai_client.verify
  end

  def test_overwrite_bypasses_cache_and_reruns_ai
    cache_file = File.join(@tmpdir, "cached_resume_data.yml")

    service = Jojo::Commands::Resume::CurationService.new(
      ai_client: @ai_client,
      config: @config,
      resume_data_path: fixture_path("resume_data.yml"),
      template_path: fixture_path("templates/resume_template.md.erb"),
      cache_path: cache_file,
      overwrite: true
    )

    # First call - runs AI and writes cache
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])
    @ai_client.expect(:generate_text, "Summary v1", [String])
    service.generate(@job_context)

    # Second call - overwrite: true must bypass cache and run AI again
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])
    @ai_client.expect(:generate_text, "Summary v2", [String])
    result2 = service.generate(@job_context)

    assert_includes result2, "Summary v2"
    @ai_client.verify
  end

  def test_overwrite_replaces_corrupt_cache_on_disk
    cache_file = File.join(@tmpdir, "cached_resume_data.yml")
    File.write(cache_file, "corrupt: data with react hallucination\n")

    service = Jojo::Commands::Resume::CurationService.new(
      ai_client: @ai_client,
      config: @config,
      resume_data_path: fixture_path("resume_data.yml"),
      template_path: fixture_path("templates/resume_template.md.erb"),
      cache_path: cache_file,
      overwrite: true
    )

    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])
    @ai_client.expect(:generate_text, "Fresh summary", [String])

    result = service.generate(@job_context)

    assert_includes result, "Fresh summary"
    @ai_client.verify
  end

  def test_caches_curated_data_for_same_job_context
    cache_file = File.join(@tmpdir, "cached_resume_data.yml")

    service_with_cache = Jojo::Commands::Resume::CurationService.new(
      ai_client: @ai_client,
      config: @config,
      resume_data_path: fixture_path("resume_data.yml"),
      template_path: fixture_path("templates/resume_template.md.erb"),
      cache_path: cache_file
    )

    # First call - uses AI
    @ai_client.expect(:generate_text, "[0, 1]", [String])
    @ai_client.expect(:generate_text, "[1, 0]", [String])
    @ai_client.expect(:generate_text, "Summary v1", [String])

    result1 = service_with_cache.generate(@job_context)
    assert_includes result1, "Summary v1"

    # Second call - uses cache (no AI calls)
    result2 = service_with_cache.generate(@job_context)
    assert_includes result2, "Summary v1"

    @ai_client.verify
  end
end
