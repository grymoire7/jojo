# frozen_string_literal: true

require_relative "../test_helper"

class StatePersistenceTest < JojoTest
  def setup
    super
    @state_file = File.join(@tmpdir, ".jojo_state")
  end

  def test_saves_slug_to_state_file
    Jojo::StatePersistence.save_slug("acme-corp-dev")

    _(File.exist?(@state_file)).must_equal true
    _(File.read(@state_file).strip).must_equal "acme-corp-dev"
  end

  def test_returns_nil_when_no_state_file_exists
    slug = Jojo::StatePersistence.load_slug
    _(slug).must_be_nil
  end

  def test_returns_saved_slug_when_state_file_exists
    File.write(@state_file, "acme-corp-dev")

    slug = Jojo::StatePersistence.load_slug
    _(slug).must_equal "acme-corp-dev"
  end

  def test_strips_whitespace_from_saved_slug
    File.write(@state_file, "  acme-corp-dev  \n")

    slug = Jojo::StatePersistence.load_slug
    _(slug).must_equal "acme-corp-dev"
  end

  def test_clear_removes_the_state_file
    File.write(@state_file, "acme-corp-dev")

    Jojo::StatePersistence.clear

    _(File.exist?(@state_file)).must_equal false
  end

  def test_clear_does_nothing_if_no_state_file_exists
    Jojo::StatePersistence.clear  # Should not raise
  end
end
