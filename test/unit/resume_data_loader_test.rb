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

  def test_raises_on_invalid_yaml_syntax
    File.write("malformed.yml", "name: [\ninvalid: yaml: content: {broken")

    loader = Jojo::ResumeDataLoader.new("malformed.yml")

    error = assert_raises(Jojo::ResumeDataLoader::LoadError) do
      loader.load
    end

    assert_includes error.message, "Invalid YAML"
  end

  def test_raises_when_skills_is_not_array
    File.write("bad_skills.yml", <<~YAML)
      name: Test
      email: test@example.com
      summary: A summary
      skills: "ruby"
      experience:
        - company: Co
          title: Dev
    YAML

    loader = Jojo::ResumeDataLoader.new("bad_skills.yml")

    error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
      loader.load
    end

    assert_includes error.message, "skills must be an array"
  end

  def test_raises_when_experience_is_not_array
    File.write("bad_experience.yml", <<~YAML)
      name: Test
      email: test@example.com
      summary: A summary
      skills:
        - Ruby
      experience: "stuff"
    YAML

    loader = Jojo::ResumeDataLoader.new("bad_experience.yml")

    error = assert_raises(Jojo::ResumeDataLoader::ValidationError) do
      loader.load
    end

    assert_includes error.message, "experience must be an array"
  end
end
