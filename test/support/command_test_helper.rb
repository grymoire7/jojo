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

  def create_application_fixture(slug, files: {})
    FileUtils.mkdir_p("applications/#{slug}")
    files.each { |name, content| File.write("applications/#{slug}/#{name}", content) }
  end

  # Alias for backward compatibility during migration
  alias_method :create_employer_fixture, :create_application_fixture

  def create_inputs_fixture(files: {})
    FileUtils.mkdir_p("inputs")
    files.each { |name, content| File.write("inputs/#{name}", content) }
  end
end
