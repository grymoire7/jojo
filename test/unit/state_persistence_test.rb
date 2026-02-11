# frozen_string_literal: true

require_relative "../test_helper"

class StatePersistenceTest < JojoTest
  def setup
    super
    @state_file = File.join(@tmpdir, ".jojo_state")
  end

  def test_saves_slug_to_state_file
    Jojo::StatePersistence.save_slug("acme-corp-dev")

    assert_equal true, File.exist?(@state_file)
    assert_equal "acme-corp-dev", File.read(@state_file).strip
  end

  def test_returns_nil_when_no_state_file_exists
    slug = Jojo::StatePersistence.load_slug
    assert_nil slug
  end

  def test_returns_saved_slug_when_state_file_exists
    File.write(@state_file, "acme-corp-dev")

    slug = Jojo::StatePersistence.load_slug
    assert_equal "acme-corp-dev", slug
  end

  def test_strips_whitespace_from_saved_slug
    File.write(@state_file, "  acme-corp-dev  \n")

    slug = Jojo::StatePersistence.load_slug
    assert_equal "acme-corp-dev", slug
  end

  def test_clear_removes_the_state_file
    File.write(@state_file, "acme-corp-dev")

    Jojo::StatePersistence.clear

    assert_equal false, File.exist?(@state_file)
  end

  def test_clear_does_nothing_if_no_state_file_exists
    Jojo::StatePersistence.clear  # Should not raise
  end
end
