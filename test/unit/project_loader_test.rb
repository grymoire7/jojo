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

  it "validates required fields" do
    loader = Jojo::ProjectLoader.new('test/fixtures/invalid_projects.yml')

    error = _ { loader.load }.must_raise Jojo::ProjectLoader::ValidationError
    _(error.message).must_include "missing 'title'"
  end

  it "validates skills is an array" do
    loader = Jojo::ProjectLoader.new('test/fixtures/invalid_skills_projects.yml')

    error = _ { loader.load }.must_raise Jojo::ProjectLoader::ValidationError
    _(error.message).must_include "'skills' must be an array"
  end

  it "returns empty array when file missing" do
    loader = Jojo::ProjectLoader.new('test/fixtures/nonexistent.yml')
    projects = loader.load

    _(projects).must_equal []
  end
end
