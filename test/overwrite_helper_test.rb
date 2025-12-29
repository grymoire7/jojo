require "test_helper"
require "tmpdir"

class OverwriteHelperTest < Minitest::Test
  # Create a test class that includes the module
  class TestCLI
    include Jojo::OverwriteHelper
  end

  def setup
    @cli = TestCLI.new
  end

  def test_env_overwrite_returns_true_for_1
    with_env("JOJO_ALWAYS_OVERWRITE" => "1") do
      assert @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_true_for_true
    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      assert @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_true_for_yes
    with_env("JOJO_ALWAYS_OVERWRITE" => "yes") do
      assert @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_true_for_uppercase_TRUE
    with_env("JOJO_ALWAYS_OVERWRITE" => "TRUE") do
      assert @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_for_0
    with_env("JOJO_ALWAYS_OVERWRITE" => "0") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_for_false
    with_env("JOJO_ALWAYS_OVERWRITE" => "false") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_for_no
    with_env("JOJO_ALWAYS_OVERWRITE" => "no") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_for_random_string
    with_env("JOJO_ALWAYS_OVERWRITE" => "whatever") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_when_unset
    with_env("JOJO_ALWAYS_OVERWRITE" => nil) do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_env_overwrite_returns_false_when_empty
    with_env("JOJO_ALWAYS_OVERWRITE" => "") do
      refute @cli.send(:env_overwrite?)
    end
  end

  def test_should_overwrite_returns_true_when_flag_is_true
    assert @cli.send(:should_overwrite?, true)
  end

  def test_should_overwrite_returns_false_when_flag_is_false
    refute @cli.send(:should_overwrite?, false)
  end

  def test_should_overwrite_returns_true_when_flag_is_nil_and_env_is_truthy
    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      assert @cli.send(:should_overwrite?, nil)
    end
  end

  def test_should_overwrite_returns_false_when_flag_is_nil_and_env_is_falsy
    with_env("JOJO_ALWAYS_OVERWRITE" => "false") do
      refute @cli.send(:should_overwrite?, nil)
    end
  end

  def test_should_overwrite_flag_false_overrides_env_true
    with_env("JOJO_ALWAYS_OVERWRITE" => "true") do
      refute @cli.send(:should_overwrite?, false)
    end
  end

  def test_with_overwrite_check_yields_when_file_does_not_exist
    Dir.mktmpdir do |dir|
      path = File.join(dir, "nonexistent.txt")
      yielded = false

      @cli.with_overwrite_check(path, nil) do
        yielded = true
      end

      assert yielded, "Expected block to be yielded when file doesn't exist"
    end
  end

  def test_with_overwrite_check_yields_when_file_exists_and_flag_is_true
    Dir.mktmpdir do |dir|
      path = File.join(dir, "existing.txt")
      File.write(path, "original")
      yielded = false

      @cli.with_overwrite_check(path, true) do
        yielded = true
      end

      assert yielded, "Expected block to be yielded when --overwrite is set"
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
