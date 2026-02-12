# test/unit/resume_data_formatter_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/resume_data_formatter"

class ResumeDataFormatterTest < JojoTest
  def test_formats_complete_resume_data
    data = build_complete_data

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "# Jane Doe"
    assert_includes result, "jane@example.com | San Francisco, CA"
    assert_includes result, "## Summary"
    assert_includes result, "Experienced engineer"
    assert_includes result, "## Skills"
    assert_includes result, "Ruby, Python, JavaScript"
    assert_includes result, "## Experience"
    assert_includes result, "### Senior Engineer at TechCorp"
    assert_includes result, "## Projects"
    assert_includes result, "### CLI Tool"
  end

  def test_formats_experience_with_technologies
    data = build_complete_data

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "Technologies: Ruby on Rails, PostgreSQL"
  end

  def test_formats_experience_without_technologies
    data = build_complete_data
    data["experience"] = [
      {
        "title" => "Developer",
        "company" => "StartupCo",
        "description" => "Built things"
      }
    ]

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "### Developer at StartupCo"
    assert_includes result, "Built things"
    refute_includes result, "Technologies:"
  end

  def test_formats_with_projects
    data = build_complete_data

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "### CLI Tool"
    assert_includes result, "A command-line tool"
    assert_includes result, "Skills: Ruby, AWS"
  end

  def test_formats_without_projects
    data = build_complete_data
    data["projects"] = []

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "No projects listed."
  end

  def test_formats_with_nil_projects
    data = build_complete_data
    data["projects"] = nil

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "No projects listed."
  end

  def test_formats_projects_without_description
    data = build_complete_data
    data["projects"] = [
      {"name" => "Secret Project", "skills" => ["Go"]}
    ]

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "### Secret Project"
    assert_includes result, "Skills: Go"
    # No description line should be present
    refute_includes result, "nil"
  end

  def test_formats_projects_without_skills
    data = build_complete_data
    data["projects"] = [
      {"name" => "Simple Project", "description" => "A basic project", "skills" => []}
    ]

    result = Jojo::ResumeDataFormatter.format(data)

    assert_includes result, "### Simple Project"
    assert_includes result, "A basic project"
    refute_includes result, "Skills:"
  end

  private

  def build_complete_data
    {
      "name" => "Jane Doe",
      "email" => "jane@example.com",
      "location" => "San Francisco, CA",
      "summary" => "Experienced engineer",
      "skills" => ["Ruby", "Python", "JavaScript"],
      "experience" => [
        {
          "title" => "Senior Engineer",
          "company" => "TechCorp",
          "description" => "Led development of microservices",
          "technologies" => ["Ruby on Rails", "PostgreSQL"]
        }
      ],
      "projects" => [
        {
          "name" => "CLI Tool",
          "description" => "A command-line tool",
          "skills" => ["Ruby", "AWS"]
        }
      ]
    }
  end
end
