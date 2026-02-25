require_relative "../test_helper"
require_relative "../../lib/jojo/cli"

class CLITest < JojoTest
  def test_exists
    refute_nil defined?(Jojo::CLI)
  end

  def test_inherits_from_thor
    assert_includes Jojo::CLI.ancestors, Thor
  end

  def test_has_configure_command
    assert_equal true, Jojo::CLI.commands.key?("configure")
  end

  def test_has_research_command
    assert_equal true, Jojo::CLI.commands.key?("research")
  end

  def test_has_resume_command
    assert_equal true, Jojo::CLI.commands.key?("resume")
  end

  def test_has_cover_letter_command
    assert_equal true, Jojo::CLI.commands.key?("cover_letter")
  end

  def test_has_website_command
    assert_equal true, Jojo::CLI.commands.key?("website")
  end

  def test_has_version_command
    assert_equal true, Jojo::CLI.commands.key?("version")
  end
end
