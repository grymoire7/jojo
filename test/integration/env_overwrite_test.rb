# test/integration/env_overwrite_test.rb
require "test_helper"
require "fileutils"
require "tmpdir"

class EnvOverwriteTest < JojoTest
  # Test class that includes OverwriteHelper
  class TestCLI
    include Jojo::OverwriteHelper

    attr_accessor :prompt_result

    def yes?(message)
      @prompt_result
    end
  end

  def setup
    super
    @test_dir = Dir.mktmpdir
    @cli = TestCLI.new
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
    super
  end

  def test_env_var_true_overwrites_without_prompting
    path = File.join(@test_dir, "test.txt")
    File.write(path, "original content")

    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      wrote = false
      @cli.with_overwrite_check(path, nil) do
        File.write(path, "new content")
        wrote = true
      end

      assert wrote, "Expected block to execute"
      assert_equal "new content", File.read(path)
    end
  end

  def test_env_var_1_overwrites_without_prompting
    path = File.join(@test_dir, "test.txt")
    File.write(path, "original content")

    with_env("JOJO_ALWAYS_OVERWRITE" => "1") do
      wrote = false
      @cli.with_overwrite_check(path, nil) do
        File.write(path, "new content")
        wrote = true
      end

      assert wrote, "Expected block to execute"
      assert_equal "new content", File.read(path)
    end
  end

  def test_env_var_yes_overwrites_without_prompting
    path = File.join(@test_dir, "test.txt")
    File.write(path, "original content")

    with_env("JOJO_ALWAYS_OVERWRITE" => "yes") do
      wrote = false
      @cli.with_overwrite_check(path, nil) do
        File.write(path, "new content")
        wrote = true
      end

      assert wrote, "Expected block to execute"
      assert_equal "new content", File.read(path)
    end
  end

  def test_no_overwrite_flag_blocks_env_var
    path = File.join(@test_dir, "test.txt")
    File.write(path, "original content")

    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      # Mock TTY to return true so we don't get the non-TTY error
      $stdout.stub :isatty, true do
        @cli.prompt_result = false
        wrote = false

        @cli.with_overwrite_check(path, false) do
          File.write(path, "new content")
          wrote = true
        end

        # Block should NOT execute because user said no via prompt
        refute wrote, "Expected block NOT to execute when user declines prompt"
        assert_equal "original content", File.read(path)
      end
    end
  end

  def test_overwrite_flag_true_takes_precedence_over_env_var
    path = File.join(@test_dir, "test.txt")
    File.write(path, "original content")

    with_env("JOJO_ALWAYS_OVERWRITE" => "false") do
      wrote = false
      @cli.with_overwrite_check(path, true) do
        File.write(path, "new content")
        wrote = true
      end

      assert wrote, "Expected block to execute when --overwrite is set"
      assert_equal "new content", File.read(path)
    end
  end

  private

  def with_env(env_vars)
    old_values = {}
    env_vars.each do |key, value|
      old_values[key] = ENV[key]
      ENV[key] = value
    end
    yield
  ensure
    old_values.each do |key, value|
      ENV[key] = value
    end
  end
end
