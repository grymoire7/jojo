# test/unit/commands/console_output_test.rb
require_relative "../../test_helper"
require_relative "../../../lib/jojo/commands/console_output"

describe Jojo::Commands::ConsoleOutput do
  describe "#say" do
    it "outputs message to stdout" do
      output = Jojo::Commands::ConsoleOutput.new

      assert_output("Hello\n") { output.say("Hello") }
    end

    it "ignores color parameter" do
      output = Jojo::Commands::ConsoleOutput.new

      assert_output("Hello\n") { output.say("Hello", :green) }
    end

    it "suppresses output when quiet" do
      output = Jojo::Commands::ConsoleOutput.new(quiet: true)

      assert_output("") { output.say("Hello") }
    end
  end

  describe "#yes?" do
    it "returns true for 'y' input" do
      output = Jojo::Commands::ConsoleOutput.new

      $stdin = StringIO.new("y\n")
      result = nil
      assert_output(/Continue\?/) { result = output.yes?("Continue?") }
      $stdin = STDIN

      _(result).must_equal true
    end

    it "returns true for 'yes' input" do
      output = Jojo::Commands::ConsoleOutput.new

      $stdin = StringIO.new("yes\n")
      result = nil
      assert_output(/Continue\?/) { result = output.yes?("Continue?") }
      $stdin = STDIN

      _(result).must_equal true
    end

    it "returns false for 'n' input" do
      output = Jojo::Commands::ConsoleOutput.new

      $stdin = StringIO.new("n\n")
      result = nil
      assert_output(/Continue\?/) { result = output.yes?("Continue?") }
      $stdin = STDIN

      _(result).must_equal false
    end
  end
end
