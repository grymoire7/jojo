# test/unit/resume_data_loader_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_data_loader"

class ResumeDataLoaderTest < JojoTest
  def test_loads_valid_resume_data
    loader = Jojo::ResumeDataLoader.new(fixture_path("resume_data.yml"))
    data = loader.load

    assert_equal "Jane Doe", data["name"]
    assert_kind_of Array, data["skills"]
    assert_kind_of Array, data["experience"]
  end

  def test_raises_error_for_missing_file
    loader = Jojo::ResumeDataLoader.new("nonexistent.yml")

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      loader.load
    end

    assert_includes error.message, "not found"
  end

  def test_validates_required_fields
    File.write("invalid_resume_data.yml", "skills: [Ruby]")

    loader = Jojo::ResumeDataLoader.new("invalid_resume_data.yml")

    error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
      loader.load
    end

    assert_includes error.message, "name"
  end
end
