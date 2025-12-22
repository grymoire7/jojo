require_relative 'test_helper'
require_relative '../lib/jojo/employer'

describe Jojo::Employer do
  it "slugifies company name with spaces" do
    employer = Jojo::Employer.new('Acme Corp')
    _(employer.slug).must_equal 'acme-corp'
  end
end
