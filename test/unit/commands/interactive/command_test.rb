# test/unit/commands/interactive/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/interactive/command"

class Jojo::Commands::Interactive::CommandTest < JojoTest
  def test_initializes_with_options
    mock_cli = Minitest::Mock.new
    command = Jojo::Commands::Interactive::Command.new(mock_cli, slug: "test-corp")
    assert_equal "test-corp", command.options[:slug]
  end
end
