require_relative 'test_helper'
require_relative '../lib/jojo/config'

describe Jojo::Config do
  it "loads seeker name" do
    config = Jojo::Config.new('test/fixtures/valid_config.yml')
    _(config.seeker_name).must_equal 'Test User'
  end
end
