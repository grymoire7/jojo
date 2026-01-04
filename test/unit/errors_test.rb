require_relative "../test_helper"
require_relative "../../lib/jojo/errors"

describe Jojo::PermissionViolation do
  it "creates error with message" do
    error = Jojo::PermissionViolation.new("Cannot remove items")
    _(error.message).must_equal "Cannot remove items"
  end

  it "is a StandardError" do
    error = Jojo::PermissionViolation.new("test")
    _(error).must_be_kind_of StandardError
  end
end
