# test/unit/commands/new/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/new/command"

describe Jojo::Commands::New::Command do
  include CommandTestHelper

  before do
    setup_temp_project
    create_inputs_fixture(files: {
      "resume_data.yml" => "name: Test User\n# Modified content"
    })
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }

  it "inherits from Base" do
    _(Jojo::Commands::New::Command.ancestors).must_include Jojo::Commands::Base
  end

  describe "validation" do
    it "exits when resume_data.yml is missing" do
      FileUtils.rm("inputs/resume_data.yml")

      @mock_cli.expect(:say, nil, [/inputs\/resume_data\.yml not found/, :red])

      command = Jojo::Commands::New::Command.new(@mock_cli, slug: "new-corp")

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
      @mock_cli.verify
    end
  end

  describe "guard failures" do
    it "exits if employer already exists" do
      create_employer_fixture("existing", files: {})

      @mock_cli.expect(:say, nil, [/already exists/, :yellow])

      command = Jojo::Commands::New::Command.new(@mock_cli, slug: "existing")

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
      @mock_cli.verify
    end
  end

  describe "successful execution" do
    it "creates employer directory" do
      @mock_cli.expect(:say, nil, ["Created application workspace: applications/new-corp", :green])
      @mock_cli.expect(:say, nil, ["\nNext step:", :cyan])
      @mock_cli.expect(:say, nil, ["  jojo job_description -s new-corp -j <job_file_or_url>", :white])

      command = Jojo::Commands::New::Command.new(@mock_cli, slug: "new-corp")
      command.execute

      _(Dir.exist?("applications/new-corp")).must_equal true
      @mock_cli.verify
    end

    it "shows next step instructions" do
      @mock_cli.expect(:say, nil, [String, :green])
      @mock_cli.expect(:say, nil, ["\nNext step:", :cyan])
      @mock_cli.expect(:say, nil, [/jojo job_description -s test-corp/, :white])

      command = Jojo::Commands::New::Command.new(@mock_cli, slug: "test-corp")
      command.execute

      @mock_cli.verify
    end
  end
end
