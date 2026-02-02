# test/unit/commands/test/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/test/command"

describe Jojo::Commands::Test::Command do
  before do
    @mock_cli = Minitest::Mock.new
  end

  it "validates unsupported options" do
    @mock_cli.expect(:say, nil, [/Unsupported option/, :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    command = Jojo::Commands::Test::Command.new(@mock_cli, unit: false)

    assert_raises(SystemExit) { command.execute }
    @mock_cli.verify
  end
end
