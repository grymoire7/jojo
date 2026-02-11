require_relative "../test_helper"
require_relative "../../lib/jojo/errors"

class PermissionViolationTest < JojoTest
  def test_creates_error_with_message
    error = Jojo::PermissionViolation.new("Cannot remove items")
    _(error.message).must_equal "Cannot remove items"
  end

  def test_is_a_standard_error
    error = Jojo::PermissionViolation.new("test")
    _(error).must_be_kind_of StandardError
  end
end
