# test/unit/resume_data_loader_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_data_loader"

class ResumeDataLoaderTest < JojoTest
  def test_loads_valid_resume_data
    loader = Jojo::ResumeDataLoader.new(fixture_path("resume_data.yml"))
    data = loader.load

    _(data["name"]).must_equal "Jane Doe"
    _(data["skills"]).must_be_kind_of Array
    _(data["experience"]).must_be_kind_of Array
  end

  def test_raises_error_for_missing_file
    loader = Jojo::ResumeDataLoader.new("nonexistent.yml")

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      loader.load
    end

    _(error.message).must_include "not found"
  end

  def test_validates_required_fields
    File.write("invalid_resume_data.yml", "skills: [Ruby]")

    loader = Jojo::ResumeDataLoader.new("invalid_resume_data.yml")

    error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
      loader.load
    end

    _(error.message).must_include "name"
  end
end
