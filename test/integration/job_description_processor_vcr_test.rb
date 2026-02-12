require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/job_description/processor"

class JobDescriptionProcessorVcrTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-company")
    @ai_client = Minitest::Mock.new
    @application.create_directory!
  end

  def test_processes_job_description_from_file
    File.write("job_posting.txt", <<~TEXT)
      Senior Ruby Developer at Acme Corp

      We are looking for a senior Ruby developer with 5+ years experience.

      Requirements:
      - Ruby on Rails
      - PostgreSQL
      - Docker

      Nice to have:
      - Kubernetes
      - AWS
    TEXT

    @ai_client.expect(:reason, "# Senior Ruby Developer\n\nRequirements: Ruby on Rails, PostgreSQL, Docker", [String])
    @ai_client.expect(:generate_text, "company_name: Acme Corp\njob_title: Senior Ruby Developer\nrequired_skills:\n  - Ruby on Rails\n  - PostgreSQL\n  - Docker", [String])

    processor = Jojo::Commands::JobDescription::Processor.new(@application, @ai_client, verbose: false)
    result = processor.process("job_posting.txt")

    assert_includes result[:job_description], "Senior Ruby Developer"
    assert_includes result[:job_details], "Acme Corp"

    @ai_client.verify
  end

  def test_saves_job_description_and_details_files
    File.write("job.txt", "Ruby Developer role\nRequirements: Ruby, Rails")

    @ai_client.expect(:reason, "Clean job description content", [String])
    @ai_client.expect(:generate_text, "company_name: Test\njob_title: Developer", [String])

    processor = Jojo::Commands::JobDescription::Processor.new(@application, @ai_client, verbose: false)
    processor.process("job.txt")

    assert File.exist?(@application.job_description_path)
    assert File.exist?(@application.job_details_path)

    assert_equal "Clean job description content", File.read(@application.job_description_path)
    assert_includes File.read(@application.job_details_path), "company_name: Test"

    @ai_client.verify
  end

  def test_raises_error_for_nonexistent_file
    processor = Jojo::Commands::JobDescription::Processor.new(@application, @ai_client, verbose: false)

    error = assert_raises(Jojo::Commands::JobDescription::Processor::ProcessingError) do
      processor.process("nonexistent.txt")
    end

    assert_includes error.message, "File not found"
  end

  def test_does_not_save_raw_content_for_file_source
    File.write("job.txt", "Job description content")

    @ai_client.expect(:reason, "Clean content", [String])
    @ai_client.expect(:generate_text, "details", [String])

    processor = Jojo::Commands::JobDescription::Processor.new(@application, @ai_client, verbose: false)
    processor.process("job.txt")

    refute File.exist?(@application.job_description_raw_path)
    @ai_client.verify
  end
end
