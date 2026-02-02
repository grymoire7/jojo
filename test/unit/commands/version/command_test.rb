# test/unit/commands/version/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/version/command"

describe Jojo::Commands::Version::Command do
  before do
    @mock_cli = Minitest::Mock.new
  end

  it "inherits from Base" do
    _(Jojo::Commands::Version::Command.ancestors).must_include Jojo::Commands::Base
  end

  it "outputs version string" do
    @mock_cli.expect(:say, nil, ["Jojo #{Jojo::VERSION}", :green])

    command = Jojo::Commands::Version::Command.new(@mock_cli)
    command.execute

    @mock_cli.verify
  end
end
