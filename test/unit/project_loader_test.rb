require_relative '../test_helper'
require_relative '../../lib/jojo/project_loader'

describe Jojo::ProjectLoader do
  it "loads valid projects YAML" do
    loader = Jojo::ProjectLoader.new('test/fixtures/valid_projects.yml')
    projects = loader.load

    _(projects).must_be_kind_of Array
    _(projects.size).must_equal 2
    _(projects.first[:title]).must_equal 'Project Alpha'
  end
end
