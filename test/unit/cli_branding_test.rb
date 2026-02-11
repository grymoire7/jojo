require_relative "../test_helper"
require_relative "../../lib/jojo/cli"

class CLIBrandingTest < JojoTest
  def test_has_branding_command
    assert_equal true, Jojo::CLI.commands.key?("branding")
  end

  def test_fails_when_application_does_not_exist
    app = Jojo::Application.new("test-branding-nonexistent")
    FileUtils.rm_rf(app.base_path) if Dir.exist?(app.base_path)

    out, err = capture_subprocess_io do
      system("#{File.join(@original_dir, "bin/jojo")} branding -s test-branding-nonexistent 2>&1 || true")
    end
    output = out + err

    assert_includes output, "not found"
  end
end
