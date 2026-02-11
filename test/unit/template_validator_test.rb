require_relative "../test_helper"
require_relative "../../lib/jojo/template_validator"

class TemplateValidatorTest < JojoTest
  def test_appears_unchanged_returns_false_when_file_does_not_exist
    result = Jojo::TemplateValidator.appears_unchanged?("nonexistent.md")
    _(result).must_equal false
  end

  def test_appears_unchanged_returns_true_when_file_contains_marker
    File.write("test.md", "<!-- JOJO_TEMPLATE_PLACEHOLDER - Delete this line -->\nContent")

    result = Jojo::TemplateValidator.appears_unchanged?("test.md")
    _(result).must_equal true
  end

  def test_appears_unchanged_returns_false_when_file_does_not_contain_marker
    File.write("test.md", "# My Resume\nCustomized content")

    result = Jojo::TemplateValidator.appears_unchanged?("test.md")
    _(result).must_equal false
  end

  def test_validate_required_file_raises_error_when_required_file_is_missing
    err = assert_raises(Jojo::TemplateValidator::MissingInputError) do
      Jojo::TemplateValidator.validate_required_file!("inputs/nonexistent.md", "generic resume")
    end
    _(err.message).must_include "inputs/nonexistent.md not found"
    _(err.message).must_include "jojo setup"
  end

  def test_validate_required_file_does_not_raise_when_file_exists_without_marker
    File.write("test.md", "# Customized Resume")

    Jojo::TemplateValidator.validate_required_file!("test.md", "resume")
  end

  def test_warn_if_unchanged_returns_continue_when_file_does_not_contain_marker
    File.write("test.md", "# Customized Resume")

    result = Jojo::TemplateValidator.warn_if_unchanged("test.md", "resume")
    _(result).must_equal :continue
  end

  def test_warn_if_unchanged_returns_skip_when_file_does_not_exist
    result = Jojo::TemplateValidator.warn_if_unchanged("nonexistent.md", "resume")
    _(result).must_equal :skip
  end
end
