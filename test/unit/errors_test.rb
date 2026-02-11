require_relative "../test_helper"
require_relative "../../lib/jojo/errors"

class PermissionViolationTest < JojoTest
  def test_creates_error_with_message
    error = Jojo::PermissionViolation.new("Cannot remove items")
    assert_equal "Cannot remove items", error.message
  end

  def test_is_a_standard_error
    error = Jojo::PermissionViolation.new("test")
    assert_kind_of StandardError, error
  end
end
