require_relative "../test_helper"
require_relative "../../lib/jojo/application"
require_relative "../../lib/jojo/commands/job_description/processor"

class JobDescriptionProcessorVcrTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-company")
    @ai_client = Minitest::Mock.new
    @processor = Jojo::Commands::JobDescription::Processor.new(@application, @ai_client, verbose: false)

    @application.create_directory!
  end

  # URL processing tests can be added here with VCR cassettes
end
