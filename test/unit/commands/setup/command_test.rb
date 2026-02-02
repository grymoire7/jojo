# test/unit/commands/setup/command_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/setup/command"

describe Jojo::Commands::Setup::Command do
  it "inherits from Base" do
    _(Jojo::Commands::Setup::Command.ancestors).must_include Jojo::Commands::Base
  end
end
