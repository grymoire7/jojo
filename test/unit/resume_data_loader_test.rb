# test/unit/resume_data_loader_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_data_loader"

describe Jojo::ResumeDataLoader do
  it "loads valid resume data" do
    loader = Jojo::ResumeDataLoader.new("test/fixtures/resume_data.yml")
    data = loader.load

    _(data["name"]).must_equal "Jane Doe"
    _(data["skills"]).must_be_kind_of Array
    _(data["experience"]).must_be_kind_of Array
  end

  it "raises error for missing file" do
    loader = Jojo::ResumeDataLoader.new("nonexistent.yml")

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      loader.load
    end

    _(error.message).must_include "not found"
  end

  it "validates required fields" do
    # Create invalid fixture
    invalid_path = "test/fixtures/invalid_resume_data.yml"
    File.write(invalid_path, "skills: [Ruby]")

    loader = Jojo::ResumeDataLoader.new(invalid_path)

    error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
      loader.load
    end

    _(error.message).must_include "name"

    FileUtils.rm_f(invalid_path)
  end
end
