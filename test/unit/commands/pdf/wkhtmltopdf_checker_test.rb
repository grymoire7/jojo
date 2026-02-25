# test/unit/commands/pdf/wkhtmltopdf_checker_test.rb
require_relative "../../../test_helper"
require_relative "../../../../lib/jojo/commands/pdf/wkhtmltopdf_checker"

class Jojo::Commands::Pdf::WkhtmltopdfCheckerTest < JojoTest
  # -- .available? --

  def test_available_returns_true_when_wkhtmltopdf_is_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:system, true) do
      assert_equal true, Jojo::Commands::Pdf::WkhtmltopdfChecker.available?
    end
  end

  def test_available_returns_false_when_wkhtmltopdf_is_not_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:system, false) do
      assert_equal false, Jojo::Commands::Pdf::WkhtmltopdfChecker.available?
    end
  end

  # -- .version --

  def test_version_returns_version_string_when_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, true) do
      Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:`, "wkhtmltopdf 0.12.6\n") do
        assert_equal "0.12.6", Jojo::Commands::Pdf::WkhtmltopdfChecker.version
      end
    end
  end

  def test_version_returns_nil_when_not_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, false) do
      assert_nil Jojo::Commands::Pdf::WkhtmltopdfChecker.version
    end
  end

  # -- .check! --

  def test_check_raises_error_when_not_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, false) do
      error = assert_raises(Jojo::Commands::Pdf::WkhtmltopdfChecker::WkhtmltopdfNotFoundError) do
        Jojo::Commands::Pdf::WkhtmltopdfChecker.check!
      end
      assert_includes error.message, "wkhtmltopdf is not installed"
    end
  end

  def test_check_returns_true_when_installed
    Jojo::Commands::Pdf::WkhtmltopdfChecker.stub(:available?, true) do
      assert_equal true, Jojo::Commands::Pdf::WkhtmltopdfChecker.check!
    end
  end
end
