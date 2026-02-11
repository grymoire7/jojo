# test/unit/commands/version/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/version/command"

class Jojo::Commands::Version::CommandTest < JojoTest
  def setup
    super
    @mock_cli = Minitest::Mock.new
  end

  def test_inherits_from_base
    assert_includes Jojo::Commands::Version::Command.ancestors, Jojo::Commands::Base
  end

  def test_outputs_version_string
    @mock_cli.expect(:say, nil, ["Jojo #{Jojo::VERSION}", :green])

    command = Jojo::Commands::Version::Command.new(@mock_cli)
    command.execute

    @mock_cli.verify
  end
end
