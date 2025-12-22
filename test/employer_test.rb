require_relative 'test_helper'
require_relative '../lib/jojo/employer'

describe Jojo::Employer do
  it "slugifies company name with spaces" do
    employer = Jojo::Employer.new('Acme Corp')
    _(employer.slug).must_equal 'acme-corp'
  end

  it "slugifies special characters" do
    employer = Jojo::Employer.new('AT&T Inc.')
    _(employer.slug).must_equal 'at-t-inc'
  end

  it "slugifies multiple spaces" do
    employer = Jojo::Employer.new('Example  Company   LLC')
    _(employer.slug).must_equal 'example-company-llc'
  end

  it "slugifies leading and trailing special characters" do
    employer = Jojo::Employer.new('!Company!')
    _(employer.slug).must_equal 'company'
  end
end
