require_relative "../test_helper"
require_relative "../../lib/jojo/template_validator"

class TemplateValidatorTest < JojoTest
  def test_appears_unchanged_returns_false_when_file_does_not_exist
    result = Jojo::TemplateValidator.appears_unchanged?("nonexistent.md")
    assert_equal false, result
  end

  def test_appears_unchanged_returns_true_when_file_contains_marker
    File.write("test.md", "<!-- JOJO_TEMPLATE_PLACEHOLDER - Delete this line -->\nContent")

    result = Jojo::TemplateValidator.appears_unchanged?("test.md")
    assert_equal true, result
  end

  def test_appears_unchanged_returns_false_when_file_does_not_contain_marker
    File.write("test.md", "# My Resume\nCustomized content")

    result = Jojo::TemplateValidator.appears_unchanged?("test.md")
    assert_equal false, result
  end

  def test_validate_required_file_raises_error_when_required_file_is_missing
    err = assert_raises(Jojo::TemplateValidator::MissingInputError) do
      Jojo::TemplateValidator.validate_required_file!("inputs/nonexistent.md", "generic resume")
    end
    assert_includes err.message, "inputs/nonexistent.md not found"
    assert_includes err.message, "jojo setup"
  end

  def test_validate_required_file_does_not_raise_when_file_exists_without_marker
    File.write("test.md", "# Customized Resume")

    Jojo::TemplateValidator.validate_required_file!("test.md", "resume")
  end

  def test_warn_if_unchanged_returns_continue_when_file_does_not_contain_marker
    File.write("test.md", "# Customized Resume")

    result = Jojo::TemplateValidator.warn_if_unchanged("test.md", "resume")
    assert_equal :continue, result
  end

  def test_warn_if_unchanged_returns_skip_when_file_does_not_exist
    result = Jojo::TemplateValidator.warn_if_unchanged("nonexistent.md", "resume")
    assert_equal :skip, result
  end

  def test_warn_if_unchanged_returns_needs_warning_when_unchanged_without_cli
    File.write("test.md", "JOJO_TEMPLATE_PLACEHOLDER\nTemplate content")

    result = Jojo::TemplateValidator.warn_if_unchanged("test.md", "resume")
    assert_equal :needs_warning, result
  end

  def test_warn_if_unchanged_returns_continue_when_user_confirms
    File.write("test.md", "JOJO_TEMPLATE_PLACEHOLDER\nTemplate content")

    mock_cli = Minitest::Mock.new
    mock_cli.expect(:say, nil, [String, :yellow])
    mock_cli.expect(:say, nil, [String, :yellow])
    mock_cli.expect(:say, nil, [""])
    mock_cli.expect(:yes?, true, ["Continue anyway?"])

    result = Jojo::TemplateValidator.warn_if_unchanged("test.md", "resume", cli_instance: mock_cli)
    assert_equal :continue, result

    mock_cli.verify
  end

  def test_warn_if_unchanged_returns_abort_when_user_declines
    File.write("test.md", "JOJO_TEMPLATE_PLACEHOLDER\nTemplate content")

    mock_cli = Minitest::Mock.new
    mock_cli.expect(:say, nil, [String, :yellow])
    mock_cli.expect(:say, nil, [String, :yellow])
    mock_cli.expect(:say, nil, [""])
    mock_cli.expect(:yes?, false, ["Continue anyway?"])

    result = Jojo::TemplateValidator.warn_if_unchanged("test.md", "resume", cli_instance: mock_cli)
    assert_equal :abort, result

    mock_cli.verify
  end
end
