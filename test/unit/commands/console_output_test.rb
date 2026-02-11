# test/unit/commands/console_output_test.rb
require_relative "../../test_helper"
require_relative "../../../lib/jojo/commands/console_output"

class Jojo::Commands::ConsoleOutputTest < JojoTest
  # --- #say ---

  def test_say_outputs_message_to_stdout
    output = Jojo::Commands::ConsoleOutput.new

    assert_output("Hello\n") { output.say("Hello") }
  end

  def test_say_ignores_color_parameter
    output = Jojo::Commands::ConsoleOutput.new

    assert_output("Hello\n") { output.say("Hello", :green) }
  end

  def test_say_suppresses_output_when_quiet
    output = Jojo::Commands::ConsoleOutput.new(quiet: true)

    assert_output("") { output.say("Hello") }
  end

  # --- #yes? ---

  def test_yes_returns_true_for_y_input
    output = Jojo::Commands::ConsoleOutput.new

    $stdin = StringIO.new("y\n")
    result = nil
    assert_output(/Continue\?/) { result = output.yes?("Continue?") }
    $stdin = STDIN

    _(result).must_equal true
  end

  def test_yes_returns_true_for_yes_input
    output = Jojo::Commands::ConsoleOutput.new

    $stdin = StringIO.new("yes\n")
    result = nil
    assert_output(/Continue\?/) { result = output.yes?("Continue?") }
    $stdin = STDIN

    _(result).must_equal true
  end

  def test_yes_returns_false_for_n_input
    output = Jojo::Commands::ConsoleOutput.new

    $stdin = StringIO.new("n\n")
    result = nil
    assert_output(/Continue\?/) { result = output.yes?("Continue?") }
    $stdin = STDIN

    _(result).must_equal false
  end
end
