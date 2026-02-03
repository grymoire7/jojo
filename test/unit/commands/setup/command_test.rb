# test/unit/commands/setup/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/setup/command"

describe Jojo::Commands::Setup::Command do
  include CommandTestHelper

  before do
    setup_temp_project
    @mock_cli = Minitest::Mock.new
  end

  after { teardown_temp_project }

  it "inherits from Base" do
    _(Jojo::Commands::Setup::Command.ancestors).must_include Jojo::Commands::Base
  end

  describe "successful execution" do
    it "calls service.run" do
      @mock_service = Minitest::Mock.new
      @mock_service.expect(:run, nil)

      command = Jojo::Commands::Setup::Command.new(
        @mock_cli,
        service: @mock_service
      )
      command.execute

      @mock_service.verify
    end
  end

  describe "error recovery" do
    it "displays error message when service fails" do
      @mock_service = Minitest::Mock.new
      @mock_service.expect(:run, nil) { raise StandardError, "Configuration error" }

      @mock_cli.expect(:say, nil, ["Setup failed: Configuration error", :red])

      command = Jojo::Commands::Setup::Command.new(
        @mock_cli,
        service: @mock_service
      )

      assert_raises(SystemExit) { command.execute }
      @mock_cli.verify
    end

    it "exits with status 1 on error" do
      @mock_service = Minitest::Mock.new
      @mock_service.expect(:run, nil) { raise StandardError, "Error" }

      @mock_cli.expect(:say, nil, [String, :red])

      command = Jojo::Commands::Setup::Command.new(
        @mock_cli,
        service: @mock_service
      )

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 1
    end

    it "allows clean exit from service" do
      @mock_service = Minitest::Mock.new
      @mock_service.expect(:run, nil) { exit 0 }

      command = Jojo::Commands::Setup::Command.new(
        @mock_cli,
        service: @mock_service
      )

      error = assert_raises(SystemExit) { command.execute }
      _(error.status).must_equal 0
    end
  end
end
