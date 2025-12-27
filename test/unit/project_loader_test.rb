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

  it "loads minimal projects with only required fields" do
    loader = Jojo::ProjectLoader.new('test/fixtures/minimal_projects.yml')
    projects = loader.load

    _(projects.size).must_equal 1
    _(projects.first[:title]).must_equal 'Minimal Project'
    _(projects.first[:year]).must_be_nil
    _(projects.first[:context]).must_be_nil
  end
end
