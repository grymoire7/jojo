# test/unit/erb_renderer_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/erb_renderer"

class ErbRendererTest < JojoTest
  def test_renders_erb_template_with_data
    template_path = fixture_path("templates/resume_template.md.erb")
    data = {
      "name" => "Jane Doe",
      "email" => "jane@example.com",
      "phone" => "+1-555-0123",
      "location" => "SF, CA",
      "summary" => "Experienced engineer",
      "skills" => ["Ruby", "Python"],
      "experience" => [
        {
          "title" => "Senior Dev",
          "company" => "TechCo",
          "start_date" => "2020-01",
          "end_date" => "present",
          "description" => "Built things",
          "technologies" => ["Ruby", "Rails"]
        }
      ],
      "education" => [
        {
          "degree" => "BS CS",
          "institution" => "State U",
          "year" => "2015"
        }
      ],
      "projects" => [
        {
          "name" => "CLI Tool",
          "description" => "Command line tool",
          "skills" => ["Ruby"]
        }
      ],
      "recommendations" => [
        {
          "name" => "Jane Smith",
          "title" => "Manager",
          "quote" => "Great engineer"
        }
      ]
    }

    renderer = Jojo::ErbRenderer.new(template_path)
    result = renderer.render(data)

    assert_includes result, "# Jane Doe"
    assert_includes result, "jane@example.com"
    assert_includes result, "Experienced engineer"
    assert_includes result, "Ruby • Python"
    assert_includes result, "### Senior Dev at TechCo"
    assert_includes result, "> Great engineer"
    assert_includes result, "Jane Smith"
  end

  def test_handles_missing_optional_fields
    template_path = fixture_path("templates/resume_template.md.erb")
    data = {
      "name" => "John Doe",
      "email" => "john@example.com",
      "phone" => "555-0100",
      "location" => "NYC",
      "summary" => "Engineer",
      "skills" => ["Python"],
      "experience" => [],
      "education" => [],
      "projects" => []
    }

    renderer = Jojo::ErbRenderer.new(template_path)
    result = renderer.render(data)

    assert_includes result, "# John Doe"
    refute_includes result, "## Recommendations"
  end
end
