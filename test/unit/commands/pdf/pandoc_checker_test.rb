# test/unit/commands/pdf/pandoc_checker_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/pandoc_checker"

class Jojo::Commands::Pdf::PandocCheckerTest < JojoTest
  # -- .available? --

  def test_available_returns_true_when_pandoc_is_installed
    Jojo::Commands::Pdf::PandocChecker.stub(:system, true) do
      _(Jojo::Commands::Pdf::PandocChecker.available?).must_equal true
    end
  end

  def test_available_returns_false_when_pandoc_is_not_installed
    Jojo::Commands::Pdf::PandocChecker.stub(:system, false) do
      _(Jojo::Commands::Pdf::PandocChecker.available?).must_equal false
    end
  end

  # -- .version --

  def test_version_returns_version_string_when_installed
    Jojo::Commands::Pdf::PandocChecker.stub(:available?, true) do
      Jojo::Commands::Pdf::PandocChecker.stub(:`, "pandoc 3.1.11\n") do
        _(Jojo::Commands::Pdf::PandocChecker.version).must_equal "3.1.11"
      end
    end
  end

  def test_version_returns_nil_when_not_installed
    Jojo::Commands::Pdf::PandocChecker.stub(:available?, false) do
      _(Jojo::Commands::Pdf::PandocChecker.version).must_be_nil
    end
  end

  # -- .check! --

  def test_check_raises_error_when_not_installed
    Jojo::Commands::Pdf::PandocChecker.stub(:available?, false) do
      error = assert_raises(Jojo::Commands::Pdf::PandocChecker::PandocNotFoundError) do
        Jojo::Commands::Pdf::PandocChecker.check!
      end
      _(error.message).must_include "Pandoc is not installed"
    end
  end

  def test_check_returns_true_when_installed
    Jojo::Commands::Pdf::PandocChecker.stub(:available?, true) do
      _(Jojo::Commands::Pdf::PandocChecker.check!).must_equal true
    end
  end
end
