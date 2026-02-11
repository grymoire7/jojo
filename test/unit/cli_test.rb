require_relative "../test_helper"
require_relative "../../lib/jojo/cli"

class CLITest < JojoTest
  def test_exists
    _(defined?(Jojo::CLI)).wont_be_nil
  end

  def test_inherits_from_thor
    _(Jojo::CLI.ancestors).must_include Thor
  end

  def test_has_setup_command
    _(Jojo::CLI.commands.key?("setup")).must_equal true
  end

  def test_has_research_command
    _(Jojo::CLI.commands.key?("research")).must_equal true
  end

  def test_has_resume_command
    _(Jojo::CLI.commands.key?("resume")).must_equal true
  end

  def test_has_cover_letter_command
    _(Jojo::CLI.commands.key?("cover_letter")).must_equal true
  end

  def test_has_website_command
    _(Jojo::CLI.commands.key?("website")).must_equal true
  end

  def test_has_version_command
    _(Jojo::CLI.commands.key?("version")).must_equal true
  end
end
