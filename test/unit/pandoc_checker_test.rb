require "test_helper"
require "jojo/pandoc_checker"

class PandocCheckerTest < Minitest::Test
  def test_pandoc_available_returns_true_when_installed
    # Mock system call
    Jojo::PandocChecker.stub :system, true do
      assert Jojo::PandocChecker.available?
    end
  end

  def test_pandoc_available_returns_false_when_not_installed
    Jojo::PandocChecker.stub :system, false do
      refute Jojo::PandocChecker.available?
    end
  end

  def test_pandoc_version_returns_version_string
    version_output = "pandoc 3.1.11\n"
    Jojo::PandocChecker.stub :`, version_output do
      assert_equal "3.1.11", Jojo::PandocChecker.version
    end
  end

  def test_pandoc_version_returns_nil_when_not_installed
    Jojo::PandocChecker.stub :`, "" do
      assert_nil Jojo::PandocChecker.version
    end
  end

  def test_check_raises_error_when_not_installed
    Jojo::PandocChecker.stub :available?, false do
      error = assert_raises(Jojo::PandocChecker::PandocNotFoundError) do
        Jojo::PandocChecker.check!
      end
      assert_includes error.message, "Pandoc is not installed"
    end
  end

  def test_check_returns_true_when_installed
    Jojo::PandocChecker.stub :available?, true do
      assert Jojo::PandocChecker.check!
    end
  end
end
